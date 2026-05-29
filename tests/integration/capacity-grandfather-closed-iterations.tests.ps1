[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\capacity-grandfather'
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }

function New-FixtureProject {
    param([string]$Root)
    $null = New-Item -ItemType Directory -Path (Join-Path $Root '.squad') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $Root '.specrew') -Force
    @'
# Squad Team

## Members

| Name | Role | Charter | Status |
| ---- | ---- | ------- | ------ |
| spec-steward | Spec Steward | `.squad/agents/spec-steward/charter.md` | baseline |
| planner | Planner | `.squad/agents/planner/charter.md` | baseline |
| implementer | Implementer | `.squad/agents/implementer/charter.md` | baseline |
| reviewer | Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| retro-facilitator | Retro Facilitator | `.squad/agents/retro-facilitator/charter.md` | baseline |
'@ | Set-Content -LiteralPath (Join-Path $Root '.squad\team.md') -Encoding UTF8
    # iteration-config baseline = 25 (the "current" baseline that drifted from historical 20).
    @'
effort_unit: "story_points"
capacity_per_iteration: 25
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
defer_strategy: "manual"
calibration_enabled: true
'@ | Set-Content -LiteralPath (Join-Path $Root '.specrew\iteration-config.yml') -Encoding UTF8
    @'
specrew_version: "0.28.0"
public_readiness:
  enabled: false
'@ | Set-Content -LiteralPath (Join-Path $Root '.specrew\config.yml') -Encoding UTF8
}

function New-EffortModelPlan {
    param([string]$IterationDir, [string]$Status, [string]$Capacity, [string]$Completed)
    $completedLine = if ([string]::IsNullOrWhiteSpace($Completed)) { '' } else { "**Completed**: $Completed" }
    @"
# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: $Status
**Capacity**: $Capacity
**Started**: 2026-05-01
$completedLine

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T001 | Fixture | FR-001 | US1 | 1 | Implementer | done | codex | 1 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | unit |
| Capacity per Iteration | 20 | historical baseline at this iteration's time |
| Iteration Bounding | scope | scope |
| Time Limit (hours) | n/a | n/a |
| Overcommit Threshold | 1.0 | warn |
| Defer Strategy | manual | manual |
| Calibration Enabled | true | yes |
"@ | Set-Content -LiteralPath (Join-Path $IterationDir 'plan.md') -Encoding UTF8
    @'
# Iteration State: 002

**Schema**: v1
**Current Phase**: iteration-closeout
**Iteration Status**: complete
**Last Completed Task**: T001
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-05-01T00:00:00Z
'@ | Set-Content -LiteralPath (Join-Path $IterationDir 'state.md') -Encoding UTF8
    @'
# Drift Log: Iteration 002

**Schema**: v1
'@ | Set-Content -LiteralPath (Join-Path $IterationDir 'drift-log.md') -Encoding UTF8
}

function Get-ValidatorText {
    param([string]$Root, [string]$IterationDir)
    $out = @(pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $Root -IterationPath $IterationDir -NoParallel -NoCacheRead 2>&1)
    return ($out | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
}

$capacityFailPattern = "Capacity (total '20'|per Iteration' value '20') does not match (the plan's own|iteration-config)"
$capacityVsConfigPattern = "does not match iteration-config(.*'25'| capacity_per_iteration '25')"

# --- Closed iteration: capacity 20 under config 25 -> grandfathered, NO capacity-vs-config FAIL ---
$closedRoot = Join-Path $scratchRoot 'closed-project'
$closedIter = Join-Path $closedRoot 'specs\017-sample\iterations\002'
$null = New-Item -ItemType Directory -Path $closedIter -Force
New-FixtureProject -Root $closedRoot
New-EffortModelPlan -IterationDir $closedIter -Status 'complete' -Capacity '20/20 story_points' -Completed '2026-05-01'
$closedText = Get-ValidatorText -Root $closedRoot -IterationDir $closedIter
if ($closedText -match $capacityVsConfigPattern) {
    Write-Fail "Closed iteration (capacity 20, config 25) still FAILED the capacity-vs-config check; grandfathering did not apply."
    Write-Host $closedText
    exit 1
}
Write-Pass 'Closed iteration with historical capacity 20 under config 25 is grandfathered (no capacity-vs-config FAIL)'

# --- Active iteration: capacity 20 under config 25 -> NOT grandfathered, capacity-vs-config FAIL ---
$activeRoot = Join-Path $scratchRoot 'active-project'
$activeIter = Join-Path $activeRoot 'specs\017-sample\iterations\002'
$null = New-Item -ItemType Directory -Path $activeIter -Force
New-FixtureProject -Root $activeRoot
New-EffortModelPlan -IterationDir $activeIter -Status 'planning' -Capacity '10/20 story_points' -Completed ''
$activeText = Get-ValidatorText -Root $activeRoot -IterationDir $activeIter
if ($activeText -notmatch $capacityVsConfigPattern) {
    Write-Fail "Active iteration (capacity 20, config 25) did NOT FAIL the capacity-vs-config check; active iterations must still validate against current config."
    Write-Host $activeText
    exit 1
}
Write-Pass 'Active iteration with capacity 20 under config 25 still FAILs the capacity-vs-config check (config enforced for in-flight work)'

# --- Closed via HISTORICAL plan-Status form (retro-complete): the corpus uses non-canonical closed
#     status forms; grandfathering must detect them, not only 'complete'/'abandoned'. ---
$retroRoot = Join-Path $scratchRoot 'retro-complete-project'
$retroIter = Join-Path $retroRoot 'specs\017-sample\iterations\002'
$null = New-Item -ItemType Directory -Path $retroIter -Force
New-FixtureProject -Root $retroRoot
New-EffortModelPlan -IterationDir $retroIter -Status 'retro-complete' -Capacity '20/20 story_points' -Completed '2026-05-01'
$retroText = Get-ValidatorText -Root $retroRoot -IterationDir $retroIter
if ($retroText -match $capacityVsConfigPattern) {
    Write-Fail "Closed iteration with historical plan Status 'retro-complete' (capacity 20, config 25) still FAILED the capacity-vs-config check; broadened status grandfathering did not apply."
    Write-Host $retroText
    exit 1
}
Write-Pass "Closed iteration with historical plan Status 'retro-complete' is grandfathered (broadened closed-status detection)"

# --- Closed via the DURABLE closed-iteration INDEX while plan Status is a non-terminal form
#     (reviewing): .specrew/closed-iterations.yml is the authoritative closeout signal and must
#     grandfather even when the plan Status text does not look closed. ---
$indexRoot = Join-Path $scratchRoot 'closed-index-project'
$indexIter = Join-Path $indexRoot 'specs\017-sample\iterations\002'
$null = New-Item -ItemType Directory -Path $indexIter -Force
New-FixtureProject -Root $indexRoot
New-EffortModelPlan -IterationDir $indexIter -Status 'reviewing' -Capacity '20/20 story_points' -Completed ''
@'
# Specrew closed-iteration index (Proposal 085).
closed:
  - feature: 017-sample
    iteration: 002
    closed_at: 2026-05-01T00:00:00Z
'@ | Set-Content -LiteralPath (Join-Path $indexRoot '.specrew\closed-iterations.yml') -Encoding UTF8
$indexText = Get-ValidatorText -Root $indexRoot -IterationDir $indexIter
if ($indexText -match $capacityVsConfigPattern) {
    Write-Fail "Iteration recorded in .specrew/closed-iterations.yml (plan Status 'reviewing', capacity 20, config 25) still FAILED the capacity-vs-config check; durable closed-index grandfathering did not apply."
    Write-Host $indexText
    exit 1
}
Write-Pass 'Iteration closed via the durable closed-iteration index is grandfathered even when plan Status is non-terminal'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue }
Write-Pass 'Capacity grandfathering: closed iterations use their own stated capacity; active iterations enforce current config'
exit 0
