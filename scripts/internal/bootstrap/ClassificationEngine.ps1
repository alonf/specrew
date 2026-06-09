<#
.SYNOPSIS
  Decide the bootstrap mode (full | welcome-back | cleared-anchor) from validated state.
.DESCRIPTION
  Stable, PURE engine (IDesign): no filesystem, git, or accessor calls - the caller passes
  the already-validated state in. This is the handover-first, two-stage classification from
  architecture-core decision 2; iteration 001 implements the anchor stage (handover stage is
  added in iteration 002, T010). Keeping this pure is what makes every mode path unit-testable
  (observability decision 2). Feature 174 (FR-001, FR-017).
.OUTPUTS
  [pscustomobject] { mode, reason }
    mode: 'full' | 'welcome-back' | 'cleared-anchor'
#>
function Resolve-SpecrewBootstrapMode {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # True when the session anchor resolved project-local, active, fresh, not merged/closed.
        [Parameter(Mandatory)][bool] $AnchorValid,
        # Non-null reason when an anchor was present but cleared (merged|closed|non-portable|mismatch).
        [Parameter()][string] $AnchorClearedReason,
        # Iteration 002 adds the handover-first stage; default false keeps the anchor-only path.
        [Parameter()][bool] $HandoverValid = $false
    )

    # Handover-first stage (architecture-core d2): a validated handover is the primary resume
    # signal and is surfaced before the anchor.
    if ($HandoverValid) {
        return [pscustomobject]@{ mode = 'welcome-back'; reason = 'resuming from a validated handover' }
    }
    if ($AnchorValid) {
        return [pscustomobject]@{ mode = 'welcome-back'; reason = $null }
    }
    if (-not [string]::IsNullOrWhiteSpace($AnchorClearedReason)) {
        return [pscustomobject]@{ mode = 'cleared-anchor'; reason = "cleared a stale anchor: $AnchorClearedReason" }
    }
    return [pscustomobject]@{ mode = 'full'; reason = 'no valid active session' }
}

function Test-SpecrewConcurrentSession {
    # Advisory local same-worktree concurrency (FR-018, FR-019). PURE: the caller passes the existing
    # marker in. This is NOT a lock (the user explicitly rejected locks: a session closed without an
    # exit hook would leave a stuck lock). A marker within the freshness window for THIS worktree
    # signals a possibly-active concurrent session (advisory only); a STALE marker signals a prior
    # UNCLEAN exit (informational); a marker for a different worktree is ignored. Never blocks.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()]$Marker,            # from Get-SpecrewSessionMarker, or $null
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $NowUtc,
        [Parameter()][int] $WindowSeconds = 3600       # 1h (clarify answer)
    )
    if ($null -eq $Marker) { return [pscustomobject]@{ concurrent = $false; reason = 'none'; age_seconds = $null } }
    $startedAt = $Marker.started_at
    if ([string]::IsNullOrWhiteSpace($startedAt)) { return [pscustomobject]@{ concurrent = $false; reason = 'none'; age_seconds = $null } }

    $mr = $Marker.project_root
    if (-not [string]::IsNullOrWhiteSpace($mr)) {
        $same = (([string]$mr).Replace('\', '/').TrimEnd('/') -ieq $ProjectRoot.Replace('\', '/').TrimEnd('/'))
        if (-not $same) { return [pscustomobject]@{ concurrent = $false; reason = 'different-worktree'; age_seconds = $null } }
    }

    try {
        # ConvertFrom-Json may have auto-deserialized started_at to [datetime]; handle both.
        $s = if ($startedAt -is [datetime]) { $startedAt.ToUniversalTime() } else { [datetime]::Parse([string]$startedAt).ToUniversalTime() }
        $n = [datetime]::Parse($NowUtc).ToUniversalTime()
        $age = [int]($n - $s).TotalSeconds
    }
    catch { return [pscustomobject]@{ concurrent = $false; reason = 'none'; age_seconds = $null } }

    if ($age -ge 0 -and $age -le $WindowSeconds) {
        return [pscustomobject]@{ concurrent = $true; reason = 'fresh-marker'; age_seconds = $age }
    }
    return [pscustomobject]@{ concurrent = $false; reason = 'stale-marker-unclean-exit'; age_seconds = $age }
}

function Test-SpecrewHandoverMaterialChange {
    # F-174 iter-4: decide whether a Stop event should refresh the rolling handover. Material change =
    # the boundary cursor moved since the last write, OR a tracked-file change occurred since the last
    # write; otherwise skip cheaply (the Stop fires every turn). PURE: the caller computes the signals
    # (current vs last boundary, git-tracked-change bool) and passes them in. FR-009.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][string] $CurrentBoundary,   # current boundary cursor
        [Parameter()][AllowNull()][string] $LastBoundary,      # boundary recorded in the existing handover (or $null)
        [Parameter()][bool] $HasTrackedChange,                 # caller-computed: tracked change since last write
        [Parameter()][bool] $HandoverExists                    # is there an existing rolling handover?
    )
    if (-not $HandoverExists) { return [pscustomobject]@{ material = $true; reason = 'no-existing-handover' } }
    if ((-not [string]::IsNullOrWhiteSpace($CurrentBoundary)) -and ($CurrentBoundary -ne $LastBoundary)) {
        return [pscustomobject]@{ material = $true; reason = 'boundary-moved' }
    }
    if ($HasTrackedChange) { return [pscustomobject]@{ material = $true; reason = 'tracked-change' } }
    return [pscustomobject]@{ material = $false; reason = 'no-material-change' }
}
