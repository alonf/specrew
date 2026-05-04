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
$freshStartChecks = @(
    @{ Pattern = 'Mode: intake-or-resume'; Failure = 'Fresh repo prompt did not enter intake-or-resume mode.' },
    @{ Pattern = 'ask the human whether they want to fix something or start a new feature'; Failure = 'Fresh repo prompt did not tell Squad to gather missing feature direction.' },
    @{ Pattern = 'additional specialist team members'; Failure = 'Fresh repo prompt did not tell Squad when to ask about extra specialists.' }
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
if (-not (Assert-Contains -Content $resumePromptContent -Pattern ([regex]::Escape($featureDirectory)) -FailureMessage 'Resume prompt did not include the resolved active feature directory.')) {
    exit 1
}
Write-Pass "Resume flow reuses the active feature directory"

Write-Host "`nAll tests passed!"

Write-Host "Cleaning up test artifacts..."
if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

exit 0
