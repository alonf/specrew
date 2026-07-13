$ErrorActionPreference = 'Stop'

# FR-045a STOP-INTENT (T019 piece 4b, MARKER-AND-GATE model 2026-07-13). `continue` requires BOTH a current-turn
# continue marker AND lifecycle authorization (neither alone); `intermediate` is async-in-flight; `real` is
# everything else. Covers the maintainer's 10 required behaviours + the marker parser + packet consistency.
Describe 'FR-045a Stop-intent classifier (marker-and-gate: continue | intermediate | real)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/stop-intent-contract.ps1')
    }

    It 'marker + authorized same-phase work -> CONTINUE (suppress; no packet, no message)' {
        $r = Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -MarkerFromAssistant $true -AuthorizedWorkRemains $true
        $r.outcome | Should -Be 'continue'; $r.enforce_packet | Should -BeFalse; $r.emit_progress | Should -BeFalse
    }
    It 'marker WITHOUT gate authorization -> real (marker-and-gate: the marker alone cannot self-authorize)' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -MarkerFromAssistant $true -AuthorizedWorkRemains $false).outcome | Should -Be 'real'
    }
    It 'authorization WITHOUT the marker -> normal real-stop handling (the phase alone does not prove work remains)' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent '' -AuthorizedWorkRemains $true).outcome | Should -Be 'real'
    }
    It 'marker at a pending boundary -> real (never self-authorize across a boundary)' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true -LifecycleBoundaryPending $true).outcome | Should -Be 'real'
    }
    It 'marker + a review request / user question -> real' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true -UserActionRequired $true).outcome | Should -Be 'real'
    }
    It 'marker + terminal completion -> real' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true -RequestedWorkComplete $true).outcome | Should -Be 'real'
    }
    It 'intermediate in-flight work takes PRECEDENCE over continue' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true -OwnedWorkInFlight $true).outcome | Should -Be 'intermediate'
    }
    It 'a user-quoted / stale marker is IGNORED (not the current assistant turn) -> real' {
        (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -MarkerFromAssistant $false -AuthorizedWorkRemains $true).outcome | Should -Be 'real'
    }
    It 'repeated no-progress continuation is BOUNDED — the loop guard trips to a real routing failure' {
        $r = Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true -ContinueLoopGuardTripped $true
        $r.outcome | Should -Be 'real'; $r.reason | Should -Match 'loop-guard'
    }
    It 'successful continuation is packet-free (enforce_packet + emit_progress both false)' {
        $r = Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'continue' -AuthorizedWorkRemains $true
        $r.enforce_packet | Should -BeFalse; $r.emit_progress | Should -BeFalse
    }

    Context 'intermediate + marker parser + known-terminal' {
        It 'the assistant intermediate marker alone -> intermediate (the async fallback)' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'intermediate' -MarkerFromAssistant $true).outcome | Should -Be 'intermediate'
        }
        It 'an authoritatively KNOWN-TERMINAL task invalidates a stale intermediate marker -> real' {
            (Resolve-ContinuousCoReviewStopIntent -MarkerIntent 'intermediate' -MarkerFromAssistant $true -RuntimeWorkKnownTerminal $true).outcome | Should -Be 'real'
        }
        It 'the marker parser reads the current-turn intent; ambiguous both-markers -> empty' {
            Get-ContinuousCoReviewStopIntentMarkerIntent -Text ("work continues`n" + (Get-ContinuousCoReviewStopIntentMarker -Intent 'continue')) | Should -Be 'continue'
            Get-ContinuousCoReviewStopIntentMarkerIntent -Text (Get-ContinuousCoReviewStopIntentMarker -Intent 'intermediate') | Should -Be 'intermediate'
            Get-ContinuousCoReviewStopIntentMarkerIntent -Text 'no marker here' | Should -Be ''
            Get-ContinuousCoReviewStopIntentMarkerIntent -Text ((Get-ContinuousCoReviewStopIntentMarker -Intent 'continue') + (Get-ContinuousCoReviewStopIntentMarker -Intent 'intermediate')) | Should -Be ''
        }
        It 'exposes both marker strings' {
            Get-ContinuousCoReviewStopIntentMarker -Intent 'continue' | Should -Be '<!-- SPECREW-STOP-INTENT: continue -->'
            Get-ContinuousCoReviewStopIntentMarker -Intent 'intermediate' | Should -Be '<!-- SPECREW-STOP-INTENT: intermediate -->'
        }
    }
}

Describe 'FR-045a packet consistency (a review request => a coherent real handoff)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/stop-intent-contract.ps1')
    }
    It 'substantive review items + "nothing required" / "I''ll proceed" -> INCONSISTENT' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -SaysNothingRequiredOrWillProceed $true).consistent | Should -BeFalse
    }
    It 'review items with NO stated response under "What I Need From You" -> inconsistent' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $false -HappensNextSaysHeld $true).consistent | Should -BeFalse
    }
    It 'review items whose "What Happens Next" does NOT say the work is held -> inconsistent' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $true -HappensNextSaysHeld $false).consistent | Should -BeFalse
    }
    It 'review items that state the response AND say work is HELD -> consistent' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $true -NeedsFromUserStatesResponse $true -HappensNextSaysHeld $true -SaysNothingRequiredOrWillProceed $false).consistent | Should -BeTrue
    }
    It 'no review items -> consistent even with "nothing required" (a completion report / continue / note)' {
        (Test-ContinuousCoReviewStopPacketConsistency -HasSubstantiveReviewItems $false -SaysNothingRequiredOrWillProceed $true).consistent | Should -BeTrue
    }
}
