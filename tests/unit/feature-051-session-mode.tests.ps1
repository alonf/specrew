[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 051 Iteration 1 (US1) acceptance tests — session-mode configuration.
# Plain-PowerShell test convention (NOT Pester): Assert-* helpers exit 1 on failure.
# T007 (FR-001/FR-002): `specrew config set session_mode` persists + reverts; invalid rejected.
# T008 (FR-003): a fresh governance scaffold defaults `.specrew/config.yml` to session_mode: single.

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Assert-True {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { Write-Fail $Message; exit 1 }
    Write-Pass $Message
}

function Assert-Contains {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text, [Parameter(Mandatory = $true)][string]$Substring, [Parameter(Mandatory = $true)][string]$Message)
    if ($Text -notlike "*$Substring*") { Write-Fail ("{0} (expected to contain '{1}')" -f $Message, $Substring); exit 1 }
    Write-Pass $Message
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scaffoldGovernance = Join-Path $repoRoot '.specify/extensions/specrew-speckit/scripts/scaffold-governance.ps1'
$configCommand = Join-Path $repoRoot 'scripts/specrew-config.ps1'

Assert-True (Test-Path -LiteralPath $scaffoldGovernance) "scaffold-governance.ps1 exists at $scaffoldGovernance"
Assert-True (Test-Path -LiteralPath $configCommand) "specrew-config.ps1 exists at $configCommand"

function New-TempProject {
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-f051-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    return $dir
}

function Get-ConfigSessionMode {
    param([string]$ProjectRoot)
    $configPath = Join-Path $ProjectRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath)) { return $null }
    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*session_mode:\s*"?(?<value>[^"#]+?)"?\s*$') { return $Matches['value'].Trim() }
    }
    return $null
}

# --- T008 (FR-003): fresh scaffold defaults to session_mode: single (REAL writer path) ---
$projectA = New-TempProject
try {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffoldGovernance -ProjectPath $projectA *> $null
    $modeAfterScaffold = Get-ConfigSessionMode -ProjectRoot $projectA
    Assert-True ($null -ne $modeAfterScaffold) "T008: fresh scaffold wrote a session_mode key to .specrew/config.yml"
    Assert-True ($modeAfterScaffold -eq 'single') "T008: fresh scaffold defaults session_mode to 'single' (FR-003), got '$modeAfterScaffold'"
}
finally {
    Remove-Item -LiteralPath $projectA -Recurse -Force -ErrorAction SilentlyContinue
}

# --- T007 (FR-001/FR-002): set persists, revert works, invalid rejected ---
$projectB = New-TempProject
try {
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffoldGovernance -ProjectPath $projectB *> $null

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $configCommand set session_mode multi -ProjectPath $projectB *> $null
    Assert-True ($LASTEXITCODE -eq 0) "T007: 'config set session_mode multi' exits 0"
    Assert-True ((Get-ConfigSessionMode -ProjectRoot $projectB) -eq 'multi') "T007: session_mode persisted as 'multi'"

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $configCommand set session_mode single -ProjectPath $projectB *> $null
    Assert-True ($LASTEXITCODE -eq 0) "T007: 'config set session_mode single' exits 0"
    Assert-True ((Get-ConfigSessionMode -ProjectRoot $projectB) -eq 'single') "T007: session_mode reverted to 'single'"

    & pwsh -NoProfile -ExecutionPolicy Bypass -File $configCommand set session_mode bogus -ProjectPath $projectB *> $null
    $rejectExit = $LASTEXITCODE
    Assert-True ($rejectExit -ne 0) "T007: invalid value 'bogus' is rejected (non-zero exit), got exit $rejectExit"
    Assert-True ((Get-ConfigSessionMode -ProjectRoot $projectB) -eq 'single') "T007: invalid set did not mutate config (still 'single')"
}
finally {
    Remove-Item -LiteralPath $projectB -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "All Feature-051 session-mode (US1) acceptance tests passed." -ForegroundColor Green
exit 0
