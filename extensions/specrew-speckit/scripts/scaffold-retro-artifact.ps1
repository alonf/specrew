[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [string]$RetroDate = (Get-Date -Format 'yyyy-MM-dd'),
    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$allowedReviewTaskVerdicts = @('pass', 'needs-work', 'blocked')

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

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank)$'
}

function Test-IsPlaceholderReviewNote {
    param([AllowNull()][string]$Value)

    if (Test-IsNullish $Value) {
        return $false
    }

    return $Value.Trim() -match '^(?:Review delivered output against .+ and adjust verdict if needed\.|Execution reported blocked; confirm blocker status and escalation path\.|Deferred work; confirm the deferral is still acceptable for this iteration\.|Task already marked needs-rework during execution; confirm re-entry scope\.|Populate verdict after reviewing the delivered evidence\.)$'
}

function Get-NormalizedReviewTaskVerdict {
    param([AllowNull()][string]$Value)

    if (Test-IsNullish $Value) {
        return $null
    }

    $normalized = $Value.Trim().ToLowerInvariant()
    if ($normalized -match '\bneeds[- ]work\b') {
        return 'needs-work'
    }

    if ($normalized -match '\bblocked\b') {
        return 'blocked'
    }

    if ($normalized -match '\bpass(?:ed)?\b') {
        return 'pass'
    }

    return $normalized
}

function ConvertTo-NullableDecimal {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $trimmed = $Value.Trim()
    if ($trimmed -notmatch '^-?\d+(?:\.\d+)?$') {
        return $null
    }

    return [decimal]$trimmed
}

function Format-Delta {
    param(
        [AllowNull()]
        [Nullable[decimal]]$Estimated,

        [AllowNull()]
        [Nullable[decimal]]$Actual
    )

    if ($null -eq $Estimated -or $null -eq $Actual) {
        return 'TBD'
    }

    $delta = $Actual - $Estimated
    if ($delta -gt 0) {
        return ('+{0}' -f $delta.ToString('0.##'))
    }

    return $delta.ToString('0.##')
}

function Get-PhaseVarianceNote {
    param([string]$PhaseName)

    switch ($PhaseName.Trim().ToLowerInvariant()) {
        'planning' { return 'Capture approval, clarification, and task-decomposition variance.' }
        'discovery/spikes' { return 'Record any preflight or research effort that changed execution certainty.' }
        'implementation' { return 'Note whether reuse, blockers, or rework changed delivery effort.' }
        'review' { return 'Capture late-found gaps, batch drift checks, or demo overhead.' }
        'rework' { return 'Record whether needs-work loops were avoided, deferred, or underestimated.' }
        default { return 'Document why actual effort differed from the planned baseline.' }
    }
}

function Get-ReviewOverallVerdict {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$ReviewLines
    )

    foreach ($line in $ReviewLines) {
        if ($line -match '^\*\*Overall Verdict\*\*:\s*(.+?)\s*$') {
            $verdict = $Matches[1].Trim()
            if ($verdict -in @('accepted', 'needs-rework', 'blocked')) {
                return $verdict
            }

            throw "review.md contains an invalid overall verdict: '$verdict'."
        }
    }

    throw 'review.md must record an overall verdict before retrospective scaffolding can run.'
}

function Assert-ReviewArtifactReadyForRetro {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$ReviewLines
    )

    $overallVerdict = Get-ReviewOverallVerdict -ReviewLines $ReviewLines
    if ($overallVerdict -ne 'accepted') {
        throw "review.md overall verdict must be 'accepted' before retrospective scaffolding can run (found '$overallVerdict')."
    }

    foreach ($line in $ReviewLines) {
        if ($line.Trim() -eq '- Replace default verdicts with the actual per-task review outcome before closing the review phase.') {
            throw 'review.md still contains scaffold reminder text and is not ready for retrospective scaffolding.'
        }
    }

    $taskVerdicts = @(Get-MarkdownSectionTable -Lines $ReviewLines -Heading 'Task Verdicts')
    if ($taskVerdicts.Count -eq 0) {
        throw 'review.md must contain a populated Task Verdicts table before retrospective scaffolding can run.'
    }

    foreach ($row in $taskVerdicts) {
        $taskId = [string]$row.Task
        if (Test-IsNullish $taskId) {
            throw 'review.md contains a verdict row without a task identifier.'
        }

        $verdict = Get-NormalizedReviewTaskVerdict -Value ([string]$row.Verdict)
        if ($null -eq $verdict) {
            throw "review.md is missing a verdict for task '$taskId'."
        }

        if ($verdict -notin $allowedReviewTaskVerdicts) {
            throw "review.md contains invalid verdict '$($row.Verdict)' for task '$taskId'."
        }

        if ($verdict -ne 'pass') {
            throw "review.md task '$taskId' is still marked '$verdict'; resolve review findings before retrospective scaffolding."
        }

        $notes = if ($null -ne $row.PSObject.Properties['Notes']) { [string]$row.Notes } else { $null }
        if (Test-IsPlaceholderReviewNote -Value $notes) {
            throw "review.md still contains scaffold placeholder notes for task '$taskId'."
        }
    }

    return $overallVerdict
}

function Get-DriftSummary {
    param(
        [AllowEmptyString()]
        [string[]]$DriftLines
    )

    $summary = [ordered]@{
        Total              = 0
        SpecUpdated        = 0
        ImplementationRevert = 0
        Deferred           = 0
        HumanDecision      = 0
    }

    foreach ($line in $DriftLines) {
        if ($line -match '^\*\*Total drift events\*\*:\s*(\d+)\s*$') {
            $summary.Total = [int]$Matches[1]
            continue
        }

        if ($line -match '^\s*-\s+\*\*Resolution\*\*:\s*(spec-updated|implementation-reverted|deferred|human-decision)\s*$') {
            switch ($Matches[1]) {
                'spec-updated' { $summary.SpecUpdated++ }
                'implementation-reverted' { $summary.ImplementationRevert++ }
                'deferred' { $summary.Deferred++ }
                'human-decision' { $summary.HumanDecision++ }
            }
        }
    }

    return [pscustomobject]$summary
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$planPath = Join-Path $resolvedIterationDirectory 'plan.md'
$statePath = Join-Path $resolvedIterationDirectory 'state.md'
$driftLogPath = Join-Path $resolvedIterationDirectory 'drift-log.md'
$reviewPath = Join-Path $resolvedIterationDirectory 'review.md'
$retroPath = Join-Path $resolvedIterationDirectory 'retro.md'
$actions = [System.Collections.ArrayList]::new()

foreach ($requiredPath in @($planPath, $statePath, $driftLogPath, $reviewPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Required retrospective input '$requiredPath' does not exist."
    }
}

$planLines = @(Get-MarkdownContent -Path $planPath)
$reviewLines = @(Get-MarkdownContent -Path $reviewPath)
$driftLines = @(Get-MarkdownContent -Path $driftLogPath)
$tasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
$phaseRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Phase Baseline')

if ($tasks.Count -eq 0) {
    throw "Plan '$planPath' does not contain a populated Tasks table."
}

if ($phaseRows.Count -eq 0) {
    throw "Plan '$planPath' does not contain a populated Phase Baseline table."
}

$iterationLabel = Get-IterationLabel -PlanLines $planLines -Fallback (Split-Path -Leaf $resolvedIterationDirectory)
$reviewOverallVerdict = Assert-ReviewArtifactReadyForRetro -ReviewLines $reviewLines
$driftSummary = Get-DriftSummary -DriftLines $driftLines

$taskVarianceRows = @(
    '| Task | Estimated | Actual | Delta |'
    '| ---- | --------- | ------ | ----- |'
)

$absoluteDeltas = New-Object System.Collections.Generic.List[decimal]
foreach ($task in $tasks) {
    $taskId = [string]$task.Task
    if ([string]::IsNullOrWhiteSpace($taskId)) {
        continue
    }

    $estimatedValue = ConvertTo-NullableDecimal -Value ([string]$task.Effort)
    $actualValue = ConvertTo-NullableDecimal -Value ([string]$task.Actual)
    if ($null -ne $estimatedValue -and $null -ne $actualValue) {
        $null = $absoluteDeltas.Add([math]::Abs($actualValue - $estimatedValue))
    }

    $taskVarianceRows += ('| {0} | {1} | {2} | {3} |' -f
        $taskId.Trim(),
        $(if ($null -eq $estimatedValue) { 'TBD' } else { $estimatedValue.ToString('0.##') }),
        $(if ($null -eq $actualValue) { 'TBD' } else { $actualValue.ToString('0.##') }),
        (Format-Delta -Estimated $estimatedValue -Actual $actualValue))
}

$averageVariance = if ($absoluteDeltas.Count -eq 0) {
    'TBD'
}
else {
    $sum = [decimal]0
    foreach ($delta in $absoluteDeltas) {
        $sum += $delta
    }

    ('+/- {0}' -f (($sum / $absoluteDeltas.Count).ToString('0.##')))
}

$phaseVarianceRows = @(
    '| Phase | Estimated | Actual | Delta | Notes |'
    '| ----- | --------- | ------ | ----- | ----- |'
)

foreach ($phaseRow in $phaseRows) {
    $phaseName = [string]$phaseRow.Phase
    if ([string]::IsNullOrWhiteSpace($phaseName)) {
        continue
    }

    $estimated = ConvertTo-NullableDecimal -Value ([string]$phaseRow.'Estimated Effort')
    $phaseVarianceRows += ('| {0} | {1} | {2} | {3} | {4} |' -f
        $phaseName.Trim(),
        $(if ($null -eq $estimated) { 'TBD' } else { $estimated.ToString('0.##') }),
        'TBD',
        'TBD',
        ((Get-PhaseVarianceNote -PhaseName $phaseName) -replace '\|', '\|'))
}

$retroContent = @"
# Retrospective: Iteration $iterationLabel

**Schema**: v1
**Date**: $RetroDate

## Estimation Accuracy

$($taskVarianceRows -join [Environment]::NewLine)

**Average variance**: $averageVariance

## Phase Variance

$($phaseVarianceRows -join [Environment]::NewLine)

## Drift Summary

- Total drift events: $($driftSummary.Total)
- Resolved via spec update: $($driftSummary.SpecUpdated)
- Resolved via revert: $($driftSummary.ImplementationRevert)
- Deferred: $($driftSummary.Deferred)
- Escalated to human decision: $($driftSummary.HumanDecision)

## What Went Well

- Review verdict recorded as **$reviewOverallVerdict** before retrospective started.
- Replace with the concrete practices that improved planning accuracy, execution flow, or governance quality.

## What Didn't Go Well

- Replace with the concrete friction, missed gates, or late-found drift that hurt this iteration.
- Call out any repeatable failure pattern that should be prevented in the next planning ceremony.

## Improvement Actions

1. Owner: TBD | Phase: next planning | Type: process | Expected effect: tighten a measurable workflow weakness.
2. Owner: TBD | Phase: next iteration | Type: implementation | Expected effect: remove one repeated source of friction.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline -> TBD
- Rationale: Replace with evidence from task variance, phase variance, and drift timing.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- Replace all TBD placeholders with evidence from the completed iteration before marking the retro phase complete.
"@

Write-MissingFile -TargetPath $retroPath -Content $retroContent -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Retro artifact scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $retroPath)) -ForegroundColor Green
exit 0
