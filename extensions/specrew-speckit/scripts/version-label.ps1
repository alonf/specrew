# THE ONE VERSION RESOLVER (PRED-BETA4-054, B4F-095).
#
# Measured on the walk project (e9334af1): the SessionStart orientation said "0.40.0-beta4" (manifest plus
# Prerelease), the turn-end orientation said "Specrew unknown is active on this host" (the deployed extension
# marker, written by init's `specify extension add` path with no version at all), `.specrew/config.yml` said
# "0.40.0" (extension.yml's version), and the review-runtime marker looked for Specrew.psd1 two levels above the
# deployed extension root, which is `.specify/`. Four writers, three answers. This file is the one they share:
# dot-sourced by the bootstrap provider, the turn-end renderer, both extension-marker writers, the
# review-runtime marker writer and init's governance scaffold. It carries no other dependency so the per-turn
# scripts stay light.

function Get-SpecrewModuleVersionInfo {
    <#
    .SYNOPSIS
    The module's version identity from its manifest: base version, prerelease label, and the display label.
    .DESCRIPTION
    Resolution, first hit wins: an explicit -ModuleRoot; SPECREW_MODULE_PATH (a dev-loop override); the module
    root this file belongs to (extensions/specrew-speckit/scripts -> three levels up - present when the file
    runs from the module, absent when it runs from a project's deployed copy); the highest installed Specrew
    module. Returns Label = '' with Source = 'none' when no manifest is found - never a literal placeholder.
    #>
    [CmdletBinding()]
    param([AllowNull()][string]$ModuleRoot)

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($ModuleRoot)) { $candidates.Add($ModuleRoot) | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) { $candidates.Add($env:SPECREW_MODULE_PATH) | Out-Null }
    try { $candidates.Add((Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) | Out-Null } catch { $null = $_ }
    try {
        $installed = @(Get-Module -ListAvailable -Name Specrew -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1)
        if ($installed.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$installed[0].ModuleBase)) { $candidates.Add([string]$installed[0].ModuleBase) | Out-Null }
    }
    catch { $null = $_ }

    foreach ($root in $candidates) {
        $manifestPath = Join-Path $root 'Specrew.psd1'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
            $version = [string]$manifest.ModuleVersion
            if ([string]::IsNullOrWhiteSpace($version)) { continue }
            $prerelease = ''
            if ($manifest.ContainsKey('PrivateData') -and $null -ne $manifest.PrivateData -and
                $manifest.PrivateData.ContainsKey('PSData') -and $null -ne $manifest.PrivateData.PSData -and
                $manifest.PrivateData.PSData.ContainsKey('Prerelease') -and $null -ne $manifest.PrivateData.PSData.Prerelease) {
                $prerelease = ([string]$manifest.PrivateData.PSData.Prerelease).Trim()
            }
            $label = if ([string]::IsNullOrWhiteSpace($prerelease)) { $version } else { '{0}-{1}' -f $version, $prerelease }
            return [pscustomobject]@{ Version = $version; Prerelease = $prerelease; Label = $label; Source = 'manifest'; ManifestPath = $manifestPath }
        }
        catch { continue }
    }
    return [pscustomobject]@{ Version = ''; Prerelease = ''; Label = ''; Source = 'none'; ManifestPath = $null }
}

function Get-SpecrewRuntimeVersionLabel {
    <#
    .SYNOPSIS
    The version label a renderer shows for a PROJECT: the deployed extension marker's value when it is a real
    version, else the module's manifest label, else '' (the renderer then says "Specrew" without a number,
    never "Specrew unknown").
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    try {
        $markerPath = Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/.specrew-extension-runtime.json'
        if (Test-Path -LiteralPath $markerPath -PathType Leaf) {
            $runtime = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($runtime.PSObject.Properties['specrew_version']) {
                $value = ([string]$runtime.specrew_version).Trim()
                if ($value -match '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?$') { return $value }
            }
        }
    }
    catch { $null = $_ }
    return (Get-SpecrewModuleVersionInfo).Label
}
