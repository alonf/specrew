[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [Parameter(Mandatory = $true)]
    [string]$BoundaryType,
    [string]$FeatureRef,
    [string]$IterationNumber,
    [string]$TaskId,
    [string]$AuthCommitHash,
    [string]$IdentityFocusArea,
    [string]$IdentityActiveIssues,
    [string]$IdentityBody,
    [string]$HandoffText
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the internal sync helper. Three layouts (in priority order):
#
#   0) Explicit override via $env:SPECREW_MODULE_PATH (iter-006 T001). Set by
#      Specrew.psm1 at import time so agent-spawned child PowerShell processes
#      dispatch to the actively-imported Dev tree instead of a stale PSGallery install.
#
#   1) Specrew dev-tree dogfooding: walk up from $PSScriptRoot looking for a dir
#      that contains BOTH .specrew/config.yml AND scripts/internal/sync-boundary-state.ps1.
#
#   2) Downstream project: discover via Get-Module -Name Specrew -ListAvailable
#      (highest version wins).
#
# iter-006 T001 also adds STALE-INSTALL DETECTION (after resolution): compares the
# resolved module's version against the project's `.specrew/config.yml::specrew_version`.
# If installed < expected, refuses to dispatch with actionable guidance.

$internalScriptPath = $null
$resolvedModuleBase = $null
$resolvedModuleVersion = $null

function _Read-SpecrewVersionFromPsd1 {
    param([string]$ModuleBase)
    $psd1Path = Join-Path $ModuleBase 'Specrew.psd1'
    if (-not (Test-Path -LiteralPath $psd1Path -PathType Leaf)) { return $null }
    try {
        $manifest = Import-PowerShellDataFile -LiteralPath $psd1Path
        return [version][string]$manifest.ModuleVersion
    } catch {
        return $null
    }
}

# Path 0: explicit env override (iter-006 T001).
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) {
    $candidate = Join-Path $env:SPECREW_MODULE_PATH 'scripts' 'internal' 'sync-boundary-state.ps1'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        $internalScriptPath = $candidate
        $resolvedModuleBase = $env:SPECREW_MODULE_PATH
        $resolvedModuleVersion = _Read-SpecrewVersionFromPsd1 -ModuleBase $env:SPECREW_MODULE_PATH
    }
}

# Path 1: dev-tree layout (walk up to find Specrew's own repo root).
if ([string]::IsNullOrWhiteSpace($internalScriptPath)) {
    $searchRoot = $PSScriptRoot
    while (-not [string]::IsNullOrWhiteSpace($searchRoot)) {
        $candidate = Join-Path $searchRoot 'scripts' 'internal' 'sync-boundary-state.ps1'
        $configExists = Test-Path -LiteralPath (Join-Path $searchRoot '.specrew' 'config.yml') -PathType Leaf
        $candidateExists = Test-Path -LiteralPath $candidate -PathType Leaf
        if ($configExists -and $candidateExists) {
            $internalScriptPath = $candidate
            $resolvedModuleBase = $searchRoot
            $resolvedModuleVersion = _Read-SpecrewVersionFromPsd1 -ModuleBase $searchRoot
            break
        }

        $parent = Split-Path -Parent $searchRoot
        if ($parent -eq $searchRoot) {
            break
        }
        $searchRoot = $parent
    }
}

# Path 2: installed Specrew module (highest version wins).
if ([string]::IsNullOrWhiteSpace($internalScriptPath)) {
    $specrewModule = Get-Module -Name 'Specrew' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $specrewModule) {
        $candidate = Join-Path $specrewModule.ModuleBase 'scripts' 'internal' 'sync-boundary-state.ps1'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $internalScriptPath = $candidate
            $resolvedModuleBase = $specrewModule.ModuleBase
            $resolvedModuleVersion = $specrewModule.Version
        }
    }
}

if ([string]::IsNullOrWhiteSpace($internalScriptPath)) {
    throw @"
Unable to locate the internal sync-boundary-state helper. Checked:
  0) `$env:SPECREW_MODULE_PATH (not set or no helper at that path)
  1) Dev-tree walk-up from '$PSScriptRoot' (no .specrew/config.yml + scripts/internal/ pair found)
  2) Installed Specrew module (Get-Module -Name Specrew -ListAvailable returned nothing usable)

Fix one of:
  - Install Specrew:     Install-Module -Name Specrew
  - Dogfood Dev tree:    Import-Module <path>/Specrew.psm1 -Force  (auto-sets `$env:SPECREW_MODULE_PATH)
  - Override manually:   `$env:SPECREW_MODULE_PATH = '<path-to-Specrew-repo>'
"@
}

# iter-006 T001: stale-install detection — compare resolved version against project's expected version.
$projectConfigPath = Join-Path $ProjectPath '.specrew' 'config.yml'
if ((Test-Path -LiteralPath $projectConfigPath -PathType Leaf) -and ($null -ne $resolvedModuleVersion)) {
    $configLines = Get-Content -LiteralPath $projectConfigPath -ErrorAction SilentlyContinue
    $expectedRaw = $configLines | ForEach-Object {
        if ($_ -match '^\s*specrew_version:\s*[''"]?([^''"#]+?)[''"]?\s*(?:#.*)?$') {
            $Matches[1].Trim()
        }
    } | Select-Object -First 1
    if (-not [string]::IsNullOrWhiteSpace($expectedRaw)) {
        try {
            $expectedVersion = [version]$expectedRaw
            if ($resolvedModuleVersion -lt $expectedVersion) {
                throw @"
Stale Specrew install — boundary-sync dispatch refused (iter-006 T001 stale-install check).

  Project expects: $expectedVersion  (from $projectConfigPath::specrew_version)
  Resolved:        $resolvedModuleVersion  (from $resolvedModuleBase)

The internal helpers in the resolved module may lack support for boundary types
the deployed shim assumes, causing silent contract drift (which is what surfaced
in the F-044 iter-006 Antigravity dogfood — sync silently routed to a stale
0.25.0 install and the agent had to patch deployed scaffolders).

Fix one of:
  1. 'specrew update'  — bring the installed module up to project expectations.
  2. Import the active Dev tree:  Import-Module <dev-path>/Specrew.psm1 -Force
     (auto-sets `$env:SPECREW_MODULE_PATH so child processes inherit the path).
  3. Manual override:  `$env:SPECREW_MODULE_PATH = '<dev-tree>'
"@
            }
        } catch [System.Management.Automation.RuntimeException] {
            # Re-throw our own stale-install error
            throw
        }
    }
}
. $internalScriptPath

$result = Invoke-SpecrewBoundaryStateSync `
    -ProjectPath $ProjectPath `
    -BoundaryType $BoundaryType `
    -FeatureRef $FeatureRef `
    -IterationNumber $IterationNumber `
    -TaskId $TaskId `
    -AuthCommitHash $AuthCommitHash `
    -IdentityFocusArea $IdentityFocusArea `
    -IdentityActiveIssues $IdentityActiveIssues `
    -IdentityBody $IdentityBody `
    -HandoffText $HandoffText

if ($null -ne $result) {
    $result | ConvertTo-Json -Depth 6 | Write-Output
}
