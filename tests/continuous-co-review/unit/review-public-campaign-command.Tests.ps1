$ErrorActionPreference = 'Stop'

# Trace: T034b + T051 / FR-012, FR-017, FR-045, FR-057, FR-058, FR-059, FR-060, FR-062, FR-065 / SC-017, SC-018, SC-020.
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
            param([string]$Root, [switch]$WithoutDesignContext)
            New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
            & git -C $Root init -q 2>&1 | Out-Null
            & git -C $Root branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', [Text.UTF8Encoding]::new($false))
            if (-not $WithoutDesignContext) {
                [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', [Text.UTF8Encoding]::new($false))
            }
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

    It 'fails mixed and all-invalid explicit design-context refs before port selection, grant persistence, or spend' -ForEach @(
        @{ name = 'mixed'; refs = @('specs/001-demo/spec.md', 'specs/001-demo/missing.md'); unresolved = @('specs/001-demo/missing.md') }
        @{ name = 'all-invalid'; refs = @('missing-a.md', 'missing-b.md'); unresolved = @('missing-a.md', 'missing-b.md') }
    ) {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive "design-$name")
        $config = New-CampaignConfig -Root $root
        $store = Join-Path $root '.specrew/review/authority'
        Mock -CommandName New-ReviewCampaignProductionPorts -MockWith { throw 'ports-must-not-be-selected' }

        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId "run-design-$name" `
            -GrantAuthorizationRef "human-slot-design-$name" -DesignContextRefs $refs -AuthorityConfigPath $config -StoreRoot $store

        $run.status | Should -Be 'not-started'
        $run.invoked | Should -BeFalse
        $run.reason | Should -Match '^design-context-unresolved:'
        @($run.unresolved_design_context) | Should -Be $unresolved
        Assert-MockCalled -CommandName New-ReviewCampaignProductionPorts -Times 0 -Exactly
        Test-Path -LiteralPath $store | Should -BeFalse -Because 'invalid caller input cannot mint a grant or touch campaign authority state'
    }

    It 'preserves the public pre-store design-context failure instead of masking it with a renderer property error' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'public-design-invalid-render')
        $publicScript = Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'
        $pwsh = (Get-Process -Id $PID).Path
        $output = @(& $pwsh -NoProfile -File $publicScript -ProjectPath $root -FeatureId '001-demo' -IterationNumber '007' `
            -Live -ReviewerHost claude -RunId 'run-public-design-invalid' -AuthorizationRef 'human-slot-public-design-invalid' `
            -DesignContextRef 'specs/001-demo/missing.md' -TimeoutSeconds 30 2>&1)
        $exitCode = $LASTEXITCODE
        $text = ($output | Out-String)

        $exitCode | Should -Be 1
        $text | Should -Match 'design-context-unresolved:'
        $text | Should -Match 'Authority store: unavailable \(run ended before authority-store creation\)'
        $text | Should -Not -Match "property 'store_root' cannot be found"
        Test-Path -LiteralPath (Join-Path $root '.specrew/review/authority') | Should -BeFalse -Because 'invalid explicit context fails before grant or store creation'
    }

    It 'passes validated repo-relative design context through the frozen campaign invocation without changing target identity' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'design-valid')
        $config = New-CampaignConfig -Root $root
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-design-valid'
        $prompt = Join-Path $root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded fixture prompt')
        $origin = Get-GitReviewTargetOriginEvidence -OriginRepo $root
        $captured = [pscustomobject]@{ invocation = $null }
        $candidate = New-CampaignCandidate -RunId $identity.run_id -Digest $origin.reviewed_state_digest
        $harness = [pscustomobject]@{
            id = 'fixture-design-context'
            preflight = { param($invocation) $captured.invocation = $invocation; [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }.GetNewClosure()
            invoke = {
                param($invocation, $environment)
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
        }
        $ports = [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'design-valid-external')
            harness = $harness; runtime = New-ReviewFixtureRuntimePort; clock = New-ReviewSystemClockPort; prompt_path = $prompt
        }
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId $identity.run_id `
            -GrantAuthorizationRef 'human-slot-design-valid' -DesignContextRefs @('specs/001-demo/spec.md') `
            -AuthorityConfigPath $config -StoreRoot (Join-Path $root '.specrew/review/authority') -Ports $ports

        $run.status | Should -Be 'terminal' -Because $run.reason
        $run.result.completion | Should -Be 'complete'
        $run.result.target_digest | Should -Be $origin.reviewed_state_digest
        $run.design_context | Should -Be 'resolved'
        @($run.resolved_design_context) | Should -Be @('specs/001-demo/spec.md')
        $captured.invocation.review_scope | Should -Match ([regex]::Escape('specs/001-demo/spec.md'))
        $captured.invocation.review_scope | Should -Not -Match ([regex]::Escape($root)) -Because 'the prompt gets repo-relative refs, never the mutable origin path'
    }

    It 'auto-resolves design context from the campaign FeatureId in a clean repo with multiple feature specs' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'design-feature-id')
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/999-distractor') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/999-distractor/spec.md'), '# Wrong feature', [Text.UTF8Encoding]::new($false))
        & git -C $root -c user.name=t -c user.email=t@example.invalid add -A 2>&1 | Out-Null
        & git -C $root -c user.name=t -c user.email=t@example.invalid commit -qm 'add distractor feature' 2>&1 | Out-Null

        $config = New-CampaignConfig -Root $root
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-design-feature-id'
        $prompt = Join-Path $root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded fixture prompt')
        $origin = Get-GitReviewTargetOriginEvidence -OriginRepo $root
        $captured = [pscustomobject]@{ invocation = $null }
        $candidate = New-CampaignCandidate -RunId $identity.run_id -Digest $origin.reviewed_state_digest
        $harness = [pscustomobject]@{
            id = 'fixture-design-feature-id'
            preflight = { param($invocation) $captured.invocation = $invocation; [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }.GetNewClosure()
            invoke = {
                param($invocation, $environment)
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
        }
        $ports = [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'design-feature-id-external')
            harness = $harness; runtime = New-ReviewFixtureRuntimePort; clock = New-ReviewSystemClockPort; prompt_path = $prompt
        }
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId $identity.run_id `
            -GrantAuthorizationRef 'human-slot-design-feature-id' -AuthorityConfigPath $config `
            -StoreRoot (Join-Path $root '.specrew/review/authority') -Ports $ports

        $run.status | Should -Be 'terminal' -Because $run.reason
        $run.result.completion | Should -Be 'complete'
        $run.design_context | Should -Be 'resolved'
        @($run.resolved_design_context) | Should -Be @('specs/001-demo/spec.md')
        $captured.invocation.review_scope | Should -Match ([regex]::Escape('specs/001-demo/spec.md'))
        $captured.invocation.review_scope | Should -Not -Match ([regex]::Escape('specs/999-distractor/spec.md'))
        $captured.invocation.review_scope | Should -Not -Match 'DESIGN_CONTEXT_EMPTY'
    }

    It 'turns an omitted unresolved design context into bounded partial evidence even when the reviewer candidate says pass' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'design-empty') -WithoutDesignContext
        $config = New-CampaignConfig -Root $root
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId 'run-design-empty'
        $prompt = Join-Path $root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded fixture prompt')
        $origin = Get-GitReviewTargetOriginEvidence -OriginRepo $root
        $captured = [pscustomobject]@{ invocation = $null }
        $candidate = New-CampaignCandidate -RunId $identity.run_id -Digest $origin.reviewed_state_digest
        $harness = [pscustomobject]@{
            id = 'fixture-design-empty'
            preflight = { param($invocation) $captured.invocation = $invocation; [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }.GetNewClosure()
            invoke = {
                param($invocation, $environment)
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
        }
        $ports = [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $root -ExternalRoot (Join-Path $TestDrive 'design-empty-external')
            harness = $harness; runtime = New-ReviewFixtureRuntimePort; clock = New-ReviewSystemClockPort; prompt_path = $prompt
        }
        $run = Invoke-ReviewCampaignCommand -RepoRoot $root -FeatureId '001-demo' -IterationNumber '007' -RunId $identity.run_id `
            -GrantAuthorizationRef 'human-slot-design-empty' -AuthorityConfigPath $config -StoreRoot (Join-Path $root '.specrew/review/authority') -Ports $ports

        $run.status | Should -Be 'terminal' -Because $run.reason
        $run.design_context | Should -Be 'empty'
        $run.result.validation | Should -Be 'valid'
        $run.result.completion | Should -Be 'partial'
        $run.result.verdict | Should -Be 'incomplete'
        $run.result.can_approve_current | Should -BeFalse
        $run.result.failure_reason | Should -Match '^DESIGN_CONTEXT_EMPTY:'
        $captured.invocation.review_scope | Should -Match 'DESIGN_CONTEXT_EMPTY:'
        $captured.invocation.review_scope.Length | Should -BeLessOrEqual 16000
        (Get-GitReviewTargetOriginEvidence -OriginRepo $root).reviewed_state_digest | Should -Be $origin.reviewed_state_digest
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

    It 'passes the requested model through campaign production-port construction' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'production-model')
        Mock -CommandName New-GitReviewTargetPort -MockWith {
            [pscustomobject]@{ kind = 'git'; origin_repo = $OriginRepo; external_root = $ExternalRoot }
        }
        Mock -CommandName New-ReviewProductionHarnessPort -MockWith {
            [pscustomobject]@{ id = 'cursor-cli-file-primary'; configured_model = $Model }
        }
        Mock -CommandName New-ReviewProductionRuntimePort -MockWith {
            [pscustomobject]@{ id = 'fixture-runtime' }
        }

        $ports = New-ReviewCampaignProductionPorts -RepoRoot $root -ReviewerHost cursor -Model auto -TimeoutSeconds 600

        $ports.harness.configured_model | Should -Be 'auto'
        $ports.target.external_root | Should -Be (Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($root))) '.specrew-targets')
        (Split-Path -Leaf $ports.target.external_root) | Should -Be '.specrew-targets' -Because 'deep Windows target paths need the short sibling root proven by T060'
        Assert-MockCalled -CommandName New-GitReviewTargetPort -Times 1 -Exactly -ParameterFilter {
            $OriginRepo -ceq $root -and $ExternalRoot -ceq (Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($root))) '.specrew-targets')
        }
        Assert-MockCalled -CommandName New-ReviewProductionHarnessPort -Times 1 -Exactly -ParameterFilter {
            $HostName -ceq 'cursor' -and $Model -ceq 'auto' -and $TimeoutSeconds -eq 600
        }
    }

    It 'uses one external-root policy for live and reconciliation paths with an explicit override' {
        $root = New-PublicCampaignRepo -Root (Join-Path $TestDrive 'target-root-policy/repo')
        $override = Join-Path $TestDrive 'explicit-target-root'
        Mock -CommandName New-GitReviewTargetPort -MockWith {
            [pscustomobject]@{ kind = 'git'; origin_repo = $OriginRepo; external_root = $ExternalRoot }
        }

        $default = New-ReviewCampaignTargetPort -RepoRoot $root
        $explicit = New-ReviewCampaignTargetPort -RepoRoot $root -RequestedRoot $override

        $default.external_root | Should -Be (Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($root))) '.specrew-targets')
        $explicit.external_root | Should -Be ([IO.Path]::GetFullPath($override))
        { New-ReviewCampaignTargetPort -RepoRoot $root -RequestedRoot (Join-Path $root 'inside') } | Should -Throw '*review-campaign-target-root-inside-origin*'
        Assert-MockCalled -CommandName New-GitReviewTargetPort -Times 2 -Exactly
    }

    It 'falls back to the repo-scoped writable user root when the repository parent is not usable' {
        $parent = Join-Path $TestDrive 'fallback-parent'
        $root = New-PublicCampaignRepo -Root (Join-Path $parent 'repo')
        [IO.File]::WriteAllText((Join-Path $parent '.specrew-targets'), 'blocks sibling directory creation')
        Mock -CommandName New-GitReviewTargetPort -MockWith {
            [pscustomobject]@{ kind = 'git'; origin_repo = $OriginRepo; external_root = $ExternalRoot }
        }

        $port = New-ReviewCampaignTargetPort -RepoRoot $root
        $gitRoot = (& git -C $root rev-parse --show-toplevel).Trim()
        $token = Get-ReviewCampaignRepositoryToken -GitRoot $gitRoot
        $expected = if ([OperatingSystem]::IsWindows()) {
            Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) ('.sr/' + $token)
        }
        else { Join-Path ([IO.Path]::GetTempPath()) ('specrew-review-targets/' + $token) }

        $port.external_root | Should -Be ([IO.Path]::GetFullPath($expected))
        Assert-MockCalled -CommandName New-GitReviewTargetPort -Times 1 -Exactly -ParameterFilter { $ExternalRoot -ceq ([IO.Path]::GetFullPath($expected)) }
    }

    It 'normalizes repository token identity and candidate dedup for case-insensitive Windows paths' -Skip:(-not [OperatingSystem]::IsWindows()) {
        $one = Get-ReviewCampaignRepositoryToken -GitRoot 'C:\Dev\Repo'
        $two = Get-ReviewCampaignRepositoryToken -GitRoot 'c:\dev\repo'
        $one | Should -Be $two
        $one | Should -Match '^[0-9a-f]{16}$'

        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1') -Raw
        $source | Should -Match '\[StringComparer\]::OrdinalIgnoreCase'
        $source | Should -Match 'HashSet\[string\]'

        $repoToken = Get-ReviewCampaignRepositoryToken -GitRoot $script:RepoRoot
        $fallbackRoot = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)) ('.sr/' + $repoToken)
        $workspaceLeaf = 'rt-' + ('a' * 16) + '-' + ('b' * 32)
        $longestTracked = @(& git -C $script:RepoRoot ls-files) | Sort-Object { $_.Length } -Descending | Select-Object -First 1
        (Join-Path (Join-Path $fallbackRoot $workspaceLeaf) $longestTracked).Length | Should -BeLessThan 260 -Because 'the Windows fallback must not reproduce the long-prefix checkout failure on the current tree'
    }

    It 'keeps a successfully probed shared root and never races to delete another run entry' {
        $root = Join-Path $TestDrive 'shared-probe-root'
        $first = Test-ReviewCampaignTargetRootWritable -Path $root
        $first.ok | Should -BeTrue
        Test-Path -LiteralPath $root -PathType Container | Should -BeTrue

        $otherRun = Join-Path $root 'other-run-entry'
        [IO.File]::WriteAllText($otherRun, 'owned by another run')
        $second = Test-ReviewCampaignTargetRootWritable -Path $root
        $second.ok | Should -BeTrue
        Test-Path -LiteralPath $otherRun -PathType Leaf | Should -BeTrue
        @(Get-ChildItem -LiteralPath $root -Filter '.specrew-write-probe-*' -Force).Count | Should -Be 0
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
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Match 'DesignContextRefs' -Because 'the public parser output must reach campaign validation'
        $source | Should -Match '\$boundDesignContextRefs\s*=\s*@\(\$DesignContextRef\s*\|\s*Where-Object' -Because 'an omitted named array must not become one empty explicit design-context ref'
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Match "PSObject\.Properties\['store_root'\]" -Because 'a pre-store not-started result must render without a second property error'
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Match '-Model\s+\(\[string\]\$parsedArgs\.Model\)' -Because 'the public model selection must reach campaign production-port construction'
        $source.Substring($campaignBranch, $legacy - $campaignBranch) | Should -Match '-TargetRoot\s+\(\[string\]\$parsedArgs\.RunRoot\)' -Because 'the public workspace-root override must reach the singular target policy'
        $source | Should -Match '--reconcile-run'
        $source | Should -Match 'Invoke-ReviewRunReconciliation' -Because 'the public recovery surface must execute the immutable reconciliation plan'
        $source | Should -Match 'New-ReviewCampaignTargetPort -RepoRoot \$resolvedProjectPath' -Because 'reconciliation must reuse the same short-root/fallback policy as live review'

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
