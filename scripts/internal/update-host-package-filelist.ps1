[CmdletBinding()]
param(
    [string]$ProjectRoot = '.',
    [switch]$Check,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'atomic-write.ps1')

$script:SpecrewRequiredHostPackageFiles = @(
    'host.psd1',
    'handlers.ps1',
    'coordinator-rules.psd1'
)

function Get-SpecrewOrdinalSortedStrings {
    param([AllowEmptyCollection()][string[]]$Values)

    $sorted = [string[]]@($Values)
    $keys = [string[]]@($sorted | ForEach-Object { $_.ToLowerInvariant() })
    # Match the module's existing lowercase-key manifest ordering without
    # inheriting the current platform's culture or filesystem semantics.
    [Array]::Sort($keys, $sorted, [System.StringComparer]::Ordinal)
    return @($sorted)
}

function Get-SpecrewHostPackageFileListEntries {
    <#
    .SYNOPSIS
    Derives deterministic module FileList membership from hosts/* packages.
    .DESCRIPTION
    Every non-underscore host directory is a package and must contain the three
    contract files. Every file under that package is shipped, so package-private
    adapters and documentation remain folder-only additions.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $hostsRoot = Join-Path $root 'hosts'
    if (-not (Test-Path -LiteralPath $hostsRoot -PathType Container)) {
        throw "Hosts root not found at '$hostsRoot'."
    }

    $entries = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $hostDirectories = @(
        Get-ChildItem -LiteralPath $hostsRoot -Directory -Force |
            Where-Object { -not $_.Name.StartsWith('_') } |
            Sort-Object Name
    )

    foreach ($hostDirectory in $hostDirectories) {
        if (($hostDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Host package '$($hostDirectory.Name)' is a reparse-point directory; package paths must remain inside the hosts root."
        }

        foreach ($requiredFile in $script:SpecrewRequiredHostPackageFiles) {
            $requiredPath = Join-Path $hostDirectory.FullName $requiredFile
            if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
                throw "Host package '$($hostDirectory.Name)' is missing required file '$requiredFile'."
            }
        }

        $manifestPath = Join-Path $hostDirectory.FullName 'host.psd1'
        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
        }
        catch {
            throw "Host package '$($hostDirectory.Name)' has an unreadable manifest: $($_.Exception.Message)"
        }
        if (-not $manifest.ContainsKey('Kind') -or [string]$manifest.Kind -cne $hostDirectory.Name) {
            throw "Host package folder '$($hostDirectory.Name)' must have an exact matching manifest Kind."
        }

        foreach ($directory in @(Get-ChildItem -LiteralPath $hostDirectory.FullName -Recurse -Directory -Force)) {
            if (($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Host package '$($hostDirectory.Name)' contains a reparse-point directory '$($directory.FullName)'; package paths must remain inside their host folder."
            }
        }

        foreach ($file in @(Get-ChildItem -LiteralPath $hostDirectory.FullName -Recurse -File -Force)) {
            if (($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Host package '$($hostDirectory.Name)' contains a reparse-point file '$($file.FullName)'; package paths must remain inside their host folder."
            }

            $relative = [System.IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
            if ($relative.StartsWith('../', [System.StringComparison]::Ordinal) -or
                [System.IO.Path]::IsPathRooted($relative) -or
                -not $relative.StartsWith("hosts/$($hostDirectory.Name)/", [System.StringComparison]::Ordinal)) {
                throw "Host package path '$($file.FullName)' escapes its registered host folder."
            }
            if (-not $seen.Add($relative)) {
                throw "Duplicate host package FileList entry '$relative'."
            }
            $entries.Add($relative) | Out-Null
        }
    }

    return @(Get-SpecrewOrdinalSortedStrings -Values $entries.ToArray())
}

function Update-SpecrewHostPackageFileList {
    <#
    .SYNOPSIS
    Regenerates or verifies host-package rows in Specrew.psd1 FileList.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [switch]$Check
    )

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $manifestPath = Join-Path $root 'Specrew.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Module manifest not found at '$manifestPath'."
    }

    $content = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
    $blockPattern = "(?ms)(?<prefix>^\s*FileList\s*=\s*@\(\r?\n)(?<body>.*?)(?<suffix>^\s*\)\r?\n\s*PrivateData\s*=)"
    $block = [regex]::Match($content, $blockPattern)
    if (-not $block.Success) {
        throw "Could not locate FileList block in '$manifestPath'."
    }

    $existingEntries = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($block.Groups['body'].Value -split '\r?\n')) {
        if ($line -match "^\s*'(?<path>[^']+)'\s*,?\s*$") {
            $existingEntries.Add($Matches['path'].Replace('\', '/')) | Out-Null
        }
        elseif (-not [string]::IsNullOrWhiteSpace($line)) {
            throw "Unsupported FileList line while generating host packages: $line"
        }
    }

    $nonHostEntries = @($existingEntries | Where-Object { $_ -notmatch '^hosts/[^/]+/' })
    $hostEntries = @(Get-SpecrewHostPackageFileListEntries -ProjectRoot $root)
    $combined = @(Get-SpecrewOrdinalSortedStrings -Values @($nonHostEntries + $hostEntries))

    $duplicates = @(
        $combined |
            Group-Object { $_.ToLowerInvariant() } |
            Where-Object Count -gt 1 |
            ForEach-Object { $_.Group[0] }
    )
    if ($duplicates.Count -gt 0) {
        throw "Duplicate FileList entries after host generation: $($duplicates -join ', ')."
    }

    $renderedLines = [System.Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $combined.Count; $index++) {
        $comma = if ($index -lt ($combined.Count - 1)) { ',' } else { '' }
        $renderedLines.Add(("        '{0}'{1}" -f $combined[$index], $comma)) | Out-Null
    }
    $newBody = ($renderedLines -join [Environment]::NewLine) + [Environment]::NewLine
    $updated = $content.Substring(0, $block.Groups['body'].Index) + $newBody + $content.Substring($block.Groups['suffix'].Index)
    $changed = $updated -cne $content

    if ($Check -and $changed) {
        throw "Generated host-package FileList drift detected in '$manifestPath'. Run update-host-package-filelist.ps1 and commit the result."
    }
    if ($changed) {
        Write-SpecrewFileAtomic -Path $manifestPath -Content $updated
    }

    return [pscustomobject]@{
        Changed         = $changed
        ManifestPath    = $manifestPath
        HostEntryCount  = $hostEntries.Count
        TotalEntryCount = $combined.Count
        HostEntries     = $hostEntries
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Update-SpecrewHostPackageFileList -ProjectRoot $ProjectRoot -Check:$Check
    if ($PassThru) {
        $result
    }
    else {
        $result | ConvertTo-Json -Depth 5
    }
}
