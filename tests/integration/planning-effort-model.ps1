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
$scaffoldScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1'
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\planning-effort-model'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$specRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-effort-feature'
$iterationRoot = Join-Path -Path $specRoot -ChildPath 'iterations\001'
$specPath = Join-Path -Path $specRoot -ChildPath 'spec.md'
$configPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'
$planPath = Join-Path -Path $iterationRoot -ChildPath 'plan.md'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $specRoot -ItemType Directory -Force
$null = New-Item -Path (Split-Path -Parent $configPath) -ItemType Directory -Force

[System.IO.File]::WriteAllText($specPath, @'
# Feature Spec: 001 Effort Sample

### User Story 1 — Iteration Planning (Priority: P2)

## Traceability & Governance Requirements *(mandatory)*

- US-1 → FR-007, FR-017

## Functional Requirements

- **FR-007**: Planning artifacts MUST reflect the configured effort model.
- **FR-017**: Capacity validation MUST use the configured effort model.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($configPath, @'
effort_unit: "dev_days"
capacity_per_iteration: 6
iteration_bounding: "time"
time_limit_hours: 40
overcommit_threshold: 1.25
calibration_enabled: "false"
defer_strategy: "manual"
'@, [System.Text.UTF8Encoding]::new($false))

$scaffoldOutput = @(
    & $scaffoldScript `
        -SpecPath $specPath `
        -IterationNumber 001 `
        -RequirementScope @('FR-007', 'FR-017') 2>&1
)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Iteration plan scaffold failed for custom effort model input.'
    $scaffoldOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$planContent = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8
foreach ($expectedSnippet in @(
    '**Capacity**: 0/6 dev_days',
    '## Effort Model',
    '| Effort Unit | dev_days |',
    '| Capacity per Iteration | 6 |',
    '| Iteration Bounding | time |',
    '| Time Limit (hours) | 40 |',
    '| Overcommit Threshold | 1.25 |',
    '| Defer Strategy | manual |',
    '| Calibration Enabled | false |'
)) {
    if (-not $planContent.Contains($expectedSnippet)) {
        Write-Fail "Scaffolded plan did not contain expected effort-model content: $expectedSnippet"
        exit 1
    }
}

$validatorOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Governance validator should accept the scaffolded effort-model snapshot.'
    $validatorOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$mutatedPlan = $planContent -replace '\| Effort Unit \| dev_days \|', '| Effort Unit | story_points |'
[System.IO.File]::WriteAllText($planPath, $mutatedPlan, [System.Text.UTF8Encoding]::new($false))

$mismatchOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -eq 0) {
    Write-Fail 'Governance validator unexpectedly passed a plan with a drifted Effort Model snapshot.'
    exit 1
}

$joinedOutput = ($mismatchOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($joinedOutput -notmatch "plan\.md Effort Model 'Effort Unit' value 'story_points' does not match iteration-config 'dev_days'") {
    Write-Fail 'Validator did not emit the expected effort-model drift message.'
    exit 1
}

Write-Pass 'Planning scaffold and validator keep the effort model aligned end to end'
exit 0
