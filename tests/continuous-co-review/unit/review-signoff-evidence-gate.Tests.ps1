$ErrorActionPreference = 'Stop'

# Trace: T061, FR-025, FR-007, FR-027, TG-013.
# NOTE (F4, 145 review): SC-019/SC-020 are demonstrated only by the WIRED boundary gate
# (deferred post-185). These tests prove the DECISION LOGIC: it blocks un-reviewed state
# (no-evidence, untracked, stale, malformed, unresolvable) and allows only a fresh match.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T061 co-review signoff gate-floor decision logic (FR-025)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:Scope = '197/003'
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
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a0' -Encoding UTF8
        Invoke-GateGit $repo @('add', '-A')
        Invoke-GateGit $repo @('commit', '-q', '-m', 'base')
        return $repo
    }

    function New-GatePassingRun {
        param($Root, $RunId, $BaselineRef, $DiffHash, $Scope = '197/003', $Status = 'pass')
        $directory = Join-Path (Join-Path $Root '.specrew/review/inline') $RunId
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        ([pscustomobject][ordered]@{
            schema_version = '1.0'; run_id = $RunId; checkpoint_id = 'cp'; baseline_ref = $BaselineRef
            diff_hash = $DiffHash; reviewed_ref = $BaselineRef; scope = $Scope; status = $Status
            created_at = '2026-06-20T00:00:01Z'; updated_at = '2026-06-20T00:00:01Z'
        } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $directory 'review-run.json') -Encoding UTF8 -NoNewline
    }

    function Get-RealDiffHash {
        param($Repo, $Baseline)
        return (Get-ContinuousCoReviewCheckpointDiff -RepoRoot $Repo -BaselineRef $Baseline -CheckpointId 'probe' -RunId 'probe').diff_hash
    }

    It 'blocks when there is no in-scope co-review evidence' {
        $repo = New-GateRepo 'no-ev'
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope).reason | Should Be 'no-co-review-evidence'
    }

    It 'allows when a real non-empty reviewed change matches the last passing run' {
        $repo = New-GateRepo 'fresh'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a1-reviewed-change' -Encoding UTF8   # tracked, uncommitted
        $hash = Get-RealDiffHash -Repo $repo -Baseline $b
        $hash | Should Not Be "sha256:$([string](Get-ContinuousCoReviewSha256Hex -Text ''))"            # prove the diff is non-empty
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash $hash

        $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope
        $decision.decision | Should Be 'allow'
        $decision.reason | Should Be 'fresh-co-review-evidence'
    }

    It 'BLOCKS untracked reviewable content even when the tracked diff_hash matches (F1)' {
        $repo = New-GateRepo 'untracked'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash (Get-RealDiffHash -Repo $repo -Baseline $b)  # matches clean tree
        Set-Content -LiteralPath (Join-Path $repo 'sneaky-unreviewed.txt') -Value 'never added' -Encoding UTF8

        $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope
        $decision.decision | Should Be 'block'
        $decision.reason | Should Be 'unreviewed-working-tree'
    }

    It 'blocks as stale when a tracked reviewable change drifts after the pass' {
        $repo = New-GateRepo 'stale'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a1' -Encoding UTF8
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash (Get-RealDiffHash -Repo $repo -Baseline $b)
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a2-drifted' -Encoding UTF8           # drift after the pass

        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope).reason | Should Be 'stale-co-review-evidence'
    }

    It 'blocks when the latest passing run has a malformed (empty) diff_hash' {
        $repo = New-GateRepo 'malformed'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash ''

        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope).reason | Should Be 'malformed-co-review-evidence'
    }

    It 'blocks when the recorded baseline can no longer be resolved' {
        $repo = New-GateRepo 'unresolvable'
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef ('0' * 40) -DiffHash 'sha256:deadbeef'

        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope).reason | Should Be 'baseline-unresolvable'
    }

    It 'ignores a passing run from a different scope (no false allow across features)' {
        $repo = New-GateRepo 'cross-scope'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash (Get-RealDiffHash -Repo $repo -Baseline $b) -Scope '999/001'

        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $repo -Scope $script:Scope).reason | Should Be 'no-co-review-evidence'
    }

    It 'Assert throws on a stale blocking decision' {
        $repo = New-GateRepo 'assert-stale'
        $b = (& git -C $repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a1' -Encoding UTF8
        New-GatePassingRun -Root $repo -RunId 'r1' -BaselineRef $b -DiffHash (Get-RealDiffHash -Repo $repo -Baseline $b)
        Set-Content -LiteralPath (Join-Path $repo 'a.txt') -Value 'a2-drifted' -Encoding UTF8
        $threw = $false
        try { Assert-ContinuousCoReviewSignoffGate -RepoRoot $repo -Scope $script:Scope | Out-Null } catch { $threw = $true }
        $threw | Should Be $true
    }
}
