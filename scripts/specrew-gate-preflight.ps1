[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [Parameter(Mandatory)][ValidateSet('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')][string]$Boundary,
    [AllowNull()][string]$Feature,
    [AllowNull()][string]$Iteration,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $moduleRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
. (Join-Path $PSScriptRoot 'internal/gate-preflight.ps1')

$result = Invoke-SpecrewGatePreflight -ProjectRoot $ProjectPath -BoundaryType $Boundary -FeatureRef $Feature -IterationNumber $Iteration
if ($Json.IsPresent) { $result | ConvertTo-Json -Depth 12 } else { $result.checks | Format-Table name, status, message -AutoSize }
if (-not $result.ok) { exit 1 }
