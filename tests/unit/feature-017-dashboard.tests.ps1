[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$rendererPath = Join-Path $repoRoot 'scripts\internal\dashboard-renderer.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\feature-017-dashboard\healthy-repository'

. $rendererPath

$previousNoColor = $env:NO_COLOR
try {
    $env:NO_COLOR = '1'
    Assert-True -Condition ((Get-SpecrewDashboardColorMode) -eq 'monochrome') -Message 'NO_COLOR should force monochrome rendering.'
}
finally {
    $env:NO_COLOR = $previousNoColor
}

$roadmap = Read-SpecrewRoadmapDefinition -ProjectRoot $fixtureRoot
Assert-True -Condition $roadmap.exists -Message 'Healthy fixture roadmap should exist.'
Assert-True -Condition ($roadmap.phases.Count -eq 2) -Message 'Healthy fixture roadmap should expose two phases.'

$features = @(Get-SpecrewFeatureRecords -ProjectRoot $fixtureRoot)
$progress = Get-SpecrewRoadmapProgress -RoadmapDefinition $roadmap -FeatureRecords $features
Assert-True -Condition ($progress.warnings.Count -eq 0) -Message 'Healthy fixture roadmap should not drift or reference missing features.'

$snapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $fixtureRoot -Team
Assert-True -Condition ($snapshot.warnings -contains 'Team mode is reserved for future multi-developer support; rendering the personal dashboard instead.') -Message '--team should add the reserved-path warning.'

$artifactText = ConvertTo-SpecrewDashboardArtifactContent -Snapshot $snapshot -Lines (ConvertTo-SpecrewCompactDashboardLines -Snapshot $snapshot) -CaptureKind 'feature-closeout' -HistoricalNotice $null
Assert-True -Condition ($artifactText -match 'Historical snapshot captured during feature closeout') -Message 'Feature-closeout artifact should include the historical notice.'
Assert-True -Condition ($artifactText -match '## Dashboard') -Message 'Artifact content should include the dashboard section heading.'
Assert-True -Condition ($artifactText -match 'SPECREW VELOCITY DASHBOARD') -Message 'Artifact content should preserve the rendered dashboard payload.'

$lowIterations = 1..3 | ForEach-Object {
    [pscustomobject]@{
        actual_story_points = 5
        elapsed_days        = 2
        closed_at           = (Get-Date).AddDays(-$_)
    }
}
$moderateIterations = 1..4 | ForEach-Object {
    [pscustomobject]@{
        actual_story_points = 5
        elapsed_days        = 2
        closed_at           = (Get-Date).AddDays(-$_)
    }
}
$highIterations = 1..10 | ForEach-Object {
    [pscustomobject]@{
        actual_story_points = 5
        elapsed_days        = 2
        closed_at           = (Get-Date).AddDays(-$_)
    }
}

Assert-True -Condition ((Get-SpecrewVelocityHeadline -ClosedIterations $lowIterations).confidence -eq 'low') -Message 'Confidence should be low for 1-3 iterations.'
Assert-True -Condition ((Get-SpecrewVelocityHeadline -ClosedIterations $moderateIterations).confidence -eq 'moderate') -Message 'Confidence should be moderate for 4-9 iterations.'
Assert-True -Condition ((Get-SpecrewVelocityHeadline -ClosedIterations $highIterations).confidence -eq 'high') -Message 'Confidence should be high for 10+ iterations.'

Write-Pass 'Feature 017 dashboard unit coverage: color policy, roadmap parsing, roadmap progress, team fallback warning, confidence mapping, and artifact rendering'
exit 0
