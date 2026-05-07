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
$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\process-quality-report'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$iterationOneRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-eval-feature\iterations\001'
$iterationTwoRoot = Join-Path -Path $projectRoot -ChildPath 'specs\001-eval-feature\iterations\002'
$reportPath = Join-Path -Path $projectRoot -ChildPath 'evaluation\report.md'

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

$output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $scorerScript -ProjectPath $projectRoot -WriteReport 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Process scorer report generation failed.'
    $output | ForEach-Object { Write-Host $_ }
    exit 1
}

if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    Write-Fail 'Process scorer did not create evaluation\report.md.'
    exit 1
}

$reportContent = Get-Content -LiteralPath $reportPath -Raw -Encoding UTF8
foreach ($expectedSnippet in @(
    '# Evaluation Report',
    '## Process Quality',
    '## Outcome Quality',
    'Deferred to Iteration 3',
    '## Per-Iteration Breakdown',
    '### Iteration 001',
    '### Iteration 002',
    'Artifact adherence: **FAIL**',
    'Phase adherence: **FAIL**'
)) {
    if (-not $reportContent.Contains($expectedSnippet)) {
        Write-Fail "Generated process report is missing expected content: $expectedSnippet"
        exit 1
    }
}

Write-Pass 'Process scorer writes a Markdown report with process and deferred outcome sections'
exit 0
