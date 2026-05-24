# Host-history persistence (F-043 / Proposal 104)
#
# Helpers for reading/writing .specrew/host-history.json (registry-driven).
# Per spec FR-001 through FR-004 + FR-012.
#
# Spec note: FR-001 originally mandated host-history.yml. Implementation uses
# .json (built-in ConvertFrom-Json / ConvertTo-Json) to avoid the powershell-yaml
# external dependency. JSON also matches the existing pattern (.specrew/start-context.json,
# .specrew/feature-status.json). Schema fields are spec-conformant; only the
# serialization format differs.
#
# Architecture: host enum NOT hardcoded — initial host entries come from
# hosts/_registry.ps1 Get-RegisteredHostKinds so adding hosts/<new-kind>/
# automatically extends the history schema.

Set-StrictMode -Version Latest

$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

function Get-SpecrewHostHistoryPath {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return (Join-Path $ProjectPath '.specrew\host-history.json')
}

function Get-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Read .specrew/host-history.json. Returns $null if missing or corrupted.
    Tolerates corruption per Proposal 059 read-tolerance pattern.
    .OUTPUTS
    pscustomobject or $null
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)

    $path = Get-SpecrewHostHistoryPath -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Warning "host-history.json is empty; treating as missing"
            return $null
        }
        $content = $raw | ConvertFrom-Json
        if (-not (Test-SpecrewHostHistorySchema -Content $content)) {
            Write-Warning "host-history.json schema invalid; regenerating from probe"
            return $null
        }
        return $content
    }
    catch {
        Write-Warning "host-history.json corrupted: $($_.Exception.Message). Regenerating from probe."
        return $null
    }
}

function Test-SpecrewHostHistorySchema {
    <#
    .SYNOPSIS
    Validate a parsed host-history.json against schema v1.
    .OUTPUTS
    bool
    #>
    param([Parameter(Mandatory = $true)][object]$Content)

    if ($null -eq $Content) { return $false }

    # Accept either flat root or { host_history: {...} } nesting (spec syntax)
    $root = if ($Content.PSObject.Properties.Name -contains 'host_history') { $Content.host_history } else { $Content }

    if ($null -eq $root) { return $false }

    foreach ($required in 'schema_version', 'hosts') {
        if ($null -eq $root.PSObject.Properties[$required]) {
            Write-Warning "host_history missing required field: $required"
            return $false
        }
    }

    if ($root.schema_version -ne 1) {
        Write-Warning "host_history schema_version is $($root.schema_version); expected 1"
        return $false
    }

    return $true
}

function New-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Construct a fresh host-history hashtable.
    Host entries are initialized from the registry — adding hosts/<new-kind>/
    extends the schema automatically with no edits to this function.
    .OUTPUTS
    hashtable
    #>
    param()

    $hosts = [ordered]@{}
    foreach ($kind in Get-RegisteredHostKinds) {
        $hosts[$kind] = [ordered]@{
            first_used_at          = $null
            last_used_at           = $null
            crew_runtime_installed = $false
            crew_runtime_path      = $null
        }
    }

    return [ordered]@{
        host_history = [ordered]@{
            schema_version     = 1
            last_selected_host = $null
            hosts              = $hosts
        }
    }
}

function Update-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Update host-history after a host selection. Per FR-004.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$SelectedHost,
        [bool]$CrewRuntimeInstalled = $false,
        [string]$CrewRuntimePath
    )

    $selectedHostLower = $SelectedHost.ToLowerInvariant()
    $history = Get-SpecrewHostHistory -ProjectPath $ProjectPath
    if ($null -eq $history) {
        $history = New-SpecrewHostHistory
    }
    else {
        # Convert ConvertFrom-Json output (pscustomobject) to an editable hashtable form
        $history = ConvertTo-EditableHashtable -InputObject $history
    }

    $now = [DateTime]::UtcNow.ToString('o')
    $hostsBlock = $history['host_history']['hosts']

    if (-not $hostsBlock.Contains($selectedHostLower)) {
        $hostsBlock[$selectedHostLower] = [ordered]@{
            first_used_at          = $null
            last_used_at           = $null
            crew_runtime_installed = $false
            crew_runtime_path      = $null
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$hostsBlock[$selectedHostLower]['first_used_at'])) {
        $hostsBlock[$selectedHostLower]['first_used_at'] = $now
    }
    $hostsBlock[$selectedHostLower]['last_used_at'] = $now
    $hostsBlock[$selectedHostLower]['crew_runtime_installed'] = $CrewRuntimeInstalled
    $hostsBlock[$selectedHostLower]['crew_runtime_path'] = $CrewRuntimePath

    $history['host_history']['last_selected_host'] = $selectedHostLower

    Write-SpecrewHostHistory -ProjectPath $ProjectPath -History $history
    return $history
}

function ConvertTo-EditableHashtable {
    # Recursively convert PSCustomObject (from ConvertFrom-Json) to ordered hashtable
    param([Parameter(ValueFromPipeline = $true)]$InputObject)

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) { return $InputObject }
    if ($InputObject -is [PSCustomObject]) {
        $result = [ordered]@{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $result[$prop.Name] = ConvertTo-EditableHashtable -InputObject $prop.Value
        }
        return $result
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        return @(foreach ($item in $InputObject) { ConvertTo-EditableHashtable -InputObject $item })
    }
    return $InputObject
}

function Write-SpecrewHostHistory {
    <#
    .SYNOPSIS
    Serialize and write the host-history.json (UTF-8, no BOM, atomic via temp+rename).
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

    $json = ConvertTo-Json -InputObject $History -Depth 10
    $tempPath = "$path.tmp"
    try {
        [System.IO.File]::WriteAllText($tempPath, $json, [System.Text.UTF8Encoding]::new($false))
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force
        }
        Move-Item -LiteralPath $tempPath -Destination $path -Force
    }
    catch {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}

function Resolve-SpecrewHostFromHistory {
    <#
    .SYNOPSIS
    Determine the host to use based on FR-002 priority order:
      1. --host flag (if provided)
      2. host-history.json last_selected_host (if present)
      3. (null — caller should fall through to first-run probe or exit)

    .OUTPUTS
    pscustomobject @{ Host = <string or $null>; Source = 'flag' | 'last-selected' | 'unresolved' }
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
        $root = if ($history.PSObject.Properties.Name -contains 'host_history') { $history.host_history } else { $history }
        $last = $root.last_selected_host
        if (-not [string]::IsNullOrWhiteSpace([string]$last)) {
            return [pscustomobject]@{ Host = [string]$last; Source = 'last-selected' }
        }
    }

    return [pscustomobject]@{ Host = $null; Source = 'unresolved' }
}

function Test-SpecrewHostBinaryAvailable {
    <#
    .SYNOPSIS
    Probes the host's primary Binary + every entry in BinaryAliases. Returns the
    actual command-name that resolved (for diagnostics), or $null if none on PATH.
    .OUTPUTS
    string (resolved binary name) or $null
    #>
    param([Parameter(Mandatory = $true)][string]$Kind)

    $manifest = Get-HostManifest -Kind $Kind
    $candidates = @([string]$manifest.Binary)
    if ($manifest.ContainsKey('BinaryAliases') -and $null -ne $manifest.BinaryAliases) {
        foreach ($alias in @($manifest.BinaryAliases)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$alias)) {
                $candidates += [string]$alias
            }
        }
    }
    foreach ($binary in $candidates) {
        if ($null -ne (Get-Command $binary -ErrorAction SilentlyContinue)) {
            return $binary
        }
    }
    return $null
}

function Invoke-SpecrewFirstRunHostProbe {
    <#
    .SYNOPSIS
    Per FR-003: probe PATH for supported hosts (Binary + BinaryAliases), present
    a numbered menu of installed hosts plus a "not installed" group, auto-select
    if exactly 1 is installed, exit with guidance if 0.

    .DESCRIPTION
    Returns a pscustomobject @{ Host = <string-or-null>; Source = 'auto-single-available' | 'first-run-prompt' | 'no-hosts-available'; Available[] }.
    When Source = 'no-hosts-available', caller should print install guidance + exit non-zero.
    When stdin is non-TTY and multiple hosts available, returns @{ Host = $null; Source = 'non-interactive-no-default' } per FR-013.

    Interactive menu (when multiple installed hosts):
      1. copilot   — GitHub Copilot CLI
      2. claude    — Claude Code CLI
      3. codex     — OpenAI Codex CLI
      Other supported (not installed on this PATH):
       - antigravity — Google Antigravity CLI (install: https://antigravity.google/)
      Select 1-3 (number) or kind name [default 1]:

    .PARAMETER NonInteractive
    Force non-interactive behavior (for tests). Auto-detected via [Console]::IsInputRedirected when not specified.
    #>
    param(
        [bool]$NonInteractive = [Console]::IsInputRedirected
    )

    # Get supported (non-deferred) hosts from registry; probe each for Binary + BinaryAliases
    $supportedKinds = @(Get-SpecrewHostsByStatus -Status supported)
    $availableKinds = @()
    $unavailableKinds = @()
    foreach ($kind in $supportedKinds) {
        if ($null -ne (Test-SpecrewHostBinaryAvailable -Kind $kind)) {
            $availableKinds += $kind
        }
        else {
            $unavailableKinds += $kind
        }
    }

    if ($availableKinds.Count -eq 0) {
        return [pscustomobject]@{
            Host      = $null
            Source    = 'no-hosts-available'
            Available = @()
        }
    }

    if ($availableKinds.Count -eq 1) {
        return [pscustomobject]@{
            Host      = $availableKinds[0]
            Source    = 'auto-single-available'
            Available = $availableKinds
        }
    }

    # Multiple available — interactive menu or non-TTY exit per FR-013
    if ($NonInteractive) {
        return [pscustomobject]@{
            Host      = $null
            Source    = 'non-interactive-no-default'
            Available = $availableKinds
        }
    }

    # Interactive numbered menu
    Write-Host ''
    Write-Host 'Select host for this Specrew session:' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Installed on this machine:' -ForegroundColor Green
    $menuIndex = 0
    foreach ($kind in $availableKinds) {
        $menuIndex++
        $manifest = Get-HostManifest -Kind $kind
        Write-Host ('  {0}. {1,-12} — {2}' -f $menuIndex, $kind, [string]$manifest.DisplayName)
    }
    if ($unavailableKinds.Count -gt 0) {
        Write-Host ''
        Write-Host 'Other supported hosts (not installed on this PATH):' -ForegroundColor DarkGray
        foreach ($kind in $unavailableKinds) {
            $manifest = Get-HostManifest -Kind $kind
            $installUrl = if ($manifest.ContainsKey('InstallUrl')) { [string]$manifest.InstallUrl } else { '' }
            $urlHint = if (-not [string]::IsNullOrWhiteSpace($installUrl)) { " (install: $installUrl)" } else { '' }
            Write-Host ('   - {0,-12} — {1}{2}' -f $kind, [string]$manifest.DisplayName, $urlHint) -ForegroundColor DarkGray
        }
    }
    Write-Host ''
    while ($true) {
        $rawInput = (Read-Host ("Select 1-{0} (number) or kind name [default 1]" -f $availableKinds.Count)).Trim()
        if ([string]::IsNullOrWhiteSpace($rawInput)) {
            $rawInput = '1'
        }
        # Numeric selection
        $asInt = 0
        if ([int]::TryParse($rawInput, [ref]$asInt)) {
            if ($asInt -ge 1 -and $asInt -le $availableKinds.Count) {
                return [pscustomobject]@{
                    Host      = $availableKinds[$asInt - 1]
                    Source    = 'first-run-prompt'
                    Available = $availableKinds
                }
            }
            Write-Host ("Invalid number '{0}'. Pick 1-{1}." -f $rawInput, $availableKinds.Count) -ForegroundColor Red
            continue
        }
        # Kind-name selection (backwards-compat)
        $choiceLower = $rawInput.ToLowerInvariant()
        if ($availableKinds -contains $choiceLower) {
            return [pscustomobject]@{
                Host      = $choiceLower
                Source    = 'first-run-prompt'
                Available = $availableKinds
            }
        }
        if ($unavailableKinds -contains $choiceLower) {
            $manifest = Get-HostManifest -Kind $choiceLower
            $installUrl = if ($manifest.ContainsKey('InstallUrl')) { [string]$manifest.InstallUrl } else { 'see host docs' }
            Write-Host ("Host '{0}' is supported but not installed on this PATH. Install: {1}" -f $choiceLower, $installUrl) -ForegroundColor Yellow
            continue
        }
        Write-Host ("Invalid choice '{0}'. Pick 1-{1} or one of: {2}" -f $rawInput, $availableKinds.Count, ($availableKinds -join ', ')) -ForegroundColor Red
    }
}
