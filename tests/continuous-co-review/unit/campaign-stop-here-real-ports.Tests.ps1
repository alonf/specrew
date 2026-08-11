$ErrorActionPreference = 'Stop'

# THE STOP-HERE LANDING WITH ITS REAL DEFAULT PORTS. No injection anywhere in this file.
#
# Round 4's first blocking finding: the production VerifyPort called New-GitReviewTargetSnapshot with
# `-RepoRoot` - a parameter that does not exist - and supplied no `-RunId`, which is mandatory. PowerShell
# threw on the binding before verification began, so the PUBLIC option-2 path could not complete a
# sign-off at all. The whole stop-here suite was green throughout, because EVERY test in it injects
# -VerifyPort / -AcceptPort / -GateSyncPort - including the three added that same morning specifically to
# guard this landing.
#
# THE MAINTAINER'S CONDITION ON THAT FIX, and it is the reason this file exists: correcting the arguments
# is not the fix. The defect is that the production DEFAULT has never executed. Correct the call and the
# next defect inside that function is exactly as invisible, and we meet it in round 6. So the fix ships
# with at least one path where the DEFAULTS RUN.
#
# WHAT THIS FILE CAN AND CANNOT ASSERT. It cannot assert a successful sign-off: that needs a verification
# plan, a passing suite, and a live gate, which is an end-to-end concern. What it CAN assert - and what
# would have caught round 4's finding - is that each default port EXECUTES and returns the {ok, reason}
# shape the composition expects, rather than throwing on its own arguments. A port that runs and reports
# a real failure is correct; a port that cannot be called is not.

Describe 'stop-here landing: the DEFAULT ports, executed' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        function script:New-RealRepo {
            param([string]$Root, [switch]$WithPassingVerificationPlan)
            New-Item -ItemType Directory -Path $Root -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'content', [Text.UTF8Encoding]::new($false))
            if ($WithPassingVerificationPlan) {
                # THE PLAN SCHEMA IS THE REAL ONE, read from New-ContinuousCoReviewStarterVerificationPlan
                # rather than composed - schema_version / plan_id / commands[] with command_id,
                # executable, arguments, timeout_seconds, env_refs, provenance, label - and the env_refs
                # are that function's own allowlist.
                #
                # THE COMMAND IS DELIBERATELY NOT THE STARTER'S. The starter runs the governance
                # validator, which needs a fully deployed .specify/ tree; standing one up here would
                # make this a test of the validator. What must be measured is that the default PORTS
                # execute, so the command is the smallest thing that genuinely runs and succeeds. If it
                # ever fails, verification failed for a real reason and the chain correctly stops.
                New-Item -ItemType Directory -Path (Join-Path $Root '.specrew') -Force | Out-Null
                $plan = [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    plan_id = 'verification.realports.fixture.v1'
                    commands = @(
                        [pscustomobject][ordered]@{
                            command_id = 'realports-noop'
                            executable = 'pwsh'
                            arguments = @('-NoProfile', '-Command', 'exit 0')
                            timeout_seconds = 60
                            env_refs = @('PATH', 'PATHEXT', 'SYSTEMROOT', 'COMSPEC', 'TEMP', 'TMP', 'TMPDIR', 'HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'PROGRAMFILES', 'PROGRAMFILES(X86)', 'PROGRAMDATA')
                            provenance = [pscustomobject][ordered]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' }
                            label = 'Fixture check that genuinely runs, so the landing reaches acceptance and gate sync.'
                        }
                    )
                }
                [IO.File]::WriteAllText((Join-Path $Root '.specrew/verification-plan.json'),
                    ($plan | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
            }
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm init 2>&1 | Out-Null
            return $Root
        }

        function script:Publish-CleanRound {
            param([string]$Store, [string]$Campaign, [string]$RunId, [string]$Lineage)
            Request-ReviewAuthorityClaim -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -TargetLineage $Lineage -ObservedAt '2026-08-11T20:00:00Z' | Out-Null
            Publish-ReviewRunResultFact -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -Fact ([pscustomobject][ordered]@{
                    schema_version = '1.0'; campaign_id = $Campaign; run_id = $RunId; target_digest = 'digest-real'
                    harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                    termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                    can_approve_current = $false; summary = 'minor only'
                    findings = @([pscustomobject][ordered]@{ finding_id = 'finding-r1'; source_local_id = 'r1'; lineage_id = $Lineage; severity = 'minor'; title = 'A follow-up'; description = 'Saved as a follow-up.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open' })
                    started_at = '2026-08-11T20:00:00Z'; ended_at = '2026-08-11T20:01:00Z'; duration_ms = 60000
                }) | Out-Null
            Complete-ReviewAuthorityClaim -StoreRoot $Store -CampaignId $Campaign -RunId $RunId -TargetLineage $Lineage -Disposition released -ObservedAt '2026-08-11T20:01:01Z' | Out-Null
        }
    }

    It 'ALL THREE DEFAULTS RUN END TO END - verification passes, residuals are accepted, the gate syncs' {
        # THE RULED CONDITION ON BLOCKER 1, completed. The first version of this file ran ONE default:
        # the chain stopped at verification because the fixture repo had no plan, so the AcceptPort and
        # GateSyncPort defaults stayed exactly as unexecuted as VerifyPort had been before round 4 -
        # two thirds of the same blindness still shipping, and that blindness is what produced round 4's
        # worst finding.
        #
        # With a verification plan that PASSES, the chain continues, and every default executes against
        # a real store and a real repository. NOTHING is injected.
        $root = script:New-RealRepo -Root (Join-Path $TestDrive 'realports-full') -WithPassingVerificationPlan
        $store = Join-Path $root '.specrew/review/authority'
        script:Publish-CleanRound -Store $store -Campaign 'cmp-real-full-i001' -RunId 'run-real-full' -Lineage 'lin-full'

        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId 'cmp-real-full-i001' -RunId 'run-real-full' -AuthorizedBy 'human' `
            -AuthorizationRef 'ref-real-full' -Rationale 'minor findings accepted as follow-ups'

        $steps = @($landing.steps)
        $names = @($steps | ForEach-Object { [string]$_.name })

        # Every step REACHED, in order, with its default implementation.
        $names | Should -Be @('gating-precondition', 'verification', 'residual-acceptance', 'gate-sync') -Because 'a chain that stops early leaves the later defaults as unexecuted as VerifyPort was'

        # THE FIRST THREE MUST SUCCEED OUTRIGHT. Their defaults now run against a real repository and a
        # real store, and there is nothing environmental left for them to trip on.
        foreach ($name in @('gating-precondition', 'verification', 'residual-acceptance')) {
            $step = @($steps | Where-Object { [string]$_.name -ceq $name })[0]
            [bool]$step.ok | Should -BeTrue -Because ("the {0} default must succeed, not merely be called: {1}" -f $name, $step.reason)
        }

        # The acceptance is REAL - a human-disposition fact now exists in the store, written by the
        # default AcceptPort rather than by a stand-in that returned $true.
        @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $store -CampaignId 'cmp-real-full-i001' -RunId 'run-real-full').Count |
            Should -Be 1 -Because 'a landed stop-here must leave the acceptance the gate will later consult'

        # GATE-SYNC IS ASSERTED AS *EXECUTED*, NOT AS ALLOWING, and the distinction is deliberate rather
        # than a softened bar. This fixture is a bare git repository with no governed feature, so the
        # signoff gate correctly refuses with `review-campaign-active-feature-unresolved` - that is the
        # gate working, not a defect. Making it ALLOW would require a full governed feature plus a
        # passing co-review evidence chain, which is the gate's own subject and belongs to an end-to-end
        # run, not here.
        #
        # What IS asserted is the thing blocker 1 was about: the default is REACHABLE and RUNS. It first
        # threw "Invoke-ContinuousCoReviewSignoffGateIfEnabled is not recognized" because
        # signoff-gate-wiring.ps1 is not in _load.ps1's set - the same load-order class, in the third
        # production default of the day. A governed refusal is a real answer; a missing function is not.
        $gate = @($steps | Where-Object { [string]$_.name -ceq 'gate-sync' })[0]
        [string]$gate.reason | Should -Not -Match '(?i)is not recognized' -Because 'this is what a default that cannot be loaded reports, and it is the whole defect class'
        [string]$gate.reason | Should -Not -Match '(?i)parameter (cannot be found|name)'
        [string]$gate.reason | Should -Match '(?i)signoff-gate-allow|review-signoff refused|campaign-review-state' -Because 'the gate must return a governed decision, whichever way it goes'
    }

    It 'THE DEFAULT VERIFY PORT RUNS - it does not throw on its own arguments' {
        # The exact regression. Before the fix this threw
        # "A parameter cannot be found that matches parameter name 'RepoRoot'" / missing -RunId, and the
        # landing reported a failed step whose reason was a PowerShell binding error rather than
        # anything about the consumer's project.
        $root = script:New-RealRepo -Root (Join-Path $TestDrive 'realports')
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-real-i001'
        $runId = 'run-real-ports'

        # A clean result, so the gating precondition passes and the chain actually REACHES verification.
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-real' -ObservedAt '2026-08-11T20:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-real'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'minor only'
                findings = @([pscustomobject][ordered]@{ finding_id = 'finding-r1'; source_local_id = 'r1'; lineage_id = 'lin-real'; severity = 'minor'; title = 'A follow-up'; description = 'Saved as a follow-up.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open' })
                started_at = '2026-08-11T20:00:00Z'; ended_at = '2026-08-11T20:01:00Z'; duration_ms = 60000
            }) | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-real' -Disposition released -ObservedAt '2026-08-11T20:01:01Z' | Out-Null

        # NO PORTS INJECTED. This is the whole point of the file.
        $landing = Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef 'ref-real' `
            -Rationale 'minor findings accepted as follow-ups'

        $steps = @($landing.steps)
        @($steps | ForEach-Object { [string]$_.name }) | Should -Contain 'verification' -Because 'the verification step must be REACHED, not skipped by an earlier refusal'

        $verification = @($steps | Where-Object { [string]$_.name -ceq 'verification' })[0]
        [string]$verification.reason | Should -Not -BeNullOrEmpty -Because 'a port that ran reports something; a port that could not be called reports nothing'

        # THE REGRESSION, stated as the shape of the failure rather than its text: a binding error names
        # a PARAMETER, and no consumer-facing reason ever should.
        [string]$verification.reason | Should -Not -Match "(?i)parameter (cannot be found|name)" -Because 'this is what a port that was never executed reports'
        [string]$verification.reason | Should -Not -Match "(?i)RepoRoot" -Because 'the corrected call passes -OriginRepo; seeing RepoRoot here means the old signature is back'
        [string]$verification.reason | Should -Not -Match '(?i)cannot be bound|missing an argument'
    }

    It 'THE DEFAULT PORTS LEAVE NO WORKTREE BEHIND' {
        # The second half of round 4's finding: the verifier creates a linked git worktree and nothing
        # disposed it, so every stop-here accumulated one the consumer never asked for.
        $root = script:New-RealRepo -Root (Join-Path $TestDrive 'realports-worktree')
        $store = Join-Path $root '.specrew/review/authority'
        $campaign = 'cmp-real-wt-i001'
        $runId = 'run-real-wt'
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-wt' -ObservedAt '2026-08-11T20:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $runId -Fact ([pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $campaign; run_id = $runId; target_digest = 'digest-wt'
                harness_id = 'fixture'; completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = $false; summary = 'minor only'; findings = @()
                started_at = '2026-08-11T20:00:00Z'; ended_at = '2026-08-11T20:01:00Z'; duration_ms = 60000
            }) | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $runId -TargetLineage 'lin-wt' -Disposition released -ObservedAt '2026-08-11T20:01:01Z' | Out-Null

        Invoke-ReviewCampaignStopHereLanding -ProjectRoot $root -StoreRoot $store `
            -CampaignId $campaign -RunId $runId -AuthorizedBy 'human' -AuthorizationRef 'ref-wt' `
            -Rationale 'accepted' | Out-Null

        $worktrees = @(& git -C $root worktree list --porcelain 2>&1 | Where-Object { $_ -match '^worktree ' })
        @($worktrees).Count | Should -Be 1 -Because 'only the origin worktree should remain; a stop-here must not leave its snapshot behind'
    }
}
