<#
.SYNOPSIS
    Sort the Specrew.psd1 FileList array alphabetically without changing membership.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'internal\atomic-write.ps1')

function Sort-SpecrewManifestFileList {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [switch]$PassThru
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Manifest not found at '$ManifestPath'."
    }

    $content = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
    $pattern = "(?ms)(?<prefix>^\s*FileList\s*=\s*@\(\r?\n)(?<body>.*?)(?<suffix>^\s*\)\r?\n\s*PrivateData\s*=)"
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) {
        throw "Could not locate FileList block in '$ManifestPath'."
    }

    $entries = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($match.Groups['body'].Value -split '\r?\n')) {
        if ($line -match "^\s*'(?<path>[^']+)'\s*,?\s*$") {
            $entries.Add($Matches['path']) | Out-Null
        }
        elseif (-not [string]::IsNullOrWhiteSpace($line)) {
            throw "Unsupported FileList line while sorting '$ManifestPath': $line"
        }
    }

    $sorted = @($entries | Sort-Object { $_.ToLowerInvariant() })
    $lines = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $sorted.Count; $i++) {
        $suffix = if ($i -lt ($sorted.Count - 1)) { ',' } else { '' }
        $lines.Add(("        '{0}'{1}" -f $sorted[$i], $suffix)) | Out-Null
    }
    $newBody = ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    $updated = $content.Substring(0, $match.Groups['body'].Index) + $newBody + $content.Substring($match.Groups['suffix'].Index)

    $changed = $updated -ne $content
    if ($changed) {
        Write-SpecrewFileAtomic -Path $ManifestPath -Content $updated
    }

    if ($PassThru) {
        return [pscustomobject]@{
            changed     = $changed
            entry_count = $entries.Count
            manifest    = $ManifestPath
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $manifestPath = if ($args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) { [string]$args[0] } else { Join-Path (Get-Location).Path 'Specrew.psd1' }
    Sort-SpecrewManifestFileList -ManifestPath $manifestPath -PassThru | ConvertTo-Json -Depth 5
}
