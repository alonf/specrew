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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$updateScript = Join-Path $repoRoot 'scripts\specrew-update.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\psgallery-check'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'project'
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

$env:SPECREW_PSGALLERY_LATEST_VERSION = '0.21.0'
$env:SPECREW_PSGALLERY_FORCE_FAILURE = $null
$env:SPECREW_SKIP_UPDATE_CHECK = $null

$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')
$initOutput = $initResult.Output -join [Environment]::NewLine
if ($initResult.ExitCode -ne 0 -or $initOutput -notmatch 'WARN: Newer version available: 0\.21\.0' -or $initOutput -notmatch 'Update-Module Specrew') {
    Write-Fail ("Init did not surface the PSGallery update warning:`n{0}" -f $initOutput)
    exit 1
}
Write-Pass 'specrew init surfaces the PSGallery update warning and seeds the shared cache'

$cachePath = Join-Path $projectRoot '.specrew\version-check-cache.json'
if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
    Write-Fail 'PSGallery cache file was not created.'
    exit 1
}

$env:SPECREW_PSGALLERY_LATEST_VERSION = '0.22.0'
$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
$startOutput = $startResult.Output -join [Environment]::NewLine
if ($startResult.ExitCode -ne 0 -or $startOutput -notmatch 'WARN: Newer version available: 0\.21\.0' -or $startOutput -match '0\.22\.0') {
    Write-Fail ("specrew start did not reuse the cached PSGallery value:`n{0}" -f $startOutput)
    exit 1
}
Write-Pass 'specrew start reuses the shared PSGallery cache'

$updateResult = Invoke-TestScript -ScriptPath $updateScript -ArgumentList @('-ProjectPath', $projectRoot)
$updateOutput = $updateResult.Output -join [Environment]::NewLine
if ($updateResult.ExitCode -ne 0 -or $updateOutput -notmatch 'WARN: Newer version available: 0\.21\.0') {
    Write-Fail ("specrew update did not surface the shared PSGallery warning:`n{0}" -f $updateOutput)
    exit 1
}
Write-Pass 'specrew update uses the shared PSGallery warning path'

$skipResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch', '-SkipUpdateCheck')
$skipOutput = $skipResult.Output -join [Environment]::NewLine
if ($skipResult.ExitCode -ne 0 -or $skipOutput -match 'Newer version available') {
    Write-Fail 'The --skip-update-check flag should suppress the PSGallery warning.'
    exit 1
}
Write-Pass '--skip-update-check suppresses the PSGallery warning'

$env:SPECREW_SKIP_UPDATE_CHECK = '1'
$envSkipResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
$envSkipOutput = $envSkipResult.Output -join [Environment]::NewLine
if ($envSkipResult.ExitCode -ne 0 -or $envSkipOutput -match 'Newer version available') {
    Write-Fail 'SPECREW_SKIP_UPDATE_CHECK=1 should suppress the PSGallery warning.'
    exit 1
}
Write-Pass 'SPECREW_SKIP_UPDATE_CHECK=1 suppresses the PSGallery warning'

$env:SPECREW_SKIP_UPDATE_CHECK = $null
Remove-Item -LiteralPath $cachePath -Force
$env:SPECREW_PSGALLERY_LATEST_VERSION = $null
$env:SPECREW_PSGALLERY_FORCE_FAILURE = '1'
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$offlineResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
$timer.Stop()
$offlineOutput = $offlineResult.Output -join [Environment]::NewLine
if ($offlineResult.ExitCode -ne 0 -or $offlineOutput -match 'Newer version available' -or $timer.ElapsedMilliseconds -ge 10000) {
    Write-Fail ("Offline PSGallery failure should stay silent and bounded (<10s). Elapsed={0} ms`n{1}" -f $timer.ElapsedMilliseconds, $offlineOutput)
    exit 1
}
Write-Pass 'Offline PSGallery failures stay silent and bounded'

exit 0
