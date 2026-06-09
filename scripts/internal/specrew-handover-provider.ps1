# Specrew Stop-event ROLLING-handover provider (Feature 174 iter-4; supersedes the SessionEnd provider).
# Registered for the per-host END-OF-TURN Stop event (Claude `Stop`, Codex `Stop`, Copilot `agentStop`,
# Cursor `stop`). The SpecrewHookDispatcher invokes it with `--event-json <json>` on each Stop; it
# refreshes the ONE rolling handover (.specrew/handover/session-handover.md) ONLY on a material change
# (boundary moved OR tracked-file change since the last write). Portable across hosts + crash-safe (the
# file always reflects the last completed turn). Write-only, emits nothing. Fail-open: any error -> exit 0.
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

    $head = ''
    try { $head = (& git -C $root rev-parse --short HEAD 2>$null) } catch { $null = $_ }
    $sections = @{
        'What I just did (last 3-5 turns or last boundary work)' =
        '(Stop-event rolling handover; turn-by-turn summary not available from the hook - reconstruct from artifacts + git status + start-context.json)'
        'Recommended next-immediate-step' =
        ("Resume {0} at {1}." -f ($(if ($feature) { $feature } else { '(no active feature)' }), $(if ($boundary) { $boundary } else { '(no boundary)' })))
    }

    Write-SpecrewRollingHandover -HandoverDir $handoverDir -Source $source -FromHost $fromHost `
        -RecordedAt $now -FromCommit $head -ActiveFeature $feature -ActiveBoundary $boundary -Sections $sections | Out-Null

    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-handover] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
