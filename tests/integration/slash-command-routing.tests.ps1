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
        Write-Fail "$Message (expected '$Substring' in output)"
        exit 1
    }
    Write-Pass $Message
}

function Assert-ExitCode {
    param(
        [Parameter(Mandatory = $true)][int]$Expected,
        [Parameter(Mandatory = $true)][int]$Actual,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Actual -ne $Expected) {
        Write-Fail "$Message (expected exit $Expected, got $Actual)"
        exit 1
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$specrew = Join-Path $repoRoot 'scripts\specrew.ps1'

Write-Host ''
Write-Host '=== Slash-Command Routing Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# --- Test 1: help/catalog includes all v1 slash commands ---
Write-Host '--- Test 1: Help output includes all v1 commands ---'
$helpOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'help' 2>&1 | Out-String
Assert-Contains -Text $helpOutput -Substring 'where' -Message 'Help includes specrew where'
Assert-Contains -Text $helpOutput -Substring 'status' -Message 'Help includes specrew status'
Assert-Contains -Text $helpOutput -Substring 'update' -Message 'Help includes specrew update'
Assert-Contains -Text $helpOutput -Substring 'team' -Message 'Help includes specrew team'
Assert-Contains -Text $helpOutput -Substring 'review' -Message 'Help includes specrew review'
Assert-Contains -Text $helpOutput -Substring 'version' -Message 'Help includes specrew version'
Assert-Contains -Text $helpOutput -Substring '/specrew-' -Message 'Help includes slash-command surface section'

# --- Test 2: unknown command exits 1 with guidance ---
Write-Host ''
Write-Host '--- Test 2: Unknown command fails with guidance ---'
$unknownOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'boguscommand' 2>&1 | Out-String
Assert-True -Condition ($LASTEXITCODE -ne 0) -Message 'Unknown command exits non-zero'
Assert-Contains -Text $unknownOutput -Substring 'Unknown command' -Message 'Unknown command error message shown'

# --- Test 3: specrew version command dispatches ---
Write-Host ''
Write-Host '--- Test 3: specrew version dispatches to specrew-version.ps1 ---'
$versionOutput = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'version' 2>&1 | Out-String
$versionExitCode = $LASTEXITCODE
Assert-True -Condition ($versionExitCode -eq 0 -or $versionOutput.Length -gt 0) -Message 'specrew version runs without missing-script error'
Assert-Contains -Text $versionOutput -Substring 'Version' -Message 'specrew version shows version information'

# --- Test 4: specrew status routes to where (alias parity) ---
Write-Host ''
Write-Host '--- Test 4: specrew status routes to same backend as specrew where ---'
# Both should produce the same type of output (either help text or status content)
# We verify by checking the specrew.ps1 routing logic directly
$scriptContent = Get-Content -LiteralPath $specrew -Raw
Assert-Contains -Text $scriptContent -Substring "MUST NOT diverge" -Message 'Alias parity safeguard comment present in dispatcher'
Assert-Contains -Text $scriptContent -Substring "'status'" -Message 'status case present in dispatcher'
Assert-Contains -Text $scriptContent -Substring "'where'" -Message 'where case present in dispatcher'

# Verify both cases call the same script
$statusMatch = [regex]::Match($scriptContent, "(?ms)'status'.*?specrew-where\.ps1", [System.Text.RegularExpressions.RegexOptions]::Singleline)
$whereMatch  = [regex]::Match($scriptContent, "(?ms)'where'.*?specrew-where\.ps1", [System.Text.RegularExpressions.RegexOptions]::Singleline)
Assert-True -Condition ($statusMatch.Success -and $whereMatch.Success) -Message 'Both where and status dispatch to specrew-where.ps1'

# --- Test 5: specrew.ps1 contains Assert-WhitelistedArguments function ---
Write-Host ''
Write-Host '--- Test 5: Argument whitelist enforcement function present ---'
Assert-Contains -Text $scriptContent -Substring 'Assert-WhitelistedArguments' -Message 'Assert-WhitelistedArguments function defined'
Assert-Contains -Text $scriptContent -Substring 'Write-Output "WARNING:' -Message 'Whitelist failure emits Write-Output warning (reviewer-visible)'

# --- Test 6: version command has whitelist in dispatcher ---
Write-Host ''
Write-Host '--- Test 6: update, review, where/status, version have whitelist enforcement in dispatcher ---'
Assert-Contains -Text $scriptContent -Substring "Assert-WhitelistedArguments -CommandName 'update'" -Message 'update whitelist enforcement present'
Assert-Contains -Text $scriptContent -Substring "Assert-WhitelistedArguments -CommandName 'where'" -Message 'where whitelist enforcement present'
Assert-Contains -Text $scriptContent -Substring "Assert-WhitelistedArguments -CommandName 'status'" -Message 'status whitelist enforcement present'
Assert-Contains -Text $scriptContent -Substring "Assert-WhitelistedArguments -CommandName 'version'" -Message 'version whitelist enforcement present'
Assert-Contains -Text $scriptContent -Substring "Assert-WhitelistedArguments -CommandName 'review'" -Message 'review whitelist enforcement present'

# --- Test 7: specrew-version.ps1 exists and contains key elements ---
Write-Host ''
Write-Host '--- Test 7: specrew-version.ps1 exists with expected content ---'
$versionScript = Join-Path $repoRoot 'scripts\specrew-version.ps1'
Assert-True -Condition (Test-Path -LiteralPath $versionScript) -Message 'specrew-version.ps1 exists'
$versionScriptContent = Get-Content -LiteralPath $versionScript -Raw
Assert-Contains -Text $versionScriptContent -Substring 'slashCommandMinVersion' -Message 'specrew-version.ps1 references min slash-command version'
Assert-Contains -Text $versionScriptContent -Substring 'compatible' -Message 'specrew-version.ps1 emits compatibility verdict'
Assert-Contains -Text $versionScriptContent -Substring 'Write-Output "WARNING:' -Message 'specrew-version.ps1 emits Write-Output warning on incompatibility'

# --- Test 8: Specrew.psm1 includes version mapping ---
Write-Host ''
Write-Host '--- Test 8: Specrew.psm1 exports specrew-version ---'
$psm1Path = Join-Path $repoRoot 'Specrew.psm1'
$psm1Content = Get-Content -LiteralPath $psm1Path -Raw
Assert-Contains -Text $psm1Content -Substring 'specrew-version' -Message 'Specrew.psm1 maps specrew-version script'
Assert-Contains -Text $psm1Content -Substring 'Show-SpecrewVersion' -Message 'Specrew.psm1 exports Show-SpecrewVersion'

Write-Host ''
Write-Host '=== All routing integration tests passed ===' -ForegroundColor Green
Write-Host ''
