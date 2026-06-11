# Specrew Stop-event ROLLING-handover provider (Feature 174 iter-4; supersedes the SessionEnd provider).
# Registered for the per-host END-OF-TURN Stop event (Claude `Stop`, Codex `Stop`, Copilot `agentStop`,
# Cursor `stop`). The SpecrewHookDispatcher invokes it with `--event-json <json>` on each Stop; it
# refreshes the ONE rolling handover (.specrew/handover/session-handover.md) ONLY on a material change
# (boundary moved OR tracked-file change since the last write). Portable across hosts + crash-safe (the
# file always reflects the last completed turn). Fail-open: any error -> exit 0.
#
# F-174 iter-5 (floor/body split): the hook writes the FLOOR and PRESERVES the agent-authored body for
# the current boundary, else writes a placeholder; it does NOT author rich content (transcript-blind).
# It also emits a NON-BLOCKING same-session detection (stderr WARN + handover-journal record) when the
# body is left a placeholder, so a hollow handover is caught - it never blocks (P1: exit 0). The agent
# authors the rich body via Write-SpecrewHandoverContext; the resume bootstrap surfaces it, or warns the
# human backstop when it is a placeholder. (Why detection, not an agent-facing Stop warn: a Stop hook
# cannot reach the agent - Stop is not an injection event and P1 forbids the only alternative, a block.)
#
#   --event-json <json>     the host Stop event payload
#   --project-root <path>   optional override (testability); else resolve up to .specrew

$ErrorActionPreference = 'Stop'

function Get-HandoverProjectRoot {
    $c = (Get-Location).Path
    while (-not [string]::IsNullOrWhiteSpace($c)) {
        if (Test-Path -LiteralPath (Join-Path $c '.specrew') -PathType Container) { return $c }
        $p = Split-Path -Parent $c
        if ($p -eq $c) { break }
        $c = $p
    }
    return (Get-Location).Path
}

function Get-HandoverProp {
    param([AllowNull()]$Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

try {
    $eventJson = ''
    $rootOverride = $null
    $hostKindArg = $null
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
    }

    $root = if ($rootOverride) { $rootOverride } else { Get-HandoverProjectRoot }

    # Component resolution (same as the bootstrap provider, D-001): beside the provider in the self-host
    # tree, else SPECREW_MODULE_PATH (dev-tree override) , else the installed module's scripts/internal/bootstrap.
    $bdir = Join-Path $PSScriptRoot 'bootstrap'
    if (-not (Test-Path -LiteralPath $bdir)) {
        $devBdir = if ($env:SPECREW_MODULE_PATH) { Join-Path $env:SPECREW_MODULE_PATH 'scripts/internal/bootstrap' } else { $null }
        if ($devBdir -and (Test-Path -LiteralPath $devBdir)) { $bdir = $devBdir }
        else {
            $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1
            if ($mod) { $bdir = Join-Path $mod.ModuleBase 'scripts/internal/bootstrap' }
        }
    }
    foreach ($f in 'HandoverStore', 'ClassificationEngine', 'ProjectMetadataAccessor') { . (Join-Path $bdir "$f.ps1") }

    # The stop event type (host-agnostic: parse the payload directly, no per-host adapter needed).
    $source = 'stop'
    $payload = $null
    if (-not [string]::IsNullOrWhiteSpace($eventJson)) { try { $payload = $eventJson | ConvertFrom-Json } catch { $payload = $null } }
    if ($null -ne $payload) {
        $s = Get-HandoverProp $payload 'hook_event_name'
        if ([string]::IsNullOrWhiteSpace($s)) { $s = Get-HandoverProp $payload 'source' }
        if (-not [string]::IsNullOrWhiteSpace($s)) { $source = [string]$s }
    }

    # Current context (the hook has no transcript; read the committed session state).
    $feature = $null; $boundary = $null; $fromHost = 'host'
    $ctxPath = Join-Path $root '.specrew/start-context.json'
    if (Test-Path -LiteralPath $ctxPath) {
        try {
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
            $ss = Get-HandoverProp $ctx 'session_state'
            $feature = Get-HandoverProp $ss 'feature_ref'
            $boundary = Get-HandoverProp $ss 'boundary_type'
            $h = Get-HandoverProp $ss 'host'; if ([string]::IsNullOrWhiteSpace($h)) { $h = Get-HandoverProp $ctx 'host' }
            if (-not [string]::IsNullOrWhiteSpace($h)) { $fromHost = [string]$h }
        }
        catch { $null = $_ }
    }

    # F-174 iter-9: the dispatcher passes the authoritative resolved host via --host-kind; prefer it so the
    # handover provenance is the REAL host (claude/codex/copilot), not the 'host' default (iter-8 dogfood:
    # 15/15 journal entries stamped 'host' because start-context carried no host field).
    if (-not [string]::IsNullOrWhiteSpace($hostKindArg)) { $fromHost = $hostKindArg }

    # F-174 (T050): the pre-specify WORKSHOP window leaves the anchor's feature_ref blank (no boundary
    # crossed yet), so without this the floor stamps an empty active_feature -> the handover validates as
    # 'no-feature' and is NEVER surfaced on resume (the agent re-derives from scratch - the "resync takes
    # minutes" symptom). Resolve the feature from the current branch (Spec Kit: branch == feature slug,
    # specs/<branch>/ already scaffolded) so the floor carries it and the handover becomes surfaceable; the
    # read-side Test-SpecrewHandoverValidity still re-checks present + not-merged + freshness. Fail-safe:
    # on main / a non-feature branch / a deleted feature dir the resolver returns $null (today's behavior).
    if ([string]::IsNullOrWhiteSpace([string]$feature)) {
        $feature = Resolve-SpecrewBranchFeatureRef -ProjectRoot $root
    }

    $handoverDir = Join-Path $root '.specrew/handover'
    $now = (Get-Date).ToUniversalTime().ToString('o')

    # Material-change gate: only refresh when the boundary moved OR there is a tracked-file change.
    $existing = Get-SpecrewRollingHandover -HandoverDir $handoverDir -NowUtc $now
    $lastBoundary = if ($null -ne $existing) { $existing.active_boundary } else { $null }
    $hasChange = $false
    try { $st = (& git -C $root status --porcelain 2>$null); $hasChange = -not [string]::IsNullOrWhiteSpace(($st -join "`n")) } catch { $null = $_ }
    $mc = Test-SpecrewHandoverMaterialChange -CurrentBoundary $boundary -LastBoundary $lastBoundary -HasTrackedChange $hasChange -HandoverExists ($null -ne $existing)
    if (-not $mc.material) { exit 0 }   # quiet turn: skip cheaply

    # F-174 iter-9 (hook-primary author): the hook CAPTURES the git/fs session delta and writes the
    # MECHANICAL body sections every material stop - so the handover is never hollow without any agent
    # cooperation. The prior from_commit (from the existing handover) bounds "new commits this session".
    $head = ''
    try { $head = ([string](& git -C $root rev-parse --short HEAD 2>$null)).Trim() } catch { $null = $_ }
    $sinceCommit = if ($null -ne $existing) { [string]$existing.from_commit } else { $null }
    $delta = Get-SpecrewSessionDelta -ProjectRoot $root -SinceCommit $sinceCommit

    $featureLabel = if ([string]::IsNullOrWhiteSpace([string]$feature)) { '(no active feature)' } else { [string]$feature }
    $boundaryLabel = if ([string]::IsNullOrWhiteSpace([string]$boundary)) { '(pre-boundary / workshop)' } else { [string]$boundary }

    # One activity line for THIS stop, accumulated newest-first across the boundary window (reset on a
    # boundary change so a fresh boundary starts a fresh arc) - the "add changed info on every stop" behavior.
    $fileNote = if ($delta.has_uncommitted) {
        $shown = (@($delta.uncommitted_files) -join ', ')
        if ($delta.uncommitted_truncated) { $shown = "$shown, +more" }
        " [$shown]"
    }
    else { '' }
    $commitNote = if ($delta.new_commit_count -gt 0) { ("; {0} new commit(s): {1}" -f $delta.new_commit_count, ((@($delta.new_commits)) -join ' | ')) } else { '' }
    $stamp = if ($now.Length -ge 19) { ($now.Substring(0, 19) + 'Z') } else { $now }
    $stopBullet = ("- [{0}] {1} uncommitted file(s){2}; HEAD {3} ({4}){5}" -f $stamp, $delta.uncommitted_count, $fileNote, $delta.head_short, $delta.head_subject, $commitNote)

    $activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
    $priorBullets = @()
    if ($null -ne $existing -and ([string]$existing.active_boundary -eq [string]$boundary) -and $existing.sections -and $existing.sections.Contains($activityTitle)) {
        $prev = [string]$existing.sections[$activityTitle]
        if (-not [string]::IsNullOrWhiteSpace($prev) -and $prev -notlike '(placeholder*') {
            $priorBullets = @($prev -split "`n" | Where-Object { $_ -match '^\s*-\s' })
        }
    }
    $activity = ((@($stopBullet) + $priorBullets) | Select-Object -First 6) -join "`n"

    $whyStopping = ("End-of-turn Stop, hook-captured (the agent did not author a handover this turn). Boundary: {0}. Refresh reason: {1}." -f $boundaryLabel, $mc.reason)
    $recNext = if ($delta.has_uncommitted) {
        ("Resume feature {0} at boundary {1}. {2} uncommitted file(s) are NOT in git history yet - review/commit them before advancing." -f $featureLabel, $boundaryLabel, $delta.uncommitted_count)
    }
    else {
        ("Resume feature {0} at boundary {1}. Working tree is clean; continue the next lifecycle step." -f $featureLabel, $boundaryLabel)
    }
    $uncommittedNote = if ($delta.has_uncommitted) { (" Uncommitted work NOT yet committed: {0}." -f ((@($delta.uncommitted_files) -join ', '))) } else { '' }
    $context = ("branch {0}, HEAD {1} ({2}). Active feature {3}, boundary {4}.{5}" -f $delta.branch, $delta.head_short, $delta.head_subject, $featureLabel, $boundaryLabel, $uncommittedNote)

    $mechanical = @{
        $activityTitle                                                = $activity
        "Why I'm stopping (the switch trigger)"                       = $whyStopping
        'Recommended next-immediate-step'                             = $recNext
        "Context the receiving host needs that artifacts don't carry" = $context
    }

    # The HOOK floor-writer: write the fresh mechanical body; preserve any agent interpretive overlay.
    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source $source -FromHost $fromHost `
        -RecordedAt $now -FromCommit $head -ActiveFeature $feature -ActiveBoundary $boundary `
        -MechanicalSections $mechanical | Out-Null

    # Recalibrated hollow detection (iter-9): hollow ONLY if the hook could author NO mechanical section
    # (git unavailable) AND no agent overlay exists - now a rare true-failure, not the every-build-stop
    # default. Journal it then so the resume bootstrap can still warn the human backstop.
    $mechAuthored = @($mechanical.Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count
    if ($mechAuthored -eq 0) {
        [Console]::Error.WriteLine(("[specrew-handover] WARN HOLLOW_HANDOVER boundary='{0}' reason='{1}' - the hook captured no session delta (git unavailable?); the next session inherits a hollow handover." -f $boundary, $mc.reason))
        try {
            $jpath = Join-Path $root '.specrew/runtime/handover-journal.jsonl'
            $jdir = Split-Path -Parent $jpath
            if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
            $rec = [pscustomobject]@{ event = 'hollow-handover-at-stop'; recorded_at = $now; boundary = $boundary; feature = $feature; from_host = $fromHost; material_reason = $mc.reason }
            ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $jpath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-handover] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
