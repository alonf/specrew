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
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function New-TestProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\020-session-state-durability\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/020-session-state-durability`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\020-session-state-durability\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed repository' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 020-session-state-durability 2>&1

    return (Join-Path $ProjectRoot 'specs\020-session-state-durability')
}

function Sync-PlanBoundary {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$SyncScript
    )

    $syncResult = Invoke-TestScript -ScriptPath $SyncScript -ArgumentList @(
        '-ProjectPath', $ProjectRoot,
        '-BoundaryType', 'plan',
        '-FeatureRef', '020-session-state-durability',
        '-IterationNumber', '001',
        '-AuthCommitHash', 'HEAD'
    )

    if ($syncResult.ExitCode -ne 0) {
        throw ("Boundary sync failed:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\stale-state-detection'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# Scenario 1: all checks pass
$goodProject = Join-Path $scratchRoot 'good'
New-TestProject -ProjectRoot $goodProject | Out-Null
Sync-PlanBoundary -ProjectRoot $goodProject -SyncScript $syncScript
$goodResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $goodProject, '-NoLaunch')
if ($goodResult.ExitCode -ne 0) {
    Write-Fail ("Good-state start unexpectedly failed:`n{0}" -f ($goodResult.Output -join [Environment]::NewLine))
    exit 1
}
Write-Pass 'Good-state session resumes without false positives'

# Scenario 2: branch missing
$missingBranchProject = Join-Path $scratchRoot 'missing-branch'
New-TestProject -ProjectRoot $missingBranchProject | Out-Null
Sync-PlanBoundary -ProjectRoot $missingBranchProject -SyncScript $syncScript
$null = & git -C $missingBranchProject checkout -b scratch 2>&1
$null = & git -C $missingBranchProject branch -D 020-session-state-durability 2>&1
$missingBranchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $missingBranchProject, '-NoLaunch', '-RecoveryChoice', 'C')
if ($missingBranchResult.ExitCode -ne 0 -or (($missingBranchResult.Output -join [Environment]::NewLine) -notmatch 'Stale state detected' -or ($missingBranchResult.Output -join [Environment]::NewLine) -notmatch 'Feature branch is missing')) {
    Write-Fail 'Missing-branch scenario did not surface the expected stale-state recovery guidance.'
    exit 1
}
Write-Pass 'Missing branch is reported through stale-state recovery guidance'

# Scenario 3: authorization record missing
$missingAuthProject = Join-Path $scratchRoot 'missing-auth'
New-TestProject -ProjectRoot $missingAuthProject | Out-Null
Sync-PlanBoundary -ProjectRoot $missingAuthProject -SyncScript $syncScript
[System.IO.File]::WriteAllText((Join-Path $missingAuthProject '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
$missingAuthResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $missingAuthProject, '-NoLaunch', '-RecoveryChoice', 'C')
if ($missingAuthResult.ExitCode -ne 0 -or (($missingAuthResult.Output -join [Environment]::NewLine) -notmatch 'Stale state detected' -or ($missingAuthResult.Output -join [Environment]::NewLine) -notmatch 'Authorization record missing')) {
    Write-Fail 'Missing-authorization scenario did not surface the expected stale-state recovery guidance.'
    exit 1
}
Write-Pass 'Missing authorization record is reported through stale-state recovery guidance'

# Scenario 4: cross-file mismatch
$mismatchProject = Join-Path $scratchRoot 'mismatch'
New-TestProject -ProjectRoot $mismatchProject | Out-Null
Sync-PlanBoundary -ProjectRoot $mismatchProject -SyncScript $syncScript
$identityPath = Join-Path $mismatchProject '.squad\identity\now.md'
$identityContent = (Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8) -replace 'session_state_boundary:\s*plan', 'session_state_boundary: clarify'
[System.IO.File]::WriteAllText($identityPath, $identityContent, [System.Text.UTF8Encoding]::new($false))
$mismatchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $mismatchProject, '-NoLaunch', '-RecoveryChoice', 'C')
if ($mismatchResult.ExitCode -ne 0 -or (($mismatchResult.Output -join [Environment]::NewLine) -notmatch 'Stale state detected' -or ($mismatchResult.Output -join [Environment]::NewLine) -notmatch 'boundary mismatch')) {
    Write-Fail 'Cross-file mismatch scenario did not surface the expected stale-state recovery guidance.'
    exit 1
}
Write-Pass 'Cross-file mismatch is reported through stale-state recovery guidance'

# Scenario 5: merged feature detected on main
$mergedProject = Join-Path $scratchRoot 'merged'
New-TestProject -ProjectRoot $mergedProject | Out-Null
Sync-PlanBoundary -ProjectRoot $mergedProject -SyncScript $syncScript
$null = & git -C $mergedProject add -A 2>&1
$null = & git -C $mergedProject commit -m 'Record plan boundary state' --quiet 2>&1
$null = & git -C $mergedProject checkout main 2>&1
$null = & git -C $mergedProject merge --no-ff 020-session-state-durability -m 'Merge feature 020' 2>&1
$mergedResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $mergedProject, '-NoLaunch', '-RecoveryChoice', 'C')
if ($mergedResult.ExitCode -ne 0 -or (($mergedResult.Output -join [Environment]::NewLine) -notmatch 'Stale state detected' -or ($mergedResult.Output -join [Environment]::NewLine) -notmatch 'merge history on main')) {
    Write-Fail 'Merged-feature scenario did not surface the expected stale-state recovery guidance.'
    exit 1
}
Write-Pass 'Merged feature is reported through stale-state recovery guidance'

exit 0
