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
$validatorScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\planning-overcommit'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$iterationRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-capacity-feature\iterations\001'
$specPath = Join-Path -Path $projectRoot -ChildPath 'specs\001-capacity-feature\spec.md'
$planPath = Join-Path -Path $iterationRoot -ChildPath 'plan.md'
$configPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $iterationRoot -ItemType Directory -Force
$null = New-Item -Path (Split-Path -Parent $configPath) -ItemType Directory -Force

[System.IO.File]::WriteAllText($specPath, @'
# Feature Spec: 001 Capacity Sample

### User Story 1 — Critical Delivery (Priority: P1)

### User Story 7 — Nice-to-Have Extension (Priority: P3)

## Traceability & Governance Requirements *(mandatory)*

- US-1 → FR-001
- US-7 → FR-007

## Functional Requirements

- **FR-001**: Critical requirement MUST ship in this iteration.
- **FR-007**: Nice-to-have requirement MAY defer when capacity is tight.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($configPath, @'
effort_unit: "story_points"
capacity_per_iteration: 2
overcommit_threshold: 1.0
defer_strategy: "lowest_priority"
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($planPath, @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 3/2 story_points
**Started**: 2026-05-03
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | Ship critical slice | FR-001 | US-1 | 1 | Implementer | planned | | | |
| T-002 | Ship nice-to-have slice | FR-007 | US-7 | 2 | Implementer | planned | | | |
'@, [System.Text.UTF8Encoding]::new($false))

$output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -eq 0) {
    Write-Fail 'Governance validator unexpectedly passed an overcommitted planning artifact.'
    exit 1
}

$joinedOutput = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($joinedOutput -notmatch 'plan\.md is over capacity') {
    Write-Fail 'Overcommit validation message was not emitted.'
    exit 1
}

if (-not $joinedOutput.Contains('defer the lowest-priority requirement slices first:') -or
    -not $joinedOutput.Contains('T-002') -or
    -not $joinedOutput.Contains('FR-007') -or
    $joinedOutput.Contains('T-001 [P1')) {
    Write-Fail 'Overcommit guidance did not rank the lowest-priority task as the explicit deferral candidate.'
    exit 1
}

Write-Pass 'Planning validation flags overcommit and recommends deferral by mapped requirement priority'
exit 0
