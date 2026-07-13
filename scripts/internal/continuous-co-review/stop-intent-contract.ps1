# FR-045a STOP-INTENT classification (T019 piece 4b; dogfood 2026-07-13, corrected 2026-07-13). Classifies each
# host Stop into THREE outcomes so an authorized workflow is neither stalled nor falsely handed back:
#
#   continue     - authorized, immediately-executable owned work remains for THIS workflow and can proceed NOW;
#                  no human decision/authorization/review/external action, and no required async result pending.
#                  -> SUPPRESS the Stop: no packet, no message; the agent continues the existing workflow.
#   intermediate - authorized work remains AND required owned ASYNC work is still running / awaiting a result;
#                  the agent resumes from that existing work. -> ONE concise, rate-limited progress line + the
#                  marker; no packet, no verdict marker; NEVER launch duplicate work.
#   real         - the requested work is complete/ready to report; a lifecycle boundary; human judgment /
#                  authorization / an external action is required; execution cannot continue after a failure /
#                  timeout; or the agent genuinely, intentionally transfers control. -> existing packet rules.
#
# THE FALSE PREMISE THIS CORRECTS: "no in-flight background work => real stop" is WRONG. Absence of async work
# only means the event is not an async yield; it does NOT create a reason to hand control to the user. And "the
# session is long / context is thin / a natural checkpoint" is an internal implementation concern, NEVER a
# downstream SDLC boundary - context compaction handles session length, so it can never justify `real`.
#
# PURE + DETERMINISTIC. The Stop hook computes the boolean inputs (marker in THIS turn's assistant message, the
# T019 in-flight registry, the pending-verdict state, whether "What Needs Your Review" carries a real decision,
# message heuristics) and this function classifies. NOT a per-host capability matrix: a host with no background
# execution never produces an async signal, so it is only ever `continue` (work remains) or `real`.
#
# MARKER RULES (maintainer correction 2026-07-13): the marker is a portable FALLBACK for host-native async work
# that has NO Specrew registry entry, never sole authority. A marker QUOTED IN USER CONTENT is IGNORED (not a
# signal, and it does NOT independently force `real`). Only an AUTHORITATIVELY-KNOWN-TERMINAL task invalidates a
# stale intermediate marker; an UNKNOWN / UNREGISTERED task does NOT invalidate it (that is what the fallback is
# for). A pending boundary, a required user action, an explicit hand-back, or a known-terminal task override it.

$script:ContinuousCoReviewStopIntentMarker = '<!-- SPECREW-STOP-INTENT: intermediate -->'

function Get-ContinuousCoReviewStopIntentMarker {
    return $script:ContinuousCoReviewStopIntentMarker
}

function Resolve-ContinuousCoReviewStopIntent {
    param(
        # REAL-forcing (a genuine handoff) - any one wins, overriding an intermediate marker:
        [bool]$LifecycleBoundaryPending = $false,   # a lifecycle verdict boundary is pending (a human handoff is due)
        [bool]$UserActionRequired = $false,         # a human decision / authorization / REVIEW / external action is required
                                                    # (a substantive "What Needs Your Review" item sets this)
        [bool]$AgentBlockedOrHandingBack = $false,  # execution cannot continue after a failure/timeout, OR the agent intentionally hands control back
        [bool]$RequestedWorkComplete = $false,      # the requested work is terminal and ready for a final report

        # ASYNC (intermediate) signal:
        [bool]$OwnedWorkInFlight = $false,          # required owned async work is running / awaiting a result (the T019 registry)
        [bool]$MarkerPresent = $false,              # the SPECREW-STOP-INTENT marker is in the assistant's CURRENT-turn message
        [bool]$MarkerFromAssistant = $true,         # that marker is the assistant's own turn, NOT quoted/echoed user content (else IGNORED)
        [bool]$RuntimeWorkKnownTerminal = $false,   # the registry AUTHORITATIVELY knows the referenced task is terminal (invalidates a stale marker);
                                                    # UNKNOWN / UNREGISTERED does NOT set this (the marker remains valid as the fallback)

        # CONTINUE signal:
        [bool]$AuthorizedWorkRemains = $false       # authorized, immediately-executable owned work remains for the CURRENT workflow
                                                    # (already-authorized, not merely a disk task list, and NOT beyond an unapproved boundary)
    )
    $mk = {
        param([string]$outcome, [bool]$enforcePacket, [bool]$emitProgress, [string]$reason)
        [pscustomobject]@{ outcome = $outcome; enforce_packet = $enforcePacket; emit_progress = $emitProgress; reason = $reason }
    }

    # 1. REAL - a pending boundary, a required human/external action (incl. a review request), or an
    #    unrecoverable failure / intentional hand-back. These OVERRIDE any intermediate marker.
    if ($LifecycleBoundaryPending)  { return & $mk 'real' $true $false 'a lifecycle verdict boundary is pending (a human handoff is due)' }
    if ($UserActionRequired)        { return & $mk 'real' $true $false 'a human decision, authorization, review, or external action is required' }
    if ($AgentBlockedOrHandingBack) { return & $mk 'real' $true $false 'execution cannot continue automatically, or the agent intentionally hands control back' }

    # 2. REAL - the requested work is complete/terminal; a final report is due.
    if ($RequestedWorkComplete)     { return & $mk 'real' $true $false 'the requested work is complete and ready for a final report' }

    # 3. INTERMEDIATE - required owned ASYNC work is still in flight. The signal is the registry OR the assistant's
    #    own marker (the fallback for host-native work with no registry entry); a user-content marker is ignored;
    #    an authoritatively-known-terminal task invalidates a stale marker, an unknown/unregistered one does not.
    $assistantMarker = $MarkerPresent -and $MarkerFromAssistant
    $asyncInFlight = ($OwnedWorkInFlight -or $assistantMarker) -and (-not $RuntimeWorkKnownTerminal)
    if ($asyncInFlight) { return & $mk 'intermediate' $false $true 'required owned async work is in flight; a one-line operational yield - the agent resumes when it completes' }

    # 4. CONTINUE - authorized, immediately-executable owned work remains for the current workflow and can proceed
    #    NOW. Suppress the Stop entirely (no packet, no message); the agent continues. Session length / context /
    #    "a natural checkpoint" are NOT reasons to hand back - compaction handles length.
    if ($AuthorizedWorkRemains) { return & $mk 'continue' $false $false 'authorized work remains and can proceed now; suppress the stop and continue the existing workflow' }

    # 5. REAL - nothing to do and nothing pending: an explicit real stop WITH a reason, never an empty handoff.
    return & $mk 'real' $true $false 'no authorized work remains and no async result is pending; an explicit real stop'
}

# FR-045a PACKET CONSISTENCY (maintainer correction 2026-07-13). A real-stop packet's five sections MUST agree on
# whether control has transferred to the user. If "What Needs Your Review" carries a SUBSTANTIVE item (a decision,
# approval request, unresolved tradeoff, or requested confirmation) then it is a review-required real stop: "What
# I Need From You" MUST state the exact requested response, "What Happens Next" MUST say the work is HELD pending
# that response, and the packet MUST NOT say "nothing blocking" / "flag this if…" / "I'll proceed" / otherwise
# auto-continue. An informational note is NOT a review item and must not sit under that section. Returns
# { consistent; reason }.
function Test-ContinuousCoReviewStopPacketConsistency {
    param(
        [bool]$HasSubstantiveReviewItems = $false,      # "What Needs Your Review" contains a real decision/approval/tradeoff/confirmation
        [bool]$NeedsFromUserStatesResponse = $false,    # "What I Need From You" states the EXACT requested response
        [bool]$HappensNextSaysHeld = $false,            # "What Happens Next" says the work is HELD pending that response
        [bool]$SaysNothingRequiredOrWillProceed = $false # the packet says "nothing blocking" / "I'll proceed" / auto-continues
    )
    if (-not $HasSubstantiveReviewItems) {
        # No review request: a completion report, a non-boundary note, or a `continue`/`intermediate` message is fine.
        return [pscustomobject]@{ consistent = $true; reason = $null }
    }
    if ($SaysNothingRequiredOrWillProceed) {
        return [pscustomobject]@{ consistent = $false; reason = 'a substantive review request cannot coexist with "nothing required" / "I''ll proceed" / automatic continuation - a review-required stop transfers control to the user' }
    }
    if (-not $NeedsFromUserStatesResponse) {
        return [pscustomobject]@{ consistent = $false; reason = 'a review request must state the EXACT response needed under "What I Need From You" (never "nothing")' }
    }
    if (-not $HappensNextSaysHeld) {
        return [pscustomobject]@{ consistent = $false; reason = 'a review request must say under "What Happens Next" that the work is HELD pending the response' }
    }
    return [pscustomobject]@{ consistent = $true; reason = $null }
}
