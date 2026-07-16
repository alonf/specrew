<#
.SYNOPSIS
  F-174 iteration 010 (T002): best-effort conversation capture for the rolling handover (FR-022).
.DESCRIPTION
  Resource accessor (IDesign). Reads a host session transcript - the path the Stop-hook payload hands us
  (Claude/Codex/Cursor `transcript_path`, Copilot `transcriptPath`, Cursor `CURSOR_TRANSCRIPT_PATH` env) -
  and renders a BOUNDED "Recent conversation" tail so a resuming agent on ANY hook-capable host sees recent
  dialogue, not just the git delta. The hook is otherwise transcript-blind by design; this is the additive,
  best-effort enrichment.

  FORMAT-RESILIENT 4-tier ladder (the providers explicitly warn their transcript format "is not a stable
  interface"; a schema change must DEGRADE gracefully, never break):
    Tier 1  structured per-host parse of the transcript tail (claude/codex/copilot/cursor schemas).
    Tier 2  raw bounded tail when the file is present but its schema is unrecognized (drift) - with a
            VISIBLE note so degradation is detectable, not silent.
    Tier 3  the event payload's last_assistant_message (a documented Codex payload field, immune to
            file-format drift) when the file itself is unreadable.
    Floor   an honest placeholder naming the host (no transcript exposed / antigravity has no hooks).

  Bounded by turn-count AND a HARD char cap, INDEPENDENT of session length (the handover is one file
  overwritten in place, so this never grows with the session - the cap is per-snapshot). The captured text
  is RAW dialogue for an LLM consumer, not parsed into a durable schema, so it survives format drift.

  Pure I/O + string building. StrictMode-safe property access throughout; fail-open (never throws).
#>

Set-StrictMode -Version Latest

function Get-SpecrewConversationProp {
    # StrictMode-safe property read: the value if present on the object, else $null.
    param([AllowNull()]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    $m = $Object.PSObject.Properties.Match($Name)
    if ($m.Count -gt 0) { return $m[0].Value }
    return $null
}

function Get-SpecrewConversationContentText {
    # Pull text from a content value that is EITHER a plain string (copilot data.content) OR an array of
    # {type,text} parts (claude/cursor/codex content[]). Parts without a `text` field (tool_use/tool_result)
    # are skipped, so tool noise never lands in the tail.
    param([AllowNull()]$Content)
    $parts = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Content) { return , $parts.ToArray() }
    if ($Content -is [string]) {
        if (-not [string]::IsNullOrWhiteSpace($Content)) { $parts.Add([string]$Content) | Out-Null }
        return , $parts.ToArray()
    }
    foreach ($c in @($Content)) {
        if ($null -eq $c) { continue }
        if ($c -is [string]) { if (-not [string]::IsNullOrWhiteSpace($c)) { $parts.Add([string]$c) | Out-Null }; continue }
        $t = Get-SpecrewConversationProp $c 'text'
        if (-not [string]::IsNullOrWhiteSpace([string]$t)) { $parts.Add([string]$t) | Out-Null }
    }
    return , $parts.ToArray()
}

function Test-SpecrewConversationMetaFlag {
    # Claude persists Stop-hook feedback as type=user/message.role=user with isMeta=true. Role alone is therefore
    # not evidence of human authorship. Keep this pure and tolerant of both camel/snake spellings so host schema
    # drift fails closed for the known metadata bit without teaching on the feedback's approval-shaped text.
    [OutputType([bool])]
    param([Parameter()][AllowNull()]$Object)
    if ($null -eq $Object) { return $false }
    foreach ($name in @('isMeta', 'is_meta')) {
        $value = Get-SpecrewConversationProp $Object $name
        if ($value -is [bool] -and [bool]$value) { return $true }
        if ([string]$value -match '(?i)^\s*(?:true|1)\s*$') { return $true }
    }
    return $false
}

function Test-SpecrewConversationMachineryEnvelope {
    # Envelope-only fallback for hosts such as Codex whose hook output may be surfaced as a user-shaped text item.
    # Match the complete injected wrapper, never its inner wording: the identical inner text remains valid when a
    # human actually types it. Other system-only wrappers are excluded for the same provenance reason.
    [OutputType([bool])]
    param([Parameter()][AllowNull()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    return [bool]($Text -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b)[\s\S]*</(?:hook_prompt|task-notification|turn_aborted|system-reminder)>\s*$')
}

function Test-SpecrewTurnIsHumanVerdictEvidence {
    # Verdict readers call this instead of trusting role=user. Parsed turns carry an explicit provenance label;
    # legacy/ad-hoc turns without the label remain compatible only when they are not a known machinery envelope.
    [OutputType([bool])]
    param([Parameter()][AllowNull()]$Turn)
    if ($null -eq $Turn -or [string](Get-SpecrewConversationProp $Turn 'role') -ne 'user') { return $false }
    $evidence = [string](Get-SpecrewConversationProp $Turn 'verdict_evidence')
    if (-not [string]::IsNullOrWhiteSpace($evidence)) { return $evidence -eq 'human' }
    return -not (Test-SpecrewConversationMachineryEnvelope -Text ([string](Get-SpecrewConversationProp $Turn 'text')))
}

function Get-SpecrewTranscriptTailLines {
    # Fast bounded tail reader for hook hot paths. Get-Content -Tail is seconds-scale on large Codex JSONL
    # transcripts on Windows; Stop hooks call this several times, so use a backward byte window and drop the
    # partial leading line when the window starts mid-file. Fail-open to the old reader if anything unexpected
    # happens.
    [OutputType([string[]])]
    param(
        [Parameter()][AllowNull()][string]$Path,
        [int]$MaxLines = 500,
        [int]$MaxBytes = 2097152
    )
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
        try {
            $length = $fs.Length
            if ($length -le 0) { return @() }
            $bytesToRead = [int64][Math]::Min($length, [int64][Math]::Max(4096, $MaxBytes))
            [void]$fs.Seek(-$bytesToRead, [System.IO.SeekOrigin]::End)
            $bytes = New-Object byte[] ([int]$bytesToRead)
            $offset = 0
            while ($offset -lt $bytesToRead) {
                $read = $fs.Read($bytes, $offset, ([int]$bytesToRead - $offset))
                if ($read -le 0) { break }
                $offset += $read
            }
            $text = [System.Text.Encoding]::UTF8.GetString($bytes, 0, $offset)
            $parts = @($text -split "`r?`n")
            if ($bytesToRead -lt $length -and $parts.Count -gt 1) {
                $parts = @($parts | Select-Object -Skip 1)
            }
            return @($parts | Select-Object -Last $MaxLines)
        }
        finally { $fs.Dispose() }
    }
    catch {
        try { return @(Get-Content -LiteralPath $Path -Tail $MaxLines -Encoding UTF8 -ErrorAction Stop) }
        catch { return @() }
    }
}

function Test-SpecrewHumanVerdictToken {
    # F-174 iteration 011 (T004, FR-026): classify a HUMAN turn's response to a boundary VERDICT packet —
    # CONSERVATIVELY. The gate-stop packet may number its choices for readability, but a bare number is never a
    # verdict: the human must type an actual "approve [X -> Y] [with instructions]" utterance, a send-back, a
    # discuss request, or a question. SAFETY RULE (the maintainer's): only IsApproval
    # when the turn CLEARLY approves; anything negated / send-back / discuss / ambiguous / a bare question -> NOT
    # an approval, so the caller records the crossing un-authorized rather than inventing one. Pure string logic;
    # never throws.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][string]$Text)

    $r = [pscustomobject]@{ Action = 'none'; IsApproval = $false; IsSendBack = $false; IsDiscuss = $false; NamedBoundaries = @(); ApprovalOption = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $t = ($Text -replace '\s+', ' ').Trim()
    $lower = $t.ToLowerInvariant()

    # Extract any boundary the human NAMED ("X -> Y", "X → Y", "approve for <b>", "approve <b>"). Used by the
    # caller only as a cross-check AGAINST the packet marker: a named boundary that contradicts the marker makes
    # the verdict ambiguous (-> un-authorized). The marker, not this, is the primary tie.
    $named = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($lower, '\b(specify|clarify|plan|tasks|before-implement|implement|review-signoff|review|retro|iteration-closeout|iteration|closeout|feature-closeout|feature)\b')) {
        if ($named -notcontains $m.Value) { $named.Add($m.Value) | Out-Null }
    }
    $r.NamedBoundaries = $named.ToArray()

    # Send-back / reject FIRST: a turn that says "send back" (even alongside praise) is NOT an approval.
    # F-174 iter-11 (review-signoff P7-1): the "changes needed/required/requested" clause must NOT fire on a
    # NEGATED change clause - "approved, no changes needed" / "no further changes required" are APPROVALS, not
    # send-backs. The negative lookbehind (variable-length, .NET-supported) rejects the clause when a negation
    # word precedes "changes" within the same sentence; an affirmative "changes needed" still trips send-back.
    if ($lower -match '\bsend\s*back\b' -or $lower -match '\breject(ed|ing)?\b' -or $lower -match '(?<!\b(?:no|zero|without|nothing|none|not)\b[^.!?]{0,20})\bchanges?\s+(needed|required|requested)\b') {
        $r.IsSendBack = $true; $r.Action = 'send-back'; return $r
    }
    # Discuss a specific prompt — NOT an authorization (discussion is not approval).
    if ($lower -match '\bdiscuss\b' -or $lower -match '\bprompt\s*#?\d') {
        $r.IsDiscuss = $true; $r.Action = 'discuss'; return $r
    }
    # Negated / deferred approval -> NOT an approval (defends "do not approve", "not yet", "hold off ... approve").
    if ($lower -match "\b(do\s*not|don'?t|never|not\s+yet|hold\s+off|wait|stop)\b[^.!?]{0,24}\bapprov") { return $r }
    if ($lower -match "\bapprov\w*\b[^.!?]{0,16}\b(later|after|once|when|unless)\b") { return $r }
    # F-174 iter-11 (review-signoff P3-1, INTEGRITY): a verdict approval is imperative/declarative, NEVER a
    # question. An approve-bearing INTERROGATIVE ("approve?", "is this ready to approve?", "can you explain
    # before I approve?", "should I approve this or not?") is deliberation, not authorization - reject it so the
    # Stop-hook capture can NEVER fabricate an approval the human did not actually give (FR-026 / SC-013).
    if ($t.EndsWith('?')) { return $r }
    # CLEAR approval: the utterance itself STARTS with approve/approved (optionally "I/we", a confirming "yes -",
    # or a numbered LABEL followed by the explicit words). Anchoring is the mention/quote/teaching firewall:
    # "if you already approved", "reply with approved...", quoted examples, and bare numbers do not match.
    # "start"/"proceed"/"continue"/"ok"/bare "yes" remain too ambiguous and fall to pending.
    $approvalUtterance = [regex]::Match(
        $lower,
        '^\s*(?:(?:option\s*)?([12])\s*[.):\-\u2013\u2014]\s*)?(?:(?:yes|confirmed)\s*[,;:\-\u2013\u2014]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed|es)\b'
    )
    if ($approvalUtterance.Success) {
        if ($approvalUtterance.Groups[1].Success) { $r.ApprovalOption = [int]$approvalUtterance.Groups[1].Value }
        $r.IsApproval = $true; $r.Action = 'approve'; return $r
    }
    return $r
}

function Test-SpecrewBoundaryPacketLikeText {
    # Markerless fallback is allowed only when the preceding assistant turn looks like the re-entry packet the
    # human was approving. This is intentionally structural and bounded, not a full prose validator.
    [OutputType([bool])]
    param(
        [Parameter()][AllowNull()][string]$Text,
        [Parameter()][AllowNull()][string]$ApprovalPhrase
    )
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $headers = @(
        'What I Just Did',
        'Why I Stopped',
        'What Needs Your Review',
        'What Happens Next',
        'Discussion Prompts',
        'What I Need From You'
    )
    $score = 0
    foreach ($h in $headers) {
        if ($Text -match ('(?im)^\s*#{1,6}\s*' + [regex]::Escape($h) + '\b')) { $score++ }
    }
    if ($score -ge 4) { return $true }
    if (-not [string]::IsNullOrWhiteSpace($ApprovalPhrase) -and
        $Text -match '(?i)\bWhat\s+I\s+Need\s+From\s+You\b' -and
        $Text -match [regex]::Escape($ApprovalPhrase)) {
        return $true
    }
    return $false
}

function Find-SpecrewPendingVerdictFallbackCandidate {
    # Pure candidate evaluator for the currently-disabled markerless fallback. Keeping this separate lets the
    # machinery/tokenizer/order/cursor contract be proved before re-enable: the pending cursor, an earlier packet
    # that explicitly names that cursor's approval phrase, and a later genuine human verdict must all agree.
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][object[]]$Turns,
        [Parameter()][AllowNull()]$Pending
    )

    $result = [pscustomobject]@{ Found = $false; FromBoundary = $null; ToBoundary = $null; VerdictText = $null; HumanText = $null; Reason = 'no-pending-state' }
    if ($null -eq $Turns -or @($Turns).Count -eq 0) { $result.Reason = 'no-turns'; return $result }
    if ($null -eq $Pending -or -not [bool]$Pending.HasPendingVerdict) { return $result }

    $pendingFromMarker = [string]$Pending.PendingFromMarkerBoundary
    $pendingToMarker = [string]$Pending.PendingToMarkerBoundary
    $pendingFrom = [string]$Pending.PendingFromBoundary
    $pendingTo = [string]$Pending.PendingToBoundary
    if ([string]::IsNullOrWhiteSpace($pendingFromMarker) -or [string]::IsNullOrWhiteSpace($pendingToMarker) -or [string]::IsNullOrWhiteSpace($pendingTo)) {
        $result.Reason = 'pending-state-incomplete'
        return $result
    }

    $approvalPhrase = ('approved for {0}' -f $pendingToMarker)
    $pendingSet = @($pendingFromMarker, $pendingToMarker, $pendingFrom, $pendingTo) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique

    for ($i = @($Turns).Count - 1; $i -ge 0; $i--) {
        $turn = $Turns[$i]
        if (-not (Test-SpecrewTurnIsHumanVerdictEvidence -Turn $turn)) { continue }
        $humanText = [string]$turn.text
        $verdict = Test-SpecrewHumanVerdictToken -Text $humanText
        if (-not $verdict.IsApproval) {
            if ($verdict.IsSendBack) { $result.Reason = 'not-approval:send-back'; return $result }
            if ($verdict.IsDiscuss) { $result.Reason = 'not-approval:discuss'; return $result }
            continue
        }

        $named = @($verdict.NamedBoundaries)
        $approveForMatches = @([regex]::Matches($humanText.ToLowerInvariant(), '\bapprov\w*\s+for\s+(specify|clarify|plan|tasks|before-implement|implement|review-signoff|review|retro|iteration-closeout|feature-closeout)\b') | ForEach-Object {
                Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$_.Groups[1].Value)
            } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
        if ($approveForMatches.Count -gt 0 -and ($approveForMatches -notcontains $pendingToMarker)) {
            $result.Reason = 'named-boundary-contradicts-pending'
            return $result
        }
        if ($named.Count -gt 0 -and @($named | Where-Object { $pendingSet -contains $_ }).Count -eq 0) {
            $result.Reason = 'named-boundary-contradicts-pending'
            return $result
        }

        $priorAssistant = $null
        for ($j = $i - 1; $j -ge 0; $j--) {
            if ([string]$Turns[$j].role -eq 'assistant') { $priorAssistant = [string]$Turns[$j].text; break }
        }
        if ([string]::IsNullOrWhiteSpace($priorAssistant)) {
            $result.Reason = 'candidate-predates-packet'
            return $result
        }

        $packetLike = Test-SpecrewBoundaryPacketLikeText -Text $priorAssistant -ApprovalPhrase $approvalPhrase
        $packetNamesPending = $priorAssistant -match [regex]::Escape($approvalPhrase)
        if (-not $packetLike -or -not $packetNamesPending) {
            $result.Reason = 'packet-cursor-mismatch'
            return $result
        }

        $result.Found = $true
        $result.FromBoundary = $pendingFromMarker
        $result.ToBoundary = $pendingToMarker
        $result.VerdictText = $approvalPhrase
        $result.HumanText = $humanText
        $result.Reason = 'captured-pending-artifact-fallback'
        return $result
    }

    $result.Reason = 'no-clear-human-approval'
    return $result
}

function Get-SpecrewPendingVerdictFallbackCapture {
    # Preferred capture is marker-bound. This fallback covers weak hosts/models that rendered a boundary packet but
    # dropped/mis-targeted the invisible marker. It still requires a real human approval and binds only to the single
    # pending crossing computed from start-context.json; the agent never supplies the boundary being authorized.
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][object[]]$Turns,
        [Parameter()][AllowNull()][string]$ProjectRoot
    )

    $result = [pscustomobject]@{ Found = $false; FromBoundary = $null; ToBoundary = $null; VerdictText = $null; HumanText = $null; Reason = 'no-pending-state' }
    if ($null -eq $Turns -or @($Turns).Count -eq 0) { $result.Reason = 'no-turns'; return $result }
    if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or -not (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue)) { return $result }

    $pending = $null
    try { $pending = Get-SpecrewPendingVerdictState -ProjectRoot $ProjectRoot } catch { $pending = $null }
    if ($null -eq $pending -or -not [bool]$pending.HasPendingVerdict) { return $result }

    # INTERIM MITIGATION (maintainer instruction at the iteration-002 closeout verdict,
    # 2026-07-11, DEC-198-GOV-003): the pending-artifact fallback is DISABLED. It fabricated
    # two authorizations in one day - both ~37s after a packet render, during the agent's own
    # stop cycle, pairing a machinery/stale turn with the pending artifact's synthesized
    # approval phrase - while the human's actual replies were send-backs. Marker-bound capture
    # stays active: an uncaptured verdict now costs one re-confirm keystroke instead of a
    # fabricated authorization. This return sits AFTER the cheap guards so the reason taxonomy
    # stays honest: 'disabled' is reported only when a live pending crossing was actually
    # declined. Re-enable ONLY when the fallback redesign passes its acceptance criteria
    # (machinery-turn exclusion, tokenizer tightening, temporal-ordering guard, and the
    # exact-sequence regression fixtures - the iteration-003 capture-integrity tasks).
    # The pure evaluator below is exercised directly until the remaining fixture/correction-door gate is complete.
    $result.Reason = 'fallback-capture-disabled-interim'
    return $result

    return (Find-SpecrewPendingVerdictFallbackCandidate -Turns $Turns -Pending $pending)
}

function Get-SpecrewCapturedBoundaryVerdict {
    # F-174 iteration 011 (T004, FR-026): read the host transcript for the human's verdict on a rendered boundary
    # VERDICT packet. The verdict is tied to a boundary ONLY via the packet's stable machine marker
    # <!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> --> (T002 / the gate-stop skill emits it; it is an HTML
    # comment, invisible in the rendered markdown, present in the transcript). NO marker -> NO capture (the human
    # re-confirms via the pending surface). Newer marker/response pairs normally win, but a newer packet with no
    # response yet must NOT hide an earlier approved packet: the Stop hook records approvals only at end-of-turn,
    # so an agent can mistakenly render the next boundary before the previous approval is persisted. Scan backward
    # for the newest marker that has a subsequent CLEAR approval. Pure read; fail-open (never throws).
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][string]$TranscriptPath,
        [Parameter()][AllowNull()][string]$ProjectRoot,
        [Parameter()][AllowNull()][string]$LastUserMessage,
        [int]$MaxTailLines = 500
    )
    $result = [pscustomobject]@{ Found = $false; FromBoundary = $null; ToBoundary = $null; VerdictText = $null; HumanText = $null; Reason = 'no-transcript' }
    if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return $result }
    # F-197 iter-004 (T070, #2885): one shared memoized parse (path,mtime,MaxLines); finalize with -Raw here.
    # The shared extract holds only user/assistant message turns; a tail with no message turns falls through to
    # the existing $turns.Count==0 -> 'no-turns' guard below. (Diagnostic-only delta vs the pre-refactor path: a
    # ZERO-BYTE file now reports Reason='no-turns' where the old per-line path reported 'empty'; both give
    # Found=$false and 'empty' is consumed by no branch, so capture/authorization behavior is unchanged. 145 T070.)
    $shared = $null
    try { $shared = @(Get-SpecrewTranscriptParsedTurns -TranscriptPath $TranscriptPath -MaxLines $MaxTailLines) } catch { $result.Reason = 'unreadable'; return $result }

    $turns = New-Object System.Collections.Generic.List[object]
    foreach ($rp in $shared) { $tn = Format-SpecrewConversationTurnText -Turn $rp -Raw; if ($null -ne $tn) { $turns.Add($tn) | Out-Null } }
    if (-not [string]::IsNullOrWhiteSpace($LastUserMessage)) {
        $syntheticUser = ([string]$LastUserMessage).Trim()
        $syntheticUser = $syntheticUser -replace '(?is)^\s*<USER_REQUEST>\s*', '' -replace '(?is)\s*</USER_REQUEST>\s*$', ''
        $syntheticUser = $syntheticUser.Trim()
        $lastTurn = if ($turns.Count -gt 0) { $turns[$turns.Count - 1] } else { $null }
        $lastIsSameUser = ($null -ne $lastTurn -and (Test-SpecrewTurnIsHumanVerdictEvidence -Turn $lastTurn) -and [string]$lastTurn.text -eq $syntheticUser)
        $syntheticIsMachinery = Test-SpecrewConversationMachineryEnvelope -Text $syntheticUser
        if (-not $lastIsSameUser -and -not $syntheticIsMachinery) {
            $turns.Add([pscustomobject]@{ role = 'user'; text = $syntheticUser; verdict_evidence = 'human' }) | Out-Null
        }
    }
    if ($turns.Count -eq 0) { $result.Reason = 'no-turns'; return $result }

    # The packet marker: case-insensitive, tolerate '->' / unicode arrow / 'to' and flexible spacing.
    $markerRx = [regex]::new('SPECREW-VERDICT-BOUNDARY:\s*([a-z-]+)\s*(?:->|→|to)\s*([a-z-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # Newest marker/response pair with a CLEAR approval wins. A newer marker with no response yet is just awaiting
    # the next user turn and must not mask an earlier approved marker that the hook has not had a chance to record.
    $sawMarker = $false
    $sawAwaiting = $false
    for ($i = 0; $i -lt $turns.Count; $i++) {
        # Loop retained for no-marker detection only; the actual selection scans backward below.
        if ([string]$turns[$i].role -ne 'assistant') { continue }
        $mm = $markerRx.Match([string]$turns[$i].text)
        if ($mm.Success) { $sawMarker = $true; break }
    }
    if (-not $sawMarker) {
        $fallback = Get-SpecrewPendingVerdictFallbackCapture -Turns ($turns.ToArray()) -ProjectRoot $ProjectRoot
        if ($fallback.Found) { return $fallback }
        $result.Reason = if ($fallback.Reason -ne 'no-pending-state') { $fallback.Reason } else { 'no-marker' }
        return $result
    }

    for ($i = $turns.Count - 1; $i -ge 0; $i--) {
        if ([string]$turns[$i].role -ne 'assistant') { continue }
        $mm = $markerRx.Match([string]$turns[$i].text)
        if (-not $mm.Success) { continue }

        $mFrom = $mm.Groups[1].Value.ToLowerInvariant()
        $mTo = $mm.Groups[2].Value.ToLowerInvariant()

        # The FIRST human turn AFTER that packet (the response to it; before it = the request, not the verdict).
        $humanText = $null
        for ($j = $i + 1; $j -lt $turns.Count; $j++) {
            if (Test-SpecrewTurnIsHumanVerdictEvidence -Turn $turns[$j]) { $humanText = [string]$turns[$j].text; break }
        }
        if ([string]::IsNullOrWhiteSpace($humanText)) { $sawAwaiting = $true; continue }

        $verdict = Test-SpecrewHumanVerdictToken -Text $humanText
        if (-not $verdict.IsApproval) {
            if ([string]::IsNullOrWhiteSpace($result.Reason) -or $result.Reason -eq 'no-transcript') { $result.Reason = ("not-approval:{0}" -f $verdict.Action) }
            continue
        }

        # Contradiction cross-check: if the human NAMED boundaries, at least one must match the marker's from/to;
        # a human who named a DIFFERENT boundary makes the tie ambiguous -> un-authorized (safety rule).
        $named = @($verdict.NamedBoundaries)
        if ($named.Count -gt 0) {
            $markerSet = @($mFrom, $mTo)
            if (@($named | Where-Object { $markerSet -contains $_ }).Count -eq 0) {
                if ([string]::IsNullOrWhiteSpace($result.Reason) -or $result.Reason -eq 'no-transcript') { $result.Reason = 'named-boundary-contradicts-marker' }
                continue
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($ProjectRoot) -and (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue)) {
            $pendingForMarker = $null
            try { $pendingForMarker = Get-SpecrewPendingVerdictState -ProjectRoot $ProjectRoot } catch { $pendingForMarker = $null }
            if ($null -ne $pendingForMarker -and [bool]$pendingForMarker.HasPendingVerdict) {
                $expectedFrom = [string]$pendingForMarker.PendingFromMarkerBoundary
                $expectedTo = [string]$pendingForMarker.PendingToMarkerBoundary
                if ($mFrom -ne $expectedFrom -or $mTo -ne $expectedTo) {
                    if ([string]::IsNullOrWhiteSpace($result.Reason) -or $result.Reason -eq 'no-transcript') { $result.Reason = 'marker-pending-mismatch' }
                    continue
                }
            }
        }

        $result.Found = $true
        $result.FromBoundary = $mFrom
        $result.ToBoundary = $mTo
        $result.VerdictText = "approved for $mTo"
        $result.HumanText = $humanText
        $result.Reason = 'captured'
        return $result
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $fallback = Get-SpecrewPendingVerdictFallbackCapture -Turns ($turns.ToArray()) -ProjectRoot $ProjectRoot
        if ($fallback.Found) { return $fallback }
        if ($result.Reason -eq 'no-transcript') { $result.Reason = $fallback.Reason }
    }
    if ($sawAwaiting -and ($result.Reason -eq 'no-transcript')) { $result.Reason = 'awaiting-response' }
    return $result
}

function Get-SpecrewCapturedBoundaryPacket {
    # F-174 iteration 011 (T002, FR-022 / DF-3): read the host transcript for the VERBATIM boundary VERDICT packet
    # the agent ACTUALLY RENDERED at the most recent gate stop - NOT a synthesized replacement (the maintainer's
    # load-bearing constraint). Tied to a boundary via the SAME stable marker as the verdict reader
    # <!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> --> (the gate-stop skill emits it). Returns the packet body RAW
    # (read with -Raw so the six '## ' headers + newline structure survive), so a resume inherits the AUTHORED
    # packet instead of placeholders. CONSERVATIVE capture: the marker MUST be present (no marker -> no capture) AND
    # the turn MUST carry substantive content (a MINIMAL structural floor - a char count, NOT six exact '## '
    # headers; demanding the exact form would be a form-without-runtime-compliance trap that a slightly-reworded but
    # genuine packet would fail). No marker / no substance -> Found=$false; the caller degrades to the placeholder.
    # Pure read; fail-open (never throws).
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][string]$TranscriptPath,
        [int]$MaxTailLines = 500,
        # substantive-content floor: a real six-section packet is well over this; a bare marker comment (~60 chars)
        # with no packet body is below it -> not captured (we do not persist an empty "packet").
        [int]$MinPacketChars = 200
    )
    $result = [pscustomobject]@{ Found = $false; FromBoundary = $null; ToBoundary = $null; PacketBody = $null; Reason = 'no-transcript' }
    if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return $result }
    # F-197 iter-004 (T070, #2885): the SAME shared memoized parse the verdict reader used (cache hit here);
    # finalize with -Raw so the six '## ' headers + newline structure round-trip verbatim.
    $shared = $null
    try { $shared = @(Get-SpecrewTranscriptParsedTurns -TranscriptPath $TranscriptPath -MaxLines $MaxTailLines) } catch { $result.Reason = 'unreadable'; return $result }

    # Same marker grammar as the verdict reader: case-insensitive, '->' / unicode arrow / 'to', flexible spacing.
    $markerRx = [regex]::new('SPECREW-VERDICT-BOUNDARY:\s*([a-z-]+)\s*(?:->|→|to)\s*([a-z-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # The LAST assistant turn carrying a marker (the most recently rendered packet), read VERBATIM (-Raw).
    $found = $null
    foreach ($rp in $shared) {
        $tn = Format-SpecrewConversationTurnText -Turn $rp -Raw
        if ($null -eq $tn -or [string]$tn.role -ne 'assistant') { continue }
        $mm = $markerRx.Match([string]$tn.text)
        if ($mm.Success) {
            $found = [pscustomobject]@{ From = $mm.Groups[1].Value.ToLowerInvariant(); To = $mm.Groups[2].Value.ToLowerInvariant(); Body = [string]$tn.text }
        }
    }
    if ($null -eq $found) { $result.Reason = 'no-marker'; return $result }

    $body = [string]$found.Body
    if ($body.Trim().Length -lt $MinPacketChars) { $result.Reason = 'marker-without-substance'; return $result }

    $result.Found = $true
    $result.FromBoundary = $found.From
    $result.ToBoundary = $found.To
    $result.PacketBody = $body
    $result.Reason = 'captured'
    return $result
}

# F-197 iter-004 (T070, #2885): single-entry transcript-parse memo + a parse counter.
# THE LATENCY FIX. Pre-refactor, the three Stop-hook consumers (verdict / packet / conversation-tail) each
# read the transcript tail AND ran `ConvertFrom-Json -Depth 40` + role/parts extraction over EVERY line
# INDEPENDENTLY - three full parses of the same tail per stop (the ~11s of #2885's ~16s). They all run in
# ONE process inside Update-SpecrewRollingHandover, so a single-entry memo keyed by (path, mtime, MaxLines)
# collapses the three parses to one; the per-consumer -Raw/flatten join + the verdict's synthetic-user append
# stay per-consumer (they operate on a COPY of the shared {role; parts} extract, never on the cache).
$script:SpecrewTranscriptParseMemo = $null         # single entry: @{ Key; Turns = {role;parts}[] }
$script:SpecrewTranscriptParseCount = 0            # number of lines ConvertFrom-Json'd on cache MISSES (parse-once witness)

function Reset-SpecrewTranscriptParseCount {
    # Test/diagnostic seam (T072): zero the parse-once witness so a single "stop" can be measured in isolation.
    $script:SpecrewTranscriptParseCount = 0
}

function Clear-SpecrewTranscriptParseMemo {
    # Test/diagnostic seam (T072): drop the single memo entry so the NEXT parse is a guaranteed cache MISS. Used
    # only to measure a single stop COLD in isolation; the production hot path never needs to clear (mtime keys it).
    $script:SpecrewTranscriptParseMemo = $null
}

function Get-SpecrewTranscriptParseCount {
    # Test/diagnostic seam (T072): the number of transcript lines parsed since the last reset. One stop that
    # shares the memo across all three consumers must equal a SINGLE consumer's count (parse-once), not 3x.
    [OutputType([int])]
    param()
    return [int]$script:SpecrewTranscriptParseCount
}

function Get-SpecrewConversationTurnRolePartsFromObject {
    # The pure role/parts EXTRACTION across the host schemas - the part of the per-line parse that is IDENTICAL
    # regardless of -Raw (only the later text-join differs). Takes the already-deserialized JSON object; returns
    # @{ role; parts = string[] } for a user/assistant message line, or $null for a non-message line (session
    # meta / tool / system / developer / unrecognized). No ConvertFrom-Json here - the cost is paid once upstream.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()]$Object)
    if ($null -eq $Object) { return $null }
    $o = $Object

    $role = $null; $parts = @()
    $typeVal = [string](Get-SpecrewConversationProp $o 'type')
    $topRole = Get-SpecrewConversationProp $o 'role'
    $msg = Get-SpecrewConversationProp $o 'message'
    $payload = Get-SpecrewConversationProp $o 'payload'
    $data = Get-SpecrewConversationProp $o 'data'
    $sourceVal = [string](Get-SpecrewConversationProp $o 'source')

    if (-not [string]::IsNullOrWhiteSpace([string]$topRole) -and $null -ne $msg) {
        # Cursor: top-level role + message.content[]
        $role = [string]$topRole
        $parts = Get-SpecrewConversationContentText (Get-SpecrewConversationProp $msg 'content')
    }
    elseif ($typeVal -in @('user', 'assistant') -and $null -ne $msg) {
        # Claude: type in {user,assistant} + message.content[]
        $role = $typeVal
        $parts = Get-SpecrewConversationContentText (Get-SpecrewConversationProp $msg 'content')
    }
    elseif ($typeVal -eq 'response_item' -and $null -ne $payload -and [string](Get-SpecrewConversationProp $payload 'type') -eq 'message') {
        # Codex: response_item -> payload.role + payload.content[] (input_text/output_text/text)
        $role = [string](Get-SpecrewConversationProp $payload 'role')
        $parts = Get-SpecrewConversationContentText (Get-SpecrewConversationProp $payload 'content')
    }
    elseif ($typeVal -match '^(user|assistant)\.message$' -and $null -ne $data) {
        # Copilot: the TYPE prefix carries the role (data has no role field); data.content is the text string
        $role = $matches[1]
        $parts = Get-SpecrewConversationContentText (Get-SpecrewConversationProp $data 'content')
    }
    elseif ($sourceVal -eq 'USER_EXPLICIT' -and $typeVal -eq 'USER_INPUT') {
        # Antigravity: explicit human turns are top-level content wrapped in <USER_REQUEST>...</USER_REQUEST>.
        $role = 'user'
        $content = [string](Get-SpecrewConversationProp $o 'content')
        $m = [regex]::Match($content, '<USER_REQUEST>\s*([\s\S]*?)\s*</USER_REQUEST>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($m.Success) { $content = [string]$m.Groups[1].Value }
        $parts = Get-SpecrewConversationContentText $content
    }
    elseif ($sourceVal -eq 'MODEL' -and $typeVal -eq 'PLANNER_RESPONSE') {
        # Antigravity: assistant planner response is top-level content.
        $role = 'assistant'
        $parts = Get-SpecrewConversationContentText (Get-SpecrewConversationProp $o 'content')
    }
    else { return $null }

    if ($role -notin @('user', 'assistant')) { return $null }   # drop developer/system/tool roles
    $joinedParts = @($parts) -join "`n"
    $isMachinery = $role -eq 'user' -and ((Test-SpecrewConversationMetaFlag -Object $o) -or (Test-SpecrewConversationMachineryEnvelope -Text $joinedParts))
    $verdictEvidence = if ($role -ne 'user') { 'not-user' } elseif ($isMachinery) { 'machinery' } else { 'human' }
    return [pscustomobject]@{ role = $role; parts = @($parts); verdict_evidence = $verdictEvidence }
}

function Format-SpecrewConversationTurnText {
    # The FINALIZE step: turn a shared {role; parts} extract into the final {role; text} a consumer needs, with
    # its OWN -Raw flag. -Raw (T002) preserves the message text VERBATIM (newlines + '## ' structure intact) for
    # the boundary-packet capture, which must round-trip the six-section markdown. The DEFAULT (no -Raw) collapses
    # all whitespace to single spaces for the bounded conversation TAIL, where structure is noise. Both paths strip
    # the system-injected wrappers (targeted removals that do not touch packet structure). Returns $null for a
    # whitespace-only result or a pure hook-prompt user turn (dropped by the caller). Does NOT mutate the input.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()]$Turn, [switch]$Raw)
    if ($null -eq $Turn) { return $null }
    $role = [string]$Turn.role
    $parts = @($Turn.parts)
    if ($role -notin @('user', 'assistant')) { return $null }
    # -Raw (T002): join parts with a newline to keep block boundaries; DEFAULT joins with a space for the flat tail.
    $text = if ($Raw) { (@($parts) -join "`n") } else { (@($parts) -join ' ') }
    $verdictEvidence = [string](Get-SpecrewConversationProp $Turn 'verdict_evidence')
    if ([string]::IsNullOrWhiteSpace($verdictEvidence)) {
        $verdictEvidence = if ($role -ne 'user') { 'not-user' } elseif (Test-SpecrewConversationMachineryEnvelope -Text $text) { 'machinery' } else { 'human' }
    }
    # strip query/redaction wrappers + the most obvious system-injected blocks (keep a short marker so the
    # signal survives without the bulk). These are targeted removals; they do not touch '## ' packet structure.
    $text = $text -replace '</?user_query>', '' -replace '</?environment_details>', '' -replace '\[REDACTED\]', ''
    $text = $text -replace '<task-notification>[\s\S]*?</task-notification>', '[task-notification]'
    $text = $text -replace '<turn_aborted>[\s\S]*?</turn_aborted>', '[turn aborted]'
    # -Raw preserves internal whitespace (newlines + the markdown structure the packet round-trip needs); the
    # default flattens it for the bounded tail. Both trim the outer edges.
    $text = if ($Raw) { $text.Trim() } else { ($text -replace '\s+', ' ').Trim() }
    if ($role -eq 'user' -and $text -match '^\s*<hook_prompt\b[\s\S]*</hook_prompt>\s*$') { return $null }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return [pscustomobject]@{ role = $role; text = $text; verdict_evidence = $verdictEvidence }
}

function Get-SpecrewTranscriptParsedTurns {
    # F-197 iter-004 (T070, #2885): read the transcript tail + ConvertFrom-Json + role/parts EXTRACT exactly ONCE
    # per (TranscriptPath, file-mtime, MaxLines), MEMOIZED to a SINGLE entry. The three Stop-hook consumers call
    # this with the same key in one process, so the expensive parse runs once and the other two are cache hits.
    # Returns a FRESH array of the shared {role; parts} turns (a COPY of the outer list) so a consumer's own
    # transform - the verdict reader's synthetic-user append, or any list mutation - can NEVER leak into the cache
    # or another consumer. The {role; parts} entries are read-only on the finalize path (Format-... only reads),
    # so a shallow array copy is sufficient; no deep clone needed. Single entry keyed by mtime => unbounded growth
    # is impossible and a rewritten transcript invalidates correctly. Fail-open: an unreadable file -> empty array.
    # mtime-resolution assumption (145 T070): the key trusts the filesystem last-write tick to advance on a real
    # rewrite. A stale hit needs DIFFERENT content at the SAME path with an IDENTICAL tick - which the hot path
    # cannot produce: the three intended hits are one in-process burst (ms apart, identical content), and two
    # distinct Stop crossings are a full agent turn apart (seconds), so the tick always advances between contents.
    # A same-tick rewrite only occurs if a writer deliberately pins the prior timestamp - not a real Stop pattern.
    [OutputType([pscustomobject[]])]
    param([Parameter()][AllowNull()][string]$TranscriptPath, [int]$MaxLines = 500)
    if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return @() }

    $mtime = $null
    try { $mtime = ([System.IO.File]::GetLastWriteTimeUtc($TranscriptPath)).Ticks } catch { $mtime = $null }
    $key = ('{0}|{1}|{2}' -f $TranscriptPath, [string]$mtime, [int]$MaxLines)

    $memo = $script:SpecrewTranscriptParseMemo
    if ($null -ne $memo -and [string]$memo.Key -eq $key) {
        # Cache HIT - hand back a fresh outer array so the caller can append/mutate its own list safely.
        return @($memo.Turns)
    }

    # Cache MISS - the one true parse for this key.
    $lines = @(Get-SpecrewTranscriptTailLines -Path $TranscriptPath -MaxLines $MaxLines)
    $turns = New-Object System.Collections.Generic.List[object]
    foreach ($l in $lines) {
        if ([string]::IsNullOrWhiteSpace($l)) { continue }
        $o = $null
        try { $o = $l | ConvertFrom-Json -Depth 40 -ErrorAction Stop } catch { $o = $null }
        $script:SpecrewTranscriptParseCount = [int]$script:SpecrewTranscriptParseCount + 1   # parse-once witness (one count per ConvertFrom-Json)
        if ($null -eq $o) { continue }
        $rp = Get-SpecrewConversationTurnRolePartsFromObject -Object $o
        if ($null -ne $rp) { $turns.Add($rp) | Out-Null }
    }
    $arr = @($turns.ToArray())
    $script:SpecrewTranscriptParseMemo = [pscustomobject]@{ Key = $key; Turns = $arr }
    return @($arr)
}

function Get-SpecrewConversationTurnFromLine {
    # Best-effort (role,text) from one transcript JSONL line across the 4 host schemas. Returns $null for a
    # non-message line (session meta / tool / system / developer / parse failure) -> skipped by the caller.
    # F-197 iter-004 (T070): now COMPOSES the split helpers - ConvertFrom-Json -> role/parts extract -> finalize -
    # so other callers that parse a single line ad hoc keep working with IDENTICAL behavior to the pre-refactor
    # monolith. (The Stop-hook hot path goes through the memoized Get-SpecrewTranscriptParsedTurns instead.)
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][string]$Line, [switch]$Raw)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    $o = $null
    try { $o = $Line | ConvertFrom-Json -Depth 40 -ErrorAction Stop } catch { return $null }
    if ($null -eq $o) { return $null }
    $rp = Get-SpecrewConversationTurnRolePartsFromObject -Object $o
    if ($null -eq $rp) { return $null }
    return (Format-SpecrewConversationTurnText -Turn $rp -Raw:$Raw)
}

function Format-SpecrewConversationBullets {
    # Render the last $MaxTurns turns as `- **role:** text` bullets, per-turn truncated, then drop OLDEST
    # bullets until the whole block is under the HARD char cap (keep the newest).
    param([Parameter()][AllowNull()][object[]]$Turns, [int]$MaxTurns = 8, [int]$MaxChars = 4000, [int]$PerTurn = 240)
    $tail = @(@($Turns) | Select-Object -Last $MaxTurns)
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($t in $tail) {
        $s = [string]$t.text
        if ($s.Length -gt $PerTurn) { $s = $s.Substring(0, $PerTurn) + '...' }
        $out.Add(('- **{0}:** {1}' -f $t.role, $s)) | Out-Null
    }
    while ((($out -join "`n").Length) -gt $MaxChars -and $out.Count -gt 1) { $out.RemoveAt(0) }
    return , $out.ToArray()
}

function Get-SpecrewConversationTail {
    # The "Recent conversation" handover section body, via the 4-tier resilience ladder. ALWAYS returns a
    # string (a real tail, a raw-tail-with-note, the payload last message, or an honest floor); never throws.
    [OutputType([string])]
    param(
        [Parameter()][AllowNull()][string]$HostKind,
        [Parameter()][AllowNull()][string]$TranscriptPath,
        [Parameter()][AllowNull()][string]$LastAssistantMessage,
        [int]$MaxTurns = 8,
        [int]$MaxChars = 4000,
        [int]$PerTurn = 240,
        # F-174 iter-10 (T002 fix F3): bound the transcript read to the TAIL. The handover refreshes on Claude
        # PostToolUse (every tool call); a long session's transcript is tens of thousands of JSONL lines, so a
        # whole-file read per tool call is an O(session) overhead trap. 500 lines comfortably covers the last
        # $MaxTurns user/assistant turns even on chatty hosts (many tool/system lines per turn).
        [int]$MaxTailLines = 500
    )
    $hostLabel = if ([string]::IsNullOrWhiteSpace($HostKind)) { 'this host' } else { $HostKind }
    $pointer = if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) { ('Full transcript (read on-demand for depth): {0}' -f $TranscriptPath) } else { $null }

    $join = {
        param($Bullets, $Note)
        $sb = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace([string]$Note)) { $sb.Add([string]$Note) | Out-Null; $sb.Add('') | Out-Null }
        foreach ($b in @($Bullets)) { $sb.Add([string]$b) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace([string]$pointer)) { $sb.Add('') | Out-Null; $sb.Add([string]$pointer) | Out-Null }
        return (($sb -join "`n").Trim())
    }

    # Tier 1: structured per-host parse. F-197 iter-004 (T070, #2885): the EXPENSIVE ConvertFrom-Json + role/parts
    # extract comes from the SHARED memoized parse (a cache hit when the verdict/packet readers ran first this
    # stop; the one true parse if this consumer runs first). It reads the tail + parses internally, so on the
    # common Tier-1 path this consumer does NOT separately byte-read the tail; the raw $fileLines below is read
    # LAZILY only when the structured parse yields nothing (the Tier-2 drift fallback). Finalize with DEFAULT
    # (non-Raw) flatten.
    if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) {
        $shared = @(Get-SpecrewTranscriptParsedTurns -TranscriptPath $TranscriptPath -MaxLines $MaxTailLines)
        if ($shared.Count -gt 0) {
            $turns = New-Object System.Collections.Generic.List[object]
            foreach ($rp in $shared) { $t = Format-SpecrewConversationTurnText -Turn $rp; if ($null -ne $t) { $turns.Add($t) | Out-Null } }
            if ($turns.Count -gt 0) {
                $bullets = Format-SpecrewConversationBullets -Turns ($turns.ToArray()) -MaxTurns $MaxTurns -MaxChars $MaxChars -PerTurn $PerTurn
                return (& $join $bullets $null)
            }
        }

        # No structured turns -> read the raw byte tail to decide Tier 2 (present-but-unrecognized schema) vs
        # fall through to Tier 3 / Floor (absent or empty file). This byte read only happens off the happy path.
        $fileLines = $null
        try {
            if (Test-Path -LiteralPath $TranscriptPath -PathType Leaf) {
                # Read only the TAIL (not the whole file) - see $MaxTailLines. On Codex this also naturally
                # skips the giant line-1 session_meta header.
                $fileLines = @(Get-SpecrewTranscriptTailLines -Path $TranscriptPath -MaxLines $MaxTailLines)
            }
        }
        catch { $fileLines = $null }

        if ($null -ne $fileLines -and $fileLines.Count -gt 0) {
            # Tier 2: present but unrecognized schema -> raw bounded tail + VISIBLE degradation note.
            $nonEmpty = @($fileLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($nonEmpty.Count -gt 0) {
                $rawTurns = @($nonEmpty | Select-Object -Last $MaxTurns | ForEach-Object { [pscustomobject]@{ role = 'raw'; text = (([string]$_ -replace '\s+', ' ').Trim()) } })
                $bullets = @(Format-SpecrewConversationBullets -Turns $rawTurns -MaxTurns $MaxTurns -MaxChars $MaxChars -PerTurn $PerTurn) | ForEach-Object { $_ -replace '^\- \*\*raw:\*\* ', '- ' }
                $note = ('(transcript present but its format was not recognized - showing a raw tail; the structured parser for {0} may need updating)' -f $hostLabel)
                return (& $join $bullets $note)
            }
        }
    }

    # Tier 3: no readable file, but the event payload handed us the last assistant message (Codex).
    if (-not [string]::IsNullOrWhiteSpace($LastAssistantMessage)) {
        $s = ([string]$LastAssistantMessage -replace '\s+', ' ').Trim()
        if ($s.Length -gt $PerTurn) { $s = $s.Substring(0, $PerTurn) + '...' }
        $note = '(transcript file unavailable this stop - showing the last assistant message from the event payload)'
        return (& $join @(('- **assistant:** {0}' -f $s)) $note)
    }

    # Floor.
    return ('(no conversation transcript exposed by {0} this stop - the next session relies on the git delta, the artifact-derived orientation, and the agent-authored sections above.)' -f $hostLabel)
}
