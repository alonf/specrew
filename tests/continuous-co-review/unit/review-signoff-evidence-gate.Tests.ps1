$ErrorActionPreference = 'Stop'

# Trace: T061, FR-025, SC-019, SC-020, TG-013.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T061 deterministic co-review signoff gate floor (FR-025)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    function Invoke-GateGit {
        param([string] $Root, [string[]] $GitArgs)
        Push-Location -LiteralPath $Root
        try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location }
    }

    function New-GateRepo {
        param([string] $Name)
        $repo = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-GateGit $repo @('init', '-q')
        Invoke-GateGit $repo @('config', 'user.email', 't@example.com')
        Invoke-GateGit $repo @('config', 'user.name', 'Test')
        return $repo
    }

    function New-GatePassingRun {
        param($Root, $RunId, $BaselineRef, $DiffHash, $ReviewedRef)
        $directory = Join-Path (Join-Path $Root '.specrew/review/inline') $RunId
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        ([pscustomobject][ordered]@{
            schema_version = '1.0'; run_id = $RunId; checkpoint_id = 'cp'; baseline_ref = $BaselineRef
            diff_hash = $DiffHash; reviewed_ref = $ReviewedRef; status = 'pass'
            created_at = '2026-06-20T00:00:01Z'; updated_at = '2026-06-20T00:00:01Z'
        } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $directory 'review-run.json') -Encoding UTF8 -NoNewline
    }

    It 'blocks when there is no co-review evidence' {
        $repo = New-GateRepo 'no-ev'
        $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo
        $decision.decision | Should Be 'block'
        $decision.reason | Should Be 'no-co-review-evidence'
    }

    It 'allows when the working tree matches the last passing run by diff_hash' {
        $repo = New-GateRepo 'fresh'
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a0' -Encoding UTF8
        Invoke-GateGit $repo @('add', '-A')
        Invoke-GateGit $repo @('commit', '-q', '-m', 'b')
        $b = (& git -C $repo rev-parse HEAD).Trim()
        $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo -BaselineRef $b -CheckpointId 'probe' -RunId 'probe'
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash $changeSet.diff_hash -ReviewedRef $b

        $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo
        $decision.decision | Should Be 'allow'
        $decision.reason | Should Be 'fresh-co-review-evidence'
    }

    It 'blocks as stale when the working tree drifted since the last passing run' {
        $repo = New-GateRepo 'stale'
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a0' -Encoding UTF8
        Invoke-GateGit $repo @('add', '-A')
        Invoke-GateGit $repo @('commit', '-q', '-m', 'b')
        $b = (& git -C $repo rev-parse HEAD).Trim()
        $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $repo -BaselineRef $b -CheckpointId 'probe' -RunId 'probe'
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash $changeSet.diff_hash -ReviewedRef $b
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a1-changed-after-review' -Encoding UTF8

        $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo
        $decision.decision | Should Be 'block'
        $decision.reason | Should Be 'stale-co-review-evidence'
    }

    It 'Assert throws on a blocking decision' {
        $repo = New-GateRepo 'assert'
        $threw = $false
        try { Assert-ContinuousCoReviewSignoffGate -RepoRoot $repo | Out-Null } catch { $threw = $true }
        $threw | Should Be $true
    }
}
