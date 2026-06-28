$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-197 co-review ESCALATION-LATCH closure predicate.
#
# THE TRUST MODEL IS THE LATCH. A co-review escalation may be closed ONLY by the human, never by the agent. This
# predicate answers "has a human authorized closing THIS escalation?" by reading ONLY user-role transcript turns
# recorded AFTER the escalation was surfaced. The agent authors assistant turns and files — it cannot author a
# user turn — so it structurally cannot forge a closure (the adversarial (b) safety gate in
# tests/continuous-co-review/unit/escalation-latch.Tests.ps1). Every ambiguity (non-user role, missing/older/
# unparseable timestamp, any negation/hesitation, empty text) resolves to KEEP BLOCKING: a false-block is the
# harmless spin; a false-close would be a co-review silencer — the one failure that must never happen.

function Get-ContinuousCoReviewTurnField {
    param([AllowNull()]$Turn, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Turn) { return $null }
    if ($Turn -is [System.Collections.IDictionary]) { if ($Turn.Contains($Name)) { return $Turn[$Name] } return $null }
    $prop = $Turn.PSObject.Properties[$Name]
    if ($null -ne $prop) { return $prop.Value }
    return $null
}

function ConvertTo-ContinuousCoReviewUtc {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try {
        return [datetimeoffset]::Parse(
            $Value, [cultureinfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    }
    catch { return $null }
}

function Test-ContinuousCoReviewEscalationHumanClosed {
    [CmdletBinding()]
    param(
        # When the escalation was surfaced to the human (ISO-8601 UTC). A closing decision must come AFTER this.
        [Parameter(Mandatory)][string]$SurfacedAtUtc,
        # Parsed transcript turns: objects/hashtables with role ('user'|'assistant'), text, timestamp (ISO UTC).
        # Supplied by the hook from the REAL transcript; the agent cannot inject a user-role turn here.
        [AllowNull()]$ConversationTurns
    )

    if ($null -eq $ConversationTurns) { return $false }
    $surfacedAt = ConvertTo-ContinuousCoReviewUtc -Value $SurfacedAtUtc
    if ($null -eq $surfacedAt) { return $false }   # unparseable surfacing time -> keep blocking

    # CONSERVATIVE matching, safety-biased.
    $authPattern = '(?i)\b(authoris|authoriz|approv|accept|defer|proceed|go ahead|sounds good|do it)'
    $negPattern = "(?i)(\bdo not\b|\bdon'?t\b|\bcannot\b|\bcan'?t\b|\bnot\b|\bno\b|\breject|\brefus|\bdeny\b|\bdisapprov|\bhold off\b|\bwait\b|\bstop\b)"

    foreach ($turn in @($ConversationTurns)) {
        if ($null -eq $turn) { continue }
        $role = ([string](Get-ContinuousCoReviewTurnField -Turn $turn -Name 'role')).Trim().ToLowerInvariant()
        if ($role -ne 'user') { continue }   # ONLY the human; the agent cannot author a user turn

        $ts = ConvertTo-ContinuousCoReviewUtc -Value ([string](Get-ContinuousCoReviewTurnField -Turn $turn -Name 'timestamp'))
        if ($null -eq $ts -or $ts -le $surfacedAt) { continue }   # must be a FRESH decision about THIS escalation

        $text = [string](Get-ContinuousCoReviewTurnField -Turn $turn -Name 'text')
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        if ($text -match $negPattern) { continue }   # any refusal/hesitation -> keep blocking
        if ($text -match $authPattern) { return $true }
    }
    return $false
}
