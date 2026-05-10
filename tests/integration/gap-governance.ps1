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

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validateScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$reviewerScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'

foreach ($requiredPath in @($validateScript, $reviewerScript, $sharedGovernancePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredPath"
        exit 1
    }
}

. $sharedGovernancePath

$scratchRoot = Join-Path $repoRoot '.scratch\gap-governance'
$projectRoot = Join-Path $scratchRoot 'project'
$iterationDirectory = Join-Path $projectRoot 'specs\001-gap-governance\iterations\007'
$decisionsPath = Join-Path $projectRoot '.squad\decisions.md'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $iterationDirectory -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.squad') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests\integration') -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to initialize scratch git repo.'
    exit 1
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\iteration-config.yml'), @'
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"
reviewer:
  test_path_globs:
    - "**/tests/**"
    - "**/*test*.*"
  sensitive_data_patterns:
    - "auth*"
    - "token*"
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

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), @'
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

[System.IO.File]::WriteAllText((Join-Path $projectRoot 'package.json'), @'
{
  "name": "gap-governance",
  "version": "1.0.0",
  "dependencies": {
    "chalk": "^5.4.1"
  }
}
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\app.js'), @'
export function loadWidget() {
  return "baseline";
}
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $projectRoot 'tests\integration\app.test.js'), @'
import { loadWidget } from "../../src/app.js";

console.log(loadWidget());
'@, [System.Text.UTF8Encoding]::new($false))

$baselineCommit = @(
    & git -C $projectRoot add . 2>&1
    & git -C $projectRoot -c user.name=Copilot -c user.email=copilot@example.com commit -m "baseline" --quiet 2>&1
    & git -C $projectRoot tag iteration-baseline 2>&1
)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to create baseline git state for the gap-governance test.'
    foreach ($line in $baselineCommit) {
        Write-Host $line
    }
    exit 1
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\app.js'), @'
export function loadWidget() {
  return "iteration-seven";
}

export function loadAdminWidget() {
  return "admin";
}
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'plan.md'), @'
# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 3/20 story_points
**Started**: 2026-05-06
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-701 | Harden no-gap closure | FR-044 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-702 | Mirror runtime routing evidence | FR-043 | US-2 | 1 | Implementer | done | copilot-agent | 1 | pass |

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
| Planning | 1 | Governance slice was already clarified. |
| Discovery/Spikes | 0 | No extra spikes required. |
| Implementation | 2 | Runtime evidence and validator enforcement. |
| Review | 1 | Closeout and replay verification. |
| Rework | 0 | No expected buffer. |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'state.md'), @'
# Iteration State: 007

**Schema**: v1
**Last Completed Task**: T-702
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: iteration-baseline
**Updated**: 2026-05-06T15:00:00Z

## Execution Summary

- Governance hardening slice completed.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'drift-log.md'), @'
# Drift Log: Iteration 007

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

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'review.md'), @'
# Review: Iteration 007

**Schema**: v1
**Reviewed**: 2026-05-06
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-701 | FR-044 | pass | No-gap closure enforcement was verified against canonical defer evidence. |
| T-702 | FR-043 | pass | Reviewer output now surfaces routing fallback evidence from the shared ledger. |

## Gap Ledger

- FR-044 deferred with approval: reviewer-index triage copy remains follow-up work; see .squad\decisions.md for the canonical defer record.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'retro.md'), @'
# Retrospective: Iteration 007

**Schema**: v1
**Date**: 2026-05-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T-701 | 2 | 2 | 0 |
| T-702 | 1 | 1 | 0 |

**Average variance**: +/- 0.0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | |
| Discovery/Spikes | 0 | 0 | 0 | |
| Implementation | 2 | 2 | 0 | |
| Review | 1 | 1 | 0 | |
| Rework | 0 | 0 | 0 | |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0

## What Went Well

- Governance evidence stayed explicit.

## What Didn't Go Well

- One known gap still needed an approved defer.

## Improvement Actions

1. Finish the deferred reviewer-index follow-up next iteration.
'@, [System.Text.UTF8Encoding]::new($false))

$validatorFailure = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validateScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -eq 0) {
    Write-Fail 'Governance validation should reject an accepted deferred gap without a canonical defer entry.'
    exit 1
}

$validatorFailureText = $validatorFailure -join "`n"
if (-not (Assert-Contains -Content $validatorFailureText -Pattern 'Deferred gap entries require a canonical defer entry with approving human' -FailureMessage 'Validator did not explain the missing canonical defer entry.')) {
    exit 1
}

Add-StructuredDecisionsLedgerEntry -ProjectRoot $projectRoot -Title 'Approved defer for reviewer-index gap' -Type 'defer' -AffectedRequirement 'FR-044' -AffectedIteration 'specs\001-gap-governance\iterations\007' -ApprovingHuman 'Alon' -NextAction 'Finish reviewer-index follow-up in Iteration 008.' -Rationale 'The reviewer-index gap is understood, low-risk, and explicitly deferred with human approval.' -DetailLines @(
    '- **Affected Artifact**: specs\001-gap-governance\iterations\007\review.md'
) | Out-Null

Add-StructuredDecisionsLedgerEntry -ProjectRoot $projectRoot -Title 'Routing evidence for reviewer fallback' -Type 'routing-evidence' -AffectedRequirement 'FR-043' -AffectedIteration 'specs\001-gap-governance\iterations\007' -NextAction 'none' -Rationale 'Reviewer closeout routing fell back because the preferred delegated family was unavailable during the iteration.' -DetailLines @(
    "- **Routing Evidence**: Reviewer | requested=codex | actual=claude | model=claude-sonnet-4.5 | status=fell-back | fallback=preferred agent 'codex' is not enabled"
) | Out-Null

$routingEvidence = @(Get-RoutingEvidenceRecords -ProjectRoot $projectRoot -IterationRelativePath 'specs\001-gap-governance\iterations\007')
if ($routingEvidence.Count -ne 1 -or
    $routingEvidence[0].RequestedClass -ne 'codex' -or
    $routingEvidence[0].EffectiveClass -ne 'claude' -or
    $routingEvidence[0].Status -ne 'fell-back') {
    Write-Fail 'Shared routing-evidence helper did not parse requested/effective routing details correctly.'
    exit 1
}

Write-Pass 'Shared routing-evidence helper parses canonical fallback entries'

$hardeningGatePath = Join-Path $iterationDirectory 'quality\hardening-gate.md'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $hardeningGatePath) -Force
[System.IO.File]::WriteAllText($hardeningGatePath, @'
# Hardening Gate: Iteration 007

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/001-gap-governance/spec.md`
**Iteration Ref**: `specs/001-gap-governance/iterations/007`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `blocked`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-05-08T19:00:00Z

## Concern Review

| Concern | Category | Status | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `true` | Covered before implementation. | `—` |
| `operational-resilience-concerns` | `operational` | `deferred-with-approval` | `true` | The follow-up is recorded with an explicit defer. | `defer-canonical-hardening` |
| `test-integrity-targets` | `test-integrity` | `tbd` | `true` | Missing evidence still blocks readiness. | `—` |
'@, [System.Text.UTF8Encoding]::new($false))

Add-StructuredDecisionsLedgerEntry -ProjectRoot $projectRoot -Title 'Approved defer for hardening follow-up' -Type 'defer' -DecisionId 'defer-canonical-hardening' -AffectedRequirement 'FR-033' -AffectedIteration 'specs\001-gap-governance\iterations\007' -ApprovingHuman 'Alon' -NextAction 'Resolve operational resilience concern before implementation proceeds.' -Rationale 'The operational follow-up is acceptable to defer briefly while the remaining blocking concern is resolved.' -DetailLines @(
    '- **Affected Artifact**: specs\001-gap-governance\iterations\007\quality\hardening-gate.md'
) | Out-Null

$hardeningState = Get-HardeningGateState -Path $hardeningGatePath -ProjectRoot $projectRoot
if (-not $hardeningState.BlocksImplementation -or
    $hardeningState.BlockingConcerns.Count -ne 1 -or
    $hardeningState.BlockingConcerns[0].Concern -ne 'test-integrity-targets' -or
    -not (Test-ApprovalReferenceHasHumanApproval -ProjectRoot $projectRoot -ApprovalRef 'defer-canonical-hardening' -AllowedTypes @('defer'))) {
    Write-Fail 'Shared hardening helper did not respect human-approved deferrals while keeping unresolved TBD concerns blocking.'
    exit 1
}

Write-Pass 'Shared hardening helpers keep approved deferrals distinct from blocking TBD concerns'

$reviewerRun = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewerScript -IterationDirectory $iterationDirectory 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Reviewer artifact scaffolding failed for the gap-governance test.'
    foreach ($line in $reviewerRun) {
        Write-Host $line
    }
    exit 1
}

$validatorPass = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validateScript -ProjectPath $projectRoot 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Governance validation should accept the deferred gap once canonical approval is recorded.'
    foreach ($line in $validatorPass) {
        Write-Host $line
    }
    exit 1
}

Write-Pass 'Validator enforces canonical defer evidence for accepted deferred gaps'

$reviewerIndexPath = Join-Path $iterationDirectory 'reviewer-index.md'
$reviewerIndexContent = Get-Content -LiteralPath $reviewerIndexPath -Raw -Encoding UTF8

foreach ($check in @(
        @{ Pattern = 'Operational Signals: escalations=0 \| routing_fallbacks=1'; Failure = 'Reviewer summary did not surface the routing fallback count from .squad\decisions.md.' },
        @{ Pattern = 'Gap concern: FR-044 deferred with approval: reviewer-index triage copy remains follow-up work; see \.squad\\decisions\.md for the canonical defer record\.'; Failure = 'Reviewer triage hints did not mirror the active gap-ledger concern.' },
        @{ Pattern = 'Routing fallbacks recorded: 1'; Failure = 'Reviewer triage hints did not call out the routing fallback signal.' }
    )) {
    if (-not (Assert-Contains -Content $reviewerIndexContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}

Write-Pass 'Reviewer index mirrors active gap concerns and routing fallback evidence'

Write-Host "`nTest 13: reviewer-regression ledger presence does not trigger false-positive gaps"
$reviewerRegressionLedgerPath = Join-Path $projectRoot '.specrew\reviewer-regression-log.md'
[System.IO.File]::WriteAllText($reviewerRegressionLedgerPath, @'
# Reviewer Regression Ledger

**Schema**: v1  
**Last Updated**: 2026-05-10

---

## Event RRE-001

- **Feature**: specs/001-gap-governance
- **Event Status**: resolved
- **Recorded At**: 2026-05-10T10:00:00Z

---
'@, [System.Text.UTF8Encoding]::new($false))

$validatorFinalOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validateScript -ProjectPath $projectRoot -IterationPath $iterationDirectory 2>&1)
$validatorFinalText = ($validatorFinalOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Validator should accept reviewer-regression ledger without gap warnings.`n$validatorFinalText"
    exit 1
}

if ($validatorFinalText -match 'reviewer-regression-log\.md.*gap') {
    Write-Fail "Validator should not flag reviewer-regression ledger as a gap."
    exit 1
}

Write-Pass "Reviewer-regression ledger presence does not trigger false-positive gaps"

Write-Host "`nAll gap governance tests passed successfully" -ForegroundColor Green
exit 0
