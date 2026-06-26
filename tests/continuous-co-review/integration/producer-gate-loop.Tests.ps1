$ErrorActionPreference = 'Stop'

# Trace: T068, FR-025, FR-027, TG-013.
# Closes the loop: the orchestrator (producer) auto-anchors a signoff run to the merge-base,
# records the content-addressed reviewed_tree_id, and the gate then ALLOWS the matching
# current state and BLOCKS once it drifts. This is the end-to-end HOLE-A/HOLE-B proof.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T068 producer auto-anchor + digest closes the gate loop (FR-025/FR-027)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Invoke-LoopGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

        function New-PassAdapter {
                return {
                    param($Candidate, $Request, $RequestBundle, [int]$AttemptNumber)
                    $findings = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $Request.run_id; status = 'no_findings'; reviewer = [pscustomobject]@{ host = $Candidate.host; model = $Candidate.model; adapter_id = $Candidate.adapter_id }; findings = @(); created_at = $Request.created_at }
                    return [pscustomobject][ordered]@{
                        kind = 'findings-result'
                        provider_invocation = [pscustomobject][ordered]@{ schema_version = '1.0'; invocation_id = "inv-$($Request.run_id)"; run_id = $Request.run_id; attempt_number = $AttemptNumber; adapter_id = $Candidate.adapter_id; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; argv_summary = @('fixture'); working_directory_ref = '.specrew/review/inline'; timeout_seconds = 30; stdout_capture_policy = 'parse-json-only'; stderr_capture_policy = 'status-only'; exit_code = 0; failure_category = $null; started_at = $Request.created_at; ended_at = $Request.created_at }
                        findings_result = $findings
                        infrastructure_failure = $null
                    }
                }.GetNewClosure()
            }
}

    

    

    It 'a signoff run auto-anchors to merge-base, records the tree-id, and the gate ALLOWS then BLOCKS on drift' {
        $repo = Join-Path $TestDrive 'loop'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-LoopGit $repo @('init', '-q'); Invoke-LoopGit $repo @('config', 'user.email', 't@e.c'); Invoke-LoopGit $repo @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo 'design.md') -Value '# design context' -Encoding UTF8
        Invoke-LoopGit $repo @('add', '-A'); Invoke-LoopGit $repo @('commit', '-q', '-m', 'base'); Invoke-LoopGit $repo @('branch', '-M', 'main')
        $anchor = (& git -C $repo rev-parse HEAD).Trim()
        Invoke-LoopGit $repo @('checkout', '-q', '-b', 'feature')
        Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature v0' -Encoding UTF8
        Invoke-LoopGit $repo @('add', '-A'); Invoke-LoopGit $repo @('commit', '-q', '-m', 'feat')

        $providerRequest = [pscustomobject][ordered]@{ requested_host = $null; requested_model = $null; authorization_ref = 'test'; timeout_seconds = 30; fallback_policy = 'none' }
        $candidate = [pscustomobject][ordered]@{ adapter_id = 'reviewer-host-adapter-fixture'; host = 'fixture'; model = 'fixture'; authorized = $true; authorization_ref = 'test'; timeout_seconds = 30 }

        $result = Invoke-ContinuousCoReviewCheckpointReview -RepoRoot $repo -CheckpointId 'cp1' -BaselineRef $anchor -RunId 'run-1' -ProviderRequest $providerRequest -DesignContextRefs @('design.md') -Candidates @($candidate) -InvokeAdapter (New-PassAdapter) -SchemaRoot $script:SchemaRoot -RebaselineToLastPass -TrunkName 'main'

        # The producer recorded a pass with a reviewed_tree_id and the auto-anchored baseline.
        $runJson = Get-Content -LiteralPath (Join-Path $repo '.specrew/review/inline/run-1/review-run.json') -Raw | ConvertFrom-Json
        $runJson.status | Should -Be 'pass'
        $runJson.reviewed_tree_id | Should -Match '^[0-9a-f]{40}$'
        $runJson.baseline_ref | Should -Be $anchor    # first run auto-anchored to merge-base

        # The gate ALLOWS the reviewed state.
        $allow = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -TrunkName 'main'
        $allow.decision | Should -Be 'allow'
        $allow.reason | Should -Be 'fresh-and-covered'

        # Drift the worktree -> the gate BLOCKS as stale.
        Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'unreviewed change' -Encoding UTF8
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -TrunkName 'main').reason | Should -Be 'stale-co-review-evidence'
    }
}
