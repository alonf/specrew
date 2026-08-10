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
                -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
                -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')

            $decision.route | Should -Not -Be 'review-stale'
        }

        It 'a delta containing implementation DOES stale it' {
            $result = script:New-TerminalResult -RunId 'run-reviewed-b'
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest ('c' * 40) -OrderedRunIds @('run-reviewed-b') -Results @($result) `
                -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
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

        It 'INPUT to a review stales it; OUTPUT of a review does not (maintainer ruling 2026-08-10)' {
            # The distinction is NOT the directory. An artifact is either INPUT TO a review - the standard the
            # code was judged against - or OUTPUT OF one. Changing an input changes what the review CONCLUDED
            # even though no code moved, so it must stale. Changing an output cannot invalidate the review that
            # produced it; saying otherwise is circular, and that circularity is DRIFT-199-I001-013 itself.
            $feature = '199-beta3-stabilization'
            $root = "specs/$feature"

            $reviewOutputs = @(
                "$root/iterations/001/drift-log.md"
                "$root/iterations/001/state.md"
                "$root/iterations/001/tasks-progress.yml"
                "$root/iterations/001/review.md"
                "$root/iterations/001/coverage-evidence.md"
                "$root/iterations/001/retro.md"
                "$root/iterations/001/quality/hardening-gate.md"
                "$root/iterations/001/checklists/security.md"
                "$root/workshop/architecture-core.md"
            )
            foreach ($path in $reviewOutputs) {
                Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @($path) -RepoRoot $script:RepoRoot -FeatureId $feature |
                    Should -BeTrue -Because "$path is a record of the process, not the standard the code was judged against"
            }

            $reviewInputs = @(
                "$root/spec.md"
                "$root/plan.md"
                "$root/tasks.md"
                "$root/iterations/001/plan.md"
                "$root/iterations/001/design-analysis.md"
                "$root/contracts/api.md"
                "$root/data-model.md"
                "$root/quickstart.md"
                "$root/iterations/001/research/t007-notes.md"
            )
            foreach ($path in $reviewInputs) {
                Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @($path) -RepoRoot $script:RepoRoot -FeatureId $feature |
                    Should -BeFalse -Because "$path is the standard the code was judged against; moving it changes what the review concluded"
            }
        }

        It 'another feature''s records tree is ordinary content to THIS campaign' {
            # The narrowing the recorded requirement already named. Only the ACTIVE feature's process records
            # are exempt; a different feature's tree has no special standing here.
            Test-ReviewCampaignDeltaIsRecordsOnly -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
                -ChangedPaths @('specs/198-beta2-hardening/iterations/009/drift-log.md') | Should -BeFalse

            # ...and with no active feature resolved, nothing under specs/ qualifies (fail closed).
            Test-ReviewCampaignDeltaIsRecordsOnly -RepoRoot $script:RepoRoot -FeatureId '' `
                -ChangedPaths @('specs/199-beta3-stabilization/iterations/001/drift-log.md') | Should -BeFalse
        }

        It 'an unlisted artifact stales - the allowlist fails toward NAGGING, never toward silence' {
            # Why an enumeration is acceptable HERE and was rejected for the class guards: an allowlist's
            # omission asks for a review that may not be owed, while a blocklist's omission lets a real change
            # slip past one. Only the first is recoverable, so an unknown artifact must stale.
            Test-ReviewCampaignDeltaIsRecordsOnly -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
                -ChangedPaths @('specs/199-beta3-stabilization/iterations/001/some-new-artifact.md') | Should -BeFalse
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

        It 'a pause NEVER suppresses a clean pass on the same tree (the packet is how the human answers)' {
            # A wedge caught live by T051's fixture, not by reasoning. T001 makes EVERY round end in a
            # pause, so after any completed round a pending pause and that round's clean pass describe
            # the SAME tree at the same moment. Quieting there leaves the human holding a decision with
            # nothing to answer it through - the boundary packet IS the answering surface.
            #
            # The pause legitimately suppresses a DEMAND (do not nag for another review or disposition
            # while one is already with them). Releasing what they need in order to answer is not one.
            $result = script:New-TerminalResult -RunId 'run-paused-clean'
            $pause = [pscustomobject]@{ run_id = 'run-paused-clean'; target_digest = $script:Digest }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @('run-paused-clean') -Results @($result) `
                -RepoRoot $script:RepoRoot -PendingPause $pause

            $decision.route | Should -Be 'boundary-clean'
            $decision.render_boundary_packet | Should -BeTrue
        }

        It 'a pause DOES quiet when the same round produced findings rather than a pass' {
            # The paired sibling, so the case above can never be read as "a pause is ignorable". With
            # nothing to release, the pause is the sanctioned quiet state it was designed to be.
            $result = script:New-TerminalResult -RunId 'run-paused-findings'
            $result.verdict = 'findings'
            $result.can_approve_current = $false
            $pause = [pscustomobject]@{ run_id = 'run-paused-findings'; target_digest = $script:Digest }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @('run-paused-findings') -Results @($result) `
                -RepoRoot $script:RepoRoot -PendingPause $pause

            $decision.route | Should -Be 'pause-pending'
        }

        It 'a pause does not survive a human ACCEPTANCE of the same result either' {
            # The residual the maintainer told me to check rather than assume, and it was a second form of the
            # same wedge. Exempting only a CLEAN pass left this wedged: the human dispositions the findings -
            # which IS answering the pause, through a different instrument - and the surface kept reporting a
            # decision outstanding. Nothing in the tree retires a pause fact (Write-ReviewCampaignPauseDecisionFact
            # has no caller), so the pause cannot answer itself; the release must recognise the answer.
            $result = script:New-TerminalResult -RunId 'run-paused-accepted'
            $result.verdict = 'findings'
            $result.can_approve_current = $false
            $result.findings = @([pscustomobject]@{
                    finding_id = 'finding-x'; source_local_id = 'local-x'; lineage_id = 'lin-x'
                    severity = 'minor'; title = 'Advisory note'; description = 'An advisory finding.'
                    location = 'app.ps1:1'; relevance = 'current'; resolution = 'open'
                })
            $disposition = [pscustomobject]@{
                schema_version = '1.0'; fact_type = 'human-disposition'; disposition_id = 'disposition-accept-a'
                campaign_id = 'cmp-199-x-i001'; run_id = 'run-paused-accepted'; target_digest = $script:Digest
                decision = 'accept-current'; authority_kind = 'human'; authorized_by = 'maintainer'
                authorization_ref = 'beta3-pause-accept'; rationale = 'advisory only'
                observed_at = '2026-08-10T12:00:00Z'
            }
            $pause = [pscustomobject]@{ run_id = 'run-paused-accepted'; target_digest = $script:Digest }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @('run-paused-accepted') -Results @($result) `
                -RepoRoot $script:RepoRoot -PendingPause $pause -HumanDispositions @($disposition)

            $decision.route | Should -Not -Be 'pause-pending'
        }

        It 'a require-correction disposition is NOT an acceptance, so the pause still quiets' {
            # The paired sibling. A human who asked for a fix has not accepted, whatever else they also said -
            # so there is still a decision outstanding and the pause is still the honest surface.
            $result = script:New-TerminalResult -RunId 'run-paused-correct'
            $result.verdict = 'findings'
            $result.can_approve_current = $false
            $disposition = [pscustomobject]@{
                schema_version = '1.0'; fact_type = 'human-disposition'; disposition_id = 'disposition-correct-a'
                campaign_id = 'cmp-199-x-i001'; run_id = 'run-paused-correct'; target_digest = $script:Digest
                decision = 'require-correction'; authority_kind = 'human'; authorized_by = 'maintainer'
                authorization_ref = 'beta3-pause-correct'; rationale = 'fix the finding'
                observed_at = '2026-08-10T12:00:00Z'
            }
            $pause = [pscustomobject]@{ run_id = 'run-paused-correct'; target_digest = $script:Digest }

            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @('run-paused-correct') -Results @($result) `
                -RepoRoot $script:RepoRoot -PendingPause $pause -HumanDispositions @($disposition)

            $decision.route | Should -Be 'pause-pending'
        }

        It 'a SUPERSEDED pause confers nothing (it describes a tree that moved on)' {
            $pause = [pscustomobject]@{ run_id = 'run-paused-b'; target_digest = ('e' * 40) }
            $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' `
                -CurrentDigest $script:Digest -OrderedRunIds @() -Results @() -PendingPause $pause

            $decision.route | Should -Not -Be 'pause-pending'
        }
    }
}
