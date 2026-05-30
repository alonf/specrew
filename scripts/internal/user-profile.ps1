# User Profile Management Helper
# Feature 049 Iteration 003 - FR-024, FR-025, FR-026
# Handles cross-platform user-profile.yml persistence for expertise dials

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:UserProfileExpertiseMap = [ordered]@{
    'architect'                     = 'software_architecture'
    'ux-ui-specialist'              = 'ui_ux'
    'product-manager'               = 'product_management'
    'ai-researcher-project-manager' = 'ai_research_project_management'
}

# Crew Interaction Profile display metadata (Feature 049 Iteration 003 + Iteration 005 / Proposal 141).
#
# The user-facing profile is a CREW INTERACTION PROFILE: four decision-area settings (1-10 or auto)
# that tell Specrew how much to ask, explain, recommend, and auto-decide. The visible DisplayLabel is
# a decision area, NOT a job title or identity the user must claim (FR-032/FR-034). The persisted
# ExpertiseKey and Specrew's internal PersonaId lens identity are STABLE internal contracts that MUST
# NOT be renamed or migrated (FR-033). Higher settings get concise, expert-level questions (the user
# decides); lower or auto settings get more explanation, recommended defaults, and transparent
# auto-decisions (FR-035). Order below is the canonical first-run + display order.
$script:CrewInteractionProfileAreas = @(
    [ordered]@{ ExpertiseKey = 'product_management';             PersonaId = 'product-manager';                DisplayLabel = 'Product Strategy';      PersonaName = 'Product Manager';                 DecisionFocus = 'Business rules, prioritization, MVP boundaries' }
    [ordered]@{ ExpertiseKey = 'ui_ux';                          PersonaId = 'ux-ui-specialist';               DisplayLabel = 'UX/UI Design';          PersonaName = 'UX/UI Specialist';                DecisionFocus = 'Interface state, accessibility, workflows' }
    [ordered]@{ ExpertiseKey = 'software_architecture';          PersonaId = 'architect';                      DisplayLabel = 'Software Architecture'; PersonaName = 'Architect';                       DecisionFocus = 'Schemas, integration boundaries, deployment' }
    [ordered]@{ ExpertiseKey = 'ai_research_project_management'; PersonaId = 'ai-researcher-project-manager';  DisplayLabel = 'AI Delivery Planning';  PersonaName = 'AI Researcher / Project Manager'; DecisionFocus = 'Capacity planning, safe parallelism, agent charters' }
)

function Get-CrewInteractionProfileAreas {
    <#
    .SYNOPSIS
    Returns the authoritative Crew Interaction Profile decision-area metadata.
    .DESCRIPTION
    Each entry exposes the user-facing DisplayLabel (a decision area, not a job title), the stable
    persisted ExpertiseKey, the internal PersonaId/PersonaName lens identity, and the DecisionFocus
    blurb. Display labels are display metadata only; persona IDs and expertise keys are stable
    internal contracts (FR-032..FR-034).
    #>
    return $script:CrewInteractionProfileAreas
}

function Get-CrewInteractionProfileLabel {
    <#
    .SYNOPSIS
    Resolves the user-facing decision-area label for a persisted expertise key or internal persona ID.
    #>
    param(
        [Parameter(Mandatory = $false)][string]$ExpertiseKey,
        [Parameter(Mandatory = $false)][string]$PersonaId
    )

    foreach ($area in $script:CrewInteractionProfileAreas) {
        if ((-not [string]::IsNullOrWhiteSpace($ExpertiseKey)) -and $area.ExpertiseKey -eq $ExpertiseKey) {
            return $area.DisplayLabel
        }
        if ((-not [string]::IsNullOrWhiteSpace($PersonaId)) -and $area.PersonaId -eq $PersonaId) {
            return $area.DisplayLabel
        }
    }

    # Unknown / future area: fall back to the supplied identifier so summaries still render.
    if (-not [string]::IsNullOrWhiteSpace($PersonaId)) { return $PersonaId }
    return $ExpertiseKey
}

function Get-CrewInteractionLevelDescriptor {
    <#
    .SYNOPSIS
    Returns the collaboration descriptor for a dial value (auto/null, 1-3, 4-6, 7-10).
    .DESCRIPTION
    Describes how Specrew collaborates at that setting, not a competency judgement: higher settings
    ask concise expert-level questions and assume the user decides; lower or auto settings explain
    more, recommend defaults, and surface transparent auto-decisions (FR-035).
    #>
    param([AllowNull()]$Value)

    if ($Value -eq 'auto' -or $null -eq $Value) {
        return 'auto (Specrew recommends defaults and explains)'
    }

    $numeric = 0
    if ([int]::TryParse([string]$Value, [ref]$numeric)) {
        if ($numeric -ge 7) { return "$Value (Senior — concise questions; you decide)" }
        if ($numeric -ge 4) { return "$Value (Standard — targeted clarifications)" }
        return "$Value (Learning — Specrew explains and auto-decides with transparency)"
    }

    return [string]$Value
}

function Test-UserProfileKey {
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

function Get-UserProfileValue {
    param(
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if (-not (Test-UserProfileKey -InputObject $InputObject -Key $Key)) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return $InputObject[$Key]
    }

    return $InputObject.$Key
}

function ConvertTo-PersistedExpertiseValue {
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $stringValue = [string]$Value
    if ([string]::IsNullOrWhiteSpace($stringValue)) {
        return $null
    }

    if ($stringValue -eq 'auto' -or $stringValue -eq 'null') {
        return $null
    }

    if ($stringValue -match '^\d+$') {
        $numericValue = [int]$stringValue
        if ($numericValue -ge 1 -and $numericValue -le 10) {
            return $numericValue
        }
    }

    return $null
}

function ConvertTo-RuntimeExpertiseDial {
    param([AllowNull()]$Value)

    $persistedValue = ConvertTo-PersistedExpertiseValue -Value $Value
    if ($null -eq $persistedValue) {
        return 'auto'
    }

    return $persistedValue
}

function ConvertTo-NormalizedUserProfile {
    param(
        [AllowNull()]
        [object]$RawProfile
    )

    if ($null -eq $RawProfile) {
        return $null
    }

    $profile = [ordered]@{
        schema                       = '1.0'
        specrew_version_at_creation  = ''
        created_at                   = ''
        last_updated_at              = ''
        user_name                    = $null
        expertise                    = [ordered]@{
            software_architecture           = $null
            ui_ux                           = $null
            product_management              = $null
            ai_research_project_management  = $null
        }
        preferences                  = [ordered]@{
            preferred_intake_depth = 'auto'
        }
        expertise_dials              = [ordered]@{}
        schema_version               = '1.0'
        updated_at                   = ''
    }

    $schema = Get-UserProfileValue -InputObject $RawProfile -Key 'schema'
    if ($null -eq $schema) {
        $schema = Get-UserProfileValue -InputObject $RawProfile -Key 'schema_version'
    }
    if ($null -ne $schema) {
        $profile.schema = [string]$schema
    }

    foreach ($key in @('specrew_version_at_creation', 'created_at', 'user_name')) {
        $value = Get-UserProfileValue -InputObject $RawProfile -Key $key
        if ($null -ne $value) {
            $profile[$key] = $value
        }
    }

    $lastUpdated = Get-UserProfileValue -InputObject $RawProfile -Key 'last_updated_at'
    if ($null -eq $lastUpdated) {
        $lastUpdated = Get-UserProfileValue -InputObject $RawProfile -Key 'updated_at'
    }
    if ($null -ne $lastUpdated) {
        $profile.last_updated_at = $lastUpdated
    }

    $rawPreferences = Get-UserProfileValue -InputObject $RawProfile -Key 'preferences'
    if ($null -ne $rawPreferences) {
        $preferredDepth = Get-UserProfileValue -InputObject $rawPreferences -Key 'preferred_intake_depth'
        if (-not [string]::IsNullOrWhiteSpace([string]$preferredDepth)) {
            $profile.preferences.preferred_intake_depth = [string]$preferredDepth
        }
    }

    $rawExpertise = Get-UserProfileValue -InputObject $RawProfile -Key 'expertise'
    if ($null -ne $rawExpertise) {
        foreach ($field in @('software_architecture', 'ui_ux', 'product_management', 'ai_research_project_management')) {
            if (Test-UserProfileKey -InputObject $rawExpertise -Key $field) {
                $profile.expertise[$field] = ConvertTo-PersistedExpertiseValue -Value (Get-UserProfileValue -InputObject $rawExpertise -Key $field)
            }
        }
    }

    $rawLegacyDials = Get-UserProfileValue -InputObject $RawProfile -Key 'expertise_dials'
    if ($null -ne $rawLegacyDials) {
        foreach ($personaId in $script:UserProfileExpertiseMap.Keys) {
            if (Test-UserProfileKey -InputObject $rawLegacyDials -Key $personaId) {
                $profile.expertise[$script:UserProfileExpertiseMap[$personaId]] = ConvertTo-PersistedExpertiseValue -Value (Get-UserProfileValue -InputObject $rawLegacyDials -Key $personaId)
            }
        }
    }

    foreach ($personaId in $script:UserProfileExpertiseMap.Keys) {
        $field = $script:UserProfileExpertiseMap[$personaId]
        $profile.expertise_dials[$personaId] = ConvertTo-RuntimeExpertiseDial -Value $profile.expertise[$field]
    }

    $profile.schema_version = $profile.schema
    $profile.updated_at = $profile.last_updated_at

    return $profile
}

function Get-UserProfilePath {
    <#
    .SYNOPSIS
    Returns the cross-platform path to user-profile.yml
    
    .DESCRIPTION
    Windows: $env:USERPROFILE\.specrew\user-profile.yml
    Unix: ~/.specrew/user-profile.yml
    #>
    if ($IsWindows -or ($null -eq $IsWindows -and $env:OS -match 'Windows')) {
        $baseDir = $env:USERPROFILE
    }
    else {
        $baseDir = $env:HOME
    }
    
    $specrewDir = Join-Path $baseDir '.specrew'
    return Join-Path $specrewDir 'user-profile.yml'
}

function Test-UserProfileExists {
    <#
    .SYNOPSIS
    Checks if user-profile.yml exists
    #>
    $profilePath = Get-UserProfilePath
    return Test-Path -LiteralPath $profilePath -PathType Leaf
}

function Get-UserProfile {
    <#
    .SYNOPSIS
    Loads and returns the user profile from user-profile.yml
    
    .DESCRIPTION
    Returns a hashtable with schema_version, created_at, updated_at, and expertise_dials.
    Returns $null if the profile doesn't exist.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProfilePath
    )
    
    if (-not $ProfilePath) {
        $ProfilePath = Get-UserProfilePath
    }
    
    if (-not (Test-Path -LiteralPath $ProfilePath -PathType Leaf)) {
        return $null
    }
    
    try {
        $content = Get-Content -LiteralPath $ProfilePath -Raw -Encoding UTF8
        
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            return ConvertTo-NormalizedUserProfile -RawProfile ($content | ConvertFrom-Yaml)
        }

        $rawProfile = [ordered]@{
            schema = '1.0'
            specrew_version_at_creation = ''
            created_at = ''
            last_updated_at = ''
            user_name = $null
            expertise = [ordered]@{}
            preferences = [ordered]@{}
            expertise_dials = [ordered]@{}
        }

        $section = $null
        foreach ($line in ($content -split "`r?`n")) {
            $trimmedLine = $line.Trim()

            if ([string]::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
                continue
            }

            if ($line -match '^(schema|schema_version|specrew_version_at_creation|created_at|last_updated_at|updated_at|user_name):\s*(.*)$') {
                $rawProfile[$matches[1]] = $matches[2].Trim().Trim('"', "'")
                $section = $null
                continue
            }

            if ($trimmedLine -match '^(expertise|preferences|expertise_dials):\s*$') {
                $section = $matches[1]
                continue
            }

            if ($line -match '^\s+([A-Za-z0-9_-]+):\s*(.*)$' -and $null -ne $section) {
                $key = $matches[1]
                $value = $matches[2].Trim().Trim('"', "'")
                if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'null') {
                    $rawProfile[$section][$key] = $null
                }
                else {
                    $rawProfile[$section][$key] = $value
                }
            }
        }

        return ConvertTo-NormalizedUserProfile -RawProfile $rawProfile
    }
    catch {
        Write-Warning "Failed to parse user-profile.yml: $($_.Exception.Message)"
        return $null
    }
}

function Save-UserProfile {
    <#
    .SYNOPSIS
    Saves the user profile to user-profile.yml
    
    .PARAMETER ExpertiseDials
    Hashtable with persona IDs as keys and expertise levels (1-10 or "auto") as values
    
    .PARAMETER ProfilePath
    Optional custom path for the profile file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ExpertiseDials,
        
        [Parameter(Mandatory = $false)]
        [string]$ProfilePath
    )
    
    if (-not $ProfilePath) {
        $ProfilePath = Get-UserProfilePath
    }
    
    $profileDir = Split-Path $ProfilePath -Parent
    if (-not (Test-Path -LiteralPath $profileDir)) {
        $null = New-Item -Path $profileDir -ItemType Directory -Force
    }
    
    $timestamp = Get-Date -Format 'o'
    
    # Check if profile already exists to preserve created_at
    $existing = Get-UserProfile -ProfilePath $ProfilePath
    $createdAt = if ($existing -and $existing.created_at) {
        $existing.created_at
    }
    else {
        $timestamp
    }
    
    # Get module version
    $specrewVersion = '0.27.6'  # Default fallback
    try {
        $modulePath = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) 'Specrew.psd1'
        if (Test-Path $modulePath) {
            $moduleData = Import-PowerShellDataFile -Path $modulePath
            $specrewVersion = $moduleData.ModuleVersion
        }
    }
    catch {
        # Fallback to default version
    }
    
    $existingProfile = ConvertTo-NormalizedUserProfile -RawProfile $existing
    $preferredDepth = if ($existingProfile -and $existingProfile.preferences.preferred_intake_depth) {
        [string]$existingProfile.preferences.preferred_intake_depth
    }
    else {
        'auto'
    }
    $userName = if ($existingProfile -and -not [string]::IsNullOrWhiteSpace([string]$existingProfile.user_name)) {
        [string]$existingProfile.user_name
    }
    else {
        $null
    }

    $persistedExpertise = [ordered]@{}
    foreach ($personaId in $script:UserProfileExpertiseMap.Keys) {
        $persistedExpertise[$script:UserProfileExpertiseMap[$personaId]] = ConvertTo-PersistedExpertiseValue -Value $ExpertiseDials[$personaId]
    }

    $yamlLines = New-Object System.Collections.Generic.List[string]
    $yamlLines.Add('# Specrew User Profile (Crew Interaction Profile)') | Out-Null
    $yamlLines.Add('# Four decision-area settings telling Specrew how much to ask, explain, recommend, and auto-decide.') | Out-Null
    $yamlLines.Add('# The expertise.* keys below are stable internal contracts and are NOT renamed by display labels.') | Out-Null
    $yamlLines.Add('') | Out-Null
    $yamlLines.Add('schema: "1.0"') | Out-Null
    $yamlLines.Add(("specrew_version_at_creation: ""{0}""" -f $specrewVersion)) | Out-Null
    $yamlLines.Add(("created_at: ""{0}""" -f $createdAt)) | Out-Null
    $yamlLines.Add(("last_updated_at: ""{0}""" -f $timestamp)) | Out-Null
    if ($null -ne $userName) {
        $yamlLines.Add(("user_name: ""{0}""" -f $userName.Replace('"', '\"'))) | Out-Null
    }
    $yamlLines.Add('') | Out-Null
    $yamlLines.Add('# Expertise dials persist as 1-10 or null; null keeps the auto-decision path') | Out-Null
    $yamlLines.Add('# These settings persist across all Specrew projects for this user') | Out-Null
    $yamlLines.Add('expertise:') | Out-Null
    foreach ($field in @('software_architecture', 'ui_ux', 'product_management', 'ai_research_project_management')) {
        $value = $persistedExpertise[$field]
        $scalar = if ($null -eq $value) { 'null' } else { [string]$value }
        $yamlLines.Add(("  {0}: {1}" -f $field, $scalar)) | Out-Null
    }
    $yamlLines.Add('') | Out-Null
    $yamlLines.Add('preferences:') | Out-Null
    $yamlLines.Add(("  preferred_intake_depth: ""{0}""" -f $preferredDepth)) | Out-Null

    ($yamlLines -join "`n") | Set-Content -LiteralPath $ProfilePath -Encoding UTF8 -NoNewline
}

function Show-UserProfileSummary {
    <#
    .SYNOPSIS
    Displays a user-friendly summary of the current profile
    
    .DESCRIPTION
    Returns formatted text suitable for inclusion in start-context.json or start-summary.md
    #>
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Profile
    )
    
    if (-not $Profile) {
        $Profile = Get-UserProfile
    }

    if (-not $Profile) {
        return "No Crew Interaction Profile found yet. Run ``specrew start`` to set how much you want Specrew to ask, explain, recommend, and auto-decide."
    }

    $summary = "**Crew Interaction Profile (current user):**`n"
    $summary += "_How much you want Specrew to ask, explain, recommend, and auto-decide across four decision areas. Higher settings get concise, expert-level questions (you make the call); lower or ``auto`` settings get more explanation, recommended defaults, and transparent auto-decisions. These are your collaboration settings — they do not rename Specrew's internal persona lenses._`n`n"

    # Resolve each decision area from the stable expertise keys, falling back to the legacy
    # expertise_dials layout keyed by internal persona IDs. Either way the persisted keys and persona
    # IDs are unchanged; only the visible labels are decision-area names (FR-032..FR-035).
    foreach ($area in Get-CrewInteractionProfileAreas) {
        $value = $null
        $resolved = $false
        if ((Test-UserProfileKey -InputObject $Profile -Key 'expertise') -and (Test-UserProfileKey -InputObject $Profile.expertise -Key $area.ExpertiseKey)) {
            $value = $Profile.expertise[$area.ExpertiseKey]
            $resolved = $true
        }
        elseif ((Test-UserProfileKey -InputObject $Profile -Key 'expertise_dials') -and (Test-UserProfileKey -InputObject $Profile.expertise_dials -Key $area.PersonaId)) {
            $value = $Profile.expertise_dials[$area.PersonaId]
            $resolved = $true
        }

        if ($resolved) {
            $summary += "- $($area.DisplayLabel): $(Get-CrewInteractionLevelDescriptor -Value $value)`n"
        }
    }

    $summary += "`nTo update: use ``/specrew-user-profile edit`` or ``/specrew-user-profile reset``"

    return $summary
}

function Invoke-FirstRunExpertisePrompt {
    <#
    .SYNOPSIS
    Prompts the user for expertise self-rating on first run
    
    .DESCRIPTION
    Presents a friendly interactive prompt asking for expertise ratings across all personas.
    Returns a hashtable suitable for Save-UserProfile.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [switch]$NonInteractive,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$DefaultDials
    )
    
    if ($NonInteractive) {
        # Return sensible defaults for non-interactive scenarios.
        $defaults = @{}
        foreach ($area in Get-CrewInteractionProfileAreas) {
            $defaults[$area.PersonaId] = 'auto'
        }
        return $defaults
    }

    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host " Welcome to Specrew - Crew Interaction Profile Setup" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your Crew Interaction Profile tells Specrew how much to ask, explain," -ForegroundColor White
    Write-Host "recommend, and auto-decide for you across four decision areas. It is a" -ForegroundColor White
    Write-Host "collaboration setting, not a job title — Specrew keeps its own internal" -ForegroundColor White
    Write-Host "persona lenses regardless of what you choose. Set each area 1-10:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1-3  : Learning (Specrew explains more and auto-decides with transparency)" -ForegroundColor Gray
    Write-Host "  4-6  : Standard (targeted clarifications)" -ForegroundColor Gray
    Write-Host "  7-10 : Senior (concise expert-level questions; you make the call)" -ForegroundColor Gray
    Write-Host "  auto : Let Specrew recommend defaults and explain them" -ForegroundColor Gray
    Write-Host ""

    $dials = @{}

    foreach ($area in Get-CrewInteractionProfileAreas) {
        Write-Host "[$($area.DisplayLabel)]" -ForegroundColor Yellow
        Write-Host "  $($area.DecisionFocus)" -ForegroundColor Gray

        $validInput = $false
        while (-not $validInput) {
            $input = Read-Host "  Your setting (1-10 or 'auto')"

            if ($input -eq 'auto') {
                $dials[$area.PersonaId] = 'auto'
                $validInput = $true
            }
            elseif ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le 10) {
                $dials[$area.PersonaId] = [string][int]$input
                $validInput = $true
            }
            else {
                Write-Host "  Please enter a number between 1 and 10, or 'auto'" -ForegroundColor Red
            }
        }
        Write-Host ""
    }

    Write-Host "Crew Interaction Profile saved! Update it anytime with /specrew-user-profile edit" -ForegroundColor Green
    Write-Host ""

    return $dials
}

function Reset-UserProfile {
    <#
    .SYNOPSIS
    Deletes the user profile, triggering first-run on next start
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProfilePath
    )
    
    if (-not $ProfilePath) {
        $ProfilePath = Get-UserProfilePath
    }
    
    if (Test-Path -LiteralPath $ProfilePath) {
        Remove-Item -LiteralPath $ProfilePath -Force
        Write-Host "Crew Interaction Profile reset. You will be prompted to set it again on next 'specrew start'." -ForegroundColor Yellow
    }
    else {
        Write-Host "No Crew Interaction Profile found." -ForegroundColor Gray
    }
}

function Edit-UserProfile {
    <#
    .SYNOPSIS
    Interactive editor for updating existing profile
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProfilePath
    )
    
    if (-not $ProfilePath) {
        $ProfilePath = Get-UserProfilePath
    }
    
    $existing = Get-UserProfile -ProfilePath $ProfilePath

    if (-not $existing) {
        Write-Host "No Crew Interaction Profile found. Creating a new one..." -ForegroundColor Yellow
        $dials = Invoke-FirstRunExpertisePrompt
        Save-UserProfile -ExpertiseDials $dials -ProfilePath $ProfilePath
        return
    }

    Write-Host ""
    Write-Host "Current Crew Interaction Profile (decision-area settings):" -ForegroundColor Cyan
    Write-Host ""

    # Iterate the canonical decision-area order; show decision-area labels while keeping the stable
    # internal persona IDs as the dial keys we read and write (FR-032..FR-034).
    foreach ($area in Get-CrewInteractionProfileAreas) {
        $value = $existing.expertise_dials[$area.PersonaId]
        Write-Host "  $($area.DisplayLabel) : $value" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Enter new settings (press Enter to keep current value):" -ForegroundColor Yellow
    Write-Host ""

    $newDials = @{}

    foreach ($area in Get-CrewInteractionProfileAreas) {
        $currentValue = $existing.expertise_dials[$area.PersonaId]
        $input = Read-Host "  $($area.DisplayLabel) (current: $currentValue)"

        if ([string]::IsNullOrWhiteSpace($input)) {
            $newDials[$area.PersonaId] = $currentValue
        }
        elseif ($input -eq 'auto') {
            $newDials[$area.PersonaId] = 'auto'
        }
        elseif ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le 10) {
            $newDials[$area.PersonaId] = [string][int]$input
        }
        else {
            Write-Host "    Invalid input, keeping current value" -ForegroundColor Red
            $newDials[$area.PersonaId] = $currentValue
        }
    }

    Save-UserProfile -ExpertiseDials $newDials -ProfilePath $ProfilePath
    Write-Host ""
    Write-Host "Crew Interaction Profile updated!" -ForegroundColor Green
    Write-Host ""
}

function New-CrewInteractionProfileSessionContext {
    <#
    .SYNOPSIS
    Builds the current-user Crew Interaction Profile block for session context (start-context.json).

    .DESCRIPTION
    Marks the resolved profile as SOFT, current-user runtime collaboration guidance for all agents —
    explicitly NOT shared project truth (FR-038). Outside /speckit.specify the profile is soft guidance
    only; /speckit.specify is the only surface that hard-applies it (FR-040). Persisted expertise keys
    and internal persona IDs are preserved unchanged (FR-033); decision_areas is keyed by the visible
    decision-area label for display, while expertise_dials retains the stable persona IDs.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [object]$Profile
    )

    if (-not $Profile) {
        $Profile = Get-UserProfile
    }

    if (-not $Profile) {
        return $null
    }

    $rawExpertise = Get-UserProfileValue -InputObject $Profile -Key 'expertise'

    $decisionAreas = [ordered]@{}
    foreach ($area in Get-CrewInteractionProfileAreas) {
        $setting = ConvertTo-RuntimeExpertiseDial -Value (Get-UserProfileValue -InputObject $rawExpertise -Key $area.ExpertiseKey)
        $decisionAreas[$area.DisplayLabel] = [ordered]@{
            expertise_key   = $area.ExpertiseKey
            persona_lens_id = $area.PersonaId
            setting         = $setting
        }
    }

    return [ordered]@{
        kind                 = 'current-user-crew-interaction-profile'
        scope                = 'current-user-runtime-guidance'
        shared_project_truth = $false
        application          = 'soft collaboration guidance for all agents; hard-applied only in /speckit.specify'
        guidance             = "Higher settings: ask concise expert-level questions and assume the current user decides. Lower or auto settings: explain more, recommend defaults, and surface transparent auto-decisions. These are the current user's collaboration settings, not Specrew's internal persona lenses."
        profile_path         = Get-UserProfilePath
        schema_version       = (Get-UserProfileValue -InputObject $Profile -Key 'schema_version')
        created_at           = (Get-UserProfileValue -InputObject $Profile -Key 'created_at')
        updated_at           = (Get-UserProfileValue -InputObject $Profile -Key 'updated_at')
        decision_areas       = $decisionAreas
        expertise_dials      = (Get-UserProfileValue -InputObject $Profile -Key 'expertise_dials')
    }
}

# Export functions when loaded as a module; allow dot-sourcing in tests.
if ($null -ne $ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function @(
        'Get-UserProfilePath',
        'Test-UserProfileExists',
        'Get-UserProfile',
        'Save-UserProfile',
        'Show-UserProfileSummary',
        'Invoke-FirstRunExpertisePrompt',
        'Reset-UserProfile',
        'Edit-UserProfile',
        'Get-CrewInteractionProfileAreas',
        'Get-CrewInteractionProfileLabel',
        'Get-CrewInteractionLevelDescriptor',
        'New-CrewInteractionProfileSessionContext'
    )
}
