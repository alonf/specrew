$ErrorActionPreference = 'Stop'

# Trace: T060, FR-024, FR-032, INT-004, TG-013.
# The dispatcher actually RUNS the orchestrator on a registered checkpoint and runs NOTHING
# on a no-op (unregistered stage / casual yield) - zero spawn proven end to end.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T060 dispatch wiring runs the reviewer only on a registered checkpoint' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
    }

    function Invoke-WireGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

    function New-WireRepo {
        $repo = Join-Path $TestDrive ('wire-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-WireGit $repo @('init', '-q'); Invoke-WireGit $repo @('config', 'user.email', 't@e.c'); Invoke-WireGit $repo @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo 'design.md') -Value '# design' -Encoding UTF8
        Invoke-WireGit $repo @('add', '-A'); Invoke-WireGit $repo @('commit', '-q', '-m', 'base'); Invoke-WireGit $repo @('branch', '-M', 'main')
        Invoke-WireGit $repo @('checkout', '-q', '-b', 'feature')
        Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'v0' -Encoding UTF8
        Invoke-WireGit $repo @('add', '-A'); Invoke-WireGit $repo @('commit', '-q', '-m', 'feat')
        return $repo
    }

    function New-PassAdapter {
        return {
            param($Candidate, $Request, $RequestBundle, [int]$AttemptNumber)
            $findings = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $Request.run_id; status = 'no_findings'; reviewer = [pscustomobject]@{ host = $Candidate.host; model = $Candidate.model; adapter_id = $Candidate.adapter_id }; findings = @(); created_at = $Request.created_at }
            return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject][ordered]@{ schema_version = '1.0'; invocation_id = "inv-$($Request.run_id)"; run_id = $Request.run_id; attempt_number = $AttemptNumber; adapter_id = $Candidate.adapter_id; requested_host = $Request.provider_request.requested_host; requested_model = $Request.provider_request.requested_model; actual_host = $Candidate.host; actual_model = $Candidate.model; argv_summary = @('fixture'); working_directory_ref = '.specrew/review/inline'; timeout_seconds = 30; stdout_capture_policy = 'parse-json-only'; stderr_capture_policy = 'status-only'; exit_code = 0; failure_category = $null; started_at = $Request.created_at; ended_at = $Request.created_at }; findings_result = $findings; infrastructure_failure = $null }
        }.GetNewClosure()
    }

    $providerRequest = [pscustomobject][ordered]@{ requested_host = $null; requested_model = $null; authorization_ref = 'test'; timeout_seconds = 30; fallback_policy = 'none' }
    $candidate = [pscustomobject][ordered]@{ adapter_id = 'reviewer-host-adapter-fixture'; host = 'fixture'; model = 'fixture'; authorized = $true; authorization_ref = 'test'; timeout_seconds = 30 }

    It 'an UNREGISTERED stage runs no reviewer (no evidence written)' {
        $repo = New-WireRepo
        $head = (& git -C $repo rev-parse HEAD).Trim()
        $r = Invoke-ContinuousCoReviewGateCheckpoint -RepoRoot $repo -Stage 'plan' -BaselineRef $head -CheckpointReached $true -ProviderRequest $providerRequest -DesignContextRefs @('design.md') -Candidates @($candidate) -InvokeAdapter (New-PassAdapter) -SchemaRoot $script:SchemaRoot
        $r.dispatched | Should Be $false
        $r.review | Should Be $null
        (Test-Path (Join-Path $repo '.specrew/review/inline')) | Should Be $false
    }

    It 'a registered implement checkpoint RUNS the orchestrator and writes a pass run' {
        $repo = New-WireRepo
        $head = (& git -C $repo rev-parse HEAD).Trim()
        $r = Invoke-ContinuousCoReviewGateCheckpoint -RepoRoot $repo -Stage 'implement' -CheckpointId 'cp1' -BaselineRef $head -TrunkName 'main' -CheckpointReached $true -ProviderRequest $providerRequest -DesignContextRefs @('design.md') -Candidates @($candidate) -InvokeAdapter (New-PassAdapter) -SchemaRoot $script:SchemaRoot
        $r.dispatched | Should Be $true
        $r.review | Should Not Be $null
        $r.review.status | Should Be 'pass'
    }
}
