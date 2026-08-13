[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initializer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
$writer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1'
$mirror = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\confirm-workshop-agenda.ps1'
$accessor = Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1'
$catalogSource = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\index.yml'

Assert-True (Test-Path -LiteralPath $writer -PathType Leaf) 'agenda confirmation writer exists'
Assert-True (Test-Path -LiteralPath $mirror -PathType Leaf) 'agenda confirmation deployed mirror exists'
Assert-True ((Get-Content -LiteralPath $writer -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $mirror -Raw -Encoding UTF8)) 'agenda confirmation source and deployed mirror are byte-identical'

$scratch = Join-Path ([IO.Path]::GetTempPath()) ('specrew-agenda-confirmation-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch '.specify\extensions\specrew-speckit\knowledge\design-lenses') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $scratch 'specs\001-url-checker') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch '.specrew\config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scratch 'specs\001-url-checker\spec.md') -Value '# URL Checker' -Encoding UTF8
    Copy-Item -LiteralPath $catalogSource -Destination (Join-Path $scratch '.specify\extensions\specrew-speckit\knowledge\design-lenses\index.yml') -Force

    & $initializer -ProjectRoot $scratch -FeatureRef '001-url-checker'
    $statePath = Join-Path $scratch 'specs\001-url-checker\lens-applicability.json'
    $before = [IO.File]::ReadAllBytes($statePath)
    $incompleteRefused = $false
    try {
        & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' `
            -SelectedLens @('architecture-core', 'requirements-nfr') `
            -SelectedDepth @('medium', 'light') `
            -SelectedDecision @('Choose the processing pipeline.', 'Choose timeouts and exit codes.') `
            -SkippedLens @('data-storage') `
            -SkippedReason @('No persistent state.') | Out-Null
    }
    catch { $incompleteRefused = ($_.Exception.Message -match 'Every technical lens must be selected or visibly skipped') }
    $afterRefusal = [IO.File]::ReadAllBytes($statePath)
    Assert-True $incompleteRefused 'writer refuses an agenda that hides omitted lenses'
    Assert-True ([Convert]::ToBase64String($before) -eq [Convert]::ToBase64String($afterRefusal)) 'incomplete-coverage refusal preserves pending controller state byte-for-byte'

    $selected = @('architecture-core', 'requirements-nfr', 'integration-api', 'code-implementation')
    $depths = @('medium', 'light', 'medium', 'medium')
    $decisions = @(
        'Choose the processing pipeline and concurrency boundary.',
        'Choose timeouts, error output, and exit codes.',
        'Choose HTTP behavior for external reference checks.',
        'Choose C# implementation and dependency rules.'
    )
    $skipped = @('data-storage', 'ui-ux', 'devops-operations', 'security-compliance', 'observability-resilience', 'component-design')
    $reasons = @(
        'The checker stores no durable data.',
        'The interface is terminal-only.',
        'The feature changes no deployment or release pipeline.',
        'The tool handles no auth, secrets, PII, or compliance data.',
        'The local CLI has no long-running service operations.',
        'The architecture pipeline already supplies the needed component boundary.'
    )
    $agendaJson = [ordered]@{
        selected = @(for ($i = 0; $i -lt $selected.Count; $i++) { [ordered]@{ lens = $selected[$i]; depth = $depths[$i]; decision = $decisions[$i] } })
        skipped = @(for ($i = 0; $i -lt $skipped.Count; $i++) { [ordered]@{ lens = $skipped[$i]; reason = $reasons[$i] } })
    } | ConvertTo-Json -Depth 6 -Compress
    $result = & $writer -ProjectRoot $scratch -FeatureRef '001-url-checker' -AgendaJson $agendaJson -PassThru
    Assert-True ([string]$result.state -eq 'confirmed' -and $result.selected_count -eq 4 -and $result.skipped_count -eq 6) 'writer reports the exact confirmed agenda coverage'

    $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    Assert-True ([string]$state.agenda_status -eq 'confirmed' -and [string]$state.agenda_confirmation -eq 'human-confirmed' -and
        [string]$state.agenda_confirmation_scope -eq 'lens-selection') 'confirmed state records typed human authority for the lens selection'
    Assert-True (@($state.selected).Count -eq 4 -and @($state.agenda.PSObject.Properties).Count -eq 4 -and
        @($state.skipped.PSObject.Properties).Count -eq 6) 'confirmed state makes both selected and skipped sets reviewable'
    Assert-True ([string]$state.skipped.'ui-ux' -eq 'The interface is terminal-only.') 'each skipped lens carries its feature-specific reason'

    . $accessor
    $lifecycle = Get-SpecrewWorkshopLifecycleState -ProjectRoot $scratch -FeatureRef '001-url-checker'
    Assert-True ($lifecycle.status -eq 'active' -and $lifecycle.current_lens -eq 'architecture-core') 'strict controller opens lens 1 only after complete coverage and human confirmation'

    $shellFeature = '002-shell-call'
    New-Item -ItemType Directory -Path (Join-Path $scratch "specs\$shellFeature") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\spec.md") -Value '# Shell Call' -Encoding UTF8
    & $initializer -ProjectRoot $scratch -FeatureRef $shellFeature
    $shellOutput = @(& pwsh -NoProfile -File $writer -ProjectRoot $scratch -FeatureRef $shellFeature -AgendaJson $agendaJson -PassThru 2>&1)
    Assert-True ($LASTEXITCODE -eq 0) "pwsh -File accepts the single JSON agenda payload: $($shellOutput -join ' ')"
    $shellState = Get-Content -LiteralPath (Join-Path $scratch "specs\$shellFeature\lens-applicability.json") -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    Assert-True ([string]$shellState.agenda_status -eq 'confirmed' -and @($shellState.skipped.PSObject.Properties).Count -eq 6) 'external shell invocation preserves complete selected/skipped coverage'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'workshop agenda confirmation: all assertions pass' -ForegroundColor Green
