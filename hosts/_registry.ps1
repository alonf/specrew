# Host Package Registry
#
# THIS IS THE ONLY FILE HOST-NEUTRAL CORE CODE CALLS.
#
# Discovers per-host packages under hosts/<kind>/host.psd1, loads their manifests,
# and dispatches to per-host handler functions via the contract defined in hosts/_contract.md.
#
# Phase A (current): manifest discovery + validation only. Handler dispatch arrives in Phase B.
# Core code continues to call legacy host-coupled scripts; this registry runs in parallel
# for parity verification (see Test-RegistryParityWithLegacy).

Set-StrictMode -Version Latest

$script:SpecrewHostsRoot = $PSScriptRoot   # hosts/ directory
$script:HostManifestCache = $null          # ordered dictionary, Kind => manifest hashtable

function Get-SpecrewHostsRoot {
    return $script:SpecrewHostsRoot
}

function Reset-HostManifestCache {
    $script:HostManifestCache = $null
}

function Get-RegisteredHostKinds {
    <#
    .SYNOPSIS
    Returns the canonical list of host kinds discovered under hosts/.
    .DESCRIPTION
    Enumerates hosts/*/host.psd1 files. The Kind field in each manifest must match
    the folder name (lowercase). Returns a sorted string[] for deterministic order.
    Caches results within the session.
    .OUTPUTS
    string[]
    #>

    if ($null -ne $script:HostManifestCache) {
        return @($script:HostManifestCache.Keys)
    }

    $cache = [ordered]@{}
    $hostDirs = Get-ChildItem -Path $script:SpecrewHostsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Name.StartsWith('_') } |
        Sort-Object Name

    foreach ($dir in $hostDirs) {
        $manifestPath = Join-Path $dir.FullName 'host.psd1'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            continue
        }

        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
        }
        catch {
            Write-Warning "Failed to load host manifest '$manifestPath': $($_.Exception.Message)"
            continue
        }

        # Folder-name vs manifest-Kind parity check
        if (-not $manifest.ContainsKey('Kind')) {
            Write-Warning "Host manifest '$manifestPath' is missing required field 'Kind'."
            continue
        }
        if ($manifest.Kind -ne $dir.Name) {
            Write-Warning "Host manifest at '$manifestPath' has Kind='$($manifest.Kind)' which does not match folder name '$($dir.Name)'."
            continue
        }

        $cache[$manifest.Kind] = $manifest
    }

    $script:HostManifestCache = $cache
    return @($cache.Keys)
}

function Get-HostManifest {
    <#
    .SYNOPSIS
    Returns the manifest hashtable for a given host kind.
    .OUTPUTS
    hashtable
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Kind
    )

    $kindLower = $Kind.ToLowerInvariant()
    if ($null -eq $script:HostManifestCache) {
        $null = Get-RegisteredHostKinds
    }

    if (-not $script:HostManifestCache.Contains($kindLower)) {
        throw "Unknown host kind '$Kind'. Registered: $((Get-RegisteredHostKinds) -join ', ')."
    }
    return $script:HostManifestCache[$kindLower]
}

function Test-HostManifestValid {
    <#
    .SYNOPSIS
    Validates a manifest hashtable against the contract.
    .OUTPUTS
    pscustomobject with IsValid (bool) + Errors (string[])
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $requiredFields = @('Kind', 'DisplayName', 'Status', 'SchemaVersion', 'Binary', 'InstallUrl', 'SkillRoot', 'HasUserSlashCommandSurface')

    foreach ($field in $requiredFields) {
        if (-not $Manifest.ContainsKey($field) -or $null -eq $Manifest[$field]) {
            $errors.Add("Missing required field: $field") | Out-Null
            continue
        }
        if ($field -in @('Kind', 'DisplayName', 'Status', 'Binary', 'InstallUrl', 'SkillRoot') -and [string]::IsNullOrWhiteSpace([string]$Manifest[$field])) {
            $errors.Add("Required field '$field' is empty") | Out-Null
        }
    }

    if ($Manifest.ContainsKey('Status')) {
        $allowedStatuses = @('supported', 'deferred', 'experimental')
        if ($Manifest.Status -notin $allowedStatuses) {
            $errors.Add("Status '$($Manifest.Status)' is not one of: $($allowedStatuses -join ', ')") | Out-Null
        }
        if ($Manifest.Status -eq 'deferred') {
            foreach ($deferredField in @('DeferredReason', 'DeferredGuidance')) {
                if (-not $Manifest.ContainsKey($deferredField) -or [string]::IsNullOrWhiteSpace([string]$Manifest[$deferredField])) {
                    $errors.Add("Status='deferred' requires '$deferredField' to be set") | Out-Null
                }
            }
        }
    }

    if ($Manifest.ContainsKey('Kind') -and $Manifest.Kind -is [string] -and $Manifest.Kind -cne $Manifest.Kind.ToLowerInvariant()) {
        $errors.Add("Field 'Kind' must be lowercase (got '$($Manifest.Kind)')") | Out-Null
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors  = $errors.ToArray()
    }
}

function Get-SpecrewHostsByStatus {
    <#
    .SYNOPSIS
    Returns host kinds filtered by Status field.
    .EXAMPLE
    Get-SpecrewHostsByStatus -Status supported
    Get-SpecrewHostsByStatus -Status deferred
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('supported', 'deferred', 'experimental')]
        [string]$Status
    )

    if ($null -eq $script:HostManifestCache) {
        $null = Get-RegisteredHostKinds
    }

    return @(
        foreach ($kind in $script:HostManifestCache.Keys) {
            if ($script:HostManifestCache[$kind].Status -eq $Status) {
                $kind
            }
        }
    )
}

# Phase B: handler dispatch (stubs reserved for next phase)
function Resolve-HostHandler {
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$ContractFunction
    )
    throw "Resolve-HostHandler is a Phase B stub. Use legacy scripts for now."
}

function Invoke-HostHandler {
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$ContractFunction,
        [hashtable]$Args = @{}
    )
    throw "Invoke-HostHandler is a Phase B stub. Use legacy scripts for now."
}
