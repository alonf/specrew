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
# Normalize to an ABSOLUTE path: the health helpers + the deploy subprocess use .NET file APIs, which resolve a
# relative path against the PROCESS cwd, not the PowerShell location (a named Windows/PowerShell trap). Fail-open
# if the path does not exist (keep the user's value so the not-a-project / broken-project path still reports).
try { $resolved = (Resolve-Path -LiteralPath $projectPath -ErrorAction Stop).Path; if ($resolved) { $projectPath = $resolved } } catch { $null = $_ }

$script:HookFailures = 0

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
    # Returns { Output (string[]); ExitCode } — the caller MUST consult ExitCode, not just scan the text, so a
    # genuine deploy FAILURE (non-zero exit: e.g. the deploy refusing a hand-broken/unparsable config) is never
    # mis-reported as success (145-review defect-001).
    param([string]$HostKind, [switch]$Remove, [switch]$ForceDeploy)
    $deployArgs = @('-ProjectPath', $projectPath, '-HostKind', $HostKind)
    if ($Remove) { $deployArgs += '-Remove' }
    if ($ForceDeploy) { $deployArgs += '-Force' }
    if (-not [string]::IsNullOrWhiteSpace($userHomeOverride)) { $deployArgs += @('-UserHomeOverride', $userHomeOverride) }
    $out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript @deployArgs 2>&1 | ForEach-Object { [string]$_ })
    return [pscustomobject]@{ Output = $out; ExitCode = $LASTEXITCODE }
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
    # F-174 iter-11 (FR-028 layer 3): surface the degradation signal — hooks may be installed yet NOT firing
    # this session (no bootstrap-directive runtime trail). -Peek so `status` never records the warn-once marker.
    $degraded = Get-SpecrewHookDegradationWarning -ProjectPath $projectPath -SessionId $null -Peek
    if (-not [string]::IsNullOrWhiteSpace($degraded)) {
        Write-Host ''
        Write-Host ("Diagnostic: {0}" -f $degraded) -ForegroundColor Yellow
    }
}

function Invoke-Install {
    # --host (or --force): explicit re-install that CLEARS that opt-out (the user is opting back in).
    # bare install: provision missing/stale, but RESPECT + REPORT existing opt-outs (deploy without -Force
    # skips an opted-out host and prints "opt-out recorded"); never silently undoes a deliberate remove.
    $explicit = (-not [string]::IsNullOrWhiteSpace($targetHost)) -or $force
    foreach ($h in (Get-TargetHosts)) {
        $r = Invoke-DeployForHost -HostKind $h -ForceDeploy:$explicit
        $joined = ($r.Output -join ' ')
        if ($r.ExitCode -ne 0) {
            # A genuine deploy FAILURE (e.g. a hand-broken config the deploy refuses) — report it, never claim
            # "installed" (145-review defect-001). Fail-open: keep going for the other hosts + exit non-zero.
            $script:HookFailures++
            Write-Host ("  {0,-9} FAILED — {1}" -f $h, ($joined.Trim())) -ForegroundColor Red
        }
        elseif ($joined -match 'opt-out recorded') {
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
        $r = Invoke-DeployForHost -HostKind $h -Remove
        if ($r.ExitCode -ne 0) {
            $script:HookFailures++
            Write-Host ("  {0,-9} FAILED — {1}" -f $h, (($r.Output -join ' ').Trim())) -ForegroundColor Red
        }
        else {
            Write-Host ("  {0,-9} removed — opt-out recorded" -f $h) -ForegroundColor DarkGray
        }
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
# Exit non-zero if any host genuinely FAILED to deploy (an opt-out skip is NOT a failure), so a script/user can
# detect a broken repair. status never sets HookFailures, so it stays exit 0.
exit ([int]($script:HookFailures -gt 0))
