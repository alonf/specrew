<#
.SYNOPSIS
Discrete intake engine for /speckit.specify persona-driven intake.

.DESCRIPTION
Orchestrates persona-cycle logic, per-lens depth-rule application, question-bank traversal,
auto-decision resolution, and annotation rendering. Thin orchestrators (prompt, agent, workflow)
invoke this engine; they do not contain inline persona definitions, category lists, question banks,
depth rules, or auto-decision defaults.

Implements FR-028 engine + data architecture for Feature 049 Iteration 003.

.PARAMETER TestMode
When specified, runs engine in test mode without interactive prompts for validation purposes.

.PARAMETER UserProfilePath
Path to user-profile.yml. Defaults to cross-platform standard location.

.PARAMETER IntakeDataRoot
Root path for intake data catalogs (personas, categories, depth-rules, questions, auto-decision-defaults).
Defaults to .specify/intake/ in the current project.

.PARAMETER UserInput
Initial user input describing the feature to specify.

.PARAMETER ExpertiseDial
Override expertise dials for testing (hashtable with persona IDs as keys, 1-10 values).

.EXAMPLE
Invoke-SpecifyIntake -UserInput "Build a REST API for user management"

.EXAMPLE
Invoke-SpecifyIntake -TestMode

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$TestMode,

    [Parameter(Mandatory = $false)]
    [string]$UserProfilePath,

    [Parameter(Mandatory = $false)]
    [string]$IntakeDataRoot,

    [Parameter(Mandatory = $false)]
    [string]$UserInput,

    [Parameter(Mandatory = $false)]
    [hashtable]$ExpertiseDial
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Determine script root for helper loading
$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptRoot)) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Load helper functions
$helpersPath = Join-Path $ScriptRoot 'helpers'
$helpers = @(
    'Read-IntakeYaml.ps1',
    'Load-PersonaCatalog.ps1',
    'Load-CategoryCatalog.ps1',
    'Resolve-PerLensMode.ps1',
    'Traverse-QuestionBank.ps1',
    'Resolve-AutoDecision.ps1',
    'Render-Annotation.ps1',
    'Detect-RepoStack.ps1'
)

foreach ($helper in $helpers) {
    $helperPath = Join-Path $helpersPath $helper
    if (Test-Path $helperPath) {
        . $helperPath
    } else {
        Write-Warning "Helper not found: $helperPath (engine may be incomplete)"
    }
}

function Test-IntakeProfileKey {
    param(
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject.Contains($Key)
    }

    return $null -ne $InputObject.PSObject.Properties[$Key]
}

function Get-IntakeProfileValue {
    param(
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if (-not (Test-IntakeProfileKey -InputObject $InputObject -Key $Key)) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject[$Key]
    }

    return $InputObject.$Key
}

# Resolve paths
if ([string]::IsNullOrEmpty($IntakeDataRoot)) {
    # Default to project .specify/intake/ directory
    $projectRoot = Get-Location
    $IntakeDataRoot = Join-Path $projectRoot '.specify\intake'
}

if ([string]::IsNullOrEmpty($UserProfilePath)) {
    # Cross-platform user profile location
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6 -or $env:OS -match 'Windows') {
        $UserProfilePath = Join-Path $env:USERPROFILE '.specrew\user-profile.yml'
    } else {
        $UserProfilePath = Join-Path $env:HOME '.specrew/user-profile.yml'
    }
}

# Engine execution begins
Write-Verbose "Intake Engine: Starting persona-driven intake orchestration"
Write-Verbose "Intake Data Root: $IntakeDataRoot"
Write-Verbose "User Profile Path: $UserProfilePath"

# Load user profile (if exists)
$userProfile = $null
if (Test-Path $UserProfilePath) {
    try {
        Write-Verbose "Loading user profile from: $UserProfilePath"
        # YAML parsing - using ConvertFrom-Yaml if available, else basic parsing
        $profileContent = Get-Content $UserProfilePath -Raw
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $userProfile = $profileContent | ConvertFrom-Yaml
        } elseif (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) {
            $userProfile = Read-IntakeYamlDocument -Path $UserProfilePath -Kind 'user_profile'
        } else {
            Write-Verbose "User profile loading skipped (no YAML parser available)"
        }
    } catch {
        Write-Warning "Failed to load user profile: $_"
    }
}

# Override expertise dials if provided (testing)
if ($ExpertiseDial) {
    if (-not $userProfile) {
        $userProfile = @{}
    }
    # Accept direct persona-ID mapping for backward compatibility
    if ($userProfile -is [System.Collections.IDictionary]) {
        $userProfile.expertise_dials = $ExpertiseDial
    }
    else {
        $userProfile | Add-Member -NotePropertyName 'expertise_dials' -NotePropertyValue $ExpertiseDial -Force
    }
}

# Map FR-024 expertise structure to legacy persona IDs for compatibility
if ($userProfile -and (Test-IntakeProfileKey -InputObject $userProfile -Key 'expertise') -and -not (Test-IntakeProfileKey -InputObject $userProfile -Key 'expertise_dials')) {
    $legacyMapping = @{
        'software_architecture' = 'architect'
        'ui_ux' = 'ux-ui-specialist'
        'product_management' = 'product-manager'
        'ai_research_project_management' = 'ai-researcher-project-manager'
    }
    if ($userProfile -is [System.Collections.IDictionary]) {
        $userProfile.expertise_dials = @{}
    }
    else {
        $userProfile | Add-Member -NotePropertyName 'expertise_dials' -NotePropertyValue @{} -Force
    }
    $rawExpertise = Get-IntakeProfileValue -InputObject $userProfile -Key 'expertise'
    foreach ($field in $legacyMapping.Keys) {
        $personaId = $legacyMapping[$field]
        if (Test-IntakeProfileKey -InputObject $rawExpertise -Key $field) {
            $userProfile.expertise_dials[$personaId] = Get-IntakeProfileValue -InputObject $rawExpertise -Key $field
        }
    }
}

# Load personas catalog
Write-Verbose "Loading personas catalog"
$personas = Load-PersonaCatalog -IntakeDataRoot $IntakeDataRoot

# Load categories catalog
Write-Verbose "Loading categories catalog"
$categories = Load-CategoryCatalog -IntakeDataRoot $IntakeDataRoot

# Load depth rules
Write-Verbose "Loading depth rules"
$depthRulesPath = Join-Path $IntakeDataRoot 'depth-rules.yml'
$depthRules = $null
if (Test-Path $depthRulesPath) {
    $depthRulesContent = Get-Content $depthRulesPath -Raw
    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $depthRules = $depthRulesContent | ConvertFrom-Yaml
    } elseif (Get-Command Read-IntakeYamlDocument -ErrorAction SilentlyContinue) {
        $depthRules = Read-IntakeYamlDocument -Path $depthRulesPath -Kind 'depth_rules'
    } else {
        Write-Verbose "Depth rules loading skipped (no YAML parser available)"
    }
}

# Detect repo stack
Write-Verbose "Detecting repository stack"
$repoStack = Detect-RepoStack -ProjectRoot (Get-Location)

# Load auto-decision defaults (stack-specific or generic fallback)
Write-Verbose "Loading auto-decision defaults for stack: $repoStack"
$autoDecisions = Resolve-AutoDecision -IntakeDataRoot $IntakeDataRoot -Stack $repoStack

# Initialize intake state
$intakeState = @{
    user_input = $UserInput
    personas = $personas
    categories = $categories
    depth_rules = $depthRules
    user_profile = $userProfile
    auto_decisions = $autoDecisions
    repo_stack = $repoStack
    test_mode = $TestMode.IsPresent
    results = @()
}

# Execute persona-driven intake cycle (4 sequential lenses)
Write-Verbose "Beginning persona lens traversal (4 sequential lenses)"

foreach ($persona in $personas) {
    Write-Verbose "Applying lens: $($persona.name) ($($persona.id))"

    # Get expertise dial for this persona
    $personaExpertiseDial = $null
    $runtimeExpertiseDials = if ($userProfile) { Get-IntakeProfileValue -InputObject $userProfile -Key 'expertise_dials' } else { $null }
    if ($userProfile -and $runtimeExpertiseDials -and (Test-IntakeProfileKey -InputObject $runtimeExpertiseDials -Key $persona.id)) {
        $dialValue = Get-IntakeProfileValue -InputObject $runtimeExpertiseDials -Key $persona.id
        
        # Handle "auto" or "I'm new, you decide" - preserve the string as-is
        if ($dialValue -eq 'auto') {
            $personaExpertiseDial = 'auto'
            Write-Verbose "  Expertise dial: auto (system auto-decides)"
        }
        elseif ($dialValue -match '^\d+$') {
            $personaExpertiseDial = [int]$dialValue
            Write-Verbose "  Expertise dial: $personaExpertiseDial"
        }
        else {
            # Treat unrecognized values as auto
            $personaExpertiseDial = 'auto'
            Write-Verbose "  Expertise dial: auto (unrecognized value '$dialValue', defaulting to auto)"
        }
    }
    else {
        # Default mid-range when no profile exists
        $personaExpertiseDial = 5
        Write-Verbose "  Expertise dial: $personaExpertiseDial (default)"
    }

    # Calculate lens completeness (placeholder - would analyze existing content)
    $lensCompleteness = 0.5 # 50% for now (would be calculated from existing answers)

    # Resolve per-lens mode (Mode A/B/C)
    # When expertise is "auto", treat as Mode C (full interview with auto-decisions)
    if ($personaExpertiseDial -eq 'auto') {
        $lensMode = 'C'
        Write-Verbose "  Resolved lens mode: C (auto-decide path)"
    }
    else {
        $lensMode = Resolve-PerLensMode -ExpertiseDial $personaExpertiseDial -LensCompleteness $lensCompleteness -DepthRules $depthRules
        Write-Verbose "  Resolved lens mode: $lensMode"
    }

    # Traverse question bank for this persona
    $questions = Traverse-QuestionBank -IntakeDataRoot $IntakeDataRoot -PersonaId $persona.id -Mode $lensMode

    # Collect results for this lens
    $lensResult = @{
        persona_id = $persona.id
        persona_name = $persona.name
        expertise_dial = $personaExpertiseDial
        lens_completeness = $lensCompleteness
        lens_mode = $lensMode
        questions = $questions
    }

    # Render annotations for auto-decided items (Proposal 053 transparency)
    # Auto path OR low-expertise path both get auto-decisions with transparency
    if ($lensMode -eq 'C' -and ($personaExpertiseDial -eq 'auto' -or $personaExpertiseDial -le 3)) {
        $annotations = Render-Annotation -LensResult $lensResult -AutoDecisions $autoDecisions
        $lensResult.annotations = $annotations
    }

    $intakeState.results += $lensResult
}

# Determine overall intake mode (most-conservative-wins: C > B > A)
$overallMode = 'A'
foreach ($result in $intakeState.results) {
    if ($result.lens_mode -eq 'C') {
        $overallMode = 'C'
        break
    } elseif ($result.lens_mode -eq 'B') {
        $overallMode = 'B'
    }
}

Write-Verbose "Overall intake mode (most-conservative-wins): $overallMode"

# Return intake state
if ($TestMode) {
    Write-Output "ENGINE TEST MODE: Intake orchestration complete"
    Write-Output "  Personas loaded: $($personas.Count)"
    Write-Output "  Categories loaded: $($categories.Count)"
    Write-Output "  Detected stack: $repoStack"
    Write-Output "  Overall mode: $overallMode"
    Write-Output "  Lens results: $($intakeState.results.Count)"
}

return $intakeState
