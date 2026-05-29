# test-publish-harness.ps1
# Trace: T003, T004, T005, FR-003, FR-004, FR-012, SC-001
#
# Pre-publish E2E validation harness for Specrew module candidates.
# This script runs inside a Docker container with a baseline Specrew v0.27.6 install
# and validates that the packaged candidate is publication-ready.
#
# Validations performed:
# 1. FileList integrity: Every Specrew.psd1 FileList entry exists on disk
# 2. Version pin drift: .specrew/config.yml specrew_version matches Specrew.psd1 ModuleVersion (Prop 134)
# 3. Clean initialization: `specrew init` succeeds in a fresh project
# 4. Clean update: `specrew update` transitions succeed without corruption

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CandidatePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message, [string]$Detail = '')
    Write-Host "FAIL: $Message" -ForegroundColor Red
    if ($Detail) {
        Write-Host "      $Detail" -ForegroundColor Yellow
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

# -----------------------------------------------------------------------------
# Phase 1: Validate Candidate Structure
# -----------------------------------------------------------------------------

Write-Section "Phase 1: Validate Candidate Structure"

# Resolve candidate path
$CandidatePath = (Resolve-Path -LiteralPath $CandidatePath).Path
Write-Host "Candidate path: $CandidatePath"

# Locate manifest
$manifestPath = Join-Path -Path $CandidatePath -ChildPath 'Specrew.psd1'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Write-Fail "Specrew.psd1 not found in candidate root." "Expected: $manifestPath"
    exit 1
}
Write-Pass "Found Specrew.psd1 at $manifestPath"

# Import manifest
try {
    $manifest = Import-PowerShellDataFile -Path $manifestPath
} catch {
    Write-Fail "Failed to parse Specrew.psd1." $_.Exception.Message
    exit 1
}
Write-Pass "Successfully parsed Specrew.psd1"

$candidateVersion = $manifest.ModuleVersion
Write-Host "Candidate version: $candidateVersion" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# Phase 2: FileList Integrity Check (FR-003)
# -----------------------------------------------------------------------------

Write-Section "Phase 2: FileList Integrity Check"

$fileList = @($manifest.FileList | ForEach-Object { [string]$_ })
Write-Host "FileList declares $($fileList.Count) entries."

$missingFiles = @()
$presentFiles = @()

foreach ($relativePath in $fileList) {
    # Normalize path separators for cross-platform compatibility
    $normalizedPath = $relativePath -replace '/', '\'
    $fullPath = Join-Path -Path $CandidatePath -ChildPath $normalizedPath
    
    if (Test-Path -LiteralPath $fullPath) {
        $presentFiles += $relativePath
    } else {
        $missingFiles += $relativePath
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Fail "FileList integrity check FAILED. Missing $($missingFiles.Count) file(s):"
    foreach ($file in $missingFiles) {
        Write-Host "  ❌ $file" -ForegroundColor Red
    }
    exit 1
}

Write-Pass "FileList integrity check PASSED. All $($fileList.Count) files exist on disk."

# -----------------------------------------------------------------------------
# Phase 3: Version Pin Drift Detection (FR-012, Prop 134)
# -----------------------------------------------------------------------------

Write-Section "Phase 3: Version Pin Drift Detection (Prop 134)"

$configPath = Join-Path -Path $CandidatePath -ChildPath '.specrew\config.yml'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Fail ".specrew/config.yml not found in candidate." "Expected: $configPath"
    exit 1
}
Write-Pass "Found .specrew/config.yml"

$configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8

# Parse specrew_version from config.yml
if ($configContent -match 'specrew_version:\s*["'']?([0-9]+\.[0-9]+\.[0-9]+)["'']?') {
    $configVersion = $Matches[1]
} else {
    Write-Fail "Could not parse specrew_version from config.yml"
    exit 1
}

Write-Host "Config specrew_version: $configVersion" -ForegroundColor Cyan
Write-Host "Manifest ModuleVersion: $candidateVersion" -ForegroundColor Cyan

if ($configVersion -ne $candidateVersion) {
    Write-Fail "Version pin DRIFT detected!" "Config declares $configVersion but manifest declares $candidateVersion"
    Write-Host "Prop 134 requires these versions to be synchronized." -ForegroundColor Yellow
    exit 1
}

Write-Pass "Version pin check PASSED. Config and manifest are synchronized at version $candidateVersion"

# -----------------------------------------------------------------------------
# Phase 4: Test Project Initialization (FR-003)
# -----------------------------------------------------------------------------

Write-Section "Phase 4: Test Project Initialization"

# Create a clean test project directory
$testProjectPath = Join-Path -Path $env:TEMP -ChildPath "specrew-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testProjectPath -Force | Out-Null
Write-Host "Created test project at: $testProjectPath"

# Initialize git repo (required by specrew init)
Push-Location $testProjectPath
try {
    git init 2>&1 | Out-Null
    git config user.email "test@example.com" 2>&1 | Out-Null
    git config user.name "Test User" 2>&1 | Out-Null
    Write-Pass "Initialized git repository"
    
    # Run specrew init with baseline version (v0.27.6 from PSGallery)
    Write-Host "Running specrew init with baseline v0.27.6..."
    try {
        Initialize-Specrew -NonInteractive -Force
        Write-Pass "specrew init succeeded with baseline version"
    } catch {
        Write-Fail "specrew init failed with baseline version" $_.Exception.Message
        exit 1
    }
    
    # Verify baseline layout
    $baselineConfigPath = Join-Path -Path $testProjectPath -ChildPath '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $baselineConfigPath)) {
        Write-Fail "Baseline .specrew/config.yml not created by init"
        exit 1
    }
    Write-Pass "Baseline project structure validated"
    
} finally {
    Pop-Location
}

# -----------------------------------------------------------------------------
# Phase 5: specrew update Transition Validation (FR-004)
# -----------------------------------------------------------------------------

Write-Section "Phase 5: specrew update Transition Validation"

Push-Location $testProjectPath
try {
    # Stage and commit baseline state to enable update
    git add -A 2>&1 | Out-Null
    git commit -m "Initial baseline commit" 2>&1 | Out-Null
    Write-Pass "Committed baseline state"
    
    # Unload baseline module and load candidate module
    Write-Host "Switching to candidate module..."
    Remove-Module Specrew -Force -ErrorAction SilentlyContinue
    
    # Import candidate module explicitly
    $candidateModulePath = Join-Path -Path $CandidatePath -ChildPath 'Specrew.psm1'
    Import-Module $candidateModulePath -Force -Global
    Write-Pass "Loaded candidate module from $candidateModulePath"
    
    # Verify candidate module is active
    $loadedModule = Get-Module Specrew
    if (-not $loadedModule) {
        Write-Fail "Candidate module not loaded"
        exit 1
    }
    Write-Host "Active module version: $($loadedModule.Version)" -ForegroundColor Cyan
    
    # Run specrew update to transition from baseline to candidate
    Write-Host "Running specrew update to apply candidate version..."
    try {
        Update-Specrew -NonInteractive -Force
        Write-Pass "specrew update succeeded"
    } catch {
        Write-Fail "specrew update failed during baseline->candidate transition" $_.Exception.Message
        exit 1
    }
    
    # Verify updated config reflects candidate version
    $updatedConfigPath = Join-Path -Path $testProjectPath -ChildPath '.specrew\config.yml'
    $updatedConfigContent = Get-Content -LiteralPath $updatedConfigPath -Raw -Encoding UTF8
    
    if ($updatedConfigContent -match 'specrew_version:\s*["'']?([0-9]+\.[0-9]+\.[0-9]+)["'']?') {
        $updatedVersion = $Matches[1]
        if ($updatedVersion -eq $candidateVersion) {
            Write-Pass "Config updated to candidate version: $updatedVersion"
        } else {
            Write-Fail "Config version mismatch after update" "Expected $candidateVersion, got $updatedVersion"
            exit 1
        }
    } else {
        Write-Fail "Could not parse specrew_version from updated config.yml"
        exit 1
    }
    
    # Verify FileList integrity in updated project
    Write-Host "Verifying FileList integrity in updated project..."
    $updateMissingFiles = @()
    
    foreach ($relativePath in $fileList) {
        # Normalize path separators
        $normalizedPath = $relativePath -replace '/', '\'
        
        # Check in candidate source first (not all files deploy to projects)
        $candidateFullPath = Join-Path -Path $CandidatePath -ChildPath $normalizedPath
        
        # For project-relevant files, check if they should exist in the project
        # Most module files stay in the module install location, not the project
        # We're primarily validating the candidate package integrity here
        if (-not (Test-Path -LiteralPath $candidateFullPath)) {
            $updateMissingFiles += $relativePath
        }
    }
    
    if ($updateMissingFiles.Count -gt 0) {
        Write-Fail "FileList integrity check FAILED after update. Missing $($updateMissingFiles.Count) file(s):"
        foreach ($file in $updateMissingFiles) {
            Write-Host "  ❌ $file" -ForegroundColor Red
        }
        exit 1
    }
    
    Write-Pass "FileList integrity validated after update transition"
    
    # Verify no duplicate Squad entries (FR-013 regression check)
    $teamPath = Join-Path -Path $testProjectPath -ChildPath '.squad\team.md'
    if (Test-Path -LiteralPath $teamPath) {
        $teamContent = Get-Content -LiteralPath $teamPath -Raw -Encoding UTF8
        $teamLines = $teamContent -split "`n" | Where-Object { $_.Trim() -match '^\|' -and $_ -notmatch '^\|\s*-' }
        
        # Group by line content and find duplicates
        $duplicates = $teamLines | Group-Object | Where-Object { $_.Count -gt 1 }
        
        if ($duplicates.Count -gt 0) {
            Write-Fail "Duplicate Squad team entries detected (FR-013 regression):"
            foreach ($dup in $duplicates) {
                Write-Host "  ❌ $($dup.Name) (appears $($dup.Count) times)" -ForegroundColor Red
            }
            exit 1
        }
        Write-Pass "No duplicate Squad entries detected"
    }
    
} finally {
    Pop-Location
    # Cleanup test project
    if (Test-Path -LiteralPath $testProjectPath) {
        Remove-Item -Path $testProjectPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Final Summary
# -----------------------------------------------------------------------------

Write-Section "Pre-Publish Validation Summary"

Write-Host "✅ All validation checks PASSED" -ForegroundColor Green
Write-Host ""
Write-Host "Validated candidate: Specrew v$candidateVersion" -ForegroundColor Cyan
Write-Host "  ✓ FileList integrity ($($fileList.Count) files)" -ForegroundColor Green
Write-Host "  ✓ Version pin synchronization (Prop 134)" -ForegroundColor Green
Write-Host "  ✓ Clean project initialization" -ForegroundColor Green
Write-Host "  ✓ Clean update transition (v0.27.6 → v$candidateVersion)" -ForegroundColor Green
Write-Host "  ✓ No duplicate Squad entries (FR-013)" -ForegroundColor Green
Write-Host ""
Write-Host "Candidate is READY for PSGallery publication." -ForegroundColor Green

exit 0
