# module-path-announce-origin.tests.ps1
#
# Regression pin for the SPECREW_MODULE_PATH honor/announce semantics in Specrew.psm1 (v0.40.0-beta1
# dry-run failure): every module load announces its tree in SPECREW_MODULE_PATH, so a session that
# loads copy A and then imports copy B must NOT treat A's self-announcement as an operator dev-trial
# override - B would silently dispatch A's scripts (the pre-publish harness's candidate ran the
# PSGallery baseline's update and stamped the baseline's stale version; a same-session upgrade would
# keep running the old version). The discriminator is SPECREW_MODULE_PATH_ANNOUNCED, which records
# the EXACT self-announced path (a bare marker flag would also suppress a mid-session operator
# override set AFTER an earlier import - codex P2 on PR #3076):
#
#   1. PATH == ANNOUNCED (stale self-announce)   -> ignored: the import resolves to its OWN tree
#   2. PATH set + ANNOUNCED absent (operator)    -> honored: dev-trial dispatch from the pointed tree
#   3. PATH absent                               -> announce own tree, record it in ANNOUNCED
#   4. PATH != ANNOUNCED (operator changed PATH
#      after an earlier self-announce)           -> honored: the recorded path no longer matches
#
# Each case runs in a fresh pwsh child so module/import state cannot leak between cases.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$stubRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-origin-stub-{0}" -f (Get-Random))
$failures = [System.Collections.ArrayList]::new()

function Write-Result {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    if ($Passed) {
        Write-Host "PASS: $Name" -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "      $Detail" -ForegroundColor Yellow }
        $null = $failures.Add($Name)
    }
}

# Build a minimal tree that passes the psm1's validity check (scripts/specrew.ps1 + Specrew.psd1) and
# survives the dot-source of dashboard-renderer.ps1 when the tree is honored as the dispatch root.
New-Item -ItemType Directory -Force -Path (Join-Path $stubRoot 'scripts\internal') | Out-Null
Set-Content -Path (Join-Path $stubRoot 'scripts\specrew.ps1') -Value '# stub CLI'
Set-Content -Path (Join-Path $stubRoot 'scripts\internal\dashboard-renderer.ps1') -Value '# stub renderer'
Set-Content -Path (Join-Path $stubRoot 'Specrew.psd1') -Value "@{ ModuleVersion = '0.0.1' }"
$stubRoot = (Resolve-Path -LiteralPath $stubRoot).Path

# Each probe imports the REAL repo psm1 with a controlled env seed, then reports the resulting env pair.
$probe = @'
param([string]$RepoRoot, [string]$SeedPath, [string]$SeedAnnounced)
if ([string]::IsNullOrWhiteSpace($SeedPath)) { $env:SPECREW_MODULE_PATH = $null } else { $env:SPECREW_MODULE_PATH = $SeedPath }
if ([string]::IsNullOrWhiteSpace($SeedAnnounced)) { $env:SPECREW_MODULE_PATH_ANNOUNCED = $null } else { $env:SPECREW_MODULE_PATH_ANNOUNCED = $SeedAnnounced }
Import-Module (Join-Path $RepoRoot 'Specrew.psm1') -Force
Write-Output ("RESULT|{0}|{1}" -f $env:SPECREW_MODULE_PATH, $env:SPECREW_MODULE_PATH_ANNOUNCED)
'@
$probePath = Join-Path $stubRoot 'probe.ps1'
Set-Content -Path $probePath -Value $probe

function Invoke-Probe {
    param([string]$SeedPath, [string]$SeedAnnounced)
    $out = & pwsh -NoProfile -File $probePath -RepoRoot $repoRoot -SeedPath $SeedPath -SeedAnnounced $SeedAnnounced 2>&1
    $line = @($out | Where-Object { "$_" -like 'RESULT|*' })[0]
    if (-not $line) {
        throw "probe produced no RESULT line. Output:`n$($out -join [Environment]::NewLine)"
    }
    $parts = "$line".Split('|')
    return [pscustomobject]@{ Path = $parts[1]; Announced = $parts[2] }
}

try {
    # Case 1: a stale self-announce (PATH == ANNOUNCED) must be ignored - the import wins with its
    # own tree and records its own announcement.
    $r1 = Invoke-Probe -SeedPath $stubRoot -SeedAnnounced $stubRoot
    Write-Result 'self-announced path is ignored (import resolves to its own tree)' `
        ($r1.Path -eq $repoRoot) "expected PATH=$repoRoot, got '$($r1.Path)'"
    Write-Result 'self-resolution records its own announcement' `
        ($r1.Announced -eq $repoRoot) "got ANNOUNCED='$($r1.Announced)'"

    # Case 2: an operator-set (unrecorded) path is a deliberate dev trial - honored, and left
    # unrecorded so nested module loads keep honoring it.
    $r2 = Invoke-Probe -SeedPath $stubRoot -SeedAnnounced ''
    Write-Result 'operator-set path is honored (dev-trial dispatch)' `
        ($r2.Path -eq $stubRoot) "expected PATH=$stubRoot, got '$($r2.Path)'"
    Write-Result 'honored override stays unrecorded for nested loads' `
        ([string]::IsNullOrEmpty($r2.Announced)) "got ANNOUNCED='$($r2.Announced)'"

    # Case 3: clean session - announce own tree and record the announcement.
    $r3 = Invoke-Probe -SeedPath '' -SeedAnnounced ''
    Write-Result 'clean session announces own tree' `
        ($r3.Path -eq $repoRoot) "expected PATH=$repoRoot, got '$($r3.Path)'"
    Write-Result 'clean-session announce is recorded in ANNOUNCED' `
        ($r3.Announced -eq $repoRoot) "got ANNOUNCED='$($r3.Announced)'"

    # Case 4 (codex P2, PR #3076): the operator changes SPECREW_MODULE_PATH to a different tree AFTER
    # an earlier import self-announced - the stale record names a DIFFERENT path, so the new path is a
    # genuine operator override and must be honored.
    $r4 = Invoke-Probe -SeedPath $stubRoot -SeedAnnounced $repoRoot
    Write-Result 'operator path set after an earlier self-announce is honored' `
        ($r4.Path -eq $stubRoot) "expected PATH=$stubRoot, got '$($r4.Path)'"
    Write-Result 'honored mid-session override clears the stale announcement record' `
        ([string]::IsNullOrEmpty($r4.Announced)) "got ANNOUNCED='$($r4.Announced)'"
}
finally {
    Remove-Item -LiteralPath $stubRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host ("=== module-path-announce-origin.tests.ps1: {0} FAILURE(S) ===" -f $failures.Count) -ForegroundColor Red
    exit 1
}

Write-Host '=== module-path-announce-origin.tests.ps1: all assertions passed ===' -ForegroundColor Green
exit 0
