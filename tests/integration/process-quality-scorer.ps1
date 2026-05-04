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

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scorerScript = Join-Path -Path $repoRoot -ChildPath 'evaluation\scorers\process-scorer.ps1'
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\process-quality-scorer'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$iterationOneRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-eval-feature\iterations\001'
$iterationTwoRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-eval-feature\iterations\002'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $iterationOneRoot -ItemType Directory -Force
$null = New-Item -Path $iterationTwoRoot -ItemType Directory -Force

[System.IO.File]::WriteAllText((Join-Path -Path $iterationOneRoot -ChildPath 'plan.md'), @'
# Iteration Plan: 001

**Schema**: v1
**Status**: executing
**Capacity**: 1/3 story_points
**Started**: 2026-05-03
**Completed**:
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationOneRoot -ChildPath 'state.md'), @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-001
**Tasks Remaining**: T-002
**In Progress**: (none)
**Updated**: 2026-05-03T00:00:00Z
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationOneRoot -ChildPath 'drift-log.md'), @'
# Drift Log: Iteration 001

**Schema**: v1

## Events

No specification drift detected during Iteration 001 execution to date.
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoRoot -ChildPath 'plan.md'), @'
# Iteration Plan: 002

**Schema**: v1
**Status**: complete
**Capacity**: 2/2 story_points
**Started**: 2026-05-03
**Completed**: 2026-05-03
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoRoot -ChildPath 'state.md'), @'
# Iteration State: 002

**Schema**: v1
**Last Completed Task**: T-010
**Tasks Remaining**: (none)
**In Progress**: (none)
**Updated**: 2026-05-03T00:00:00Z
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoRoot -ChildPath 'drift-log.md'), @'
# Drift Log: Iteration 002

**Schema**: v1

## Events

No specification drift detected during Iteration 002 execution to date.
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoRoot -ChildPath 'review.md'), @'
# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-03
**Overall Verdict**: accepted
'@, [System.Text.UTF8Encoding]::new($false))

$json = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $scorerScript -ProjectPath $projectRoot -AsJson 2>&1) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Process scorer script failed to execute.'
    exit 1
}

$result = $json | ConvertFrom-Json
if ($result.overall -ne 'FAIL') {
    Write-Fail 'Process scorer should fail when a complete iteration is missing retro.md.'
    exit 1
}

if ($result.criteria.artifact_adherence.failed_iterations -notcontains '002') {
    Write-Fail 'Process scorer did not flag missing required artifacts for iteration 002.'
    exit 1
}

if ($result.criteria.phase_adherence.failed_iterations -notcontains '002') {
    Write-Fail 'Process scorer did not flag phase-adherence failure for iteration 002.'
    exit 1
}

$iterationOne = @($result.iterations | Where-Object { $_.iteration_id -eq '001' })[0]
if ($iterationOne.artifact_adherence.status -ne 'PASS' -or $iterationOne.phase_adherence.status -ne 'PASS') {
    Write-Fail 'Process scorer should pass the healthy executing iteration.'
    exit 1
}

Write-Pass 'Process scorer returns structured artifact and phase adherence results'
exit 0
