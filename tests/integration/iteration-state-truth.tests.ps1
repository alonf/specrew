[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail $Message
        Write-Host $Text
        exit 1
    }
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content.TrimStart() + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function New-StateTruthFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $projectRoot = Join-Path $Root $Name
    $featureRef = '221-state-md-flow'
    $featurePath = Join-Path $projectRoot "specs\$featureRef"
    $iterationPath = Join-Path $featurePath 'iterations\001'
    New-Item -ItemType Directory -Path $iterationPath -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.squad') -Force | Out-Null
    Write-TextFile -Path (Join-Path $projectRoot '.squad\decisions.md') -Content '# Decisions'
    Write-TextFile -Path (Join-Path $featurePath 'spec.md') -Content '# Spec'
    Write-TextFile -Path (Join-Path $iterationPath 'plan.md') -Content @'
# Iteration Plan: 001

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T001 | Build path | FR-001 | US-1 | 1 | Implementer | done |
| T002 | Verify path | SC-001 | US-1 | 1 | Reviewer | planned |
'@

    return [pscustomobject]@{
        ProjectRoot   = $projectRoot
        FeatureRef    = $featureRef
        FeaturePath   = $featurePath
        IterationPath = $iterationPath
    }
}

function Write-ScaffoldState {
    param([Parameter(Mandatory = $true)][string]$IterationPath)

    Write-TextFile -Path (Join-Path $IterationPath 'state.md') -Content @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: (none)
**Tasks Remaining**: (populate from plan.md)
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-06-08T00:00:00Z

## Execution Summary

- Execution has not started yet.
- This artifact was scaffolded before task execution so resume state can be updated after each task.
'@
}

function Write-PartialReviewState {
    param([Parameter(Mandatory = $true)][string]$IterationPath)

    Write-TextFile -Path (Join-Path $IterationPath 'state.md') -Content @'
# Iteration State: 001

**Schema**: v1
**Current Phase**: review-signoff
**Iteration Status**: reviewing
**Last Completed Task**: T001
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-06-08T00:00:00Z

## Execution Summary

- Execution has not started yet.
- This artifact was scaffolded before task execution so resume state can be updated after each task.
'@
}

function Write-LegacyProgressState {
    param([Parameter(Mandatory = $true)][string]$IterationPath)

    Write-TextFile -Path (Join-Path $IterationPath 'state.md') -Content @'
# Iteration State: 001

**Schema**: v1
**Current Phase**: review-signoff
**Iteration Status**: reviewing
**Baseline Ref**: HEAD
**Updated**: 2026-06-08T00:00:00Z

## Execution Summary

- Review artifacts are present and the iteration has reached review-signoff.
'@
}

function Write-ReviewEvidence {
    param([Parameter(Mandatory = $true)][string]$IterationPath)

    Write-TextFile -Path (Join-Path $IterationPath 'code-map.md') -Content '# Code Map'
    Write-TextFile -Path (Join-Path $IterationPath 'reviewer-index.md') -Content @'
# Reviewer Index

## Summary

- Evidence exists.

## Replay Digest

digest
'@
    Write-TextFile -Path (Join-Path $IterationPath 'review.md') -Content @'
# Review

**Reviewed**: 2026-06-08
**Overall Verdict**: accepted
'@
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1')

$scratchRoot = Join-Path $repoRoot '.scratch\iteration-state-truth'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

$clean = New-StateTruthFixture -Root $scratchRoot -Name 'clean-scaffold'
Write-ScaffoldState -IterationPath $clean.IterationPath
$cleanIssues = @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $clean.ProjectRoot -FeatureRef $clean.FeatureRef -IterationNumber '001')
if ($cleanIssues.Count -ne 0) {
    Write-Fail "A scaffold-only not-started iteration should not be reported stale."
    Write-Host ($cleanIssues -join [Environment]::NewLine)
    exit 1
}
Write-Pass 'Scaffold-only not-started state passes truth check'

$stale = New-StateTruthFixture -Root $scratchRoot -Name 'stale-with-evidence'
Write-ScaffoldState -IterationPath $stale.IterationPath
Write-ReviewEvidence -IterationPath $stale.IterationPath
$staleIssues = @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $stale.ProjectRoot -FeatureRef $stale.FeatureRef -IterationNumber '001')
Assert-Match -Text ($staleIssues -join [Environment]::NewLine) -Pattern 'Execution has not started yet.*evidence artifacts exist' -Message 'Scaffold state with implementation/review evidence should be rejected.'
Write-Pass 'Scaffold state with evidence is rejected'

$partial = New-StateTruthFixture -Root $scratchRoot -Name 'partial-review'
Write-PartialReviewState -IterationPath $partial.IterationPath
Write-ReviewEvidence -IterationPath $partial.IterationPath
$partialIssues = @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $partial.ProjectRoot -FeatureRef $partial.FeatureRef -IterationNumber '001')
Assert-Match -Text ($partialIssues -join [Environment]::NewLine) -Pattern 'Execution has not started yet' -Message 'Partially updated review-signoff state should still reject stale execution summary.'
Write-Pass 'Partial review-signoff state with stale summary is rejected'

$legacy = New-StateTruthFixture -Root $scratchRoot -Name 'legacy-without-task-fields'
Write-LegacyProgressState -IterationPath $legacy.IterationPath
Write-ReviewEvidence -IterationPath $legacy.IterationPath
$legacyIssues = @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $legacy.ProjectRoot -FeatureRef $legacy.FeatureRef -IterationNumber '001')
if ($legacyIssues.Count -ne 0) {
    Write-Fail 'Legacy progressed state without task metadata labels should not be treated as scaffold task fields.'
    Write-Host ($legacyIssues -join [Environment]::NewLine)
    exit 1
}
Write-Pass 'Legacy progressed state without task fields is not marked scaffolded'

$gateBlocked = $false
try {
    Invoke-SpecrewIterationStateTruthGate -ProjectRoot $stale.ProjectRoot -BoundaryType 'review-signoff' -FeatureRef $stale.FeatureRef -IterationNumber '001'
}
catch {
    $gateBlocked = ($_.Exception.Message -match '\[iteration-state-truth-gate\]')
}

if (-not $gateBlocked) {
    Write-Fail 'Review-signoff boundary should block stale state.md when review evidence exists.'
    exit 1
}
Write-Pass 'Review-signoff boundary blocks stale iteration state'

$reviewOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts\specrew-review.ps1') -ProjectPath $partial.ProjectRoot -FeatureId $partial.FeatureRef -IterationNumber '001' -Json 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail ("specrew review failed unexpectedly:`n{0}" -f ($reviewOutput -join [Environment]::NewLine))
    exit 1
}

$reviewJson = $reviewOutput -join [Environment]::NewLine
Assert-Match -Text $reviewJson -Pattern 'Iteration state truth mismatch' -Message 'specrew review should surface stale state.md truth warnings.'
Write-Pass 'specrew review surfaces state truth warnings'

exit 0
