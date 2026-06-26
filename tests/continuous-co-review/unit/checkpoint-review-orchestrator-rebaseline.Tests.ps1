$ErrorActionPreference = 'Stop'

# Trace: T058, FR-027, FR-025, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T058 orchestrator rebaselines to the last passing reviewed point and records reviewed_ref' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Invoke-FixtureGit {
                param([string] $Root, [string[]] $GitArgs)
                Push-Location -LiteralPath $Root
                try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location }
            }

        function New-RebaselineFixtureAdapter {
                return {
                    param($Candidate, $Request, $RequestBundle, [int] $AttemptNumber)
                    $findings = [pscustomobject][ordered]@{
                        schema_version = '1.0'
                        run_id         = $Request.run_id
                        status         = 'no_findings'
                        reviewer       = [pscustomobject][ordered]@{ host = $Candidate.host; model = $Candidate.model; adapter_id = $Candidate.adapter_id }
                        findings       = @()
                        created_at     = $Request.created_at
                    }
                    return [pscustomobject][ordered]@{
                        kind                = 'findings-result'
                        provider_invocation = [pscustomobject][ordered]@{
                            schema_version        = '1.0'
                            invocation_id         = "invocation-$($Request.run_id)-fixture-$AttemptNumber"
                            run_id                = $Request.run_id
                            attempt_number        = $AttemptNumber
                            adapter_id            = $Candidate.adapter_id
                            requested_host        = $Request.provider_request.requested_host
                            requested_model       = $Request.provider_request.requested_model
                            actual_host           = $Candidate.host
                            actual_model          = $Candidate.model
                            argv_summary          = @('fixture', '--stdin')
                            working_directory_ref = '.specrew/review/inline'
                            timeout_seconds       = 30
                            stdout_capture_policy = 'parse-json-only'
                            stderr_capture_policy = 'status-only'
                            exit_code             = 0
                            failure_category      = $null
                            started_at            = $Request.created_at
                            ended_at              = $Request.created_at
                        }
                        findings_result     = $findings
                        infrastructure_failure = $null
                    }
                }.GetNewClosure()
            }
}

    
    
    It 'advances the baseline to the last passing reviewed_ref and records reviewed_ref = HEAD' {
        $repo = Join-Path $TestDrive 'reb-repo'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-FixtureGit $repo @('init', '-q')
        Invoke-FixtureGit $repo @('config', 'user.email', 't@example.com')
        Invoke-FixtureGit $repo @('config', 'user.name', 'Test')
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a0' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo 'design.md') -Value '# Design context for the fixture review' -Encoding UTF8
        Invoke-FixtureGit $repo @('add', '-A')
        Invoke-FixtureGit $repo @('commit', '-q', '-m', 'init')
        $bInit = (& git -C $repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $repo 'b.txt') -Value 'b0' -Encoding UTF8
        Invoke-FixtureGit $repo @('add', '-A')
        Invoke-FixtureGit $repo @('commit', '-q', '-m', 'b0')
        $b0 = (& git -C $repo rev-parse HEAD).Trim()

        $inlineDir = Join-Path $repo (Join-Path '.specrew/review/inline' 'prev-run')
        New-Item -ItemType Directory -Path $inlineDir -Force | Out-Null
        ([pscustomobject][ordered]@{
            schema_version = '1.0'; run_id = 'prev-run'; checkpoint_id = 'cp-prev'; baseline_ref = $bInit
            diff_hash = 'sha256:prev'; reviewed_ref = $b0; status = 'pass'
            created_at = '2026-06-20T00:00:01Z'; updated_at = '2026-06-20T00:00:01Z'
        } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $inlineDir 'review-run.json') -Encoding UTF8 -NoNewline

        # Uncommitted increment after the last passing point.
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a1' -Encoding UTF8

        $providerRequest = [pscustomobject][ordered]@{ requested_host = $null; requested_model = $null; authorization_ref = 'test'; timeout_seconds = 30; fallback_policy = 'none' }
        $candidate = [pscustomobject][ordered]@{ adapter_id = 'reviewer-host-adapter-fixture'; host = 'fixture'; model = 'fixture'; authorized = $true; authorization_ref = 'test'; timeout_seconds = 30 }

        $result = Invoke-ContinuousCoReviewCheckpointReview -RepoRoot $repo -CheckpointId 'cp-now' -BaselineRef $bInit -RunId 'reb-now' -ProviderRequest $providerRequest -DesignContextRefs @('design.md') -Candidates @($candidate) -InvokeAdapter (New-RebaselineFixtureAdapter) -SchemaRoot $script:SchemaRoot -RebaselineToLastPass

        $result.change_set.baseline_ref | Should -Be $b0
        ($result.change_set.changed_paths -contains 'b.txt') | Should -Be $false
        ($result.change_set.changed_paths -contains 'a.txt') | Should -Be $true

        $runJson = Get-Content -LiteralPath (Join-Path $repo '.specrew/review/inline/reb-now/review-run.json') -Raw | ConvertFrom-Json
        $runJson.reviewed_ref | Should -Be $b0
        $runJson.diff_hash | Should -Not -BeNullOrEmpty
    }
}
