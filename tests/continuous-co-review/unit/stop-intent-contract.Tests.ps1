$ErrorActionPreference = 'Stop'

# FR-045a STOP-INTENT classification (T019 piece 4b). The PURE, deterministic classifier that distinguishes an
# INTERMEDIATE stop (an operational yield while Specrew-owned work is in flight and the agent continues) from a
# REAL stop (a genuine handoff). Contradictions (a pending boundary, terminal/absent runtime work, a user-action
# request, a hand-back, a user-sourced marker) force REAL. These cover the PURE-LOGIC subset of the 13 required
# behaviours; the hook-wiring + host-parity subset (no duplicate work, completion resumes, surface parity) lives
# in the runtime-wiring tests once the classifier is wired into the Stop hook.
Describe 'FR-045a Stop-intent classifier (intermediate vs real)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/stop-intent-contract.ps1')
    }

    It '1. known owned work in flight + no user need -> intermediate (a one-line progress message)' {
        $r = Resolve-ContinuousCoReviewStopIntent -OwnedWorkInFlight $true
        $r.intent | Should -Be 'intermediate'; $r.enforce_packet | Should -BeFalse
    }
    It '2. the explicit marker works when NO runtime registration is available' {
        $r = Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $true -OwnedWorkInFlight $false
        $r.intent | Should -Be 'intermediate'
    }
    It '3. an intermediate stop does NOT require the five-part packet (enforce_packet is false)' {
        (Resolve-ContinuousCoReviewStopIntent -OwnedWorkInFlight $true).enforce_packet | Should -BeFalse
    }
    It '7. a pending lifecycle boundary OVERRIDES the intermediate marker (real)' {
        $r = Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -OwnedWorkInFlight $true -LifecycleBoundaryPending $true
        $r.intent | Should -Be 'real'; $r.enforce_packet | Should -BeTrue
    }
    It '8. a message asking the user a question is REAL even with the marker' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -OwnedWorkInFlight $true -MessageRequestsUserAction $true).intent | Should -Be 'real'
    }
    It '9. a terminal/absent registered task contradicts + invalidates the marker (real)' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -RuntimeWorkTerminalOrAbsent $true).intent | Should -Be 'real'
    }
    It '10. failure/timeout requiring human action -> real (even while other work is in flight)' {
        (Resolve-ContinuousCoReviewStopIntent -OwnedWorkInFlight $true -AgentBlockedOrHandingBack $true).intent | Should -Be 'real'
    }
    It '11. final successful completion is REAL, not intermediate (no in-flight signal; a stale marker cannot override terminal runtime state)' {
        (Resolve-ContinuousCoReviewStopIntent -OwnedWorkInFlight $false).intent | Should -Be 'real'
        (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -RuntimeWorkTerminalOrAbsent $true).intent | Should -Be 'real'
    }
    It '12. no work in flight -> real, and the material-work packet stays enforced' {
        $r = Resolve-ContinuousCoReviewStopIntent
        $r.intent | Should -Be 'real'; $r.enforce_packet | Should -BeTrue
    }
    It 'a marker sourced from USER content (not the assistant turn) is not authority -> real' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerPresent $true -MarkerFromAssistant $false -OwnedWorkInFlight $false).intent | Should -Be 'real'
    }
    It 'exposes the portable marker string for the hook + the canonical instruction' {
        Get-ContinuousCoReviewStopIntentMarker | Should -Be '<!-- SPECREW-STOP-INTENT: intermediate -->'
    }
}
