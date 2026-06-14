<#
.SYNOPSIS
  `specrew hooks` — the discoverable hook install / repair / status surface (F-174 iteration 011, FR-028
  layer 2, decision f174-i011-hook-deploy-hardening).

.DESCRIPTION
  Subcommands:
    status              Report per hook-capable host: installed / missing / stale / opted-out / failed.
    install [--host h]  Provision hooks. Bare `install` provisions MISSING/STALE hosts and RESPECTS + REPORTS
                        recorded opt-outs (never silently re-enables a deliberate `remove`). `install --host h`
                        (or `--force`) CLEARS that opt-out and re-installs.
    remove [--host h]   Remove Specrew hook entries and RECORD an opt-out (so a later `specrew update` does not
                        re-add them). Without --host, removes for every hook-capable host.

  Flags (Unix-style, parsed from remaining args): --host <claude|codex|copilot|cursor>, --force,
  --project-path <path>, --user-home-override <path> (test seam).

  Dispatcher-only command (registered in scripts/specrew.ps1) — it does NOT gate on project setup, so `status`
  works even in a broken project (it is the repair surface). Fail-open: it never throws; install/remove
  delegate to the per-host deploy primitive (scripts/internal/deploy-refocus-hooks.ps1), which preserves user
  entries, replaces only Specrew-owned entries, and records/respects opt-outs.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'status',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Unix-style flag parse (the CLI dispatcher forwards --flag tokens, which do not bind PowerShell-style) ---
$targetHost = $null; $force = $false; $projectPath = $null; $userHomeOverride = $null
$remaining = @($Rest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
for ($i = 0; $i -lt $remaining.Count; $i++) {
    $arg = $remaining[$i]
    if ($arg -match '^--host=(.+)$') { $targetHost = $Matches[1] }
    elseif ($arg -ieq '--host' -and ($i + 1) -lt $remaining.Count) { $targetHost = $remaining[++$i] }
    elseif ($arg -match '^--project-path=(.+)$') { $projectPath = $Matches[1] }
    elseif ($arg -ieq '--project-path' -and ($i + 1) -lt $remaining.Count) { $projectPath = $remaining[++$i] }
    elseif ($arg -match '^--user-home-override=(.+)$') { $userHomeOverride = $Matches[1] }
    elseif ($arg -ieq '--user-home-override' -and ($i + 1) -lt $remaining.Count) { $userHomeOverride = $remaining[++$i] }
    elseif ($arg -ieq '--force') { $force = $true }
}
if ([string]::IsNullOrWhiteSpace($projectPath)) { $projectPath = (Get-Location).Path }

. (Join-Path $PSScriptRoot 'internal/specrew-hook-health.ps1')
$deployScript = Join-Path $PSScriptRoot 'internal/deploy-refocus-hooks.ps1'

function Write-HooksError {
    param([string]$Message)
    Write-Host ("ERROR: {0}" -f $Message) -ForegroundColor Red
    Write-Host "Usage: specrew hooks <status|install|remove> [--host claude|codex|copilot|cursor] [--force]" -ForegroundColor Yellow
    exit 1
}

function Get-TargetHosts {
    # The hosts this invocation acts on: a single --host (validated), else all hook-capable hosts.
    if (-not [string]::IsNullOrWhiteSpace($targetHost)) {
        $valid = @(Get-SpecrewHookHealthHostList)
        $h = $targetHost.ToLowerInvariant()
        if ($valid -notcontains $h) {
            Write-HooksError ("Unknown or hookless host '{0}'. Hook-capable hosts: {1}" -f $targetHost, ($valid -join ', '))
        }
        return @($h)
    }
    return @(Get-SpecrewHookHealthHostList)
}

function Invoke-DeployForHost {
    param([string]$HostKind, [switch]$Remove, [switch]$ForceDeploy)
    $deployArgs = @('-ProjectPath', $projectPath, '-HostKind', $HostKind)
    if ($Remove) { $deployArgs += '-Remove' }
    if ($ForceDeploy) { $deployArgs += '-Force' }
    if (-not [string]::IsNullOrWhiteSpace($userHomeOverride)) { $deployArgs += @('-UserHomeOverride', $userHomeOverride) }
    return @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript @deployArgs 2>&1 | ForEach-Object { [string]$_ })
}

function Show-Status {
    $rows = @(Get-SpecrewHooksStatus -ProjectPath $projectPath -UserHomeOverride $userHomeOverride)
    if (-not [string]::IsNullOrWhiteSpace($targetHost)) {
        $h = $targetHost.ToLowerInvariant()
        $rows = @($rows | Where-Object { $_.Host -eq $h })
    }
    Write-Host ''
    Write-Host 'Specrew hook status' -ForegroundColor Cyan
    Write-Host '-------------------' -ForegroundColor Cyan
    foreach ($row in $rows) {
        $color = switch ($row.State) {
            'installed' { 'Green' }
            'stale' { 'Yellow' }
            'missing' { 'Yellow' }
            'opted-out' { 'DarkGray' }
            'failed' { 'Red' }
            default { 'White' }
        }
        Write-Host ("  {0,-9} {1,-10} {2}" -f $row.Host, $row.State, $row.Detail) -ForegroundColor $color
    }
    Write-Host ''
    $needRepair = @($rows | Where-Object { $_.State -in @('missing', 'stale') })
    if ($needRepair.Count -gt 0) {
        Write-Host ("Repair: run 'specrew hooks install' (or 'specrew update') to provision {0} host(s)." -f $needRepair.Count) -ForegroundColor Yellow
    }
    else {
        Write-Host 'All hook-capable hosts are installed or intentionally opted-out.' -ForegroundColor Green
    }
}

function Invoke-Install {
    # --host (or --force): explicit re-install that CLEARS that opt-out (the user is opting back in).
    # bare install: provision missing/stale, but RESPECT + REPORT existing opt-outs (deploy without -Force
    # skips an opted-out host and prints "opt-out recorded"); never silently undoes a deliberate remove.
    $explicit = (-not [string]::IsNullOrWhiteSpace($targetHost)) -or $force
    foreach ($h in (Get-TargetHosts)) {
        $out = Invoke-DeployForHost -HostKind $h -ForceDeploy:$explicit
        $joined = ($out -join ' ')
        if ($joined -match 'opt-out recorded') {
            Write-Host ("  {0,-9} skipped — opt-out recorded (re-enable: specrew hooks install --host {0})" -f $h) -ForegroundColor DarkGray
        }
        else {
            Write-Host ("  {0,-9} installed" -f $h) -ForegroundColor Green
        }
    }
    Write-Host ''
    Write-Host "Done. Run 'specrew hooks status' to verify." -ForegroundColor Cyan
}

function Invoke-Remove {
    foreach ($h in (Get-TargetHosts)) {
        $null = Invoke-DeployForHost -HostKind $h -Remove
        Write-Host ("  {0,-9} removed — opt-out recorded" -f $h) -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host "Done. Re-enable with 'specrew hooks install --host <host>'." -ForegroundColor Cyan
}

switch ($Command.ToLowerInvariant()) {
    'status' { Show-Status }
    'install' { Invoke-Install }
    'remove' { Invoke-Remove }
    default { Write-HooksError ("Unknown subcommand '{0}'." -f $Command) }
}
exit 0
