$ErrorActionPreference = 'Stop'

# Shared trunk resolver (maintainer 2026-07-13): ONE 6-level precedence resolver replacing the duplicated 'main'
# defaults. NEVER creates/renames/moves a branch. These tests exercise each precedence level + the required
# scenarios: local-only master, local-only main, origin/HEAD -> develop, explicit override, ambiguous branches,
# no-commit repository (plus greenfield and precedence ordering).
Describe 'Shared co-review trunk resolver (6-level precedence)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-trunk-resolver.ps1')

        function New-TrunkRepo {
            param([string]$Base = 'main', [string[]]$Extra = @(), [switch]$NoCommit, [switch]$OriginHeadDevelop, [string]$Config)
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            & git -C $repo symbolic-ref HEAD "refs/heads/$Base" 2>&1 | Out-Null
            if ($NoCommit) { return $repo }
            & git -C $repo config user.email 't@e.c' 2>&1 | Out-Null
            & git -C $repo config user.name 'T' 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'f.txt') -Value 'base' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null
            & git -C $repo commit -qm base 2>&1 | Out-Null
            foreach ($b in $Extra) { & git -C $repo branch $b 2>&1 | Out-Null }
            if ($OriginHeadDevelop) {
                $baseCommit = ([string](& git -C $repo rev-parse HEAD)).Trim()
                & git -C $repo update-ref refs/remotes/origin/develop $baseCommit 2>&1 | Out-Null
                & git -C $repo symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop 2>&1 | Out-Null
                & git -C $repo remote add origin 'https://example.invalid/repo.git' 2>&1 | Out-Null
            }
            & git -C $repo checkout -q -b feature 2>&1 | Out-Null
            if ($Config) {
                New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo '.specrew/config.yml') -Value $Config -Encoding UTF8
            }
            return $repo
        }

        # main (base B) + feature (current, commit F on top) where feature TRACKS <Remote>/feature. Creates
        # remote-tracking refs <Remote>/main=B and <Remote>/feature=F. -RemoteHeadMain points <Remote>/HEAD -> main.
        function New-TrackingRepo {
            param([string]$Remote = 'origin', [switch]$RemoteHeadMain)
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            & git -C $repo symbolic-ref HEAD 'refs/heads/main' 2>&1 | Out-Null
            & git -C $repo config user.email 't@e.c' 2>&1 | Out-Null
            & git -C $repo config user.name 'T' 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'base' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null
            & git -C $repo commit -qm base 2>&1 | Out-Null
            $baseCommit = ([string](& git -C $repo rev-parse HEAD)).Trim()
            & git -C $repo checkout -q -b feature 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null
            & git -C $repo commit -qm feat 2>&1 | Out-Null
            $featCommit = ([string](& git -C $repo rev-parse HEAD)).Trim()
            & git -C $repo update-ref "refs/remotes/$Remote/main" $baseCommit 2>&1 | Out-Null
            & git -C $repo update-ref "refs/remotes/$Remote/feature" $featCommit 2>&1 | Out-Null
            & git -C $repo remote add $Remote 'https://example.invalid/repo.git' 2>&1 | Out-Null
            & git -C $repo config 'branch.feature.remote' $Remote 2>&1 | Out-Null
            & git -C $repo config 'branch.feature.merge' 'refs/heads/feature' 2>&1 | Out-Null
            if ($RemoteHeadMain) { & git -C $repo symbolic-ref "refs/remotes/$Remote/HEAD" "refs/remotes/$Remote/main" 2>&1 | Out-Null }
            return @{ repo = $repo; base = $baseCommit; feat = $featCommit }
        }
    }

    It 'local-only master -> master (conventional ref)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'master')
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'master'; $r.source | Should -Be 'conventional-ref'
    }

    It 'local-only main -> main (conventional ref)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'main')
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'main'; $r.source | Should -Be 'conventional-ref'
    }

    It 'origin/HEAD -> develop wins over a local conventional main (precedence 2 > 4)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'main' -OriginHeadDevelop)
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'origin/develop'; $r.source | Should -Be 'origin-head'
    }

    It 'REGRESSION (amended level 3): a branch tracking origin/feature resolves main/origin-main, NEVER origin/feature' {
        # feature tracks origin/feature, origin/HEAD UNSET. The OLD level 3 returned the @{upstream} ref
        # (origin/feature) -> merge-base with itself is empty. The amended level 3 never uses the upstream ref, so
        # this falls through to the conventional 'main'. Either main or origin/main is acceptable; origin/feature is not.
        $t = New-TrackingRepo -Remote 'origin'
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $t.repo
        $r.ok | Should -BeTrue
        $r.trunk_ref | Should -BeIn @('main', 'origin/main')
        $r.trunk_ref | Should -Not -Be 'origin/feature'
    }

    It 'amended level 3: a branch tracking a NON-origin remote resolves THAT remote''s HEAD (tracking-remote-head)' {
        # feature tracks upstream/feature; upstream/HEAD -> upstream/main; no origin. Level 2 (hardcoded origin)
        # skips; level 3 resolves the tracking remote's default branch - proving it generalizes beyond origin.
        $t = New-TrackingRepo -Remote 'upstream' -RemoteHeadMain
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $t.repo
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'upstream/main'; $r.source | Should -Be 'tracking-remote-head'
    }

    It 'explicit co_review_trunk (config) wins over everything, and the -Trunk override wins over config' {
        $repo = New-TrunkRepo -Base 'main' -Extra @('release-1') -Config "co_review_trunk: release-1"
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $repo
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'release-1'; $r.source | Should -Be 'explicit-co_review_trunk'
        # the -Trunk param overrides the config value.
        $r2 = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $repo -Trunk 'main'
        $r2.trunk_ref | Should -Be 'main'; $r2.source | Should -Be 'explicit-co_review_trunk'
    }

    It 'an explicit co_review_trunk that does not resolve FAILS with a config instruction (never guesses)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'main' -Config "co_review_trunk: does-not-exist")
        $r.ok | Should -BeFalse; $r.source | Should -Be 'explicit-trunk-unresolvable'; $r.message | Should -Match 'co_review_trunk'
    }

    It 'ambiguous branches (local-only, multiple non-conventional pre-feature branches) -> FAIL with a config instruction' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'alpha' -Extra @('beta'))
        $r.ok | Should -BeFalse; $r.source | Should -Be 'ambiguous'; $r.message | Should -Match 'co_review_trunk'
    }

    It 'local-only with ONE non-conventional pre-feature branch -> that branch (precedence 5)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -Base 'trunkish')
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -Be 'trunkish'; $r.source | Should -Be 'single-pre-feature-branch'
    }

    It 'no-commit repository -> FAIL (no HEAD)' {
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot (New-TrunkRepo -NoCommit)
        $r.ok | Should -BeFalse; $r.source | Should -Be 'no-commit-repo'; $r.message | Should -Match 'no commits'
    }

    It 'greenfield (only the feature branch, no trunk) -> ok with a null trunk_ref (empty-tree baseline), NOT a failure' {
        # A repo whose ONLY branch is the feature branch (specrew init greenfield).
        $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q 2>&1 | Out-Null
        & git -C $repo symbolic-ref HEAD 'refs/heads/feature' 2>&1 | Out-Null
        & git -C $repo config user.email 't@e.c' 2>&1 | Out-Null
        & git -C $repo config user.name 'T' 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'f.txt') -Value 'base' -NoNewline -Encoding UTF8
        & git -C $repo add -A 2>&1 | Out-Null
        & git -C $repo commit -qm base 2>&1 | Out-Null
        $r = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $repo
        $r.ok | Should -BeTrue; $r.trunk_ref | Should -BeNullOrEmpty; $r.source | Should -Be 'greenfield'
    }

    It 'never creates, renames, or moves a branch (branch set is unchanged after resolution)' {
        $repo = New-TrunkRepo -Base 'alpha' -Extra @('beta')   # an ambiguous repo
        $before = @((& git -C $repo branch --format='%(refname:short)') | ForEach-Object { ([string]$_).Trim() } | Sort-Object)
        $null = Resolve-ContinuousCoReviewTrunkRef -RepoRoot $repo
        $after = @((& git -C $repo branch --format='%(refname:short)') | ForEach-Object { ([string]$_).Trim() } | Sort-Object)
        ($after -join '|') | Should -Be ($before -join '|') -Because 'resolution is read-only; it never mutates the branch set'
    }
}

# Consumer-level contract: the worktree baseline resolver (the fire-path diff baseline) must fail LOUDLY on every
# ok=false resolver result and reserve the empty-tree baseline for the explicit greenfield result ONLY.
Describe 'Worktree baseline consumer (fail-loud on ok=false; empty-tree only for greenfield)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        # Resolve-ContinuousCoReviewWorktreeBaseline lives in the orchestrator (not in _load); it dot-sources the
        # shared trunk resolver itself when needed.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')
        $script:EmptyTree = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'

        function New-BaselineTrackingRepo {
            # main (base B) + feature (F on top) tracking origin/feature; origin/HEAD UNSET.
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            & git -C $repo symbolic-ref HEAD 'refs/heads/main' 2>&1 | Out-Null
            & git -C $repo config user.email 't@e.c' 2>&1 | Out-Null
            & git -C $repo config user.name 'T' 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'base.txt') -Value 'base' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null; & git -C $repo commit -qm base 2>&1 | Out-Null
            $base = ([string](& git -C $repo rev-parse HEAD)).Trim()
            & git -C $repo checkout -q -b feature 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'feat.txt') -Value 'feature' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null; & git -C $repo commit -qm feat 2>&1 | Out-Null
            $feat = ([string](& git -C $repo rev-parse HEAD)).Trim()
            & git -C $repo update-ref 'refs/remotes/origin/main' $base 2>&1 | Out-Null
            & git -C $repo update-ref 'refs/remotes/origin/feature' $feat 2>&1 | Out-Null
            & git -C $repo remote add origin 'https://example.invalid/repo.git' 2>&1 | Out-Null
            & git -C $repo config 'branch.feature.remote' 'origin' 2>&1 | Out-Null
            & git -C $repo config 'branch.feature.merge' 'refs/heads/feature' 2>&1 | Out-Null
            return @{ repo = $repo; base = $base; feat = $feat }
        }
        function New-BaselineSimpleRepo {
            # $Base branch + feature (current). $NoCommit -> no HEAD. $Extra adds ambiguous sibling branches.
            param([string]$Base = 'feature', [string[]]$Extra = @(), [switch]$NoCommit)
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            & git -C $repo symbolic-ref HEAD "refs/heads/$Base" 2>&1 | Out-Null
            if ($NoCommit) { return $repo }
            & git -C $repo config user.email 't@e.c' 2>&1 | Out-Null
            & git -C $repo config user.name 'T' 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'f.txt') -Value 'base' -NoNewline -Encoding UTF8
            & git -C $repo add -A 2>&1 | Out-Null; & git -C $repo commit -qm base 2>&1 | Out-Null
            foreach ($b in $Extra) { & git -C $repo branch $b 2>&1 | Out-Null }
            if ($Base -ne 'feature') { & git -C $repo checkout -q -b feature 2>&1 | Out-Null }
            return $repo
        }
    }

    It 'origin/feature tracking -> NON-EMPTY baseline: the merge-base with main, not HEAD and not empty-tree' {
        $t = New-BaselineTrackingRepo
        $baseline = Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot $t.repo
        $baseline | Should -Be $t.base                      # merge-base with main = the base commit
        $baseline | Should -Not -Be $t.feat                 # NOT HEAD (that would be an empty feature diff)
        $baseline | Should -Not -Be $script:EmptyTree       # NOT the greenfield empty-tree fallback
    }

    It 'greenfield (only the feature branch) -> the empty-tree baseline (the one allowed empty-tree path)' {
        $baseline = Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot (New-BaselineSimpleRepo -Base 'feature')
        $baseline | Should -Be $script:EmptyTree
    }

    It 'ambiguous trunk (ok=false) -> THROWS with a config instruction (never a silent empty-tree)' {
        { Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot (New-BaselineSimpleRepo -Base 'alpha' -Extra @('beta')) } |
            Should -Throw -ExpectedMessage '*co_review_trunk*'
    }

    It 'no-commit repo (ok=false) -> THROWS (never a silent empty-tree)' {
        { Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot (New-BaselineSimpleRepo -NoCommit) } |
            Should -Throw -ExpectedMessage '*no commits*'
    }
}
