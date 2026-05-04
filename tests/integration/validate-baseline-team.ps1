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

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'

if (-not (Test-Path -Path $validatorScript -PathType Leaf)) {
    Write-Fail "Missing validator script: $validatorScript"
    exit 1
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Baseline team validation tests require tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\validate-baseline-team'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitInitOutput) {
        Write-Host $line
    }
    Write-Fail "Failed to initialize git repository in scratch project: $projectRoot"
    exit 1
}

Write-Host "Initializing Specrew project..."
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'
$initOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -ProjectPath $projectRoot -Force -NoAgents 2>&1)

if ($LASTEXITCODE -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $initOutput) {
        Write-Host $line
    }
    Write-Fail "Bootstrap failed"
    exit 1
}

Write-Pass "Bootstrap completed successfully"

Write-Host "`nTest 1: Validate baseline team (no custom members)"
# We'll test just the team validation by creating a minimal valid iteration manually
$specDirectory = Join-Path -Path $projectRoot -ChildPath 'specs\001-test-feature'
$iterationDirectory = Join-Path -Path $specDirectory -ChildPath 'iterations\001'
$planPath = Join-Path -Path $iterationDirectory -ChildPath 'plan.md'
$specPath = Join-Path -Path $specDirectory -ChildPath 'spec.md'

$null = New-Item -Path $iterationDirectory -ItemType Directory -Force

$specContent = @'
# Feature Spec: 001 Test

## User Stories

- US-1 → FR-001

## Functional Requirements

- **FR-001**: Test requirement
'@

[System.IO.File]::WriteAllText($specPath, $specContent, [System.Text.UTF8Encoding]::new($false))

# Create a minimal valid plan that matches what validate-governance expects
$configPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'
$configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8

$planContent = @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 1/20 story_points
**Started**: 2026-05-04

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | Test requirement | US-1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T-001 | Test task | FR-001 | US-1 | 1 | Implementer | planned |

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

## Traceability Summary

- Requirement scope for this iteration: FR-001
- User stories represented: US-1
'@

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))

$validateOutput1 = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
$validateExitCode1 = $LASTEXITCODE

if ($validateExitCode1 -ne 0) {
    Write-Fail "Validator rejected baseline-only team"
    foreach ($line in $validateOutput1) {
        Write-Host $line
    }
    exit 1
}

Write-Pass "Validator accepts baseline-only team"

Write-Host "`nTest 2: Add custom team member and validate"
$teamScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-team.ps1'
$addOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $teamScript add security-analyst --role "Security Analyst" --charter "Review code for security vulnerabilities." -ProjectPath $projectRoot 2>&1)

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to add custom team member"
    foreach ($line in $addOutput) {
        Write-Host $line
    }
    exit 1
}

$validateOutput2 = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
$validateExitCode2 = $LASTEXITCODE

if ($validateExitCode2 -ne 0) {
    Write-Fail "Validator rejected baseline+custom team"
    foreach ($line in $validateOutput2) {
        Write-Host $line
    }
    exit 1
}

Write-Pass "Validator accepts baseline+custom team"

Write-Host "`nTest 3: Remove baseline role and validate (should fail)"
$teamPath = Join-Path -Path $projectRoot -ChildPath '.squad\team.md'
$teamContent = Get-Content -LiteralPath $teamPath -Raw -Encoding UTF8
$modifiedContent = $teamContent -replace '\| Implementer \|[^\n]*\n', ''
[System.IO.File]::WriteAllText($teamPath, $modifiedContent, [System.Text.UTF8Encoding]::new($false))

$validateOutput3 = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
$validateExitCode3 = $LASTEXITCODE

if ($validateExitCode3 -eq 0) {
    Write-Fail "Validator should have failed when baseline role is missing"
    exit 1
}

$validateText3 = $validateOutput3 -join "`n"
if ($validateText3 -notmatch 'missing required baseline role.*Implementer') {
    Write-Fail "Validator did not provide clear error message for missing baseline role"
    exit 1
}

Write-Pass "Validator correctly rejects team missing baseline role"

Write-Host "`nTest 4: Add multiple custom members and validate"
[System.IO.File]::WriteAllText($teamPath, $teamContent, [System.Text.UTF8Encoding]::new($false))

$customRoles = @(
    @{ Name = 'ux-designer'; Role = 'UX Designer'; Charter = 'Design user interfaces.' }
    @{ Name = 'dba'; Role = 'Database Administrator'; Charter = 'Manage database schema.' }
)

foreach ($roleInfo in $customRoles) {
    $addResult = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $teamScript add $roleInfo.Name --role $roleInfo.Role --charter $roleInfo.Charter -ProjectPath $projectRoot 2>&1)
    
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to add custom member: $($roleInfo.Role)"
        exit 1
    }
}

$validateOutput4 = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
$validateExitCode4 = $LASTEXITCODE

if ($validateExitCode4 -ne 0) {
    Write-Fail "Validator rejected baseline+multiple-custom team"
    foreach ($line in $validateOutput4) {
        Write-Host $line
    }
    exit 1
}

Write-Pass "Validator accepts baseline+multiple-custom team"

Write-Host "`nAll tests passed!" -ForegroundColor Green
Write-Host "Cleaning up test artifacts..."

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

exit 0
