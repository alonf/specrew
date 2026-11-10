$ErrorActionPreference = 'Stop'

# Trace: T005 / FR-006.
#
# THE DISTINCTION THIS SUITE EXISTS FOR (maintainer, 2026-08-10): a prompt is a REQUEST; a contract
# needs a REJECTION. If the reviewer omits a failure scenario and ingest accepts the finding anyway,
# "every finding states a concrete failure scenario or it is not a finding" is aspirational text that
# changes nothing. So the prompt half and the INGEST half are asserted together - neither alone is the
# requirement.
#
# AND THE FAIL DIRECTION IS DEMOTION, NOT DISCARD. Losing a real blocking finding is worse than
# admitting a weak one, so a scenario-less finding is never dropped: it lands below the gating floor
# and is carried as a recorded follow-up, exactly like a minor. That keeps the signal, removes its
# power to hold sign-off hostage, and attacks the gold-plating economics where they bite - an
# observation with no failure scenario can still be reported, it just cannot cost the human a round.
Describe 'Verdict-goal reviewer prompt contract (T005/FR-006)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        # Rendering lives in the navigator layer (the D1 binding), which _load does not dot-source.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        $script:Prompt = Get-ContinuousCoReviewSlimPrompt -RunId 'run-t005-probe' -RoundNumber 1 -MaxRounds 3

        function script:Invoke-ScenarioIngress {
                param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Description, [string]$Severity = 'blocking')
                $store = Join-Path $Root 'store'; $staging = Join-Path $Root 'staging'
                $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId 'cmp-demo' -RunId 'run-one'
                $candidate = [pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest-one'
                    completion = 'complete'; verdict = 'findings'; summary = 'review complete'
                    findings = @([pscustomobject][ordered]@{
                            local_id = 'l1'; severity = $Severity; title = 'unvalidated input reaches the shell'
                            description = $Description; location = 'src/app.ps1:10'
                        })
                }
                [IO.File]::WriteAllText($paths.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                return Invoke-ReviewResultIngress -StoreRoot $store -StagingRoot $staging -CampaignId 'cmp-demo' -RunId 'run-one' `
                    -TargetDigest 'digest-one' -HarnessId 'fixture' -RuntimeOutcome 'completed' -Invoked $true `
                    -TerminationVerified $true -Containment 'verified' -Currentness 'current' `
                    -StartedAt '2026-08-10T00:00:00Z' -EndedAt '2026-08-10T00:00:01Z' -DurationMs 1000
            }
    }

    Context 'the prompt asks for a verdict, not only for faults' {
        It 'blesses a justified clean verdict that names what was verified' {
            # The counterweight to REPORT-FALSIFICATION STANCE / NEVER-FALSE-GREEN. Without it the only
            # unambiguously "successful" reviewer output is a finding, which is the incentive that
            # manufactures findings - the reviewer determines whether the artifact is SAFE TO PROCEED ON,
            # and saying so with its basis is a blessed answer.
            $script:Prompt | Should -Match '(?i)safe to proceed'
            $script:Prompt | Should -Match '(?i)clean verdict'
            $script:Prompt | Should -Match '(?i)naming what you verified|name what you verified|what you actually verified'
        }

        It 'requires a concrete failure scenario on every finding' {
            $script:Prompt | Should -Match '(?i)Failure scenario:'
            $script:Prompt | Should -Match '(?i)is not a finding'
        }

        It 'asks for severity-ranked, capped output' {
            $script:Prompt | Should -Match '(?i)rank(ed)? .*severity|order.*by severity'
            $script:Prompt | Should -Match '(?i)at most \d+|cap(ped)? at \d+|no more than \d+'
        }
    }

    Context 'INGEST is where the contract exists or does not' {
        BeforeAll {
            function script:New-CandidateFinding {
                param([string]$LocalId, [string]$Severity, [string]$Description)
                return [pscustomobject]@{
                    local_id = $LocalId; severity = $Severity; title = 'A finding'
                    description = $Description; location = 'scripts/app.ps1:1'
                }
            }
        }

        It 'a finding WITH a failure scenario keeps its severity and gates normally' {
            $withScenario = script:New-CandidateFinding -LocalId 'l1' -Severity 'blocking' `
                -Description 'The digest strip drops real source. Failure scenario: on a case-sensitive volume a change under Specs/ is classified records-only, so the review never runs and the change ships unreviewed.'

            $graded = @(Resolve-ReviewFindingGatingEligibility -Findings @($withScenario))
            $graded[0].severity | Should -Be 'blocking'
            $graded[0].demoted | Should -BeFalse
        }

        It 'a finding WITHOUT a failure scenario is present, demoted below the gating floor, and marked' {
            $withoutScenario = script:New-CandidateFinding -LocalId 'l2' -Severity 'blocking' `
                -Description 'This function is long and would read better split into smaller helpers.'

            $graded = @(Resolve-ReviewFindingGatingEligibility -Findings @($withoutScenario))
            @($graded).Count | Should -Be 1 -Because 'a scenario-less finding is DEMOTED, never discarded - losing a real blocking finding is worse than admitting a weak one'
            $graded[0].severity | Should -Be 'minor' -Because 'minors never gate; they are carried as recorded follow-ups'
            $graded[0].demoted | Should -BeTrue
            $graded[0].description | Should -Match '(?i)no concrete failure scenario'
        }

        It 'the demoted finding is ABSENT from the gating count' {
            # The whole point, against what decides a stop now: a scenario-less observation cannot cost the human a round.
            # Feature 203 T008 (maintainer classification 2026-11-09, class A; the decision's counts were deleted under
            # a0ab0ca0): the demoted finding opens no finding, and it is stored as minor with the reviewer's severity kept.
            $published = script:Invoke-ScenarioIngress -Root (Join-Path $TestDrive 'ingest-demote') -Description 'Please rename this variable for clarity.'
            $published.result.findings[0].severity | Should -Be 'minor'
            $published.result.findings[0].demoted_from | Should -Be 'blocking'
            @(Get-ReviewCampaignOpenFindings -StoreRoot (Join-Path $TestDrive 'ingest-demote/store') -CampaignId 'cmp-demo').Count | Should -Be 0 -Because 'a demoted finding opens nothing that can gate'
        }

        It 'a minor without a scenario is untouched (demotion has nothing to demote)' {
            $minor = script:New-CandidateFinding -LocalId 'l4' -Severity 'minor' -Description 'A typo in a comment.'
            $graded = @(Resolve-ReviewFindingGatingEligibility -Findings @($minor))
            $graded[0].severity | Should -Be 'minor'
            $graded[0].demoted | Should -BeFalse -Because 'a finding that never gated is not demoted, and its description must not be rewritten'
            $graded[0].description | Should -Be 'A typo in a comment.'
        }
    }

    # Feature 203 T008 step (iv) (B5F-017, FR-005; DRIFT-052 ordering constraint: before T014). The prompt half above
    # pins the SLIM prompt; every campaign review is sent reviewer-candidate-prompt.md instead, rendered by the harness
    # contract, and that prompt never asked for the clause the ingest requires. So a finding that stated its scenario in
    # prose was demoted - eleven rounds of it (B5F-017's instances). The request and the rejection have to be the same rule.
    Context 'the campaign reviewer is asked for the clause the ingest requires (B5F-017)' {
        BeforeAll {
            $script:CandidatePrompt = Render-ReviewFilePrimaryPrompt -Template (Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md') -Raw) `
                -Invocation ([pscustomobject]@{ run_id = 'run-b5f017'; target_digest = ('a' * 40); candidate_result_path = (Join-Path $TestDrive 'candidate.json'); review_scope = 'the whole tree'; deadline = '2026-11-10T12:00:00Z' })
        }

        It 'the prompt every campaign harness renders asks each blocking or major finding for a literal Failure scenario clause' {
            $script:CandidatePrompt | Should -Match 'Failure scenario:'
            $script:CandidatePrompt | Should -Match '(?i)blocking or major'
            $script:CandidatePrompt | Should -Match '(?i)description'
        }

        It 'the clause the prompt shows passes the ingest rule as written, so following the prompt keeps the severity' {
            $example = [regex]::Match($script:CandidatePrompt, 'Failure scenario: [^`\r\n]+').Value
            $example | Should -Not -BeNullOrEmpty
            Test-ReviewFindingStatesFailureScenario -Description ('The cache is never invalidated. ' + $example) | Should -BeTrue
        }

        It 'a scenario stated under an emphasised label keeps its severity through the real ingress' {
            $published = script:Invoke-ScenarioIngress -Root (Join-Path $TestDrive 'ingest-bold-label') `
                -Description 'The retry never backs off. **Failure scenario**: a host that answers 503 forever gets a request every 10 ms until the run is killed.'
            $published.result.findings[0].severity | Should -Be 'blocking'
            $published.result.findings[0].demoted | Should -BeFalse
        }
    }

    # Maintainer instruction 2026-08-10: verify rather than assume that the contract binds through the
    # REAL ingress entry point, not only through the pure eligibility function.
    #
    # It did not, and only this shape could have shown it. The cases above call
    # Resolve-ReviewFindingGatingEligibility directly and were green while the terminal projection in
    # Invoke-ReviewResultIngress rebuilt each finding from an explicit field list that DROPPED the
    # demotion marks - so end to end the demotion reached the human as an ordinary minor with no trace
    # of what the reviewer had actually reported. THE WIRING IS WHAT DRIFTS.
    Context 'the contract binds through the REAL ingress, end to end' {
        BeforeAll {
            # Invoke-ScenarioIngress moved to the Describe's BeforeAll (feature 203 T008), so the ingest cases reach the store too.
        }

        It 'a scenario-less blocking finding is demoted IN THE PUBLISHED RESULT, with the marks intact' {
            $root = Join-Path $TestDrive 'e2e-demote'
            $published = script:Invoke-ScenarioIngress -Root $root -Description 'This function is long and would read better split into smaller helpers.'

            $published.published | Should -BeTrue
            @($published.result.findings).Count | Should -Be 1 -Because 'demote, NEVER discard'
            $published.result.findings[0].severity | Should -Be 'minor'
            $published.result.findings[0].demoted | Should -BeTrue -Because 'the demotion mark must SURVIVE the terminal projection or the human can never be told'
            $published.result.findings[0].demoted_from | Should -Be 'blocking'

            # Read back through the CONTRACT, not the in-memory object: the terminal finding shape is
            # closed, so this is what proves the marks are a sanctioned part of the record rather than
            # properties that happen to survive until the first validator sees them.
            $persisted = Read-ReviewAuthorityFactFile -Path $published.result_path -ContractName ReviewResult
            $persisted.findings[0].demoted | Should -BeTrue
            $persisted.findings[0].demoted_from | Should -Be 'blocking'
        }

        It 'the human-facing surface names that demotion, from the PERSISTED result' {
            # The full chain in one case: reviewer output -> ingest -> store -> the words the human reads. Feature 203 T008
            # (class A): the surface is the sign-off listing, built from the stored result, which names the demotion and
            # the severity the reviewer used.
            $root = Join-Path $TestDrive 'e2e-surface'
            $null = script:Invoke-ScenarioIngress -Root $root -Description 'Please rename this variable for clarity.'
            $listing = @(Get-ReviewCampaignSignoffFindingLines -StoreRoot (Join-Path $root 'store') -CampaignId 'cmp-demo') -join "`n"
            $listing | Should -Match 'Demoted: .*unvalidated input reaches the shell'
            $listing | Should -Match '(?i)reported it as blocking'
            $listing | Should -Match '(?i)no concrete failure scenario'
        }

        It 'a finding WITH a scenario keeps its severity and its gate through the same path' {
            # The other direction, so the case above cannot be satisfied by demoting everything. Feature 203 T008 (class A,
            # maintainer ruling 2026-11-09: both halves): the finding keeps its severity AND opens a finding, and the sign-off
            # listing carries no demotion for it.
            $root = Join-Path $TestDrive 'e2e-keeps'
            $published = script:Invoke-ScenarioIngress -Root $root `
                -Description 'The digest strip drops real source. Failure scenario: on a case-sensitive volume a change under Specs/ is classified records-only, so the review never runs and the change ships unreviewed.'

            $published.result.findings[0].severity | Should -Be 'blocking'
            $published.result.findings[0].demoted | Should -BeFalse
            $published.result.findings[0].demoted_from | Should -BeNullOrEmpty

            $open = @(Get-ReviewCampaignOpenFindings -StoreRoot (Join-Path $root 'store') -CampaignId 'cmp-demo')
            $open.Count | Should -Be 1 -Because 'a finding that keeps its scenario keeps its gate'
            [string]$open[0].severity | Should -Be 'blocking'
            (@(Get-ReviewCampaignSignoffFindingLines -StoreRoot (Join-Path $root 'store') -CampaignId 'cmp-demo') -join "`n") | Should -Not -Match '(?i)demoted'
        }
    }
}
