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

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$specrew = Join-Path $repoRoot 'scripts\specrew.ps1'

Write-Host ''
Write-Host '=== Slash-Command Compatibility Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# --- Test 1: version-check.ps1 contains Get-SpecrewSlashCommandMinVersion ---
Write-Host '--- Test 1: version-check.ps1 exports Get-SpecrewSlashCommandMinVersion ---'
$versionCheckPath = Join-Path $repoRoot 'scripts\internal\version-check.ps1'
Assert-True -Condition (Test-Path -LiteralPath $versionCheckPath -PathType Leaf) -Message 'version-check.ps1 exists'
$versionCheckContent = Get-Content -LiteralPath $versionCheckPath -Raw
Assert-Contains -Text $versionCheckContent -Substring 'Get-SpecrewSlashCommandMinVersion' -Message 'Get-SpecrewSlashCommandMinVersion function defined'
Assert-Contains -Text $versionCheckContent -Substring '0.21.0' -Message 'Slash-command min version is 0.21.0'

# --- Test 2: specrew-version.ps1 uses the min version constant ---
Write-Host ''
Write-Host '--- Test 2: specrew-version.ps1 references slash-command min version ---'
$versionScriptPath = Join-Path $repoRoot 'scripts\specrew-version.ps1'
$versionScriptContent = Get-Content -LiteralPath $versionScriptPath -Raw
Assert-Contains -Text $versionScriptContent -Substring '0.21.0' -Message 'specrew-version.ps1 embeds slash-command min version constant'
Assert-Contains -Text $versionScriptContent -Substring 'compatible' -Message 'specrew-version.ps1 emits compatibility verdict'
Assert-Contains -Text $versionScriptContent -Substring 'specrew update' -Message 'specrew-version.ps1 references upgrade remediation path'

# --- Test 3: specrew.ps1 Assert-ProjectSetup references specrew init remediation ---
Write-Host ''
Write-Host '--- Test 3: specrew.ps1 project-setup gate emits init remediation ---'
$specrewContent = Get-Content -LiteralPath $specrew -Raw
Assert-Contains -Text $specrewContent -Substring 'specrew init' -Message 'specrew.ps1 Assert-ProjectSetup cites specrew init'
Assert-Contains -Text $specrewContent -Substring 'Write-Output "WARNING:' -Message 'Assert-ProjectSetup emits Write-Output WARNING (reviewer-visible)'
Assert-Contains -Text $specrewContent -Substring 'config.yml' -Message 'Assert-ProjectSetup checks .specrew\config.yml presence'

# --- Test 4: Project-setup gate fires for 'where' in an uninitialized directory ---
Write-Host ''
Write-Host '--- Test 4: Project-setup gate fires for uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-uninit'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'where' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew where on uninit project exits non-zero'
    Assert-Contains -Text $output -Substring 'WARNING:' -Message 'specrew where on uninit project emits WARNING prefix'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew where on uninit project suggests specrew init'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

# --- Test 5: Project-setup gate fires for 'review' in an uninitialized directory ---
Write-Host ''
Write-Host '--- Test 5: Project-setup gate fires for review on uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-review'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'review' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew review on uninit project exits non-zero'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew review on uninit project suggests specrew init'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

# --- Test 6: specrew version does NOT require project setup ---
Write-Host ''
Write-Host '--- Test 6: specrew version runs without project setup (compatibility-safe) ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-version'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force

    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'version' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    # version should succeed (exit 0) regardless of project setup; it reports compatibility state
    Assert-True -Condition ($exitCode -eq 0) -Message 'specrew version runs without project setup (exit 0)'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

# --- Test 7: specrew routing contract documents compatibility gate ---
Write-Host ''
Write-Host '--- Test 7: Routing contract documents compatibility and setup gates ---'
$routingContract = Join-Path $repoRoot 'specs\021-specrew-slash-commands\contracts\slash-command-routing.md'
Assert-True -Condition (Test-Path -LiteralPath $routingContract -PathType Leaf) -Message 'slash-command-routing.md contract exists'
$contractContent = Get-Content -LiteralPath $routingContract -Raw
Assert-Contains -Text $contractContent -Substring 'Setup gate' -Message 'Routing contract defines setup gate'
Assert-Contains -Text $contractContent -Substring 'Compatibility gate' -Message 'Routing contract defines compatibility gate'
Assert-Contains -Text $contractContent -Substring 'specrew init' -Message 'Routing contract references specrew init remediation'

Write-Host ''
Write-Host '=== All compatibility integration tests passed ===' -ForegroundColor Green
Write-Host ''
