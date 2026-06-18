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

# Composed resumability — a bogus feature is never present or resumable (real repo, durable).
$bogus = Get-SpecrewFeatureResumable -ProjectRoot $repoRoot -FeatureRef 'zzz-not-a-feature' -BaseBranch 'main'
Assert-True (-not $bogus.present) 'bogus feature not present'
Assert-True (-not $bogus.resumable) 'bogus feature not resumable'
# The present + UNMERGED-is-resumable path is exercised against the CONTROLLED temp repo below.
# (f184: the real-repo feature this once named, 174-hook-driven-session-bootstrap, has since merged to
# main, so it is no longer a stable "unmerged" fixture — a controlled branch is the durable guard.)

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

    # Composed resumability (durable, controlled repo): a feature branch with work AHEAD of base (unmerged)
    # is present + resumable - the guard the real-repo 174 reference gave before 174 merged. A commit makes
    # the branch genuinely diverge (a fresh `checkout -b` is still an ancestor of main == counts as merged).
    Set-Content -LiteralPath (Join-Path $tmp 'specs/001-pomodoro-cli/work.md') -Value '# wip' -Encoding UTF8
    git -C $tmp add -A 2>$null; git -C $tmp commit -q -m 'feature work (unmerged)' 2>$null
    $activeTmp = Get-SpecrewFeatureResumable -ProjectRoot $tmp -FeatureRef '001-pomodoro-cli' -BaseBranch 'main'
    Assert-True ($activeTmp.present -and $activeTmp.resumable) 'unmerged feature branch (ahead of base) is present + resumable'

    # MULTI-FEATURE SAFETY: specs/001-pomodoro-cli/ still exists on disk, but on branch 999-* the resolver
    # keys on the BRANCH (which has no specs dir) and returns $null - never falsely the other feature. This is
    # exactly why branch-keyed (not a disk scan of specs/) is correct in a multi-feature repo.
    git -C $tmp checkout -q -b '999-deleted-feature' 2>$null
    Assert-True ($null -eq (Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp)) 'feature branch but specs/<branch>/ absent -> $null (branch-keyed, not disk-scan)'

    # Non-feature branch name (no NNN- prefix) -> $null.
    git -C $tmp checkout -q -b 'spike-no-number' 2>$null
    Assert-True ($null -eq (Resolve-SpecrewBranchFeatureRef -ProjectRoot $tmp)) 'non-feature branch name -> $null'

    # --- Get-SpecrewWorkshopProgress: deterministic in-flight disk scan (F-174 T050 round-2) ---
    $fdir = Join-Path $tmp 'specs/001-pomodoro-cli'
    # (a) COPILOT shape: spec + per-lens records + lens-applicability.json (under workshop/) with moved_on flags.
    Set-Content -LiteralPath (Join-Path $fdir 'spec.md') -Value '# spec' -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $fdir 'workshop') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $fdir 'workshop/product-domain.md') -Value '# lens' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $fdir 'workshop/architecture-core.md') -Value '# lens' -Encoding UTF8
    (@{ selected = @('product-domain', 'architecture-core', 'requirements-nfr', 'data-storage')
            workshop = @{ 'product-domain' = @{ moved_on = $true }; 'architecture-core' = @{ moved_on = $true } } } |
        ConvertTo-Json -Depth 5) | Set-Content -LiteralPath (Join-Path $fdir 'workshop/lens-applicability.json') -Encoding UTF8
    $wp = Get-SpecrewWorkshopProgress -ProjectRoot $tmp -FeatureRef '001-pomodoro-cli'
    Assert-True $wp.in_flight 'copilot-shape: feature is in flight'
    Assert-True $wp.spec_exists 'copilot-shape: spec.md detected (the intent)'
    Assert-True (@($wp.done) -contains 'product-domain' -and @($wp.done) -contains 'architecture-core') 'copilot-shape: done lenses from moved_on + records'
    Assert-True (@($wp.remaining)[0] -eq 'requirements-nfr') 'copilot-shape: next remaining lens in selected order'
    # (b) CODEX shape: records on disk but NO lens-applicability.json -> done from files, remaining unknown.
    Remove-Item -LiteralPath (Join-Path $fdir 'workshop/lens-applicability.json') -Force
    $wp2 = Get-SpecrewWorkshopProgress -ProjectRoot $tmp -FeatureRef '001-pomodoro-cli'
    Assert-True ($wp2.in_flight -and @($wp2.done) -contains 'product-domain' -and @($wp2.remaining).Count -eq 0) 'codex-shape: done from lens FILES alone, no remaining claim'
    # (c) clean feature dir (no spec, no records) -> NOT in flight (no false in-flight block).
    New-Item -ItemType Directory -Path (Join-Path $tmp 'specs/002-empty') -Force | Out-Null
    Assert-True (-not (Get-SpecrewWorkshopProgress -ProjectRoot $tmp -FeatureRef '002-empty').in_flight) 'empty feature dir -> not in flight (fail-safe)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'ProjectMetadataAccessor: all tests passed.' -ForegroundColor Green
