[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$RefreshExisting,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Add-DeploymentAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $Path) {
        Add-DeploymentAction -Actions $Actions -Action 'preserved-directory' -Path $Path
        return
    }

    Add-DeploymentAction -Actions $Actions -Action 'created-directory' -Path $Path
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-MissingItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    # -Force needed so Get-Item finds hidden source items (e.g., .gitkeep)
    # on Linux PowerShell. The recursive Get-ChildItem below uses -Force to
    # enumerate hidden files; without -Force here, Get-Item then fails to
    # re-open those exact children, breaking `specrew update` on Linux.
    $sourceItem = Get-Item -LiteralPath $SourcePath -Force
    if ($sourceItem.PSIsContainer) {
        Ensure-Directory -Path $TargetPath -Actions $Actions
        $children = @(Get-ChildItem -LiteralPath $SourcePath -Force)
        foreach ($child in $children) {
            Copy-MissingItem -SourcePath $child.FullName -TargetPath (Join-Path $TargetPath $child.Name) -Actions $Actions
        }

        return
    }

    if (Test-Path -LiteralPath $TargetPath) {
        if (-not $RefreshExisting) {
            Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
            return
        }

        $sourceContent = Get-Content -LiteralPath $SourcePath -Raw
        $targetContent = Get-Content -LiteralPath $TargetPath -Raw
        if ($sourceContent -eq $targetContent) {
            Add-DeploymentAction -Actions $Actions -Action 'preserved' -Path $TargetPath
            return
        }

        Add-DeploymentAction -Actions $Actions -Action $(if ($DryRun) { 'would-update' } else { 'updated' }) -Path $TargetPath
        if (-not $DryRun) {
            $parent = Split-Path -Parent $TargetPath
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
        }
        return
    }

    Add-DeploymentAction -Actions $Actions -Action 'created' -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
    }
}

function Get-ExtensionVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $manifestContent = Get-Content -LiteralPath $ManifestPath -Raw
    $versionMatch = [regex]::Match($manifestContent, '(?m)^\s*version:\s*"?(?<version>[^"\r\n]+)')
    if (-not $versionMatch.Success) {
        throw "Could not determine Specrew extension version from '$ManifestPath'."
    }

    return $versionMatch.Groups['version'].Value.Trim()
}

function Ensure-ExtensionRegistration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$ExtensionName,

        [Parameter(Mandatory = $true)]
        [string]$ExtensionVersion,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    $entryLines = @(
        ('  - name: {0}' -f $ExtensionName),
        ('    version: {0}' -f $ExtensionVersion),
        '    enabled: true',
        '    source: local',
        '    path: .specify/extensions/specrew-speckit'
    )

    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        Add-DeploymentAction -Actions $Actions -Action 'created' -Path $ManifestPath
        if (-not $DryRun) {
            $newContent = @(
                'installed:'
                $entryLines
                'settings:'
                '  auto_execute_hooks: true'
                'hooks: {}'
                ''
            ) -join [Environment]::NewLine
            [System.IO.File]::WriteAllText($ManifestPath, $newContent, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.AddRange([string[]](Get-Content -LiteralPath $ManifestPath))

    # Spec Kit 0.9.0+ writes the `installed:` list as bare extension-id strings
    # (e.g. "- specrew-speckit") instead of the legacy object entries. Detect that
    # shape and register/no-op as a string. Inserting a legacy object entry into a
    # bare-string list produces a malformed mixed-type list with specrew-speckit
    # registered twice (validated defect, feature 090 / spike-speckit-090).
    $installedHeaderIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*installed:\s*(\[\s*\])?\s*$') {
            $installedHeaderIndex = $index
            break
        }
    }

    if ($installedHeaderIndex -ge 0) {
        $listIsStringFormat = $false
        $stringEntryPresent = $false
        $lastStringItemIndex = $installedHeaderIndex
        $stringItemIndent = ''
        for ($index = $installedHeaderIndex + 1; $index -lt $lines.Count; $index++) {
            $listLine = $lines[$index]
            if ([string]::IsNullOrWhiteSpace($listLine)) {
                continue
            }
            if ($listLine -match '^\s*-\s*name:\s*') {
                # Legacy object-format list; fall through to the object-entry logic below.
                break
            }
            # Capture the list item's indentation so a new entry aligns with its siblings.
            # 0.9.0 emits column-0 items, but an indented sequence under installed: is valid
            # YAML too — inserting at column 0 there would break the mapping.
            if ($listLine -match '^(?<indent>\s*)-\s*(?<id>[A-Za-z0-9._-]+)\s*$') {
                $listIsStringFormat = $true
                $lastStringItemIndex = $index
                $stringItemIndent = $Matches['indent']
                if ($Matches['id'] -eq $ExtensionName) {
                    $stringEntryPresent = $true
                }
                continue
            }
            # Any other non-blank, non-list line ends the installed: block.
            break
        }

        if ($listIsStringFormat) {
            if ($stringEntryPresent) {
                Add-DeploymentAction -Actions $Actions -Action 'preserved-registration' -Path $ManifestPath
                return
            }

            $lines.Insert($lastStringItemIndex + 1, ('{0}- {1}' -f $stringItemIndent, $ExtensionName))
            Add-DeploymentAction -Actions $Actions -Action 'updated-registration' -Path $ManifestPath
            if (-not $DryRun) {
                $stringContent = ($lines -join [Environment]::NewLine)
                if (-not $stringContent.EndsWith([Environment]::NewLine)) {
                    $stringContent += [Environment]::NewLine
                }

                [System.IO.File]::WriteAllText($ManifestPath, $stringContent, [System.Text.UTF8Encoding]::new($false))
            }

            return
        }
    }

    $existingEntryStart = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*-\s*name:\s*"?specrew-speckit"?\s*$') {
            $existingEntryStart = $index
            break
        }
    }

    if ($existingEntryStart -ge 0) {
        $existingEntryEnd = $existingEntryStart + 1
        while ($existingEntryEnd -lt $lines.Count) {
            $currentLine = $lines[$existingEntryEnd]
            if (-not [string]::IsNullOrWhiteSpace($currentLine) -and $currentLine -notmatch '^\s{4,}') {
                break
            }

            $existingEntryEnd++
        }

        $existingEntryLines = @()
        for ($index = $existingEntryStart; $index -lt $existingEntryEnd; $index++) {
            $existingEntryLines += $lines[$index]
        }

        if ($existingEntryLines.Count -eq $entryLines.Count) {
            $matchesDesiredEntry = $true
            for ($index = 0; $index -lt $entryLines.Count; $index++) {
                if ($existingEntryLines[$index] -ne $entryLines[$index]) {
                    $matchesDesiredEntry = $false
                    break
                }
            }

            if ($matchesDesiredEntry) {
                Add-DeploymentAction -Actions $Actions -Action 'preserved-registration' -Path $ManifestPath
                return
            }
        }

        for ($index = $existingEntryEnd - 1; $index -ge $existingEntryStart; $index--) {
            $lines.RemoveAt($index)
        }

        for ($offset = 0; $offset -lt $entryLines.Count; $offset++) {
            $lines.Insert($existingEntryStart + $offset, $entryLines[$offset])
        }

        Add-DeploymentAction -Actions $Actions -Action 'updated-registration' -Path $ManifestPath
        if (-not $DryRun) {
            $content = ($lines -join [Environment]::NewLine)
            if (-not $content.EndsWith([Environment]::NewLine)) {
                $content += [Environment]::NewLine
            }

            [System.IO.File]::WriteAllText($ManifestPath, $content, [System.Text.UTF8Encoding]::new($false))
        }

        return
    }

    $installedIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*installed:\s*(\[\s*\])?\s*$') {
            $installedIndex = $index
            break
        }
    }

    if ($installedIndex -lt 0) {
        $newLines = [System.Collections.Generic.List[string]]::new()
        $newLines.Add('installed:')
        foreach ($entryLine in $entryLines) {
            $newLines.Add($entryLine)
        }

        if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[0])) {
            $newLines.Add('')
        }

        $newLines.AddRange($lines)
        $lines = $newLines
    }
    else {
        if ($lines[$installedIndex] -match '^\s*installed:\s*\[\s*\]\s*$') {
            $lines[$installedIndex] = 'installed:'
            $insertIndex = $installedIndex + 1
        }
        else {
            $insertIndex = $installedIndex + 1
            while ($insertIndex -lt $lines.Count -and ($lines[$insertIndex] -match '^\s+' -or [string]::IsNullOrWhiteSpace($lines[$insertIndex]))) {
                $insertIndex++
            }
        }

        for ($offset = 0; $offset -lt $entryLines.Count; $offset++) {
            $lines.Insert($insertIndex + $offset, $entryLines[$offset])
        }
    }

    Add-DeploymentAction -Actions $Actions -Action 'updated-registration' -Path $ManifestPath
    if (-not $DryRun) {
        $content = ($lines -join [Environment]::NewLine)
        if (-not $content.EndsWith([Environment]::NewLine)) {
            $content += [Environment]::NewLine
        }

        [System.IO.File]::WriteAllText($ManifestPath, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$extensionRoot = Split-Path -Parent $PSScriptRoot
$targetSpecifyRoot = Join-Path $resolvedProjectPath '.specify'
$targetExtensionRoot = Join-Path $targetSpecifyRoot 'extensions\specrew-speckit'
$targetExtensionsManifest = Join-Path $targetSpecifyRoot 'extensions.yml'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $targetSpecifyRoot) -and -not $DryRun) {
    throw "Spec Kit must be initialized before deploying the Specrew extension. Missing '$targetSpecifyRoot'."
}

$extensionVersion = Get-ExtensionVersion -ManifestPath (Join-Path $extensionRoot 'extension.yml')

if ($DryRun -and -not (Test-Path -LiteralPath $targetSpecifyRoot)) {
    Add-DeploymentAction -Actions $actions -Action 'would-create-directory' -Path $targetSpecifyRoot
}

Ensure-Directory -Path (Join-Path $targetSpecifyRoot 'extensions') -Actions $actions
Ensure-Directory -Path $targetExtensionRoot -Actions $actions

# Items marked Optional may legitimately be absent in the installed package
# specrew-self-ok: Specrew's own update path - the module genuinely installs from this registry
# (PSGallery/NuGet packaging drops empty-with-.gitkeep directories like hooks/);
# absence is logged and skipped. Required items are load-bearing for the Spec Kit
# extension — absence indicates a corrupt installed package and MUST throw loudly,
# not silently skip (otherwise a future packaging regression would be masked).
$itemsToCopy = @(
    @{ Name = 'commands';        Optional = $false }
    @{ Name = 'extension.yml';   Optional = $false }
    @{ Name = 'README.md';       Optional = $false }
    # specrew-self-ok: Specrew's own update path - the module genuinely installs from this registry
    @{ Name = 'hooks';           Optional = $true  }   # PSGallery drops empty .gitkeep dirs
    @{ Name = 'scripts';         Optional = $false }
    @{ Name = 'templates';       Optional = $false }
    @{ Name = 'squad-templates'; Optional = $false }
)
foreach ($item in $itemsToCopy) {
    $sourceItemPath = Join-Path $extensionRoot $item.Name
    if (-not (Test-Path -LiteralPath $sourceItemPath)) {
        if ($item.Optional) {
            Add-DeploymentAction -Actions $actions -Action 'skipped-missing-source' -Path $sourceItemPath
            continue
        }
        throw "Required Specrew extension source item missing from installed package: '$sourceItemPath'. The installed module appears corrupt — try Uninstall-Module Specrew -AllVersions -Force followed by Install-Module Specrew -Force."
    }
    Copy-MissingItem -SourcePath $sourceItemPath -TargetPath (Join-Path $targetExtensionRoot $item.Name) -Actions $actions
}

Ensure-ExtensionRegistration -ManifestPath $targetExtensionsManifest -ExtensionName 'specrew-speckit' -ExtensionVersion $extensionVersion -Actions $actions

if ($PassThru) {
    foreach ($action in $actions) {
        $action
    }
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Spec Kit extension deployment {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $resolvedProjectPath)) -ForegroundColor Green
exit 0