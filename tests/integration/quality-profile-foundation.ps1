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

function Assert-Action {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$AllowedActions,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $match = $Actions | Where-Object { [System.IO.Path]::GetFullPath([string]$_.Path) -ieq $resolvedPath } | Select-Object -First 1
    if ($null -eq $match) {
        Write-Fail $FailureMessage
        return $false
    }

    if ($AllowedActions -notcontains [string]$match.Action) {
        Write-Fail ("{0} Observed action '{1}' for {2}." -f $FailureMessage, $match.Action, $resolvedPath)
        return $false
    }

    return $true
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-FileMatchesFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActualPath,

        [Parameter(Mandatory = $true)]
        [string]$FixturePath,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not (Test-Path -LiteralPath $ActualPath -PathType Leaf)) {
        Write-Fail $FailureMessage
        return $false
    }

    $actualContent = Get-Content -LiteralPath $ActualPath -Raw -Encoding UTF8
    $fixtureContent = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8
    if ($actualContent -cne $fixtureContent) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Invoke-ScaffoldGovernance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [switch]$DryRun
    )

    $arguments = @{
        ProjectPath    = $ProjectPath
        SpecrewVersion = '0.1.0-dev'
        SpecKitVersion = '0.12.9'
        SquadVersion   = '0.11.0'
        PassThru       = $true
    }
    if ($DryRun) {
        $arguments.DryRun = $true
    }

    $result = & $ScriptPath @arguments
    return @($result)
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sourceScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-governance.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$qualityProfileResolverPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\resolve-quality-profile.ps1'
$sourceTemplateRoot = Join-Path $repoRoot 'extensions\specrew-speckit\templates'
$planTemplatePath = Join-Path $repoRoot '.specify\templates\plan-template.md'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\quality-profile-foundation'
$fixtureQualityRoot = Join-Path $fixtureRoot 'templates\quality'
$scratchRoot = Join-Path $repoRoot '.scratch\quality-profile-foundation'
$projectRoot = Join-Path $scratchRoot 'project'
$fixtureExtensionRoot = Join-Path $scratchRoot 'fixture-extension'
$fixtureTemplateRoot = Join-Path $fixtureExtensionRoot 'templates'
$fixtureScriptPath = Join-Path $fixtureExtensionRoot 'scripts\scaffold-governance.ps1'
$fixtureSharedGovernancePath = Join-Path $fixtureExtensionRoot 'scripts\shared-governance.ps1'

foreach ($requiredPath in @($sourceScriptPath, $sharedGovernancePath, $sourceTemplateRoot, $fixtureQualityRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing required quality-profile foundation dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -Path (Join-Path $fixtureExtensionRoot 'scripts') -ItemType Directory -Force
$null = New-Item -Path $fixtureTemplateRoot -ItemType Directory -Force
Copy-Item -LiteralPath $sourceScriptPath -Destination $fixtureScriptPath -Force
Copy-Item -LiteralPath $sharedGovernancePath -Destination $fixtureSharedGovernancePath -Force
Copy-Item -Path (Join-Path $sourceTemplateRoot '*') -Destination $fixtureTemplateRoot -Recurse -Force
$null = New-Item -Path (Join-Path $fixtureTemplateRoot 'quality\presets') -ItemType Directory -Force
$null = New-Item -Path (Join-Path $fixtureTemplateRoot 'quality\lenses') -ItemType Directory -Force
Copy-Item -Path (Join-Path $fixtureQualityRoot 'presets\*') -Destination (Join-Path $fixtureTemplateRoot 'quality\presets') -Recurse -Force
Copy-Item -Path (Join-Path $fixtureQualityRoot 'lenses\*') -Destination (Join-Path $fixtureTemplateRoot 'quality\lenses') -Recurse -Force

$expectedPresets = @(
    'node-public-ws-service-v1.md',
    'react-spa-public-v1.md',
    'node-rest-with-postgres-v1.md',
    'python-fastapi-service-v1.md',
    'dotnet-aspnet-api-v1.md'
)
$expectedLenses = @(
    'security-baseline-v1.md',
    'robustness-baseline-v1.md',
    'test-integrity-v1.md'
)

$allChecksPassed = $true

$dryRunActions = Invoke-ScaffoldGovernance -ScriptPath $fixtureScriptPath -ProjectPath $projectRoot -DryRun
if (-not (Assert-Action -Actions $dryRunActions -Path (Join-Path $projectRoot '.specrew\presets') -AllowedActions @('would-create-directory', 'preserved-directory') -FailureMessage 'Dry-run scaffold did not advertise the downstream .specrew\presets registry root.')) {
    $allChecksPassed = $false
}
if (-not (Assert-Action -Actions $dryRunActions -Path (Join-Path $projectRoot '.specrew\lenses') -AllowedActions @('would-create-directory', 'preserved-directory') -FailureMessage 'Dry-run scaffold did not advertise the downstream .specrew\lenses registry root.')) {
    $allChecksPassed = $false
}

foreach ($presetFile in $expectedPresets) {
    $presetPath = Join-Path $projectRoot (Join-Path '.specrew\presets' $presetFile)
    if (-not (Assert-Action -Actions $dryRunActions -Path $presetPath -AllowedActions @('would-create', 'preserved') -FailureMessage ("Dry-run scaffold did not advertise preset asset '{0}'." -f $presetFile))) {
        $allChecksPassed = $false
    }
}

foreach ($lensFile in $expectedLenses) {
    $lensPath = Join-Path $projectRoot (Join-Path '.specrew\lenses' $lensFile)
    if (-not (Assert-Action -Actions $dryRunActions -Path $lensPath -AllowedActions @('would-create', 'preserved') -FailureMessage ("Dry-run scaffold did not advertise lens asset '{0}'." -f $lensFile))) {
        $allChecksPassed = $false
    }
}

$realActions = Invoke-ScaffoldGovernance -ScriptPath $fixtureScriptPath -ProjectPath $projectRoot
$configPath = Join-Path $projectRoot '.specrew\config.yml'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Fail 'Real scaffold did not create .specrew\config.yml.'
    $allChecksPassed = $false
}
else {
    $configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    $qualityBlockPattern = 'quality:\s*\r?\n\s+presets_path:\s*".specrew/presets"\s*\r?\n\s+lenses_path:\s*".specrew/lenses"\s*\r?\n\s+findings_schema_version:\s*"v1"\s*\r?\n\s+evidence_directory_name:\s*"quality"'
    if (-not (Assert-Contains -Content $configContent -Pattern $qualityBlockPattern -FailureMessage 'Scaffolded config.yml did not include the Phase 1 quality asset registry block.')) {
        $allChecksPassed = $false
    }
}

foreach ($presetFile in $expectedPresets) {
    $actualPresetPath = Join-Path $projectRoot (Join-Path '.specrew\presets' $presetFile)
    $fixturePresetPath = Join-Path $fixtureQualityRoot (Join-Path 'presets' $presetFile)
    if (-not (Assert-FileMatchesFixture -ActualPath $actualPresetPath -FixturePath $fixturePresetPath -FailureMessage ("Scaffolded preset '{0}' did not match the fixture source artifact." -f $presetFile))) {
        $allChecksPassed = $false
    }
}

foreach ($lensFile in $expectedLenses) {
    $actualLensPath = Join-Path $projectRoot (Join-Path '.specrew\lenses' $lensFile)
    $fixtureLensPath = Join-Path $fixtureQualityRoot (Join-Path 'lenses' $lensFile)
    if (-not (Assert-FileMatchesFixture -ActualPath $actualLensPath -FixturePath $fixtureLensPath -FailureMessage ("Scaffolded lens '{0}' did not match the fixture source artifact." -f $lensFile))) {
        $allChecksPassed = $false
    }
}

$localOverridePresetPath = Join-Path $projectRoot '.specrew\presets\node-public-ws-service-v1.md'
if (Test-Path -LiteralPath $localOverridePresetPath -PathType Leaf) {
    [System.IO.File]::WriteAllText($localOverridePresetPath, @'
# Local Override: node-public-ws-service v1.0.0

This file simulates a project-specific edit that must not be overwritten by a later scaffold run.
'@, [System.Text.UTF8Encoding]::new($false))

    $rerunActions = Invoke-ScaffoldGovernance -ScriptPath $fixtureScriptPath -ProjectPath $projectRoot
    if (-not (Assert-Action -Actions $rerunActions -Path $localOverridePresetPath -AllowedActions @('preserved') -FailureMessage 'Rerun scaffold should preserve local edits to versioned preset artifacts.')) {
        $allChecksPassed = $false
    }

    $localOverrideContent = Get-Content -LiteralPath $localOverridePresetPath -Raw -Encoding UTF8
    if (-not (Assert-Contains -Content $localOverrideContent -Pattern 'project-specific edit' -FailureMessage 'Rerun scaffold overwrote the simulated local preset edit.')) {
        $allChecksPassed = $false
    }
}
else {
    Write-Fail 'Cannot validate local preset preservation because the initial scaffold did not materialize node-public-ws-service-v1.md.'
    $allChecksPassed = $false
}

if (-not (Assert-PathExists -Path $qualityProfileResolverPath -FailureMessage 'US1 quality-profile integration is missing extensions\specrew-speckit\scripts\resolve-quality-profile.ps1 for recognized-stack and bounded custom-composition planning.')) {
    $allChecksPassed = $false
}
else {
    $phaseTwoFeaturePath = Join-Path $repoRoot 'specs\005-stack-aware-quality-bar'
    $phaseTwoProfileJson = & $qualityProfileResolverPath -ProjectPath $repoRoot -FeaturePath $phaseTwoFeaturePath -OutputFormat Json
    $phaseTwoProfile = $phaseTwoProfileJson | ConvertFrom-Json

    if (-not (Assert-Condition -Condition ($phaseTwoProfile.PSObject.Properties.Name -contains 'phase2_slice_scope') -FailureMessage 'Resolved quality profile is missing the Phase 2 slice-scope field required for bounded hardening planning.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.phase2_hardening_gate_artifact -match 'specs/005-stack-aware-quality-bar/iterations/<NNN>/quality/hardening-gate\.md') -FailureMessage 'Resolved quality profile did not publish the canonical hardening-gate artifact path for Phase 2 planning.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.phase2_known_traps_corpus_location -eq '.specrew/quality/known-traps.md') -FailureMessage 'Resolved quality profile did not reuse the configured known-traps corpus location for Phase 2 planning.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.phase2_hardening_focus_areas.Count -eq 4) -FailureMessage 'Resolved quality profile did not publish the bounded four-row hardening focus-area plan for the approved slice.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition (@($phaseTwoProfile.phase2_hardening_focus_areas | Where-Object { $_.focus_area -eq 'Retry and idempotency expectations' }).Count -eq 1) -FailureMessage 'Resolved quality profile is missing the retry/idempotency hardening focus row needed for pre-implementation review.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition (@($phaseTwoProfile.phase2_lens_activation_plan | Where-Object { $_.lens_ref -eq 'security-baseline@v1.0.0' -and $_.activation -eq 'required' }).Count -eq 1) -FailureMessage 'Resolved quality profile did not classify the security baseline lens as required Phase 2 planning metadata.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.phase2_routing_policy[0].requested_review_class -eq 'strongest-available') -FailureMessage 'Resolved quality profile did not publish the configured strongest-available routing default for hardening planning.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.markdown_summary -match '## Phase 2 Hardening and Specialist Review Planning') -FailureMessage 'Resolved quality profile markdown summary did not render the Phase 2 hardening planning section.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.phase2_slice_scope -match 'planning-time analysis' -and $phaseTwoProfile.phase2_slice_scope -match 'runtime-only final proof') -FailureMessage 'Resolved quality profile did not publish the repaired planning-time-versus-runtime evidence boundary in the Phase 2 slice scope.')) {
        $allChecksPassed = $false
    }
    if (-not (Assert-Condition -Condition ($phaseTwoProfile.markdown_summary -match 'expected controls' -and $phaseTwoProfile.markdown_summary -match 'runtime proof can remain pending') -FailureMessage 'Resolved quality profile markdown summary did not keep expected controls and later runtime proof explicit.')) {
        $allChecksPassed = $false
    }
}

if (-not (Assert-PathExists -Path $planTemplatePath -FailureMessage 'Missing .specify\templates\plan-template.md for Phase 1 quality-planning contract validation.')) {
    $allChecksPassed = $false
}
else {
    $planTemplateContent = Get-Content -LiteralPath $planTemplatePath -Raw -Encoding UTF8
    $phaseOneQualityContractPatterns = @(
        @{
            Pattern = 'Phase 1.*quality'
            FailureMessage = 'Plan template does not expose a dedicated Phase 1 quality-planning section for US1.'
        },
        @{
            Pattern = 'inferred quality profile'
            FailureMessage = 'Plan template does not require the inferred quality profile to be published in planning artifacts.'
        },
        @{
            Pattern = 'selected preset ref[s]?\s+or\s+explicit custom composition'
            FailureMessage = 'Plan template does not require either a recognized-stack preset reference or an explicit bounded custom composition path.'
        },
        @{
            Pattern = 'stack surface'
            FailureMessage = 'Plan template does not require stack surfaces to be recorded for the active Phase 1 quality profile.'
        },
        @{
            Pattern = 'risk dimension'
            FailureMessage = 'Plan template does not require risk dimensions for the active Phase 1 quality profile.'
        },
        @{
            Pattern = 'quality tool bundle'
            FailureMessage = 'Plan template does not require the Phase 1 quality tool bundle to be published.'
        },
        @{
            Pattern = 'required quality gate'
            FailureMessage = 'Plan template does not require the Phase 1 quality gates to be listed explicitly.'
        },
        @{
            Pattern = 'not-applicable.*rationale'
            FailureMessage = 'Plan template does not require not-applicable dimensions and rationale for omitted gates.'
        },
        @{
            Pattern = 'Phase 2\+.*defer'
            FailureMessage = 'Plan template does not keep later-phase behavior explicit by requiring Phase 2+ deferrals.'
        },
        @{
            Pattern = 'bounded custom composition'
            FailureMessage = 'Plan template does not describe the bounded custom-composition fallback required when no stack preset matches.'
        }
    )

    foreach ($contractPattern in $phaseOneQualityContractPatterns) {
        if (-not (Assert-Contains -Content $planTemplateContent -Pattern $contractPattern.Pattern -FailureMessage $contractPattern.FailureMessage)) {
            $allChecksPassed = $false
        }
    }

    $phaseTwoQualityContractPatterns = @(
        @{
            Pattern = 'Phase 2 Hardening and Specialist Review Planning'
            FailureMessage = 'Plan template does not expose the bounded Phase 2 hardening-planning section.'
        },
        @{
            Pattern = 'slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals'
            FailureMessage = 'Plan template does not tell planners to mirror the resolved Phase 2 hardening planning metadata.'
        },
        @{
            Pattern = 'planning-time-vs-runtime evidence boundary'
            FailureMessage = 'Plan template does not tell planners to keep the planning-time versus runtime evidence boundary explicit.'
        },
        @{
            Pattern = 'record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments'
            FailureMessage = 'Plan template does not require planning-time analysis, expected controls, rationale, non-applicable reasoning, and narrow runtime-only deferments.'
        },
        @{
            Pattern = 'Known-Traps Corpus Location\*\*:\s*\[e\.g\., `\.specrew/quality/known-traps\.md`\]'
            FailureMessage = 'Plan template does not show the canonical project-wide known-traps corpus location for bounded Phase 2 planning.'
        }
    )

    foreach ($contractPattern in $phaseTwoQualityContractPatterns) {
        if (-not (Assert-Contains -Content $planTemplateContent -Pattern $contractPattern.Pattern -FailureMessage $contractPattern.FailureMessage)) {
            $allChecksPassed = $false
        }
    }
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations'
exit 0
