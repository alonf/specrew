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
        # `_load.ps1` does NOT carry worktree-reviewer.ps1, which is where the ONE FR-012 machinery
        # resolver and its source-repo probe live; the predicate under test self-loads it lazily. Load
        # it here explicitly so the fixture asserts against the real resolver rather than depending on
        # whether some earlier assertion happened to trigger that lazy load first.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')

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
                -RepoRoot $script:RepoRoot `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')

            $decision.route | Should -Not -Be 'review-stale'
        }

        It 'a delta containing implementation DOES stale it' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-b'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-b') -Results @($result) `
                -RepoRoot $script:RepoRoot `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md', 'scripts/internal/continuous-co-review/worktree-navigator.ps1')

            $decision.route | Should -Be 'review-stale'
        }

        It 'an unknown delta stales as before (fail closed - absence of evidence is not evidence)' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-c'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-c') -Results @($result) `
                -RepoRoot $script:RepoRoot

            $decision.route | Should -Be 'review-stale'
        }

        It 'an unresolvable repo root stales too (a machinery list is never guessed)' {
            # The defect this pins fell out of the case above it: the predicate used to ask the FR-012
            # machinery resolver with NO root, and a rootless resolver answers with the DEPLOYED-project
            # list - which names scripts/internal/continuous-co-review as machinery. In the Specrew
            # source repo that is the feature under review, so an engine change classified as
            # records-only and a stale review read as current. Fail closed instead of guessing.
            $result = script:New-TerminalResult -RunId 'run-reviewed-f'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-f') -Results @($result) `
                -RepoRoot '' `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')

            $decision.route | Should -Be 'review-stale'
        }

        It 'the SAME engine path IS records-only in a deployed project (the answer belongs to the root)' {
            # The other direction of the identical call, and the reason the fix is "consult the resolver
            # for THIS root" rather than "hardcode the source-repo answer". Where Specrew is DEPLOYED,
            # scripts/internal/continuous-co-review is inert machinery the digest strips, so changing it
            # must not stale a review; in the source repo the very same path is reviewable content.
            $deployed = Join-Path ([IO.Path]::GetTempPath()) ('specrew-deployed-' + [Guid]::NewGuid().ToString('n'))
            $null = New-Item -ItemType Directory -Path $deployed -Force
            try {
                (Test-ContinuousCoReviewSpecrewSourceRepo -RepoRoot $deployed) |
                    Should -BeFalse -Because 'this fixture is only meaningful against a NON-source root'

                Test-ReviewCampaignDeltaIsRecordsOnly -RepoRoot $deployed `
                    -ChangedPaths @('scripts/internal/continuous-co-review/worktree-navigator.ps1') |
                    Should -BeTrue

                Test-ReviewCampaignDeltaIsRecordsOnly -RepoRoot $script:RepoRoot `
                    -ChangedPaths @('scripts/internal/continuous-co-review/worktree-navigator.ps1') |
                    Should -BeFalse -Because 'in the source repo the co-review engine IS the feature under review'
            }
            finally { Remove-Item -LiteralPath $deployed -Recurse -Force -ErrorAction SilentlyContinue }
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
