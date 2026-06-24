# Devin host package — in-package handover normalizer (DevinHandoverAdapter)
#
# Feature 200 FR-011 (in-package), spike outcome 2.
#
# The tested build's Stop payload carries only {hook_event_name, stop_hook_active} — no
# assistant-message field — so Tier-3 event-payload handover is unavailable. But `devin --export`
# writes an ATIF document (v1.7, steps[]) BEFORE Stop, where:
#   - source: "user"  carries a string `message`
#   - source: "agent" carries a string `message`
#
# This adapter normalizes that ATIF document to the EXISTING Claude-like JSONL turn shape that the
# UNCHANGED parser (scripts/internal/bootstrap/ConversationCaptureAccessor.ps1) already consumes:
#   {"type":"user","message":{"content":[{"type":"text","text":"..."}]}}
#   {"type":"assistant","message":{"content":[{"type":"text","text":"..."}]}}
#
# No parser change and no accessor edit are required (FR-012). All Devin specifics live here, in
# hosts/devin/. The output is BYTE-STABLE across repeated normalization of the same input
# (deterministic: fixed key order via explicit JSON construction, '\n' line joins, no timestamps).

Set-StrictMode -Version Latest

function ConvertTo-DevinAtifJsonlLine {
    <#
    .SYNOPSIS
    Render ONE normalized Claude-like JSONL turn line for a (role, text) pair.
    .DESCRIPTION
    Builds the object as an ordered structure and serializes it with -Compress so the key order and
    spacing are stable. The parser reads `type` (user|assistant) + message.content[].text.
    .OUTPUTS
    string (one JSONL line) or $null when role/text is unusable.
    #>
    param(
        [Parameter()][AllowNull()][string]$Role,
        [Parameter()][AllowNull()][string]$Text
    )
    if ([string]::IsNullOrWhiteSpace($Role) -or [string]::IsNullOrWhiteSpace($Text)) { return $null }
    # ATIF source 'agent' maps to the parser's 'assistant'; 'user' stays 'user'.
    $type = switch ($Role.ToLowerInvariant()) {
        'user'      { 'user' }
        'agent'     { 'assistant' }
        'assistant' { 'assistant' }
        default     { $null }
    }
    if ($null -eq $type) { return $null }

    # Ordered hashtable -> stable key order under -Compress (type, then message).
    $turn = [ordered]@{
        type    = $type
        message = [ordered]@{
            content = @(
                [ordered]@{ type = 'text'; text = [string]$Text }
            )
        }
    }
    return ($turn | ConvertTo-Json -Depth 10 -Compress)
}

function ConvertFrom-DevinAtifToParserJsonl {
    <#
    .SYNOPSIS
    Normalize a Devin ATIF document into the unchanged parser's Claude-like JSONL turn shape (FR-011).
    .DESCRIPTION
    Accepts either an ATIF JSON STRING (the literal --export output) or an already-parsed object.
    Walks steps[] in order, emitting one JSONL line per user/agent message step. Non-message steps
    (tool calls, system rows, steps without a string message) are skipped, so tool noise never lands
    in the handover tail. Deterministic + byte-stable: same input -> same bytes, line-ordered as the
    source steps, '\n'-joined, no trailing newline.
    .OUTPUTS
    string — the normalized JSONL document (lines joined by '\n').
    #>
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Atif
    )

    $doc = $null
    if ($Atif -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Atif)) { return '' }
        try { $doc = $Atif | ConvertFrom-Json -Depth 40 -ErrorAction Stop }
        catch { return '' }
    }
    else {
        $doc = $Atif
    }
    if ($null -eq $doc) { return '' }

    # StrictMode-safe read of steps[].
    $stepsProp = $doc.PSObject.Properties.Match('steps')
    if ($stepsProp.Count -eq 0 -or $null -eq $stepsProp[0].Value) { return '' }
    $steps = @($stepsProp[0].Value)

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($step in $steps) {
        if ($null -eq $step) { continue }
        $srcProp = $step.PSObject.Properties.Match('source')
        $msgProp = $step.PSObject.Properties.Match('message')
        if ($srcProp.Count -eq 0 -or $msgProp.Count -eq 0) { continue }
        $source = [string]$srcProp[0].Value
        $messageValue = $msgProp[0].Value
        # The tested build's user/agent turns carry a STRING message. A non-string message (structured
        # tool payload) is not a conversational turn for this shape -> skip rather than guess.
        if ($messageValue -isnot [string]) { continue }
        $line = ConvertTo-DevinAtifJsonlLine -Role $source -Text ([string]$messageValue)
        if (-not [string]::IsNullOrWhiteSpace($line)) { $lines.Add($line) | Out-Null }
    }

    return ($lines.ToArray() -join "`n")
}
