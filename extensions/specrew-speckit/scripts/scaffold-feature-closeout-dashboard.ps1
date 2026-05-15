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
$rendererAvailable = Test-Path -LiteralPath $rendererPath -PathType Leaf
if ($rendererAvailable) {
    . $rendererPath
}

$actions = [System.Collections.ArrayList]::new()
if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
    Add-ScaffoldAction -Actions $actions -Action 'preserved' -Path $targetPath
}
else {
    if ($DryRun) {
        Add-ScaffoldAction -Actions $actions -Action 'would-create' -Path $targetPath
    }
    elseif (-not $rendererAvailable) {
        Write-Host ("WARN [dashboard] Velocity dashboard renderer '{0}' is missing; feature closeout snapshot not generated." -f $rendererPath) -ForegroundColor Yellow
        Add-ScaffoldAction -Actions $actions -Action 'warning' -Path $targetPath
    }
    else {
        try {
            $snapshotParameters = @{
                ProjectRoot = $resolvedProjectPath
                FeatureId   = $featureRef
            }
            if ((Get-Command Get-SpecrewDashboardSnapshot -ErrorAction SilentlyContinue).Parameters.ContainsKey('CaptureKind')) {
                $snapshotParameters.CaptureKind = 'feature-closeout'
            }
            $snapshot = Get-SpecrewDashboardSnapshot @snapshotParameters
            $lines = ConvertTo-SpecrewDashboardLines -Snapshot $snapshot
            $content = ConvertTo-SpecrewDashboardArtifactContent -Snapshot $snapshot -Lines $lines -CaptureKind 'feature-closeout' -HistoricalNotice $null
            Write-Utf8FileAtomic -Path $targetPath -Content $content
            Add-ScaffoldAction -Actions $actions -Action 'created' -Path $targetPath
        }
        catch {
            Write-Host ("WARN [dashboard] Unable to generate feature closeout snapshot: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            Add-ScaffoldAction -Actions $actions -Action 'warning' -Path $targetPath
        }
    }
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Feature closeout dashboard scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $targetPath)) -ForegroundColor Green
exit 0
