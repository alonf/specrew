# Feature 185 FR-011 / FR-015 / FR-004 / FR-005 - the conformance Stop-provider (DETECTION + BLOCK delivery).
#
# This is a CONSUMER of the EXISTING hook dispatcher + provider catalog (refocus-scopes.json), registered
# as kind=inject events=[Stop] order=40 - it runs AFTER the handover provider (order 30) has done the
# verdict capture (which advances last_authorized_boundary via the authorization writer on a captured marker).
# It is an isolated script the dispatcher invokes; it does NOT edit HandoverStore.ps1 and NEVER calls the
# verdict-authority write path - it is a strictly READ-ONLY consumer of the gate STATE, so it physically
# cannot break what keeps the lifecycle honest. Its only writes are best-effort diagnostics under
# .specrew/runtime/ (the conformance journal + the stop-block loop-guard counter), never gate state.
#
# ARG CONTRACT: the dispatcher invokes inject providers with DOUBLE-dash flags (--host-kind, --source-event,
# --transcript-path) via ProcessStartInfo.ArgumentList. PowerShell's single-dash `param()` binding REJECTS
# a `--flag` token (it reads as `-flag`), so a `param()`/[CmdletBinding()] block makes the script exit 1 at
# the binding boundary BEFORE its body runs. So parse $args MANUALLY (the handover provider's convention). NO param().
#
# DELIVERY = BLOCK AT THE STOP (FR-015 maintainer ruling 2026-06-20): the 6-section re-entry packet must render
# AT the stop, not as a too-late next-turn nudge - a packet-less stop already leaves the human puzzled. So when a
# stop owes the packet and it is absent, this provider emits a BLOCK SENTINEL (`<<<SPECREW-STOP-BLOCK>>>` + the
# directive); the dispatcher translates it into the host's stop-block envelope (verified capability matrix,
# research/stop-block-capability-matrix.md: claude/codex/copilot decision:block, antigravity decision:continue,
# cursor followup_message), force-continuing the turn so the agent renders the packet before control returns.
#
# WHAT OWES THE PACKET (block triggers; only a proved current workshop question is intermediate):
#   - BOUNDARY stop: HasPendingVerdict (working boundary ahead of last-authorized, no captured verdict - the #2884
#     silent advance). REUSES the canonical Get-SpecrewPendingVerdictState (FR-008; not a parallel inference engine).
#     The block directive carries the CONTIGUOUS last_authorized -> successor verdict marker (145 F2).
#   - MATERIAL non-boundary stop: the live owner-scoped turn delta reports changed user files or new commits after
#     a genuine UserPromptSubmit/PreInvocation baseline. SessionStart is the live-refreshed degraded fallback, so
#     a read-only consultation over files an earlier session left dirty owes nothing and a missing prompt event
#     never fabricates "this turn" ownership. The last assistant message must carry the five-part context packet.
#     A LONG read-only investigation (>= the assistant-entry threshold since the last human message) owes
#     the packet too - the re-entry cost is the turn itself. A PostToolUse tracked-change fires a ONE-PER-SURFACE
#     pre-arrangement nudge so the packet lands IN the original response instead of a forced duplicate turn.
#   FALSE-POSITIVE GUARD: if the last assistant message already surfaced the exact pending boundary crossing (the
#   marker the capture path would accept) -> no block.
#
# #1 INTAKE QUESTION (asking "what to build" while a spec exists) and #3 RAW `specify[.exe] workflow`: cooperative
#   redirects, folded into the block directive when a block fires, else emitted as a plain inject nudge.
#
# LOOP GUARD (never hang a session): claude/codex have a built-in stop_hook_active cap (the dispatcher also
#   honours it - it does NOT block when already continuing). copilot/antigravity have none, so this provider keeps
#   its OWN consecutive-block counter (.specrew/runtime/conformance-stop-block.json), capped at $BLOCK_CAP within a
#   short window; over the cap -> stop blocking, degrade to a plain nudge, never trap. Reset when the packet appears.
#
# HONEST CEILINGS: (1) cursor cannot hard-block (followup_message re-triggers a NEW turn - the human may glimpse the
#   packet-less stop); declared best-effort. (2) capability != firing reliability - codex Stop does not fire on an
#   Esc-interrupted turn / headless exec (a real-host dogfood concern). (3) DETECTION SCOPE: boundary enforcement
#   keys off gate state; material-work enforcement keys off the current rolling-handover Stop snapshot. If either
#   signal is unavailable, the provider fails open. (4) a workshop pause is intermediate only when its exact
#   feature-level intake OR feature/iteration design-analysis scope, current-lens state, and visible pending
#   question validate; lifecycle boundary state always wins.
#   Fully FAIL-OPEN: any error / uncertainty
#   degrades to NO block (allow the stop) - blocking is the narrow exception, never the default.

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort UTF-8 (child half of the dispatcher's encoding contract)

$script:SpecrewReentryHeaders = @('What I Just Did', 'Why I Stopped', 'What Needs Your Review', 'What Happens Next', 'Discussion Prompts', 'What I Need From You')
$script:SpecrewBlockCap = 3
$script:SpecrewFireDedupWindowSec = 60  # idempotency: a duplicate hook fire for the SAME observable state within this window is a no-op.
$script:SpecrewMaterialHandoverMaxAgeSec = 300  # handover provider runs immediately before conformance; older snapshots are stale.
$script:SpecrewMaterialRetryWindowSec = 600  # after a material stop block, keep enforcing only during the forced-continue loop.
$script:SpecrewSubstantialChars = 600
$script:SpecrewContinueLoopGuardBound = 3  # FR-045a: bound on consecutive `continue` classifications for the SAME material surface before the guard trips the classifier to a real stop (a runaway continue can never loop forever).
$script:SpecrewLongTurnAssistantEntries = 15  # maintainer 2026-07-14 fixture (d): a read-only turn with >= this many assistant transcript entries since the last HUMAN message is a LONG investigation and owes the five-part packet (re-entry cost is the turn itself, not the diff).

function Test-SpecrewReentryPacketPresent {
    # >=4 of the 6 canonical section-header phrases present in the (flattened) last assistant message = the packet
    # was rendered. Phrase-based (not '## '-prefixed) so it survives the transcript flattening; >=4 (not all 6)
    # tolerates minor wording drift without letting a bare message through.
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $hits = 0
    foreach ($h in $script:SpecrewReentryHeaders) { if ($Text -match [regex]::Escape($h)) { $hits++ } }
    return ($hits -ge 4)
}

function Get-SpecrewBlockCount {
    # Consecutive-block count for THIS advance ($Key = "<working>|<lastAuth>"). 0 if absent / a DIFFERENT advance /
    # unreadable. Keyed by the advance identity (NOT a time window): the count accumulates across consecutive
    # packet-less stops for the same advance regardless of how long each forced-continue turn takes (145 HANG-1: a
    # time window let a >120s/turn loop reset to 0 forever and never cap). A different advance is a fresh sequence.
    param([string]$Path, [string]$Key)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'count') -and ($rec.PSObject.Properties.Name -contains 'key') -and ([string]$rec.key -eq $Key)) {
                return [int]$rec.count
            }
        }
    }
    catch { $null = $_ }
    return 0
}

function Get-SpecrewBlockRecord {
    param([string]$Path)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'key') -and ($rec.PSObject.Properties.Name -contains 'count')) {
                return $rec
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Set-SpecrewBlockCount {
    # Persist the count for $Key and VERIFY it landed (read-back). Returns $true only when the increment is durably
    # readable - the caller blocks ONLY on $true, so a persistent / non-atomic write failure can never start an
    # uncappable block loop on a host without a built-in cap (145 HANG-2 fail-open).
    param([string]$Path, [string]$Key, [int]$Count)
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ key = $Key; count = $Count; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $back = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($back.PSObject.Properties.Name -contains 'count') -and ([int]$back.count -eq $Count) -and ($back.PSObject.Properties.Name -contains 'key') -and ([string]$back.key -eq $Key)) { return $true }
        }
    }
    catch { $null = $_ }
    return $false
}

function Get-SpecrewCapFactPath {
    # W53: the cap fact lives BESIDE the counter it documents - session-scoped when the counter is,
    # legacy-named at the runtime root otherwise - so "capped for this session" is literally the
    # file's own scope.
    param($Runtime)
    $dir = Split-Path -Parent ([string]$Runtime.BlockPath)
    $legacy = [string]::IsNullOrWhiteSpace([string]$Runtime.Owner)
    return (Join-Path $dir $(if ($legacy) { 'conformance-cap-facts.jsonl' } else { 'cap-facts.jsonl' }))
}

function Test-SpecrewCapFactRecorded {
    param([string]$Path, [string]$Key)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
        foreach ($line in @(Get-Content -LiteralPath $Path -Encoding UTF8)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $rec = $null
            try { $rec = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($null -ne $rec -and ($rec.PSObject.Properties.Name -contains 'advance_key') -and ([string]$rec.advance_key -ceq $Key)) { return $true }
        }
    }
    catch { $null = $_ }
    return $false
}

function Write-SpecrewCapFact {
    # W53: append + read-back verify - the SAME durability rule the block counter follows (145
    # HANG-2). The announcement block fires ONLY when the fact explaining it is durably on disk, so
    # a write failure degrades to the released-silent path rather than adding an unrecorded block.
    param([string]$Path, [pscustomobject]$Fact)
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ($Fact | ConvertTo-Json -Compress) | Add-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
        return (Test-SpecrewCapFactRecorded -Path $Path -Key ([string]$Fact.advance_key))
    }
    catch { $null = $_ }
    return $false
}

function Get-SpecrewRecentMaterialRetryKey {
    param([AllowNull()]$Record)
    try {
        if ($null -eq $Record -or -not ($Record.PSObject.Properties.Name -contains 'key')) { return $null }
        $key = [string]$Record.key
        if ($key -notlike 'material|*') { return $null }
        if (-not ($Record.PSObject.Properties.Name -contains 'epoch')) { return $null }
        $age = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$Record.epoch
        if ($age -ge 0 -and $age -le $script:SpecrewMaterialRetryWindowSec) { return $key }
    }
    catch { $null = $_ }
    return $null
}

function Get-SpecrewMaterialSatisfiedKey {
    param([string]$Path)
    try {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $rec = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if (($rec.PSObject.Properties.Name -contains 'key') -and -not [string]::IsNullOrWhiteSpace([string]$rec.key)) {
                return [string]$rec.key
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Set-SpecrewMaterialSatisfiedKey {
    param([string]$Path, [string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return }
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ key = $Key; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
    }
    catch { $null = $_ }
}

function Get-SpecrewCurrentStopMaterialSignal {
    # Deterministic non-boundary packet trigger. The handover provider (order 30) runs before this conformance
    # provider (order 40) and writes the latest Stop snapshot. Treat it as material ONLY when the current, fresh
    # Stop snapshot's newest activity bullet reports changed user files or new commits. Conversation-only Stop
    # refreshes update recorded_at but do not prepend an activity bullet, so their bullet timestamp will not match.
    # 2026-07-14 (maintainer packet-hardening): -AllowedSources widens the lane (the PostToolUse pre-arrangement
    # nudge reads PostToolUse-captured bullets); -AnySnapshot bypasses the source/freshness gates entirely (the
    # SessionStart BASELINE lane wants the last known surface, however old). The surface KEY is computed for ANY
    # recognized bullet (material or not) and STRIPS the volatile '(+N Specrew-managed)' clause, so managed-count
    # drift alone never reads as a new material surface.
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$BootstrapDir,
        [string[]]$AllowedSources = @('stop', 'agentstop'),
        [switch]$AnySnapshot
    )
    $result = [pscustomobject]@{ material = $false; key = $null; reason = 'no-material-signal'; user_file_count = 0; new_commit_count = 0; active_feature = $null; active_boundary = $null }
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir)) { $result.reason = 'no-bootstrap-dir'; return $result }
        $store = Join-Path $BootstrapDir 'HandoverStore.ps1'
        if (-not (Test-Path -LiteralPath $store -PathType Leaf)) { $result.reason = 'no-handover-store'; return $result }
        if (-not (Get-Command ConvertFrom-SpecrewHandoverFile -ErrorAction SilentlyContinue)) {
            try { . $store } catch { $result.reason = 'handover-store-unloadable'; return $result }
        }
        if (-not (Get-Command ConvertFrom-SpecrewHandoverFile -ErrorAction SilentlyContinue)) { $result.reason = 'handover-parser-unavailable'; return $result }

        $path = Join-Path $ProjectRoot '.specrew/handover/session-handover.md'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $result.reason = 'no-handover'; return $result }
        $handover = ConvertFrom-SpecrewHandoverFile -Path $path
        if ($null -eq $handover) { $result.reason = 'unreadable-handover'; return $result }
        $result.active_feature = [string]$handover.active_feature
        $result.active_boundary = [string]$handover.active_boundary

        $recordedAt = [datetime]::UtcNow
        if (-not $AnySnapshot) {
            $source = [string]$handover.source
            if ([string]::IsNullOrWhiteSpace($source) -or $source.ToLowerInvariant() -notin @($AllowedSources | ForEach-Object { $_.ToLowerInvariant() })) {
                $result.reason = 'not-stop-handover'; return $result
            }

            $recordedRaw = [string]$handover.recorded_at
            if ([string]::IsNullOrWhiteSpace($recordedRaw)) { $result.reason = 'missing-recorded-at'; return $result }
            $recordedAt = [datetime]::Parse($recordedRaw).ToUniversalTime()
            $age = ([datetime]::UtcNow - $recordedAt).TotalSeconds
            if ($age -lt -30 -or $age -gt $script:SpecrewMaterialHandoverMaxAgeSec) {
                $result.reason = 'stale-handover'; return $result
            }
        }

        $activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
        $activity = if ($handover.sections -and $handover.sections.Contains($activityTitle)) { [string]$handover.sections[$activityTitle] } else { '' }
        if ([string]::IsNullOrWhiteSpace($activity)) { $result.reason = 'no-activity-section'; return $result }
        $bullet = @($activity -split "`r?`n" | Where-Object { $_ -match '^\s*-\s+\[' } | Select-Object -First 1)
        if ($bullet.Count -eq 0) { $result.reason = 'no-activity-bullet'; return $result }

        $bulletText = [string]$bullet[0]
        $rx = [regex]::new('^\s*-\s+\[(?<stamp>[^\]]+)\]\s+\((?<source>[^)]+)\)\s+(?<files>\d+)\s+changed user file\(s\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $m = $rx.Match($bulletText)
        if (-not $m.Success) { $result.reason = 'activity-unrecognized'; return $result }
        if (-not $AnySnapshot) {
            if (($m.Groups['source'].Value).ToLowerInvariant() -notin @($AllowedSources | ForEach-Object { $_.ToLowerInvariant() })) { $result.reason = 'activity-not-stop'; return $result }

            $activityAt = [datetime]::Parse($m.Groups['stamp'].Value).ToUniversalTime()
            if ([math]::Abs(($recordedAt - $activityAt).TotalSeconds) -gt 5) {
                $result.reason = 'activity-not-current-stop'; return $result
            }
        }

        # The stable material-surface KEY: the bullet minus its timestamp/source prefix and minus the VOLATILE
        # '(+N Specrew-managed)' clause (managed scaffolding accumulates independently of user work - its count
        # drifting must never fake a NEW user-material surface). Also strip the TRANSIENT '; N new commit(s): ...'
        # observation: the same HEAD is annotated as new only on its first handover, then loses that suffix on the
        # next conversational Stop. HEAD itself remains in the key, so a genuinely different commit still creates
        # a new material surface. Computed for ANY recognized bullet so the SessionStart baseline and the Stop-lane
        # delta compare like with like.
        $stableMaterialSurface = ($bulletText -replace '^\s*-\s+\[[^\]]+\]\s+\([^)]+\)\s+', '').Trim()
        $stableMaterialSurface = ($stableMaterialSurface -replace '\s*\(\+\d+\s+Specrew-managed\)', '').Trim()
        $stableMaterialSurface = ($stableMaterialSurface -replace ';\s+\d+\s+new commit\(s\):.*$', '').Trim()
        $surfaceHash = Get-SpecrewFireIdentity -Parts @($stableMaterialSurface)
        $result.key = ('material|{0}' -f $surfaceHash)

        $files = [int]$m.Groups['files'].Value
        $commitMatch = [regex]::Match($bulletText, ';\s+(?<commits>\d+)\s+new commit\(s\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $commits = if ($commitMatch.Success -and -not [string]::IsNullOrWhiteSpace($commitMatch.Groups['commits'].Value)) { [int]$commitMatch.Groups['commits'].Value } else { 0 }
        if ($files -le 0 -and $commits -le 0) { $result.reason = 'no-user-files-or-commits'; return $result }

        $result.material = $true
        $result.reason = 'current-stop-material-delta'
        $result.user_file_count = $files
        $result.new_commit_count = $commits
        return $result
    }
    catch {
        $result.reason = 'material-signal-unreadable'
        return $result
    }
}

function Get-SpecrewLongTurnSignal {
    # Maintainer 2026-07-14 fixture (d): a GENUINELY LONG read-only investigation owes the five-part packet even
    # when no file changed - the human's re-entry cost is the turn itself, not the diff. DETERMINISTIC + CHEAP: a
    # raw string scan (NO per-line JSON parse - the T099 perf doctrine) of the transcript tail counts assistant
    # TURNS SINCE the last HUMAN user line (a '"type":"user"' line WITHOUT a '"tool_use_id"' marker - tool
    # results ride user-role lines on Claude-format transcripts).
    #
    # DRIFT-198-I0NN-0NN (2026-08-01, reproduced live in the maintainer's session): raw LINE count over-fired.
    # Claude Code's transcript writer splits ONE logical assistant response into SEVERAL separate
    # "assistant"-typed JSONL records - one per content block (a thinking block, a text block, a tool_use block)
    # - all sharing the SAME top-level `message.id`. Measured directly against this session's own live
    # transcript: consecutive raw assistant lines paired up under one shared `"id":"msg_..."` value. A SINGLE
    # purely conversational reply with ZERO tool calls, split into a thinking block plus a text block, already
    # read as multiple "entries" before any tool ran at all; a short 2-3-call read-only status-poll turn (each
    # call contributing a thinking+tool_use PAIR under its own message id) could cross the threshold the same
    # way a genuinely long, many-STEP investigation was meant to. The count now dedupes by `message.id`, so ONE
    # logical response counts ONCE regardless of how many raw lines the writer split it into - restoring the
    # original intent (count STEPS, not fragments) without changing the threshold or the anchor. A line whose
    # id cannot be extracted (a synthetic/legacy transcript, or an unrecognized shape) still counts on its own -
    # fail toward STILL counting, never toward silently going quiet, matching this function's existing
    # fail-open direction for shapes it does not recognize.
    #
    # Count >= the threshold -> long; with no human line in the window every assistant TURN in the tail counts,
    # so a saturated window reads long by count alone while a short no-human transcript stays quiet. A host whose
    # transcript lines carry neither marker counts 0 and is never long (fail-open - the documented honest
    # ceiling; the material-delta lane still enforces there). The hash keys the enforcement to the LAST HUMAN
    # line, which is STABLE across a forced-continue loop, so consecutive packet-less retries accumulate on ONE
    # loop-guard key and the block cap can trip (never an uncapped loop).
    param([AllowNull()][string]$TranscriptPath)
    $result = [pscustomobject]@{ long = $false; assistant_entries = 0; hash = '' }
    try {
        if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return $result }
        $tail = @(Get-Content -LiteralPath $TranscriptPath -Tail 200 -Encoding UTF8 -ErrorAction Stop)
        $assistantRx = [regex]::new('"type"\s*:\s*"assistant"')
        $userRx = [regex]::new('"type"\s*:\s*"user"')
        $messageIdRx = [regex]::new('"id"\s*:\s*"(msg_[^"]*)"')
        $seenMessageIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $count = 0; $humanLine = $null
        for ($i = $tail.Count - 1; $i -ge 0; $i--) {
            $ln = [string]$tail[$i]
            if ($assistantRx.IsMatch($ln)) {
                $idMatch = $messageIdRx.Match($ln)
                if ($idMatch.Success) { if ($seenMessageIds.Add($idMatch.Groups[1].Value)) { $count++ } }
                else { $count++ }
                continue
            }
            if ($userRx.IsMatch($ln) -and -not $ln.Contains('"tool_use_id"')) { $humanLine = $ln; break }
        }
        $result.assistant_entries = $count
        $result.long = ($count -ge $script:SpecrewLongTurnAssistantEntries)
        $anchor = if ($null -ne $humanLine) { $humanLine } else { 'saturated-no-human-line-in-window' }
        $result.hash = Get-SpecrewFireIdentity -Parts @($anchor)
        return $result
    }
    catch { return $result }
}

function Reset-SpecrewBlockCount {
    param([string]$Path)
    try { if (Test-Path -LiteralPath $Path -PathType Leaf) { Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue } }
    catch { $null = $_ }
}

function Get-SpecrewFireIdentity {
    # A stable identity for THIS Stop fire = a hash of the recent transcript tail + the boundary cursor + the source
    # event. Two fires with the same identity are the SAME observable state (a duplicate hook delivery for the same
    # message); the boundary force-continue loop produces a NEW message each turn -> a different identity.
    param([string[]]$Parts)
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes(($Parts -join '|'))
        return (-join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }))
    }
    catch { return '' }
}

function Get-SpecrewMaterialRuntimeState {
    # Production dispatch supplies a sanitized host session id. Scope every mutable material/loop/dedupe record to
    # that owner so concurrent sessions cannot overwrite one another's baseline or satisfaction state. Direct legacy
    # invocations without a session id retain the historical paths and the conservative enforcement behavior.
    param([string]$ProjectRoot, [AllowNull()][string]$HostKind, [AllowNull()][string]$SessionId)
    $runtimeRoot = Join-Path $ProjectRoot '.specrew/runtime'
    $stateRoot = $runtimeRoot
    $owner = $null
    if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
        $safeHost = if ([string]::IsNullOrWhiteSpace($HostKind)) { 'unknown' } else { (($HostKind -replace '[^a-zA-Z0-9-]+', '-').Trim('-').ToLowerInvariant()) }
        $safeSession = (($SessionId -replace '[^a-zA-Z0-9-]+', '-').Trim('-'))
        if (-not [string]::IsNullOrWhiteSpace($safeSession)) {
            $owner = ('{0}|{1}' -f $safeHost, $safeSession)
            $ownerHash = Get-SpecrewFireIdentity -Parts @($owner)
            if (-not [string]::IsNullOrWhiteSpace($ownerHash)) {
                $stateRoot = Join-Path (Join-Path $runtimeRoot 'conformance-sessions') $ownerHash
            }
            else { $owner = $null }
        }
    }
    $legacy = [string]::IsNullOrWhiteSpace($owner)
    return [pscustomobject]@{
        Owner = $owner
        BaselinePath = Join-Path $stateRoot $(if ($legacy) { 'conformance-turn-baseline.json' } else { 'turn-baseline.json' })
        SatisfiedPath = Join-Path $stateRoot $(if ($legacy) { 'conformance-material-satisfied.json' } else { 'material-satisfied.json' })
        NudgedPath = Join-Path $stateRoot $(if ($legacy) { 'conformance-material-nudged.json' } else { 'material-nudged.json' })
        BlockPath = Join-Path $stateRoot $(if ($legacy) { 'conformance-stop-block.json' } else { 'stop-block.json' })
        ContinueGuardPath = Join-Path $stateRoot $(if ($legacy) { 'conformance-continue-guard.json' } else { 'continue-guard.json' })
        LastFirePath = Join-Path $stateRoot $(if ($legacy) { 'conformance-last-fire.json' } else { 'last-fire.json' })
        # W25: once the human has actually SEEN this session's orientation, the check is over. Every later
        # stop early-exits on this one Test-Path, which is what keeps a first-turn obligation from becoming
        # a per-stop cost (the maintainer's objection to a Stop-side check, 2026-08-18).
        OrientationPath = Join-Path $stateRoot $(if ($legacy) { 'conformance-orientation-rendered.json' } else { 'orientation-rendered.json' })
        AttributionPath = Join-Path $runtimeRoot 'conformance-material-owner.json'
    }
}

function Get-SpecrewMaterialOwnerRecord {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
        $record = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace([string]$record.key) -or [string]::IsNullOrWhiteSpace([string]$record.owner) -or $null -eq $record.epoch) { return $null }
        return $record
    }
    catch { return $null }
}

function Set-SpecrewMaterialOwnerRecord {
    param([string]$Path, [string]$Key, [string]$Owner)
    if ([string]::IsNullOrWhiteSpace($Key) -or [string]::IsNullOrWhiteSpace($Owner)) { return $false }
    $temp = $null
    try {
        $dir = Split-Path -Parent $Path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $temp = $Path + '.tmp-' + [guid]::NewGuid().ToString('N')
        $json = [pscustomobject]@{ key = $Key; owner = $Owner; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($temp, $json, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
        $back = Get-SpecrewMaterialOwnerRecord -Path $Path
        return ($null -ne $back -and [string]$back.key -eq $Key -and [string]$back.owner -eq $Owner)
    }
    catch { return $false }
    finally { if (-not [string]::IsNullOrWhiteSpace($temp) -and (Test-Path -LiteralPath $temp -PathType Leaf)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
}

function Resolve-SpecrewBootstrapDir {
    # The scripts/internal/bootstrap dir (ConversationCaptureAccessor + ProjectMetadataAccessor). Direct candidates
    # (project tree, then SPECREW_MODULE_PATH) FIRST; the Get-Module -ListAvailable scan (slow over OneDrive /
    # multi-version) runs ONLY if they miss. $null if none resolves.
    param([string]$ProjectRoot)
    foreach ($base in @($ProjectRoot, $env:SPECREW_MODULE_PATH)) {
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        $bd = Join-Path $base 'scripts/internal/bootstrap'
        if (Test-Path -LiteralPath (Join-Path $bd 'ConversationCaptureAccessor.ps1') -PathType Leaf) { return $bd }
    }
    try {
        $mod = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1') } | Select-Object -First 1
        if ($mod) { return (Join-Path $mod.ModuleBase 'scripts/internal/bootstrap') }
    }
    catch { $null = $_ }
    return $null
}

function Test-SpecrewWorkshopInProgress {
    # Feature-intake optimization only. The strict lifecycle accessor, not Markdown presence or assistant prose,
    # proves active state. Exact iteration scope is resolved separately by Resolve-SpecrewWorkshopQuestionPause.
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir) -or [string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopLifecycleState -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopLifecycleState -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        if ($null -ne $wp -and [string]$wp.status -eq 'active') { return $true }
    }
    catch { $null = $_ }
    return $false
}

function Test-SpecrewWorkshopComplete {
    # PostToolUse nudge optimization only. Once a workshop is complete, later mutations should receive the normal
    # pre-arrangement nudge even if lifecycle state has not yet advanced. Stop enforcement never relies on this proxy.
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir) -or [string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopLifecycleState -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopLifecycleState -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        return ($null -ne $wp -and [string]$wp.status -eq 'complete')
    }
    catch { $null = $_ }
    return $false
}

function Test-SpecrewUntouchedFeatureSpecScaffold {
    param([string]$ProjectRoot, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $specPath = Join-Path $ProjectRoot ("specs/{0}/spec.md" -f $FeatureRef)
        $templatePath = Join-Path $ProjectRoot '.specify/templates/spec-template.md'
        if (-not (Test-Path -LiteralPath $specPath -PathType Leaf) -or -not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { return $false }
        $specItem = Get-Item -LiteralPath $specPath -ErrorAction Stop
        $templateItem = Get-Item -LiteralPath $templatePath -ErrorAction Stop
        if ($specItem.Length -le 0 -or $specItem.Length -ne $templateItem.Length -or $specItem.Length -gt 1048576) { return $false }
        return ([string](Get-FileHash -LiteralPath $specPath -Algorithm SHA256 -ErrorAction Stop).Hash -ceq
            [string](Get-FileHash -LiteralPath $templatePath -Algorithm SHA256 -ErrorAction Stop).Hash)
    }
    catch { return $false }
}

function Resolve-SpecrewWorkshopQuestionPause {
    # FR-056: controller-owned durable state is the cross-host workshop authority. Model-authored comments and
    # question-tool payloads are intentionally irrelevant: hosts may omit or swallow them. The exact active feature /
    # iteration scope must contain a strictly valid, incomplete lens-applicability.json; completed lenses require the
    # full skill contract plus matching Markdown records. Lifecycle boundary state always wins before this helper,
    # while complete/malformed/ambiguous state restores ordinary Stop behavior.
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$BootstrapDir,
        [AllowNull()][string]$ActiveFeatureRef,
        [AllowNull()][string]$ActiveIterationNumber,
        [bool]$HasActiveLifecycleBoundary,
        [ValidateSet('absent', 'readable', 'unreadable')][string]$StartContextState = 'absent',
        [AllowNull()][string]$LastAssistantText,
        [bool]$HasPendingVerdict
    )
    $result = [pscustomobject]@{ valid = $false; reason = 'workshop-state-unproven'; scope = $null; feature_ref = $null; iteration_number = $null; lens = $null; phase = $null; agenda_status = $null; question = $null; message_hash = $null; agenda_digest = $null; agenda_binding = $null; agenda_visibility = $null; artifact_path = $null; binding_conflict = $null }
    try {
        if ($HasPendingVerdict) { $result.reason = 'lifecycle-boundary-overrides-workshop'; return $result }
        if ([string]::IsNullOrWhiteSpace($ActiveFeatureRef)) { return $result }
        if ($StartContextState -eq 'unreadable') { $result.reason = 'workshop-start-context-unreadable'; return $result }
        if ([string]::IsNullOrWhiteSpace($BootstrapDir)) { $result.reason = 'workshop-accessor-unresolved'; return $result }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { $result.reason = 'workshop-accessor-missing'; return $result }
        try { . $pma } catch { $result.reason = 'workshop-accessor-unreadable'; return $result }
        if (-not (Get-Command Get-SpecrewWorkshopLifecycleState -ErrorAction SilentlyContinue)) { $result.reason = 'workshop-accessor-contract-missing'; return $result }

        $scope = 'feature'
        $iteration = $null
        $featureRoot = Join-Path $ProjectRoot ("specs/{0}" -f $ActiveFeatureRef)
        if ($HasActiveLifecycleBoundary -or -not [string]::IsNullOrWhiteSpace($ActiveIterationNumber)) {
            if ([string]::IsNullOrWhiteSpace($ActiveIterationNumber)) { $result.reason = 'workshop-active-iteration-missing'; return $result }
            $scope = 'iteration'
            $iteration = $ActiveIterationNumber
        }
        else {
            $iterationsRoot = Join-Path $featureRoot 'iterations'
            if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
                $numericIterations = @(Get-ChildItem -LiteralPath $iterationsRoot -Directory -ErrorAction Stop | Where-Object { $_.Name -match '^[0-9]{3,}$' })
                if ($numericIterations.Count -gt 0) { $result.reason = 'workshop-feature-scope-after-lifecycle-activation'; return $result }
            }
        }

        $state = if ($scope -eq 'iteration') {
            Get-SpecrewWorkshopLifecycleState -ProjectRoot $ProjectRoot -FeatureRef $ActiveFeatureRef -IterationNumber $iteration
        }
        else {
            Get-SpecrewWorkshopLifecycleState -ProjectRoot $ProjectRoot -FeatureRef $ActiveFeatureRef
        }
        if ($null -eq $state -or [string]$state.status -ne 'active') {
            $result.reason = if ($null -ne $state -and -not [string]::IsNullOrWhiteSpace([string]$state.reason)) { [string]$state.reason } else { 'workshop-state-unproven' }
            if ($null -ne $state) {
                $result.scope = $scope
                $result.feature_ref = $ActiveFeatureRef
                $result.iteration_number = if ($scope -eq 'iteration') { $iteration } else { $null }
                $result.artifact_path = [string]$state.artifact_path
                if ($state.PSObject.Properties['binding_conflict']) { $result.binding_conflict = $state.binding_conflict }
            }
            return $result
        }

        $question = $null
        if (-not [string]::IsNullOrWhiteSpace($LastAssistantText)) {
            $questionLines = @($LastAssistantText -split "`r?`n" | Where-Object { $_.TrimEnd().EndsWith('?') } | Select-Object -Last 1)
            if ($questionLines.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace([string]$questionLines[0])) { $question = ([string]$questionLines[0]).Trim() }
        }
        $result.valid = $true
        $result.reason = 'durable-workshop-active'
        $result.scope = $scope
        $result.feature_ref = $ActiveFeatureRef
        $result.iteration_number = if ($scope -eq 'iteration') { $iteration } else { $null }
        $result.lens = [string]$state.current_lens
        $result.agenda_status = [string]$state.agenda_status
        $result.phase = 'lens'
        if ([string]$state.agenda_status -eq 'pending-confirmation' -and [string]$state.current_lens -eq 'product-domain') {
            $productMarkdown = Join-Path $featureRoot 'workshop/product-domain.md'
            $productStructured = Join-Path $featureRoot 'workshop/product-domain.yml'
            $result.phase = if ((Test-Path -LiteralPath $productMarkdown -PathType Leaf) -and
                (Test-Path -LiteralPath $productStructured -PathType Leaf)) { 'agenda' } else { 'product-domain' }
        }
        $result.question = $question
        $result.message_hash = Get-SpecrewFireIdentity -Parts @($scope, $ActiveFeatureRef, $iteration, [string]$state.current_lens, [string]$LastAssistantText)
        $result.artifact_path = [string]$state.artifact_path
        if ($result.phase -eq 'agenda') {
            # Host transcript accessors may normalize assistant prose, so the transcript hash cannot also be the
            # agenda-decision identity. RenderOnly writes the immutable agenda content separately. Bind that digest
            # only when the visible assistant turn contains the canonical agenda block.
            $proposalPath = Join-Path $ProjectRoot '.specrew/handover/workshop-agenda-proposal.json'
            $authorityPath = Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
            if ((Test-Path -LiteralPath $proposalPath -PathType Leaf) -and (Test-Path -LiteralPath $authorityPath -PathType Leaf)) {
                try {
                    if (-not (Get-Command Get-SpecrewWorkshopAgendaDigest -ErrorAction SilentlyContinue)) { . $authorityPath }
                    $proposal = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 12 -ErrorAction Stop
                    $digestProperty = $proposal.PSObject.Properties['agenda_digest']
                    $bindingProperty = $proposal.PSObject.Properties['agenda_binding']
                    $textProperty = $proposal.PSObject.Properties['canonical_text']
                    if ([string]$proposal.schema_version -ceq '1.0' -and [string]$proposal.feature_ref -ceq $ActiveFeatureRef -and
                        [string]$proposal.lens -ceq 'product-domain' -and $digestProperty -and $bindingProperty -and $textProperty -and
                        [string]$digestProperty.Value -cmatch '^[a-f0-9]{64}$' -and
                        (Get-SpecrewWorkshopAgendaDigest -Binding $bindingProperty.Value) -ceq [string]$digestProperty.Value) {
                        $agendaVisible = Test-SpecrewWorkshopAgendaVisibleInText -Text $LastAssistantText -CanonicalAgendaText ([string]$textProperty.Value)
                        $result.agenda_visibility = if ($agendaVisible) { 'visible' } else { 'not-visible' }
                        if ($agendaVisible) {
                            $result.agenda_digest = [string]$digestProperty.Value
                            $result.agenda_binding = $bindingProperty.Value
                        }
                    }
                }
                catch { $result.agenda_digest = $null; $result.agenda_binding = $null }
            }
        }
        return $result
    }
    catch { $result.reason = 'workshop-question-state-unreadable'; return $result }
}

function Test-SpecrewScopedFeatureRef {
    param([string]$ProjectRoot, [AllowNull()][string]$FeatureRef)
    if ([string]::IsNullOrWhiteSpace($FeatureRef) -or $FeatureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$') { return $false }
    return Test-Path -LiteralPath (Join-Path (Join-Path $ProjectRoot 'specs') $FeatureRef) -PathType Container
}

function Update-SpecrewWorkshopQuestionHandover {
    # A small local projection makes an interrupted workshop resumable without becoming authority. Classification
    # never reads this file; the exact, strict feature/iteration applicability artifact decides.
    param([string]$ProjectRoot, $Decision)
    $path = Join-Path $ProjectRoot '.specrew/handover/workshop-question.json'
    try {
        if ($null -eq $Decision -or -not [bool]$Decision.valid) {
            if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
            return
        }
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $phase = if ($Decision.PSObject.Properties['phase'] -and [string]$Decision.phase -in @('product-domain','agenda','lens')) { [string]$Decision.phase } else { 'lens' }
        $record = [ordered]@{
            schema = 'v3'; status = 'workshop-active'; scope = [string]$Decision.scope; feature_ref = [string]$Decision.feature_ref
            iteration_number = [string]$Decision.iteration_number; lens = [string]$Decision.lens
            phase = $phase; agenda_status = [string]$Decision.agenda_status
            question = [string]$Decision.question; message_hash = [string]$Decision.message_hash
            artifact_path = [string]$Decision.artifact_path
            recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
        }
        if ($phase -eq 'agenda' -and $Decision.PSObject.Properties['agenda_digest'] -and
            [string]$Decision.agenda_digest -cmatch '^[a-f0-9]{64}$' -and $Decision.PSObject.Properties['agenda_binding'] -and
            $null -ne $Decision.agenda_binding) {
            $record['agenda_digest'] = [string]$Decision.agenda_digest
            $record['agenda_binding'] = $Decision.agenda_binding
        }
        $temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
        try {
            [IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
            [IO.File]::Move($temp, $path, $true)
        }
        finally { if (Test-Path -LiteralPath $temp -PathType Leaf) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
    }
    catch { $null = $_ }
}

# --- manual $args parse (the double-dash contract; B1 - NO param()) ---
$hostKindArg = $null
$sourceEventArg = $null
$transcriptPathArg = $null
$sessionIdArg = $null
$structuredQuestionToolArg = $null
$structuredQuestionOutcomeArg = $null
$structuredQuestionTextArg = $null
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--transcript-path' -and ($i + 1) -lt $args.Count) { $transcriptPathArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--session-id' -and ($i + 1) -lt $args.Count) { $sessionIdArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--structured-question-tool' -and ($i + 1) -lt $args.Count) { $structuredQuestionToolArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--structured-question-outcome' -and ($i + 1) -lt $args.Count) { $structuredQuestionOutcomeArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--structured-question-text' -and ($i + 1) -lt $args.Count) { $structuredQuestionTextArg = [string]$args[$i + 1] }
}

try {
    $projectRoot = (Get-Location).Path
    if ([string]::IsNullOrWhiteSpace($projectRoot) -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew'))) {
        return  # not a governed project root - nothing to check.
    }
    $eventLower = if ([string]::IsNullOrWhiteSpace($sourceEventArg)) { 'stop' } else { $sourceEventArg.ToLowerInvariant() }
    if ($eventLower -notin @('stop', 'agentstop', 'sessionstart', 'userpromptsubmit', 'preinvocation', 'posttooluse')) {
        return  # Stop enforcement + genuine turn-start capture + PostToolUse nudge only (defensive).
    }
    $materialRuntime = Get-SpecrewMaterialRuntimeState -ProjectRoot $projectRoot -HostKind $hostKindArg -SessionId $sessionIdArg
    $turnCorePath = Join-Path $PSScriptRoot 'conformance-turn-delta.ps1'
    if (-not (Get-Command Get-SpecrewTurnSnapshot -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $turnCorePath -PathType Leaf)) {
        try { . $turnCorePath } catch { $null = $_ }
    }
    $turnCoreAvailable = (
        (Get-Command Get-SpecrewTurnSnapshot -ErrorAction SilentlyContinue) -and
        (Get-Command Read-SpecrewTurnBaseline -ErrorAction SilentlyContinue) -and
        (Get-Command Compare-SpecrewTurnSnapshot -ErrorAction SilentlyContinue) -and
        (Get-Command Resolve-SpecrewTurnPacketDemand -ErrorAction SilentlyContinue)
    )

    # --- TURN-START BASELINE lane (T070): host adapters normalize their genuine prompt boundary to
    # UserPromptSubmit / PreInvocation; SessionStart anchors the first turn and is also the explicit degraded
    # fallback. The baseline comes from LIVE Git state, never a rolling handover written by another session. ---
    if ($eventLower -in @('sessionstart', 'userpromptsubmit', 'preinvocation')) {
        try {
            if ($turnCoreAvailable) {
                $snapshot = Get-SpecrewTurnSnapshot -ProjectRoot $projectRoot
                $null = Write-SpecrewTurnBaseline -Path $materialRuntime.BaselinePath -Snapshot $snapshot -CaptureEvent $sourceEventArg
            }
        }
        catch { $null = $_ }
        return
    }

    # --- POSTTOOLUSE PRE-ARRANGEMENT NUDGE lane (maintainer packet-hardening 2026-07-14): when a tool call
    # inside the CURRENT turn produces a tracked user-file change (the handover provider, order 30, just
    # refreshed on this same event), remind the agent ONCE per material surface to END its final message with
    # the five-heading packet - arranging the packet IN the original response instead of rejecting a complete
    # response afterwards and forcing a duplicate turn. Non-blocking, deduplicated, fail-open. ---
    if ($eventLower -eq 'posttooluse') {
        try {
            if ([string]$structuredQuestionToolArg -ieq 'ask_user') {
                $workshopQuestionContext = $false
                $specsRoot = Join-Path $projectRoot 'specs'
                if (-not (Test-Path -LiteralPath $specsRoot -PathType Container)) {
                    $workshopQuestionContext = $true
                }
                else {
                    $controllerPaths = @(Get-ChildItem -LiteralPath $specsRoot -Filter 'lens-applicability.json' -File -Recurse -ErrorAction SilentlyContinue)
                    foreach ($controllerPath in $controllerPaths) {
                        try {
                            $controller = Get-Content -LiteralPath $controllerPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 10 -ErrorAction Stop
                            if ([string]$controller.agenda_contract -eq 'complete-coverage-v1' -and [string]$controller.agenda_status -in @('pending-confirmation', 'confirmed')) {
                                $selectedCount = @($controller.selected).Count
                                $completedCount = if ($controller.PSObject.Properties['workshop']) { @($controller.workshop.PSObject.Properties | Where-Object { $_.Value.PSObject.Properties['moved_on'] -and [bool]$_.Value.moved_on }).Count } else { 0 }
                                if ([string]$controller.agenda_status -eq 'pending-confirmation' -or $completedCount -lt $selectedCount) { $workshopQuestionContext = $true; break }
                            }
                        }
                        catch { $null = $_ }
                    }
                }
                if ($workshopQuestionContext) {
                    $outcomeLabel = if ([string]::IsNullOrWhiteSpace($structuredQuestionOutcomeArg)) { 'unknown' } else { $structuredQuestionOutcomeArg }
                    Write-Output ("Specrew: WORKSHOP QUESTION NEEDS A TYPED REPLY. The structured picker returned '{0}', which is not workshop authority. Ctrl+O/dismissal is no answer and grants no delegation or permission to choose defaults; a selected picker answer also has no typed-turn receipt. If the governed feature/controller does not exist yet, scaffold it and invoke specrew-design-workshop before asking. Render the unanswered question as visible prose, stop, and wait for the human to type a reply. Do not persist human-confirmed, human-delegated, or human-skipped from this picker result." -f $outcomeLabel)
                    return
                }
            }
            if (-not $turnCoreAvailable) { return }
            $current = Get-SpecrewTurnSnapshot -ProjectRoot $projectRoot
            if ($null -eq $current -or -not [bool]$current.available) { return }
            $baseline = Read-SpecrewTurnBaseline -Path $materialRuntime.BaselinePath
            if ($null -eq $baseline) { $baseline = New-SpecrewDegradedTurnBaseline -Current $current }
            $sig = Compare-SpecrewTurnSnapshot -Baseline $baseline -Current $current -ProjectRoot $projectRoot
            $satKey = Get-SpecrewMaterialSatisfiedKey -Path $materialRuntime.SatisfiedPath
            $ownerRecord = Get-SpecrewMaterialOwnerRecord -Path $materialRuntime.AttributionPath
            $decision = Resolve-SpecrewTurnPacketDemand -Delta $sig -SatisfiedKey $satKey -Owner ([string]$materialRuntime.Owner) -OwnerRecord $ownerRecord -OwnerMaxAgeSeconds $script:SpecrewMaterialHandoverMaxAgeSec
            if (-not [bool]$decision.demand) { return }
            $bd = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot
            $key = [string]$sig.key
            if (-not [string]::IsNullOrWhiteSpace([string]$materialRuntime.Owner)) {
                $null = Set-SpecrewMaterialOwnerRecord -Path $materialRuntime.AttributionPath -Key $key -Owner ([string]$materialRuntime.Owner)
            }
            $nudgedPath = $materialRuntime.NudgedPath
            $nudgedKey = Get-SpecrewMaterialSatisfiedKey -Path $nudgedPath
            if (-not [string]::IsNullOrWhiteSpace($nudgedKey)) {
                if ($nudgedKey -eq $key) { return }                                                     # this exact surface already nudged
                # ONE reminder per OBLIGATION WINDOW: while an earlier nudge's surface is still undischarged
                # (not absorbed into the baseline, not satisfied by a packet), every additional touched file
                # mutates the surface key - re-nudging each mutation is a per-tool-call drumbeat, not signal.
                if ($nudgedKey -ne $satKey) { return }
            }
            # Nudge-only optimization: avoid interrupting a likely in-progress lens turn before its final question is
            # rendered. The Stop lane does not trust this broad signal; it proves the exact scoped marker and question.
            $handoverContext = Get-SpecrewCurrentStopMaterialSignal -ProjectRoot $projectRoot -BootstrapDir $bd -AnySnapshot
            $featureRef = if ($null -ne $handoverContext) { [string]$handoverContext.active_feature } else { '' }
            if (Test-SpecrewWorkshopInProgress -ProjectRoot $projectRoot -BootstrapDir $bd -FeatureRef $featureRef) { return }
            try {
                $scP = Join-Path $projectRoot '.specrew/start-context.json'
                if (Test-Path -LiteralPath $scP -PathType Leaf) {
                    $scObj = Get-Content -LiteralPath $scP -Raw -Encoding UTF8 | ConvertFrom-Json
                    $hasBoundary = ($scObj.PSObject.Properties['session_state'] -and $null -ne $scObj.session_state -and $scObj.session_state.PSObject.Properties['boundary_type'] -and -not [string]::IsNullOrWhiteSpace([string]$scObj.session_state.boundary_type))
                    $hasAuth = $false
                    if ($scObj.PSObject.Properties['boundary_enforcement'] -and $null -ne $scObj.boundary_enforcement) {
                        if ($scObj.boundary_enforcement.PSObject.Properties['last_authorized_boundary'] -and -not [string]::IsNullOrWhiteSpace([string]$scObj.boundary_enforcement.last_authorized_boundary)) { $hasAuth = $true }
                        if ($scObj.boundary_enforcement.PSObject.Properties['verdict_history'] -and @($scObj.boundary_enforcement.verdict_history).Count -gt 0) { $hasAuth = $true }
                    }
                    if ((-not $hasBoundary) -and (-not $hasAuth) -and (-not (Test-SpecrewWorkshopComplete -ProjectRoot $projectRoot -BootstrapDir $bd -FeatureRef $featureRef))) { return }
                }
            }
            catch { $null = $_ }
            Set-SpecrewMaterialSatisfiedKey -Path $nudgedPath -Key $key
            $activityLabel = if ([string]$sig.attribution_mode -eq 'exact-turn') {
                'MATERIAL WORK IN PROGRESS this turn ({0} changed user file(s), {1} new commit(s)).' -f [int]$sig.user_file_count, [int]$sig.new_commit_count
            }
            else {
                'CURRENTLY DIRTY IN THE WORKTREE ({0} user file(s)); exact per-turn attribution is unavailable.' -f [int]$sig.current_dirty_user_file_count
            }
            Write-Output ('[specrew-conformance] {0} When you finish, END your final message with the five-heading non-boundary context packet - ## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## What I Need From You, every artifact reference a bare file:/// URL. Rendering it IN this response is the contract; a packet-less stop after material work gets force-continued into a duplicate turn.' -f $activityLabel)
        }
        catch { $null = $_ }
        return
    }

    # --- component resolution (fail-open: a component that cannot load simply disables its lane) ---
    # shared-governance.ps1 ships BESIDE this provider - the canonical Get-SpecrewPendingVerdictState + boundary order.
    $sgBeside = Join-Path $PSScriptRoot 'shared-governance.ps1'
    if (Test-Path -LiteralPath $sgBeside -PathType Leaf) { try { . $sgBeside } catch { $null = $_ } }

    # --- CHEAP signals first (no per-line transcript parse) ---
    # Pending-verdict state (the boundary trigger) - reused canonical helper; WARN loudly if it cannot load (F4).
    $pending = $null
    if (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue) {
        try { $pending = Get-SpecrewPendingVerdictState -ProjectRoot $projectRoot } catch { $pending = $null }
    }
    else {
        [Console]::Error.WriteLine('[specrew-conformance] WARN CONFORMANCE_DETECTOR_UNAVAILABLE shared-governance/Get-SpecrewPendingVerdictState did not load; the boundary lane is dark this stop (the gate STATE + resume surface remain the authority).')
    }
    $hasPending = ($null -ne $pending -and [bool]$pending.HasPendingVerdict)
    # FR-066 (amended 2026-08-03), T089. Computed HERE, beside $hasPending, and not at the block
    # decision — because the transcript-read gate below keys on $hasPending, and this state is
    # deliberately NOT pending (there is no crossing to approve). Computing it late left
    # $lastAssistantText null, so $canAssess was false and the block could never warrant: the
    # correction looked right and changed nothing. Caught by re-running T087 rather than by review.
    $boundaryUnrecordable = ($null -ne $pending) -and ([string]$pending.IntegrityStatus -eq 'boundary-unrecordable')
    # FR-068 (T090): the crossing IS pending — capture must keep working — but the stage owes evidence
    # it has not produced, so the DEMAND is suppressed. Same reachability lesson as T089: read beside
    # $hasPending, not at the block decision.
    $stageEvidenceAbsent = ($null -ne $pending) -and ($pending.PSObject.Properties.Name -contains 'StageEvidenceAbsent') -and ([bool]$pending.StageEvidenceAbsent)

    # Any feature spec on disk (cheap dir check) -> the substantial + #1 triggers need this.
    $anySpec = $false; $specPath = $null; $specs = @()
    try {
        $specs = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'specs') -Directory -ErrorAction Stop |
            ForEach-Object { Join-Path $_.FullName 'spec.md' } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($specs.Count -gt 0) { $anySpec = $true; $specPath = $specs[0] }
    }
    catch { $anySpec = $false }

    # Active feature ref (145 OB-1): workshop validation must scope to THIS feature, not the whole project.
    # session_state.feature_ref is canonical; fall back to the current material signal and then the discovered spec.
    $activeFeatureRef = $null
    $activeIterationNumber = $null
    $activeFeatureFromSessionState = $false
    $startContextState = 'absent'
    $hasActiveLifecycleBoundary = $false
    $hasBoundaryAuthorization = $false
    try {
        $scPath = Join-Path $projectRoot '.specrew/start-context.json'
        if (Test-Path -LiteralPath $scPath -PathType Leaf) {
            $startContextState = 'unreadable'
            $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $startContextState = 'readable'
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['feature_ref'] -and (Test-SpecrewScopedFeatureRef -ProjectRoot $projectRoot -FeatureRef ([string]$sc.session_state.feature_ref))) {
                $activeFeatureRef = ([string]$sc.session_state.feature_ref).Trim()
                $activeFeatureFromSessionState = $true
            }
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['iteration_number'] -and ([string]$sc.session_state.iteration_number -cmatch '^[0-9]{3,}$')) {
                $activeIterationNumber = [string]$sc.session_state.iteration_number
            }
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['boundary_type'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.session_state.boundary_type)) {
                $hasActiveLifecycleBoundary = $true
            }
            if ($sc.PSObject.Properties['boundary_enforcement'] -and $null -ne $sc.boundary_enforcement) {
                if ($sc.boundary_enforcement.PSObject.Properties['last_authorized_boundary'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.boundary_enforcement.last_authorized_boundary)) {
                    $hasBoundaryAuthorization = $true
                }
                if ($sc.boundary_enforcement.PSObject.Properties['verdict_history'] -and @($sc.boundary_enforcement.verdict_history).Count -gt 0) {
                    $hasBoundaryAuthorization = $true
                }
            }
        }
    }
    catch { $null = $_ }
    $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot

    # If lifecycle state is still pre-boundary / anchorless, the rolling Stop handover is the fresher FEATURE signal.
    # It is context only: T070 forbids using its absolute dirty-file count as turn ownership evidence.
    # In a multi-feature repo, falling back to the first specs/* directory can incorrectly borrow an abandoned
    # feature's workshop state. Prefer the current rolling Stop handover when lifecycle state is still anchorless.
    $handoverContextSignal = Get-SpecrewCurrentStopMaterialSignal -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -AnySnapshot
    if (-not $activeFeatureFromSessionState -and $null -ne $handoverContextSignal -and (Test-SpecrewScopedFeatureRef -ProjectRoot $projectRoot -FeatureRef ([string]$handoverContextSignal.active_feature))) {
        $activeFeatureRef = ([string]$handoverContextSignal.active_feature).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($activeFeatureRef) -and $specs.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($specPath)) {
        $activeFeatureRef = Split-Path (Split-Path $specPath -Parent) -Leaf
    }
    # A first product-domain question cannot carry authority until a governed feature exists. This narrow candidate
    # lets the Stop lane inspect the last assistant turn in a fresh project even though no spec/controller exists yet;
    # otherwise the optimized transcript gate skips the read and the violation is invisible by construction.
    $preScaffoldWorkshopCandidate = (-not $hasPending) -and (-not $hasActiveLifecycleBoundary) -and
        [string]::IsNullOrWhiteSpace($activeFeatureRef) -and $specs.Count -eq 0
    # #3 RAW SPEC KIT - a CHEAP raw-text scan of the recent tail (NO per-line JSON parse). NEGATION GUARD: skip a
    # match whose preceding context is a prohibition / quote (the contract's OWN "do NOT run the raw `specify.exe
    # workflow`" prose) so it does not false-fire (dogfood + 145 fix-followup). A proved question suppresses it below.
    $rawHit = $false
    $rawTail = ''
    if (-not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)) {
        try {
            $rawTail = (@(Get-Content -LiteralPath $transcriptPathArg -Tail 40 -Encoding UTF8 -ErrorAction Stop) -join "`n")
            foreach ($mm in ([regex]::new('(?i)\bspecify(?:\.exe)?\s+workflow\b')).Matches($rawTail)) {
                $pre = $rawTail.Substring([Math]::Max(0, $mm.Index - 24), [Math]::Min(24, $mm.Index))
                if ($pre.Contains([char]96) -or ($pre -match '(?i)\b(not|never|raw|un|forbidden|avoid|don)\b')) { continue }  # prohibition/quote prose, not an invocation
                $rawHit = $true; break
            }
        }
        catch { $null = $_ }
    }

    # Material-work lane (T070): compare a LIVE Git status/content-fingerprint snapshot to this owner's turn-start
    # baseline. The pure core owns snapshotting, delta semantics, and the packet-demand decision; this provider owns
    # only host-event orchestration and presentation.
    $blockStatePath = $materialRuntime.BlockPath
    $materialSatisfiedPath = $materialRuntime.SatisfiedPath
    $materialBaselinePath = $materialRuntime.BaselinePath
    $turnCurrentSnapshot = $null
    $materialSignal = $null
    $materialDecision = $null
    if ($turnCoreAvailable) {
        try {
            $turnCurrentSnapshot = Get-SpecrewTurnSnapshot -ProjectRoot $projectRoot
            if ($null -ne $turnCurrentSnapshot -and [bool]$turnCurrentSnapshot.available) {
                $turnBaseline = Read-SpecrewTurnBaseline -Path $materialBaselinePath
                if ($null -eq $turnBaseline) { $turnBaseline = New-SpecrewDegradedTurnBaseline -Current $turnCurrentSnapshot }
                $materialSignal = Compare-SpecrewTurnSnapshot -Baseline $turnBaseline -Current $turnCurrentSnapshot -ProjectRoot $projectRoot
                $ownerRecord = Get-SpecrewMaterialOwnerRecord -Path $materialRuntime.AttributionPath
                $materialSatisfiedKeyForDecision = Get-SpecrewMaterialSatisfiedKey -Path $materialSatisfiedPath
                $materialDecision = Resolve-SpecrewTurnPacketDemand -Delta $materialSignal -SatisfiedKey $materialSatisfiedKeyForDecision -Owner ([string]$materialRuntime.Owner) -OwnerRecord $ownerRecord -OwnerMaxAgeSeconds $script:SpecrewMaterialHandoverMaxAgeSec
                if ([bool]$materialDecision.demand -and -not [string]::IsNullOrWhiteSpace([string]$materialRuntime.Owner)) {
                    $null = Set-SpecrewMaterialOwnerRecord -Path $materialRuntime.AttributionPath -Key ([string]$materialSignal.key) -Owner ([string]$materialRuntime.Owner)
                }
            }
        }
        catch { $materialSignal = $null; $materialDecision = $null }
    }
    # W34-B: mint the authorship observation from what the hook WATCHED this session write, before
    # any block-kind decision narrows the view. It runs wherever a turn delta exists rather than only
    # on a material stop, because a review record is often written in a turn that raises no block at
    # all - which is exactly the turn whose authorship a later reader needs.
    if ($null -ne $materialSignal -and (Get-Command -Name 'Write-SpecrewReviewAuthorshipObservation' -ErrorAction SilentlyContinue)) {
        $authorshipPaths = @()
        try { $authorshipPaths = @($materialSignal.changed_paths | ForEach-Object { [string]$_ }) } catch { $authorshipPaths = @() }
        # W37: the mode travels with the paths. Without it the observation cannot tell what this turn
        # WROTE from what merely happens to be dirty, and it minted a source-writer fact either way.
        $authorshipMode = ''
        try { $authorshipMode = [string]$materialSignal.attribution_mode } catch { $authorshipMode = '' }
        Write-SpecrewReviewAuthorshipObservation -ProjectRoot $projectRoot -HostKind $hostKindArg -SessionId $sessionIdArg -ChangedPaths $authorshipPaths -AttributionMode $authorshipMode
    }
    if ($null -eq $materialSignal) {
        $materialSignal = [pscustomobject]@{ material = $false; reason = 'turn-delta-unavailable'; key = ''; user_file_count = 0; current_dirty_user_file_count = 0; new_commit_count = 0; attribution_mode = 'degraded-worktree' }
    }
    $materialStop = ($null -ne $materialDecision -and [bool]$materialDecision.demand)
    $materialBaselineSuppressed = ($null -ne $materialDecision -and [string]$materialDecision.reason -in @('no-turn-delta', 'turn-delta-already-satisfied'))
    $materialForeignOwnerSuppressed = ($null -ne $materialDecision -and [bool]$materialDecision.foreign_owner_suppressed)
    # --- LONG-TURN lane (maintainer fixture (d) 2026-07-14): a read-only turn with no material delta still owes
    # the packet when it was a GENUINELY LONG investigation (assistant-entry count since the last human message
    # >= the threshold) - the re-entry cost is the turn, not the diff. Deterministic, cheap (raw string scan),
    # fail-open on unrecognized transcript shapes. ---
    $longTurn = $null
    if (-not $materialStop -and $null -ne $materialSignal) {
        $longTurn = Get-SpecrewLongTurnSignal -TranscriptPath $transcriptPathArg
        if ($null -ne $longTurn -and [bool]$longTurn.long) {
            $materialStop = $true
            $materialSignal.material = $true
            $materialSignal.key = ('material|longturn|{0}' -f [string]$longTurn.hash)
            $materialSignal.reason = 'long-turn-investigation'
        }
    }
    $continueGuardPath = $materialRuntime.ContinueGuardPath  # FR-045a continue loop-guard store ({key,count,epoch}); keyed by "continue|<materialSurfaceHash>", NO time window (a changed surface = intervening progress = reset to 0).
    $existingBlockRecord = Get-SpecrewBlockRecord -Path $blockStatePath
    $materialRetryKey = Get-SpecrewRecentMaterialRetryKey -Record $existingBlockRecord
    $materialSatisfiedKey = Get-SpecrewMaterialSatisfiedKey -Path $materialSatisfiedPath
    # (IDEMPOTENCY check is performed BELOW - after the role-aware last-assistant message + the workshop/marker state
    # are computed - so the fire-identity captures the FULL decision-relevant state. An EARLY tail-40 identity falsely
    # deduped a genuine second boundary stop when the distinguishing message fell outside tail-40, or across a
    # workshop-completion flip; 145 IDEMP-1 / SC-1.)

    # --- WORKSHOP STATE (FR-056): strict controller-owned artifacts decide whether the exact current scope is
    # actively mid-workshop. This does not depend on a model-authored comment or a host's question-tool transcript.
    # A lifecycle boundary still has precedence inside the resolver. ---
    $workshopQuestion = $null
    $workshopStateInProgress = $false
    $workshopConflictState = $false
    $workshopRepairState = $false
    $preScaffoldWorkshopAttempt = $false
    $workshopProductRecordMissingAgenda = $false
    $workshopAgendaReformatted = $false
    $workshopProductRecordsUnreceipted = $false
    $workshopRepairReasons = @(
        'workshop-decision-bindings-invalid',
        'workshop-code-implementation-manifest-missing',
        'workshop-code-implementation-manifest-invalid',
        'workshop-human-turn-contract-invalid',
        'workshop-human-turn-helper-missing',
        'workshop-pre-agenda-turn-receipt-invalid',
        'workshop-agenda-turn-receipt-invalid',
        'workshop-agenda-selected-entry-invalid',
        'workshop-agenda-skipped-entry-invalid',
        'workshop-agenda-digest-mismatch',
        'workshop-completed-human-turn-receipt-invalid'
    )
    $missingWorkshopController = $false
    $workshopAgendaPresentationMissing = $false
    if ($hasPending -or $anySpec -or $rawHit -or $materialStop) {
        if ([string]::IsNullOrWhiteSpace($bootstrapDir)) { $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot }
        $workshopQuestion = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -ActiveFeatureRef $activeFeatureRef -ActiveIterationNumber $activeIterationNumber -HasActiveLifecycleBoundary $hasActiveLifecycleBoundary -StartContextState $startContextState -LastAssistantText $null -HasPendingVerdict $hasPending
        $workshopStateInProgress = ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid)
        $workshopConflictState = ($null -ne $workshopQuestion -and [string]$workshopQuestion.reason -eq 'workshop-decision-binding-conflict')
        $workshopRepairState = ($null -ne $workshopQuestion -and [string]$workshopQuestion.reason -in $workshopRepairReasons)
        $changedPathsForWorkshopRepair = @()
        try { $changedPathsForWorkshopRepair = @($materialSignal.changed_paths | ForEach-Object { ([string]$_).Replace([char]92, [char]47) }) } catch { $changedPathsForWorkshopRepair = @() }
        $productDomainRecordChanged = @($changedPathsForWorkshopRepair | Where-Object { $_ -match '(^|/)workshop/product-domain\.(md|yml)$' }).Count -gt 0
        $missingWorkshopController = ($productDomainRecordChanged -and $materialStop -and -not $hasPending -and -not $hasActiveLifecycleBoundary -and [string]::IsNullOrWhiteSpace($activeIterationNumber) -and $null -ne $workshopQuestion -and [string]$workshopQuestion.reason -eq 'workshop-applicability-absent')
    }

    # --- EXPENSIVE transcript parse ONLY on a MATERIAL-TURN stop (T099/FR-040, design N3): the per-line
    # ConvertFrom-Json parse is the dominant Stop-hook cost and scales with session size. It runs ONLY when
    # the stop actually followed material work (the deterministic live turn-delta signal), a boundary is
    # pending, or a material forced-continue retry is in flight - a trivial/conversational stop skips it
    # entirely. The old `$anySpec` trigger made EVERY stop in EVERY real project pay the parse just to feed
    # the #1 intake regex; that check now only evaluates on the stops that already warranted the parse
    # (an idle intake drift is caught by the bootstrap orientation surface instead). ---
    $lastAssistantText = $null; $intakeHit = $false; $ccLoaded = $false; $markerForPendingCrossing = $false
    $pendingCrossing = $null
    if ($hasPending -and (Get-Command Get-SpecrewPendingBoundaryCrossing -ErrorAction SilentlyContinue)) {
        try { $pendingCrossing = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary ([string]$pending.LastAuthorizedBoundary) -WorkingBoundary ([string]$pending.WorkingBoundary) } catch { $pendingCrossing = $null }
    }
    if ($hasPending -or $boundaryUnrecordable -or $materialStop -or -not [string]::IsNullOrWhiteSpace($materialRetryKey) -or $workshopStateInProgress -or $workshopConflictState -or $workshopRepairState -or $missingWorkshopController -or $preScaffoldWorkshopCandidate) {
        if ([string]::IsNullOrWhiteSpace($bootstrapDir)) { $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot }
        if (-not [string]::IsNullOrWhiteSpace($bootstrapDir)) {
            $cc = Join-Path $bootstrapDir 'ConversationCaptureAccessor.ps1'
            if (Test-Path -LiteralPath $cc -PathType Leaf) { try { . $cc; $ccLoaded = $true } catch { $null = $_ } }
        }
        if ($ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf) -and
            (Get-Command Get-SpecrewConversationTurnFromLine -ErrorAction SilentlyContinue)) {
            try {
                $tail = @(Get-Content -LiteralPath $transcriptPathArg -Tail 200 -Encoding UTF8 -ErrorAction Stop)
                for ($k = $tail.Count - 1; $k -ge 0; $k--) {
                    $turn = Get-SpecrewConversationTurnFromLine -Line $tail[$k]
                    if ($null -ne $turn -and [string]$turn.role -eq 'assistant' -and -not [string]::IsNullOrWhiteSpace([string]$turn.text)) { $lastAssistantText = [string]$turn.text; break }
                }
            }
            catch { $lastAssistantText = $null }
        }
        # #1 intake question (needs the role-aware last assistant text + a spec on disk).
        if ($anySpec -and -not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
            $intakeRx = [regex]::new('(?i)\bwhat\b[^.?!]{0,60}\b(?:do you want|would you like|are you looking|should we|are we|can i help you)\b[^.?!]{0,40}\b(?:build|create|make|work on)\b|(?i)\bwhat\b[^.?!]{0,40}\b(?:feature|app|project|product)\b[^.?!]{0,40}\b(?:build|create|want|like)\b|(?i)\bwhat (?:do you want|would you like) to build\b')
            if ($intakeRx.IsMatch($lastAssistantText)) { $intakeHit = $true }
        }
        # BOUNDARY VERDICT MARKER (Antigravity dogfood gap): at a boundary the six-section HEADERS alone do NOT
        # authorize the crossing - the <!-- SPECREW-VERDICT-BOUNDARY --> marker is what captures the verdict. A weak
        # host rendered the headers but NOT the marker, so the verdict was never captured (last_authorized stayed
        # none) yet the header check suppressed the block. So at a boundary, suppress ONLY when the marker for the
        # PENDING crossing is present; headers without that marker still block.
        if ($hasPending -and $ccLoaded -and (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue)) {
            try {
                $pkt = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $transcriptPathArg
                if ($null -ne $pkt -and [bool]$pkt.Found -and $null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) {
                    $pktFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.FromBoundary)
                    $pktTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pkt.ToBoundary)
                    $expectedFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingFromMarkerBoundary)
                    $expectedTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingToMarkerBoundary)
                    if (-not [string]::IsNullOrWhiteSpace($pktTo) -and $pktFrom -eq $expectedFrom -and $pktTo -eq $expectedTo) { $markerForPendingCrossing = $true }
                }
            }
            catch { $null = $_ }
        }
    }
    $packetPresent = Test-SpecrewReentryPacketPresent -Text $lastAssistantText
    $transcriptRereadAttempted = $false
    $transcriptRereadRecovered = $false
    # DRIFT-199-I001-015: a transcript writer can expose a parseable but incomplete final assistant
    # record while Stop is reading it. Do not tax every Stop with repeated tail-200 parsing. A 1-3 header
    # near-miss is the measured signature, so only then wait one scheduler slice and re-read eight lines.
    # This is a bounded recovery read, not a poll loop; an unreadable retry preserves fail-safe enforcement.
    $initialHeaderHits = 0
    foreach ($header in $script:SpecrewReentryHeaders) {
        if (-not [string]::IsNullOrEmpty([string]$lastAssistantText) -and [string]$lastAssistantText -match [regex]::Escape($header)) { $initialHeaderHits++ }
    }
    if (-not $packetPresent -and $initialHeaderHits -ge 1 -and $initialHeaderHits -le 3 -and $ccLoaded -and
        -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)) {
        $transcriptRereadAttempted = $true
        try {
            Start-Sleep -Milliseconds 15
            $retryTail = @(Get-Content -LiteralPath $transcriptPathArg -Tail 8 -Encoding UTF8 -ErrorAction Stop)
            $retryAssistantText = $null
            for ($retryIndex = $retryTail.Count - 1; $retryIndex -ge 0; $retryIndex--) {
                $retryTurn = Get-SpecrewConversationTurnFromLine -Line $retryTail[$retryIndex]
                if ($null -ne $retryTurn -and [string]$retryTurn.role -eq 'assistant' -and -not [string]::IsNullOrWhiteSpace([string]$retryTurn.text)) {
                    $retryAssistantText = [string]$retryTurn.text
                    break
                }
            }
            if (-not [string]::IsNullOrWhiteSpace($retryAssistantText) -and (Test-SpecrewReentryPacketPresent -Text $retryAssistantText)) {
                $lastAssistantText = $retryAssistantText
                $packetPresent = $true
                $transcriptRereadRecovered = $true
                # Boundary packets also owe an exact crossing marker. Re-run the canonical capture only
                # after a recovered near-miss so the header and marker decisions see the same bytes.
                if ($hasPending -and (Get-Command Get-SpecrewCapturedBoundaryPacket -ErrorAction SilentlyContinue)) {
                    try {
                        $retryPacket = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $transcriptPathArg
                        if ($null -ne $retryPacket -and [bool]$retryPacket.Found -and $null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) {
                            $retryFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$retryPacket.FromBoundary)
                            $retryTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$retryPacket.ToBoundary)
                            $expectedRetryFrom = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingFromMarkerBoundary)
                            $expectedRetryTo = Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pendingCrossing.PendingToMarkerBoundary)
                            if (-not [string]::IsNullOrWhiteSpace($retryTo) -and $retryFrom -eq $expectedRetryFrom -and $retryTo -eq $expectedRetryTo) { $markerForPendingCrossing = $true }
                        }
                    }
                    catch { $null = $_ }
                }
            }
        }
        catch { $null = $_ }
    }
    # Re-resolve only to enrich the non-authoritative handover projection with the visible question, if one exists.
    # Artifact classification remains identical whether the host emitted plain prose, a question tool, or a comment.
    $workshopQuestion = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -ActiveFeatureRef $activeFeatureRef -ActiveIterationNumber $activeIterationNumber -HasActiveLifecycleBoundary $hasActiveLifecycleBoundary -StartContextState $startContextState -LastAssistantText $lastAssistantText -HasPendingVerdict $hasPending
    $workshopIntermediate = ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid)
    $workshopConflict = ($null -ne $workshopQuestion -and [string]$workshopQuestion.reason -eq 'workshop-decision-binding-conflict')
    $workshopRepair = ($null -ne $workshopQuestion -and [string]$workshopQuestion.reason -in $workshopRepairReasons)
    $preScaffoldWorkshopAttempt = ($preScaffoldWorkshopCandidate -and
        -not [string]::IsNullOrWhiteSpace($lastAssistantText) -and
        $lastAssistantText -match '(?i)\bproduct[- ]domain\b' -and
        $lastAssistantText -match '\?')
    if ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid -and
        [string]$workshopQuestion.agenda_status -eq 'pending-confirmation' -and
        [string]$workshopQuestion.phase -eq 'product-domain' -and
        -not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
        # ConversationCaptureAccessor intentionally collapses display whitespace. Detect the semantic agenda form,
        # not line layout: the visible block must name the agenda and its negative (skipped) selection.
        $workshopProductRecordMissingAgenda = ($lastAssistantText -match '(?is)\bWorkshop agenda\b.*\bSkipped(?:\s+lenses)?\s*:')
    }
    if ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid -and
        [string]$workshopQuestion.agenda_status -eq 'pending-confirmation' -and
        [string]$workshopQuestion.lens -eq 'product-domain' -and
        -not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
        $technicalLensHeading = $lastAssistantText -match '(?im)^\s*(?:preparing\s+)?(?:lens\s+\d+\s+of\s+\d+\s*[:—-]\s*)?(?:architecture-core|requirements-nfr|data-storage|ui-ux|devops-operations|integration-api|security-compliance|observability-resilience|component-design|code-implementation)(?:\s+lens)?\b'
        if ($technicalLensHeading) { $workshopAgendaPresentationMissing = $true }
    }
    if ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid -and
        [string]$workshopQuestion.phase -eq 'agenda' -and
        [string]$workshopQuestion.agenda_visibility -eq 'not-visible' -and
        -not [string]::IsNullOrWhiteSpace($lastAssistantText)) {
        # The visibility check is right: a bullet or spacing rewrite is not the block the human saw.
        # Silence here is the defect. Name the rewrite on this Stop so the agent re-sends the command
        # output instead of diagnosing a missing receipt one turn later.
        $workshopAgendaReformatted = ($lastAssistantText -match '(?is)\bWorkshop agenda\b' -or
            $lastAssistantText -match '(?is)\bSelected lenses\s*:' -or
            $lastAssistantText -match '(?im)^\s*[-*•]\s+(?:architecture-core|requirements-nfr|data-storage|ui-ux|devops-operations|integration-api|security-compliance|observability-resilience|component-design|code-implementation)\b')
    }
    if ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid -and
        [string]$workshopQuestion.agenda_status -eq 'pending-confirmation' -and
        [string]$workshopQuestion.phase -eq 'agenda') {
        # Phase 'agenda' means both product-domain records are already persisted, so the typed pre-agenda
        # turn that authorized them must have minted a receipt. None on file means the answers arrived
        # through a channel that mints nothing - a structured picker selection or a dismissed question UI
        # (hosts without a per-tool-call event never reach the PostToolUse picker guard, so this Stop is
        # the first surface that can speak). The store is right to refuse; silence here is the defect:
        # the next turn misreads the refusal as broken hook wiring and proposes hand-written records.
        try {
            if (-not (Get-Command Get-SpecrewWorkshopAuthorityReceipt -ErrorAction SilentlyContinue)) {
                $authorityStoreBeside = Join-Path $PSScriptRoot 'workshop-authority-store.ps1'
                if (Test-Path -LiteralPath $authorityStoreBeside -PathType Leaf) { . $authorityStoreBeside }
            }
            if (Get-Command Get-SpecrewWorkshopAuthorityReceipt -ErrorAction SilentlyContinue) {
                $productReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $projectRoot -FeatureRef ([string]$workshopQuestion.feature_ref) -Phase 'product-domain'
                $workshopProductRecordsUnreceipted = ($null -eq $productReceipt -or [string]$productReceipt.confirmation -eq 'invalid')
            }
        }
        catch { $null = $_ }  # a corrupt store already surfaces through its own receipt-invalid repair reasons
    }
    if ($workshopIntermediate -or $workshopConflict -or $workshopRepair) { $rawHit = $false }
    # The old 4x tail-200 mitigation remains removed. The measured 2026-08-10 signature now triggers only the
    # bounded tail-8 recovery above; diagnostics record both attempted and recovered so it cannot fail silently.
    $substantial = (-not [string]::IsNullOrWhiteSpace($lastAssistantText)) -and ($lastAssistantText.Length -ge $script:SpecrewSubstantialChars)

    # --- IDEMPOTENCY (duplicate-fire guard, 145 IDEMP-1 / SC-1): dedup a re-fired hook for the SAME observable DECISION
    # state, processed ONCE. The identity uses the ROLE-AWARE last-assistant message (the SAME view the block decision
    # reads - NOT a coarse tail-40 that collides when the distinguishing message is >40 entries back) PLUS the boundary
    # cursor and the marker / workshop / pending discriminators - so two genuinely-different stops, or a
    # workshop-completion flip, get DIFFERENT identities and are NOT falsely deduped (the dangerous missed-enforcement
    # direction). Computed AFTER those signals exist. Best-effort + fail-open: a read/write miss just disables dedup,
    # never blocks the stop. The force-continue loop is unaffected (each forced re-render is a NEW message).
    $idWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
    $idAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
    $fireIdentity = Get-SpecrewFireIdentity -Parts @([string]$lastAssistantText, $idWorking, $idAuth, ("m={0}" -f [int][bool]$markerForPendingCrossing), ("wq={0}" -f [int][bool]$workshopIntermediate), ("wc={0}" -f [int][bool]$workshopConflict), ("p={0}" -f [int][bool]$hasPending), ("mat={0}" -f [string]$materialSignal.key), ("mr={0}" -f [string]$materialRetryKey), [string]$sourceEventArg)
    $lastFirePath = $materialRuntime.LastFirePath
    if (-not [string]::IsNullOrWhiteSpace($fireIdentity)) {
        try {
            if (Test-Path -LiteralPath $lastFirePath -PathType Leaf) {
                $lf = Get-Content -LiteralPath $lastFirePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if (($lf.PSObject.Properties.Name -contains 'identity') -and ([string]$lf.identity -eq $fireIdentity) -and ($lf.PSObject.Properties.Name -contains 'epoch')) {
                    $age = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$lf.epoch
                    if ($age -ge 0 -and $age -le $script:SpecrewFireDedupWindowSec) { return }  # duplicate fire -> idempotent no-op
                }
            }
        }
        catch { $null = $_ }
        try {
            $rdir = Split-Path -Parent $lastFirePath
            if ($rdir -and -not (Test-Path -LiteralPath $rdir)) { New-Item -ItemType Directory -Path $rdir -Force | Out-Null }
            ([pscustomobject]@{ identity = $fireIdentity; epoch = [System.DateTimeOffset]::UtcNow.ToUnixTimeSeconds() } | ConvertTo-Json -Compress) | Set-Content -LiteralPath $lastFirePath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    # Persist/clear the non-authoritative re-entry record only for a NEW observable Stop. A duplicate hook
    # delivery returned above, so it neither rewrites the record nor creates a second visible pause.
    Update-SpecrewWorkshopQuestionHandover -ProjectRoot $projectRoot -Decision $(if ($workshopIntermediate) { $workshopQuestion } else { $null })

    # --- block decision: does this stop owe the packet, and is the packet absent? ---
    # BOUNDARY stops (HasPendingVerdict) owe the packet regardless of workshop state. Material stops are intermediate
    # only while the exact scoped durable workshop state is valid and incomplete. The length-only substantial trigger remains gated on a spec, so
    # initial pre-spec intake prose does not become a packet obligation by length alone.
    # FIX C (145 F1-CC-FAIL-CLOSED): only block when we ACTUALLY READ the last assistant message - we cannot claim
    # "the packet is absent" without reading it. If ConversationCaptureAccessor did not load (stale install) or there
    # is no transcript, $lastAssistantText is null -> do NOT block (fail-open, matching the Get-SpecrewPendingVerdictState
    # fail-open; never block a correctly-rendered packet we simply could not see, and never go fail-CLOSED on a missing
    # component). This is the same failure-class -> same direction (allow) as the boundary-trigger load failure above.
    $canAssess = -not [string]::IsNullOrWhiteSpace($lastAssistantText)
    # BOUNDARY stop: owes the verdict MARKER (not just the six headers) - the marker is what captures the verdict;
    #   headers WITHOUT it leave the gate un-authorized (the Antigravity dogfood: a packet rendered, no marker,
    #   last_authorized stayed `none`). $markerForPendingCrossing also subsumes the old false-positive guard (a
    #   captured marker for THIS crossing = a legitimate awaiting-verdict stop, 145 TI-2/F1).
    # NON-BOUNDARY material hand-back: the packet headers suffice (a within-phase stop has no verdict marker).
    # FIX C (145 F1-CC): $canAssess gates both - we never claim "absent" without reading the message (fail-open).
    # Hard-block ONLY genuine DECISION-YIELD stops = a BOUNDARY (pending verdict + missing marker). The earlier
    # "substantial" (>=600-char) non-boundary trigger was DROPPED (maintainer 2026-06-21): a long but communicative
    # DISCUSSION / status answer is not a decision-yield and must not be force-blocked into a packet. The replacement
    # hard block is deterministic material work only: the live turn delta reports changed user files or new commits.
    # Once a packet has been rendered for the same material surface, later quick discussion while the tree
    # stays dirty is allowed; a changed material surface requires a fresh packet.
    # FR-066 (amended 2026-08-03), T089: a boundary that could not be RECORDED must still be spoken
    # to. `$boundaryUnrecordable` is computed up beside $hasPending; it carries
    # HasPendingVerdict=$false — there is genuinely nothing to approve — so it can never reach
    # $boundaryBlock, and before this the provider fell silent and a brand-new project's first
    # boundary passed with no enforcement surface at all (T087 case 2). It gets its own block kind,
    # deliberately NOT 'boundary': no approval options, no verdict marker, and no marker-suppression
    # check, because there is no crossing to approve.
    $boundaryBlock = $hasPending -and (-not $markerForPendingCrossing)
    $materialAlreadySatisfied = $materialStop -and (-not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) -and ([string]$materialSignal.key -eq [string]$materialSatisfiedKey)
    $materialInitialBlock = (-not $hasPending) -and $materialStop -and (-not $packetPresent) -and (-not $materialAlreadySatisfied)
    $materialRetryBlock = (-not $hasPending) -and (-not [string]::IsNullOrWhiteSpace($materialRetryKey)) -and (-not $packetPresent)
    $materialBlock = $materialInitialBlock -or $materialRetryBlock
    # FR-068 (T090): stage-evidence absence PRE-EMPTS the ordinary boundary block, so the demand and
    # its marker instruction are never composed. It deliberately does NOT clear $hasPending.
    # certify f2 (run-f198-beta2-c0c3cda6-certify): the evidence-absent refusal must NOT be
    # defeated by a pre-rendered marker. Keying the first arm on $boundaryBlock let
    # StageEvidenceAbsent=true plus a guessed/stale matching marker fall through to 'none' — no
    # refusal composed, and the stale marker could feed verdict capture. The refusal now keys on
    # $hasPending directly: while the stage owes evidence it has not produced, the missing-evidence
    # block composes regardless of any marker already in the transcript.
    # --- W25 ORIENTATION LANE: THE HUMAN MUST ACTUALLY SEE THE SESSION ORIENTATION -------------------
    #
    # W23 tried instruction alone - the session directive AND the always-loaded project instructions both
    # carry the obligation - and the very next controlled walk skipped it anyway, with both texts deployed
    # and SessionStart delivered in full mode. The recorded ruling named that outcome as the trigger to
    # build this check rather than sharpen the wording a second time.
    #
    # SCOPED SO IT IS NOT A PER-STOP COST, which was the objection to building it at all:
    #   - it only evaluates while this session has no orientation receipt (one Test-Path once satisfied),
    #   - it only evaluates when a bootstrap was actually DELIVERED to this session (a render claim exists),
    #   - it is the LOWEST-priority block, so it never displaces a boundary, workshop or material demand -
    #     it rides along as an extra line on those, and only stands alone when nothing else blocks,
    #   - and it fails OPEN on every error, unreadable path and unassessable turn.
    $orientationOwed = $false
    $orientationSatisfiedNow = $false
    if ($canAssess -and -not [string]::IsNullOrWhiteSpace([string]$materialRuntime.OrientationPath)) {
        try {
            if (-not (Test-Path -LiteralPath ([string]$materialRuntime.OrientationPath) -PathType Leaf)) {
                # A bootstrap was delivered to THIS session when its render claim exists. Without one there
                # is nothing the agent was handed to show, so nothing is owed.
                $claimDelivered = $false
                try {
                    $runtimeDir = Join-Path $projectRoot '.specrew/runtime'
                    if (Test-Path -LiteralPath $runtimeDir -PathType Container) {
                        $claimDelivered = @(Get-ChildItem -LiteralPath $runtimeDir -Filter 'hook-bootstrap-render-*.json' -File -ErrorAction SilentlyContinue).Count -gt 0
                    }
                }
                catch { $claimDelivered = $false }
                if ($claimDelivered) {
                    # W35: LOOK WHERE THE ORIENTATION ACTUALLY IS - THE OPENING MESSAGE.
                    #
                    # This tested $lastAssistantText only, and the obligation is that a session OPENS by
                    # orienting the human. So the orientation lands in message 1 and the check ran against
                    # message N, which is a different message on every stop but the first.
                    #
                    # Measured 2026-08-20 (KeyContextAI, session e9c42e87): the opening message DOES clear
                    # this bar - it is a full banner - and only 2 of that session's 190 assistant messages
                    # do. Every stop whose last message was one of the other 188 told a compliant session
                    # "your orientation was handed to you and the human never saw it". Third instance of a
                    # detector punishing compliant output, after W16's bullet glyphs and W35's prose scan.
                    #
                    # So candidates are the HEAD of the transcript (where the orientation belongs) as well
                    # as the last assistant text. Cost is bounded and self-limiting: this runs only while
                    # the receipt is absent, and the receipt is written the moment it is satisfied - so a
                    # session pays for the head read at most a handful of times, never per stop.
                    $orientationCandidates = [System.Collections.Generic.List[string]]::new()
                    if (-not [string]::IsNullOrWhiteSpace($lastAssistantText)) { [void]$orientationCandidates.Add([string]$lastAssistantText) }
                    if ($ccLoaded -and -not [string]::IsNullOrWhiteSpace($transcriptPathArg) -and
                        (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf) -and
                        (Get-Command Get-SpecrewConversationTurnFromLine -ErrorAction SilentlyContinue)) {
                        try {
                            foreach ($headLine in @(Get-Content -LiteralPath $transcriptPathArg -TotalCount 200 -Encoding UTF8 -ErrorAction Stop)) {
                                $headTurn = Get-SpecrewConversationTurnFromLine -Line $headLine
                                if ($null -ne $headTurn -and [string]$headTurn.role -eq 'assistant' -and
                                    -not [string]::IsNullOrWhiteSpace([string]$headTurn.text)) {
                                    [void]$orientationCandidates.Add([string]$headTurn.text)
                                }
                            }
                        }
                        catch { $null = $_ }
                    }
                    # A rendered orientation names the product AND at least one thing only the orientation
                    # carries: the resolved version, or what the crew believes about the human. Deliberately
                    # a LOW bar - any genuine banner clears it, and a reply that goes straight to work does
                    # not. It never demands particular wording, because the banner is free prose.
                    $orientationSatisfiedNow = $false
                    foreach ($candidateText in $orientationCandidates) {
                        $namesProduct = $candidateText -match '(?i)\bspecrew\b'
                        $namesOrientationFact = ($candidateText -match '(?i)what I know about you') -or
                            ($candidateText -match '(?i)/specrew-user-profile') -or
                            ($candidateText -match '(?i)\bspecrew\b[^\n]{0,40}\b\d+\.\d+\.\d+')
                        if ($namesProduct -and $namesOrientationFact) { $orientationSatisfiedNow = $true; break }
                    }
                    if (-not $orientationSatisfiedNow) { $orientationOwed = $true }
                }
            }
        }
        catch { $orientationOwed = $false }
    }
    # W47 (2026-08-23): SOURCE WRITTEN WHERE THE STATE STOOD. The state-advance check watches the
    # cursor, and on the KeyContextAI walk the cursor never moved - the session committed product
    # source at `tasks` with the hardening gate blocked and no crossing minted, and nothing fired.
    # This is the live half of the enforcement (the validator FAILs at rest): on a material stop,
    # product source that changed since the last authorized pre-implement boundary refuses the stop
    # and names the missing verdict. Gated on material stops so trivial stops never pay the git cost.
    $unauthorizedSourceBlock = $false
    $unauthorizedSourceDrift = $null
    if ($materialStop -and (Get-Command Get-SpecrewUnauthorizedSourceDrift -ErrorAction SilentlyContinue)) {
        try { $unauthorizedSourceDrift = Get-SpecrewUnauthorizedSourceDrift -ProjectRoot $projectRoot } catch { $unauthorizedSourceDrift = $null }
        if ($null -ne $unauthorizedSourceDrift -and [bool]$unauthorizedSourceDrift.checked -and [bool]$unauthorizedSourceDrift.pre_implement -and
            (@($unauthorizedSourceDrift.committed_source).Count + @($unauthorizedSourceDrift.uncommitted_source).Count) -gt 0) {
            $unauthorizedSourceBlock = $true
        }
    }
    # W52: EXHAUSTION IS A DECISION, NOT A CONDITION. When the round allowance is exhausted AND new
    # product source exists beyond the last DELIVERED review, coverage is actually falling behind -
    # and that gets ONE first-class decision stop, not silence and not a nag. Exhaustion with zero
    # source drift stays silent (planning is not uncovered work). A recorded deferral - the human's
    # typed `continue without coverage until the review phase` - keeps it silent until the review
    # phase, because CHOSEN absence is honest; ACCUMULATED absence is the thing this release exists
    # to prevent. Gated on material stops with implementation authorized, so trivial stops and
    # pre-implement stages never pay the coverage math.
    $coverageDecisionBlock = $false
    $coverageDecisionState = $null
    if ($materialStop -and -not $unauthorizedSourceBlock -and
        $null -ne $unauthorizedSourceDrift -and [string]$unauthorizedSourceDrift.reason -ceq 'implementation-authorized' -and
        (Get-Command Get-SpecrewReviewCoverageState -ErrorAction SilentlyContinue)) {
        try {
            $coverageDecisionState = Get-SpecrewReviewCoverageState -ProjectRoot $projectRoot
            if ($null -ne $coverageDecisionState -and [bool]$coverageDecisionState.available -and
                [bool]$coverageDecisionState.exhausted -and [int]$coverageDecisionState.source_drift_count -gt 0) {
                $coverageDeferral = $null
                if (Get-Command Get-SpecrewCoverageDeferralAuthorization -ErrorAction SilentlyContinue) {
                    try { $coverageDeferral = Get-SpecrewCoverageDeferralAuthorization -ProjectRoot $projectRoot } catch { $coverageDeferral = $null }
                }
                # A deferral recorded AGAINST THIS COVERAGE STATE silences the stop; one that
                # predates the last delivered review - or that source has moved PAST since the human
                # deferred (round-12 finding, DRIFT-199-I001-120) - no longer describes anything and
                # does not. The ONE shared currency decision lives in shared-governance.
                $deferralCurrent = $false
                if ($null -ne $coverageDeferral -and (Get-Command Test-SpecrewCoverageDeferralCurrent -ErrorAction SilentlyContinue)) {
                    # SPECREW-AUTHORITY-CONSUMER: coverage-deferral
                    try { $deferralCurrent = [bool](Test-SpecrewCoverageDeferralCurrent -ProjectRoot $projectRoot -Deferral $coverageDeferral -CoverageState $coverageDecisionState) } catch { $deferralCurrent = $false }
                }
                if (-not $deferralCurrent) { $coverageDecisionBlock = $true }
            }
        }
        catch { $coverageDecisionBlock = $false }
    }
    $blockKind = if ($hasPending -and $stageEvidenceAbsent) { 'boundary-evidence-absent' } elseif ($boundaryBlock) { 'boundary' } elseif ($boundaryUnrecordable) { 'boundary-unrecordable' } elseif ($workshopConflict) { 'workshop-conflict' } elseif ($workshopRepair -or $missingWorkshopController -or $workshopAgendaPresentationMissing -or $preScaffoldWorkshopAttempt -or $workshopProductRecordMissingAgenda -or $workshopAgendaReformatted -or $workshopProductRecordsUnreceipted) { 'workshop-repair' } elseif ($unauthorizedSourceBlock) { 'unauthorized-source' } elseif ($coverageDecisionBlock) { 'coverage-decision' } elseif ($materialBlock) { 'material' } elseif ($orientationOwed) { 'orientation' } else { 'none' }

    # --- FR-045a STOP-INTENT classification (SAFETY-CRITICAL; FAIL-SAFE) --------------------------------------------
    # Classify this Stop as continue|intermediate|real BEFORE the material-work packet enforcement, so an authorized
    # in-phase workflow is neither stalled behind a status packet (continue) nor falsely handed back while owned async
    # is in flight (intermediate). STRICTLY SCOPED to a MATERIAL, packet-less, non-boundary stop we could actually read
    # ($blockKind -eq 'material' -and $canAssess). BOUNDARY stops, 'none', an unavailable classifier, and EVERY error
    # leave $stopIntentOutcome at its 'real' default -> today's real-stop enforcement is preserved byte-for-byte. The
    # classifier is dot-sourced fail-open: the ONE pure, self-contained contract file (sibling of bootstrap; no _load).
    $stopIntentOutcome = if ($workshopConflict) { 'workshop-conflict' } elseif ($workshopRepair -or $missingWorkshopController -or $workshopAgendaPresentationMissing -or $preScaffoldWorkshopAttempt -or $workshopProductRecordMissingAgenda -or $workshopAgendaReformatted -or $workshopProductRecordsUnreceipted) { 'workshop-repair' } else { 'real' }
    $stopIntentReason = $null
    $stopIntentContinueKey = $null
    $stopIntentContinueCount = 0
    # WORKSHOP-RECORD-ONLY TURNS DO NOT OWE A MATERIAL PACKET.
    #
    # Measured across one Claude workshop: the exemption fired 9 times and failed 3, and all three
    # failures were the SAME turn shape - persist the previous lens, then present the next lens question.
    # That is the shape EVERY lens boundary produces. Material-work enforcement keys off the rolling
    # handover Stop snapshot, so persisting the lens record MOVES the material surface, and the material
    # path won over a workshop question that was otherwise proved.
    #
    # Precedence by ruling: the material that moved IS the workshop record for the question just
    # answered, and it cannot surprise the human who co-authored it. So a turn whose entire changed set
    # lies inside the workshop record set does not owe a packet.
    #
    # THE GUARD IS THE POINT: touch anything outside that set and material-work wins exactly as today.
    # This narrows the exemption to the turn shape that produced the duplicates; it does not weaken
    # material-work enforcement for real work that happens to coincide with a workshop.
    #
    # The exact durable workshop classification proves the exception is in scope; changed_paths then decides
    # precedence. Unknown or empty paths, or any path outside the workshop record set, fall through to today's
    # material-work behavior (block), which is fail-closed.
    $workshopRecordOnlyTurn = $false
    # The paths that cost this turn its workshop exemption. The enforcement decision does not need them;
    # the human does. Without them the correction says "render a packet" in the middle of a design
    # conversation and names nothing the human can act on.
    $workshopOutsidePaths = @()
    $preAgendaUntouchedScaffoldTurn = ($workshopIntermediate -and
        [string]$workshopQuestion.scope -eq 'feature' -and
        [string]$workshopQuestion.lens -eq 'product-domain' -and
        [string]$workshopQuestion.agenda_status -eq 'pending-confirmation' -and
        (Test-SpecrewUntouchedFeatureSpecScaffold -ProjectRoot $projectRoot -FeatureRef ([string]$workshopQuestion.feature_ref)))
    $preAgendaSpecPath = if ($preAgendaUntouchedScaffoldTurn) { ("specs/{0}/spec.md" -f [string]$workshopQuestion.feature_ref) } else { $null }
    if ($blockKind -eq 'material' -and $canAssess -and $null -ne $materialSignal) {
        $turnPaths = @()
        try { $turnPaths = @($materialSignal.changed_paths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) }
        catch { $turnPaths = @() }
        if (@($turnPaths).Count -gt 0) {
            $outsideWorkshop = @($turnPaths | Where-Object {
                    $normalizedTurnPath = ([string]$_).Replace([char]92, [char]47)
                    -not ($normalizedTurnPath -match '(^|/)workshop/' -or
                        $normalizedTurnPath -match '(^|/)lens-applicability\.json$' -or
                        $normalizedTurnPath -match '(^|/)\.specrew/handover/workshop-question\.json$' -or
                        ($preAgendaUntouchedScaffoldTurn -and $normalizedTurnPath.Equals($preAgendaSpecPath, [StringComparison]::OrdinalIgnoreCase)) -or
                        # W26: PROJECT DOCUMENTATION THE HUMAN ASKED FOR IS NOT A SURPRISE EITHER.
                        #
                        # The exemption's own ruling says a workshop-record turn is exempt because "the
                        # material that moved IS the workshop record for the question just answered, and it
                        # cannot surprise the human who co-authored it". A README the human asked for in
                        # that same conversation cannot surprise them either - but the rule proxied
                        # "co-authored" as "path is a workshop record", so asking for a README mid-workshop
                        # produced a five-heading re-entry packet about a file the human had just requested.
                        # Measured 2026-08-19 (KeyContextAI walk): correct enforcement, wrong proportion.
                        #
                        # Scoped to an ACTIVE WORKSHOP and to ordinary repo documentation. Everything the
                        # guard exists for is untouched: `specs/` stays outside (premature spec authoring is
                        # the drift it catches), and so does every source, test, script and machinery path.
                        ($workshopIntermediate -and
                            $normalizedTurnPath -notmatch '^specs/' -and
                            ($normalizedTurnPath -match '(?i)(^|/)(README|LICENSE|LICENCE|NOTICE|CHANGELOG|CONTRIBUTING|CODE_OF_CONDUCT|SECURITY|SUPPORT)(\.[A-Za-z0-9]+)?$' -or
                             $normalizedTurnPath -match '(?i)(^|/)\.(gitignore|gitattributes|editorconfig)$' -or
                             $normalizedTurnPath -match '(?i)^docs/')))
                })
            $workshopRecordOnlyTurn = (@($outsideWorkshop).Count -eq 0)
            if ($workshopIntermediate) { $workshopOutsidePaths = @($outsideWorkshop | Select-Object -First 3) }
        }
    }
    # A valid pre-agenda controller normally proves an intermediate question. It must not suppress the targeted
    # repair when the visible turn nevertheless opened a technical lens before the agenda decision: the state is
    # valid precisely because it still says product-domain/pending-confirmation, which is the evidence of drift.
    $workshopQuestionWins = $workshopIntermediate -and (-not $workshopAgendaPresentationMissing) -and
        (-not $workshopProductRecordMissingAgenda) -and (-not $workshopAgendaReformatted) -and
        (-not $workshopProductRecordsUnreceipted) -and
        (($blockKind -ne 'material') -or $workshopRecordOnlyTurn)
    if ($workshopQuestionWins) {
        $stopIntentOutcome = 'workshop-intermediate'
        $stopIntentReason = [string]$workshopQuestion.reason
    }
    if ($blockKind -eq 'material' -and $canAssess -and (-not $workshopRecordOnlyTurn)) {
        try {
            if (-not (Get-Command Resolve-ContinuousCoReviewStopIntent -ErrorAction SilentlyContinue) -and -not [string]::IsNullOrWhiteSpace($bootstrapDir)) {
                $stopIntentPath = Join-Path (Split-Path $bootstrapDir -Parent) 'continuous-co-review/stop-intent-contract.ps1'
                if (Test-Path -LiteralPath $stopIntentPath -PathType Leaf) { try { . $stopIntentPath } catch { $null = $_ } }
            }
            if (Get-Command Resolve-ContinuousCoReviewStopIntent -ErrorAction SilentlyContinue) {
                $markerIntent = Get-ContinuousCoReviewStopIntentMarkerIntent -Text $lastAssistantText
                # The GATE half of marker-and-gate: lifecycle confirms an already-authorized phase AND no pending
                # boundary to cross. The marker alone never self-authorizes; the phase alone never proves work remains.
                $authorizedWorkRemains = $hasBoundaryAuthorization -and $hasActiveLifecycleBoundary -and (-not $hasPending)
                # Continue loop-guard: a CHANGED material surface key = intervening progress = read as 0; an UNCHANGED
                # key accumulates. At the bound the classifier returns 'real' (the runaway-continue fallback to a packet).
                $stopIntentContinueKey = 'continue|' + [string]$materialSignal.key
                try {
                    if (Test-Path -LiteralPath $continueGuardPath -PathType Leaf) {
                        $cg = Get-Content -LiteralPath $continueGuardPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                        if (($cg.PSObject.Properties.Name -contains 'key') -and ([string]$cg.key -eq $stopIntentContinueKey) -and ($cg.PSObject.Properties.Name -contains 'count')) {
                            $stopIntentContinueCount = [int]$cg.count
                        }
                    }
                }
                catch { $null = $_ }
                $continueGuardTripped = $stopIntentContinueCount -ge $script:SpecrewContinueLoopGuardBound
                # v1 primary signals: the current-turn marker contract + the lifecycle boundary gate. UserActionRequired
                # / AgentBlockedOrHandingBack / RequestedWorkComplete stay at their $false defaults - a same-stop review
                # request / hand-back / completion is NOT inferred here in v1 (the marker is the agent's explicit continue
                # assertion, the gate is authorization). OwnedWorkInFlight / RuntimeWorkKnownTerminal are host-native
                # async signals this provider does not track (an `intermediate` marker is the async fallback).
                $intent = Resolve-ContinuousCoReviewStopIntent -LifecycleBoundaryPending:$hasPending -MarkerIntent $markerIntent -MarkerFromAssistant:$true -AuthorizedWorkRemains:$authorizedWorkRemains -OwnedWorkInFlight:$false -RuntimeWorkKnownTerminal:$false -ContinueLoopGuardTripped:$continueGuardTripped
                if ($null -ne $intent -and -not [string]::IsNullOrWhiteSpace([string]$intent.outcome)) {
                    $stopIntentOutcome = [string]$intent.outcome
                    $stopIntentReason = [string]$intent.reason
                }
            }
        }
        catch { $stopIntentOutcome = 'real'; $stopIntentReason = $null }  # FAIL-SAFE: any error -> the existing enforcement.
    }
    # Only a MATERIAL stop can flip these off 'real' (boundary/'none' never reach the classifier), so an unexpected
    # outcome keeps $blockWarranted true (fails toward enforcement). Continue emits its own directive below; intermediate
    # simply ends the turn (its async completion resumes the agent).
    $stopIntentContinue = ($stopIntentOutcome -eq 'continue')
    $stopIntentIntermediate = ($stopIntentOutcome -in @('intermediate', 'workshop-intermediate'))
    $blockWarranted = $canAssess -and ($blockKind -ne 'none') -and (-not $stopIntentContinue) -and (-not $stopIntentIntermediate)

    $journalPath = Join-Path $projectRoot '.specrew/runtime/conformance-journal.jsonl'
    $blockReason = $null
    $corrections = New-Object System.Collections.Generic.List[string]
    $capped = $false
    $cappedKind = $null
    $capAnnounced = $false
    # The advance identity the consecutive-block cap keys on: a boundary advance is working|lastAuth; a material
    # non-boundary stop is keyed by the current handover snapshot. A NEW advance/snapshot starts a fresh count; the agent
    # rendering the packet (not blockWarranted) resets it. No time window (145 HANG-1).
    # The if-guard also protects the $pending null-deref under the leaked StrictMode; the else value is an unused
    # placeholder ($advanceKey is read only inside the blockWarranted branch, which implies $hasPending; 145 SC-3).
    $advanceKey = if ($blockKind -eq 'boundary' -and $hasPending) {
        ("{0}|{1}" -f [string]$pending.WorkingBoundary, [string]$pending.LastAuthorizedBoundary)
    }
    elseif ($blockKind -eq 'coverage-decision') {
        ("coverage-decision|{0}|{1}" -f [string]$coverageDecisionState.campaign_id, [string]$coverageDecisionState.covered_tree)
    }
    elseif ($blockKind -eq 'unauthorized-source') {
        ("unauthorized-source|{0}|{1}" -f [string]$unauthorizedSourceDrift.authorized_boundary, [string]$unauthorizedSourceDrift.anchor_commit)
    }
    elseif ($blockKind -eq 'material' -and $materialInitialBlock -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
        [string]$materialSignal.key
    }
    elseif ($blockKind -eq 'material' -and -not [string]::IsNullOrWhiteSpace($materialRetryKey)) {
        [string]$materialRetryKey
    }
    elseif ($blockKind -eq 'workshop-conflict') {
        $conflict = $workshopQuestion.binding_conflict
        ("workshop-conflict|{0}|{1}|{2}|{3}" -f [string]$workshopQuestion.feature_ref, [string]$conflict.binding, [string]$conflict.prior_value, [string]$conflict.value)
    }
    elseif ($blockKind -eq 'workshop-repair') {
        $repairReason = if ($preScaffoldWorkshopAttempt) { 'workshop-feature-not-created' } elseif ($workshopProductRecordMissingAgenda) { 'workshop-product-records-not-persisted' } elseif ($workshopProductRecordsUnreceipted) { 'workshop-product-records-unreceipted' } elseif ($workshopAgendaReformatted) { 'workshop-agenda-reformatted' } elseif ($workshopAgendaPresentationMissing) { 'workshop-agenda-not-confirmed' } else { [string]$workshopQuestion.reason }
        $repairFeature = if ($preScaffoldWorkshopAttempt) { 'unscaffolded' } else { [string]$workshopQuestion.feature_ref }
        ("workshop-repair|{0}|{1}" -f $repairFeature, $repairReason)
    }
    # certify f3: boundary-evidence-absent and boundary-unrecordable get their OWN advance keys so
    # the cap tracks each refused surface distinctly instead of pooling them under 'na'.
    elseif ($blockKind -eq 'boundary-evidence-absent' -and $null -ne $pending) {
        ("evidence-absent|{0}|{1}" -f [string]$pending.WorkingBoundary, [string]$pending.LastAuthorizedBoundary)
    }
    elseif ($blockKind -eq 'orientation') {
        # Keyed per session so the cap counts THIS session's unshown orientation, not a pooled 'na'.
        ("orientation|{0}" -f [string]$materialRuntime.Owner)
    }    elseif ($blockKind -eq 'boundary-unrecordable' -and $null -ne $pending) {
        ("unrecordable|{0}" -f [string]$pending.WorkingBoundary)
    }
    else { 'na' }

    if ($stopIntentContinue) {
        # FR-045a CONTINUE: the current assistant turn declares the `continue` marker AND lifecycle authorization
        # confirms remaining in-phase work. Do NOT render the five-part material packet; force-continue the turn with a
        # SHORT continuation directive so the agent performs the NEXT authorized action (never another status packet).
        # Increment the dedicated continue loop-guard for THIS material surface; once it reaches the bound the classifier
        # returns 'real' (above) and the standard material packet fires instead - a runaway continue cannot loop forever.
        $null = Set-SpecrewBlockCount -Path $continueGuardPath -Key $stopIntentContinueKey -Count ($stopIntentContinueCount + 1)
        $sbC = New-Object System.Text.StringBuilder
        [void]$sbC.AppendLine('Specrew: CONTINUATION DIRECTIVE - your last turn declared the continue marker while an already-authorized in-phase workflow still has remaining work. Continue the existing authorized workflow and perform the NEXT authorized action NOW, then stop again. Do NOT render a status packet; this is an internal continuation, not a human hand-back.')
        if (-not [string]::IsNullOrWhiteSpace($stopIntentReason)) { [void]$sbC.AppendLine(('Reason: {0}' -f $stopIntentReason)) }
        $blockReason = $sbC.ToString().TrimEnd()
    }
    elseif ($blockWarranted) {
        $count = Get-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey
        if ($count -ge $script:SpecrewBlockCap) {
            # Over the consecutive-block cap - stop blocking to avoid a hang; degrade to a plain nudge this turn.
            $capped = $true
            $cappedKind = $blockKind
            $capSubject = if ($blockKind -eq 'material') { 'material-work packet' } elseif ($blockKind -eq 'workshop-conflict') { 'workshop decision reconciliation' } elseif ($blockKind -eq 'workshop-repair') { 'workshop record repair' } elseif ($blockKind -eq 'boundary-evidence-absent') { 'stage evidence' } elseif ($blockKind -eq 'boundary-unrecordable') { 'boundary recording' } elseif ($blockKind -eq 'unauthorized-source') { 'implementation authorization' } elseif ($blockKind -eq 'coverage-decision') { 'coverage decision' } elseif ($blockKind -eq 'orientation') { 'session orientation' } else { 'verdict marker' }
            [Console]::Error.WriteLine(("[specrew-conformance] WARN STOP_BLOCK_CAP {0} still absent or wrong after {1} consecutive blocks; releasing the stop (degrading to a nudge) to avoid a hang." -f $capSubject, $count))
            # W53 (DRIFT-199-I001-119): AN EXEMPTION-BY-EXHAUSTION IS A DOCUMENTED EVENT, NOT AN
            # AMBIENT STATE. The corrections below are real, but on a claude Stop they ride plain
            # stdout, which the host does not deliver to the model - so the cap was invisible in the
            # exact transcript a human reads, and "complied" and "outlasted" looked identical (the
            # maintainer caught it from the store, from outside). The FIRST capped stop therefore
            # announces itself through the one channel that reaches the transcript: one more block,
            # whose only demand is the one-line notice in the final permitted output. The fact is
            # written and read back BEFORE the block fires (the counter's own 145 HANG-2 rule), so
            # an unverifiable write degrades to the silent-release path instead of adding an
            # unrecorded block - and the fact's presence is what keeps this to ONE extra turn.
            $capFactPath = Get-SpecrewCapFactPath -Runtime $materialRuntime
            if (-not (Test-SpecrewCapFactRecorded -Path $capFactPath -Key $advanceKey)) {
                $capFact = [pscustomobject]@{
                    schema_version = '1.0'; fact_type = 'conformance-cap-reached'
                    advance_key = [string]$advanceKey; block_kind = [string]$blockKind; subject = [string]$capSubject
                    cap = [int]$script:SpecrewBlockCap; owner = [string]$materialRuntime.Owner
                    recorded_at = ([System.DateTimeOffset]::UtcNow.ToString('o'))
                }
                if (Write-SpecrewCapFact -Path $capFactPath -Fact $capFact) {
                    $capAnnounced = $true
                    $sbCap = New-Object System.Text.StringBuilder
                    [void]$sbCap.AppendLine(('Specrew: this stop was refused {0} consecutive times for the same unmet requirement ({1}), and the refusal cap has now released it - Specrew is no longer holding your turns. Render the message you were going to render, and include this exact line in it, so a reader of the transcript can tell that enforcement ended rather than the requirement being met:' -f $count, $capSubject))
                    [void]$sbCap.AppendLine('')
                    [void]$sbCap.AppendLine(('Specrew: packet discipline capped for this session after {0} refusals - {1} is still unmet.' -f $count, $capSubject))
                    [void]$sbCap.AppendLine('')
                    [void]$sbCap.AppendLine('The requirement itself is unchanged and still yours to meet; this notice documents that it is now on you rather than on the hook. Do not present boundary-verdict options and do not add any approval comment that the released requirement itself did not call for - asking for the evidence-producing approvals the requirement itself names remains your job.')
                    $blockReason = $sbCap.ToString().TrimEnd()
                }
            }
        }
        elseif (Set-SpecrewBlockCount -Path $blockStatePath -Key $advanceKey -Count ($count + 1)) {
            # Block ONLY when the increment durably persisted (145 HANG-2): a host without a built-in cap relies on
            # this counter, so an unverifiable write must NOT start an uncappable loop.
            # Build the packet directive. At a boundary, include the CONTIGUOUS last_authorized -> successor marker.
            $sb = New-Object System.Text.StringBuilder
            if ($blockKind -eq 'boundary') {
                [void]$sb.AppendLine('Specrew: boundary state is pending, but your last message did not expose the verdict marker for the pending boundary crossing. Render the full six-section re-entry packet NOW as your message, then stop again:')
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## Discussion Prompts / ## What I Need From You')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                $fromBoundary = if ($null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) { [string]$pendingCrossing.PendingFromMarkerBoundary } else { $null }
                $toBoundary = if ($null -ne $pendingCrossing -and [bool]$pendingCrossing.HasPendingVerdict) { [string]$pendingCrossing.PendingToMarkerBoundary } else { [string]$pending.WorkingBoundary }
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine([string]$pending.Message)
                if (-not [string]::IsNullOrWhiteSpace($fromBoundary)) {
                    [void]$sb.AppendLine(("This is a BOUNDARY stop ({0} -> {1}); emit the verdict marker as the LAST line: <!-- SPECREW-VERDICT-BOUNDARY: {0} -> {1} -->" -f $fromBoundary, $toBoundary))
                }
                else {
                    [void]$sb.AppendLine(("This is a BOUNDARY stop into '{0}' (the first unauthorized boundary); emit the contiguous verdict marker as the LAST line." -f $toBoundary))
                }
                [void]$sb.AppendLine('Do NOT record the authorization yourself; the verdict is captured from your rendered packet + the human''s reply.')
            }
            elseif ($blockKind -eq 'boundary-evidence-absent') {
                # FR-068: names what the stage owes, offers no approval options, emits no marker.
                # The crossing remains pending, so if the human approves anyway their verdict is still
                # captured — suppressing the demand must not suppress the capture.
                [void]$sb.AppendLine([string]$pending.Message)
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine('Report this plainly and name the missing artifact(s). Do NOT present boundary-verdict options and do NOT emit a verdict marker: the stage has produced nothing to approve, and a verdict recorded now would be indistinguishable in the ledger from an approval of real work. Asking for the evidence-producing approvals the requirement itself names remains your job.')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
            }
            elseif ($blockKind -eq 'boundary-unrecordable') {
                # FR-066 amended MUST: the surface MUST speak and MUST name what is missing. It also
                # MUST NOT present approval options or a verdict marker — there is no recorded
                # crossing, so approving would authorize nothing. Both halves are load-bearing:
                # silence hides the boundary, and a marker here would capture a verdict against a
                # crossing that does not exist.
                [void]$sb.AppendLine([string]$pending.Message)
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine('Tell the human plainly: a lifecycle boundary was reached, it could NOT be recorded, and what is missing. Do NOT present boundary-verdict options and do NOT emit a verdict marker - there is no crossing to approve, and approving an unrecorded crossing would authorize nothing. Asking for the evidence-producing approvals the requirement itself names remains your job.')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
            }
            elseif ($blockKind -eq 'unauthorized-source') {
                # W47: the no-code-without-approval refusal, at the moment it can still be cheap. The
                # session is told to STOP implementing, not to hide what happened: the work is surfaced
                # to the human, and the two honest exits are the verdict or the revert - both theirs.
                $w47Committed = @($unauthorizedSourceDrift.committed_source)
                $w47Uncommitted = @($unauthorizedSourceDrift.uncommitted_source)
                $w47Shown = @(@($w47Committed + $w47Uncommitted) | Select-Object -First 5) -join ', '
                if (($w47Committed.Count + $w47Uncommitted.Count) -gt 5) { $w47Shown = "$w47Shown (+$(($w47Committed.Count + $w47Uncommitted.Count) - 5) more)" }
                [void]$sb.AppendLine(("Specrew: product source has been written, but implementation has not been approved. The last authorized boundary is '{0}', and the ledger holds no 'approved for before-implement' - so this code is outside the process this project follows, whoever wrote it and however good it is. Changed source: {1}." -f [string]$unauthorizedSourceDrift.authorized_boundary, $w47Shown))
                [void]$sb.AppendLine('STOP implementing now. Do not write or modify further product source this turn, and do not record any authorization yourself.')
                [void]$sb.AppendLine('Tell the human plainly what was written and why you believed it was licensed - if a rule or an approval read as an implementation go-ahead, quote it, because the wording is then part of the defect. Their code is safe either way.')
                # W49 applied here by maintainer ruling: this menu numbers TWO DISTINCT DECISIONS (unlike
                # boundary packets, whose numbers only index discussion prompts inside one typed phrase),
                # and a typed `1` at this surface was already quoted as an implementation licence on the
                # first live firing. So it takes the pause-menu shape: typed decisions with the
                # consequence stated on each, never numbered.
                [void]$sb.AppendLine('Then present their two decisions the way this system presents every decision - typed replies with the consequence stated on each, and NEVER numbered (a bare number is never an authorization here, and the first live firing collected exactly that misreading):')
                [void]$sb.AppendLine('  - `approved for before-implement` - licenses the written work retroactively and implementation proceeds; this reply comes AFTER the preparation, so first complete the hardening gate, run the boundary sync, and present the packet')
                [void]$sb.AppendLine('  - `revert the source changes` - the unauthorized files are reverted, nothing is licensed, and the project returns to where the process stands')
                [void]$sb.AppendLine('Wait for one of those typed replies; nothing advances until the human gives one.')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
            }
            elseif ($blockKind -eq 'coverage-decision') {
                # W52: the one-time decision stop, in the typed-decision shape. The middle option is
                # the crucial one - running uncovered becomes a CHOSEN, RECORDED fact the signoff gate
                # can later distinguish from nobody noticing.
                $w52Line = if (Get-Command Get-SpecrewReviewCoverageLine -ErrorAction SilentlyContinue) { [string](Get-SpecrewReviewCoverageLine -ProjectRoot $projectRoot) } else { '' }
                [void]$sb.AppendLine('Specrew: your review allowance is exhausted, and product source has moved beyond the last delivered review - coverage is now falling behind, and running without it is a decision only the human can make.')
                if (-not [string]::IsNullOrWhiteSpace($w52Line)) { [void]$sb.AppendLine($w52Line) }
                [void]$sb.AppendLine('Present their three decisions the way this system presents every decision - typed replies with the consequence stated on each, never numbered:')
                [void]$sb.AppendLine('  - `approved for allowance reset` - replenishes the review rounds; you then run the reset with their reason and reviews resume')
                [void]$sb.AppendLine('  - `continue without coverage until the review phase` - implementation continues uncovered, and their choice is RECORDED so the review phase knows the absence was deliberate, not unnoticed')
                [void]$sb.AppendLine('  - `hold implementation here` - no further product source until they decide otherwise; nothing is recorded and nothing runs')
                [void]$sb.AppendLine('Each decision is their typed reply as a normal chat message - a reply inside a question UI or picker is not captured.')
                [void]$sb.AppendLine('Wait for one of those typed replies. Do not continue writing product source while this decision is theirs to make, and never record a decision on their behalf.')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
            }
            elseif ($blockKind -eq 'workshop-conflict') {
                $conflict = $workshopQuestion.binding_conflict
                [void]$sb.AppendLine(("Specrew paused this workshop because two recorded answers disagree: decision '{0}' was '{1}' in '{2}' and is now '{3}' in '{4}'. Do not continue to another topic yet. If the later answer came from a default, keep the earlier human-confirmed answer. If the human intentionally changed it, ask one concise question to confirm which answer should apply, then update the affected workshop records consistently." -f $conflict.binding, $conflict.prior_value, $conflict.prior_lens, $conflict.value, $conflict.lens))
                if (-not (Get-Command Get-SpecrewWorkshopRefusalContractText -ErrorAction SilentlyContinue)) {
                    $workshopAuthorityPath = Join-Path $projectRoot '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
                    if (Test-Path -LiteralPath $workshopAuthorityPath -PathType Leaf) { . $workshopAuthorityPath }
                }
                if (Get-Command Get-SpecrewWorkshopRefusalContractText -ErrorAction SilentlyContinue) {
                    [void]$sb.AppendLine((Get-SpecrewWorkshopRefusalContractText))
                }
                else {
                    [void]$sb.AppendLine('Try the action above once. If it does not resolve the situation, do not retry and do not edit this project''s workshop records by hand. Tell the human calmly what you were doing, that their answers are safe and nothing has been lost, what you could not complete without assigning blame, and one concrete next action you can take. Ask the human for approval before taking that action.')
                }
            }
            elseif ($blockKind -eq 'workshop-repair') {
                if ($preScaffoldWorkshopAttempt) {
                    [void]$sb.AppendLine('The product discussion started before this feature had a working area where its answer could be kept. Create the feature with the project-provided feature setup action, then show the same product question again. Do not treat an earlier reply as recorded authority.')
                }
                elseif ($workshopProductRecordMissingAgenda) {
                    [void]$sb.AppendLine('The technical topics were shown before the product grounding was recorded. Record the product grounding from its typed answer first, then show the complete technical-topic selection once. Do not ask for another agenda confirmation first; it cannot be retained until that earlier record exists.')
                }
                elseif ($workshopProductRecordsUnreceipted) {
                    [void]$sb.AppendLine('The recorded product answers arrived through a selection channel (a structured picker or a dismissed question UI), so no typed human reply stands behind them and they cannot authorize the workshop. Workshop questions need the human to type their answer so it can be recorded. Tell the human their answers are preserved but must be re-given as typed replies, ask approval to set the unauthorized product records aside, then ask each product question again as visible prose and wait for the typed response before recording it.')
                }
                elseif ($workshopAgendaReformatted) {
                    [void]$sb.AppendLine('The agenda you showed was reformatted, so the confirmation could not be recorded against it. Send the command''s output exactly as printed, without changing bullets or spacing, then ask again.')
                }
                elseif ([string]$workshopQuestion.reason -eq 'workshop-decision-bindings-invalid') {
                    $badBinding = $workshopQuestion.binding_conflict
                    [void]$sb.AppendLine(("This workshop answer could not be recorded cleanly: decision '{0}' has value '{1}' in '{2}'. Use lowercase stable values (for example `ihttpclientfactory`, not `IHttpClientFactory`), record the corrected answer through the workshop flow, then show the current question again. Do not continue to another topic first." -f $badBinding.binding, $badBinding.value, $badBinding.lens))
                }
                elseif ([string]$workshopQuestion.reason -eq 'workshop-applicability-absent') {
                    [void]$sb.AppendLine(("This project's workshop setup is not ready for feature '{0}'. Initialize the workshop records with the project-provided setup action, then show the current question again. Do not continue to another topic first." -f [string]$workshopQuestion.feature_ref))
                }
                elseif ($workshopAgendaPresentationMissing) {
                    [void]$sb.AppendLine('The technical workshop cannot start until the human has seen and confirmed its agenda. Show every selected topic with its depth and concrete decision, plus every skipped topic with a feature-specific reason, then ask whether to confirm or change the selection. After the typed answer is recorded through the workshop flow, open the first topic.')
                }
                elseif ([string]$workshopQuestion.reason -in @('workshop-agenda-selected-entry-invalid','workshop-agenda-skipped-entry-invalid','workshop-agenda-digest-mismatch','workshop-agenda-turn-receipt-invalid')) {
                    [void]$sb.AppendLine("This project's workshop records no longer match the agenda the human confirmed. The answers remain safe. Another confirmation of the unchanged agenda cannot resolve the mismatch. Propose restarting the workshop from its agenda so one consistent selection can be recorded.")
                }
                else {
                    [void]$sb.AppendLine('The implementation discussion is marked complete, but its agreed coding rules have not been recorded. Record those rules through the project-provided workshop action, then show the current question again. Do not continue to another topic first.')
                }
                if (-not (Get-Command Get-SpecrewWorkshopRefusalContractText -ErrorAction SilentlyContinue)) {
                    $workshopAuthorityPath = Join-Path $projectRoot '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
                    if (Test-Path -LiteralPath $workshopAuthorityPath -PathType Leaf) { . $workshopAuthorityPath }
                }
                if (Get-Command Get-SpecrewWorkshopRefusalContractText -ErrorAction SilentlyContinue) {
                    $answerState = if ($preScaffoldWorkshopAttempt) { 'none' } else { 'preserved' }
                    [void]$sb.AppendLine((Get-SpecrewWorkshopRefusalContractText -AnswerState $answerState))
                }
                else {
                    $answerStatus = if ($preScaffoldWorkshopAttempt) { 'that no answer was recorded yet' } else { 'that their answers are safe and nothing has been lost' }
                    [void]$sb.AppendLine(("Try the action above once. If it does not resolve the situation, do not retry and do not edit this project's workshop records by hand. Tell the human calmly what you were doing, {0}, and what you could not complete without assigning blame. Give one concrete next action you can take and ask the human for approval before taking it." -f $answerStatus))
                }
            }
            elseif ($blockKind -eq 'material' -and $workshopIntermediate) {
                # A DESIGN CONVERSATION IS STILL OPEN, so the generic packet demand lands as an
                # engineering interrupt mid-question and takes the human's place in the workshop with
                # it. Enforcement is unchanged - work outside the workshop notes still owes the packet -
                # but the correction now names WHICH work cost the exemption and requires the pending
                # question to survive the packet, so the human is not left re-finding the conversation.
                $topicLabel = if ([string]::IsNullOrWhiteSpace([string]$workshopQuestion.lens)) { 'current' } else { [string]$workshopQuestion.lens }
                if (@($workshopOutsidePaths).Count -gt 0) {
                    [void]$sb.AppendLine(("Specrew: the design workshop is still open on the '{0}' topic, and this turn also changed work outside the workshop notes: {1}. That work owes the human a short summary before the conversation continues." -f $topicLabel, (@($workshopOutsidePaths) -join ', ')))
                }
                else {
                    [void]$sb.AppendLine(("Specrew: the design workshop is still open on the '{0}' topic, and this turn also changed work outside the workshop notes. That work owes the human a short summary before the conversation continues." -f $topicLabel))
                }
                [void]$sb.AppendLine('Render the five-part context packet NOW as your message:')
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## What I Need From You')
                [void]$sb.AppendLine('END that message by asking the SAME workshop question again, in full, so the human keeps their place in the conversation and can simply answer it. Do not replace the question with the packet, and do not open the next topic.')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                [void]$sb.AppendLine('This is a NON-BOUNDARY material-work stop; do NOT emit a SPECREW-VERDICT-BOUNDARY marker.')
                [void]$sb.AppendLine('If that outside work was the feature specification, say so plainly: the specification is written after the workshop finishes, so its content is not settled yet and the human should not read it as agreed.')
            }
            elseif ($blockKind -eq 'material') {
                [void]$sb.AppendLine('Specrew: this Stop followed material work, but your last message did not render the required non-boundary context packet. Render the five-part context packet NOW as your message, then stop again:')
                $w52MaterialLine = if (Get-Command Get-SpecrewReviewCoverageLine -ErrorAction SilentlyContinue) { try { [string](Get-SpecrewReviewCoverageLine -ProjectRoot $projectRoot) } catch { '' } } else { '' }
                if (-not [string]::IsNullOrWhiteSpace($w52MaterialLine)) { [void]$sb.AppendLine(('Include this line verbatim in the packet: {0}' -f $w52MaterialLine)) }
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## What I Need From You')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                [void]$sb.AppendLine('This is a NON-BOUNDARY material-work stop; do NOT emit a SPECREW-VERDICT-BOUNDARY marker.')
            }
            if ($blockKind -eq 'orientation') {
                [void]$sb.AppendLine('Specrew: this session''s orientation was handed to you and the human never saw it. Render it NOW as visible prose: that Specrew is active with its version and host, where this project stands in the lifecycle, where their artifacts live, what will be asked of them at boundaries, and what you believe about them so they can correct it. Then continue what you were doing.')
                [void]$sb.AppendLine('Reading it to orient yourself is not rendering it. Do not summarise it as having happened; show it.')
            }
            elseif ($orientationOwed) {
                [void]$sb.AppendLine('Also: this session''s orientation was never shown to the human - include it in this same message, before the rest, so they learn what this project asks of them now rather than at a boundary they did not expect.')
            }            if ($intakeHit) { [void]$sb.AppendLine('Also: an active feature already exists - do NOT ask what to build; continue it.') }
            if ($rawHit) { [void]$sb.AppendLine('Also: do NOT run the raw `specify workflow` SDD engine - route through the governed Specrew flow.') }
            $blockReason = $sb.ToString().TrimEnd()
        }
        else {
            # The counter increment could not be persisted/verified -> the cap cannot be guaranteed on a capless
            # host -> do NOT block (fail-open, 145 HANG-2). A hang with no diagnostic is the worst outcome, so WARN.
            [Console]::Error.WriteLine('[specrew-conformance] WARN STOP_BLOCK_COUNTER_UNWRITABLE cannot persist the loop-guard counter; releasing the stop (no block) to stay fail-open.')
        }
    }
    else {
        # Packet present, or nothing owed -> the agent complied; clear the loop-guard counter.
        # W25: record that this session's orientation reached the human, so every later stop costs one
        # Test-Path instead of a transcript inspection. Written on the compliant path only.
        if ($orientationSatisfiedNow -and -not [string]::IsNullOrWhiteSpace([string]$materialRuntime.OrientationPath)) {
            try {
                $orientationDir = Split-Path -Parent ([string]$materialRuntime.OrientationPath)
                if ($orientationDir -and -not (Test-Path -LiteralPath $orientationDir)) { New-Item -ItemType Directory -Path $orientationDir -Force | Out-Null }
                [IO.File]::WriteAllText([string]$materialRuntime.OrientationPath, (([ordered]@{ schema_version = '1.0'; rendered_at = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json -Compress) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
            }
            catch { $null = $_ }
        }        if ($materialStop -and $packetPresent -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
            Set-SpecrewMaterialSatisfiedKey -Path $materialSatisfiedPath -Key ([string]$materialSignal.key)
        }
        Reset-SpecrewBlockCount -Path $blockStatePath
        # BASELINE ADVANCE: this obligation is discharged. Persist the complete live snapshot, not a handover key,
        # so a same-path re-edit changes its content fingerprint and re-arms the next delta. CaptureEvent=Stop makes
        # any missing next prompt event explicitly degraded; a genuine prompt adapter replaces it at turn start.
        if ($null -ne $turnCurrentSnapshot -and [bool]$turnCurrentSnapshot.available -and (($blockKind -eq 'none') -or ($materialStop -and $packetPresent))) {
            $null = Write-SpecrewTurnBaseline -Path $materialBaselinePath -Snapshot $turnCurrentSnapshot -CaptureEvent 'Stop'
        }
    }

    # If not blocking (not warranted, or capped), surface the cooperative nudges instead.
    if ([string]::IsNullOrWhiteSpace($blockReason)) {
        if ($capped) {
            # A CAPPED BLOCK MUST ANNOUNCE THAT IT CAPPED.
            #
            # The cap is a defensible runaway guard; the SILENCE is not. Until now it wrote only to
            # stderr, so from the transcript the fourth turn looked exactly like the first three - a
            # nudge - while enforcement had actually stopped. Measured: the maintainer watched governance
            # work, watched it stop, and reasonably concluded the hook had broken. The condition was
            # unmet the whole time.
            #
            # The corrections below already NAME the unmet condition. What was missing is the fact that
            # nothing is enforcing it any more, which is the difference between "I am being reminded"
            # and "I am now on my own".
            $corrections.Add(('[specrew-conformance] ENFORCEMENT STOPPED after {0} consecutive blocks on the same unmet condition. Specrew is no longer holding this turn - the requirement below is still unmet, and from here it is on you rather than on the hook. This limit exists so a disagreement between us cannot hang your session indefinitely. Include this exact line in your message so the transcript records it: "Specrew: packet discipline capped for this session after {0} refusals - {1} is still unmet."' -f $script:SpecrewBlockCap, $capSubject)) | Out-Null
            if ($cappedKind -eq 'material') {
                $corrections.Add('[specrew-conformance] MATERIAL-WORK STOP packet still missing - render the five-part context packet with file:/// references before handing control back.') | Out-Null
            }
            # certify f3: a REFUSED boundary must never be instructed to emit a marker, capped or
            # not — for missing evidence that reintroduces the marker FR-068 suppresses, and for an
            # unrecordable crossing it invents a marker for a crossing that does not exist (FR-066).
            elseif ($cappedKind -eq 'boundary-evidence-absent') {
                $corrections.Add('[specrew-conformance] STAGE EVIDENCE still missing - do NOT render boundary-verdict options and do NOT include any boundary approval comment; there is nothing to approve until the stage produces its evidence in the bound tree, and asking for the evidence-producing approvals the requirement itself names remains your job. Produce the missing artifacts, commit them, re-run the boundary sync, then stop again.') | Out-Null
            }
            elseif ($cappedKind -eq 'boundary-unrecordable') {
                $corrections.Add('[specrew-conformance] BOUNDARY REMAINS UNRECORDABLE - do NOT render boundary-verdict options and do NOT include any boundary approval comment; no crossing exists to approve, and asking for the evidence-producing approvals the requirement itself names remains your job. Run the project''s Specrew start/bootstrap path so the boundary ledger exists, then stop again.') | Out-Null
            }
            elseif ($cappedKind -eq 'coverage-decision') {
                $corrections.Add('[specrew-conformance] COVERAGE DECISION still unmade - the allowance is exhausted, source has moved beyond the last delivered review, and the block cap has released this stop. The decision is still the human''s: `approved for allowance reset`, `continue without coverage until the review phase`, or `hold implementation here` - each as their typed reply in a normal chat message, because a reply inside a question UI or picker is not captured. Surface it; do not continue implementing as if it were made.') | Out-Null
            }
            elseif ($cappedKind -eq 'unauthorized-source') {
                $corrections.Add('[specrew-conformance] UNAUTHORIZED SOURCE still present - product source was written without the before-implement verdict, and the block cap has released this stop. The condition is still unmet: surface the work to the human and ask for their verdict or their revert decision. Do not continue implementing.') | Out-Null
            }
            elseif ($cappedKind -eq 'workshop-repair') {
                $corrections.Add('[specrew-conformance] WORKSHOP RECORD still invalid or incomplete - repair the named binding or implementation-rules.yml requirement before moving to another lens. Do not render the generic five-part packet.') | Out-Null
            }
            else {
                $corrections.Add('[specrew-conformance] BOUNDARY VERDICT MARKER still missing or wrong - render the six-section packet and emit the exact pending-crossing SPECREW-VERDICT-BOUNDARY marker so the human verdict can be captured.') | Out-Null
            }
        }
        if ($intakeHit) { $corrections.Add(("[specrew-conformance] INTAKE QUESTION while an active feature exists`n`nYou asked the human what to build, but a feature is already in flight (spec exists at {0}). Do NOT restart intake - read it and continue the active feature." -f $specPath)) | Out-Null }
        if ($rawHit) { $corrections.Add("[specrew-conformance] RAW SPEC KIT invocation detected`n`nDo NOT run the un-governed 'specify workflow' automation - route through the Specrew design workshop and the governed /speckit.* commands so the gates are honored.") | Out-Null }
    }

    # --- forensic journal (diagnostics only - never gate state) ---
    # Also record EVERY material stop (not only blocks) so a spurious material block is diagnosable against the
    # passing case (D-197-I009 conformance false-negative: a valid packet on disk still evaluated packetPresent=false).
    if (-not [string]::IsNullOrWhiteSpace($blockReason) -or $capped -or $intakeHit -or $rawHit -or $materialStop) {
        try {
            $jdir = Split-Path -Parent $journalPath
            if ($jdir -and -not (Test-Path -LiteralPath $jdir)) { New-Item -ItemType Directory -Path $jdir -Force | Out-Null }
            # FR-045a: a continuation directive is NOT a packet-render block - label it distinctly so the flush-race
            # forensic (which keys off 'stop-block' + a low dx_lat_hits to catch mid-flush truncation) does not treat a
            # by-design non-packet continue message as a partial-read suspect.
            $evt = if ($workshopQuestionWins) { 'workshop-intermediate' } elseif ($workshopConflict) { 'workshop-conflict' } elseif ($workshopRepair) { 'workshop-repair' } elseif ($stopIntentContinue) { 'stop-continue' } elseif ($capAnnounced) { 'stop-block-cap-announce' } elseif (-not [string]::IsNullOrWhiteSpace($blockReason)) { 'stop-block' } elseif ($capped) { 'stop-block-capped' } elseif ($intakeHit -or $rawHit) { 'nudge' } else { 'observe' }
            $jWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
            $jAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
            # dx_* = the actual inputs to the packetPresent decision, so a wrong block is no longer silent.
            $diagLat = [string]$lastAssistantText
            $diagHits = 0; foreach ($dh in $script:SpecrewReentryHeaders) { if (-not [string]::IsNullOrEmpty($diagLat) -and $diagLat -match [regex]::Escape($dh)) { $diagHits++ } }
            # NO content snippet is recorded: dx_lat_len + dx_lat_hits diagnose a false-negative (hits<4 = the
            # packet was not seen; len distinguishes a short stale message from the long packet) WITHOUT writing
            # any conversation text to the (local, git-ignored) journal. Maintainer privacy call 2026-06-28.
            $rec = [pscustomobject]@{ event = $evt; recorded_at = (Get-Date).ToUniversalTime().ToString('o'); has_pending = $hasPending; working = $jWorking; last_authorized = $jAuth; substantial = $substantial; material = $materialStop; block_kind = $blockKind; stop_intent = $stopIntentOutcome; stop_intent_reason = $stopIntentReason; workshop_scope = $(if ($workshopQuestionWins) { [string]$workshopQuestion.scope } else { $null }); workshop_feature = $(if ($workshopQuestionWins) { [string]$workshopQuestion.feature_ref } else { $null }); workshop_iteration = $(if ($workshopQuestionWins) { [string]$workshopQuestion.iteration_number } else { $null }); workshop_lens = $(if ($workshopQuestionWins) { [string]$workshopQuestion.lens } else { $null }); intake = $intakeHit; raw = $rawHit; host = $hostKindArg; source = $sourceEventArg; dx_transcript_arg = (-not [string]::IsNullOrWhiteSpace($transcriptPathArg)); dx_transcript_exists = ((-not [string]::IsNullOrWhiteSpace($transcriptPathArg)) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)); dx_cc_loaded = $ccLoaded; dx_lat_len = $diagLat.Length; dx_lat_hits = $diagHits; dx_packet_present = $packetPresent; dx_reread_attempted = $transcriptRereadAttempted; dx_reread_recovered = $transcriptRereadRecovered; dx_material_retry = (-not [string]::IsNullOrWhiteSpace($materialRetryKey)); dx_baseline_suppressed = $materialBaselineSuppressed; dx_foreign_owner_suppressed = $materialForeignOwnerSuppressed; dx_owner = [string]$materialRuntime.Owner; dx_long_turn = ($null -ne $longTurn -and [bool]$longTurn.long) }
            ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $journalPath -Encoding UTF8
        }
        catch { $null = $_ }
    }

    # --- emit: a block sentinel (the dispatcher force-continues), else the plain inject nudges, else nothing ---
    if (-not [string]::IsNullOrWhiteSpace($blockReason)) {
        Write-Output ("<<<SPECREW-STOP-BLOCK>>>`n" + $blockReason)
    }
    elseif ($corrections.Count -gt 0) {
        Write-Output ($corrections.ToArray() -join "`n`n")
    }
    return
}
catch {
    [Console]::Error.WriteLine("[specrew-conformance] WARN CONFORMANCE_PROVIDER_FAILED $($_.Exception.Message)")
    return
}
# specrew-self-provenance-ok: D-197-I009,DRIFT-198-I0NN-0NN,DRIFT-199-I001-015; implementation history is recorded for maintainers and is never emitted as consumer instruction
