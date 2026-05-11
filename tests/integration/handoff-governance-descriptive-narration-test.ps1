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
$coordinatorResponsePath = Join-Path $repoRoot 'extensions\specrew-speckit\prompts\coordinator-response.md'
$squadAgentPath = Join-Path $repoRoot '.github\agents\squad.agent.md'
$squadTemplatePath = Join-Path $repoRoot '.squad\templates\squad.agent.md'
$templatePath = Join-Path $repoRoot 'specs\001-specrew-product\contracts\coordinator-handoff-template.md'

$requiredPaths = @($validatorScript, $coordinatorResponsePath, $squadAgentPath, $squadTemplatePath, $templatePath)
foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Missing required artifact: $path"
        exit 1
    }
}

$coordinatorResponse = Get-Content -Raw -LiteralPath $coordinatorResponsePath
$squadAgent = Get-Content -Raw -LiteralPath $squadAgentPath
$squadTemplate = Get-Content -Raw -LiteralPath $squadTemplatePath
$template = Get-Content -Raw -LiteralPath $templatePath

if ($coordinatorResponse -notmatch '## Readable Reference Rule') {
    Write-Fail 'Coordinator response guidance is missing the readable reference rule section.'
    exit 1
}

if ($coordinatorResponse -notmatch 'feature 012, descriptive references in handoffs') {
    Write-Fail 'Coordinator response guidance is missing the acceptable narration example.'
    exit 1
}

if ($coordinatorResponse -notmatch 'I finished 012, 001, T003, T004, FR-008, and 070dd06\.') {
    Write-Fail 'Coordinator response guidance is missing the unacceptable narration example.'
    exit 1
}

if ($squadAgent -notmatch 'When authored prose mentions three or more feature, iteration, task, requirement, corpus, or commit references') {
    Write-Fail 'Squad agent guidance is missing the readable reference rule.'
    exit 1
}

if ($squadAgent -notmatch 'T003 and T004, the validator-and-contract foundation') {
    Write-Fail 'Squad agent guidance is missing the grouped-list shared scope example.'
    exit 1
}

if ($squadTemplate -notmatch 'When authored prose mentions three or more feature, iteration, task, requirement, corpus, or commit references') {
    Write-Fail 'Squad template guidance is missing the readable reference rule.'
    exit 1
}

if ($template -notmatch '## Descriptive Reference Rules') {
    Write-Fail 'Coordinator handoff template is missing the descriptive reference rules section.'
    exit 1
}

$warnNarration = @'
## What I just did
Completed 012, 001, T003, T004, FR-008, and 070dd06.

## Why I stopped
I stopped because the requested review is still pending and I cannot continue safely until it is resolved.

## What I need from you
Next step: review the wording.
'@

$warnOutput = @(& $validatorScript -ResponseText $warnNarration 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on opaque narration input.'
    $warnOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$warnJoined = ($warnOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($warnJoined -notmatch 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Expected opaque numeric reference warning for narration fixture.`n$warnJoined"
    exit 1
}

$passNarration = @'
## What I just did
Completed feature 012, descriptive references in handoffs, and iteration 001, the readable-reference rollout. I finished T003 and T004, the validator-and-contract foundation, and aligned FR-008 and FR-009, the non-blocking governance review requirements, with 070dd06, the implementation-authorization boundary commit.

## Why I stopped
I stopped because the Squad startup guidance edits are a restart-trigger boundary, and I cannot finish that slice safely in this session.

## What I need from you
Next step: restart the session before the startup guidance edits continue.
'@

$passOutput = @(& $validatorScript -ResponseText $passNarration 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on described narration input.'
    $passOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$passJoined = ($passOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($passJoined -match 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Did not expect opaque numeric reference warning for described narration input.`n$passJoined"
    exit 1
}

$groupedListNarration = @'
## What I just did
Updated the validator and contract foundation (T003 and T004), the narration prompts (T005 through T007), and the stop-message guidance (T009 and T010) for feature 012, descriptive references in handoffs.

## Why I stopped
This slice is complete.

## What I need from you
Next step: review the wording.
'@

$groupedOutput = @(& $validatorScript -ResponseText $groupedListNarration 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on grouped-list narration input.'
    $groupedOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$groupedJoined = ($groupedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($groupedJoined -match 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Did not expect opaque numeric reference warning for grouped-list narration input.`n$groupedJoined"
    exit 1
}

$excludedNarration = @'
## What I just did
Updated the narration guidance.

```text
Completed 012, 001, T003, T004, FR-008, and 070dd06.
```

## Why I stopped
This slice is complete.

## What I need from you
Next step: review the wording.
'@

$excludedOutput = @(& $validatorScript -ResponseText $excludedNarration 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'Validator should not hard-fail on excluded-surface narration input.'
    $excludedOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$excludedJoined = ($excludedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($excludedJoined -match 'soft-warning\.opaque-numeric-references') {
    Write-Fail "Did not expect opaque numeric reference warning for excluded-surface narration input.`n$excludedJoined"
    exit 1
}

Write-Pass 'Narration guidance and validator stay aligned for descriptive references and excluded surfaces'
exit 0
