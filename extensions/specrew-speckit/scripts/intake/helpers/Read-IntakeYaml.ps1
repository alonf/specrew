<#
.SYNOPSIS
Read intake YAML artifacts without requiring ConvertFrom-Yaml.

.DESCRIPTION
Provides narrow parsers for the fixed Feature 049 intake catalogs so the
engine can execute in PowerShell 7 environments that do not ship with the
powershell-yaml module.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-IntakeYamlScalarValue {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $trimmed = $Value.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return ''
    }

    if (($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) -or ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'"))) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }

    if ($trimmed -eq 'null') {
        return $null
    }

    if ($trimmed -match '^\[(.*)\]$') {
        $inner = $matches[1].Trim()
        if ([string]::IsNullOrWhiteSpace($inner)) {
            return @()
        }

        return @(
            $inner -split ',' |
                ForEach-Object { Convert-IntakeYamlScalarValue -Value $_ } |
                Where-Object { $_ -ne '' }
        )
    }

    if ($trimmed -match '^\d+$') {
        return [int]$trimmed
    }

    if ($trimmed -match '^\d+\.\d+$') {
        return [double]::Parse($trimmed, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return $trimmed
}

function Convert-IntakeYamlObjectList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$RootKey
    )

    $items = New-Object System.Collections.Generic.List[object]
    $current = $null
    $currentArrayProperty = $null
    $inSection = $false

    foreach ($rawLine in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) {
            continue
        }

        if ($rawLine.TrimStart().StartsWith('#')) {
            continue
        }

        if (-not $inSection) {
            if ($rawLine -match ('^{0}:\s*$' -f [regex]::Escape($RootKey))) {
                $inSection = $true
            }
            continue
        }

        if ($rawLine -match '^\s{2}-\s+id:\s*(.+)$') {
            if ($null -ne $current) {
                $items.Add([pscustomobject]$current) | Out-Null
            }

            $current = [ordered]@{
                id = Convert-IntakeYamlScalarValue -Value $matches[1]
            }
            $currentArrayProperty = $null
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($rawLine -match '^\s{4}([A-Za-z0-9_]+):\s*(.*)$') {
            $propertyName = $matches[1]
            $propertyValue = $matches[2]

            if ([string]::IsNullOrWhiteSpace($propertyValue)) {
                $current[$propertyName] = @()
                $currentArrayProperty = $propertyName
            }
            else {
                $current[$propertyName] = Convert-IntakeYamlScalarValue -Value $propertyValue
                $currentArrayProperty = $null
            }
            continue
        }

        if ($null -ne $currentArrayProperty -and $rawLine -match '^\s{6}-\s*(.+)$') {
            $current[$currentArrayProperty] += Convert-IntakeYamlScalarValue -Value $matches[1]
        }
    }

    if ($null -ne $current) {
        $items.Add([pscustomobject]$current) | Out-Null
    }

    return $items.ToArray()
}

function Convert-IntakeYamlMapSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$RootKey
    )

    $map = @{}
    $inSection = $false

    foreach ($rawLine in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) {
            continue
        }

        if ($rawLine.TrimStart().StartsWith('#')) {
            continue
        }

        if (-not $inSection) {
            if ($rawLine -match ('^{0}:\s*$' -f [regex]::Escape($RootKey))) {
                $inSection = $true
            }
            continue
        }

        if ($rawLine -match '^[A-Za-z0-9_]+:\s*.*$') {
            break
        }

        if ($rawLine -match '^\s{2}([A-Za-z0-9_]+):\s*(.+)$') {
            $map[$matches[1]] = Convert-IntakeYamlScalarValue -Value $matches[2]
        }
    }

    return $map
}

function Convert-IntakeDepthRules {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $rules = @{
        mode_a_thresholds = @{}
        mode_b_thresholds = @{
            expertise_range    = @{}
            completeness_range = @{}
        }
        mode_c_thresholds = @{}
        conflict_resolution = @{
            priority_order = @()
        }
    }

    $section = ''
    $subsection = ''

    foreach ($rawLine in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) {
            continue
        }

        if ($rawLine.TrimStart().StartsWith('#')) {
            continue
        }

        if ($rawLine -match '^(mode_a_thresholds|mode_b_thresholds|mode_c_thresholds|conflict_resolution):\s*$') {
            $section = $matches[1]
            $subsection = ''
            continue
        }

        if ($rawLine -match '^\s{2}(expertise_range|completeness_range):\s*$') {
            $subsection = $matches[1]
            continue
        }

        if ($rawLine -match '^\s{2}([A-Za-z0-9_]+):\s*(.+)$') {
            $key = $matches[1]
            $value = Convert-IntakeYamlScalarValue -Value $matches[2]
            if ($section -eq 'mode_a_thresholds') {
                $rules.mode_a_thresholds[$key] = $value
            }
            elseif ($section -eq 'mode_c_thresholds') {
                $rules.mode_c_thresholds[$key] = $value
            }
            elseif ($section -eq 'conflict_resolution') {
                $rules.conflict_resolution[$key] = $value
            }
            continue
        }

        if ($rawLine -match '^\s{4}([A-Za-z0-9_]+):\s*(.+)$' -and $section -eq 'mode_b_thresholds' -and -not [string]::IsNullOrWhiteSpace($subsection)) {
            $rules.mode_b_thresholds[$subsection][$matches[1]] = Convert-IntakeYamlScalarValue -Value $matches[2]
        }
    }

    return $rules
}

function Convert-IntakeUserProfile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $personaFieldMap = [ordered]@{
        'architect'                     = 'software_architecture'
        'ux-ui-specialist'              = 'ui_ux'
        'product-manager'               = 'product_management'
        'ai-researcher-project-manager' = 'ai_research_project_management'
    }

    $profileData = [ordered]@{
        schema                      = '1.0'
        schema_version              = '1.0'
        specrew_version_at_creation = ''
        created_at                  = ''
        last_updated_at             = ''
        updated_at                  = ''
        user_name                   = $null
        expertise                   = [ordered]@{
            software_architecture          = $null
            ui_ux                          = $null
            product_management             = $null
            ai_research_project_management = $null
        }
        preferences                 = [ordered]@{
            preferred_intake_depth = 'auto'
        }
        expertise_dials             = [ordered]@{}
    }

    $section = $null

    foreach ($rawLine in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) {
            continue
        }

        if ($rawLine.TrimStart().StartsWith('#')) {
            continue
        }

        if ($rawLine -match '^schema:\s*(.+)$') {
            $profileData.schema = Convert-IntakeYamlScalarValue -Value $matches[1]
            continue
        }

        if ($rawLine -match '^schema_version:\s*(.+)$') {
            $profileData.schema = Convert-IntakeYamlScalarValue -Value $matches[1]
            continue
        }

        if ($rawLine -match '^(specrew_version_at_creation|created_at|last_updated_at|updated_at|user_name):\s*(.+)$') {
            $profileData[$matches[1]] = Convert-IntakeYamlScalarValue -Value $matches[2]
            continue
        }

        if ($rawLine -match '^(expertise|preferences|expertise_dials):\s*$') {
            $section = $matches[1]
            continue
        }

        if ($rawLine -match '^\s{2}([A-Za-z0-9_-]+):\s*(.+)$' -and $null -ne $section) {
            $key = $matches[1]
            $value = Convert-IntakeYamlScalarValue -Value $matches[2]
            if ($section -eq 'preferences') {
                $profileData.preferences[$key] = $value
            }
            else {
                $profileData[$section][$key] = $value
            }
        }
    }

    foreach ($personaId in $personaFieldMap.Keys) {
        $field = $personaFieldMap[$personaId]
        if ($profileData.expertise[$field] -eq 'auto') {
            $profileData.expertise[$field] = $null
        }
        elseif ($null -eq $profileData.expertise[$field] -and $profileData.expertise_dials.Contains($personaId)) {
            $legacyValue = $profileData.expertise_dials[$personaId]
            if ($legacyValue -eq 'auto') {
                $profileData.expertise[$field] = $null
            }
            elseif ($null -ne $legacyValue) {
                $profileData.expertise[$field] = $legacyValue
            }
        }

        $profileData.expertise_dials[$personaId] = if ($null -eq $profileData.expertise[$field]) { 'auto' } else { $profileData.expertise[$field] }
    }

    $profileData.schema_version = $profileData.schema
    $profileData.updated_at = if ($null -ne $profileData.last_updated_at -and $profileData.last_updated_at -ne '') { $profileData.last_updated_at } else { $profileData.updated_at }

    return $profileData
}

function Read-IntakeYamlDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('personas', 'categories', 'questions', 'lenses', 'defaults', 'depth_rules', 'user_profile')]
        [string]$Kind
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "YAML artifact not found: $Path"
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

    switch ($Kind) {
        'personas' { return Convert-IntakeYamlObjectList -Content $content -RootKey 'personas' }
        'categories' { return Convert-IntakeYamlObjectList -Content $content -RootKey 'categories' }
        'questions' { return Convert-IntakeYamlObjectList -Content $content -RootKey 'questions' }
        'lenses' { return Convert-IntakeYamlObjectList -Content $content -RootKey 'lenses' }
        'defaults' { return Convert-IntakeYamlMapSection -Content $content -RootKey 'defaults' }
        'depth_rules' { return Convert-IntakeDepthRules -Content $content }
        'user_profile' { return Convert-IntakeUserProfile -Content $content }
    }
}
