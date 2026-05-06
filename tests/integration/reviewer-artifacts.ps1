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

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$scriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Fail "Missing reviewer artifact script: $scriptPath"
    exit 1
}

$scratchRoot = Join-Path $repoRoot '.scratch\reviewer-artifacts'
$projectRoot = Join-Path $scratchRoot 'project'
$iterationDirectory = Join-Path $projectRoot 'specs\001-sample\iterations\005'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $iterationDirectory -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.squad') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests\integration') -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to initialize scratch git repo.'
    exit 1
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\iteration-config.yml'), @'
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"
reviewer:
  test_path_globs:
    - "**/tests/**"
    - "**/*test*.*"
  sensitive_data_patterns:
    - "auth*"
    - "token*"
  test_commands: []
  coverage:
    tool: ""
    kind: "qualitative"
  skip_test_execution_at_close: false
  vulnerability_scanner:
    auto_detect: false
    command: ""
    candidates:
      - "npm audit --json"
  baseline_ref: "iteration-baseline"
  diagram_format: "mermaid"
  hotspot_thresholds:
    file_changed_lines: 5
    function_changed_lines: 2
  diagram_thresholds:
    structure:
      min_modules_touched: 2
      min_inter_module_edges: 1
    flow:
      min_entrypoints_changed: 1
      min_modules_in_flow: 2
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), @'
# Squad Team

## Members

| Name | Role | Charter | Status |
| ---- | ---- | ------- | ------ |
| reviewer | Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| security-analyst | Security Analyst | `.squad/agents/security-analyst/charter.md` | active |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $projectRoot 'package.json'), @'
{
  "name": "sample-project",
  "version": "1.0.0",
  "dependencies": {
    "left-pad": "^1.3.0"
  }
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\api.js'), @'
export function getOldValue() {
  return "old";
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\auth.js'), @'
export function maskToken(token) {
  return token;
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'tests\integration\api.test.js'), "describe('api', () => { it('works', () => expect(true).toBe(true)); });`n", [System.Text.UTF8Encoding]::new($false))

@(& git -C $projectRoot add . 2>&1) | Out-Null
$commitOutput = @(& git -C $projectRoot -c user.name=Copilot -c user.email=copilot@example.com commit -m "baseline" --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Failed to create baseline commit.'
    exit 1
}

$baselineRef = (@(& git -C $projectRoot rev-parse HEAD 2>&1))[0]
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'package.json'), @'
{
  "name": "sample-project",
  "version": "1.1.0",
  "dependencies": {
    "left-pad": "^1.3.0",
    "chalk": "^5.3.0"
  }
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\api.js'), @'
import { maskToken } from "./auth.js";

export function getOldValue() {
  return "old";
}

export function getNewValue(token) {
  return maskToken(token);
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'src\auth.js'), @'
export function maskToken(token) {
  return token.replace(/./g, "*");
}
'@, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'tests\integration\api.test.js'), @'
describe("api", () => {
  it("returns the masked value", () => {
    expect(true).toBe(true);
  });
});
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'plan.md'), @'
# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 5/20 story_points
**Started**: 2026-05-06
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-501 | Generate reviewer code map | FR-046 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-502 | Generate dependency and coverage evidence | FR-047, FR-049 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-503 | Replay reviewer closeout | FR-050, FR-051, FR-052 | US-2 | 1 | Reviewer | done | copilot-agent | 1 | pass |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'state.md'), @"
# Iteration State: 005

**Schema**: v1
**Last Completed Task**: T-503
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: $baselineRef
**Updated**: 2026-05-06T10:00:00Z

## Execution Summary

- Reviewer-core dogfood slice completed.
"@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'drift-log.md'), @'
# Drift Log: Iteration 005

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: None detected
**Implementation drift**: None detected

## Drift Events

- 2026-05-06 | review | Fixed reviewer digest contract mismatch before closure.

## Resolution Breakdown

- Resolved via spec update: 0
- Resolved via revert: 1
- Deferred: 0
- Escalated to human decision: 0
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'review.md'), @'
# Review: Iteration 005

**Schema**: v1
**Reviewed**: 2026-05-06
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-501 | FR-046 | pass | Code-map contract implemented. |
| T-502 | FR-047, FR-049 | pass | Dependency and coverage artifacts generated from baseline diff. |
| T-503 | FR-050, FR-051, FR-052 | pass | Replay surface matches persisted digest. |

## Gap Ledger

No known gaps remain.
'@, [System.Text.UTF8Encoding]::new($false))

$result = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath -IterationDirectory $iterationDirectory 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $result) {
        Write-Host $line
    }
    Write-Fail 'Reviewer artifact generation failed.'
    exit 1
}

$output = $result -join "`n"
$codeMapContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'code-map.md') -Raw -Encoding UTF8
$dependencyContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'dependency-report.md') -Raw -Encoding UTF8
$coverageContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'coverage-evidence.md') -Raw -Encoding UTF8
$securityContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'security-surface.md') -Raw -Encoding UTF8
$diagramContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'review-diagrams.md') -Raw -Encoding UTF8
$indexContent = Get-Content -LiteralPath (Join-Path $iterationDirectory 'reviewer-index.md') -Raw -Encoding UTF8
$currentArchitectureContent = Get-Content -LiteralPath (Join-Path $projectRoot 'specs\001-sample\current-architecture.md') -Raw -Encoding UTF8

foreach ($check in @(
        @{ Content = $codeMapContent; Pattern = '\| Path \| Lines Added \| Lines Removed \| Owning Task ID\(s\) \| Owning Role \|'; Failure = 'Code map is missing Files Touched columns.' },
        @{ Content = $codeMapContent; Pattern = '## Public-API Delta'; Failure = 'Code map is missing Public-API Delta.' },
        @{ Content = $codeMapContent; Pattern = 'getNewValue'; Failure = 'Code map did not report the added public API symbol.' },
        @{ Content = $codeMapContent; Pattern = '## Module Hotspots'; Failure = 'Code map is missing Module Hotspots.' },
        @{ Content = $dependencyContent; Pattern = '\| npm \| chalk \| none \| \^5\.3\.0 \| added \| unknown \|'; Failure = 'Dependency report did not record the new package row.' },
        @{ Content = $dependencyContent; Pattern = '## New-to-Project'; Failure = 'Dependency report is missing New-to-Project.' },
        @{ Content = $dependencyContent; Pattern = 'status:\s+unscanned'; Failure = 'Dependency report did not record unscanned vulnerability status.' },
        @{ Content = $coverageContent; Pattern = '## Test Strategy'; Failure = 'Coverage evidence is missing Test Strategy.' },
        @{ Content = $coverageContent; Pattern = '## Tests Run'; Failure = 'Coverage evidence is missing Tests Run.' },
        @{ Content = $coverageContent; Pattern = 'not_executed'; Failure = 'Coverage evidence did not record not_executed.' },
        @{ Content = $coverageContent; Pattern = 'Kind:\s+qualitative'; Failure = 'Coverage evidence did not record qualitative coverage kind.' },
        @{ Content = $securityContent; Pattern = '## Trust Boundaries Touched'; Failure = 'Security surface is missing trust boundaries.' },
        @{ Content = $securityContent; Pattern = '## Sensitive Data Touchpoints'; Failure = 'Security surface is missing sensitive touchpoints.' },
        @{ Content = $securityContent; Pattern = 'Security Analyst'; Failure = 'Security surface did not record the security-focused role.' },
        @{ Content = $diagramContent; Pattern = '## Structure Diagram'; Failure = 'Review diagrams are missing the structure section.' },
        @{ Content = $diagramContent; Pattern = '```mermaid'; Failure = 'Review diagrams did not emit Mermaid output.' },
        @{ Content = $currentArchitectureContent; Pattern = '\*\*Source Iteration Ref\*\*: 005'; Failure = 'Current architecture view did not record the source iteration.' },
        @{ Content = $indexContent; Pattern = '## Triage Hints'; Failure = 'Reviewer index is missing triage hints.' },
        @{ Content = $indexContent; Pattern = '\.squad\\decisions\.md'; Failure = 'Reviewer index is missing the decisions-ledger link.' },
        @{ Content = $indexContent; Pattern = 'security-surface\.md'; Failure = 'Reviewer index is missing the security surface link.' },
        @{ Content = $indexContent; Pattern = 'review-diagrams\.md'; Failure = 'Reviewer index is missing the review diagrams link.' },
        @{ Content = $indexContent; Pattern = 'current-architecture\.md'; Failure = 'Reviewer index is missing the current architecture link.' },
        @{ Content = $indexContent; Pattern = 'SPECREW_REVIEW schema=v1 iter=005 feature=001-sample verdict=accepted tasks=3/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=0 drift=1/1 index=specs\\001-sample\\iterations\\005\\reviewer-index\.md'; Failure = 'Reviewer index digest does not match FR-051.' },
        @{ Content = $output; Pattern = 'SPECREW_REVIEW schema=v1 iter=005 feature=001-sample verdict=accepted tasks=3/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=0 drift=1/1 index=specs\\001-sample\\iterations\\005\\reviewer-index\.md'; Failure = 'Closeout output did not emit the FR-051 digest.' }
    )) {
    if (-not (Assert-Contains -Content $check.Content -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}

Write-Pass 'Reviewer artifact generation produces FR-shaped closeout content'
exit 0
