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
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
$specPath = Join-Path $repoRoot 'specs\007-user-facing-progress-handoff\spec.md'

foreach ($requiredPath in @($validatorScript, $specPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required file: $requiredPath"
        exit 1
    }
}

$specUri = [System.Uri]::new([System.IO.Path]::GetFullPath($specPath)).AbsoluteUri

$responseText = @'
## What I just did
Completed the review guidance update and verified the affected files were updated.

## Why I stopped
This slice is complete, and no blockers remain in the current scope.

## What I need from you
Review the updated handoff wording in `{0}`. Next step: confirm the wording is acceptable for rollout.
'@ -f $specUri

$output = @(& $validatorScript -ResponseText $responseText 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Handoff governance validator should not hard-fail on plain-language input.'
    $output | ForEach-Object { Write-Host $_ }
    exit 1
}

$joinedOutput = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($joinedOutput -notmatch 'status: pass') {
    Write-Fail "Expected pass status for plain-language input.`n$joinedOutput"
    exit 1
}

if ($joinedOutput -match 'soft-warning\.') {
    Write-Fail "Did not expect soft warnings for plain-language input.`n$joinedOutput"
    exit 1
}

Write-Pass 'Handoff governance validator accepts plain-language-first handoffs with explicit next steps'
exit 0
