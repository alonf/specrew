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

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-NotContains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -match $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function New-BaseProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $featureDirectory = Join-Path $ProjectRoot 'specs\001-review-evidence-integrity'
    $iterationDirectory = Join-Path $featureDirectory 'iterations\001'
    $null = New-Item -ItemType Directory -Path $iterationDirectory -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.specrew') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.squad') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot 'src') -Force

    @(& git -C $ProjectRoot init --quiet 2>&1) | Out-Null
    @(& git -C $ProjectRoot config user.name Copilot 2>&1) | Out-Null
    @(& git -C $ProjectRoot config user.email copilot@example.com 2>&1) | Out-Null

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\iteration-config.yml'), @'
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"
reviewer:
  test_path_globs: []
  sensitive_data_patterns: []
  test_commands: []
  coverage:
    tool: ""
    kind: "qualitative"
  skip_test_execution_at_close: false
  vulnerability_scanner:
    auto_detect: false
    command: ""
    candidates: []
  baseline_ref: "iteration-baseline"
  diagram_format: "mermaid"
  hotspot_thresholds:
    file_changed_lines: 1
    function_changed_lines: 1
  diagram_thresholds:
    structure:
      min_modules_touched: 1
      min_inter_module_edges: 0
    flow:
      min_entrypoints_changed: 1
      min_modules_in_flow: 1
'@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), @'
# Squad Team

## Members

| Name | Role | Charter | Status |
| ---- | ---- | ------- | ------ |
| spec-steward | Spec Steward | `.squad/agents/spec-steward/charter.md` | baseline |
| planner | Planner | `.squad/agents/planner/charter.md` | baseline |
| implementer | Implementer | `.squad/agents/implementer/charter.md` | baseline |
| reviewer | Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| retro-facilitator | Retro Facilitator | `.squad/agents/retro-facilitator/charter.md` | baseline |

## Specrew Baseline Roles

| Role | Charter | Status |
| ---- | ------- | ------ |
| Spec Steward | `.squad/agents/spec-steward/charter.md` | baseline |
| Planner | `.squad/agents/planner/charter.md` | baseline |
| Implementer | `.squad/agents/implementer/charter.md` | baseline |
| Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| Retro Facilitator | `.squad/agents/retro-facilitator/charter.md` | baseline |

**Team Status**: configured  
**Baseline Roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator  
**Configuration**: Specrew-managed baseline
'@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $featureDirectory 'spec.md'), @'
# Feature Spec: Review Evidence Integrity

## Summary

- Scratch spec used by the Feature 028 integration harness.
'@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'src\app.js'), @'
export function loadWidget() {
  return "baseline";
}
'@, [System.Text.UTF8Encoding]::new($false))

    @(& git -C $ProjectRoot add . 2>&1) | Out-Null
    @(& git -C $ProjectRoot commit -m "baseline" --quiet 2>&1) | Out-Null
    @(& git -C $ProjectRoot tag iteration-baseline 2>&1) | Out-Null

    return $iterationDirectory
}

function Set-IterationArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string]$TaskRows,

        [string]$LastCompletedTask = '(none)',

        [string]$TasksRemaining = '(none)'
    )

    [System.IO.File]::WriteAllText((Join-Path $IterationDirectory 'plan.md'), @"
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: $Status
**Capacity**: 3/20 story_points
**Started**: 2026-05-21
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
$TaskRows

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds threshold. |
| Defer Strategy | manual | How planning should choose deferrals. |
| Calibration Enabled | true | When true, retrospectives suggest adjustments. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Clarified feature slice. |
| Discovery/Spikes | 0 | No additional spikes. |
| Implementation | 2 | Validator and scaffold changes. |
| Review | 1 | Review evidence verification. |
| Rework | 0 | No expected buffer. |
"@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $IterationDirectory 'state.md'), @"
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: $LastCompletedTask
**Tasks Remaining**: $TasksRemaining
**In Progress**: (none)
**Baseline Ref**: iteration-baseline
**Updated**: 2026-05-21T00:00:00Z

## Execution Summary

- Review evidence integrity scratch scenario.
"@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $IterationDirectory 'drift-log.md'), @'
# Drift Log: Iteration 001

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 0% (0/0 resolved)
**Specification drift**: None detected
**Implementation drift**: None detected

## Drift Events

- none

## Resolution Breakdown

- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
'@, [System.Text.UTF8Encoding]::new($false))

    [System.IO.File]::WriteAllText((Join-Path $IterationDirectory 'review.md'), @'
# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-21
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | Scratch review artifact. |

## Gap Ledger

- fixed-now: No known gaps remain.
'@, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValidateScript,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ValidateScript -ProjectPath $ProjectRoot -IterationPath $IterationDirectory 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join [Environment]::NewLine)
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validateScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$reviewerScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'

foreach ($requiredPath in @($validateScript, $reviewerScript, $sharedGovernancePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredPath"
        exit 1
    }
}

. $sharedGovernancePath

$scratchRoot = Join-Path $repoRoot '.scratch\review-evidence-integrity'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

$allPassed = $true

try {
    $helperCases = @(
        @{ Declared = 2; Observed = 0; Expected = 'error'; Label = 'zero-diff helper severity' }
        @{ Declared = 0; Observed = 0; Expected = 'info'; Label = 'empty iteration helper severity' }
        @{ Declared = 2; Observed = 1; Expected = 'warning'; Label = 'partial helper severity' }
    )

    foreach ($helperCase in $helperCases) {
        $helperResult = Test-FormMeaningParity -Declared $helperCase.Declared -Observed $helperCase.Observed
        if ($helperResult.Severity -ne $helperCase.Expected) {
            Write-Fail "Helper scenario '$($helperCase.Label)' expected severity '$($helperCase.Expected)' but found '$($helperResult.Severity)'."
            $allPassed = $false
        }
    }
    if ($allPassed) {
        Write-Pass 'Helper API contract scenarios passed.'
    }

    $gapProject = Join-Path $scratchRoot 'gap-detected'
    $gapIteration = New-BaseProject -ProjectRoot $gapProject
    Set-IterationArtifacts -IterationDirectory $gapIteration -Status 'reviewing' -TaskRows '| T001 | Ship implementation | FR-001 | US-1 | 2 | Implementer | done | squad | 2 | pass |' -LastCompletedTask 'T001'
    $gapResult = Invoke-Validator -ValidateScript $validateScript -ProjectRoot $gapProject -IterationDirectory $gapIteration
    if ($gapResult.ExitCode -eq 0 -or -not (Assert-Contains -Content $gapResult.Output -Pattern '\[review-evidence-integrity\]|category=review-evidence-integrity' -FailureMessage 'Gap-detected scenario did not emit the review-evidence-integrity failure.')) {
        $allPassed = $false
    }
    else {
        Write-Pass 'Gap-detected scenario blocked review boundary as expected.'
    }

    $emptyProject = Join-Path $scratchRoot 'empty-iteration'
    $emptyIteration = New-BaseProject -ProjectRoot $emptyProject
    Set-IterationArtifacts -IterationDirectory $emptyIteration -Status 'reviewing' -TaskRows '| T001 | No implementation required | FR-EMPTY | US-0 | 0 | Planner | deferred | squad | 0 | pass |' -LastCompletedTask '(none)' -TasksRemaining '(none)'
    $emptyResult = Invoke-Validator -ValidateScript $validateScript -ProjectRoot $emptyProject -IterationDirectory $emptyIteration
    if ($emptyResult.ExitCode -ne 0) {
        Write-Fail "Empty iteration scenario failed unexpectedly:`n$($emptyResult.Output)"
        $allPassed = $false
    }
    elseif (-not (Assert-NotContains -Content $emptyResult.Output -Pattern '\[review-evidence-integrity\]|category=review-evidence-integrity' -FailureMessage ("Empty iteration scenario produced a false-positive review-evidence-integrity failure:`n" + $emptyResult.Output))) {
        $allPassed = $false
    }
    else {
        Write-Pass 'Empty-iteration scenario stayed clear of false positives.'
    }

    $cleanProject = Join-Path $scratchRoot 'clean-diff'
    $cleanIteration = New-BaseProject -ProjectRoot $cleanProject
    [System.IO.File]::WriteAllText((Join-Path $cleanProject 'src\app.js'), @'
export function loadWidget() {
  return "implemented";
}
'@, [System.Text.UTF8Encoding]::new($false))
    @(& git -C $cleanProject add . 2>&1) | Out-Null
    @(& git -C $cleanProject commit -m "implementation" --quiet 2>&1) | Out-Null
    Set-IterationArtifacts -IterationDirectory $cleanIteration -Status 'reviewing' -TaskRows '| T001 | Ship implementation | FR-001 | US-1 | 2 | Implementer | done | squad | 2 | pass |' -LastCompletedTask 'T001'
    $cleanResult = Invoke-Validator -ValidateScript $validateScript -ProjectRoot $cleanProject -IterationDirectory $cleanIteration
    if ($cleanResult.ExitCode -ne 0) {
        Write-Fail "Committed implementation scenario failed unexpectedly:`n$($cleanResult.Output)"
        $allPassed = $false
    }
    elseif (-not (Assert-NotContains -Content $cleanResult.Output -Pattern '\[review-evidence-integrity\]|category=review-evidence-integrity' -FailureMessage ("Clean committed scenario produced a false-positive review-evidence-integrity failure:`n" + $cleanResult.Output))) {
        $allPassed = $false
    }
    else {
        Write-Pass 'Committed implementation scenario passed without false positives.'
    }

    $rerunProject = Join-Path $scratchRoot 'rerunnable-artifacts'
    $rerunIteration = New-BaseProject -ProjectRoot $rerunProject
    [System.IO.File]::WriteAllText((Join-Path $rerunProject 'src\app.js'), @'
export function loadWidget() {
  return "v1";
}
'@, [System.Text.UTF8Encoding]::new($false))
    @(& git -C $rerunProject add . 2>&1) | Out-Null
    @(& git -C $rerunProject commit -m "implementation-v1" --quiet 2>&1) | Out-Null
    Set-IterationArtifacts -IterationDirectory $rerunIteration -Status 'reviewing' -TaskRows '| T001 | Ship implementation | FR-001 | US-1 | 2 | Implementer | done | squad | 2 | pass |' -LastCompletedTask 'T001'

    $firstRun = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewerScript -IterationDirectory $rerunIteration -Confirm:$false 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Initial scaffolder run failed for rerun scenario.'
        $allPassed = $false
    }
    else {
        $codeMapPath = Join-Path $rerunIteration 'code-map.md'
        $firstCodeMap = if (Test-Path -LiteralPath $codeMapPath -PathType Leaf) { Get-Content -LiteralPath $codeMapPath -Raw -Encoding UTF8 } else { '' }

        [System.IO.File]::WriteAllText((Join-Path $rerunProject 'src\late.js'), @'
export function lateCommitMarker() {
  return "late";
}
'@, [System.Text.UTF8Encoding]::new($false))
        @(& git -C $rerunProject add . 2>&1) | Out-Null
        @(& git -C $rerunProject commit -m "late-commit" --quiet 2>&1) | Out-Null

        $rerunOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewerScript -IterationDirectory $rerunIteration -Force -Confirm:$false 2>&1)
        $secondCodeMap = if (Test-Path -LiteralPath $codeMapPath -PathType Leaf) { Get-Content -LiteralPath $codeMapPath -Raw -Encoding UTF8 } else { '' }

        if ($LASTEXITCODE -ne 0) {
            Write-Fail 'Forced scaffolder rerun failed for late-commit scenario.'
            $allPassed = $false
        }
        elseif ([string]::IsNullOrWhiteSpace($firstCodeMap) -or [string]::IsNullOrWhiteSpace($secondCodeMap) -or $firstCodeMap -eq $secondCodeMap) {
            Write-Fail 'Forced scaffolder rerun did not refresh the generated review artifacts after the late commit.'
            $allPassed = $false
        }
        else {
            Write-Pass 'Late-commit rerun scenario refreshed generated artifacts with -Force -Confirm:$false.'
        }
    }
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (-not $allPassed) {
    exit 1
}

Write-Host 'PASS: Review evidence integrity integration lane passed.' -ForegroundColor Green
