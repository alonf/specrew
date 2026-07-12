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

    It 'REFUSES an EphemeralRoot JUNCTION whose target is inside origin (symlink/junction escape, finding 3b5ae645)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $origin = script:New-OriginRepo
        $link = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-jn-' + [guid]::NewGuid().ToString('N'))
        try {
            $insideTarget = Join-Path $origin 'nested-target'
            New-Item -ItemType Directory -Path $insideTarget -Force | Out-Null
            # The link path is LEXICALLY outside origin, but its TARGET is inside origin - the lexical-only
            # check passed it, then materialization would physically create the worktree under origin.
            New-Item -ItemType Junction -Path $link -Target $insideTarget | Out-Null
            { New-ContinuousCoReviewStrippedWorktree -RepoRoot $origin -BaselineRef 'HEAD' -EphemeralRoot $link } |
                Should -Throw -ExpectedMessage '*containment*'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }   # remove the junction, not its target contents
            Remove-Item -LiteralPath $origin -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'shared physical-path canonicalizer (Get-ContinuousCoReviewPhysicalPath) - the ONE primitive for T013 + strict design-context (co-review 44760c20)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'follows an INTERMEDIATE directory junction to its real target (physical path leaves the lexical base)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $base = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-base-' + [guid]::NewGuid().ToString('N'))
        $outside = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-out-' + [guid]::NewGuid().ToString('N'))
        $link = Join-Path $base 'link'
        try {
            New-Item -ItemType Directory -Path $base -Force | Out-Null
            New-Item -ItemType Directory -Path $outside -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $outside 'f.txt') -Value 'x' -Encoding UTF8
            New-Item -ItemType Junction -Path $link -Target $outside | Out-Null
            $real = Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $link 'f.txt')
            $baseReal = Get-ContinuousCoReviewPhysicalPath -Path $base
            $outsideReal = Get-ContinuousCoReviewPhysicalPath -Path $outside
            $real | Should -Be (Join-Path $outsideReal 'f.txt') -Because 'the intermediate junction is followed to the real physical target, not the lexical alias'
            $real.StartsWith($baseReal + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) | Should -Be $false -Because 'the resolved physical path is NOT under the lexical base'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }
            Remove-Item -LiteralPath $base, $outside -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'an IN-scope junction to a target UNDER the root stays under the root (documented policy: in-scope links pass)' {
        if (-not $IsWindows) { Set-ItResult -Skipped -Because 'directory-junction creation is Windows-specific'; return }
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-root-' + [guid]::NewGuid().ToString('N'))
        $link = Join-Path $root 'link'
        try {
            New-Item -ItemType Directory -Path (Join-Path $root 'real') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'real/f.txt') -Value 'x' -Encoding UTF8
            New-Item -ItemType Junction -Path $link -Target (Join-Path $root 'real') | Out-Null
            $real = Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $link 'f.txt')
            $rootReal = Get-ContinuousCoReviewPhysicalPath -Path $root
            $real.StartsWith($rootReal + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) | Should -Be $true -Because 'a link whose physical target is under the root stays under the root - allowed'
        }
        finally {
            if (Test-Path -LiteralPath $link) { try { [System.IO.Directory]::Delete($link) } catch { $null = $_ } }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'resolves a plain (link-free) existing path to its normalized physical path' {
        $d = Join-Path ([System.IO.Path]::GetTempPath()) ('pp-plain-' + [guid]::NewGuid().ToString('N'))
        try {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $d 'f.txt') -Value 'x' -Encoding UTF8
            (Get-ContinuousCoReviewPhysicalPath -Path (Join-Path $d 'f.txt')) | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $d 'f.txt')).TrimEnd([char]'\', [char]'/'))
        }
        finally { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
