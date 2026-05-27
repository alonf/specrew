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

    $profile = @{
        schema_version = '1.0'
        created_at = ''
        updated_at = ''
        expertise_dials = @{}
    }

    $inExpertiseDials = $false

    foreach ($rawLine in ($Content -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) {
            continue
        }

        if ($rawLine.TrimStart().StartsWith('#')) {
            continue
        }

        if ($rawLine -match '^schema(?:_version)?:\s*(.+)$') {
            $profile.schema_version = Convert-IntakeYamlScalarValue -Value $matches[1]
            continue
        }

        if ($rawLine -match '^created_at:\s*(.+)$') {
            $profile.created_at = Convert-IntakeYamlScalarValue -Value $matches[1]
            continue
        }

        if ($rawLine -match '^updated_at:\s*(.+)$') {
            $profile.updated_at = Convert-IntakeYamlScalarValue -Value $matches[1]
            continue
        }

        if ($rawLine -match '^expertise(?:_dials)?:\s*$') {
            $inExpertiseDials = $true
            continue
        }

        if ($inExpertiseDials -and $rawLine -match '^\s{2}([A-Za-z0-9_-]+):\s*(.+)$') {
            $profile.expertise_dials[$matches[1]] = Convert-IntakeYamlScalarValue -Value $matches[2]
        }
    }

    return $profile
}

function Read-IntakeYamlDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('personas', 'categories', 'questions', 'defaults', 'depth_rules', 'user_profile')]
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
        'defaults' { return Convert-IntakeYamlMapSection -Content $content -RootKey 'defaults' }
        'depth_rules' { return Convert-IntakeDepthRules -Content $content }
        'user_profile' { return Convert-IntakeUserProfile -Content $content }
    }
}
