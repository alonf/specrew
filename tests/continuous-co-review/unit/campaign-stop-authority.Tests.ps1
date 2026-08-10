$ErrorActionPreference = 'Stop'

# Trace: T003 / FR-007, FR-008, FR-009 / SC-003.
#
# The single-authority stop surface. Every case here was reproduced LIVE during this feature rather
# than imagined, which is why the shapes are specific:
#
#   FR-008  DRIFT-199-I001-011: a run holding requested.json + reserved.json and NO result.json -
#           reserved and in flight - coexisted with a surface telling the implementer to REQUEST a
#           review. The classifier already has a review-running route; it simply did not match this
#           shape. The maintainer narrowed the work accordingly: make the EXISTING route recognise
#           it, do not add a second notion of in-flight.
#   FR-009  DRIFT-199-I001-013: a commit whose entire content was this feature's own drift log
#           flipped the surface to review-stale. Writing down what a review found invalidated that
#           review.
#   FR-007  T067's two-governor collision: the signoff gate said allow while the campaign surface
#           said blocked, and an agent had to adjudicate - which a consumer cannot do.
#   Pause   A pending pause on the CURRENT tree is a sanctioned quiet state; a superseded one is not.
Describe 'Single-authority stop surface (T003)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        $script:Digest = 'a1b2c3d4e5f60718293a4b5c6d7e8f9012345678'

        function script:New-TerminalResult {
            param([string]$RunId, [string]$Digest = $script:Digest, [string]$Outcome = 'completed')
            return [pscustomobject]@{
                schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = $RunId
                target_digest = $Digest; harness_id = 'codex-cli-file-primary'
                completion = 'complete'; verdict = 'pass'; runtime_outcome = $Outcome
                termination_verified = $true; containment = 'verified'; currentness = 'current'
                validation = 'valid'; can_approve_current = $true; failure_reason = $null
                summary = 'ok'; findings = @()
                started_at = '2026-08-10T10:00:00Z'; ended_at = '2026-08-10T10:05:00Z'; duration_ms = 300000
            }
        }
    }

    Context 'FR-008: an authorized in-flight run suppresses the block' {
        It 'a RESERVED, non-terminal run routes to review-running, never review-required' {
            $activeRun = [pscustomobject]@{
                schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = 'run-inflight-a'
                target_digest = $script:Digest; harness_id = 'codex-cli-file-primary'; state = 'reserved'
            }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @() -Results @() -ActiveRun $activeRun

            $decision.route | Should -Be 'review-running'
            $decision.implementer_action | Should -Be 'poll-existing-run'
        }

        It 'a reserved run targeting a DIFFERENT tree does not suppress (it cannot authorize this one)' {
            $activeRun = [pscustomobject]@{
                schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = 'run-inflight-b'
                target_digest = ('b' * 40); harness_id = 'codex-cli-file-primary'; state = 'reserved'
            }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @() -Results @() -ActiveRun $activeRun

            $decision.route | Should -Not -Be 'review-running'
        }
    }

    Context 'FR-009: governance and records deltas never stale a reviewed state' {
        It 'a records-only delta leaves a passing result current' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-a'
            # The tree moved, but only under the lifecycle records tree.
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-a') -Results @($result) `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')

            $decision.route | Should -Not -Be 'review-stale'
        }

        It 'a delta containing implementation DOES stale it' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-b'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-b') -Results @($result) `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md', 'scripts/internal/continuous-co-review/worktree-navigator.ps1')

            $decision.route | Should -Be 'review-stale'
        }

        It 'an unknown delta stales as before (fail closed - absence of evidence is not evidence)' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-c'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-c') -Results @($result)

            $decision.route | Should -Be 'review-stale'
        }
    }

    Context 'FR-007: the recorded gate decision is consulted, never contradicted' {
        It 'a recorded ALLOW is not overridden by the campaign surface' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-d'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-d') -Results @($result) `
                -SignoffGateDecision ([pscustomobject]@{ decision = 'allow'; reviewed_digest = ('c' * 40) })

            $decision.route | Should -Not -Be 'review-stale'
            $decision.reason | Should -Match 'signoff-gate'
        }

        It 'a gate decision for a DIFFERENT tree does not confer anything' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-e'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-e') -Results @($result) `
                -SignoffGateDecision ([pscustomobject]@{ decision = 'allow'; reviewed_digest = ('d' * 40) })

            $decision.route | Should -Be 'review-stale'
        }
    }

    Context 'the pending pause is a sanctioned quiet state' {
        It 'a pause on the CURRENT tree quiets the surface' {
            $pause = [pscustomobject]@{ run_id = 'run-paused-a'; target_digest = $script:Digest }
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @() -Results @() -PendingPause $pause

            $decision.route | Should -Be 'pause-pending'
            $decision.implementer_action | Should -Be 'await-human-pause-decision'
        }

        It 'a SUPERSEDED pause confers nothing (it describes a tree that moved on)' {
            $pause = [pscustomobject]@{ run_id = 'run-paused-b'; target_digest = ('e' * 40) }
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @() -Results @() -PendingPause $pause

            $decision.route | Should -Not -Be 'pause-pending'
        }
    }
}
