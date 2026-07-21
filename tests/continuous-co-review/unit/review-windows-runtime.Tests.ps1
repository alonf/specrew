$ErrorActionPreference = 'Stop'

Describe 'Windows Job Object production review runtime (T056)' -Skip:(-not $IsWindows) {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-store.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-windows-runtime-port.ps1')
        $script:PwshPath = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source

        function script:New-T056Invocation {
            param([Parameter(Mandatory)][string]$Root)
            $snapshot = Join-Path $Root 'snapshot'; $stage = Join-Path $Root 'stage'
            New-Item -ItemType Directory -Path $snapshot, $stage -Force | Out-Null
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-demo'; run_id = 'run-one'; target_digest = 'digest-one'
                snapshot_path = $snapshot; review_scope = 'fixture'; prompt_path = (Join-Path $Root 'prompt.md')
                candidate_result_path = (Join-Path $stage 'candidate.json'); candidate_report_path = (Join-Path $stage 'candidate.md')
                deadline = '2026-07-17T00:00:00Z'
            }
        }

        function script:New-T056FixtureScripts {
            param([Parameter(Mandatory)][string]$Root)
            $sleeper = Join-Path $Root 'sleeper.ps1'
            $runner = Join-Path $Root 'runner.ps1'
            [IO.File]::WriteAllText($sleeper, @'
param([string]$AlivePath)
[IO.File]::WriteAllText($AlivePath, [string]$PID)
while ($true) { [Console]::Out.WriteLine(('child-output-' + ('x' * 256))); Start-Sleep -Milliseconds 50 }
'@, [Text.UTF8Encoding]::new($false))
            [IO.File]::WriteAllText($runner, @'
param([string]$CandidatePath, [string]$ChildPidPath, [string]$ChildAlivePath, [string]$SleeperPath, [string]$Mode)
$pwsh = (Get-Process -Id $PID).Path
$child = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-File', $SleeperPath, $ChildAlivePath) -PassThru -NoNewWindow
[IO.File]::WriteAllText($ChildPidPath, [string]$child.Id)
$candidate = [ordered]@{
    schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest-one'
    completion = $(if ($Mode -eq 'timeout') { 'partial' } else { 'complete' })
    verdict = $(if ($Mode -eq 'timeout') { 'incomplete' } else { 'pass' })
    summary = 'windows runtime fixture'; findings = @()
}
[IO.File]::WriteAllText($CandidatePath, ($candidate | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
if ($Mode -eq 'timeout') { Start-Sleep -Seconds 30 }
'@, [Text.UTF8Encoding]::new($false))
            return [pscustomobject]@{ runner = $runner; sleeper = $sleeper }
        }

        function script:New-T056ProcessHarness {
            param([Parameter(Mandatory)]$Invocation, [Parameter(Mandatory)]$Scripts, [Parameter(Mandatory)][string]$Mode, [int]$TimeoutSeconds)
            $childPid = Join-Path ([IO.Path]::GetDirectoryName($Invocation.candidate_result_path)) 'child.pid'
            $childAlive = Join-Path ([IO.Path]::GetDirectoryName($Invocation.candidate_result_path)) 'child-alive.pid'
            $spec = [pscustomobject][ordered]@{
                schema_version = '1.0'; harness_id = 'fixture-process'; command = $script:PwshPath
                argument_list = @('-NoProfile', '-File', $Scripts.runner, $Invocation.candidate_result_path, $childPid, $childAlive, $Scripts.sleeper, $Mode)
                prompt_transport = 'argument'; stdin_text = $null; working_directory = $Invocation.snapshot_path
                environment_delta = [ordered]@{ SPECREW_REFOCUS_DISABLE = '1' }
                candidate_result_path = $Invocation.candidate_result_path; deadline = $Invocation.deadline
                timeout_seconds = $TimeoutSeconds; result_transport = 'file-primary'; stdout_authority = $false
            }
            $build = { param($invocationArg, $environment) return $spec }.GetNewClosure()
            return [pscustomobject]@{ id = 'fixture-process'; build_process = $build; child_pid_path = $childPid; child_alive_path = $childAlive }
        }
    }

    It 'preflights the real Job Object capability without starting or spending a reviewer process' {
        $invocation = New-T056Invocation -Root (Join-Path $TestDrive 'preflight')
        $port = New-ReviewWindowsRuntimePort -TimeoutSeconds 5 -TerminationGraceSeconds 0
        $capability = Test-ReviewWindowsJobObjectAvailability
        $capability.ok | Should -BeTrue -Because $capability.reason
        (& $port.preflight $invocation).ok | Should -BeTrue

        $blocked = New-ReviewWindowsRuntimePort -CapabilityProbe { [pscustomobject]@{ ok = $false; reason = 'fixture-unavailable' } }
        (& $blocked.preflight $invocation).reason | Should -Be 'fixture-unavailable'
        { New-ReviewWindowsRuntimePort -TerminationGraceSeconds 11 } | Should -Throw
    }

    It 'resolves native executables first and unwraps only the bounded PowerShell shim shape' {
        (Resolve-ReviewWindowsProcessLaunch -CommandName $script:PwshPath).resolution | Should -Be 'native'
        $shimRoot = Join-Path $TestDrive 'bounded-shim'; New-Item -ItemType Directory -Path $shimRoot -Force | Out-Null
        $shimPath = Join-Path $shimRoot 't056-reviewer.cmd'; $scriptPath = Join-Path $shimRoot 't056-reviewer.ps1'
        [IO.File]::WriteAllText($shimPath, '@echo off' + [Environment]::NewLine + '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\t056-reviewer.ps1" %*', [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText($scriptPath, '# fixture', [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText((Join-Path $shimRoot 't056-unsafe.cmd'), '@echo off' + [Environment]::NewLine + 'cmd.exe /c echo unsafe', [Text.UTF8Encoding]::new($false))
        $priorPath = $env:PATH
        try {
            $env:PATH = $shimRoot + [IO.Path]::PathSeparator + $priorPath
            $shim = Resolve-ReviewWindowsProcessLaunch -CommandName t056-reviewer
            $shim.resolution | Should -Be 'bounded-powershell-shim'
            $shim.file | Should -Match 'WindowsPowerShell.*powershell\.exe$'
            @($shim.pre_arguments) | Should -Contain '-File'
            [string]$shim.pre_arguments[-1] | Should -Be $scriptPath
            { Resolve-ReviewWindowsProcessLaunch -CommandName t056-unsafe } | Should -Throw '*runtime-command-shim-unsupported*'
        }
        finally { $env:PATH = $priorPath }
    }

    It 'rejects a malformed process spec before onStarted and before any provider spend' {
        $invocation = New-T056Invocation -Root (Join-Path $TestDrive 'invalid-spec')
        $harness = [pscustomobject]@{ id = 'invalid'; build_process = { param($i, $e) [pscustomobject]@{ schema_version = '1.0' } } }
        $started = [Collections.Generic.List[string]]::new(); $onStarted = { $started.Add('started') | Out-Null }.GetNewClosure()
        $result = & (New-ReviewWindowsRuntimePort -TimeoutSeconds 5 -TerminationGraceSeconds 0).invoke $harness $invocation $onStarted @{}
        $result.runtime_outcome | Should -Be 'launch-failed'
        $result.failure_reason | Should -Match 'runtime-process-spec-invalid'
        $started.Count | Should -Be 0
    }

    It 'fails closed before onStarted when Job Object assignment degrades after process creation' {
        $root = Join-Path $TestDrive 'assignment-degraded'; $invocation = New-T056Invocation -Root $root
        $spec = [pscustomobject][ordered]@{
            schema_version = '1.0'; harness_id = 'fixture-process'; command = $script:PwshPath
            argument_list = @('-NoProfile', '-Command', 'Start-Sleep -Seconds 30')
            prompt_transport = 'argument'; stdin_text = $null; working_directory = $invocation.snapshot_path
            environment_delta = [ordered]@{}; candidate_result_path = $invocation.candidate_result_path
            deadline = $invocation.deadline; timeout_seconds = 5; result_transport = 'file-primary'; stdout_authority = $false
        }
        $harness = [pscustomobject]@{ id = 'fixture-process'; build_process = { param($i, $e) $spec }.GetNewClosure() }
        $degradedContainment = {
            param($ChildPid)
            [pscustomobject]@{ mode = 'tree-kill'; child_pid = $ChildPid; child_pgid = $null; job_handle = $null; degraded_reason = 'fixture-assignment-failed' }
        }.GetNewClosure()
        $started = [Collections.Generic.List[string]]::new(); $onStarted = { $started.Add('started') | Out-Null }.GetNewClosure()

        $result = & (New-ReviewWindowsRuntimePort -TimeoutSeconds 5 -TerminationGraceSeconds 0 -ContainmentFactory $degradedContainment).invoke $harness $invocation $onStarted @{}

        $result.runtime_outcome | Should -Be 'containment-violated'
        $result.containment | Should -Be 'violated'
        $result.failure_reason | Should -Be 'windows-job-object-assignment-failed:fixture-assignment-failed'
        $started.Count | Should -Be 0 -Because 'spend authority starts only after required containment is verified'
    }

    It 'reaps a background descendant and closes inherited streams after a clean root exit' {
        $root = Join-Path $TestDrive 'clean'; $invocation = New-T056Invocation -Root $root
        $scripts = New-T056FixtureScripts -Root $root
        $harness = New-T056ProcessHarness -Invocation $invocation -Scripts $scripts -Mode complete -TimeoutSeconds 5
        $started = [Collections.Generic.List[string]]::new(); $onStarted = { $started.Add('started') | Out-Null }.GetNewClosure()
        $result = & (New-ReviewWindowsRuntimePort -TimeoutSeconds 5 -TerminationGraceSeconds 0).invoke $harness $invocation $onStarted @{}
        $result.runtime_outcome | Should -Be 'completed' -Because $result.failure_reason
        $result.termination_verified | Should -BeTrue
        $result.containment | Should -Be 'verified'
        $result.streams_closed | Should -BeTrue
        $result.process_tree_live | Should -BeFalse
        $started.Count | Should -Be 1
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        (Read-ReviewCandidateResult -Path $invocation.candidate_result_path -ExpectedRunId run-one -ExpectedTargetDigest digest-one).valid | Should -BeTrue
    }

    It 'kills the root and descendant, closes streams, then returns the timeout reason' {
        $root = Join-Path $TestDrive 'timeout'; $invocation = New-T056Invocation -Root $root
        $scripts = New-T056FixtureScripts -Root $root
        $harness = New-T056ProcessHarness -Invocation $invocation -Scripts $scripts -Mode timeout -TimeoutSeconds 1
        $started = [Collections.Generic.List[string]]::new(); $onStarted = { $started.Add('started') | Out-Null }.GetNewClosure()
        $heartbeats = [Collections.Generic.List[object]]::new(); $progress = { param($sample) $heartbeats.Add($sample) | Out-Null; 'runtime-progress-sentinel' }.GetNewClosure()
        $runtimeOutput = @(& (New-ReviewWindowsRuntimePort -TimeoutSeconds 1 -TerminationGraceSeconds 0).invoke $harness $invocation $onStarted @{} $progress)
        $runtimeOutput.Count | Should -Be 1 -Because 'an output-producing runtime progress sink cannot change the scalar runtime result'
        $result = $runtimeOutput[0]
        $result.runtime_outcome | Should -Be 'timed-out'
        $result.termination_verified | Should -BeTrue -Because $result.failure_reason
        $result.failure_reason | Should -Match 'process tree verified dead and streams closed'
        $result.streams_closed | Should -BeTrue
        $result.process_tree_live | Should -BeFalse
        $started.Count | Should -Be 1
        $heartbeats.Count | Should -BeGreaterThan 0
        @($heartbeats | Where-Object { -not [bool]$_.process_tree_live }).Count | Should -Be 0 -Because 'runtime heartbeats only describe the live wait; terminal death is controller evidence'
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
    }

    It 'recovers an interrupted receipt by killing the recorded process identity' {
        $process = Start-Process -FilePath $script:PwshPath -ArgumentList @('-NoProfile', '-Command', 'Start-Sleep -Seconds 30') -PassThru -WindowStyle Hidden
        try {
            $receipt = [pscustomobject]@{
                runtime_id = 'windows-job-object-runtime'; platform = 'windows'; containment_kind = 'job-object'
                containment_id = ('job-object-process-' + $process.Id); process_id = $process.Id
                process_started_at = $process.StartTime.ToUniversalTime().ToString('o')
            }
            $replayedReceipt = ($receipt | ConvertTo-Json -Compress) | ConvertFrom-Json
            $recovered = & (New-ReviewWindowsRuntimePort -TimeoutSeconds 5 -TerminationGraceSeconds 0).recover $replayedReceipt
            $recovered.termination_verified | Should -BeTrue -Because $recovered.failure_reason
            $recovered.containment | Should -Be 'verified'
            (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        }
        finally {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
            $process.Dispose()
        }
    }

    It 'publishes timeout authority only after the runtime has verified the process tree dead' {
        $root = Join-Path $TestDrive 'ingress-order'; $invocation = New-T056Invocation -Root $root
        $scripts = New-T056FixtureScripts -Root $root
        $harness = New-T056ProcessHarness -Invocation $invocation -Scripts $scripts -Mode timeout -TimeoutSeconds 1
        $runtime = & (New-ReviewWindowsRuntimePort -TimeoutSeconds 1 -TerminationGraceSeconds 0).invoke $harness $invocation {} @{}
        $runtime.termination_verified | Should -BeTrue
        $childPid = [int]([IO.File]::ReadAllText($harness.child_pid_path))
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty

        $store = Join-Path $root 'store'; $staging = Join-Path $root 'staging'
        $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId cmp-demo -RunId run-one
        [IO.File]::Copy($invocation.candidate_result_path, $paths.candidate_result_path)
        $published = Invoke-ReviewResultIngress -StoreRoot $store -StagingRoot $staging -CampaignId cmp-demo -RunId run-one -TargetDigest digest-one -HarnessId fixture-process `
            -RuntimeOutcome $runtime.runtime_outcome -Invoked $true -TerminationVerified $runtime.termination_verified -Containment $runtime.containment -Currentness current `
            -StartedAt '2026-07-16T21:00:00Z' -EndedAt '2026-07-16T21:00:01Z' -DurationMs 1000 -FailureReason $runtime.failure_reason
        $published.result.runtime_outcome | Should -Be 'timed-out'
        $published.result.termination_verified | Should -BeTrue
        $published.result.failure_reason | Should -Match 'verified dead and streams closed'
        Test-Path -LiteralPath $published.result_path | Should -BeTrue
    }
}
