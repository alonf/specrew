$ErrorActionPreference = 'Stop'

# Trace: T001 / FR-001, FR-002, FR-003, FR-004, FR-023 / SC-001, SC-002.
#
# The economics core. Ledger F8 measured the failure this exists to end: 20 runs and 15 fix rounds
# on one target before any code existed, continuation self-minted from a single grant, and no
# sanctioned way to stop. The design (maintainer-approved, Option B) makes the pause a FACT rather
# than an inference: the round terminal records it, the surface renders from it, and the human's
# numbered reply is the only thing that authorizes another round.
#
# These cases pin the pure decision and the fact contract. The orchestrator terminal and the
# rendered surface are pinned separately.
Describe 'Campaign pause core (T001)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        # Rendering lives in the navigator layer (the D1 binding), which _load does not dot-source.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        function script:New-Finding {
            param([string]$Severity, [string]$Title = 'a finding', [string]$Location = 'src/x.ps1:1')
            return [pscustomobject]@{ severity = $Severity; title = $Title; description = 'detail'; location = $Location }
        }
    }

    Context 'the decision the surface renders from' {
        It 'separates the severities and reports the cost the human is spending' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @(
                (script:New-Finding -Severity 'blocking' -Title 'auth bypass' -Location 'src/auth.ps1:12'),
                (script:New-Finding -Severity 'major'),
                (script:New-Finding -Severity 'minor'),
                (script:New-Finding -Severity 'minor')
            ) -RoundsUsed 3 -BudgetTotal 4 -ElapsedMinutes 41

            $decision.blocking_count | Should -Be 1
            $decision.major_count | Should -Be 1
            $decision.minor_count | Should -Be 2
            $decision.rounds_used | Should -Be 3
            $decision.budget_total | Should -Be 4
            $decision.elapsed_minutes | Should -Be 41
        }

        It 'FR-004: minors never gate, and are carried as recorded follow-ups' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @(
                (script:New-Finding -Severity 'minor'),
                (script:New-Finding -Severity 'minor'),
                (script:New-Finding -Severity 'minor')
            ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 5

            $decision.gating | Should -BeFalse
            $decision.carried_followups | Should -Be 3
        }

        It 'a blocking finding gates' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'blocking')) `
                -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 5
            $decision.gating | Should -BeTrue
        }

        It 'the recommendation is derived from severity ALONE and never decides for the human' {
            $blocking = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'blocking')) `
                -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 5
            $minorsOnly = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'minor')) `
                -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 5

            $blocking.recommendation | Should -Not -BeNullOrEmpty
            $minorsOnly.recommendation | Should -Not -BeNullOrEmpty
            $blocking.recommendation | Should -Not -Be $minorsOnly.recommendation
            # Three numbered options are always offered: the recommendation informs, it never selects.
            @($blocking.options).Count | Should -Be 3
            @($minorsOnly.options).Count | Should -Be 3
        }

        It 'SC-002: an exhausted budget refuses continuation until a human reset' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60

            $decision.budget_exhausted | Should -BeTrue
            $decision.continuation_available | Should -BeFalse
            $decision.options | Where-Object { $_.id -eq 1 } | Should -BeNullOrEmpty
        }

        It 'SC-002: continue is ABSENT when the budget is spent, never merely discouraged' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60

            @($decision.options | Where-Object { $_.choice -ceq 'fix-and-continue' }).Count | Should -Be 0
            # The reset is NOT a numbered choice: a sanctioned bypass rendered as an option becomes
            # one keystroke inside the flow it exists to interrupt, and exhaustion must feel
            # different from an ordinary continuation.
            @($decision.options | Where-Object { $_.choice -ceq 'reset-allowance' }).Count | Should -Be 0
            @($decision.options).Count | Should -Be 2
            @($decision.options | ForEach-Object { $_.choice }) | Should -Be @('stop-here', 'abandon')
        }

        It 'the refusal names what happened and the exact command to reset (U4 shape)' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60

            $decision.budget_refusal | Should -Not -BeNullOrEmpty
            $decision.budget_refusal | Should -Match '4 of 4'
            $decision.budget_refusal | Should -Match 'allowance-reset'
        }

        It 'no refusal text is rendered while budget remains' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 3
            $decision.budget_refusal | Should -BeNullOrEmpty
        }

        It 'continuation stays available while budget remains' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 2 -BudgetTotal 4 -ElapsedMinutes 20

            $decision.budget_exhausted | Should -BeFalse
            $decision.continuation_available | Should -BeTrue
        }

        It 'a review that produced no valid result gates and never renders as clean at the budget ceiling' {
            $result = [pscustomobject][ordered]@{
                completion = 'none'; validation = 'not-produced'; verdict = 'incomplete'
                failure_reason = 'review-timeout'; findings = @()
            }
            $decision = Resolve-ReviewCampaignPauseDecision -Result $result -Findings @() `
                -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60

            $decision.gating | Should -BeTrue
            $decision.evidence_state | Should -Be 'not-produced'
            $decision.result_produced | Should -BeFalse
            $decision.continuation_available | Should -BeFalse
            @($decision.options | Where-Object { $_.id -eq 1 }).Count | Should -Be 0
            $decision.budget_refusal | Should -Match '4 of 4'

            $surface = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision $decision
            $surface | Should -Match 'found nothing and cleared nothing'
            $surface | Should -Match 'not a clean review|Do not read this as a clean result'
            $surface | Should -Not -Match 'Nothing was found\. Stopping here completes your sign-off'
        }
    }

    Context 'the rendered decision surface (what the human actually reads)' {
        BeforeAll {
            $script:Surface = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @(
                    (script:New-Finding -Severity 'blocking' -Title 'SQL injection in the export endpoint' -Location 'src/export.ps1:88'),
                    (script:New-Finding -Severity 'major' -Title 'retry loop never backs off' -Location 'src/poll.ps1:41'),
                    (script:New-Finding -Severity 'minor'), (script:New-Finding -Severity 'minor'), (script:New-Finding -Severity 'minor')
                ) -RoundsUsed 3 -BudgetTotal 4 -ElapsedMinutes 41
            )
        }

        It 'names the project and what was found, with locations' {
            $script:Surface | Should -Match 'linkcheck'
            $script:Surface | Should -Match 'SQL injection in the export endpoint'
            $script:Surface | Should -Match 'src/export\.ps1:88'
        }

        It 'shows the minors as saved follow-ups that do not block' {
            $script:Surface | Should -Match '3 minor'
            $script:Surface | Should -Match 'follow-up'
        }

        It 'shows the cost and the budget position' {
            $script:Surface | Should -Match '3 rounds'
            $script:Surface | Should -Match '41 minutes'
            $script:Surface | Should -Match '3 of 4'
        }

        It 'offers numbered options and states that nothing spends until the human answers' {
            $script:Surface | Should -Match '(?m)^\s*1\.'
            $script:Surface | Should -Match '(?m)^\s*2\.'
            $script:Surface | Should -Match '(?m)^\s*3\.'
            $script:Surface | Should -Match '[Nn]othing runs and nothing is spent until you answer'
        }

        It 'FR-015: carries no internal machinery vocabulary' {
            foreach ($banned in @('crossing', 'mint', 'digest', 'boundary sync', 'verdict capture', 'ratchet', 'terminalize', 'claim-ordered')) {
                $script:Surface | Should -Not -Match ([regex]::Escape($banned))
            }
        }

        It 'renders the exhausted-budget refusal as prose with only two numbered options' {
            $exhausted = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60
            )
            $exhausted | Should -Match '4 of 4'
            $exhausted | Should -Match 'allowance-reset'
            $exhausted | Should -Not -Match '(?m)^\s*1\.'
            $exhausted | Should -Match '(?m)^\s*2\.'
            $exhausted | Should -Match '(?m)^\s*3\.'
        }
    }

    # Maintainer ruling 2026-08-10. T005 demotes a gating finding that states no concrete failure
    # scenario, and the demotion itself was INVISIBLE: the finding arrived in the follow-up list
    # looking like any other minor. A human reading "3 minor findings" could not tell that one of them
    # was a security finding the reviewer meant to gate on - and a demotion the human cannot see is a
    # SILENCING, which is the exact direction this whole feature exists to close.
    #
    # Pinned BOTH WAYS on purpose: a round with demotions names them, and a round without them renders
    # no such line. A surface that always mentions demotion teaches the reader to skip the sentence.
    Context 'a demotion is never silent (FR-006 visibility)' {
        BeforeAll {
            function script:New-DemotedFinding {
                # The shape ingest produces: severity already lowered to minor, the reviewer's original
                # severity preserved beside it. Built here rather than by calling the grader so this
                # suite keeps testing the SURFACE, not the ingestor.
                param([string]$From = 'blocking', [string]$Title = 'unvalidated input reaches the shell')
                return [pscustomobject]@{
                    severity = 'minor'; title = $Title; description = 'detail'; location = 'src/x.ps1:1'
                    demoted = $true; demoted_from = $From
                }
            }
        }

        It 'the decision counts the demotions and keeps the reviewer original severity' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @(
                (script:New-DemotedFinding -From 'blocking'),
                (script:New-DemotedFinding -From 'major'),
                (script:New-Finding -Severity 'minor')
            ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9

            $decision.demoted_count | Should -Be 2
            $decision.demoted_from_blocking | Should -Be 1
            $decision.demoted_from_major | Should -Be 1
            $decision.minor_count | Should -Be 3 -Because 'a demoted finding IS a minor now - the demotion count names a subset, it does not add a bucket'
            $decision.gating | Should -BeFalse -Because 'the whole point of the demotion is that it cannot cost the human a round'
        }

        It 'a round with no demotions reports zero' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @(
                (script:New-Finding -Severity 'blocking'), (script:New-Finding -Severity 'minor')
            ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9

            $decision.demoted_count | Should -Be 0
            $decision.demoted_from_blocking | Should -Be 0
            $decision.demoted_from_major | Should -Be 0
        }

        It 'the surface NAMES the demotion, the reviewer original severity, and where it went' {
            $surface = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @(
                    (script:New-DemotedFinding -From 'blocking'), (script:New-Finding -Severity 'minor')
                ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9
            )

            $surface | Should -Match '(?i)reported as blocking' -Because 'the human must be able to see it was NOT the reviewer that called this minor'
            $surface | Should -Match '(?i)demoted'
            $surface | Should -Match '(?i)no concrete failure scenario'
            $surface | Should -Match '(?i)follow-up'
        }

        It 'a round with NO demotions renders no demotion line at all' {
            $surface = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @(
                    (script:New-Finding -Severity 'blocking'), (script:New-Finding -Severity 'minor')
                ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9
            )

            $surface | Should -Not -Match '(?i)demoted'
            $surface | Should -Not -Match '(?i)no concrete failure scenario'
        }

        It 'mixed origins are stated honestly rather than collapsed to one severity' {
            $surface = Format-ReviewCampaignPauseSurface -ProjectName 'linkcheck' -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @(
                    (script:New-DemotedFinding -From 'blocking'), (script:New-DemotedFinding -From 'major')
                ) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9
            )

            $surface | Should -Match '(?i)reported as blocking or major'
            $surface | Should -Match '2 findings'
        }

        It 'the recorded pause fact carries the demotion count and still validates' {
            # Without this the SURFACE tells the truth while the RECORD does not, and the record is
            # what a later reader has.
            $fact = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-demote' `
                -TargetDigest ('a' * 40) -Decision (
                Resolve-ReviewCampaignPauseDecision -Findings @((script:New-DemotedFinding -From 'blocking')) `
                    -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 9
            ) -ObservedAt '2026-08-10T10:00:00Z'

            $fact.demoted_count | Should -Be 1
            (Test-ReviewAuthorityContractObject -ContractName PendingPauseFact -InputObject $fact -ExpectedCampaignId 'cmp-199-x-i001').valid | Should -BeTrue
        }
    }

    Context 'the round terminal (FR-001: every round ends in a pause, never another round)' {
        BeforeAll {
            . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1')
        }

        It 'records the pause and returns the surface when a round publishes its result' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-term-' + [Guid]::NewGuid().ToString('N'))
            try {
                $result = [pscustomobject]@{
                    findings = @(
                        [pscustomobject]@{ severity = 'major'; title = 'retry loop never backs off'; location = 'src/poll.ps1:41' },
                        [pscustomobject]@{ severity = 'minor'; title = 'wording'; location = 'docs/a.md:2' }
                    )
                    duration_ms = 600000
                }
                $pause = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-a' `
                    -TargetDigest ('e' * 40) -ProjectName 'linkcheck' -Result $result -ObservedAt '2026-08-10T11:00:00Z'

                $pause.recorded | Should -BeTrue
                $pause.surface | Should -Match 'Review round'
                $pause.surface | Should -Match 'Nothing runs and nothing is spent until you answer'
                # The pause is now readable state, not something the caller must remember.
                (Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Not -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'counts this round against the campaign budget, so cost accumulates across rounds' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-term-' + [Guid]::NewGuid().ToString('N'))
            try {
                $result = [pscustomobject]@{ findings = @(); duration_ms = 60000 }
                $first = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-1' `
                    -TargetDigest ('f' * 40) -ProjectName 'linkcheck' -Result $result -ObservedAt '2026-08-10T11:00:00Z'
                $first.decision.rounds_used | Should -Be 1

                # A second round on the same campaign sees the first one's cost.
                $second = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-2' `
                    -TargetDigest ('f' * 40) -ProjectName 'linkcheck' -Result $result -ObservedAt '2026-08-10T11:10:00Z'
                $second.decision.rounds_used | Should -Be 2
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'the published-result path in the orchestrator records the pause' {
            # Source guard (labelled as such): the behavioural cases above exercise the helper
            # directly; this pins that the terminal actually calls it, which a unit fixture cannot
            # reach without standing up the full harness/runtime port set.
            $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1') -Raw
            $publishedBlock = [regex]::Match($source, '(?ms)if \(\$ingress\.published\) \{.*?\n        \}').Value

            $publishedBlock | Should -Not -BeNullOrEmpty
            $publishedBlock | Should -Match 'Add-ReviewCampaignRoundPause'
        }
    }

    Context 'the pause facts (Option B: the pause is recorded, never inferred)' {
        It 'a pending-pause fact validates against its contract' {
            $fact = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-10T10:00:00Z'

            $validation = Test-ReviewAuthorityContractObject -ContractName PendingPauseFact -InputObject $fact -ExpectedCampaignId 'cmp-199-x-i001'
            $validation.valid | Should -BeTrue
        }

        It 'a pause-decision fact validates and carries the human choice' {
            $fact = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -Choice 'stop-here' -ObservedAt '2026-08-10T10:05:00Z'

            $validation = Test-ReviewAuthorityContractObject -ContractName PauseDecisionFact -InputObject $fact -ExpectedCampaignId 'cmp-199-x-i001'
            $validation.valid | Should -BeTrue
            $fact.choice | Should -Be 'stop-here'
        }

        It 'a choice outside the closed set is refused' {
            { New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                    -Choice 'continue-forever' -ObservedAt '2026-08-10T10:05:00Z' } | Should -Throw
        }

        It 'FR-003: an unanswered pause blocks continuation - no agent-minted authorization' {
            $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-10T10:00:00Z'

            $unanswered = Test-ReviewCampaignContinuationAuthorized -PendingPause $pending -PauseDecisions @()
            $unanswered.authorized | Should -BeFalse
            $unanswered.reason | Should -Match 'pending'
        }

        It 'FR-003: a fix-and-continue decision authorizes EXACTLY ONE further round' {
            $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-10T10:00:00Z'
            $answer = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -Choice 'fix-and-continue' -ObservedAt '2026-08-10T10:05:00Z'

            $authorized = Test-ReviewCampaignContinuationAuthorized -PendingPause $pending -PauseDecisions @($answer)
            $authorized.authorized | Should -BeTrue

            # The SAME decision cannot authorize a second round: one answer, one round.
            $second = Test-ReviewCampaignContinuationAuthorized -PendingPause $pending -PauseDecisions @($answer) -RoundsSinceDecision 1
            $second.authorized | Should -BeFalse
            $second.reason | Should -Match 'single-run'
        }

        # Maintainer ruling 2026-08-10. A pause is recorded AGAINST a tree state. The human then
        # fixes things and the tree moves. If quiet did not check that, a stale pause would silence
        # a tree it never described - the review-stale class in a new place, and worse than the
        # original because this one SILENCES the surface instead of nagging it.
        It 'a pause whose tree state still matches confers quiet' {
            $digest = 'a' * 40
            $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -TargetDigest $digest -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-10T10:00:00Z'

            $quiet = Test-ReviewCampaignPendingPauseQuiet -PendingPause $pending -CurrentDigest $digest
            $quiet.confers_quiet | Should -BeTrue
        }

        It 'a pause whose tree state has moved is SUPERSEDED and confers no quiet' {
            $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-10T10:00:00Z'

            $quiet = Test-ReviewCampaignPendingPauseQuiet -PendingPause $pending -CurrentDigest ('b' * 40)
            $quiet.confers_quiet | Should -BeFalse
            $quiet.reason | Should -Match 'superseded'
        }

        It 'an absent or unreadable pause confers no quiet (fail closed)' {
            (Test-ReviewCampaignPendingPauseQuiet -PendingPause $null -CurrentDigest ('a' * 40)).confers_quiet | Should -BeFalse
        }

        It 'the facts persist and read back through the immutable store' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-pause-' + [Guid]::NewGuid().ToString('N'))
            try {
                $digest = 'c' * 40
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-store' `
                    -TargetDigest $digest -Decision (Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) -RoundsUsed 2 -BudgetTotal 4 -ElapsedMinutes 12) `
                    -ObservedAt '2026-08-10T10:00:00Z'

                $write = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $pending
                $write.created | Should -BeTrue

                $readBack = Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001'
                $readBack | Should -Not -BeNullOrEmpty
                $readBack.run_id | Should -Be 'run-t001-store'
                $readBack.target_digest | Should -Be $digest
                # Resume renders the surface VERBATIM from the fact, so its content must survive.
                $readBack.recommendation | Should -Be $pending.recommendation
                $readBack.rounds_used | Should -Be 2
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'an answered pause is no longer pending' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-pause-' + [Guid]::NewGuid().ToString('N'))
            try {
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-answered' `
                    -TargetDigest ('d' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 3) `
                    -ObservedAt '2026-08-10T10:00:00Z'
                Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $pending | Out-Null

                (Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Not -BeNullOrEmpty

                $answer = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-answered' `
                    -Choice 'stop-here' -ObservedAt '2026-08-10T10:05:00Z'
                Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact $answer | Out-Null

                (Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'a second answer for the same round is refused (one reply, one round)' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-pause-' + [Guid]::NewGuid().ToString('N'))
            try {
                $answer = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-dup' `
                    -Choice 'fix-and-continue' -ObservedAt '2026-08-10T10:05:00Z'
                Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact $answer | Out-Null

                $conflicting = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-dup' `
                    -Choice 'abandon' -ObservedAt '2026-08-10T10:06:00Z'
                { Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact $conflicting } | Should -Throw '*conflicting-immutable-fact*'
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'stop-here and abandon never authorize another round' {
            foreach ($choice in @('stop-here', 'abandon')) {
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                    -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                    -ObservedAt '2026-08-10T10:00:00Z'
                $answer = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                    -Choice $choice -ObservedAt '2026-08-10T10:05:00Z'

                (Test-ReviewCampaignContinuationAuthorized -PendingPause $pending -PauseDecisions @($answer)).authorized | Should -BeFalse
            }
        }
    }
}
