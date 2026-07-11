$ErrorActionPreference = 'Stop'

# FR-008 (203 W1) / SC-002 — reviewer worktree containment (F-198 iteration 003, T013):
# the stripped reviewer worktree MUST materialize OUTSIDE the origin root so no upward
# directory/git walk from inside the confined worktree can resolve the real project. Paired:
# the default (temp) path materializes outside origin; an EphemeralRoot inside origin is REFUSED.
Describe 'reviewer worktree containment (FR-008 / SC-002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        # _load.ps1 brings the shared leaf modules (Invoke-ContinuousCoReviewGit etc.); the
        # orchestrator dot-sources worktree-reviewer.ps1 which DEFINES New-ContinuousCoReviewStrippedWorktree.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

        function script:New-OriginRepo {
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-origin-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'origin content' -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='ccr' -c user.email='ccr@test.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='ccr' -c user.email='ccr@test.local' commit -q -m 'seed' 2>&1 | Out-Null
            return $repo
        }
    }

    It 'materializes OUTSIDE the origin root and no upward git-walk resolves origin' {
        $origin = script:New-OriginRepo
        try {
            $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD'
            $wt.worktree_path | Should -Not -BeNullOrEmpty
            $originFull = [System.IO.Path]::GetFullPath($origin).TrimEnd([char]'\', [char]'/')
            $wtFull = [System.IO.Path]::GetFullPath($wt.worktree_path).TrimEnd([char]'\', [char]'/')
            $wtFull.StartsWith($originFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) |
                Should -Be $false -Because 'the confined worktree must live outside origin'
            # Upward git-walk from inside the worktree must NOT resolve the origin repo.
            $top = (& git -C $wt.worktree_path rev-parse --show-toplevel 2>$null)
            if ($top) {
                ([System.IO.Path]::GetFullPath($top.Trim()).TrimEnd([char]'\', [char]'/')) |
                    Should -Not -Be $originFull -Because 'no upward walk may resolve origin'
            }
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REFUSES to materialize inside the origin root (containment guard, paired abuse)' {
        $origin = script:New-OriginRepo
        try {
            $inside = Join-Path $origin 'nested-eph'
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $inside } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'REFUSES an EphemeralRoot that IS the origin root itself' {
        $origin = script:New-OriginRepo
        try {
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $origin } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally { Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
