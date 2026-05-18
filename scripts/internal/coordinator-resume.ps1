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

function Get-ValidatorSummaryPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    return Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specrew\last-validator-summary.json'
}

function Get-ValidatorWarningSummary {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $summaryPath = Get-ValidatorSummaryPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
        return $null
    }

    try {
        $summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 6
        return [pscustomobject]@{
            total      = [int]$summary.warnings.total
            soft       = [int]$summary.warnings.soft
            medium     = [int]$summary.warnings.medium
            hard       = [int]$summary.warnings.hard
            command    = [string]$summary.command
            recorded_at = [string]$summary.recorded_at
        }
    }
    catch {
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

$suggestedActionsBlock
"@
}
