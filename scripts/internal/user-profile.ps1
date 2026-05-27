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
    $yamlLines.Add('# Specrew User Profile') | Out-Null
    $yamlLines.Add('# Feature 049 Iteration 003 - Expertise-Aware Substantive Intake') | Out-Null
    $yamlLines.Add('# Cross-platform user-level expertise settings for persona-driven specification intake') | Out-Null
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
        return "No user profile found. Run specrew start to configure expertise settings."
    }
    
    # Load persona names from catalog for friendly display
    $personaMapping = @{
        'software_architecture' = @{ id = 'architect'; name = 'Architect' }
        'ui_ux' = @{ id = 'ux-ui-specialist'; name = 'UX/UI Specialist' }
        'product_management' = @{ id = 'product-manager'; name = 'Product Manager' }
        'ai_research_project_management' = @{ id = 'ai-researcher-project-manager'; name = 'AI Researcher / Project Manager' }
    }
    
    $summary = "**Expertise Profile:**`n"
    
    # Handle both old expertise_dials format and new expertise format
    if ($Profile.expertise) {
        foreach ($field in @('software_architecture', 'ui_ux', 'product_management', 'ai_research_project_management')) {
            if (Test-UserProfileKey -InputObject $Profile.expertise -Key $field) {
                $value = $Profile.expertise[$field]
                $personaName = $personaMapping[$field].name
                
                $levelDesc = if ($value -eq 'auto' -or $null -eq $value) {
                    'Auto (system decides)'
                }
                elseif ([int]$value -ge 7) {
                    "$value (Senior)"
                }
                elseif ([int]$value -ge 4) {
                    "$value (Standard)"
                }
                else {
                    "$value (Learning)"
                }
                
                $summary += "- ${personaName}: $levelDesc`n"
            }
        }
    }
    elseif ($Profile.expertise_dials) {
        # Legacy format fallback
        $legacyNames = @{
            'architect' = 'Architect'
            'ux-ui-specialist' = 'UX/UI Specialist'
            'product-manager' = 'Product Manager'
            'ai-researcher-project-manager' = 'AI Researcher / Project Manager'
        }
        foreach ($personaId in $Profile.expertise_dials.Keys | Sort-Object) {
            $value = $Profile.expertise_dials[$personaId]
            $personaName = if ($legacyNames.ContainsKey($personaId)) {
                $legacyNames[$personaId]
            }
            else {
                $personaId
            }
            
            $levelDesc = if ($value -eq 'auto' -or $null -eq $value) {
                'Auto (system decides)'
            }
            elseif ([int]$value -ge 7) {
                "$value (Senior)"
            }
            elseif ([int]$value -ge 4) {
                "$value (Standard)"
            }
            else {
                "$value (Learning)"
            }
            
            $summary += "- ${personaName}: $levelDesc`n"
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
        # Return sensible defaults for non-interactive scenarios
        return @{
            'product-manager' = 'auto'
            'ux-ui-specialist' = 'auto'
            'architect' = 'auto'
            'ai-researcher-project-manager' = 'auto'
        }
    }
    
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host " Welcome to Specrew - First-Time Setup" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To tailor the specification intake experience to your expertise," -ForegroundColor White
    Write-Host "please rate your comfort level in each of these areas (1-10):" -ForegroundColor White
    Write-Host ""
    Write-Host "  1-3  : Learning (system auto-decides with transparency)" -ForegroundColor Gray
    Write-Host "  4-6  : Standard (targeted clarifications)" -ForegroundColor Gray
    Write-Host "  7-10 : Senior (nuanced questions, minimal auto-decisions)" -ForegroundColor Gray
    Write-Host "  auto : I'm new, system decides for me" -ForegroundColor Gray
    Write-Host ""
    
    $personas = @(
        @{ Id = 'product-manager'; Name = 'Product Manager'; Desc = 'Business rules, prioritization, MVP boundaries' }
        @{ Id = 'ux-ui-specialist'; Name = 'UX/UI Specialist'; Desc = 'Interface state, accessibility, workflows' }
        @{ Id = 'architect'; Name = 'Architect'; Desc = 'Schemas, integration boundaries, deployment' }
        @{ Id = 'ai-researcher-project-manager'; Name = 'AI Researcher / Project Manager'; Desc = 'Capacity planning, safe parallelism, agent charters' }
    )
    
    $dials = @{}
    
    foreach ($persona in $personas) {
        Write-Host "[$($persona.Name)]" -ForegroundColor Yellow
        Write-Host "  $($persona.Desc)" -ForegroundColor Gray
        
        $validInput = $false
        while (-not $validInput) {
            $input = Read-Host "  Your rating (1-10 or 'auto')"
            
            if ($input -eq 'auto') {
                $dials[$persona.Id] = 'auto'
                $validInput = $true
            }
            elseif ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le 10) {
                $dials[$persona.Id] = [string][int]$input
                $validInput = $true
            }
            else {
                Write-Host "  Please enter a number between 1 and 10, or 'auto'" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
    
    Write-Host "Profile saved! You can update it anytime with /specrew-user-profile edit" -ForegroundColor Green
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
        Write-Host "User profile reset. You will be prompted to set expertise levels on next 'specrew start'." -ForegroundColor Yellow
    }
    else {
        Write-Host "No user profile found." -ForegroundColor Gray
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
        Write-Host "No profile found. Creating a new one..." -ForegroundColor Yellow
        $dials = Invoke-FirstRunExpertisePrompt
        Save-UserProfile -ExpertiseDials $dials -ProfilePath $ProfilePath
        return
    }
    
    Write-Host ""
    Write-Host "Current Expertise Settings:" -ForegroundColor Cyan
    Write-Host ""
    
    $personaNames = @{
        'product-manager' = 'Product Manager'
        'ux-ui-specialist' = 'UX/UI Specialist'
        'architect' = 'Architect'
        'ai-researcher-project-manager' = 'AI Researcher / Project Manager'
    }
    
    foreach ($personaId in $existing.expertise_dials.Keys | Sort-Object) {
        $value = $existing.expertise_dials[$personaId]
        $personaName = if ($personaNames.ContainsKey($personaId)) {
            $personaNames[$personaId]
        }
        else {
            $personaId
        }
        Write-Host "  $personaName : $value" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Enter new ratings (press Enter to keep current value):" -ForegroundColor Yellow
    Write-Host ""
    
    $newDials = @{}
    
    foreach ($personaId in $existing.expertise_dials.Keys | Sort-Object) {
        $personaName = if ($personaNames.ContainsKey($personaId)) {
            $personaNames[$personaId]
        }
        else {
            $personaId
        }
        
        $currentValue = $existing.expertise_dials[$personaId]
        $input = Read-Host "  $personaName (current: $currentValue)"
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            $newDials[$personaId] = $currentValue
        }
        elseif ($input -eq 'auto') {
            $newDials[$personaId] = 'auto'
        }
        elseif ($input -match '^\d+$' -and [int]$input -ge 1 -and [int]$input -le 10) {
            $newDials[$personaId] = [string][int]$input
        }
        else {
            Write-Host "    Invalid input, keeping current value" -ForegroundColor Red
            $newDials[$personaId] = $currentValue
        }
    }
    
    Save-UserProfile -ExpertiseDials $newDials -ProfilePath $ProfilePath
    Write-Host ""
    Write-Host "Profile updated!" -ForegroundColor Green
    Write-Host ""
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
        'Edit-UserProfile'
    )
}
