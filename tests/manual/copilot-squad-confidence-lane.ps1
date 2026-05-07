[CmdletBinding()]
param(
    [string]$ProjectPath,
    [string]$FeatureRequest = 'Create a tiny sample app with one visible UI surface and one simple health/status capability so Specrew can drive the full lifecycle.',
    [switch]$LaunchCopilot,
    [switch]$NewWindow,
    [switch]$PromptApprovals,
    [string]$TraceDirectory,
    [ValidateSet('confidence', 'contract')]
    [string]$LaneName = 'confidence',
    [ValidateSet('skip', 'fail')]
    [string]$MissingToolExitMode = 'skip'
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

function Get-RelativePathSafe {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath) -or
        [string]::IsNullOrWhiteSpace($TargetPath) -or
        -not (Test-Path -LiteralPath $TargetPath)) {
        return $null
    }

    $fromUri = [System.Uri]([System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\')
    $toUri = [System.Uri]([System.IO.Path]::GetFullPath($TargetPath))
    return [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()) -replace '/', '\'
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$smokeScript = Join-Path -Path $repoRoot -ChildPath 'tests\manual\copilot-squad-smoke.ps1'
if (-not (Test-Path -LiteralPath $smokeScript -PathType Leaf)) {
    Write-Fail "Missing smoke harness: $smokeScript"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Join-Path -Path $repoRoot -ChildPath ('.scratch\copilot-squad-{0}-lane\project' -f $LaneName)
}

if ([string]::IsNullOrWhiteSpace($TraceDirectory)) {
    $TraceDirectory = Join-Path -Path $repoRoot -ChildPath ('.scratch\copilot-squad-{0}-lane\traces' -f $LaneName)
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$resolvedTraceDirectory = [System.IO.Path]::GetFullPath($TraceDirectory)
$null = New-Item -Path $resolvedTraceDirectory -ItemType Directory -Force

$startedAtUtc = [DateTime]::UtcNow
$smokeArgs = @(
    '-ProjectPath', $resolvedProjectPath,
    '-FeatureRequest', $FeatureRequest,
    '-KeepProject'
)

if ($LaunchCopilot) {
    $smokeArgs += '-LaunchCopilot'
    if ($NewWindow) {
        $smokeArgs += '-NewWindow'
    }
}

if ($PromptApprovals) {
    $smokeArgs += '-PromptApprovals'
}

$output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $smokeScript @smokeArgs 2>&1)
$exitCode = $LASTEXITCODE
$completedAtUtc = [DateTime]::UtcNow
$outputLines = @($output | ForEach-Object { [string]$_ })
$joinedOutput = $outputLines -join [Environment]::NewLine

$promptPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\last-start-prompt.md'
$contextPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\start-context.json'
$summaryPath = Join-Path -Path $resolvedProjectPath -ChildPath '.specrew\start-summary.md'

$startContext = $null
if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
    $startContext = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$traceStatus = if ($exitCode -eq 0) { 'passed' } elseif ($joinedOutput -match 'Smoke harness requires tools not available') { 'missing-tools' } else { 'failed' }
$effectiveExitCode = $exitCode
if ($traceStatus -eq 'missing-tools' -and $MissingToolExitMode -eq 'skip') {
    $effectiveExitCode = 0
}

$traceRecord = [ordered]@{
    schema            = 'v1'
    lane              = $LaneName
    execution_mode    = if ($LaunchCopilot) { 'live' } else { 'manual-handoff' }
    project_path      = $resolvedProjectPath
    feature_request   = $FeatureRequest
    started_at_utc    = $startedAtUtc.ToString('o')
    completed_at_utc  = $completedAtUtc.ToString('o')
    status            = $traceStatus
    exit_code         = $exitCode
    command           = ('pwsh -NoProfile -ExecutionPolicy Bypass -File {0} {1}' -f $smokeScript, ($smokeArgs -join ' '))
    output_lines      = $outputLines
    replay_inputs     = [ordered]@{
        prompt_path  = Get-RelativePathSafe -BasePath $resolvedProjectPath -TargetPath $promptPath
        context_path = Get-RelativePathSafe -BasePath $resolvedProjectPath -TargetPath $contextPath
        summary_path = Get-RelativePathSafe -BasePath $resolvedProjectPath -TargetPath $summaryPath
    }
    policy_trace      = if ($null -eq $startContext) {
        $null
    }
    else {
        [ordered]@{
            mode                        = $startContext.mode
            approval_mode               = $startContext.approval_mode
            launch_mode                 = $startContext.launch_mode
            copilot_autopilot           = $startContext.copilot_autopilot
            project_state               = $startContext.project_state
            delegated_routing_evidence  = $startContext.delegated_routing_evidence
            routing_guardrail_count     = @($startContext.delivery_guidance.routing_guardrails).Count
            quality_attribute_names     = @($startContext.delivery_guidance.quality_attributes | ForEach-Object { $_.name })
            specialist_hint_roles       = @($startContext.delivery_guidance.specialist_hints | ForEach-Object { $_.role })
            same_specialty_pair_roles   = @($startContext.delivery_guidance.same_specialty_pair_hints | ForEach-Object { '{0}|{1}' -f $_.junior_role, $_.senior_role })
        }
    }
}

$traceTimestamp = $completedAtUtc.ToString('yyyyMMdd-HHmmss')
$tracePath = Join-Path -Path $resolvedTraceDirectory -ChildPath ('{0}-trace-{1}.json' -f $LaneName, $traceTimestamp)
[System.IO.File]::WriteAllText($tracePath, ($traceRecord | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))

Write-Info ("Trace:   {0}" -f $tracePath)
Write-Info ("Project: {0}" -f $resolvedProjectPath)

if ($traceStatus -eq 'missing-tools' -and $MissingToolExitMode -eq 'skip') {
    Write-Host ("SKIP: Live smoke lane tools are unavailable; trace persisted at {0}" -f $tracePath) -ForegroundColor Yellow
    exit 0
}

if ($effectiveExitCode -ne 0) {
    foreach ($line in $outputLines) {
        Write-Host $line
    }
    Write-Fail ("Smoke lane execution failed; trace persisted at {0}" -f $tracePath)
    exit $effectiveExitCode
}

Write-Pass ("Smoke lane completed and persisted trace at {0}" -f $tracePath)
exit 0
