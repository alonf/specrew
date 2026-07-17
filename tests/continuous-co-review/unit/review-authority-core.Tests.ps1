$ErrorActionPreference = 'Stop'

# Trace: T042-T044 / FR-057..FR-063 / SC-017, SC-018, SC-020, SC-021.
Describe 'Review authority closed contracts (T042)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')

        function script:New-CandidateFinding {
            param([string]$LocalId = 'local-1', [string]$Severity = 'major', [string]$Title = 'Bug', [string]$Description = 'Incorrect result', [string]$Location = 'src/app.ps1:10')
            [pscustomobject][ordered]@{ local_id = $LocalId; severity = $Severity; title = $Title; description = $Description; location = $Location }
        }
        function script:New-Candidate {
            param([string]$RunId = 'run-one', [string]$Digest = 'digest-one', [string]$Completion = 'complete', [string]$Verdict = 'pass', [object[]]$Findings = @())
            [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $RunId; target_digest = $Digest; completion = $Completion; verdict = $Verdict; summary = 'reviewed'; findings = @($Findings) }
        }
        function script:New-TerminalFinding {
            [pscustomobject][ordered]@{
                finding_id = 'finding-one'; source_local_id = 'local-1'; lineage_id = 'lin-finding-one'
                severity = 'major'; title = 'Bug'; description = 'Incorrect result'; location = 'src/app.ps1:10'
                relevance = 'current'; resolution = 'open'
            }
        }
        function script:New-TerminalResult {
            param(
                [string]$RunId = 'run-one', [string]$Digest = 'digest-one', [string]$Completion = 'complete',
                [string]$Verdict = 'pass', [string]$RuntimeOutcome = 'completed', [bool]$TerminationVerified = $true,
                [string]$Containment = 'verified', [string]$Currentness = 'current', [string]$Validation = 'valid',
                [bool]$CanApprove = $true, [object[]]$Findings = @(), [long]$DurationMs = 1000
            )
            [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = $RunId; target_digest = $Digest; harness_id = 'fixture'
                completion = $Completion; verdict = $Verdict; runtime_outcome = $RuntimeOutcome; termination_verified = $TerminationVerified
                containment = $Containment; currentness = $Currentness; validation = $Validation; can_approve_current = $CanApprove
                failure_reason = $null; summary = 'terminal'; findings = @($Findings)
                started_at = '2026-07-16T00:00:00.0000000Z'; ended_at = '2026-07-16T00:00:01.0000000Z'; duration_ms = $DurationMs
            }
        }
        function script:New-Grant {
            param([string]$GrantId = 'grant-human', [int]$Slots = 2, [string]$AuthorityKind = 'human')
            [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'grant'; campaign_id = 'cmp-demo'; grant_id = $GrantId; slots = $Slots
                authority_kind = $AuthorityKind; authorization_ref = 'workshop-198-beta2-hardening'; observed_at = '2026-07-16T00:00:00Z'
            }
        }
        function script:New-Reservation {
            param([string]$RunId = 'run-one', [string]$ReservationId = 'res-one', [string]$GrantId = 'grant-human', [int]$Slot = 1)
            [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'reservation'; campaign_id = 'cmp-demo'; reservation_id = $ReservationId
                grant_id = $GrantId; slot = $Slot; run_id = $RunId; observed_at = '2026-07-16T00:00:01Z'
            }
        }
        function script:New-Spend {
            param([string]$RunId = 'run-one', [string]$ReservationId = 'res-one')
            [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'spend'; campaign_id = 'cmp-demo'; reservation_id = $ReservationId
                run_id = $RunId; invocation_started_at = '2026-07-16T00:00:02Z'
            }
        }
        function script:New-Release {
            param([string]$RunId = 'run-one', [string]$ReservationId = 'res-one')
            [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'release'; campaign_id = 'cmp-demo'; reservation_id = $ReservationId
                run_id = $RunId; reason = 'preflight failed'; observed_at = '2026-07-16T00:00:02Z'
            }
        }
    }

    It 'accepts every versioned authority object shape' {
        $cases = @(
            @{ name = 'ReviewCampaign'; object = [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = 'cmp-demo'; target_lineage = 'lin-code'; created_at = '2026-07-16T00:00:00Z' } }
            @{ name = 'ReviewRun'; object = [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'; harness_id = 'fixture'; state = 'requested' } }
            @{ name = 'ReviewInvocation'; object = [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'; snapshot_path = 'C:\review\snapshot'; review_scope = 'Review the full frozen target'; prompt_path = 'C:\review\prompt.md'; candidate_result_path = 'C:\review\candidate.json'; candidate_report_path = 'C:\review\candidate.md'; deadline = '2026-07-16T00:15:00Z' } }
            @{ name = 'ReviewerCandidate'; object = (New-Candidate) }
            @{ name = 'ReviewResult'; object = (New-TerminalResult) }
            @{ name = 'GrantFact'; object = (New-Grant) }
            @{ name = 'ReservationFact'; object = (New-Reservation) }
            @{ name = 'SpendFact'; object = (New-Spend) }
            @{ name = 'ReleaseFact'; object = (New-Release) }
            @{ name = 'ClaimFact'; object = [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'claim-held'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_lineage = 'lin-code'; generation = 1; disposition = 'held'; observed_at = '2026-07-16T00:00:01Z' } }
            @{ name = 'RecoveryFact'; object = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'recovery'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'; harness_id = 'fixture'
                target_lineage = 'lin-code'; runtime_id = 'fixture-runtime'; platform = 'fixture'; containment_kind = 'fixture'; containment_id = 'fixture-contained-process'
                process_id = 42; process_started_at = '2026-07-16T00:00:02Z'; invocation_started_at = '2026-07-16T00:00:02Z'; invocation_started_monotonic_ms = 100
                target_kind = 'fixture'; snapshot_path = 'C:\review\snapshot'; workspace_root = 'C:\review\snapshot'; origin_repo = 'not-applicable'
                git_root = 'not-applicable'; origin_head_before = 'not-applicable'; staging_root = 'C:\review\staging'
            } }
        )
        foreach ($case in $cases) {
            $result = Test-ReviewAuthorityContractObject -ContractName $case.name -InputObject $case.object
            $result.valid | Should -BeTrue -Because ("{0}: {1}" -f $case.name, ($result.errors -join '; '))
            $result.category | Should -Be 'valid'
        }
    }

    It 'derives the terminal duration ceiling from the shared timeout, grace, and overhead limits' {
        $limits = Get-ReviewAuthorityTimingLimits
        $limits.max_invocation_timeout_seconds | Should -Be 7200
        $limits.max_termination_grace_seconds | Should -Be 10
        $limits.orchestration_overhead_allowance_seconds | Should -Be 120
        $limits.max_duration_ms | Should -Be ((
            $limits.max_invocation_timeout_seconds +
            $limits.max_termination_grace_seconds +
            $limits.orchestration_overhead_allowance_seconds
        ) * 1000)

        (Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject (New-TerminalResult -DurationMs $limits.max_duration_ms)).valid | Should -BeTrue
        $beyond = Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject (New-TerminalResult -DurationMs ($limits.max_duration_ms + 1))
        $beyond.valid | Should -BeFalse
        ($beyond.errors -join ';') | Should -Match 'out-of-range:duration_ms'
    }

    It 'rejects unknown fields, unsupported versions, illegal states, and identity substitution' {
        $unknown = New-Candidate
        $unknown | Add-Member -NotePropertyName hidden_retry -NotePropertyValue $true
        (Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $unknown).category | Should -Be 'unknown-field'

        $version = New-Candidate
        $version.schema_version = '2.0'
        (Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $version).category | Should -Be 'unsupported-version'

        $illegal = New-Candidate -Completion partial -Verdict pass
        $illegalResult = Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $illegal
        $illegalResult.valid | Should -BeFalse
        ($illegalResult.errors -join ';') | Should -Match 'partial-requires-incomplete'

        $substituted = Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject (New-Candidate -RunId 'run-other' -Digest 'digest-other') -ExpectedRunId 'run-one' -ExpectedTargetDigest 'digest-one'
        $substituted.category | Should -Be 'identity-mismatch'
        ($substituted.errors -join ';') | Should -Match 'run_id'
        ($substituted.errors -join ';') | Should -Match 'target_digest'
    }

    It 'rejects prose-wrapped, malformed, oversized, and unbounded candidate JSON' {
        (Test-ReviewAuthorityContractJson -ContractName ReviewerCandidate -Json 'Here is the JSON: {"schema_version":"1.0"}').category | Should -Be 'prose-wrapped-json'
        (Test-ReviewAuthorityContractJson -ContractName ReviewerCandidate -Json '{broken}').category | Should -Be 'invalid-json'
        (Test-ReviewAuthorityContractJson -ContractName ReviewerCandidate -Json ('{"x":"' + ('x' * 200) + '"}') -MaxBytes 32).category | Should -Be 'payload-too-large'

        $findings = @(1..101 | ForEach-Object { New-CandidateFinding -LocalId "local-$_" })
        $unbounded = New-Candidate -Completion partial -Verdict incomplete -Findings $findings
        $validation = Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $unbounded
        $validation.valid | Should -BeFalse
        ($validation.errors -join ';') | Should -Match 'too-many:findings:100'
    }

    It 'rejects duplicate candidate local IDs and accepts distinct IDs' {
        $duplicate = New-Candidate -Verdict findings -Findings @(
            (New-CandidateFinding -LocalId 'reviewer-1'),
            (New-CandidateFinding -LocalId 'reviewer-1' -Title 'Second bug')
        )
        $duplicateValidation = Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $duplicate
        $duplicateValidation.valid | Should -BeFalse
        ($duplicateValidation.errors -join ';') | Should -Match 'duplicate-value:findings\[1\]\.local_id'

        $distinct = New-Candidate -Verdict findings -Findings @(
            (New-CandidateFinding -LocalId 'reviewer-1'),
            (New-CandidateFinding -LocalId 'reviewer-2' -Title 'Second bug')
        )
        (Test-ReviewAuthorityContractObject -ContractName ReviewerCandidate -InputObject $distinct).valid | Should -BeTrue
    }

    It 'rejects agent-created allowance and an approval claim missing its prerequisites' {
        $grant = New-Grant -AuthorityKind 'agent'
        (Test-ReviewAuthorityContractObject -ContractName GrantFact -InputObject $grant).valid | Should -BeFalse

        $result = New-TerminalResult -Completion partial -Verdict incomplete -RuntimeOutcome timed-out -CanApprove $true
        $validation = Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject $result
        $validation.valid | Should -BeFalse
        ($validation.errors -join ';') | Should -Match 'approval-prerequisites-not-proven'
    }

    It 'keeps the policy core free of filesystem, Git, process, environment, and clock reads' {
        $path = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1'
        $tokens = $null; $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors)
        @($parseErrors).Count | Should -Be 0
        $commandNames = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })
        foreach ($forbidden in @('Get-Content', 'Set-Content', 'New-Item', 'Remove-Item', 'Start-Process', 'Get-Process', 'Invoke-Expression', 'git')) {
            $commandNames | Should -Not -Contain $forbidden
        }
        (Get-Content -LiteralPath $path -Raw) | Should -Not -Match '\[datetime\]::(UtcNow|Now)|\$env:'
    }
}

Describe 'Pure campaign allowance and rerun policy (T043)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')

        function script:Grant([int]$Slots = 2) { [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'grant'; campaign_id = 'cmp-demo'; grant_id = 'grant-human'; slots = $Slots; authority_kind = 'human'; authorization_ref = 'human-verdict'; observed_at = '2026-07-16T00:00:00Z' } }
        function script:Reservation([string]$Run = 'run-one', [string]$Id = 'res-one', [int]$Slot = 1) { [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'reservation'; campaign_id = 'cmp-demo'; reservation_id = $Id; grant_id = 'grant-human'; slot = $Slot; run_id = $Run; observed_at = '2026-07-16T00:00:01Z' } }
        function script:Spend([string]$Run = 'run-one', [string]$Id = 'res-one') { [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'spend'; campaign_id = 'cmp-demo'; reservation_id = $Id; run_id = $Run; invocation_started_at = '2026-07-16T00:00:02Z' } }
        function script:Release([string]$Run = 'run-one', [string]$Id = 'res-one') { [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'release'; campaign_id = 'cmp-demo'; reservation_id = $Id; run_id = $Run; reason = 'preflight failure'; observed_at = '2026-07-16T00:00:02Z' } }
        function script:PriorResult([string]$Completion = 'partial', [string]$Currentness = 'current', [string]$Validation = 'valid') { [pscustomobject]@{ run_id = 'run-one'; completion = $Completion; currentness = $Currentness; validation = $Validation } }
    }

    It 'reserves only a human-granted free slot and reports exhaustion' {
        (Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-one -ReservationId res-one -ObservedAt now).reason | Should -Be 'allowance-exhausted'

        $first = Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-one -ReservationId res-one -ObservedAt now -Grants @(Grant)
        $first.permitted | Should -BeTrue
        $first.fact.grant_id | Should -Be 'grant-human'
        $first.fact.slot | Should -Be 1

        $second = Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-two -ReservationId res-two -ObservedAt later -Grants @(Grant) -Reservations @($first.fact)
        $second.permitted | Should -BeTrue
        $second.fact.slot | Should -Be 2

        (Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-three -ReservationId res-one -ObservedAt latest -Grants @(Grant) -Reservations @($first.fact)).reason | Should -Be 'reservation-id-already-used'

        (Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-three -ReservationId res-three -ObservedAt latest -Grants @(Grant) -Reservations @($first.fact, $second.fact)).reason | Should -Be 'allowance-exhausted'
    }

    It 'requires all cheap preflights before spend and keeps an invoked failure spent' {
        $reservation = Reservation
        $failed = Resolve-ReviewCampaignSpendDecision -Reservation $reservation -InvocationStartedAt now -Preflight @{ target = $true; store = $true; contract = $true; containment = $true; harness = $false; runtime = $true }
        $failed.permitted | Should -BeFalse
        $failed.reason | Should -Match 'preflight-failed:harness'

        $spent = Resolve-ReviewCampaignSpendDecision -Reservation $reservation -InvocationStartedAt now -Preflight @{ target = $true; store = $true; contract = $true; containment = $true; harness = $true; runtime = $true }
        $spent.permitted | Should -BeTrue
        $spent.fact.fact_type | Should -Be 'spend'

        $release = Resolve-ReviewCampaignReleaseDecision -Reservation $reservation -Reason 'reviewer crashed' -ObservedAt later -Spends @($spent.fact)
        $release.permitted | Should -BeFalse
        $release.reason | Should -Be 'invoked-slot-remains-spent'
    }

    It 'releases only a proven pre-invocation reservation and makes its slot reusable' {
        $reservation = Reservation
        $release = Resolve-ReviewCampaignReleaseDecision -Reservation $reservation -Reason 'preflight failed' -ObservedAt later
        $release.permitted | Should -BeTrue
        $state = Get-ReviewCampaignAllowanceState -CampaignId cmp-demo -Grants @(Grant 1) -Reservations @($reservation) -Releases @($release.fact)
        $state.valid | Should -BeTrue
        $state.available.Count | Should -Be 1
        $state.spent.Count | Should -Be 0

        $replacement = Resolve-ReviewCampaignReservationDecision -CampaignId cmp-demo -RunId run-two -ReservationId res-two -ObservedAt latest -Grants @(Grant 1) -Reservations @($reservation) -Releases @($release.fact)
        $replacement.permitted | Should -BeTrue
        $replacement.fact.slot | Should -Be 1
        $reused = Get-ReviewCampaignAllowanceState -CampaignId cmp-demo -Grants @(Grant 1) -Reservations @($reservation, $replacement.fact) -Releases @($release.fact)
        $reused.valid | Should -BeTrue
        $reused.active.Count | Should -Be 1
        $reused.active[0].run_id | Should -Be 'run-two'
    }

    It 'bounds immutable release diagnostics without losing explicit truncation provenance' {
        $release = Resolve-ReviewCampaignReleaseDecision -Reservation (Reservation) -Reason ('adapter failure ' + ('x' * 2000)) -ObservedAt later
        $release.permitted | Should -BeTrue
        $release.fact.reason.Length | Should -Be 512
        $release.fact.reason | Should -Match '\.\.\.\[truncated\]$'
        (Test-ReviewAuthorityContractObject -ContractName ReleaseFact -InputObject $release.fact).valid | Should -BeTrue
    }

    It 'fails closed on conflicting slot history and on agent allowance' {
        $duplicate = Get-ReviewCampaignAllowanceState -CampaignId cmp-demo -Grants @(Grant 1) -Reservations @((Reservation), (Reservation -Run run-two -Id res-two))
        $duplicate.valid | Should -BeFalse
        ($duplicate.errors -join ';') | Should -Match 'overlapping-reservation-slot'

        $agentGrant = Grant
        $agentGrant.authority_kind = 'agent'
        (Get-ReviewCampaignAllowanceState -CampaignId cmp-demo -Grants @($agentGrant)).valid | Should -BeFalse
    }

    It 'requires a visible new run for partial/moved reruns and requests a human grant when exhausted' {
        $available = Resolve-ReviewRerunDecision -PriorResult (PriorResult) -ProposedRunId run-two -ExistingRunIds @('run-one') -HasAvailableSlot $true
        $available.required | Should -BeTrue
        $available.launch | Should -BeTrue
        $available.action | Should -Be 'launch-visible-rerun'

        (Resolve-ReviewRerunDecision -PriorResult (PriorResult) -ProposedRunId run-one -ExistingRunIds @('run-one') -HasAvailableSlot $true).reason | Should -Be 'rerun-requires-new-run-id'
        (Resolve-ReviewRerunDecision -PriorResult (PriorResult -Currentness snapshot-moved) -ProposedRunId run-two -ExistingRunIds @('run-one') -HasAvailableSlot $false).action | Should -Be 'request-human-grant'
        (Resolve-ReviewRerunDecision -PriorResult (PriorResult -Completion complete) -ProposedRunId run-two -ExistingRunIds @('run-one') -HasAvailableSlot $true).required | Should -BeFalse
    }

    It 'selects at most one result by explicit run order, never timestamp' {
        $r1 = [pscustomobject]@{ run_id = 'run-one'; target_digest = 'digest'; completion = 'complete'; currentness = 'current'; validation = 'valid'; ended_at = 'later' }
        $r2 = [pscustomobject]@{ run_id = 'run-two'; target_digest = 'digest'; completion = 'complete'; currentness = 'current'; validation = 'valid'; ended_at = 'earlier' }
        (Resolve-ReviewCampaignSelectedResult -TargetDigest digest -OrderedRunIds @('run-one', 'run-two') -Results @($r1, $r2)).selected_run_id | Should -Be 'run-two'
        (Resolve-ReviewCampaignSelectedResult -TargetDigest digest -OrderedRunIds @('run-two', 'run-one') -Results @($r1, $r2)).selected_run_id | Should -Be 'run-one'
        (Resolve-ReviewCampaignSelectedResult -TargetDigest digest -OrderedRunIds @('run-one') -Results @($r1, $r1)).valid | Should -BeFalse
    }

    It 'surfaces a duplicate target/harness/contract combination before spend' {
        $runs = @([pscustomobject]@{ schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest'; harness_id = 'claude'; state = 'requested' })
        $duplicate = Test-ReviewCampaignDuplicateCombination -TargetDigest digest -HarnessId claude -ContractVersion '1.0' -Runs $runs
        $duplicate.duplicate | Should -BeTrue
        $duplicate.prior_run_ids | Should -Contain 'run-one'
    }
}

Describe 'Pure run, acceptance, currentness, and finding-lineage policy (T044)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
        function script:Candidate([string]$Completion = 'complete', [string]$Verdict = 'pass', [object[]]$Findings = @()) { [pscustomobject]@{ completion = $Completion; verdict = $Verdict; findings = @($Findings) } }
        function script:Finding([string]$Local = 'local-1', [string]$Severity = 'major', [string]$Title = 'Same bug', [string]$Description = 'Same description', [string]$Location = 'src/a.ps1:1') { [pscustomobject]@{ local_id = $Local; severity = $Severity; title = $Title; description = $Description; location = $Location } }
    }

    It 'permits every legal one-invocation transition' -ForEach @(
        @{ state = 'requested'; event = 'reserve'; next = 'reserved' }
        @{ state = 'reserved'; event = 'preflight-pass'; next = 'preflighted' }
        @{ state = 'preflighted'; event = 'claim'; next = 'claimed' }
        @{ state = 'claimed'; event = 'invoke'; next = 'invoked' }
        @{ state = 'invoked'; event = 'candidate-ready'; next = 'validating' }
        @{ state = 'reserved'; event = 'close-pre-invocation'; next = 'terminal' }
        @{ state = 'preflighted'; event = 'close-pre-invocation'; next = 'terminal' }
        @{ state = 'claimed'; event = 'close-pre-invocation'; next = 'terminal' }
        @{ state = 'invoked'; event = 'close-post-invocation'; next = 'terminal' }
        @{ state = 'validating'; event = 'close-post-invocation'; next = 'terminal' }
    ) {
        $decision = Resolve-ReviewRunTransition -CurrentState $state -Event $event
        $decision.allowed | Should -BeTrue
        $decision.next_state | Should -Be $next
    }

    It 'rejects illegal, repeated invocation, and second-terminal transitions' {
        (Resolve-ReviewRunTransition -CurrentState requested -Event invoke).allowed | Should -BeFalse
        (Resolve-ReviewRunTransition -CurrentState invoked -Event invoke).allowed | Should -BeFalse
        (Resolve-ReviewRunTransition -CurrentState terminal -Event close-post-invocation).reason | Should -Be 'terminal-is-immutable'
        (Resolve-ReviewRunTransition -CurrentState validating -Event close-post-invocation -TerminalResultExists $true).allowed | Should -BeFalse
    }

    It 'classifies exact, moved, and unknown target evidence' {
        (Resolve-ReviewCurrentness -ReviewedDigest d1 -CurrentDigest d1 -OriginHeadBefore h1 -OriginHeadAfter h1).classification | Should -Be 'current'
        (Resolve-ReviewCurrentness -ReviewedDigest d1 -CurrentDigest d2 -OriginHeadBefore h1 -OriginHeadAfter h1).classification | Should -Be 'snapshot-moved'
        (Resolve-ReviewCurrentness -ReviewedDigest d1 -CurrentDigest d1 -OriginHeadBefore h1 -OriginHeadAfter h2).classification | Should -Be 'snapshot-moved'
        (Resolve-ReviewCurrentness -ReviewedDigest '' -CurrentDigest d1 -OriginHeadBefore h1 -OriginHeadAfter h1).classification | Should -Be 'unknown'
    }

    It 'allows approval only for a complete valid current pass with verified containment and termination' {
        $pass = Resolve-ReviewResultClassification -RuntimeOutcome completed -Invoked $true -TerminationVerified $true -Containment verified -Currentness current -Candidate (Candidate) -CandidateValid $true
        $pass.publish_permitted | Should -BeTrue
        $pass.completion | Should -Be 'complete'
        $pass.can_approve_current | Should -BeTrue

        $finding = Finding
        $blocking = Resolve-ReviewResultClassification -RuntimeOutcome completed -Invoked $true -TerminationVerified $true -Containment verified -Currentness current -Candidate (Candidate -Verdict findings -Findings @($finding)) -CandidateValid $true
        $blocking.completion | Should -Be 'complete'
        $blocking.can_approve_current | Should -BeFalse
        $blocking.findings_advisory | Should -BeFalse
    }

    It 'retains partial and moved findings as advisory and requires a complete current rerun' {
        $finding = Finding
        $partial = Resolve-ReviewResultClassification -RuntimeOutcome timed-out -Invoked $true -TerminationVerified $true -Containment verified -Currentness current -Candidate (Candidate -Completion partial -Verdict incomplete -Findings @($finding)) -CandidateValid $true
        $partial.completion | Should -Be 'partial'
        $partial.findings.Count | Should -Be 1
        $partial.findings_advisory | Should -BeTrue
        $partial.require_complete_rerun | Should -BeTrue

        $moved = Resolve-ReviewResultClassification -RuntimeOutcome completed -Invoked $true -TerminationVerified $true -Containment verified -Currentness snapshot-moved -Candidate (Candidate -Verdict findings -Findings @($finding)) -CandidateValid $true
        $moved.completion | Should -Be 'complete'
        $moved.can_approve_current | Should -BeFalse
        $moved.findings_advisory | Should -BeTrue
        $moved.reason | Should -Be 'snapshot-moved'
    }

    It 'does not publish a timeout classification until process-tree death is verified' {
        $decision = Resolve-ReviewResultClassification -RuntimeOutcome timed-out -Invoked $true -TerminationVerified $false -Containment unknown -Currentness current -Candidate $null -CandidateValid $false
        $decision.publish_permitted | Should -BeFalse
        $decision.reason | Should -Be 'timeout-requires-verified-tree-death'
        $decision.can_approve_current | Should -BeFalse
    }

    It 'links likely matches without requiring shared reviewer IDs or rewriting severity' {
        $prior = [pscustomobject]@{ finding_id = 'finding-one'; lineage_id = 'lin-existing'; severity = 'blocking'; title = 'Same bug'; description = 'Same description'; location = 'src/a.ps1:1' }
        $current = Finding -Local 'reviewer-local-99' -Severity minor
        $links = @(Resolve-ReviewFindingLineage -RunId run-two -CurrentFindings @($current) -PriorFindings @($prior))
        $links.Count | Should -Be 1
        $links[0].matched_prior_finding_id | Should -Be 'finding-one'
        $links[0].lineage_id | Should -Be 'lin-existing'
        $links[0].severity | Should -Be 'minor'
        $links[0].prior_severity | Should -Be 'blocking'
        $links[0].current_local_id | Should -Be 'reviewer-local-99'
    }

    It 'starts a new deterministic lineage for a non-matching finding' {
        $links = @(Resolve-ReviewFindingLineage -RunId run-two -CurrentFindings @((Finding -Title 'New bug')) -PriorFindings @())
        $links[0].lineage_id | Should -Match '^lin-[a-f0-9]{16}$'
        $links[0].finding_id | Should -Match '^finding-[a-f0-9]{16}$'
    }
}
