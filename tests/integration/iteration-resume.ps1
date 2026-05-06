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

function Invoke-EscalationScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateSet('get', 'activate', 'resolve', 'clear')]
        [string]$Mode,

        [string]$Artifact,
        [string]$Gate,
        [string]$Owner,
        [string[]]$LockedOutAgents
    )

    $params = @{
        IterationDirectory = $IterationDirectory
        Mode               = $Mode
        PassThru           = $true
    }

    if ($PSBoundParameters.ContainsKey('Artifact')) {
        $params.Artifact = $Artifact
    }

    if ($PSBoundParameters.ContainsKey('Gate')) {
        $params.Gate = $Gate
    }

    if ($PSBoundParameters.ContainsKey('Owner')) {
        $params.Owner = $Owner
    }

    if ($PSBoundParameters.ContainsKey('LockedOutAgents')) {
        $params.LockedOutAgents = $LockedOutAgents
    }

    return (& '.\extensions\specrew-speckit\scripts\manage-escalation-state.ps1' @params)
}

function Invoke-SyncModelOverrideScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory
    )

    return (& '.\extensions\specrew-speckit\scripts\sync-squad-model-overrides.ps1' -IterationDirectory $IterationDirectory -PassThru)
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
$null = New-Item -Path (Join-Path $projectRoot '.squad') -ItemType Directory -Force
$squadConfigPath = Join-Path $projectRoot '.squad\config.json'
$decisionsPath = Join-Path $projectRoot '.squad\decisions.md'

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
[System.IO.File]::WriteAllText($squadConfigPath, @'
{
  "version": 1,
  "agentModelOverrides": {
    "Reviewer": "claude-sonnet-4.5",
    "Spec Steward": "gpt-5.2-codex"
  },
  "specrewManagedModelRouting": {
    "baselineAgentModelOverrides": {
      "Reviewer": "claude-sonnet-4.5",
      "Spec Steward": "gpt-5.2-codex"
    },
    "roleAgentFamilies": {
      "Planner": "copilot",
      "Implementer": "copilot",
      "Reviewer": "claude",
      "Spec Steward": "codex",
      "Retro Facilitator": "copilot"
    },
    "activeEscalation": {
      "status": "inactive",
      "role": null,
      "tier": "efficiency",
      "sourceIteration": null,
      "sourceArtifact": null,
      "sourceGate": null,
      "updatedAt": null
    }
  }
}
'@, [System.Text.UTF8Encoding]::new($false))

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

$stateWithEscalationContent = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002, T-003
**In Progress**: (none)
**Updated**: 2026-05-03T00:00:00Z

## Execution Summary

- Execution paused after the first validation failure.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->
'@

[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $stateWithEscalationContent, [System.Text.UTF8Encoding]::new($false))

$firstEscalation = Invoke-EscalationScript -IterationDirectory $iterationDirectory -Mode 'activate' -Artifact 'tasks.md' -Gate 'after-tasks' -Owner 'Oracle' -LockedOutAgents @('Morpheus')
if ($firstEscalation.status -ne 'active' -or $firstEscalation.failure_count -ne 1 -or $firstEscalation.current_tier -ne 'balanced') {
    Write-Fail 'First escalation activation should persist a balanced active repair cycle.'
    exit 1
}

$secondEscalation = Invoke-EscalationScript -IterationDirectory $iterationDirectory -Mode 'activate' -Artifact 'tasks.md' -Gate 'after-tasks' -Owner 'Planner'
if ($secondEscalation.status -ne 'active' -or $secondEscalation.failure_count -ne 2 -or $secondEscalation.current_tier -ne 'deep') {
    Write-Fail 'Second escalation activation should escalate the repair tier to deep reasoning.'
    exit 1
}

if ($secondEscalation.locked_out_agents -notcontains 'Morpheus' -or $secondEscalation.locked_out_agents -notcontains 'Oracle') {
    Write-Fail 'Escalation should preserve prior lockouts and lock out the previous repair owner.'
    exit 1
}

$syncedEscalation = Invoke-SyncModelOverrideScript -IterationDirectory $iterationDirectory
if ($syncedEscalation.escalation_status -ne 'active' -or $syncedEscalation.escalation_role -ne 'Planner' -or $syncedEscalation.applied_model -ne 'gpt-5.4') {
    Write-Fail 'Sync helper should apply a deep repair override for the active escalation owner.'
    exit 1
}

$syncedConfig = Get-Content -LiteralPath $squadConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($syncedConfig.agentModelOverrides.Planner -ne 'gpt-5.4' -or $syncedConfig.agentModelOverrides.Reviewer -ne 'claude-sonnet-4.5') {
    Write-Fail 'Sync helper should merge the escalation override with the baseline delegated overrides.'
    exit 1
}

if ($syncedConfig.specrewManagedModelRouting.activeEscalation.status -ne 'active' -or $syncedConfig.specrewManagedModelRouting.activeEscalation.role -ne 'Planner') {
    Write-Fail 'Sync helper should persist active escalation metadata into .squad\config.json.'
    exit 1
}

$escalatedResume = Invoke-ResumeScript -IterationDirectory $iterationDirectory -ResumeMode 'continue'
if ($escalatedResume.status -ne 'ready' -or $escalatedResume.next_suggested_task -or $escalatedResume.repair_escalation.status -ne 'active') {
    Write-Fail 'Resume should prioritize an active repair escalation over normal task resumption.'
    exit 1
}

if ($escalatedResume.next_recovery_action -notmatch 'tasks\.md' -or $escalatedResume.next_recovery_action -notmatch 'Planner' -or $escalatedResume.next_recovery_action -notmatch 'deep') {
    Write-Fail 'Resume should surface the active escalation owner, artifact, and tier.'
    exit 1
}

$escalatedState = Get-Content -LiteralPath $statePath -Raw
if ($escalatedState -notmatch '\*\*Repair Escalation\*\*:\s*tasks\.md \| owner=Planner \| tier=deep \| failures=2') {
    Write-Fail 'Resume report should record the active escalation summary.'
    exit 1
}

$resolvedEscalation = Invoke-EscalationScript -IterationDirectory $iterationDirectory -Mode 'resolve'
if ($resolvedEscalation.status -ne 'inactive' -or $resolvedEscalation.current_tier -ne 'efficiency' -or $resolvedEscalation.current_owner) {
    Write-Fail 'Resolved escalation should de-escalate to the default efficiency tier and clear the temporary owner override.'
    exit 1
}

$resolvedSync = Invoke-SyncModelOverrideScript -IterationDirectory $iterationDirectory
if ($resolvedSync.escalation_status -ne 'inactive' -or $resolvedSync.applied_model) {
    Write-Fail 'Resolving escalation should remove the temporary live model override.'
    exit 1
}

$resolvedState = Get-Content -LiteralPath $statePath -Raw
if ($resolvedState -notmatch '\*\*Status\*\*:\s*inactive' -or $resolvedState -notmatch '\*\*Current Tier\*\*:\s*efficiency' -or $resolvedState -notmatch '\*\*Current Owner\*\*:\s*\(none\)') {
    Write-Fail 'Resolving escalation should persist a de-escalated inactive state in state.md.'
    exit 1
}

$resolvedConfig = Get-Content -LiteralPath $squadConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($resolvedConfig.agentModelOverrides.PSObject.Properties.Name -contains 'Planner') {
    Write-Fail 'Resolved sync should restore baseline overrides without keeping the temporary escalation owner override.'
    exit 1
}

if ($resolvedConfig.agentModelOverrides.Reviewer -ne 'claude-sonnet-4.5' -or $resolvedConfig.specrewManagedModelRouting.activeEscalation.status -ne 'inactive') {
    Write-Fail 'Resolved sync should restore baseline delegated overrides and mark escalation inactive.'
    exit 1
}

if (-not (Test-Path -LiteralPath $decisionsPath -PathType Leaf)) {
    Write-Fail 'Escalation flow should write audit entries into .squad\decisions.md.'
    exit 1
}

$decisionsContent = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
foreach ($pattern in @(
        'Repair escalation activated',
        'Repair escalation resolved',
        'Repair escalation routing sync',
        '\*\*Artifact\*\*:\s*tasks\.md',
        '\*\*Applied Model\*\*:\s*gpt-5\.4'
    )) {
    if ($decisionsContent -notmatch $pattern) {
        Write-Fail "Escalation audit trail is missing expected ledger content matching: $pattern"
        exit 1
    }
}

Write-Pass 'Escalation state persists across resume and de-escalates after success'

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
