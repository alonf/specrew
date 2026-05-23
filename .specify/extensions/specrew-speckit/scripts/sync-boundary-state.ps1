[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [Parameter(Mandatory = $true)]
    [ValidateSet('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')]
    [string]$BoundaryType,
    [string]$FeatureRef,
    [string]$IterationNumber,
    [string]$TaskId,
    [string]$AuthCommitHash,
    [string]$IdentityFocusArea,
    [string]$IdentityActiveIssues,
    [string]$IdentityBody
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve the internal sync helper. Two layouts are supported:
#
#   1) Downstream project: the wrapper is deployed to
#      `<project>/.specify/extensions/specrew-speckit/scripts/`, and the internal
#      helper lives inside the installed Specrew PowerShell module at
#      `<module-base>/scripts/internal/sync-boundary-state.ps1`. Discovered via
#      `Get-Module -Name Specrew -ListAvailable`.
#
#   2) Specrew dev-tree dogfooding: the wrapper is mirrored at
#      `<specrew>/.specify/extensions/specrew-speckit/scripts/`, and the internal
#      helper lives alongside it at `<specrew>/scripts/internal/sync-boundary-state.ps1`.
#      Resolved by walking up from $PSScriptRoot until a `.specrew/config.yml` is found.
#
# Try the dev-tree path first when we're inside Specrew's own repo (so dogfooding edits
# to scripts/internal/sync-boundary-state.ps1 take effect without reinstalling the
# module). Fall back to the installed module for every other project.

$internalScriptPath = $null

# Path 1: dev-tree layout (walk up to find Specrew's own repo root).
$searchRoot = $PSScriptRoot
while (-not [string]::IsNullOrWhiteSpace($searchRoot)) {
    $candidate = Join-Path $searchRoot 'scripts\internal\sync-boundary-state.ps1'
    if ((Test-Path -LiteralPath (Join-Path $searchRoot '.specrew\config.yml') -PathType Leaf) -and
        (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $internalScriptPath = $candidate
        break
    }

    $parent = Split-Path -Parent $searchRoot
    if ($parent -eq $searchRoot) {
        break
    }
    $searchRoot = $parent
}

# Path 2: installed Specrew module.
if ([string]::IsNullOrWhiteSpace($internalScriptPath)) {
    $specrewModule = Get-Module -Name 'Specrew' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $specrewModule) {
        $candidate = Join-Path $specrewModule.ModuleBase 'scripts\internal\sync-boundary-state.ps1'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $internalScriptPath = $candidate
        }
    }
}

if ([string]::IsNullOrWhiteSpace($internalScriptPath)) {
    throw "Unable to locate the internal sync-boundary-state helper. Checked the downstream-project layout (walked up from '$PSScriptRoot' for scripts\internal\sync-boundary-state.ps1) and the installed Specrew module (Get-Module -Name Specrew -ListAvailable). If you're running this from a downstream project, ensure the Specrew module is installed: 'Install-Module -Name Specrew'."
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
    -IdentityBody $IdentityBody

if ($null -ne $result) {
    $result | ConvertTo-Json -Depth 6 | Write-Output
}
