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

function Invoke-TestScriptWithInput {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$InputText
    )

    $output = @($InputText | & pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function New-TestProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\051-multi-session-foundation\iterations\002')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/051-multi-session-foundation`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\051-multi-session-foundation\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed repository' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 051-multi-session-foundation 2>&1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$env:SPECREW_MODULE_PATH = $repoRoot
. (Join-Path $repoRoot 'scripts\internal\session-management.ps1')
. (Join-Path $repoRoot 'scripts\internal\feature-claims.ps1')

$scratchRoot = Join-Path $repoRoot '.scratch\feature-051-callsite-wiring'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

$projectRoot = Join-Path $scratchRoot 'repo'
New-TestProject -ProjectRoot $projectRoot

$specifyResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'specify',
    '-FeatureRef', '051-multi-session-foundation',
    '-IterationNumber', '002',
    '-AuthCommitHash', 'HEAD'
)
if ($specifyResult.ExitCode -ne 0) {
    Write-Fail ("Specify sync failed:`n{0}" -f ($specifyResult.Output -join [Environment]::NewLine))
    exit 1
}

$claims = @(Read-FeatureClaims -ProjectRoot $projectRoot)
if ($claims.Count -ne 1 -or $claims[0].feature_id -ne '051-multi-session-foundation') {
    Write-Fail 'Specify boundary did not add the feature claim.'
    exit 1
}
$firstRefresh = [string]$claims[0].last_refresh_time
Write-Pass 'Specify boundary adds the active feature claim'

Start-Sleep -Seconds 1
$planResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'plan',
    '-FeatureRef', '051-multi-session-foundation',
    '-IterationNumber', '002',
    '-AuthCommitHash', 'HEAD'
)
if ($planResult.ExitCode -ne 0) {
    Write-Fail ("Plan sync failed:`n{0}" -f ($planResult.Output -join [Environment]::NewLine))
    exit 1
}

$claims = @(Read-FeatureClaims -ProjectRoot $projectRoot)
if ($claims.Count -ne 1 -or [string]$claims[0].last_refresh_time -le $firstRefresh) {
    Write-Fail 'Plan boundary did not refresh the feature claim monotonically.'
    exit 1
}
Write-Pass 'Boundary sync refreshes the feature claim'

Register-SessionLock -ProjectRoot $projectRoot -FeatureId '051-multi-session-foundation' -User 'stale' -Fingerprint 'STALE-HOST' -NowUtc '2026-05-29T00:00:00Z'
Register-SessionLock -ProjectRoot $projectRoot -FeatureId '051-multi-session-foundation' -User 'other' -Fingerprint 'OTHER-HOST' -NowUtc (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch', '-SkipUpdateCheck')
if ($startResult.ExitCode -ne 0) {
    Write-Fail ("specrew start failed:`n{0}" -f ($startResult.Output -join [Environment]::NewLine))
    exit 1
}
$startOutput = $startResult.Output -join [Environment]::NewLine
if ($startOutput -notmatch 'Cleared 1 stale active session lock' -or $startOutput -notmatch 'Another active session detected') {
    Write-Fail 'specrew start did not surface stale-lock clearing and collision warning.'
    exit 1
}
$sessions = @(Read-ActiveSessions -ProjectRoot $projectRoot)
if ($sessions.Count -lt 2) {
    Write-Fail 'specrew start did not register the current session lock.'
    exit 1
}
Write-Pass 'specrew start clears stale locks, warns on collisions, and registers a session lock'

$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Record active feature claim and session lock' --quiet 2>&1
$null = & git -C $projectRoot checkout main 2>&1
$null = & git -C $projectRoot merge --no-ff 051-multi-session-foundation -m 'Merge pull request #999 from alonf/051-multi-session-foundation' 2>&1

$closeoutResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $projectRoot,
    '-BoundaryType', 'feature-closeout',
    '-FeatureRef', '051-multi-session-foundation',
    '-IterationNumber', '002',
    '-AuthCommitHash', 'HEAD'
)
if ($closeoutResult.ExitCode -ne 0) {
    Write-Fail ("Feature closeout sync failed:`n{0}" -f ($closeoutResult.Output -join [Environment]::NewLine))
    exit 1
}
if ((@(Read-FeatureClaims -ProjectRoot $projectRoot)).Count -ne 0) {
    Write-Fail 'Feature closeout did not remove the merged feature claim.'
    exit 1
}
if ((@(Read-ActiveSessions -ProjectRoot $projectRoot | Where-Object { $_.feature_id -eq '051-multi-session-foundation' })).Count -ne 0) {
    Write-Fail 'Feature closeout did not remove active session locks for the feature.'
    exit 1
}
Write-Pass 'Feature closeout removes merged feature claims and active session locks'

$conflictProjectRoot = Join-Path $scratchRoot 'claim-conflict'
New-TestProject -ProjectRoot $conflictProjectRoot
$null = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $conflictProjectRoot,
    '-BoundaryType', 'plan',
    '-FeatureRef', '051-multi-session-foundation',
    '-IterationNumber', '002',
    '-AuthCommitHash', 'HEAD'
)
Write-FeatureClaims -ProjectRoot $conflictProjectRoot -Claims @()
Add-FeatureClaim -ProjectRoot $conflictProjectRoot -FeatureId '051-multi-session-foundation' -ClaimedBy 'other@HOST-B' -BranchName '051-multi-session-foundation' -NowUtc '2026-05-31T00:00:00Z'

$declineResult = Invoke-TestScriptWithInput -ScriptPath $startScript -ArgumentList @('-ProjectPath', $conflictProjectRoot, '-NoLaunch', '-SkipUpdateCheck') -InputText 'n'
if ($declineResult.ExitCode -ne 2 -or (@(Read-ActiveSessions -ProjectRoot $conflictProjectRoot).Count -ne 0)) {
    Write-Fail 'Concurrent-claim decline did not exit without recording a session lock.'
    exit 1
}
Write-Pass 'Concurrent-claim decline exits without recording a session'

$continueResult = Invoke-TestScriptWithInput -ScriptPath $startScript -ArgumentList @('-ProjectPath', $conflictProjectRoot, '-NoLaunch', '-SkipUpdateCheck') -InputText 'y'
if ($continueResult.ExitCode -ne 0 -or (@(Read-ActiveSessions -ProjectRoot $conflictProjectRoot).Count -eq 0)) {
    Write-Fail 'Concurrent-claim continue did not proceed and record a session lock.'
    exit 1
}
Write-Pass 'Concurrent-claim continue proceeds and records a session'

exit 0
