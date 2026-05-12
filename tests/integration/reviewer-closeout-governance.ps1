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
$reviewerScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\reviewer-closeout-governance'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$specRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-reviewer-closeout'
$iterationDirectory = Join-Path -Path $specRoot -ChildPath 'iterations\009'
$legacyIterationDirectory = Join-Path -Path $specRoot -ChildPath 'iterations\005'
$specPath = Join-Path -Path $specRoot -ChildPath 'spec.md'
$teamPath = Join-Path -Path $projectRoot -ChildPath '.squad\team.md'
$configPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $iterationDirectory -ItemType Directory -Force
$null = New-Item -Path $legacyIterationDirectory -ItemType Directory -Force
$null = New-Item -Path (Join-Path -Path $projectRoot -ChildPath '.squad') -ItemType Directory -Force
$null = New-Item -Path (Join-Path -Path $projectRoot -ChildPath '.specrew') -ItemType Directory -Force
$null = New-Item -Path (Join-Path -Path $projectRoot -ChildPath 'src') -ItemType Directory -Force
$null = New-Item -Path (Join-Path -Path $projectRoot -ChildPath 'tests\integration') -ItemType Directory -Force

[System.IO.File]::WriteAllText($teamPath, @'
# Squad Team

## Members

| Name | Role | Charter | Status |
| ---- | ---- | ------- | ------ |
| steward | Spec Steward | `.squad/agents/steward/charter.md` | baseline |
| planner | Planner | `.squad/agents/planner/charter.md` | baseline |
| implementer | Implementer | `.squad/agents/implementer/charter.md` | baseline |
| reviewer | Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| retro | Retro Facilitator | `.squad/agents/retro/charter.md` | baseline |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($configPath, @'
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"
reviewer:
  closeout_packet_required_since_iteration: "009"
  test_path_globs:
    - "**/tests/**"
    - "**/*test*.*"
  test_commands: []
  coverage:
    tool: ""
    kind: "qualitative"
  skip_test_execution_at_close: false
  vulnerability_scanner:
    auto_detect: false
    command: ""
    candidates:
      - "npm audit --json"
  baseline_ref: "iteration-baseline"
  diagram_format: "mermaid"
  hotspot_thresholds:
    file_changed_lines: 5
    function_changed_lines: 2
  diagram_thresholds:
    structure:
      min_modules_touched: 2
      min_inter_module_edges: 1
    flow:
      min_entrypoints_changed: 1
      min_modules_in_flow: 2
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText($specPath, @'
# Feature Spec: 001 Reviewer Closeout

### User Story 2 — Reviewer Closeout (Priority: P1)

## Traceability & Governance Requirements *(mandatory)*

- US-2 → FR-046, FR-049, FR-052, FR-053

## Functional Requirements

- **FR-046**: Reviewer closeout records a code map for touched files.
- **FR-049**: Reviewer closeout records test and coverage evidence.
- **FR-052**: Reviewer closeout emits a reviewer index for replay and triage.
- **FR-053**: Reviewer closeout emits diagrams or explicit omissions.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'src\app.js'), @'
export function loadMessage() {
  return "baseline";
}
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'tests\integration\app.test.js'), @'
import { loadMessage } from "../../src/app.js";

console.log(loadMessage());
'@, [System.Text.UTF8Encoding]::new($false))

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to initialize scratch git repo.'
    exit 1
}

@(& git -C $projectRoot add . 2>&1) | Out-Null
$baselineCommit = @(& git -C $projectRoot -c user.name=Copilot -c user.email=copilot@example.com commit -m "baseline" --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to create baseline commit.'
    exit 1
}

@(& git -C $projectRoot tag iteration-baseline 2>&1) | Out-Null

[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'src\app.js'), @'
export function loadMessage() {
  return "iteration-eight";
}

export function loadAdminMessage() {
  return "admin";
}
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'tests\integration\app.test.js'), @'
import { loadAdminMessage, loadMessage } from "../../src/app.js";

console.log(loadMessage(), loadAdminMessage());
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationDirectory -ChildPath 'plan.md'), @'
# Iteration Plan: 009

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 4/20 story_points
**Started**: 2026-05-06
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-901 | Generate reviewer closeout | FR-046, FR-049, FR-052, FR-053 | US-2 | 4 | Reviewer | done | copilot-agent | 4 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds the configured threshold. |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Reviewer packet planning |
| Discovery/Spikes | 0 | No spike needed |
| Implementation | 2 | Code changes plus reviewer packet |
| Review | 1 | Reviewer closeout validation |
| Rework | 0 | No expected rework |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationDirectory -ChildPath 'state.md'), @'
# Iteration State: 009

**Schema**: v1
**Last Completed Task**: T-901
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: iteration-baseline
**Updated**: 2026-05-06T22:00:00Z

## Execution Summary

- Reviewer closeout slice completed.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationDirectory -ChildPath 'drift-log.md'), @'
# Drift Log: Iteration 009

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 0% (0/0 resolved)
**Specification drift**: None detected
**Implementation drift**: None detected

## Drift Events

- none

## Resolution Breakdown

- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationDirectory -ChildPath 'review.md'), @'
# Review: Iteration 009

**Schema**: v1
**Reviewed**: 2026-05-06
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-901 | FR-046, FR-049, FR-052, FR-053 | pass | Reviewer closeout was delivered for the code-touching slice. |

## Gap Ledger

No known gaps remain.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationDirectory -ChildPath 'retro.md'), @'
# Retrospective: Iteration 009

**Schema**: v1
**Date**: 2026-05-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-901 | 4 | 4 | 0 |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0

## What Went Well

- Reviewer closeout stayed deterministic.

## What Didn't Go Well

- None material.

## Improvement Actions

1. Keep reviewer closeout artifacts mandatory for code-touching iterations.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $legacyIterationDirectory -ChildPath 'plan.md'), @'
# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 2/20 story_points
**Started**: 2026-05-05
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-501 | Historical reviewer closeout slice | FR-046, FR-049 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the legacy fixture scope-bounded. |
| Time Limit (hours) | n/a | Not used for this fixture. |
| Overcommit Threshold | 1.0 | No overcommit expected. |
| Defer Strategy | manual | Legacy fixture does not auto-defer work. |
| Calibration Enabled | true | Included for contract completeness. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Historical reviewer closeout planning |
| Implementation | 1 | Historical reviewer closeout implementation |
| Review | 0 | No additional review effort in the legacy fixture |
| Rework | 0 | No expected rework |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $legacyIterationDirectory -ChildPath 'state.md'), @'
# Iteration State: 005

**Schema**: v1
**Last Completed Task**: T-501
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: legacy-pre-reviewer-baseline
**Updated**: 2026-05-05T18:00:00Z

## Execution Summary

- Historical reviewer closeout slice completed before closeout packet enforcement existed.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $legacyIterationDirectory -ChildPath 'drift-log.md'), @'
# Drift Log: Iteration 005

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 0% (0/0 resolved)
**Specification drift**: None detected
**Implementation drift**: None detected

## Drift Events

- none

## Resolution Breakdown

- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $legacyIterationDirectory -ChildPath 'review.md'), @'
# Review: Iteration 005

**Schema**: v1
**Reviewed**: 2026-05-05
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-501 | FR-046, FR-049 | pass | Historical reviewer closeout was accepted before the reviewer packet contract became mandatory. |

## Gap Ledger

No known gaps remain.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $legacyIterationDirectory -ChildPath 'retro.md'), @'
# Retrospective: Iteration 005

**Schema**: v1
**Date**: 2026-05-05

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-501 | 2 | 2 | 0 |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- Historical reviewer closeout stayed lightweight and sufficient for its original contract.

## What Didn't Go Well

- None material.

## Improvement Actions

1. Keep newer reviewer closeout enforcement scoped to post-cutoff iterations.
'@, [System.Text.UTF8Encoding]::new($false))

$missingPacketOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot -IterationPath $iterationDirectory 2>&1)
if ($LASTEXITCODE -eq 0) {
    Write-Fail 'Validator unexpectedly passed without required reviewer closeout artifacts.'
    exit 1
}

$missingPacketText = ($missingPacketOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
foreach ($artifactName in @('code-map.md', 'coverage-evidence.md', 'reviewer-index.md', 'review-diagrams.md')) {
    if ($missingPacketText -notmatch [regex]::Escape($artifactName)) {
        Write-Fail "Validator did not report missing reviewer artifact: $artifactName"
        exit 1
    }
}

Write-Pass 'Validator rejects retro iteration without required reviewer closeout packet'

$reviewerOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewerScript -IterationDirectory $iterationDirectory 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Reviewer scaffold failed to generate the required closeout packet.'
    foreach ($line in $reviewerOutput) {
        Write-Host $line
    }
    exit 1
}

$passingOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot -IterationPath $iterationDirectory 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should pass after reviewer closeout artifacts are generated.'
    foreach ($line in $passingOutput) {
        Write-Host $line
    }
    exit 1
}

Write-Pass 'Validator accepts retro iteration after scaffold-reviewer-artifacts generates the closeout packet'

$legacyExplicitOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot -IterationPath $legacyIterationDirectory 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should accept an explicitly targeted legacy iteration when reviewer closeout enforcement is configured to start later.'
    foreach ($line in $legacyExplicitOutput) {
        Write-Host $line
    }
    exit 1
}

Write-Pass 'Validator accepts explicitly targeted legacy iterations before the configured reviewer-closeout cutoff'

# Additional test for lockout-chain cap visibility in reviewer closeout packet
Write-Host ''
Write-Host 'Testing lockout-chain cap visibility in reviewer closeout...'

$capFixturePath = Join-Path $repoRoot 'tests\integration\fixtures\lockout-chain-cap\project'
if (-not (Test-Path -LiteralPath $capFixturePath -PathType Container)) {
    Write-Fail "Missing lockout-chain-cap fixture: $capFixturePath"
    exit 1
}

$capIterationDir = Join-Path $capFixturePath 'specs\008-sample\iterations\001'
$capStatePath = Join-Path $capIterationDir 'state.md'

if (-not (Test-Path -LiteralPath $capStatePath -PathType Leaf)) {
    Write-Fail "Missing state.md in lockout-chain-cap fixture: $capStatePath"
    exit 1
}

$capStateContent = Get-Content -LiteralPath $capStatePath -Raw -Encoding UTF8

if ($capStateContent -notmatch '## Reviewer Regression State') {
    Write-Fail 'Reviewer regression state block missing from lockout-chain-cap fixture state.md'
    exit 1
}

if ($capStateContent -notmatch 'Cap Active.*true') {
    Write-Fail 'Cap Active should be true in lockout-chain-cap fixture state.md'
    exit 1
}

if ($capStateContent -notmatch 'Lockout Chain Length.*3') {
    Write-Fail 'Lockout Chain Length should be 3 in lockout-chain-cap fixture state.md'
    exit 1
}

if ($capStateContent -notmatch 'Next Owner Path.*Awaiting') {
    Write-Fail 'Next Owner Path should indicate awaiting human or alternate in lockout-chain-cap fixture state.md'
    exit 1
}

if ($capStateContent -notmatch 'Implementer Chain') {
    Write-Fail 'Implementer Chain should be listed in lockout-chain-cap fixture state.md'
    exit 1
}

Write-Pass 'Lockout-chain cap state is visible in reviewer-regression-state managed block'

exit 0
