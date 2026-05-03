[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Test-ContentPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in $output) {
            Write-Host $line
        }

        throw ("Script failed: {0}" -f $ScriptPath)
    }

    return @($output | ForEach-Object { [string]$_ })
}

function Invoke-TestScriptExpectFailure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    if ($LASTEXITCODE -eq 0) {
        Write-Fail ("Script unexpectedly succeeded: {0}" -f $ScriptPath)
        return $false
    }

    return $true
}

function Invoke-TestScriptJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in $output) {
            Write-Host $line
        }

        throw ("Script failed: {0}" -f $ScriptPath)
    }

    $json = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    return $json | ConvertFrom-Json
}

function Test-DriftSkillContract {
    param([string]$SkillPath)

    if (-not (Test-Path -LiteralPath $SkillPath -PathType Leaf)) {
        Write-Fail "Missing drift-check skill template: $SkillPath"
        return $false
    }

    $content = Get-Content -LiteralPath $SkillPath -Raw -Encoding UTF8
    $isValid = $true

    $checks = @(
        @{ Pattern = 'Did we omit something required\?'; Failure = 'Drift skill is missing the incomplete-output check.' },
        @{ Pattern = 'Did we add something not authorized\?'; Failure = 'Drift skill is missing the unauthorized-addition check.' },
        @{ Pattern = 'Did we contradict the requirement or a documented deferral\?'; Failure = 'Drift skill is missing the contradiction check.' },
        @{ Pattern = '`spec-updated`'; Failure = 'Drift skill is missing the spec-updated resolution path.' },
        @{ Pattern = '`implementation-reverted`'; Failure = 'Drift skill is missing the implementation-reverted resolution path.' },
        @{ Pattern = '`deferred`'; Failure = 'Drift skill is missing the deferred resolution path.' },
        @{ Pattern = '`human-decision`'; Failure = 'Drift skill is missing the human-decision resolution path.' },
        @{ Pattern = 'Markdown snippet that can be copied into `drift-log\.md`'; Failure = 'Drift skill no longer guarantees drift-log-ready output.' },
        @{ Pattern = 'zero-drift placeholder summary.*must be replaced|summary text must be updated when the first event is added'; Failure = 'Drift skill no longer documents placeholder-summary replacement.' }
    )

    foreach ($check in $checks) {
        if (-not (Test-ContentPattern -Content $content -Pattern $check.Pattern -FailureMessage $check.Failure)) {
            $isValid = $false
        }
    }

    if ($isValid) {
        Write-Pass 'Drift skill contract validated'
    }

    return $isValid
}

function Test-ReviewArtifact {
    param([string]$ReviewPath)

    if (-not (Test-Path -LiteralPath $ReviewPath -PathType Leaf)) {
        Write-Fail "Review artifact missing: $ReviewPath"
        return $false
    }

    $content = Get-Content -LiteralPath $ReviewPath -Raw -Encoding UTF8
    $isValid = $true

    $checks = @(
        @{ Pattern = '\*\*Overall Verdict\*\*:\s*accepted'; Failure = 'Review artifact did not record the requested accepted verdict.' },
        @{ Pattern = '\| T-900 \| FR-008 \| needs-work \|'; Failure = 'Review artifact is missing the seeded task verdict row.' },
        @{ Pattern = 'invoke specrew-drift-check in batch and update drift-log\.md before accepting the iteration'; Failure = 'Review artifact is missing the drift-check escalation note.' }
    )

    foreach ($check in $checks) {
        if (-not (Test-ContentPattern -Content $content -Pattern $check.Pattern -FailureMessage $check.Failure)) {
            $isValid = $false
        }
    }

    if ($isValid) {
        Write-Pass 'Review scaffold captured drift-review expectations'
    }

    return $isValid
}

function Test-RetroArtifact {
    param([string]$RetroPath)

    if (-not (Test-Path -LiteralPath $RetroPath -PathType Leaf)) {
        Write-Fail "Retro artifact missing: $RetroPath"
        return $false
    }

    $content = Get-Content -LiteralPath $RetroPath -Raw -Encoding UTF8
    $isValid = $true

    $checks = @(
        @{ Pattern = '- Total drift events: 1'; Failure = 'Retro artifact did not summarize the drift-event count.' },
        @{ Pattern = '- Resolved via revert: 1'; Failure = 'Retro artifact did not summarize the implementation-reverted resolution count.' },
        @{ Pattern = '- Review verdict recorded as \*\*accepted\*\* before retrospective started\.'; Failure = 'Retro artifact lost the accepted review verdict handoff.' }
    )

    foreach ($check in $checks) {
        if (-not (Test-ContentPattern -Content $content -Pattern $check.Pattern -FailureMessage $check.Failure)) {
            $isValid = $false
        }
    }

    if ($isValid) {
        Write-Pass 'Retro scaffold captured resolved drift summary'
    }

    return $isValid
}

function Test-DriftDetectionResult {
    param([object]$Result)

    $isValid = $true

    if ($Result.verdict -ne 'DRIFT') {
        Write-Fail 'Drift detection did not report DRIFT for contradicting output.'
        $isValid = $false
    }

    if ($Result.requirement_ref -ne 'FR-008') {
        Write-Fail 'Drift detection did not preserve the expected requirement reference.'
        $isValid = $false
    }

    if (-not $Result.drift_events -or $Result.drift_events.Count -eq 0) {
        Write-Fail 'Drift detection did not emit any drift events.'
        $isValid = $false
    }
    else {
        $firstEvent = $Result.drift_events[0]
        if ($firstEvent.resolution -ne 'implementation-reverted') {
            Write-Fail 'Drift detection did not propose the expected implementation-reverted resolution.'
            $isValid = $false
        }

        if ($firstEvent.log_snippet -notmatch '\*\*DR-001\*\*') {
            Write-Fail 'Drift detection did not produce a drift-log-ready snippet.'
            $isValid = $false
        }
    }

    if ($isValid) {
        Write-Pass 'Executed contradicting output triggered drift detection'
    }

    return $isValid
}

function Test-ResolvedDriftResult {
    param([object]$Result)

    $isValid = $true

    if ($Result.verdict -ne 'PASS') {
        Write-Fail 'Resolved output did not return PASS after implementation revert.'
        $isValid = $false
    }

    if ($Result.evidence_summary -notmatch 'contains required token|does not contain forbidden token') {
        Write-Fail 'Resolved drift result did not summarize the restored compliant evidence.'
        $isValid = $false
    }

    if ($isValid) {
        Write-Pass 'Resolved output cleared drift after implementation revert'
    }

    return $isValid
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\drift-scenario'
$iterationRoot = Join-Path -Path $scratchRoot -ChildPath 'iterations\999'
$skillPath = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\squad-templates\skills\drift-check.md'
$driftDiffScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\drift-diff.ps1'
$reviewScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1'
$retroScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1'
$planPath = Join-Path -Path $iterationRoot -ChildPath 'plan.md'
$statePath = Join-Path -Path $iterationRoot -ChildPath 'state.md'
$driftPath = Join-Path -Path $iterationRoot -ChildPath 'drift-log.md'
$reviewPath = Join-Path -Path $iterationRoot -ChildPath 'review.md'
$retroPath = Join-Path -Path $iterationRoot -ChildPath 'retro.md'
$specPath = Join-Path -Path $scratchRoot -ChildPath 'spec.md'
$taskOutputPath = Join-Path -Path $scratchRoot -ChildPath 'task-output.txt'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $iterationRoot -ItemType Directory -Force

$specContent = @'
# Feature Spec: 999 Drift Sample

## Functional Requirements

- **FR-008**: Contradicting task output MUST include `BLUE` and MUST NOT include `RED`.
'@

$planContent = @'
# Iteration Plan: 999

**Capacity**: 1/1 story_points

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-900 | Simulate contradicting output | FR-008 | US-3 | 1 | Planner | done | copilot-agent | 1 | pass |

## Phase Baseline

| Phase | Goal | Estimated Effort | Exit Criteria |
| ----- | ---- | ---------------- | ------------- |
| Planning | Create a traceable scenario | 0.25 | Drift scenario is traceable to FR-008 |
| Implementation | Produce contradictory output for review | 0.5 | Scenario can exercise drift handling |
| Review | Validate drift and resolution handling | 0.25 | Review artifact records the required verdicts |
'@

$stateContent = @'
# Iteration State: 999

**Schema**: v1
**Last Completed Task**: T-900
**Tasks Remaining**: (none)
**In Progress**: (none)
**Updated**: 2026-04-30T00:00:00Z

## Execution Summary

 - Contradicting output was introduced intentionally for drift validation and then reverted after detection.
'@
[System.IO.File]::WriteAllText($specPath, $specContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($taskOutputPath, @'
TaskId: T-900
RequirementRef: FR-008
Delivered output: RED
'@, [System.Text.UTF8Encoding]::new($false))

$skillValid = Test-DriftSkillContract -SkillPath $skillPath
$driftResult = Invoke-TestScriptJson -ScriptPath $driftDiffScript -ArgumentList @('-SpecPath', $specPath, '-TaskId', 'T-900', '-ImplementationPath', $taskOutputPath)
$driftDetected = Test-DriftDetectionResult -Result $driftResult

$driftContent = @"
# Drift Log: Iteration 999

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: Resolved via implementation correction

## Events

$($driftResult.drift_events[0].log_snippet)
"@

[System.IO.File]::WriteAllText($driftPath, $driftContent, [System.Text.UTF8Encoding]::new($false))

Invoke-TestScript -ScriptPath $reviewScript -ArgumentList @('-IterationDirectory', $iterationRoot, '-OverallVerdict', 'accepted', '-DefaultTaskVerdict', 'needs-work') | Out-Null
$reviewValid = Test-ReviewArtifact -ReviewPath $reviewPath
$retroBlockedByPlaceholderReview = Invoke-TestScriptExpectFailure -ScriptPath $retroScript -ArgumentList @('-IterationDirectory', $iterationRoot)
if ($retroBlockedByPlaceholderReview) {
    Write-Pass 'Retro scaffold rejected placeholder review output'
}

$placeholderNoteOnlyReviewContent = @'
# Review: Iteration 999

**Schema**: v1
**Reviewed**: 2026-04-30
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-900 | FR-008 | pass | Deferred work; confirm the deferral is still acceptable for this iteration. |

## Notes

- Review completed after manual reminder cleanup, but task notes are still scaffold placeholders.
'@

[System.IO.File]::WriteAllText($reviewPath, $placeholderNoteOnlyReviewContent, [System.Text.UTF8Encoding]::new($false))
$retroBlockedByPlaceholderNotes = Invoke-TestScriptExpectFailure -ScriptPath $retroScript -ArgumentList @('-IterationDirectory', $iterationRoot)
if ($retroBlockedByPlaceholderNotes) {
    Write-Pass 'Retro scaffold rejected placeholder review notes without relying on the top-level reminder'
}

[System.IO.File]::WriteAllText($taskOutputPath, @'
TaskId: T-900
RequirementRef: FR-008
Delivered output: BLUE
'@, [System.Text.UTF8Encoding]::new($false))
$resolvedDriftResult = Invoke-TestScriptJson -ScriptPath $driftDiffScript -ArgumentList @('-SpecPath', $specPath, '-TaskId', 'T-900', '-ImplementationPath', $taskOutputPath)
$resolvedDriftValid = Test-ResolvedDriftResult -Result $resolvedDriftResult

$completedReviewContent = @'
# Review: Iteration 999

**Schema**: v1
**Reviewed**: 2026-04-30
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-900 | FR-008 | pass | Contradicting output was reverted before acceptance, and the final delivered output now contains `BLUE` without `RED`. |

## Notes

- Review completed after the drift event was resolved via implementation revert.
'@

[System.IO.File]::WriteAllText($reviewPath, $completedReviewContent, [System.Text.UTF8Encoding]::new($false))
Invoke-TestScript -ScriptPath $retroScript -ArgumentList @('-IterationDirectory', $iterationRoot) | Out-Null
$retroValid = Test-RetroArtifact -RetroPath $retroPath

if (-not ($skillValid -and $driftDetected -and $reviewValid -and $retroBlockedByPlaceholderReview -and $retroBlockedByPlaceholderNotes -and $resolvedDriftValid -and $retroValid)) {
    exit 1
}

Write-Pass 'Drift scenario lifecycle checks passed'
exit 0
