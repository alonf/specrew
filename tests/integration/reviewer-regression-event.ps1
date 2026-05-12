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
$scratchRoot = Join-Path $repoRoot '.scratch\reviewer-regression-event'
$scriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1'

foreach ($requiredPath in @($fixtureProject, $scriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing reviewer-regression-event dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$strongerWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'stronger-class'
$fallbackWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'same-class-and-hold'
$strongerIteration = Join-Path $strongerWorkspace 'specs\008-sample\iterations\001'
$fallbackIteration = Join-Path $fallbackWorkspace 'specs\008-sample\iterations\001'

Write-Host 'Test 1: stronger-class routing selects the next stronger reviewer tier'
$strongerResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $strongerWorkspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $strongerIteration,
    '-Slice', 'iteration 001 stronger-class slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'copilot',
    '-PriorReviewerOwner', 'copilot-reviewer',
    '-DefectDescription', 'The approved slice missed a reviewer-visible defect.',
    '-DefectSourceLocation', 'src/app.js:10'
)
if (-not (Assert-Condition -Condition ($strongerResult.ExitCode -eq 0) -FailureMessage "Stronger-class report failed.`n$($strongerResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerResult.Json.EventId -eq 'RRE-001') -FailureMessage 'First stronger-class event should allocate RRE-001.')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerResult.Json.Duplicate -eq $false) -FailureMessage 'First stronger-class event should not be marked duplicate.')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerResult.Json.Routing.Action -eq 'stronger-class') -FailureMessage 'Stronger-class scenario should route to a stronger class.')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerResult.Json.Routing.CurrentReviewerClass -eq 'claude') -FailureMessage 'Stronger-class scenario should choose the next stronger class (claude).')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerResult.Json.Routing.CurrentReviewerOwner -eq 'claude-reviewer') -FailureMessage 'Stronger-class scenario should pick the eligible claude reviewer owner.')) { exit 1 }

$strongerDecisions = Get-Content -LiteralPath (Join-Path $strongerWorkspace '.squad\decisions.md') -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($strongerDecisions -match 'reviewer-regression-escalation') -FailureMessage 'Stronger-class scenario should record a reviewer-regression escalation decision.')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerDecisions -match 'Selected Reviewer Class\*\*:\s*claude') -FailureMessage 'Decision log should record the selected stronger reviewer class.')) { exit 1 }
if (-not (Assert-Condition -Condition ($strongerDecisions -match 'Selected Reviewer Owner\*\*:\s*claude-reviewer') -FailureMessage 'Decision log should record the selected stronger reviewer owner.')) { exit 1 }

Write-Pass 'Stronger-class routing records the event and picks the next stronger reviewer tier'

Write-Host "`nTest 2: same-class fallback chooses an independent owner when no stronger class exists"
$fallbackResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $fallbackWorkspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $fallbackIteration,
    '-Slice', 'iteration 001 same-class fallback slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'codex',
    '-PriorReviewerOwner', 'codex-reviewer-a',
    '-DefectDescription', 'The strongest-class reviewer missed a follow-up defect.',
    '-DefectSourceLocation', 'src/app.js:20'
)
if (-not (Assert-Condition -Condition ($fallbackResult.ExitCode -eq 0) -FailureMessage "Same-class fallback report failed.`n$($fallbackResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($fallbackResult.Json.Routing.Action -eq 'same-class-independent-owner') -FailureMessage 'Same-class fallback scenario should route to an independent owner at the same class.')) { exit 1 }
if (-not (Assert-Condition -Condition ($fallbackResult.Json.Routing.CurrentReviewerClass -eq 'codex') -FailureMessage 'Same-class fallback should stay at the codex class.')) { exit 1 }
if (-not (Assert-Condition -Condition ($fallbackResult.Json.Routing.CurrentReviewerOwner -eq 'codex-reviewer-b') -FailureMessage 'Same-class fallback should choose the unused codex reviewer owner.')) { exit 1 }

Write-Pass 'Same-class fallback prefers an independent unused owner at the same class'

Write-Host "`nTest 3: maximum-strength routing holds for human direction when no independent owner remains"
$fallbackAssignmentsPath = Join-Path $fallbackWorkspace '.specrew\role-assignments.yml'
$fallbackAssignments = Get-Content -LiteralPath $fallbackAssignmentsPath -Raw -Encoding UTF8
$fallbackAssignments = [regex]::Replace(
    $fallbackAssignments,
    '(?s)(- role: Reviewer\s+agent: codex-reviewer-a\s+reasoning_class: codex\s+eligible: )true',
    '${1}false'
)
[System.IO.File]::WriteAllText($fallbackAssignmentsPath, $fallbackAssignments, [System.Text.UTF8Encoding]::new($false))

$holdResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $fallbackWorkspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $fallbackIteration,
    '-Slice', 'iteration 001 maximum-strength hold slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'codex',
    '-PriorReviewerOwner', 'codex-reviewer-b',
    '-DefectDescription', 'A second codex-reviewed defect leaves no safe reviewer route.',
    '-DefectSourceLocation', 'src/app.js:30'
)
if (-not (Assert-Condition -Condition ($holdResult.ExitCode -eq 0) -FailureMessage "Maximum-strength hold report failed.`n$($holdResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($holdResult.Json.Routing.Action -eq 'human-direction-hold') -FailureMessage 'Maximum-strength scenario should hold for human direction.')) { exit 1 }
if (-not (Assert-Condition -Condition ($holdResult.Json.Routing.Status -eq 'held') -FailureMessage 'Maximum-strength scenario should return held status.')) { exit 1 }
if (-not (Assert-Condition -Condition ($holdResult.Json.Routing.CurrentReviewerOwner -eq $null) -FailureMessage 'Human-direction hold should not pick another reviewer owner.')) { exit 1 }

$holdDecisions = Get-Content -LiteralPath (Join-Path $fallbackWorkspace '.squad\decisions.md') -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($holdDecisions -match 'Routing Outcome\*\*:\s*human-direction-hold') -FailureMessage 'Hold scenario should record a human-direction hold decision.')) { exit 1 }

Write-Pass 'Maximum-strength routing records the hold when no independent reviewer remains'

Write-Host "`nTest 4: duplicate reports reuse the active chain instead of appending a second event"
$duplicateResult = Invoke-RegressionCommand -ScriptPath $scriptPath -ArgumentList @(
    '-Mode', 'report',
    '-ProjectRoot', $strongerWorkspace,
    '-Feature', 'specs/008-sample',
    '-IterationDirectory', $strongerIteration,
    '-Slice', 'iteration 001 stronger-class slice',
    '-PriorReviewerVerdict', 'approved',
    '-PriorReviewerClass', 'copilot',
    '-PriorReviewerOwner', 'copilot-reviewer',
    '-DefectDescription', 'The approved slice missed a reviewer-visible defect.',
    '-DefectSourceLocation', 'src/app.js:10'
)
if (-not (Assert-Condition -Condition ($duplicateResult.ExitCode -eq 0) -FailureMessage "Duplicate report failed.`n$($duplicateResult.Text)")) { exit 1 }
if (-not (Assert-Condition -Condition ($duplicateResult.Json.Duplicate -eq $true) -FailureMessage 'Duplicate report should be marked as a duplicate.')) { exit 1 }
if (-not (Assert-Condition -Condition ($duplicateResult.Json.EventId -eq 'RRE-001') -FailureMessage 'Duplicate report should reuse the existing event identifier.')) { exit 1 }

$ledgerEntries = @((Get-Content -LiteralPath (Join-Path $strongerWorkspace '.specrew\reviewer-regression-log.md') -Encoding UTF8) | Where-Object { $_ -match '^###\s+RRE-' })
if (-not (Assert-Condition -Condition ($ledgerEntries.Count -eq 1) -FailureMessage 'Duplicate report should not append a second ledger event.')) { exit 1 }

Write-Pass 'Duplicate reports reuse the existing active reviewer-regression chain'
exit 0
