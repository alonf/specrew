[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host ("PASS: {0}" -f $Message) -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host ("FAIL: {0}" -f $Message) -ForegroundColor Red
}

function Invoke-ResumeScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateSet('continue', 'replan', 'abort')]
        [string]$ResumeMode
    )

    return (& '.\extensions\specrew-speckit\scripts\resume-iteration.ps1' -IterationDirectory $IterationDirectory -ResumeMode $ResumeMode -PassThru)
}

$scratchRoot = Join-Path -Path (Resolve-Path '.').Path -ChildPath '.scratch\iteration-resume'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$iterationDirectory = Join-Path $scratchRoot 'specs\001-resume\iterations\001'
$null = New-Item -Path $iterationDirectory -ItemType Directory -Force

$planPath = Join-Path $iterationDirectory 'plan.md'
$statePath = Join-Path $iterationDirectory 'state.md'
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $iterationDirectory))
$null = New-Item -Path (Join-Path $projectRoot '.specrew') -ItemType Directory -Force

$planContent = @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 3/5 story_points
**Started**: 2026-05-03
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | First task | FR-005 | US-2 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-002 | Resume-safe task | FR-019 | US-2 | 1 | Implementer | planned |  |  |  |
| T-003 | Review guard | FR-009 | US-2 | 1 | Reviewer | planned |  |  |  |
'@

$stateContent = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002, T-003
**In Progress**: (none)
**Updated**: 2026-05-03T00:00:00Z

## Execution Summary

- Execution was interrupted after T-001 completed.
'@

$partialStateContent = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002, T-003

## Execution Summary

- Execution metadata is incomplete and should be repaired during resume.
'@

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))

$continueResult = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'continue'
if ($continueResult.status -ne 'ready' -or $continueResult.next_suggested_task -ne 'T-002') {
    Write-Fail "Continue mode should suggest T-002 as the next task."
    exit 1
}

$updatedState = Get-Content -LiteralPath $statePath -Raw
if ($updatedState -notmatch '\*\*In Progress\*\*:\s*T-002') {
    Write-Fail 'Continue mode should update state.md to mark T-002 in progress.'
    exit 1
}

if ($updatedState -notmatch '\*\*Tasks Remaining\*\*:\s*T-003') {
    Write-Fail 'Continue mode should remove the resumed task from Tasks Remaining.'
    exit 1
}

if ($updatedState -notmatch '## Resume Report') {
    Write-Fail 'Continue mode should write a resume report into state.md.'
    exit 1
}

Write-Pass 'Continue mode resumed from the last completed task and updated state.md'

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $partialStateContent, [System.Text.UTF8Encoding]::new($false))

$partialResult = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'continue'
if ($partialResult.status -ne 'ready' -or $partialResult.next_suggested_task -ne 'T-002') {
    Write-Fail 'Continue mode should still recover when state metadata fields are missing.'
    exit 1
}

$partialState = Get-Content -LiteralPath $statePath -Raw
if ($partialState -notmatch '\*\*Tasks Remaining\*\*:\s*T-003' -or $partialState -notmatch '\*\*In Progress\*\*:\s*T-002' -or $partialState -notmatch '\*\*Updated\*\*:\s*\d{4}-\d{2}-\d{2}T') {
    Write-Fail 'Resume should restore missing Tasks Remaining, In Progress, and Updated metadata fields in state.md.'
    exit 1
}

Write-Pass 'Continue mode repairs missing state metadata fields while resuming execution'

$staleStateContent = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-003
**In Progress**: (none)
**Updated**: 2026-05-03T00:00:00Z

## Execution Summary

- Tasks Remaining is stale and should be repaired from plan.md.
'@

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $staleStateContent, [System.Text.UTF8Encoding]::new($false))

$staleResult = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'continue'
if ($staleResult.status -ne 'ready' -or $staleResult.next_suggested_task -ne 'T-002') {
    Write-Fail 'Continue mode should recover the next task from plan.md when Tasks Remaining is stale.'
    exit 1
}

$staleState = Get-Content -LiteralPath $statePath -Raw
if ($staleState -notmatch '\*\*Tasks Remaining\*\*:\s*T-003' -or $staleState -notmatch '\*\*In Progress\*\*:\s*T-002') {
    Write-Fail 'Resume should repair stale Tasks Remaining data before marking the next task in progress.'
    exit 1
}

Write-Pass 'Continue mode repairs stale Tasks Remaining metadata from the plan task table'

$blockedPlanContent = @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 3/5 story_points
**Started**: 2026-05-03
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | First task | FR-005 | US-2 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-002 | Blocked task | FR-019 | US-2 | 1 | Implementer | blocked |  |  |  |
| T-003 | Downstream task | FR-009 | US-2 | 1 | Reviewer | planned |  |  |  |
'@
[System.IO.File]::WriteAllText($planPath, $blockedPlanContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))

$blockedResult = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'continue'
if ($blockedResult.status -ne 'blocked' -or $blockedResult.next_suggested_task) {
    Write-Fail 'Blocked continue mode should report blocked status with no next task.'
    exit 1
}

$blockedState = Get-Content -LiteralPath $statePath -Raw
if ($blockedState -match '## Resume Report') {
    Write-Fail 'Blocked resume should not write a resume report into state.md.'
    exit 1
}

Write-Pass 'Blocked resume path preserved state.md and surfaced the blocker'

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))

$abortResult = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'abort'
if ($abortResult.status -ne 'needs-replan' -or -not $abortResult.salvageable_tasks -or $abortResult.salvageable_tasks.Count -ne 2) {
    Write-Fail 'Abort mode should report salvageable remaining tasks.'
    exit 1
}

$abortState = Get-Content -LiteralPath $statePath -Raw
if ($abortState -notmatch 'Salvageable Tasks') {
    Write-Fail 'Abort mode should record salvageable tasks in the resume report.'
    exit 1
}

Write-Pass 'Abort mode reports salvageable tasks for re-planning'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

Write-Pass 'Iteration resume integration checks passed'
exit 0
