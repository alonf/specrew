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

        function script:New-PauseRepo {
            param([string]$Root)
            New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', [Text.UTF8Encoding]::new($false))
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm initial 2>&1 | Out-Null
            return $Root
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
            param([string]$Root, [string]$External, [string]$RunId)
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
                        description = 'Concretely: when the store is empty the command throws instead of returning null.'
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
            param([string]$Root, [string]$Config, [string]$RunId, [string]$External, [string]$AuthRef = 'auth-pause-1')
            return Invoke-ReviewCampaignCommand -RepoRoot $Root -FeatureId '001-demo' -IterationNumber '007' `
                -RunId $RunId -AuthorityConfigPath $Config -GrantAuthorizationRef $AuthRef `
                -Ports (script:New-PausePorts -Root $Root -External $External -RunId $RunId)
        }
    }

    It 'a completed round RETURNS the decision surface through the public command (it was projected away)' {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'surface')
        $config = script:New-PauseConfig -Root $root
        $run = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-surface-a' -External (Join-Path $TestDrive 'surface-ext')

        [string]$run.status | Should -Be 'terminal' -Because 'the fixture reviewer completes; if this is not terminal the rest of the assertions are about the wrong thing'
        # STATUS IS NOT VALIDITY, and conflating them cost two debugging rounds here. A rejected
        # candidate still publishes a terminal result - completion 'none', verdict 'incomplete',
        # validation 'invalid' - so 'terminal' alone says only that the round ended, not that it
        # produced anything. Asserted before the counts, because a count over an invalid result is a
        # measurement of the fixture's bugs.
        [string]$run.result.validation | Should -Be 'valid' -Because ('the candidate contract rejected the fixture: ' + [string]$run.result.failure_reason)
        [string]$run.result.completion | Should -Be 'complete'
        $run.PSObject.Properties['pause'] | Should -Not -BeNullOrEmpty -Because 'THE defect: the projection carried no pause field at all'
        $run.pause | Should -Not -BeNullOrEmpty

        # WHAT THE FLOW ACTUALLY PRODUCES, measured rather than assumed - and the first draft of this
        # assertion got it wrong in a way worth keeping. It expected major_count = 1, because the fixture
        # reviewer reports the finding as major and Resolve-ReviewCampaignPauseDecision, called directly,
        # counts exactly that. Through the COMMAND it is 0: the result ingestor applies the T005 gating
        # contract first, so the finding reaches the pause already demoted. Calling the helper and
        # calling the command give different answers, which is the fifth rule demonstrating itself
        # inside a test written to honour the fifth rule.
        [int]$run.pause.decision.minor_count | Should -Be 1
        [int]$run.pause.decision.demoted_count | Should -Be 1
        [int]$run.pause.decision.demoted_from_major | Should -Be 1 -Because 'the surface must say which severity the reviewer actually used'

        @($run.pause.decision.options).Count | Should -BeGreaterThan 0 -Because 'a pause with no options is not a decision, it is a notification'
        @($run.pause.surface).Count | Should -BeGreaterThan 0 -Because 'the rendered surface is the one thing the consumer actually reads'
        # The load-bearing last line, quoted from the renderer rather than paraphrased: ledger F8 is the
        # console held open while spend continued, so the surface must say plainly that it has stopped.
        (@($run.pause.surface) -join "`n") | Should -Match 'Nothing runs and nothing is spent until you answer'
        (@($run.pause.surface) -join "`n") | Should -Match 'What would you like to do\?'

        # THE DEMOTION-VISIBILITY RULING, checked where it matters: on the surface a consumer reads,
        # reached through the command. A demotion the human cannot see is a silencing, and the round
        # that demotes is exactly the round where "1 minor finding" would otherwise be the whole story.
        (@($run.pause.surface) -join "`n") | Should -Match '(?i)demoted'
        (@($run.pause.surface) -join "`n") | Should -Match '(?i)major' -Because 'naming the severity the reviewer used is the point of the line'
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
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'gating')
        $config = script:New-PauseConfig -Root $root
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
            -RunId 'run-gating' -AuthorityConfigPath $config -GrantAuthorizationRef 'auth-gating' `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot $external
                    harness = $harness; runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = $prompt
                })

        [string]$run.result.validation | Should -Be 'valid' -Because ('candidate rejected: ' + [string]$run.result.failure_reason)
        [int]$run.pause.decision.blocking_count | Should -Be 2
        [int]$run.pause.decision.minor_count | Should -Be 0 -Because 'the phantom minor was the wrapper element being counted as a finding'
        [bool]$run.pause.decision.gating | Should -BeTrue

        $surface = @($run.pause.surface) -join "`n"
        $surface | Should -Match 'Findings that need your attention \(2\)'
        $surface | Should -Not -Match 'Nothing found that needs your attention' -Because 'this is what a two-blocker round used to say'
        $surface | Should -Match 'First blocker'
        $surface | Should -Match 'Second blocker'
    }

    It 'an UNANSWERED pause stops the next round from spending (FR-003, ledger obs-6)' {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'block')
        $config = script:New-PauseConfig -Root $root
        $first = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-block-a' -External (Join-Path $TestDrive 'block-ext-a')
        [string]$first.status | Should -Be 'terminal'

        # The SECOND invocation is the whole point. Before this wiring it ran a full review.
        $second = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId 'run-block-b' -AuthorityConfigPath $config -GrantAuthorizationRef 'auth-pause-2' `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'block-ext-b')
                    # If the guard leaks, THIS throws - the refusal must happen before any harness work.
                    harness = [pscustomobject]@{
                        id = 'must-not-run'
                        preflight = { param($invocation) throw 'harness-must-not-be-reached-while-a-pause-is-unanswered' }
                        invoke = { param($invocation, $environment) throw 'harness-must-not-be-reached-while-a-pause-is-unanswered' }
                    }
                    runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $root 'prompt.txt')
                })

        [string]$second.status | Should -Be 'paused'
        [bool]$second.invoked | Should -BeFalse
        [string]$second.reason | Should -Match 'pause-decision-pending'
        [bool]$second.continuation_authorized | Should -BeFalse
        @($second.pause_surface).Count | Should -BeGreaterThan 0 -Because 'a refusal that does not re-show the question leaves the consumer with nothing to answer'
        (@($second.pause_surface) -join "`n") | Should -Match 'still waiting for your answer'
    }

    It 'ANSWERING fix-and-continue authorizes exactly one further round' {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive 'continue')
        $config = script:New-PauseConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        $first = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-cont-a' -External (Join-Path $TestDrive 'cont-ext-a')
        [string]$first.status | Should -Be 'terminal'

        # The human's reply, written the way the CLI writes it.
        $answered = [string]$first.pause.fact.run_id
        Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (
            New-ReviewCampaignPauseDecisionFact -CampaignId ([string]$first.campaign_id) -RunId $answered `
                -Choice 'fix-and-continue' -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))) | Out-Null

        $second = script:Invoke-PauseCommand -Root $root -Config $config -RunId 'run-cont-b' -External (Join-Path $TestDrive 'cont-ext-b') -AuthRef 'auth-pause-2'
        [string]$second.status | Should -Be 'terminal' -Because 'an answered fix-and-continue is what authorizes the next round'
        [bool]$second.invoked | Should -BeTrue
    }

    It 'ANSWERING stop-here or abandon does NOT authorize a further round' -ForEach @(
        @{ choice = 'stop-here' }
        @{ choice = 'abandon' }
    ) {
        $root = script:New-PauseRepo -Root (Join-Path $TestDrive "end-$choice")
        $config = script:New-PauseConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        $first = script:Invoke-PauseCommand -Root $root -Config $config -RunId "run-end-$choice" -External (Join-Path $TestDrive "end-ext-$choice")
        [string]$first.status | Should -Be 'terminal'

        Write-ReviewCampaignPauseDecisionFact -StoreRoot $store -Fact (
            New-ReviewCampaignPauseDecisionFact -CampaignId ([string]$first.campaign_id) -RunId ([string]$first.pause.fact.run_id) `
                -Choice $choice -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))) | Out-Null

        # An ANSWERED pause is not an open door. This is why the guard reads the latest pause WITH its
        # decision instead of asking Get-ReviewCampaignPendingPause, which only ever returns unanswered
        # pauses and could therefore only answer "pending" - a tautology, not a check.
        $second = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' `
            -RunId "run-end-$choice-b" -AuthorityConfigPath $config -GrantAuthorizationRef 'auth-pause-2' `
            -Ports ([pscustomobject]@{
                    target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive "end-ext2-$choice")
                    harness = [pscustomobject]@{
                        id = 'must-not-run'
                        preflight = { param($invocation) throw 'harness-must-not-be-reached-after-a-terminal-choice' }
                        invoke = { param($invocation, $environment) throw 'harness-must-not-be-reached-after-a-terminal-choice' }
                    }
                    runtime = New-ReviewFixtureRuntimePort; verification = New-ReviewFixtureVerificationPort
                    clock = New-ReviewSystemClockPort; prompt_path = (Join-Path $root 'prompt.txt')
                })

        [string]$second.status | Should -Be 'paused'
        [bool]$second.invoked | Should -BeFalse
        [string]$second.reason | Should -Match ('choice-does-not-continue:' + $choice)
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
