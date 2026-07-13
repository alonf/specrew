$ErrorActionPreference = 'Stop'

# FR-045a STOP-INTENT (T019 piece 4b, corrected 2026-07-13). The THREE-outcome classifier (continue | intermediate
# | real) + the packet-consistency validator. Covers the maintainer's required behaviours: the false premise
# ("no async work => real") is gone - authorized remaining work is `continue`, not a handoff; a review request or
# a pending boundary is `real`; required async is `intermediate`; a user-content marker is ignored; only a KNOWN-
# terminal task invalidates a stale marker; and a review-required packet whose sections contradict fails validation.
Describe 'FR-045a Stop-intent classifier (continue | intermediate | real)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/stop-intent-contract.ps1')
    }

    It '1. authorized, immediately-executable work -> CONTINUE (suppress the stop; no packet, no message)' {
        $r = Resolve-ContinuousCoReviewStopIntent -AuthorizedWorkRemains $true
        $r.outcome | Should -Be 'continue'; $r.enforce_packet | Should -BeFalse; $r.emit_progress | Should -BeFalse
    }
    It '2. a clean commit with authorized remaining work does NOT create a real stop (continue)' {
        # There is no "just committed" input; a clean commit is not a boundary. Authorized work remains -> continue.
        (Resolve-ContinuousCoReviewStopIntent -AuthorizedWorkRemains $true).outcome | Should -Be 'continue'
    }
    It '3. "session long / context thin / a natural checkpoint" cannot force real - there is no such input; work remains -> continue' {
        (Resolve-ContinuousCoReviewStopIntent -AuthorizedWorkRemains $true).outcome | Should -Be 'continue'
    }
    It '4. required owned async work -> INTERMEDIATE (a one-line yield)' {
        $r = Resolve-ContinuousCoReviewStopIntent -OwnedWorkInFlight $true -AuthorizedWorkRemains $true
        $r.outcome | Should -Be 'intermediate'; $r.emit_progress | Should -BeTrue; $r.enforce_packet | Should -BeFalse
    }
    It '5. a pending lifecycle boundary OVERRIDES both continue and intermediate (real)' {
        (Resolve-ContinuousCoReviewStopIntent -LifecycleBoundaryPending $true -AuthorizedWorkRemains $true -OwnedWorkInFlight $true).outcome | Should -Be 'real'
    }
    It '6. required human judgment / authorization / review -> real' {
        (Resolve-ContinuousCoReviewStopIntent -UserActionRequired $true -AuthorizedWorkRemains $true).outcome | Should -Be 'real'
    }
    It '7. terminal requested-work completion -> real (a final report is due)' {
        (Resolve-ContinuousCoReviewStopIntent -RequestedWorkComplete $true).outcome | Should -Be 'real'
    }
    It '8. a failure the agent can REPAIR automatically stays CONTINUE (not blocked -> work remains)' {
        (Resolve-ContinuousCoReviewStopIntent -AuthorizedWorkRemains $true -AgentBlockedOrHandingBack $false).outcome | Should -Be 'continue'
    }
    It '9. a failure REQUIRING human action -> real' {
        (Resolve-ContinuousCoReviewStopIntent -AgentBlockedOrHandingBack $true -AuthorizedWorkRemains $true).outcome | Should -Be 'real'
    }
    It '12. existing boundary-authorization behaviour unchanged: a pending boundary is real regardless of remaining work' {
        (Resolve-ContinuousCoReviewStopIntent -LifecycleBoundaryPending $true).outcome | Should -Be 'real'
    }

    Context 'marker corrections (2026-07-13)' {
        It 'the assistant marker alone (no registry entry) is a valid async signal -> intermediate (the fallback works)' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $true).outcome | Should -Be 'intermediate'
        }
        It 'a marker QUOTED IN USER CONTENT is IGNORED - not a signal AND does not force real (work remains -> continue)' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $false -AuthorizedWorkRemains $true).outcome | Should -Be 'continue'
        }
        It 'UNKNOWN / UNREGISTERED work does NOT invalidate the marker (still intermediate)' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $true -RuntimeWorkKnownTerminal $false).outcome | Should -Be 'intermediate'
        }
        It 'an authoritatively KNOWN-TERMINAL task invalidates a stale marker -> continue when work remains' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $true -RuntimeWorkKnownTerminal $true -AuthorizedWorkRemains $true).outcome | Should -Be 'continue'
        }
        It 'nothing to do and nothing pending -> an explicit real stop (never an empty handoff)' {
            $r = Resolve-ContinuousCoReviewStopIntent
            $r.outcome | Should -Be 'real'; $r.reason | Should -Match 'explicit real stop'
        }
    }
}

Describe 'FR-045a packet consistency (a review request => a coherent real handoff)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/stop-intent-contract.ps1')
    }
    It 'substantive review items + "nothing required" / "I''ll proceed" -> INCONSISTENT (fails validation)' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -SaysNothingRequiredOrWillProceed $true).consistent | Should -BeFalse
    }
    It 'review items with NO stated response under "What I Need From You" -> inconsistent' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $false -HappensNextSaysHeld $true).consistent | Should -BeFalse
    }
    It 'review items with a response that does NOT say the work is held -> inconsistent' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $true -HappensNextSaysHeld $false).consistent | Should -BeFalse
    }
    It 'review items that state the response AND say work is HELD -> consistent (a clean review-required stop)' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $true -HappensNextSaysHeld $true -SaysNothingRequiredOrWillProceed $false).consistent | Should -BeTrue
    }
    It 'no review items -> consistent (a completion report / continue / note is fine even with "nothing required")' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $false -SaysNothingRequiredOrWillProceed $true).consistent | Should -BeTrue
    }
    It 'exposes the portable marker string for the hook + the canonical instruction' {
        Get-ContinuousCoReviewStopIntentMarker | Should -Be '<!-- SPECREW-STOP-INTENT: intermediate -->'
    }
}
