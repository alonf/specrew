# Host-history persistence (F-043 / Proposal 104)
#
# Helpers for reading/writing .specrew/host-history.yml. Schema v1 per spec
# data-model.md. Per spec FR-001 through FR-004 + FR-012.
#
# DRAFT — pre-staged 2026-05-23. Pending F-040 + F-041 + F-042 merge +
# F-043 plan-boundary verdict before production wiring.
#
# Functions in this file have no clarify-decision dependency — they're pure
# persistence helpers. The host-selection LOGIC (probe → prompt → exit) lives
# in specrew-start.ps1 and needs plan-boundary approval before wiring.

Set-StrictMode -Version Latest

function Get-SpecrewHostHistoryPath {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return (Join-Path $ProjectPath '.specrew\host-history.yml')
}

function Get-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Read .specrew/host-history.yml. Returns $null if missing.
    Tolerates corruption per Proposal 059 read-tolerance pattern — regenerates
    via re-probe on next selection if corruption detected.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)

    $path = Get-SpecrewHostHistoryPath -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Warning "host-history.yml is empty; regenerating from probe"
            return $null
        }
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $content = ConvertFrom-Yaml -Yaml $raw
        }
        else {
            throw "ConvertFrom-Yaml not available; F-043 wiring requires the codebase YAML parser"
        }
        if (-not (Test-SpecrewHostHistorySchema -Content $content)) {
            Write-Warning "host-history.yml schema invalid; regenerating from probe"
            return $null
        }
        return $content
    }
    catch {
        Write-Warning "host-history.yml corrupted: $($_.Exception.Message). Regenerating from probe."
        return $null
    }
}

function Test-SpecrewHostHistorySchema {
    <#
    .SYNOPSIS
    Validate a parsed host-history.yml against schema v1.
    Returns $true if valid; $false otherwise (with specific warnings).
    #>
    param([Parameter(Mandatory = $true)][object]$Content)

    if ($null -eq $Content) { return $false }

    $root = if ($Content -is [hashtable] -and $Content.ContainsKey('host_history')) { $Content['host_history'] } else { $Content }

    if (-not ($root -is [hashtable])) {
        Write-Warning "host_history root is not a hashtable"
        return $false
    }

    foreach ($required in 'schema_version', 'hosts') {
        if (-not $root.ContainsKey($required)) {
            Write-Warning "host_history missing required field: $required"
            return $false
        }
    }

    if ($root['schema_version'] -ne 1) {
        Write-Warning "host_history schema_version is $($root['schema_version']); expected 1"
        return $false
    }

    return $true
}

function New-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Construct a fresh host-history hashtable with all known host kinds + null timestamps.
    #>
    param()

    return @{
        host_history = @{
            schema_version     = 1
            last_selected_host = $null
            hosts              = @{
                copilot     = @{ first_used_at = $null; last_used_at = $null; crew_runtime_installed = $false; crew_runtime_path = $null }
                claude      = @{ first_used_at = $null; last_used_at = $null; crew_runtime_installed = $false; crew_runtime_path = $null }
                codex       = @{ first_used_at = $null; last_used_at = $null; crew_runtime_installed = $false; crew_runtime_path = $null }
                antigravity = @{ first_used_at = $null; last_used_at = $null; crew_runtime_installed = $false; crew_runtime_path = $null }
            }
        }
    }
}

function Update-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Update host-history after a host selection. Per FR-004:
      - Set last_selected_host
      - Set last_used_at
      - Set first_used_at if not already set
      - Refresh crew_runtime_installed + crew_runtime_path

    .PARAMETER ProjectPath
    Project root.

    .PARAMETER SelectedHost
    The host kind that was just selected (copilot / claude / codex / antigravity).

    .PARAMETER CrewRuntimeInstalled
    Whether the per-host Crew runtime is deployed for this project.

    .PARAMETER CrewRuntimePath
    Path to the Crew runtime root (.squad/, .claude/agents/, .codex/agents/).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$SelectedHost,
        [bool]$CrewRuntimeInstalled = $false,
        [string]$CrewRuntimePath
    )

    $history = Get-SpecrewHostHistory -ProjectPath $ProjectPath
    if ($null -eq $history) {
        $history = New-SpecrewHostHistory
    }

    $now = [DateTime]::UtcNow.ToString('o')
    $hostsBlock = $history['host_history']['hosts']

    if (-not $hostsBlock.ContainsKey($SelectedHost)) {
        $hostsBlock[$SelectedHost] = @{ first_used_at = $null; last_used_at = $null; crew_runtime_installed = $false; crew_runtime_path = $null }
    }

    if ([string]::IsNullOrWhiteSpace($hostsBlock[$SelectedHost]['first_used_at'])) {
        $hostsBlock[$SelectedHost]['first_used_at'] = $now
    }
    $hostsBlock[$SelectedHost]['last_used_at'] = $now
    $hostsBlock[$SelectedHost]['crew_runtime_installed'] = $CrewRuntimeInstalled
    $hostsBlock[$SelectedHost]['crew_runtime_path'] = $CrewRuntimePath

    $history['host_history']['last_selected_host'] = $SelectedHost

    Write-SpecrewHostHistory -ProjectPath $ProjectPath -History $history
    return $history
}

function Write-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Serialize and atomically write the host-history.yml.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][object]$History
    )

    $path = Get-SpecrewHostHistoryPath -ProjectPath $ProjectPath
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
        $yaml = ConvertTo-Yaml -Data $History
        Write-Utf8FileAtomic -Path $path -Content $yaml
    }
    else {
        throw "ConvertTo-Yaml not available; F-043 wiring requires the codebase YAML serializer"
    }
}

function Resolve-SpecrewHostFromHistory {
    <#
    .SYNOPSIS
    Determine the host to use based on FR-002 priority order:
      1. --host flag (if provided)
      2. host-history.yml last_selected_host (if present)
      3. (null — caller should fall through to first-run probe or exit)

    .OUTPUTS
    PSCustomObject with Host (string or null) and Source ('flag' / 'last-selected' / 'unresolved').
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$ExplicitHost
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitHost)) {
        return [pscustomobject]@{ Host = $ExplicitHost.ToLowerInvariant(); Source = 'flag' }
    }

    $history = Get-SpecrewHostHistory -ProjectPath $ProjectPath
    if ($null -ne $history) {
        $last = $history['host_history']['last_selected_host']
        if (-not [string]::IsNullOrWhiteSpace($last)) {
            return [pscustomobject]@{ Host = $last; Source = 'last-selected' }
        }
    }

    return [pscustomobject]@{ Host = $null; Source = 'unresolved' }
}
