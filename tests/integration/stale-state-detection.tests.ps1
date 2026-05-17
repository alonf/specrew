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
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InitScript
    )

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    $initResult = Invoke-TestScript -ScriptPath $InitScript -ArgumentList @('-ProjectPath', $ProjectRoot, '-Force', '-NoAgents')
    if ($initResult.ExitCode -ne 0) {
        throw ("Bootstrap failed:`n{0}" -f ($initResult.Output -join [Environment]::NewLine))
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed repository' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 020-session-state-durability 2>&1

    $featureDirectory = Join-Path $ProjectRoot 'specs\020-session-state-durability'
    $iterationDirectory = Join-Path $featureDirectory 'iterations\001'
    $null = New-Item -ItemType Directory -Path $iterationDirectory -Force
    [System.IO.File]::WriteAllText((Join-Path $featureDirectory 'spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/020-session-state-durability`"`n}", [System.Text.UTF8Encoding]::new($false))
    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    $configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    $configContent = $configContent -replace 'bootstrap_date:\s*"[^"]+"', 'bootstrap_date: "2026-01-01"'
    [System.IO.File]::WriteAllText($configPath, $configContent, [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed feature files' --quiet 2>&1

    return $featureDirectory
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
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\stale-state-detection'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# Scenario 1: all checks pass
$goodProject = Join-Path $scratchRoot 'good'
New-TestProject -ProjectRoot $goodProject -InitScript $initScript | Out-Null
Sync-PlanBoundary -ProjectRoot $goodProject -SyncScript $syncScript
$goodResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $goodProject, '-NoLaunch')
if ($goodResult.ExitCode -ne 0) {
    Write-Fail ("Good-state start unexpectedly failed:`n{0}" -f ($goodResult.Output -join [Environment]::NewLine))
    exit 1
}
Write-Pass 'Good-state session resumes without false positives'

# Scenario 2: branch missing
$missingBranchProject = Join-Path $scratchRoot 'missing-branch'
New-TestProject -ProjectRoot $missingBranchProject -InitScript $initScript | Out-Null
Sync-PlanBoundary -ProjectRoot $missingBranchProject -SyncScript $syncScript
$null = & git -C $missingBranchProject checkout -b scratch 2>&1
$null = & git -C $missingBranchProject branch -D 020-session-state-durability 2>&1
$missingBranchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $missingBranchProject, '-NoLaunch')
if ($missingBranchResult.ExitCode -eq 0 -or (($missingBranchResult.Output -join [Environment]::NewLine) -notmatch 'Feature branch is missing')) {
    Write-Fail 'Missing-branch scenario did not produce the expected stale-state failure.'
    exit 1
}
Write-Pass 'Missing branch is reported as stale state'

# Scenario 3: authorization record missing
$missingAuthProject = Join-Path $scratchRoot 'missing-auth'
New-TestProject -ProjectRoot $missingAuthProject -InitScript $initScript | Out-Null
Sync-PlanBoundary -ProjectRoot $missingAuthProject -SyncScript $syncScript
[System.IO.File]::WriteAllText((Join-Path $missingAuthProject '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
$missingAuthResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $missingAuthProject, '-NoLaunch')
if ($missingAuthResult.ExitCode -eq 0 -or (($missingAuthResult.Output -join [Environment]::NewLine) -notmatch 'Authorization record missing')) {
    Write-Fail 'Missing-authorization scenario did not produce the expected stale-state failure.'
    exit 1
}
Write-Pass 'Missing authorization record is reported as stale state'

# Scenario 4: cross-file mismatch
$mismatchProject = Join-Path $scratchRoot 'mismatch'
New-TestProject -ProjectRoot $mismatchProject -InitScript $initScript | Out-Null
Sync-PlanBoundary -ProjectRoot $mismatchProject -SyncScript $syncScript
$identityPath = Join-Path $mismatchProject '.squad\identity\now.md'
$identityContent = (Get-Content -LiteralPath $identityPath -Raw -Encoding UTF8) -replace 'session_state_boundary:\s*plan', 'session_state_boundary: clarify'
[System.IO.File]::WriteAllText($identityPath, $identityContent, [System.Text.UTF8Encoding]::new($false))
$mismatchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $mismatchProject, '-NoLaunch')
if ($mismatchResult.ExitCode -eq 0 -or (($mismatchResult.Output -join [Environment]::NewLine) -notmatch 'boundary mismatch')) {
    Write-Fail 'Cross-file mismatch scenario did not produce the expected stale-state failure.'
    exit 1
}
Write-Pass 'Cross-file mismatch is reported as stale state'

# Scenario 5: merged feature detected on main
$mergedProject = Join-Path $scratchRoot 'merged'
New-TestProject -ProjectRoot $mergedProject -InitScript $initScript | Out-Null
Sync-PlanBoundary -ProjectRoot $mergedProject -SyncScript $syncScript
$null = & git -C $mergedProject add -A 2>&1
$null = & git -C $mergedProject commit -m 'Record plan boundary state' --quiet 2>&1
$null = & git -C $mergedProject checkout main 2>&1
$null = & git -C $mergedProject merge --no-ff 020-session-state-durability -m 'Merge feature 020' 2>&1
$mergedResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $mergedProject, '-NoLaunch')
if ($mergedResult.ExitCode -eq 0 -or (($mergedResult.Output -join [Environment]::NewLine) -notmatch 'merge history on main')) {
    Write-Fail 'Merged-feature scenario did not produce the expected stale-state failure.'
    exit 1
}
Write-Pass 'Merged feature is reported as stale state'

exit 0
