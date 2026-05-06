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
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\concurrency-sizing'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$specRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-concurrency-feature'
$specPath = Join-Path -Path $specRoot -ChildPath 'spec.md'
$iterationEightPath = Join-Path -Path $specRoot -ChildPath 'iterations\008'
$planPath = Join-Path -Path $iterationEightPath -ChildPath 'plan.md'
$priorCodeMapPath = Join-Path -Path $specRoot -ChildPath 'iterations\007\code-map.md'
$teamPath = Join-Path -Path $projectRoot -ChildPath '.squad\team.md'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path (Join-Path -Path $projectRoot -ChildPath '.squad') -ItemType Directory -Force
$null = New-Item -Path (Split-Path -Parent $priorCodeMapPath) -ItemType Directory -Force

[System.IO.File]::WriteAllText($teamPath, @'
# Team

## Specrew Baseline Roles

| Role | Purpose |
| ---- | ------- |
| Spec Steward | Own spec quality |
| Planner | Shape plans |
| Implementer | Deliver code |
| Reviewer | Review slices |
| Retro Facilitator | Lead retros |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($specPath, @'
# Feature Spec: 001 Concurrency Sample

### User Story 1 — Reporting Dashboard (Priority: P1)

## Traceability & Governance Requirements *(mandatory)*

- US-1 → FR-038, FR-039, FR-040, FR-041

## Functional Requirements

- **FR-038**: Add a reporting dashboard with multiple independent frontend screens, export workflows, and API-backed data loading.
- **FR-039**: Team shaping may propose Junior and Senior frontend roles when safe parallel work exists.
- **FR-040**: Junior work should stay bounded while Senior work handles integration-heavy acceptance slices.
- **FR-041**: Parallel same-specialty work must record explicit ownership boundaries.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($priorCodeMapPath, @'
# Code Map

## Module Hotspots

- `client/src/dashboard` changed heavily in the previous iteration.
- `client/src/shared/charts` is still a high-churn surface.
'@, [System.Text.UTF8Encoding]::new($false))

$scaffoldOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffoldScript -SpecPath $specPath -IterationNumber '008' 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $scaffoldOutput) {
        Write-Host $line
    }
    Write-Fail 'Iteration plan scaffold failed for concurrency-sizing sample.'
    exit 1
}

$scaffoldedPlan = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8
foreach ($expected in @(
        '## Concurrency Rationale',
        'Owner File Globs',
        'Latest reviewer hotspots:',
        'client/src/dashboard',
        'keep the work serial'
    )) {
    if (-not $scaffoldedPlan.Contains($expected)) {
        Write-Fail "Scaffolded plan is missing expected concurrency rationale content: $expected"
        exit 1
    }
}

Write-Pass 'Iteration plan scaffold records concurrency rationale and ownership-boundary guidance'

[System.IO.File]::WriteAllText($planPath, @'
# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 4/20 story_points
**Started**: 2026-05-06

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-038 | Reporting dashboard | US-1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T-801 | Build dashboard shell | FR-038 | US-1 | 2 | Junior Frontend Developer |  | planned | | | |
| T-802 | Wire export orchestration | FR-040 | US-1 | 2 | Senior Frontend Developer |  | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds configured capacity. |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Frontend-oriented signals dominate the scoped requirements.
- Recommendation: same-specialty expansion is tentatively warranted.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Ready |

## Traceability Summary

- Requirement scope for this iteration: FR-038, FR-040
'@, [System.Text.UTF8Encoding]::new($false))

$failingValidation = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -eq 0) {
    Write-Fail 'Validator unexpectedly allowed same-specialty parallel planning without ownership boundaries.'
    exit 1
}

$failingText = ($failingValidation | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($failingText -notmatch 'without explicit Owner File Globs') {
    Write-Fail 'Validator did not explain the missing ownership-boundary failure.'
    exit 1
}

Write-Pass 'Validator blocks same-specialty pair plans that omit ownership boundaries'

$serialPlan = $scaffoldedPlan -replace '\(Stub\)', '' -replace '\*\*Capacity\*\*: 0/20 story_points', '**Capacity**: 4/20 story_points'
$serialPlan = $serialPlan -replace '\| ---- \| ----- \| ----------- \| ----- \| ------ \| ----- \| ---------------- \| ------ \| ----- \| ------ \| ------- \|', @'
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T-803 | Build dashboard shell | FR-038 | US-1 | 2 | Junior Frontend Developer |  | planned | | | |
| T-804 | Wire export orchestration | FR-040 | US-1 | 2 | Senior Frontend Developer |  | planned | | | |
'@
[System.IO.File]::WriteAllText($planPath, $serialPlan, [System.Text.UTF8Encoding]::new($false))

$serialValidation = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should allow same-specialty pair planning when the rationale explicitly keeps work serial.'
    foreach ($line in $serialValidation) {
        Write-Host $line
    }
    exit 1
}

Write-Pass 'Validator allows same-specialty pair plans when Concurrency Rationale keeps the work serial'
exit 0
