$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Proposal-145 review fix (iter-007, 2026-06-26): subtree-scoping the REVIEW change-set diff (un-deferred).
# The change-set builder ran git from the governance-root cwd; on a NESTED project (governance root is a
# SUBDIR of a larger git repo) that produced a HOLLOW review: (1) unscoped `--name-only` returned the WHOLE
# repo's divergence, and (2) the batched `git diff -- <repo-root-relative paths>` run from the subdir
# reinterpreted them as subdir-relative pathspecs -> they missed, so the reviewer got ~1 coincidental file
# of the real change-set (none of the actual work). The fix runs git from the TOPLEVEL, scoped to the
# subtree prefix, with consistent repo-root-relative paths. This pins it: a nested project's change-set
# contains the SUBDIR changes (repo-root-relative), with the PARENT changes scoped OUT, and real diff
# content (not hollow). Fails before the fix (whole-repo OR ~1-file); passes after. Own-repo projects
# (empty prefix) are exercised green by the navigator + reviewed-state-digest suites.

function Assert-True { param([bool]$c, [string]$m) if (-not $c) { throw "FAIL: $m" } ; Write-Host "PASS: $m" -ForegroundColor Green }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/_load.ps1')

$top = Join-Path ([System.IO.Path]::GetTempPath()) ('cdsub-' + [guid]::NewGuid().ToString('N'))
$sub = Join-Path $top 'sub'
$u = [System.Text.UTF8Encoding]::new($false)
try {
    $null = New-Item -ItemType Directory -Path (Join-Path $sub 'src'), (Join-Path $top '.github') -Force
    & git -C $top init -q 2>&1 | Out-Null
    & git -C $top branch -m main 2>&1 | Out-Null
    # --- baseline ---
    [System.IO.File]::WriteAllText((Join-Path $top 'parent.txt'), 'p1', $u)               # PARENT file (outside the subtree)
    [System.IO.File]::WriteAllText((Join-Path $top '.github\at-both.md'), 'r1', $u)         # exists at the repo-root path...
    [System.IO.File]::WriteAllText((Join-Path $sub 'src\app.cs'), 'a1', $u)
    $null = New-Item -ItemType Directory -Path (Join-Path $sub '.github') -Force
    [System.IO.File]::WriteAllText((Join-Path $sub '.github\at-both.md'), 's1', $u)         # ...AND at the subdir path (the old coincidental match)
    & git -C $top -c user.name='t' -c user.email='t@t' add -A 2>&1 | Out-Null
    & git -C $top -c user.name='t' -c user.email='t@t' commit -q -m base 2>&1 | Out-Null
    # --- change: parent (must be EXCLUDED) + subdir (must be INCLUDED) ---
    [System.IO.File]::WriteAllText((Join-Path $top 'parent.txt'), 'p2-CHANGED', $u)
    [System.IO.File]::WriteAllText((Join-Path $top '.github\at-both.md'), 'r2-CHANGED', $u)
    [System.IO.File]::WriteAllText((Join-Path $sub 'src\app.cs'), 'a2-CHANGED', $u)
    [System.IO.File]::WriteAllText((Join-Path $sub 'src\new.cs'), 'n1-NEW', $u)
    [System.IO.File]::WriteAllText((Join-Path $sub '.github\at-both.md'), 's2-CHANGED', $u)   # the SUBDIR copy of the both-levels file IS changed
    & git -C $top -c user.name='t' -c user.email='t@t' add -A 2>&1 | Out-Null
    & git -C $top -c user.name='t' -c user.email='t@t' commit -q -m change 2>&1 | Out-Null
    $base = (& git -C $top rev-parse 'HEAD~1').Trim()

    # Compute the change-set with RepoRoot = the NESTED governance subdir (the broken case).
    $cs = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $sub -BaselineRef $base -CheckpointId t -RunId t
    Assert-True ($cs.status -eq 'reviewable') 'nested: the change-set is reviewable (not skipped/hollow)'
    $paths = @($cs.changed_paths)
    Assert-True ($paths -contains 'sub/src/app.cs') 'nested: the subdir change is present, REPO-ROOT-relative (sub/src/app.cs)'
    Assert-True ($paths -contains 'sub/src/new.cs') 'nested: the new subdir file is present'
    Assert-True ($paths -contains 'sub/.github/at-both.md') 'nested: the subdir copy of the both-levels file is present'
    Assert-True (-not ($paths -contains 'parent.txt')) 'nested: the PARENT change is scoped OUT (subtree-scoped, not whole-repo)'
    Assert-True (-not ($paths -contains '.github/at-both.md')) "nested: the PARENT copy of the both-levels file is NOT in scope (no coincidental whole-repo match)"
    Assert-True ($paths.Count -eq 3) ("nested: exactly the 3 SUBDIR changes (was the whole repo OR ~1 coincidental file before the fix); got " + $paths.Count)
    $headers = @($cs.diff_inline -split "`n" | Where-Object { $_ -match '^diff --git' })
    Assert-True ($headers.Count -eq 3) ("nested: diff_inline carries 3 REAL diffs (not a hollow/coincidental diff); got " + $headers.Count)

    Write-Host "`n=== checkpoint-diff-subtree-scope.tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $top -Recurse -Force -ErrorAction SilentlyContinue }
