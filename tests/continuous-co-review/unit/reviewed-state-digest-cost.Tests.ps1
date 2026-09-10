#requires -Version 7.0
# PRED-BETA4-018: the reviewed-state digest at every material Stop, and what it cost.
#
# Measured on the self-host repo (5,792 tracked paths): 18-37 s per digest - 14 s in a per-path predicate
# loop, 4-9 s in a marker walk that descended into 37,899 scratch files it then discarded - inside a Stop
# hook whose whole budget is 20 s shared by three providers. The conformance provider was killed after
# writing last-fire and before the turn counter, the token consumption and the journal row; the navigator
# was never reached; four unconsumed tokens and a turn id stuck at turn-1 were the visible symptoms.
#
# Three changes, each identity-preserving by construction and proved here on the same tree:
#   1. the denial loop hands a path to the predicate only when its first segment can match a literal or a
#      `<prefix>/**` pattern - and hands EVERY path over when any other wildcard pattern exists;
#   2. the marker walk prunes the volatile roots at the top level instead of discarding afterwards;
#   3. the digest is cached by worktree CONTENT state (HEAD + porcelain listing + size/mtime of each listed
#      file) in the git directory, which is never in a listing or a tree.

Describe 'reviewed-state digest: cheaper, and byte-identical' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewed-state-digest.ps1')

        function New-DigestFixture {
            # A small repo with: source files, a tracked file under a machinery dir, a marker-detected dir, a
            # file whose NAME would match a wildcard pattern, and a `.scratch` copy of everything.
            $root = Join-Path ([IO.Path]::GetTempPath()) ('rsd-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            & git -C $root init --quiet
            & git -C $root config core.autocrlf false
            New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.agents/skills/specrew-x') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.scratch/copy/.agents/skills/specrew-y') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $root 'src/a.ps1'), "Write-Host 'a'`n")
            [IO.File]::WriteAllText((Join-Path $root 'src/notes.tmp'), "scratch notes`n")
            [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), "x: 1`n")
            [IO.File]::WriteAllText((Join-Path $root '.agents/skills/specrew-x/.specrew-managed'), '')
            [IO.File]::WriteAllText((Join-Path $root '.agents/skills/specrew-x/SKILL.md'), "# x`n")
            [IO.File]::WriteAllText((Join-Path $root '.scratch/copy/.agents/skills/specrew-y/.specrew-managed'), '')
            [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/runtime/`n")
            & git -C $root add -A
            & git -C $root -c user.name=T -c user.email=t@x.invalid commit --quiet -m base
            return $root
        }
    }

    It 'prunes the marker walk at the top level and finds the same markers' {
        $root = New-DigestFixture
        try {
            $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $root)
            ($paths -contains '.agents/skills/specrew-x') | Should -BeTrue -Because 'a marked dir outside the pruned roots is machinery'
            ($paths | Where-Object { $_ -like '.scratch/*' }) | Should -BeNullOrEmpty -Because 'a marker under a pruned root was never machinery, before or after the pruned walk'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the cache returns the same tree id as the computation, and a content change invalidates it' {
        $root = New-DigestFixture
        try {
            $first = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
            $first.ok | Should -BeTrue
            $cachePath = Get-ContinuousCoReviewDigestCachePath -RepoRoot $root
            (Test-Path -LiteralPath $cachePath) | Should -BeTrue -Because 'a successful computation is stored'
            $cachePath | Should -BeLike (Join-Path $root '.git*') -Because 'the cache lives in the git directory, where nothing is ever in a listing or a tree'
            @(& git -C $root status --porcelain=v1 --untracked-files=all) | Should -BeNullOrEmpty -Because 'computing and storing the digest must not move the worktree status - the verification runner refuses a mutation, and the key is built from that listing'
            $hit = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
            $hit.tree_id | Should -Be $first.tree_id
            $fresh = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -NoCache
            $fresh.tree_id | Should -Be $first.tree_id -Because 'the cache never answers differently from the computation'
            [IO.File]::WriteAllText((Join-Path $root 'src/a.ps1'), "Write-Host 'changed'`n")
            $changed = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
            $changed.tree_id | Should -Not -Be $first.tree_id -Because 'a modified tracked file is a different reviewable tree'
            [IO.File]::WriteAllText((Join-Path $root 'src/new.ps1'), "new`n")
            $added = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
            $added.tree_id | Should -Not -Be $changed.tree_id -Because 'an untracked non-ignored file is in the identity'
            [IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/anything.json'), '{}')
            $runtimeTouched = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root
            $runtimeTouched.tree_id | Should -Be $added.tree_id -Because 'the runtime dir is outside the identity, so writing there (the cache itself included) does not move it'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a wildcard exclusion that is not a prefix-slash-star-star pattern still strips by name - the prefilter falls back to the full scan' {
        $root = New-DigestFixture
        try {
            $plain = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -NoCache
            $withWildcard = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -NoCache -ExcludedPathPatterns @('*.tmp')
            $withWildcard.ok | Should -BeTrue
            $withWildcard.tree_id | Should -Not -Be $plain.tree_id -Because 'src/notes.tmp is stripped by the wildcard; with the prefilter alone (first segment src is not a deniable prefix) it would have stayed in'
            # And the same exclusion expressed as a prefix pattern strips a different set - the two are not confused.
            $withPrefix = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -NoCache -ExcludedPathPatterns @('src/**')
            $withPrefix.tree_id | Should -Not -Be $withWildcard.tree_id
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
