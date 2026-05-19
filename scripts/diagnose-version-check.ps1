#!/usr/bin/env pwsh
# Diagnostic for Linux Get-SpecrewInstalledVersion regression.
# Run from any directory: pwsh /path/to/specrew/scripts/diagnose-version-check.ps1
# Or from a downstream project:
#   pwsh ~/projects/specrew/scripts/diagnose-version-check.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'  # Show ALL errors, don't swallow.

Write-Host "=== Specrew version-check diagnostic ==="
Write-Host "OS:             $($PSVersionTable.OS)"
Write-Host "PSVersion:      $($PSVersionTable.PSVersion)"
Write-Host "PWD:            $(Get-Location)"
Write-Host "PSScriptRoot:   '$PSScriptRoot'"
Write-Host ""

$repoRoot = Split-Path -Parent $PSScriptRoot
Write-Host "computed repoRoot:  '$repoRoot'"

$versionCheckHelperPath = Join-Path $PSScriptRoot 'internal/version-check.ps1'
Write-Host "version-check path: '$versionCheckHelperPath'"
Write-Host "exists?             $(Test-Path -LiteralPath $versionCheckHelperPath -PathType Leaf)"
Write-Host ""

. $versionCheckHelperPath

Write-Host "--- Step 1: Get-Module -ListAvailable -Name Specrew ---"
try {
    $mods = @(Get-Module -Name Specrew -ListAvailable -ErrorAction SilentlyContinue)
    Write-Host "module count: $($mods.Count)"
    foreach ($m in $mods) {
        Write-Host "  Version: $($m.Version) | Path: $($m.ModuleBase)"
    }
}
catch {
    Write-Host "  THREW: $($_.Exception.Message)"
}
Write-Host ""

Write-Host "--- Step 2: manifest candidates ---"
$manifestA = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Specrew.psd1'
Write-Host "  candidate A: '$manifestA'"
Write-Host "  exists?       $(Test-Path -LiteralPath $manifestA -PathType Leaf)"

$repoManifest = Join-Path $repoRoot 'Specrew.psd1'
Write-Host "  candidate B (repoRoot): '$repoManifest'"
Write-Host "  exists?                  $(Test-Path -LiteralPath $repoManifest -PathType Leaf)"

if (Test-Path -LiteralPath $manifestA -PathType Leaf) {
    try {
        $data = Import-PowerShellDataFile -LiteralPath $manifestA
        Write-Host "  Import OK. ModuleVersion = '$($data.ModuleVersion)'"
    }
    catch {
        Write-Host "  Import THREW: $($_.Exception.Message)"
    }
}
Write-Host ""

Write-Host "--- Step 3: Get-SpecrewInstalledVersion -ProjectRoot \$repoRoot ---"
try {
    $result = Get-SpecrewInstalledVersion -ProjectRoot $repoRoot
    if ($null -eq $result) {
        Write-Host "  Result: <null>"
    }
    elseif ([string]::IsNullOrEmpty($result)) {
        Write-Host "  Result: <empty string>"
    }
    else {
        Write-Host "  Result: '$result'"
    }
}
catch {
    Write-Host "  THREW: $($_.Exception.Message)"
    Write-Host "  ScriptStackTrace: $($_.ScriptStackTrace)"
}
Write-Host ""

Write-Host "=== End diagnostic ==="
