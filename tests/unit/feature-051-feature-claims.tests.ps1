[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 051 Iteration 2a (US4) acceptance tests — feature claims.
# Plain-PowerShell convention; real temp files, no mocks (Shape-6).
# Covers: T027 read/write (reuse shared atomic-write), T028 Add (upsert@specify),
# T029 Update (monotonic refresh, SC-008), T031 Remove (@closeout), T030 conflict detection,
# corrupt-YAML safe-degradation, and the claim half of the T026b race reconciliation (FR-014 re-add).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m; exit 1 } Write-Pass $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mod = Join-Path $repoRoot 'scripts/internal/feature-claims.ps1'
Assert-True (Test-Path -LiteralPath $mod) "feature-claims.ps1 exists at $mod"
. $mod

function New-TempProject {
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-f051-fc-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path (Join-Path $d '.squad') -Force | Out-Null
    return $d
}
function Get-ClaimsPath { param($root) Join-Path $root '.squad/active-features.yml' }

# --- T028: Add claim (upsert by feature_id) ---
$p = New-TempProject
try {
    Add-FeatureClaim -ProjectRoot $p -FeatureId '051-x' -ClaimedBy 'alon@HOST-A' -BranchName '051-x' -NowUtc '2026-05-31T06:00:00Z'
    $claims = @(Read-FeatureClaims -ProjectRoot $p)
    Assert-True ($claims.Count -eq 1) "T028: one claim after add (got $($claims.Count))"
    Assert-True ($claims[0].feature_id -eq '051-x' -and $claims[0].claimed_by -eq 'alon@HOST-A') "T028: claim fields persisted (feature_id, claimed_by)"
    Assert-True ($claims[0].branch_name -eq '051-x') "T028: branch_name persisted"
    # Upsert: re-add same feature does not duplicate
    Add-FeatureClaim -ProjectRoot $p -FeatureId '051-x' -ClaimedBy 'alon@HOST-A' -BranchName '051-x' -NowUtc '2026-05-31T06:30:00Z'
    Assert-True ((@(Read-FeatureClaims -ProjectRoot $p)).Count -eq 1) "T028: re-add same feature is upsert (no duplicate)"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T029: Update refresh (monotonic, SC-008) ---
$p = New-TempProject
try {
    Add-FeatureClaim -ProjectRoot $p -FeatureId '051-y' -ClaimedBy 'alon@HOST-A' -BranchName '051-y' -NowUtc '2026-05-31T06:00:00Z'
    Update-FeatureClaim -ProjectRoot $p -FeatureId '051-y' -NowUtc '2026-05-31T07:00:00Z'
    $c = @(Read-FeatureClaims -ProjectRoot $p)[0]
    Assert-True ($c.last_refresh_time -eq '2026-05-31T07:00:00Z') "T029: last_refresh_time advanced (SC-008)"
    # Monotonic: an earlier refresh does not move it backward
    Update-FeatureClaim -ProjectRoot $p -FeatureId '051-y' -NowUtc '2026-05-31T05:00:00Z'
    $c = @(Read-FeatureClaims -ProjectRoot $p)[0]
    Assert-True ($c.last_refresh_time -eq '2026-05-31T07:00:00Z') "T029: refresh is monotonic (no backward move)"
    # Update of an active claim re-adds it if missing (Edge Case / FR-014 reconciliation)
    Write-FeatureClaims -ProjectRoot $p -Claims @()
    Update-FeatureClaim -ProjectRoot $p -FeatureId '051-y' -ClaimedBy 'alon@HOST-A' -BranchName '051-y' -NowUtc '2026-05-31T08:00:00Z'
    Assert-True ((@(Read-FeatureClaims -ProjectRoot $p)).Count -eq 1) "T029/FR-014: update re-adds a missing-but-active claim (manual-removal Edge Case)"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T030: concurrent-claim conflict detection (FR-015) ---
$p = New-TempProject
try {
    Add-FeatureClaim -ProjectRoot $p -FeatureId '051-z' -ClaimedBy 'alon@HOST-A' -BranchName '051-z' -NowUtc '2026-05-31T06:00:00Z'
    $conf = Test-FeatureClaimConflict -ProjectRoot $p -FeatureId '051-z' -ClaimedBy 'bob@HOST-B'
    Assert-True ($null -ne $conf -and $conf.claimed_by -eq 'alon@HOST-A') "T030: conflict detected for a feature claimed by another developer"
    $none = Test-FeatureClaimConflict -ProjectRoot $p -FeatureId '051-z' -ClaimedBy 'alon@HOST-A'
    Assert-True ($null -eq $none) "T030: no conflict for the same claimant"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T031: Remove claim (@closeout) ---
$p = New-TempProject
try {
    Add-FeatureClaim -ProjectRoot $p -FeatureId '051-r' -ClaimedBy 'alon@HOST-A' -BranchName '051-r' -NowUtc '2026-05-31T06:00:00Z'
    Remove-FeatureClaim -ProjectRoot $p -FeatureId '051-r'
    Assert-True ((@(Read-FeatureClaims -ProjectRoot $p)).Count -eq 0) "T031: claim removed"
    Remove-FeatureClaim -ProjectRoot $p -FeatureId 'absent'  # no-op
    Assert-True $true "T031: remove of absent claim is a no-op success"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- corrupt-YAML safe-degradation ---
$p = New-TempProject
try {
    Set-Content -LiteralPath (Get-ClaimsPath $p) -Value "::: garbage :::`n  - nope" -Encoding UTF8
    Assert-True ((@(Read-FeatureClaims -ProjectRoot $p)).Count -eq 0) "corrupt active-features.yml degrades to empty (no crash)"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "All Feature-051 feature-claims (US4) acceptance tests passed." -ForegroundColor Green
exit 0
