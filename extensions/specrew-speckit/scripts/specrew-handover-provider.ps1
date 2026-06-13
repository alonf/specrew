# Specrew ROLLING-handover provider (Feature 174). Thin TRIGGER ADAPTER (iter-9.1): it resolves the project
# root, host, and trigger source, then funnels into the ONE core save path `Update-SpecrewRollingHandover`
# (HandoverStore). It re-implements no save logic. Registered for the per-host END-OF-TURN events (Claude
# `Stop`, Codex `Stop`, Copilot `agentStop`, Cursor `stop`) AND `PostToolUse` (so the handover refreshes
# mid-turn during picker-driven phases like the workshop, where no end-of-turn Stop fires). It is ALSO
# invoked directly by the design-workshop skill with `--source workshop`. Portable across hosts + crash-safe
# (the core's material-change gate keeps the per-tool-call PostToolUse cost cheap; the atomic writer keeps
# the file safe). Fail-open: any error -> exit 0.
#
#   --event-json <json>     the host event payload (Stop/agentStop/PostToolUse); source derived from it
#   --host-kind <kind>      the authoritative resolved host (claude|codex|copilot|cursor)
#   --source <label>        explicit trigger label (used by the workshop skill: `--source workshop`)
#   --project-root <path>   optional override (testability); else resolve up to .specrew

$ErrorActionPreference = 'Stop'

# SPECREW-UTF8-OUTPUT (F-174 iter-10, Prop-145 P3): declare UTF-8 stdout/stderr so non-ASCII output (e.g. a
# transcript/path WARN under a non-Latin home) is not mangled to '?' by the child pwsh's default OEM console
# codepage when the dispatcher captures it. The dispatcher reads UTF-8 (ProcessStartInfo.StandardOutputEncoding);
# this is the child half of that contract. Fail-open.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort: a host that rejects UTF-8 console encoding must still run (fail-open)

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
    $sourceArg = $null
    $sourceEventArg = $null
    $transcriptPathArg = $null
    $lastAssistantArg = $null
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq '--event-json' -and ($i + 1) -lt $args.Count) { $eventJson = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--project-root' -and ($i + 1) -lt $args.Count) { $rootOverride = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--source' -and ($i + 1) -lt $args.Count) { $sourceArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--transcript-path' -and ($i + 1) -lt $args.Count) { $transcriptPathArg = [string]$args[$i + 1] }
        elseif ($args[$i] -eq '--last-assistant-message' -and ($i + 1) -lt $args.Count) { $lastAssistantArg = [string]$args[$i + 1] }
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
    foreach ($f in 'HandoverStore', 'ClassificationEngine', 'ProjectMetadataAccessor', 'ConversationCaptureAccessor') { . (Join-Path $bdir "$f.ps1") }
    # F-174 iteration 011 (T004): load shared-governance so the Stop-hook Update-SpecrewRollingHandover can record
    # the captured human verdict (Add-SpecrewBoundaryAuthorization / Get-SpecrewBoundaryOrder). Same 3-tier
    # resolution the bootstrap provider uses ($bdir -> scripts/internal -> module root -> extensions/.../scripts).
    # FAIL-OPEN: if it cannot be resolved the handover still writes; the verdict-capture step self-guards on
    # Get-Command and simply skips the authorization (the resume then surfaces the boundary as awaiting-verdict).
    try {
        $sgModuleRoot = Split-Path (Split-Path (Split-Path $bdir -Parent))
        $sgPath = Join-Path (Join-Path $sgModuleRoot 'extensions/specrew-speckit/scripts') 'shared-governance.ps1'
        if (Test-Path -LiteralPath $sgPath -PathType Leaf) { . $sgPath }
    }
    catch { $null = $_ }

    # Resolve the trigger source, in precedence order: an explicit --source (the workshop skill passes
    # `workshop`); else --source-event (the dispatcher passes the neutral event name as a CLEAN arg, since
    # the --event-json payload gets mangled through Start-Process -ArgumentList); else parse the event name
    # from --event-json (direct invocations); else 'stop'. Host-agnostic - no per-host adapter.
    $source = if (-not [string]::IsNullOrWhiteSpace($sourceArg)) { $sourceArg }
    elseif (-not [string]::IsNullOrWhiteSpace($sourceEventArg)) { $sourceEventArg }
    else { 'stop' }
    if ([string]::IsNullOrWhiteSpace($sourceArg) -and [string]::IsNullOrWhiteSpace($sourceEventArg) -and -not [string]::IsNullOrWhiteSpace($eventJson)) {
        $payload = $null
        try { $payload = $eventJson | ConvertFrom-Json } catch { $payload = $null }
        if ($null -ne $payload) {
            $s = Get-HandoverProp $payload 'hook_event_name'
            if ([string]::IsNullOrWhiteSpace($s)) { $s = Get-HandoverProp $payload 'source' }
            if (-not [string]::IsNullOrWhiteSpace($s)) { $source = [string]$s }
        }
    }

    # F-174 iter-10 (T002): resolve the conversation transcript handle for capture. Robustness ladder:
    #   1. the CLEAN --transcript-path arg the dispatcher extracts from the INTACT stdin event (the
    #      --event-json arg gets mangled through Start-Process -ArgumentList, so it is not trusted for paths);
    #   2. else parse transcript_path / transcriptPath (+ last_assistant_message) from --event-json itself
    #      (direct/test invocations, where the JSON is intact);
    #   3. else the Cursor CURSOR_TRANSCRIPT_PATH env var (inherited through the process tree).
    $transcriptPath = $transcriptPathArg
    $lastAssistant = $lastAssistantArg
    if (([string]::IsNullOrWhiteSpace($transcriptPath) -or [string]::IsNullOrWhiteSpace($lastAssistant)) -and -not [string]::IsNullOrWhiteSpace($eventJson)) {
        $tp = $null
        try { $tp = $eventJson | ConvertFrom-Json } catch { $tp = $null }
        if ($null -ne $tp) {
            if ([string]::IsNullOrWhiteSpace($transcriptPath)) {
                $t = Get-HandoverProp $tp 'transcript_path'
                if ([string]::IsNullOrWhiteSpace($t)) { $t = Get-HandoverProp $tp 'transcriptPath' }
                if (-not [string]::IsNullOrWhiteSpace($t)) { $transcriptPath = [string]$t }
            }
            if ([string]::IsNullOrWhiteSpace($lastAssistant)) {
                $la = Get-HandoverProp $tp 'last_assistant_message'
                if (-not [string]::IsNullOrWhiteSpace($la)) { $lastAssistant = [string]$la }
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($transcriptPath) -and -not [string]::IsNullOrWhiteSpace($env:CURSOR_TRANSCRIPT_PATH)) {
        $transcriptPath = [string]$env:CURSOR_TRANSCRIPT_PATH
    }

    # SINGLE save path (F-174 iter-9.1): every trigger - this Stop/PostToolUse hook AND the workshop skill -
    # funnels through the one core orchestrator. Its material-change gate makes the PostToolUse (every
    # tool call) path cheap, and the hollow-journal lives there too.
    Update-SpecrewRollingHandover -ProjectRoot $root -HostKind $hostKindArg -Source $source `
        -TranscriptPath $transcriptPath -LastAssistantMessage $lastAssistant | Out-Null
    exit 0
}
catch {
    [Console]::Error.WriteLine("[specrew-handover] WARN PROVIDER_FAILED $($_.Exception.Message)")
    exit 0
}
