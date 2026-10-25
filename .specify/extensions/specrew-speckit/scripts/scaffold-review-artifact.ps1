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

function ConvertTo-LintCleanMarkdown {
    <#
    DRIFT-198-I011-011. Governed writers must emit markdown that passes the repository's OWN required
    lint — the same `markdownlint` step templates/lifecycle/docs-only-lifecycle.md instructs CONSUMERS
    to run. Emitting non-conformant markdown hands every downstream project a red Lint out of the box,
    and it reached the beta2 release gate as a failing REQUIRED check on files nobody hand-wrote.

    Normalizes exactly the three rules the generator violated, at the ONE choke point both write paths
    funnel through — patching individual emit sites would leave whichever one was missed, which is this
    iteration's recurring lesson.

      MD009 no-trailing-spaces      - strip trailing whitespace (the generator never intends hard breaks)
      MD032 blanks-around-lists     - blank line before the first and after the last item of a list run,
                                      blockquote-aware so `> - item` is handled with a `>` spacer
      MD047 single-trailing-newline - exactly one terminating newline

    Pinned by tests/integration/generator-markdown-parity.tests.ps1, which runs the repo's own
    .markdownlint.json over freshly-generated output.
    #>
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content)

    if ([string]::IsNullOrEmpty($Content)) { return "`n" }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Content -split "`r?`n")) { $lines.Add(($line -replace '[ \t]+$', '')) | Out-Null }

    $isListLine = { param([string]$l) $l -match '^\s*>?\s*([-*+]|\d+[.)])\s+' }
    $isBlankish = { param([string]$l) $l -match '^\s*>?\s*$' }
    $isQuoted = { param([string]$l) $l -match '^\s*>' }

    $out = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $cur = $lines[$i]
        if ((& $isListLine $cur)) {
            $prev = if ($out.Count -gt 0) { $out[$out.Count - 1] } else { $null }
            # Opening a list run that is not already separated, and not a continuation of one.
            if ($null -ne $prev -and -not (& $isBlankish $prev) -and -not (& $isListLine $prev)) {
                $out.Add($(if ((& $isQuoted $cur)) { '>' } else { '' })) | Out-Null
            }
            $out.Add($cur) | Out-Null
            # Closing the run: look ahead past further list lines and their indented continuations.
            $j = $i + 1
            while ($j -lt $lines.Count -and ((& $isListLine $lines[$j]) -or $lines[$j] -match '^\s{2,}\S')) { $j++ }
            for ($k = $i + 1; $k -lt $j; $k++) { $out.Add($lines[$k]) | Out-Null }
            if ($j -lt $lines.Count -and -not (& $isBlankish $lines[$j])) {
                $out.Add($(if ((& $isQuoted $lines[$j])) { '>' } else { '' })) | Out-Null
            }
            $i = $j - 1
            continue
        }
        $out.Add($cur) | Out-Null
    }

    $joined = ($out -join "`n").TrimEnd("`r", "`n", ' ', "`t")
    return ($joined + "`n")
}

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

function Test-SpecrewFileHasPopulatedVerdict {
    param([string]$TargetPath)

    if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $TargetPath -Raw -Encoding UTF8
    if ($content -match '(?m)^\s*\*\*Overall Verdict\*\*:\s*accepted\s*$' -or
        $content -match 'Overall Verdict:\s*accepted' -or
        $content -match '\|\s*(pass|blocked)\s*\|') {
        return $true
    }

    $iterationDir = Split-Path -Parent $TargetPath
    $reviewPath = Join-Path $iterationDir 'review.md'
    $retroPath = Join-Path $iterationDir 'retro.md'
    
    if (Test-Path -LiteralPath $reviewPath -PathType Leaf) {
        $reviewContent = Get-Content -LiteralPath $reviewPath -Raw -Encoding UTF8
        if ($reviewContent -match 'Overall Verdict\*\*?:\s*accepted') {
            return $true
        }
    }
    
    if (Test-Path -LiteralPath $retroPath -PathType Leaf) {
        $retroContent = Get-Content -LiteralPath $retroPath -Raw -Encoding UTF8
        if ($retroContent -match 'Overall Verdict\*\*?:\s*accepted') {
            return $true
        }
    }

    return $false
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

    $finalPath = $TargetPath
    if (Test-SpecrewFileHasPopulatedVerdict -TargetPath $TargetPath) {
        $finalPath = "$TargetPath.pending"
        Write-Host "WARN: Protected existing accepted artifact '$TargetPath'. Emitting template default to sibling '$finalPath' instead." -ForegroundColor Yellow
    }

    if (Test-Path -LiteralPath $finalPath) {
        Add-ScaffoldAction -Actions $Actions -Action 'preserved' -Path $finalPath
        return
    }

    Add-ScaffoldAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $finalPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $finalPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($finalPath, (ConvertTo-LintCleanMarkdown -Content $Content), [System.Text.UTF8Encoding]::new($false))
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

# W35: THE EVIDENCE MARKER NEEDS A PRODUCER, or it is a comment rather than a control.
#
# The validator honours <!-- SPECREW-REVIEW-EVIDENCE: run-... --> as the authored half of the evidence
# union, and nothing emitted it or mentioned it anywhere an agent would read - so no review record
# could ever declare its own evidence and the union was always a union of one. This emits it, already
# populated when a qualifying run exists.
#
# FAIL-OPEN IN EVERY DIRECTION: no shared-governance beside us, or no qualifying run, emits the marker
# EMPTY. An empty marker declares nothing, which is precisely today's behaviour.
$evidenceRunId = ''
try {
    $sharedGovernanceForEvidence = Join-Path $PSScriptRoot 'shared-governance.ps1'
    if (Test-Path -LiteralPath $sharedGovernanceForEvidence -PathType Leaf) {
        if (-not (Get-Command -Name 'Get-SpecrewQualifyingIndependentRun' -ErrorAction SilentlyContinue)) {
            . $sharedGovernanceForEvidence
        }
        if (Get-Command -Name 'Get-SpecrewQualifyingIndependentRun' -ErrorAction SilentlyContinue) {
            # specs/<feature>/iterations/<N> -> the project root is four levels up.
            $projectRootForEvidence = (Resolve-Path -LiteralPath (Join-Path $resolvedIterationDirectory '..\..\..\..') -ErrorAction Stop).Path
            $qualifyingForEvidence = Get-SpecrewQualifyingIndependentRun -ProjectRoot $projectRootForEvidence
            if ($null -ne $qualifyingForEvidence) { $evidenceRunId = [string]$qualifyingForEvidence.result.run_id }
        }
    }
}
catch { $evidenceRunId = '' }

$reviewContent = @"
# Review: Iteration $iterationLabel

**Schema**: v1
**Reviewed**: $ReviewedDate
**Overall Verdict**: $OverallVerdict

## Task Verdicts

$($verdictRows -join [Environment]::NewLine)

<!--
  Review evidence marker (validator-enforced):
    The line below names the run(s) this record RESTS ON. Only what is named here - and the run named
    by the derived independent-review block - is checked against the review store. Run ids appearing
    anywhere else in this document are treated as NARRATIVE and are never checked, so a retraction may
    name a failed run freely without the record being refused for it.
    Leave it empty when the record rests on no campaign run. Do not name a run you are only discussing.
-->
<!-- SPECREW-REVIEW-EVIDENCE: $evidenceRunId -->

<!--
  Gap Ledger schema (validator-enforced):
    EVERY non-empty line MUST be a bullet entry classified with one of two tokens:
      - "fixed-now"  — the gap was repaired during this iteration
      - "deferred"   — the gap is parked with explicit human approval (the approval
                       reference must be recorded in .squad/decisions.md)
    Free-form intro prose between the heading and the bullets is REJECTED by the
    validator (it scans every non-empty line for a classification token).

  When there are no gaps, write ONE line:
    - "No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now."
-->

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Notes

- This artifact was scaffolded from plan.md for the Review/Demo ceremony.
- Replace default verdicts in the Task Verdicts table with the actual per-task review outcome (valid values: `pass` | `needs-work` | `blocked`) before closing the review phase.
- Set `Overall Verdict` (in the metadata above) to `accepted` only when every task is `pass` and every Gap Ledger entry is `fixed-now` (or `deferred` with an approval ref in .squad/decisions.md). Otherwise `needs-rework` or `blocked`.
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
# specrew-self-provenance-ok: DRIFT-198-I011-011; implementation history is recorded for maintainers and is never emitted as consumer instruction
