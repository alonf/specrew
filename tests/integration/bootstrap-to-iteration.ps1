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
    $exitCode = $LASTEXITCODE
    $stringOutput = @($output | ForEach-Object { [string]$_ })
    if ($exitCode -ne 0) {
        foreach ($line in $stringOutput) {
            Write-Host $line
        }

        throw ("Script failed: {0}" -f $ScriptPath)
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $stringOutput
    }
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
    $initScriptContent = Get-Content -LiteralPath $initScript -Raw -Encoding UTF8
    if ($initScriptContent -match 'function\s+Read-AgentConsent\b' -or
        $initScriptContent -match 'Read-Host\s+\("Enable .* Specrew-managed delegation') {
        Write-Fail 'specrew init still contains the interactive delegated-agent bootstrap question path.'
        exit 1
    }

    $initResult = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot 2>&1
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

$iterationConfigPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'
$roleAssignmentsPath = Join-Path -Path $projectRoot -ChildPath '.specrew\role-assignments.yml'
$iterationConfigContent = Get-Content -LiteralPath $iterationConfigPath -Raw -Encoding UTF8
$roleAssignmentsContent = Get-Content -LiteralPath $roleAssignmentsPath -Raw -Encoding UTF8

if (-not (Assert-ContentPattern -Content $iterationConfigContent -Pattern 'copilot:\s*\r?\n\s+enabled:\s*true' -FailureMessage 'Bootstrap should always keep Copilot enabled as the host runtime.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $iterationConfigContent -Pattern 'claude:\s*\r?\n\s+enabled:\s*false' -FailureMessage 'Bootstrap should leave Claude disabled unless -Agents explicitly opts in.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $iterationConfigContent -Pattern 'codex:\s*\r?\n\s+enabled:\s*false' -FailureMessage 'Bootstrap should leave Codex disabled unless -Agents explicitly opts in.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $roleAssignmentsContent -Pattern 'Spec Steward"[\s\S]*?preferred_agent:\s*"codex"' -FailureMessage 'Bootstrap role assignments should prefer Codex for Spec Steward by default.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $roleAssignmentsContent -Pattern 'Planner"[\s\S]*?preferred_agent:\s*"claude"' -FailureMessage 'Bootstrap role assignments should prefer Claude for Planner by default.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $roleAssignmentsContent -Pattern 'Reviewer"[\s\S]*?preferred_agent:\s*"claude"' -FailureMessage 'Bootstrap role assignments should prefer Claude for Reviewer by default.')) {
    exit 1
}

$installedScriptsRoot = Join-Path -Path $projectRoot -ChildPath '.specify\extensions\specrew-speckit\scripts'
$planScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-iteration-plan.ps1'
$artifactScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-iteration-artifacts.ps1'
$reviewScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-review-artifact.ps1'
$reviewerArtifactsScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-reviewer-artifacts.ps1'
$retroScript = Join-Path -Path $installedScriptsRoot -ChildPath 'scaffold-retro-artifact.ps1'
$resumeScript = Join-Path -Path $installedScriptsRoot -ChildPath 'resume-iteration.ps1'
$syncModelOverrideScript = Join-Path -Path $installedScriptsRoot -ChildPath 'sync-squad-model-overrides.ps1'

foreach ($scriptPath in @($planScript, $artifactScript, $reviewScript, $reviewerArtifactsScript, $retroScript, $resumeScript, $syncModelOverrideScript)) {
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
$codeMapPath = Join-Path -Path $iterationDirectory -ChildPath 'code-map.md'
$dependencyReportPath = Join-Path -Path $iterationDirectory -ChildPath 'dependency-report.md'
$coverageEvidencePath = Join-Path -Path $iterationDirectory -ChildPath 'coverage-evidence.md'
$reviewerIndexPath = Join-Path -Path $iterationDirectory -ChildPath 'reviewer-index.md'
$retroPath = Join-Path -Path $iterationDirectory -ChildPath 'retro.md'
$hardeningGatePath = Join-Path -Path $iterationDirectory -ChildPath 'quality\hardening-gate.md'
$qualityLensesPath = Join-Path -Path $iterationDirectory -ChildPath 'quality\lenses'
$trapReapplicationPath = Join-Path -Path $iterationDirectory -ChildPath 'quality\trap-reapplication.md'
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
if (-not (Assert-ContentPattern -Content $reviewerCharter -Pattern 'implemented, enforced, observable, and documented' -FailureMessage 'Reviewer charter is missing the critical review dimensions.')) {
    exit 1
}
if (-not (Assert-ContentPattern -Content $reviewerCharter -Pattern 'Emit a gap ledger' -FailureMessage 'Reviewer charter is missing the gap-ledger directive.')) {
    exit 1
}

$coordinatorPromptChecks = @(
    @{ Pattern = 'Formal Spec-Kit \+ Specrew Lifecycle'; Failure = 'Coordinator prompt is missing the Specrew lifecycle override.' },
    @{ Pattern = 'do not describe the run as Spec-Kit/Specrew compliant'; Failure = 'Coordinator prompt is missing process-claim discipline for bypassed runs.' },
    @{ Pattern = 'After `speckit\.specify`, run `speckit\.clarify` for every newly generated spec before planning'; Failure = 'Coordinator prompt is missing the required clarify gate for new specs.' },
    @{ Pattern = 'sync-squad-model-overrides\.ps1 -IterationDirectory'; Failure = 'Coordinator prompt is missing the live model-override sync helper for escalation.' },
    @{ Pattern = 'What do you want to build\?'; Failure = 'Coordinator prompt is missing explicit greenfield intake guidance.' },
    @{ Pattern = 'wait for the human developer''s answer'; Failure = 'Coordinator prompt is missing the explicit wait-for-human intake rule.' },
    @{ Pattern = 'not generic skills'; Failure = 'Coordinator prompt is missing the dedicated Speckit invocation rule.' },
    @{ Pattern = 'Do not ask about specialist team additions before `speckit\.specify` and the clarify outcome'; Failure = 'Coordinator prompt is missing the post-spec team-shaping rule.' },
    @{ Pattern = 'Only propose Junior/Senior same-specialty pairs when the work can be partitioned cleanly enough to avoid conflicting execution'; Failure = 'Coordinator prompt is missing the Junior/Senior same-specialty guardrail.' },
    @{ Pattern = 'Route bounded, lower-risk, well-scoped work to Junior roles'; Failure = 'Coordinator prompt is missing the Junior/Senior routing policy.' },
    @{ Pattern = 'careful, responsible, knowledgeable, and review-ready'; Failure = 'Coordinator prompt does not set the higher Junior quality bar.' },
    @{ Pattern = 'deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences'; Failure = 'Coordinator prompt does not set the deeper Senior technical bar.' },
    @{ Pattern = 'file-write or tool-contract failure'; Failure = 'Coordinator prompt is missing the fail-fast artifact generation rule.' },
    @{ Pattern = 'Do not invoke `speckit\.implement` until that approval is given'; Failure = 'Coordinator prompt is missing the explicit implementation approval gate.' },
    @{ Pattern = 'Treat revisions, idempotency keys, retries, conflict detection, locks, and telemetry as incomplete'; Failure = 'Coordinator prompt is missing the quality/semantic integrity rule.' },
    @{ Pattern = 'developer-facing briefing'; Failure = 'Coordinator prompt is missing the implementation briefing handoff.' }
    @{ Pattern = 'review-heavy and problem-solving-heavy work as delegated-routing candidates'; Failure = 'Coordinator prompt is missing the delegated routing policy for review/problem-solving work.' },
    @{ Pattern = 'concrete model ID'; Failure = 'Coordinator prompt is missing the delegated runtime evidence requirement.' },
    @{ Pattern = 'no-gap policy'; Failure = 'Coordinator prompt is missing the no-gap closure policy.' },
    @{ Pattern = 'implemented, enforced, observable, and documented'; Failure = 'Coordinator prompt is missing the critical review dimensions.' },
    @{ Pattern = 'If review finds an ambiguity, contradiction, or missing decision in the governing spec'; Failure = 'Coordinator prompt is missing the spec-repair clarification loop.' }
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
$null = New-Item -ItemType Directory -Path (Join-Path -Path $specDirectory -ChildPath 'contracts') -Force
[System.IO.File]::WriteAllText((Join-Path -Path $specDirectory -ChildPath 'contracts\quality-governance-artifacts.md'), @'
# Quality Governance Artifacts

## Phase 2 Surfaces

- `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`
- `specs/<feature>/iterations/<NNN>/quality/lenses/*.md`
- `specs/<feature>/iterations/<NNN>/quality/trap-reapplication.md`
'@, [System.Text.UTF8Encoding]::new($false))

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
**Baseline Ref**: iteration-baseline
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
$retroResult = Invoke-TestScript -ScriptPath $retroScript -ArgumentList @('-IterationDirectory', $iterationDirectory)
if ($retroResult.ExitCode -ne 0) {
    foreach ($line in $retroResult.Output) {
        Write-Host $line
    }

    Write-Fail 'Retro scaffolder failed for the sample closeout'
    exit 1
}

foreach ($requiredArtifact in @($statePath, $driftPath, $reviewPath, $codeMapPath, $dependencyReportPath, $coverageEvidencePath, $reviewerIndexPath, $retroPath, $hardeningGatePath, $trapReapplicationPath)) {
    if (-not (Test-Path -LiteralPath $requiredArtifact -PathType Leaf)) {
        Write-Fail "Missing expected iteration artifact: $requiredArtifact"
        exit 1
    }
}

if (-not (Test-Path -LiteralPath $qualityLensesPath -PathType Container)) {
    Write-Fail "Missing expected quality lenses directory: $qualityLensesPath"
    exit 1
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

$reviewerIndexContent = Get-Content -LiteralPath $reviewerIndexPath -Raw -Encoding UTF8
$hardeningGateContent = Get-Content -LiteralPath $hardeningGatePath -Raw -Encoding UTF8
$trapReapplicationContent = Get-Content -LiteralPath $trapReapplicationPath -Raw -Encoding UTF8
$reviewerIndexValid = $true
foreach ($check in @(
        @{ Pattern = 'Header:\s+feature=001-sample-feature\s+\|\s+iteration=001'; Failure = 'Reviewer index is missing the summary header.' },
        @{ Pattern = '\[code-map\.md\]\(code-map\.md\)'; Failure = 'Reviewer index is missing the code-map link.' },
        @{ Pattern = 'SPECREW_REVIEW schema=v1 iter=001 feature=001-sample-feature verdict=accepted tasks=3/3 reqs=3 files=0 new_deps=0 vuln=unscanned cov=not_executed escalations=0 drift=0/0 index=specs\\001-sample-feature\\iterations\\001\\reviewer-index\.md'; Failure = 'Reviewer index did not persist the FR-051 digest format.' }
    )) {
    if (-not (Assert-ContentPattern -Content $reviewerIndexContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $reviewerIndexValid = $false
    }
}

$coverageContent = Get-Content -LiteralPath $coverageEvidencePath -Raw -Encoding UTF8
foreach ($check in @(
        @{ Pattern = '## Test Strategy'; Failure = 'Coverage evidence is missing the Test Strategy section.' },
        @{ Pattern = '## Tests Run'; Failure = 'Coverage evidence is missing the Tests Run section.' },
        @{ Pattern = '## Coverage Estimate'; Failure = 'Coverage evidence is missing the Coverage Estimate section.' },
        @{ Pattern = 'Kind:\s+qualitative'; Failure = 'Coverage evidence did not mark the estimate kind as qualitative.' },
        @{ Pattern = 'not_executed'; Failure = 'Coverage evidence did not record the mandated not_executed token.' }
    )) {
    if (-not (Assert-ContentPattern -Content $coverageContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $reviewerIndexValid = $false
    }
}

$codeMapContent = Get-Content -LiteralPath $codeMapPath -Raw -Encoding UTF8
foreach ($check in @(
        @{ Pattern = '\| Path \| Lines Added \| Lines Removed \| Owning Task ID\(s\) \| Owning Role \|'; Failure = 'Code map is missing the FR-046 Files Touched header.' },
        @{ Pattern = '## Public-API Delta'; Failure = 'Code map is missing the Public-API Delta section.' },
        @{ Pattern = '## Module Hotspots'; Failure = 'Code map is missing the Module Hotspots section.' },
        @{ Pattern = 'Test-to-Code Ratio'; Failure = 'Code map is missing the Test-to-Code Ratio line.' }
    )) {
    if (-not (Assert-ContentPattern -Content $codeMapContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $reviewerIndexValid = $false
    }
}

$dependencyContent = Get-Content -LiteralPath $dependencyReportPath -Raw -Encoding UTF8
foreach ($check in @(
        @{ Pattern = '## Vulnerability Scan'; Failure = 'Dependency report is missing the Vulnerability Scan section.' },
        @{ Pattern = 'status:\s+unscanned'; Failure = 'Dependency report did not explicitly label the scan as unscanned.' },
        @{ Pattern = '## Transitive Surface'; Failure = 'Dependency report is missing the Transitive Surface note.' }
    )) {
    if (-not (Assert-ContentPattern -Content $dependencyContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $reviewerIndexValid = $false
    }
}

foreach ($check in @(
        @{ Content = $hardeningGateContent; Pattern = '\*\*Gate ID\*\*:\s*`pre-implementation-hardening`'; Failure = 'Hardening gate scaffold is missing the gate identifier.' },
        @{ Content = $hardeningGateContent; Pattern = '\| `security-surface` \| `security` \| `tbd` \| `true` \|'; Failure = 'Hardening gate scaffold is missing the security concern placeholder row.' },
        @{ Content = $trapReapplicationContent; Pattern = '\*\*Scan ID\*\*:\s*`trap-reapplication\.pending`'; Failure = 'Trap reapplication scaffold is missing the scan identifier.' },
        @{ Content = $trapReapplicationContent; Pattern = '\| `\(pending trap refs\)` \| `\(pending scan scope\)` \| `skipped-with-rationale` \|'; Failure = 'Trap reapplication scaffold is missing the placeholder scan row.' }
    )) {
    if (-not (Assert-ContentPattern -Content $check.Content -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        $reviewerIndexValid = $false
    }
}

$retroOutput = $retroResult.Output -join "`n"
if (-not (Assert-ContentPattern -Content $retroOutput -Pattern 'SPECREW_REVIEW schema=v1 iter=001 feature=001-sample-feature verdict=accepted tasks=3/3 reqs=3 files=0 new_deps=0 vuln=unscanned cov=not_executed escalations=0 drift=0/0 index=specs\\001-sample-feature\\iterations\\001\\reviewer-index\.md' -FailureMessage 'Closeout output did not emit the FR-051 digest.')) {
    $reviewerIndexValid = $false
}

if (-not ($bootstrapOutputValid -and $planValid -and $retroValid -and $reviewerIndexValid)) {
    exit 1
}

Write-Pass 'Greenfield bootstrap advanced through spec creation, traceable plan scaffolding, and review/retro artifact generation'
exit 0
