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

# --- F-174 iter-10: HOOK double-render dedupe via an ATOMIC single-winner CLAIM (a SEPARATE concern from the
# launcher<->hook dedupe above) ---
# codex intrinsically fires SessionStart TWICE per launch from a SINGLE hook registration, and the worktree
# dogfood (2026-06-13) proved the two fires are near-SIMULTANEOUS (~microseconds apart, same session id +
# source) - NOT the ~7s-sequential gap an earlier main-repo sample suggested. A recency / record-after-render
# scheme cannot dedupe simultaneous fires: both check the marker before EITHER records, so both render (the
# dogfood saw exactly this - two render markers ~10us apart). So we elect exactly ONE renderer with an ATOMIC
# create-if-absent claim: the FIRST fire of a given (session, source) to create its claim file WINS and
# renders; every concurrent/later fire finds the file present and stays silent. `File.Open(..., CreateNew)`
# (O_EXCL) is a SINGLE atomic syscall - there is NO check-then-act gap for two processes to slip through - so
# it elects a single winner regardless of timing (10us or 7s apart). Keyed per (session, source): a different
# session, or a /clear (different source), wins its OWN claim and renders. The caller filters the 'no-session'
# sentinel (no stable id - a Stop event, or the self-host repo where codex sends none) -> NEVER claimed ->
# always renders. Fail-OPEN: the claim returns $true (render) on anything that is not "the file genuinely
# already exists" - a duplicate render is benign, a SUPPRESSED one is the only unacceptable outcome. Per-key
# claim files accumulate (one per session) - tiny + cosmetic; NO time-based cleanup by design (a cleanup
# threshold below the inter-fire gap would delete the first fire's claim and re-open the double-render).

function Get-SpecrewHookRenderClaimPath {
    # Per-(session, source) claim path. Session id + source are sanitized to a filename-safe token (the same
    # rule the session-id sanitizer uses) so the path is always valid.
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $DedupeKey,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Source
    )
    $safeKey = ([string]$DedupeKey) -replace '[^a-zA-Z0-9-]', '-'
    $safeSrc = ([string]$Source) -replace '[^a-zA-Z0-9-]', '-'
    return (Join-Path $ProjectRoot (".specrew/runtime/hook-bootstrap-render-{0}-{1}.json" -f $safeKey, $safeSrc))
}

function Request-SpecrewHookRenderClaim {
    # Atomic single-winner election for the codex double-fire. Returns $true if THIS fire WON the (session,
    # source) claim and must render; $false if a sibling fire already claimed it and this fire must stay
    # silent. The election is the atomic CreateNew (O_EXCL): exactly one concurrent caller creates the file;
    # the rest get an IOException. Fail-OPEN: only "the file genuinely exists" returns $false; every other
    # outcome (incl. unexpected errors) returns $true so a directive is never wrongly suppressed.
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $DedupeKey,
        [Parameter(Mandatory)][AllowEmptyString()][string] $Source,
        [Parameter(Mandatory)][string] $RecordedAt
    )
    try {
        $path = Get-SpecrewHookRenderClaimPath -ProjectRoot $ProjectRoot -DedupeKey $DedupeKey -Source $Source
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $fs = $null
        try {
            # CreateNew = create-if-absent in ONE atomic step; throws IOException if the file already exists.
            $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        }
        catch [System.IO.IOException] {
            # Lost the race ONLY if the file genuinely exists; any other IO fault -> fail-open to render.
            if (Test-Path -LiteralPath $path) { return $false }
            return $true
        }
        try {
            $json = ([pscustomobject]@{ dedupe_key = $DedupeKey; source = $Source; recorded_at = $RecordedAt } | ConvertTo-Json -Compress)
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
            $fs.Write($bytes, 0, $bytes.Length)
        }
        finally { $fs.Dispose() }
        return $true   # we created the claim -> sole winner -> render
    }
    catch {
        return $true   # fail-open: never suppress on an unexpected error
    }
}
