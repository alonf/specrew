[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)] $Expected,
        [Parameter(Mandatory = $true)] $Actual,
        [Parameter(Mandatory = $true)][string] $Message
    )
    if ($Expected -ne $Actual) {
        Write-Fail ("{0} (expected '{1}', got '{2}')" -f $Message, $Expected, $Actual)
    }
    Write-Pass $Message
}

function Assert-Null {
    param(
        [AllowNull()] $Actual,
        [Parameter(Mandatory = $true)][string] $Message
    )
    if ($null -ne $Actual) {
        Write-Fail ("{0} (expected null, got '{1}')" -f $Message, $Actual)
    }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$versionCheckScript = Join-Path $repoRoot 'scripts\internal\version-check.ps1'
if (-not (Test-Path -LiteralPath $versionCheckScript -PathType Leaf)) {
    Write-Fail "Missing version-check helper at $versionCheckScript"
}

Write-Host ''
Write-Host '=== Proposal 079 Version Info Four-State Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

# Dot-source the helper to access Get-SpecrewVersionStatus + Get-SpecrewSupportedVersions
. $versionCheckScript

# Clear any test env overrides so we test the file-backed declaration first
$originalSpeckitMax = [Environment]::GetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', 'Process')
$originalSquadMax = [Environment]::GetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', 'Process')
[Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $null, 'Process')
[Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $null, 'Process')

try {
    Write-Host "Test 1: Get-SpecrewSupportedVersions loads the shipped declaration"
    $declaration = Get-SpecrewSupportedVersions
    if ($null -eq $declaration) {
        Write-Fail "Declaration loaded as null; expected to find scripts/internal/supported-versions.yml"
    }
    Assert-Equal -Expected 'v1' -Actual $declaration.Schema -Message "Schema field parsed"
    Assert-Equal -Expected '0.8.4' -Actual $declaration.Speckit.Min -Message "Speckit.Min parsed"
    Assert-Equal -Expected '0.9.1' -Actual $declaration.Squad.Min -Message "Squad.Min parsed"
    if ([string]::IsNullOrWhiteSpace($declaration.Speckit.MaxTested)) {
        Write-Fail "Speckit.MaxTested is empty"
    }
    if ([string]::IsNullOrWhiteSpace($declaration.Squad.MaxTested)) {
        Write-Fail "Squad.MaxTested is empty"
    }
    Write-Pass "Speckit.MaxTested and Squad.MaxTested are populated"

    Write-Host ""
    Write-Host "Test 2: Get-SpecrewVersionStatus four-state logic"
    Assert-Equal -Expected 'not-installed' -Actual (Get-SpecrewVersionStatus -Current $null -Min '0.8.4' -MaxTested '0.8.4') -Message "null Current returns not-installed"
    Assert-Equal -Expected 'not-installed' -Actual (Get-SpecrewVersionStatus -Current '' -Min '0.8.4' -MaxTested '0.8.4') -Message "empty Current returns not-installed"
    Assert-Equal -Expected 'behind-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.3' -Min '0.8.4' -MaxTested '0.8.11') -Message "Current below Min returns behind-supported"
    Assert-Equal -Expected 'current' -Actual (Get-SpecrewVersionStatus -Current '0.8.11' -Min '0.8.4' -MaxTested '0.8.11') -Message "Current == MaxTested returns current"
    Assert-Equal -Expected 'update-available-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.5' -Min '0.8.4' -MaxTested '0.8.11') -Message "Min < Current < MaxTested returns update-available-supported"
    Assert-Equal -Expected 'update-available-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.4' -Min '0.8.4' -MaxTested '0.8.11') -Message "Current == Min < MaxTested returns update-available-supported"
    Assert-Equal -Expected 'ahead-of-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.12' -Min '0.8.4' -MaxTested '0.8.11') -Message "Current > MaxTested returns ahead-of-supported"
    Assert-Equal -Expected 'unknown' -Actual (Get-SpecrewVersionStatus -Current 'not-a-version' -Min '0.8.4' -MaxTested '0.8.11') -Message "Unparseable Current returns unknown"

    Write-Host ""
    Write-Host "Test 3: Env override SPECREW_SUPPORTED_MAX_SPECKIT replaces file value"
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', '99.0.0', 'Process')
    $overridden = Get-SpecrewSupportedVersions
    Assert-Equal -Expected '99.0.0' -Actual $overridden.Speckit.MaxTested -Message "Speckit.MaxTested env override applied"
    Assert-Equal -Expected $declaration.Speckit.Min -Actual $overridden.Speckit.Min -Message "Speckit.Min preserved (env override only touches MaxTested)"
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $null, 'Process')

    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', '99.0.0', 'Process')
    $overriddenSquad = Get-SpecrewSupportedVersions
    Assert-Equal -Expected '99.0.0' -Actual $overriddenSquad.Squad.MaxTested -Message "Squad.MaxTested env override applied"
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $null, 'Process')

    Write-Host ""
    Write-Host "Test 4: Missing-file fallback returns null (graceful degradation)"
    $bogusPath = Join-Path $repoRoot '.scratch\does-not-exist-supported-versions.yml'
    if (Test-Path -LiteralPath $bogusPath -PathType Leaf) {
        Remove-Item -LiteralPath $bogusPath -Force
    }
    Assert-Null -Actual (Get-SpecrewSupportedVersions -Path $bogusPath) -Message "Missing file returns null (caller falls back to two-state)"

    Write-Host ""
    Write-Host "Test 5: Malformed yml fallback returns null"
    $scratchDir = Join-Path $repoRoot '.scratch\version-info-states'
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    $malformedPath = Join-Path $scratchDir 'malformed.yml'
    [System.IO.File]::WriteAllText($malformedPath, "this is not yaml`nthis is just text`n", [System.Text.UTF8Encoding]::new($false))
    Assert-Null -Actual (Get-SpecrewSupportedVersions -Path $malformedPath) -Message "Malformed yml returns null (missing required fields)"

    Write-Host ""
    Write-Host "Test 6: Partial declaration (missing max_tested) returns null"
    $partialPath = Join-Path $scratchDir 'partial.yml'
    @'
schema: v1
speckit:
  min: "0.8.4"
squad:
  min: "0.9.1"
  max_tested: "0.9.4"
'@ | Set-Content -LiteralPath $partialPath -Encoding UTF8
    Assert-Null -Actual (Get-SpecrewSupportedVersions -Path $partialPath) -Message "Missing speckit.max_tested returns null (caller falls back)"

    Write-Host ""
    Write-Host "Test 7: Notes field optional and preserved when set"
    $notesPath = Join-Path $scratchDir 'with-notes.yml'
    @'
schema: v1
speckit:
  min: "0.8.4"
  max_tested: "0.8.4"
  notes: "0.8.12 released; adoption pending"
squad:
  min: "0.9.1"
  max_tested: "0.9.4"
  notes: ""
'@ | Set-Content -LiteralPath $notesPath -Encoding UTF8
    $notesDeclaration = Get-SpecrewSupportedVersions -Path $notesPath
    Assert-Equal -Expected '0.8.12 released; adoption pending' -Actual $notesDeclaration.Speckit.Notes -Message "Speckit.Notes preserved"
    Assert-Equal -Expected '' -Actual $notesDeclaration.Squad.Notes -Message "Squad.Notes empty when blank"

    Write-Host ""
    Write-Host "Test 8: Spec Kit 0.9.0 is within the supported window (feature 090 / spike-speckit-090)"
    # Churn-free lock: an installed 0.9.0 must resolve as supported against the SHIPPED
    # declaration (current or update-available-supported, never ahead/behind). Survives
    # future bumps above 0.9.0 without test edits.
    $shipped = Get-SpecrewSupportedVersions
    if ($null -eq $shipped) { Write-Fail "Shipped declaration loaded as null" }
    $status090 = Get-SpecrewVersionStatus -Current '0.9.0' -Min $shipped.Speckit.Min -MaxTested $shipped.Speckit.MaxTested
    if ($status090 -notin @('current', 'update-available-supported')) {
        Write-Fail ("Installed Spec Kit 0.9.0 resolves to '{0}'; expected supported (current/update-available-supported). Shipped max_tested='{1}'" -f $status090, $shipped.Speckit.MaxTested)
    }
    Write-Pass ("Spec Kit 0.9.0 resolves to '{0}' against the shipped declaration (supported)" -f $status090)
    # Four-state logic locked at a 0.9.0 ceiling (explicit params; churn-free).
    Assert-Equal -Expected 'current' -Actual (Get-SpecrewVersionStatus -Current '0.9.0' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.9.0 == max_tested 0.9.0 returns current"
    Assert-Equal -Expected 'update-available-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.18' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.8.18 < max_tested 0.9.0 returns update-available-supported"
    Assert-Equal -Expected 'ahead-of-supported' -Actual (Get-SpecrewVersionStatus -Current '0.9.1' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.9.1 > max_tested 0.9.0 returns ahead-of-supported"
}
finally {
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $originalSpeckitMax, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $originalSquadMax, 'Process')
}

Write-Host ""
Write-Host "All Proposal 079 version-info-states tests passed." -ForegroundColor Green
exit 0
