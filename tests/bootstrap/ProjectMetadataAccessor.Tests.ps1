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

Write-Host 'ProjectMetadataAccessor: all tests passed.' -ForegroundColor Green
