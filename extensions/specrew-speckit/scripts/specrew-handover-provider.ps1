# Specrew SessionEnd handover provider (Feature 174, T022 / D-002; Proposal 130 Pillar 4a).
# Registered as a provider row in refocus-scopes.json (events: SessionEnd). The
# SpecrewHookDispatcher invokes this on SessionEnd with `--event-json <json>`; it writes a
# best-effort Proposal-130 handover via SessionEndHandoverManager and emits nothing (the session
# is ending - no injection). Fail-open doctrine (P1): any error -> no output, exit 0.
#
#   --event-json <json>     the host SessionEnd event (source: clear|exit|compact|...)
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

    # Same component resolution as the bootstrap provider (D-001).
    $bdir = Join-Path $PSScriptRoot 'bootstrap'
    if (-not (Test-Path -LiteralPath $bdir)) {
        $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1
        if ($mod) { $bdir = Join-Path $mod.ModuleBase 'scripts/internal/bootstrap' }
    }
    foreach ($f in 'HostEventAdapter', 'HandoverStore', 'SessionEndHandoverManager') {
        . (Join-Path $bdir "$f.ps1")
    }

    # Gather context from the committed session state (the hook has no transcript access).
    $feature = $null; $boundary = $null
    $ctxPath = Join-Path $root '.specrew/start-context.json'
    if (Test-Path -LiteralPath $ctxPath) {
        try {
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
            $ss = Get-HandoverProp $ctx 'session_state'
            $feature = Get-HandoverProp $ss 'feature_ref'
            $boundary = Get-HandoverProp $ss 'boundary_type'
        }
        catch { $null = $_ }  # fail-open: missing/partial context degrades, never blocks
    }
    $head = ''
    try { $head = (& git -C $root rev-parse --short HEAD 2>$null) } catch { $null = $_ }
    $now = (Get-Date).ToUniversalTime().ToString('o')

    # Best-effort sections (Proposal 130 Pillar 4a): the hook cannot read the transcript.
    $sections = @{
        'What I just did (last 3-5 turns or last boundary work)' =
        '(SessionEnd hook handover; turn-by-turn summary not available from the hook - reconstruct from artifacts + git status + start-context.json)'
        'Recommended next-immediate-step' =
        ("Resume {0} at {1}." -f ($(if ($feature) { $feature } else { '(no active feature)' }), $(if ($boundary) { $boundary } else { '(no boundary)' })))
    }

    Invoke-SpecrewSessionEndHandover -RawEvent $eventJson -HostName claude -ProjectRoot $root `
        -RecordedAt $now -FromCommit $head -ActiveFeature $feature -ActiveBoundary $boundary -Sections $sections | Out-Null

    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-handover] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
