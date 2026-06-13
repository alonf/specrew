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

# --- F-174 iter-10: HOOK double-render dedupe (a SEPARATE concern from the launcher<->hook dedupe above) ---
# Some hosts (codex, CONFIRMED live) intrinsically fire SessionStart TWICE per launch from a SINGLE hook
# registration (~7s apart in observation), so the bootstrap provider renders its directive twice. These three
# functions keep at most ONE rendered directive per (session, launch-source): the provider RECORDS a marker
# AFTER it renders, and the host's duplicate fire reads the marker and stays silent. Distinct from the
# launcher dedupe in two ways that matter: (1) it is keyed on the session id + launch source, NOT pure
# recency - a DIFFERENT session, or the SAME session under a different source (a /clear re-bootstrap), still
# renders; (2) the caller filters the 'no-session' sentinel, so any event with no stable session id (a Stop
# event, or the self-host repo where codex sends none) is NEVER deduped -> always renders. Fail-open
# throughout: a MISSING directive is the only unacceptable outcome, a DUPLICATE one is benign, so every error
# path (and a torn/garbage/stale marker) returns "render". The marker is intentionally NON-atomic for the
# same reason: a torn read fails open to render and the next render overwrites it, so corruption cannot
# persist into a suppressed directive (unlike the session marker, whose corruption WOULD persist).

function Get-SpecrewHookRenderMarkerPath {
    param([Parameter(Mandatory)][string] $ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/runtime/hook-bootstrap-render.json')
}

function Write-SpecrewHookRenderMarker {
    # Called by the bootstrap provider AFTER a successful render, so the host's duplicate SessionStart fire
    # dedupes against it. Records the (session, source) that rendered + when. The 'no-session' sentinel is
    # filtered by the caller (it is never recorded), so the marker always carries a real session key.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $DedupeKey,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Source,
        [Parameter(Mandatory)][string] $RecordedAt
    )
    $path = Get-SpecrewHookRenderMarkerPath -ProjectRoot $ProjectRoot
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ([pscustomobject]@{ dedupe_key = $DedupeKey; source = $Source; recorded_at = $RecordedAt } | ConvertTo-Json) | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Test-SpecrewHookRenderRecent {
    # True ONLY when a directive for the SAME (DedupeKey, Source) was rendered within the window -> a
    # duplicate SessionStart fire must stay silent. Any mismatch (different session, different launch source),
    # a stale marker, a torn/garbage marker, or any error -> $false (render): suppression requires positive
    # proof that THIS session+source already rendered; absent that proof we render. The caller never passes
    # the 'no-session' sentinel here.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $DedupeKey,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Source,
        [Parameter(Mandatory)][string] $NowUtc,           # ISO-8601 (deterministic for tests; Get-Date live)
        [Parameter()][int] $WindowSeconds = 60
    )
    $path = Get-SpecrewHookRenderMarkerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    try {
        $m = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json
        if ($m -is [System.Array]) { return $false }                        # torn/garbage (two objects) -> render
        if ([string]$m.dedupe_key -ne [string]$DedupeKey) { return $false }  # different session -> render
        if ([string]$m.source -ne [string]$Source) { return $false }         # different launch source (e.g. /clear) -> render
        # ConvertFrom-Json (PS7) auto-deserializes an ISO-8601 string to [datetime]; handle both.
        $rawRec = $m.recorded_at
        $r = if ($rawRec -is [datetime]) { $rawRec.ToUniversalTime() } else { [datetime]::Parse([string]$rawRec).ToUniversalTime() }
        $n = [datetime]::Parse($NowUtc).ToUniversalTime()
        $age = ($n - $r).TotalSeconds
        return ($age -ge 0 -and $age -le $WindowSeconds)
    }
    catch { return $false }
}
