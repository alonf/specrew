<#
.SYNOPSIS
  Launcher <-> hook dedupe: at most one bootstrap surface per session.
.DESCRIPTION
  Adapter (IDesign, volatile). `specrew start` remains a retained launcher (FR-006). When the
  launcher emits a bootstrap it writes a DEDICATED marker (`.specrew/runtime/launcher-bootstrap.json`);
  the SessionStart hook bootstrap provider checks it and stays SILENT if the launcher bootstrapped
  within the dedupe window, so a launcher-then-hook startup yields exactly one bootstrap (FR-007,
  SC-002). Recency-based (no session id - the host assigns it only after launch), no lock semantics.
  NOTE: an earlier version keyed on `last-start-prompt.md`, but boundary syncs ALSO rewrite that file,
  causing false dedupe (caught by the iteration-003 live cross-host smoke). The dedicated marker is
  written ONLY by the launcher, so syncs never trip the dedupe. Feature 174.
#>

function Get-SpecrewLauncherMarkerPath {
    param([Parameter(Mandatory)][string] $ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/runtime/launcher-bootstrap.json')
}

function Write-SpecrewLauncherBootstrapMarker {
    # Called by `specrew start` when it emits a launcher bootstrap, so the hook dedupes after it.
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $ProjectRoot, [Parameter(Mandatory)][string] $RecordedAt)
    $path = Get-SpecrewLauncherMarkerPath -ProjectRoot $ProjectRoot
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ([pscustomobject]@{ recorded_at = $RecordedAt } | ConvertTo-Json) | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Test-SpecrewLauncherBootstrapRecent {
    # True when the launcher emitted a bootstrap within the window -> the hook must stay silent.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $NowUtc,           # ISO-8601 (deterministic for tests; Get-Date live)
        [Parameter()][int] $WindowSeconds = 120
    )
    $path = Get-SpecrewLauncherMarkerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    try {
        $m = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
        # ConvertFrom-Json (PS7) auto-deserializes an ISO-8601 string to [datetime]; handle both.
        $rawRec = $m.recorded_at
        $r = if ($rawRec -is [datetime]) { $rawRec.ToUniversalTime() } else { [datetime]::Parse([string]$rawRec).ToUniversalTime() }
        $n = [datetime]::Parse($NowUtc).ToUniversalTime()
        $age = ($n - $r).TotalSeconds
        return ($age -ge 0 -and $age -le $WindowSeconds)
    }
    catch { return $false }
}
