# User Profile Management Helper
# Feature 049 Iteration 003 - FR-024, FR-025, FR-026
# Handles cross-platform user-profile.yml persistence for expertise dials

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
        
        # Try to use powershell-yaml if available
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $profile = $content | ConvertFrom-Yaml
            return $profile
        }
        
        # Fallback: basic YAML parser for FR-024 schema
        $profile = @{
            schema = '1.0'
            specrew_version_at_creation = ''
            created_at = ''
            last_updated_at = ''
            user_name = $null
            expertise = @{
                software_architecture = $null
                ui_ux = $null
                product_management = $null
                ai_research_project_management = $null
            }
            preferences = @{
                preferred_intake_depth = 'auto'
            }
        }
        
        $lines = $content -split "`n"
        $inExpertiseSection = $false
        $inPreferencesSection = $false
        
        foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            
            if ($trimmedLine -match '^schema:\s*(.+)$') {
                $profile.schema = $matches[1].Trim('"', "'")
            }
            elseif ($trimmedLine -match '^specrew_version_at_creation:\s*(.+)$') {
                $profile.specrew_version_at_creation = $matches[1].Trim('"', "'")
            }
            elseif ($trimmedLine -match '^created_at:\s*(.+)$') {
                $profile.created_at = $matches[1].Trim('"', "'")
            }
            elseif ($trimmedLine -match '^last_updated_at:\s*(.+)$') {
                $profile.last_updated_at = $matches[1].Trim('"', "'")
            }
            elseif ($trimmedLine -match '^user_name:\s*(.+)$') {
                $profile.user_name = $matches[1].Trim('"', "'")
            }
            elseif ($trimmedLine -match '^expertise:') {
                $inExpertiseSection = $true
                $inPreferencesSection = $false
            }
            elseif ($trimmedLine -match '^preferences:') {
                $inPreferencesSection = $true
                $inExpertiseSection = $false
            }
            elseif ($inExpertiseSection -and $line -match '^\s+([a-z_]+):\s*(.+)$') {
                $field = $matches[1]
                $value = $matches[2].Trim().Trim('"', "'")
                if ($value -ne 'null' -and $value -ne '') {
                    $profile.expertise[$field] = $value
                }
            }
            elseif ($inPreferencesSection -and $line -match '^\s+([a-z_]+):\s*(.+)$') {
                $field = $matches[1]
                $value = $matches[2].Trim().Trim('"', "'")
                $profile.preferences[$field] = $value
            }
        }
        
        return $profile
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
    
    # Build YAML content per FR-024 schema
    $yamlContent = @"
# Specrew User Profile
# Feature 049 Iteration 003 - Expertise-Aware Substantive Intake
# Cross-platform user-level expertise settings for persona-driven specification intake

schema: "1.0"
specrew_version_at_creation: "$specrewVersion"
created_at: "$createdAt"
last_updated_at: "$timestamp"

# Expertise dials: 1-10 scale or "auto" for "I'm new, you decide"
# These settings persist across all Specrew projects for this user
expertise:
  software_architecture: $($ExpertiseDials['architect'])
  ui_ux: $($ExpertiseDials['ux-ui-specialist'])
  product_management: $($ExpertiseDials['product-manager'])
  ai_research_project_management: $($ExpertiseDials['ai-researcher-project-manager'])

preferences:
  preferred_intake_depth: "auto"
"@
    
    $yamlContent | Set-Content -LiteralPath $ProfilePath -Encoding UTF8 -NoNewline
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
            if ($Profile.expertise.ContainsKey($field)) {
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
