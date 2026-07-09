# module-path-announce-origin.tests.ps1
#
# Regression pin for the SPECREW_MODULE_PATH honor/announce semantics in Specrew.psm1 (v0.40.0-beta1
# dry-run failure): every module load announces its tree in SPECREW_MODULE_PATH, so a session that
# loads copy A and then imports copy B must NOT treat A's self-announcement as an operator dev-trial
# override - B would silently dispatch A's scripts (the pre-publish harness's candidate ran the
# PSGallery baseline's update and stamped the baseline's stale version; a same-session upgrade would
# keep running the old version). The discriminator is SPECREW_MODULE_PATH_ORIGIN:
#
#   1. PATH set + ORIGIN='module-announce'  -> ignored: the import resolves to its OWN tree
#   2. PATH set + ORIGIN absent (operator)  -> honored: dev-trial dispatch from the pointed tree
#   3. PATH absent                          -> announce own tree and mark ORIGIN='module-announce'
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

# Each probe imports the REAL repo psm1 with a controlled env seed, then reports the resulting env pair.
$probe = @'
param([string]$RepoRoot, [string]$SeedPath, [string]$SeedOrigin)
if ([string]::IsNullOrWhiteSpace($SeedPath)) { $env:SPECREW_MODULE_PATH = $null } else { $env:SPECREW_MODULE_PATH = $SeedPath }
if ([string]::IsNullOrWhiteSpace($SeedOrigin)) { $env:SPECREW_MODULE_PATH_ORIGIN = $null } else { $env:SPECREW_MODULE_PATH_ORIGIN = $SeedOrigin }
Import-Module (Join-Path $RepoRoot 'Specrew.psm1') -Force
Write-Output ("RESULT|{0}|{1}" -f $env:SPECREW_MODULE_PATH, $env:SPECREW_MODULE_PATH_ORIGIN)
'@
$probePath = Join-Path $stubRoot 'probe.ps1'
Set-Content -Path $probePath -Value $probe

function Invoke-Probe {
    param([string]$SeedPath, [string]$SeedOrigin)
    $out = & pwsh -NoProfile -File $probePath -RepoRoot $repoRoot -SeedPath $SeedPath -SeedOrigin $SeedOrigin 2>&1
    $line = @($out | Where-Object { "$_" -like 'RESULT|*' })[0]
    if (-not $line) {
        throw "probe produced no RESULT line. Output:`n$($out -join [Environment]::NewLine)"
    }
    $parts = "$line".Split('|')
    return [pscustomobject]@{ Path = $parts[1]; Origin = $parts[2] }
}

try {
    # Case 1: a stale module announce must be ignored - the import wins with its own tree and re-marks.
    $r1 = Invoke-Probe -SeedPath $stubRoot -SeedOrigin 'module-announce'
    Write-Result 'module-announced path is ignored (import resolves to its own tree)' `
        ($r1.Path -eq $repoRoot) "expected PATH=$repoRoot, got '$($r1.Path)'"
    Write-Result 'self-resolution re-marks ORIGIN=module-announce' `
        ($r1.Origin -eq 'module-announce') "got ORIGIN='$($r1.Origin)'"

    # Case 2: an operator-set (unmarked) path is a deliberate dev trial - honored, and left unmarked so
    # nested module loads keep honoring it.
    $r2 = Invoke-Probe -SeedPath $stubRoot -SeedOrigin ''
    Write-Result 'operator-set path is honored (dev-trial dispatch)' `
        ($r2.Path -eq $stubRoot) "expected PATH=$stubRoot, got '$($r2.Path)'"
    Write-Result 'honored override stays unmarked for nested loads' `
        ([string]::IsNullOrEmpty($r2.Origin)) "got ORIGIN='$($r2.Origin)'"

    # Case 3: clean session - announce own tree and mark the announcement.
    $r3 = Invoke-Probe -SeedPath '' -SeedOrigin ''
    Write-Result 'clean session announces own tree' `
        ($r3.Path -eq $repoRoot) "expected PATH=$repoRoot, got '$($r3.Path)'"
    Write-Result 'clean-session announce is marked ORIGIN=module-announce' `
        ($r3.Origin -eq 'module-announce') "got ORIGIN='$($r3.Origin)'"
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
