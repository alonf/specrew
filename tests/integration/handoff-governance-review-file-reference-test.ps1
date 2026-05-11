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

if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
    Write-Fail "Missing validator script: $validatorScript"
    exit 1
}

$responseText = @'
## What I just did
Updated the handoff guidance and verified the affected files.

## Why I stopped
This slice is complete, so I paused for review.

## What I need from you
Review the updated handoff wording in `C:\Dev\Specrew\specs\007-user-facing-progress-handoff\spec.md`. Next step: confirm the wording is acceptable for rollout.
'@

$output = @(& $validatorScript -ResponseText $responseText 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Handoff governance validator should not hard-fail on review-file warning input.'
    $output | ForEach-Object { Write-Host $_ }
    exit 1
}

$joinedOutput = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($joinedOutput -notmatch 'status: warn') {
    Write-Fail "Expected warn status for missing file URI input.`n$joinedOutput"
    exit 1
}

if ($joinedOutput -notmatch 'soft-warning\.review-file-reference-format') {
    Write-Fail "Expected review-file-reference warning when file:/// URI is missing.`n$joinedOutput"
    exit 1
}

if ($joinedOutput -match 'soft-warning\.missing-(progress-status|next-step)') {
    Write-Fail "Did not expect missing-field warnings for review-file fixture.`n$joinedOutput"
    exit 1
}

Write-Pass 'Handoff governance validator warns when local review requests omit file:/// URI'
exit 0
