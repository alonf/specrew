[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SpecDirectory,

    [Parameter(Mandatory = $true)]
    [string]$IterationNumber,

    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-ScaffoldAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $Path) {
        Add-ScaffoldAction -Actions $Actions -Action 'preserved-directory' -Path $Path
        return
    }

    Add-ScaffoldAction -Actions $Actions -Action $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' }) -Path $Path
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-MissingFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $TargetPath) {
        Add-ScaffoldAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-ScaffoldAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
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
        $currentLine = $Lines[$index]
        if ($currentLine -match '^##\s+') {
            break
        }

        if ($currentLine.Trim().StartsWith('|')) {
            $null = $tableLines.Add($currentLine)
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = ($tableLines[0].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    $rows = New-Object System.Collections.Generic.List[object]

    for ($rowIndex = 1; $rowIndex -lt $tableLines.Count; $rowIndex++) {
        $cells = ($tableLines[$rowIndex].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
        $isSeparator = $true

        foreach ($cell in $cells) {
            if ($cell -notmatch '^:?-{3,}:?$') {
                $isSeparator = $false
                break
            }
        }

        if ($isSeparator) {
            continue
        }

        $row = [ordered]@{}
        for ($cellIndex = 0; $cellIndex -lt $headers.Count; $cellIndex++) {
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-PlanTaskIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlanPath
    )

    if (-not (Test-Path -LiteralPath $PlanPath)) {
        return @()
    }

    $planLines = @(Get-MarkdownContent -Path $PlanPath)
    $taskRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
    $seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    $taskIds = New-Object System.Collections.Generic.List[string]

    foreach ($taskRow in $taskRows) {
        $taskId = [string]$taskRow.Task
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            continue
        }

        $taskId = $taskId.Trim()
        if ($seen.Add($taskId)) {
            $null = $taskIds.Add($taskId)
        }
    }

    return $taskIds.ToArray()
}

$resolvedSpecDirectory = [System.IO.Path]::GetFullPath($SpecDirectory)
$iterationsRoot = Join-Path $resolvedSpecDirectory 'iterations'
$iterationDirectory = Join-Path $iterationsRoot $IterationNumber
$planPath = Join-Path $iterationDirectory 'plan.md'
$statePath = Join-Path $iterationDirectory 'state.md'
$driftLogPath = Join-Path $iterationDirectory 'drift-log.md'
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $resolvedSpecDirectory)) {
    throw "Spec directory '$resolvedSpecDirectory' does not exist."
}

Ensure-Directory -Path $iterationsRoot -Actions $actions
Ensure-Directory -Path $iterationDirectory -Actions $actions

$taskIds = @(Get-PlanTaskIds -PlanPath $planPath)
$tasksRemaining = if ($taskIds.Count -gt 0) { $taskIds -join ', ' } else { '(populate from plan.md)' }

$stateContent = @"
# Iteration State: $IterationNumber

**Schema**: v1
**Last Completed Task**: (none)
**Tasks Remaining**: $tasksRemaining
**In Progress**: (none)
**Updated**: $timestamp

## Execution Summary

- Execution has not started yet.
- This artifact was scaffolded before task execution so resume state can be updated after each task.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.
"@

$driftLogContent = @"
# Drift Log: Iteration $IterationNumber

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration $IterationNumber execution to date.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:
- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
"@

Write-MissingFile -TargetPath $statePath -Content $stateContent -Actions $actions
Write-MissingFile -TargetPath $driftLogPath -Content $driftLogContent -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Iteration artifact scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $iterationDirectory)) -ForegroundColor Green
exit 0
