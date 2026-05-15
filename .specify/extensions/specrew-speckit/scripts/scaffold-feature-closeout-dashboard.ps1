[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$FeatureId,
    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Add-ScaffoldAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.ArrayList]$Actions,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Get-ResolvedFeatureDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath,
        [AllowNull()][string]$FeatureId
    )

    if (-not [string]::IsNullOrWhiteSpace($FeatureId)) {
        return Join-Path $ResolvedProjectPath ('specs\' + $FeatureId)
    }

    $featureJsonPath = Join-Path $ResolvedProjectPath '.specify\feature.json'
    if (-not (Test-Path -LiteralPath $featureJsonPath -PathType Leaf)) {
        throw "Cannot resolve the feature-closeout dashboard target because '.specify\feature.json' is missing."
    }

    $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
        throw "Cannot resolve the feature-closeout dashboard target because '.specify\feature.json' does not contain feature_directory."
    }

    $candidate = [string]$featureJson.feature_directory
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $ResolvedProjectPath $candidate
    }

    return [System.IO.Path]::GetFullPath($candidate)
}

$resolvedProjectPath = (Resolve-Path -Path (Resolve-ProjectPath -Path $ProjectPath)).Path
$featureDirectory = Get-ResolvedFeatureDirectory -ResolvedProjectPath $resolvedProjectPath -FeatureId $FeatureId
if (-not (Test-Path -LiteralPath $featureDirectory -PathType Container)) {
    throw "Feature directory '$featureDirectory' does not exist."
}

$featureRef = Split-Path -Leaf $featureDirectory
$targetPath = Join-Path $featureDirectory 'closeout-dashboard.md'
$rendererPath = Join-Path $resolvedProjectPath 'scripts\internal\dashboard-renderer.ps1'
if (-not (Test-Path -LiteralPath $rendererPath -PathType Leaf)) {
    throw "Velocity dashboard renderer '$rendererPath' is missing."
}
. $rendererPath

$actions = [System.Collections.ArrayList]::new()
if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
    Add-ScaffoldAction -Actions $actions -Action 'preserved' -Path $targetPath
}
else {
    Add-ScaffoldAction -Actions $actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $targetPath
    if (-not $DryRun) {
        $snapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $resolvedProjectPath -FeatureId $featureRef
        $lines = ConvertTo-SpecrewDashboardLines -Snapshot $snapshot
        $content = ConvertTo-SpecrewDashboardArtifactContent -Snapshot $snapshot -Lines $lines -CaptureKind 'feature-closeout' -HistoricalNotice $null
        Write-Utf8FileAtomic -Path $targetPath -Content $content
    }
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Feature closeout dashboard scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $targetPath)) -ForegroundColor Green
exit 0
