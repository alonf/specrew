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
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\carry-forward-closed-iteration'
$fixtureProject = Join-Path $fixtureRoot 'project'
$scratchRoot = Join-Path $repoRoot '.scratch\carry-forward-closed-iteration'
$scriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1'

foreach ($requiredPath in @($fixtureProject, $scriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing carry-forward-closed-iteration dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$workspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'carry-forward-test'
$closedIteration = Join-Path $workspace 'specs\008-sample\iterations\001'
$nextIteration = Join-Path $workspace 'specs\008-sample\iterations\002'

Write-Host ''
Write-Host 'Closed-Iteration Carry-Forward Tests' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host ''

# Test 1: Closed iteration state remains unchanged
Write-Host 'Test 1: Closed iteration artifacts not reopened'
$closedStatePath = Join-Path $closedIteration 'state.md'
if (-not (Test-Path -LiteralPath $closedStatePath -PathType Leaf)) {
    Write-Fail "Closed iteration state file not found: $closedStatePath"
    exit 1
}
$closedStateContent = Get-Content -LiteralPath $closedStatePath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($closedStateContent -match '\*\*Status\*\*:\s+complete') -FailureMessage "Closed iteration status should remain 'complete'.")) { exit 1 }
if (-not (Assert-Condition -Condition ($closedStateContent -match '\*\*Carry Forward From Iteration\*\*:\s+iteration 001') -FailureMessage "Carry-forward marker not in closed iteration.")) { exit 1 }
Write-Pass "Closed iteration remains closed with carry-forward marker"

# Test 2: Ledger recorded the event
Write-Host 'Test 2: Event recorded in ledger with carry-forward reference'
$ledgerPath = Join-Path $workspace '.specrew\reviewer-regression-log.md'
if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
    Write-Fail "Ledger file not found: $ledgerPath"
    exit 1
}
$ledgerContent = Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($ledgerContent -match 'RRE-001') -FailureMessage "Event ID not in ledger.")) { exit 1 }
if (-not (Assert-Condition -Condition ($ledgerContent -match '\*\*Carry Forward Iteration\*\*:\s+`iteration 002`') -FailureMessage "Carry-forward iteration not in ledger.")) { exit 1 }
Write-Pass "Ledger contains event with carry-forward reference"

# Test 3: Next iteration receives projected state
Write-Host 'Test 3: Next active iteration receives projected escalation state'
$projectResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'project',
    '-ProjectRoot', $workspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $nextIteration
)
if (-not (Assert-Condition -Condition ($projectResult.ExitCode -eq 0) -FailureMessage "Project command failed.`n$($projectResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($null -ne $projectResult.Json) -FailureMessage "Project command did not return JSON.")) { exit 1 }
if (-not (Assert-Condition -Condition ($projectResult.Json.Status -eq 'active') -FailureMessage "Projected status should be 'active'.")) { exit 1 }
if (-not (Assert-Condition -Condition ($projectResult.Json.CurrentReviewerClass -eq 'claude') -FailureMessage "Projected reviewer class should be 'claude'.")) { exit 1 }
Write-Pass "Next iteration received projected escalation state"

# Test 4: Next iteration state file shows carry-forward
Write-Host 'Test 4: Next iteration state file reflects carry-forward'
$nextStatePath = Join-Path $nextIteration 'state.md'
if (-not (Test-Path -LiteralPath $nextStatePath -PathType Leaf)) {
    Write-Fail "Next iteration state file not found: $nextStatePath"
    exit 1
}
$nextStateContent = Get-Content -LiteralPath $nextStatePath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($nextStateContent -match '\*\*Carry Forward From Iteration\*\*:\s+iteration 001') -FailureMessage "Carry-forward source not in next iteration state.")) { exit 1 }
if (-not (Assert-Condition -Condition ($nextStateContent -match '- \*\*Status\*\*:\s+active') -FailureMessage "Next iteration state should be 'active'.")) { exit 1 }
Write-Pass "Next iteration state file reflects carry-forward correctly"

Write-Host ''
Write-Host 'All carry-forward tests passed successfully' -ForegroundColor Green
exit 0
