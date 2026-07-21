$ErrorActionPreference = 'Stop'

# Trace: T059 / FR-060, FR-061, FR-062, FR-064 / SC-017, SC-018, SC-019,
# SC-020, SC-021, NFR-007. These are deterministic fake-provider processes; passing
# never promotes a harness/OS pair to live support.
BeforeDiscovery {
    # A generic unprivileged Linux lane cannot create/delegate a cgroup v2 root. The dedicated three-OS
    # review-runtime job sets SPECREW_REQUIRE_POSIX_RUNTIME_PROOF=1, provisions the bounded cgroup root, and
    # must run every native case. Only the duplicate generic honesty lane skips those native process cases.
    $script:SkipUnprivilegedGenericLinuxNativeCases = $IsLinux -and $env:SPECREW_REQUIRE_POSIX_RUNTIME_PROOF -ne '1'
}
Describe 'T059 all-adapter fake-process and native-runtime fault matrix' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        $script:OriginalPath = $env:PATH
        $script:FakeBin = Join-Path $TestDrive 'fake-provider-bin'
        [IO.Directory]::CreateDirectory($script:FakeBin) | Out-Null
        $providerSource = @'
$ErrorActionPreference = 'Stop'
$prompt = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($prompt) -and $args.Count -gt 0) { $prompt = [string]$args[-1] }
if ([string]::IsNullOrWhiteSpace($prompt)) { [Console]::Error.WriteLine('fake-provider-prompt-missing'); exit 41 }

$candidateMatch = [regex]::Match($prompt, '(?ms)Write the candidate directly to this exact path:\s*\r?\n(?<path>[^\r\n]+)')
$runMatch = [regex]::Match($prompt, '(?m)^run_id\s*=\s*"(?<value>[^"]+)"\s*$')
$digestMatch = [regex]::Match($prompt, '(?m)^target_digest\s*=\s*"(?<value>[^"]+)"\s*$')
$modeMatch = [regex]::Match($prompt, 'FAKE_PROVIDER_MODE=(?<value>[a-z-]+)')
if (-not $candidateMatch.Success -or -not $runMatch.Success -or -not $digestMatch.Success) {
    [Console]::Error.WriteLine('fake-provider-contract-parse-failed'); exit 42
}
$candidatePath = $candidateMatch.Groups['path'].Value.Trim()
$parent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($candidatePath))
$mode = if ($modeMatch.Success) { $modeMatch.Groups['value'].Value } else { 'valid' }
$countPath = Join-Path $parent 'fake-provider-invocations.txt'
$count = 0
if ([IO.File]::Exists($countPath)) { [void][int]::TryParse([IO.File]::ReadAllText($countPath), [ref]$count) }
[IO.File]::WriteAllText($countPath, [string]($count + 1), [Text.UTF8Encoding]::new($false))

$candidate = [ordered]@{
    schema_version = '1.0'
    run_id = $runMatch.Groups['value'].Value
    target_digest = $digestMatch.Groups['value'].Value
    completion = $(if ($mode -eq 'timeout') { 'partial' } else { 'complete' })
    verdict = $(if ($mode -eq 'timeout') { 'incomplete' } else { 'pass' })
    summary = "T059 fake provider $mode"
    findings = @()
}
$json = $candidate | ConvertTo-Json -Compress
if ($mode -eq 'malformed') {
    [IO.File]::WriteAllText($candidatePath, "Review complete.`n$json", [Text.UTF8Encoding]::new($false))
    exit 0
}
if ($mode -eq 'timeout') {
    $pwsh = (Get-Process -Id $PID).Path
    $child = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60') -PassThru
    [IO.File]::WriteAllText((Join-Path $parent 'fake-provider-child.pid'), [string]$child.Id, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($candidatePath, $json, [Text.UTF8Encoding]::new($false))
    Start-Sleep -Seconds 60
    exit 0
}
[IO.File]::WriteAllText($candidatePath, $json, [Text.UTF8Encoding]::new($false))
exit 0
'@

        # The fake command name is deliberately not any provider's real executable. Adapter process
        # specs are built normally, then the test-only seam substitutes only this executable path;
        # arguments, prompt transport, identity, timeout, and file contract remain adapter-owned.
        $script:FakeCommand = 'specrew-t059-fake-provider'
        if ($IsWindows) {
            $providerPath = Join-Path $script:FakeBin 'fake-review-provider.ps1'
            [IO.File]::WriteAllText($providerPath, $providerSource, [Text.UTF8Encoding]::new($false))
            $shim = Join-Path $script:FakeBin "$($script:FakeCommand).cmd"
            $text = "@echo off`r`n%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%SCRIPT_DIR%\fake-review-provider.ps1`" %*`r`n"
            [IO.File]::WriteAllText($shim, $text, [Text.UTF8Encoding]::new($false))
        }
        else {
            $path = Join-Path $script:FakeBin $script:FakeCommand
            [IO.File]::WriteAllText($path, "#!/usr/bin/env pwsh`n$providerSource", [Text.UTF8Encoding]::new($false))
            & chmod +x $path
            if ($LASTEXITCODE -ne 0) { throw "fake-provider-chmod-failed:$path" }
        }
        $env:PATH = $script:FakeBin + [IO.Path]::PathSeparator + $env:PATH

        function script:New-T059Case {
            param([string]$Root, [string]$HostName, [string]$Mode, [string]$RunId)
            $snapshot = Join-Path $Root 'snapshot'; [IO.Directory]::CreateDirectory($snapshot) | Out-Null
            [IO.File]::WriteAllText((Join-Path $snapshot 'source.txt'), 'origin-equivalent frozen source', [Text.UTF8Encoding]::new($false))
            $stagingRoot = Join-Path $Root 'staging'
            $paths = Initialize-ReviewRunStaging -StagingRoot $stagingRoot -CampaignId 'cmp-t059' -RunId $RunId
            $digest = "digest-$RunId"
            $invocation = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-t059'; run_id = $RunId; target_digest = $digest
                snapshot_path = $snapshot; review_scope = "T059 deterministic process fixture. FAKE_PROVIDER_MODE=$Mode"
                prompt_path = (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-candidate-prompt.md')
                candidate_result_path = $paths.candidate_result_path; candidate_report_path = $paths.candidate_report_path
                deadline = [DateTimeOffset]::UtcNow.AddMinutes(2).ToString('o')
            }
            return [pscustomobject]@{
                invocation = $invocation; staging_root = $stagingRoot; store_root = (Join-Path $Root 'store')
                count_path = (Join-Path $paths.staging_path 'fake-provider-invocations.txt')
                child_pid_path = (Join-Path $paths.staging_path 'fake-provider-child.pid')
                host = $HostName
            }
        }

        function script:New-T059NativeRuntime {
            param([int]$TimeoutSeconds)
            if ($IsWindows) { return New-ReviewWindowsRuntimePort -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds 0 }
            if ($IsLinux) { return New-ReviewLinuxRuntimePort -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds 0 }
            if ($IsMacOS) { return New-ReviewMacOSRuntimePort -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds 0 }
            throw 't059-unsupported-platform'
        }

        function script:New-T059FakeProcessHarness {
            param([string]$HostName, [int]$TimeoutSeconds)
            $parameters = @{ TimeoutSeconds = $TimeoutSeconds; AvailabilityProbe = { $true } }
            $harness = switch ($HostName) {
                'claude' { New-ReviewClaudeFilePrimaryHarnessPort @parameters }
                'codex' { New-ReviewCodexFilePrimaryHarnessPort @parameters }
                'copilot' { New-ReviewCopilotFilePrimaryHarnessPort @parameters }
                'cursor-agent' { New-ReviewCursorAgentFilePrimaryHarnessPort @parameters }
                'antigravity' { New-ReviewAntigravityFilePrimaryHarnessPort @parameters }
                default { throw "t059-harness-unknown:$HostName" }
            }
            $adapterBuild = $harness.build_process
            $fakeCommand = $script:FakeCommand
            $harness.build_process = {
                param($invocation, $environment)
                $spec = & $adapterBuild $invocation $environment
                $spec.command = $fakeCommand
                return $spec
            }.GetNewClosure()
            return $harness
        }

        function script:Invoke-T059NativeCase {
            # The first native Windows process on a fresh hosted runner can pay cold PowerShell,
            # code-signing, and endpoint-scanning startup cost. Keep successful fake cases bounded
            # without turning that infrastructure latency into a semantic timeout. The dedicated
            # descendant-kill case below still supplies its independent five-second bound.
            param($Case, [int]$TimeoutSeconds = 30)
            $harness = New-T059FakeProcessHarness -HostName $Case.host -TimeoutSeconds $TimeoutSeconds
            $runtime = New-T059NativeRuntime -TimeoutSeconds $TimeoutSeconds
            $harnessReady = & $harness.preflight $Case.invocation
            $runtimeReady = & $runtime.preflight $Case.invocation
            $harnessReady.ok | Should -BeTrue -Because $harnessReady.reason
            $runtimeReady.ok | Should -BeTrue -Because $runtimeReady.reason
            $started = [pscustomobject]@{ count = 0 }
            $onStarted = { $started.count++ }.GetNewClosure()
            $result = & $runtime.invoke $harness $Case.invocation $onStarted @{ SPECREW_REFOCUS_DISABLE = '1'; SPECREW_DISABLE_EVENTS = '1' }
            return [pscustomobject]@{ runtime = $result; started = $started.count; harness = $harness }
        }
    }

    AfterAll {
        $env:PATH = $script:OriginalPath
    }

    It 'runs the <harness_name> production adapter vector through one native contained fake-provider process' -Skip:$script:SkipUnprivilegedGenericLinuxNativeCases -ForEach @(
        @{ harness_name = 'claude' }, @{ harness_name = 'codex' }, @{ harness_name = 'copilot' }, @{ harness_name = 'cursor-agent' }, @{ harness_name = 'antigravity' }
    ) {
        $slug = $harness_name.Replace('-agent', '')
        $case = New-T059Case -Root (Join-Path $TestDrive "valid-$slug") -HostName $harness_name -Mode valid -RunId "run-valid-$slug"
        $run = Invoke-T059NativeCase -Case $case
        $run.started | Should -Be 1
        $run.runtime.runtime_outcome | Should -Be 'completed' -Because $run.runtime.failure_reason
        $run.runtime.termination_verified | Should -BeTrue
        $run.runtime.containment | Should -Be 'verified'
        [IO.File]::ReadAllText($case.count_path) | Should -Be '1'
        $candidate = Read-ReviewCandidateResult -Path $case.invocation.candidate_result_path -ExpectedRunId $case.invocation.run_id -ExpectedTargetDigest $case.invocation.target_digest
        $candidate.valid | Should -BeTrue -Because ($candidate.errors -join ',')
        $candidate.candidate.verdict | Should -Be 'pass'
    }

    It 'rejects prose-wrapped output from the <harness_name> fake process through strict ingress with no hidden retry' -Skip:$script:SkipUnprivilegedGenericLinuxNativeCases -ForEach @(
        @{ harness_name = 'claude' }, @{ harness_name = 'codex' }, @{ harness_name = 'copilot' }, @{ harness_name = 'cursor-agent' }, @{ harness_name = 'antigravity' }
    ) {
        $slug = $harness_name.Replace('-agent', '')
        $case = New-T059Case -Root (Join-Path $TestDrive "malformed-$slug") -HostName $harness_name -Mode malformed -RunId "run-bad-$slug"
        $run = Invoke-T059NativeCase -Case $case
        $run.runtime.runtime_outcome | Should -Be 'completed' -Because $run.runtime.failure_reason
        $run.runtime.termination_verified | Should -BeTrue
        [IO.File]::ReadAllText($case.count_path) | Should -Be '1'
        $ingress = Invoke-ReviewResultIngress -StoreRoot $case.store_root -StagingRoot $case.staging_root -CampaignId cmp-t059 `
            -RunId $case.invocation.run_id -TargetDigest $case.invocation.target_digest -HarnessId $run.harness.id `
            -RuntimeOutcome completed -Invoked $true -TerminationVerified $true -Containment verified -Currentness current `
            -StartedAt '2026-07-16T00:00:00Z' -EndedAt '2026-07-16T00:00:01Z' -DurationMs 1000
        $ingress.published | Should -BeTrue
        $ingress.result.runtime_outcome | Should -Be 'invalid-output'
        $ingress.result.validation | Should -Be 'invalid'
        $ingress.result.can_approve_current | Should -BeFalse
        [IO.File]::ReadAllText($case.count_path) | Should -Be '1' -Because 'strict ingress never invokes or retries a provider'
    }

    It 'kills a timed-out fake provider and descendant before publishing partial timeout evidence' -Skip:$script:SkipUnprivilegedGenericLinuxNativeCases {
        $case = New-T059Case -Root (Join-Path $TestDrive 'timeout-tree') -HostName claude -Mode timeout -RunId 'run-timeout-tree'
        # Five seconds is still bounded while leaving enough cold-start margin on hosted/virtualized
        # POSIX runners for the fake provider to create its descendant before timeout containment fires.
        $run = Invoke-T059NativeCase -Case $case -TimeoutSeconds 5
        $run.runtime.runtime_outcome | Should -Be 'timed-out'
        $run.runtime.termination_verified | Should -BeTrue -Because $run.runtime.failure_reason
        $run.runtime.containment | Should -Be 'verified'
        [IO.File]::ReadAllText($case.count_path) | Should -Be '1'
        $childPid = [int][IO.File]::ReadAllText($case.child_pid_path)
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty -Because 'terminal timeout evidence follows verified descendant death'
        $ingress = Invoke-ReviewResultIngress -StoreRoot $case.store_root -StagingRoot $case.staging_root -CampaignId cmp-t059 `
            -RunId $case.invocation.run_id -TargetDigest $case.invocation.target_digest -HarnessId $run.harness.id `
            -RuntimeOutcome timed-out -Invoked $true -TerminationVerified $true -Containment verified -Currentness current `
            -StartedAt '2026-07-16T00:00:00Z' -EndedAt '2026-07-16T00:00:02Z' -DurationMs 2000 -FailureReason $run.runtime.failure_reason
        $ingress.result.completion | Should -Be 'partial'
        $ingress.result.runtime_outcome | Should -Be 'timed-out'
        $ingress.result.can_approve_current | Should -BeFalse
        @($ingress.result.findings).Count | Should -Be 0
    }

    It 'labels this matrix as deterministic simulation rather than live support evidence' {
        $source = Get-Content -LiteralPath $PSCommandPath -Raw
        $source | Should -Match 'deterministic fake-provider processes'
        $source | Should -Match 'never promotes a harness/OS pair to live support'
        $source | Should -Not -Match 'support_tier\s*=\s*[''"]verified'
    }

    It 'keeps the deterministic fault suite wired on Windows, Linux, and macOS CI without claiming live support' {
        $workflowPath = Join-Path $script:RepoRoot '.github/workflows/cross-platform-validation.yml'
        $workflow = Get-Content -LiteralPath $workflowPath -Raw
        foreach ($runner in @('windows-latest', 'ubuntu-latest', 'macos-latest')) {
            $workflow | Should -Match ([regex]::Escape($runner))
        }
        foreach ($suite in @(
            'review-cross-platform-fault-matrix.Tests.ps1',
            'review-harness-contract.Tests.ps1',
            'review-authority-store.Tests.ps1',
            'review-spend-allowance.Tests.ps1',
            'review-campaign-orchestrator.Tests.ps1',
            'review-result-ingestor.Tests.ps1',
            'review-target-port.Tests.ps1',
            'worktree-containment.Tests.ps1',
            'review-windows-runtime.Tests.ps1',
            'review-posix-runtime.Tests.ps1'
        )) {
            $workflow | Should -Match ([regex]::Escape($suite))
        }
        $workflow | Should -Match 'Deterministic fake-provider review runtime'
        $workflow | Should -Match 'never live support evidence'
        $workflow | Should -Match 'Scope AllUsers'
        $workflow | Should -Match 'sudo --preserve-env=SPECREW_REVIEW_CGROUP_ROOT,SPECREW_REQUIRE_POSIX_RUNTIME_PROOF'
        $workflow | Should -Match 'sudo git config --global --add safe\.directory'
    }
}
