# FR-045 STOP-INTENT classification (T019 piece 4b, maintainer 2026-07-13). Distinguishes an INTERMEDIATE stop
# (an operational YIELD on a background-capable harness while Specrew-OWNED work is still in flight and the agent
# intends to continue) from a REAL stop (a genuine conversational handoff). An intermediate stop gets ONE concise
# progress sentence + the SPECREW-STOP-INTENT marker and is EXEMPT from the five-part material-work packet; a real
# stop keeps the existing boundary / non-boundary packet enforcement unchanged.
#
# PURE + DETERMINISTIC. The Stop hook computes the boolean inputs (from the marker in THIS turn's assistant message,
# the T019 in-flight registry, the pending-verdict state, and message heuristics) and this function classifies. This
# is NOT a per-host background-capability matrix: a host with no background execution simply never produces an
# in-flight signal, so it always classifies as a real stop and behaves exactly as before.
#
# The marker is a portable FALLBACK, never sole authority. A contradiction with known runtime state, a pending
# lifecycle boundary, a user-action request, a hand-back, or a marker sourced from user content ALL force REAL.
# "The agent needs nothing from the user" is NOT sufficient on its own — final completion also needs nothing, yet
# is a REAL stop. The defining condition for intermediate is that OWNED WORK REMAINS ACTIVE and the agent continues.

$script:ContinuousCoReviewStopIntentMarker = '<!-- SPECREW-STOP-INTENT: intermediate -->'

function Get-ContinuousCoReviewStopIntentMarker {
    return $script:ContinuousCoReviewStopIntentMarker
}

function Resolve-ContinuousCoReviewStopIntent {
    param(
        # INTERMEDIATE SIGNAL — the agent asserts owned work is in flight and it intends to continue automatically:
        [bool]$MarkerPresent = $false,               # the SPECREW-STOP-INTENT marker is in the assistant's CURRENT-turn message
        [bool]$MarkerFromAssistant = $true,          # that marker came from the assistant's turn, NOT from quoted/echoed user content
        [bool]$OwnedWorkInFlight = $false,           # known Specrew in-flight runtime state (the T019 registry) shows an ACTIVE owned run

        # CONTRADICTIONS — any one forces a REAL stop even when an intermediate signal is present:
        [bool]$LifecycleBoundaryPending = $false,    # a lifecycle verdict boundary is pending (a human handoff is due)
        [bool]$RuntimeWorkTerminalOrAbsent = $false, # known runtime state says the claimed in-flight work is terminal or absent (stale marker)
        [bool]$MessageRequestsUserAction = $false,   # the message asks the user a question / requests a decision, authorization, action, or review
        [bool]$AgentBlockedOrHandingBack = $false    # the agent says it is blocked, failed unrecoverably, or is intentionally handing control back
    )
    $mk = {
        param([string]$intent, [bool]$enforcePacket, [string]$reason)
        [pscustomobject]@{ intent = $intent; enforce_packet = $enforcePacket; reason = $reason }
    }

    # A marker counts ONLY as the assistant's own current-turn assertion (never user-quoted content).
    $assistantMarker = $MarkerPresent -and $MarkerFromAssistant
    # The intermediate SIGNAL: the agent marked an operational yield OR the registry shows owned work in flight.
    $intermediateSignal = $assistantMarker -or $OwnedWorkInFlight

    # CONTRADICTION PRECEDENCE — force REAL and apply normal enforcement. Order is by specificity of the reason.
    if ($MarkerPresent -and -not $MarkerFromAssistant) { return & $mk 'real' $true 'stop-intent marker came from user content, not the assistant turn' }
    if ($LifecycleBoundaryPending)                     { return & $mk 'real' $true 'a lifecycle verdict boundary is pending (human handoff due)' }
    if ($RuntimeWorkTerminalOrAbsent)                  { return & $mk 'real' $true 'known runtime state says the claimed in-flight work is terminal or absent (stale marker)' }
    if ($MessageRequestsUserAction)                    { return & $mk 'real' $true 'the message requests a user decision, authorization, action, or review' }
    if ($AgentBlockedOrHandingBack)                    { return & $mk 'real' $true 'the agent is blocked, failed unrecoverably, or is handing control back' }

    # INTERMEDIATE: owned work is active AND the agent intends to continue AND no contradiction. Exempt from the packet.
    if ($intermediateSignal) { return & $mk 'intermediate' $false 'owned work remains in flight; an operational yield - the agent continues automatically' }

    # Default REAL: no in-flight owned work and no intermediate signal (complete-and-ready, an intentional handoff, or a
    # plain material-work stop). Normal boundary / non-boundary packet enforcement applies.
    return & $mk 'real' $true 'no in-flight owned work and no intermediate signal; a real stop under normal enforcement'
}
