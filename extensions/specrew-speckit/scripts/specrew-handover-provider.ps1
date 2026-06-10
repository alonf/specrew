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
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
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
    foreach ($f in 'HandoverStore', 'ClassificationEngine') { . (Join-Path $bdir "$f.ps1") }

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

    $handoverDir = Join-Path $root '.specrew/handover'
    $now = (Get-Date).ToUniversalTime().ToString('o')

    # Material-change gate: only refresh when the boundary moved OR there is a tracked-file change.
    $existing = Get-SpecrewRollingHandover -HandoverDir $handoverDir -NowUtc $now
    $lastBoundary = if ($null -ne $existing) { $existing.active_boundary } else { $null }
    $hasChange = $false
    try { $st = (& git -C $root status --porcelain 2>$null); $hasChange = -not [string]::IsNullOrWhiteSpace(($st -join "`n")) } catch { $null = $_ }
    $mc = Test-SpecrewHandoverMaterialChange -CurrentBoundary $boundary -LastBoundary $lastBoundary -HasTrackedChange $hasChange -HandoverExists ($null -ne $existing)
    if (-not $mc.material) { exit 0 }   # quiet turn: skip cheaply

    # iter-5 detection (failure-mode B, NON-BLOCKING): was the EXISTING body authored FOR THE CURRENT
    # boundary? If so, the hook below preserves it (not hollow). If not (boundary moved, or never
    # authored), the hook writes a placeholder and we record a same-session hollow detection.
    $authoredForCurrent = $false
    if ($null -ne $existing -and $existing.PSObject.Properties['sections'] -and (([string]$existing.active_boundary) -eq ([string]$boundary))) {
        $authoredForCurrent = -not (Test-SpecrewHandoverBodyPlaceholder -Sections $existing.sections).placeholder
    }

    $head = ''
    try { $head = (& git -C $root rev-parse --short HEAD 2>$null) } catch { $null = $_ }

    # The HOOK floor-writer: refresh the floor; preserve the agent body for THIS boundary, else placeholder.
    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source $source -FromHost $fromHost `
        -RecordedAt $now -FromCommit $head -ActiveFeature $feature -ActiveBoundary $boundary | Out-Null

    # Same-session hollow-handover detection (non-blocking; the resume bootstrap re-detects + warns the
    # human backstop). Fires when this material Stop left the body a placeholder.
    if (-not $authoredForCurrent) {
        [Console]::Error.WriteLine(("[specrew-handover] WARN HOLLOW_HANDOVER boundary='{0}' reason='{1}' - the rolling handover body is a placeholder (the agent did not author it for this boundary); the next session inherits a hollow handover." -f $boundary, $mc.reason))
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
