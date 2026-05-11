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
$decisionGuidancePath = Join-Path $repoRoot 'extensions\specrew-speckit\prompts\coordinator-decision-guidance.md'
$checklistPath = Join-Path $repoRoot 'extensions\specrew-speckit\checklists\coordinator-handoff-governance.md'
$templatePath = Join-Path $repoRoot 'specs\001-specrew-product\contracts\coordinator-handoff-template.md'

$requiredPaths = @($validatorScript, $decisionGuidancePath, $checklistPath, $templatePath)
foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Missing required artifact: $path"
        exit 1
    }
}

$decisionGuidance = Get-Content -Raw -LiteralPath $decisionGuidancePath
$checklist = Get-Content -Raw -LiteralPath $checklistPath
$template = Get-Content -Raw -LiteralPath $templatePath

if ($decisionGuidance -notmatch '### 6\. Readable Reference Decision') {
    Write-Fail 'Coordinator decision guidance is missing the readable-reference decision section.'
    exit 1
}

if ($decisionGuidance -notmatch 'Unacceptable:\s*\r?\n\r?\n> I finished 012, 001, T009, T010, and 070dd06\.' ) {
    Write-Fail 'Coordinator decision guidance is missing the unacceptable stop-message example.'
    exit 1
}

if ($checklist -notmatch 'soft-warning\.opaque-numeric-references') {
    Write-Fail 'Checklist is missing the opaque numeric reference heuristic.'
    exit 1
}

if ($checklist -notmatch 'Excluded verbatim surfaces stay excluded') {
    Write-Fail 'Checklist is missing the excluded-surface guidance.'
    exit 1
}

if ($template -notmatch '## Descriptive Reference Rules') {
    Write-Fail 'Coordinator handoff template is missing the descriptive reference rules section.'
    exit 1
}

if ($template -notmatch 'implementation-authorization boundary commit') {
    Write-Fail 'Coordinator handoff template is missing the commit why-it-matters example.'
    exit 1
}

$warnStopMessage = @'
## What I just did
Completed 012, 001, T009, T010, FR-008, and 070dd06.

## Why I stopped
I stopped because the requested review is still pending and I cannot continue safely until it is resolved.

## What I need from you
Next step: review the wording.
'@

$warnOutput = @(& $validatorScript -ResponseText $warnStopMessage 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on opaque stop-message input.'
    $warnOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$warnJoined = ($warnOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($warnJoined -notmatch 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Expected opaque numeric reference warning for stop-message fixture.`n$warnJoined"
    exit 1
}

$passStopMessage = @'
## What I just did
Completed feature 012, descriptive references in handoffs, and iteration 001, the readable-reference rollout. I finished T009 and T010, the stop-message guidance updates, and aligned FR-008 and FR-009, the non-blocking governance review requirements, with 070dd06, the implementation-authorization boundary commit.

## Why I stopped
I stopped because the Squad startup guidance edits are a restart-trigger boundary, and I cannot finish that slice safely in this session.

## What I need from you
Next step: restart the session before the startup guidance edits continue.
'@

$passOutput = @(& $validatorScript -ResponseText $passStopMessage 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on described stop-message input.'
    $passOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$passJoined = ($passOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($passJoined -match 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Did not expect opaque numeric reference warning for described stop-message input.`n$passJoined"
    exit 1
}

$excludedStopMessage = @'
## What I just did
Updated the stop-message guidance.

```text
Completed 012, 001, T009, T010, FR-008, and 070dd06.
```

## Why I stopped
This slice is complete.

## What I need from you
Next step: review the wording.
'@

$excludedOutput = @(& $validatorScript -ResponseText $excludedStopMessage 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on excluded-surface stop-message input.'
    $excludedOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$excludedJoined = ($excludedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($excludedJoined -match 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Did not expect opaque numeric reference warning for excluded-surface stop-message input.`n$excludedJoined"
    exit 1
}

Write-Pass 'Stop-message guidance and validator stay aligned for descriptive references and excluded surfaces'
exit 0
