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

function Set-SpecrewVersion {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigPath,
        [Parameter(Mandatory = $true)][string]$Version
    )

    $updated = (Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8) -replace 'specrew_version:\s*"[^"]+"', ('specrew_version: "{0}"' -f $Version)
    [System.IO.File]::WriteAllText($ConfigPath, $updated, [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\version-checks'
$projectRoot = Join-Path $scratchRoot 'project'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

$initResult = Invoke-TestScript -ScriptPath $initScript -ArgumentList @('-ProjectPath', $projectRoot, '-Force', '-NoAgents')
if ($initResult.ExitCode -ne 0) {
    Write-Fail ("Bootstrap failed:`n{0}" -f ($initResult.Output -join [Environment]::NewLine))
    exit 1
}

$configPath = Join-Path $projectRoot '.specrew\config.yml'

Set-SpecrewVersion -ConfigPath $configPath -Version '0.18.0'
$mismatchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
$mismatchOutput = $mismatchResult.Output -join [Environment]::NewLine
if ($mismatchResult.ExitCode -ne 0) {
    Write-Fail ("Version-mismatch start should remain non-blocking:`n{0}" -f $mismatchOutput)
    exit 1
}
foreach ($pattern in @('Module version mismatch detected', 'installed 0\.19\.0', 'project expects 0\.18\.0', 'specrew update', 'Launch skipped by --no-launch')) {
    if ($mismatchOutput -notmatch $pattern) {
        Write-Fail ("Version-mismatch output did not include expected pattern '{0}'." -f $pattern)
        exit 1
    }
}
if ($mismatchOutput -match 'Options:\s+|re-anchor') {
    Write-Fail 'Version mismatch should not trigger an interactive stale-state prompt.'
    exit 1
}
Write-Pass 'Version mismatch warning is non-blocking and actionable'

Set-SpecrewVersion -ConfigPath $configPath -Version '0.19.0'
$matchResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $projectRoot, '-NoLaunch')
$matchOutput = $matchResult.Output -join [Environment]::NewLine
if ($matchResult.ExitCode -ne 0) {
    Write-Fail ("Matching-version start unexpectedly failed:`n{0}" -f $matchOutput)
    exit 1
}
if ($matchOutput -match 'Module version mismatch detected') {
    Write-Fail 'Matching versions should not emit a mismatch warning.'
    exit 1
}
Write-Pass 'Matching versions do not emit a warning'

exit 0
