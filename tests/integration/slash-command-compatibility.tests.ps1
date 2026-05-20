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

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
    Write-Pass $Message
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Substring,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Text -notlike "*$Substring*") {
        Write-Fail "$Message (expected '$Substring' in text)"
        exit 1
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$specrew = Join-Path $repoRoot 'scripts\specrew.ps1'

Write-Host ''
Write-Host '=== Slash-Command Compatibility Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

Write-Host '--- Test 1: version-check.ps1 exports the Feature 024 minimum version ---'
$versionCheckPath = Join-Path $repoRoot 'scripts\internal\version-check.ps1'
$versionCheckContent = Get-Content -LiteralPath $versionCheckPath -Raw
Assert-Contains -Text $versionCheckContent -Substring 'Get-SpecrewSlashCommandMinVersion' -Message 'Get-SpecrewSlashCommandMinVersion function defined'
Assert-Contains -Text $versionCheckContent -Substring '0.24.0' -Message 'Slash-command minimum version is 0.24.0'

Write-Host ''
Write-Host '--- Test 2: specrew-version.ps1 reports the Feature 024 compatibility baseline ---'
$versionScriptPath = Join-Path $repoRoot 'scripts\specrew-version.ps1'
$versionScriptContent = Get-Content -LiteralPath $versionScriptPath -Raw
Assert-Contains -Text $versionScriptContent -Substring '0.24.0' -Message 'specrew-version.ps1 embeds the 0.24.0 compatibility floor'
Assert-Contains -Text $versionScriptContent -Substring '/specrew-help' -Message 'specrew-version.ps1 help guidance references /specrew-help'
Assert-Contains -Text $versionScriptContent -Substring 'compatible' -Message 'specrew-version.ps1 emits a compatibility verdict'

Write-Host ''
Write-Host '--- Test 3: specrew dispatcher advertises the hyphenated slash-command catalog ---'
$specrewContent = Get-Content -LiteralPath $specrew -Raw
Assert-Contains -Text $specrewContent -Substring '/specrew-where' -Message 'specrew.ps1 help includes /specrew-where'
Assert-Contains -Text $specrewContent -Substring '/specrew-help' -Message 'specrew.ps1 help includes /specrew-help'
Assert-True -Condition ($specrewContent -notmatch '/specrew\.') -Message 'specrew.ps1 no longer publishes dot-form slash commands'

Write-Host ''
Write-Host '--- Test 4: project-setup gate still fires for where on an uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-uninit'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'where' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew where on an uninitialized project exits non-zero'
    Assert-Contains -Text $output -Substring 'WARNING:' -Message 'specrew where emits a reviewer-visible WARNING'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew where suggests specrew init remediation'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '--- Test 5: project-setup gate still fires for review on an uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-review'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'review' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew review on an uninitialized project exits non-zero'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew review suggests specrew init remediation'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '--- Test 6: specrew version remains project-setup tolerant ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-version'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'version' '--project-path' $scratchDir | Out-Null
    Assert-True -Condition ($LASTEXITCODE -eq 0) -Message 'specrew version runs without project setup'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '=== All compatibility integration tests passed ===' -ForegroundColor Green
Write-Host ''
