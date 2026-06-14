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

function Test-SpecrewHumanVerdictToken {
    # F-174 iteration 011 (T004, FR-026): classify a HUMAN turn's response to a boundary VERDICT packet —
    # CONSERVATIVELY. The gate-stop packet offers: (1) Approve as-is, (2) Approve with instructions, (3) Send
    # back, (4) Discuss prompt #N. A human types one of those, a bare option number, an "approve [X -> Y] [with
    # instructions]" line, or a send-back / discuss / question. SAFETY RULE (the maintainer's): only IsApproval
    # when the turn CLEARLY approves; anything negated / send-back / discuss / ambiguous / a bare question -> NOT
    # an approval, so the caller records the crossing un-authorized rather than inventing one. Pure string logic;
    # never throws.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][string]$Text)

    $r = [pscustomobject]@{ Action = 'none'; IsApproval = $false; IsSendBack = $false; IsDiscuss = $false; NamedBoundaries = @() }
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
    if ($lower -match '\bsend\s*back\b' -or $lower -match '\breject(ed|ing)?\b' -or $lower -match '^\s*3\b' -or $lower -match '\bchanges?\s+(needed|required|requested)\b') {
        $r.IsSendBack = $true; $r.Action = 'send-back'; return $r
    }
    # Discuss a specific prompt — NOT an authorization (discussion is not approval).
    if ($lower -match '\bdiscuss\b' -or $lower -match '^\s*4\b' -or $lower -match '\bprompt\s*#?\d') {
        $r.IsDiscuss = $true; $r.Action = 'discuss'; return $r
    }
    # Negated / deferred approval -> NOT an approval (defends "do not approve", "not yet", "hold off ... approve").
    if ($lower -match "\b(do\s*not|don'?t|never|not\s+yet|hold\s+off|wait|stop)\b[^.!?]{0,24}\bapprov") { return $r }
    if ($lower -match "\bapprov\w*\b[^.!?]{0,16}\b(later|after|once|when|unless)\b") { return $r }
    # CLEAR approval: an "approve"/"approved" verb (incl. canonical "approved for <boundary>"), OR a bare option
    # 1/2 where the WHOLE turn is just that number. Deliberately NARROW — "start"/"proceed"/"continue"/"ok"/"yes"
    # are NOT treated as boundary approvals (too ambiguous against the safety rule); they fall to pending so the
    # human re-confirms rather than risk an invented approval.
    if ($lower -match '\bapprove(d|s)?\b' -or $lower -match '^\s*[12]\s*[.):]?\s*$') {
        $r.IsApproval = $true; $r.Action = 'approve'; return $r
    }
    return $r
}

function Get-SpecrewCapturedBoundaryVerdict {
    # F-174 iteration 011 (T004, FR-026): read the host transcript for the human's verdict on the MOST RECENTLY
    # rendered boundary VERDICT packet. The verdict is tied to a boundary ONLY via the packet's stable machine
    # marker <!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> --> (T002 / the gate-stop skill emits it; it is an HTML
    # comment, invisible in the rendered markdown, present in the transcript). NO marker -> NO capture (the human
    # re-confirms via the pending surface). Finds the last marker-bearing ASSISTANT turn, then the FIRST human
    # turn after it, and classifies that turn with Test-SpecrewHumanVerdictToken. Returns captured verdict
    # evidence ONLY on a CLEAR approval whose human-named boundary (if any) does not CONTRADICT the marker;
    # otherwise Found=$false so the caller records the crossing un-authorized. Pure read; fail-open (never throws).
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()][string]$TranscriptPath,
        [int]$MaxTailLines = 500
    )
    $result = [pscustomobject]@{ Found = $false; FromBoundary = $null; ToBoundary = $null; VerdictText = $null; HumanText = $null; Reason = 'no-transcript' }
    if ([string]::IsNullOrWhiteSpace($TranscriptPath) -or -not (Test-Path -LiteralPath $TranscriptPath -PathType Leaf)) { return $result }
    $lines = $null
    try { $lines = @(Get-Content -LiteralPath $TranscriptPath -Tail $MaxTailLines -Encoding UTF8 -ErrorAction Stop) } catch { $result.Reason = 'unreadable'; return $result }
    if ($null -eq $lines -or $lines.Count -eq 0) { $result.Reason = 'empty'; return $result }

    $turns = New-Object System.Collections.Generic.List[object]
    foreach ($l in $lines) { $tn = Get-SpecrewConversationTurnFromLine -Line $l; if ($null -ne $tn) { $turns.Add($tn) | Out-Null } }
    if ($turns.Count -eq 0) { $result.Reason = 'no-turns'; return $result }

    # The packet marker: case-insensitive, tolerate '->' / unicode arrow / 'to' and flexible spacing.
    $markerRx = [regex]::new('SPECREW-VERDICT-BOUNDARY:\s*([a-z-]+)\s*(?:->|→|to)\s*([a-z-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # The LAST assistant turn that carries a marker (the most recently gated boundary).
    $markerIdx = -1; $mFrom = $null; $mTo = $null
    for ($i = 0; $i -lt $turns.Count; $i++) {
        if ([string]$turns[$i].role -ne 'assistant') { continue }
        $mm = $markerRx.Match([string]$turns[$i].text)
        if ($mm.Success) { $markerIdx = $i; $mFrom = $mm.Groups[1].Value.ToLowerInvariant(); $mTo = $mm.Groups[2].Value.ToLowerInvariant() }
    }
    if ($markerIdx -lt 0) { $result.Reason = 'no-marker'; return $result }

    # The FIRST human turn AFTER that packet (the response to it; before it = the request, not the verdict).
    $humanText = $null
    for ($j = $markerIdx + 1; $j -lt $turns.Count; $j++) {
        if ([string]$turns[$j].role -eq 'user') { $humanText = [string]$turns[$j].text; break }
    }
    if ([string]::IsNullOrWhiteSpace($humanText)) { $result.Reason = 'awaiting-response'; return $result }

    $verdict = Test-SpecrewHumanVerdictToken -Text $humanText
    if (-not $verdict.IsApproval) { $result.Reason = ("not-approval:{0}" -f $verdict.Action); return $result }

    # Contradiction cross-check: if the human NAMED boundaries, at least one must match the marker's from/to;
    # a human who named a DIFFERENT boundary makes the tie ambiguous -> un-authorized (safety rule).
    $named = @($verdict.NamedBoundaries)
    if ($named.Count -gt 0) {
        $markerSet = @($mFrom, $mTo)
        if (@($named | Where-Object { $markerSet -contains $_ }).Count -eq 0) { $result.Reason = 'named-boundary-contradicts-marker'; return $result }
    }

    $result.Found = $true
    $result.FromBoundary = $mFrom
    $result.ToBoundary = $mTo
    $result.VerdictText = "approved for $mTo"
    $result.HumanText = $humanText
    $result.Reason = 'captured'
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
    $lines = $null
    try { $lines = @(Get-Content -LiteralPath $TranscriptPath -Tail $MaxTailLines -Encoding UTF8 -ErrorAction Stop) } catch { $result.Reason = 'unreadable'; return $result }
    if ($null -eq $lines -or $lines.Count -eq 0) { $result.Reason = 'empty'; return $result }

    # Same marker grammar as the verdict reader: case-insensitive, '->' / unicode arrow / 'to', flexible spacing.
    $markerRx = [regex]::new('SPECREW-VERDICT-BOUNDARY:\s*([a-z-]+)\s*(?:->|→|to)\s*([a-z-]+)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    # The LAST assistant turn carrying a marker (the most recently rendered packet), read VERBATIM (-Raw).
    $found = $null
    foreach ($l in $lines) {
        $tn = Get-SpecrewConversationTurnFromLine -Line $l -Raw
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

function Get-SpecrewConversationTurnFromLine {
    # Best-effort (role,text) from one transcript JSONL line across the 4 host schemas. Returns $null for a
    # non-message line (session meta / tool / system / developer / parse failure) -> skipped by the caller.
    # F-174 iter-11 (T002): -Raw preserves the message text VERBATIM (newlines + '## ' structure intact) for the
    # boundary-packet capture, which must round-trip the six-section markdown. The DEFAULT (no -Raw) collapses all
    # whitespace to single spaces for the bounded conversation TAIL, where structure is noise. Raw still strips the
    # system-injected wrappers (targeted removals that do not touch packet structure) and joins multiple content
    # parts with a newline (a part boundary is a block boundary), but never collapses internal whitespace.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][string]$Line, [switch]$Raw)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    $o = $null
    try { $o = $Line | ConvertFrom-Json -Depth 40 -ErrorAction Stop } catch { return $null }
    if ($null -eq $o) { return $null }

    $role = $null; $parts = @()
    $typeVal = [string](Get-SpecrewConversationProp $o 'type')
    $topRole = Get-SpecrewConversationProp $o 'role'
    $msg = Get-SpecrewConversationProp $o 'message'
    $payload = Get-SpecrewConversationProp $o 'payload'
    $data = Get-SpecrewConversationProp $o 'data'

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
    else { return $null }

    if ($role -notin @('user', 'assistant')) { return $null }   # drop developer/system/tool roles
    # -Raw (T002): join parts with a newline to keep block boundaries; DEFAULT joins with a space for the flat tail.
    $text = if ($Raw) { (@($parts) -join "`n") } else { (@($parts) -join ' ') }
    # strip query/redaction wrappers + the most obvious system-injected blocks (keep a short marker so the
    # signal survives without the bulk). These are targeted removals; they do not touch '## ' packet structure.
    $text = $text -replace '</?user_query>', '' -replace '</?environment_details>', '' -replace '\[REDACTED\]', ''
    $text = $text -replace '<task-notification>[\s\S]*?</task-notification>', '[task-notification]'
    $text = $text -replace '<turn_aborted>[\s\S]*?</turn_aborted>', '[turn aborted]'
    # -Raw preserves internal whitespace (newlines + the markdown structure the packet round-trip needs); the
    # default flattens it for the bounded tail. Both trim the outer edges.
    $text = if ($Raw) { $text.Trim() } else { ($text -replace '\s+', ' ').Trim() }
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return [pscustomobject]@{ role = $role; text = $text }
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

    $fileLines = $null
    if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) {
        try {
            if (Test-Path -LiteralPath $TranscriptPath -PathType Leaf) {
                # Read only the TAIL (not the whole file) - see $MaxTailLines. On Codex this also naturally
                # skips the giant line-1 session_meta header.
                $fileLines = @(Get-Content -LiteralPath $TranscriptPath -Tail $MaxTailLines -Encoding UTF8 -ErrorAction Stop)
            }
        }
        catch { $fileLines = $null }
    }

    $join = {
        param($Bullets, $Note)
        $sb = New-Object System.Collections.Generic.List[string]
        if (-not [string]::IsNullOrWhiteSpace([string]$Note)) { $sb.Add([string]$Note) | Out-Null; $sb.Add('') | Out-Null }
        foreach ($b in @($Bullets)) { $sb.Add([string]$b) | Out-Null }
        if (-not [string]::IsNullOrWhiteSpace([string]$pointer)) { $sb.Add('') | Out-Null; $sb.Add([string]$pointer) | Out-Null }
        return (($sb -join "`n").Trim())
    }

    if ($null -ne $fileLines -and $fileLines.Count -gt 0) {
        # Tier 1: structured per-host parse.
        $turns = New-Object System.Collections.Generic.List[object]
        foreach ($l in $fileLines) { $t = Get-SpecrewConversationTurnFromLine -Line $l; if ($null -ne $t) { $turns.Add($t) | Out-Null } }
        if ($turns.Count -gt 0) {
            $bullets = Format-SpecrewConversationBullets -Turns ($turns.ToArray()) -MaxTurns $MaxTurns -MaxChars $MaxChars -PerTurn $PerTurn
            return (& $join $bullets $null)
        }
        # Tier 2: present but unrecognized schema -> raw bounded tail + VISIBLE degradation note.
        $nonEmpty = @($fileLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($nonEmpty.Count -gt 0) {
            $rawTurns = @($nonEmpty | Select-Object -Last $MaxTurns | ForEach-Object { [pscustomobject]@{ role = 'raw'; text = (([string]$_ -replace '\s+', ' ').Trim()) } })
            $bullets = @(Format-SpecrewConversationBullets -Turns $rawTurns -MaxTurns $MaxTurns -MaxChars $MaxChars -PerTurn $PerTurn) | ForEach-Object { $_ -replace '^\- \*\*raw:\*\* ', '- ' }
            $note = ('(transcript present but its format was not recognized - showing a raw tail; the structured parser for {0} may need updating)' -f $hostLabel)
            return (& $join $bullets $note)
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
