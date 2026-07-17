$ErrorActionPreference = 'Stop'

Describe 'Linux cgroup and macOS process-group production runtimes (T057)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-runtime-contract.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-windows-runtime-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-posix-runtime-common.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-linux-runtime-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-macos-runtime-port.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-runtime-factory.ps1')
        $script:PwshPath = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source

        function script:New-T057Invocation {
            param([Parameter(Mandatory)][string]$Root)
            $snapshot = Join-Path $Root 'snapshot'; $stage = Join-Path $Root 'stage'
            New-Item -ItemType Directory -Path $snapshot, $stage -Force | Out-Null
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-posix'; run_id = 'run-posix'; target_digest = 'digest-posix'
                snapshot_path = $snapshot; review_scope = 'fixture'; prompt_path = (Join-Path $Root 'prompt.md')
                candidate_result_path = (Join-Path $stage 'candidate.json'); candidate_report_path = (Join-Path $stage 'candidate.md')
                deadline = '2026-07-17T00:00:00Z'
            }
        }

        function script:New-T057FixtureScripts {
            param([Parameter(Mandatory)][string]$Root)
            $sleeper = Join-Path $Root 'sleeper.ps1'; $runner = Join-Path $Root 'runner.ps1'
            [IO.File]::WriteAllText($sleeper, @'
param([string]$AlivePath)
[IO.File]::WriteAllText($AlivePath, [string]$PID)
while ($true) { [Console]::Out.WriteLine(('posix-child-' + ('x' * 256))); Start-Sleep -Milliseconds 50 }
'@, [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText($runner, @'
param([string]$CandidatePath, [string]$ChildPidPath, [string]$ChildAlivePath, [string]$SleeperPath, [string]$Mode)
$pwsh = (Get-Process -Id $PID).Path
$child = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-File', $SleeperPath, $ChildAlivePath) -PassThru -NoNewWindow
[IO.File]::WriteAllText($ChildPidPath, [string]$child.Id)
$candidate = [ordered]@{
    schema_version = '1.0'; run_id = 'run-posix'; target_digest = 'digest-posix'
    completion = $(if ($Mode -eq 'timeout') { 'partial' } else { 'complete' })
    verdict = $(if ($Mode -eq 'timeout') { 'incomplete' } else { 'pass' })
    summary = 'posix runtime fixture'; findings = @()
}
[IO.File]::WriteAllText($CandidatePath, ($candidate | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
if ($Mode -eq 'timeout') { Start-Sleep -Seconds 30 }
'@, [Text.UTF8Encoding]::new($false))
            return [pscustomobject]@{ runner = $runner; sleeper = $sleeper }
        }

        function script:New-T057Harness {
            param([Parameter(Mandatory)]$Invocation, [Parameter(Mandatory)]$Scripts, [Parameter(Mandatory)][string]$Mode, [int]$TimeoutSeconds)
            $childPid = Join-Path ([IO.Path]::GetDirectoryName($Invocation.candidate_result_path)) 'child.pid'
            $childAlive = Join-Path ([IO.Path]::GetDirectoryName($Invocation.candidate_result_path)) 'child-alive.pid'
            $spec = [pscustomobject][ordered]@{
                schema_version = '1.0'; harness_id = 'fixture-posix'; command = $script:PwshPath
                argument_list = @('-NoProfile', '-File', $Scripts.runner, $Invocation.candidate_result_path, $childPid, $childAlive, $Scripts.sleeper, $Mode)
                prompt_transport = 'argument'; stdin_text = $null; working_directory = $Invocation.snapshot_path
                environment_delta = [ordered]@{ SPECREW_REFOCUS_DISABLE = '1' }
                candidate_result_path = $Invocation.candidate_result_path; deadline = $Invocation.deadline
                timeout_seconds = $TimeoutSeconds; result_transport = 'file-primary'; stdout_authority = $false
            }
            $build = { param($invocationArg, $environment) return $spec }.GetNewClosure()
            return [pscustomobject]@{ id = 'fixture-posix'; build_process = $build; child_pid_path = $childPid; child_alive_path = $childAlive }
        }

        function script:Get-T057RuntimeCapability {
            if ($IsLinux) { return Test-ReviewLinuxCgroupAvailability }
            if ($IsMacOS) { return Test-ReviewMacProcessGroupAvailability }
            return [pscustomobject]@{ ok = $false; reason = 'posix-runtime-wrong-platform' }
        }

        function script:Get-T057RuntimePort {
            param([int]$TimeoutSeconds)
            if ($IsLinux) { return New-ReviewLinuxRuntimePort -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds 0 }
            return New-ReviewMacOSRuntimePort -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds 0
        }

        function script:Assert-T057CapabilityOrSkip {
            $capability = Get-T057RuntimeCapability
            if (-not $capability.ok) {
                if ($env:SPECREW_REQUIRE_POSIX_RUNTIME_PROOF -eq '1') { $capability.ok | Should -BeTrue -Because $capability.reason }
                Set-ItResult -Skipped -Because $capability.reason
                return $false
            }
            return $true
        }
    }

    It 'shares the closed process contract and rejects scalar argument transport before launch' {
        $invocation = New-T057Invocation -Root (Join-Path $TestDrive 'contract')
        $spec = [pscustomobject][ordered]@{
            schema_version = '1.0'; harness_id = 'bad'; command = 'pwsh'; argument_list = 'one scalar'
            prompt_transport = 'argument'; working_directory = $invocation.snapshot_path; environment_delta = [ordered]@{}
            candidate_result_path = $invocation.candidate_result_path; timeout_seconds = 5; result_transport = 'file-primary'; stdout_authority = $false
        }
        $result = Test-ReviewRuntimeProcessSpec -Spec $spec -Invocation $invocation
        $result.valid | Should -BeFalse
        $result.errors | Should -Contain 'arguments-invalid'
    }

    It 'reports unavailable POSIX capability before a reviewer can start or spend' {
        $invocation = New-T057Invocation -Root (Join-Path $TestDrive 'unavailable')
        $linux = New-ReviewLinuxRuntimePort -CapabilityProbe { [pscustomobject]@{ ok = $false; reason = 'fixture-linux-unavailable' } }
        $mac = New-ReviewMacOSRuntimePort -CapabilityProbe { [pscustomobject]@{ ok = $false; reason = 'fixture-macos-unavailable' } }
        (& $linux.preflight $invocation).reason | Should -Be 'fixture-linux-unavailable'
        (& $mac.preflight $invocation).reason | Should -Be 'fixture-macos-unavailable'
    }

    It 'selects exactly one production runtime for the current operating system' {
        $runtime = New-ReviewProductionRuntimePort -TimeoutSeconds 5
        if ($IsWindows) { $runtime.id | Should -Be 'windows-job-object-runtime' }
        elseif ($IsLinux) { $runtime.id | Should -Be 'linux-cgroup-v2-runtime' }
        elseif ($IsMacOS) { $runtime.id | Should -Be 'macos-process-group-runtime' }
        else { $runtime.id | Should -Be 'unavailable-runtime' }
    }

    It 'treats an already-empty persisted native containment identity as recovered' -Skip:$IsWindows {
        if ($IsLinux) {
            $root = Resolve-ReviewLinuxCgroupRoot
            $receipt = [pscustomobject]@{
                runtime_id = 'linux-cgroup-v2-runtime'; platform = 'linux'; containment_kind = 'cgroup-v2'
                containment_id = (Join-Path $root ('specrew-review-' + ('a' * 32))); process_id = 2147483000
                process_started_at = '2026-07-17T00:00:00Z'
            }
            $port = New-ReviewLinuxRuntimePort -CgroupRoot $root
        }
        else {
            $receipt = [pscustomobject]@{
                runtime_id = 'macos-process-group-runtime'; platform = 'macos'; containment_kind = 'process-group'
                containment_id = '2147483000'; process_id = 2147483000; process_started_at = '2026-07-17T00:00:00Z'
            }
            $port = New-ReviewMacOSRuntimePort
        }
        $recovered = & $port.recover $receipt
        $recovered.termination_verified | Should -BeTrue -Because $recovered.failure_reason
        $recovered.containment | Should -Be 'verified'
    }

    It 'exercises the native process-group mechanism on Unix without promoting cross-OS support' -Skip:$IsWindows {
        $root = Join-Path $TestDrive 'portable-pgid'; $invocation = New-T057Invocation -Root $root
        $scripts = New-T057FixtureScripts -Root $root; $harness = New-T057Harness -Invocation $invocation -Scripts $scripts -Mode timeout -TimeoutSeconds 1
        $port = New-ReviewMacOSRuntimePort -TimeoutSeconds 1 -TerminationGraceSeconds 0 -CapabilityProbe { [pscustomobject]@{ ok = $true; reason = 'fixture-posix-pgid-ready' } }
        $heartbeats = [Collections.Generic.List[object]]::new(); $progress = { param($sample) $heartbeats.Add($sample) | Out-Null }.GetNewClosure()
        $runtime = & $port.invoke $harness $invocation {} @{} $progress
        $runtime.runtime_outcome | Should -Be 'timed-out' -Because $runtime.failure_reason
        $runtime.termination_verified | Should -BeTrue -Because $runtime.failure_reason
        $runtime.cleanup_verified | Should -BeTrue
        $heartbeats.Count | Should -BeGreaterThan 0
        @($heartbeats | Where-Object { -not [bool]$_.process_tree_live }).Count | Should -Be 0
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
    }

    It 'reaps a clean-exit descendant through the real current-OS POSIX containment' -Skip:$IsWindows {
        if (-not (Assert-T057CapabilityOrSkip)) { return }
        $root = Join-Path $TestDrive 'clean'; $invocation = New-T057Invocation -Root $root
        $scripts = New-T057FixtureScripts -Root $root; $harness = New-T057Harness -Invocation $invocation -Scripts $scripts -Mode complete -TimeoutSeconds 5
        $started = [Collections.Generic.List[string]]::new(); $onStarted = { $started.Add('started') | Out-Null }.GetNewClosure()
        $port = Get-T057RuntimePort -TimeoutSeconds 5
        $preflight = & $port.preflight $invocation
        $preflight.ok | Should -BeTrue -Because $preflight.reason
        $result = & $port.invoke $harness $invocation $onStarted @{}
        $result.runtime_outcome | Should -Be 'completed' -Because $result.failure_reason
        $result.termination_verified | Should -BeTrue -Because $result.failure_reason
        $result.streams_closed | Should -BeTrue
        $result.cleanup_verified | Should -BeTrue
        $started.Count | Should -Be 1
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        (Read-ReviewCandidateResult -Path $invocation.candidate_result_path -ExpectedRunId run-posix -ExpectedTargetDigest digest-posix).valid | Should -BeTrue
    }

    It 'kills the real current-OS POSIX tree before returning timeout authority' -Skip:$IsWindows {
        if (-not (Assert-T057CapabilityOrSkip)) { return }
        $root = Join-Path $TestDrive 'timeout'; $invocation = New-T057Invocation -Root $root
        $scripts = New-T057FixtureScripts -Root $root; $harness = New-T057Harness -Invocation $invocation -Scripts $scripts -Mode timeout -TimeoutSeconds 3
        $port = Get-T057RuntimePort -TimeoutSeconds 3
        $runtime = & $port.invoke $harness $invocation {} @{}
        $runtime.runtime_outcome | Should -Be 'timed-out' -Because $runtime.failure_reason
        $runtime.termination_verified | Should -BeTrue -Because $runtime.failure_reason
        $runtime.failure_reason | Should -Match 'process tree verified dead, streams closed, containment cleaned'
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty

        $store = Join-Path $root 'store'; $staging = Join-Path $root 'staging'
        $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId cmp-posix -RunId run-posix
        [IO.File]::Copy($invocation.candidate_result_path, $paths.candidate_result_path)
        $published = Invoke-ReviewResultIngress -StoreRoot $store -StagingRoot $staging -CampaignId cmp-posix -RunId run-posix -TargetDigest digest-posix -HarnessId fixture-posix `
            -RuntimeOutcome $runtime.runtime_outcome -Invoked $true -TerminationVerified $runtime.termination_verified -Containment $runtime.containment -Currentness current `
            -StartedAt '2026-07-16T21:00:00Z' -EndedAt '2026-07-16T21:00:03Z' -DurationMs 3000 -FailureReason $runtime.failure_reason
        $published.result.runtime_outcome | Should -Be 'timed-out'
        $published.result.termination_verified | Should -BeTrue
    }
}
