# SpecrewHookDispatcher (Feature 171, FR-008/FR-012; T006 core).
# THE single Specrew-registered handler per bound host event. Host hook configs
# register exactly one entry per event pointing here; every Specrew mechanism
# that wants to ride host events is a PROVIDER REGISTRY ROW in refocus-scopes.json
# — never a second registration on the host settings surface (ownership rule).
#
# Contract:
#   -Event <name>      host-neutral event name (SessionStart | PostToolUse | PreToolUse)
#   stdin              host event JSON (Claude shape: {session_id, source, tool_name, ...})
#   stdout             injection output, shaped per event (plain for SessionStart;
#                      hookSpecificOutput JSON for PostToolUse; permissionDecision
#                      JSON for PreToolUse gate providers — DORMANT seat, F-165)
#   exit code          ALWAYS 0 — a refocus failure may never block a session (P1).
#
# Fail-open doctrine: session-blocking failures are forbidden; injection failures
# degrade to silence + one visible stderr WARN ("fail-open for the session,
# fail-quiet-but-loud-once for the automation"). Gate providers fail OPEN to allow.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Event,
    [string]$EventJson,
    [int]$ProviderTimeoutSeconds = 20,
    # T014: per-host event/output shaping. The neutral -Event vocabulary stays
    # host-blind (SessionStart | PostToolUse | UserPromptSubmit | PreToolUse);
    # the BINDING (per-host hook config) names both when it registers.
    [ValidateSet('claude', 'codex', 'copilot', 'cursor')][string]$HostKind = 'claude'
)

# KILL SWITCH FIRST (FR-008): this check must precede ANY logic that could itself
# fail — a kill switch placed after catalog/state parsing never gets reached when
# the bug is in catalog/state parsing.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) { exit 0 }

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# SPECREW-UTF8-OUTPUT (F-174 iter-10, Prop-145 P3): the dispatcher is the FINAL emitter to the host - it writes
# the merged provider output (which inlines handover dialogue that may be Hebrew/emoji/unicode) to its own
# stdout. Declare UTF-8 so the host (and the provider->dispatcher capture is the other half) receives the
# non-ASCII intact rather than '?' from the child's default OEM console codepage. Fail-open; after the kill
# switch so the switch always wins first.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort: a host that rejects UTF-8 console encoding must still run (fail-open)

$script:Banner = '[specrew-refocus]'

function Write-DispatcherWarn {
    param([string]$Code, [string]$Message)
    [Console]::Error.WriteLine(("{0} WARN {1} {2}" -f $script:Banner, $Code, $Message))
}

function Get-DispatcherProjectRoot {
    # Resolve the project root (the dir holding .specrew) so the dispatcher works from ANY host cwd.
    #
    # When THIS dispatcher is the DEPLOYED copy — its own directory is
    # <project>/.specify/extensions/specrew-speckit/scripts — its location reliably identifies the project the
    # hook belongs to, so PREFER walking up from $PSScriptRoot over the cwd. This is the fix for the cwd bug: the
    # host may fire the hook from an unrelated directory whose ancestors contain a STRAY .specrew (e.g.
    # ~/.specrew), which a cwd-first walk-up would wrongly resolve. When it is the in-repo SOURCE copy
    # (scripts/internal, used in dev/tests) the dispatcher's own location is the framework repo rather than the
    # target project, so resolve from the cwd FIRST (the project under test), falling back to $PSScriptRoot.
    $isDeployedCopy = $PSScriptRoot -match '[\\/]\.specify[\\/]extensions[\\/]specrew-speckit[\\/]scripts[\\/]?$'
    $starts = if ($isDeployedCopy) { @($PSScriptRoot, (Get-Location).Path) } else { @((Get-Location).Path, $PSScriptRoot) }
    foreach ($start in $starts) {
        $candidate = $start
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            if (Test-Path -LiteralPath (Join-Path $candidate '.specrew') -PathType Container) { return $candidate }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    return $null
}

function Get-SanitizedSessionId {
    param([AllowNull()][string]$RawSessionId)
    # Security control (lens 5): the session id becomes part of a FILENAME — strip
    # everything outside [a-zA-Z0-9-] so a hostile id cannot traverse paths.
    if ([string]::IsNullOrWhiteSpace($RawSessionId)) { return 'unknown' }
    $clean = ($RawSessionId -replace '[^a-zA-Z0-9-]', '')
    if ([string]::IsNullOrWhiteSpace($clean)) { return 'unknown' }
    return $clean
}

function Get-DispatcherCatalog {
    param([string]$ProjectRoot)
    foreach ($path in @(
            (Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/refocus-scopes.json'),
            (Join-Path $ProjectRoot 'extensions/specrew-speckit/refocus-scopes.json')
        )) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try { return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) }
        catch {
            Write-DispatcherWarn -Code 'CATALOG_SCHEMA' -Message ("catalog unreadable at {0}; automation quiet this event" -f $path)
            return $null
        }
    }
    return $null
}

function Resolve-ProviderCommandPath {
    param([string]$ProjectRoot, [string]$Command)
    # Security control (lens 5 / FR-004): provider commands MUST resolve under the
    # project's deployed extension tree — an out-of-tree command is refused.
    $deployedDir = Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/scripts'
    $candidate = Join-Path $deployedDir (Split-Path -Leaf $Command)
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    # Self-host fallback: the Specrew repo's own internal scripts dir.
    $selfHost = Join-Path $ProjectRoot 'scripts/internal'
    $candidate = Join-Path $selfHost (Split-Path -Leaf $Command)
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    return $null
}

function Invoke-ProviderProcess {
    param(
        [string]$CommandPath,
        [string[]]$CommandArgs,
        [string]$WorkingDirectory,
        [int]$TimeoutSeconds
    )
    # Child process: provider scripts use `exit` (their CLI contract), which would terminate an in-process
    # caller. Timeout enforced per provider (C3).
    #
    # ARG DELIVERY (F-174 iter-10 fix): use ProcessStartInfo.ArgumentList, NOT `Start-Process -ArgumentList`.
    # Start-Process joins the array into one command line WITHOUT robustly quoting elements that contain
    # spaces - empirically a transcript_path under a spaced home (`C:\Users\First Last\...`, the common Windows
    # case) is SPLIT into several args, and any embedded-quote/space value (the --event-json JSON) is mangled.
    # ArgumentList applies correct per-arg Win32 escaping, so every clean arg (notably --transcript-path) and
    # the JSON survive byte-for-byte. stdout/stderr are read ASYNCHRONOUSLY (started before WaitForExit) to
    # avoid a full-pipe deadlock when a provider emits more than a pipe buffer.
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    foreach ($a in @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $CommandPath)) { $psi.ArgumentList.Add([string]$a) }
    foreach ($a in @($CommandArgs)) { $psi.ArgumentList.Add([string]$a) }
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    try {
        $null = $proc.Start()
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()
        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            try { $proc.Kill($true) } catch { $null = $_ }  # already exited (the goal) or unkillable; we abandon it on timeout regardless
            return @{ TimedOut = $true; ExitCode = -1; StdOut = ''; StdErr = ''; LaunchFailed = $false }
        }
        # Drain the async readers, BOUNDED: after the process exits its pipes normally close and the reads
        # settle at once (~0ms). But a provider that leaves a GRANDCHILD holding the stdout handle open can keep
        # the pipe alive, so a bare GetResult() could hang the hook indefinitely. Cap the post-exit drain; on a
        # miss take whatever arrived (fail-open) + one loud WARN (the degrade-to-silence-but-WARN doctrine), so
        # a stuck stream is diagnosable instead of silently empty.
        $drainMs = 5000
        $drained = $false
        try { $drained = [System.Threading.Tasks.Task]::WaitAll(@($outTask, $errTask), $drainMs) } catch { $drained = $false }
        $stdout = if ($outTask.IsCompletedSuccessfully) { $outTask.Result } else { '' }
        $stderr = if ($errTask.IsCompletedSuccessfully) { $errTask.Result } else { '' }
        if (-not $drained) {
            Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("provider '{0}' exited but its output stream stayed open >{1}ms (a lingering child?); using partial output" -f (Split-Path -Leaf $CommandPath), $drainMs)
        }
        return @{
            TimedOut     = $false
            ExitCode     = $proc.ExitCode
            StdOut       = ($stdout ?? '')
            StdErr       = ($stderr ?? '')
            LaunchFailed = $false
        }
    }
    catch {
        # CONTAIN a per-provider LAUNCH failure (Prop-145 round-4): a too-long command line (Windows passes the
        # full argv as one ~32KB-capped string; a large --event-json can exceed it) makes Process.Start() throw
        # "The filename or extension is too long". Without this catch the exception propagates to the dispatcher's
        # outer catch and ABORTS the whole event - every later provider for that event is skipped too. Degrade to a
        # failed result for THIS provider only; the CALLER emits the single WARN (LaunchFailed -> "failed to launch"),
        # so a launch failure is reported once, not twice.
        return @{ TimedOut = $false; ExitCode = -1; StdOut = ''; StdErr = [string]$_.Exception.Message; LaunchFailed = $true }
    }
    finally {
        $proc.Dispose()
    }
}

# ---------------------------------------------------------------------------
# Per-session runtime state (FR-009/FR-010 surface; T007 state-diff + dedupe).
# State files live under .specrew/runtime/ (gitignored), keyed by the SANITIZED
# host session id. Absent state = fresh session (anchor, don't inject); corrupt
# state = STATE_UNAVAILABLE (no safe dedupe -> no automatic injection).
# ---------------------------------------------------------------------------

function Get-SessionStatePath {
    param([string]$ProjectRoot, [string]$SessionId)
    return (Join-Path $ProjectRoot ('.specrew/runtime/refocus-state-{0}.json' -f $SessionId))
}

function Read-SessionState {
    param([string]$Path)
    # Returns @{ Exists; Corrupt; State }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return @{ Exists = $false; Corrupt = $false; State = $null }
    }
    try {
        $state = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        return @{ Exists = $true; Corrupt = $false; State = $state }
    }
    catch {
        return @{ Exists = $true; Corrupt = $true; State = $null }
    }
}

function Save-SessionState {
    param([string]$Path, $State)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, ($State | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

function New-SessionState {
    param([string]$SessionId)
    return [pscustomobject]@{
        session_id         = $SessionId
        last_seen_boundary = $null
        context_mtime      = $null
        breaker            = $null
        journal            = @()
    }
}

function Get-BoundaryCursor {
    param([string]$ProjectRoot)
    # Returns @{ Cursor; MTime } from start-context.json (the state truth B3 watches).
    $path = Join-Path $ProjectRoot '.specrew/start-context.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $mtime = (Get-Item -LiteralPath $path).LastWriteTimeUtc.ToString('o')
    try {
        $ctx = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        $cursor = $null
        if ($ctx.PSObject.Properties['session_state'] -and $null -ne $ctx.session_state -and $ctx.session_state.PSObject.Properties['boundary_type']) {
            $cursor = [string]$ctx.session_state.boundary_type
        }
        return @{ Cursor = $cursor; MTime = $mtime }
    }
    catch { return $null }
}

function Get-ChannelOneFingerprint {
    param([string]$ProjectRoot)
    $path = Join-Path $ProjectRoot '.specrew/runtime/refocus-channel1.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) }
    catch { return $null }
}

function Test-B3ShouldInject {
    # The B3 decision (FR-009): watch the STATE (boundary cursor), never the actor.
    # Returns @{ Action = 'inject' | 'silent' | 'dedupe'; State } with State already
    # updated (caller saves). Cheap-guard: when start-context.json's mtime matches
    # the last recorded check, exit without even parsing it.
    param([string]$ProjectRoot, $SessionState)

    $cursorInfo = Get-BoundaryCursor -ProjectRoot $ProjectRoot
    if ($null -eq $cursorInfo -or [string]::IsNullOrWhiteSpace($cursorInfo.Cursor)) {
        return @{ Action = 'silent'; State = $SessionState }
    }

    $lastMtime = if ($SessionState.PSObject.Properties['context_mtime']) { [string]$SessionState.context_mtime } else { $null }
    $lastSeen = if ($SessionState.PSObject.Properties['last_seen_boundary']) { [string]$SessionState.last_seen_boundary } else { $null }

    # First sight in this session: ANCHOR, never inject — otherwise the first
    # PostToolUse after deploy/install would fire a spurious "crossing".
    if ([string]::IsNullOrWhiteSpace($lastSeen)) {
        $SessionState.last_seen_boundary = $cursorInfo.Cursor
        $SessionState.context_mtime = $cursorInfo.MTime
        return @{ Action = 'anchor'; State = $SessionState }
    }

    # Cheap guard: nothing changed on disk since the last check.
    if ($lastMtime -eq $cursorInfo.MTime) {
        return @{ Action = 'silent'; State = $SessionState }
    }

    if ($lastSeen -eq $cursorInfo.Cursor) {
        # File touched but cursor unchanged (other start-context churn).
        $SessionState.context_mtime = $cursorInfo.MTime
        return @{ Action = 'silent'; State = $SessionState }
    }

    # Real crossing. Was it already delivered in-band by the wrapper (channel 1)?
    $SessionState.last_seen_boundary = $cursorInfo.Cursor
    $SessionState.context_mtime = $cursorInfo.MTime
    $fingerprint = Get-ChannelOneFingerprint -ProjectRoot $ProjectRoot
    if ($null -ne $fingerprint -and $fingerprint.PSObject.Properties['boundary'] -and ([string]$fingerprint.boundary -eq $cursorInfo.Cursor)) {
        return @{ Action = 'dedupe'; State = $SessionState }
    }
    return @{ Action = 'inject'; State = $SessionState }
}

function Add-JournalEntry {
    # Bounded injection journal (FR-010): the post-hoc evidence that survives
    # compaction. Ring of 20; --status prints the tail; beta validation cites it.
    param($State, [string]$Trigger, [string]$Scope, [string]$Channel, [int]$Tokens, [string]$Outcome)
    $entry = [pscustomobject]@{
        at      = (Get-Date).ToUniversalTime().ToString('o')
        trigger = $Trigger
        scope   = $Scope
        channel = $Channel
        tokens  = $Tokens
        outcome = $Outcome
    }
    $journal = @(if ($State.PSObject.Properties['journal'] -and $null -ne $State.journal) { @($State.journal) } else { @() })
    $journal += $entry
    if ($journal.Count -gt 20) { $journal = @($journal | Select-Object -Last 20) }
    $State.journal = $journal
    return $State
}

function Get-BannerFacts {
    # Parse scope + token estimate from the engine's banner (line 1 of payload).
    param([AllowEmptyString()][string]$Payload)
    $firstLine = ($Payload -split "`r?`n")[0]
    $match = [regex]::Match($firstLine, '\[specrew-refocus\] trigger=\S+ scope=(?<scope>\S+) sources=\d+ tokens~(?<tokens>\d+)')
    if ($match.Success) {
        return @{ Scope = $match.Groups['scope'].Value; Tokens = [int]$match.Groups['tokens'].Value }
    }
    return @{ Scope = 'unknown'; Tokens = [int][math]::Ceiling($Payload.Length / 4.0) }
}

function Remove-StaleSessionState {
    # Opportunistic pruning (FR-010): per-session files older than ~7 days swept
    # at dispatcher start. Cheap (one dir listing); failures never matter.
    param([string]$ProjectRoot)
    try {
        $runtimeDir = Join-Path $ProjectRoot '.specrew/runtime'
        if (-not (Test-Path -LiteralPath $runtimeDir -PathType Container)) { return }
        $cutoff = (Get-Date).AddDays(-7)
        foreach ($file in @(Get-ChildItem -LiteralPath $runtimeDir -Filter 'refocus-state-*.json' -File -ErrorAction SilentlyContinue)) {
            if ($file.LastWriteTime -lt $cutoff) {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch { $null = $_ }  # opportunistic GC of stale state files; a cleanup failure must never block the dispatch
}

# ---------------------------------------------------------------------------
# Circuit breaker (FR-011; T009). Per-session, dispatcher path ONLY — the slash
# command and channel-1 wrapper emission are constitutionally exempt. Trips are
# loud ONCE (the trip WARN teaches the manual switches), then silent for the
# rest of the session; new sessions start clean; --reset-breaker clears.
# ---------------------------------------------------------------------------

$script:BreakerRunawayCount = 3      # same trigger injected >= N times ...
$script:BreakerRunawayWindow = 10    # ... within the last N journal entries
$script:BreakerTokenCap = 15000     # total injected tokens per session

function Test-BreakerSuppressed {
    param($State, [string]$Trigger)
    if ($null -eq $State -or -not $State.PSObject.Properties['breaker'] -or $null -eq $State.breaker) { return $false }
    $breaker = $State.breaker
    if (-not ($breaker.PSObject.Properties['tripped'] -and [bool]$breaker.tripped)) { return $false }
    $scopes = @(if ($breaker.PSObject.Properties['scopes'] -and $null -ne $breaker.scopes) { @($breaker.scopes) } else { @('all') })
    return (($scopes -contains 'all') -or ($scopes -contains $Trigger))
}

function Test-BreakerShouldTrip {
    # Returns $null (healthy) or @{ Scopes; Reason }.
    param($State, [string]$Trigger)
    $journal = @(if ($null -ne $State -and $State.PSObject.Properties['journal'] -and $null -ne $State.journal) { @($State.journal) } else { @() })
    if ($journal.Count -eq 0) { return $null }

    # Session token runaway -> trip ALL hook triggers (budget is global).
    $totalTokens = 0
    foreach ($entry in $journal) {
        if ($entry.PSObject.Properties['tokens']) { $totalTokens += [int]$entry.tokens }
    }
    if ($totalTokens -ge $script:BreakerTokenCap) {
        return @{ Scopes = @('all'); Reason = ("session injected ~{0} tokens (cap {1})" -f $totalTokens, $script:BreakerTokenCap) }
    }

    # Repeat-injection runaway -> trip ONLY this trigger (healthy B3 fires once
    # per crossing; repeats inside a short window mean dedupe is broken).
    $recent = @($journal | Select-Object -Last $script:BreakerRunawayWindow)
    $fires = @($recent | Where-Object { [string]$_.trigger -eq $Trigger -and ([string]$_.outcome -in @('injected', 'budget-clipped')) }).Count
    if ($fires -ge $script:BreakerRunawayCount) {
        return @{ Scopes = @($Trigger); Reason = ("trigger '{0}' fired {1} times within the last {2} events (repeat-injection runaway)" -f $Trigger, $fires, $script:BreakerRunawayWindow) }
    }
    return $null
}

function Set-BreakerTripped {
    # Trips LOUDLY ONCE: the WARN names the reason + every re-enable path — the
    # incident is the documentation delivery (lens-6 decision).
    param($State, [string[]]$Scopes, [string]$Reason)
    $State.breaker = [pscustomobject]@{
        tripped = $true
        scopes  = $Scopes
        reason  = $Reason
        at      = (Get-Date).ToUniversalTime().ToString('o')
    }
    Write-DispatcherWarn -Code 'BREAKER_TRIPPED' -Message ("auto-disabled {0} for this session ({1}). Manual /specrew-refocus still works. Re-enable: refocus.ps1 --reset-breaker, or start a new session. Persistent problem? Disable durably: refocus-scopes.json triggers.<id>.enabled=false" -f ($Scopes -join '+'), $Reason)
    return $State
}

function Get-RefocusProviderArgs {
    param([string]$EventName, [AllowNull()][string]$Source)
    # RefocusProvider routing (FR-009 surface; B3 state-diff lands in T007):
    #   SessionStart source: compact            -> B1 (general + current stage)
    #   SessionStart source: startup|resume|clear -> B2 (launch grounding)
    #   PostToolUse                              -> B3 (boundary-cross; T007 gates
    #                                               this behind the state-diff)
    switch ($EventName) {
        'SessionStart' {
            if ($Source -eq 'compact') { return @('--trigger', 'b1') }
            return @('--trigger', 'b2')
        }
        'PostToolUse' { return @('--trigger', 'b3') }
        'UserPromptSubmit' { return @('--trigger', 'b3') }   # the per-human-prompt B3 carrier (T013 latency analysis)
        default { return $null }
    }
}

function Write-InjectionOutput {
    param([string]$EventName, [string]$Payload, [string]$TargetHost = 'claude')
    # Per-host event output shaping (C2; contracts per the T013 research matrix,
    # all fetched live 2026-06-07):
    #   claude  : SessionStart -> plain stdout (added to context);
    #             PostToolUse / UserPromptSubmit -> hookSpecificOutput.additionalContext
    #   codex   : hookSpecificOutput.additionalContext (WITH hookEventName). The flat { additionalContext }
    #             form (which copilot accepts) is silently IGNORED by codex - the hook runs but its output
    #             never reaches the agent (2026-06-10 dogfood: journal written, but no context injected).
    #             Per developers.openai.com/codex/hooks the SessionStart output schema is hookSpecificOutput.
    #   copilot : additionalContext JSON (camelCase reference contract)
    #   cursor  : additional_context JSON (snake_case official contract)
    switch ($TargetHost) {
        'codex' {
            @{ hookSpecificOutput = @{ hookEventName = $EventName; additionalContext = $Payload } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
        }
        'copilot' {
            @{ additionalContext = $Payload } | ConvertTo-Json -Depth 3 -Compress | Write-Output
        }
        'cursor' {
            @{ additional_context = $Payload } | ConvertTo-Json -Depth 3 -Compress | Write-Output
        }
        default {
            if ($EventName -in @('PostToolUse', 'UserPromptSubmit')) {
                @{ hookSpecificOutput = @{ hookEventName = $EventName; additionalContext = $Payload } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
            }
            else {
                Write-Output $Payload
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Main — every failure path inside this try lands on exit 0 (P1).
# ---------------------------------------------------------------------------
try {
    # Self-gate: a stray hook firing outside a Specrew project is a silent no-op.
    $projectRoot = Get-DispatcherProjectRoot
    if ($null -eq $projectRoot) { exit 0 }

    # Host event JSON: -EventJson (tests/bindings) or stdin (Claude hooks).
    $rawEvent = $EventJson
    if ([string]::IsNullOrWhiteSpace($rawEvent) -and -not [Console]::IsInputRedirected) { $rawEvent = '' }
    elseif ([string]::IsNullOrWhiteSpace($rawEvent)) { $rawEvent = [Console]::In.ReadToEnd() }

    $hostEvent = $null
    if (-not [string]::IsNullOrWhiteSpace($rawEvent)) {
        try { $hostEvent = $rawEvent | ConvertFrom-Json }
        catch {
            Write-DispatcherWarn -Code 'EVENT_PARSE' -Message ("host event JSON unreadable for {0}; automation quiet this event (host surface changed? see the research matrix)" -f $Event)
            exit 0
        }
    }

    # Session-id field varies per host contract: session_id (Claude/Codex),
    # sessionId (Copilot camelCase), conversation_id (Cursor).
    $rawSessionId = $null
    if ($null -ne $hostEvent) {
        foreach ($idKey in @('session_id', 'sessionId', 'conversation_id')) {
            if ($hostEvent.PSObject.Properties[$idKey] -and -not [string]::IsNullOrWhiteSpace([string]$hostEvent.$idKey)) {
                $rawSessionId = [string]$hostEvent.$idKey
                break
            }
        }
    }
    $sessionId = Get-SanitizedSessionId -RawSessionId $rawSessionId
    $source = if ($null -ne $hostEvent -and $hostEvent.PSObject.Properties['source']) { [string]$hostEvent.source } else { $null }

    $catalog = Get-DispatcherCatalog -ProjectRoot $projectRoot
    if ($null -eq $catalog -or -not $catalog.PSObject.Properties['providers']) { exit 0 }

    Remove-StaleSessionState -ProjectRoot $projectRoot

    # Per-session runtime state (T007/T008): absent = fresh; corrupt = no safe dedupe.
    $sessionStatePath = Get-SessionStatePath -ProjectRoot $projectRoot -SessionId $sessionId
    $stateRead = Read-SessionState -Path $sessionStatePath
    $stateCorrupt = [bool]$stateRead.Corrupt
    $sessionState = $null
    if ($stateRead.Exists -and -not $stateRead.Corrupt) {
        $sessionState = $stateRead.State
        # Schema tolerance: older/foreign state files gain missing properties.
        foreach ($prop in @('last_seen_boundary', 'context_mtime', 'breaker', 'journal')) {
            if (-not $sessionState.PSObject.Properties[$prop]) {
                $sessionState | Add-Member -NotePropertyName $prop -NotePropertyValue $(if ($prop -eq 'journal') { @() } else { $null })
            }
        }
    }
    elseif (-not $stateRead.Exists) {
        $sessionState = New-SessionState -SessionId $sessionId
    }
    $stateDirty = $false
    # The refocus trigger this event maps to (journal attribution).
    $eventTrigger = if ($Event -in @('PostToolUse', 'UserPromptSubmit')) { 'b3' } elseif ($source -eq 'compact') { 'b1' } else { 'b2' }

    # Providers for THIS event, deterministic order (the host runs parallel hooks
    # unordered; Specrew owns ordering internally — the lens-2 dispatcher decision).
    $providers = @($catalog.providers | Where-Object { @($_.events) -contains $Event } | Sort-Object { [int]$_.order })

    $fragments = New-Object System.Collections.Generic.List[string]
    foreach ($provider in $providers) {
        $kind = if ($provider.PSObject.Properties['kind']) { [string]$provider.kind } else { 'inject' }
        $providerId = [string]$provider.id

        $commandPath = Resolve-ProviderCommandPath -ProjectRoot $projectRoot -Command ([string]$provider.command)
        if ($null -eq $commandPath) {
            Write-DispatcherWarn -Code 'SOURCE_CONFINED' -Message ("provider '{0}' command does not resolve under the deployed tree; skipped" -f $providerId)
            continue
        }

        if ($kind -eq 'gate') {
            # DORMANT F-165 seat (FR-008 forward-compat): gate providers run on
            # PreToolUse, receive tool_input, return allow/deny permissionDecision.
            # No gate provider ships in F-171; this path is fixture-tested only.
            if ($Event -ne 'PreToolUse') { continue }
            $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs @('--gate') -WorkingDirectory $projectRoot -TimeoutSeconds $ProviderTimeoutSeconds
            if ($result.TimedOut -or $result.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($result.StdOut)) {
                # Gates fail OPEN to allow — a broken gate never blocks a session.
                Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("gate provider '{0}' failed; failing OPEN to allow" -f $providerId)
                @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; permissionDecisionReason = "specrew gate provider '$providerId' failed open" } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
                continue
            }
            Write-Output $result.StdOut.Trim()
            continue
        }

        # inject providers (refocus is registry row #1; future rows — e.g. 130-P4
        # handover — ride the same path with event JSON on their own contract).
        $commandArgs = $null
        if ($providerId -eq 'refocus') {
            # Corrupt state = no safe dedupe = no safe AUTOMATION at all (FR-011
            # state-unavailability condition applies to every hook trigger; the
            # manual surface and channel 1 are constitutionally unaffected).
            if ($stateCorrupt) {
                Write-DispatcherWarn -Code 'STATE_UNAVAILABLE' -Message 'session state unreadable; hook automation quiet (manual /specrew-refocus and channel 1 unaffected); repair: refocus.ps1 --reset-breaker or delete the session state file'
                continue
            }
            # B3 gating (T007, FR-009): watch the boundary cursor, dedupe against
            # the channel-1 fingerprint, anchor on first sight.
            if ($Event -in @('PostToolUse', 'UserPromptSubmit')) {
                $b3 = Test-B3ShouldInject -ProjectRoot $projectRoot -SessionState $sessionState
                $sessionState = $b3.State
                $stateDirty = $true
                if ($b3.Action -eq 'dedupe') {
                    $sessionState = Add-JournalEntry -State $sessionState -Trigger 'b3' -Scope 'general+boundary.next' -Channel 'hook' -Tokens 0 -Outcome 'deduped'
                }
                if ($b3.Action -ne 'inject') { continue }
            }
            # Circuit breaker (T009): suppression is SILENT (the trip already
            # warned once); a fresh violation trips loudly here.
            if (Test-BreakerSuppressed -State $sessionState -Trigger $eventTrigger) {
                $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope 'suppressed' -Channel 'hook' -Tokens 0 -Outcome 'breaker-suppressed'
                $stateDirty = $true
                continue
            }
            $trip = Test-BreakerShouldTrip -State $sessionState -Trigger $eventTrigger
            if ($null -ne $trip) {
                $sessionState = Set-BreakerTripped -State $sessionState -Scopes $trip.Scopes -Reason $trip.Reason
                $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope 'suppressed' -Channel 'hook' -Tokens 0 -Outcome 'breaker-suppressed'
                $stateDirty = $true
                continue
            }
            $commandArgs = Get-RefocusProviderArgs -EventName $Event -Source $source
        }
        else {
            # Pass the resolved host so the provider can shape host-aware delivery (F-174 codex fix: codex
            # drops the oversized SessionStart additionalContext, so the provider hands codex a lean pointer).
            # Also pass the neutral event name as its own CLEAN arg (--source-event): a provider that wants the
            # event name (the F-174 handover, to label its trigger source) reads it directly instead of digging
            # the field out of the full --event-json blob. (Historically this also dodged Start-Process
            # -ArgumentList arg-mangling; the launch primitive is now ProcessStartInfo.ArgumentList which escapes
            # every arg correctly, but the dedicated arg stays - it is clearer and decouples providers from the
            # host's JSON shape.) Both are harmless to inject providers that do not read them.
            # Prop-145 round-4 (HIGH): the handover provider reads ONLY the clean args (--source-event for the
            # trigger, --host-kind, --transcript-path) - it does NOT need the full event JSON. Codex's Stop event
            # carries a `last_assistant_message` that can be 10s of KB; as --event-json that blows the Windows
            # command-line length limit, ProcessStartInfo refuses to launch, and the handover (so the conversation
            # capture) silently never runs. Pass only the bounded clean args to handover. The transcript FILE route
            # (--transcript-path, extracted below) is the robust primary; tier-3 (last_assistant_message) stays
            # DEFERRED. Other inject providers (bootstrap needs session_id/source) still get --event-json.
            $commandArgs = if ($providerId -eq 'handover') {
                @('--host-kind', $HostKind, '--source-event', $Event)
            }
            else {
                @('--event-json', ($rawEvent ?? ''), '--host-kind', $HostKind, '--source-event', $Event)
            }
            # F-174 iter-10 (T002): also extract the conversation transcript_path from the INTACT stdin event and
            # pass it as its own CLEAN arg, so the handover provider captures the conversation tail without
            # re-parsing the event JSON. Field name varies (snake/camel); harmless to providers that ignore the
            # arg. (Invoke-ProviderProcess delivers it via ProcessStartInfo.ArgumentList, so a path with spaces
            # survives byte-for-byte - the spaced-home bug this fixed.) Fail-open.
            if (-not [string]::IsNullOrWhiteSpace($rawEvent)) {
                try {
                    $evtObj = $rawEvent | ConvertFrom-Json -ErrorAction Stop
                    $tpath = $null
                    foreach ($k in @('transcript_path', 'transcriptPath')) {
                        $pp = $evtObj.PSObject.Properties[$k]
                        if ($pp -and -not [string]::IsNullOrWhiteSpace([string]$pp.Value)) { $tpath = [string]$pp.Value; break }
                    }
                    if (-not [string]::IsNullOrWhiteSpace($tpath)) { $commandArgs += @('--transcript-path', $tpath) }
                }
                catch { $null = $_ }
            }
        }
        if ($null -eq $commandArgs) { continue }

        $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs $commandArgs -WorkingDirectory $projectRoot -TimeoutSeconds $ProviderTimeoutSeconds
        if ($result.TimedOut -or $result.ExitCode -ne 0) {
            $why = if ($result.TimedOut) { 'timed out' }
            elseif ($result.LaunchFailed) { "failed to launch: $($result.StdErr)" }
            else { "exited $($result.ExitCode)" }
            Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("provider '{0}' {1}; skipped" -f $providerId, $why)
            if ($providerId -eq 'refocus' -and $null -ne $sessionState -and -not $stateCorrupt) {
                $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope 'unknown' -Channel 'hook' -Tokens 0 -Outcome 'failed'
                $stateDirty = $true
            }
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdOut)) {
            $fragments.Add($result.StdOut.Trim()) | Out-Null
            if ($providerId -eq 'refocus' -and $null -ne $sessionState -and -not $stateCorrupt) {
                $facts = Get-BannerFacts -Payload $result.StdOut
                $outcome = if ($result.StdErr -match 'WARN BUDGET_EXCEEDED') { 'budget-clipped' } else { 'injected' }
                $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope $facts.Scope -Channel 'hook' -Tokens $facts.Tokens -Outcome $outcome
                $stateDirty = $true
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdErr)) {
            # Provider WARNs pass through once (visible, attributable).
            [Console]::Error.Write($result.StdErr)
        }
    }

    if ($null -ne $sessionState -and -not $stateCorrupt -and $stateDirty) {
        Save-SessionState -Path $sessionStatePath -State $sessionState
    }

    if ($fragments.Count -gt 0) {
        Write-InjectionOutput -EventName $Event -Payload (($fragments -join "`n`n")) -TargetHost $HostKind
    }
    exit 0
}
catch {
    Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("dispatcher fail-open: {0}" -f $_.Exception.Message)
    exit 0
}
