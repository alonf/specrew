$ErrorActionPreference = 'Stop'

# Trace: T003 / FR-007 / SC-003.
#
# THE COLLISION, captured live at a real gate on 2026-08-10 and again on 2026-08-11: one stop
# produced two contradictory instructions at the same moment.
#
#   Governor A (the boundary evidence gate, controller truth): a crossing is recorded and pending,
#       and the stop must carry its verdict marker or the human's answer cannot be captured at all.
#   Governor B (the campaign review block): "(Campaign review block, not a lifecycle verdict - do
#       NOT emit a SPECREW-VERDICT-BOUNDARY marker.)" - emitted UNCONDITIONALLY, with no knowledge
#       of whether a crossing exists.
#
# An agent adjudicated it by reasoning about which governor's clause described itself. That is
# exactly the ledger's F5 failure: a CONSUMER could not have made that call, and the two readings
# differ on whether the human can authorize anything at all. Under B winning, a recorded crossing
# becomes unanswerable - the marker is suppressed, the verdict cannot be captured, and the lifecycle
# wedges on a review the human may not even owe yet.
#
# MAINTAINER RULING (2026-08-10, recorded in drift-log.md): the recorded crossing WINS. Controller
# truth naming an exact pending authorization outranks the campaign block's no-marker clause, which
# governs ITSELF - it describes what the campaign block is, not what the lifecycle owes.
#
# What these cases pin is NOT "the agent chose right". It is that the block STATES the adjudication,
# so no judgement is left at the surface.
Describe 'Two-governor adjudication: a recorded crossing outranks the campaign no-marker clause (T003/FR-007)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        # The stop-block builder lives in the legacy navigator module, which `_load.ps1` does not carry.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        # Feature 203 T008 (DRIFT-052 item 6; maintainer classification 2026-11-09, class B): the per-route navigator block is
        # gone. A review stop is the human's block now (Format-ReviewCampaignStopSurface) with the agent's half beside it
        # (Build-ReviewCampaignStopAgentDirective). The adjudication is the same, checked on those two.
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
        $script:Stop = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-beta3-stabilization-i001' -RunId 'run-20260810-085753967-af5bef76' `
            -TargetDigest ('a' * 40) -Decision $decision -ObservedAt '2026-08-10T08:05:00Z' -StopKind 'c-judgment' -StopReason 'ask'
        $script:Stop | Add-Member -NotePropertyName recommendation -NotePropertyValue 'should the retry cap count per host or per campaign?' -Force
        function script:Get-HumanBlock([AllowNull()]$Crossing) {
            return (@(Format-ReviewCampaignStopSurface -Stop $script:Stop -OpenFindings @() -PendingCrossing $Crossing) -join "`n")
        }

        # The shape is transcribed from this repository's own .specrew/start-context.json rather than
        # invented, so the fixture cannot pass against a crossing shape the controller never writes.
        function script:New-PendingCrossing {
            param([string]$To = 'review-signoff', [string]$From = 'before-implement')
            return [pscustomobject]@{
                crossing_id = 'crossing-9b3d255e'
                from_boundary = $From
                to_boundary = $To
                working_boundary = $To
                boundary_commit_hash = '8ed3313d1ec114e33e1696e37e937649ed57afbb'
                artifact_state_kind = 'git-tree'
                artifact_state_id = '6886b43d7138d0a505c64a847f21a7c98d94f156'
                recorded_at = '2026-08-10T08:02:26Z'
            }
        }
    }

    Context 'with no recorded crossing the block is unchanged' {
        It 'still carries the blanket no-marker clause (nothing to adjudicate against)' {
            # The pre-existing guarantee, restated here so the adjudication below can never be read as permission to emit
            # markers generally. MOVED 2026-08-11 (T010, emission-point rule): the no-marker clause is an AGENT directive.
            Build-ReviewCampaignStopAgentDirective -PendingCrossing $null | Should -Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
            script:Get-HumanBlock -Crossing $null | Should -Not -Match '(?i)approval you still owe' -Because 'with no crossing there is nothing to defer to'
        }
    }

    Context 'with a recorded crossing the block scopes itself instead of suppressing the marker' {
        It 'does NOT instruct blanket marker suppression' {
            Build-ReviewCampaignStopAgentDirective -PendingCrossing (script:New-PendingCrossing) | Should -Not -Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
            script:Get-HumanBlock -Crossing (script:New-PendingCrossing) | Should -Not -Match 'SPECREW-VERDICT-BOUNDARY' -Because 'the marker clause is never the human''s to read'
        }

        It 'names the crossing it is deferring to, so the adjudication is readable rather than inferred' {
            # MOVED 2026-08-11 (T010). The human is told which approval is still theirs, in boundary names they can act on; the
            # identifier travels on the agent channel, where it is the thing being matched. Fix 5 (maintainer classification
            # 2026-11-09): the stop block says it does not decide that approval.
            $block = script:Get-HumanBlock -Crossing (script:New-PendingCrossing)
            $block | Should -Match 'before-implement'
            $block | Should -Match 'review-signoff'
            $block | Should -Match '(?i)does not decide'
            $block | Should -Not -Match 'crossing-9b3d255e' -Because 'the identifier is noise to a reader'
            Build-ReviewCampaignStopAgentDirective -PendingCrossing (script:New-PendingCrossing) | Should -Match 'crossing-9b3d255e'
        }

        It 'still states its own review position - deferring on the marker is not withdrawing the block' {
            # The stop does not evaporate because a crossing exists: it still states why it stopped and the decision it needs.
            $block = script:Get-HumanBlock -Crossing (script:New-PendingCrossing)
            $block | Should -Match 'Specrew review stopped'
            $block | Should -Match 'Why: the crew needs your judgment'
            $block | Should -Match 'Your decision: '
            $block | Should -Not -Match 'c-judgment' -Because 'the position must be stated in words the reader can act on'
        }
    }

    Context 'fail closed: only a well-formed crossing outranks the clause' {
        It 'a crossing missing its destination confers nothing' {
            # Absence of evidence is not evidence. A half-written crossing must not unlock a marker.
            $partial = script:New-PendingCrossing
            $partial.to_boundary = ''
            $partial.working_boundary = ''
            Build-ReviewCampaignStopAgentDirective -PendingCrossing $partial | Should -Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
            script:Get-HumanBlock -Crossing $partial | Should -Not -Match '(?i)approval you still owe'
        }

        It 'a null crossing confers nothing' {
            Build-ReviewCampaignStopAgentDirective -PendingCrossing $null | Should -Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
        }
    }
}
