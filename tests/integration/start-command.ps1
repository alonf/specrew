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
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
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
$entryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew.ps1'
$startScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-start.ps1'
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'

foreach ($requiredScript in @($entryScript, $startScript, $initScript)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        Write-Fail "Missing required script: $requiredScript"
        exit 1
    }
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Start command tests require tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\start-command'
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

Write-Host "Initializing Specrew project..."
$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')
if ($initResult.ExitCode -ne 0) {
    Write-Host "Bootstrap output:"
    foreach ($line in $initResult.Output) {
        Write-Host $line
    }
    Write-Fail "Bootstrap failed"
    exit 1
}

Write-Pass "Bootstrap completed successfully"

Write-Host "`nTest 1: start command help advertises the new flow"
$helpResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('start', '--help')
if ($helpResult.ExitCode -ne 0) {
    Write-Fail "specrew start --help failed"
    exit 1
}

$helpOutput = $helpResult.Output -join "`n"
if (-not (Assert-Contains -Content $helpOutput -Pattern 'specrew start' -FailureMessage 'Help output does not describe the start command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'prompt-approvals' -FailureMessage 'Help output does not describe the prompt-approvals option.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'new-window' -FailureMessage 'Help output does not describe the new-window option.')) {
    exit 1
}
if (-not (Assert-Contains -Content $helpOutput -Pattern 'same-window' -FailureMessage 'Help output does not describe the same-window option.')) {
    exit 1
}
Write-Pass "Help output includes specrew start"

Write-Host "`nTest 2: start command enters intake-or-resume mode on a fresh repo"
$freshStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($freshStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start should succeed on a fresh repo without a feature request"
    foreach ($line in $freshStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$freshPromptPath = Join-Path -Path $projectRoot -ChildPath '.specrew\last-start-prompt.md'
$freshContextPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-context.json'
if (-not (Test-Path -LiteralPath $freshPromptPath -PathType Leaf)) {
    Write-Fail "Fresh repo start did not create a prompt artifact"
    exit 1
}
if (-not (Test-Path -LiteralPath $freshContextPath -PathType Leaf)) {
    Write-Fail "Fresh repo start did not create a context artifact"
    exit 1
}

$freshPromptContent = Get-Content -LiteralPath $freshPromptPath -Raw -Encoding UTF8
$freshContext = Get-Content -LiteralPath $freshContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$freshOutput = $freshStartResult.Output -join "`n"
$freshStartChecks = @(
    @{ Pattern = 'Mode: intake-or-resume'; Failure = 'Fresh repo prompt did not enter intake-or-resume mode.' },
    @{ Pattern = 'Finalize the team first'; Failure = 'Fresh repo prompt did not tell Squad to finalize the team first.' },
    @{ Pattern = 'Classify the repository using the project-state snapshot above'; Failure = 'Fresh repo prompt did not tell Squad to classify the repository before asking for spec details.' },
    @{ Pattern = 'ask for the next feature/fix spec request only after team finalization and state classification are complete'; Failure = 'Fresh repo prompt did not tell Squad to gather missing feature direction after the required sequencing.' },
    @{ Pattern = 'only ask about team additions when the work clearly needs specialists'; Failure = 'Fresh repo prompt did not tell Squad when to ask about extra specialists.' },
    @{ Pattern = 'After speckit\.specify, explicitly decide whether to run speckit\.clarify before speckit\.plan'; Failure = 'Fresh repo prompt did not require an explicit clarify decision before planning.' }
)

foreach ($check in $freshStartChecks) {
    if (-not (Assert-Contains -Content $freshPromptContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}
if ($freshContext.approval_mode -ne 'allow-all') {
    Write-Fail "Fresh repo start did not default to allow-all approval mode."
    exit 1
}
if ($freshContext.launch_mode -ne 'none') {
    Write-Fail "Fresh repo no-launch flow did not record the expected launch mode."
    exit 1
}
if ($freshContext.project_state.state -ne 'greenfield-new') {
    Write-Fail "Fresh repo start did not classify the project as greenfield-new."
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern 'Manual launch command' -FailureMessage 'Fresh repo no-launch flow did not print an exact manual launch command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern "copilot --agent 'Squad' --autopilot" -FailureMessage 'Fresh repo no-launch flow did not show the Copilot + Squad handoff command.')) {
    exit 1
}
if (-not (Assert-Contains -Content $freshOutput -Pattern '--allow-all' -FailureMessage 'Fresh repo no-launch flow did not preserve allow-all in the manual handoff command.')) {
    exit 1
}
Write-Pass "Fresh repo start enters intake-or-resume mode"

Write-Host "`nTest 3: start command writes prompt artifacts for a new feature"
$request = 'Build a sample reporting dashboard with export support'
$startResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    $request,
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($startResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for new feature request"
    foreach ($line in $startResult.Output) {
        Write-Host $line
    }
    exit 1
}

$promptPath = Join-Path -Path $projectRoot -ChildPath '.specrew\last-start-prompt.md'
$contextPath = Join-Path -Path $projectRoot -ChildPath '.specrew\start-context.json'
foreach ($artifactPath in @($promptPath, $contextPath)) {
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        Write-Fail "Start command did not create expected artifact: $artifactPath"
        exit 1
    }
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
$startContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$promptChecks = @(
    @{ Pattern = 'speckit\.specify'; Failure = 'Prompt is missing specify lifecycle step.' },
    @{ Pattern = 'speckit\.clarify'; Failure = 'Prompt is missing clarify lifecycle step.' },
    @{ Pattern = 'speckit\.plan'; Failure = 'Prompt is missing plan lifecycle step.' },
    @{ Pattern = 'speckit\.tasks'; Failure = 'Prompt is missing tasks lifecycle step.' },
    @{ Pattern = 'speckit\.implement'; Failure = 'Prompt is missing implement lifecycle step.' },
    @{ Pattern = 'explicitly decide whether to run speckit\.clarify before speckit\.plan'; Failure = 'Prompt does not require an explicit clarify decision before planning.' },
    @{ Pattern = 'default to speckit\.clarify'; Failure = 'Prompt does not default new feature work to speckit.clarify.' },
    @{ Pattern = 'record a concrete dated skip rationale in \.squad\\decisions\.md before speckit\.plan'; Failure = 'Prompt does not require a recorded skip rationale when clarify is skipped.' },
    @{ Pattern = [regex]::Escape($request); Failure = 'Prompt is missing the requested feature text.' }
)

foreach ($check in $promptChecks) {
    if (-not (Assert-Contains -Content $promptContent -Pattern $check.Pattern -FailureMessage $check.Failure)) {
        exit 1
    }
}
if ($startContext.approval_mode -ne 'allow-all') {
    Write-Fail "New feature flow did not record allow-all approval mode."
    exit 1
}
Write-Pass "Start command wrote prompt artifacts for new feature flow"

Write-Host "`nTest 4: prompt-approvals mode is preserved in start context"
$promptApprovalResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    'Inspect an auth flow bug',
    '--project-path', $projectRoot,
    '--prompt-approvals',
    '--no-launch'
)

if ($promptApprovalResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for prompt-approvals mode"
    foreach ($line in $promptApprovalResult.Output) {
        Write-Host $line
    }
    exit 1
}

$promptApprovalContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($promptApprovalContext.approval_mode -ne 'prompt-approvals') {
    Write-Fail "Prompt approval mode was not recorded correctly."
    exit 1
}
$promptApprovalOutput = $promptApprovalResult.Output -join "`n"
if (-not (Assert-Contains -Content $promptApprovalOutput -Pattern 'Manual launch command' -FailureMessage 'Prompt-approvals flow did not print an exact manual launch command.')) {
    exit 1
}
if ($promptApprovalOutput -match '--allow-all') {
    Write-Fail "Prompt-approvals flow should not include --allow-all in the manual launch command."
    exit 1
}
Write-Pass "Prompt approvals mode is preserved"

Write-Host "`nTest 5: resume mode reuses active feature context"
$featureDirectory = Join-Path -Path $projectRoot -ChildPath 'specs\001-existing-feature'
$null = New-Item -Path $featureDirectory -ItemType Directory -Force
$featureJsonPath = Join-Path -Path $projectRoot -ChildPath '.specify\feature.json'
[System.IO.File]::WriteAllText(
    $featureJsonPath,
    "{`n  `"feature_directory`": `"specs/001-existing-feature`"`n}",
    [System.Text.UTF8Encoding]::new($false)
)

$resumeResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--resume-feature', 'auto',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($resumeResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for resume flow"
    foreach ($line in $resumeResult.Output) {
        Write-Host $line
    }
    exit 1
}

$resumePromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if ((Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json).project_state.state -ne 'existing-continue') {
    Write-Fail 'Resume flow did not classify the project as existing-continue.'
    exit 1
}
if (-not (Assert-Contains -Content $resumePromptContent -Pattern ([regex]::Escape($featureDirectory)) -FailureMessage 'Resume prompt did not include the resolved active feature directory.')) {
    exit 1
}
Write-Pass "Resume flow reuses the active feature directory"

Write-Host "`nTest 5b: brownfield project is classified before spec intake"
$brownfieldRoot = Join-Path -Path $projectRoot -ChildPath 'src'
$null = New-Item -Path $brownfieldRoot -ItemType Directory -Force
[System.IO.File]::WriteAllText((Join-Path -Path $brownfieldRoot -ChildPath 'app.txt'), 'existing app content', [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'README.md'), "# Clipboard Sync`n`nA React dashboard for clipboard sync, analytics, and export workflows.", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $projectRoot -ChildPath 'package.json'), "{`n  `"name`": `"clipboard-sync`",`n  `"dependencies`": {`n    `"react`": `"^18.2.0`",`n    `"typescript`": `"^5.5.0`",`n    `"express`": `"^4.19.0`",`n    `"pg`": `"^8.11.0`"`n  }`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path -Path $brownfieldRoot -ChildPath 'app.tsx'), 'export const App = () => null;', [System.Text.UTF8Encoding]::new($false))
Remove-Item -LiteralPath $featureJsonPath -Force

$gitAddOutput = @(& git -C $projectRoot add README.md package.json src 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitAddOutput) {
        Write-Host $line
    }
    Write-Fail 'Failed to stage brownfield fixture files for git-history testing.'
    exit 1
}

$gitCommitOutput = @(& git -C $projectRoot -c user.name='Specrew Test' -c user.email='specrew-test@example.com' commit -m 'Add clipboard analytics dashboard baseline' --quiet 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $gitCommitOutput) {
        Write-Host $line
    }
    Write-Fail 'Failed to create a git commit for brownfield-history testing.'
    exit 1
}

$brownfieldResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($brownfieldResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed for brownfield classification flow"
    foreach ($line in $brownfieldResult.Output) {
        Write-Host $line
    }
    exit 1
}

$brownfieldContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($brownfieldContext.project_state.state -ne 'brownfield-new') {
    Write-Fail 'Brownfield project was not classified as brownfield-new.'
    exit 1
}
$brownfieldPromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
if (-not (Assert-Contains -Content $brownfieldPromptContent -Pattern 'perform brownfield discovery before asking the human broad intake questions' -FailureMessage 'Brownfield prompt did not instruct Squad to perform brownfield discovery first.')) {
    exit 1
}
if (-not (Assert-Contains -Content $brownfieldPromptContent -Pattern 'Brownfield discovery snapshot:' -FailureMessage 'Brownfield prompt did not include the serialized discovery snapshot.')) {
    exit 1
}
if ($null -eq $brownfieldContext.brownfield_discovery) {
    Write-Fail 'Brownfield start did not serialize a discovery snapshot into start-context.json.'
    exit 1
}
$brownfieldTechnologies = @($brownfieldContext.brownfield_discovery.technologies | ForEach-Object { $_.name })
if ($brownfieldTechnologies -notcontains 'React' -or $brownfieldTechnologies -notcontains 'Express') {
    Write-Fail 'Brownfield discovery did not capture the expected technology signals.'
    exit 1
}
$brownfieldDomainSignals = @($brownfieldContext.brownfield_discovery.domain_signals)
if ($brownfieldDomainSignals -notcontains 'Analytics & Reporting' -or $brownfieldDomainSignals -notcontains 'Sync & Data Transfer') {
    Write-Fail 'Brownfield discovery did not infer expected domain signals from docs/history.'
    exit 1
}
$suggestedRoles = @($brownfieldContext.brownfield_discovery.suggested_specialists | ForEach-Object { $_.role })
if ($suggestedRoles.Count -eq 0 -or $suggestedRoles -notcontains 'React Frontend Specialist') {
    Write-Fail 'Brownfield discovery did not suggest stack-aware specialist team members.'
    exit 1
}
if (@($brownfieldContext.brownfield_discovery.recent_commits).Count -eq 0) {
    Write-Fail 'Brownfield discovery did not capture recent git history.'
    exit 1
}
Write-Pass "Brownfield project classification is captured before spec intake"

Write-Host "`nTest 6: start command preserves the existing Specrew roster and serializes delegated routing"
$teamAddResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'team',
    'add', 'react-expert',
    '--role', 'Frontend React Expert',
    '--charter', 'Decide and implement React-related frontend work.',
    '-ProjectPath', $projectRoot
)

if ($teamAddResult.ExitCode -ne 0) {
    Write-Fail "Failed to add a supplemental team member for roster-preservation testing"
    foreach ($line in $teamAddResult.Output) {
        Write-Host $line
    }
    exit 1
}

$roleAssignmentsPath = Join-Path -Path $projectRoot -ChildPath '.specrew\role-assignments.yml'
$roleAssignmentsContent = @'
# Role Assignments
# Schema: v1

roles:
  - name: "Spec Steward"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "codex"
    responsibilities: "Spec integrity"

  - name: "Planner"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Planning"

  - name: "Implementer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Implementation"

  - name: "Reviewer"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "claude"
    responsibilities: "Review"

  - name: "Retro Facilitator"
    type: "baseline"
    assigned_to: "unassigned"
    preferred_agent: "copilot"
    responsibilities: "Retrospective"
'@
[System.IO.File]::WriteAllText($roleAssignmentsPath, $roleAssignmentsContent, [System.Text.UTF8Encoding]::new($false))

$iterationConfigPath = Join-Path -Path $projectRoot -ChildPath '.specrew\iteration-config.yml'
$iterationConfigWithDelegation = @'
# Iteration Configuration
# Schema: v1
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"

# >>> specrew-managed agents >>>
# Specrew-managed agent consent and detection state (FR-022).
agents:
  copilot:
    enabled: true
    access_path: copilot_default
    availability: available
  claude:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
  codex:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
# <<< specrew-managed agents <<<
'@
[System.IO.File]::WriteAllText($iterationConfigPath, $iterationConfigWithDelegation, [System.Text.UTF8Encoding]::new($false))

$delegatedStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    'Add a clipboard sync feature',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($delegatedStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed while testing roster preservation and delegated routing"
    foreach ($line in $delegatedStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$delegatedPromptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
$delegatedContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$squadConfigPath = Join-Path -Path $projectRoot -ChildPath '.squad\config.json'
$squadConfig = Get-Content -LiteralPath $squadConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

if (-not (Assert-Contains -Content $delegatedPromptContent -Pattern 'Do NOT enter generic Squad team-setup mode or recast the roster' -FailureMessage 'Prompt did not explicitly preserve the existing Specrew-managed roster.')) {
    exit 1
}

if ($delegatedContext.team_roster.mode -ne 'specrew-managed') {
    Write-Fail 'Start context did not classify the current roster as Specrew-managed.'
    exit 1
}

$supplementalRoles = @($delegatedContext.team_roster.supplemental_members | ForEach-Object { $_.role })
if ($supplementalRoles -notcontains 'Frontend React Expert') {
    Write-Fail 'Start context did not preserve the supplemental roster member.'
    exit 1
}

if ($delegatedContext.delegated_routing.roles.Reviewer.effective_agent -ne 'claude') {
    Write-Fail 'Reviewer did not route to Claude when Claude was enabled and preferred.'
    exit 1
}

if ($delegatedContext.delegated_routing.roles.'Spec Steward'.effective_agent -ne 'codex') {
    Write-Fail 'Spec Steward did not route to Codex when Codex was enabled and preferred.'
    exit 1
}

if ($delegatedContext.squad_model_overrides.Reviewer -ne 'claude-sonnet-4.5') {
    Write-Fail 'Start context did not expose the Reviewer model override.'
    exit 1
}

if ($delegatedContext.squad_model_overrides.'Spec Steward' -ne 'gpt-5.2-codex') {
    Write-Fail 'Start context did not expose the Spec Steward model override.'
    exit 1
}

if ($squadConfig.agentModelOverrides.Reviewer -ne 'claude-sonnet-4.5' -or $squadConfig.agentModelOverrides.'Spec Steward' -ne 'gpt-5.2-codex') {
    Write-Fail 'specrew start did not persist delegated model overrides into .squad\config.json.'
    exit 1
}

if ($null -eq $squadConfig.specrewManagedModelRouting) {
    Write-Fail 'specrew start did not persist Specrew-managed model-routing metadata into .squad\config.json.'
    exit 1
}

if ($squadConfig.specrewManagedModelRouting.baselineAgentModelOverrides.Reviewer -ne 'claude-sonnet-4.5' -or
    $squadConfig.specrewManagedModelRouting.roleAgentFamilies.Reviewer -ne 'claude' -or
    $squadConfig.specrewManagedModelRouting.roleAgentFamilies.Planner -ne 'copilot') {
    Write-Fail 'specrew start did not persist the baseline override map and role agent families needed for live escalation.'
    exit 1
}

Write-Pass "Start command preserves the Specrew roster and serializes delegated routing"

Write-Host "`nTest 7: start command records fallback reasons when a delegated agent is unavailable"
$iterationConfigWithFallback = @'
# Iteration Configuration
# Schema: v1
effort_unit: "story_points"
capacity_per_iteration: 20
iteration_bounding: "scope"
time_limit_hours: null
overcommit_threshold: 1.0
calibration_enabled: true
defer_strategy: "manual"

# >>> specrew-managed agents >>>
# Specrew-managed agent consent and detection state (FR-022).
agents:
  copilot:
    enabled: true
    access_path: copilot_default
    availability: available
  claude:
    enabled: true
    access_path: copilot_agent_hq
    availability: available
  codex:
    enabled: false
    access_path: copilot_agent_hq
    availability: available
# <<< specrew-managed agents <<<
'@
[System.IO.File]::WriteAllText($iterationConfigPath, $iterationConfigWithFallback, [System.Text.UTF8Encoding]::new($false))

$fallbackStartResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'start',
    'Harden delegated review routing',
    '--project-path', $projectRoot,
    '--no-launch'
)

if ($fallbackStartResult.ExitCode -ne 0) {
    Write-Fail "specrew start failed while testing delegated fallback logging"
    foreach ($line in $fallbackStartResult.Output) {
        Write-Host $line
    }
    exit 1
}

$fallbackContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$specStewardPlan = $fallbackContext.delegated_routing.roles.'Spec Steward'
if ($specStewardPlan.effective_agent -ne 'claude') {
    Write-Fail 'Spec Steward did not fall back to Claude when Codex was disabled.'
    exit 1
}

$fallbackEvents = @($fallbackContext.delegated_routing.fallback_events)
$specStewardFallback = @($fallbackEvents | Where-Object { $_.role -eq 'Spec Steward' })
if ($specStewardFallback.Count -eq 0 -or $specStewardFallback[0].reason -notmatch "preferred agent 'codex' is not enabled") {
    Write-Fail 'Delegated routing fallback reason was not recorded for Spec Steward.'
    exit 1
}

Write-Pass "Start command records delegated routing fallback reasons"

Write-Host "`nAll tests passed!"

Write-Host "Cleaning up test artifacts..."
if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

exit 0
