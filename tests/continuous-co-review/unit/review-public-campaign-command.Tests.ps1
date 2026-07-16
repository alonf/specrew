$ErrorActionPreference = 'Stop'

# Trace: T051 / FR-045, FR-057, FR-058, FR-059, FR-062, FR-065 / SC-017, SC-018, SC-020.
Describe 'Public campaign review delegation and campaign-aware packet gate (T051)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        function script:New-CampaignConfig {
            param([string]$Root, [string]$Mode = 'campaign')
            $path = Join-Path $Root 'authority.json'
            [IO.File]::WriteAllText($path, (([ordered]@{ schema_version = '1.0'; mode = $Mode }) | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
            return $path
        }

        function script:New-PublicCampaignRepo {
            param([string]$Root)
            New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', [Text.UTF8Encoding]::new($false))
            & git -C $Root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
            & git -C $Root -c user.name=t -c user.email=t@example.invalid commit -qm initial 2>&1 | Out-Null
            return $Root
        }

        function script:New-CampaignFinding {
            param([string]$Severity = 'major', [string]$Resolution = 'open')
            return [pscustomobject][ordered]@{
                finding_id = 'finding-demo'; source_local_id = 'local-demo'; lineage_id = 'lin-demo'
                severity = $Severity; title = 'Review observation'; description = 'A deterministic finding.'
                location = 'app.txt:1'; relevance = 'current'; resolution = $Resolution
            }
        }

        function script:New-CampaignResult {
            param(
                [string]$RunId = 'run-one', [string]$Digest = 'digest-current',
                [string]$Completion = 'complete', [string]$Verdict = 'pass',
                [string]$Runtime = 'completed', [string]$Currentness = 'current',
                [string]$Validation = 'valid', [bool]$CanApprove = $true,
                [object[]]$Findings = @(), [string]$FailureReason = $null
            )
            $result = [ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-demo-i007'; run_id = $RunId; target_digest = $Digest
                harness_id = 'fixture'; completion = $Completion; verdict = $Verdict; runtime_outcome = $Runtime
                termination_verified = $true; containment = 'verified'; currentness = $Currentness; validation = $Validation
                can_approve_current = $CanApprove; summary = 'fixture result'; findings = @($Findings)
                started_at = '2026-07-16T00:00:00Z'; ended_at = '2026-07-16T00:01:00Z'; duration_ms = 60000
            }
            if (-not [string]::IsNullOrWhiteSpace($FailureReason)) { $result.failure_reason = $FailureReason }
            return [pscustomobject]$result
        }

        function script:New-CampaignCandidate {
            param([string]$RunId, [string]$Digest)
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; run_id = $RunId; target_digest = $Digest
                completion = 'complete'; verdict = 'pass'; summary = 'public command fixture'; findings = @()
            }
        }
    }

    It 'delegates one public operation through campaign ports and preserves the exact origin state' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'public-pass')
        $config = New-CampaignConfig -Root $root
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-public-one'
        $prompt = Join-Path $root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded fixture prompt')
        $originBefore = Get-GitReviewTargetOriginEvidence -OriginRepo $root
        $ports = [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'external')
            harness = New-ReviewFixtureHarnessPort -Candidate (New-CampaignCandidate -RunId $identity.run_id -Digest $originBefore.reviewed_state_digest)
            runtime = New-ReviewFixtureRuntimePort
            clock = New-ReviewSystemClockPort
            prompt_path = $prompt
        }
        $store = Join-Path $root '.specrew/review/authority'
        $progressEvents = [Collections.Generic.List[object]]::new()
        $progressSink = { param($event) $progressEvents.Add($event) | Out-Null }.GetNewClosure()
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId $identity.run_id `
            -ReviewerHost fixture -GrantAuthorizationRef 'human-slot-public-one' -AuthorityConfigPath $config -StoreRoot $store -Ports $ports -ProgressSink $progressSink

        $run.status | Should -Be 'terminal' -Because $run.reason
        $run.invoked | Should -BeTrue
        $run.campaign_id | Should -Be 'cmp-001-demo-i007'
        $run.result.target_digest | Should -Be $originBefore.reviewed_state_digest
        $run.result.can_approve_current | Should -BeTrue
        $run.diagnostics.authority | Should -BeFalse
        $run.diagnostics.event_count | Should -Be @($progressEvents).Count
        $run.diagnostics.heartbeat_count | Should -BeGreaterThan 0
        $run.diagnostics.usage.status | Should -Be 'unavailable'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind grants).Count | Should -Be 1
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind spend).Count | Should -Be 1
        $originAfter = Get-GitReviewTargetOriginEvidence -OriginRepo $root
        $originAfter.origin_head | Should -Be $originBefore.origin_head
        $originAfter.reviewed_state_digest | Should -Be $originBefore.reviewed_state_digest

        $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -AuthorityConfigPath $config -CampaignId $run.campaign_id `
            -TargetLineage $run.target_lineage -CampaignStoreRoot $store
        $gate.decision | Should -Be 'allow'
        $gate.route | Should -Be 'boundary-clean'
        $gate.render_verdict_marker | Should -BeTrue

        $reused = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-public-two' `
            -ReviewerHost fixture -GrantAuthorizationRef 'human-slot-public-one' -AuthorityConfigPath $config -StoreRoot $store -Ports $ports
        $reused.status | Should -Be 'not-started'
        $reused.invoked | Should -BeFalse
        $reused.reason | Should -Be 'allowance-exhausted'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind grants).Count | Should -Be 1
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind spend).Count | Should -Be 1
    }

    It 'fails preflight without spend and never falls back to legacy authority' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'preflight')
        $config = New-CampaignConfig -Root $root
        $prompt = Join-Path $root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded fixture prompt')
        $snapshot = Join-Path $root 'snapshot'; New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
        $ports = [pscustomobject]@{
            target = New-ReviewFixtureTargetPort -SnapshotPath $snapshot -TargetDigest 'digest-current'
            harness = New-ReviewUnavailableHarnessPort -Reason 'fixture-harness-missing'
            runtime = New-ReviewFixtureRuntimePort
            clock = New-ReviewSystemClockPort
            prompt_path = $prompt
        }
        $store = Join-Path $root '.specrew/review/authority'
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-preflight-one' `
            -GrantAuthorizationRef 'human-slot-preflight-one' -AuthorityConfigPath $config -StoreRoot $store -Ports $ports
        $run.status | Should -Be 'failed'
        $run.invoked | Should -BeFalse
        $run.result.runtime_outcome | Should -Be 'preflight-failed'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind spend).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $store -CampaignId $run.campaign_id -Kind releases).Count | Should -Be 1

        $legacyDir = Join-Path $root '.specrew/review/inline/legacy-pass'; New-Item -ItemType Directory -Path $legacyDir -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $legacyDir 'review-run.json'), '{"status":"pass"}')
        $emptyStore = Join-Path $root '.specrew/review/empty-campaign-store'
        $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -AuthorityConfigPath $config -CampaignId 'cmp-001-demo-i007' -TargetLineage 'lin-001-demo' -CampaignStoreRoot $emptyStore
        $gate.decision | Should -Be 'block'
        $gate.reason | Should -Be 'no-authoritative-campaign-result'
    }

    It 'suppresses all execution for missing, malformed, disabled, and legacy authority modes' -ForEach @(
        @{ name = 'missing'; mode = $null; raw = $null; expected = 'authority-config-missing' }
        @{ name = 'malformed'; mode = $null; raw = '{'; expected = 'authority-config-invalid-json' }
        @{ name = 'disabled'; mode = 'disabled'; raw = $null; expected = 'authority-mode-disabled' }
        @{ name = 'legacy'; mode = 'legacy'; raw = $null; expected = 'authority-mode-legacy' }
    ) {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive $name)
        $config = Join-Path $root 'authority.json'
        if ($null -ne $raw) { [IO.File]::WriteAllText($config, $raw) }
        elseif ($null -ne $mode) { $config = New-CampaignConfig -Root $root -Mode $mode }
        $store = Join-Path $root 'store'
        $result = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId "run-$name" -AuthorityConfigPath $config -StoreRoot $store
        $result.status | Should -Be 'suppressed'
        $result.invoked | Should -BeFalse
        $result.reason | Should -Match ([regex]::Escape($expected))
        Test-Path -LiteralPath $store | Should -BeFalse
    }

    It 'wires the existing public live surface to campaign delegation before the legacy diagnostic path' {
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1') -Raw
        $campaignBranch = $source.IndexOf('if ([bool]$authorityDecision.campaign_authority_enabled)')
        $delegate = $source.IndexOf('Invoke-ReviewCampaignCommand', $campaignBranch)
        $legacy = $source.IndexOf("`$coReviewEngine = 'worktree'", $campaignBranch)
        $campaignBranch | Should -BeGreaterThan -1
        $delegate | Should -BeGreaterThan $campaignBranch
        $legacy | Should -BeGreaterThan $delegate
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Not -Match 'Start-ContinuousCoReviewServiceRun'
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Match "campaignRun.status -cne 'terminal'"

        $remediationBranch = $source.IndexOf("if (-not [string]::IsNullOrWhiteSpace([string]`$parsedArgs.Remediate))")
        $legacyRemediation = $source.IndexOf("internal/continuous-co-review/worktree-review-orchestrator.ps1", $remediationBranch)
        $remediationBranch | Should -BeGreaterThan -1
        $legacyRemediation | Should -BeGreaterThan $remediationBranch
        $source.Substring($remediationBranch, $legacyRemediation - $remediationBranch) | Should -Match 'neither legacy nor campaign remediation may mutate review state'
    }

    It 'routes running, clean, actionable, advisory, partial, stale, timeout, and explicit human disposition without marker leakage' {
        $active = [pscustomobject][ordered]@{ schema_version = '1.0'; campaign_id = 'cmp-demo-i007'; run_id = 'run-one'; target_digest = 'digest-current'; harness_id = 'fixture'; state = 'invoked' }
        (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -ActiveRun $active).route | Should -Be 'review-running'

        $clean = New-CampaignResult
        $cleanRoute = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($clean)
        $cleanRoute.route | Should -Be 'boundary-clean'
        $cleanRoute.render_boundary_packet | Should -BeTrue
        $cleanRoute.render_verdict_marker | Should -BeTrue

        $major = New-CampaignResult -Verdict findings -CanApprove $false -Findings @((New-CampaignFinding -Severity major))
        $majorRoute = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($major)
        $majorRoute.route | Should -Be 'review-actionable'

        $note = New-CampaignResult -Verdict findings -CanApprove $false -Findings @((New-CampaignFinding -Severity note))
        $noteRoute = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($note)
        $noteRoute.route | Should -Be 'review-human-decision'
        $noteRoute.ask_narrow_question | Should -BeTrue

        $disposition = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'human-disposition'; disposition_id = 'disposition-human-one'
            campaign_id = 'cmp-demo-i007'; run_id = 'run-one'; target_digest = 'digest-current'; decision = 'accept-current'
            authority_kind = 'human'; authorized_by = 'maintainer'; authorization_ref = 'human-message-1'; rationale = 'accepted advisory risk'; observed_at = '2026-07-16T00:02:00Z'
        }
        $accepted = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($note) -HumanDispositions @($disposition)
        $accepted.route | Should -Be 'boundary-human-disposition'
        $accepted.render_verdict_marker | Should -BeTrue

        $partial = New-CampaignResult -Completion partial -Verdict incomplete -Runtime terminated -CanApprove $false -Findings @((New-CampaignFinding -Severity minor))
        (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($partial)).route | Should -Be 'review-partial'
        $laterPartial = New-CampaignResult -RunId 'run-two' -Completion partial -Verdict incomplete -Runtime terminated -CanApprove $false -Findings @((New-CampaignFinding -Severity minor))
        $supersededClean = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one', 'run-two') -Results @($clean, $laterPartial)
        $supersededClean.route | Should -Be 'review-partial'
        $supersededClean.run_id | Should -Be 'run-two'
        $supersededClean.render_verdict_marker | Should -BeFalse
        $stale = New-CampaignResult -Digest digest-old -Verdict findings -Currentness snapshot-moved -CanApprove $false -Findings @((New-CampaignFinding -Severity major))
        (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($stale)).route | Should -Be 'review-stale'
        $timeout = New-CampaignResult -Completion partial -Verdict incomplete -Runtime timed-out -CanApprove $false -Findings @((New-CampaignFinding -Severity minor)) -FailureReason 'killed after timeout'
        (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($timeout)).route | Should -Be 'review-timeout'

        foreach ($blocked in @($majorRoute, $noteRoute,
                (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($partial)),
                (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($stale)),
                (Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($timeout)))) {
            $blocked.render_boundary_packet | Should -BeFalse
            $blocked.render_verdict_marker | Should -BeFalse
            (Build-ReviewCampaignNavigatorStopBlock -PacketDecision $blocked) | Should -Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
        }
    }

    It 'fails closed when an active claim has no readable run state' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'missing-active-run')
        $store = Join-Path $TestDrive 'missing-active-run-store'
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-missing-state' -TargetLineage 'lin-demo' -ObservedAt '2026-07-16T00:00:00Z' | Out-Null
        $decision = Get-ReviewCampaignVerdictPacketDecision -RepoRoot $root -CampaignId 'cmp-demo-i007' -TargetLineage 'lin-demo' -StoreRoot $store
        $decision.route | Should -Be 'review-failure'
        $decision.reason | Should -Be 'active-claim-run-state-missing'
        $decision.render_verdict_marker | Should -BeFalse
    }

    It 'persists only an exact complete current findings disposition and rejects partial acceptance' {
        $store = Join-Path $TestDrive 'disposition-store'
        $findingResult = New-CampaignResult -Verdict findings -CanApprove $false -Findings @((New-CampaignFinding -Severity note))
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-one' -Fact $findingResult | Out-Null
        $written = Add-ReviewCampaignHumanDisposition -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-one' -Decision accept-current -AuthorizedBy maintainer -AuthorizationRef human-message-1 -Rationale 'accept note'
        $written.created | Should -BeTrue
        @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-one').Count | Should -Be 1

        $partial = New-CampaignResult -RunId 'run-two' -Completion partial -Verdict incomplete -Runtime timed-out -CanApprove $false -Findings @((New-CampaignFinding -Severity minor)) -FailureReason timeout
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-two' -Fact $partial | Out-Null
        { Add-ReviewCampaignHumanDisposition -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-two' -Decision accept-current -AuthorizedBy maintainer -AuthorizationRef human-message-2 -Rationale 'do not allow' } | Should -Throw -ExpectedMessage '*requires-complete-current-valid-result*'

        [IO.File]::Copy($written.path, (Join-Path (Split-Path -Parent $written.path) 'disposition-substituted.json'))
        { Get-ReviewCampaignHumanDispositionFacts -StoreRoot $store -CampaignId 'cmp-demo-i007' } | Should -Throw -ExpectedMessage '*human-disposition-path-identity-mismatch*'
    }
}
