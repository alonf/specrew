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

function Initialize-GitRepo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $gitOutput = @(& git -C $ProjectPath init --quiet 2>&1)
    if ($LASTEXITCODE -ne 0) {
        foreach ($line in $gitOutput) {
            Write-Host $line
        }

        throw ("Failed to initialize git repository in scratch project: {0}" -f $ProjectPath)
    }
}

function Invoke-BootstrapWithShimPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InitScript,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ShimPath
    )

    $originalPath = $env:PATH
    try {
        $env:PATH = "{0};{1}" -f $ShimPath, $originalPath
        Push-Location $RepoRoot
        try {
            $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $InitScript -ProjectPath $ProjectPath -Agents 'copilot' 2>&1)
            return [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output   = @($output | ForEach-Object { [string]$_ })
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        $env:PATH = $originalPath
    }
}

function Assert-OutputPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'

if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
    Write-Fail "Missing bootstrap entrypoint: $initScript"
    exit 1
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\bootstrap-asset-blocker-recovery'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path $scratchRoot -ItemType Directory -Force

try {
    $successRoot = Join-Path -Path $scratchRoot -ChildPath 'repair-success'
    $successShimPath = Join-Path -Path $successRoot -ChildPath 'shim'
    $successProjectPath = Join-Path -Path $successRoot -ChildPath 'project'
    $null = New-Item -Path $successShimPath, $successProjectPath -ItemType Directory -Force
    Initialize-GitRepo -ProjectPath $successProjectPath

    New-CliShim -DirectoryPath $successShimPath -CommandName 'specify' -Content @'
@echo off
set state=%~dp0specify-state.txt
if not exist "%state%" (
  >"%state%" echo blocker
)
set /p phase=<"%state%"
if /I "%~1"=="--version" goto versionflag
if /I "%~1"=="version" goto version
if /I "%~1"=="extension" goto extension
if /I "%~1"=="init" goto init
echo unexpected specify args: %*
exit /b 9
:versionflag
echo Usage: specify [OPTIONS] COMMAND [ARGS]...
echo Try 'specify --help' for help.
echo No such option: --version
exit /b 2
:version
echo GitHub Spec Kit - Spec-Driven Development Toolkit
echo CLI Version    1.0.0
echo Template Version    0.8.4
exit /b 0
:extension
echo unexpected specify args: %*
exit /b 9
:init
if /I "%phase%"=="blocker" goto blocker
mkdir .specify 2>nul
exit /b 0
:blocker
>"%state%" echo repaired
echo No matching release asset found for github-spec-kit-template-copilot
exit /b 1
'@ | Out-Null

    New-CliShim -DirectoryPath $successShimPath -CommandName 'uv' -Content @'
@echo off
echo %*>>"%~dp0uv-success.log"
echo repaired-from-github
exit /b 0
'@ | Out-Null

    New-CliShim -DirectoryPath $successShimPath -CommandName 'squad' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo 0.9.1
  exit /b 0
)
if /I "%~1"=="init" (
  mkdir .squad 2>nul
  exit /b 0
)
echo unexpected squad args: %*
exit /b 9
'@ | Out-Null

    $successResult = Invoke-BootstrapWithShimPath -InitScript $initScript -RepoRoot $repoRoot -ProjectPath $successProjectPath -ShimPath $successShimPath
    $successOutput = ($successResult.Output -join [Environment]::NewLine)
    if ($successResult.ExitCode -ne 0) {
        Write-Fail ("Repair-success bootstrap exited with code {0}`n{1}" -f $successResult.ExitCode, $successOutput)
        exit 1
    }

    $successChecks = @(
        @{
            Pattern = '\[info\] Detected Spec Kit release-asset blocker during preflight; reinstalling official Spec Kit v0\.8\.4 from GitHub\.'
            Failure = 'Repair-success bootstrap did not report the automatic release-asset repair path.'
        },
        @{
            Pattern = 'Spec Kit: reinstalled Spec Kit from official GitHub release v0\.8\.4'
            Failure = 'Repair-success bootstrap summary did not record the Spec Kit repair outcome.'
        },
        @{
            Pattern = 'Bootstrap completed for '
            Failure = 'Repair-success bootstrap did not complete cleanly after the automatic repair.'
        }
    )

    foreach ($check in $successChecks) {
        if (-not (Assert-OutputPattern -Content $successOutput -Pattern $check.Pattern -FailureMessage $check.Failure)) {
            exit 1
        }
    }

    $uvLogPath = Join-Path -Path $successShimPath -ChildPath 'uv-success.log'
    if (-not (Test-Path -LiteralPath $uvLogPath -PathType Leaf)) {
        Write-Fail 'Repair-success bootstrap did not invoke uv for the automatic repair.'
        exit 1
    }

    $uvLog = Get-Content -LiteralPath $uvLogPath -Raw -Encoding UTF8
    if ($uvLog -notmatch 'tool install --force specify-cli --from git\+https://github\.com/github/spec-kit\.git@v0\.8\.4') {
        Write-Fail ("Repair-success bootstrap invoked the wrong uv repair command: {0}" -f $uvLog.Trim())
        exit 1
    }

    Write-Pass 'Automatic Spec Kit release-asset repair completes bootstrap cleanly and records the repair outcome'

    $failureRoot = Join-Path -Path $scratchRoot -ChildPath 'repair-fails'
    $failureShimPath = Join-Path -Path $failureRoot -ChildPath 'shim'
    $failureProjectPath = Join-Path -Path $failureRoot -ChildPath 'project'
    $null = New-Item -Path $failureShimPath, $failureProjectPath -ItemType Directory -Force
    Initialize-GitRepo -ProjectPath $failureProjectPath

    New-CliShim -DirectoryPath $failureShimPath -CommandName 'specify' -Content @'
@echo off
if /I "%~1"=="--version" goto versionflag
if /I "%~1"=="version" goto version
if /I "%~1"=="extension" goto extension
if /I "%~1"=="init" goto init
echo unexpected specify args: %*
exit /b 9
:versionflag
echo Usage: specify [OPTIONS] COMMAND [ARGS]...
echo Try 'specify --help' for help.
echo No such option: --version
exit /b 2
:version
echo GitHub Spec Kit - Spec-Driven Development Toolkit
echo CLI Version    1.0.0
echo Template Version    0.8.4
exit /b 0
:extension
echo unexpected specify args: %*
exit /b 9
:init
echo No matching release asset found for github-spec-kit-template-copilot
exit /b 1
'@ | Out-Null

    New-CliShim -DirectoryPath $failureShimPath -CommandName 'uv' -Content @'
@echo off
echo %*>>"%~dp0uv-failure.log"
echo repaired-from-github
exit /b 0
'@ | Out-Null

    New-CliShim -DirectoryPath $failureShimPath -CommandName 'squad' -Content @'
@echo off
if /I "%~1"=="--version" (
  echo 0.9.1
  exit /b 0
)
if /I "%~1"=="init" (
  mkdir .squad 2>nul
  exit /b 0
)
echo unexpected squad args: %*
exit /b 9
'@ | Out-Null

    $failureResult = Invoke-BootstrapWithShimPath -InitScript $initScript -RepoRoot $repoRoot -ProjectPath $failureProjectPath -ShimPath $failureShimPath
    $failureOutput = ($failureResult.Output -join [Environment]::NewLine)
    if ($failureResult.ExitCode -eq 0) {
        Write-Fail ("Repair-failure bootstrap unexpectedly succeeded.`n{0}" -f $failureOutput)
        exit 1
    }

    $failureChecks = @(
        @{
            Pattern = 'Spec Kit was repaired to the official GitHub release'
            Failure = 'Repair-failure bootstrap did not report that the automatic repair was attempted.'
        },
        @{
            Pattern = 'still failed in preflight'
            Failure = 'Repair-failure bootstrap did not report that preflight still failed after repair.'
        },
        @{
            Pattern = 'github-spec-kit-template-copilot'
            Failure = 'Repair-failure bootstrap did not preserve the upstream release-asset blocker detail.'
        }
    )

    foreach ($check in $failureChecks) {
        if (-not (Assert-OutputPattern -Content $failureOutput -Pattern $check.Pattern -FailureMessage $check.Failure)) {
            exit 1
        }
    }

    if ($failureOutput -match 'property ''Ready'' cannot be found') {
        Write-Fail 'Repair-failure bootstrap regressed to the Ready-property crash instead of returning one structured result.'
        exit 1
    }

    foreach ($unexpectedPath in @('.specify', '.specrew')) {
        $fullPath = Join-Path -Path $failureProjectPath -ChildPath $unexpectedPath
        if (Test-Path -LiteralPath $fullPath) {
            Write-Fail ("Repair-failure bootstrap should stop before mutating {0}, but found: {1}" -f $unexpectedPath, $fullPath)
            exit 1
        }
    }

    Write-Pass 'Automatic Spec Kit release-asset repair failures stop before mutation and return an actionable preflight error'
    exit 0
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
