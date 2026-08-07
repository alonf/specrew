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

# Test 8: the historical bootstrap and current candidate must have separate,
# exact toolchain identities. A single pin made the v0.27.6 baseline invoke its
# removed `--ai` surface against Spec Kit 0.12.9 and silently broke publication.
$dockerfileContent = Get-Content -LiteralPath $dockerfilePath -Raw -Encoding UTF8
$twoPhaseDockerAssertions = [ordered]@{
    'baseline Spec Kit pin' = 'ARG BASELINE_SPEC_KIT_VERSION=0\.8\.4'
    'baseline Squad pin' = 'ARG BASELINE_SQUAD_VERSION=0\.9\.1'
    'target Spec Kit pin' = 'ARG SPEC_KIT_VERSION=0\.12\.9'
    'target Squad pin' = 'ARG SQUAD_VERSION=0\.11\.0'
    'baseline Spec Kit install' = 'specify-cli[\s\\]+--from "git\+https://github\.com/github/spec-kit\.git@v\$\{BASELINE_SPEC_KIT_VERSION\}"'
    'baseline Squad install' = '@bradygaster/squad-cli@\$\{BASELINE_SQUAD_VERSION\}'
    'target identity export' = 'SPECREW_HARNESS_TARGET_SPEC_KIT_VERSION="\$\{SPEC_KIT_VERSION\}"'
}
foreach ($assertion in $twoPhaseDockerAssertions.GetEnumerator()) {
    if ($dockerfileContent -notmatch $assertion.Value) {
        Write-Fail ("Docker harness is missing the two-phase contract: {0}." -f $assertion.Key)
        exit 1
    }
}
Write-Pass 'Docker harness keeps exact baseline-era and candidate toolchain identities separate.'

# Test 9: Phase 4 remains real, and Phase 5 delegates the tool upgrade to the
# candidate's production update path instead of a harness-owned uv/npm shortcut.
if ($harnessContent -notmatch 'Initialize-Specrew\s+--force') {
    Write-Fail 'Publish harness no longer executes the real v0.27.6 Phase 4 initialization.'
    exit 1
}
if ($harnessContent -notmatch 'Update-Specrew\s+-All\s+-SkipUpdateCheck') {
    Write-Fail 'Publish harness does not exercise the production all-scope update path.'
    exit 1
}
if ($harnessContent -notmatch 'Assert-HarnessToolchain' -or $harnessContent -notmatch "-Phase 'Baseline'" -or $harnessContent -notmatch "-Phase 'Candidate'") {
    Write-Fail 'Publish harness does not prove exact toolchain identity before and after update.'
    exit 1
}
if ($harnessContent -match '(?m)^\s*&\s+(uv|npm)\s+') {
    Write-Fail 'Publish harness bypasses specrew update with a direct toolchain installer.'
    exit 1
}
Write-Pass 'Publish harness preserves Phase 4 and uses the production update path with exact pre/post assertions.'

Write-Host ''
Write-Host 'All publish-module harness assertions passed!' -ForegroundColor Green
exit 0
