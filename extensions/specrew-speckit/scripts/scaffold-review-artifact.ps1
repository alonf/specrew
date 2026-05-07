[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [ValidateSet('accepted', 'needs-rework', 'blocked')]
    [string]$OverallVerdict = 'needs-rework',

    [ValidateSet('pass', 'needs-work', 'blocked')]
    [string]$DefaultTaskVerdict = 'needs-work',

    [string]$ReviewedDate = (Get-Date -Format 'yyyy-MM-dd'),
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
        [AllowEmptyString()]
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

function Get-TaskReviewNote {
    param(
        [string]$TaskStatus,
        [string]$RequirementRef
    )

    $normalized = $TaskStatus.Trim().ToLowerInvariant()
    switch ($normalized) {
        'done' { return "Review delivered output against $RequirementRef and adjust verdict if needed." }
        'blocked' { return 'Execution reported blocked; confirm blocker status and escalation path.' }
        'deferred' { return 'Deferred work; confirm the deferral is still acceptable for this iteration.' }
        'needs-rework' { return 'Task already marked needs-rework during execution; confirm re-entry scope.' }
        default { return 'Populate verdict after reviewing the delivered evidence.' }
    }
}

function Get-IterationLabel {
    param(
        [AllowEmptyString()]
        [string[]]$PlanLines,
        [string]$Fallback
    )

    $titleLine = @($PlanLines | Select-Object -First 1)[0]
    if (-not [string]::IsNullOrWhiteSpace($titleLine) -and $titleLine -match '^#\s+Iteration Plan:\s+(.+?)(?:\s+\(stub\))?\s*$') {
        return $Matches[1].Trim()
    }

    return $Fallback
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$planPath = Join-Path $resolvedIterationDirectory 'plan.md'
$reviewPath = Join-Path $resolvedIterationDirectory 'review.md'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $planPath)) {
    throw "Iteration plan '$planPath' does not exist."
}

$planLines = @(Get-MarkdownContent -Path $planPath)
$tasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
if ($tasks.Count -eq 0) {
    throw "Plan '$planPath' does not contain a populated Tasks table."
}

$iterationLabel = Get-IterationLabel -PlanLines $planLines -Fallback (Split-Path -Leaf $resolvedIterationDirectory)

$verdictRows = @(
    '| Task | Requirement | Verdict | Notes |'
    '| ---- | ----------- | ------- | ----- |'
)

foreach ($task in $tasks) {
    $taskId = [string]$task.Task
    if ([string]::IsNullOrWhiteSpace($taskId)) {
        continue
    }

    $requirementRef = [string]$task.Requirement
    $taskStatus = [string]$task.Status
    $note = Get-TaskReviewNote -TaskStatus $taskStatus -RequirementRef $requirementRef
    $verdictRows += ('| {0} | {1} | {2} | {3} |' -f $taskId.Trim(), $requirementRef.Trim(), $DefaultTaskVerdict, ($note -replace '\|', '\|'))
}

$reviewContent = @"
# Review: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $ReviewedDate
**Overall Verdict**: $OverallVerdict

## Task Verdicts

$($verdictRows -join [Environment]::NewLine)

## Gap Ledger

- Replace this reminder with either: (a) `No known gaps remain.` or (b) explicit gap entries covering the affected requirement/artifact, whether the gap is fixed now or deferred with approval, and any required spec/plan/tasks updates.

## Notes

- This artifact was scaffolded from plan.md for the Review/Demo ceremony.
- Replace default verdicts with the actual per-task review outcome before closing the review phase.
- Use the no-gap policy: known gaps must be fixed now or explicitly deferred with approval and recorded evidence before closure.
- If per-task drift checks did not run during execution, invoke `specrew-drift-check` in batch and update drift-log.md before accepting the iteration.
"@

Write-MissingFile -TargetPath $reviewPath -Content $reviewContent -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Review artifact scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $reviewPath)) -ForegroundColor Green
exit 0
