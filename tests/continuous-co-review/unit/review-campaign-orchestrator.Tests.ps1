$ErrorActionPreference = 'Stop'

# Trace: T048 / FR-057, FR-060, FR-061, FR-063 / SC-020, SC-021.
Describe 'Synchronous review campaign orchestration through ports (T048)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:OrchestratorPath = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1'
        . $script:OrchestratorPath
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-claude-harness-port.ps1')

        function script:New-OrchestratorCandidate {
            param([string]$Run = 'run-one', [string]$Digest = 'digest-one', [string]$Completion = 'complete', [string]$Verdict = 'pass', [object[]]$Findings = @())
            [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $Run; target_digest = $Digest; completion = $Completion; verdict = $Verdict; summary = 'fixture review'; findings = @($Findings) }
        }
        function script:New-OrchestratorFinding {
            [pscustomobject][ordered]@{ local_id = 'local-1'; severity = 'major'; title = 'Bug'; description = 'Incorrect behavior'; location = 'src/app.ps1:1' }
        }
        function script:New-OrchestratorClock {
            $times = @(0..30 | ForEach-Object { ([DateTimeOffset]'2026-07-16T00:00:00Z').AddSeconds($_).ToString('o') })
            return New-ReviewFixtureClockPort -UtcValues $times -MonotonicValues @(100, 1100)
        }
        function script:Initialize-OrchestratorContext {
            param([Parameter(Mandatory)][string]$Root, [int]$Slots = 1)
            $store = Join-Path $Root 'store'; $staging = Join-Path $Root 'staging'; $snapshot = Join-Path $Root 'snapshot'
            New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
            $prompt = Join-Path $Root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded prompt')
            $config = Join-Path $Root 'authority.json'; [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}')
            $grant = [pscustomobject][ordered]@{ schema_version = '1.0'; fact_type = 'grant'; campaign_id = 'cmp-demo'; grant_id = 'grant-human'; slots = $Slots; authority_kind = 'human'; authorization_ref = 'human-verdict'; observed_at = '2026-07-16T00:00:00Z' }
            Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant | Out-Null
            return [pscustomobject]@{ store = $store; staging = $staging; snapshot = $snapshot; prompt = $prompt; config = $config }
        }
        function script:Invoke-OrchestratorFixture {
            param(
                [Parameter(Mandatory)]$Context, [string]$Run = 'run-one', [string]$Reservation = 'res-one',
                [Parameter(Mandatory)]$Target, [Parameter(Mandatory)]$Harness, [Parameter(Mandatory)]$Runtime,
                [scriptblock]$ProgressSink, [int]$TimeoutSeconds = 900
            )
            return Invoke-ReviewCampaignRun -StoreRoot $Context.store -StagingRoot $Context.staging -CampaignId cmp-demo -RunId $Run -ReservationId $Reservation -TargetLineage lin-code -TargetPort $Target -HarnessPort $Harness -RuntimePort $Runtime -VerificationPort (New-ReviewFixtureVerificationPort) -ClockPort (New-OrchestratorClock) -PromptPath $Context.prompt -ProgressSink $ProgressSink -TimeoutSeconds $TimeoutSeconds -AuthorityConfigPath $Context.config
        }
        function script:New-OrchestratorGitRepo {
            param([string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null; & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'app.txt'), 'v1')
            & git -C $Path -c user.name=orchestrator-test -c user.email=test@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=orchestrator-test -c user.email=test@example.invalid commit -qm initial 2>&1 | Out-Null
        }
        function script:New-ClaudeFilePrimaryFixtureHarness {
            param(
                [Parameter(Mandatory)]$FileCandidate,
                [Parameter(Mandatory)][string]$Stdout
            )
            $promptPath = Join-Path $TestDrive ('claude-file-primary-' + [guid]::NewGuid().ToString('N') + '.md')
            [IO.File]::WriteAllText($promptPath, @'
Write the candidate directly to this exact path:
CANDIDATE_RESULT_PATH=__CANDIDATE_RESULT_PATH__
The run is __RUN_ID__ and the target digest is __TARGET_DIGEST__.
Review scope: __REVIEW_SCOPE__
Deadline: __DEADLINE__
Do not modify the source. The file must contain ONLY the raw JSON object: no prose and no Markdown fences.
Do not delegate to subagents or start other model-backed reviewers.
Use risk-based inspection; you are not required to open every file. A complete candidate means the requested review scope received reasonable risk coverage. Do not complete while a high-risk check remains.
Stdout is telemetry and is never parsed for authority.
`location`, when present, must be one plain JSON string; never an object, array, number, or boolean.
'@)
            $candidateText = if ($FileCandidate -is [string]) { $FileCandidate } else { $FileCandidate | ConvertTo-Json -Depth 20 -Compress }
            $agentInvoker = {
                param($worktreePath, $prompt, $timeout)
                $match = [regex]::Match($prompt, '(?m)^CANDIDATE_RESULT_PATH=(?<path>.+)$')
                if (-not $match.Success) { throw 'fixture-candidate-path-not-in-prompt' }
                [IO.File]::WriteAllText($match.Groups['path'].Value.Trim(), $candidateText, [Text.UTF8Encoding]::new($false))
                return [pscustomobject]@{
                    exit_code = 0; stdout = $Stdout; stderr = ''
                    telemetry = [pscustomobject]@{ timed_out = $false; containment = 'fixture'; containment_degraded_reason = $null }
                }
            }.GetNewClosure()
            return New-ReviewClaudeFilePrimaryHarnessPort -PromptTemplatePath $promptPath -TimeoutSeconds 900 -AgentInvoker $agentInvoker -AvailabilityProbe { $true }
        }
    }

    It 'suppresses campaign execution when the single authority seam is not in campaign mode' {
        $root = Join-Path $TestDrive 'suppressed'; $context = Initialize-OrchestratorContext -Root $root
        [IO.File]::WriteAllText($context.config, '{"schema_version":"1.0","mode":"legacy"}')
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort)
        $result.status | Should -Be 'suppressed'
        $result.invoked | Should -BeFalse
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind reservations).Count | Should -Be 0
    }

    It 'composes a successful run with preflight-before-spend and informational progress' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'success')
        $events = [Collections.Generic.List[object]]::new(); $sink = { param($event) $events.Add($event) | Out-Null }.GetNewClosure()
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort) -ProgressSink $sink
        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.invoked | Should -BeTrue
        $result.result.can_approve_current | Should -BeTrue
        $result.result.duration_ms | Should -Be 1000
        $result.result.started_at | Should -Match '^2026-07-16T'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 1
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind releases).Count | Should -Be 0
        @($events).Count | Should -BeGreaterThan 2
        @($events | Where-Object { $_.authority }).Count | Should -Be 0
        @($events | Where-Object { $null -ne $_.validated_finding_count -and $_.stage -ne 'terminal' }).Count | Should -Be 0
    }

    It 'contains output-producing progress renderers across the real orchestration call path' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'outputting-progress-renderer')
        $outputtingSink = { param($event) 'renderer-pipeline-sentinel' }
        $pipelineResult = @(Invoke-OrchestratorFixture -Context $context `
            -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) `
            -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) `
            -Runtime (New-ReviewFixtureRuntimePort) -ProgressSink $outputtingSink)

        $pipelineResult.Count | Should -Be 1 -Because 'renderer output must not join the runtime result pipeline'
        $pipelineResult[0].status | Should -Be 'terminal' -Because $pipelineResult[0].reason
        $pipelineResult[0].result.can_approve_current | Should -BeTrue
    }

    It 'models production progress-output containment in the fixture runtime port' {
        $runtime = New-ReviewFixtureRuntimePort
        $harness = [pscustomobject]@{
            invoke = { param($invocation, $environment) [pscustomobject]@{ output_activity = $false } }
        }
        $runtimeOutput = @(& $runtime.invoke $harness ([pscustomobject]@{}) {} @{} { param($sample) 'fixture-runtime-progress-sentinel' })

        $runtimeOutput.Count | Should -Be 1 -Because 'the fixture must model the production runtime progress-discard boundary'
        $runtimeOutput[0].runtime_outcome | Should -Be 'completed'
    }

    It 'warns about a duplicate target-harness-contract before a separately authorized rerun spends' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'duplicate-warning') -Slots 2
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $first = Invoke-OrchestratorFixture -Context $context -Run run-one -Reservation res-one -Target $target `
            -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Run run-one)) -Runtime (New-ReviewFixtureRuntimePort)
        $first.status | Should -Be 'terminal'

        $events = [Collections.Generic.List[object]]::new(); $sink = { param($event) $events.Add($event) | Out-Null }.GetNewClosure()
        $second = Invoke-OrchestratorFixture -Context $context -Run run-two -Reservation res-two -Target $target `
            -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Run run-two)) -Runtime (New-ReviewFixtureRuntimePort) -ProgressSink $sink
        $second.status | Should -Be 'terminal' -Because $second.reason

        $stages = @($events | ForEach-Object { [string]$_.stage })
        $warningIndex = [array]::IndexOf($stages, 'duplicate-warning')
        $runningIndex = [array]::IndexOf($stages, 'running')
        $warningIndex | Should -BeGreaterThan -1
        $runningIndex | Should -BeGreaterThan $warningIndex
        @($events | Where-Object { [string]$_.stage -ceq 'duplicate-warning' -and $_.authority }).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 2
    }

    It 'accepts the shared invocation-timeout ceiling and rejects a value above it before reservation' {
        $limits = Get-ReviewAuthorityTimingLimits
        $atMax = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'timeout-at-max')
        $accepted = Invoke-OrchestratorFixture -Context $atMax -Target (New-ReviewFixtureTargetPort -SnapshotPath $atMax.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort) -TimeoutSeconds $limits.max_invocation_timeout_seconds
        $accepted.status | Should -Be 'terminal' -Because $accepted.reason

        $aboveMax = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'timeout-above-max')
        { Invoke-OrchestratorFixture -Context $aboveMax -Target (New-ReviewFixtureTargetPort -SnapshotPath $aboveMax.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort) -TimeoutSeconds ($limits.max_invocation_timeout_seconds + 1) } | Should -Throw -ExpectedMessage '*TimeoutSeconds must be between 1 and 7200*'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $aboveMax.store -CampaignId cmp-demo -Kind reservations).Count | Should -Be 0
    }

    It 'runs the production Git target through the same synchronous contract' {
        $root = Join-Path $TestDrive 'git-flow'; $context = Initialize-OrchestratorContext -Root $root
        $origin = Join-Path $root 'origin'; $external = Join-Path $root 'external'
        New-OrchestratorGitRepo -Path $origin
        [IO.File]::WriteAllText((Join-Path $origin 'app.txt'), 'dirty-v2')
        $evidence = Get-GitReviewTargetOriginEvidence -OriginRepo $origin
        $candidate = New-OrchestratorCandidate -Digest $evidence.reviewed_state_digest
        $headBefore = $evidence.origin_head
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-GitReviewTargetPort -OriginRepo $origin -ExternalRoot $external) -Harness (New-ReviewFixtureHarnessPort -Candidate $candidate) -Runtime (New-ReviewFixtureRuntimePort)
        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.result.target_digest | Should -Be $evidence.reviewed_state_digest
        $result.result.currentness | Should -Be 'current'
        (Get-GitReviewTargetOriginEvidence -OriginRepo $origin).origin_head | Should -Be $headBefore
        (Get-Content -LiteralPath (Join-Path $origin 'app.txt') -Raw) | Should -Be 'dirty-v2'
        @(& git -C $origin worktree list --porcelain | Select-String 'review-target-run-one').Count | Should -Be 0 -Because 'the synchronous run disposes its external worktree before return'
    }

    It 'fails preflight and launch before spend, releasing allowance without invoking a provider' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'preflight-launch') -Slots 3
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $preflight = Invoke-OrchestratorFixture -Context $context -Run run-one -Reservation res-one -Target $target -Harness (New-ReviewFixtureHarnessPort -PreflightPass $false) -Runtime (New-ReviewFixtureRuntimePort)
        $preflight.invoked | Should -BeFalse
        $preflight.result.runtime_outcome | Should -Be 'preflight-failed'
        Test-Path -LiteralPath $preflight.result_path -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath $preflight.report_path -PathType Leaf | Should -BeTrue

        $runtimePreflight = Invoke-OrchestratorFixture -Context $context -Run run-two -Reservation res-two -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Run run-two)) -Runtime (New-ReviewFixtureRuntimePort -PreflightPass $false)
        $runtimePreflight.invoked | Should -BeFalse
        $runtimePreflight.reason | Should -Be 'preflight-failed:runtime'
        Test-Path -LiteralPath $runtimePreflight.report_path -PathType Leaf | Should -BeTrue

        $launch = Invoke-OrchestratorFixture -Context $context -Run run-three -Reservation res-three -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Run run-three)) -Runtime (New-ReviewFixtureRuntimePort -Outcome launch-failed)
        $launch.invoked | Should -BeFalse
        $launch.result.runtime_outcome | Should -Be 'launch-failed'
        Test-Path -LiteralPath $launch.report_path -PathType Leaf | Should -BeTrue
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind releases).Count | Should -Be 3
    }

    It 'stops before harness or runtime preflight when OS target protection is unavailable' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'target-protection-preflight')
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $target.protect = { param($snapshot, $candidatePath) [pscustomobject]@{ ok = $false; reason = 'fixture-protection-refused'; lease = $null } }
        $harnessCalls = 0; $runtimeCalls = 0
        $harness = New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)
        $runtime = New-ReviewFixtureRuntimePort
        $harness.preflight = { param($invocation) $harnessCalls++; [pscustomobject]@{ ok = $true; reason = 'must-not-reach' } }.GetNewClosure()
        $runtime.preflight = { param($invocation) $runtimeCalls++; [pscustomobject]@{ ok = $true; reason = 'must-not-reach' } }.GetNewClosure()

        $result = Invoke-OrchestratorFixture -Context $context -Target $target -Harness $harness -Runtime $runtime

        $result.invoked | Should -BeFalse
        $result.reason | Should -Be 'preflight-failed:harness,runtime,target_protection:fixture-protection-refused'
        $harnessCalls | Should -Be 0
        $runtimeCalls | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 0
    }

    It 'bounds a long target preflight exception, releases allowance, and publishes the failure' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'long-preflight')
        $longTarget = [pscustomobject]@{
            prepare = { param($runId) throw ('target materialization failed: ' + ('x' * 4000)) }
            currentness = { param($snapshot) throw 'unreachable' }
            integrity = { param($snapshot) throw 'unreachable' }
            dispose = { param($snapshot) $null }
        }
        $result = Invoke-OrchestratorFixture -Context $context -Target $longTarget -Harness (New-ReviewFixtureHarnessPort) -Runtime (New-ReviewFixtureRuntimePort)
        $result.status | Should -Be 'failed'
        $result.invoked | Should -BeFalse
        $result.result.runtime_outcome | Should -Be 'preflight-failed'
        Test-Path -LiteralPath $result.report_path -PathType Leaf | Should -BeTrue
        $result.result.failure_reason.Length | Should -Be 2000
        $result.result.failure_reason | Should -Match '\.\.\.\[truncated\]$'
        $release = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind releases)
        $release.Count | Should -Be 1
        $release[0].reason.Length | Should -Be 512
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 0
    }

    It 'classifies a losing active-claim race truthfully before spend' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'claim-contention')
        Request-ReviewAuthorityClaim -StoreRoot $context.store -CampaignId cmp-demo -RunId run-other -TargetLineage lin-code -ObservedAt '2026-07-16T00:00:00Z' | Out-Null
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort) -Runtime (New-ReviewFixtureRuntimePort)
        $result.status | Should -Be 'not-started'
        $result.invoked | Should -BeFalse
        $result.result.runtime_outcome | Should -Be 'claim-contended'
        $result.result.failure_reason | Should -Be 'claim-not-acquired:active-claim'
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind releases).Count | Should -Be 1
    }

    It 'publishes invalid output once without a hidden provider retry' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'invalid')
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness (New-ReviewFixtureHarnessPort -RawCandidate 'not-json') -Runtime (New-ReviewFixtureRuntimePort)
        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.result.runtime_outcome | Should -Be 'invalid-output'
        $result.result.can_approve_current | Should -BeFalse
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 1
        @(Get-ChildItem -LiteralPath (Join-Path $context.store 'campaigns/cmp-demo/runs') -Directory).Count | Should -Be 1
    }

    It 'rejects a prose-wrapped candidate file even when Claude stdout contains valid raw JSON' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'claude-file-prose')
        $candidate = New-OrchestratorCandidate
        $rawJson = $candidate | ConvertTo-Json -Depth 20 -Compress
        $harness = New-ClaudeFilePrimaryFixtureHarness -FileCandidate ("All checks are complete.`n`n" + $rawJson) -Stdout $rawJson
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness $harness -Runtime (New-ReviewFixtureRuntimePort)

        $result.status | Should -Be 'terminal'
        $result.result.runtime_outcome | Should -Be 'invalid-output'
        $result.result.validation | Should -Be 'invalid'
        $result.result.can_approve_current | Should -BeFalse
        $result.result.findings.Count | Should -Be 0
    }

    It 'accepts file-primary raw JSON while ignoring prose-wrapped Claude stdout for authority' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'claude-file-raw')
        $candidate = New-OrchestratorCandidate
        $stdout = "All checks are complete.`n`n" + ($candidate | ConvertTo-Json -Depth 20 -Compress)
        $harness = New-ClaudeFilePrimaryFixtureHarness -FileCandidate $candidate -Stdout $stdout
        $result = Invoke-OrchestratorFixture -Context $context -Target (New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one) -Harness $harness -Runtime (New-ReviewFixtureRuntimePort)

        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.result.runtime_outcome | Should -Be 'completed'
        $result.result.validation | Should -Be 'valid'
        $result.result.verdict | Should -Be 'pass'
        $result.result.can_approve_current | Should -BeTrue
    }

    It 'publishes bounded changed-path evidence when snapshot integrity fails' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'integrity-path-evidence')
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one `
            -IntegrityPass $false -IntegrityChangedPaths @('.claude/settings.local.json')
        $result = Invoke-OrchestratorFixture -Context $context -Target $target `
            -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort)

        $result.status | Should -Be 'terminal'
        $result.result.runtime_outcome | Should -Be 'containment-violated'
        $result.result.containment | Should -Be 'violated'
        $result.result.failure_reason | Should -Be 'target-integrity-failed:snapshot-tampered:.claude/settings.local.json'
        $result.result.can_approve_current | Should -BeFalse
    }

    It 'publishes verified timeout partials, moved results, and a visible complete rerun under new run IDs' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'rerun') -Slots 2
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $partialCandidate = New-OrchestratorCandidate -Run run-one -Completion partial -Verdict incomplete -Findings @((New-OrchestratorFinding))
        $partialEvents = [Collections.Generic.List[object]]::new(); $partialSink = { param($event) $partialEvents.Add($event) | Out-Null }.GetNewClosure()
        $partial = Invoke-OrchestratorFixture -Context $context -Run run-one -Reservation res-one -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate $partialCandidate) -Runtime (New-ReviewFixtureRuntimePort -Outcome timed-out -TerminationVerified $true -FailureReason 'timed out after verified kill') -ProgressSink $partialSink
        $partial.result.runtime_outcome | Should -Be 'timed-out'
        $partial.result.completion | Should -Be 'partial'
        $partial.result.findings.Count | Should -Be 1
        @($partialEvents | Where-Object { $null -ne $_.validated_finding_count }).Count | Should -Be 0 -Because 'a valid partial is useful evidence, but not a complete finding-count checkpoint'

        $allowance = Get-ReviewCampaignAllowanceState -CampaignId cmp-demo -Grants @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind grants) -Reservations @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind reservations) -Spends @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend) -Releases @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind releases)
        (Resolve-ReviewRerunDecision -PriorResult $partial.result -ProposedRunId run-two -ExistingRunIds @('run-one') -HasAvailableSlot ($allowance.available.Count -gt 0)).action | Should -Be 'launch-visible-rerun'

        $completeEvents = [Collections.Generic.List[object]]::new(); $completeSink = { param($event) $completeEvents.Add($event) | Out-Null }.GetNewClosure()
        $complete = Invoke-OrchestratorFixture -Context $context -Run run-two -Reservation res-two -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Run run-two)) -Runtime (New-ReviewFixtureRuntimePort) -ProgressSink $completeSink
        $complete.result.can_approve_current | Should -BeTrue
        @($completeEvents | Where-Object { [string]$_.stage -ceq 'terminal' })[0].validated_finding_count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-demo -Kind spend).Count | Should -Be 2
        (Resolve-ReviewCampaignSelectedResult -TargetDigest digest-one -OrderedRunIds @('run-one', 'run-two') -Results @($partial.result, $complete.result)).selected_run_id | Should -Be 'run-two'

        $movedContext = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'moved')
        $moved = Invoke-OrchestratorFixture -Context $movedContext -Target (New-ReviewFixtureTargetPort -SnapshotPath $movedContext.snapshot -TargetDigest digest-one -Currentness snapshot-moved) -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate -Verdict findings -Findings @((New-OrchestratorFinding)))) -Runtime (New-ReviewFixtureRuntimePort)
        $moved.result.currentness | Should -Be 'snapshot-moved'
        $moved.result.can_approve_current | Should -BeFalse
        $moved.result.findings[0].relevance | Should -Be 'snapshot-moved'
    }

    It 'leaves an invoked crash unclosed until recovery verifies terminal state' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'crash')
        $fixtureTarget = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $disposeLog = [System.Collections.Generic.List[string]]::new()
        $recordDispose = { param($snapshot) $disposeLog.Add([string]$snapshot.snapshot_path) | Out-Null }.GetNewClosure()
        $observedTarget = [pscustomobject]@{ kind = $fixtureTarget.kind; prepare = $fixtureTarget.prepare; currentness = $fixtureTarget.currentness; integrity = $fixtureTarget.integrity; dispose = $recordDispose }
        $result = Invoke-OrchestratorFixture -Context $context -Target $observedTarget -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) -Runtime (New-ReviewFixtureRuntimePort -Outcome abandoned -TerminationVerified $false -Containment unknown -FailureReason 'fixture controller crash')
        $result.status | Should -Be 'awaiting-termination-verification'
        $result.invoked | Should -BeTrue
        $disposeLog.Count | Should -Be 0 -Because 'a possibly live reviewer tree still owns the frozen target until recovery verifies termination'
        Test-Path -LiteralPath (Join-Path $context.store 'campaigns/cmp-demo/runs/run-one/result.json') | Should -BeFalse
        (Get-ReviewRunReconciliationPlan -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('publish-spent-abandoned-result', 'retire-claim-abandoned')

        $recoveryClock = New-ReviewFixtureClockPort -UtcValues @('2026-07-16T00:01:00Z') -MonotonicValues @(55100)
        $recovered = Invoke-ReviewRunReconciliation -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code `
            -TargetPort $observedTarget -RuntimePort (New-ReviewFixtureRuntimePort) -ClockPort $recoveryClock
        $recovered.status | Should -Be 'terminal'
        $recovered.result.runtime_outcome | Should -Be 'abandoned'
        $recovered.result.termination_verified | Should -BeTrue
        $recovered.result.can_approve_current | Should -BeFalse
        $disposeLog.Count | Should -Be 1
        (Get-ReviewRunReconciliationPlan -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('complete')
    }

    It 'fails restart reconciliation closed when the immutable recovery receipt is unavailable' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'crash-no-receipt')
        $fixtureTarget = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $disposeLog = [Collections.Generic.List[string]]::new()
        $target = [pscustomobject]@{
            kind = $fixtureTarget.kind; prepare = $fixtureTarget.prepare; currentness = $fixtureTarget.currentness; integrity = $fixtureTarget.integrity
            dispose = { param($snapshot) $disposeLog.Add([string]$snapshot.snapshot_path) | Out-Null }.GetNewClosure()
        }
        $run = Invoke-OrchestratorFixture -Context $context -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) `
            -Runtime (New-ReviewFixtureRuntimePort -Outcome abandoned -TerminationVerified $false -Containment unknown -FailureReason 'fixture controller crash')
        $run.status | Should -Be 'awaiting-termination-verification'
        Remove-Item -LiteralPath (Join-Path $context.store 'campaigns/cmp-demo/runs/run-one/recovery.json') -Force

        $recovered = Invoke-ReviewRunReconciliation -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code `
            -TargetPort $target -RuntimePort (New-ReviewFixtureRuntimePort) -ClockPort (New-OrchestratorClock)
        $recovered.status | Should -Be 'blocked'
        $recovered.reason | Should -Be 'reconciliation-recovery-fact-missing'
        $disposeLog.Count | Should -Be 0
        Test-Path -LiteralPath (Join-Path $context.store 'campaigns/cmp-demo/runs/run-one/result.json') | Should -BeFalse
    }

    It 'continues an interrupted validating boundary and retires its claim in one recovery call' {
        $context = Initialize-OrchestratorContext -Root (Join-Path $TestDrive 'crash-validating')
        $target = New-ReviewFixtureTargetPort -SnapshotPath $context.snapshot -TargetDigest digest-one
        $run = Invoke-OrchestratorFixture -Context $context -Target $target -Harness (New-ReviewFixtureHarnessPort -Candidate (New-OrchestratorCandidate)) `
            -Runtime (New-ReviewFixtureRuntimePort -Outcome abandoned -TerminationVerified $false -Containment unknown -FailureReason 'fixture validating crash')
        $run.status | Should -Be 'awaiting-termination-verification'
        Write-ReviewRunAuthorityFact -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -Stage validating `
            -Fact (New-ReviewRunStateFact -CampaignId cmp-demo -RunId run-one -TargetDigest digest-one -HarnessId fixture-harness -State validating) | Out-Null
        (Get-ReviewRunReconciliationPlan -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('continue-validation-and-classification')

        $recovered = Invoke-ReviewRunReconciliation -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code `
            -TargetPort $target -RuntimePort (New-ReviewFixtureRuntimePort) -ClockPort (New-OrchestratorClock)
        $recovered.status | Should -Be 'terminal'
        (Get-ReviewRunReconciliationPlan -StoreRoot $context.store -CampaignId cmp-demo -RunId run-one -TargetLineage lin-code).actions | Should -Be @('complete')
    }

    It 'reads production time live and contains no background scheduler or provider retry loop' {
        $clock = New-ReviewSystemClockPort
        $firstUtc = Read-ReviewClockUtc -ClockPort $clock; $firstMono = Read-ReviewClockMonotonic -ClockPort $clock
        $secondUtc = Read-ReviewClockUtc -ClockPort $clock; $secondMono = Read-ReviewClockMonotonic -ClockPort $clock
        [DateTimeOffset]::Parse($firstUtc) | Should -Not -BeNullOrEmpty
        [DateTimeOffset]::Parse($secondUtc) | Should -Not -BeNullOrEmpty
        $secondMono | Should -BeGreaterOrEqual $firstMono
        $source = Get-Content -LiteralPath $script:OrchestratorPath -Raw
        $executableSource = $source -replace '(?m)^\s*#.*$', ''
        $executableSource | Should -Not -Match 'Start-Job|Start-ThreadJob|Register-ObjectEvent|Start-Process|while\s*\('
    }
}
