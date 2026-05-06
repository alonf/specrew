[CmdletBinding()]
param(
    [string]$ProjectPath,
    [string]$FeatureRequest = 'Create a tiny sample app with one visible UI surface and one simple health/status capability so Specrew can drive the full lifecycle.',
    [switch]$LaunchCopilot,
    [switch]$NewWindow,
    [switch]$PromptApprovals,
    [switch]$KeepProject
)

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

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return [pscustomobject]@{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Path {
    param(
        [string]$Path,
        [string]$FailureMessage
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Fail $FailureMessage
        exit 1
    }
}

function Initialize-GitRepo {
    param([string]$Root)

    $gitInitOutput = @(& git -C $Root init --quiet 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in $gitInitOutput) {
            Write-Host $line
        }

        Write-Fail ("Failed to initialize git repository in smoke workspace: {0}" -f $Root)
        exit 1
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$entryScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew.ps1'
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'

foreach ($requiredScript in @($entryScript, $initScript)) {
    Assert-Path -Path $requiredScript -FailureMessage ("Missing required script: {0}" -f $requiredScript)
}

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}
if ($LaunchCopilot -and -not (Get-Command -Name 'copilot' -ErrorAction SilentlyContinue)) {
    $missingTools += 'copilot'
}

if ($missingTools.Count -gt 0) {
    Write-Fail ("Smoke harness requires tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 1
}

if (-not $ProjectPath) {
    $ProjectPath = Join-Path -Path $repoRoot -ChildPath '.scratch\copilot-squad-smoke\project'
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
if ((Test-Path -LiteralPath $resolvedProjectPath) -and -not $KeepProject) {
    Remove-Item -LiteralPath $resolvedProjectPath -Recurse -Force
}

$null = New-Item -Path $resolvedProjectPath -ItemType Directory -Force
Initialize-GitRepo -Root $resolvedProjectPath
Write-Pass ("Initialized smoke workspace: {0}" -f $resolvedProjectPath)

Write-Info 'Running specrew init...'
$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $resolvedProjectPath, '-Force', '-NoAgents')
if ($initResult.ExitCode -ne 0) {
    foreach ($line in $initResult.Output) {
        Write-Host $line
    }
    Write-Fail 'specrew init failed in smoke harness.'
    exit 1
}

Assert-Path -Path (Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\config.yml') -FailureMessage 'Smoke harness bootstrap did not produce .specrew\config.yml.'
Assert-Path -Path (Join-Path -Path $resolvedProjectPath -ChildPath '.github\agents\squad.agent.md') -FailureMessage 'Smoke harness bootstrap did not deploy the Squad coordinator prompt.'
Write-Pass 'Specrew bootstrap completed in smoke workspace'

$startArgs = @(
    'start',
    $FeatureRequest,
    '--project-path', $resolvedProjectPath
)

if (-not $LaunchCopilot) {
    $startArgs += '--no-launch'
}
elseif ($NewWindow) {
    $startArgs += '--new-window'
}

if ($PromptApprovals) {
    $startArgs += '--prompt-approvals'
}

Write-Info 'Running specrew start...'
$startResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList $startArgs
if ($startResult.ExitCode -ne 0) {
    foreach ($line in $startResult.Output) {
        Write-Host $line
    }
    Write-Fail 'specrew start failed in smoke harness.'
    exit 1
}

$promptPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\last-start-prompt.md'
$contextPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\start-context.json'
$summaryPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\start-summary.md'
Assert-Path -Path $promptPath -FailureMessage 'Smoke harness start did not create the handoff prompt.'
Assert-Path -Path $contextPath -FailureMessage 'Smoke harness start did not create start-context.json.'
Assert-Path -Path $summaryPath -FailureMessage 'Smoke harness start did not create start-summary.md.'
Write-Pass 'Specrew start produced handoff artifacts'

$startOutput = $startResult.Output -join [Environment]::NewLine
$startContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent -notmatch 'Do not invoke speckit\.implement until the human approves') {
    Write-Fail 'Smoke harness prompt is missing the explicit implementation-approval gate.'
    exit 1
}

if ($promptContent -notmatch 'developer-facing implementation briefing') {
    Write-Fail 'Smoke harness prompt is missing the final implementation briefing instruction.'
    exit 1
}

if ($promptContent -notmatch 'run speckit\.clarify for every newly generated spec before speckit\.plan') {
    Write-Fail 'Smoke harness prompt is missing the mandatory clarify rule for newly generated specs.'
    exit 1
}

if ($promptContent -notmatch 'route bounded, lower-risk, well-scoped work to the Junior role') {
    Write-Fail 'Smoke harness prompt is missing Junior/Senior routing guidance.'
    exit 1
}

if ($promptContent -notmatch 'careful, responsible, knowledgeable, and review-ready') {
    Write-Fail 'Smoke harness prompt is missing the higher Junior quality bar.'
    exit 1
}

if ($promptContent -notmatch 'deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences') {
    Write-Fail 'Smoke harness prompt is missing the deeper Senior technical bar.'
    exit 1
}

if ($promptContent -notmatch 'Planning/problem-solving work should prefer Planner or Spec Steward delegated routing') {
    Write-Fail 'Smoke harness prompt is missing the delegated routing policy for problem-solving-heavy work.'
    exit 1
}

if ($promptContent -notmatch 'concrete model ID') {
    Write-Fail 'Smoke harness prompt is missing the delegated runtime evidence requirement.'
    exit 1
}

if ($promptContent -notmatch 'no-gap policy' -or
    $promptContent -notmatch 'implemented, enforced, observable, and documented') {
    Write-Fail 'Smoke harness prompt is missing the no-gap / critical-review policy.'
    exit 1
}

if ($null -eq $startContext.delivery_guidance -or @($startContext.delivery_guidance.quality_attributes).Count -eq 0) {
    Write-Fail 'Smoke harness context is missing delivery guidance quality attributes.'
    exit 1
}

if ($null -eq $startContext.delivery_guidance.same_specialty_pair_hints) {
    Write-Fail 'Smoke harness context is missing the Junior/Senior same-specialty pair hints field.'
    exit 1
}

if ($null -eq $startContext.delegated_routing_evidence -or
    $startContext.delegated_routing_evidence.ledger_path -ne '.squad\decisions.md' -or
    @($startContext.delegated_routing_evidence.required_fields) -notcontains 'model_id') {
    Write-Fail 'Smoke harness context is missing the delegated runtime evidence contract.'
    exit 1
}

$summaryContent = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8
if ($summaryContent -notmatch 'Review/closure use a no-gap policy' -or
    $summaryContent -notmatch 'Delegated Routing') {
    Write-Fail 'Smoke harness summary is missing the no-gap or delegated-routing overview.'
    exit 1
}

if (-not $startContext.copilot_autopilot) {
    Write-Fail 'Smoke harness context should record autopilot mode for grounded feature requests.'
    exit 1
}

if (-not $LaunchCopilot) {
    if ($startOutput -notmatch 'Manual launch command') {
        Write-Fail 'Smoke harness expected specrew start --no-launch to print an exact manual launch command.'
        exit 1
    }
    if ($startOutput -notmatch 'last-start-prompt\.md' -or $startOutput -notmatch 'start-context\.json') {
        Write-Fail 'Smoke harness manual command did not reference the saved handoff files.'
        exit 1
    }

    Write-Pass 'Manual smoke handoff command was printed'
    Write-Info ("Project: {0}" -f $resolvedProjectPath)
    Write-Info ("Prompt:  {0}" -f $promptPath)
    Write-Info ("Context: {0}" -f $contextPath)
    Write-Info ("Summary: {0}" -f $summaryPath)
    exit 0
}

Write-Pass ("Copilot handoff launched with mode: {0}" -f $startContext.launch_mode)
if ($startContext.launch_mode -eq 'new-window') {
    Write-Info 'Copilot + Squad should now be running in a new PowerShell window. Continue the mission there and inspect generated artifacts in this smoke workspace.'
}
else {
    Write-Info 'Copilot + Squad was launched in the current terminal. Continue the mission in this shell until the lifecycle reaches the desired stopping point.'
}

Write-Info ("Project: {0}" -f $resolvedProjectPath)
Write-Info ("Prompt:  {0}" -f $promptPath)
Write-Info ("Context: {0}" -f $contextPath)
Write-Info ("Summary: {0}" -f $summaryPath)
exit 0
