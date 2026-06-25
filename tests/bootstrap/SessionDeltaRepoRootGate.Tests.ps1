$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-6, HIGH). FALSIFICATION floor for "Get-SpecrewSessionDelta scans the
# PARENT repo when the project root is not its own repo root". The temp dir the reviewer ran in lives under a
# HOME that is itself a git worktree, so `git status --untracked-files=all` from a NON-repo-root walks the whole
# parent tree (unbounded -> the hook hangs) AND reports the parent's files as this project's delta. The fix is
# Test-SpecrewIsGitRepoRoot (git rev-parse --show-prefix) is the predicate; iter-007 Fix 2 then changed the
# CALLERS from skip-when-nested to SCAN-SCOPED-when-nested (Get-SpecrewGitScanScope + a `-- .` pathspec + a
# --show-prefix strip), so a project nested in a monorepo gets its OWN subtree delta without ever scanning the
# parent (the prior skip hollowed EnglishIntake's handover). This test pins BOTH the predicate AND the
# scoped-scan behavior with a HERMETIC nested repo.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/ProjectMetadataAccessor.ps1"

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }
function Assert-Equal { param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message) if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repo = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-rrgate-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $repo -Force | Out-Null
$worktree = $repo + '-wt'
try {
    & git -C $repo init -q 2>$null | Out-Null
    Set-Content -LiteralPath (Join-Path $repo 'seed.txt') -Value 'seed' -Encoding UTF8
    & git -C $repo add -A 2>$null | Out-Null
    & git -C $repo -c user.email='t@t' -c user.name='t' commit -q -m init 2>$null | Out-Null

    # An UNCOMMITTED file at the repo root: this is what a nested-dir scan would (wrongly) surface as the
    # nested project's delta if the gate were absent. It is the discriminator below.
    Set-Content -LiteralPath (Join-Path $repo 'dirty-at-root.txt') -Value 'x' -Encoding UTF8
    $nested = Join-Path $repo 'sub/deeper'
    New-Item -ItemType Directory -Path $nested -Force | Out-Null

    # --- Test-SpecrewIsGitRepoRoot: the O(repo-depth), path-normalization-free gate. ---
    Assert-True (Test-SpecrewIsGitRepoRoot -ProjectRoot $repo) 'the repo TOP-LEVEL is recognized as a repo root (empty --show-prefix)'
    Assert-True (-not (Test-SpecrewIsGitRepoRoot -ProjectRoot $nested)) 'a NESTED dir is NOT a repo root (non-empty --show-prefix)'

    # A linked WORKTREE root must ALSO pass the gate (the real Specrew project IS a worktree; the gate must not
    # skip the scan there). git rev-parse --show-prefix returns empty for a worktree root too.
    & git -C $repo worktree add -q -b rrgate-wt $worktree 2>$null | Out-Null
    if (Test-Path -LiteralPath $worktree) {
        Assert-True (Test-SpecrewIsGitRepoRoot -ProjectRoot $worktree) 'a linked WORKTREE root passes the gate (empty --show-prefix, no parent scan)'
    }
    else { Write-Host 'SKIP: worktree-root case (git worktree add unavailable)' -ForegroundColor Yellow }

    # --- iter-007 Fix 2: a NESTED root is now SCANNED, SCOPED to its own subtree (not skipped). A change INSIDE
    # the subtree surfaces, project-relative (the --show-prefix is stripped); the parent's dirty-at-root.txt is
    # scoped OUT (no parent scan); the scan actually RAN (branch populated, unlike the old skip). ---
    Set-Content -LiteralPath (Join-Path $nested 'nested-work.txt') -Value 'work' -Encoding UTF8
    $deltaNested = Get-SpecrewSessionDelta -ProjectRoot $nested
    Assert-True (@($deltaNested.uncommitted_files) -contains 'nested-work.txt') 'NESTED root -> the subtree change surfaces, PROJECT-relative (show-prefix stripped)'
    Assert-True (-not (@($deltaNested.uncommitted_files) -contains 'sub/deeper/nested-work.txt')) 'NESTED root -> the path is NOT repo-root-relative (the prefix was stripped)'
    Assert-True (-not (@($deltaNested.uncommitted_files) -contains 'dirty-at-root.txt')) 'NESTED root -> the PARENT dirty-at-root.txt is scoped OUT (the parent tree is never scanned)'
    Assert-True (-not [string]::IsNullOrWhiteSpace($deltaNested.branch)) 'NESTED root -> the scoped scan RAN (branch populated); the project is no longer skipped'
    Assert-True ($deltaNested.has_uncommitted) 'NESTED root -> has_uncommitted is true (the subtree change was seen)'

    # --- the POSITIVE branch still works: from the repo root the real scan runs and sees dirty-at-root.txt. ---
    $deltaRoot = Get-SpecrewSessionDelta -ProjectRoot $repo
    Assert-True ($deltaRoot.uncommitted_count -ge 1) 'repo ROOT -> the real scan runs and surfaces the uncommitted file'
    Assert-True (@($deltaRoot.uncommitted_files) -contains 'dirty-at-root.txt') 'repo ROOT -> the uncommitted file is named in the delta'
}
finally {
    if (Test-Path -LiteralPath $worktree) { & git -C $repo worktree remove --force $worktree 2>$null | Out-Null }
    Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $worktree -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "`n=== SessionDeltaRepoRootGate.Tests.ps1: all assertions passed ===" -ForegroundColor Green
