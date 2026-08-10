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

        It 'continuation stays available while budget remains' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 2 -BudgetTotal 4 -ElapsedMinutes 20

            $decision.budget_exhausted | Should -BeFalse
            $decision.continuation_available | Should -BeTrue
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
