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

function New-CliShim {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath,

        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $shimPath = Join-Path -Path $DirectoryPath -ChildPath ("{0}.cmd" -f $CommandName)
    if ($PSCmdlet.ShouldProcess($shimPath, 'Write CLI shim')) {
        [System.IO.File]::WriteAllText($shimPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
    return $shimPath
}

function Invoke-ValidationWithShimPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValidateScript,

        [Parameter(Mandatory = $true)]
        [string]$ShimPath
    )

    $originalPath = $env:PATH
    try {
        $env:PATH = "{0}{1}{2}" -f $ShimPath, [System.IO.Path]::PathSeparator, $originalPath
        return @(& $ValidateScript -PassThru)
    }
    finally {
        $env:PATH = $originalPath
    }
}

function Invoke-SpecrewCli {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [string[]]$ArgumentList = @()
    )

    $output = @(
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1
    )

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output | ForEach-Object { [string]$_ })
        Text     = (@($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validateScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\validate-versions.ps1'
$specrewScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew.ps1'

if (-not (Test-Path -LiteralPath $validateScript -PathType Leaf)) {
    Write-Fail "Missing validator script: $validateScript"
    exit 1
}

if (-not (Test-Path -LiteralPath $specrewScript -PathType Leaf)) {
    Write-Fail "Missing Specrew CLI script: $specrewScript"
    exit 1
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\validate-versions-cli-behavior'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $scratchRoot -ItemType Directory -Force

try {
    $healthyShimPath = Join-Path -Path $scratchRoot -ChildPath 'healthy-specify-version'
    $null = New-Item -Path $healthyShimPath -ItemType Directory -Force

    New-CliShim -DirectoryPath $healthyShimPath -CommandName 'specify' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo Usage: specify [OPTIONS] COMMAND [ARGS]...
  echo Try 'specify --help' for help.
  echo No such option: --version
  exit /b 2
)
if /I "%~1"=="version" (
  echo GitHub Spec Kit - Spec-Driven Development Toolkit
  echo CLI Version    1.0.0
  echo Template Version    0.8.4
  exit /b 0
)
echo unexpected specify args: %*
exit /b 9
'@ | Out-Null

    New-CliShim -DirectoryPath $healthyShimPath -CommandName 'squad' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo 0.9.1
  exit /b 0
)
echo unexpected squad args: %*
exit /b 9
'@ | Out-Null

    New-CliShim -DirectoryPath $healthyShimPath -CommandName 'uv' -Content @'
@echo off
if /I "%~1 %~2"=="tool list" (
  echo specify-cli v1.0.0
  echo - specify
  exit /b 0
)
echo unexpected uv args: %*
exit /b 9
'@ | Out-Null

    $healthyResults = @(Invoke-ValidationWithShimPath -ValidateScript $validateScript -ShimPath $healthyShimPath)
    $healthySpecKit = @($healthyResults | Where-Object { $_.Platform -eq 'Spec Kit' })[0]

    if (-not $healthySpecKit.IsOperational) {
        Write-Fail 'Healthy Spec Kit install should pass when the CLI exposes version through `specify version`.'
        exit 1
    }

    if ($healthySpecKit.Version -ne '1.0.0') {
        Write-Fail ("Healthy Spec Kit probe returned unexpected version: {0}" -f $healthySpecKit.Version)
        exit 1
    }

    if ($healthySpecKit.VersionSource -ne 'command:version') {
        Write-Fail ("Healthy Spec Kit probe should record the version subcommand source, found: {0}" -f $healthySpecKit.VersionSource)
        exit 1
    }

    if ($healthySpecKit.SuggestedInstall -ne 'uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4') {
        Write-Fail ("Healthy Spec Kit install guidance should point at the official GitHub release source, found: {0}" -f $healthySpecKit.SuggestedInstall)
        exit 1
    }

    if ($healthySpecKit.SuggestedRepair -ne 'uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4') {
        Write-Fail ("Healthy Spec Kit repair guidance should point at the official GitHub release source, found: {0}" -f $healthySpecKit.SuggestedRepair)
        exit 1
    }

    Write-Pass 'Healthy Spec Kit installs pass validation when the CLI requires `specify version` instead of `specify --version`'

    $brokenShimPath = Join-Path -Path $scratchRoot -ChildPath 'broken-specify-command'
    $null = New-Item -Path $brokenShimPath -ItemType Directory -Force

    New-CliShim -DirectoryPath $brokenShimPath -CommandName 'specify' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo Failed to load specify runtime
  exit /b 1
)
if /I "%~1"=="version" (
  echo Failed to load specify runtime
  exit /b 1
)
echo unexpected specify args: %*
exit /b 9
'@ | Out-Null

    New-CliShim -DirectoryPath $brokenShimPath -CommandName 'squad' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo 0.9.1
  exit /b 0
)
echo unexpected squad args: %*
exit /b 9
'@ | Out-Null

    New-CliShim -DirectoryPath $brokenShimPath -CommandName 'uv' -Content @'
@echo off
if /I "%~1 %~2"=="tool list" (
  echo specify-cli v1.0.0
  echo - specify
  exit /b 0
)
echo unexpected uv args: %*
exit /b 9
'@ | Out-Null

    $brokenResults = @(Invoke-ValidationWithShimPath -ValidateScript $validateScript -ShimPath $brokenShimPath)
    $brokenSpecKit = @($brokenResults | Where-Object { $_.Platform -eq 'Spec Kit' })[0]

    if ($brokenSpecKit.IsOperational) {
        Write-Fail 'Broken Spec Kit commands should still fail validation even when uv inventory reports an installed package.'
        exit 1
    }

    if (-not $brokenSpecKit.IsCompatible) {
        Write-Fail 'Broken Spec Kit commands should still preserve the detected compatible version from uv inventory.'
        exit 1
    }

    if ($brokenSpecKit.VersionSource -ne 'uv-tool-list') {
        Write-Fail ("Broken Spec Kit fallback should use uv tool inventory, found: {0}" -f $brokenSpecKit.VersionSource)
        exit 1
    }

    if ($brokenSpecKit.ProbeError -notmatch 'Failed to load specify runtime') {
        Write-Fail ("Broken Spec Kit failure detail was not preserved: {0}" -f $brokenSpecKit.ProbeError)
        exit 1
    }

    if ($brokenSpecKit.SuggestedRepair -ne 'uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4') {
        Write-Fail ("Broken Spec Kit repair guidance should point at the official GitHub release source, found: {0}" -f $brokenSpecKit.SuggestedRepair)
        exit 1
    }

    Write-Pass 'Broken Spec Kit installs still fail validation even when uv inventory can report a version'

    $nonProjectRoot = Join-Path $scratchRoot 'non-project'
    $null = New-Item -Path $nonProjectRoot -ItemType Directory -Force

    Push-Location $nonProjectRoot
    try {
        $canonicalVersion = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('version')
        $longAliasVersion = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('--version')
        $shortAliasVersion = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('-v')
        $canonicalVersionWithProjectPath = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('version', '--project-path', $nonProjectRoot)
        $longAliasVersionWithProjectPath = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('--version', '--project-path', $nonProjectRoot)
        $shortAliasVersionWithProjectPath = Invoke-SpecrewCli -ScriptPath $specrewScript -WorkingDirectory $nonProjectRoot -ArgumentList @('-v', '--project-path', $nonProjectRoot)
    }
    finally {
        Pop-Location
    }

    if ($canonicalVersion.ExitCode -ne 0) {
        Write-Fail ("Canonical 'specrew version' should succeed outside a project:`n{0}" -f $canonicalVersion.Text)
        exit 1
    }

    if ($longAliasVersion.ExitCode -ne 0) {
        Write-Fail ("Top-level 'specrew --version' should route to canonical version behavior:`n{0}" -f $longAliasVersion.Text)
        exit 1
    }

    if ($shortAliasVersion.ExitCode -ne 0) {
        Write-Fail ("Top-level 'specrew -v' should route to canonical version behavior:`n{0}" -f $shortAliasVersion.Text)
        exit 1
    }

    foreach ($aliasResult in @($longAliasVersion, $shortAliasVersion)) {
        if ($aliasResult.Text -ne $canonicalVersion.Text) {
            Write-Fail ("Version alias output must match canonical output.`nCanonical:`n{0}`nAlias:`n{1}" -f $canonicalVersion.Text, $aliasResult.Text)
            exit 1
        }
    }

    foreach ($aliasResult in @($longAliasVersionWithProjectPath, $shortAliasVersionWithProjectPath)) {
        if ($aliasResult.ExitCode -ne 0) {
            Write-Fail ("Version aliases should preserve --project-path routing:`n{0}" -f $aliasResult.Text)
            exit 1
        }

        if ($aliasResult.Text -ne $canonicalVersionWithProjectPath.Text) {
            Write-Fail ("Version alias --project-path output must match canonical output.`nCanonical:`n{0}`nAlias:`n{1}" -f $canonicalVersionWithProjectPath.Text, $aliasResult.Text)
            exit 1
        }
    }

    if ($canonicalVersion.Text -match 'WARNING: Specrew version could not be determined') {
        Write-Fail "'specrew version' outside a project should not warn that version is undetermined when installed/module metadata is available."
        exit 1
    }

    Write-Pass 'Top-level --version and -v aliases match canonical version output outside a project without false warning noise'
    exit 0
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
