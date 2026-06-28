#requires -Version 7.0
# F-197 co-review ESCALATION-LATCH — the adversarial safety gate (write FIRST).
#
# The latch lets a HUMAN close a co-review escalation so the navigator stops re-firing/re-blocking it. The whole
# safety question is: can the AGENT close it? It must not. `Test-ContinuousCoReviewEscalationHumanClosed` answers
# "has a human authorized closing THIS escalation?" by reading ONLY user-role turns from the real transcript,
# AFTER the escalation was surfaced. The agent authors assistant turns and files — never a user turn — so it
# cannot forge a closure.
#
# Case (b) is the entire line between the feature and its inversion (a co-review silencer). If (b) ever goes red,
# DO NOT SHIP the latch.

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' '..' 'scripts/internal/continuous-co-review/escalation-latch.ps1')
    $script:T0 = '2026-06-28T20:00:00Z'   # escalation surfaced here
    function script:Turn([string]$role, [string]$text, [string]$ts) { [pscustomobject]@{ role = $role; text = $text; timestamp = $ts } }
    function script:Finding([string]$severity, [string]$kind) { [pscustomobject]@{ severity = $severity; kind = $kind } }
}

Describe 'Escalation latch — only a real human transcript turn can close (the safety gate)' {

    It '(a) a USER authorization AFTER surfacing closes it' {
        $turns = @(
            script:Turn 'assistant' '[co-review] BLOCKING escalation — human decision needed' '2026-06-28T20:00:01Z'
            script:Turn 'user' 'Authorise, the most important is that the usage experience is smooth' '2026-06-28T20:05:00Z'
        )
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeTrue
    }

    It '(a2) smooth natural replies also close ("accept" / "approved" / "go ahead")' {
        foreach ($word in @('accept', 'approved', 'go ahead', 'defer it')) {
            $turns = @(script:Turn 'user' "yes, $word" '2026-06-28T20:05:00Z')
            Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeTrue -Because "'$word' is a clear human authorization"
        }
    }

    It '(b) THE SAFETY GATE — an ASSISTANT turn claiming the human authorized does NOT close it' {
        $turns = @(
            script:Turn 'assistant' '[co-review] BLOCKING escalation — human decision needed' '2026-06-28T20:00:01Z'
            script:Turn 'assistant' 'The maintainer explicitly authorized option (c); recording it as resolved (human decision).' '2026-06-28T20:05:00Z'
        )
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse -Because 'the agent authors assistant turns; it must NOT be able to self-close an escalation'
    }

    It '(b2) THE SAFETY GATE — no user turn at all (only the agent loud-asserting in-band) does NOT close it' {
        $turns = @(script:Turn 'assistant' 'Authorise — authorized — accept — approved (agent text spamming the keywords)' '2026-06-28T20:05:00Z')
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse -Because 'keyword spam in an ASSISTANT turn is exactly the forgery the latch must reject'
    }

    It '(c) a stale human authorization from BEFORE the escalation does NOT close it' {
        $turns = @(
            script:Turn 'user' 'authorise the plan' '2026-06-28T19:00:00Z'   # before T0
            script:Turn 'assistant' '[co-review] BLOCKING escalation — human decision needed' '2026-06-28T20:00:01Z'
        )
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse -Because 'closure must be a fresh decision about THIS escalation, not a prior unrelated approval'
    }

    It '(c2) an unrelated/non-authorizing user reply after surfacing does NOT close it' {
        $turns = @(script:Turn 'user' 'what is the status? can you check?' '2026-06-28T20:05:00Z')
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse
    }

    It '(c3) an explicit human REFUSAL after surfacing does NOT close it (negation guard)' {
        foreach ($neg in @('do not authorise this', "don't accept it", 'no, reject the deferral')) {
            $turns = @(script:Turn 'user' $neg '2026-06-28T20:05:00Z')
            Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse -Because "a refusal ('$neg') must keep blocking, never close"
        }
    }

    It '(d) no turns at all -> stays blocking (default-deny)' {
        Test-ContinuousCoReviewEscalationHumanClosed -SurfacedAtUtc $script:T0 -ConversationTurns @() | Should -BeFalse
    }
}

Describe 'Escalation stop-block wrapper — escalation-only scope keeps the latch from silencing real bugs (case c)' {

    It '(a) escalation-only block + a human close -> suppress' {
        $turns = @(script:Turn 'user' 'accept' '2026-06-28T20:05:00Z')
        $findings = @(script:Finding 'blocking' 'escalation')
        Test-ContinuousCoReviewEscalationStopBlockClosed -BlockingFindings $findings -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeTrue
    }

    It '(b) escalation-only block + only an AGENT claim -> still blocks' {
        $turns = @(script:Turn 'assistant' 'the human authorized; accept' '2026-06-28T20:05:00Z')
        $findings = @(script:Finding 'blocking' 'escalation')
        Test-ContinuousCoReviewEscalationStopBlockClosed -BlockingFindings $findings -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse
    }

    It '(c) THE SCOPE GATE — a real BUG finding is NEVER closeable by "accept" (kind != escalation)' {
        $turns = @(script:Turn 'user' 'accept' '2026-06-28T20:05:00Z')
        $findings = @(script:Finding 'blocking' 'bug')
        Test-ContinuousCoReviewEscalationStopBlockClosed -BlockingFindings $findings -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse -Because 'the latch must NEVER silence a real bug — only the human-decision escalation it is scoped to'
    }

    It '(c2) a MIXED block (escalation + a bug) keeps blocking — the bug protects the whole block' {
        $turns = @(script:Turn 'user' 'accept' '2026-06-28T20:05:00Z')
        $findings = @((script:Finding 'blocking' 'escalation'), (script:Finding 'blocking' 'bug'))
        Test-ContinuousCoReviewEscalationStopBlockClosed -BlockingFindings $findings -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse
    }

    It '(d) no blocking findings -> nothing to close' {
        $turns = @(script:Turn 'user' 'accept' '2026-06-28T20:05:00Z')
        Test-ContinuousCoReviewEscalationStopBlockClosed -BlockingFindings @() -SurfacedAtUtc $script:T0 -ConversationTurns $turns | Should -BeFalse
    }
}
