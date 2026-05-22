[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function New-MinimalProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\022-hotfix-schema-tests\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/022-hotfix-schema-tests`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\022-hotfix-schema-tests\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed project' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 022-hotfix-schema-tests 2>&1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\lifecycle-boundary-sync'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# Ordered nine-boundary sync scenario
$orderedProject = Join-Path $scratchRoot 'ordered'
New-MinimalProject -ProjectRoot $orderedProject
foreach ($boundary in @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout')) {
    $syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $orderedProject, '-BoundaryType', $boundary, '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
    if ($syncResult.ExitCode -ne 0) {
        Write-Fail ("Boundary sync failed for '{0}':`n{1}" -f $boundary, ($syncResult.Output -join [Environment]::NewLine))
        exit 1
    }
}

$featureCloseoutResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $orderedProject, '-BoundaryType', 'feature-closeout', '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
if ($featureCloseoutResult.ExitCode -ne 0) {
    Write-Fail ("Feature closeout sync failed:`n{0}" -f ($featureCloseoutResult.Output -join [Environment]::NewLine))
    exit 1
}

$decisionsContent = Get-Content -LiteralPath (Join-Path $orderedProject '.squad\decisions.md') -Raw -Encoding UTF8
$boundaryMatches = [regex]::Matches($decisionsContent, 'Boundary sync:\s*(specify|clarify|plan|tasks|before-implement|review-signoff|retro|iteration-closeout|feature-closeout)')
$actualOrder = @($boundaryMatches | ForEach-Object { $_.Groups[1].Value })
$expectedOrder = @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')
if ($actualOrder.Count -ne $expectedOrder.Count -or (($actualOrder -join ',') -ne ($expectedOrder -join ','))) {
    Write-Fail ("Expected ordered boundary sync entries '{0}' but found '{1}'." -f ($expectedOrder -join ', '), ($actualOrder -join ', '))
    exit 1
}

if ($decisionsContent -match 'Auth Commit Hash\*\*:\s*HEAD') {
    Write-Fail 'Boundary sync ledger recorded the literal HEAD instead of a durable commit hash.'
    exit 1
}

$featureJson = Get-Content -LiteralPath (Join-Path $orderedProject '.specify\feature.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not [string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
    Write-Fail 'Feature closeout should clear .specify\feature.json only after syncing the closeout boundary.'
    exit 1
}

Write-Pass 'All nine lifecycle boundaries recorded ordered sync entries with durable commit hashes'

# Drift visibility scenario
$driftProject = Join-Path $scratchRoot 'drift'
New-MinimalProject -ProjectRoot $driftProject
foreach ($boundary in @('specify', 'clarify', 'plan', 'tasks')) {
    $syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $driftProject, '-BoundaryType', $boundary, '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
    if ($syncResult.ExitCode -ne 0) {
        Write-Fail ("Boundary sync failed for drift setup '{0}':`n{1}" -f $boundary, ($syncResult.Output -join [Environment]::NewLine))
        exit 1
    }
}

[System.IO.File]::WriteAllText((Join-Path $driftProject 'specs\022-hotfix-schema-tests\iterations\001\review.md'), @'
# Review: Iteration 001

**Schema**: v1
**Overall Verdict**: accepted
'@, [System.Text.UTF8Encoding]::new($false))

$staleResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $driftProject, '-NoLaunch', '-RecoveryChoice', 'C')
$staleOutput = $staleResult.Output -join [Environment]::NewLine
if ($staleOutput -notmatch 'Stale state detected' -or $staleOutput -notmatch 'Late boundary sync mismatch' -or $staleOutput -notmatch 'review-signoff') {
    Write-Fail ("Restart validation did not expose the late-boundary drift clearly:`n{0}" -f $staleOutput)
    exit 1
}

$warningResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $driftProject, '-BoundaryType', 'iteration-closeout', '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
if ($warningResult.ExitCode -ne 0) {
    Write-Fail ("Out-of-order iteration closeout sync failed:`n{0}" -f ($warningResult.Output -join [Environment]::NewLine))
    exit 1
}

$warningContent = Get-Content -LiteralPath (Join-Path $driftProject '.squad\decisions.md') -Raw -Encoding UTF8
if ($warningContent -notmatch 'Boundary sync warning:\s*iteration-closeout' -or $warningContent -notmatch 'Expected next boundary ''before-implement''') {
    Write-Fail 'Lifecycle evidence did not record the out-of-order late-boundary warning.'
    exit 1
}

Write-Pass 'Late-boundary drift remains visible through restart validation and ledger evidence'
exit 0
