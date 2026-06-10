$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/ProjectMetadataAccessor.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

# Project-local presence.
Assert-True (Test-SpecrewFeatureLocal -SpecsRoot (Join-Path $repoRoot 'specs') -FeatureRef '174-hook-driven-session-bootstrap') 'active feature dir is present'
Assert-True (-not (Test-SpecrewFeatureLocal -SpecsRoot (Join-Path $repoRoot 'specs') -FeatureRef 'zzz-not-a-feature')) 'bogus feature dir is absent'

# Git merged-status (against the real repo).
Assert-True (Test-SpecrewBranchMergedToBase -RepoRoot $repoRoot -Branch 'HEAD' -BaseBranch 'HEAD') 'HEAD is an ancestor of HEAD (merged)'
Assert-True (-not (Test-SpecrewBranchMergedToBase -RepoRoot $repoRoot -Branch 'no-such-branch-zzz' -BaseBranch 'HEAD')) 'missing branch fails safe to not-merged'

# Composed resumability.
$active = Get-SpecrewFeatureResumable -ProjectRoot $repoRoot -FeatureRef '174-hook-driven-session-bootstrap' -BaseBranch 'main'
Assert-True $active.present 'active feature resolves present'
Assert-True $active.resumable 'active unmerged feature is resumable'

$bogus = Get-SpecrewFeatureResumable -ProjectRoot $repoRoot -FeatureRef 'zzz-not-a-feature' -BaseBranch 'main'
Assert-True (-not $bogus.present) 'bogus feature not present'
Assert-True (-not $bogus.resumable) 'bogus feature not resumable'

# --- Resolve-SpecrewBranchFeatureRef: branch-keyed feature for the pre-specify workshop window (F-174 T050) ---
# A controlled temp repo so we can check out arbitrary branches (the real repo's branch is fixed).
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-branchfeat-" + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $tmp | Out-Null
    git -C $tmp init -q -b main 2>$null
    git -C $tmp config user.email 't@t'; git -C $tmp config user.name 't'
    New-Item -ItemType Directory -Path (Join-Path $tmp 'specs/001-pomodoro-cli') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $tmp 'specs/001-pomodoro-cli/spec.md') -Value '# spec' -Encoding UTF8
    git -C $tmp add -A 2>$null; git -C $tmp commit -q -m init 2>$null

    # On main: not a feature branch -> $null (no bogus stamp; the closed-feature-then-back-on-main case).
    Assert-True ($null -eq (Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp)) 'on main -> no branch feature (fail-safe)'

    # On the feature branch with specs/<branch>/ present -> resolves the feature (the workshop window).
    git -C $tmp checkout -q -b '001-pomodoro-cli' 2>$null
    Assert-True ((Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp) -eq '001-pomodoro-cli') 'feature branch + specs dir present -> resolves the feature'

    # MULTI-FEATURE SAFETY: specs/001-pomodoro-cli/ still exists on disk, but on branch 999-* the resolver
    # keys on the BRANCH (which has no specs dir) and returns $null - never falsely the other feature. This is
    # exactly why branch-keyed (not a disk scan of specs/) is correct in a multi-feature repo.
    git -C $tmp checkout -q -b '999-deleted-feature' 2>$null
    Assert-True ($null -eq (Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp)) 'feature branch but specs/<branch>/ absent -> $null (branch-keyed, not disk-scan)'

    # Non-feature branch name (no NNN- prefix) -> $null.
    git -C $tmp checkout -q -b 'spike-no-number' 2>$null
    Assert-True ($null -eq (Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp)) 'non-feature branch name -> $null'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'ProjectMetadataAccessor: all tests passed.' -ForegroundColor Green
