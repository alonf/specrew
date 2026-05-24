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

function Get-FeatureCloseoutIdentityBody {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath,
        [Parameter(Mandatory = $true)][string]$FeatureRef
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $featureLabel = Get-FeatureCloseoutNumberLabel -FeatureRef $FeatureRef
    $nextRoadmapItem = Get-NextRoadmapItemLabel -ResolvedProjectPath $ResolvedProjectPath
    return @(
        '# What We''re Focused On'
        ''
        ('No active feature. Last completed: {0} at {1}. Next roadmap item: {2} (not yet authorized).' -f $featureLabel, $timestamp, $nextRoadmapItem)
        ''
    ) -join [Environment]::NewLine
}

$syncBoundaryStateScript = Join-Path $PSScriptRoot 'sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $syncBoundaryStateScript -PathType Leaf)) {
    throw "Missing boundary-state sync helper '$syncBoundaryStateScript'."
}

function Get-ResolvedFeatureDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedProjectPath,
        [AllowNull()][string]$FeatureId
    )

    if (-not [string]::IsNullOrWhiteSpace($FeatureId)) {
        $exactPath = Join-Path $ResolvedProjectPath ('specs\' + $FeatureId)
        if (Test-Path -LiteralPath $exactPath -PathType Container) {
            return $exactPath
        }
        # Tolerate numeric-only IDs like "001" → prefix-match "specs/001-*"
        if ($FeatureId -match '^\d+$') {
            $specsRoot = Join-Path $ResolvedProjectPath 'specs'
            if (Test-Path -LiteralPath $specsRoot -PathType Container) {
                $match = @(Get-ChildItem -LiteralPath $specsRoot -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match ('^' + [regex]::Escape($FeatureId) + '-') } |
                    Sort-Object Name |
                    Select-Object -First 1)
                if ($match.Count -eq 1) {
                    return $match[0].FullName
                }
            }
        }
        return $exactPath
    }

    $featureJsonPath = Join-Path $ResolvedProjectPath '.specify\feature.json'
    if (-not (Test-Path -LiteralPath $featureJsonPath -PathType Leaf)) {
        throw "Cannot resolve the feature-closeout dashboard target because '.specify\feature.json' is missing."
    }

    $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 12

    # F-023: Legacy schema handling - missing 'schema' field implies v0
    $schema = Get-SpecrewStateSchemaVersion -State $featureJson -Path $featureJsonPath
    # v0 behavior: feature_directory field is required (old closeout scripts expect it)
    # v1+ behavior: same as v0 for this field (no behavioral divergence yet)

    if ([string]::IsNullOrWhiteSpace([string]$featureJson['feature_directory'])) {
        throw "Cannot resolve the feature-closeout dashboard target because '.specify\feature.json' does not contain feature_directory."
    }

    $candidate = [string]$featureJson['feature_directory']
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

# Resolve the velocity dashboard renderer. Two layouts supported (same pattern as the
# sync-boundary-state wrapper after F-040 dogfooding 2026-05-23):
#   1) Dev-tree: <project>/scripts/internal/dashboard-renderer.ps1
#   2) Downstream: <installed-Specrew-module-base>/scripts/internal/dashboard-renderer.ps1
$rendererPath = Join-Path $resolvedProjectPath 'scripts\internal\dashboard-renderer.ps1'
if (-not (Test-Path -LiteralPath $rendererPath -PathType Leaf)) {
    $specrewModule = Get-Module -Name 'Specrew' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $specrewModule) {
        $candidate = Join-Path $specrewModule.ModuleBase 'scripts\internal\dashboard-renderer.ps1'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $rendererPath = $candidate
        }
    }
}
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
        Write-Output ("WARN [dashboard] Velocity dashboard renderer '{0}' is missing; feature closeout snapshot not generated." -f $rendererPath)
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
            Write-Output ("WARN [dashboard] Unable to generate feature closeout snapshot: {0}" -f $_.Exception.Message)
            Add-ScaffoldAction -Actions $actions -Action 'warning' -Path $targetPath
        }
    }
}

if (-not $DryRun) {
    $identityPath = Get-FeatureCloseoutIdentityPath -ResolvedProjectPath $resolvedProjectPath
    $identityBody = Get-FeatureCloseoutIdentityBody -ResolvedProjectPath $resolvedProjectPath -FeatureRef $featureRef
    Add-ScaffoldAction -Actions $actions -Action 'updated' -Path $identityPath
    & $syncBoundaryStateScript -ProjectPath $resolvedProjectPath -BoundaryType 'feature-closeout' -FeatureRef $featureRef -IdentityFocusArea 'No active feature' -IdentityActiveIssues '[]' -IdentityBody $identityBody | Out-Null
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Output ("Feature closeout dashboard scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $targetPath))
exit 0
