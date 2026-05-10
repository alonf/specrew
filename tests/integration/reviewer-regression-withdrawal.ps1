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
    if (Test-Path -LiteralPath $workspace) {
        Remove-Item -LiteralPath $workspace -Recurse -Force
    }
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
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\reviewer-regression-withdrawal'
$fixtureProject = Join-Path $fixtureRoot 'project'
$scratchRoot = Join-Path $repoRoot '.scratch\reviewer-regression-withdrawal'
$scriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1'

foreach ($requiredPath in @($fixtureProject, $scriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing reviewer-regression-withdrawal dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$workspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'withdrawal-test'
$iterationDirectory = Join-Path $workspace 'specs\008-sample\iterations\001'

Write-Host ''
Write-Host 'Reviewer Regression Withdrawal Tests' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host ''

# Test 1: Withdrawal reverses only pending escalation state
Write-Host 'Test 1: Withdrawal reverses pending escalation state'
$withdrawResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'withdraw',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-EventId', 'RRE-001',
    '-IterationDirectory', $iterationDirectory
)
if (-not (Assert-Condition -Condition ($withdrawResult.ExitCode -eq 0) -FailureMessage "Withdrawal command failed.`n$($withdrawResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($null -ne $withdrawResult.Json) -FailureMessage "Withdrawal command did not return JSON.")) { exit 1 }
if (-not (Assert-Condition -Condition ($withdrawResult.Json.EventId -eq 'RRE-001') -FailureMessage "Withdrawal event ID mismatch.")) { exit 1 }
if (-not (Assert-Condition -Condition ($withdrawResult.Json.Withdrawn -eq $true) -FailureMessage "Withdrawal flag not set.")) { exit 1 }
Write-Pass "Withdrawal command executed and returned expected structure"

# Test 2: Ledger preserves audit trail with withdrawal marker
Write-Host 'Test 2: Ledger preserves withdrawal audit trail'
$ledgerPath = Join-Path $workspace '.specrew\reviewer-regression-log.md'
if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
    Write-Fail "Ledger file not found: $ledgerPath"
    exit 1
}
$ledgerContent = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($ledgerContent -match 'RRE-001') -FailureMessage "Original event ID not in ledger.")) { exit 1 }
if (-not (Assert-Condition -Condition ($ledgerContent -match '(?i)(withdrawn|misreport)') -FailureMessage "Withdrawal marker not in ledger.")) { exit 1 }
Write-Pass "Ledger preserves withdrawal audit trail"

# Test 3: Escalation state reverted in managed block
Write-Host 'Test 3: Escalation state reverted after withdrawal'
$stateFilePath = Join-Path $iterationDirectory 'state.md'
if (-not (Test-Path -LiteralPath $stateFilePath -PathType Leaf)) {
    Write-Fail "State file not found: $stateFilePath"
    exit 1
}
$stateContent = Get-Content -LiteralPath $stateFilePath -Raw -Encoding UTF8
# After withdrawal, the reviewer-regression state should be reverted (status should be inactive or resolved, not active)
if (-not (Assert-Condition -Condition ($stateContent -match '- \*\*Status\*\*:\s+(inactive|resolved)') -FailureMessage "State block status not reverted after withdrawal.")) { exit 1 }
Write-Pass "Escalation state reverted after withdrawal"

# Test 4: Duplicate withdrawal detection
Write-Host 'Test 4: Duplicate withdrawal attempt is handled gracefully'
$dupWithdrawResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'withdraw',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-EventId', 'RRE-001',
    '-IterationDirectory', $iterationDirectory
)
# Should succeed but indicate already withdrawn or no-op
if (-not (Assert-Condition -Condition ($dupWithdrawResult.ExitCode -eq 0) -FailureMessage "Duplicate withdrawal failed unexpectedly.`n$($dupWithdrawResult.Text)")) { exit 1 }
Write-Pass "Duplicate withdrawal handled gracefully"

Write-Host ''
Write-Host 'All withdrawal tests passed successfully' -ForegroundColor Green
exit 0
