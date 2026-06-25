$ErrorActionPreference = 'Stop'

# Trace: iter-007 real-host dogfood fix (the navigator-never-fired root cause).
#
# New-SpecrewIsolatedTaskWorktree materializes the reviewed tree via `git archive --output <tar>` +
# `tar -xf`. On Windows, bare `tar` on PATH is almost always Git-for-Windows' MSYS tar
# (C:\Program Files\Git\usr\bin\tar.exe), which parses the absolute archive path `C:\...\<id>.tar` as
# an rcp-style REMOTE host:path ("tar: Cannot connect to C: resolve failed", exit 128) and CANNOT
# extract. That is the exact reason the navigator reached FIRE but never materialized the review
# worktree on the real host (it surfaced as `fire-failed: tar extract failed ... exit 128` -> no-op,
# and as 12 navigator + 2 launcher unit failures sharing this one root cause). The fix pins Windows to
# System32 bsdtar (handles C:\ natively); Unix is unchanged (bare tar).
#
# This test is HERMETIC (synchronous git archive + tar extract, no process spawn): it materializes a
# real tree-id into an ABSOLUTE path under TEMP (on Windows that is a C:\ path - the trap) and asserts
# the content actually extracted. It FAILS before the fix on any Git-for-Windows machine (exit 128)
# and PASSES after.
#
# Harness: run in a fresh pwsh with $env:TEMP/$env:TMP -> <repo>\.scratch\tmp and
# $env:SPECREW_MODULE_PATH=(Get-Location).Path. git identity is per-invocation (`git -c user.*`) in a
# TEMP repo only - never against the Specrew repo.

Describe 'iter-007 worktree materialize uses a tar that handles absolute Windows paths (navigator-fire root cause)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')

        function script:New-TempTreeIdRepo {
            param([Parameter(Mandatory)][string]$MarkerContent)
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('wtmat-src-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'MARKER.txt') -Value $MarkerContent -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='wtmat' -c user.email='wtmat@test.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='wtmat' -c user.email='wtmat@test.local' commit -q -m 'seed' 2>&1 | Out-Null
            $tree = (& git -C $repo rev-parse 'HEAD^{tree}').Trim()
            return [pscustomobject]@{ Repo = $repo; TreeId = $tree }
        }
    }

    It 'materializes the tree content into an absolute (C:\ on Windows) ephemeral path - the MSYS-tar trap' {
        $marker = 'materialize-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $src = script:New-TempTreeIdRepo -MarkerContent $marker
        # An ABSOLUTE ephemeral root (under TEMP). On Windows this is a C:\... path, which is precisely
        # what MSYS tar misreads as a remote host:path. System32 bsdtar handles it.
        $ephemeral = Join-Path ([System.IO.Path]::GetTempPath()) ('wtmat-eph-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $ephemeral -Force | Out-Null
        try {
            # Before the fix this THROWS "tar extract failed ... (exit 128)"; after, it returns the worktree.
            $worktree = New-SpecrewIsolatedTaskWorktree -RepoRoot $src.Repo -TreeId $src.TreeId -EphemeralRoot $ephemeral
            $worktree | Should Not BeNullOrEmpty
            Test-Path -LiteralPath $worktree -PathType Container | Should Be $true
            $markerPath = Join-Path $worktree 'MARKER.txt'
            Test-Path -LiteralPath $markerPath -PathType Leaf | Should Be $true
            (Get-Content -LiteralPath $markerPath -Raw).Trim() | Should Be $marker
        }
        finally {
            Remove-Item -LiteralPath $ephemeral -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
