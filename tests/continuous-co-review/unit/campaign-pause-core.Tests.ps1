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

        # Feature 203 T008 step (iii): a store holding one published round with $Findings, through the engine's own writers.
        function script:New-RoundStore([object[]]$Findings, [bool]$Collected = $true, [string]$RunId = 'run-core-1', [string]$Digest = ('c' * 40)) {
            $store = Join-Path $TestDrive ('store-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
            $result = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-199-x-i001'; run_id = $RunId; target_digest = $Digest; harness_id = 'fixture'
                completion = $(if ($Collected) { 'complete' } else { 'partial' }); verdict = $(if ($Collected) { 'findings' } else { 'incomplete' })
                runtime_outcome = $(if ($Collected) { 'completed' } else { 'terminated' }); termination_verified = $true; containment = 'verified'
                currentness = 'current'; validation = 'valid'; can_approve_current = $false; failure_reason = $(if ($Collected) { $null } else { 'the run brought back half a review' }); summary = 'fixture'; findings = @($Findings)
                started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/x.ps1'); review_collected = $Collected
            }
            Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -TargetLineage 'lin-199-x' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
            Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -Fact $result | Out-Null
            Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId $RunId -TargetLineage 'lin-199-x' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
            return $store
        }
        function script:New-StoredFinding([string]$Id, [string]$Severity, [string]$Title = 'a finding', [string]$Location = 'src/x.ps1:1', [string]$DemotedFrom = '') {
            return [pscustomobject][ordered]@{
                finding_id = $Id; source_local_id = 'l1'; lineage_id = 'lin-' + $Id.Substring(8); severity = $Severity; title = $Title
                description = 'Failure scenario: it breaks.'; location = $Location; relevance = 'current'; resolution = 'open'
                demoted = (-not [string]::IsNullOrWhiteSpace($DemotedFrom)); demoted_from = $DemotedFrom
            }
        }

        function script:New-Finding {
            param([string]$Severity, [string]$Title = 'a finding', [string]$Location = 'src/x.ps1:1')
            return [pscustomobject]@{ severity = $Severity; title = $Title; description = 'detail'; location = $Location }
        }
    }

    Context 'the decision the surface renders from' {
        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. Class A (the decision's counts are gone): the stop the human sees
        # counts its open findings one by one and shows the rounds used.
        It 'stop (a) counts its open findings one by one and shows the rounds used' {
            $text = (script:New-StopSurface -Kind 'a-budget-spent') -join "`n"
            $text | Should -Match 'What happened: 2 of 2 rounds used; 1 finding open\.'
            $text | Should -Match '- finding-0123456789abcdef \(major\) Empty store at src/app\.ps1:1'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B, both halves: a minor never opens a finding, never causes stop (a)
        # and never blocks sign-off, AND the sign-off lists it as a follow-up (FR-013).
        It 'FR-004: minors never gate, and are carried as recorded follow-ups' {
            $store = script:New-RoundStore -Findings @((script:New-StoredFinding -Id 'finding-00000000000000a1' -Severity 'minor' -Title 'wording'))
            @(Get-ReviewCampaignOpenFindings -StoreRoot $store -CampaignId 'cmp-199-x-i001').Count | Should -Be 0
            (Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001').ended_clean | Should -BeTrue
            @(Get-ReviewCampaignSignoffFindingLines -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Contain 'Follow-up: finding-00000000000000a1 (minor) wording at src/x.ps1:1'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B.
        It 'a blocking finding gates' {
            $store = script:New-RoundStore -Findings @((script:New-StoredFinding -Id 'finding-00000000000000b1' -Severity 'blocking'))
            @(Get-ReviewCampaignOpenFindings -StoreRoot $store -CampaignId 'cmp-199-x-i001').Count | Should -Be 1
            (Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001').ended_clean | Should -BeFalse
        }

        # Class A for the old menu (deleted, no production caller; maintainer ruling 2026-11-09); the property - nothing
        # decides for the human - now holds on the stop surface the human sees.
        It 'no stop line is pre-chosen or marked as the default: nothing decides for the human' {
            foreach ($kind in @('a-budget-spent', 'b-dispute-or-defer', 'c-judgment', 'd-host-outside-order')) {
                $text = (script:New-StopSurface -Kind $kind -NextHost 'copilot') -join "`n"
                $text | Should -Not -Match '(?i)recommended|\(default\)|default:|we will|selected|\[x\]'
            }
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B, on the budget state the launch consumes.
        It 'SC-002: an exhausted budget refuses continuation until a human reset' {
            $store = script:New-RoundStore -Findings @() -RunId 'run-core-1'
            $null = Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-core-2' -TargetLineage 'lin-199-x' -ObservedAt '2026-11-09T08:02:00Z'
            $second = (Get-ReviewRunAuthorityFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-core-1' -Stage result) | Select-Object *
            $second.run_id = 'run-core-2'; $second.started_at = '2026-11-09T08:02:00Z'; $second.ended_at = '2026-11-09T08:03:00Z'
            $null = Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-core-2' -Fact $second
            (Get-ReviewCampaignRoundBudgetState -StoreRoot $store -CampaignId 'cmp-199-x-i001').continuation_available | Should -BeFalse
            $null = Write-ReviewCampaignBudgetResetFact -StoreRoot $store -Fact (New-ReviewCampaignBudgetResetFact -CampaignId 'cmp-199-x-i001' -AuthorizedBy 'human' -Reason 'more' -ObservedAt '2026-11-09T09:00:00Z')
            (Get-ReviewCampaignRoundBudgetState -StoreRoot $store -CampaignId 'cmp-199-x-i001').continuation_available | Should -BeTrue
        }

        # Class A for the old menu; SC-002 on the stop surface: at (a) the only line that continues is the allowance reset,
        # sent as a line with its consequence; with budget left there is no (a) stop at all (review-loop-stops.Tests.ps1).
        It 'SC-002: at stop (a) the only line that continues is approved for allowance reset, sent with its consequence' {
            $lines = @(script:New-StopSurface -Kind 'a-budget-spent')
            $continuing = @($lines | Where-Object { $_ -match '^\s{2}\S' -and $_ -match '(?i)goes on|continue' })
            $continuing.Count | Should -Be 1
            $continuing[0] | Should -Match '^\s+approved for allowance reset - .+'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B (FR-010 for the command): the refusal names what happened and the
        # typed line, never a command for the agent to run on the human's behalf.
        It 'the refusal names what happened and the typed reset line (U4 shape)' {
            $text = Format-ReviewCampaignBudgetSpentDetail -BudgetState ([pscustomobject]@{ rounds_used = 2; budget_total = 2; budget_source = 'grant'; in_flight = 0 })
            $text | Should -Match '2 of 2 rounds'
            $text | Should -Match 'approved for allowance reset'
            $text | Should -Not -Match '--remediate'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B.
        It 'no refusal text is rendered while budget remains' {
            $store = script:New-RoundStore -Findings @()
            (Get-ReviewCampaignRoundBudgetState -StoreRoot $store -CampaignId 'cmp-199-x-i001').continuation_available | Should -BeTrue -Because 'one of the floor''s two rounds is left, so the launch is not refused'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B, checked on an empty campaign.
        It 'continuation stays available while budget remains' {
            $store = Join-Path $TestDrive ('store-empty-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
            $state = Get-ReviewCampaignRoundBudgetState -StoreRoot $store -CampaignId 'cmp-199-x-i001'
            $state.rounds_used | Should -Be 0
            $state.continuation_available | Should -BeTrue
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B: a run without a complete review never ends
        # clean, its findings stay open, and the sign-off routes it review-partial.
        It 'a review that produced no valid result gates and never renders as clean at the budget ceiling' {
            $store = script:New-RoundStore -Findings @((script:New-StoredFinding -Id 'finding-00000000000000c1' -Severity 'major')) -Collected $false
            @(Get-ReviewCampaignOpenFindings -StoreRoot $store -CampaignId 'cmp-199-x-i001').Count | Should -Be 1
            (Get-ReviewCampaignLoopState -StoreRoot $store -CampaignId 'cmp-199-x-i001').ended_clean | Should -BeFalse
            $partial = Get-ReviewRunAuthorityFact -StoreRoot $store -CampaignId 'cmp-199-x-i001' -RunId 'run-core-1' -Stage result
            (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-199-x-i001' -CurrentDigest ('c' * 40) -OrderedRunIds @('run-core-1') -Results @($partial)).route | Should -BeExactly 'review-partial'
        }
    }

    Context 'the rendered decision surface (what the human actually reads)' {
        BeforeAll {
            # Feature 203 T008 step (iii): the old menu renderer is deleted (no production caller); the surface the human
            # reads at a stop is Format-ReviewCampaignStopSurface.
            $script:Surface = (script:New-StopSurface -Kind 'a-budget-spent') -join "`n"
            $script:AllSurfaces = @('a-budget-spent', 'b-dispute-or-defer', 'c-judgment', 'd-host-outside-order' | ForEach-Object { (script:New-StopSurface -Kind $_ -NextHost 'copilot') -join "`n" })
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. A for the project name (it belonged to the deleted menu); B for the
        # findings: the stop lists each open finding with its id, severity, title and location.
        It 'names what was found, with locations' {
            $script:Surface | Should -Match 'finding-0123456789abcdef \(major\) Empty store at src/app\.ps1:1'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. Both halves: no minor appears as an open finding at a stop, and the
        # sign-off lists it as a follow-up.
        It 'shows the minors as follow-ups that do not block' {
            $store = script:New-RoundStore -Findings @((script:New-StoredFinding -Id 'finding-00000000000000d2' -Severity 'major' -Title 'retry'), (script:New-StoredFinding -Id 'finding-00000000000000d3' -Severity 'minor' -Title 'wording'))
            $open = @(Get-ReviewCampaignOpenFindings -StoreRoot $store -CampaignId 'cmp-199-x-i001')
            @($open | ForEach-Object { $_.finding_id }) | Should -Be @('finding-00000000000000d2')
            $stopText = (Format-ReviewCampaignStopSurface -Stop ([pscustomobject]@{ stop_kind = 'a-budget-spent'; stop_reason = 'budget-spent'; rounds_used = 2; budget_total = 2 }) -OpenFindings $open) -join "`n"
            $stopText | Should -Not -Match 'finding-00000000000000d3'
            @(Get-ReviewCampaignSignoffFindingLines -StoreRoot $store -CampaignId 'cmp-199-x-i001') | Should -Contain 'Follow-up: finding-00000000000000d3 (minor) wording at src/x.ps1:1'
        }

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B.
        It 'shows the cost and the budget position' {
            $script:Surface | Should -Match '2 of 2 rounds used'
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

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B (class guard): every stop surface.
        It 'FR-015: carries no internal machinery vocabulary' {
            foreach ($surface in $script:AllSurfaces) {
                foreach ($banned in @('crossing', 'mint', 'digest', 'boundary sync', 'verdict capture', 'ratchet', 'terminalize', 'claim-ordered')) {
                    $surface | Should -Not -Match ([regex]::Escape($banned))
                }
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
            # Feature 203 T008 step (iii), maintainer ruling 2026-11-09: a demoted blocker opens no finding, so the loop can end
            # clean with no stop; the required surface is the SIGN-OFF, which names each demotion with the reviewer's original
            # severity and why. B for all five cases, and the code was wrong (nothing live showed demotions).
            $script:DemotedStore = script:New-RoundStore -Findings @(
                (script:New-StoredFinding -Id 'finding-00000000000000e1' -Severity 'minor' -Title 'unvalidated input reaches the shell' -Location 'src/run.ps1:7' -DemotedFrom 'blocking'),
                (script:New-StoredFinding -Id 'finding-00000000000000e2' -Severity 'minor' -Title 'retry ignores the cap' -Location 'src/poll.ps1:3' -DemotedFrom 'major'))
            $script:DemotedLines = @(Get-ReviewCampaignSignoffFindingLines -StoreRoot $script:DemotedStore -CampaignId 'cmp-199-x-i001')
            $script:PlainLines = @(Get-ReviewCampaignSignoffFindingLines -StoreRoot (script:New-RoundStore -Findings @((script:New-StoredFinding -Id 'finding-00000000000000e3' -Severity 'minor' -Title 'wording'))) -CampaignId 'cmp-199-x-i001')
        }

        It 'the sign-off counts each demotion and keeps the reviewer original severity' {
            @($script:DemotedLines | Where-Object { $_ -like 'Demoted:*' }).Count | Should -Be 2
            ($script:DemotedLines -join "`n") | Should -Match 'reported it as blocking'
        }

        It 'a round with no demotions reports zero' {
            @($script:PlainLines | Where-Object { $_ -like 'Demoted:*' }).Count | Should -Be 0
        }

        It 'the sign-off NAMES the demotion, the reviewer original severity, and where it went' {
            $script:DemotedLines | Should -Contain 'Demoted: finding-00000000000000e1 unvalidated input reaches the shell at src/run.ps1:7 - the reviewer reported it as blocking; it was recorded as minor because it states no concrete failure scenario.'
        }

        It 'a round with NO demotions renders no demotion line at all' {
            ($script:PlainLines -join "`n") | Should -Not -Match '(?i)demot'
            $script:PlainLines | Should -Contain 'Follow-up: finding-00000000000000e3 (minor) wording at src/x.ps1:1'
        }

        It 'mixed origins are stated honestly rather than collapsed to one severity' {
            @($script:DemotedLines | Where-Object { $_ -match 'finding-00000000000000e1.*reported it as blocking' }).Count | Should -Be 1
            @($script:DemotedLines | Where-Object { $_ -match 'finding-00000000000000e2.*reported it as major' }).Count | Should -Be 1
        }

        # Class A (the counts are no longer written); what stays: a fact stored before, with its demotion count, still validates.
        It 'a pause fact stored with its demotion count still validates' {
            $fact = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-dem' -TargetDigest ('e' * 40) `
                -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 2) -ObservedAt '2026-08-10T11:00:00Z'
            foreach ($name in @('blocking_count', 'major_count', 'minor_count')) { $fact | Add-Member -NotePropertyName $name -NotePropertyValue 0 }
            $fact | Add-Member -NotePropertyName demoted_count -NotePropertyValue 1
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

        # Feature 203 T008 step (iii), maintainer ruling 2026-11-09 on the 19 cases. B: the fields a stop carries now persist and read back.
        It 'the facts persist and read back through the immutable store' {
            $store = Join-Path ([IO.Path]::GetTempPath()) ('ccr-persist-' + [Guid]::NewGuid().ToString('N'))
            try {
                $pending = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-199-x-i001' -RunId 'run-persist' -TargetDigest ('a' * 40) `
                    -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2) -ObservedAt '2026-08-10T10:00:00Z' -StopKind 'a-budget-spent' -StopReason 'budget-spent'
                $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $pending
                $read = Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId 'cmp-199-x-i001'
                [int]$read.rounds_used | Should -Be 2
                [int]$read.budget_total | Should -Be 2
                [string]$read.stop_kind | Should -BeExactly 'a-budget-spent'
                [string]$read.stop_reason | Should -BeExactly 'budget-spent'
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
