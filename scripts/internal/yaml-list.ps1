<#
.SYNOPSIS
    Minimal read/serialize for a YAML "top-key: list-of-flat-mappings" schema (F-051).

.DESCRIPTION
    Specrew deliberately avoids a `ConvertFrom-Yaml` / powershell-yaml dependency (see
    Read-IntakeYaml.ps1). This shared helper handles the specific, controlled schema used
    by the multi-session state files - a single top-level key whose value is a list of
    mappings with scalar string fields:

        <top-key>:
          - field_a: "value"
            field_b: "value"

    Reused by session-management.ps1 (active-sessions.yml) and feature-claims.ps1
    (active-features.yml) so the parse/emit logic exists once, not copy-pasted.
#>

Set-StrictMode -Version Latest

function ConvertTo-SpecrewYamlList {
    <# Serialize an array of [ordered] entries to the top-key list schema. #>
    param(
        [Parameter(Mandatory = $true)][string]$TopKey,
        [AllowEmptyCollection()][AllowNull()][object[]]$Entries
    )
    $entries = @($Entries | Where-Object { $null -ne $_ })
    if ($entries.Count -eq 0) {
        return ('{0}: []{1}' -f $TopKey, [Environment]::NewLine)
    }
    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.Append($TopKey).Append(':').Append([Environment]::NewLine)
    foreach ($entry in $entries) {
        $first = $true
        foreach ($name in $entry.Keys) {
            $raw = [string]$entry[$name]
            $escaped = $raw.Replace('\', '\\').Replace('"', '\"')
            $prefix = if ($first) { '  - ' } else { '    ' }
            $null = $sb.Append($prefix).Append($name).Append(': "').Append($escaped).Append('"').Append([Environment]::NewLine)
            $first = $false
        }
    }
    return $sb.ToString()
}

function ConvertFrom-SpecrewYamlList {
    <#
    Parse the top-key list schema into an array of [ordered] hashtables. Tolerant of blank
    lines and comments; throws on a structurally broken entry so callers can degrade safely.
    Returns @() when the top key is absent.
    #>
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][AllowNull()][string]$Content,
        [Parameter(Mandatory = $true)][string]$TopKey
    )
    $entries = [System.Collections.Generic.List[object]]::new()
    if ([string]::IsNullOrWhiteSpace($Content)) { return @() }

    $lines = $Content -split "`r?`n"
    $inList = $false
    $current = $null
    $escapedKey = [regex]::Escape($TopKey)

    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $trimmedStart = $line.TrimStart()
        if ($trimmedStart.StartsWith('#')) { continue }

        if (-not $inList) {
            if ($line -match ("^{0}:\s*\[\s*\]\s*$" -f $escapedKey)) { return @() }       # top-key: []
            if ($line -match ("^{0}:\s*$" -f $escapedKey)) { $inList = $true; continue }   # top-key:
            continue                                                                        # ignore preamble/other keys
        }

        if ($line -match '^\s{2}-\s+(?<k>[A-Za-z0-9_]+):\s*(?<v>.*)$') {
            if ($null -ne $current) { $entries.Add($current) }
            $current = [ordered]@{}
            $current[$Matches['k']] = (Convert-SpecrewYamlScalar -Raw $Matches['v'])
        }
        elseif ($line -match '^\s{4}(?<k>[A-Za-z0-9_]+):\s*(?<v>.*)$') {
            if ($null -eq $current) { throw "Malformed YAML list: field line before any '- ' entry start." }
            $current[$Matches['k']] = (Convert-SpecrewYamlScalar -Raw $Matches['v'])
        }
        else {
            throw "Malformed YAML list line: '$line'"
        }
    }
    if ($null -ne $current) { $entries.Add($current) }
    return $entries.ToArray()
}

function Convert-SpecrewYamlScalar {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Raw)
    $v = $Raw.Trim()
    if ($v.Length -ge 2 -and $v.StartsWith('"') -and $v.EndsWith('"')) {
        $v = $v.Substring(1, $v.Length - 2).Replace('\"', '"').Replace('\\', '\')
    }
    return $v
}

function Read-SpecrewYamlList {
    <# Read a YAML-list file safely: missing OR corrupt -> @() (+warning on corrupt). #>
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TopKey
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    try {
        $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        return @(ConvertFrom-SpecrewYamlList -Content $content -TopKey $TopKey)
    }
    catch {
        Write-Warning ("Specrew: '{0}' could not be parsed ({1}); treating as empty." -f $Path, $_.Exception.Message)
        return @()
    }
}
