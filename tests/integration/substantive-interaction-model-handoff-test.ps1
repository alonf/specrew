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
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$fixtureIteration = Join-Path $repoRoot 'tests\integration\fixtures\016-substantive-interaction-model\interaction-model-state'
$existingPlanUri = 'file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/plan.md'
$existingGateUri = 'file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/quality/hardening-gate.md'
$missingUri = 'file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/missing-artifact.md'
$settingsPath = Join-Path $repoRoot '.specrew\config.yml'
$barePathSeverity = 'soft-warning'
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    foreach ($line in Get-Content -LiteralPath $settingsPath -Encoding UTF8) {
        if ($line -match '^\s{2}bare_path_boundary_handoff_severity:\s*"?(?<value>[^"]+)"?\s*$') {
            $barePathSeverity = $Matches['value'].Trim()
            break
        }
    }
}
$expectedStatus = if ($barePathSeverity -eq 'validation-fail') { 'status: fail' } else { 'status: warn' }
$expectedExitCode = if ($barePathSeverity -eq 'validation-fail') { 1 } else { 0 }
$expectedBarePathToken = if ($barePathSeverity -eq 'validation-fail') { 'validation-fail.bare-path-in-boundary-handoff' } else { 'soft-warning.bare-path-in-boundary-handoff' }

foreach ($path in @($validatorScript, (Join-Path $fixtureIteration 'plan.md'), (Join-Path $fixtureIteration 'state.md'))) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Fail "Missing required artifact: $path"
        exit 1
    }
}

$warnResponse = @"
## What I just did
Updated FR-001 and $existingPlanUri quickly.

## Why I stopped
I stopped for the next step.

## What I need from you
Check C:\Dev\Specrew\specs\016-substantive-interaction-model\iterations\001\plan.md and let me know.

Reference: $missingUri
"@

$warnOutput = @(
    pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $repoRoot -IterationPath $fixtureIteration -ResponseText $warnResponse 2>&1
)
if ($LASTEXITCODE -ne $expectedExitCode) {
    Write-Fail ("validate-governance should return exit {0} for thin/bare-path handoff findings." -f $expectedExitCode)
    $warnOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$warnJoined = ($warnOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
foreach ($expected in @(
        $expectedStatus,
        'soft-warning.thin-what-i-just-did',
        'soft-warning.unspecific-stop-boundary',
        'soft-warning.unactionable-user-request',
        $expectedBarePathToken,
        'soft-warning.broken-file-url-reference'
    )) {
    if ($warnJoined -notmatch [regex]::Escape($expected)) {
        Write-Fail "Missing expected interaction-model warning '$expected'.`n$warnJoined"
        exit 1
    }
}

$passResponse = @"
## What I just did
I completed feature 016, substantive interaction model, across FR-001 through FR-019 and validated the retro-boundary handoff wording against the current rules. I aligned $existingPlanUri, $existingGateUri, and FR-010 with T011, decision-reference authorization-feature-016-iter-001-implementation, and commit abc1234 so the current stop stays substantive, clickable, and traceable without forcing the reviewer to open artifacts first.

## Why I stopped
I stopped at the retro-boundary because the active iteration fixture is already at retro-boundary, and Feature 016 still requires a separate authorization before any later closeout boundary can proceed.

## What I need from you
Review $existingPlanUri and $existingGateUri, then approve or reject advancement from the retro-boundary.
"@

$passOutput = @(
    pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $repoRoot -IterationPath $fixtureIteration -ResponseText $passResponse 2>&1
)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'validate-governance should not hard-fail on compliant Feature 016 handoff input.'
    $passOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$passJoined = ($passOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($passJoined -notmatch 'status: pass') {
    Write-Fail "Expected pass status for compliant Feature 016 handoff input.`n$passJoined"
    exit 1
}

foreach ($unexpected in @(
        'soft-warning.thin-what-i-just-did',
        'soft-warning.unspecific-stop-boundary',
        'soft-warning.unactionable-user-request',
        'soft-warning.bare-path-in-boundary-handoff',
        'soft-warning.broken-file-url-reference'
    )) {
    if ($passJoined -match [regex]::Escape($unexpected)) {
        Write-Fail "Did not expect '$unexpected' for compliant Feature 016 handoff input.`n$passJoined"
        exit 1
    }
}

$narrationResponse = 'I am still working, and the next note points at C:\Dev\Specrew\specs\016-substantive-interaction-model\spec.md while I continue the validator edits.'
$narrationOutput = @(
    pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $repoRoot -ResponseScope narration -ResponseText $narrationResponse 2>&1
)
if ($LASTEXITCODE -ne 0) {
    Write-Fail 'validate-governance should not hard-fail on narration bare-path warnings.'
    $narrationOutput | ForEach-Object { Write-Host $_ }
    exit 1
}

$narrationJoined = ($narrationOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if ($narrationJoined -notmatch 'soft-warning\.bare-path-in-narration') {
    Write-Fail "Expected bare-path-in-narration warning for narration fixture.`n$narrationJoined"
    exit 1
}

Write-Pass 'Feature 016 handoff and narration validation stays aligned for thin summaries, boundary specificity, actionable requests, and file:/// navigation'
exit 0
