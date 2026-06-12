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

function Get-SpecrewConversationTurnFromLine {
    # Best-effort (role,text) from one transcript JSONL line across the 4 host schemas. Returns $null for a
    # non-message line (session meta / tool / system / developer / parse failure) -> skipped by the caller.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][string]$Line)
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
    $text = (@($parts) -join ' ')
    # strip query/redaction wrappers + the most obvious system-injected blocks (keep a short marker so the
    # signal survives without the bulk)
    $text = $text -replace '</?user_query>', '' -replace '</?environment_details>', '' -replace '\[REDACTED\]', ''
    $text = $text -replace '<task-notification>[\s\S]*?</task-notification>', '[task-notification]'
    $text = $text -replace '<turn_aborted>[\s\S]*?</turn_aborted>', '[turn aborted]'
    $text = ($text -replace '\s+', ' ').Trim()
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
        [int]$PerTurn = 240
    )
    $hostLabel = if ([string]::IsNullOrWhiteSpace($HostKind)) { 'this host' } else { $HostKind }
    $pointer = if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) { ('Full transcript (read on-demand for depth): {0}' -f $TranscriptPath) } else { $null }

    $fileLines = $null
    if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) {
        try {
            if (Test-Path -LiteralPath $TranscriptPath -PathType Leaf) {
                $fileLines = @(Get-Content -LiteralPath $TranscriptPath -Encoding UTF8 -ErrorAction Stop)
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
