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

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScratchRoot,
        [Parameter(Mandatory = $true)]
        [string]$FixtureProjectPath,
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceName
    )

    $workspace = Join-Path $ScratchRoot $WorkspaceName
    Copy-Item -LiteralPath $FixtureProjectPath -Destination $workspace -Recurse -Force
    return $workspace
}

function Invoke-RegressionCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    $text = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    return @{
        ExitCode = $LASTEXITCODE
        Text     = $text
        Json     = if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($text)) { $text | ConvertFrom-Json } else { $null }
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\reviewer-regression-event'
$fixtureProject = Join-Path $fixtureRoot 'project'
$scratchRoot = Join-Path $repoRoot '.scratch\reviewer-regression-ledger'
$scriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1'
$validatorPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'

foreach ($requiredPath in @($fixtureProject, $scriptPath, $validatorPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing reviewer-regression-ledger dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$workspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'active-chain'
$iterationDirectory = Join-Path $workspace 'specs\008-sample\iterations\001'

Write-Host 'Test 1: ledger entries preserve the agreed reviewer-regression schema'
$firstResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $iterationDirectory,
    '-Slice', 'iteration 001 ledger baseline slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'codex',
    '-PriorReviewerOwner', 'codex-reviewer-a',
    '-DefectDescription', 'The first codex-reviewed slice missed a regression detail.',
    '-DefectSourceLocation', 'src/app.js:20'
)
if (-not (Assert-Condition -Condition ($firstResult.ExitCode -eq 0) -FailureMessage "Initial ledger event failed.`n$($firstResult.Text)")) { exit 1 }

$ledgerPath = Join-Path $workspace '.specrew\reviewer-regression-log.md'
$ledgerText = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
foreach ($pattern in @(
        '### RRE-001',
        '\*\*Feature\*\*:\s*`specs/008-sample`',
        '\*\*Event Status\*\*:\s*`active`',
        '\*\*Severity\*\*:\s*`soft-warning`',
        '\*\*Escalation Action\*\*:\s*`same-class-independent-owner`',
        '\*\*Same-Class Fallback Owner\*\*:\s*`codex-reviewer-b`'
    )) {
    if (-not (Assert-Condition -Condition ($ledgerText -match $pattern) -FailureMessage "Ledger entry is missing expected reviewer-regression field: $pattern")) { exit 1 }
}

Write-Pass 'Reviewer-regression ledger entries preserve the expected schema and routing evidence'

Write-Host "`nTest 2: active-chain readback preserves the strongest unresolved routing outcome"
$assignmentsPath = Join-Path $workspace '.specrew\role-assignments.yml'
$assignmentsText = Get-Content -LiteralPath $assignmentsPath -Raw -Encoding UTF8
$assignmentsText = [regex]::Replace(
    $assignmentsText,
    '(?s)(- role: Reviewer\s+agent: codex-reviewer-a\s+reasoning_class: codex\s+eligible: )true',
    '${1}false'
)
[System.IO.File]::WriteAllText($assignmentsPath, $assignmentsText, [System.Text.UTF8Encoding]::new($false))

$secondResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $iterationDirectory,
    '-Slice', 'iteration 001 held slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'codex',
    '-PriorReviewerOwner', 'codex-reviewer-b',
    '-DefectDescription', 'A second codex-reviewed miss leaves no independent owner.',
    '-DefectSourceLocation', 'src/app.js:30'
)
if (-not (Assert-Condition -Condition ($secondResult.ExitCode -eq 0) -FailureMessage "Held ledger event failed.`n$($secondResult.Text)")) { exit 1 }

$getResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'get',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample'
)
if (-not (Assert-Condition -Condition ($getResult.ExitCode -eq 0) -FailureMessage "Get mode failed.`n$($getResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($getResult.Json.Status -eq 'held') -FailureMessage 'Active chain should report held status after the maximum-strength hold event.')) { exit 1 }
if (-not (Assert-Condition -Condition ($getResult.Json.StrongestUnresolvedAction -eq 'human-direction-hold') -FailureMessage 'Active chain should preserve the strongest unresolved action.')) { exit 1 }
if (-not (Assert-Condition -Condition ($getResult.Json.CleanPassesRequired -eq 1) -FailureMessage 'Active chain readback should preserve the configured clean-pass threshold.')) { exit 1 }
if (-not (Assert-Condition -Condition ($getResult.Json.ActiveEventIds.Count -eq 2) -FailureMessage 'Active chain should include both unresolved event identifiers.')) { exit 1 }

Write-Pass 'Active-chain readback preserves the strongest unresolved routing outcome and clean-pass threshold'

Write-Host "`nTest 3: project mode writes the reviewer-regression state mirror back to the active iteration"
$projectResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'project',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $iterationDirectory
)
if (-not (Assert-Condition -Condition ($projectResult.ExitCode -eq 0) -FailureMessage "Project mode failed.`n$($projectResult.Text)")) { exit 1 }

$stateText = Get-Content -LiteralPath (Join-Path $iterationDirectory 'state.md') -Raw -Encoding UTF8
foreach ($pattern in @(
        '\*\*Status\*\*:\s*held',
        '\*\*Feature\*\*:\s*specs/008-sample',
        '\*\*Active Event IDs\*\*:\s*RRE-001, RRE-002',
        '\*\*Current Reviewer Class\*\*:\s*codex',
        '\*\*Lockout Cap\*\*:\s*2',
        '\*\*Cap Active\*\*:\s*false',
        '\*\*Notes\*\*:\s*Awaiting explicit human direction before review continues\.'
    )) {
    if (-not (Assert-Condition -Condition ($stateText -match $pattern) -FailureMessage "Projected state block is missing expected reviewer-regression field: $pattern")) { exit 1 }
}

Write-Pass 'Project mode writes the reviewer-regression state mirror back to the active iteration'

Write-Host "`nTest 4: governance validation accepts the reviewer-regression ledger and projection artifacts"
$validatorOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectPath $workspace -IterationPath $iterationDirectory 2>&1)
$validatorText = ($validatorOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
if (-not (Assert-Condition -Condition ($LASTEXITCODE -eq 0) -FailureMessage "Governance validation should accept the reviewer-regression fixtures and projections.`n$validatorText")) { exit 1 }

$decisionText = Get-Content -LiteralPath (Join-Path $workspace '.squad\decisions.md') -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition (([regex]::Matches($decisionText, '- \*\*Type\*\*: reviewer-regression-escalation')).Count -eq 2) -FailureMessage 'Reviewer-regression decisions should be recorded for both unresolved events.')) { exit 1 }

Write-Pass 'Governance validation accepts the reviewer-regression ledger and projection artifacts'

Write-Host "`nTest 5: duplicate event detection prevents redundant escalation entries"
$duplicateResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $iterationDirectory,
    '-Slice', 'iteration 001 ledger baseline slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'codex',
    '-PriorReviewerOwner', 'codex-reviewer-a',
    '-DefectDescription', 'The first codex-reviewed slice missed a regression detail.',
    '-DefectSourceLocation', 'src/app.js:20'
)
if (-not (Assert-Condition -Condition ($duplicateResult.ExitCode -eq 0) -FailureMessage "Duplicate report command failed.`n$($duplicateResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($duplicateResult.Json.Duplicate -eq $true) -FailureMessage 'Duplicate detection flag should be true for identical event.')) { exit 1 }
if (-not (Assert-Condition -Condition ($duplicateResult.Json.EventId -eq 'RRE-001') -FailureMessage 'Duplicate report should return original event ID.')) { exit 1 }

Write-Pass 'Duplicate event detection prevents redundant escalation entries'

Write-Host "`nTest 6: corpus-disabled path does not offer candidate traps"
$configPath = Join-Path $workspace '.specrew\iteration-config.yml'
$configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($configText -match 'known_traps_integration:\s*false') -FailureMessage 'Fixture should have corpus disabled.')) { exit 1 }

$ledgerAfterDuplicate = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
$trapCount = ([regex]::Matches($ledgerAfterDuplicate, '\*\*Candidate Trap Status\*\*:\s*`(?!not-applicable)')).Count
if (-not (Assert-Condition -Condition ($trapCount -eq 0) -FailureMessage 'Corpus-disabled fixture should not propose candidate traps.')) { exit 1 }

Write-Pass 'Corpus-disabled path does not offer candidate traps'

exit 0
