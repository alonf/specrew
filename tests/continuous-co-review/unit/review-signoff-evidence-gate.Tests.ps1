$ErrorActionPreference = 'Stop'

# Trace: T067, FR-025, FR-027, NFR-001, TG-013.
# These prove the re-architected gate DECISION LOGIC: it allows only a current reviewed-state
# that matches a passing run AND whose chain reaches the trunk anchor, and blocks HOLE A
# (gitignored drift), HOLE B (unanchored/coverage gap), stale, empty, no-evidence, and
# fail-closed git/digest failures. SC-019/SC-020 are demonstrated by the WIRED boundary gate
# (deferred post-185).
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T067 re-architected co-review signoff gate (FR-025)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    function Invoke-GateGit { param($Root, [string[]] $GitArgs) Push-Location $Root; try { & git @GitArgs 2>&1 | Out-Null } finally { Pop-Location } }

    function New-FeatureRepo {
        # main (base) -> feature branch with one feature commit. Returns @{ repo; anchor }.
        param([string] $Name)
        $repo = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Invoke-GateGit $repo @('init', '-q'); Invoke-GateGit $repo @('config', 'user.email', 't@e.c'); Invoke-GateGit $repo @('config', 'user.name', 't')
        Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'shipped' -Encoding UTF8
        Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'base')
        Invoke-GateGit $repo @('branch', '-M', 'main')
        $anchor = (& git -C $repo rev-parse HEAD).Trim()
        Invoke-GateGit $repo @('checkout', '-q', '-b', 'feature')
        Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature v0' -Encoding UTF8
        Invoke-GateGit $repo @('add', '-A'); Invoke-GateGit $repo @('commit', '-q', '-m', 'feat')
        return @{ repo = $repo; anchor = $anchor }
    }

    function Write-PassRun {
        param($Repo, $RunId, $BaselineRef, $TreeId, $ReviewedRef)
        $dir = Join-Path (Join-Path $Repo '.specrew/review/inline') $RunId
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        ([pscustomobject][ordered]@{
            schema_version = '1.0'; run_id = $RunId; checkpoint_id = 'cp'; baseline_ref = $BaselineRef
            diff_hash = 'sha256:x'; reviewed_ref = $ReviewedRef; reviewed_tree_id = $TreeId; status = 'pass'
            created_at = '2026-06-20T00:00:01Z'; updated_at = '2026-06-20T00:00:01Z'
        } | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $dir 'review-run.json') -Encoding UTF8 -NoNewline
    }

    It 'blocks when there is no co-review evidence' {
        $f = New-FeatureRepo 'no-ev'
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should Be 'no-co-review-evidence'
    }

    It 'ALLOWS when the current tree-id matches a pass whose chain reaches the anchor' {
        $f = New-FeatureRepo 'allow'
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head   # baseline = anchor -> chain reaches
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should Be 'allow'
        $d.reason | Should Be 'fresh-and-covered'
    }

    It 'BLOCKS HOLE A: a gitignored-source change makes the tree-id stale' {
        $f = New-FeatureRepo 'hole-a'
        Set-Content -LiteralPath (Join-Path $f.repo '.gitignore') -Value "gen/`n" -Encoding UTF8
        New-Item -ItemType Directory -Path (Join-Path $f.repo 'gen') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $f.repo 'gen/logic.py') -Value 'def s(): pass' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '.gitignore'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'ignore')
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').decision | Should Be 'allow'   # baseline state passes
        Set-Content -LiteralPath (Join-Path $f.repo 'gen/logic.py') -Value 'def s(): evil()' -Encoding UTF8           # gitignored drift
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should Be 'stale-co-review-evidence'
    }

    It 'BLOCKS HOLE B: a pass that does not chain to the anchor is a coverage gap' {
        $f = New-FeatureRepo 'hole-b'
        # Add a SECOND feature commit; the only pass baselines on HEAD~1 (mid-feature), not the anchor.
        $mid = (& git -C $f.repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'feature v1' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'feat2')
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $mid -TreeId $treeId -ReviewedRef $head   # baseline = mid, NOT anchor; no prior run -> gap
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should Be 'block'
        $d.reason | Should Be 'coverage-gap'
    }

    It 'A1: ALLOWS via a MULTI-HOP chain (tip pass -> mid pass -> anchor) with no gap' {
        $f = New-FeatureRepo 'multihop'                       # main(anchor) + feature commit c1
        $c1 = (& git -C $f.repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'feature v1' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'feat2')
        $c2 = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId 'tree-c1' -ReviewedRef $c1   # link: anchor -> c1
        Write-PassRun -Repo $f.repo -RunId 'r2' -BaselineRef $c1 -TreeId $treeId -ReviewedRef $c2           # tip matches current; baseline = c1
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main'
        $d.decision | Should Be 'allow'                        # exercises the recursive chain step (r2.baseline c1 -> r1 -> anchor)
        $d.reason | Should Be 'fresh-and-covered'
        $d.matched_run_id | Should Be 'r2'
    }

    It 'A1: BLOCKS a multi-hop chain with a GAP in the middle (the mid link is missing)' {
        $f = New-FeatureRepo 'multihop-gap'
        $c1 = (& git -C $f.repo rev-parse HEAD).Trim()
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'feature v1' -Encoding UTF8
        Invoke-GateGit $f.repo @('add', '-A'); Invoke-GateGit $f.repo @('commit', '-q', '-m', 'feat2')
        $c2 = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        # The tip pass matches current, but no pass covers anchor->c1, so the chain has a gap.
        Write-PassRun -Repo $f.repo -RunId 'r2' -BaselineRef $c1 -TreeId $treeId -ReviewedRef $c2
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should Be 'coverage-gap'
    }

    It 'blocks stale when the tracked tree drifts after the pass' {
        $f = New-FeatureRepo 'stale'
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head
        Set-Content -LiteralPath (Join-Path $f.repo 'feat.txt') -Value 'drifted' -Encoding UTF8
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main').reason | Should Be 'stale-co-review-evidence'
    }

    It 'blocks when the trunk anchor cannot be resolved (fail-closed)' {
        $f = New-FeatureRepo 'no-trunk'
        $head = (& git -C $f.repo rev-parse HEAD).Trim()
        $treeId = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $f.repo).tree_id
        Write-PassRun -Repo $f.repo -RunId 'r1' -BaselineRef $f.anchor -TreeId $treeId -ReviewedRef $head
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'nonexistent-trunk').reason | Should Be 'anchor-unresolvable'
    }

    It 'allows under a well-formed human-authorized recorded override (and records it)' {
        $f = New-FeatureRepo 'override'
        $override = [pscustomobject]@{ authorized_by = 'alon'; rationale = 'documented partial coverage for a vendored tree' }
        $d = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -OverrideAuthorization $override
        $d.decision | Should Be 'allow'
        $d.reason | Should Be 'human-authorized-partial-override'
        $d.override.authorized_by | Should Be 'alon'
    }

    It 'ignores a malformed override (no rationale) and blocks normally' {
        $f = New-FeatureRepo 'bad-override'
        $override = [pscustomobject]@{ authorized_by = 'alon' }   # no rationale
        (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $f.repo -TrunkName 'main' -OverrideAuthorization $override).reason | Should Be 'no-co-review-evidence'
    }

    It 'Assert throws on a block' {
        $f = New-FeatureRepo 'assert'
        $threw = $false
        try { Assert-ContinuousCoReviewSignoffGate -RepoRoot $f.repo -TrunkName 'main' | Out-Null } catch { $threw = $true }
        $threw | Should Be $true
    }
}
