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

function Assert-NotEqual {
    param(
        [Parameter(Mandatory = $true)] $Unexpected,
        [AllowNull()] $Actual,
        [Parameter(Mandatory = $true)][string] $Message
    )
    if ($Unexpected -eq $Actual) {
        Write-Fail ("{0} (expected NOT '{1}', but got it)" -f $Message, $Unexpected)
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
    Assert-Equal -Expected '0.12.9' -Actual $declaration.Speckit.Min -Message "Speckit.Min parsed"
    Assert-Equal -Expected '0.11.0' -Actual $declaration.Squad.Min -Message "Squad.Min parsed"
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
    $bogusPath = Join-Path $repoRoot '.scratch/does-not-exist-supported-versions.yml'
    if (Test-Path -LiteralPath $bogusPath -PathType Leaf) {
        Remove-Item -LiteralPath $bogusPath -Force
    }
    Assert-Null -Actual (Get-SpecrewSupportedVersions -Path $bogusPath) -Message "Missing file returns null (caller falls back to two-state)"

    Write-Host ""
    Write-Host "Test 5: Malformed yml fallback returns null"
    $scratchDir = Join-Path $repoRoot '.scratch/version-info-states'
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
    Write-Host "Test 8: the shipped PIN is within its own supported window (F-198 single-tested-pin, I2)"
    # Churn-free lock: the shipped min must resolve as supported against the SHIPPED
    # declaration (current or update-available-supported, never ahead/behind), whatever
    # the pin is. Pre-pin versions (e.g. 0.9.0, the pre-0.10.0 --ai syntax era) must now
    # resolve behind-supported: the 0.10.0 flag break makes them incompatible with the
    # deployed init surface (F-198 T001 probe evidence).
    $shipped = Get-SpecrewSupportedVersions
    if ($null -eq $shipped) { Write-Fail "Shipped declaration loaded as null" }
    $statusPin = Get-SpecrewVersionStatus -Current $shipped.Speckit.Min -Min $shipped.Speckit.Min -MaxTested $shipped.Speckit.MaxTested
    if ($statusPin -notin @('current', 'update-available-supported')) {
        Write-Fail ("Installed Spec Kit {0} resolves to '{1}'; expected supported (current/update-available-supported). Shipped max_tested='{2}'" -f $shipped.Speckit.Min, $statusPin, $shipped.Speckit.MaxTested)
    }
    Write-Pass ("Spec Kit {0} resolves to '{1}' against the shipped declaration (supported)" -f $shipped.Speckit.Min, $statusPin)
    $statusPrePin = Get-SpecrewVersionStatus -Current '0.9.0' -Min $shipped.Speckit.Min -MaxTested $shipped.Speckit.MaxTested
    Assert-Equal -Expected 'behind-supported' -Actual $statusPrePin -Message "pre-break 0.9.0 resolves behind-supported against the shipped pin"
    # Four-state logic locked at a fixed ceiling (explicit params; churn-free).
    Assert-Equal -Expected 'current' -Actual (Get-SpecrewVersionStatus -Current '0.9.0' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.9.0 == max_tested 0.9.0 returns current"
    Assert-Equal -Expected 'update-available-supported' -Actual (Get-SpecrewVersionStatus -Current '0.8.18' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.8.18 < max_tested 0.9.0 returns update-available-supported"
    Assert-Equal -Expected 'ahead-of-supported' -Actual (Get-SpecrewVersionStatus -Current '0.9.1' -Min '0.8.4' -MaxTested '0.9.0') -Message "0.9.1 > max_tested 0.9.0 returns ahead-of-supported"

    Write-Host ""
    Write-Host "Test 9: Get-SpecrewVersionInfoFromManifest surfaces the prerelease label (finding #2)"
    # The report must show 0.31.0-beta3, not a bare 0.31.0 indistinguishable from a stable build —
    # while the BASE version (Version) still feeds every semver comparison unchanged.
    $preManifest = Join-Path $scratchDir 'prerelease.psd1'
    Set-Content -LiteralPath $preManifest -Encoding UTF8 -Value "@{ ModuleVersion = '0.31.0'; PrivateData = @{ PSData = @{ Prerelease = 'beta3' } } }"
    $preInfo = Get-SpecrewVersionInfoFromManifest -ManifestPath $preManifest
    Assert-Equal -Expected '0.31.0' -Actual $preInfo.Version -Message "prerelease manifest: base Version 0.31.0 (feeds semver compare)"
    Assert-Equal -Expected 'beta3' -Actual $preInfo.Prerelease -Message "prerelease manifest: Prerelease label parsed"
    Assert-Equal -Expected '0.31.0-beta3' -Actual $preInfo.Display -Message "prerelease manifest: Display = base-label"

    $stableManifest = Join-Path $scratchDir 'stable.psd1'
    Set-Content -LiteralPath $stableManifest -Encoding UTF8 -Value "@{ ModuleVersion = '0.31.0'; PrivateData = @{ PSData = @{ Prerelease = '' } } }"
    Assert-Equal -Expected '0.31.0' -Actual (Get-SpecrewVersionInfoFromManifest -ManifestPath $stableManifest).Display -Message "stable manifest: Display is bare base (no -label)"

    $noPsData = Join-Path $scratchDir 'no-psdata.psd1'
    Set-Content -LiteralPath $noPsData -Encoding UTF8 -Value "@{ ModuleVersion = '0.29.0' }"
    Assert-Equal -Expected '0.29.0' -Actual (Get-SpecrewVersionInfoFromManifest -ManifestPath $noPsData).Display -Message "manifest without PSData: Display is base version"

    Assert-Null -Actual (Get-SpecrewVersionInfoFromManifest -ManifestPath (Join-Path $scratchDir 'does-not-exist.psd1')) -Message "missing manifest returns null"

    Write-Host ""
    Write-Host "Test 10: SPECREW_MODULE_PATH dev-trial override is honored as the installed version (F-044 parity)"
    # The dev-trial dispatcher (Specrew.psm1) runs the override tree's code, so the version probe must report
    # THAT tree's version -- not a stale Gallery copy on PSModulePath -- or every unpublished-branch dev-trial
    # shows a false INCOMPATIBLE. The override is honored ONLY for a valid tree (Specrew.psd1 + scripts/specrew.ps1).
    $originalModulePath = [Environment]::GetEnvironmentVariable('SPECREW_MODULE_PATH', 'Process')
    $overrideTree = Join-Path $scratchDir 'override-tree'
    $overrideScripts = Join-Path $overrideTree 'scripts'
    $null = New-Item -ItemType Directory -Path $overrideScripts -Force
    Set-Content -LiteralPath (Join-Path $overrideTree 'Specrew.psd1') -Encoding UTF8 -Value "@{ ModuleVersion = '9.99.0'; PrivateData = @{ PSData = @{ Prerelease = 'devtrial' } } }"
    Set-Content -LiteralPath (Join-Path $overrideScripts 'specrew.ps1') -Encoding UTF8 -Value "# stub CLI entry (validity marker the dispatcher checks)"
    try {
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $overrideTree, 'Process')
        Assert-Equal -Expected '9.99.0' -Actual (Get-SpecrewInstalledVersion -ProjectRoot $repoRoot) -Message "valid override tree: Get-SpecrewInstalledVersion returns the override version"
        Assert-Equal -Expected '9.99.0-devtrial' -Actual (Get-SpecrewInstalledVersionInfo -ProjectRoot $repoRoot).Display -Message "valid override tree: Get-SpecrewInstalledVersionInfo surfaces override Display + prerelease"

        # Manifest present but NO scripts/specrew.ps1 marker -> not a real dispatch tree -> ignored, falls through.
        $invalidTree = Join-Path $scratchDir 'override-invalid'
        $null = New-Item -ItemType Directory -Path $invalidTree -Force
        Set-Content -LiteralPath (Join-Path $invalidTree 'Specrew.psd1') -Encoding UTF8 -Value "@{ ModuleVersion = '9.99.0'; PrivateData = @{ PSData = @{ Prerelease = 'devtrial' } } }"
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $invalidTree, 'Process')
        Assert-NotEqual -Unexpected '9.99.0' -Actual (Get-SpecrewInstalledVersion -ProjectRoot $repoRoot) -Message "override tree missing scripts/specrew.ps1 is ignored (falls through to normal resolution)"

        # Nonexistent override path -> ignored.
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', (Join-Path $scratchDir 'override-does-not-exist'), 'Process')
        Assert-NotEqual -Unexpected '9.99.0' -Actual (Get-SpecrewInstalledVersion -ProjectRoot $repoRoot) -Message "nonexistent override path is ignored (falls through)"
    }
    finally {
        [Environment]::SetEnvironmentVariable('SPECREW_MODULE_PATH', $originalModulePath, 'Process')
    }
}
finally {
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SPECKIT', $originalSpeckitMax, 'Process')
    [Environment]::SetEnvironmentVariable('SPECREW_SUPPORTED_MAX_SQUAD', $originalSquadMax, 'Process')
}

Write-Host ""
Write-Host "All Proposal 079 version-info-states tests passed." -ForegroundColor Green
exit 0
