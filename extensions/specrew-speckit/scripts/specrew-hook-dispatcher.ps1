# SpecrewHookDispatcher (Feature 171, FR-008/FR-012; T006 core).
# THE single Specrew-registered handler per bound host event. Host hook configs
# register exactly one entry per event pointing here; every Specrew mechanism
# that wants to ride host events is a PROVIDER REGISTRY ROW in refocus-scopes.json
# — never a second registration on the host settings surface (ownership rule).
#
# Contract:
#   -Event <name>      host-neutral event name (SessionStart | PostToolUse | UserPromptSubmit | PreInvocation | PreToolUse)
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
    [string]$HostBinding,
    # T014: per-host event/output shaping. The neutral -Event vocabulary stays
    # host-blind (SessionStart | PostToolUse | UserPromptSubmit | PreToolUse);
    # the BINDING (per-host hook config) names both when it registers.
    [ValidatePattern('^[A-Za-z0-9_.-]+$')][string]$HostKind = 'claude'
)

function Write-EarlyDecisionOnlyNoopIfNeeded {
    param([string]$EventName, [string]$EncodedBinding)
    if ([string]::IsNullOrWhiteSpace($EncodedBinding)) { return }
    try {
        $runtime = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($EncodedBinding)) | ConvertFrom-Json -ErrorAction Stop
        if (@($runtime.DecisionOnlyEvents | ForEach-Object { [string]$_ }) -contains $EventName) {
            @{} | ConvertTo-Json -Depth 3 -Compress | Write-Output
        }
    }
    catch { $null = $_ }
}

# KILL SWITCH FIRST (FR-008): this check must precede ANY logic that could itself
# fail — a kill switch placed after catalog/state parsing never gets reached when
# the bug is in catalog/state parsing. Decision-only hosts still require no-op
# JSON; use only the baked binding so the switch remains independent of project state.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) {
    Write-EarlyDecisionOnlyNoopIfNeeded -EventName $Event -EncodedBinding $HostBinding
    exit 0
}
# Per-event kill-switch (recovery lever): SPECREW_DISABLE_EVENTS is a comma/semicolon-separated list of hook
# events to no-op for THIS process - e.g. `SPECREW_DISABLE_EVENTS=Stop` runs a shell whose Stop hook fires NOTHING
# (no co-review / conformance / handover-on-Stop) while SessionStart + PostToolUse stay live. A SURGICAL
# alternative to SPECREW_REFOCUS_DISABLE (which silences every event), so a misbehaving / blocking Stop provider
# can be bypassed in a fresh shell without losing the rest of the hook surface. Case-insensitive; the early
# decision-only no-op keeps the host's hook contract satisfied.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_DISABLE_EVENTS)) {
    $disabledEvents = @($env:SPECREW_DISABLE_EVENTS -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($disabledEvents -contains $Event) {
        Write-EarlyDecisionOnlyNoopIfNeeded -EventName $Event -EncodedBinding $HostBinding
        exit 0
    }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# SPECREW-UTF8-OUTPUT (F-174 iter-10, Prop-145 P3): the dispatcher is the FINAL emitter to the host - it writes
# the merged provider output (which inlines handover dialogue that may be Hebrew/emoji/unicode) to its own
# stdout. Declare UTF-8 so the host (and the provider->dispatcher capture is the other half) receives the
# non-ASCII intact rather than '?' from the child's default OEM console codepage. Fail-open; after the kill
# switch so the switch always wins first.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort: a host that rejects UTF-8 console encoding must still run (fail-open)

# Co-review round 3 (202): when this fire began - the receipt outcome a provider journaled during it is read by time -
# and whether this fire's own append degraded, so the output it delivers can say so (FR-007).
$script:DispatcherStartedUtc = [DateTimeOffset]::UtcNow
$script:DispatcherRecordingDegradedThisFire = $false
# Co-review round 4 (202): whether this fire withheld its output because it could not be recorded (FR-005), so a stamp
# that says something was supplied during this fire can be taken back (Clear-DispatcherUndeliveredOrientationStamp).
$script:DispatcherOutputWithheldThisFire = $false
# Co-review round 4 (202 iteration 002, FR-027): what this fire actually delivered, and whether the not-recorded line
# was already reconciled against it, so the fail-open exit can reconcile it too (Restore-DispatcherUndeliveredNotRecordedLine).
$script:DispatcherDeliveredPayload = ''
$script:DispatcherNotRecordedReconciled = $false
# Co-review round 5 (202, FR-007): this fire's session and typed reply, so the recording disclosure reads THIS reply's
# outcome from the shared outcome journal, never another session's (Get-DispatcherRecordingDisclosure).
$script:DispatcherTurnSessionId = ''
$script:DispatcherTurnTypedText = ''
# 202 DRIFT-023 (maintainer ruling, 2026-10-15): every wait for the Unix journal lock in this fire draws on one 1000 ms
# budget, so the lock can add about 1 s to a hook fire at most, not 1 s per append.
$script:DispatcherLockWaitSpentMs = 0.0
$script:Banner = '[specrew-refocus]'
$script:HostHookOutputCapChars = 10000

function Write-DispatcherWarn {
    param([string]$Code, [string]$Message)
    [Console]::Error.WriteLine(("{0} WARN {1} {2}" -f $script:Banner, $Code, $Message))
}

function ConvertTo-DispatcherInstant {
    # A STORED TIME IS AN INSTANT, NOT A RENDERED STRING (202 iteration 002, after review sign-off). ConvertFrom-Json
    # hands an ISO time back as a [datetime]; casting that to [string] drops the fraction and, for a `+00:00` row,
    # prints LOCAL time, which a UTC re-parse then shifts by this machine's zone. An object keeps its own instant, and
    # only a genuine string is parsed: offset-bearing round-trips exactly, a bare one is UTC, because the stores write UTC.
    # The same rule as ConvertTo-SpecrewAuthorityInstant; the dispatcher loads no store module, so it carries its own.
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [DateTimeOffset]) { return $Value }
    if ($Value -is [datetime]) {
        $dt = [datetime]$Value
        if ($dt.Kind -eq [DateTimeKind]::Unspecified) { $dt = [datetime]::SpecifyKind($dt, [DateTimeKind]::Utc) }
        return [DateTimeOffset]::new($dt)
    }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse(([string]$Value).Trim(), [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) { return $parsed }
    return $null
}

function Get-DispatcherHookOutputHash {
    param([AllowEmptyString()][string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes(([string]$Text).Trim())
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Get-DispatcherHookOutputPaths {
    param([string]$ProjectRoot)
    $runtimeDir = Join-Path $ProjectRoot '.specrew/runtime'
    $journal = Join-Path $runtimeDir 'hook-output-authority.jsonl'
    return [pscustomobject]@{
        RuntimeDir   = $runtimeDir
        Journal      = $journal
        BufferDir    = Join-Path $runtimeDir 'hook-output-buffer'
        Health       = Join-Path $runtimeDir 'hook-output-health.jsonl'
        LegacyMarker = $journal + '.unhealthy'
    }
}

function Open-DispatcherAppendStream {
    # Feature 202 T003 (FR-001): concurrent appends from separate hook processes. MEASURED (202 research.md, T003):
    # [IO.File]::Open(Append, ReadWrite) let three concurrent writers lose 58 of 1200 lines and tear 3 - .NET
    # positions an Append stream at open time, so two writers can land on the same offset. A handle opened with
    # ONLY the AppendData right is an OS-level atomic append on Windows (1200/1200 intact). Elsewhere the regular
    # Append stream is used under the per-write lock (Enter-DispatcherAppendLock), which case (e) showed it needs.
    # FileShare.ReadWrite: never lock out a reader or another writer (the B4F-108 latch was FileShare.Read).
    param([string]$Path)
    if ($IsWindows) {
        return [IO.FileSystemAclExtensions]::Create([IO.FileInfo]::new($Path), [IO.FileMode]::Append, [Security.AccessControl.FileSystemRights]::AppendData, [IO.FileShare]::ReadWrite, 4096, [IO.FileOptions]::None, $null)
    }
    return [IO.File]::Open($Path, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
}

function Enter-DispatcherAppendLock {
    # Linux and macOS only - the per-write lock T003 permitted if case (e) showed lost lines, which it did (202
    # research.md, CI run 38487295823: Linux lost 58 of 2000 and tore 1, macOS lost 32; Windows lost none). A sidecar
    # `<journal>.lock` is opened exclusively for ONE write: .NET maps FileShare.None to an advisory flock that every
    # Specrew writer honours. Readers never take it, so no read waits on a writer or is refused because of one. A
    # lock not acquired within the wait throws, and the caller's retry window and buffer apply as for any failed append.
    #
    # THE WAIT IS FOR A TURN, NOT A RETRY (202 DRIFT-023). It was 200 ms, inside FR-002's 250 ms retry window, and
    # FR-001 failed: case (e) degraded once on Linux CI (38573833479) and once on macOS CI (38583777333), each a writer
    # that never got the lock - the flock is unfair, and a waiter polling every 2 ms loses the short gaps between
    # another writer's back-to-back appends. Reproduced in WSL Ubuntu with four writers (2 of 3 runs). Waiting for a
    # turn is not an append failing, so it gets its own bound, polled every millisecond. The retry window still
    # governs appends that actually fail.
    #
    # THE BOUND IS ONE BUDGET PER HOOK FIRE (maintainer ruling 2026-10-15, an accepted deviation from the agreed 250 ms
    # tuning): every wait in this fire - every attempt of every append - draws on the same 1000 ms. One fire makes up
    # to five appends, so a per-wait bound let the lock add about 5 s; this one adds about 1 s at most, and the busy
    # poll runs for 1 s at most. Once the budget is spent, the lock is tried once without waiting, and a held lock
    # throws [TimeoutException], which the caller takes straight to the outage buffer instead of retrying.
    param([string]$Path)
    $lockPath = $Path + '.lock'
    $spent = Get-Variable -Name DispatcherLockWaitSpentMs -Scope Script -ValueOnly -ErrorAction Ignore
    if ($null -eq $spent) { $spent = 0.0 }
    $remaining = 1000.0 - [double]$spent
    $wait = [Diagnostics.Stopwatch]::StartNew()
    try {
        while ($true) {
            try { return [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
            catch [IO.IOException] {
                if ($wait.Elapsed.TotalMilliseconds -ge $remaining) {
                    throw [TimeoutException]::new(("the journal lock stayed held past this hook fire's 1000 ms wait budget ({0})" -f $_.Exception.Message))
                }
                [Threading.Thread]::Sleep(1)
            }
        }
    }
    finally { $script:DispatcherLockWaitSpentMs = [double]$spent + $wait.Elapsed.TotalMilliseconds }
}

function Add-DispatcherJournalText {
    # One open and one write for the whole text. FR-002: a failed append is retried as a backup only - at most
    # 5 attempts within 250 ms - before the caller degrades. Returns $null on success, else the last error text.
    param([string]$Path, [string]$Text)
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    $window = [Diagnostics.Stopwatch]::StartNew()
    $lastError = $null
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $lock = $null
        try {
            if (-not $IsWindows) { $lock = Enter-DispatcherAppendLock -Path $Path }
            $stream = Open-DispatcherAppendStream -Path $Path
            try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
            finally { $stream.Dispose() }
            return $null
        }
        catch [TimeoutException] {
            # This fire's lock-wait budget is spent (DRIFT-023): no retry, the caller buffers the record.
            $lastError = $_.Exception.Message
            if ($null -ne $lock) { $lock.Dispose(); $lock = $null }
            break
        }
        catch { $lastError = $_.Exception.Message }
        finally { if ($null -ne $lock) { $lock.Dispose() } }
        if ($attempt -lt 5 -and ($window.ElapsedMilliseconds + 50) -le 250) { Start-Sleep -Milliseconds 50 } else { break }
    }
    return $lastError
}

function Read-DispatcherSharedLines {
    # Read every line without locking writers out (FileShare.ReadWrite on the reader too).
    param([string]$Path)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
    try {
        $reader = [IO.StreamReader]::new($stream, [Text.UTF8Encoding]::new($false))
        try { return @($reader.ReadToEnd() -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) }
        finally { $reader.Dispose() }
    }
    finally { $stream.Dispose() }
}

function Get-DispatcherLastHealthRecord {
    param([string]$HealthPath)
    if (-not (Test-Path -LiteralPath $HealthPath -PathType Leaf)) { return $null }
    try {
        $lines = @(Read-DispatcherSharedLines -Path $HealthPath)
        if ($lines.Count -eq 0) { return $null }
        $last = $lines[$lines.Count - 1] | ConvertFrom-Json -ErrorAction Stop
        # Co-review round 3: valid JSON is not yet a record. Handing {} back made every caller's `.state` read throw
        # under StrictMode, on every append after the line - a latch. A last line that is not a record reads as none.
        if ($last -isnot [pscustomobject] -or -not $last.PSObject.Properties['state']) { return $null }
        return $last
    }
    catch { return $null }
}

function Write-DispatcherHookOutputHealth {
    # FR-008: one line per transition - class, error text, first-seen, count, recovered-at. Hashes and machinery
    # error text only; never a prompt, a reply or hook output text.
    param([string]$HealthPath, [ValidateSet('degraded', 'recovered')][string]$State, [string]$Class, [AllowNull()][string]$ErrorText, [AllowNull()][string]$FirstSeen, [int]$Count)
    $now = [DateTimeOffset]::UtcNow.ToString('o')
    $record = [ordered]@{
        schema_version = '1.0'
        state          = $State
        class          = $Class
        error          = $ErrorText
        first_seen     = if ([string]::IsNullOrWhiteSpace($FirstSeen)) { $now } else { $FirstSeen }
        count          = $Count
        recovered_at   = if ($State -eq 'recovered') { $now } else { $null }
        host           = $HostKind
        observed_at    = $now
    }
    $null = Add-DispatcherJournalText -Path $HealthPath -Text (($record | ConvertTo-Json -Compress) + "`n")
}

function Write-DispatcherHookOutputAuthorityRecord {
    # SPECREW-AUTHORITY-CONTROL: workshop-hook-output-identity
    # The workshop authority reader rejects UserPromptSubmit text whose hash was emitted by this
    # dispatcher. Record both the human-visible payload/reason and the host envelope so replay remains
    # non-authoritative whether a host submits the inner text or its transport representation.
    #
    # Feature 202 T003 (FR-001..FR-005, FR-008): no permanent latch. Append with retry; on a persistent failure
    # record the hash in this process's outage-buffer file and a 'degraded' health transition; the next good
    # append flushes every buffer file, clears a legacy `.unhealthy` marker and records 'recovered'. Returns
    # $true when the hash is recorded (journal or buffer) - only then is the output safe to show - and $false when
    # neither accepted it, in which case the caller withholds that output for this turn (FR-005: only that turn
    # fails closed).
    param(
        [AllowNull()][string]$ProjectRoot,
        [AllowEmptyString()][string]$Text,
        [string]$EventName,
        [string]$OutputKind
    )
    if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or [string]::IsNullOrWhiteSpace($Text)) { return $true }
    $paths = Get-DispatcherHookOutputPaths -ProjectRoot $ProjectRoot
    $record = [ordered]@{
        schema_version = '1.0'
        output_hash = Get-DispatcherHookOutputHash -Text $Text
        event = $EventName
        host = $HostKind
        output_kind = $OutputKind
        observed_at = [DateTimeOffset]::UtcNow.ToString('o')
    }
    $line = ($record | ConvertTo-Json -Depth 4 -Compress) + "`n"
    try { [IO.Directory]::CreateDirectory($paths.RuntimeDir) | Out-Null } catch { $null = $_ }

    $appendError = Add-DispatcherJournalText -Path $paths.Journal -Text $line
    if ($null -eq $appendError) {
        Complete-DispatcherHookOutputRecovery -Paths $paths
        return $true
    }

    # Degraded: the hash goes to the outage buffer, which the reader checks before the next prompt decision.
    #
    # Co-review round 2: each buffered record is PUBLISHED AS A CLOSED FILE - written in full under a name the
    # reader and the flush ignore, then renamed into place. No buffer file is ever written after it becomes
    # visible, so a flush can never claim and remove a file a writer still holds open. Appending to a per-process
    # file could not promise that on Linux and macOS, where a rename does not detach a writer that already opened
    # the file, and a hash written after the flush removed it was lost while the output was still shown.
    $temp = $null
    try {
        [IO.Directory]::CreateDirectory($paths.BufferDir) | Out-Null
        $name = '{0}-{1}' -f $PID, [guid]::NewGuid().ToString('N')
        $temp = Join-Path $paths.BufferDir ($name + '.writing')
        [IO.File]::WriteAllText($temp, $line, [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temp, (Join-Path $paths.BufferDir ($name + '.jsonl')))
        $temp = $null
    }
    catch {
        if ($temp) { try { [IO.File]::Delete($temp) } catch { $null = $_ } }
        Write-DispatcherWarn -Code 'HOOK_OUTPUT_UNRECORDED' -Message ("hook output could not be journaled ({0}) or buffered ({1}); it is withheld this turn" -f $appendError, $_.Exception.Message)
        return $false
    }
    $script:DispatcherRecordingDegradedThisFire = $true
    $last = Get-DispatcherLastHealthRecord -HealthPath $paths.Health
    if ($null -eq $last -or [string]$last.state -ne 'degraded') {
        Write-DispatcherHookOutputHealth -HealthPath $paths.Health -State 'degraded' -Class 'journal-append-failed' -ErrorText $appendError -Count 1
    }
    Write-DispatcherWarn -Code 'HOOK_OUTPUT_JOURNAL_DEGRADED' -Message ("journal append failed after retry ({0}); hash buffered, recovery on the next good append" -f $appendError)
    return $true
}

function Complete-DispatcherHookOutputRecovery {
    # After a good append: flush every outage-buffer file into the journal (one write), remove them, clear a legacy
    # marker, and close the degraded episode with 'recovered'. Idempotent: a re-flushed hash is a duplicate line
    # the reader treats exactly like the first.
    #
    # Co-review round 1 (202): only data that was read AND journaled is removed. Each buffer file is first claimed by
    # a rename, so two flushes never both remove it. Buffer files are published closed (see the writer), so nothing
    # writes to a file once it is visible here. A file that cannot be read is kept, and a file whose length changed
    # while it was flushed is kept too; the lines already journaled come back only as harmless duplicates. The
    # claimed name keeps the .jsonl suffix, so the reader still counts it as recorded hook output until it is gone.
    #
    # Co-review round 2: the episode closes ('recovered') only when no buffer file is left. A file kept because it
    # could not be read still holds hashes the reader cannot see, so prompts can still meet an unreadable store;
    # declaring recovery then would hide the degraded disclosure and close the recovery question while replies
    # were still being refused.
    param($Paths)
    $bufferFiles = @(if (Test-Path -LiteralPath $Paths.BufferDir -PathType Container) { Get-ChildItem -LiteralPath $Paths.BufferDir -File -Filter '*.jsonl' })
    $flushed = 0
    if ($bufferFiles.Count -gt 0) {
        $lines = New-Object System.Collections.Generic.List[string]
        $readFiles = New-Object System.Collections.Generic.List[object]
        foreach ($file in $bufferFiles) {
            $claimed = $file.FullName
            if ($file.Name -notmatch '\.flushing-[0-9a-f]{32}\.jsonl$') {
                $claimed = Join-Path $Paths.BufferDir ('{0}.flushing-{1}.jsonl' -f $file.BaseName, [guid]::NewGuid().ToString('N'))
                try { Move-Item -LiteralPath $file.FullName -Destination $claimed -ErrorAction Stop } catch { continue }
            }
            try {
                $length = ([IO.FileInfo]::new($claimed)).Length
                foreach ($l in @(Read-DispatcherSharedLines -Path $claimed)) { $lines.Add($l) }
                $readFiles.Add([pscustomobject]@{ Path = $claimed; Length = $length }) | Out-Null
            }
            catch { $null = $_ }
        }
        if ($lines.Count -gt 0) {
            $flushError = Add-DispatcherJournalText -Path $Paths.Journal -Text (($lines -join "`n") + "`n")
            if ($null -ne $flushError) { return }
        }
        foreach ($read in $readFiles) {
            try {
                if (([IO.FileInfo]::new($read.Path)).Length -ne $read.Length) { continue }
                Remove-Item -LiteralPath $read.Path -Force -ErrorAction Stop
            }
            catch { $null = $_ }
        }
        $flushed = $lines.Count
    }
    $bufferLeft = @(if (Test-Path -LiteralPath $Paths.BufferDir -PathType Container) { Get-ChildItem -LiteralPath $Paths.BufferDir -File -Filter '*.jsonl' }).Count -gt 0
    if ($bufferLeft) { return }
    $hadMarker = Test-Path -LiteralPath $Paths.LegacyMarker -PathType Leaf
    if ($hadMarker) { try { Remove-Item -LiteralPath $Paths.LegacyMarker -Force -ErrorAction Stop } catch { $hadMarker = $false } }
    $last = Get-DispatcherLastHealthRecord -HealthPath $Paths.Health
    if (($null -ne $last -and [string]$last.state -eq 'degraded') -or $hadMarker -or $flushed -gt 0) {
        # Co-review round 6 (202, FR-003): a last line with a state but no class or first_seen passed the reader's guard,
        # and these reads threw under StrictMode after every good append - a latch. Missing fields take safe defaults,
        # so the recovered line still closes the episode.
        $lastClass = if ($null -ne $last -and $null -ne $last.PSObject.Properties['class'] -and -not [string]::IsNullOrWhiteSpace([string]$last.class)) { [string]$last.class } else { 'journal-append-failed' }
        $lastFirstSeen = if ($null -ne $last -and $null -ne $last.PSObject.Properties['first_seen'] -and -not [string]::IsNullOrWhiteSpace([string]$last.first_seen)) { [string]$last.first_seen } else { $null }
        $class = if ($hadMarker -and ($null -eq $last -or [string]$last.state -ne 'degraded')) { 'legacy-marker' } else { $lastClass }
        $firstSeen = if ($null -ne $last -and [string]$last.state -eq 'degraded') { $lastFirstSeen } else { $null }
        Write-DispatcherHookOutputHealth -HealthPath $Paths.Health -State 'recovered' -Class $class -ErrorText $null -FirstSeen $firstSeen -Count $flushed
    }
}

function Get-DispatcherFragmentPriority {
    param([string]$ProviderId)
    switch ($ProviderId) {
        'bootstrap' { return 100 }
        'fallback' { return 90 }
        'refocus' { return 10 }
        default { return 50 }
    }
}

function New-DispatcherFragment {
    param(
        [string]$ProviderId,
        [string]$Text,
        [int]$Order = 0
    )
    return [pscustomobject]@{
        ProviderId = $ProviderId
        Priority   = Get-DispatcherFragmentPriority -ProviderId $ProviderId
        Order      = $Order
        Text       = $Text
    }
}

function Limit-DispatcherFragmentText {
    param(
        [AllowNull()][string]$Text,
        [int]$MaxChars,
        [string]$ProviderId
    )
    if ([string]::IsNullOrWhiteSpace($Text) -or $MaxChars -le 0) { return '' }
    $note = "`n`n[specrew-refocus] lower-priority $ProviderId fragment truncated to fit the SessionStart hook-output cap; bootstrap remains intact. Run `/specrew-refocus` for full refocus context."
    if ($MaxChars -le ($note.Length + 80)) { return '' }
    $bodyCap = $MaxChars - $note.Length
    if ($Text.Length -le $bodyCap) { return $Text }
    $cut = $Text.Substring(0, $bodyCap)
    $nl = $cut.LastIndexOf("`n")
    if ($nl -gt [int]($bodyCap / 2)) { $cut = $cut.Substring(0, $nl) }
    return ($cut.TrimEnd() + $note)
}

function Join-DispatcherFragments {
    param(
        [object[]]$Fragments,
        [string]$EventName,
        [int]$CapChars = $script:HostHookOutputCapChars
    )
    $available = @($Fragments | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.Text) })
    if ($available.Count -eq 0) { return '' }
    if ($EventName -ne 'SessionStart') {
        return ((@($available | ForEach-Object { [string]$_.Text })) -join "`n`n")
    }

    # SessionStart is the only hook event where the startup banner is load-bearing.
    # Compose by policy priority, not catalog order: bootstrap must survive before
    # lower-priority refocus content when the host cap would drop the whole payload.
    # PowerShell emission appends a line ending; reserve two chars so the bytes
    # handed to the host remain below the documented 10k cap after Write-Output.
    $effectiveCap = [Math]::Max(1, ($CapChars - 2))
    $ordered = @($available | Sort-Object @{ Expression = { [int]$_.Priority }; Descending = $true }, @{ Expression = { [int]$_.Order }; Descending = $false })
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($fragment in $ordered) {
        $text = [string]$fragment.Text
        $current = (($kept.ToArray()) -join "`n`n")
        $sep = if ($kept.Count -gt 0) { "`n`n" } else { '' }
        $candidate = $current + $sep + $text
        if ($candidate.Length -le $effectiveCap) {
            $kept.Add($text) | Out-Null
            continue
        }

        if ([int]$fragment.Priority -ge 90) {
            # Bootstrap/fallback are the governed minimum. Keep them whole and
            # make any unresolved oversize visible rather than silently truncating
            # the lifecycle banner.
            $kept.Add($text) | Out-Null
            Write-DispatcherWarn -Code 'PAYLOAD_OVERSIZE' -Message ("priority provider '{0}' is {1} chars; kept intact even though SessionStart may exceed the {2} host hook-output cap" -f $fragment.ProviderId, $text.Length, $CapChars)
            continue
        }

        $remaining = $effectiveCap - $current.Length - $sep.Length
        $limited = Limit-DispatcherFragmentText -Text $text -MaxChars $remaining -ProviderId ([string]$fragment.ProviderId)
        if (-not [string]::IsNullOrWhiteSpace($limited)) {
            $kept.Add($limited) | Out-Null
            Write-DispatcherWarn -Code 'PAYLOAD_CLIPPED' -Message ("lower-priority provider '{0}' truncated so SessionStart output stays under {1} chars" -f $fragment.ProviderId, $CapChars)
        }
        else {
            Write-DispatcherWarn -Code 'PAYLOAD_CLIPPED' -Message ("lower-priority provider '{0}' dropped so SessionStart bootstrap stays under {1} chars" -f $fragment.ProviderId, $CapChars)
        }
    }
    return (($kept.ToArray()) -join "`n`n")
}

function New-GovernedProviderFailureFallback {
    param(
        [string]$HostKind,
        [string[]]$FailedProviders
    )
    $failed = if (@($FailedProviders).Count -gt 0) { (@($FailedProviders | Sort-Object -Unique) -join ', ') } else { 'provider' }   # specrew-dedup-not-a-path
    return (@(
        '[specrew-bootstrap] degraded governed fallback',
        ("Specrew governance is still active, but the normal SessionStart provider path failed ({0})." -f $failed),
        'Continue under the current lifecycle artifacts; do not treat this hook failure as boundary authorization.',
        'Recovery: run `specrew where` to inspect lifecycle state, or `/specrew-refocus` to reload Specrew guidance.',
        ("If hook delivery keeps failing, run `specrew hooks status` and `specrew start --host {0}` from the project root." -f $HostKind)
    ) -join "`n")
}

function Test-DispatcherMapKey {
    param($Map, [string]$Key)
    if ($null -eq $Map) { return $false }
    if ($Map -is [System.Collections.IDictionary]) { return $Map.Contains($Key) }
    return ($null -ne $Map.PSObject.Properties[$Key])
}

function Get-DispatcherMapValue {
    param($Map, [string]$Key, $Default = $null)
    if (-not (Test-DispatcherMapKey -Map $Map -Key $Key)) { return $Default }
    if ($Map -is [System.Collections.IDictionary]) { return $Map[$Key] }
    return $Map.PSObject.Properties[$Key].Value
}

function Get-DispatcherMapKeys {
    param($Map)
    if ($null -eq $Map) { return @() }
    if ($Map -is [System.Collections.IDictionary]) { return @($Map.Keys | ForEach-Object { [string]$_ }) }
    return @($Map.PSObject.Properties | ForEach-Object { [string]$_.Name })
}

function ConvertTo-DispatcherStringArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function ConvertFrom-DispatcherRuntimeBinding {
    param($Runtime)
    $defaultTriggers = [pscustomobject]@{}
    return [pscustomobject]@{
        BootstrapDeliveryEvents = $(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $Runtime -Key 'BootstrapDeliveryEvents' -Default @('SessionStart')))
        B3DeliveryEvents        = $(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $Runtime -Key 'B3DeliveryEvents' -Default @('PostToolUse', 'UserPromptSubmit')))
        RefocusTriggerByEvent   = Get-DispatcherMapValue -Map $Runtime -Key 'RefocusTriggerByEvent' -Default $defaultTriggers
        SuppressedRefocusEvents = $(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $Runtime -Key 'SuppressedRefocusEvents' -Default @()))
        OutputShape             = [string](Get-DispatcherMapValue -Map $Runtime -Key 'OutputShape' -Default 'plain-or-hookSpecificOutput')
        DecisionOnlyEvents      = $(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $Runtime -Key 'DecisionOnlyEvents' -Default @()))
        BootstrapDeliveryMode   = [string](Get-DispatcherMapValue -Map $Runtime -Key 'BootstrapDeliveryMode' -Default 'inline')
        # FR-004 (185): the host's STOP-BLOCK lever - how a Stop-class consumer force-continues the turn so the
        # 6-section re-entry packet renders AT the stop (verified capability matrix, research/stop-block-capability-matrix.md):
        #   decision-block    -> {"decision":"block","reason":...}    (claude, codex, copilot)
        #   decision-continue -> {"decision":"continue","reason":...}  (antigravity - any non-continue value allows the stop)
        #   followup-message  -> {"followup_message":...}              (cursor - best-effort re-triggered turn, NOT a hard same-turn block)
        #   none              -> cannot block; degrades to the cooperative instruction only
        StopBlockShape          = [string](Get-DispatcherMapValue -Map $Runtime -Key 'StopBlockShape' -Default 'none')
        # Feature 202 T002 (DA-1, option B): the host's declared input contract (host.psd1). $null when the
        # binding predates it; ConvertTo-SpecrewTurnRecord then uses the host-neutral defaults below.
        InputFieldMap           = Get-DispatcherMapValue -Map $Runtime -Key 'InputFieldMap'
        OriginRules             = Get-DispatcherMapValue -Map $Runtime -Key 'OriginRules'
        InputTransform          = [string](Get-DispatcherMapValue -Map $Runtime -Key 'InputTransform' -Default '')
        # Feature 202 iteration 002, T016 (FR-028, DA-1): this host's payload signature and the other hosts'.
        PayloadSignature         = Get-DispatcherMapValue -Map $Runtime -Key 'PayloadSignature'
        ForeignPayloadSignatures = Get-DispatcherMapValue -Map $Runtime -Key 'ForeignPayloadSignatures'
    }
}

function Test-DispatcherPayloadSignature {
    # $true when the payload carries every AllOf field and none of the NoneOf fields of the rule for this event
    # ('Default' when the event has no rule of its own); $false when it does not; $null when there is no rule.
    param($PayloadKeys, $Signature, [string]$EventName)
    if ($null -eq $Signature) { return $null }
    $rule = $null
    if (Test-DispatcherMapKey -Map $Signature -Key $EventName) { $rule = Get-DispatcherMapValue -Map $Signature -Key $EventName }
    elseif (Test-DispatcherMapKey -Map $Signature -Key 'Default') { $rule = Get-DispatcherMapValue -Map $Signature -Key 'Default' }
    if ($null -eq $rule) { return $null }
    $keys = @($PayloadKeys)
    foreach ($field in @(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $rule -Key 'AllOf' -Default @()))) { if ($keys -cnotcontains $field) { return $false } }
    foreach ($field in @(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $rule -Key 'NoneOf' -Default @()))) { if ($keys -ccontains $field) { return $false } }
    return $true
}

function Get-DispatcherPayloadHostMatch {
    # Feature 202 iteration 002, T016 (FR-028, DA-1, with the maintainer's change): whose payload is this?
    #   own      - it matches this host's signature (or the binding declares none): handle it.
    #   foreign  - it matches ANOTHER known host's signature and not this host's: stand down, write nothing.
    #   unknown  - this host declares a signature and the payload matches no known host: handle it as today and
    #              log the shape once, so a host that changes its payload can never switch governance off silently.
    param($Payload, $Binding, [string]$EventName)
    if ($null -eq $Payload -or -not ($Payload -is [psobject])) { return [pscustomobject]@{ Kind = 'own'; Host = '' } }
    $keys = @($Payload.PSObject.Properties | ForEach-Object { [string]$_.Name })
    $ownSignature = Get-DispatcherMapValue -Map $Binding -Key 'PayloadSignature'
    $own = Test-DispatcherPayloadSignature -PayloadKeys $keys -Signature $ownSignature -EventName $EventName
    if ($own -eq $true) { return [pscustomobject]@{ Kind = 'own'; Host = '' } }
    $foreign = Get-DispatcherMapValue -Map $Binding -Key 'ForeignPayloadSignatures'
    if ($null -ne $foreign) {
        foreach ($otherHost in @(Get-DispatcherMapKeys -Map $foreign)) {
            if ((Test-DispatcherPayloadSignature -PayloadKeys $keys -Signature (Get-DispatcherMapValue -Map $foreign -Key ([string]$otherHost)) -EventName $EventName) -eq $true) {
                return [pscustomobject]@{ Kind = 'foreign'; Host = [string]$otherHost }
            }
        }
    }
    if ($null -eq $own) { return [pscustomobject]@{ Kind = 'own'; Host = '' } }
    return [pscustomobject]@{ Kind = 'unknown'; Host = ''; Keys = @($keys | Sort-Object) }
}

function Write-DispatcherUnrecognizedPayloadLog {
    # Once per (host, event, set of field names): the field names only, never a value. Fail-open.
    param([string]$ProjectRoot, [string]$HostKind, [string]$EventName, [string[]]$Keys)
    try {
        $joined = (@($Keys) -join ',')
        $hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($HostKind + '|' + $EventName + '|' + $joined)))).ToLowerInvariant().Substring(0, 12)
        $dir = Join-Path $ProjectRoot '.specrew/runtime/hook-health'
        $path = Join-Path $dir ("unrecognized-payload-{0}-{1}-{2}.json" -f ($HostKind -replace '[^A-Za-z0-9_.-]', ''), ($EventName -replace '[^A-Za-z0-9_.-]', ''), $hash)
        if (Test-Path -LiteralPath $path -PathType Leaf) { return }
        [IO.Directory]::CreateDirectory($dir) | Out-Null
        $record = [ordered]@{ schema = 'specrew-unrecognized-payload/v1'; host = $HostKind; event = $EventName; field_names = @($Keys); first_seen = [DateTimeOffset]::UtcNow.ToString('o')
            note = 'This hook received a payload that matches no known host signature. It was handled as before; this record is written once per shape.' }
        [IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
        Write-DispatcherWarn -Code 'PAYLOAD_SHAPE' -Message ("{0} {1}: payload matches no known host signature; handled as before and recorded once" -f $HostKind, $EventName)
    }
    catch { $null = $_ }
}

function Find-DispatcherHostManifestPath {
    param([string]$Kind, [AllowNull()][string]$ProjectRoot)
    $starts = New-Object System.Collections.Generic.List[string]
    foreach ($start in @($env:SPECREW_MODULE_PATH, $PSScriptRoot, $ProjectRoot)) {
        if (-not [string]::IsNullOrWhiteSpace($start) -and (Test-Path -LiteralPath $start -PathType Container)) {
            $starts.Add((Resolve-Path -LiteralPath $start).Path) | Out-Null
        }
    }
    foreach ($start in $starts.ToArray()) {
        $candidate = $start
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $probe = Join-Path $candidate ("hosts/{0}/host.psd1" -f $Kind)
            if (Test-Path -LiteralPath $probe -PathType Leaf) { return $probe }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    try {
        $module = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase ("hosts/{0}/host.psd1" -f $Kind)) -PathType Leaf } |
            Select-Object -First 1
        if ($module) { return (Join-Path $module.ModuleBase ("hosts/{0}/host.psd1" -f $Kind)) }
    }
    catch { $null = $_ }
    return $null
}

function Resolve-DispatcherHostRuntimeBinding {
    param(
        [string]$Kind,
        [AllowNull()][string]$ProjectRoot,
        [AllowNull()][string]$EncodedBinding
    )

    if (-not [string]::IsNullOrWhiteSpace($EncodedBinding)) {
        try {
            $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($EncodedBinding))
            return (ConvertFrom-DispatcherRuntimeBinding -Runtime ($json | ConvertFrom-Json -ErrorAction Stop))
        }
        catch {
            Write-DispatcherWarn -Code 'HOST_BINDING' -Message ("runtime binding for host '{0}' is unreadable; trying manifest fallback" -f $Kind)
        }
    }

    $manifestPath = Find-DispatcherHostManifestPath -Kind $Kind -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($manifestPath)) {
        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
            $hookBindings = Get-DispatcherMapValue -Map $manifest -Key 'RefocusHookBindings'
            $runtime = Get-DispatcherMapValue -Map $hookBindings -Key 'DispatcherRuntime'
            if ($null -ne $runtime) { return (ConvertFrom-DispatcherRuntimeBinding -Runtime $runtime) }
        }
        catch {
            Write-DispatcherWarn -Code 'HOST_BINDING' -Message ("manifest runtime binding for host '{0}' is unreadable; using dispatcher defaults" -f $Kind)
        }
    }

    return (ConvertFrom-DispatcherRuntimeBinding -Runtime ([pscustomobject]@{}))
}

function Test-DispatcherEventInList {
    param([string]$EventName, [string[]]$Events)
    return (@($Events) -contains $EventName)
}

function Test-IsBootstrapDeliveryEvent {
    param([string]$EventName, $Binding)
    return (Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'BootstrapDeliveryEvents' -Default @('SessionStart')))
}

function Test-IsB3DeliveryEvent {
    param([string]$EventName, $Binding)
    return (Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'B3DeliveryEvents' -Default @('PostToolUse', 'UserPromptSubmit')))
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
    # Security control (lens 5): the session id becomes part of a FILENAME - normalize
    # everything outside [a-zA-Z0-9-] and fall back per launch if no usable id remains.
    if ([string]::IsNullOrWhiteSpace($RawSessionId)) { return ('launch-{0}' -f ([guid]::NewGuid().ToString('N'))) }
    $clean = (([string]$RawSessionId) -replace '[^a-zA-Z0-9-]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($clean)) { return ('launch-{0}' -f ([guid]::NewGuid().ToString('N'))) }
    return $clean
}

# ---------------------------------------------------------------------------
# Standard turn record (Feature 202 T002; FR-006; DA-1 option B). The ONE place a host payload is read. Each host
# declares its input contract as data (hosts/<host>/host.psd1 DispatcherRuntime: InputFieldMap, OriginRules,
# optional InputTransform); this code applies whatever is declared and names no host. Providers receive the
# record's fields as clean args (and the bootstrap the whole record), so no provider re-parses the payload.
# ---------------------------------------------------------------------------

# Host-neutral defaults, used only for a binding that predates the declared contract (a project deployed before
# 202 and not yet redeployed). They are the union the dispatcher accepted before, so such a project keeps working.
$script:DefaultTurnInputFieldMap = @{
    SessionId      = @('session_id', 'sessionId', 'conversation_id', 'conversationId')
    Prompt         = @('prompt', 'user_prompt', 'userPrompt', 'message', 'text', 'content')
    TranscriptPath = @('transcript_path', 'transcriptPath')
    Source         = @('source')
    ToolName       = @('toolName', 'tool_name')
    ToolOutcome    = @('toolResult.toolTelemetry.properties.outcome')
    ToolQuestion   = @('toolResult.toolTelemetry.restrictedProperties.question')
    StopHookActive = @('stop_hook_active')
}
$script:DefaultTurnOriginRules = @(
    @{ Origin = 'host-injected'; Rule = 'hook-output-journal' },
    @{ Origin = 'host-injected'; Rule = 'prompt-pattern'; Pattern = '(?is)^\s*<(?:task-notification|hook_prompt|turn_aborted|system-reminder|environment_context)\b' },
    @{ Origin = 'host-injected'; Rule = 'prompt-pattern'; Pattern = '(?is)^\s*(?:Specrew:|Specrew\s+review\s+[-—]|\[specrew-|AWAITING YOUR VERDICT:|BOUNDARY NOT READY FOR A VERDICT:|Campaign review authority\b)' },
    @{ Origin = 'typed-user'; Rule = 'prompt-present' }
)

# Shared transform registry: small, named, tested transforms for host quirks a field map cannot express. A host
# binding names at most one (InputTransform). Each returns an origin, or $null to let the origin rules decide.
$script:TurnRecordTransforms = @{
    # A dismissed ask_user form is an absence, never an answer. 1.0.96 emits no hook event for a dismissal
    # (Esc -> "User cancelled the request.", Ctrl+O -> "User responded: <default>", both tool results; B4F-113);
    # the legacy "User skipped question" string stays recognized if a host ever submits it as a prompt.
    'ask-user-dismissal-text' = {
        param([string]$Text)
        if ($Text -match '^\s*(?:User skipped question|User cancelled the request\.)\s*$') { return 'host-injected' }
        return $null
    }
}

function Read-DispatcherStdinText {
    # Hook payloads are UTF-8. A host-spawned hook's console input code page is the OEM one (measured ibm437 on
    # every validated host, 202 research.md T001) and [Console]::In decodes with it, so a Hebrew prompt reached
    # the providers as mojibake. Read the raw bytes and decode UTF-8 explicitly; a leading BOM is dropped.
    $buffer = [IO.MemoryStream]::new()
    [Console]::OpenStandardInput().CopyTo($buffer)
    return [Text.UTF8Encoding]::new($false).GetString($buffer.ToArray()).TrimStart([char]0xFEFF)
}

function Get-DispatcherTurnFieldValue {
    # First non-empty value among the declared paths. A path may be dotted (toolResult.toolTelemetry.x).
    param($Payload, [string[]]$Paths)
    if ($null -eq $Payload) { return $null }
    foreach ($path in @($Paths)) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $node = $Payload
        foreach ($segment in $path.Split('.')) {
            if ($null -eq $node -or $node -isnot [psobject] -or $null -eq $node.PSObject.Properties[$segment]) { $node = $null; break }
            $node = $node.PSObject.Properties[$segment].Value
        }
        if ($null -eq $node) { continue }
        if ($node -is [bool]) { return $node }
        if ($node -is [string]) { if (-not [string]::IsNullOrWhiteSpace($node)) { return $node }; continue }
        if ($node -is [psobject] -or $node -is [System.Array]) { continue }
        if (-not [string]::IsNullOrWhiteSpace([string]$node)) { return [string]$node }
    }
    return $null
}

function Get-DispatcherTurnFieldPaths {
    # The declared paths for one field; a key the binding does not declare falls back to the host-neutral default.
    param($Binding, [string]$Field)
    $declared = Get-DispatcherMapValue -Map $Binding -Key 'InputFieldMap'
    if ($null -ne $declared -and (Test-DispatcherMapKey -Map $declared -Key $Field)) { return @(ConvertTo-DispatcherStringArray (Get-DispatcherMapValue -Map $declared -Key $Field)) }
    return @($script:DefaultTurnInputFieldMap[$Field])
}

function Test-DispatcherHookOutputJournalText {
    # 'match' when the text equals output this dispatcher recorded - in the journal or in an outage-buffer file
    # (T003) - i.e. a host replaying a Stop reason; 'none' when it does not; 'unavailable' when a store cannot be
    # read. A legacy `.unhealthy` marker no longer makes the journal unable to vouch (FR-003): it is degraded only.
    param([AllowNull()][string]$ProjectRoot, [AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { return 'none' }
    $paths = Get-DispatcherHookOutputPaths -ProjectRoot $ProjectRoot
    $hash = Get-DispatcherHookOutputHash -Text $Text
    $sources = @(if (Test-Path -LiteralPath $paths.BufferDir -PathType Container) { Get-ChildItem -LiteralPath $paths.BufferDir -File -Filter '*.jsonl' | ForEach-Object FullName })
    # A journal set aside by an approved recovery (T004, FR-009) still counts, as it does for the store's reader.
    $sources += @(Get-ChildItem -LiteralPath $paths.RuntimeDir -File -Filter 'hook-output-authority.set-aside-*.jsonl' -ErrorAction SilentlyContinue | ForEach-Object FullName)
    if (Test-Path -LiteralPath $paths.Journal -PathType Leaf) { $sources += $paths.Journal }
    foreach ($source in $sources) {
        # A store that cannot be READ cannot vouch: 'unavailable', for this turn only. A malformed LINE is not that
        # (co-review round 2): it is skipped, exactly as the store's reader skips it, so one torn or hand-damaged
        # line no longer turns every later typed reply into origin 'unknown' (FR-003).
        $lines = $null
        try { $lines = @(Read-DispatcherSharedLines -Path $source) }
        catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { continue }  # a buffer file flushed between listing and reading
        catch { return 'unavailable' }
        foreach ($line in $lines) {
            $record = $null
            try { $record = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($null -ne $record -and $record.PSObject.Properties['output_hash'] -and [string]$record.output_hash -ceq $hash) { return 'match' }
        }
    }
    return 'none'
}

function Get-DispatcherTurnOrigin {
    param([string]$EventName, [AllowNull()][string]$TypedText, $Binding, [AllowNull()][string]$ProjectRoot)
    if ($EventName -notin @('UserPromptSubmit', 'PreInvocation')) { return 'unknown' }
    if ([string]::IsNullOrWhiteSpace($TypedText)) { return 'unknown' }
    $transformName = [string](Get-DispatcherMapValue -Map $Binding -Key 'InputTransform' -Default '')
    if (-not [string]::IsNullOrWhiteSpace($transformName)) {
        if ($script:TurnRecordTransforms.ContainsKey($transformName)) {
            $transformed = & $script:TurnRecordTransforms[$transformName] $TypedText
            if (-not [string]::IsNullOrWhiteSpace([string]$transformed)) { return [string]$transformed }
        }
        else {
            Write-DispatcherWarn -Code 'TURN_TRANSFORM' -Message ("host binding names unknown transform '{0}'; origin rules decide alone" -f $transformName)
        }
    }
    $rules = Get-DispatcherMapValue -Map $Binding -Key 'OriginRules'
    if ($null -eq $rules) { $rules = $script:DefaultTurnOriginRules }
    foreach ($rule in @($rules)) {
        $ruleOrigin = [string](Get-DispatcherMapValue -Map $rule -Key 'Origin')
        if ($ruleOrigin -notin @('typed-user', 'host-injected', 'unknown')) { continue }
        switch ([string](Get-DispatcherMapValue -Map $rule -Key 'Rule')) {
            'hook-output-journal' {
                $state = Test-DispatcherHookOutputJournalText -ProjectRoot $ProjectRoot -Text $TypedText
                if ($state -eq 'match') { return $ruleOrigin }
                # Fail closed: a journal that cannot vouch means this text cannot be proven NOT to be a replay.
                if ($state -eq 'unavailable') { return 'unknown' }
            }
            'prompt-pattern' {
                $pattern = [string](Get-DispatcherMapValue -Map $rule -Key 'Pattern')
                if (-not [string]::IsNullOrWhiteSpace($pattern) -and $TypedText -match $pattern) { return $ruleOrigin }
            }
            'prompt-present' { return $ruleOrigin }
        }
    }
    return 'unknown'
}

function ConvertTo-SpecrewTurnRecord {
    # The single normalizer. Every field comes from the binding's declared paths; the origin from its declared
    # rules and named transform. Shape: data-model.md "Standard turn record".
    param(
        [Parameter(Mandatory)][string]$EventName,
        [Parameter(Mandatory)][string]$HostName,
        $Payload,
        $Binding,
        [AllowNull()][string]$ProjectRoot
    )
    $sessionId = Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'SessionId')
    $isPromptEvent = $EventName -in @('UserPromptSubmit', 'PreInvocation')
    $typedText = if ($isPromptEvent) { Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'Prompt') } else { $null }
    $toolName = Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'ToolName')
    $tool = $null
    if (-not [string]::IsNullOrWhiteSpace([string]$toolName)) {
        $tool = [ordered]@{
            name     = [string]$toolName
            outcome  = [string](Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'ToolOutcome'))
            question = [string](Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'ToolQuestion'))
        }
    }
    $stopHookActive = Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'StopHookActive')
    # Feature 202 iteration 002, T017 (FR-027, DA-2): the host's own ID for this message, when its binding declares
    # one (Claude prompt_id, Codex turn_id). A binding with no MessageId field declares 'none': its message hook is
    # the only recording path for a typed approval.
    $messageIdPaths = @(Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'MessageId' | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $messageId = if ($isPromptEvent -and $messageIdPaths.Count -gt 0) { Get-DispatcherTurnFieldValue -Payload $Payload -Paths $messageIdPaths } else { $null }
    return [ordered]@{
        schema           = 'specrew-turn-record/v1'
        event            = $EventName
        host             = $HostName
        session_id       = if ([string]::IsNullOrWhiteSpace([string]$sessionId)) { $null } else { [string]$sessionId }
        safe_session_id  = Get-SanitizedSessionId -RawSessionId ([string]$sessionId)
        source           = $(Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'Source'))
        typed_text       = $typedText
        origin           = Get-DispatcherTurnOrigin -EventName $EventName -TypedText $typedText -Binding $Binding -ProjectRoot $ProjectRoot
        transcript_path  = $(Get-DispatcherTurnFieldValue -Payload $Payload -Paths (Get-DispatcherTurnFieldPaths -Binding $Binding -Field 'TranscriptPath'))
        stop_hook_active = ($stopHookActive -eq $true -or [string]$stopHookActive -eq 'True')
        tool             = $tool
        message_id       = if ([string]::IsNullOrWhiteSpace([string]$messageId)) { $null } else { [string]$messageId }
        message_identity = if ($messageIdPaths.Count -gt 0) { 'declared' } else { 'none' }
    }
}

function ConvertTo-DispatcherTurnRecordArgument {
    # The record a provider receives on --turn-record: base64 UTF-8 JSON without the prompt text (that rides
    # --last-user-message) and without tool detail, so the argument stays small and carries no user text.
    param($TurnRecord)
    $slim = [ordered]@{}
    foreach ($key in $TurnRecord.Keys) { if ($key -notin @('typed_text', 'tool')) { $slim[$key] = $TurnRecord[$key] } }
    return [Convert]::ToBase64String([Text.UTF8Encoding]::new($false).GetBytes(($slim | ConvertTo-Json -Depth 4 -Compress)))
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
        # dispatcher-local v2-tolerant boundary read = the hook-dispatcher mirror of Get-SpecrewStartContextBoundary.
        # The dispatcher is self-contained (loads NO shared-governance), so the logic is mirrored here and pinned
        # identical to the canonical by the boundary-reader conformance test. v1: session_state.boundary_type;
        # v2 (no session_state): boundary_enforcement.last_authorized_boundary. Previously v1-only -> a v2
        # start-context read $null -> B3 boundary-cross watch never saw a cursor and could not fire.
        $cursor = $null
        if ($ctx.PSObject.Properties['session_state'] -and $null -ne $ctx.session_state -and $ctx.session_state.PSObject.Properties['boundary_type']) {
            $cursor = [string]$ctx.session_state.boundary_type
        }
        if ([string]::IsNullOrWhiteSpace($cursor) -and $ctx.PSObject.Properties['boundary_enforcement'] -and $null -ne $ctx.boundary_enforcement -and $ctx.boundary_enforcement.PSObject.Properties['last_authorized_boundary']) {
            $cursor = [string]$ctx.boundary_enforcement.last_authorized_boundary
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
    param([string]$EventName, [AllowNull()][string]$Source, $Binding)
    # RefocusProvider routing (FR-009 surface; B3 state-diff lands in T007):
    #   SessionStart source: compact            -> B1 (general + current stage)
    #   SessionStart source: startup|resume|clear -> B2 (launch grounding)
    #   Host-defined B3 events                   -> B3 (boundary-cross; T007 gates
    #                                               this behind the state-diff)
    if (Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'SuppressedRefocusEvents' -Default @())) {
        return $null
    }
    if ($EventName -eq 'SessionStart') {
        if ($Source -eq 'compact') { return @('--trigger', 'b1') }
        return @('--trigger', 'b2')
    }
    $triggerMap = Get-DispatcherMapValue -Map $Binding -Key 'RefocusTriggerByEvent' -Default ([pscustomobject]@{})
    $explicitTrigger = Get-DispatcherMapValue -Map $triggerMap -Key $EventName
    if (-not [string]::IsNullOrWhiteSpace([string]$explicitTrigger)) {
        return @('--trigger', [string]$explicitTrigger)
    }
    if (Test-IsB3DeliveryEvent -EventName $EventName -Binding $Binding) { return @('--trigger', 'b3') }
    return $null
}

function ConvertTo-DispatcherInjectionOutput {
    # Per-host event output shaping (C2) is manifest data
    # (RefocusHookBindings.DispatcherRuntime.OutputShape). The dispatcher only
    # knows generic envelope strategies; adding or changing a host updates the
    # manifest, not this core switch.
    param([string]$EventName, [AllowEmptyString()][string]$Payload, $Binding)
    $renderedOutput = $null
    if (Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'DecisionOnlyEvents' -Default @())) {
        $renderedOutput = @{} | ConvertTo-Json -Depth 3 -Compress
    }
    $outputShape = [string](Get-DispatcherMapValue -Map $Binding -Key 'OutputShape' -Default 'plain-or-hookSpecificOutput')
    if ($null -eq $renderedOutput) { switch ($outputShape) {
        'injectSteps' {
            if (-not [string]::IsNullOrWhiteSpace($Payload)) {
                $renderedOutput = @{ injectSteps = @(@{ ephemeralMessage = $Payload }) } | ConvertTo-Json -Depth 6 -Compress
            }
            else {
                $renderedOutput = @{} | ConvertTo-Json -Depth 3 -Compress
            }
        }
        'hookSpecificOutput' {
            $renderedOutput = @{ hookSpecificOutput = @{ hookEventName = $EventName; additionalContext = $Payload } } | ConvertTo-Json -Depth 4 -Compress
        }
        'additionalContext' {
            $renderedOutput = @{ additionalContext = $Payload } | ConvertTo-Json -Depth 3 -Compress
        }
        'additional_context' {
            $renderedOutput = @{ additional_context = $Payload } | ConvertTo-Json -Depth 3 -Compress
        }
        default {
            if ($EventName -in @('PostToolUse', 'UserPromptSubmit')) {
                $renderedOutput = @{ hookSpecificOutput = @{ hookEventName = $EventName; additionalContext = $Payload } } | ConvertTo-Json -Depth 4 -Compress
            }
            else {
                $renderedOutput = $Payload
            }
        }
    } }
    return $renderedOutput
}

function Get-DispatcherRecordingDisclosure {
    # Co-review round 3 (202, FR-007): the reply-recording disclosure for an episode this fire found at its own append,
    # with whether the human's reply was used - read from the receipt outcome the provider journaled during this fire.
    # The wording is the store's, so every surface says the same sentence; the store is loaded only on this rare path.
    param([AllowNull()][string]$ProjectRoot, [switch]$Withheld)
    $fallback = if ($Withheld) { "Specrew: this turn's Specrew guidance could not be recorded safely, so it was held back, and nothing is lost. Mention this to the human in one sentence." } else { 'Specrew: replies are being recorded in a fallback record until the main one is free again, and nothing is lost. Mention this to the human in one sentence.' }
    try {
        if (-not (Get-Command Get-SpecrewReplyRecordingWithheldDisclosure -ErrorAction SilentlyContinue)) {
            foreach ($candidate in @((Join-Path $PSScriptRoot 'workshop-authority-store.ps1'), (Join-Path ([string]$env:SPECREW_MODULE_PATH) 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'), (Join-Path $PSScriptRoot '../../extensions/specrew-speckit/scripts/workshop-authority-store.ps1'))) {
                if (Test-Path -LiteralPath $candidate -PathType Leaf) { . $candidate; break }
            }
        }
        if (-not (Get-Command Get-SpecrewReplyRecordingWithheldDisclosure -ErrorAction SilentlyContinue)) { return $fallback }
        $outcome = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $null } else { Get-SpecrewWorkshopTurnReceiptOutcome -ProjectRoot $ProjectRoot -Since $script:DispatcherStartedUtc -Response $script:DispatcherTurnTypedText -SessionId $script:DispatcherTurnSessionId -HostKind $HostKind }
        if ($Withheld) { return (Get-SpecrewReplyRecordingWithheldDisclosure -Outcome $outcome) }
        $text = Get-SpecrewReplyRecordingDegradedDisclosure -ProjectRoot $ProjectRoot -Outcome $outcome
        if ([string]::IsNullOrWhiteSpace($text)) { return $fallback }
        return $text
    }
    catch { return $fallback }
}

function Write-InjectionOutput {
    param([string]$EventName, [string]$Payload, $Binding, [AllowNull()][string]$ProjectRoot)
    # F-174 iter-11 (P2): cap-overflow observability. Every current hook host caps its output (claude STDOUT +
    # additionalContext at 10,000 chars on v2.1.177; codex drops oversized additionalContext; copilot/cursor
    # caps unverified-but-suspected). When the ASSEMBLED payload (all provider fragments joined - the bootstrap
    # directive + the variable refocus fragment) exceeds the cap, the host SILENTLY drops it to a file + a ~2KB
    # preview and the directive never reaches the model (the exact iter-11 break). The providers bound their own
    # inlined content, but this is the ONE place that sees the joined total, so it is the right place to make an
    # overflow VISIBLE. This is observability only (the advisor's "defensible cap-role"): WARN, never truncate -
    # a blind truncate here would drop the integrity-critical mid-payload sections (e.g. AWAITING YOUR VERDICT).
    if (-not [string]::IsNullOrEmpty($Payload) -and $Payload.Length -gt 10000) {
        Write-DispatcherWarn -Code 'PAYLOAD_OVERSIZE' -Message ("assembled {0} payload is {1} chars (> the 10000 host hook-output cap); the host will drop it to a file + preview and the directive may not reach the model - a provider's inlined content needs tightening (F-174 P2)" -f $EventName, $Payload.Length)
    }
    $renderedOutput = ConvertTo-DispatcherInjectionOutput -EventName $EventName -Payload $Payload -Binding $Binding
    $decisionOnly = Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'DecisionOnlyEvents' -Default @())
    $script:DispatcherRecordingDegradedThisFire = $false
    $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text $Payload -EventName $EventName -OutputKind 'payload'
    if ($recorded -and ([string]$renderedOutput).Trim() -cne ([string]$Payload).Trim()) {
        $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text ([string]$renderedOutput) -EventName $EventName -OutputKind 'envelope'
    }
    # Co-review round 3 (202, FR-007 / SC-002): the providers composed this payload BEFORE this append, so a degraded
    # episode that starts HERE is in no provider's disclosure. Say it in this same turn, with whether the reply was used,
    # and record the output as it is actually delivered. A payload that already carries the disclosure gets no copy.
    if ($recorded -and $script:DispatcherRecordingDegradedThisFire -and -not $decisionOnly -and -not ([string]$Payload).Contains('recorded in a fallback record')) {
        $disclosure = Get-DispatcherRecordingDisclosure -ProjectRoot $ProjectRoot
        if (-not [string]::IsNullOrWhiteSpace($disclosure)) {
            $Payload = ([string]$Payload).TrimEnd() + "`n`n" + $disclosure
            $renderedOutput = ConvertTo-DispatcherInjectionOutput -EventName $EventName -Payload $Payload -Binding $Binding
            $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text $Payload -EventName $EventName -OutputKind 'payload'
            if ($recorded -and ([string]$renderedOutput).Trim() -cne ([string]$Payload).Trim()) {
                $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text ([string]$renderedOutput) -EventName $EventName -OutputKind 'envelope'
            }
        }
    }
    if (-not $recorded) {
        # FR-005: output whose hash could be neither journaled nor buffered could later be replayed as a "reply"
        # with nothing to match it against. Withhold it for this turn only; a decision-only host still gets no-op JSON.
        $script:DispatcherOutputWithheldThisFire = $true
        if ($decisionOnly) {
            Write-Output (@{} | ConvertTo-Json -Depth 3 -Compress)
            return
        }
        # Co-review round 3: withheld is still said (FR-007). The one sentence shown instead starts with 'Specrew:', which is
        # never accepted as a typed reply, so it is safe to show unrecorded.
        $withheld = Get-DispatcherRecordingDisclosure -ProjectRoot $ProjectRoot -Withheld
        if (-not [string]::IsNullOrWhiteSpace($withheld)) { Write-Output (ConvertTo-DispatcherInjectionOutput -EventName $EventName -Payload $withheld -Binding $Binding) }
        return
    }
    Write-Output $renderedOutput
}

function Write-DecisionOnlyNoopIfNeeded {
    param([string]$EventName, $Binding)
    if (Test-DispatcherEventInList -EventName $EventName -Events @(Get-DispatcherMapValue -Map $Binding -Key 'DecisionOnlyEvents' -Default @())) {
        Write-InjectionOutput -EventName $EventName -Payload '' -Binding $Binding
    }
}

# The blocking StopBlockShapes (a host that force-continues the turn); 'none' is excluded (cannot block).
$script:SpecrewStopBlockShapes = @('decision-block', 'decision-continue', 'followup-message')

function Write-StopBlockOutput {
    # FR-004/FR-005/FR-015 (185): emit the host's STOP-BLOCK envelope (to the hook's stdout) so the agent
    # force-continues and renders the 6-section re-entry packet AT the stop (the $Reason carries the directive).
    # Per-host shape is the verified capability matrix (research/stop-block-capability-matrix.md). Writes ONLY the
    # envelope JSON (no return value - the caller guards $Shape against $script:SpecrewStopBlockShapes first, so a
    # leaked return cannot corrupt the hook stdout the host parses).
    param(
        [string]$Shape,
        [string]$Reason,
        [AllowNull()][string]$ProjectRoot,
        [string]$EventName = 'Stop'
    )
    $renderedOutput = ConvertTo-DispatcherStopBlockOutput -Shape $Shape -Reason $Reason
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $script:DispatcherRecordingDegradedThisFire = $false
        $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text $Reason -EventName $EventName -OutputKind 'payload'
        if ($recorded) { $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text ([string]$renderedOutput) -EventName $EventName -OutputKind 'envelope' }
        # Co-review round 4 (202, FR-007): the stop block gets the same same-turn disclosure as injected output. The
        # providers composed this reason BEFORE this append, so an episode that begins here is in no provider's text.
        if ($recorded -and $script:DispatcherRecordingDegradedThisFire -and -not ([string]$Reason).Contains('recorded in a fallback record')) {
            $disclosure = Get-DispatcherRecordingDisclosure -ProjectRoot $ProjectRoot
            if (-not [string]::IsNullOrWhiteSpace($disclosure)) {
                $Reason = ([string]$Reason).TrimEnd() + "`n`n" + $disclosure
                $renderedOutput = ConvertTo-DispatcherStopBlockOutput -Shape $Shape -Reason $Reason
                $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text $Reason -EventName $EventName -OutputKind 'payload'
                if ($recorded) { $recorded = Write-DispatcherHookOutputAuthorityRecord -ProjectRoot $ProjectRoot -Text ([string]$renderedOutput) -EventName $EventName -OutputKind 'envelope' }
            }
        }
        if (-not $recorded) {
            # FR-005: an unrecordable reason is withheld this turn. Co-review round 4 (FR-007): withheld is still said -
            # the block carries the one 'Specrew:' sentence instead, which is never accepted as a typed reply, so it is
            # safe to show unrecorded. It is a block like any other, so the host's stop_hook_active (or the provider's
            # own cap) bounds it. Valid no-op JSON remains the fallback when no sentence can be composed.
            $script:DispatcherOutputWithheldThisFire = $true
            $withheld = Get-DispatcherRecordingDisclosure -ProjectRoot $ProjectRoot -Withheld
            if (-not [string]::IsNullOrWhiteSpace($withheld)) { Write-Output (ConvertTo-DispatcherStopBlockOutput -Shape $Shape -Reason $withheld) }
            else { Write-Output (@{} | ConvertTo-Json -Depth 3 -Compress) }
            return
        }
    }
    Write-Output $renderedOutput
}

function Clear-DispatcherUndeliveredOrientationStamp {
    # Co-review round 4 (202, FR-005 / FR-014): the bootstrap provider stamps the session's orientation as supplied
    # BEFORE it returns it. When this fire then withheld its output, that orientation never reached the human - and
    # the stamp would make every later prompt skip it (the dispatcher skips the provider, and conformance drops its
    # dials fallback). Only a stamp written DURING this fire is taken back; an earlier, delivered one stays.
    param([AllowNull()][string]$ProjectRoot, [AllowNull()][string]$SessionId)
    if (-not $script:DispatcherOutputWithheldThisFire) { return }
    if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or [string]::IsNullOrWhiteSpace($SessionId)) { return }
    try {
        $stamp = Join-Path $ProjectRoot ('.specrew/runtime/hook-bootstrap-orientation-{0}.json' -f ($SessionId -replace '[^a-zA-Z0-9-]', '-'))
        if (-not (Test-Path -LiteralPath $stamp -PathType Leaf)) { return }
        if ((Get-Item -LiteralPath $stamp).LastWriteTimeUtc -ge $script:DispatcherStartedUtc.UtcDateTime) {
            Remove-Item -LiteralPath $stamp -Force
            Write-DispatcherWarn -Code 'ORIENTATION_UNDELIVERED' -Message 'this prompt''s output was withheld, so the orientation stamped during it is cleared and the next prompt supplies it again'
        }
    }
    catch { Write-DispatcherWarn -Code 'ORIENTATION_UNDELIVERED' -Message ("could not clear the undelivered orientation stamp: {0}" -f $_.Exception.Message) }
}

function Clear-DispatcherUndeliveredRecoveryRequest {
    # Co-review round 5 (202, FR-009): the store records the reply-recording recovery question as open for this session
    # BEFORE the payload that asks it. When this fire withheld its output, the human never saw the question, and a later
    # "yes" from them must not answer it. Only a question recorded DURING this fire, for this session and not yet
    # answered, is taken back; the next prompt asks it again. An earlier, delivered question stays open.
    param([AllowNull()][string]$ProjectRoot, [AllowNull()][string]$SessionId)
    if (-not $script:DispatcherOutputWithheldThisFire) { return }
    if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or [string]::IsNullOrWhiteSpace($SessionId)) { return }
    try {
        $request = Join-Path $ProjectRoot '.specrew/runtime/reply-recording-recovery-request.json'
        if (-not (Test-Path -LiteralPath $request -PathType Leaf)) { return }
        if ((Get-Item -LiteralPath $request).LastWriteTimeUtc -lt $script:DispatcherStartedUtc.UtcDateTime) { return }
        $open = [IO.File]::ReadAllText($request, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop
        if ([string]$open.asked_session -cne $SessionId) { return }
        if ($null -ne $open.PSObject.Properties['declined_at']) { return }  # the human's answer this turn stands
        Remove-Item -LiteralPath $request -Force
        Write-DispatcherWarn -Code 'RECOVERY_QUESTION_UNDELIVERED' -Message 'this prompt''s output was withheld, so the recovery question recorded during it is withdrawn and the next prompt asks it again'
    }
    catch { Write-DispatcherWarn -Code 'RECOVERY_QUESTION_UNDELIVERED' -Message ("could not withdraw the undelivered recovery question: {0}" -f $_.Exception.Message) }
}

function Restore-DispatcherUndeliveredNotRecordedLine {
    # Co-review round 2 (202 iteration 002, FR-027): the store marks a not-recorded approval line as said when it composes
    # the payload, BEFORE this dispatcher delivers it. Each line marked said during this fire, for this session, that the
    # human did not get is put back: an `undelivered` row after it makes the store say it again at the next message.
    # Append-only, like the journal it reads.
    #
    # Co-review round 3: "did not get" is decided by WHAT WAS DELIVERED, not by one cause of loss. A withheld output, a
    # provider that timed out or failed after marking the line, and any other path that drops it all look the same here:
    # the delivered text does not carry the line. Called once per prompt, whatever happened to the providers.
    #
    # Co-review round 4: "whatever happened" includes the dispatcher itself failing after a provider marked the line
    # (a session state it cannot save, for one). Its fail-open exit calls this too, with what it had delivered by then.
    param([AllowNull()][string]$ProjectRoot, [AllowNull()][string]$SessionId, [AllowNull()][string]$DeliveredPayload)
    if ($script:DispatcherNotRecordedReconciled) { return }
    $script:DispatcherNotRecordedReconciled = $true
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { return }
    $delivered = if ($script:DispatcherOutputWithheldThisFire) { '' } else { [string]$DeliveredPayload }
    try {
        $journal = Join-Path $ProjectRoot '.specrew/runtime/authority-capture-drops.jsonl'
        if (-not (Test-Path -LiteralPath $journal -PathType Leaf)) { return }
        $restored = 0
        $retypes = @{}
        $lines = [IO.File]::ReadAllLines($journal)
        foreach ($line in $lines) {
            if ($line -notmatch '"authority-phrase-not-recorded"') { continue }
            $report = $null
            try { $report = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ($report.PSObject.Properties['retype']) { $retypes[[string]$report.entry_key] = [string]$report.retype }
        }
        foreach ($line in $lines) {
            if ($line -notmatch 'authority-phrase-not-recorded-disclosed') { continue }
            $row = $null
            try { $row = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ([string]$row.event -cne 'authority-phrase-not-recorded-disclosed') { continue }
            $rowSession = if ($row.PSObject.Properties['session_id']) { [string]$row.session_id } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($rowSession) -and $rowSession -cne [string]$SessionId) { continue }
            $at = if ($row.PSObject.Properties['recorded_at']) { ConvertTo-DispatcherInstant -Value $row.recorded_at } else { $null }
            if ($null -eq $at -or $at -lt $script:DispatcherStartedUtc) { continue }
            $retype = if ($retypes.ContainsKey([string]$row.entry_key)) { [string]$retypes[[string]$row.entry_key] } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($retype) -and $delivered.Contains(("your earlier '{0}'" -f $retype))) { continue }
            (([pscustomobject][ordered]@{ event = 'authority-phrase-not-recorded-undelivered'; entry_key = [string]$row.entry_key; host_kind = [string]$row.host_kind; session_id = $rowSession; recorded_at = [DateTimeOffset]::UtcNow.ToString('o') }) | ConvertTo-Json -Compress) |
                Add-Content -LiteralPath $journal -Encoding UTF8 -ErrorAction Stop
            $restored++
        }
        if ($restored -gt 0) { Write-DispatcherWarn -Code 'NOT_RECORDED_LINE_UNDELIVERED' -Message 'the not-recorded approval line marked during this prompt did not reach the human, so it is said again at the next prompt' }
    }
    catch { Write-DispatcherWarn -Code 'NOT_RECORDED_LINE_UNDELIVERED' -Message ("could not restore the undelivered not-recorded line: {0}" -f $_.Exception.Message) }
}

function ConvertTo-DispatcherStopBlockOutput {
    param([string]$Shape, [string]$Reason)
    switch ($Shape) {
        # claude / codex / copilot: a hard deny that prevents turn-end and force-continues using reason.
        'decision-block' { return (@{ decision = 'block'; reason = $Reason } | ConvertTo-Json -Depth 4 -Compress) }
        # antigravity: decision=continue re-enters the loop; any other value allows the stop (soft block).
        'decision-continue' { return (@{ decision = 'continue'; reason = $Reason } | ConvertTo-Json -Depth 4 -Compress) }
        # cursor: no same-turn hard block; followup_message auto-submits a NEW user turn (best-effort degrade).
        'followup-message' { return (@{ followup_message = $Reason } | ConvertTo-Json -Depth 4 -Compress) }
    }
}

# ---------------------------------------------------------------------------
# Hook-health receipt (FR-053): durable PROOF-OF-FIRE. A deployed hook config is
# NOT proof the host loaded and fired it; only a receipt written from a GENUINE
# host-triggered SessionStart/Stop fire is. This records that receipt best-effort.
# STRICTLY fail-open: a module-absent / resolve / dot-source / write failure must
# NEVER block or alter the hook's normal dispatch (every path swallows and returns).
# ---------------------------------------------------------------------------
function Resolve-DispatcherHookHealthModulePath {
    # Locate the shipped hook-health-receipt helper (it lives in the Specrew MODULE tree,
    # not the extension tree), the same fail-open way Find-DispatcherHostManifestPath resolves
    # a host manifest: walk SPECREW_MODULE_PATH / PSScriptRoot / ProjectRoot up to a dir that
    # holds it, then fall back to the installed module base. Returns $null if it is not found.
    param([AllowNull()][string]$ProjectRoot)
    $rel = 'scripts/internal/continuous-co-review/hook-health-receipt.ps1'
    foreach ($start in @($env:SPECREW_MODULE_PATH, $PSScriptRoot, $ProjectRoot)) {
        if ([string]::IsNullOrWhiteSpace($start) -or -not (Test-Path -LiteralPath $start -PathType Container)) { continue }
        $candidate = (Resolve-Path -LiteralPath $start).Path
        while (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $probe = Join-Path $candidate $rel
            if (Test-Path -LiteralPath $probe -PathType Leaf) { return $probe }
            $parent = Split-Path -Parent $candidate
            if ($parent -eq $candidate) { break }
            $candidate = $parent
        }
    }
    try {
        $module = Get-Module -ListAvailable Specrew | Sort-Object Version -Descending |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.ModuleBase $rel) -PathType Leaf } |
            Select-Object -First 1
        if ($module) { return (Join-Path $module.ModuleBase $rel) }
    }
    catch { $null = $_ }
    return $null
}

function Test-DispatcherIsLifecycleReceiptEvent {
    # The lifecycle proof points FR-053 records: SessionStart and any Stop-class event (the
    # neutral DispatcherEvent is 'Stop'/'stop' for most hosts, 'agentStop' for copilot). Every
    # other event (PostToolUse / UserPromptSubmit / PreToolUse / PreInvocation) is skipped.
    param([AllowNull()][string]$EventName)
    if ([string]::IsNullOrWhiteSpace($EventName)) { return $false }
    $n = $EventName.Trim().ToLowerInvariant()
    return ($n -eq 'sessionstart' -or $n -eq 'stop' -or $n -eq 'agentstop')
}

function Test-DispatcherIsSessionStartEvent {
    # The ONE lifecycle event at which the host-version probe runs. Stop/agentStop must NEVER probe (a per-Stop
    # `--version` subprocess would tax the tight Stop budget, and only SessionStart is the trusted version fact) -
    # they record proof-of-fire with an 'unknown' version and never overwrite/promote the SessionStart version.
    param([AllowNull()][string]$EventName)
    if ([string]::IsNullOrWhiteSpace($EventName)) { return $false }
    return ($EventName.Trim().ToLowerInvariant() -eq 'sessionstart')
}

function Get-DispatcherSessionStartHostVersion {
    # The observed host version for a SessionStart receipt: a BOUNDED, shell-free probe of the resolved host CLI's
    # own `--version` (Get-SpecrewHostVersionProbe, provided by the hook-health module the caller already loaded).
    # NEVER reads an ambient env value - SPECREW_OBSERVED_HOST_VERSION is GONE as a version source (co-review
    # finding 3): no ambient/secret value can be persisted, because the version can ONLY come from running the
    # resolved executable. Any probe failure (unresolved / timeout / malformed / ambiguous) -> the honest 'unknown'.
    param([string]$HostKind)
    try {
        if (-not (Get-Command -Name 'Get-SpecrewHostVersionProbe' -ErrorAction SilentlyContinue)) { return 'unknown' }
        $probe = Get-SpecrewHostVersionProbe -HostName $HostKind
        if ($null -ne $probe -and $probe.ok -and -not [string]::IsNullOrWhiteSpace([string]$probe.version)) { return [string]$probe.version }
    }
    catch { $null = $_ }
    return 'unknown'
}

function Write-DispatcherHookHealthReceipt {
    # Record a sanitized hook-health receipt for a genuine host fire (best-effort). Returns nothing and swallows
    # EVERY failure so the hook's dispatch is never affected (fail-open). The observed host version is a BOUNDED
    # SessionStart PROBE (Stop/agentStop record 'unknown', NEVER launch a probe, and NEVER overwrite/promote the
    # SessionStart version fact - which lives in the separate SessionStart receipt file).
    param([string]$HostKind, [string]$EventName, [AllowNull()][string]$ProjectRoot)
    try {
        if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { return }
        if (-not (Test-DispatcherIsLifecycleReceiptEvent -EventName $EventName)) { return }
        if (-not (Get-Command -Name 'Write-SpecrewHookHealthReceipt' -ErrorAction SilentlyContinue)) {
            $modulePath = Resolve-DispatcherHookHealthModulePath -ProjectRoot $ProjectRoot
            if ([string]::IsNullOrWhiteSpace($modulePath)) { return }
            . $modulePath
        }
        if (-not (Get-Command -Name 'Write-SpecrewHookHealthReceipt' -ErrorAction SilentlyContinue)) { return }
        # SessionStart -> a bounded ambient version DIAGNOSTIC (non-authoritative, non-promoting); Stop/agentStop ->
        # no probe. version_source is 'ambient-path-binding' when a reading was captured, else 'unavailable'.
        $observed = if (Test-DispatcherIsSessionStartEvent -EventName $EventName) { Get-DispatcherSessionStartHostVersion -HostKind $HostKind } else { 'unknown' }
        $vsource = if (-not [string]::IsNullOrWhiteSpace($observed) -and $observed -ne 'unknown') { 'ambient-path-binding' } else { 'unavailable' }
        $null = Write-SpecrewHookHealthReceipt -ProjectRoot $ProjectRoot -HostName $HostKind -Surface 'cli' -Event $EventName -ObservedHostVersion $observed -ObservedVersionSource $vsource
    }
    catch { $null = $_ }
}

# ---------------------------------------------------------------------------
# Main — every failure path inside this try lands on exit 0 (P1).
# ---------------------------------------------------------------------------
try {
    $earlyHostRuntimeBinding = Resolve-DispatcherHostRuntimeBinding -Kind $HostKind -ProjectRoot $null -EncodedBinding $HostBinding

    # Self-gate: a stray hook firing outside a Specrew project is a silent no-op.
    $projectRoot = Get-DispatcherProjectRoot
    if ($null -eq $projectRoot) {
        Write-DecisionOnlyNoopIfNeeded -EventName $Event -Binding $earlyHostRuntimeBinding
        exit 0
    }

    # Host event JSON: -EventJson (tests/bindings) or stdin (Claude hooks).
    $rawEvent = $EventJson
    if ([string]::IsNullOrWhiteSpace($rawEvent) -and -not [Console]::IsInputRedirected) { $rawEvent = '' }
    elseif ([string]::IsNullOrWhiteSpace($rawEvent)) { $rawEvent = Read-DispatcherStdinText }

    $hostEvent = $null
    if (-not [string]::IsNullOrWhiteSpace($rawEvent)) {
        try { $hostEvent = $rawEvent | ConvertFrom-Json }
        catch {
            Write-DispatcherWarn -Code 'EVENT_PARSE' -Message ("host event JSON unreadable for {0}; automation quiet this event (host surface changed? see the research matrix)" -f $Event)
            Write-DecisionOnlyNoopIfNeeded -EventName $Event -Binding $earlyHostRuntimeBinding
            exit 0
        }
    }

    # Feature 202 T002: the host's declared binding (baked into the deployed hook, else its manifest) drives the
    # single normalizer; every field below comes from the standard turn record, never from the raw payload.
    $hostRuntimeBinding = Resolve-DispatcherHostRuntimeBinding -Kind $HostKind -ProjectRoot $projectRoot -EncodedBinding $HostBinding
    # Feature 202 iteration 002, T016 (FR-028, DA-1; B4F-129): a hook acts only for its own host. Copilot also runs
    # the hooks in Claude's settings, so the same event arrives here twice. Stand down - nothing written, not even a
    # health receipt - only when the payload positively belongs to another known host.
    $payloadMatch = Get-DispatcherPayloadHostMatch -Payload $hostEvent -Binding $hostRuntimeBinding -EventName $Event
    if ($payloadMatch.Kind -eq 'foreign') {
        Write-DecisionOnlyNoopIfNeeded -EventName $Event -Binding $hostRuntimeBinding
        exit 0
    }
    if ($payloadMatch.Kind -eq 'unknown') {
        Write-DispatcherUnrecognizedPayloadLog -ProjectRoot $projectRoot -HostKind $HostKind -EventName $Event -Keys @($payloadMatch.Keys)
    }
    $turnRecord = ConvertTo-SpecrewTurnRecord -EventName $Event -HostName $HostKind -Payload $hostEvent -Binding $hostRuntimeBinding -ProjectRoot $projectRoot
    $rawSessionId = $turnRecord.session_id
    $sessionId = $turnRecord.safe_session_id
    $source = $turnRecord.source
    $script:DispatcherTurnSessionId = [string]$sessionId
    $script:DispatcherTurnTypedText = [string]$turnRecord.typed_text

    # FR-053 (co-review finding 2): record the sanitized lifecycle receipt as durable proof-of-fire ONLY
    # AFTER the host envelope validated as a GENUINE, well-formed lifecycle fire - a non-null host-shaped JSON
    # object carrying a recognized host session id ($rawSessionId is populated ONLY from that host-shaped
    # payload). A MALFORMED event already exited above via EVENT_PARSE; an EMPTY ($hostEvent = $null) or a
    # NON-HOST-SHAPED payload (a JSON array/scalar, an empty object, or an object with no host session id) leaves
    # $rawSessionId blank and therefore records NO receipt - so Resolve-SpecrewHookHealth can never read a
    # false-green from a broken/incompatible hook payload (the finding-2 defect). Still placed EARLY (before
    # catalog/state parsing) so a real fire is captured even if later parsing degrades, and STILL strictly
    # fail-open: Write-DispatcherHookHealthReceipt swallows every failure and never blocks or alters dispatch (a
    # malformed/empty event still dispatches/quiets exactly as before - it just records no receipt).
    if (($null -ne $hostEvent) -and ($hostEvent -is [psobject]) -and (-not [string]::IsNullOrWhiteSpace($rawSessionId))) {
        Write-DispatcherHookHealthReceipt -HostKind $HostKind -EventName $Event -ProjectRoot $projectRoot
    }

    $catalog = Get-DispatcherCatalog -ProjectRoot $projectRoot
    if ($null -eq $catalog -or -not $catalog.PSObject.Properties['providers']) {
        Write-DecisionOnlyNoopIfNeeded -EventName $Event -Binding $hostRuntimeBinding
        exit 0
    }

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
    $eventTrigger = if (Test-IsB3DeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) { 'b3' } elseif ($source -eq 'compact') { 'b1' } else { 'b2' }

    # Providers for THIS event, deterministic order (the host runs parallel hooks
    # unordered; Specrew owns ordering internally — the lens-2 dispatcher decision).
    $providers = @($catalog.providers | Where-Object { @($_.events) -contains $Event } | Sort-Object { [int]$_.order })
    # The host owns the outer hook timeout. Provider timeouts must therefore be a
    # shared dispatcher budget, not a per-provider multiplier; otherwise two slow
    # Stop providers can exceed Codex's 30s ceiling before we can fail open.
    $providerBudget = [System.Diagnostics.Stopwatch]::StartNew()
    $providerBudgetMs = [Math]::Max(1000, ($ProviderTimeoutSeconds * 1000))

    $fragments = New-Object System.Collections.Generic.List[object]
    $failedSessionStartProviders = New-Object System.Collections.Generic.List[string]
    # FR-004/FR-015: stop-block reasons requested by Stop-class consumers (the packet-at-stop force-continue).
    # specrew-self-ok: provenance comment citing the self-host feature that shaped this behavior
    # F-197 (maintainer-authorized 2026-06-24): ACCUMULATE across ALL providers in one Stop run rather than
    # last-writer-wins. The navigator (order 50) runs after conformance (order 40); if both emit a stop-block in
    # the same run, a single $stopBlockReason variable let the navigator's reason OVERWRITE conformance's,
    # dropping one directive. Collect distinct reasons here and MERGE them below so BOTH survive. A single
    # blocking provider collapses to a 1-element list = identical output to the old single-reason path.
    $stopBlockReasons = New-Object System.Collections.Generic.List[string]
    foreach ($provider in $providers) {
        $kind = if ($provider.PSObject.Properties['kind']) { [string]$provider.kind } else { 'inject' }
        $providerId = [string]$provider.id
        $providerOrder = if ($provider.PSObject.Properties['order']) { [int]$provider.order } else { 1000 }

        $commandPath = Resolve-ProviderCommandPath -ProjectRoot $projectRoot -Command ([string]$provider.command)
        if ($null -eq $commandPath) {
            Write-DispatcherWarn -Code 'SOURCE_CONFINED' -Message ("provider '{0}' command does not resolve under the deployed tree; skipped" -f $providerId)
            if ((Test-IsBootstrapDeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) -and $providerId -in @('bootstrap', 'refocus')) {
                $failedSessionStartProviders.Add($providerId) | Out-Null
            }
            continue
        }

        if ($kind -eq 'gate') {
            # DORMANT F-165 seat (FR-008 forward-compat): gate providers run on
            # PreToolUse, receive tool_input, return allow/deny permissionDecision.
            # No gate provider ships in F-171; this path is fixture-tested only.
            if ($Event -ne 'PreToolUse') { continue }
            $remainingMs = $providerBudgetMs - [int]$providerBudget.ElapsedMilliseconds
            if ($remainingMs -le 0) {
                Write-DispatcherWarn -Code 'PROVIDER_BUDGET' -Message ("provider budget exhausted before '{0}'; skipped" -f $providerId)
                @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; permissionDecisionReason = "specrew gate provider '$providerId' skipped after dispatcher budget exhausted" } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
                continue
            }
            $providerTimeoutForCall = [Math]::Max(1, [int][Math]::Ceiling($remainingMs / 1000.0))
            $providerTimeoutForCall = [Math]::Min($ProviderTimeoutSeconds, $providerTimeoutForCall)
            $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs @('--gate') -WorkingDirectory $projectRoot -TimeoutSeconds $providerTimeoutForCall
            if ($result.TimedOut -or $result.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($result.StdOut)) {
                # Gates fail OPEN to allow — a broken gate never blocks a session.
                Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("gate provider '{0}' failed; failing OPEN to allow" -f $providerId)
                @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; permissionDecisionReason = "specrew gate provider '$providerId' failed open" } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
                continue
            }
            Write-Output $result.StdOut.Trim()
            continue
        }

        # Feature 202 T008: the bootstrap provider runs on a prompt only to supply the session's finished orientation,
        # once. After that its stamp (named by session, like the render claims) exists, and launching it again would
        # cost every later prompt a process start to learn that (measured ~0.5 s against a ~0.2 s bare pwsh start).
        if ($providerId -eq 'bootstrap' -and $Event -eq 'UserPromptSubmit' -and -not [string]::IsNullOrWhiteSpace($sessionId) -and
            (Test-Path -LiteralPath (Join-Path $projectRoot ('.specrew/runtime/hook-bootstrap-orientation-{0}.json' -f ($sessionId -replace '[^a-zA-Z0-9-]', '-'))) -PathType Leaf)) {
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
            if (Test-IsB3DeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) {
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
            $commandArgs = Get-RefocusProviderArgs -EventName $Event -Source $source -Binding $hostRuntimeBinding
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
            # specrew-self-ok: provenance comment citing the self-host feature that shaped this behavior
            # F-197 (maintainer-authorized 2026-06-24): co-review-navigator joins the clean-args allow-list. It
            # binds Stop-class AND SessionStart, and on Codex Stop the same 10s-of-KB last_assistant_message in
            # --event-json blew the Windows command-line limit, so the navigator silently never launched. It
            # reads ONLY --source-event (and accepts-but-ignores --host-kind/--transcript-path) on EVERY event
            # incl. SessionStart - it works off git state + the registry, never the event payload/session_id -
            # so the provider-keyed strip is safe on SessionStart too (no session_id dependence to break).
            $commandArgs = if ($providerId -in @('handover', 'conformance', 'co-review-navigator')) {
                # All read ONLY the clean args (+ --transcript-path appended below) - never the full
                # --event-json blob (Codex Stop carries a 10s-of-KB last_assistant_message that blows the
                # Windows command-line limit and makes ProcessStartInfo refuse to launch). FR-011 C3.
                @('--host-kind', $HostKind, '--source-event', $Event)
            }
            else {
                @('--event-json', ($rawEvent ?? ''), '--host-kind', $HostKind, '--source-event', $Event)
            }
            if (-not [string]::IsNullOrWhiteSpace($HostBinding)) {
                $commandArgs += @('--host-binding', $HostBinding)
            }
            # T069: bind provider-local material state to the genuine host session. Only host-supplied identities
            # are forwarded; the dispatcher's per-launch fallback is not stable enough to claim session ownership.
            if (-not [string]::IsNullOrWhiteSpace($rawSessionId)) {
                $commandArgs += @('--session-id', $sessionId)
            }
            # Feature 202 T002: every remaining field comes from the standard turn record - the transcript path
            # (F-174 iter-10: a clean arg, so a spaced path survives via ProcessStartInfo.ArgumentList), the
            # prompt text and its origin (FR-006), and the ask_user tool detail - never from re-parsing the payload.
            if (-not [string]::IsNullOrWhiteSpace([string]$turnRecord.transcript_path)) { $commandArgs += @('--transcript-path', [string]$turnRecord.transcript_path) }
            if ($Event -in @('UserPromptSubmit', 'PreInvocation')) {
                if (-not [string]::IsNullOrWhiteSpace([string]$turnRecord.typed_text)) { $commandArgs += @('--last-user-message', [string]$turnRecord.typed_text) }
                $commandArgs += @('--turn-origin', [string]$turnRecord.origin)
            }
            # Feature 202 iteration 002, T017 (FR-027): the handover provider keys a typed approval by the host's
            # message ID on the prompt event, and learns on every event whether the binding declares one at all.
            if ($providerId -eq 'handover') {
                if ($Event -in @('UserPromptSubmit', 'PreInvocation') -and -not [string]::IsNullOrWhiteSpace([string]$turnRecord.message_id)) {
                    $commandArgs += @('--message-id', [string]$turnRecord.message_id)
                }
                $commandArgs += @('--message-identity', [string]$turnRecord.message_identity)
            }
            # Feature 202 T006: which SessionStart this is (startup, resume, clear, compact). Every one is a context
            # gap for the presented-crossing memory; the kind is recorded beside it for diagnosis.
            if ($providerId -eq 'conformance' -and $Event -eq 'SessionStart' -and -not [string]::IsNullOrWhiteSpace([string]$source)) {
                $commandArgs += @('--session-start-source', [string]$source)
            }
            if ($providerId -notin @('handover', 'conformance', 'co-review-navigator')) {
                $commandArgs += @('--turn-record', (ConvertTo-DispatcherTurnRecordArgument -TurnRecord $turnRecord))
            }
            if ($providerId -eq 'conformance' -and $Event -eq 'PostToolUse' -and $null -ne $turnRecord.tool -and [string]$turnRecord.tool.name -ieq 'ask_user') {
                $commandArgs += @('--structured-question-tool', 'ask_user', '--structured-question-outcome', [string]$turnRecord.tool.outcome)
                $question = [string]$turnRecord.tool.question
                if (-not [string]::IsNullOrWhiteSpace($question)) {
                    $boundedQuestion = if ($question.Length -gt 1000) { $question.Substring(0, 1000) } else { $question }
                    $commandArgs += @('--structured-question-text', $boundedQuestion)
                }
            }
        }
        if ($null -eq $commandArgs) { continue }

        $remainingMs = $providerBudgetMs - [int]$providerBudget.ElapsedMilliseconds
        if ($remainingMs -le 0) {
            Write-DispatcherWarn -Code 'PROVIDER_BUDGET' -Message ("provider budget exhausted before '{0}'; skipped" -f $providerId)
            continue
        }
        $providerTimeoutForCall = [Math]::Max(1, [int][Math]::Ceiling($remainingMs / 1000.0))
        $providerTimeoutForCall = [Math]::Min($ProviderTimeoutSeconds, $providerTimeoutForCall)
        $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs $commandArgs -WorkingDirectory $projectRoot -TimeoutSeconds $providerTimeoutForCall
        if ($result.TimedOut -or $result.ExitCode -ne 0) {
            $why = if ($result.TimedOut) { 'timed out' }
            elseif ($result.LaunchFailed) { "failed to launch: $($result.StdErr)" }
            else { "exited $($result.ExitCode)" }
            Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("provider '{0}' {1}; skipped" -f $providerId, $why)
            if ((Test-IsBootstrapDeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) -and $providerId -in @('bootstrap', 'refocus')) {
                $failedSessionStartProviders.Add($providerId) | Out-Null
            }
            if ($providerId -eq 'refocus' -and $null -ne $sessionState -and -not $stateCorrupt) {
                $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope 'unknown' -Channel 'hook' -Tokens 0 -Outcome 'failed'
                $stateDirty = $true
            }
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdOut)) {
            $stdoutTrim = $result.StdOut.Trim()
            if ($stdoutTrim.StartsWith('<<<SPECREW-STOP-BLOCK>>>')) {
                # FR-004/FR-015: a Stop-class consumer (conformance, navigator) requests a force-continue so the
                # re-entry packet renders AT the stop. Accumulate the reason (do NOT add it as a normal injection
                # specrew-self-ok: provenance comment citing the self-host feature that shaped this behavior
                # fragment); F-197 merges all providers' reasons below so a later provider can't clobber an
                # earlier one. Skip blanks and exact duplicates so the merge stays clean.
                $thisReason = $stdoutTrim.Substring('<<<SPECREW-STOP-BLOCK>>>'.Length).Trim()
                if ((-not [string]::IsNullOrWhiteSpace($thisReason)) -and (-not $stopBlockReasons.Contains($thisReason))) {
                    $stopBlockReasons.Add($thisReason) | Out-Null
                }
            }
            else {
                $fragments.Add((New-DispatcherFragment -ProviderId $providerId -Text $stdoutTrim -Order $providerOrder)) | Out-Null
                if ($providerId -eq 'refocus' -and $null -ne $sessionState -and -not $stateCorrupt) {
                    $facts = Get-BannerFacts -Payload $result.StdOut
                    $outcome = if ($result.StdErr -match 'WARN BUDGET_EXCEEDED') { 'budget-clipped' } else { 'injected' }
                    $sessionState = Add-JournalEntry -State $sessionState -Trigger $eventTrigger -Scope $facts.Scope -Channel 'hook' -Tokens $facts.Tokens -Outcome $outcome
                    $stateDirty = $true
                }
            }
        }
        if ((Test-IsBootstrapDeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) -and $providerId -in @('bootstrap', 'refocus') -and $result.StdErr -match '\bPROVIDER_FAILED\b') {
            $failedSessionStartProviders.Add($providerId) | Out-Null
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdErr)) {
            # Provider WARNs pass through once (visible, attributable).
            [Console]::Error.Write($result.StdErr)
        }
    }

    if ($null -ne $sessionState -and -not $stateCorrupt -and $stateDirty) {
        Save-SessionState -Path $sessionStatePath -State $sessionState
    }

    if ((Test-IsBootstrapDeliveryEvent -EventName $Event -Binding $hostRuntimeBinding) -and $failedSessionStartProviders.Count -gt 0) {
        $hasBootstrap = @($fragments | Where-Object { [string]$_.ProviderId -eq 'bootstrap' }).Count -gt 0
        if (-not $hasBootstrap) {
            $fragments.Add((New-DispatcherFragment -ProviderId 'fallback' -Text (New-GovernedProviderFailureFallback -HostKind $HostKind -FailedProviders $failedSessionStartProviders.ToArray()) -Order 0)) | Out-Null
        }
    }

    # STOP-BLOCK short-circuit (FR-004/FR-005/FR-015): a Stop-class consumer asked to force-continue the turn so
    # the 6-section re-entry packet renders AT the stop (not as a too-late next-turn nudge). Honor it via the
    # host's declared StopBlockShape - UNLESS the host is already continuing from a prior stop-block
    # (stop_hook_active true on claude/codex) -> then ALLOW, to respect the host's loop cap and never hang. Fully
    # fail-open: an unknown/none shape or any miss falls through to the normal (allow/inject) path. The provider
    # supplies its OWN consecutive-block cap for hosts lacking stop_hook_active (copilot/antigravity).
    if ($stopBlockReasons.Count -gt 0) {
        # specrew-self-ok: provenance comment citing the self-host feature that shaped this behavior
        # F-197: MERGE every blocking provider's reason this run so a co-occurring conformance + navigator
        # stop-block surfaces BOTH directives (the navigator at order 50 used to overwrite conformance at
        # order 40). One blocking provider = a 1-element join = byte-identical to the prior single-reason path.
        # The separator is a clear, parseable divider so the agent sees each directive distinctly.
        $mergedStopBlockReason = if ($stopBlockReasons.Count -eq 1) {
            $stopBlockReasons[0]
        }
        else {
            ($stopBlockReasons -join "`n`n----- AND ALSO -----`n`n")
        }
        $alreadyContinuing = [bool]$turnRecord.stop_hook_active
        $blockShape = [string](Get-DispatcherMapValue -Map $hostRuntimeBinding -Key 'StopBlockShape' -Default 'none')
        if ((-not $alreadyContinuing) -and ($blockShape -in $script:SpecrewStopBlockShapes)) {
            Write-StopBlockOutput -Shape $blockShape -Reason $mergedStopBlockReason -ProjectRoot $projectRoot -EventName $Event
            if ($Event -eq 'UserPromptSubmit') {
                Restore-DispatcherUndeliveredNotRecordedLine -ProjectRoot $projectRoot -SessionId $sessionId -DeliveredPayload $mergedStopBlockReason
            }
            exit 0
        }
        # else: host already continuing OR cannot block -> fall through to the normal path (cooperative degrade).
    }

    $deliveredPayload = ''
    if ($fragments.Count -gt 0) {
        $deliveredPayload = Join-DispatcherFragments -Fragments $fragments.ToArray() -EventName $Event
        Write-InjectionOutput -EventName $Event -Payload $deliveredPayload -Binding $hostRuntimeBinding -ProjectRoot $projectRoot
        $script:DispatcherDeliveredPayload = $deliveredPayload
        if ($Event -eq 'UserPromptSubmit') {
            Clear-DispatcherUndeliveredOrientationStamp -ProjectRoot $projectRoot -SessionId $sessionId
            Clear-DispatcherUndeliveredRecoveryRequest -ProjectRoot $projectRoot -SessionId $sessionId
        }
    }
    elseif (Test-DispatcherEventInList -EventName $Event -Events @(Get-DispatcherMapValue -Map $hostRuntimeBinding -Key 'DecisionOnlyEvents' -Default @())) {
        Write-InjectionOutput -EventName $Event -Payload '' -Binding $hostRuntimeBinding -ProjectRoot $projectRoot
    }
    if ($Event -eq 'UserPromptSubmit') {
        Restore-DispatcherUndeliveredNotRecordedLine -ProjectRoot $projectRoot -SessionId $sessionId -DeliveredPayload $deliveredPayload
    }
    exit 0
}
catch {
    Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("dispatcher fail-open: {0}" -f $_.Exception.Message)
    $catchRuntimeBinding = Resolve-DispatcherHostRuntimeBinding -Kind $HostKind -ProjectRoot $null -EncodedBinding $HostBinding
    if (Test-IsBootstrapDeliveryEvent -EventName $Event -Binding $catchRuntimeBinding) {
        Write-InjectionOutput -EventName $Event -Payload (New-GovernedProviderFailureFallback -HostKind $HostKind -FailedProviders @('dispatcher')) -Binding $catchRuntimeBinding
    }
    elseif (Test-DispatcherEventInList -EventName $Event -Events @(Get-DispatcherMapValue -Map $catchRuntimeBinding -Key 'DecisionOnlyEvents' -Default @())) {
        Write-InjectionOutput -EventName $Event -Payload '' -Binding $catchRuntimeBinding
    }
    if ($Event -eq 'UserPromptSubmit') {
        # Co-review round 4 (202 iteration 002, FR-027): a provider may have marked the not-recorded line said before
        # this failure. Reconciled against what was delivered before the failure (usually nothing).
        Restore-DispatcherUndeliveredNotRecordedLine -ProjectRoot ([string](Get-Variable -Name projectRoot -ValueOnly -ErrorAction SilentlyContinue)) `
            -SessionId ([string](Get-Variable -Name sessionId -ValueOnly -ErrorAction SilentlyContinue)) -DeliveredPayload $script:DispatcherDeliveredPayload
    }
    exit 0
}
# specrew-self-provenance-ok: F-165,F-171,F-174,F-197; implementation history is recorded for maintainers and is never emitted as consumer instruction
