[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Write-Fail $Message }
    Write-Pass $Message
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
$mirrorScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
$accessor = Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\workshop-controller-initialization'

Assert-True (Test-Path -LiteralPath $sourceScript -PathType Leaf) 'pre-agenda initializer source exists'
Assert-True (Test-Path -LiteralPath $mirrorScript -PathType Leaf) 'pre-agenda initializer project mirror exists'
Assert-True ((Get-Content -LiteralPath $sourceScript -Raw -Encoding UTF8) -eq
    (Get-Content -LiteralPath $mirrorScript -Raw -Encoding UTF8)) 'pre-agenda initializer source and project mirror are byte-identical'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    $project = Join-Path $scratchRoot 'governed'
    $featureRoot = Join-Path $project 'specs\001-article-amplifier'
    New-Item -ItemType Directory -Path (Join-Path $project '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $featureRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $project '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $featureRoot 'spec.md') -Value '# Article Amplifier' -Encoding UTF8

    $created = & $sourceScript -ProjectRoot $project -FeatureRef '001-article-amplifier' -PassThru
    $statePath = Join-Path $featureRoot 'lens-applicability.json'
    Assert-True (Test-Path -LiteralPath $statePath -PathType Leaf) 'initializer writes the exact feature-level controller artifact'
    Assert-True ([string]$created.state -eq 'pending-confirmation' -and [string]$created.artifact_path -eq $statePath) 'initializer reports its exact durable target'

    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8
    Assert-True ($state.workshop_intake -eq $true -and $state.confirmation_required -eq $true -and
        [string]$state.agenda_status -eq 'pending-confirmation') 'initializer writes the required controller flags and pre-agenda status'
    Assert-True ([string]$state.agenda_contract -eq 'complete-coverage-v1' -and [string]$state.human_turn_contract -eq 'typed-turns-v1' -and
        @($state.selected).Count -eq 0 -and @($state.agenda.PSObject.Properties).Count -eq 0 -and
        @($state.skipped.PSObject.Properties).Count -eq 0 -and @($state.workshop.PSObject.Properties).Count -eq 0 -and
        [string]$state.agenda_confirmation -eq 'pending' -and [string]$state.agenda_confirmation_scope -eq 'lens-selection' -and [string]$state.agenda_turn_receipt -eq 'pending') 'pre-agenda state requires complete selected/skipped coverage and typed human authority before lens 1'

    . $accessor
    $lifecycle = Get-SpecrewWorkshopLifecycleState -ProjectRoot $project -FeatureRef '001-article-amplifier'
    Assert-True ($lifecycle.status -eq 'active' -and $lifecycle.reason -eq 'workshop-pre-agenda-active' -and
        $lifecycle.current_lens -eq 'product-domain') 'initializer output is accepted by the strict lifecycle accessor as product-domain authority'

    $before = [IO.File]::ReadAllBytes($statePath)
    $overwriteRefused = $false
    try {
        & $sourceScript -ProjectRoot $project -FeatureRef '001-article-amplifier' | Out-Null
    }
    catch {
        $overwriteRefused = ($_.Exception.Message -match 'Refusing to overwrite')
    }
    $after = [IO.File]::ReadAllBytes($statePath)
    Assert-True $overwriteRefused 'initializer refuses to overwrite any existing workshop artifact'
    Assert-True ([Convert]::ToBase64String($before) -eq [Convert]::ToBase64String($after)) 'overwrite refusal preserves the existing artifact byte-for-byte'

    $ungoverned = Join-Path $scratchRoot 'ungoverned'
    $ungovernedFeature = Join-Path $ungoverned 'specs\001-feature'
    New-Item -ItemType Directory -Path $ungovernedFeature -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $ungovernedFeature 'spec.md') -Value '# Feature' -Encoding UTF8
    $ungovernedRefused = $false
    try {
        & $sourceScript -ProjectRoot $ungoverned -FeatureRef '001-feature' | Out-Null
    }
    catch {
        $ungovernedRefused = ($_.Exception.Message -match 'Specrew-governed')
    }
    Assert-True $ungovernedRefused 'initializer refuses non-Specrew projects'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $ungovernedFeature 'lens-applicability.json'))) 'non-Specrew refusal leaves no partial state'

    $incomplete = Join-Path $scratchRoot 'incomplete'
    New-Item -ItemType Directory -Path (Join-Path $incomplete '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $incomplete 'specs\001-feature') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $incomplete '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    $incompleteRefused = $false
    try {
        & $sourceScript -ProjectRoot $incomplete -FeatureRef '001-feature' | Out-Null
    }
    catch {
        $incompleteRefused = ($_.Exception.Message -match 'spec.md is missing')
    }
    Assert-True $incompleteRefused 'initializer refuses an incomplete feature scaffold'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $incomplete 'specs\001-feature\lens-applicability.json'))) 'incomplete-scaffold refusal leaves no partial state'
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Host "`nworkshop controller initialization: all assertions pass" -ForegroundColor Green
exit 0
