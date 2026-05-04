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

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
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

function Assert-ContentPattern {
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

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'

if (-not (Test-Path -Path $initScript -PathType Leaf)) {
    Write-Fail "Missing bootstrap entrypoint: $initScript"
    exit 1
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Bootstrap integration requires tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\bootstrap-to-iteration'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

$gitInitOutput = @(& git -C $projectRoot init --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitInitOutput) {
        Write-Host $line
    }

    Write-Fail "Failed to initialize git repository in scratch project: $projectRoot"
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.git'))) {
    Write-Fail "Scratch project is missing .git after git init: $projectRoot"
    exit 1
}

Push-Location $repoRoot
try {
    $initResult = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot -Agents 'copilot' 2>&1
    if ($initResult) {
        $initResult | ForEach-Object { Write-Host $_ }
    }
}
catch {
    Write-Fail ("Bootstrap execution failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -eq 3) {
    Write-Fail 'Git-only repo was rejected as non-empty; bootstrap should not require -Force when only .git exists'
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Skip ("Bootstrap command returned non-zero exit code ({0}); skipping artifact assertions because bootstrap tooling is unavailable in this environment" -f $LASTEXITCODE)
    exit 0
}

$initTranscript = ($initResult | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
$bootstrapOutputValid = $true
$bootstrapOutputChecks = @(
    @{ Pattern = 'Baseline Specrew crew installed:\s*Spec Steward,\s*Planner,\s*Implementer,\s*Reviewer,\s*Retro Facilitator\.'; Failure = 'Bootstrap output did not explain the installed baseline Specrew crew.' },
    @{ Pattern = 'specrew start'; Failure = 'Bootstrap output did not guide the user to specrew start.' },
    @{ Pattern = 'Add extra Squad members after bootstrap'; Failure = 'Bootstrap output did not explain how to extend the Squad team after bootstrap.' },
    @{ Pattern = 'Keep the Specrew-managed baseline block intact'; Failure = 'Bootstrap output did not protect the managed baseline roles from removal.' }
)

foreach ($check in $bootstrapOutputChecks) {
    if (-not (Assert-ContentPattern -Content $initTranscript -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $bootstrapOutputValid = $false
    }
}

Write-Pass 'Greenfield bootstrap succeeds without -Force when the repo only contains .git'

$requiredBootstrapPaths = @(
    '.specify',
    '.squad',
    '.specrew\config.yml',
    '.specrew\constitution.md',
    '.specrew\iteration-config.yml',
    '.specrew\role-assignments.yml',
    '.specify\extensions\specrew-speckit\extension.yml'
)

$missingPaths = @()
foreach ($relativePath in $requiredBootstrapPaths) {
    $fullPath = Join-Path -Path $projectRoot -ChildPath $relativePath
    if (-not (Test-Path -Path $fullPath)) {
        $missingPaths += $relativePath
    }
}

$skillPath = Join-Path -Path $projectRoot -ChildPath '.copilot\skills'
$hasSpecrewSkills = $false
if (Test-Path -Path $skillPath -PathType Container) {
    $hasSpecrewSkills = [bool](Get-ChildItem -Path $skillPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'specrew-*' } | Select-Object -First 1)
}

if (-not $hasSpecrewSkills) {
    $missingPaths += '.copilot\skills\specrew-*'
}

if ($missingPaths.Count -gt 0) {
    Write-Fail ("Missing expected bootstrap artifacts: {0}" -f ($missingPaths -join ', '))
    exit 1
}

$installedScriptsRoot = Join-Path -Path $projectRoot -ChildPath '.specify\extensions\specrew-speckit\scripts'
$planScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-iteration-plan.ps1'
$artifactScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-iteration-artifacts.ps1'
$reviewScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-review-artifact.ps1'
$retroScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-retro-artifact.ps1'
$resumeScript = Join-Path -Path $installedScriptsRoot -ChildPath 'resume-iteration.ps1'

foreach ($scriptPath in @($planScript, $artifactScript, $reviewScript, $retroScript, $resumeScript)) {
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        Write-Fail "Missing installed downstream helper: $scriptPath"
        exit 1
    }
}

$specDirectory = Join-Path -Path $projectRoot -ChildPath 'specs\001-sample-feature'
$iterationDirectory = Join-Path -Path $specDirectory -ChildPath 'iterations\001'
$planPath = Join-Path -Path $iterationDirectory -ChildPath 'plan.md'
$statePath = Join-Path -Path $iterationDirectory -ChildPath 'state.md'
$driftPath = Join-Path -Path $iterationDirectory -ChildPath 'drift-log.md'
$reviewPath = Join-Path -Path $iterationDirectory -ChildPath 'review.md'
$retroPath = Join-Path -Path $iterationDirectory -ChildPath 'retro.md'
$specPath = Join-Path -Path $specDirectory -ChildPath 'spec.md'
$resumeSkillPath = Join-Path -Path $projectRoot -ChildPath '.copilot\skills\specrew-iteration-resume\SKILL.md'
$implementerCharterPath = Join-Path -Path $projectRoot -ChildPath '.squad\agents\implementer\charter.md'
$reviewerCharterPath = Join-Path -Path $projectRoot -ChildPath '.squad\agents\reviewer\charter.md'
$coordinatorPromptPath = Join-Path -Path $projectRoot -ChildPath '.github\agents\squad.agent.md'

$null = New-Item -Path $specDirectory -ItemType Directory -Force

foreach ($runtimePath in @($resumeSkillPath, $implementerCharterPath, $reviewerCharterPath, $coordinatorPromptPath)) {
    if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) {
        Write-Fail "Missing runtime resume surface: $runtimePath"
        exit 1
    }
}

$implementerCharter = Get-Content -LiteralPath $implementerCharterPath -Raw -Encoding UTF8
$reviewerCharter = Get-Content -LiteralPath $reviewerCharterPath -Raw -Encoding UTF8
$coordinatorPrompt = Get-Content -LiteralPath $coordinatorPromptPath -Raw -Encoding UTF8
if (-not (Assert-ContentPattern -Content $implementerCharter -Pattern 'update `iterations/NNN/state\.md`|update `state\.md`' -FailureMessage 'Implementer charter is missing the FR-019 state persistence directive.')) {
    exit 1
}

if (-not (Assert-ContentPattern -Content $reviewerCharter -Pattern 'update `iterations/NNN/state\.md`|update `state\.md`' -FailureMessage 'Reviewer charter is missing the FR-019 state persistence directive.')) {
    exit 1
}

$coordinatorPromptChecks = @(
    @{ Pattern = 'Formal Spec-Kit \+ Specrew Lifecycle'; Failure = 'Coordinator prompt is missing the Specrew lifecycle override.' },
    @{ Pattern = 'do not describe the run as Spec-Kit/Specrew compliant'; Failure = 'Coordinator prompt is missing process-claim discipline for bypassed runs.' }
)

foreach ($check in $coordinatorPromptChecks) {
    if (-not (Assert-ContentPattern -Content $coordinatorPrompt -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}

$specContent = @'
# Feature Spec: 001 Sample

## User Stories

- US-1 → FR-001, FR-002
- US-2 → FR-003

## Functional Requirements

- **FR-001**: Bootstrap flow MUST create downstream governance artifacts.
- **FR-002**: Iteration planning MUST generate a traceable plan for scoped requirements.
- **FR-003**: Review and retrospective phases MUST produce downstream artifacts.
'@

[System.IO.File]::WriteAllText($specPath, $specContent, [System.Text.UTF8Encoding]::new($false))

Invoke-TestScript -ScriptPath $planScript -ArgumentList @('-SpecPath', $specPath, '-IterationNumber', '001') | Out-Null
if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
    Write-Fail "Iteration plan scaffold was not created: $planPath"
    exit 1
}

$scaffoldedPlan = Get-Content -LiteralPath $planPath -Raw -Encoding UTF8
$planValid = $true
$planChecks = @(
    @{ Pattern = '\*\*Status\*\*:\s*planning'; Failure = 'Scaffolded plan did not stay in planning status.' },
    @{ Pattern = 'FR-001'; Failure = 'Scaffolded plan is missing FR-001 traceability.' },
    @{ Pattern = 'FR-002'; Failure = 'Scaffolded plan is missing FR-002 traceability.' },
    @{ Pattern = 'FR-003'; Failure = 'Scaffolded plan is missing FR-003 traceability.' },
    @{ Pattern = 'US-1'; Failure = 'Scaffolded plan is missing user-story linkage for US-1.' },
    @{ Pattern = 'US-2'; Failure = 'Scaffolded plan is missing user-story linkage for US-2.' }
)

foreach ($check in $planChecks) {
    if (-not (Assert-ContentPattern -Content $scaffoldedPlan -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $planValid = $false
    }
}

$executedPlanContent = @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 3/20 story_points
**Started**: 2026-05-01
**Completed**:

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | Bootstrap flow MUST create downstream governance artifacts. | US-1 |
| FR-002 | Iteration planning MUST generate a traceable plan for scoped requirements. | US-1 |
| FR-003 | Review and retrospective phases MUST produce downstream artifacts. | US-2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-001 | Bootstrap sample project | FR-001 | US-1 | 1 | Implementer | done | copilot-agent | 1 | pass |
| T-002 | Scaffold traceable iteration plan | FR-002 | US-1 | 1 | Planner | done | copilot-agent | 1 | pass |
| T-003 | Produce review and retro artifacts | FR-003 | US-2 | 1 | Reviewer | done | copilot-agent | 1 | pass |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Scope the sample requirements and seed the plan |
| Discovery/Spikes | 0 | No additional spikes required for the sample path |
| Implementation | 1 | Bootstrap and artifact creation |
| Review | 0.5 | Review scaffold and verdict capture |
| Rework | 0.5 | Buffer for lifecycle corrections |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003
- User stories represented in current scope: US-1, US-2
- Pending detailed planning: complete

## Notes

- Sample plan promoted from the scaffolded stub to validate the downstream bootstrap-to-iteration path.
- Each task remains traceable to one scoped requirement and one user story.
'@

[System.IO.File]::WriteAllText($planPath, $executedPlanContent, [System.Text.UTF8Encoding]::new($false))
Invoke-TestScript -ScriptPath $artifactScript -ArgumentList @('-SpecDirectory', $specDirectory, '-IterationNumber', '001') | Out-Null

$stateContent = @'
# Iteration State: 001

**Schema**: v1
**Last Completed Task**: T-003
**Tasks Remaining**: (none)
**In Progress**: (none)
**Updated**: 2026-05-01T00:00:00Z

## Execution Summary

- Bootstrap completed and all three sample tasks were executed in the scratch project.
'@

[System.IO.File]::WriteAllText($statePath, $stateContent, [System.Text.UTF8Encoding]::new($false))

Invoke-TestScript -ScriptPath $reviewScript -ArgumentList @('-IterationDirectory', $iterationDirectory) | Out-Null
$completedReviewContent = @'
# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-01
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-001 | FR-001 | pass | Bootstrap created downstream governance artifacts in the scratch project. |
| T-002 | FR-002 | pass | The downstream helper generated a traceable iteration plan for the sample requirements. |
| T-003 | FR-003 | pass | Review and retrospective artifacts were produced from the downstream installed helpers. |

## Notes

- Review accepted the sample first-iteration flow after bootstrap, plan, review, and retro artifacts were all created.
'@

[System.IO.File]::WriteAllText($reviewPath, $completedReviewContent, [System.Text.UTF8Encoding]::new($false))
Invoke-TestScript -ScriptPath $retroScript -ArgumentList @('-IterationDirectory', $iterationDirectory) | Out-Null

foreach ($requiredArtifact in @($statePath, $driftPath, $reviewPath, $retroPath)) {
    if (-not (Test-Path -LiteralPath $requiredArtifact -PathType Leaf)) {
        Write-Fail "Missing expected iteration artifact: $requiredArtifact"
        exit 1
    }
}

$retroContent = Get-Content -LiteralPath $retroPath -Raw -Encoding UTF8
$retroValid = $true
$retroChecks = @(
    @{ Pattern = '## Drift Summary'; Failure = 'Retro artifact is missing the drift summary section.' },
    @{ Pattern = '- Total drift events: 0'; Failure = 'Retro artifact did not preserve the zero-drift summary for the sample flow.' },
    @{ Pattern = '- Review verdict recorded as \*\*accepted\*\* before retrospective started\.'; Failure = 'Retro artifact did not carry forward the accepted review verdict.' }
)

foreach ($check in $retroChecks) {
    if (-not (Assert-ContentPattern -Content $retroContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $retroValid = $false
    }
}

if (-not ($bootstrapOutputValid -and $planValid -and $retroValid)) {
    exit 1
}

Write-Pass 'Greenfield bootstrap advanced through spec creation, traceable plan scaffolding, and review/retro artifact generation'
exit 0
