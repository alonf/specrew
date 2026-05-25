# Host Package Registry
#
# THIS IS THE ONLY FILE HOST-NEUTRAL CORE CODE CALLS.
#
# Discovers per-host packages under hosts/<kind>/host.psd1, loads their manifests,
# and dispatches to per-host handler functions via the contract defined in hosts/_contract.md.
# Phases A-D + Slice 9 are shipped: manifest discovery, validation, dispatch, registry-driven
# launch path, and per-host Crew-runtime install (5th contract function).

Set-StrictMode -Version Latest

$script:SpecrewHostsRoot = $PSScriptRoot   # hosts/ directory
$script:HostManifestCache = $null          # ordered dictionary, Kind => manifest hashtable

# Dot-source the canonical team-location helpers (Proposal 108 Slice 9)
$_teamCanonicalPath = Join-Path $script:SpecrewHostsRoot '_team-canonical.ps1'
if (Test-Path -LiteralPath $_teamCanonicalPath -PathType Leaf) {
    . $_teamCanonicalPath
}

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

    # iter-011: load manifests first, then sort by MenuPriority (then Kind for
    # stable ordering when priorities tie or are missing). Hosts without a
    # MenuPriority field sort last (default 999) — keeps new hosts visible but
    # not surprising users with reordering.
    $hostDirs = Get-ChildItem -Path $script:SpecrewHostsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { -not $_.Name.StartsWith('_') }

    $loaded = [System.Collections.Generic.List[object]]::new()
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

        $priority = if ($manifest.ContainsKey('MenuPriority')) { [int]$manifest.MenuPriority } else { 999 }
        $loaded.Add([pscustomobject]@{
            Kind     = $manifest.Kind
            Priority = $priority
            Manifest = $manifest
        })
    }

    $sorted = $loaded | Sort-Object Priority, Kind

    $cache = [ordered]@{}
    foreach ($entry in $sorted) {
        $cache[$entry.Kind] = $entry.Manifest
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
        if ($Manifest.Status -eq 'supported') {
            # Install-<Kind>CrewRuntime resolves the agent root via Get-SpecrewHostAgentRoot,
            # which reads AgentDir. A supported host without AgentDir cannot deploy its Crew runtime.
            if (-not $Manifest.ContainsKey('AgentDir') -or [string]::IsNullOrWhiteSpace([string]$Manifest['AgentDir'])) {
                $errors.Add("Status='supported' requires 'AgentDir' to be set (consumed by Install-<Kind>CrewRuntime)") | Out-Null
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

# Phase B: handler dispatch
# Contract function => actual per-host PowerShell function-name template.
# To add a new contract function, add an entry here AND export it from each hosts/<kind>/handlers.ps1.
$script:HostContractFunctionMap = @{
    'NewLaunchInvocation'    = 'New-{0}LaunchInvocation'
    'ConvertFlag'            = 'ConvertTo-{0}Flag'
    'TestRuntimeInstalled'   = 'Test-{0}RuntimeInstalled'
    'GetSignals'             = 'Get-{0}Signals'
    # Proposal 108 Slice 9: per-host Crew runtime install (5-agent baseline deployment).
    # Each host's Install-<Kind>CrewRuntime writes the agent charters in that host's
    # native format (Copilot: .squad/agents/*/charter.md, Claude: .claude/agents/*.md,
    # Codex: .codex/agents/*.toml, Antigravity: .agents/agents/*.md).
    'InstallCrewRuntime'     = 'Install-{0}CrewRuntime'
}
$script:HostHandlersDotSourced = @{}

function Resolve-HostHandler {
    <#
    .SYNOPSIS
    Returns the per-host function name for a given contract slot.
    Does NOT verify the function exists — that's Invoke-HostHandler's job.
    .EXAMPLE
    Resolve-HostHandler -Kind claude -ContractFunction NewLaunchInvocation
    # Returns 'New-ClaudeLaunchInvocation'
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$ContractFunction
    )

    if (-not $script:HostContractFunctionMap.ContainsKey($ContractFunction)) {
        throw "Unknown contract function '$ContractFunction'. Registered: $($script:HostContractFunctionMap.Keys -join ', ')."
    }

    # Verify Kind exists (will throw if not)
    $null = Get-HostManifest -Kind $Kind

    # Pascal-case the Kind for the function name
    $kindLower = $Kind.ToLowerInvariant()
    $pascalKind = $kindLower.Substring(0, 1).ToUpperInvariant() + $kindLower.Substring(1)
    return [string]::Format($script:HostContractFunctionMap[$ContractFunction], $pascalKind)
}

function Invoke-HostHandler {
    <#
    .SYNOPSIS
    Dispatch a contract function for a given host with the supplied arguments.
    Requires the host's handlers.ps1 to be dot-sourced (done eagerly at the end of _registry.ps1).
    .EXAMPLE
    Invoke-HostHandler -Kind claude -ContractFunction NewLaunchInvocation -Arguments @{
        ProjectPath = 'C:\proj'; Prompt = 'BOOT'; Agent = 'Squad'; AllowAll = $true
    }
    .OUTPUTS
    Whatever the per-host contract function returns
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$ContractFunction,
        [hashtable]$Arguments = @{}
    )

    $functionName = Resolve-HostHandler -Kind $Kind -ContractFunction $ContractFunction

    $cmd = Get-Command $functionName -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        throw "Handler '$functionName' is not defined. Ensure hosts/_registry.ps1 was dot-sourced (which eagerly loads all hosts/<kind>/handlers.ps1)."
    }

    return & $functionName @Arguments
}

# Eagerly dot-source all hosts' handlers.ps1 at the script level so the functions
# they define land in the SAME scope that's dot-sourcing _registry.ps1 (typically
# the caller's script scope). Lazy loading inside a function dot-sources into the
# function's scope only, which doesn't help dispatch.
#
# Performance: loading 4 small files (~100-150 lines each) is cheap. The alternative —
# in-memory modules via New-Module — adds complexity for no measurable benefit at this scale.
foreach ($_hostDir in (Get-ChildItem -Path $script:SpecrewHostsRoot -Directory -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.StartsWith('_') })) {
    $_handlersPath = Join-Path $_hostDir.FullName 'handlers.ps1'
    if (Test-Path -LiteralPath $_handlersPath -PathType Leaf) {
        . $_handlersPath
        $script:HostHandlersDotSourced[$_hostDir.Name.ToLowerInvariant()] = $_handlersPath
    }
}
Remove-Variable -Name _hostDir, _handlersPath -ErrorAction SilentlyContinue
