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
#   feature/iteration/current-lens state and visible pending question validate; lifecycle boundary state always wins.
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
    # entries SINCE the last HUMAN user line (a '"type":"user"' line WITHOUT a '"tool_use_id"' marker - tool
    # results ride user-role lines on Claude-format transcripts). Count >= the threshold -> long; with no human
    # line in the window every assistant line in the tail counts, so a saturated window reads long by count
    # alone while a short no-human transcript stays quiet. A host whose transcript lines carry neither marker counts 0 and is never
    # long (fail-open - the documented honest ceiling; the material-delta lane still enforces there). The hash
    # keys the enforcement to the LAST HUMAN line, which is STABLE across a forced-continue loop, so consecutive
    # packet-less retries accumulate on ONE loop-guard key and the block cap can trip (never an uncapped loop).
    param([AllowNull()][string]$TranscriptPath)
    $result = [pscustomobject]@{ long = $false; assistant_entries = 0; hash = '' }
    try {
        if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return $result }
        $tail = @(Get-Content -LiteralPath $TranscriptPath -Tail 200 -Encoding UTF8 -ErrorAction Stop)
        $assistantRx = [regex]::new('"type"\s*:\s*"assistant"')
        $userRx = [regex]::new('"type"\s*:\s*"user"')
        $count = 0; $humanLine = $null
        for ($i = $tail.Count - 1; $i -ge 0; $i--) {
            $ln = [string]$tail[$i]
            if ($assistantRx.IsMatch($ln)) { $count++; continue }
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
    # Cheap candidate only: remaining lenses justify the role-aware transcript read, but never suppress a Stop.
    # Resolve-SpecrewWorkshopQuestionPause independently proves the exact iteration/current lens/visible question.
    # Scope ONLY to $FeatureRef so an abandoned feature cannot lend another feature workshop state. Any miss or
    # unreadable state returns false; prose and incomplete state never fabricate the exception.
    param([string]$ProjectRoot, [AllowNull()][string]$BootstrapDir, [AllowNull()][string]$FeatureRef)
    try {
        if ([string]::IsNullOrWhiteSpace($BootstrapDir) -or [string]::IsNullOrWhiteSpace($FeatureRef)) { return $false }
        $pma = Join-Path $BootstrapDir 'ProjectMetadataAccessor.ps1'
        if (-not (Test-Path -LiteralPath $pma -PathType Leaf)) { return $false }
        try { . $pma } catch { return $false }
        if (-not (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        if ($null -ne $wp -and [bool]$wp.has_applicability -and (@($wp.remaining).Count -gt 0)) { return $true }
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
        if (-not (Get-Command Get-SpecrewWorkshopProgress -ErrorAction SilentlyContinue)) { return $false }
        $wp = $null
        try { $wp = Get-SpecrewWorkshopProgress -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef } catch { $wp = $null }
        return ($null -ne $wp -and [bool]$wp.has_applicability -and (@($wp.selected).Count -gt 0) -and (@($wp.remaining).Count -eq 0))
    }
    catch { $null = $_ }
    return $false
}

function Resolve-SpecrewWorkshopQuestionPause {
    # FR-056: the workshop exception is marker-and-durable-state, not prose inference.
    # The assistant marker names the exact feature/iteration/lens; the matching iteration artifact must
    # prove that lens is the first remaining selected lens; and the visible body must contain real lens
    # content followed by an explicit question. Lifecycle boundary state always wins before this helper.
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$ActiveFeatureRef,
        [AllowNull()][string]$ActiveIterationNumber,
        [AllowNull()][string]$LastAssistantText,
        [bool]$HasPendingVerdict
    )
    $result = [pscustomobject]@{ valid = $false; reason = 'workshop-question-unproven'; feature_ref = $null; iteration_number = $null; lens = $null; question = $null; message_hash = $null }
    try {
        if ($HasPendingVerdict) { $result.reason = 'lifecycle-boundary-overrides-workshop'; return $result }
        if ([string]::IsNullOrWhiteSpace($ActiveFeatureRef) -or [string]::IsNullOrWhiteSpace($ActiveIterationNumber) -or [string]::IsNullOrWhiteSpace($LastAssistantText)) { return $result }
        $markerPattern = '<!--\s*SPECREW-WORKSHOP-QUESTION:\s*feature=(?<feature>[0-9]{3}-[a-z0-9][a-z0-9-]{0,63});\s*iteration=(?<iteration>[0-9]{3,});\s*lens=(?<lens>[a-z][a-z0-9-]{1,63})\s*-->'
        $matches = @([regex]::Matches($LastAssistantText, $markerPattern, [Text.RegularExpressions.RegexOptions]::CultureInvariant))
        if ($matches.Count -ne 1) { $result.reason = 'workshop-question-marker-missing-or-ambiguous'; return $result }
        $match = $matches[0]
        $featureRef = [string]$match.Groups['feature'].Value
        $iteration = [string]$match.Groups['iteration'].Value
        $lens = [string]$match.Groups['lens'].Value
        if ($featureRef -cne $ActiveFeatureRef) { $result.reason = 'workshop-question-feature-mismatch'; return $result }
        if ($iteration -cne $ActiveIterationNumber) { $result.reason = 'workshop-question-iteration-mismatch'; return $result }

        $iterationRoot = Join-Path $ProjectRoot ("specs/{0}/iterations/{1}" -f $featureRef, $iteration)
        $applicabilityPath = Join-Path $iterationRoot 'lens-applicability.json'
        if (-not (Test-Path -LiteralPath $applicabilityPath -PathType Leaf)) { $result.reason = 'workshop-question-iteration-state-missing'; return $result }
        $item = Get-Item -LiteralPath $applicabilityPath -ErrorAction Stop
        if ($item.Length -gt 262144) { $result.reason = 'workshop-question-iteration-state-oversized'; return $result }
        $applicability = Get-Content -LiteralPath $applicabilityPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 20 -ErrorAction Stop
        $selectedProperty = $applicability.PSObject.Properties['selected']
        if (-not $selectedProperty -or $null -eq $selectedProperty.Value) { $result.reason = 'workshop-question-selected-lenses-missing'; return $result }
        $selected = @($selectedProperty.Value | ForEach-Object { [string]$_ })
        if ($lens -cnotin $selected) { $result.reason = 'workshop-question-lens-not-selected'; return $result }
        $done = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $workshopProperty = $applicability.PSObject.Properties['workshop']
        if ($workshopProperty -and $null -ne $workshopProperty.Value) {
            foreach ($property in $workshopProperty.Value.PSObject.Properties) {
                $movedOn = $property.Value.PSObject.Properties['moved_on']
                if ($movedOn -and [bool]$movedOn.Value) { $null = $done.Add([string]$property.Name) }
            }
        }
        $recordsRoot = Join-Path $iterationRoot 'workshop'
        if (Test-Path -LiteralPath $recordsRoot -PathType Container) {
            foreach ($record in @(Get-ChildItem -LiteralPath $recordsRoot -Filter '*.md' -File -ErrorAction Stop)) {
                $null = $done.Add([IO.Path]::GetFileNameWithoutExtension($record.Name))
            }
        }
        $remaining = @($selected | Where-Object { -not $done.Contains($_) })
        if ($remaining.Count -eq 0 -or [string]$remaining[0] -cne $lens) { $result.reason = 'workshop-question-lens-not-current'; return $result }

        $body = [regex]::Replace($LastAssistantText, $markerPattern, '', [Text.RegularExpressions.RegexOptions]::CultureInvariant).Trim()
        if ($body.Length -lt 80 -or $body -cnotmatch [regex]::Escape($lens) -or $body -notmatch '\?\s*$') {
            $result.reason = 'workshop-question-visible-contract-missing'; return $result
        }
        $question = @($body -split "`r?`n" | Where-Object { $_.TrimEnd().EndsWith('?') } | Select-Object -Last 1)
        if ($question.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$question[0])) { $result.reason = 'workshop-question-text-missing'; return $result }
        $result.valid = $true
        $result.reason = 'durable-current-lens-question'
        $result.feature_ref = $featureRef
        $result.iteration_number = $iteration
        $result.lens = $lens
        $result.question = ([string]$question[0]).Trim()
        $result.message_hash = Get-SpecrewFireIdentity -Parts @($body)
        return $result
    }
    catch { $result.reason = 'workshop-question-state-unreadable'; return $result }
}

function Update-SpecrewWorkshopQuestionHandover {
    # A small local handover record makes an interrupted question resumable without making it authority.
    # Classification never reads this file; only the exact iteration artifact + current rendered marker decide.
    param([string]$ProjectRoot, $Decision)
    $path = Join-Path $ProjectRoot '.specrew/handover/workshop-question.json'
    try {
        if ($null -eq $Decision -or -not [bool]$Decision.valid) {
            if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force -ErrorAction Stop }
            return
        }
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $record = [ordered]@{
            schema = 'v1'; status = 'pending-human-answer'; feature_ref = [string]$Decision.feature_ref
            iteration_number = [string]$Decision.iteration_number; lens = [string]$Decision.lens
            question = [string]$Decision.question; message_hash = [string]$Decision.message_hash
            recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
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
for ($i = 0; $i -lt $args.Count; $i++) {
    if ($args[$i] -eq '--host-kind' -and ($i + 1) -lt $args.Count) { $hostKindArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--source-event' -and ($i + 1) -lt $args.Count) { $sourceEventArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--transcript-path' -and ($i + 1) -lt $args.Count) { $transcriptPathArg = [string]$args[$i + 1] }
    elseif ($args[$i] -eq '--session-id' -and ($i + 1) -lt $args.Count) { $sessionIdArg = [string]$args[$i + 1] }
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

    # Any feature spec on disk (cheap dir check) -> the substantial + #1 triggers need this.
    $anySpec = $false; $specPath = $null
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
    $startContextReadable = $false
    $hasActiveLifecycleBoundary = $false
    $hasBoundaryAuthorization = $false
    try {
        $scPath = Join-Path $projectRoot '.specrew/start-context.json'
        if (Test-Path -LiteralPath $scPath -PathType Leaf) {
            $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $startContextReadable = $true
            if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state -and $sc.session_state.PSObject.Properties['feature_ref'] -and -not [string]::IsNullOrWhiteSpace([string]$sc.session_state.feature_ref)) {
                $activeFeatureRef = [string]$sc.session_state.feature_ref
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
    if (-not $activeFeatureFromSessionState -and $null -ne $handoverContextSignal -and -not [string]::IsNullOrWhiteSpace([string]$handoverContextSignal.active_feature)) {
        $activeFeatureRef = [string]$handoverContextSignal.active_feature
    }
    if ([string]::IsNullOrWhiteSpace($activeFeatureRef) -and -not [string]::IsNullOrWhiteSpace($specPath)) {
        $activeFeatureRef = Split-Path (Split-Path $specPath -Parent) -Leaf
    }
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

    # --- WORKSHOP CANDIDATE (FR-056): remaining lenses make the transcript worth inspecting, but do NOT suppress
    # anything by themselves. The exact current feature/iteration/lens marker + visible pending question is proved
    # only after the role-aware last assistant turn is read below. ---
    $workshopStateInProgress = $false
    if ($hasPending -or $anySpec -or $rawHit -or $materialStop) {
        if ([string]::IsNullOrWhiteSpace($bootstrapDir)) { $bootstrapDir = Resolve-SpecrewBootstrapDir -ProjectRoot $projectRoot }
        $workshopStateInProgress = Test-SpecrewWorkshopInProgress -ProjectRoot $projectRoot -BootstrapDir $bootstrapDir -FeatureRef $activeFeatureRef
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
    if ($hasPending -or $materialStop -or -not [string]::IsNullOrWhiteSpace($materialRetryKey) -or $workshopStateInProgress) {
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
    $workshopQuestion = Resolve-SpecrewWorkshopQuestionPause -ProjectRoot $projectRoot -ActiveFeatureRef $activeFeatureRef -ActiveIterationNumber $activeIterationNumber -LastAssistantText $lastAssistantText -HasPendingVerdict $hasPending
    $workshopIntermediate = ($null -ne $workshopQuestion -and [bool]$workshopQuestion.valid)
    if ($workshopIntermediate) { $rawHit = $false }
    # ISSUE-2 PERF REVERT: the flush/read-race RE-READ (4x tail-200 parse, ~17s on a large transcript) is REMOVED.
    # It was an UNCONFIRMED mitigation (the instrumented false-negative never reproduced) and it taxed every
    # material stop AND starved the navigator (order 50) of the shared 20s Stop budget, so co-review stopped firing.
    # If the flush-race double-render ever reproduces WITH a captured dx_ record, re-add a CHEAP variant (a tiny
    # last-line re-read, not a full 200-line parse). The dx_* journal keeps the decision observable in the meantime.
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
    $fireIdentity = Get-SpecrewFireIdentity -Parts @([string]$lastAssistantText, $idWorking, $idAuth, ("m={0}" -f [int][bool]$markerForPendingCrossing), ("wq={0}" -f [int][bool]$workshopIntermediate), ("p={0}" -f [int][bool]$hasPending), ("mat={0}" -f [string]$materialSignal.key), ("mr={0}" -f [string]$materialRetryKey), [string]$sourceEventArg)
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
    # only after exact workshop-question proof above. The length-only substantial trigger remains gated on a spec, so
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
    $boundaryBlock = $hasPending -and (-not $markerForPendingCrossing)
    $materialAlreadySatisfied = $materialStop -and (-not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) -and ([string]$materialSignal.key -eq [string]$materialSatisfiedKey)
    $materialInitialBlock = (-not $hasPending) -and $materialStop -and (-not $packetPresent) -and (-not $materialAlreadySatisfied)
    $materialRetryBlock = (-not $hasPending) -and (-not [string]::IsNullOrWhiteSpace($materialRetryKey)) -and (-not $packetPresent)
    $materialBlock = $materialInitialBlock -or $materialRetryBlock
    $blockKind = if ($boundaryBlock) { 'boundary' } elseif ($materialBlock) { 'material' } else { 'none' }

    # --- FR-045a STOP-INTENT classification (SAFETY-CRITICAL; FAIL-SAFE) --------------------------------------------
    # Classify this Stop as continue|intermediate|real BEFORE the material-work packet enforcement, so an authorized
    # in-phase workflow is neither stalled behind a status packet (continue) nor falsely handed back while owned async
    # is in flight (intermediate). STRICTLY SCOPED to a MATERIAL, packet-less, non-boundary stop we could actually read
    # ($blockKind -eq 'material' -and $canAssess). BOUNDARY stops, 'none', an unavailable classifier, and EVERY error
    # leave $stopIntentOutcome at its 'real' default -> today's real-stop enforcement is preserved byte-for-byte. The
    # classifier is dot-sourced fail-open: the ONE pure, self-contained contract file (sibling of bootstrap; no _load).
    $stopIntentOutcome = if ($workshopIntermediate) { 'workshop-intermediate' } else { 'real' }
    $stopIntentReason = if ($workshopIntermediate) { [string]$workshopQuestion.reason } else { $null }
    $stopIntentContinueKey = $null
    $stopIntentContinueCount = 0
    if ($blockKind -eq 'material' -and $canAssess -and (-not $workshopIntermediate)) {
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
    # The advance identity the consecutive-block cap keys on: a boundary advance is working|lastAuth; a material
    # non-boundary stop is keyed by the current handover snapshot. A NEW advance/snapshot starts a fresh count; the agent
    # rendering the packet (not blockWarranted) resets it. No time window (145 HANG-1).
    # The if-guard also protects the $pending null-deref under the leaked StrictMode; the else value is an unused
    # placeholder ($advanceKey is read only inside the blockWarranted branch, which implies $hasPending; 145 SC-3).
    $advanceKey = if ($blockKind -eq 'boundary' -and $hasPending) {
        ("{0}|{1}" -f [string]$pending.WorkingBoundary, [string]$pending.LastAuthorizedBoundary)
    }
    elseif ($blockKind -eq 'material' -and $materialInitialBlock -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
        [string]$materialSignal.key
    }
    elseif ($blockKind -eq 'material' -and -not [string]::IsNullOrWhiteSpace($materialRetryKey)) {
        [string]$materialRetryKey
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
            $capSubject = if ($blockKind -eq 'material') { 'material-work packet' } else { 'verdict marker' }
            [Console]::Error.WriteLine(("[specrew-conformance] WARN STOP_BLOCK_CAP {0} still absent or wrong after {1} consecutive blocks; releasing the stop (degrading to a nudge) to avoid a hang." -f $capSubject, $count))
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
            elseif ($blockKind -eq 'material') {
                [void]$sb.AppendLine('Specrew: this Stop followed material work, but your last message did not render the required non-boundary context packet. Render the five-part context packet NOW as your message, then stop again:')
                [void]$sb.AppendLine('## What I Just Did / ## Why I Stopped / ## What Needs Your Review / ## What Happens Next / ## What I Need From You')
                [void]$sb.AppendLine('Every artifact reference uses a bare file:/// URL.')
                [void]$sb.AppendLine('This is a NON-BOUNDARY material-work stop; do NOT emit a SPECREW-VERDICT-BOUNDARY marker.')
            }
            if ($intakeHit) { [void]$sb.AppendLine('Also: an active feature already exists - do NOT ask what to build; continue it.') }
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
        if ($materialStop -and $packetPresent -and -not [string]::IsNullOrWhiteSpace([string]$materialSignal.key)) {
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
            if ($cappedKind -eq 'material') {
                $corrections.Add('[specrew-conformance] MATERIAL-WORK STOP packet still missing (FR-015) - render the five-part context packet with file:/// references before handing control back.') | Out-Null
            }
            else {
                $corrections.Add('[specrew-conformance] BOUNDARY VERDICT MARKER still missing or wrong (FR-011/FR-015) - render the six-section packet and emit the exact pending-crossing SPECREW-VERDICT-BOUNDARY marker so the human verdict can be captured.') | Out-Null
            }
        }
        if ($intakeHit) { $corrections.Add(("[specrew-conformance] INTAKE QUESTION while an active feature exists (FR-011 #1)`n`nYou asked the human what to build, but a feature is already in flight (spec exists at {0}). Do NOT restart intake - read it and continue the active feature." -f $specPath)) | Out-Null }
        if ($rawHit) { $corrections.Add("[specrew-conformance] RAW SPEC KIT invocation detected (FR-011 #3)`n`nDo NOT run the un-governed 'specify workflow' automation - route through the Specrew design workshop and the governed /speckit.* commands so the gates are honored.") | Out-Null }
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
            $evt = if ($workshopIntermediate) { 'workshop-intermediate' } elseif ($stopIntentContinue) { 'stop-continue' } elseif (-not [string]::IsNullOrWhiteSpace($blockReason)) { 'stop-block' } elseif ($capped) { 'stop-block-capped' } elseif ($intakeHit -or $rawHit) { 'nudge' } else { 'observe' }
            $jWorking = if ($null -ne $pending) { [string]$pending.WorkingBoundary } else { '' }
            $jAuth = if ($null -ne $pending) { [string]$pending.LastAuthorizedBoundary } else { '' }
            # dx_* = the actual inputs to the packetPresent decision, so a wrong block is no longer silent.
            $diagLat = [string]$lastAssistantText
            $diagHits = 0; foreach ($dh in $script:SpecrewReentryHeaders) { if (-not [string]::IsNullOrEmpty($diagLat) -and $diagLat -match [regex]::Escape($dh)) { $diagHits++ } }
            # NO content snippet is recorded: dx_lat_len + dx_lat_hits diagnose a false-negative (hits<4 = the
            # packet was not seen; len distinguishes a short stale message from the long packet) WITHOUT writing
            # any conversation text to the (local, git-ignored) journal. Maintainer privacy call 2026-06-28.
            $rec = [pscustomobject]@{ event = $evt; recorded_at = (Get-Date).ToUniversalTime().ToString('o'); has_pending = $hasPending; working = $jWorking; last_authorized = $jAuth; substantial = $substantial; material = $materialStop; block_kind = $blockKind; stop_intent = $stopIntentOutcome; stop_intent_reason = $stopIntentReason; workshop_feature = $(if ($workshopIntermediate) { [string]$workshopQuestion.feature_ref } else { $null }); workshop_iteration = $(if ($workshopIntermediate) { [string]$workshopQuestion.iteration_number } else { $null }); workshop_lens = $(if ($workshopIntermediate) { [string]$workshopQuestion.lens } else { $null }); intake = $intakeHit; raw = $rawHit; host = $hostKindArg; source = $sourceEventArg; dx_transcript_arg = (-not [string]::IsNullOrWhiteSpace($transcriptPathArg)); dx_transcript_exists = ((-not [string]::IsNullOrWhiteSpace($transcriptPathArg)) -and (Test-Path -LiteralPath $transcriptPathArg -PathType Leaf)); dx_cc_loaded = $ccLoaded; dx_lat_len = $diagLat.Length; dx_lat_hits = $diagHits; dx_packet_present = $packetPresent; dx_material_retry = (-not [string]::IsNullOrWhiteSpace($materialRetryKey)); dx_baseline_suppressed = $materialBaselineSuppressed; dx_foreign_owner_suppressed = $materialForeignOwnerSuppressed; dx_owner = [string]$materialRuntime.Owner; dx_long_turn = ($null -ne $longTurn -and [bool]$longTurn.long) }
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
