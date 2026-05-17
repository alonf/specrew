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

function Get-FeatureCloseoutIdentityPath {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath
    )

    return Join-Path $ResolvedProjectPath '.squad\identity\now.md'
}

function Get-FeatureCloseoutNumberLabel {
    param(
        [Parameter(Mandatory = $true)][string]$FeatureRef
    )

    if ($FeatureRef -match '^(?<number>\d{3})') {
        return "Feature $($Matches['number'])"
    }

    return $FeatureRef
}

function Get-NextRoadmapItemLabel {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath
    )

    if (-not (Get-Command Read-SpecrewRoadmapDefinition -ErrorAction SilentlyContinue)) {
        return 'Roadmap update pending'
    }

    $roadmapDefinition = Read-SpecrewRoadmapDefinition -ProjectRoot $ResolvedProjectPath
    $nextPhase = @($roadmapDefinition.phases | Where-Object { $_.status -eq 'queued' } | Select-Object -First 1)
    if ($nextPhase.Count -eq 0) {
        $nextPhase = @($roadmapDefinition.phases | Where-Object { $_.status -ne 'shipped' } | Select-Object -First 1)
    }

    if ($nextPhase.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$nextPhase[0].name)) {
        return [string]$nextPhase[0].name
    }

    return 'Roadmap update pending'
}

function Set-FeatureCloseoutIdentityNow {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath,
        [Parameter(Mandatory = $true)][string]$FeatureRef
    )

    $identityPath = Get-FeatureCloseoutIdentityPath -ResolvedProjectPath $ResolvedProjectPath
    $identityDirectory = Split-Path -Parent $identityPath
    if (-not (Test-Path -LiteralPath $identityDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $identityDirectory -Force
    }

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $featureLabel = Get-FeatureCloseoutNumberLabel -FeatureRef $FeatureRef
    $nextRoadmapItem = Get-NextRoadmapItemLabel -ResolvedProjectPath $ResolvedProjectPath
    $content = @(
        '---'
        ('updated_at: {0}' -f $timestamp)
        'focus_area: No active feature'
        'active_issues: []'
        '---'
        ''
        '# What We''re Focused On'
        ''
        ('No active feature. Last completed: {0} at {1}. Next roadmap item: {2} (not yet authorized).' -f $featureLabel, $timestamp, $nextRoadmapItem)
        ''
    ) -join [Environment]::NewLine

    [System.IO.File]::WriteAllText($identityPath, $content, [System.Text.UTF8Encoding]::new($false))
    return $identityPath
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

if (-not $DryRun) {
    $identityPath = Set-FeatureCloseoutIdentityNow -ResolvedProjectPath $resolvedProjectPath -FeatureRef $featureRef
    Add-ScaffoldAction -Actions $actions -Action 'updated' -Path $identityPath
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Feature closeout dashboard scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $targetPath)) -ForegroundColor Green
exit 0
