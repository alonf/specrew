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

$searchRoot = $PSScriptRoot
while (-not [string]::IsNullOrWhiteSpace($searchRoot)) {
    if (Test-Path -LiteralPath (Join-Path $searchRoot '.specrew\config.yml') -PathType Leaf) {
        break
    }

    $parent = Split-Path -Parent $searchRoot
    if ($parent -eq $searchRoot) {
        $searchRoot = $null
        break
    }

    $searchRoot = $parent
}

if ([string]::IsNullOrWhiteSpace($searchRoot)) {
    throw 'Unable to locate the Specrew repository root for sync-boundary-state.'
}

$internalScriptPath = Join-Path $searchRoot 'scripts\internal\sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $internalScriptPath -PathType Leaf)) {
    throw "Missing internal sync helper '$internalScriptPath'."
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
