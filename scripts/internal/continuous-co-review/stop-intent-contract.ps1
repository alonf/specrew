# FR-045a STOP-INTENT classification (T019 piece 4b; dogfood + corrections 2026-07-13). Classifies each host Stop
# into THREE outcomes so an authorized workflow is neither stalled nor falsely handed back:
#
#   continue     - the CURRENT assistant turn declares the `continue` marker AND lifecycle authorization confirms
#                  an already-authorized phase with NO unapproved boundary to cross, AND no async is pending, AND
#                  the message carries no review request / question / completion / blocker / hand-back → SUPPRESS
#                  the Stop (no packet); the agent performs the NEXT authorized action (not another status packet).
#                  MARKER-AND-GATE: neither the marker nor the phase alone suffices — the marker asserts only that
#                  executable work remains; the lifecycle state supplies authorization; work is never self-
#                  authorized across a pending boundary.
#   intermediate - required owned ASYNC work is in flight (the T019 registry, OR the assistant's `intermediate`
#                  marker as the fallback for host-native work with no registry entry) → ONE concise, rate-limited
#                  progress line + the marker; no packet, no verdict marker; NEVER launch duplicate work.
#   real         - a pending boundary, human judgment/authorization/an external action, terminal completion, an
#                  unrecoverable failure, or an intentional hand-back → existing boundary / non-boundary packet.
#
# THE FALSE PREMISE THIS CORRECTS: "no in-flight background work ⇒ real stop" is WRONG. Absence of async work only
# means the event is not an async yield; it does NOT create a reason to hand control to the user. And "the session
# is long / context is thin / a natural checkpoint" is an internal concern, NEVER a boundary — compaction handles
# session length, so it can never justify `real`.
#
# PURE + DETERMINISTIC. The Stop hook computes the boolean inputs (the marker in THIS turn's assistant message via
# Get-ContinuousCoReviewStopIntentMarkerIntent, the lifecycle/authorization gate state, the T019 in-flight
# registry, whether the message carries a review request / completion / hand-back, and the loop-guard counter) and
# this function classifies. NOT a per-host capability matrix: a host with no background execution never produces
# an async signal, so it is only ever `continue` (marker + gate) or `real`.
#
# MARKER RULES: a marker is honoured ONLY as the CURRENT assistant turn's own declaration — a marker quoted in
# USER content or carried from an EARLIER transcript turn is IGNORED (not a signal, and it does NOT force `real`).
# Only an AUTHORITATIVELY-KNOWN-TERMINAL task invalidates a stale `intermediate` marker; an UNKNOWN/UNREGISTERED
# task does not (that is what the fallback is for).
#
# LOOP GUARD: a `continue` requires INTERVENING material progress / changed workflow state between consecutive
# continues. Repeated `continue` markers with neither must not loop forever — after the bounded retry the hook
# trips the guard and this returns a REAL stop (a specific internal-routing failure), never an infinite loop.

$script:ContinuousCoReviewStopIntentContinueMarker = '<!-- SPECREW-STOP-INTENT: continue -->'
$script:ContinuousCoReviewStopIntentIntermediateMarker = '<!-- SPECREW-STOP-INTENT: intermediate -->'

function Get-ContinuousCoReviewStopIntentMarker {
    param([ValidateSet('continue', 'intermediate')][string]$Intent = 'intermediate')
    if ($Intent -eq 'continue') { return $script:ContinuousCoReviewStopIntentContinueMarker }
    return $script:ContinuousCoReviewStopIntentIntermediateMarker
}

# Pure parser: the stop-intent a marker declares in $Text — 'continue' | 'intermediate' | ''. The CALLER passes
# ONLY the current assistant turn's text (never quoted user content / earlier turns); provenance is the hook's
# job. Both markers present ⇒ ambiguous ⇒ '' (fail-closed to no clear intent, so neither continue nor the marker
# async-signal fires).
function Get-ContinuousCoReviewStopIntentMarkerIntent {
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $hasContinue = $Text.Contains($script:ContinuousCoReviewStopIntentContinueMarker)
    $hasIntermediate = $Text.Contains($script:ContinuousCoReviewStopIntentIntermediateMarker)
    if ($hasContinue -and $hasIntermediate) { return '' }
    if ($hasContinue) { return 'continue' }
    if ($hasIntermediate) { return 'intermediate' }
    return ''
}

function Resolve-ContinuousCoReviewStopIntent {
    param(
        # REAL-forcing (precedence 1) — a genuine handoff. Any one wins, overriding a marker.
        [bool]$LifecycleBoundaryPending = $false,   # a lifecycle verdict boundary is pending (a human handoff is due)
        [bool]$UserActionRequired = $false,         # a substantive review request, a user question, or a required external action
        [bool]$AgentBlockedOrHandingBack = $false,  # execution cannot continue (a blocker), or the agent intentionally hands control back
        [bool]$RequestedWorkComplete = $false,      # terminal completion; a final report is due

        # ASYNC / intermediate (precedence 2):
        [bool]$OwnedWorkInFlight = $false,          # required owned async work is running / awaiting a result (the T019 registry)
        [bool]$RuntimeWorkKnownTerminal = $false,   # the registry AUTHORITATIVELY knows the referenced task is terminal (invalidates a stale marker)

        # MARKER — the current assistant turn's declared intent:
        [ValidateSet('', 'continue', 'intermediate')][string]$MarkerIntent = '',
        [bool]$MarkerFromAssistant = $true,         # the marker is the CURRENT assistant turn (else IGNORED: user-quoted / stale)

        # CONTINUE authorization (precedence 3 — the GATE half of marker-and-gate):
        [bool]$AuthorizedWorkRemains = $false,      # lifecycle confirms an already-authorized phase AND no unapproved boundary to cross

        # LOOP GUARD:
        [bool]$ContinueLoopGuardTripped = $false    # repeated continue with no intervening material progress / unchanged workflow → bounded to a real stop
    )
    $mk = {
        param([string]$outcome, [bool]$enforcePacket, [bool]$emitProgress, [string]$reason)
        [pscustomobject]@{ outcome = $outcome; enforce_packet = $enforcePacket; emit_progress = $emitProgress; reason = $reason }
    }

    # A marker counts ONLY as the current assistant turn's own declaration (never user-quoted / stale / earlier turn).
    $effectiveMarker = if ($MarkerFromAssistant) { $MarkerIntent } else { '' }

    # 1. REAL — a pending boundary, a required human/external action, terminal completion, or a failure / hand-back.
    if ($LifecycleBoundaryPending)  { return & $mk 'real' $true $false 'a lifecycle verdict boundary is pending (a human handoff is due)' }
    if ($UserActionRequired)        { return & $mk 'real' $true $false 'a substantive review request, a user question, or a required external action' }
    if ($AgentBlockedOrHandingBack) { return & $mk 'real' $true $false 'execution cannot continue automatically, or the agent intentionally hands control back' }
    if ($RequestedWorkComplete)     { return & $mk 'real' $true $false 'the requested work is complete and ready for a final report' }

    # 2. INTERMEDIATE — required owned ASYNC work in flight (the registry OR the assistant's `intermediate` marker),
    #    unless authoritatively known-terminal. Async takes precedence over continue.
    $asyncInFlight = ($OwnedWorkInFlight -or ($effectiveMarker -eq 'intermediate')) -and (-not $RuntimeWorkKnownTerminal)
    if ($asyncInFlight) { return & $mk 'intermediate' $false $true 'required owned async work is in flight; a one-line operational yield - the agent resumes when it completes' }

    # 3. CONTINUE — MARKER-AND-GATE: the current-assistant `continue` marker AND confirmed authorization (neither
    #    alone). The loop guard bounds repeated no-progress continues to a real routing failure.
    if (($effectiveMarker -eq 'continue') -and $AuthorizedWorkRemains) {
        if ($ContinueLoopGuardTripped) {
            return & $mk 'real' $true $false 'continue-loop-guard tripped: repeated continue with no intervening material progress / unchanged workflow - an internal routing failure surfaced as a real stop'
        }
        return & $mk 'continue' $false $false 'the current assistant turn declares continue AND lifecycle authorization confirms remaining in-phase work; suppress the stop and perform the next authorized action'
    }

    # 4. Otherwise → normal real-stop enforcement, with an explicit reason (never an empty handoff).
    return & $mk 'real' $true $false 'no current-turn continue marker with authorization, no async in flight, and no other trigger; normal real-stop enforcement applies'
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
