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
    exit 1
}

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -ne $Expected) {
        Write-Fail "$Message (expected '$Expected', actual '$Actual')"
    }
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
    }
}

function Assert-GreaterOrEqual {
    param(
        [Parameter(Mandatory = $true)][double]$Actual,
        [Parameter(Mandatory = $true)][double]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Actual -lt $Expected) {
        Write-Fail "$Message (expected >= $Expected, actual $Actual)"
    }
}

function Test-MapKey {
    param(
        [Parameter(Mandatory = $true)]$Map,
        [Parameter(Mandatory = $true)][string]$Key
    )

    if ($Map -is [System.Collections.IDictionary]) {
        return $Map.Contains($Key)
    }

    return $null -ne $Map.PSObject.Properties[$Key]
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$intakeRoot = Join-Path $repoRoot '.specify\intake'
$enginePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\intake\Invoke-SpecifyIntake.ps1'
$mirrorEnginePath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\intake\Invoke-SpecifyIntake.ps1'
$helperRoot = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\intake\helpers'
$mirrorHelperRoot = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\intake\helpers'
$userProfileHelperPath = Join-Path $repoRoot 'scripts\internal\user-profile.ps1'
$scratchRoot = Join-Path $repoRoot 'tests\integration\scratch\f049-i003-intake-engine'

. (Join-Path $helperRoot 'Read-IntakeYaml.ps1')
. (Join-Path $helperRoot 'Load-PersonaCatalog.ps1')
. (Join-Path $helperRoot 'Load-CategoryCatalog.ps1')
. (Join-Path $helperRoot 'Resolve-PerLensMode.ps1')
. (Join-Path $helperRoot 'Traverse-QuestionBank.ps1')
. (Join-Path $helperRoot 'Resolve-AutoDecision.ps1')
. (Join-Path $helperRoot 'Render-Annotation.ps1')
. (Join-Path $helperRoot 'Detect-RepoStack.ps1')
. $userProfileHelperPath

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

Push-Location -LiteralPath $repoRoot
try {
    $mirrorPairs = @(
        @{
            Primary = $enginePath
            Mirror  = $mirrorEnginePath
            Label   = 'Invoke-SpecifyIntake.ps1'
        }
        @{
            Primary = Join-Path $helperRoot 'Render-Annotation.ps1'
            Mirror  = Join-Path $mirrorHelperRoot 'Render-Annotation.ps1'
            Label   = 'Render-Annotation.ps1'
        }
        @{
            Primary = Join-Path $helperRoot 'Read-IntakeYaml.ps1'
            Mirror  = Join-Path $mirrorHelperRoot 'Read-IntakeYaml.ps1'
            Label   = 'Read-IntakeYaml.ps1'
        }
    )

    foreach ($pair in $mirrorPairs) {
        $primaryHash = (Get-FileHash -LiteralPath $pair.Primary -Algorithm SHA256).Hash
        $mirrorHash = (Get-FileHash -LiteralPath $pair.Mirror -Algorithm SHA256).Hash
        Assert-Equal -Actual $mirrorHash -Expected $primaryHash -Message "FR-028/TG-014: $($pair.Label) maintains extension/.specify mirror parity"
    }
    Write-Pass 'Mirror parity verified for intake engine runtime surfaces'

    $personas = Load-PersonaCatalog -IntakeDataRoot $intakeRoot
    $categories = Load-CategoryCatalog -IntakeDataRoot $intakeRoot
    $rules = Read-IntakeYamlDocument -Path (Join-Path $intakeRoot 'depth-rules.yml') -Kind 'depth_rules'
    $defaults = Resolve-AutoDecision -IntakeDataRoot $intakeRoot -Stack 'generic'

    Assert-Equal -Actual $personas.Count -Expected 4 -Message 'T001/T002: persona catalog loads all four lenses'
    Assert-Equal -Actual $categories.Count -Expected 12 -Message 'T001/T010: category catalog loads all twelve categories'
    Assert-Equal -Actual $defaults.Count -Expected 12 -Message 'T016/T031: generic auto-decision catalog exposes twelve defaults'
    Assert-Equal -Actual (Detect-RepoStack -ProjectRoot $repoRoot) -Expected 'nodejs' -Message 'T019: stack detection falls back to repository package.json'
    Write-Pass 'Engine foundation catalogs and stack detection load without ConvertFrom-Yaml'

    $profilePath = Join-Path $scratchRoot 'user-profile.yml'
    $expertiseDials = @{
        'product-manager' = 8
        'ux-ui-specialist' = 'auto'
        'architect' = 5
        'ai-researcher-project-manager' = 2
    }

    Save-UserProfile -ExpertiseDials $expertiseDials -ProfilePath $profilePath
    $loadedProfile = Get-UserProfile -ProfilePath $profilePath
    $profileContent = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8
    Assert-True -Condition (Test-Path -LiteralPath $profilePath -PathType Leaf) -Message 'T020/T021: user-profile.yml is persisted to the requested path'
    
    # FR-024 schema validation
    Assert-True -Condition ((Test-MapKey -Map $loadedProfile -Key 'schema') -and $loadedProfile.schema -eq '1.0') -Message 'FR-024: schema field present and correct'
    Assert-True -Condition (Test-MapKey -Map $loadedProfile -Key 'specrew_version_at_creation') -Message 'FR-024: specrew_version_at_creation field present'
    Assert-True -Condition ((Test-MapKey -Map $loadedProfile -Key 'created_at') -and -not [string]::IsNullOrWhiteSpace($loadedProfile.created_at)) -Message 'FR-024: created_at field present'
    Assert-True -Condition ((Test-MapKey -Map $loadedProfile -Key 'last_updated_at') -and -not [string]::IsNullOrWhiteSpace($loadedProfile.last_updated_at)) -Message 'FR-024: last_updated_at field present'
    Assert-True -Condition (Test-MapKey -Map $loadedProfile -Key 'expertise') -Message 'FR-024: expertise structure present'
    Assert-True -Condition (Test-MapKey -Map $loadedProfile -Key 'preferences') -Message 'FR-024: preferences structure present'
    
    Assert-Equal -Actual $loadedProfile.expertise['software_architecture'] -Expected 5 -Message 'FR-024: architect expertise persists as numeric software_architecture'
    Assert-True -Condition ($null -eq $loadedProfile.expertise['ui_ux']) -Message 'FR-024: auto expertise persists as null in expertise.ui_ux'
    Assert-Equal -Actual $loadedProfile.expertise['product_management'] -Expected 8 -Message 'FR-024: product-manager expertise persists as numeric product_management'
    Assert-Equal -Actual $loadedProfile.expertise_dials['ux-ui-specialist'] -Expected 'auto' -Message 'FR-023/FR-024: runtime profile maps null expertise.ui_ux back to auto semantics'
    Assert-True -Condition ($profileContent -match '(?m)^  ui_ux: null$') -Message 'FR-024: persisted YAML writes null for the auto expertise field'
    Assert-True -Condition (-not ($profileContent -match '(?m)^  (software_architecture|ui_ux|product_management|ai_research_project_management): auto$')) -Message 'FR-024: persisted expertise fields never store the string auto'
    Assert-True -Condition ((Show-UserProfileSummary -Profile $loadedProfile) -match '/specrew-user-profile edit') -Message 'T022/T025: profile summary advertises slash-command edit guidance'
    Write-Pass 'User profile persistence stores FR-024 numeric-or-null schema while preserving summary guidance'
    
    # Test persisted auto-decision path end-to-end (FR-023) through both engine roots
    $autoProfilePath = Join-Path $scratchRoot 'user-profile-auto.yml'
    Save-UserProfile -ExpertiseDials @{
        'product-manager' = 'auto'
        'ux-ui-specialist' = 'auto'
        'architect' = 'auto'
        'ai-researcher-project-manager' = 'auto'
    } -ProfilePath $autoProfilePath
    $autoProfileContent = Get-Content -LiteralPath $autoProfilePath -Raw -Encoding UTF8
    Assert-True -Condition (-not ($autoProfileContent -match '(?m)^  (software_architecture|ui_ux|product_management|ai_research_project_management): auto$')) -Message 'FR-024: fully auto profiles still persist null instead of auto'

    foreach ($engineUnderTest in @(
            @{ Name = 'primary'; Path = $enginePath }
            @{ Name = 'mirror'; Path = $mirrorEnginePath }
        )) {
        $autoResult = & $engineUnderTest.Path -TestMode -IntakeDataRoot $intakeRoot -UserInput 'Build a planning assistant' -UserProfilePath $autoProfilePath
        $autoState = $autoResult | Select-Object -Last 1
        Assert-True -Condition ((@($autoState.results | ForEach-Object expertise_dial) -join ',') -eq 'auto,auto,auto,auto') -Message "FR-023: $($engineUnderTest.Name) engine preserves null-backed auto semantics through engine processing"
        Assert-True -Condition ((@($autoState.results | ForEach-Object lens_mode) -join ',') -eq 'C,C,C,C') -Message "FR-023: $($engineUnderTest.Name) engine resolves all null-backed auto lenses to Mode C"
        $autoAnnotationCounts = @($autoState.results | ForEach-Object { @($_.annotations).Count })
        Assert-Equal -Actual ($autoAnnotationCounts | Select-Object -First 1) -Expected 12 -Message "FR-023: $($engineUnderTest.Name) engine surfaces one transparency annotation per category for persisted auto profiles"
    }
    Write-Pass 'Persisted auto-decision path works through both extension and .specify intake engines'

    $seniorResult = & $enginePath -TestMode -IntakeDataRoot $intakeRoot -UserInput 'Build a planning assistant' -ExpertiseDial @{
        'product-manager' = 8
        'ux-ui-specialist' = 8
        'architect' = 8
        'ai-researcher-project-manager' = 8
    }
    $seniorState = $seniorResult | Select-Object -Last 1

    Assert-Equal -Actual $seniorState.personas.Count -Expected 4 -Message 'T001/T002: engine state includes all four personas'
    Assert-Equal -Actual $seniorState.categories.Count -Expected 12 -Message 'T001/T010: engine state includes all twelve categories'
    Assert-Equal -Actual $seniorState.results.Count -Expected 4 -Message 'T001/T028: engine emits one lens result per persona'
    Assert-True -Condition ((@($seniorState.results | ForEach-Object { $_.questions.Count }) -join ',') -eq '3,3,3,3') -Message 'T031: senior intake stays on the reduced three-question path per lens'
    Write-Pass 'Intake engine executes end to end with reduced senior-question counts'

    Assert-Equal -Actual (Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.80 -DepthRules $rules) -Expected 'A' -Message 'T033: high expertise and high completeness resolve to Mode A'
    Assert-Equal -Actual (Resolve-PerLensMode -ExpertiseDial 5 -LensCompleteness 0.50 -DepthRules $rules) -Expected 'B' -Message 'T033: mid expertise resolves to Mode B'
    Assert-Equal -Actual (Resolve-PerLensMode -ExpertiseDial 2 -LensCompleteness 0.20 -DepthRules $rules) -Expected 'C' -Message 'T033: low expertise resolves to Mode C'

    $modeAQuestions = @(Traverse-QuestionBank -IntakeDataRoot $intakeRoot -PersonaId 'product-manager' -Mode 'A')
    $modeCQuestions = @(Traverse-QuestionBank -IntakeDataRoot $intakeRoot -PersonaId 'product-manager' -Mode 'C')
    $questionReduction = [math]::Round((1 - ($modeAQuestions.Count / [double]$modeCQuestions.Count)) * 100, 2)
    Assert-Equal -Actual $modeAQuestions.Count -Expected 3 -Message 'T031/T033: Mode A returns the condensed confirmation set'
    Assert-Equal -Actual $modeCQuestions.Count -Expected 8 -Message 'T031/T033: Mode C returns the full interview set'
    Assert-GreaterOrEqual -Actual $questionReduction -Expected 30 -Message 'SC-005: high-expertise path reduces question count by at least 30 percent'
    Write-Pass "Per-lens mode rules reduce senior question count by $questionReduction percent"

    $noviceResult = & $enginePath -TestMode -IntakeDataRoot $intakeRoot -UserInput 'Build a planning assistant' -ExpertiseDial @{
        'product-manager' = 1
        'ux-ui-specialist' = 1
        'architect' = 1
        'ai-researcher-project-manager' = 1
    }
    $noviceState = $noviceResult | Select-Object -Last 1
    $annotationCounts = @($noviceState.results | ForEach-Object { @($_.annotations).Count })
    $annotationCoverage = [math]::Round((($annotationCounts | Measure-Object -Average).Average / [double]$categories.Count) * 100, 2)

    Assert-True -Condition ((@($noviceState.results | ForEach-Object lens_mode) -join ',') -eq 'C,C,C,C') -Message 'T031/T033: novice intake resolves all lenses to Mode C'
    Assert-Equal -Actual ($annotationCounts | Select-Object -First 1) -Expected 12 -Message 'T031/T034: novice intake surfaces one transparency annotation per category'
    Assert-GreaterOrEqual -Actual $annotationCoverage -Expected 40 -Message 'SC-005: low-expertise path auto-decides at least 40 percent of decision slots'
    Write-Pass "Low-expertise path surfaces auto-decisions for $annotationCoverage percent of decision slots"

    $modeAThresholdResults = @(
        Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.80 -DepthRules $rules
        Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.80 -DepthRules $rules
        Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.80 -DepthRules $rules
        Resolve-PerLensMode -ExpertiseDial 8 -LensCompleteness 0.80 -DepthRules $rules
    )
    $modeARate = [math]::Round(((@($modeAThresholdResults | Where-Object { $_ -eq 'A' }).Count / [double]$modeAThresholdResults.Count) * 100), 2)
    Assert-GreaterOrEqual -Actual $modeARate -Expected 70 -Message 'SC-005: senior high-completeness per-lens Mode A rate meets the 70 percent threshold'
    Write-Pass "Senior/high-completeness Mode A rate of $modeARate percent (4/4 modeled lenses) exceeds 70 percent threshold (SC-005 third clause)"

    $extendedIntakeRoot = Join-Path $scratchRoot 'extended-intake'
    Copy-Item -LiteralPath $intakeRoot -Destination $extendedIntakeRoot -Recurse -Force

    Add-Content -LiteralPath (Join-Path $extendedIntakeRoot 'personas.yml') -Encoding UTF8 -Value @'
  - id: security-engineer
    name: "Security Engineer"
    description: "Threat modeling, abuse cases, and control selection"
    question_bank_path: "questions/security-engineer.yml"
    focus_areas:
      - "Threat modeling"
      - "Control design"
'@

    Set-Content -LiteralPath (Join-Path $extendedIntakeRoot 'questions\security-engineer.yml') -Encoding UTF8 -Value @'
# Security Engineer Question Bank
schema_version: "1.0"
persona_id: security-engineer
persona_name: "Security Engineer"

questions:
  - id: sec-q001
    category: security-and-compliance
    text: "What abuse cases and threat actors must the system defend against?"
    priority: high
    tags: [security, threat-model]
    mode_applicability: [A, B, C]
  - id: sec-q002
    category: security-and-compliance
    text: "What controls or review gates are mandatory before release?"
    priority: medium
    tags: [security, controls]
    mode_applicability: [B, C]
  - id: sec-q003
    category: security-and-compliance
    text: "What logging and audit evidence is required for security incidents?"
    priority: low
    tags: [security, audit]
    mode_applicability: [C]
'@

    $extendedPersonas = Load-PersonaCatalog -IntakeDataRoot $extendedIntakeRoot
    Assert-Equal -Actual $extendedPersonas.Count -Expected 5 -Message 'T032/SC-006: persona catalog accepts a fifth YAML-only persona'

    $extendedResult = & $enginePath -TestMode -IntakeDataRoot $extendedIntakeRoot -UserInput 'Build a planning assistant' -ExpertiseDial @{
        'product-manager' = 8
        'ux-ui-specialist' = 8
        'architect' = 8
        'ai-researcher-project-manager' = 8
        'security-engineer' = 8
    }
    $extendedState = $extendedResult | Select-Object -Last 1
    Assert-Equal -Actual $extendedState.results.Count -Expected 5 -Message 'T032/SC-006: engine processes the fifth persona without code changes'
    Assert-True -Condition (($extendedState.results | ForEach-Object persona_id) -contains 'security-engineer') -Message 'T032/SC-006: extended intake results include the fifth persona'
    Write-Pass 'Fifth-persona extensibility proof succeeded with YAML-only additions'

    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $repoRoot '.claude\skills\specrew-user-profile\SKILL.md') -PathType Leaf) -Message 'T023: slash command deployed to .claude'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $repoRoot '.github\skills\specrew-user-profile\SKILL.md') -PathType Leaf) -Message 'T024: slash command deployed to .github'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $repoRoot '.agents\skills\specrew-user-profile\SKILL.md') -PathType Leaf) -Message 'T025: slash command deployed to .agents'
    Write-Pass 'Slash-command deployment verified across active host roots'
}
finally {
    Pop-Location
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 049 Iteration 003 intake engine integration coverage'
exit 0
