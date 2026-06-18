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
What I just did
before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse, and validator alignment are pending.

Why I stopped
I stopped because the blocker still needs review.

What needs your review
Review the governance wording and confirm the lead should be rewritten in plain language.

What happens next
After review, the response can be rewritten with a plain-language lead before formal terms.

What I need from you
Next step: approve the pending governance items.
'@

$output = @(& $validatorScript -ResponseText $responseText 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Handoff governance validator should not hard-fail on jargon-first input.'
    $output | ForEach-Object { Write-Host $_ }
    exit 1
}

$joinedOutput = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($joinedOutput -notmatch 'status: warn') {
    Write-Fail "Expected warn status for jargon-first input.`n$joinedOutput"
    exit 1
}

if ($joinedOutput -notmatch 'soft-warning\.jargon-first-lead') {
    Write-Fail "Expected jargon-first warning for jargon-heavy lead.`n$joinedOutput"
    exit 1
}

Write-Pass 'Handoff governance validator flags jargon-first lead without hard-blocking response delivery'
exit 0
