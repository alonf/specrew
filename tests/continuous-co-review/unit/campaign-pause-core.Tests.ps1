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

        # Feature 203 T008 step (iii): one stop of each kind through the engine's own writer, rendered by the surface the human sees.
        function script:New-StopSurface([string]$Kind, [int]$Used = 2, [int]$Total = 2, [string]$NextHost = '') {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed $Used -BudgetTotal $Total
            $reason = switch ($Kind) { 'a-budget-spent' { 'budget-spent' } 'b-dispute-or-defer' { 'dispute' } 'c-judgment' { 'ask' } default { 'host-order-exhausted' } }
            $stop = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-surface' -TargetDigest ('a' * 40) -Decision $decision `
                -ObservedAt '2026-11-09T08:00:00Z' -StopKind $Kind -StopReason $reason -NextHost $NextHost
            $open = @([pscustomobject]@{ finding_id = 'finding-0123456789abcdef'; finding_key = 'finding-0123456789abcdef'; severity = 'major'; title = 'Empty store'; location = 'src/app.ps1:1' })
            return @(Format-ReviewCampaignStopSurface -Stop $stop -OpenFindings $open)
        }

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

        # Class A for the old menu (deleted, no production caller; maintainer ruling 2026-11-09); the property - nothing
        # decides for the human - now holds on the stop surface the human sees.
        It 'no stop line is pre-chosen or marked as the default: nothing decides for the human' {
            foreach ($kind in @('a-budget-spent', 'b-dispute-or-defer', 'c-judgment', 'd-host-outside-order')) {
                $text = (script:New-StopSurface -Kind $kind -NextHost 'copilot') -join "`n"
                $text | Should -Not -Match '(?i)recommended|\(default\)|default:|we will|selected|\[x\]'
            }
        }

        It 'SC-002: an exhausted budget refuses continuation until a human reset' {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) `
                -RoundsUsed 4 -BudgetTotal 4 -ElapsedMinutes 60

            $decision.budget_exhausted | Should -BeTrue
            $decision.continuation_available | Should -BeFalse
            $decision.options | Where-Object { $_.id -eq 1 } | Should -BeNullOrEmpty
        }

        # Class A for the old menu; SC-002 on the stop surface: at (a) the only line that continues is the allowance reset,
        # sent as a line with its consequence; with budget left there is no (a) stop at all (review-loop-stops.Tests.ps1).
        It 'SC-002: at stop (a) the only line that continues is approved for allowance reset, sent with its consequence' {
            $lines = @(script:New-StopSurface -Kind 'a-budget-spent')
            $continuing = @($lines | Where-Object { $_ -match '^\s{2}\S' -and $_ -match '(?i)goes on|continue' })
            $continuing.Count | Should -Be 1
            $continuing[0] | Should -Match '^\s+approved for allowance reset - .+'
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
            # W67 (2026-08-26) replaced the trailing "3 minor findings" footnote with the whole mix
            # stated in one place - total, blocking, needing acceptance, notes - because a reader had
            # to combine three separate lines to learn what the round amounted to, and no line said
            # nothing blocked even when nothing did. The property this case exists for is unchanged:
            # the minors are visible AS non-gating follow-ups.
            $script:Surface | Should -Match '(?i)3 are notes'
            $script:Surface | Should -Match 'follow-up'
        }

        It 'shows the cost and the budget position' {
            $script:Surface | Should -Match '3 rounds'
            $script:Surface | Should -Match '41 minutes'
            $script:Surface | Should -Match '3 of 4'
        }

        # Class A for the old menu (FR-011): each stop offers exactly its own lines, and none asks for a round or abandons.
        It 'each stop kind offers exactly its FR-011 lines, and none says run another round or abandon' {
            $expected = @{
                'a-budget-spent'       = @('approved for allowance reset', 'stop the review here', 'defer finding <id> to <backlog item or iteration>', 'drop finding <id>')
                'b-dispute-or-defer'   = @('fix finding <id>', 'defer finding <id> to <backlog item or iteration>', 'drop finding <id>')
                'c-judgment'           = @('your answer, in your own words', 'stop the review here')
                'd-host-outside-order' = @('allow reviewer copilot', 'stop the review here')
            }
            foreach ($kind in $expected.Keys) {
                $lines = @(script:New-StopSurface -Kind $kind -NextHost 'copilot')
                $offered = @($lines | Where-Object { $_ -match '^\s{2}\S.* - ' -and $_ -notmatch '^\s{2}- ' } | ForEach-Object { ($_.Trim() -split ' - ', 2)[0] })
                $offered | Should -Be $expected[$kind] -Because $kind
                ($lines -join "`n") | Should -Not -Match '(?i)run another round|abandon'
            }
        }

        It 'FR-015: carries no internal machinery vocabulary' {
            foreach ($banned in @('crossing', 'mint', 'digest', 'boundary sync', 'verdict capture', 'ratchet', 'terminalize', 'claim-ordered')) {
                $script:Surface | Should -Not -Match ([regex]::Escape($banned))
            }
        }

        # B (maintainer ruling 2026-11-09): the exhausted-budget refusal stays prose naming the reset, and says the reset is
        # typed as a normal chat message (W54).
        It 'renders the exhausted-budget refusal as prose naming the reset, typed as a normal chat message' {
            $text = Format-ReviewCampaignBudgetSpentDetail -BudgetState ([pscustomobject]@{ rounds_used = 2; budget_total = 2; budget_source = 'grant'; in_flight = 0 })
            $text | Should -Match 'approved for allowance reset'
            $text | Should -Match 'as a normal chat message'
            $text | Should -Not -Match '(?i)abandon|run another round'
            $stopText = (script:New-StopSurface -Kind 'a-budget-spent') -join "`n"
            $resetLine = @($stopText -split "`n" | Where-Object { $_ -match 'approved for allowance reset' })[0]
            $resetLine | Should -Match 'normal chat message' -Because 'W54: the line naming a captured phrase says how it is sent'
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

        # Class A (203 T008 step (iii), DRIFT-052 item 5): a round no longer always ends in a pause. Within the budget it records
        # nothing; it records a stop only for (a) or (c), and that stop returns the FR-011 surface.
        It 'records no pause for a round within the budget, and records stop (c) with its FR-011 surface for a reviewer that changed the frozen copy' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-term-' + [Guid]::NewGuid().ToString('N'))
            try {
                $result = [pscustomobject]@{
                    findings = @([pscustomobject]@{ severity = 'major'; title = 'retry loop never backs off'; location = 'src/poll.ps1:41' })
                    duration_ms = 600000; completion = 'complete'; review_collected = $true; containment = 'verified'; runtime_outcome = 'completed'
                }
                $within = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-a' `
                    -TargetDigest ('e' * 40) -ProjectName 'linkcheck' -Result $result -ObservedAt '2026-08-10T11:00:00Z'
                $within.recorded | Should -BeFalse
                (Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -BeNullOrEmpty

                $result.containment = 'violated'
                $violated = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-b' `
                    -TargetDigest ('e' * 40) -ProjectName 'linkcheck' -Result $result -ObservedAt '2026-08-10T11:05:00Z'
                $violated.recorded | Should -BeTrue
                [string]$violated.stop_kind | Should -BeExactly 'c-judgment'
                (@($violated.surface) -join "`n") | Should -Match 'Why: '
                (Get-ReviewCampaignOpenStop -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Not -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'counts this round against the campaign budget, so cost accumulates across rounds' {
            # Feature 203 T008 (DRIFT-052 item 3): a round is the terminal of a run that collected a complete review. Each
            # round is published the way the orchestrator publishes it, then paused, so the counter reads the store.
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-term-' + [Guid]::NewGuid().ToString('N'))
            $publish = {
                param([string]$RunId, [bool]$Collected, [string]$StartedAt)
                $result = [pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = $RunId; target_digest = ('f' * 40); harness_id = 'fixture'
                    completion = $(if ($Collected) { 'complete' } else { 'partial' }); verdict = $(if ($Collected) { 'pass' } else { 'incomplete' })
                    runtime_outcome = $(if ($Collected) { 'completed' } else { 'timed-out' }); termination_verified = $true; containment = 'verified'
                    currentness = 'current'; validation = 'valid'; can_approve_current = $Collected; summary = 'fixture'; findings = @()
                    started_at = $StartedAt; ended_at = $StartedAt; duration_ms = 60000; examined_paths = @(); review_collected = $Collected
                }
                Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -TargetLineage 'lin-term' -ObservedAt $StartedAt | Out-Null
                Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -Fact $result | Out-Null
                Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -TargetLineage 'lin-term' -Disposition released -ObservedAt $StartedAt | Out-Null
                return $result
            }
            try {
                $r1 = & $publish 'run-term-1' $true '2026-08-10T11:00:00Z'
                $first = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-1' `
                    -TargetDigest ('f' * 40) -ProjectName 'linkcheck' -Result $r1 -ObservedAt '2026-08-10T11:01:00Z'
                $first.decision.rounds_used | Should -Be 1

                # A second round on the same campaign sees the first one's cost.
                $r2 = & $publish 'run-term-2' $true '2026-08-10T11:10:00Z'
                $second = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-2' `
                    -TargetDigest ('f' * 40) -ProjectName 'linkcheck' -Result $r2 -ObservedAt '2026-08-10T11:11:00Z'
                $second.decision.rounds_used | Should -Be 2

                # A run that brought back no complete review costs nothing, and its pause says so.
                $r3 = & $publish 'run-term-3' $false '2026-08-10T11:20:00Z'
                $third = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-term-3' `
                    -TargetDigest ('f' * 40) -ProjectName 'linkcheck' -Result $r3 -ObservedAt '2026-08-10T11:21:00Z'
                $third.decision.rounds_used | Should -Be 2
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

        # Class A (203 T008 step (iii); FR-006, FR-010): the per-round continuation check is gone. What blocks the next launch
        # is an open stop, which only the human's answer closes (the launch refusal itself: review-loop-stops.Tests.ps1).
        It 'an open stop stays open until the human answers it - no agent-minted authorization' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-open-' + [Guid]::NewGuid().ToString('N'))
            try {
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                    -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @((script:New-Finding -Severity 'major')) -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 2) `
                    -ObservedAt '2026-08-10T10:00:00Z' -StopKind 'c-judgment' -StopReason 'ask'
                $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $pending
                (Get-ReviewCampaignOpenStop -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Not -BeNullOrEmpty
                $null = Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' -Choice 'answered' -ObservedAt '2026-08-10T10:05:00Z')
                (Get-ReviewCampaignOpenStop -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        # Class A (203 T008 step (iii); FR-006, FR-010): fix-and-continue is removed. After a fix-needed round, exactly one round
        # runs once the files move: the loop's own record of the last round's files is what the launch compares (the
        # command path, refused while unchanged and run once after a fix: review-loop-stops.Tests.ps1).
        It 'after a fix-needed round the loop records the files it reviewed, which the next launch compares' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-loop-' + [Guid]::NewGuid().ToString('N'))
            try {
                $result = [pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = 'run-t001-loop'; target_digest = ('c' * 40); harness_id = 'fixture'
                    completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
                    currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'one finding'
                    findings = @([pscustomobject][ordered]@{ finding_id = 'finding-00000000000000aa'; source_local_id = 'l1'; lineage_id = 'lin-00000000000000aa'; severity = 'major'; title = 'retry'; description = 'Failure scenario: it never backs off.'; location = 'src/poll.ps1:41'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' })
                    started_at = '2026-08-10T10:00:00Z'; ended_at = '2026-08-10T10:01:00Z'; duration_ms = 60000; examined_paths = @('src/poll.ps1'); review_collected = $true
                }
                Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-loop' -TargetLineage 'lin-199-x' -ObservedAt '2026-08-10T10:00:00Z' | Out-Null
                Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-loop' -Fact $result | Out-Null
                $loop = Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001'
                [string]$loop.last_spent_digest | Should -BeExactly ('c' * 40)
                $loop.ended_clean | Should -BeFalse
                @($loop.open_findings).Count | Should -Be 1
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
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

        # B: one reply per round still holds, with the answers that can still be recorded.
        It 'a second answer for the same round is refused (one reply, one round)' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-pause-' + [Guid]::NewGuid().ToString('N'))
            try {
                $answer = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-dup' `
                    -Choice 'stop-here' -ObservedAt '2026-08-10T10:05:00Z'
                Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact $answer | Out-Null

                $conflicting = New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-dup' `
                    -Choice 'answered' -ObservedAt '2026-08-10T10:06:00Z'
                { Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact $conflicting } | Should -Throw '*conflicting-immutable-fact*'
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }

        # Class A (203 T008 step (iii); FR-011, maintainer ruling 2026-11-09): abandon is retired; `stop the review here` ends
        # the campaign's rounds until an allowance reset recorded after it reopens the review (fix 6).
        It 'stop the review here ends the campaign''s rounds until an allowance reset reopens them' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-stop-' + [Guid]::NewGuid().ToString('N'))
            try {
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' `
                    -TargetDigest ('a' * 40) -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2 -ElapsedMinutes 2) `
                    -ObservedAt '2026-08-10T10:00:00Z' -StopKind 'a-budget-spent' -StopReason 'budget-spent'
                $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $pending
                $null = Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (New-ReviewCampaignPauseDecisionFact -CampaignId 'cmp-199-x-i001' -RunId 'run-t001-a' -Choice 'stop-here' -ObservedAt '2026-08-10T10:05:00Z')
                (Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001').stopped_here | Should -BeTrue
                $null = Write-ReviewCampaignBudgetResetFact -StoreRoot $store -Fact (New-ReviewCampaignBudgetResetFact -CampaignId 'cmp-199-x-i001' -AuthorizedBy 'maintainer' -Reason 'reopen' -ObservedAt '2026-08-10T10:10:00Z')
                (Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001').stopped_here | Should -BeFalse
            }
            finally { Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
