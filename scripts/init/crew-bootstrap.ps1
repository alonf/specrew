# Crew-bootstrap dispatcher (Proposal 108 Slice 9)
#
# Single entry point for deploying the 5-agent Specrew Crew to a specific host's native location.
# Reads canonical charters from .specrew/team/agents/<role>.md and dispatches to each host's
# Install-<Kind>CrewRuntime contract function (in hosts/<kind>/handlers.ps1).
#
# Called by:
#   - scripts/specrew-init.ps1 main flow (greenfield bootstrap for the default host)
#   - scripts/specrew-start.ps1 (sync the selected host's view with canonical on every launch)
#
# Adding a new host = adding hosts/<new-kind>/handlers.ps1 with an Install-<NewKind>CrewRuntime function.
# This dispatcher picks it up automatically via Invoke-HostHandler.

Set-StrictMode -Version Latest

# Locate the host registry via a marker-file walk so this file is relocation-independent.
# The previous 2-level Split-Path was fragile if scripts/init/ moved relative to hosts/.
# Same lesson Slice 5/8 memorialized in _utilities.ps1::Get-SpecrewExecutionLayout.
$_crewBootstrapDistRoot = $PSScriptRoot
for ($_i = 0; $_i -lt 5; $_i++) {
    if (Test-Path -LiteralPath (Join-Path $_crewBootstrapDistRoot 'Specrew.psd1') -PathType Leaf) {
        break
    }
    $_crewBootstrapParent = Split-Path -Parent $_crewBootstrapDistRoot
    if ([string]::IsNullOrWhiteSpace($_crewBootstrapParent) -or $_crewBootstrapParent -eq $_crewBootstrapDistRoot) {
        break
    }
    $_crewBootstrapDistRoot = $_crewBootstrapParent
}
$_registryFromCrewBootstrap = Join-Path $_crewBootstrapDistRoot 'hosts\_registry.ps1'
if (Test-Path -LiteralPath $_registryFromCrewBootstrap -PathType Leaf) {
    . $_registryFromCrewBootstrap
}

function Initialize-SpecrewTeam {
    <#
    .SYNOPSIS
    Seed .specrew/team/agents/ from the shipped baseline charters (idempotent).
    Called on greenfield specrew init so the user has the canonical source-of-truth in place.
    .OUTPUTS
    pscustomobject @{ Actions[]; CanonicalRoot }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    if (-not (Get-Command Initialize-SpecrewTeamCanonical -ErrorAction SilentlyContinue)) {
        throw "Canonical-team helper not loaded (hosts/_team-canonical.ps1 missing or not dot-sourced)."
    }

    return (Initialize-SpecrewTeamCanonical -ProjectPath $ProjectPath -DryRun:$DryRun)
}

function Invoke-CrewBootstrap {
    <#
    .SYNOPSIS
    Deploy the Crew runtime to the specified host's native location by dispatching to
    hosts/<kind>/handlers.ps1::Install-<Kind>CrewRuntime via the host-package registry.
    .DESCRIPTION
    Idempotent + safe to call on every specrew start. Cheap (~50ms for 5-7 file translations).
    Translation source: .specrew/team/agents/<role>.md (canonical). Target: per-host AgentDir.
    .OUTPUTS
    Whatever the per-host Install-<Kind>CrewRuntime function returns (typically
    pscustomobject @{ Actions[]; CrewRuntimePath; Notices[] }).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$HostKind,
        [switch]$DryRun
    )

    if (-not (Get-Command Invoke-HostHandler -ErrorAction SilentlyContinue)) {
        throw "Host registry not loaded. Ensure hosts/_registry.ps1 is dot-sourced before calling Invoke-CrewBootstrap."
    }

    # Auto-seed canonical .specrew/team/agents/ if missing. This makes `specrew start` work
    # on greenfield projects that never ran `specrew init`, AND keeps the "user edits canonical"
    # docs contract honest — the file actually appears after first start, ready for editing.
    if (Get-Command Get-SpecrewTeamAgentsPath -ErrorAction SilentlyContinue) {
        $_canonicalAgents = Get-SpecrewTeamAgentsPath -ProjectPath $ProjectPath
        if (-not (Test-Path -LiteralPath $_canonicalAgents -PathType Container) -and -not $DryRun) {
            if (Get-Command Initialize-SpecrewTeamCanonical -ErrorAction SilentlyContinue) {
                Initialize-SpecrewTeamCanonical -ProjectPath $ProjectPath | Out-Null
            }
        }
    }

    return Invoke-HostHandler -Kind $HostKind -ContractFunction InstallCrewRuntime -Arguments @{
        ProjectPath = $ProjectPath
        DryRun      = $DryRun
    }
}
