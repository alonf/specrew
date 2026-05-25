# Per-host flag translation — registry-driven dispatcher (Phase C refactor)
#
# Original implementation moved to hosts/<kind>/handlers.ps1 (Phase B).
# This file is now a thin shim that delegates to the per-host packages via
# hosts/_registry.ps1. Existing call sites do not need to change — the
# Get-HostFlagTranslation function signature is preserved.
#
# To add a new flag mapping, edit each hosts/<kind>/handlers.ps1
# ConvertTo-<Kind>Flag switch arm. To add a new host, create
# hosts/<kind>/ — no edits to this file.
#
# Translation table (per host coordinator-rules and verified flag matrices):
#
#  | Specrew-side flag | Copilot      | Claude                          | Codex                                              | Antigravity              |
#  |-------------------|--------------|---------------------------------|----------------------------------------------------|--------------------------|
#  | --remote          | --remote     | --remote-control                | warn-and-continue, drop                            | warn-and-continue, drop  |
#  | --allow-all       | --allow-all  | --dangerously-skip-permissions  | --dangerously-bypass-approvals-and-sandbox         | warn (unverified)        |
#  | --autopilot       | --autopilot  | drop with notice                | folds into --dangerously-bypass-approvals-and-sandbox | warn (no equivalent)  |

Set-StrictMode -Version Latest

# Dot-source the registry once (idempotent — handler files are dot-sourced inside the registry eagerly).
$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not $script:RegistryPath -or -not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    # Module-mode lookup: when running from installed Specrew module, hosts/ is a sibling of scripts/
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

function Get-HostFlagTranslation {
    <#
    .SYNOPSIS
    Translates a Specrew-side flag to host-specific flag(s).
    Delegates to per-host packages under hosts/<kind>/handlers.ps1.
    .OUTPUTS
    pscustomobject @{ Args[]; Notice; SuppressWarning }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex', 'antigravity')]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [ValidateSet('--remote', '--allow-all', '--autopilot')]
        [string]$SpecrewFlag
    )

    return Invoke-HostHandler -Kind $HostKind -ContractFunction ConvertFlag -Arguments @{
        SpecrewFlag = $SpecrewFlag
    }
}
