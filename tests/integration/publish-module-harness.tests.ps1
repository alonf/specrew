# T001: Add failing E2E publish-module test assertions
# This test validates the Docker pre-publish harness for FileList integrity
# and version pin drift detection (Prop 134).
# Trace: FR-003, FR-012, SC-001

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$testHarnessScript = Join-Path -Path $repoRoot -ChildPath 'scripts\internal\test-publish-harness.ps1'
$dockerfilePath = Join-Path -Path $repoRoot -ChildPath 'tests\Dockerfile.publish-test'
$manifestPath = Join-Path -Path $repoRoot -ChildPath 'Specrew.psd1'
$configPath = Join-Path -Path $repoRoot -ChildPath '.specrew\config.yml'

# Test 1: Dockerfile.publish-test must exist (T002 will create it)
if (-not (Test-Path -LiteralPath $dockerfilePath)) {
    Write-Fail "Dockerfile.publish-test does not exist yet. Expected at: $dockerfilePath"
    Write-Host "This will be created in T002 (Create tests/Dockerfile.publish-test)." -ForegroundColor Yellow
    exit 1
}
Write-Pass "Dockerfile.publish-test exists at expected location."

# Test 2: test-publish-harness.ps1 must exist (T003 will create it)
if (-not (Test-Path -LiteralPath $testHarnessScript)) {
    Write-Fail "test-publish-harness.ps1 does not exist yet. Expected at: $testHarnessScript"
    Write-Host "This will be created in T003 (Create scripts/internal/test-publish-harness.ps1)." -ForegroundColor Yellow
    exit 1
}
Write-Pass "test-publish-harness.ps1 exists at expected location."

# Test 3: FileList integrity - verify every FileList entry exists on disk
$manifest = Import-PowerShellDataFile -Path $manifestPath
$fileList = @($manifest.FileList | ForEach-Object { [string]$_ })
$missingFiles = @()

foreach ($relativePath in $fileList) {
    $normalizedPath = $relativePath -replace '/', '\'
    $fullPath = Join-Path -Path $repoRoot -ChildPath $normalizedPath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $missingFiles += $relativePath
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Fail "FileList integrity check failed. Missing files:"
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
    exit 1
}
Write-Pass "FileList integrity check passed. All $($fileList.Count) files exist on disk."

# Test 4: Version pin drift detection (Prop 134)
# Compare specrew_version in .specrew/config.yml with ModuleVersion in Specrew.psd1
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Fail "Config file does not exist at: $configPath"
    exit 1
}

$configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
if ($configContent -match 'specrew_version:\s*["'']?([0-9]+\.[0-9]+\.[0-9]+)["'']?') {
    $configVersion = $Matches[1]
} else {
    Write-Fail "Could not parse specrew_version from config.yml"
    exit 1
}

$manifestVersion = $manifest.ModuleVersion

if ($configVersion -ne $manifestVersion) {
    Write-Fail "Version pin drift detected! Config version: $configVersion, Manifest version: $manifestVersion"
    Write-Host "Prop 134 version pin check enforces these must match." -ForegroundColor Yellow
    exit 1
}
Write-Pass "Version pin check passed. Config and manifest both declare version: $manifestVersion"

# Test 5: test-publish-harness.ps1 must contain FileList validation logic (T003)
$harnessContent = Get-Content -LiteralPath $testHarnessScript -Raw -Encoding UTF8
if ($harnessContent -notmatch 'FileList') {
    Write-Fail "test-publish-harness.ps1 does not contain FileList validation logic."
    Write-Host "This will be implemented in T003." -ForegroundColor Yellow
    exit 1
}
Write-Pass "test-publish-harness.ps1 contains FileList validation logic."

# Test 6: test-publish-harness.ps1 must contain version pin drift assertions (T004)
if ($harnessContent -notmatch 'version|drift|pin') {
    Write-Fail "test-publish-harness.ps1 does not contain version pin drift assertions."
    Write-Host "This will be implemented in T004." -ForegroundColor Yellow
    exit 1
}
Write-Pass "test-publish-harness.ps1 contains version pin drift assertions."

# Test 7: publish-module.yml must wire the Docker harness (T006)
$publishWorkflowPath = Join-Path -Path $repoRoot -ChildPath '.github\workflows\publish-module.yml'
$workflowContent = Get-Content -LiteralPath $publishWorkflowPath -Raw -Encoding UTF8

if ($workflowContent -notmatch 'Dockerfile\.publish-test|test-publish-harness') {
    Write-Fail "publish-module.yml does not wire the Docker harness yet."
    Write-Host "This will be implemented in T006." -ForegroundColor Yellow
    exit 1
}
Write-Pass "publish-module.yml wires the Docker harness."

Write-Host ''
Write-Host 'All publish-module harness assertions passed!' -ForegroundColor Green
exit 0
