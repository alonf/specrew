<#
.SYNOPSIS
  `specrew hooks doctor` — the host-integration doctor: host-support tiers + hook-health receipt evidence +
  the Codex untrusted-headless governance preflight, in ONE report (F-198 iteration 005, T038/T039;
  FR-050 / FR-053 / FR-051).

.DESCRIPTION
  The three Beta2 host-integration truths a maintainer needs at a glance are produced by three sibling leaf
  modules and stitched by the aggregator scripts/internal/continuous-co-review/host-support-doctor.ps1
  (Format-SpecrewHostSupportDoctorReport). This is the AUTHORIZED production seam that surfaces them: the
  natural home (`specrew hooks status` in scripts/specrew-hooks.ps1) is F-184-protected, so the doctor rides
  its own routed, non-protected script here (dispatched from the non-protected scripts/specrew.ps1 `hooks` arm).

  Read-only and fail-open: it NEVER writes a receipt, a config, or ~/.codex. Missing / stale / drifted evidence
  renders HONESTLY (unverified/degraded), never health-washed - it only FORMATS what the resolvers return.

  Dispatcher-only command - it does NOT gate on project setup (it is a diagnostic surface, useful even in a
  broken project). Flags (Unix-style, parsed from the forwarded args):
    --project-path <path>   Project whose hook-health receipts to resolve (default: cwd).
    --host <h>              Narrow the hook-health rows to this host (repeatable). Default: the CLI-first hosts.
    --help | -h             Usage.
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Unix-style flag parse (the CLI dispatcher forwards --flag tokens, which do not bind PowerShell-style) ---
$projectPath = $null
$hosts = New-Object System.Collections.Generic.List[string]
$showHelp = $false
$remaining = @($Rest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
for ($i = 0; $i -lt $remaining.Count; $i++) {
    $arg = $remaining[$i]
    if ($arg -match '^--project-path=(.+)$') { $projectPath = $Matches[1] }
    elseif ($arg -ieq '--project-path' -and ($i + 1) -lt $remaining.Count) { $projectPath = $remaining[++$i] }
    elseif ($arg -match '^--host=(.+)$') { $hosts.Add($Matches[1]) | Out-Null }
    elseif ($arg -ieq '--host' -and ($i + 1) -lt $remaining.Count) { $hosts.Add($remaining[++$i]) | Out-Null }
    elseif ($arg -ieq '--help' -or $arg -ieq '-h') { $showHelp = $true }
}

if ($showHelp) {
    Write-Host 'Usage: specrew hooks doctor [--project-path <path>] [--host <claude|codex|copilot> ...]'
    Write-Host ''
    Write-Host 'Surfaces, in one report:'
    Write-Host '  - host+surface support tiers (FR-050)'
    Write-Host '  - hook-health receipt evidence (FR-053) - a deployed hook config is NOT proof it fired'
    Write-Host '  - the Codex untrusted-headless governance preflight (FR-051)'
    Write-Host ''
    Write-Host 'Read-only and fail-open; missing / stale / drifted evidence renders unverified/degraded, never healthy.'
    exit 0
}

if ([string]::IsNullOrWhiteSpace($projectPath)) { $projectPath = (Get-Location).Path }
# Normalize to an ABSOLUTE path: the health resolvers use .NET file APIs, which resolve a relative path against
# the PROCESS cwd, not the PowerShell location. Fail-open if the path does not exist (keep the user's value).
try { $resolved = (Resolve-Path -LiteralPath $projectPath -ErrorAction Stop).Path; if ($resolved) { $projectPath = $resolved } } catch { $null = $_ }

# Load the aggregator (it self-loads its two sibling leaf modules fail-open, so this single dot-source is enough).
$doctorModule = Join-Path $PSScriptRoot 'internal/continuous-co-review/host-support-doctor.ps1'
if (-not (Test-Path -LiteralPath $doctorModule -PathType Leaf)) {
    Write-Host "ERROR: host-support doctor module not found at $doctorModule" -ForegroundColor Red
    exit 1
}
. $doctorModule
if (-not (Get-Command -Name 'Format-SpecrewHostSupportDoctorReport' -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: Format-SpecrewHostSupportDoctorReport is unavailable (aggregator failed to load).' -ForegroundColor Red
    exit 1
}

$reportArgs = @{ ProjectRoot = $projectPath }
if ($hosts.Count -gt 0) { $reportArgs.Hosts = @($hosts) }
# The aggregator is fail-open per section and returns a STRING; write it as-is (no console coloring so the
# report stays copy-paste faithful and testable).
Write-Host (Format-SpecrewHostSupportDoctorReport @reportArgs)
exit 0
