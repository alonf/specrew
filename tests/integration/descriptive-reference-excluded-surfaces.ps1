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

function Invoke-ReplayFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValidatorScript,
        [Parameter(Mandatory = $true)]
        [string]$FixtureDirectory
    )

    $manifestPath = Join-Path $FixtureDirectory 'fixture.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Missing fixture manifest: $manifestPath"
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
    $responsePath = Join-Path $FixtureDirectory $manifest.ResponseFile
    if (-not (Test-Path -LiteralPath $responsePath -PathType Leaf)) {
        throw "Missing fixture response file: $responsePath"
    }

    $responseText = Get-Content -LiteralPath $responsePath -Raw -Encoding UTF8
    $output = @(& $ValidatorScript -ResponseText $responseText 2>&1)
    return @{
        Manifest = $manifest
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Matches {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-NotMatches {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -match $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
$fixturesRoot = Join-Path $repoRoot 'tests\integration\fixtures\descriptive-reference-excluded-surfaces'

foreach ($requiredPath in @($validatorScript, $fixturesRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing required path: $requiredPath"
        exit 1
    }
}

$fixtureDirectories = @(
    Get-ChildItem -LiteralPath $fixturesRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'fixture.psd1') -PathType Leaf } |
        Sort-Object FullName
)

if ($fixtureDirectories.Count -eq 0) {
    Write-Fail "No excluded-surface fixtures found under $fixturesRoot"
    exit 1
}

foreach ($fixtureDirectory in $fixtureDirectories) {
    $result = Invoke-ReplayFixture -ValidatorScript $validatorScript -FixtureDirectory $fixtureDirectory.FullName
    $manifest = $result.Manifest
    $joinedOutput = ($result.Output -join [Environment]::NewLine).Trim()

    if ($result.ExitCode -ne 0) {
        Write-Fail "Fixture '$($manifest.FixtureId)' should not hard-fail the real governance review path."
        $result.Output | ForEach-Object { Write-Host $_ }
        exit 1
    }

    if ($manifest.ReplayPath -ne 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1') {
        Write-Fail "Fixture '$($manifest.FixtureId)' does not point at the real governance replay path."
        exit 1
    }

    foreach ($pattern in @($manifest.RequiredPatterns)) {
        if (-not (Assert-Matches -Content $joinedOutput -Pattern $pattern -FailureMessage ("Fixture '{0}' is missing expected user-visible output pattern '{1}'.`n{2}" -f $manifest.FixtureId, $pattern, $joinedOutput))) {
            exit 1
        }
    }

    foreach ($pattern in @($manifest.ForbiddenPatterns)) {
        if (-not (Assert-NotMatches -Content $joinedOutput -Pattern $pattern -FailureMessage ("Fixture '{0}' emitted forbidden output pattern '{1}'.`n{2}" -f $manifest.FixtureId, $pattern, $joinedOutput))) {
            exit 1
        }
    }

    Write-Pass ("Fixture '{0}' replayed through the real governance validator path without counting excluded verbatim content." -f $manifest.FixtureId)
}

Write-Pass 'Excluded-surface replay fixtures prove quoted, code, raw-tool, and Copilot-rendered blocks stay out of scope'
exit 0
