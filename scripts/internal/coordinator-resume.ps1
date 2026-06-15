Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$taskProgressHelperPath = Join-Path $PSScriptRoot 'task-progress.ps1'
if (-not (Test-Path -LiteralPath $taskProgressHelperPath -PathType Leaf)) {
    throw "Missing task-progress helper '$taskProgressHelperPath'."
}
. $taskProgressHelperPath

$worktreeHelperPath = Join-Path $PSScriptRoot 'worktree-awareness.ps1'
if (-not (Test-Path -LiteralPath $worktreeHelperPath -PathType Leaf)) {
    throw "Missing worktree-awareness helper '$worktreeHelperPath'."
}
. $worktreeHelperPath

$boundaryStateHelperPath = Join-Path $PSScriptRoot 'sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $boundaryStateHelperPath -PathType Leaf)) {
    throw "Missing boundary-state helper '$boundaryStateHelperPath'."
}
. $boundaryStateHelperPath

# F-174 iter-10 (T008): the rolling-handover read + the SHARED resume reconciliation. `specrew start` is the
# ONLY recovery path for antigravity (no hooks) and for any non-hook launch, so it must surface the same
# git-delta resume context the SessionStart hook does. Dot-source the two bootstrap components that own those
# functions; fail-open so a missing/broken component degrades the snapshot rather than failing the launcher.
foreach ($bootstrapDep in @('bootstrap\HandoverStore.ps1', 'bootstrap\ProjectMetadataAccessor.ps1')) {
    $bootstrapDepPath = Join-Path $PSScriptRoot $bootstrapDep
    if (Test-Path -LiteralPath $bootstrapDepPath -PathType Leaf) {
        try { . $bootstrapDepPath } catch { $null = $_ }
    }
}

function Get-ResumeSessionStateProp {
    # StrictMode-safe property read: returns the property value if present on the object, else $null.
    # Get-SpecrewProp (the project-wide equivalent) lives in SessionStateAccessor.ps1, which is NOT in
    # this file's dot-source chain - so this local reader keeps coordinator-resume dependency-free.
    param([AllowNull()]$Object, [Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq $Object) { return $null }
    $match = $Object.PSObject.Properties.Match($Name)
    if ($match.Count -gt 0) { return $match[0].Value }
    return $null
}

function ConvertTo-NormalizedResumeSessionState {
    # F-174 iter-10 (T008 hardening): the resume snapshot is now the load-bearing recovery path for
    # `specrew start` (the ONLY recovery seam for antigravity, which has no hooks). Callers pass EITHER the
    # raw session anchor (Get-SpecrewSessionAnchor emits `boundary`/`iteration` and NO `task_id`) OR the
    # already-mapped generator shape (`boundary_type`/`iteration_number`/`task_id`). Under
    # Set-StrictMode -Version Latest (set at this file's scope) a direct `.iteration_number` read on the raw
    # anchor THROWS "property cannot be found" -> a HARD throw inside Get-StartPrompt (the call at
    # launch-contract.ps1 is NOT wrapped) -> crashed `specrew start` / silent provider fail-open: the same
    # D-009 trap class that already bit this feature. Both real callers map first, so production is safe
    # TODAY; this normalizes BOTH shapes to the generator shape ONCE so the snapshot body never reads an
    # absent property regardless of which caller (or any FUTURE caller) hands it which shape. Defense-in-
    # depth on the function T008 made load-bearing - it must never depend on the caller remembering to map.
    param([AllowNull()][pscustomobject]$SessionState)
    if ($null -eq $SessionState) { return $null }
    $iteration = Get-ResumeSessionStateProp $SessionState 'iteration_number'
    if ([string]::IsNullOrWhiteSpace([string]$iteration)) { $iteration = Get-ResumeSessionStateProp $SessionState 'iteration' }
    $boundary = Get-ResumeSessionStateProp $SessionState 'boundary_type'
    if ([string]::IsNullOrWhiteSpace([string]$boundary)) { $boundary = Get-ResumeSessionStateProp $SessionState 'boundary' }
    return [pscustomobject]@{
        feature_ref      = Get-ResumeSessionStateProp $SessionState 'feature_ref'
        feature_path     = Get-ResumeSessionStateProp $SessionState 'feature_path'
        boundary_type    = $boundary
        iteration_number = $iteration
        task_id          = Get-ResumeSessionStateProp $SessionState 'task_id'
    }
}

function Get-ValidatorSummaryPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Get-SpecrewValidatorSummaryPath -ProjectRoot $ProjectRoot
}

function Get-ValidatorWarningSummary {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $summaryPath = Get-ValidatorSummaryPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
        return $null
    }

    try {
        # F-023: Use -AsHashtable for StrictMode compatibility; hashtable indexer tolerates missing fields
        $summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 6

        # F-023: Legacy schema handling - missing 'schema' field implies v0
        $schema = Get-SpecrewStateSchemaVersion -State $summary -Path $summaryPath
        # v0/v1 behavior: warnings field structure is required in both schemas
        # v1+ behavior: same as v0 for this summary (no behavioral divergence yet)

        return [pscustomobject]@{
            total      = [int]$summary['warnings']['total']
            soft       = [int]$summary['warnings']['soft']
            medium     = [int]$summary['warnings']['medium']
            hard       = [int]$summary['warnings']['hard']
            command    = [string]$summary['command']
            recorded_at = [string]$summary['recorded_at']
        }
    }
    catch {
        if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
            throw
        }
        return $null
    }
}

function Resolve-ResumeIterationNumber {
    param(
        [AllowNull()][string]$ResolvedFeaturePath,
        [AllowNull()][pscustomobject]$SessionState
    )

    if ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.iteration_number)) {
        return [string]$SessionState.iteration_number
    }

    if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        return $null
    }

    $iterationsRoot = Join-Path $ResolvedFeaturePath 'iterations'
    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
        return $null
    }

    $latestIteration = Get-ChildItem -LiteralPath $iterationsRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'plan.md') -PathType Leaf } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($null -eq $latestIteration) {
        return $null
    }

    return [string]$latestIteration.Name
}

function Get-CoordinatorResumeSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$ResolvedFeaturePath,
        [AllowNull()][pscustomobject]$SessionState
    )

    # F-174 iter-10 (T008 hardening): normalize the session-state shape ONCE (raw anchor OR mapped generator
    # shape) so every read below - and Resolve-ResumeIterationNumber, which receives it - is StrictMode-safe
    # and never throws on an absent property. See ConvertTo-NormalizedResumeSessionState for the why.
    $SessionState = ConvertTo-NormalizedResumeSessionState -SessionState $SessionState

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $effectiveFeaturePath = if (-not [string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) { $ResolvedFeaturePath } elseif ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_path)) { [string]$SessionState.feature_path } else { $null }
    $featureRef = if ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) { [string]$SessionState.feature_ref } elseif (-not [string]::IsNullOrWhiteSpace($effectiveFeaturePath)) { Split-Path -Leaf $effectiveFeaturePath } else { $null }
    $iterationNumber = Resolve-ResumeIterationNumber -ResolvedFeaturePath $effectiveFeaturePath -SessionState $SessionState
    $taskSummary = if (-not [string]::IsNullOrWhiteSpace($featureRef) -and -not [string]::IsNullOrWhiteSpace($iterationNumber)) {
        Get-TaskProgressSummary -ProjectRoot $resolvedProjectRoot -FeatureRef $featureRef -IterationNumber $iterationNumber -ResolvedFeaturePath $effectiveFeaturePath
    }
    else {
        $null
    }

    $latestBoundary = Get-LatestSpecrewBoundarySyncState -ProjectRoot $resolvedProjectRoot
    $validatorSummary = Get-ValidatorWarningSummary -ProjectRoot $resolvedProjectRoot

    # F-174 iter-10 (T008): read the rolling handover + run the SHARED reconciliation (re-compute the CURRENT
    # cheap delta), so a `specrew start` launch recovers the same "changed since the last stop -> read +
    # continue" context the hook surfaces. Fail-open: any failure leaves both $null and the snapshot still
    # carries the lifecycle state above.
    $resumeHandover = $null
    $resumeReconciliation = $null
    try {
        if (Get-Command Get-SpecrewRollingHandover -ErrorAction SilentlyContinue) {
            $resumeHandover = Get-SpecrewRollingHandover -HandoverDir (Join-Path $resolvedProjectRoot '.specrew/handover') -NowUtc ((Get-Date).ToUniversalTime().ToString('o'))
        }
        if (Get-Command Get-SpecrewResumeReconciliation -ErrorAction SilentlyContinue) {
            $resumeReconciliation = Get-SpecrewResumeReconciliation -ProjectRoot $resolvedProjectRoot -Handover $resumeHandover
        }
    }
    catch { $resumeHandover = $null; $resumeReconciliation = $null }

    $suggestedActions = New-Object System.Collections.Generic.List[string]

    if ($null -ne $taskSummary -and $taskSummary.InProgress.Count -gt 0) {
        $task = $taskSummary.InProgress[0]
        $suggestedActions.Add(("Resume {0} — {1}" -f $task.id, $task.title)) | Out-Null
    }
    elseif ($null -ne $taskSummary -and $taskSummary.Pending.Count -gt 0) {
        $task = $taskSummary.Pending[0]
        $suggestedActions.Add(("Start {0} — {1}" -f $task.id, $task.title)) | Out-Null
    }

    if ($null -ne $validatorSummary -and $validatorSummary.total -gt 0) {
        $validatorCommand = if (-not [string]::IsNullOrWhiteSpace($validatorSummary.command)) {
            $validatorSummary.command
        }
        elseif (-not [string]::IsNullOrWhiteSpace($featureRef) -and -not [string]::IsNullOrWhiteSpace($iterationNumber)) {
            'pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\' + $featureRef + '\iterations\' + $iterationNumber
        }
        else {
            'pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .'
        }

        $suggestedActions.Add(("Review validator warnings with: {0}" -f $validatorCommand)) | Out-Null
    }

    return [pscustomobject]@{
        feature_ref         = $featureRef
        feature_path        = $effectiveFeaturePath
        worktree_path       = $resolvedProjectRoot
        iteration_number    = $iterationNumber
        current_boundary    = if ($null -ne $SessionState) { [string]$SessionState.boundary_type } else { $null }
        current_task        = if ($null -ne $SessionState) { [string]$SessionState.task_id } else { $null }
        last_boundary_commit = if ($null -ne $latestBoundary) { [string]$latestBoundary.auth_commit_hash } else { $null }
        last_boundary_at    = if ($null -ne $latestBoundary) { [string]$latestBoundary.recorded_at } else { $null }
        task_summary        = $taskSummary
        validator_summary   = $validatorSummary
        handover            = $resumeHandover
        reconciliation      = $resumeReconciliation
        suggested_actions   = $suggestedActions.ToArray()
    }
}

function Get-CoordinatorResumePromptBlock {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$ResolvedFeaturePath,
        [AllowNull()][pscustomobject]$SessionState
    )

    $snapshot = Get-CoordinatorResumeSnapshot -ProjectRoot $ProjectRoot -ResolvedFeaturePath $ResolvedFeaturePath -SessionState $SessionState
    if ([string]::IsNullOrWhiteSpace($snapshot.feature_ref)) {
        return $null
    }

    $taskSummary = $snapshot.task_summary
    $taskStatusLine = if ($null -eq $taskSummary) {
        'Task progress: (not available)'
    }
    else {
        'Task progress: {0} complete, {1} in-progress, {2} pending, {3} blocked' -f $taskSummary.Complete.Count, $taskSummary.InProgress.Count, $taskSummary.Pending.Count, $taskSummary.Blocked.Count
    }

    $taskDetails = @()
    if ($null -ne $taskSummary -and $taskSummary.Complete.Count -gt 0) {
        $taskDetails += '- Complete: ' + (($taskSummary.Complete | ForEach-Object { $_.id }) -join ', ')
    }
    if ($null -ne $taskSummary -and $taskSummary.InProgress.Count -gt 0) {
        $taskDetails += '- In progress: ' + (($taskSummary.InProgress | ForEach-Object { '{0} ({1})' -f $_.id, $_.title }) -join '; ')
    }
    if ($null -ne $taskSummary -and $taskSummary.Pending.Count -gt 0) {
        $taskDetails += '- Pending: ' + (($taskSummary.Pending | Select-Object -First 3 | ForEach-Object { $_.id }) -join ', ')
    }
    if ($null -ne $taskSummary -and $taskSummary.Blocked.Count -gt 0) {
        $taskDetails += '- Blocked: ' + (($taskSummary.Blocked | ForEach-Object { '{0} ({1})' -f $_.id, $_.blocked_reason }) -join '; ')
    }

    $validatorLine = if ($null -eq $snapshot.validator_summary -or $snapshot.validator_summary.total -le 0) {
        'Validator state: no recorded warnings'
    }
    else {
        'Validator state: {0} warnings: {1} soft, {2} medium, {3} hard' -f $snapshot.validator_summary.total, $snapshot.validator_summary.soft, $snapshot.validator_summary.medium, $snapshot.validator_summary.hard
    }

    $lastCompletedTaskLine = if ($null -ne $taskSummary -and $null -ne $taskSummary.LatestCompleted) {
        '- Last completed task: {0} at {1}' -f $taskSummary.LatestCompleted.id, $taskSummary.LatestCompleted.timestamp
    }
    else {
        '- Last completed task: (none)'
    }

    $suggestedActionsBlock = if ($snapshot.suggested_actions.Count -gt 0) {
        ($snapshot.suggested_actions | ForEach-Object { '- ' + $_ }) -join [Environment]::NewLine
    }
    else {
        '- Continue from the current feature boundary'
    }

    $detailBlock = if ($taskDetails.Count -gt 0) {
        ($taskDetails -join [Environment]::NewLine) + [Environment]::NewLine
    }
    else {
        ''
    }

    # F-174 iter-10 (T008): the resume reconciliation directive - re-computed CURRENT delta vs the last stop,
    # so a `specrew start` launch (incl. antigravity) reads what changed since and continues from the real state.
    $reconciliationBlock = if ($null -ne $snapshot.reconciliation -and -not [string]::IsNullOrWhiteSpace([string]$snapshot.reconciliation.directive_text)) {
        [Environment]::NewLine + [Environment]::NewLine + '## Resume Reconciliation (current tree, re-computed now)' + [Environment]::NewLine + [Environment]::NewLine + [string]$snapshot.reconciliation.directive_text
    }
    else { '' }

    return @"
## Welcome Back Snapshot

- Active feature: $($snapshot.feature_ref)
- Feature path: $(if ($snapshot.feature_path) { $snapshot.feature_path } else { '(none)' })
- Worktree: $($snapshot.worktree_path)
- Current boundary: $(if ($snapshot.current_boundary) { $snapshot.current_boundary } else { '(none)' })
- Current task: $(if ($snapshot.current_task) { $snapshot.current_task } else { '(none)' })
$lastCompletedTaskLine
- Last completed boundary: $(if ($snapshot.last_boundary_commit) { "$($snapshot.last_boundary_commit) at $($snapshot.last_boundary_at)" } else { '(none)' })
- $taskStatusLine
$detailBlock- $validatorLine

### Suggested Next Actions

$suggestedActionsBlock$reconciliationBlock
"@
}

function Get-CoordinatorRecoveryPromptBlock {
    param(
        [AllowNull()][pscustomobject]$RecoverySession
    )

    if ($null -eq $RecoverySession) {
        return $null
    }

    $reasonLines = if (@($RecoverySession.stale_reasons).Count -gt 0) {
        (@($RecoverySession.stale_reasons) | ForEach-Object { '- ' + [string]$_ }) -join [Environment]::NewLine
    }
    else {
        '- Recovery was requested explicitly.'
    }

    $choiceLines = if (@($RecoverySession.choice_set).Count -gt 0) {
        (@($RecoverySession.choice_set) | ForEach-Object { '- ' + [string]$_ }) -join [Environment]::NewLine
    }
    else {
        '- Recovery is active without an interactive choice requirement.'
    }

    return @"
## Recovery Mode

- Entry mode: $($RecoverySession.entry_mode)
- Selected choice: $(if ($RecoverySession.selected_choice) { $RecoverySession.selected_choice } else { '(none)' })
- Bypass stale-state gate: $($RecoverySession.bypass_gate)
- Approval behavior changed: $($RecoverySession.approval_mode_changed)
- Next action: $($RecoverySession.next_action_message)

### Recovery Reasons

$reasonLines

### Available Recovery Choices

$choiceLines
"@
}
