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

function Assert-Match {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail $Message
        return $false
    }

    return $true
}

function Assert-NotMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Message
    )

    if ($Text -match $Pattern) {
        Write-Fail $Message
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$taskProgressHelper = Join-Path $repoRoot 'scripts\internal\task-progress.ps1'
$skillCatalogHelper = Join-Path $repoRoot 'scripts\internal\skill-catalog-state.ps1'
$reviewerScaffolder = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'

foreach ($path in @($validatorScript, $taskProgressHelper, $skillCatalogHelper, $reviewerScaffolder)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Missing required script: $path"
        exit 1
    }
}

$scratchRoot = Join-Path $repoRoot '.scratch\f047-trust-hardening'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'validator-project'
$iterationPath = Join-Path $projectRoot 'specs\017-sample\iterations\002'
$null = New-Item -ItemType Directory -Path $iterationPath -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.squad') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'scripts\internal') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.antigravitycli\brain\session-1') -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'proposals') -Force

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
'@ | Set-Content -LiteralPath (Join-Path $projectRoot '.squad\team.md') -Encoding UTF8

@'
specrew_version: "0.27.3"
public_readiness:
  enabled: false
'@ | Set-Content -LiteralPath (Join-Path $projectRoot '.specrew\config.yml') -Encoding UTF8

@'
# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 2/20 story_points
**Started**: 2026-05-26
**Completed**:

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T001 | Fixture | FR-001 | US1 | 1 | Implementer | planned | codex | - | - |
| T002 | Fixture two | FR-002 | US1 | 1 | Implementer | planned | codex | - | - |
'@ | Set-Content -LiteralPath (Join-Path $iterationPath 'plan.md') -Encoding UTF8

@'
# Iteration State: 002

**Schema**: v1
**Current Phase**: planning
**Iteration Status**: planning
**Last Completed Task**: (none)
**Tasks Remaining**: T001-T002
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-05-26T00:00:00Z
'@ | Set-Content -LiteralPath (Join-Path $iterationPath 'state.md') -Encoding UTF8

@'
# Drift Log: Iteration 002

**Schema**: v1
'@ | Set-Content -LiteralPath (Join-Path $iterationPath 'drift-log.md') -Encoding UTF8

@'
# Review Diagrams

```text
ASCII only
```
'@ | Set-Content -LiteralPath (Join-Path $iterationPath 'review-diagrams.md') -Encoding UTF8

@'
{"boundary_events":[
  {"commit":"abc1234","boundary":"implement","response_text":"No durable handoff here."},
  {"commit":"def5678","boundary":"implement","response_text":"Context resumed without handoff.","compaction_marker":true}
]}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot '.specrew\handoff-evidence.json') -Encoding UTF8

@'
# Wrong Location Review
'@ | Set-Content -LiteralPath (Join-Path $projectRoot '.antigravitycli\brain\session-1\review.md') -Encoding UTF8

@'
=== SPECREW HANDOFF ===
STOPPED AT: review
STATUS: internal reference fixture
WHY STOPPED: Feature 016 should not be in handoff prose.
HUMAN ACTION NEEDED:
  - Review the fixture.
RESUME WITH: approve
=== END SPECREW HANDOFF ===
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'handoff-sample.md') -Encoding UTF8

@'
=== SPECREW HANDOFF ===
WHY STOPPED: Feature 016 is allowed here because proposals are excluded.
=== END SPECREW HANDOFF ===
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'proposals\999-internal.md') -Encoding UTF8

@"
function Get-SpecrewFeatureRecords {
    param([string]`$ProjectRoot)
    @(
        [pscustomobject]@{
            feature_ref = '017-sample'
            feature_status = 'active'
            has_feature_closeout = `$false
            closeout_dashboard_path = ''
            closed_iterations = @(
                [pscustomobject]@{
                    iteration_ref = '002'
                    iteration_directory = '$($iterationPath -replace '\\','\\')'
                },
                [pscustomobject]@{
                    iteration_ref = '003'
                    iteration_directory = '$((Join-Path $projectRoot 'external-history') -replace '\\','\\')'
                }
            )
        }
    )
}
function Read-SpecrewRoadmapDefinition { param([string]`$ProjectRoot) [pscustomobject]@{ exists = `$false; warnings = @() } }
function Get-SpecrewRoadmapProgress { param([object]`$RoadmapDefinition, [object[]]`$FeatureRecords) [pscustomobject]@{ warnings = @() } }
"@ | Set-Content -LiteralPath (Join-Path $projectRoot 'scripts\internal\dashboard-renderer.ps1') -Encoding UTF8
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot 'external-history') -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to initialize scratch git repository.`n$($gitInitOutput -join [Environment]::NewLine)"
    exit 1
}
@(& git -C $projectRoot add . 2>&1) | Out-Null
$gitCommitOutput = @(& git -C $projectRoot -c user.name=Codex -c user.email=codex@example.com commit -m 'baseline' --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to commit scratch baseline.`n$($gitCommitOutput -join [Environment]::NewLine)"
    exit 1
}

$validatorOutput = @(
    pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $projectRoot -IterationPath $iterationPath -NoParallel -NoCacheRead 2>&1
)
$validatorText = ($validatorOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    Write-Fail "validate-governance should keep F-047 findings WARN-only.`n$validatorText"
    exit 1
}

foreach ($check in @(
        @{ Pattern = 'WARN \[trust-hardening\] handoff-block-missing'; Message = 'Missing handoff block did not emit WARN.' },
        @{ Pattern = 'WARN \[trust-hardening\] post-compaction-handoff-drop'; Message = 'Post-compaction handoff drop did not emit WARN.' },
        @{ Pattern = 'WARN \[trust-hardening\] canonical-artifact-wrong-location'; Message = 'Wrong-location artifact did not emit WARN.' },
        @{ Pattern = 'WARN \[trust-hardening\] review-diagrams-missing-mermaid'; Message = 'Missing Mermaid block did not emit WARN.' },
        @{ Pattern = 'WARN \[trust-hardening\] internal-reference-in-handoff'; Message = 'Internal reference in handoff did not emit WARN.' },
        @{ Pattern = 'WARN \[dashboard\] missing-dashboard-auto-render-regression'; Message = 'Managed missing dashboard diagnosis was not specific.' },
        @{ Pattern = 'WARN \[dashboard\] missing-dashboard-non-specrew-managed'; Message = 'Non-managed missing dashboard diagnosis was not specific.' }
    )) {
    if (-not (Assert-Match -Text $validatorText -Pattern $check.Pattern -Message $check.Message)) {
        Write-Host $validatorText
        exit 1
    }
}

if (-not (Assert-NotMatch -Text $validatorText -Pattern 'proposals/999-internal\.md' -Message 'Internal-reference check scanned excluded proposal handoff prose.')) {
    Write-Host $validatorText
    exit 1
}

. $skillCatalogHelper
$skillProject = Join-Path $scratchRoot 'skill-project'
foreach ($hostKind in Get-SpecrewSupportedHostKinds) {
    $rootPath = Get-SpecrewHostSkillRoot -HostKind $hostKind -ProjectPath $skillProject
    $null = New-Item -ItemType Directory -Path $rootPath -Force
    'placeholder only' | Set-Content -LiteralPath (Join-Path $rootPath 'README.md') -Encoding UTF8
}
$skillState = Get-SpecrewSkillCatalogState -ProjectPath $skillProject
if (-not $skillState.HasMissingRoots) {
    Write-Fail 'Empty skill roots should be treated as missing roots.'
    exit 1
}
if (@($skillState.MissingRoots | Where-Object { $_.Exists -and $_.SkillFileCount -eq 0 }).Count -eq 0) {
    Write-Fail 'MissingRoots did not include present-but-empty skill roots.'
    exit 1
}

. $taskProgressHelper
$progressProject = Join-Path $scratchRoot 'progress-project'
$progressFeature = '047-complete'
$progressIteration = '001'
$progressFeaturePath = Join-Path $progressProject "specs\$progressFeature"
$progressIterationPath = Join-Path $progressFeaturePath "iterations\$progressIteration"
$null = New-Item -ItemType Directory -Path $progressIterationPath -Force
@'
# Tasks

- [x] T001 Finished first task. (Trace: FR-012)
- [x] T002 Finished second task. (Trace: FR-012)
'@ | Set-Content -LiteralPath (Join-Path $progressFeaturePath 'tasks.md') -Encoding UTF8
@'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 2/20 story_points
**Started**: 2026-05-26
**Completed**: 2026-05-26

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T001 | Finished first task | FR-012 | US7 | 1 | Implementer | done | codex | 1 | pass |
| T002 | Finished second task | FR-012 | US7 | 1 | Implementer | done | codex | 1 | pass |
'@ | Set-Content -LiteralPath (Join-Path $progressIterationPath 'plan.md') -Encoding UTF8
@'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T002
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: HEAD
**Updated**: 2026-05-26T00:00:00Z
'@ | Set-Content -LiteralPath (Join-Path $progressIterationPath 'state.md') -Encoding UTF8
$progressState = Sync-IterationTaskProgress -ProjectRoot $progressProject -FeatureRef $progressFeature -IterationNumber $progressIteration -ResolvedFeaturePath $progressFeaturePath
$progressText = Get-Content -LiteralPath $progressState.Path -Raw -Encoding UTF8
if (-not (Assert-Match -Text $progressText -Pattern 'T001:\s*\r?\n\s+title: "Finished first task"\s*\r?\n\s+status: "done"' -Message 'T001 did not regenerate as done from tasks.md.')) {
    Write-Host $progressText
    exit 1
}
if (-not (Assert-Match -Text $progressText -Pattern 'T002:\s*\r?\n\s+title: "Finished second task"\s*\r?\n\s+status: "done"' -Message 'T002 did not regenerate as done from tasks.md.')) {
    Write-Host $progressText
    exit 1
}

# Regression test for Codex PR #985 review finding: live non-pending statuses
# (in-progress / blocked / needs-rework / deferred) MUST NOT be silently downgraded
# to 'pending' when tasks.md derivation yields 'pending' for unchecked rows. Only
# tasks.md promotion to 'done' should override live state.
$preserveProject = Join-Path $scratchRoot 'preserve-live-state-project'
$preserveFeature = '047-preserve'
$preserveIteration = '001'
$preserveFeaturePath = Join-Path $preserveProject "specs\$preserveFeature"
$preserveIterationPath = Join-Path $preserveFeaturePath "iterations\$preserveIteration"
$null = New-Item -ItemType Directory -Path $preserveIterationPath -Force
@'
# Tasks

- [ ] T010 Still working on this. (Trace: FR-012)
- [ ] T011 Hit a blocker. (Trace: FR-012)
- [ ] T012 Needs rework after review. (Trace: FR-012)
- [ ] T013 Deferred to next iteration. (Trace: FR-012)
- [x] T014 Promoted to done in tasks.md. (Trace: FR-012)
'@ | Set-Content -LiteralPath (Join-Path $preserveFeaturePath 'tasks.md') -Encoding UTF8
@'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 5/20 story_points
**Started**: 2026-05-26

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T010 | Still working on this | FR-012 | US7 | 1 | Implementer | in-progress | codex | 1 | |
| T011 | Hit a blocker | FR-012 | US7 | 1 | Implementer | blocked | codex | 1 | |
| T012 | Needs rework after review | FR-012 | US7 | 1 | Implementer | needs-rework | codex | 1 | |
| T013 | Deferred to next iteration | FR-012 | US7 | 1 | Implementer | deferred | codex | 1 | |
| T014 | Promoted to done in tasks.md | FR-012 | US7 | 1 | Implementer | in-progress | codex | 1 | |
'@ | Set-Content -LiteralPath (Join-Path $preserveIterationPath 'plan.md') -Encoding UTF8
@'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: (none)
**Tasks Remaining**: T010, T011, T012, T013
**In Progress**: T010
**Baseline Ref**: HEAD
**Updated**: 2026-05-26T00:00:00Z
'@ | Set-Content -LiteralPath (Join-Path $preserveIterationPath 'state.md') -Encoding UTF8

# Seed the tasks-progress.yml with live non-pending statuses (simulates active work in progress).
$preserveProgressDir = Join-Path $preserveIterationPath ''
$preserveProgressPath = Join-Path $preserveIterationPath 'tasks-progress.yml'
@'
schema: "v1"
feature: "047-preserve"
iteration: "001"
updated_at: "2026-05-26T00:00:00Z"
tasks:
  T010:
    title: "Still working on this"
    status: "in-progress"
    started_at: "2026-05-26T08:00:00Z"
    completed_at: ""
    blocked_reason: ""
  T011:
    title: "Hit a blocker"
    status: "blocked"
    started_at: "2026-05-26T08:00:00Z"
    completed_at: ""
    blocked_reason: "External dependency unavailable"
  T012:
    title: "Needs rework after review"
    status: "needs-rework"
    started_at: "2026-05-26T08:00:00Z"
    completed_at: ""
    blocked_reason: ""
  T013:
    title: "Deferred to next iteration"
    status: "deferred"
    started_at: ""
    completed_at: ""
    blocked_reason: ""
  T014:
    title: "Promoted to done in tasks.md"
    status: "in-progress"
    started_at: "2026-05-26T08:00:00Z"
    completed_at: ""
    blocked_reason: ""
'@ | Set-Content -LiteralPath $preserveProgressPath -Encoding UTF8

$preserveResult = Sync-IterationTaskProgress -ProjectRoot $preserveProject -FeatureRef $preserveFeature -IterationNumber $preserveIteration -ResolvedFeaturePath $preserveFeaturePath
$preserveText = Get-Content -LiteralPath $preserveResult.Path -Raw -Encoding UTF8

foreach ($preserveCase in @(
    @{ TaskId = 'T010'; ExpectedStatus = 'in-progress'; Reason = "in-progress live state must survive tasks.md '[ ]' derivation" },
    @{ TaskId = 'T011'; ExpectedStatus = 'blocked';     Reason = "blocked live state must survive tasks.md '[ ]' derivation" },
    @{ TaskId = 'T012'; ExpectedStatus = 'needs-rework'; Reason = "needs-rework live state must survive tasks.md '[ ]' derivation" },
    @{ TaskId = 'T013'; ExpectedStatus = 'deferred';    Reason = "deferred live state must survive tasks.md '[ ]' derivation" }
)) {
    $pattern = ('{0}:\s*\r?\n\s+title:.*\r?\n\s+status: "{1}"' -f $preserveCase.TaskId, $preserveCase.ExpectedStatus)
    if (-not (Assert-Match -Text $preserveText -Pattern $pattern -Message ("Live state regression: {0}" -f $preserveCase.Reason))) {
        Write-Host $preserveText
        exit 1
    }
}

# T014: tasks.md marks it [x] → derived promotes 'in-progress' → 'done'. Promotion wins.
if (-not (Assert-Match -Text $preserveText -Pattern 'T014:\s*\r?\n\s+title:.*\r?\n\s+status: "done"' -Message "tasks.md '[x]' must promote in-progress → done.")) {
    Write-Host $preserveText
    exit 1
}

$startScriptText = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-start.ps1') -Raw -Encoding UTF8
foreach ($phrase in @('push the branch', 'open a PR', 'address automated PR review', 'merge after approval')) {
    if (-not (Assert-Match -Text $startScriptText -Pattern ([regex]::Escape($phrase)) -Message "Feature-closeout handoff template is missing '$phrase'.")) {
        exit 1
    }
}

$reviewerCharterText = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\agents\reviewer\charter.md') -Raw -Encoding UTF8
if (-not (Assert-Match -Text $reviewerCharterText -Pattern 'Mermaid fences' -Message 'Reviewer charter template does not direct Mermaid diagrams.')) {
    exit 1
}
if (-not (Assert-Match -Text $reviewerCharterText -Pattern 'ASCII trees' -Message 'Reviewer charter template does not prohibit ASCII-tree substitution.')) {
    exit 1
}

Write-Pass 'F-047 trust-hardening fixtures cover WARN-only handoff, dashboard, wrong-location, mermaid, skill-root, closeout-template, and task-progress reconciliation paths'
exit 0
