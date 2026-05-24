# specrew host — multi-host inspection + selection command (F-043 / Proposal 104)
#
# Subcommands:
#   list   — show available + currently-selected hosts (FR-005)
#   use    — set last_selected_host without launching (FR-006)
#   status — per-host Crew-runtime install state (FR-007)
#
# Registry-driven: enumerates hosts/_registry.ps1 Get-RegisteredHostKinds.
# Adding hosts/<new-kind>/ extends every subcommand's output automatically.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('list', 'use', 'status')]
    [string]$Subcommand,

    [Parameter(Position = 1)]
    [string]$HostKind,

    [string]$ProjectPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $repoRoot 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
    # Module-mode: hosts/ is sibling of scripts/, both under Specrew module root
    $registryPath = Join-Path (Split-Path -Parent $repoRoot) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
    Write-Host "ERROR: Host registry not found. Searched: $registryPath" -ForegroundColor Red
    exit 1
}
. $registryPath
. (Join-Path $PSScriptRoot 'internal\host-history.ps1')
. (Join-Path $PSScriptRoot 'internal\host-runtime-inventory.ps1')

function Invoke-SpecrewHostList {
    param([string]$ProjectPath)

    $registered = @(Get-RegisteredHostKinds)
    $history = Get-SpecrewHostHistory -ProjectPath $ProjectPath
    $selected = if ($null -ne $history) {
        $root = if ($history.PSObject.Properties.Name -contains 'host_history') { $history.host_history } else { $history }
        [string]$root.last_selected_host
    } else {
        ''
    }

    Write-Host ''
    Write-Host 'Hosts' -ForegroundColor Cyan
    Write-Host '-----' -ForegroundColor Cyan

    $rows = foreach ($kind in $registered) {
        $manifest = Get-HostManifest -Kind $kind
        $binary = $manifest.Binary
        $available = ($null -ne (Get-Command $binary -ErrorAction SilentlyContinue))
        $status = $manifest.Status

        $statusMark = switch ($status) {
            'supported'    { '' }
            'deferred'     { ' [deferred]' }
            'experimental' { ' [experimental]' }
            default        { " [$status]" }
        }

        $selectedMark = if ($kind -eq $selected) { '  *selected' } else { '' }
        $availableMark = if ($available) { 'available' } else { 'not on PATH' }

        [pscustomobject]@{
            Kind        = $kind
            DisplayName = $manifest.DisplayName
            Binary      = $binary
            Available   = $availableMark
            Status      = $status
            Selected    = ($kind -eq $selected)
            Line        = "{0,-12} {1,-30} bin={2,-12} {3}{4}{5}" -f $kind, $manifest.DisplayName, $binary, $availableMark, $statusMark, $selectedMark
        }
    }
    foreach ($row in $rows) {
        if ($row.Selected) {
            Write-Host $row.Line -ForegroundColor Green
        } elseif ($row.Status -ne 'supported') {
            Write-Host $row.Line -ForegroundColor DarkGray
        } else {
            Write-Host $row.Line
        }
    }
    Write-Host ''
    if ([string]::IsNullOrWhiteSpace($selected)) {
        Write-Host "No host selected. Use 'specrew host use <kind>' to set one, or pass --host on 'specrew start'." -ForegroundColor Yellow
    }
}

function Invoke-SpecrewHostUse {
    param([string]$ProjectPath, [string]$HostKind)

    if ([string]::IsNullOrWhiteSpace($HostKind)) {
        Write-Host "ERROR: 'specrew host use' requires a <kind> argument." -ForegroundColor Red
        Write-Host "Usage: specrew host use <kind>" -ForegroundColor Yellow
        $registered = @(Get-RegisteredHostKinds | Where-Object { (Get-HostManifest -Kind $_).Status -eq 'supported' })
        Write-Host "Supported: $($registered -join ', ')" -ForegroundColor Yellow
        exit 1
    }

    $kindLower = $HostKind.ToLowerInvariant()

    # Validate kind exists and is supported
    try {
        $manifest = Get-HostManifest -Kind $kindLower
    }
    catch {
        Write-Host "ERROR: Unknown host kind '$HostKind'." -ForegroundColor Red
        $registered = @(Get-RegisteredHostKinds)
        Write-Host "Registered: $($registered -join ', ')" -ForegroundColor Yellow
        exit 1
    }

    if ($manifest.Status -eq 'deferred') {
        $guidance = if ($manifest.PSObject.Properties.Name -contains 'DeferredGuidance') { [string]$manifest.DeferredGuidance } else { 'No guidance provided.' }
        Write-Host "ERROR: Host '$kindLower' is deferred. $guidance" -ForegroundColor Red
        exit 1
    }

    # Probe Crew-runtime install state for the chosen host
    $inventory = Get-SpecrewHostRuntimeInventory -ProjectPath $ProjectPath
    $crewInstalled = [bool]$inventory[$kindLower].installed
    $crewPath = [string]$inventory[$kindLower].path

    $null = Update-SpecrewHostHistory `
        -ProjectPath $ProjectPath `
        -SelectedHost $kindLower `
        -CrewRuntimeInstalled $crewInstalled `
        -CrewRuntimePath $crewPath

    Write-Host "OK: Selected host '$kindLower' (persisted to .specrew/host-history.json)." -ForegroundColor Green
    Write-Host "Run 'specrew start' to launch this host." -ForegroundColor Cyan
}

function Invoke-SpecrewHostStatus {
    param([string]$ProjectPath)

    $inventory = Get-SpecrewHostRuntimeInventory -ProjectPath $ProjectPath
    $history = Get-SpecrewHostHistory -ProjectPath $ProjectPath
    $selected = if ($null -ne $history) {
        $root = if ($history.PSObject.Properties.Name -contains 'host_history') { $history.host_history } else { $history }
        [string]$root.last_selected_host
    } else {
        ''
    }

    Write-Host ''
    Write-Host 'Host runtime status' -ForegroundColor Cyan
    Write-Host '-------------------' -ForegroundColor Cyan
    foreach ($kind in (Get-RegisteredHostKinds)) {
        $manifest = Get-HostManifest -Kind $kind
        $binary = $manifest.Binary
        $available = ($null -ne (Get-Command $binary -ErrorAction SilentlyContinue))
        $entry = $inventory[$kind]
        $crewInstalled = if ($entry) { [bool]$entry.installed } else { $false }
        $crewPath = if ($entry) { [string]$entry.path } else { '' }
        $selectedMark = if ($kind -eq $selected) { ' [SELECTED]' } else { '' }

        $color = if ($kind -eq $selected) { 'Green' } elseif ($manifest.Status -ne 'supported') { 'DarkGray' } else { 'White' }
        $line = "{0,-12} PATH={1,-13} CrewRuntime={2,-13} {3}{4}" -f $kind, $(if ($available) { 'available' } else { 'missing' }), $(if ($crewInstalled) { 'installed' } else { 'not-installed' }), $(if ($crewInstalled) { "path=$crewPath" } else { '' }), $selectedMark
        Write-Host $line -ForegroundColor $color
    }
    Write-Host ''
}

# Dispatch
switch ($Subcommand) {
    'list'   { Invoke-SpecrewHostList   -ProjectPath $ProjectPath }
    'use'    { Invoke-SpecrewHostUse    -ProjectPath $ProjectPath -HostKind $HostKind }
    'status' { Invoke-SpecrewHostStatus -ProjectPath $ProjectPath }
}
