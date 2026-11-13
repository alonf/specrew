$ErrorActionPreference = 'Stop'

# Trace: T001/T002/T003 wiring - FR-002, FR-003, FR-005, FR-015 - against the authorized signoff round's
# SECOND BLOCKING FINDING (run-20260811-093414640-d58e787b).
#
# THE DEFECT, and it is a defect of SEAMS rather than of code. Every piece of the pause protocol existed
# and every piece was green: Resolve-ReviewCampaignPauseDecision built the decision surface,
# Format-ReviewCampaignPauseSurface rendered it, Add-ReviewCampaignRoundPause recorded it,
# Write-ReviewCampaignPauseDecisionFact stored the reply, Test-ReviewCampaignContinuationAuthorized
# judged it, Invoke-ReviewCampaignStopHereLanding composed the landing. Invoke-ReviewCampaignRun even
# returned the pause. And a workspace-wide caller inspection found NO PRODUCTION CALL to three of them,
# because Invoke-ReviewCampaignCommand's explicit field list dropped `pause` on the way out and
# scripts/specrew-review.ps1 rendered only the generic result. The release's P1 acceptance flow shipped
# as disconnected helpers.
#
# WHY EVERY TEST HERE ENTERS AT Invoke-ReviewCampaignCommand. This is the fifth method rule, ruled in on
# this exact finding: ASSERT EVERY CAPABILITY FROM THE COMMAND A CONSUMER TYPES, NOT FROM THE FUNCTION
# THAT IMPLEMENTS IT. A fixture calling Add-ReviewCampaignRoundPause directly would have been green
# throughout the defect, because the defect was never inside a function - it was in the projection
# between two of them. The helper's author tests the helper, the CLI's author tests the CLI, and the
# seam belongs to nobody. So: no test in this file calls a pause helper to set up the state it checks.
# The state is produced by running the command.

Describe 'the pause protocol, reached from the command a consumer runs' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
        # Round A finding 1: a grant is spent only when its cited verdict was typed; the fixture records that verdict.
        foreach ($dependency in @('ConversationCaptureAccessor', 'HumanAuthorityStore')) { . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1')) }
        . (Join-Path $script:RepoRoot 'tests/support/cited-typed-turn.ps1')

        function script:New-PauseRepo {
            param([string]$Root, [int]$Budget = 4)
            New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', [Text.UTF8Encoding]::new($false))
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm initial 2>&1 | Out-Null
            # Feature 203 T008 (FR-003, FR-010): the campaign's budget grant is its only launch authority. Four rounds, the
            # cap these cases were written against, counted from before any round below.
            script:Set-PauseBudget -Root $Root -Total $Budget
            return $Root
        }

        function script:Set-PauseBudget {
            param([string]$Root, [int]$Total)
            $resolution = [pscustomobject]@{
                budget_total = $Total; host_order = @(); host_order_stated = $false; infra_failure_cap = 2
                budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-demo/plan.md'; plan_hash = ('a' * 64)
            }
            $fact = New-ReviewBudgetGrantFact -CampaignId 'cmp-001-demo-i007' -Resolution $resolution -VerdictEntry 'auth-pause-verdict' -ObservedAt '2026-01-01T00:00:00.0000000+00:00'
            $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot (Join-Path $Root '.specrew/review/authority') -Fact $fact
            $null = Add-SpecrewTestLedgerVerdict -ProjectRoot $Root -AuthorizationId 'auth-pause-verdict'
        }

        # A round the counter counts: a published result that collected a complete review (DRIFT-052 item 3).
        function script:Add-SpentRound {
            param([string]$Store, [string]$Campaign, [string]$RunId, [string]$StartedAt, [string]$Digest)
            $result = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $Campaign; run_id = $RunId; target_digest = $Digest; harness_id = 'fixture'
                completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
                currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'fixture'; findings = @()
                started_at = $StartedAt; ended_at = $StartedAt; duration_ms = 60000; examined_paths = @(); review_collected = $true
            }
            Request-ReviewAuthorityClaim -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -TargetLineage 'lin-budget' -ObservedAt $StartedAt | Out-Null
            Publish-ReviewRunResultFact -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -Fact $result | Out-Null
            Complete-ReviewAuthorityClaim -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -TargetLineage 'lin-budget' -Disposition released -ObservedAt $StartedAt | Out-Null
        }

        function script:New-PauseConfig {
            param([string]$Root)
            $path = Join-Path $Root 'authority.json'
            [IO.File]::WriteAllText($path, (([ordered]@{ schema_version = '1.0'; mode = 'campaign' }) | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
            return $path
        }

        # A reviewer that returns one MAJOR finding, so the round genuinely has something to pause over.
        # A clean round would pause too, but a decision surface with nothing on it is the one shape that
        # would not notice if the findings were dropped.
        function script:New-PausePorts {
            param([string]$Root, [string]$External, [string]$RunId, [switch]$Gating)
            $candidate = [pscustomobject][ordered]@{
                schema_version = '1.0'; run_id = $RunId; target_digest = 'unused-overwritten-by-engine'
                completion = 'complete'; verdict = 'findings'; summary = 'pause fixture'
                # THE CANDIDATE FINDING SHAPE, taken from the engine's own rejection message rather than
                # from memory - and it is deliberately NOT the terminal shape. A reviewer may declare
                # local_id, severity, title, description, location and nothing else; finding_id,
                # lineage_id, relevance and resolution are assigned by the engine, precisely so a
                # reviewer cannot self-declare its own identity or resolution.
                #
                # Two wrong drafts before this one, both instructive. The first omitted local_id and the
                # candidate was rejected whole. The second "fixed" it by adding the terminal fields,
                # which the closed candidate contract rejects as unknown-field - a correction that moved
                # further from the contract while looking more complete. Both times the run still
                # returned status 'terminal' with an INVALID result, so the early assertions passed and
                # only a later count disagreed. The engine had the answer the whole time, in
                # result.failure_reason; two rounds of guessing preceded one round of reading it.
                findings = @(
                    [pscustomobject][ordered]@{
                        local_id = 'local-pause'
                        severity = 'major'; title = 'A thing worth your attention'
                        description = $(if ($Gating) { 'Failure scenario: a consumer runs the command on an empty store and it throws instead of returning null.' } else { 'Concretely: when the store is empty the command throws instead of returning null.' })
                        location = 'app.txt:1'
                    }
                )
            }
            $prompt = Join-Path $Root 'prompt.txt'
            [IO.File]::WriteAllText($prompt, 'review the target', [Text.UTF8Encoding]::new($false))
            $harness = [pscustomobject]@{
                id = 'fixture-pause'
                preflight = { param($invocation) [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }
                invoke = {
                    param($invocation, $environment)
                    $payload = $candidate | Select-Object *
                    $payload.target_digest = [string]$invocation.target_digest
                    $payload.run_id = [string]$invocation.run_id
                    [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($payload | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                    [pscustomobject]@{ exit_code = 0; output_activity = $true }
                }.GetNewClosure()
            }
            return [pscustomobject]@{
                target = New-GitReviewTargetPort -OriginRepo $Root -ExternalRoot $External
                harness = $harness
                runtime = New-ReviewFixtureRuntimePort
                verification = New-ReviewFixtureVerificationPort
                clock = New-ReviewSystemClockPort
                prompt_path = $prompt
            }
        }

        function script:Invoke-PauseCommand {
            param([string]$Root, [string]$Config, [string]$RunId, [string]$External, [switch]$Gating)
            return Invoke-ReviewCampaignCommand -RepoRoot $Root -FeatureId '001-demo' -IterationNumber '007' `
                -RunId $RunId -AuthorityConfigPath $Config `
                -Ports (script:New-PausePorts -Root $Root -External $External -RunId $RunId -Gating:$Gating)
        }

        # Feature 203 T008 (DRIFT-052 item 5): a round stops only at (a) to (d). To reach stop (a) through the command, the
        # budget is the floor of 2, one earlier round has collected a review, and this round leaves a gating finding open.
        function script:Invoke-StopARound {
            param([string]$Name, [string]$RunId)
            $root = script:New-PauseRepo -Root (Join-Path $TestDrive $Name) -Budget 2
            $config = script:New-PauseConfig -Root $root
            script:Add-SpentRound -Store (Join-Path $root '.specrew/review/authority') -Campaign 'cmp-001-demo-i007' -RunId ($RunId + '-prior') `
                -StartedAt '2026-08-11T01:00:00.0000000+00:00' -Digest 'digest-prior'
            $run = script:Invoke-PauseCommand -Root $root -Config $config -RunId $RunId -External (Join-Path $TestDrive ($Name + '-ext')) -Gating
            return [pscustomobject]@{ root = $root; config = $config; store = (Join-Path $root '.specrew/review/authority'); run = $run }
        }

        # A launch whose reviewer must never be reached: the refusal has to come before any harness work.
        function script:Invoke-RefusedLaunch {
            param([string]$Root, [string]$Config, [string]$RunId, [string]$External)
            return Invoke-ReviewCampaignCommand -RepoRoot $Root -FeatureId '001-demo' -IterationNumber '007' `
                -RunId $RunId -AuthorityConfigPath $Config `
                -Ports ([pscustomobject]@{
                        target = New-GitReviewTargetPort -OriginRepo $Root -ExternalRoot $External
                        harness = [pscustomobject]@{
                            id = 'must-not-run'
                            preflight = { param($invocation) throw 'harness-must-not-be-reached' }
                            invoke = { param($invocation, $environment) throw 'harness-must-not-be-reached' }
                        }
                        runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                        clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $Root 'prompt.txt')
                    })
        }

        # The crew's fix: the files change, so the next round has something new to review.
        function script:Invoke-CrewFix {
            param([string]$Root, [string]$Text)
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), $Text, [Text.UTF8Encoding]::new($false))
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm $Text 2>&1 | Out-Null
        }
    }

    It 'a completed round RETURNS the decision surface through the public command (it was projected away)' {
        # Feature 203 T008 (DRIFT-052 item 5; maintainer classification 2026-11-09, class A): a round within the budget records
        # nothing; the round that spends the budget with a finding open is stop (a), and the public command returns its
        # FR-011 surface. The projection defect this case was written for is the same: the field must survive the command.
        $stop = script:Invoke-StopARound -Name 'surface' -RunId 'run-surface-a'
        $run = $stop.run
        [string]$run.status | Should -Be 'terminal' -Because 'the fixture reviewer completes; if this is not terminal the rest of the assertions are about the wrong thing'
        # STATUS IS NOT VALIDITY: a rejected candidate still publishes a terminal result.
        [string]$run.result.validation | Should -Be 'valid' -Because ('the candidate contract rejected the fixture: ' + [string]$run.result.failure_reason)
        [string]$run.result.completion | Should -Be 'complete'
        $run.PSObject.Properties['pause'] | Should -Not -BeNullOrEmpty -Because 'THE defect: the projection carried no pause field at all'
        [bool]$run.pause.recorded | Should -BeTrue
        [string]$run.pause.stop_kind | Should -BeExactly 'a-budget-spent'
        $surface = @($run.pause.surface) -join "`n"
        $surface | Should -Match 'Why: the review budget is spent \(2 of 2 rounds\) and 1 finding is still open\.'
        $surface | Should -Match 'A thing worth your attention' -Because 'the stop names the finding it is about'
        $surface | Should -Match '(?m)^\s+approved for allowance reset - ' -Because 'the one continuing line, with its consequence'
        $surface | Should -Match '(?m)^\s+stop the review here - '
        $surface | Should -Not -Match '(?i)run another round|approved for review round' -Because 'no stop asks for a round (FR-006)'
    }

    It 'A GATING ROUND RENDERS AS GATING - the counts are per finding, not per array' {
        # THE WORST DEFECT THIS ITERATION FOUND, and it was only ever reachable from the command.
        #
        # Add-ReviewCampaignRoundPause built its decision with
        #   @(Get-ReviewAuthorityProperty -Object $Result -Name 'findings')
        # and that accessor returns collections with `Write-Output -NoEnumerate`. Wrapping the CALL in
        # @() therefore produced an array of ONE element whose type is Object[] - the findings array
        # itself. The wrapper has no `severity`, so it fell past the blocking/major test into the minor
        # bucket, and EVERY round reported blocking=0, major=0, minor=1, demoted=0, gating=FALSE
        # regardless of what the reviewer found. A round with two blocking findings rendered
        # "Nothing found that needs your attention" and recommended stopping here.
        #
        # Two findings, not one, on purpose: with a single finding the wrong answer and the right answer
        # are both "1", and this test would have passed while the surface was inverted.
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): the same property at stop (a), the stop a gating
        # round reaches when it spends the budget - floor of 2, one earlier round already collected.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'gating') -Budget 2
        $config = script:New-PauseConfig -Root $root
        script:Add-SpentRound -Store (Join-Path $root '.specrew/review/authority') -Campaign 'cmp-001-demo-i007' -RunId 'run-gating-prior' `
            -StartedAt '2026-08-11T01:00:00.0000000+00:00' -Digest 'digest-prior'
        $external = Join-Path $TestDrive 'gating-ext'
        $prompt = Join-Path $root 'prompt.txt'
        [IO.File]::WriteAllText($prompt, 'review the target', [Text.UTF8Encoding]::new($false))
        $harness = [pscustomobject]@{
            id = 'fixture-gating'
            preflight = { param($invocation) [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }
            invoke = {
                param($invocation, $environment)
                # Concrete failure scenarios, so the T005 contract lets them GATE rather than demoting.
                $payload = [pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = [string]$invocation.run_id; target_digest = [string]$invocation.target_digest
                    completion = 'complete'; verdict = 'findings'; summary = 'two blocking findings'
                    findings = @(
                        [pscustomobject][ordered]@{ local_id = 'b1'; severity = 'blocking'; title = 'First blocker'
                            description = 'Failure scenario: a consumer runs the command on a fresh project and it throws because the store directory does not exist.'; location = 'app.txt:1' }
                        [pscustomobject][ordered]@{ local_id = 'b2'; severity = 'blocking'; title = 'Second blocker'
                            description = 'Failure scenario: the second round reuses a spent grant, so the budget is bypassed and spend continues unbounded.'; location = 'app.txt:2' }
                    )
                }
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($payload | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }
        }
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId 'run-gating' -AuthorityConfigPath $config `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot $external
                    harness = $harness; runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = $prompt
                })

        [string]$run.result.validation | Should -Be 'valid' -Because ('candidate rejected: ' + [string]$run.result.failure_reason)
        [string]$run.pause.stop_kind | Should -BeExactly 'a-budget-spent'
        $surface = @($run.pause.surface) -join "`n"
        $surface | Should -Match 'What happened: 2 of 2 rounds used; 2 findings open\.' -Because 'two findings, counted one by one'
        $surface | Should -Not -Match '1 finding open' -Because 'the wrapper-as-one-finding defect counted an array as a finding'
        $surface | Should -Match 'First blocker'
        $surface | Should -Match 'Second blocker'
    }

    It 'an UNANSWERED pause stops the next round from spending (FR-003, ledger obs-6)' {
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): an open stop refuses the next launch and spends
        # nothing.
        $stop = script:Invoke-StopARound -Name 'block' -RunId 'run-block-a'
        [string]$stop.run.pause.stop_kind | Should -BeExactly 'a-budget-spent'
        $spentBefore = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $stop.store -CampaignId 'cmp-001-demo-i007' -Kind spend).Count

        # The SECOND invocation is the whole point. Before the pause wiring it ran a full review.
        $second = script:Invoke-RefusedLaunch -Root $stop.root -Config $stop.config -RunId 'run-block-b' -External (Join-Path $TestDrive 'block-ext-b')
        [string]$second.status | Should -Be 'paused'
        [bool]$second.invoked | Should -BeFalse
        [string]$second.reason | Should -BeExactly 'review-stop-open:a-budget-spent'
        [bool]$second.continuation_authorized | Should -BeFalse
        @($second.pause_surface).Count | Should -BeGreaterThan 0 -Because 'a refusal that does not re-show the question leaves the consumer with nothing to answer'
        (@($second.pause_surface) -join "`n") | Should -Match 'Your decision: '
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $stop.store -CampaignId 'cmp-001-demo-i007' -Kind spend).Count | Should -Be $spentBefore -Because 'nothing is spent'
    }

    It 'ANSWERING fix-and-continue authorizes exactly one further round' {
        # Feature 203 T008 (FR-006, FR-010; maintainer classification 2026-11-09, class A): fix-and-continue is removed. After
        # a fix-needed round the crew's fix lets exactly one round run, and unchanged files are refused.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'continue')
        $config = script:New-PauseConfig -Root $root
        $first = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-cont-a' -External (Join-Path $TestDrive 'cont-ext-a') -Gating
        [string]$first.status | Should -Be 'terminal'
        [bool]$first.pause.recorded | Should -BeFalse -Because 'a fix-needed round within the budget is not a stop'

        $unchanged = script:Invoke-RefusedLaunch -Root $root -Config $config -RunId 'run-cont-b' -External (Join-Path $TestDrive 'cont-ext-b')
        [string]$unchanged.reason | Should -BeExactly 'review-tree-unchanged' -Because 'the fix has not been made yet'
        [bool]$unchanged.invoked | Should -BeFalse

        script:Invoke-CrewFix -Root $root -Text 'fixed once'
        $second = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-cont-c' -External (Join-Path $TestDrive 'cont-ext-c') -Gating
        [string]$second.status | Should -Be 'terminal' -Because 'the fix is what lets the next round run'
        [bool]$second.invoked | Should -BeTrue

        $again = script:Invoke-RefusedLaunch -Root $root -Config $config -RunId 'run-cont-d' -External (Join-Path $TestDrive 'cont-ext-d')
        [string]$again.reason | Should -BeExactly 'review-tree-unchanged' -Because 'one fix, exactly one round'
    }

    It 'THE PUBLIC COMMAND refuses a fifth round of a four-round budget even when the latest pause says fix-and-continue' {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'budget-ceiling')
        $config = script:New-PauseConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-001-demo-i007'

        # Feature 203 T008 (maintainer classification 2026-11-09, class B): the same cap, reached through fixes - four rounds
        # that each collected a review, no pause answer anywhere (fix-and-continue is removed).
        foreach ($round in 1..4) {
            script:Add-SpentRound -Store $store -Campaign $campaign -RunId "run-budget-$round" -StartedAt "2026-08-11T0$round`:00:00.0000000+00:00" -Digest "digest-$round"
        }

        $fifth = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId 'run-budget-5' -AuthorityConfigPath $config `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'budget-ceiling-ext')
                    harness = [pscustomobject]@{
                        id = 'must-not-run'
                        preflight = { param($invocation) throw 'budget-refusal-must-precede-harness-preflight' }
                        invoke = { param($invocation, $environment) throw 'budget-refusal-must-precede-harness-invocation' }
                    }
                    runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $root 'prompt.txt')
                })

        [string]$fifth.status | Should -Be 'not-started'
        [bool]$fifth.invoked | Should -BeFalse
        [string]$fifth.reason | Should -Be 'review-round-budget-exhausted'
        [string]$fifth.continuation_reason | Should -Be 'review-round-budget-exhausted'
        [string]$fifth.reason_detail | Should -Match '4 of 4 rounds'
        [string]$fifth.reason_detail | Should -Match 'approved for allowance reset'
    }

    It 'THE PUBLIC COMMAND fails closed before harness work when the authority store is corrupt' -ForEach @(
        @{ name = 'invalid-run-directory'; arrange = 'invalid-directory' }
        @{ name = 'result-path-identity-mismatch'; arrange = 'identity-mismatch' }
    ) {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive "corrupt-$name")
        $config = script:New-PauseConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-001-demo-i007'
        $runsRoot = Join-Path $store "campaigns/$campaign/runs"
        New-Item -ItemType Directory -Path $runsRoot -Force | Out-Null

        if ($arrange -ceq 'invalid-directory') {
            New-Item -ItemType Directory -Path (Join-Path $runsRoot 'INVALID!') -Force | Out-Null
        }
        else {
            $fact = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = 'run-original'; target_digest = 'digest-corrupt'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'pass'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $true; failure_reason = $null; summary = 'valid fact moved under a different run path'
                findings = @(); started_at = '2026-08-11T01:00:00Z'; ended_at = '2026-08-11T01:01:00Z'; duration_ms = 60000
            }
            Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId 'run-original' -Fact $fact | Out-Null
            Move-Item -LiteralPath (Join-Path $runsRoot 'run-original') -Destination (Join-Path $runsRoot 'run-other')
        }

        $attempt = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId "run-after-$name" -AuthorityConfigPath $config `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive "corrupt-$name-ext")
                    harness = [pscustomobject]@{
                        id = 'must-not-run'
                        preflight = { param($invocation) throw 'corrupt-store-refusal-must-precede-harness-preflight' }
                        invoke = { param($invocation, $environment) throw 'corrupt-store-refusal-must-precede-harness-invocation' }
                    }
                    runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $root 'prompt.txt')
                })

        [string]$attempt.status | Should -Be 'paused'
        [bool]$attempt.invoked | Should -BeFalse
        [string]$attempt.reason | Should -Be 'review-authority-store-invalid'
        [string]$attempt.continuation_reason | Should -Be 'review-authority-store-invalid'
        (@($attempt.pause_surface) -join "`n") | Should -Match 'could not read its review authority safely'
    }

    It 'ANSWERING stop-here or abandon does NOT authorize a further round' -ForEach @(
        @{ choice = 'stop-here'; refusal = 'review-stopped-here' }
        @{ choice = 'abandon'; refusal = 'review-stop-open:a-budget-spent' }
    ) {
        # Feature 203 T008 (maintainer classification and mapping, 2026-11-09, class B): `stop the review here` closes the
        # campaign for good (fix 6) - even a later fix does not let a round run. `abandon` is retired the way the round
        # approval is: it cannot be recorded, so it answers nothing and the stop still waits.
        $stop = script:Invoke-StopARound -Name "end-$choice" -RunId "run-end-$choice"
        [string]$stop.run.pause.stop_kind | Should -BeExactly 'a-budget-spent'
        $record = { Write-ReviewCampaignPauseDecisionFact -StoreRoot $stop.store -Fact (
                New-ReviewCampaignPauseDecisionFact -CampaignId ([string]$stop.run.campaign_id) -RunId ([string]$stop.run.pause.fact.run_id) `
                    -Choice $choice -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))) | Out-Null }
        if ($choice -ceq 'abandon') { $record | Should -Throw -Because 'abandon is no longer an answer anything records' }
        else { & $record }

        script:Invoke-CrewFix -Root $stop.root -Text "fixed after $choice"
        $second = script:Invoke-RefusedLaunch -Root $stop.root -Config $stop.config -RunId "run-end-$choice-b" -External (Join-Path $TestDrive "end-ext2-$choice")
        [string]$second.status | Should -BeIn @('paused', 'not-started')
        [bool]$second.invoked | Should -BeFalse
        [string]$second.reason | Should -BeExactly $refusal
    }

    It 'the pending pause is the CHRONOLOGICALLY newest, not the lexicographically last run-id' {
        # Maintainer ruling 2026-08-11. Get-ReviewCampaignPendingPause enumerated run directories and
        # sorted them LEXICOGRAPHICALLY, then took the last. Run ids need not sort chronologically -
        # explicit ids are supported - and the T067 store really does hold `run-review-signoff-10` and
        # `run-review-signoff-9`, which sort BACKWARDS: "...-9" > "...-10" as text.
        #
        # THE CONSEQUENCE IS A WEDGE, NOT A COSMETIC MIS-RENDER, which is why failing closed is not
        # enough here. --pause-choice records the human's reply against the mis-picked run_id; the
        # continuation guard then reads the genuinely newest pause, correctly finds it unanswered, and
        # refuses. Nothing is spent - but the consumer answers, is told it worked, and the next run
        # refuses identically. They can answer forever and nothing moves.
        #
        # Written against the store directly rather than through two live rounds because the defect is
        # in ORDER SELECTION over recorded facts, and two fixture rounds cannot produce the backwards
        # pair without inventing the ids anyway. The ids and their real ordering are transcribed from
        # the T067 store, not composed.
        $store = Join-Path $TestDrive 'sortstore'
        $campaign = 'cmp-sort-i001'

        # Deliberately combines both ordering traps: the run ids sort backwards, and the older
        # timestamp uses Z while the newer instant uses +00:00 with fractional seconds. Lexical
        # timestamp ordering puts Z after '.', so only parsed-instant ordering gets both right.
        Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact (
            New-ReviewCampaignPendingPauseFact -CampaignId $campaign -RunId 'run-review-signoff-9' -TargetDigest 'digest-older' `
                -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 1) `
                -ObservedAt '2026-08-02T00:00:00Z') | Out-Null
        Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact (
            New-ReviewCampaignPendingPauseFact -CampaignId $campaign -RunId 'run-review-signoff-10' -TargetDigest 'digest-newer' `
                -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 4 -ElapsedMinutes 2) `
                -ObservedAt '2026-08-02T00:00:00.5000000+00:00') | Out-Null

        # The premise, asserted so the test cannot quietly stop testing anything if the ids ever change.
        ('run-review-signoff-9' -gt 'run-review-signoff-10') | Should -BeTrue -Because 'these ids sort backwards as text; that is the entire trap'
        ('2026-08-02T00:00:00Z' -gt '2026-08-02T00:00:00.5000000+00:00') | Should -BeTrue -Because 'valid equivalent-offset timestamp spellings also sort backwards as text'

        $pending = Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId $campaign
        [string]$pending.run_id | Should -Be 'run-review-signoff-10' -Because 'the newest pause is the one the human is actually being asked about'

        # The two selectors must never disagree about which pause is newest - they now read one ordering.
        $latest = Get-ReviewCampaignLatestPause -StoreRoot $store -CampaignId $campaign
        [string]$latest.run_id | Should -Be ([string]$pending.run_id)

        # And once the newest is answered, the pending selector must fall silent rather than reaching
        # back to the older unanswered-looking one by a different sort. Feature 203 T008 (maintainer classification
        # 2026-11-09, class B): the answer is `stop-here`, the one pause answer left; fix-and-continue can no longer be recorded.
        Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (
            New-ReviewCampaignPauseDecisionFact -CampaignId $campaign -RunId 'run-review-signoff-10' `
                -Choice 'stop-here' -ObservedAt '2026-08-02T01:00:00.0000000+00:00') | Out-Null
        [string](Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId $campaign).run_id | Should -Be 'run-review-signoff-9' -Because 'the older pause is genuinely still unanswered; it becomes pending only once the newer one is answered'
        [string](Get-ReviewCampaignLatestPause -StoreRoot $store -CampaignId $campaign).run_id | Should -Be 'run-review-signoff-10' -Because 'latest is about recency, pending is about answeredness; they are different questions over the same order'
    }

    It 'STOP-HERE REFUSES on a round whose RESULT gates, even when the pause fact says nothing blocks' {
        # THE LIVE-STORE HAZARD (maintainer ruling 2026-08-11), reproduced from the real facts.
        #
        # DRIFT-199-I001-033 wrote a pending-pause fact into the live campaign store reading
        # blocking=0, major=0, minor=1, "Nothing here blocks you. Stopping here saves the minor findings
        # as follow-ups" - for run-20260811-093414640-d58e787b, whose result.json holds 8 findings: 2
        # BLOCKING and 5 MAJOR. The code fix could not correct a fact already written, because authority
        # facts are immutable by design and that design is right. So the surface a maintainer was about
        # to read actively RECOMMENDED the option that completes sign-off on two blocking findings.
        #
        # The counts below are TRANSCRIBED from that store, not composed, so this test reproduces the
        # real hazard rather than an imagined one.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'stophere')
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-stop-i001'
        $runId = 'run-gating-result'

        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-stop' -ObservedAt '2026-08-11T09:00:00Z' | Out-Null
        $findings = @(
            [pscustomobject][ordered]@{ finding_id = 'finding-b1'; source_local_id = 'b1'; lineage_id = 'lin-stop'; severity = 'blocking'; title = 'Package omits a runtime file'; description = 'Failure scenario: a packaged install throws on first use.'; location = 'Specrew.psd1:1'; relevance = 'current'; resolution = 'open' }
            [pscustomobject][ordered]@{ finding_id = 'finding-b2'; source_local_id = 'b2'; lineage_id = 'lin-stop'; severity = 'blocking'; title = 'Pause protocol unreachable'; description = 'Failure scenario: the consumer never sees a decision surface.'; location = 'cli.ps1:1'; relevance = 'current'; resolution = 'open' }
            [pscustomobject][ordered]@{ finding_id = 'finding-m1'; source_local_id = 'm1'; lineage_id = 'lin-stop'; severity = 'major'; title = 'Restored slot not disclosed'; description = 'Failure scenario: the human mints an authorization they did not need.'; location = 'cli.ps1:2'; relevance = 'current'; resolution = 'open' }
        )
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-stop'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'gating round'; findings = $findings
                started_at = '2026-08-11T09:00:00Z'; ended_at = '2026-08-11T09:25:00Z'; duration_ms = 1500000
            }) | Out-Null

        # THE LYING SUMMARY, byte-for-byte in shape with the one in the live store.
        Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $campaign; run_id = $runId
                target_digest = 'digest-stop'; blocking_count = 0; major_count = 0; minor_count = 1
                demoted_count = 0; rounds_used = 2; budget_total = 4; elapsed_minutes = 25.0
                recommendation = 'Nothing here blocks you. Stopping here saves the minor findings as follow-ups.'
                observed_at = '2026-08-11T09:47:53.0259184+00:00'
            }) | Out-Null

        # Ports that MUST NOT RUN. A refusal has to happen before the frozen-tree check, before the
        # residual acceptance is recorded, and before the gate is synced - otherwise "refused" still
        # leaves an accept fact behind for the gate to find later.
        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef 'ref-stop' `
            -Rationale 'accepting residuals' `
            -VerifyPort { param($ctx) throw 'verification-must-not-run-on-a-gating-round' } `
            -AcceptPort { param($ctx) throw 'acceptance-must-not-be-recorded-on-a-gating-round' } `
            -GateSyncPort { param($ctx) throw 'gate-must-not-be-synced-on-a-gating-round' }

        [bool]$landing.landed | Should -BeFalse -Because 'the RESULT holds two blocking findings, whatever the pause fact says'
        # ARM 1 by name. Blocking always refuses - accepting one as a residual defeats the severity -
        # and it fires BEFORE the consent check, which is why the live fact is closed by this arm rather
        # than by the mismatch arm.
        [string]$landing.reason | Should -Match 'stop-here-refused-blocking-findings'
        [string]$landing.reason | Should -Match 'blocking=2'
        [string]$landing.message | Should -Match '(?i)must be fixed before sign-off' -Because 'blocking and mismatch mean different things to a human and must not read alike'

        # And it names the next step rather than only refusing - a prohibition with no way forward is
        # how the stop-block lost its action line.
        $text = [string]$landing.message
        $text | Should -Match '(?i)option 1'

        # Nothing was accepted. This is the assertion that matters most: a refusal that still left a
        # human-disposition fact behind would let the gate allow sign-off on the next read.
        @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $store -CampaignId $campaign -RunId $runId).Count |
            Should -Be 0 -Because 'a refused landing must leave no acceptance behind'
    }

    It 'STOP-HERE PERMITS majors the human actually SAW, and REFUSES the ones they did not' -ForEach @(
        @{ case = 'matched'; shownMajor = 2; shouldLand = $true }
        @{ case = 'mismatched'; shownMajor = 0; shouldLand = $false }
    ) {
        # THE CORRECTED RULING (maintainer, 2026-08-11). The first version of this guard refused on ANY
        # major, which would have left stop-here technically present and practically dead: majors are
        # exactly what it exists to accept as residuals - the decision surface itself says "Look at the
        # major findings; fix what matters to you, then stop here" - and a minor-only round never needed
        # stop-here at all, because minors do not gate.
        #
        # The danger in the live store was never that majors might be accepted. It was that the human
        # was told there were NONE. So the axis is not severity, it is whether they saw it:
        #
        #     CONSENT GIVEN AGAINST FALSE INFORMATION IS NOT CONSENT.
        #
        # Both arms are driven from ONE fixture with only the shown count varying, so the permit and the
        # refusal are proven to differ by exactly that and nothing else.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive "consent-$case")
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = "cmp-consent-$case-i001"
        $runId = "run-consent-$case"

        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-consent' -ObservedAt '2026-08-11T09:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = "digest-$case"
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'two majors, no blocking'
                findings = @(
                    [pscustomobject][ordered]@{ finding_id = 'finding-c1'; source_local_id = 'c1'; lineage_id = 'lin-consent'; severity = 'major'; title = 'First major'; description = 'Failure scenario: a retry is wasted on a partial label.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open' }
                    [pscustomobject][ordered]@{ finding_id = 'finding-c2'; source_local_id = 'c2'; lineage_id = 'lin-consent'; severity = 'major'; title = 'Second major'; description = 'Failure scenario: the budget line reads zero after a release.'; location = 'app.txt:2'; relevance = 'current'; resolution = 'open' }
                )
                started_at = '2026-08-11T09:00:00Z'; ended_at = '2026-08-11T09:10:00Z'; duration_ms = 600000
            }) | Out-Null

        Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'pending-pause'; campaign_id = $campaign; run_id = $runId
                target_digest = "digest-$case"; blocking_count = 0; major_count = $shownMajor; minor_count = 0
                demoted_count = 0; rounds_used = 1; budget_total = 4; elapsed_minutes = 10.0
                recommendation = 'Look at the major findings; fix what matters to you, then stop here.'
                observed_at = '2026-08-11T09:11:00.0000000+00:00'
            }) | Out-Null

        $reached = [Collections.Generic.List[string]]::new()
        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef "ref-$case" `
            -Rationale 'majors read and carried as follow-ups' `
            -VerifyPort { param($ctx) $reached.Add('verify') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'verified' } }.GetNewClosure() `
            -AcceptPort { param($ctx) $reached.Add('accept') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'residuals-accepted' } }.GetNewClosure() `
            -GateSyncPort { param($ctx) $reached.Add('gate') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'signoff-gate-allow' } }.GetNewClosure()

        [bool]$landing.landed | Should -Be $shouldLand

        if ($shouldLand) {
            @($reached) -join ',' | Should -Be 'verify,accept,gate' -Because 'the designed flow must actually run when the human saw the real number'
            # Round-11 finding (DRIFT-199-I001-118): this landing just accepted TWO MAJOR residuals,
            # and the completion sentence said "Any remaining minor findings" - telling the human who
            # had just consented to majors that nothing above minor remained. The sentence must not
            # qualify the residuals with a severity the landing never established.
            [string]$landing.message | Should -Match '(?i)remaining findings' -Because 'the residuals here are major, so the phrase must be severity-neutral'
            [string]$landing.message | Should -Not -Match '(?i)minor findings' -Because 'naming only minors misstates what the human accepted'
        }
        else {
            @($reached).Count | Should -Be 0 -Because 'a refusal must happen before the tree is verified or anything is accepted'
            [string]$landing.reason | Should -Match 'stop-here-refused-summary-mismatch'
            [string]$landing.reason | Should -Match 'shown=0;actual=2'
            # ARM 3 must NOT read like arm 1. This is the sentence that would have saved the maintainer:
            # the problem is not that the findings are unacceptable, it is that the answer was not
            # informed - so the next step is to SEE the real numbers, not to fix something.
            [string]$landing.message | Should -Match '(?i)does not match what this round found'
            [string]$landing.message | Should -Match '(?i)cannot treat your answer as informed'
            [string]$landing.message | Should -Not -Match '(?i)must be fixed before sign-off' -Because 'collapsing the mismatch into the blocking sentence loses the one fact the human needs'
        }
    }

    It 'STOP-HERE REFUSES majors when NO summary was ever recorded (consent cannot be verified)' {
        # The third way consent can be absent: not wrong, but missing. A landing invoked on a round that
        # never produced a pause fact has no record of what the human was shown, so it cannot claim they
        # were informed. Fails closed for the same reason as an unreadable result.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'consent-absent')
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-consent-absent-i001'
        $runId = 'run-consent-absent'
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-absent' -ObservedAt '2026-08-11T09:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-absent'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'one major, no pause recorded'
                findings = @([pscustomobject][ordered]@{ finding_id = 'finding-a1'; source_local_id = 'a1'; lineage_id = 'lin-absent'; severity = 'major'; title = 'A major'; description = 'Failure scenario: the surface never rendered.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open' })
                started_at = '2026-08-11T09:00:00Z'; ended_at = '2026-08-11T09:05:00Z'; duration_ms = 300000
            }) | Out-Null

        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef 'ref-absent' `
            -Rationale 'accepting residuals' `
            -VerifyPort { param($ctx) throw 'must-not-run' } `
            -AcceptPort { param($ctx) throw 'must-not-run' } `
            -GateSyncPort { param($ctx) throw 'must-not-run' }

        [bool]$landing.landed | Should -BeFalse
        [string]$landing.reason | Should -Match 'stop-here-refused-consent-unverifiable'
    }

    It 'STOP-HERE FAILS CLOSED when the result cannot be read at all' {
        # A sign-off that cannot see what it is signing off is the failure this feature exists to
        # prevent, so an absent result refuses rather than falling forward.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'stophere-missing')
        $store = Join-Path $root '.specrew/review/authority'
        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId 'cmp-missing-i001' -RunId 'run-missing' -AuthorizedBy 'human' `
            -AuthorizationRef 'ref-missing' -Rationale 'accepting residuals' `
            -VerifyPort { param($ctx) throw 'must-not-run' } `
            -AcceptPort { param($ctx) throw 'must-not-run' } `
            -GateSyncPort { param($ctx) throw 'must-not-run' }

        [bool]$landing.landed | Should -BeFalse
        [string]$landing.reason | Should -Match 'stop-here-result-unavailable'
    }

    It 'STOP-HERE STILL COMPLETES on a clean round - the guard refuses gating, not stopping' {
        # The positive half (rule 4). Four prohibitions above would be satisfied by a landing that
        # refuses everything, which would break the option the feature exists to offer.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'stophere-clean')
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-clean-i001'
        $runId = 'run-clean'
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-clean' -ObservedAt '2026-08-11T09:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-clean'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'minor only'
                findings = @([pscustomobject][ordered]@{ finding_id = 'finding-n1'; source_local_id = 'n1'; lineage_id = 'lin-clean'; severity = 'minor'; title = 'A follow-up'; description = 'Saved as a follow-up.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open' })
                started_at = '2026-08-11T09:00:00Z'; ended_at = '2026-08-11T09:05:00Z'; duration_ms = 300000
            }) | Out-Null

        $reached = [Collections.Generic.List[string]]::new()
        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef 'ref-clean' `
            -Rationale 'minor findings accepted as follow-ups' `
            -VerifyPort { param($ctx) $reached.Add('verify') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'verified' } }.GetNewClosure() `
            -AcceptPort { param($ctx) $reached.Add('accept') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'residuals-accepted' } }.GetNewClosure() `
            -GateSyncPort { param($ctx) $reached.Add('gate') | Out-Null; [pscustomobject]@{ ok = $true; reason = 'signoff-gate-allow' } }.GetNewClosure()

        [bool]$landing.landed | Should -BeTrue -Because 'a minor-only round is exactly what stop-here is for'
        @($reached) -join ',' | Should -Be 'verify,accept,gate' -Because 'the guard must pass THROUGH to the chain, in order, not short-circuit it'
    }

    It 'A REFUSED stop-here leaves the pause ANSWERABLE; a successful one does not' {
        # Round-3 blocking finding 1. The CLI recorded the immutable pause-decision BEFORE attempting
        # the landing, so a refused landing left the human holding a spent answer: the command reports
        # no round waiting (answered pauses are excluded from Get-ReviewCampaignPendingPause) while the
        # recorded choice also refuses another round. Wedged - and the landing's own message told them
        # to choose "stop here" again, which could no longer be submitted.
        #
        # The gating precondition ruled in this morning made it reachable rather than theoretical: it
        # ADDED refusal arms, so my own safety fix increased the chance of hitting this one.
        #
        # BOTH DIRECTIONS, as ruled - a prohibition alone would be satisfied by never recording at all.
        $store = Join-Path $TestDrive 'answerable'
        $campaign = 'cmp-answerable-i001'

        # (a) refused: no decision written -> the pause is still pending and can be answered again.
        Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact (
            New-ReviewCampaignPendingPauseFact -CampaignId $campaign -RunId 'run-refused' -TargetDigest 'digest-refused' `
                -Decision (Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 4 -ElapsedMinutes 1) `
                -ObservedAt '2026-08-11T10:00:00.0000000+00:00') | Out-Null
        [string](Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId $campaign).run_id |
            Should -Be 'run-refused' -Because 'a refused landing must leave the question open'

        # (b) succeeded: decision written -> the pause is answered and no longer pending.
        Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (
            New-ReviewCampaignPauseDecisionFact -CampaignId $campaign -RunId 'run-refused' -Choice 'stop-here' `
                -ObservedAt '2026-08-11T10:05:00.0000000+00:00') | Out-Null
        Get-ReviewCampaignPendingPause -StoreRoot $store -CampaignId $campaign |
            Should -BeNullOrEmpty -Because 'a landed stop-here really is answered, and must not be re-answerable'

        # THE ORDERING ITSELF, which is what actually decides recoverability. Asserted on the source
        # because the defect was neither function being wrong - it was which one ran first.
        $cli = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Raw
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): --pause-choice stop-here is now a relay, and the
        # command has two `stop-here` branches - one loads the capture store, one lands. The guard anchors on the one that
        # lands, so it keeps checking what it always did: the answer is spent only after the landing succeeds.
        $branch = [regex]::Match($cli, "(?s)if \(\`$choice -ceq 'stop-here'\) \{\s*\r?\n\s*\`$rationale = .*?\n                \}")
        $branch.Success | Should -BeTrue -Because 'the guard must anchor on the real stop-here landing branch'
        $landingAt = $branch.Value.IndexOf('Invoke-ReviewCampaignStopHereLanding')
        $writeAt = $branch.Value.IndexOf('Write-ReviewCampaignPauseDecisionFact')
        $landingAt | Should -BeGreaterThan -1
        $writeAt | Should -BeGreaterThan -1
        $landingAt | Should -BeLessThan $writeAt -Because 'the answer must be spent only AFTER the attempt it authorizes has succeeded'
        $branch.Value | Should -Match '(?i)has NOT been used up' -Because 'the human must be told the answer survived, or they cannot know retrying is possible'
    }

    It 'A PRE-INVOCATION FAILURE does not consume the continuation decision (FR-014)' {
        # Feature 203 T008 (maintainer classification 2026-11-09, class B): a failure before the reviewer starts leaves the
        # rounds used and the open stop untouched. Round-3 blocking finding 2's property, with the stop in place of the
        # numbered answer: a run record that never reached a reviewer is FR-014 working, and it must not count.
        $stop = script:Invoke-StopARound -Name 'preinvoke' -RunId 'run-pre-a'
        $campaign = [string]$stop.run.campaign_id
        $usedBefore = [int](Get-ReviewCampaignRoundBudgetState -StoreRoot $stop.store -CampaignId $campaign).rounds_used
        $usedBefore | Should -Be 2
        [string](Get-ReviewCampaignOpenStop -StoreRoot $stop.store -CampaignId $campaign).run_id | Should -BeExactly 'run-pre-a'

        $failedAt = [DateTimeOffset]::UtcNow.AddMinutes(1).ToString('o')
        Request-ReviewAuthorityClaim -StoreRoot $stop.store -CampaignId $campaign -RunId 'run-pre-failed' -TargetLineage ([string]$stop.run.target_lineage) -ObservedAt $failedAt | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $stop.store -CampaignId $campaign -RunId 'run-pre-failed' -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = 'run-pre-failed'; target_digest = 'digest-pre'
                harness_id = 'fixture'; completion = 'none'; verdict = 'incomplete'; runtime_outcome = 'preflight-failed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'not-produced'
                can_approve_current = $false; failure_reason = 'preflight-failed:verification'; summary = 'never invoked'
                findings = @(); started_at = $failedAt; ended_at = $failedAt; duration_ms = 30000
            }) | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $stop.store -CampaignId $campaign -RunId 'run-pre-failed' -TargetLineage ([string]$stop.run.target_lineage) -Disposition released -ObservedAt $failedAt | Out-Null

        [int](Get-ReviewCampaignRoundBudgetState -StoreRoot $stop.store -CampaignId $campaign).rounds_used | Should -Be $usedBefore -Because 'a run that never reached a reviewer used no round'
        [string](Get-ReviewCampaignOpenStop -StoreRoot $stop.store -CampaignId $campaign).run_id | Should -BeExactly 'run-pre-a' -Because 'the stop the human is answering is still the one waiting'
    }

    It 'A COMPLETED ROUND WITH NO PAUSE RECORD fails CLOSED instead of letting the next round spend' {
        # Round-3 blocking finding 3. Recording the pause is deliberately forgiving so a write failure
        # cannot destroy a review the human paid for. That was harmless while nothing read pause facts;
        # the continuation guard reads them, so the same tolerance became an open door - no pause, no
        # brake, and the next command reserves and invokes another reviewer with nobody having answered.
        #
        # ADDING A CONSUMER CHANGES THE RISK OF AN EXISTING TOLERANCE. The fail-soft was not wrong
        # before and is not wrong now; what changed is that something now depends on its output.
        #
        # Feature 203 T008 (fix 7; maintainer classification 2026-11-09, class A in its letter, B in what it protects):
        # rounds no longer pause, but a round that stops at (c) - the reviewer changed the frozen copy - must be recorded as
        # a stop. A (c) round whose stop record could not be written refuses the next launch rather than reading as "no
        # stop". The launch first records the missing stop and shows it; when that write fails too, it says what could not
        # be saved and where.
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'nopause')
        $config = script:New-PauseConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-001-demo-i007'

        # An INVOKED round that completed, with its pending-pause.json missing - the failed-write state.
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId 'run-nopause' -TargetLineage 'lin-nopause' -ObservedAt '2026-08-11T12:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId 'run-nopause' -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = 'run-nopause'; target_digest = 'digest-nopause'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'violated'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'completed but pause write failed'; findings = @()
                started_at = '2026-08-11T12:00:00Z'; ended_at = '2026-08-11T12:10:00Z'; duration_ms = 600000; review_collected = $true
            }) | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId 'run-nopause' -TargetLineage 'lin-nopause' -Disposition released -ObservedAt '2026-08-11T12:10:01Z' | Out-Null

        $next = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId 'run-nopause-next' -AuthorityConfigPath $config `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'nopause-ext')
                    harness = [pscustomobject]@{
                        id = 'must-not-run'
                        preflight = { param($invocation) throw 'harness-must-not-run-when-the-pause-record-is-missing' }
                        invoke = { param($invocation, $environment) throw 'harness-must-not-run-when-the-pause-record-is-missing' }
                    }
                    runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $root 'prompt.txt')
                })

        [string]$next.status | Should -Be 'paused'
        [bool]$next.invoked | Should -BeFalse
        [string]$next.reason | Should -BeExactly 'review-stop-open:c-judgment' -Because 'the missing (c) stop is recorded now and shown, never read as no stop'
        (@($next.pause_surface) -join "`n") | Should -Match 'changed the frozen copy'

        # When the stop cannot be written now either, the launch refuses and says what could not be saved, and where.
        $root2 = script:New-PauseRepo -Root (Join-Path $TestDrive 'nopause-unwritable')
        $config2 = script:New-PauseConfig -Root $root2
        $store2 = Join-Path $root2 '.specrew/review/authority'
        Request-ReviewAuthorityClaim -StoreRoot $store2 -CampaignId $campaign -RunId 'run-nopause' -TargetLineage 'lin-nopause' -ObservedAt '2026-08-11T12:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store2 -CampaignId $campaign -RunId 'run-nopause' -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = 'run-nopause'; target_digest = 'digest-nopause'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'violated'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'completed but pause write failed'; findings = @()
                started_at = '2026-08-11T12:00:00Z'; ended_at = '2026-08-11T12:10:00Z'; duration_ms = 600000; review_collected = $true
            }) | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store2 -CampaignId $campaign -RunId 'run-nopause' -TargetLineage 'lin-nopause' -Disposition released -ObservedAt '2026-08-11T12:10:01Z' | Out-Null
        Mock -CommandName Write-ReviewCampaignPendingPauseFact -MockWith { throw 'the stop file could not be created' }
        $blocked = script:Invoke-RefusedLaunch -Root $root2 -Config $config2 -RunId 'run-nopause-next' -External (Join-Path $TestDrive 'nopause-ext2')
        [string]$blocked.status | Should -Be 'paused'
        [bool]$blocked.invoked | Should -BeFalse
        [string]$blocked.reason | Should -Match 'pause-record-missing-for-completed-round'
        (@($blocked.pause_surface) -join "`n") | Should -Match '(?i)could not save the record' -Because 'the consumer must be told what is wrong and where to look, not merely refused'
        (@($blocked.pause_surface) -join "`n") | Should -Match '(?i)\.specrew/review/authority'
    }

    It 'THE RESUMED SURFACE carries the findings and the numbered choices' {
        # Round-3 major finding: the surface a consumer meets when they come back the next day named nothing and offered
        # nothing. Feature 203 T008 (maintainer classification 2026-11-09: A for the numbered choices, B for the findings):
        # the resumed stop lists its open findings and offers FR-011's typed lines, each with its consequence - no numbers,
        # no flags, and nothing that asks for a round.
        $stop = script:Invoke-StopARound -Name 'resume' -RunId 'run-resume-a'
        $second = script:Invoke-RefusedLaunch -Root $stop.root -Config $stop.config -RunId 'run-resume-b' -External (Join-Path $TestDrive 'resume-ext-b')
        [string]$second.status | Should -Be 'paused'
        $surface = @($second.pause_surface) -join "`n"
        $surface | Should -Match 'A thing worth your attention' -Because 'what MUST be there: the finding the stop is about'
        $surface | Should -Match '(?m)^\s+- finding-[0-9a-f]+ \(major\) '
        $surface | Should -Match '(?m)^\s+approved for allowance reset - '
        $surface | Should -Match '(?m)^\s+stop the review here - '
        $surface | Should -Not -Match '(?m)^\s+\d\.\s' -Because 'W49: numbers index nothing for a human; the typed line is the answer'
        $surface | Should -Not -Match '--pause-choice' -Because 'W49: machinery flags are the agent''s vocabulary, never the stop''s'
        $surface | Should -Not -Match '(?i)run another round|abandon this review campaign' -Because 'retired lines (FR-006; the 2026-11-09 mapping)'
    }

    It 'THE CLI CAN REACH ALL OF IT: the shipped command exposes the reply and calls the three helpers' {
        # A source-level companion to the behaviour above, and it exists because the finding was found by
        # a CALLER INSPECTION, not by a failing test: three functions with no production caller. The
        # behaviour tests above prove the engine; this proves the path a consumer types stays connected
        # to it, which is the exact thing that was broken while every unit test passed.
        $cli = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Raw

        $cli | Should -Match 'pause-choice' -Because 'a decision surface a consumer cannot answer is a notification'
        $cli | Should -Match 'Write-ReviewCampaignPauseDecisionFact' -Because 'the reply must be RECORDED, or the next round cannot know it happened'
        $cli | Should -Match 'Invoke-ReviewCampaignStopHereLanding' -Because 'option 2 is a composed landing, not three steps a consumer must know to run in order'
        $cli | Should -Match 'pause_surface|pause\.surface|pauseLines' -Because 'the surface must be rendered where the human is standing'
    }

    It 'the restored-slot disclosure survives the same projection (F4, same seam)' {
        # Not a separate defect. The identical explicit field list dropped slot_restored/_note while the
        # CLI already contained the code to render them, so F4 was fixed everywhere except the one place
        # it travels. Asserted here because it is the SAME line of code and would regress together.
        $orchestrator = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1') -Raw
        $projection = [regex]::Match($orchestrator, '(?s)# THIS PROJECTION IS WHERE TWO CAPABILITIES DIED.*?\n\}')
        $projection.Success | Should -BeTrue -Because 'the guard must anchor on the real projection, not on a copy that drifted'
        $projection.Value | Should -Match 'pause\s*='
        $projection.Value | Should -Match 'slot_restored\s*='
        $projection.Value | Should -Match 'slot_restored_note\s*='
    }
}
