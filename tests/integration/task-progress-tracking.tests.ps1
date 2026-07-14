[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$taskProgressHelperPath = Join-Path $repoRoot 'scripts\internal\task-progress.ps1'
. $taskProgressHelperPath

$scratchRoot = Join-Path $repoRoot '.scratch\task-progress-tracking'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'project'
$featureRoot = Join-Path $projectRoot 'specs\020-session-state-durability'
$iterationRoot = Join-Path $featureRoot 'iterations\002'
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents', '-SkipUpdateCheck')
if ($initResult.ExitCode -ne 0) {
    Write-Fail ("Bootstrap failed:`n{0}" -f ($initResult.Output -join [Environment]::NewLine))
    exit 1
}

$null = New-Item -ItemType Directory -Path $iterationRoot -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\020-session-state-durability\iterations\002\plan.md') -Destination (Join-Path $iterationRoot 'plan.md') -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\020-session-state-durability\tasks.md') -Destination (Join-Path $featureRoot 'tasks.md') -Force
[System.IO.File]::WriteAllText((Join-Path $featureRoot 'spec.md'), "# Feature 020`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/020-session-state-durability`"`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $iterationRoot 'state.md'), @'
# Iteration State: 002

**Schema**: v1
**Last Completed Task**: (none)
**Tasks Remaining**: I2-T001, I2-T002, I2-T003
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-05-18T00:00:00Z

## Execution Summary

- Execution has not started yet.
- This artifact was scaffolded before task execution so resume state can be updated after each task.
'@, [System.Text.UTF8Encoding]::new($false))

Sync-IterationTaskProgress -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' | Out-Null
$stateAfterInitialSync = Get-Content -LiteralPath (Join-Path $iterationRoot 'state.md') -Raw -Encoding UTF8
if ($stateAfterInitialSync -notmatch '\*\*Current Phase\*\*:\s*before-implement' -or $stateAfterInitialSync -notmatch 'Execution has not started yet') {
    Write-Fail 'Not-started task reconciliation should keep state.md in a planning/not-started shape.'
    exit 1
}
Write-Pass 'Not-started task reconciliation keeps state.md consistent'

$progressResult = Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001' -Status 'in-progress'
if ([string]::IsNullOrWhiteSpace([string]$progressResult.StartedAt)) {
    Write-Fail 'In-progress transition did not record started_at.'
    exit 1
}
Write-Pass 'In-progress transition records started_at'

$stateAfterProgress = Get-Content -LiteralPath (Join-Path $iterationRoot 'state.md') -Raw -Encoding UTF8
if ($stateAfterProgress -notmatch '\*\*In Progress\*\*:\s*I2-T001' -or $stateAfterProgress -match 'Execution has not started yet') {
    Write-Fail 'In-progress transition should update state.md and remove scaffold execution text.'
    exit 1
}
Write-Pass 'In-progress transition updates iteration state.md'

$completeResult = Set-TaskComplete -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001'
if ([string]::IsNullOrWhiteSpace([string]$completeResult.CompletedAt)) {
    Write-Fail 'Complete transition did not record completed_at.'
    exit 1
}
Write-Pass 'Complete transition records completed_at'

$stateAfterComplete = Get-Content -LiteralPath (Join-Path $iterationRoot 'state.md') -Raw -Encoding UTF8
if ($stateAfterComplete -notmatch '\*\*Last Completed Task\*\*:\s*I2-T001' -or $stateAfterComplete -notmatch '\*\*Tasks Remaining\*\*:\s*I2-T002,\s*I2-T003') {
    Write-Fail 'Complete transition should refresh Last Completed Task and Tasks Remaining in state.md.'
    exit 1
}
Write-Pass 'Complete transition refreshes iteration state.md'

Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001' -Status 'pending' | Out-Null
$stateAfterPending = Get-Content -LiteralPath (Join-Path $iterationRoot 'state.md') -Raw -Encoding UTF8
if ($stateAfterPending -notmatch '\*\*Current Phase\*\*:\s*before-implement' -or $stateAfterPending -notmatch '\*\*Iteration Status\*\*:\s*not-started') {
    Write-Fail 'Pending-only task state should not be labeled as implement.'
    exit 1
}
Write-Pass 'Pending-only task state remains before-implement/not-started'
Set-TaskComplete -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T001' | Out-Null

$blockedWithoutReasonFailed = $false
try {
    Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T002' -Status 'blocked' | Out-Null
}
catch {
    $blockedWithoutReasonFailed = $true
}

if (-not $blockedWithoutReasonFailed) {
    Write-Fail 'Blocked transition should require a blocked_reason.'
    exit 1
}
Write-Pass 'Blocked transition requires blocked_reason'

$blockedResult = Set-TaskBlocked -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T002' -Reason 'Waiting for approval'
if ($blockedResult.BlockedReason -ne 'Waiting for approval') {
    Write-Fail 'Blocked transition did not persist blocked_reason.'
    exit 1
}
Write-Pass 'Blocked transition persists blocked_reason'

[System.IO.File]::WriteAllText((Join-Path $featureRoot 'tasks.md'), "# Regenerated task list`n", [System.Text.UTF8Encoding]::new($false))
$summary = Get-TaskProgressSummary -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002'
if (@($summary.Complete | Where-Object { $_.id -eq 'I2-T001' }).Count -ne 1) {
    Write-Fail 'Task progress did not survive tasks.md regeneration.'
    exit 1
}
Write-Pass 'Task progress survives tasks.md regeneration'

$validatorSummaryPath = Join-Path $projectRoot '.specrew\last-validator-summary.json'
[System.IO.File]::WriteAllText($validatorSummaryPath, @'
{
  "recorded_at": "2026-05-18T00:00:00Z",
  "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File .\\extensions\\specrew-speckit\\scripts\\validate-governance.ps1 -ProjectPath . -IterationPath .\\specs\\020-session-state-durability\\iterations\\002",
  "warnings": {
    "total": 1,
    "soft": 1,
    "medium": 0,
    "hard": 0
  }
}
'@, [System.Text.UTF8Encoding]::new($false))
Set-TaskStatus -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' -TaskId 'I2-T003' -Status 'in-progress' | Out-Null

$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch', '-SkipUpdateCheck')
if ($startResult.ExitCode -ne 0) {
    Write-Fail ("Start command failed:`n{0}" -f ($startResult.Output -join [Environment]::NewLine))
    exit 1
}

$promptContent = Get-Content -LiteralPath (Join-Path $projectRoot '.specrew\last-start-prompt.md') -Raw -Encoding UTF8
foreach ($pattern in @('## Welcome Back Snapshot', 'I2-T003', 'Task progress: 1 complete, 1 in-progress', 'Validator state: 1 warnings: 1 soft, 0 medium, 0 hard', 'Suggested Next Actions')) {
    if ($promptContent -notmatch [regex]::Escape($pattern)) {
        Write-Fail ("Welcome-back prompt is missing expected pattern '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'Welcome-back prompt includes task progress and validator summary'

# Regression (Feature 141 class): when bare task IDs (T0NN) are reused across iterations, the
# feature-root tasks.md (which is the Iteration 1 task list) must NOT downgrade Iteration 2's
# live ledger status. Reproduces the start/resume summary corruption where iteration-002 done
# tasks were reported pending because iteration-1 tasks.md carried the same bare IDs unchecked.
$bareProject = Join-Path $scratchRoot 'bare-id-cross-iteration'
$bareFeature = '141-bare-id-sample'
$bareFeaturePath = Join-Path $bareProject "specs\$bareFeature"
$bareIterationPath = Join-Path $bareFeaturePath 'iterations\002'
$null = New-Item -ItemType Directory -Path $bareIterationPath -Force

# Feature-root tasks.md = Iteration 1's list (bare IDs, all unchecked — as in the real 141 repo).
@'
# Tasks

- [ ] T001 Iteration 1: confirm scope. (Trace: FR-1)
- [ ] T002 Iteration 1: scaffold. (Trace: FR-1)
- [ ] T003 Iteration 1: detection. (Trace: FR-1)
- [ ] T004 Iteration 1: parsing. (Trace: FR-1)
- [ ] T005 Iteration 1: validator. (Trace: FR-1)
- [ ] T006 Iteration 1: packet. (Trace: FR-1)
- [ ] T007 Iteration 1: persist packet. (Trace: FR-1)
- [ ] T008 Iteration 1: docs. (Trace: FR-1)
- [ ] T009 Iteration 1: unit tests. (Trace: FR-1)
'@ | Set-Content -LiteralPath (Join-Path $bareFeaturePath 'tasks.md') -Encoding UTF8

# Iteration 2 plan.md catalog: same bare IDs, DIFFERENT meaning (FR-024 slice T007-T009 done).
@'
# Iteration Plan: 002

**Schema**: v1
**Status**: executing

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T001 | Iter2 path repro | FR-011 | US0 | 1 | Spec Steward | planned |
| T002 | Iter2 path fix | FR-011 | US4 | 2 | Implementer | planned |
| T003 | Iter2 host wording | FR-014 | US7 | 2 | Implementer | planned |
| T004 | Iter2 harness cleanup | FR-015 | US0 | 1 | Implementer | planned |
| T005 | Iter2 tests | SC-007 | US4 | 2 | Implementer | planned |
| T006 | Iter2 docs | TG-006 | US0 | 1 | Planner | planned |
| T007 | Iter2 stale detect | FR-024 | US0 | 3 | Implementer | done |
| T008 | Iter2 safe cleanup | FR-024 | US0 | 2 | Implementer | done |
| T009 | Iter2 regression | FR-024 | US0 | 2 | Reviewer | done |
'@ | Set-Content -LiteralPath (Join-Path $bareIterationPath 'plan.md') -Encoding UTF8

# Live ledger: iteration-2 FR-024 slice done (T007/T008/T009); everything else pending.
@'
schema: "v1"
feature: "141-bare-id-sample"
iteration: "002"
updated_at: "2026-06-02T21:00:00Z"
tasks:
  T001:
    title: "Iter2 path repro"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T002:
    title: "Iter2 path fix"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T003:
    title: "Iter2 host wording"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T004:
    title: "Iter2 harness cleanup"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T005:
    title: "Iter2 tests"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T006:
    title: "Iter2 docs"
    status: "pending"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T007:
    title: "Iter2 stale detect"
    status: "done"
    started_at: "2026-06-02T19:00:00Z"
    completed_at: "2026-06-02T20:35:00Z"
    blocked_reason: ""
  T008:
    title: "Iter2 safe cleanup"
    status: "done"
    started_at: "2026-06-02T19:00:00Z"
    completed_at: "2026-06-02T20:35:00Z"
    blocked_reason: ""
  T009:
    title: "Iter2 regression"
    status: "done"
    started_at: "2026-06-02T20:35:00Z"
    completed_at: "2026-06-02T21:44:00Z"
    blocked_reason: ""
'@ | Set-Content -LiteralPath (Join-Path $bareIterationPath 'tasks-progress.yml') -Encoding UTF8

[System.IO.File]::WriteAllText((Join-Path $bareFeaturePath 'spec.md'), "# Feature 141 sample`n", [System.Text.UTF8Encoding]::new($false))

$bareSummary = Get-TaskProgressSummary -ProjectRoot $bareProject -FeatureRef $bareFeature -IterationNumber '002' -ResolvedFeaturePath $bareFeaturePath
$bareComplete = @($bareSummary.Complete | ForEach-Object { [string]$_.id })
$barePending = @($bareSummary.Pending | ForEach-Object { [string]$_.id })
foreach ($doneId in @('T007', 'T008', 'T009')) {
    if ($bareComplete -notcontains $doneId) {
        Write-Fail ("Iteration-2 '{0}' should be complete but was not (downgraded by the iteration-1 feature-root tasks.md). Complete=[{1}] Pending=[{2}]" -f $doneId, ($bareComplete -join ','), ($barePending -join ','))
        exit 1
    }
}
foreach ($pendingId in @('T001', 'T002', 'T003', 'T004', 'T005', 'T006')) {
    if ($barePending -notcontains $pendingId) {
        Write-Fail ("Iteration-2 '{0}' should be pending/remaining. Complete=[{1}] Pending=[{2}]" -f $pendingId, ($bareComplete -join ','), ($barePending -join ','))
        exit 1
    }
}
Write-Pass 'Iteration-2 bare-ID task progress is not downgraded by the Iteration-1 feature-root tasks.md'

# --- Hand-authored Execution Summary narrative is NEVER machinery-destroyed (DRIFT-198-I003-009, 2026-07-14) ---
# The old whole-section replacement collapsed a rich committed execution record to three generated bullets on any
# task-progress sync (the observed iteration-003/005 state truncations). The digest now lives in a marker-bounded
# managed block; the narrative below it survives every sync, idempotently.
$narrativeState = Join-Path $iterationRoot 'state.md'
$narrativeSentinel = 'Piece 3 DONE - the navigator FIRE decision now consumes the per-lineage lease (rich narrative sentinel 7719).'
$existingState = Get-Content -LiteralPath $narrativeState -Raw -Encoding UTF8
[System.IO.File]::WriteAllText($narrativeState, ($existingState.TrimEnd() + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
$withNarrative = $existingState -replace '(?ms)(^##\s+Execution Summary\s*\r?\n)', ('$1' + [Environment]::NewLine + '- ' + $narrativeSentinel + [Environment]::NewLine)
[System.IO.File]::WriteAllText($narrativeState, $withNarrative, [System.Text.UTF8Encoding]::new($false))
Sync-IterationTaskProgress -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' | Out-Null
$afterFirstSync = Get-Content -LiteralPath $narrativeState -Raw -Encoding UTF8
if ($afterFirstSync -notmatch [regex]::Escape($narrativeSentinel)) {
    Write-Fail 'A task-progress sync DESTROYED the hand-authored Execution Summary narrative (DRIFT-198-I003-009 regression).'
    exit 1
}
if ($afterFirstSync -notmatch [regex]::Escape('<!-- specrew:task-progress-summary:begin -->') -or $afterFirstSync -notmatch 'Task progress: \d+ complete') {
    Write-Fail 'The generated task-progress digest should be present in its marker-bounded managed block after a sync.'
    exit 1
}
Sync-IterationTaskProgress -ProjectRoot $projectRoot -FeatureRef '020-session-state-durability' -IterationNumber '002' | Out-Null
$afterSecondSync = Get-Content -LiteralPath $narrativeState -Raw -Encoding UTF8
if ($afterSecondSync -notmatch [regex]::Escape($narrativeSentinel)) {
    Write-Fail 'The SECOND sync destroyed the narrative - the managed block refresh is not scoped.'
    exit 1
}
if (([regex]::Matches($afterSecondSync, [regex]::Escape('<!-- specrew:task-progress-summary:begin -->'))).Count -ne 1) {
    Write-Fail 'Repeated syncs must refresh ONE managed block idempotently, never accumulate duplicates.'
    exit 1
}
Write-Pass 'Hand-authored Execution Summary narrative survives task-progress syncs; the managed digest refreshes idempotently (DRIFT-198-I003-009)'

exit 0
