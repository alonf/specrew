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

    # =====================================================================================
    # Proposal 141 (Iteration 005): Crew Interaction Profile / Persona Lens Separation
    # =====================================================================================

    # FR-032/FR-033/FR-034: shared decision-area metadata maps display labels to stable keys + persona IDs
    $areas = @(Get-CrewInteractionProfileAreas)
    Assert-Equal -Actual $areas.Count -Expected 4 -Message 'FR-032: Crew Interaction Profile exposes four decision areas'
    $labelByKey = @{}
    foreach ($a in $areas) { $labelByKey[$a.ExpertiseKey] = $a.DisplayLabel }
    Assert-Equal -Actual $labelByKey['product_management'] -Expected 'Product Strategy' -Message 'FR-034: product_management displays as Product Strategy'
    Assert-Equal -Actual $labelByKey['ui_ux'] -Expected 'UX/UI Design' -Message 'FR-034: ui_ux displays as UX/UI Design'
    Assert-Equal -Actual $labelByKey['software_architecture'] -Expected 'Software Architecture' -Message 'FR-034: software_architecture displays as Software Architecture'
    Assert-Equal -Actual $labelByKey['ai_research_project_management'] -Expected 'AI Delivery Planning' -Message 'FR-034: ai_research_project_management displays as AI Delivery Planning'

    # Proposal 170: first-run setup uses behavior-centered labels/questions while preserving the
    # canonical profile display labels above.
    $setupLabelByKey = @{}
    foreach ($a in $areas) {
        $setupLabelByKey[$a.ExpertiseKey] = $a.SetupLabel
        Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($a.SetupQuestion)) -Message "P170: setup question exists for $($a.DisplayLabel)"
        Assert-True -Condition ($a.SetupQuestion -match 'how much guidance do you want') -Message "P170: setup question asks for guidance preference for $($a.DisplayLabel)"
    }
    Assert-Equal -Actual $setupLabelByKey['product_management'] -Expected 'Product Scope & Priorities' -Message 'P170: product first-run label is behavior-centered'
    Assert-Equal -Actual $setupLabelByKey['ui_ux'] -Expected 'UX & Workflows' -Message 'P170: UX first-run label is behavior-centered'
    Assert-Equal -Actual $setupLabelByKey['software_architecture'] -Expected 'Architecture & Integration' -Message 'P170: architecture first-run label is behavior-centered'
    Assert-Equal -Actual $setupLabelByKey['ai_research_project_management'] -Expected 'Planning & Agent Coordination' -Message 'P170: AI delivery first-run label is behavior-centered'
    foreach ($a in $areas) {
        Assert-True -Condition ($a.SetupLabel -ne $a.DisplayLabel) -Message "P170: setup label is distinct from canonical display label for $($a.DisplayLabel)"
    }
    Write-Pass 'P170 first-run setup metadata is guidance-oriented while canonical labels remain stable'

    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue $null) -Expected 'auto' -Message 'P170: null first-run input normalizes to auto'
    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue '') -Expected 'auto' -Message 'P170: blank first-run input normalizes to auto'
    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue '   ') -Expected 'auto' -Message 'P170: whitespace first-run input normalizes to auto'
    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue 'AUTO') -Expected 'auto' -Message 'P170: auto is case-insensitive'
    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue '07') -Expected '7' -Message 'P170: numeric input normalizes to canonical string'
    Assert-Equal -Actual (Normalize-CrewInteractionProfileSetupInput -InputValue '10') -Expected '10' -Message 'P170: upper numeric bound accepted'
    Assert-True -Condition ($null -eq (Normalize-CrewInteractionProfileSetupInput -InputValue '0')) -Message 'P170: lower out-of-range input rejects'
    Assert-True -Condition ($null -eq (Normalize-CrewInteractionProfileSetupInput -InputValue '11')) -Message 'P170: upper out-of-range input rejects'
    Assert-True -Condition ($null -eq (Normalize-CrewInteractionProfileSetupInput -InputValue 'expert')) -Message 'P170: non-supported token rejects'
    Write-Pass 'P170 first-run setup input normalization verified'

    # FR-033: stable persona IDs preserved (including ai-researcher-project-manager)
    Assert-Equal -Actual (Get-CrewInteractionProfileLabel -PersonaId 'ai-researcher-project-manager') -Expected 'AI Delivery Planning' -Message 'FR-033: ai-researcher-project-manager persona ID resolves to AI Delivery Planning'
    Assert-Equal -Actual (Get-CrewInteractionProfileLabel -ExpertiseKey 'ai_research_project_management') -Expected 'AI Delivery Planning' -Message 'FR-033: ai_research_project_management key resolves to AI Delivery Planning'

    # FR-032/FR-035: summary uses Crew Interaction Profile framing + decision-area labels, not job-title identity
    $p141Path = Join-Path $scratchRoot 'p141-profile.yml'
    Save-UserProfile -ExpertiseDials @{ 'product-manager' = 7; 'ux-ui-specialist' = 'auto'; 'architect' = 9; 'ai-researcher-project-manager' = 2 } -ProfilePath $p141Path
    $p141Profile = Get-UserProfile -ProfilePath $p141Path
    $p141Summary = Show-UserProfileSummary -Profile $p141Profile
    Assert-True -Condition ($p141Summary -match 'Crew Interaction Profile') -Message 'FR-032: summary uses Crew Interaction Profile framing'
    foreach ($label in @('Product Strategy', 'UX/UI Design', 'Software Architecture', 'AI Delivery Planning')) {
        Assert-True -Condition ($p141Summary -match [regex]::Escape($label)) -Message "FR-034: summary renders decision-area label '$label'"
    }
    Assert-True -Condition (-not ($p141Summary -match 'Expertise Profile:')) -Message 'FR-032: summary drops the job-title-style Expertise Profile heading'
    Assert-True -Condition ($p141Summary -match 'persona lens') -Message 'FR-035: summary distinguishes the profile from Specrew internal persona lenses'

    # Feature 141 Iteration 006 (FR-025 transparency half): Get-SpecrewProfileOrientationLine renders the
    # assumed expertise as a concise, correctable one-liner for the visible orientation. Bands MUST match
    # the runtime adaptation in Get-SpecrewLensQuestionDepth (>=8 expert, <=3 learning, else mid-level) so
    # the surfaced level matches how Specrew actually adapts. $p141Profile spans all four bands at once.
    $p141Orientation = Get-SpecrewProfileOrientationLine -Profile $p141Profile
    Assert-True -Condition ($p141Orientation -match 'What I know about you:') -Message 'FR-025: orientation line opens with the transparency framing'
    Assert-True -Condition ($p141Orientation -match 'expert on Software Architecture') -Message 'FR-025: architect dial 9 -> expert (>=8 band, matches Get-SpecrewLensQuestionDepth)'
    Assert-True -Condition ($p141Orientation -match 'mid-level on Product Strategy') -Message 'FR-025: product dial 7 -> mid-level (4-7 band)'
    Assert-True -Condition ($p141Orientation -match 'learning on AI Delivery Planning') -Message 'FR-025: ai-pm dial 2 -> learning (<=3 band)'
    Assert-True -Condition ($p141Orientation -match 'auto on UX/UI Design') -Message 'FR-025: auto dial renders as auto (Specrew recommends + explains)'
    Assert-True -Condition ($p141Orientation -match "correct me if that's off") -Message 'FR-025: orientation line invites correction'
    Assert-True -Condition ($p141Orientation -match '/specrew-user-profile edit') -Message 'FR-025: orientation line surfaces the correction path'

    # Band boundaries pinned to the same cutoffs Get-SpecrewLensQuestionDepth uses (>=8 / <=3).
    $bandsPath = Join-Path $scratchRoot 'fr025-bands.yml'
    Save-UserProfile -ExpertiseDials @{ 'architect' = 8; 'ux-ui-specialist' = 7; 'product-manager' = 4; 'ai-researcher-project-manager' = 3 } -ProfilePath $bandsPath
    $bandsLine = Get-SpecrewProfileOrientationLine -Profile (Get-UserProfile -ProfilePath $bandsPath)
    Assert-True -Condition ($bandsLine -match 'expert on Software Architecture') -Message 'FR-025 boundary: dial 8 -> expert (not mid-level)'
    Assert-True -Condition ($bandsLine -match 'mid-level on UX/UI Design') -Message 'FR-025 boundary: dial 7 -> mid-level (not expert)'
    Assert-True -Condition ($bandsLine -match 'mid-level on Product Strategy') -Message 'FR-025 boundary: dial 4 -> mid-level (not learning)'
    Assert-True -Condition ($bandsLine -match 'learning on AI Delivery Planning') -Message 'FR-025 boundary: dial 3 -> learning (not mid-level)'

    # Graceful: no recognizable profile -> $null (orientation omits the section, no throw).
    Assert-True -Condition ($null -eq (Get-SpecrewProfileOrientationLine -Profile @{})) -Message 'FR-025: empty profile -> null (orientation section omitted)'
    Write-Pass 'FR-025 transparency: Get-SpecrewProfileOrientationLine renders correctable, band-accurate expertise (Iteration 006)'

    # FR-033: persisted YAML keeps the stable schema keys (no rename/migration)
    $p141Yaml = Get-Content -LiteralPath $p141Path -Raw -Encoding UTF8
    Assert-True -Condition ($p141Yaml -match '(?m)^  ai_research_project_management:') -Message 'FR-033: persisted YAML retains stable ai_research_project_management key'
    Assert-True -Condition ($p141Yaml -match '(?m)^  software_architecture:') -Message 'FR-033: persisted YAML retains stable software_architecture key'

    # FR-037 + scenario 10: legacy profiles load without migration, preserving routing/depth
    $legacyFixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\f049-legacy-user-profile'
    $legacyExpertise = Get-UserProfile -ProfilePath (Join-Path $legacyFixtureRoot 'legacy-expertise.yml')
    Assert-Equal -Actual $legacyExpertise.expertise['ai_research_project_management'] -Expected 3 -Message 'FR-037: legacy expertise profile loads stable ai_research_project_management value'
    Assert-Equal -Actual $legacyExpertise.expertise_dials['architect'] -Expected 9 -Message 'FR-037: legacy expertise profile preserves architect routing/depth'
    Assert-Equal -Actual $legacyExpertise.expertise_dials['ux-ui-specialist'] -Expected 'auto' -Message 'FR-037: legacy null expertise maps back to auto semantics'
    $legacySummary = Show-UserProfileSummary -Profile $legacyExpertise
    Assert-True -Condition ($legacySummary -match 'AI Delivery Planning') -Message 'FR-037/scenario10: legacy profile renders the updated AI Delivery Planning label'

    $legacyDials = Get-UserProfile -ProfilePath (Join-Path $legacyFixtureRoot 'legacy-dials.yml')
    Assert-Equal -Actual $legacyDials.expertise_dials['architect'] -Expected 8 -Message 'FR-037: older expertise_dials layout still preserves architect routing'
    Assert-Equal -Actual $legacyDials.expertise['ai_research_project_management'] -Expected 2 -Message 'FR-037: older expertise_dials layout maps ai-researcher-project-manager to the stable key'

    # Legacy depth behavior preserved end-to-end through the engine (all four internal lenses still run)
    $legacyEngineResult = & $enginePath -TestMode -IntakeDataRoot $intakeRoot -UserInput 'Build a planning assistant' -UserProfilePath (Join-Path $legacyFixtureRoot 'legacy-expertise.yml')
    $legacyEngineState = $legacyEngineResult | Select-Object -Last 1
    Assert-Equal -Actual $legacyEngineState.results.Count -Expected 4 -Message 'FR-037: legacy profile drives all four internal persona lenses unchanged'
    Write-Pass 'Crew Interaction Profile labels + legacy compatibility verified (FR-032..FR-037)'

    # FR-038/FR-040: session context surfaces the profile as SOFT current-user runtime guidance, not shared truth
    $sessionCtx = New-CrewInteractionProfileSessionContext -Profile $p141Profile
    Assert-Equal -Actual $sessionCtx.shared_project_truth -Expected $false -Message 'FR-038: session context marks the profile as NOT shared project truth'
    Assert-True -Condition ($sessionCtx.scope -match 'current-user') -Message 'FR-038: session context scopes the profile to the current user'
    Assert-True -Condition ($sessionCtx.application -match 'speckit\.specify') -Message 'FR-040: session context records /speckit.specify as the only hard-applied surface'
    Assert-True -Condition ($sessionCtx.application -match 'soft') -Message 'FR-040: session context records soft guidance outside /speckit.specify'
    Assert-True -Condition ($sessionCtx.decision_areas.Contains('AI Delivery Planning')) -Message 'FR-038: session context keys decision areas by display label'
    Assert-Equal -Actual $sessionCtx.expertise_dials['ai-researcher-project-manager'] -Expected 2 -Message 'FR-033/FR-038: session context preserves stable persona-id dials'

    # FR-041/SC-008: paired developers with divergent local profiles resolve independently
    $devA = Get-UserProfile -ProfilePath (Join-Path $legacyFixtureRoot 'dev-a.yml')
    $devB = Get-UserProfile -ProfilePath (Join-Path $legacyFixtureRoot 'dev-b.yml')
    Assert-Equal -Actual $devA.expertise_dials['architect'] -Expected 9 -Message 'FR-041: developer A resolves their own architecture setting'
    Assert-Equal -Actual $devB.expertise_dials['architect'] -Expected 2 -Message 'FR-041: developer B resolves a divergent architecture setting'
    Assert-True -Condition ($devA.expertise_dials['architect'] -ne $devB.expertise_dials['architect']) -Message 'SC-008: divergent local profiles coexist without shared-repository coupling'
    Write-Pass 'Session-context soft guidance + paired-developer safety verified (FR-038, FR-040, FR-041, SC-008)'

    # FR-039/SC-008: shared instruction surfaces reference the loader/path rule, not resolved dial values
    $sharedSurfaces = @(
        Join-Path $repoRoot 'README.md'
        Join-Path $repoRoot 'docs\user-guide.md'
    )
    foreach ($surface in $sharedSurfaces) {
        $surfaceName = [System.IO.Path]::GetFileName($surface)
        $surfaceText = Get-Content -LiteralPath $surface -Raw -Encoding UTF8
        Assert-True -Condition ($surfaceText -match 'Crew Interaction Profile') -Message "FR-039: shared surface '$surfaceName' describes the Crew Interaction Profile"
        Assert-True -Condition ($surfaceText -match 'user-profile\.yml') -Message "FR-039: shared surface '$surfaceName' points to the user-profile loader/path rule"
    }
    Write-Pass 'Shared-instruction loader/path-rule audit verified (FR-039, SC-008)'
}
finally {
    Pop-Location
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 049 Iteration 003 intake engine integration coverage'
exit 0
