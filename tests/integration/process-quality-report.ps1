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
$iterationOneQualityRoot = Join-Path -Path $iterationOneRoot -ChildPath 'quality'
$iterationTwoQualityRoot = Join-Path -Path $iterationTwoRoot -ChildPath 'quality'
$reportPath = Join-Path -Path $projectRoot -ChildPath 'evaluation\report.md'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $iterationOneRoot -ItemType Directory -Force
$null = New-Item -Path $iterationTwoRoot -ItemType Directory -Force
$null = New-Item -Path $iterationOneQualityRoot -ItemType Directory -Force
$null = New-Item -Path $iterationTwoQualityRoot -ItemType Directory -Force

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
[System.IO.File]::WriteAllText((Join-Path -Path $iterationOneQualityRoot -ChildPath 'quality-evidence.md'), @'
# Quality Evidence: Iteration 001

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/001-eval-feature/iterations/001/quality/mechanical-findings.json`
**Reviewed By**: Mechanical checks (automated)
**Reviewed At**: 2026-05-03T00:00:00Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | FR-011, FR-027, FR-030 | `specs/001-eval-feature/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `anti-pattern` | FR-011, FR-028, FR-030 | `specs/001-eval-feature/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `test-integrity` | FR-011, FR-029, FR-030 | `specs/001-eval-feature/iterations/001/quality/mechanical-findings.json` | `passed` | `—` |
| `stack-tooling-evidence` | FR-011 | `specs/001-eval-feature/iterations/001/quality/quality-evidence.md` | `passed` | `—` |
| `quality-lens-review` | FR-011, FR-012 | `specs/001-eval-feature/iterations/001/quality/quality-evidence.md` | `passed` | `—` |
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationOneQualityRoot -ChildPath 'mechanical-findings.json'), @'
{
  "schemaVersion": "v1",
  "featureRef": "specs/001-eval-feature/spec.md",
  "iterationRef": "specs/001-eval-feature/iterations/001",
  "generatedAt": "2026-05-03T00:00:00Z",
  "generator": {
    "name": "specrew-mechanical-checks",
    "version": "0.1.0-dev"
  },
  "findings": []
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoQualityRoot -ChildPath 'quality-evidence.md'), @'
# Quality Evidence: Iteration 002

**Profile Ref**: `quality-profile.pending`
**Preset Refs**: (pending preset selection)
**Findings Ref**: `specs/001-eval-feature/iterations/002/quality/mechanical-findings.json`
**Reviewed By**: Mechanical checks (automated)
**Reviewed At**: 2026-05-03T00:00:00Z

## Gate Matrix

| Gate | Requirement | Evidence Source | Status | Exception |
| --- | --- | --- | --- | --- |
| `dead-field` | FR-011, FR-027, FR-030 | `specs/001-eval-feature/iterations/002/quality/mechanical-findings.json` | `passed` | `—` |
| `anti-pattern` | FR-011, FR-028, FR-030 | `specs/001-eval-feature/iterations/002/quality/mechanical-findings.json` | `passed` | `—` |
| `test-integrity` | FR-011, FR-029, FR-030 | `specs/001-eval-feature/iterations/002/quality/mechanical-findings.json` | `passed` | `—` |
| `stack-tooling-evidence` | FR-011 | `specs/001-eval-feature/iterations/002/quality/quality-evidence.md` | `planned` | `—` |
| `quality-lens-review` | FR-011, FR-012 | `specs/001-eval-feature/iterations/002/quality/quality-evidence.md` | `planned` | `—` |
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $iterationTwoQualityRoot -ChildPath 'mechanical-findings.json'), @'
{
  "schemaVersion": "v1",
  "featureRef": "specs/001-eval-feature/spec.md",
  "iterationRef": "specs/001-eval-feature/iterations/002",
  "generatedAt": "2026-05-03T00:00:00Z",
  "generator": {
    "name": "specrew-mechanical-checks",
    "version": "0.1.0-dev"
  },
  "findings": []
}
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
    'missing: retro.md',
    'Phase adherence: **FAIL**'
)) {
    if (-not $reportContent.Contains($expectedSnippet)) {
        Write-Fail "Generated process report is missing expected content: $expectedSnippet"
        exit 1
    }
}

Write-Pass 'Process scorer writes a Markdown report with process and deferred outcome sections'
exit 0
