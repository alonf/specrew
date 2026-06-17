<#
.SYNOPSIS
  Read the session anchor and write the advisory SessionStart marker.
.DESCRIPTION
  Resource accessor (IDesign): the only component that touches the session-state and marker
  files. Reads fail open (return $null on missing/corrupt). Absolute-path anchors are treated
  as non-portable and must be re-resolved against the current project root before use (FR-015).
  The marker is local-only and never committed (integration-api d2). Property access is
  defensive so the functions are safe under Set-StrictMode. Feature 174 (FR-013, FR-015, FR-018).
#>

function Get-SpecrewProp {
    # StrictMode-safe property read: returns $null when the property is absent.
    param([AllowNull()]$Object, [Parameter(Mandatory)][string] $Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

function Get-SpecrewSessionAnchor {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $StatePath)

    if (-not (Test-Path -LiteralPath $StatePath)) { return $null }
    try {
        $obj = (Get-Content -LiteralPath $StatePath -Raw -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
    }
    catch { return $null }

    $s = Get-SpecrewProp $obj 'session_state'
    if ($null -eq $s) { return $null }

    [pscustomobject]@{
        feature_ref      = Get-SpecrewProp $s 'feature_ref'
        feature_path     = Get-SpecrewProp $s 'feature_path'
        boundary         = Get-SpecrewProp $s 'boundary_type'
        iteration        = Get-SpecrewProp $s 'iteration_number'
        auth_commit_hash = Get-SpecrewProp $s 'auth_commit_hash'
        recorded_at      = Get-SpecrewProp $s 'recorded_at'
        active           = [bool](Get-SpecrewProp $s 'active')
    }
}

function Write-SpecrewSessionMarker {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $MarkerPath,
        [Parameter(Mandatory)][string] $HostName,
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][string] $Branch,
        [Parameter()][string] $HeadCommit,
        [Parameter()][string] $SessionId,
        # Caller supplies the timestamp (keeps the accessor deterministic + unit-testable).
        [Parameter(Mandatory)][string] $StartedAt
    )

    $marker = [pscustomobject]@{
        started_at   = $StartedAt
        host         = $HostName
        session_id   = $SessionId
        project_root = $ProjectRoot
        branch       = $Branch
        head_commit  = $HeadCommit
    }
    $dir = Split-Path -Parent $MarkerPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    # Atomic write (F-174 iter-10). The codex double-hook-call dogfood (2026-06-12) left a permanently
    # corrupt session-marker.json (two JSON objects, same session, ms apart). A plain Set-Content
    # truncates-then-writes the DEST in place, so a writer killed mid-write - or a host that re-emits
    # SessionStart so two writers overlap - can leave the dest half-written FOR GOOD (the session ends
    # before any later write heals it). Write to a PID-unique temp first, then swap it into place with
    # File.Replace: the dest is only ever touched by an atomic filesystem-level rename, so it is always
    # either the OLD marker or the NEW one - whole, never partial - no matter when the process dies.
    # Replace with a $null backup (NOT Move): Replace is the true ReplaceFile primitive (atomic swap,
    # the same one the rolling handover uses), and the $null backup avoids the `.old` clutter that would
    # otherwise accrue in runtime/ for a file re-derived every session. First write (dest absent) ->
    # plain Move. Fail-soft: any error falls back to a direct write so a session is never left WITHOUT a
    # marker (a torn marker is recoverable - Get-SpecrewSessionMarker fails open to null; a MISSING one
    # is the harmful case). Transient mid-race torn READS stay possible but are harmless by that same
    # fail-open; what this closes is the PERSISTENT corruption a half-written dest leaves behind.
    $json = ($marker | ConvertTo-Json)
    $tmp = "$MarkerPath.$PID.tmp"
    try {
        Set-Content -LiteralPath $tmp -Value $json -Encoding UTF8
        if (Test-Path -LiteralPath $MarkerPath) {
            [System.IO.File]::Replace($tmp, $MarkerPath, $null)   # atomic same-volume swap, no .old backup
        }
        else {
            [System.IO.File]::Move($tmp, $MarkerPath)             # first write: dest absent, nothing to replace
        }
    }
    catch {
        # Last resort: a direct write so a session is never left without a marker.
        try { Set-Content -LiteralPath $MarkerPath -Value $json -Encoding UTF8 } catch { $null = $_ }
    }
    finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    }
    $marker
}

function Get-SpecrewSessionMarker {
    # Read the advisory SessionStart marker (fail open). FR-018.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $MarkerPath)
    if (-not (Test-Path -LiteralPath $MarkerPath)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $MarkerPath -Raw -ErrorAction Stop
        # An empty/whitespace file is the truncate-window torn read: Get-Content -Raw yields $null and
        # $null | ConvertFrom-Json is also $null, which would otherwise build an all-null-fields object
        # that looks like a usable-but-empty marker. Fail open to $null instead (the safe "no marker").
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $m = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch { return $null }
    # A torn or concatenated payload can parse to an array (two objects) or to an object missing the
    # mandatory field. Either way there is no single usable marker -> fail open rather than half-trust it.
    if ($m -is [System.Array]) { return $null }
    $startedAt = Get-SpecrewProp $m 'started_at'
    if ([string]::IsNullOrWhiteSpace([string]$startedAt)) { return $null }
    [pscustomobject]@{
        started_at   = $startedAt
        host         = Get-SpecrewProp $m 'host'
        session_id   = Get-SpecrewProp $m 'session_id'
        project_root = Get-SpecrewProp $m 'project_root'
        branch       = Get-SpecrewProp $m 'branch'
        head_commit  = Get-SpecrewProp $m 'head_commit'
    }
}

function Test-SpecrewAnchorPortable {
    # An absolute feature_path that does not resolve under the current project root is
    # non-portable (the merged-Feature-171 cross-worktree incident). FR-015.
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter()][AllowNull()]$Anchor, [Parameter(Mandatory)][string] $ProjectRoot)

    if ($null -eq $Anchor) { return $false }
    $fp = Get-SpecrewProp $Anchor 'feature_path'
    if ([string]::IsNullOrWhiteSpace($fp)) { return $true }  # nothing absolute recorded -> re-resolve project-local
    if ([System.IO.Path]::IsPathRooted($fp)) {
        $norm = ([string]$fp).Replace('\', '/').TrimEnd('/')
        $root = $ProjectRoot.Replace('\', '/').TrimEnd('/')
        return $norm.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)
    }
    return $true
}
