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
Write-Host '=== Slash-Command Argument Whitelist Unit Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# Helper: invoke specrew with command + args, capture output + exit code
function Invoke-Specrew {
    param([string[]]$CommandArgs)
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew @CommandArgs 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $output
    }
}

# --- Test 1: unsupported arg for 'update' is rejected ---
Write-Host '--- Test 1: update rejects unsupported argument ---'
$result = Invoke-Specrew -CommandArgs @('update', '--bogus')
Assert-True -Condition ($result.ExitCode -ne 0) -Message 'specrew update --bogus exits non-zero'
Assert-Contains -Text $result.Output -Substring 'Unsupported argument' -Message 'specrew update --bogus emits unsupported-argument error'
Assert-Contains -Text $result.Output -Substring '--help' -Message 'specrew update --bogus suggests --help'

# --- Test 2: unsupported arg for 'update' emits Write-Output WARNING ---
Write-Host ''
Write-Host '--- Test 2: update emits Write-Output WARNING on unsupported argument ---'
Assert-Contains -Text $result.Output -Substring 'WARNING:' -Message 'specrew update --bogus emits reviewer-visible WARNING prefix'

# --- Test 3: unsupported arg for 'where' is rejected ---
Write-Host ''
Write-Host '--- Test 3: where rejects unsupported argument ---'
$result = Invoke-Specrew -CommandArgs @('where', '--bogus-flag')
Assert-True -Condition ($result.ExitCode -ne 0) -Message 'specrew where --bogus-flag exits non-zero'
Assert-Contains -Text $result.Output -Substring 'Unsupported argument' -Message 'specrew where --bogus-flag emits unsupported-argument error'
Assert-Contains -Text $result.Output -Substring 'WARNING:' -Message 'specrew where --bogus-flag emits WARNING prefix'

# --- Test 4: unsupported arg for 'status' alias is rejected (parity with where) ---
Write-Host ''
Write-Host '--- Test 4: status alias rejects unsupported argument (same as where) ---'
$result = Invoke-Specrew -CommandArgs @('status', '--bogus-flag')
Assert-True -Condition ($result.ExitCode -ne 0) -Message 'specrew status --bogus-flag exits non-zero'
Assert-Contains -Text $result.Output -Substring 'WARNING:' -Message 'specrew status --bogus-flag emits WARNING prefix'

# --- Test 5: unsupported arg for 'version' is rejected ---
Write-Host ''
Write-Host '--- Test 5: version rejects unsupported argument ---'
$result = Invoke-Specrew -CommandArgs @('version', '--unknown-flag')
Assert-True -Condition ($result.ExitCode -ne 0) -Message 'specrew version --unknown-flag exits non-zero'
Assert-Contains -Text $result.Output -Substring 'WARNING:' -Message 'specrew version --unknown-flag emits WARNING prefix'

# --- Test 6: unsupported arg for 'review' is rejected ---
Write-Host ''
Write-Host '--- Test 6: review rejects unsupported argument ---'
$result = Invoke-Specrew -CommandArgs @('review', '--not-a-real-flag')
Assert-True -Condition ($result.ExitCode -ne 0) -Message 'specrew review --not-a-real-flag exits non-zero'
Assert-Contains -Text $result.Output -Substring 'WARNING:' -Message 'specrew review --not-a-real-flag emits WARNING prefix'

# --- Test 7: --help is always accepted (whitelisted flag) ---
Write-Host ''
Write-Host '--- Test 7: --help flag is always accepted (not rejected by whitelist) ---'
$result = Invoke-Specrew -CommandArgs @('version', '--help')
# --help should pass through to the backend and get exit 0 with usage output
Assert-True -Condition ($result.ExitCode -eq 0) -Message 'specrew version --help exits 0'

# --- Test 8: valid update args are not rejected ---
Write-Host ''
Write-Host '--- Test 8: valid update arguments are not rejected by whitelist ---'
$result = Invoke-Specrew -CommandArgs @('update', '--info', '--skip-update-check')
# --info and --skip-update-check are both in the whitelist; should not produce whitelist rejection
Assert-True -Condition (-not ($result.Output -like '*Unsupported argument*')) -Message 'specrew update --info --skip-update-check passes whitelist check'

# --- Test 9: help guidance includes /specrew-help reference ---
Write-Host ''
Write-Host '--- Test 9: whitelist rejection references /specrew-help catalog ---'
$result = Invoke-Specrew -CommandArgs @('update', '--totally-bogus')
Assert-Contains -Text $result.Output -Substring '/specrew-help' -Message 'Rejection message references /specrew-help catalog'

Write-Host ''
Write-Host '=== All whitelist unit tests passed ===' -ForegroundColor Green
Write-Host ''
