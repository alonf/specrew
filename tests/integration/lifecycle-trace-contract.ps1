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
$traceLaneScript = Join-Path -Path $repoRoot -ChildPath 'tests\manual\copilot-squad-confidence-lane.ps1'
if (-not (Test-Path -LiteralPath $traceLaneScript -PathType Leaf)) {
    Write-Fail "Missing confidence lane script: $traceLaneScript"
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
    Write-Host ("SKIP: Lifecycle trace contract test requires tools not available in this environment: {0}" -f ($missingTools -join ', ')) -ForegroundColor Yellow
    exit 0
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\lifecycle-trace-contract'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$traceRoot = Join-Path -Path $scratchRoot -ChildPath 'traces'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$traceRun = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $traceLaneScript -LaneName contract -ProjectPath $projectRoot -TraceDirectory $traceRoot -MissingToolExitMode fail 2>&1)
if ($LASTEXITCODE -ne 0) {
    foreach ($line in $traceRun) {
        Write-Host $line
    }
    Write-Fail 'Contract trace lane failed to execute successfully.'
    exit 1
}

$traceFile = Get-ChildItem -Path $traceRoot -Filter 'contract-trace-*.json' | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
if ($null -eq $traceFile) {
    Write-Fail 'Contract trace lane did not persist a structured trace file.'
    exit 1
}

$trace = Get-Content -LiteralPath $traceFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
if ($trace.schema -ne 'v1') {
    Write-Fail 'Lifecycle trace does not record schema=v1.'
    exit 1
}
if ($trace.lane -ne 'contract') {
    Write-Fail 'Lifecycle trace did not identify the contract lane.'
    exit 1
}
if ($trace.execution_mode -ne 'manual-handoff') {
    Write-Fail 'Contract trace lane should remain deterministic/manual-handoff.'
    exit 1
}
if ($trace.status -ne 'passed') {
    Write-Fail "Contract trace lane should pass, found status '$($trace.status)'."
    exit 1
}
foreach ($requiredPathField in @('prompt_path', 'context_path', 'summary_path')) {
    if ([string]::IsNullOrWhiteSpace([string]$trace.replay_inputs.$requiredPathField)) {
        Write-Fail "Lifecycle trace is missing replay input '$requiredPathField'."
        exit 1
    }
}
if ($trace.policy_trace.delegated_routing_evidence.ledger_path -ne '.squad\decisions.md') {
    Write-Fail 'Lifecycle trace did not preserve delegated routing evidence contract.'
    exit 1
}
if (@($trace.policy_trace.delegated_routing_evidence.required_fields) -notcontains 'model_id') {
    Write-Fail 'Lifecycle trace did not preserve required delegated routing evidence fields.'
    exit 1
}
if (@($trace.policy_trace.quality_attribute_names).Count -eq 0) {
    Write-Fail 'Lifecycle trace did not preserve delivery guidance quality attributes.'
    exit 1
}
if ($trace.policy_trace.mode -notin @('new-feature', 'intake-or-resume')) {
    Write-Fail 'Lifecycle trace did not preserve a valid start mode.'
    exit 1
}

Write-Pass 'Contract trace lane persists structured lifecycle traces with replay inputs and policy evidence'
exit 0
