[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [ValidateSet('continue', 'replan', 'abort')]
    [string]$ResumeMode = 'continue',

    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownMetadataValue {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank)$'
}

function Get-MarkdownSectionTable {
    param(
        [string[]]$Lines,
        [string]$Heading
    )

    $headingPattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $tableLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $line = $Lines[$index]
        if ($line -match '^##\s+' -and $tableLines.Count -gt 0) {
            break
        }

        if ($line.TrimStart().StartsWith('|')) {
            $tableLines.Add($line)
        }
        elseif ($tableLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($line)) {
            break
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = @($tableLines[0].Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    $rows = New-Object System.Collections.Generic.List[object]
    for ($index = 2; $index -lt $tableLines.Count; $index++) {
        $columns = @($tableLines[$index].Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($columns.Count -ne $headers.Count) {
            continue
        }

        $row = [ordered]@{}
        for ($columnIndex = 0; $columnIndex -lt $headers.Count; $columnIndex++) {
            $row[$headers[$columnIndex]] = $columns[$columnIndex]
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-TaskListFromMetadata {
    param([AllowNull()][string]$Value)

    if (Test-IsNullish $Value) {
        return @()
    }

    return @(
        $Value -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Get-NormalizedTaskStatus {
    param([AllowNull()][string]$Status)

    if ([string]::IsNullOrWhiteSpace($Status)) {
        return ''
    }

    return $Status.Trim().ToLowerInvariant()
}

function Set-MarkdownMetadataValue {
    param(
        [string[]]$Lines,
        [string]$Label,
        [string]$Value
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $pattern) {
            $Lines[$index] = ('**{0}**: {1}' -f $Label, $Value)
            return $Lines
        }
    }

    $insertIndex = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\*\*[^*]+\*\*:\s*') {
            $insertIndex = $index + 1
            continue
        }

        if ($insertIndex -ge 0 -and $Lines[$index] -match '^##\s+') {
            break
        }
    }

    $updatedLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        $updatedLines.Add($line)
    }

    if ($insertIndex -lt 0) {
        $updatedLines.Add(('**{0}**: {1}' -f $Label, $Value))
    }
    else {
        $updatedLines.Insert($insertIndex, ('**{0}**: {1}' -f $Label, $Value))
    }

    return $updatedLines.ToArray()
}

function Set-ManagedBlock {
    param(
        [string]$Content,
        [string]$BlockName,
        [string]$BlockContent
    )

    $startMarker = "<!-- >>> specrew-managed $BlockName >>> -->"
    $endMarker = "<!-- <<< specrew-managed $BlockName <<< -->"
    $managedBlock = @(
        $startMarker
        $BlockContent.Trim()
        $endMarker
    ) -join [Environment]::NewLine
    $pattern = '(?ms)\s*' + [regex]::Escape($startMarker) + '.*?' + [regex]::Escape($endMarker) + '\s*'

    if ($Content -match $pattern) {
        $updated = [regex]::Replace($Content, $pattern, ([Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine + [Environment]::NewLine))
        return $updated.TrimEnd() + [Environment]::NewLine
    }

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $managedBlock + [Environment]::NewLine
    }

    return $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine
}

function Get-DefaultEscalationState {
    return [pscustomobject]@{
        status            = 'inactive'
        artifact          = $null
        gate              = $null
        failure_count     = 0
        current_tier      = 'efficiency'
        current_owner     = $null
        locked_out_agents = @()
        last_escalated    = $null
        resolved_at       = $null
        notes             = $null
    }
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$planPath = Join-Path $resolvedIterationDirectory 'plan.md'
$statePath = Join-Path $resolvedIterationDirectory 'state.md'

if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
    throw "Iteration plan '$planPath' does not exist."
}

$planLines = Get-MarkdownContent -Path $planPath
$planTasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
if ($planTasks.Count -eq 0) {
    throw "Iteration plan '$planPath' does not contain a Tasks table."
}

$stateExists = Test-Path -LiteralPath $statePath -PathType Leaf
$stateLines = @(if ($stateExists) { Get-MarkdownContent -Path $statePath } else { @() })
$repairEscalation = Get-DefaultEscalationState
$escalationHelperPath = Join-Path -Path $PSScriptRoot -ChildPath 'manage-escalation-state.ps1'
if ($stateExists -and (Test-Path -LiteralPath $escalationHelperPath -PathType Leaf)) {
    $repairEscalation = & $escalationHelperPath -IterationDirectory $resolvedIterationDirectory -Mode get -PassThru
}

$lastCompletedTask = if ($stateExists) { Get-MarkdownMetadataValue -Lines $stateLines -Label 'Last Completed Task' } else { '(none)' }
$tasksRemainingValue = if ($stateExists) { Get-MarkdownMetadataValue -Lines $stateLines -Label 'Tasks Remaining' } else { $null }
$inProgressValue = if ($stateExists) { Get-MarkdownMetadataValue -Lines $stateLines -Label 'In Progress' } else { $null }

$planTaskLookup = @{}
foreach ($task in $planTasks) {
    $planTaskLookup[$task.Task] = $task
}

$planRemainingTasks = @(
    $planTasks |
        Where-Object { (Get-NormalizedTaskStatus -Status $_.Status) -eq 'planned' } |
        ForEach-Object { $_.Task }
)
$planInProgressTasks = @(
    $planTasks |
        Where-Object { (Get-NormalizedTaskStatus -Status $_.Status) -in @('in-progress', 'needs-rework') } |
        ForEach-Object { $_.Task }
)

$blockers = New-Object System.Collections.Generic.List[object]

if (-not (Test-IsNullish $lastCompletedTask) -and $lastCompletedTask -ne '(none)' -and -not $planTaskLookup.ContainsKey($lastCompletedTask)) {
    $blockers.Add([pscustomobject]@{
            type        = 'resource'
            description = "state.md references unknown last completed task '$lastCompletedTask'."
        })
}

$stateRemainingTasks = @(Get-TaskListFromMetadata -Value $tasksRemainingValue)
$remainingTasks = @($planRemainingTasks)

$stateInProgressTasks = @(Get-TaskListFromMetadata -Value $inProgressValue)
$inProgressTasks = @($stateInProgressTasks)
if ($inProgressTasks.Count -eq 0) {
    $inProgressTasks = @($planInProgressTasks)
}

$invalidInProgressTasks = @(
    $inProgressTasks |
        Where-Object {
            $planTaskLookup.ContainsKey($_) -and
            (Get-NormalizedTaskStatus -Status $planTaskLookup[$_].Status) -in @('done', 'blocked')
        }
)
foreach ($taskId in $invalidInProgressTasks) {
    $blockers.Add([pscustomobject]@{
            type        = 'resource'
            description = "state.md marks task '$taskId' in progress, but plan.md shows it as '$($planTaskLookup[$taskId].Status)'."
        })
}

$inProgressTasks = @(
    $inProgressTasks |
        Where-Object {
            $planTaskLookup.ContainsKey($_) -and
            (Get-NormalizedTaskStatus -Status $planTaskLookup[$_].Status) -notin @('done', 'blocked')
        } |
        Select-Object -Unique
)

if ($inProgressTasks.Count -eq 0 -and $planInProgressTasks.Count -gt 0) {
    $inProgressTasks = @($planInProgressTasks)
}

$remainingTasks = @($remainingTasks | Where-Object { $_ -notin $inProgressTasks })

foreach ($taskId in @($stateRemainingTasks + $stateInProgressTasks) | Select-Object -Unique) {
    if (-not $planTaskLookup.ContainsKey($taskId)) {
        $blockers.Add([pscustomobject]@{
                type        = 'resource'
                description = "state.md references unknown task '$taskId'."
            })
    }
}

$blockedPlanTasks = @(
    $planTasks |
        Where-Object { (Get-NormalizedTaskStatus -Status $_.Status) -eq 'blocked' } |
        ForEach-Object { $_.Task }
)
foreach ($taskId in $blockedPlanTasks) {
    $blockers.Add([pscustomobject]@{
            type        = 'dependency'
            description = "Task '$taskId' is marked blocked in plan.md and must be resolved before execution can continue."
        })
}

$status = 'ready'
$nextSuggestedTask = $null
$salvageableTasks = $null
$nextRecoveryAction = $null
$hasActiveEscalation = $repairEscalation.status -eq 'active'

switch ($ResumeMode) {
    'continue' {
        if ($blockers.Count -gt 0) {
            $status = 'blocked'
        }
        elseif ($hasActiveEscalation) {
            $nextRecoveryAction = 'Resume active escalation for {0} at gate {1} using {2} on the {3} tier.' -f $repairEscalation.artifact, $repairEscalation.gate, $repairEscalation.current_owner, $repairEscalation.current_tier
        }
        elseif ($inProgressTasks.Count -gt 0) {
            $nextSuggestedTask = $inProgressTasks[0]
        }
        elseif ($remainingTasks.Count -gt 0) {
            $nextSuggestedTask = $remainingTasks[0]
        }
    }
    'replan' {
        $status = 'needs-replan'
        if ($blockers.Count -eq 0) {
            $blockers.Add([pscustomobject]@{
                    type        = 'resource'
                    description = 'Resume mode ''replan'' was selected; refresh the remaining task plan before execution resumes.'
                })
        }
    }
    'abort' {
        $status = 'needs-replan'
        $salvageableTasks = @($remainingTasks | Where-Object { $_ -notin $blockedPlanTasks })
        if ($blockers.Count -eq 0) {
            $blockers.Add([pscustomobject]@{
                    type        = 'resource'
                    description = 'Resume mode ''abort'' was selected; carry salvageable tasks into the next iteration or abandonment closeout.'
                })
        }
    }
}

$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$normalizedLastCompletedTask = if (Test-IsNullish $lastCompletedTask) { $null } else { $lastCompletedTask }
$normalizedSalvageableTasks = if ($null -eq $salvageableTasks) { $null } else { @($salvageableTasks) }
$blockerItems = [object[]]$blockers.ToArray()
$result = New-Object psobject
$result | Add-Member -NotePropertyName 'status' -NotePropertyValue $status
$result | Add-Member -NotePropertyName 'resume_mode' -NotePropertyValue $ResumeMode
$result | Add-Member -NotePropertyName 'iteration_directory' -NotePropertyValue $resolvedIterationDirectory
$result | Add-Member -NotePropertyName 'last_completed_task' -NotePropertyValue $normalizedLastCompletedTask
$result | Add-Member -NotePropertyName 'in_progress_tasks' -NotePropertyValue @($inProgressTasks)
$result | Add-Member -NotePropertyName 'remaining_tasks' -NotePropertyValue @($remainingTasks)
$result | Add-Member -NotePropertyName 'next_suggested_task' -NotePropertyValue $nextSuggestedTask
$result | Add-Member -NotePropertyName 'next_recovery_action' -NotePropertyValue $nextRecoveryAction
$result | Add-Member -NotePropertyName 'blockers' -NotePropertyValue $blockerItems
$result | Add-Member -NotePropertyName 'salvageable_tasks' -NotePropertyValue $normalizedSalvageableTasks
$result | Add-Member -NotePropertyName 'repair_escalation' -NotePropertyValue $repairEscalation

if ($status -ne 'blocked' -and $stateExists) {
    $updatedStateLines = @($stateLines)
    $updatedInProgressTasks = @()
    $updatedRemainingTasks = @($remainingTasks)

    if ($ResumeMode -eq 'continue' -and $hasActiveEscalation) {
        $updatedInProgressTasks = @($inProgressTasks)
        $updatedRemainingTasks = @($remainingTasks)
    }
    elseif ($ResumeMode -eq 'continue' -and -not [string]::IsNullOrWhiteSpace($nextSuggestedTask)) {
        if ($inProgressTasks.Count -gt 0) {
            $updatedInProgressTasks = @($inProgressTasks)
        }
        else {
            $updatedInProgressTasks = @($nextSuggestedTask)
            $updatedRemainingTasks = @($updatedRemainingTasks | Where-Object { $_ -ne $nextSuggestedTask })
        }
    }
    elseif ($ResumeMode -in @('replan', 'abort')) {
        $updatedRemainingTasks = @($remainingTasks)
    }

    $updatedStateLines = Set-MarkdownMetadataValue -Lines $updatedStateLines -Label 'Tasks Remaining' -Value $(if ($updatedRemainingTasks.Count -gt 0) { $updatedRemainingTasks -join ', ' } else { '(none)' })
    $updatedStateLines = Set-MarkdownMetadataValue -Lines $updatedStateLines -Label 'In Progress' -Value $(if ($updatedInProgressTasks.Count -gt 0) { $updatedInProgressTasks -join ', ' } else { '(none)' })
    $updatedStateLines = Set-MarkdownMetadataValue -Lines $updatedStateLines -Label 'Updated' -Value $timestamp
    $stateContent = ($updatedStateLines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine

    $resumeReportLines = @(
        '## Resume Report'
        ''
        ('- **Timestamp**: {0}' -f $timestamp)
        ('- **Mode**: {0}' -f $ResumeMode)
        ('- **Status**: {0}' -f $status)
        ('- **Last Completed Task**: {0}' -f $(if (Test-IsNullish $lastCompletedTask) { '(none)' } else { $lastCompletedTask }))
        ('- **Next Suggested Task**: {0}' -f $(if ([string]::IsNullOrWhiteSpace($nextSuggestedTask)) { '(none)' } else { $nextSuggestedTask }))
        ('- **Next Recovery Action**: {0}' -f $(if ([string]::IsNullOrWhiteSpace($nextRecoveryAction)) { '(none)' } else { $nextRecoveryAction }))
        ('- **In-Progress Tasks**: {0}' -f $(if ($inProgressTasks.Count -gt 0) { $inProgressTasks -join ', ' } else { '(none)' }))
        ('- **Remaining Tasks**: {0}' -f $(if ($remainingTasks.Count -gt 0) { $remainingTasks -join ', ' } else { '(none)' }))
        ('- **Repair Escalation**: {0}' -f $(if ($hasActiveEscalation) { '{0} | owner={1} | tier={2} | failures={3} | locked_out={4}' -f $repairEscalation.artifact, $repairEscalation.current_owner, $repairEscalation.current_tier, $repairEscalation.failure_count, $(if ($repairEscalation.locked_out_agents.Count -gt 0) { $repairEscalation.locked_out_agents -join ', ' } else { '(none)' }) } else { 'inactive' }))
        ('- **Blockers**: {0}' -f $(if ($blockers.Count -gt 0) { ($blockers | ForEach-Object { $_.description }) -join ' | ' } else { '(none)' }))
        ('- **Salvageable Tasks**: {0}' -f $(if ($null -ne $salvageableTasks -and $salvageableTasks.Count -gt 0) { $salvageableTasks -join ', ' } elseif ($null -ne $salvageableTasks) { '(none)' } else { 'n/a' }))
    )

    $stateContent = Set-ManagedBlock -Content $stateContent -BlockName 'resume-report' -BlockContent ($resumeReportLines -join [Environment]::NewLine)
    if (-not $DryRun) {
        [System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))
    }
}

if ($PassThru) {
    $result
    return
}

$result | ConvertTo-Json -Depth 5
exit 0
