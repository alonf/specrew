# Per-host Crew-runtime install inventory — registry-driven iterator (Phase C refactor)
#
# Original per-host Test-<Host>RuntimeInstalled implementations moved to
# hosts/<kind>/handlers.ps1 (Phase B). The original per-host wrapper functions
# in this file were removed in Phase C because they collided with the handler
# function names in the same scope (causing infinite recursion). Callers that
# need per-host detection use Invoke-HostHandler -ContractFunction TestRuntimeInstalled.
#
# Only the aggregate iterator Get-SpecrewHostRuntimeInventory remains here as
# a host-neutral public API.
#
# To add detection for a new host, implement Test-<Kind>RuntimeInstalled in
# the host's handlers.ps1 — this iterator picks it up automatically via the registry.

Set-StrictMode -Version Latest

$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    # Module-mode lookup: when running from installed Specrew module, hosts/ is a sibling of scripts/
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

function Get-SpecrewHostRuntimeInventory {
    <#
    .SYNOPSIS
    Aggregate per-host Crew-runtime install state for this project — host-neutral iterator.
    Iterates the registry; for each registered host, dispatches its TestRuntimeInstalled.
    Returns an ordered hashtable keyed by host kind with @{ installed = $bool; path = $string-or-null }.
    No host names hardcoded — adding a new host (hosts/<kind>/) makes it appear here automatically.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)

    $result = [ordered]@{}
    foreach ($kind in Get-RegisteredHostKinds) {
        $installed = [bool](Invoke-HostHandler -Kind $kind -ContractFunction TestRuntimeInstalled -Arguments @{ ProjectPath = $ProjectPath })

        # Path for the "installed" case is per-host convention. Derive from manifest where
        # available; fall back to known per-host conventions otherwise. (Phase D consolidates
        # this into a manifest CrewRuntimePath field; for now we keep behavior parity.)
        $path = $null
        if ($installed) {
            $manifest = Get-HostManifest -Kind $kind
            $candidatePaths = @()
            if ($manifest.ContainsKey('AgentDir') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.AgentDir)) {
                $candidatePaths += (Join-Path $ProjectPath (([string]$manifest.AgentDir) -replace '/', [System.IO.Path]::DirectorySeparatorChar).TrimEnd([System.IO.Path]::DirectorySeparatorChar))
            }
            # Copilot's crew runtime is .squad/, not an AgentDir — special case for backwards compat
            if ($kind -eq 'copilot') {
                $candidatePaths = @(Join-Path $ProjectPath '.squad')
            }
            $path = $candidatePaths | Where-Object { $_ } | Select-Object -First 1
        }

        $result[$kind] = @{ installed = $installed; path = $path }
    }
    return $result
}
