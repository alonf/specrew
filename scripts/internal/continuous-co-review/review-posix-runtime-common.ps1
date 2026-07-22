$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Starting the isolated PowerShell containment host can exceed five seconds on a loaded hosted runner
# or a low-resource local machine. Keep the handshake separately and explicitly bounded; reviewer
# execution time remains governed by the invocation timeout after the handshake succeeds.
$script:ReviewPosixContainmentHandshakeTimeoutMilliseconds = 15000

if (-not (Get-Command -Name 'Test-ReviewRuntimeProcessSpec' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-runtime-contract.ps1')
}
if (-not (Get-Command -Name 'Get-SpecrewProcessTreeDescendants' -ErrorAction SilentlyContinue)) {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1')
}

function Resolve-ReviewPosixExecutable {
    param([Parameter(Mandatory)][string]$CommandName)
    $command = Get-Command -Name $CommandName -CommandType Application -All -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) { throw "runtime-command-unavailable:$CommandName" }
    $path = [IO.Path]::GetFullPath([string]$command.Source)
    if (-not [IO.File]::Exists($path)) { throw "runtime-command-path-missing:$CommandName" }
    return $path
}

function Wait-ReviewPosixReadyFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][ValidateSet('linux-cgroup', 'process-group')][string]$ExpectedMode,
        [ValidateRange(100, 30000)][int]$TimeoutMilliseconds = $script:ReviewPosixContainmentHandshakeTimeoutMilliseconds
    )
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        if ([IO.File]::Exists($Path)) {
            try {
                $text = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false, $true))
                $ready = $text | ConvertFrom-Json -Depth 8
                if ([string]$ready.schema_version -cne '1.0' -or [string]$ready.mode -cne $ExpectedMode -or [int]$ready.pid -lt 1) { return $null }
                return $ready
            }
            catch { return $null }
        }
        [Threading.Thread]::Sleep(20)
    }
    return $null
}

function Test-ReviewPosixProcessDead {
    param([Parameter(Mandatory)][int]$ProcessId)
    try { return $null -eq (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) }
    catch { return $true }
}

function New-ReviewPosixRuntimePort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RuntimeId,
        [Parameter(Mandatory)][ValidateSet('linux', 'macos')][string]$Platform,
        [Parameter(Mandatory)][ValidateSet('cgroup-v2', 'process-group')][string]$Containment,
        [Parameter(Mandatory)][ValidateSet('linux-cgroup', 'process-group')][string]$HostMode,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [ValidateRange(0, 10)][int]$TerminationGraceSeconds = 5,
        [Parameter(Mandatory)][scriptblock]$CapabilityProbe,
        [Parameter(Mandatory)][scriptblock]$SetupContainment,
        [Parameter(Mandatory)][scriptblock]$VerifyContainment,
        [Parameter(Mandatory)][scriptblock]$StopContainment,
        [Parameter(Mandatory)][scriptblock]$WaitContainmentEmpty,
        [Parameter(Mandatory)][scriptblock]$CleanupContainment,
        [Parameter(Mandatory)][scriptblock]$RecoverContainment
    )
    $validateSpecCommand = ${function:Test-ReviewRuntimeProcessSpec}
    $resolveExecutableCommand = ${function:Resolve-ReviewPosixExecutable}
    $waitReadyCommand = ${function:Wait-ReviewPosixReadyFile}
    $testDeadCommand = ${function:Test-ReviewPosixProcessDead}
    $writeProgressCommand = ${function:Write-ReviewRuntimeProgressSample}
    $testOutputActivityCommand = ${function:Test-ReviewRuntimeOutputActivity}
    $handshakeTimeoutMilliseconds = $script:ReviewPosixContainmentHandshakeTimeoutMilliseconds
    $hostPath = Join-Path $PSScriptRoot 'review-posix-process-host.ps1'
    $pwshPath = [IO.Path]::GetFullPath((Get-Process -Id $PID).Path)

    $preflight = {
        param($invocation)
        try {
            $capability = & $CapabilityProbe
            if (-not $capability.ok) { return $capability }
            if ($null -eq $invocation -or -not [IO.Directory]::Exists([string]$invocation.snapshot_path)) {
                return [pscustomobject]@{ ok = $false; reason = "$Platform-runtime-snapshot-missing" }
            }
            return [pscustomobject]@{ ok = $true; reason = "$RuntimeId-ready" }
        }
        catch { return [pscustomobject]@{ ok = $false; reason = ("$Platform-runtime-preflight-failed:" + $_.Exception.Message) } }
    }.GetNewClosure()

    $invoke = {
        param($harness, $invocation, $onStarted, $environment, $progress)
        $process = $null; $descriptor = $null; $readyPath = $null; $started = $false
        $stdoutDrain = $null; $stderrDrain = $null; $containmentVerified = $false
        try {
            if ($null -eq $harness -or -not $harness.PSObject.Properties['build_process'] -or $harness.build_process -isnot [scriptblock]) {
                return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = 'runtime-harness-process-contract-missing'; process_tree_live = $false; output_activity = $false }
            }
            $spec = & $harness.build_process $invocation $environment
            $specValidation = & $validateSpecCommand -Spec $spec -Invocation $invocation
            if (-not $specValidation.valid) {
                return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = ('runtime-process-spec-invalid:' + ($specValidation.errors -join ',')); process_tree_live = $false; output_activity = $false }
            }
            $executable = & $resolveExecutableCommand -CommandName ([string]$spec.command)
            $descriptor = & $SetupContainment $invocation
            if ($null -eq $descriptor) { throw "$Platform-containment-setup-returned-null" }
            $candidateParent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath([string]$spec.candidate_result_path))
            $readyPath = Join-Path $candidateParent ('.runtime-ready-' + [guid]::NewGuid().ToString('N') + '.json')

            $startInfo = [Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $pwshPath
            foreach ($argument in @('-NoProfile', '-File', $hostPath, '-Mode', $HostMode, '-ReadyPath', $readyPath)) { [void]$startInfo.ArgumentList.Add($argument) }
            if ($HostMode -ceq 'linux-cgroup') { [void]$startInfo.ArgumentList.Add('-CgroupPath'); [void]$startInfo.ArgumentList.Add([string]$descriptor.path) }
            $startInfo.WorkingDirectory = [string]$spec.working_directory
            $startInfo.UseShellExecute = $false; $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardInput = $true; $startInfo.RedirectStandardOutput = $true; $startInfo.RedirectStandardError = $true
            $startInfo.StandardInputEncoding = [Text.UTF8Encoding]::new($false)

            $process = [Diagnostics.Process]::new(); $process.StartInfo = $startInfo
            if (-not $process.Start()) { throw 'posix-runtime-host-start-returned-false' }
            $started = $true
            $stdoutDrain = $process.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null)
            $stderrDrain = $process.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
            $ready = & $waitReadyCommand -Path $readyPath -ExpectedMode $HostMode -TimeoutMilliseconds $handshakeTimeoutMilliseconds
            if ($null -eq $ready -or [int]$ready.pid -ne $process.Id) { throw "$Platform-containment-handshake-failed" }
            $containmentVerified = [bool](& $VerifyContainment $descriptor $ready $process.Id)
            if (-not $containmentVerified) { throw "$Platform-containment-verification-failed" }

            $containmentId = if ($Containment -ceq 'cgroup-v2') { [string]$descriptor.path } else { [string]$descriptor.pgid }
            $runtimeReceipt = [pscustomobject][ordered]@{
                schema_version = '1.0'; runtime_id = $RuntimeId; platform = $Platform; containment_kind = $Containment
                containment_id = $containmentId; process_id = $process.Id
                process_started_at = $process.StartTime.ToUniversalTime().ToString('o')
            }
            try { $null = & $onStarted $runtimeReceipt }
            catch { throw ('runtime-start-callback-failed:' + $_.Exception.Message) }

            $environmentDelta = [ordered]@{}
            foreach ($key in @($spec.environment_delta.Keys)) { $environmentDelta[[string]$key] = [string]$spec.environment_delta[$key] }
            $payload = [ordered]@{
                executable = $executable; argument_list = @($spec.argument_list); working_directory = [string]$spec.working_directory
                environment_delta = $environmentDelta; prompt_transport = [string]$spec.prompt_transport; stdin_text = $(if ($spec.prompt_transport -ceq 'stdin') { [string]$spec.stdin_text } else { $null })
            }
            $process.StandardInput.Write(($payload | ConvertTo-Json -Compress -Depth 12))
            $process.StandardInput.Close()

            $effectiveTimeout = [Math]::Min($TimeoutSeconds, [int]$spec.timeout_seconds)
            $timeoutMilliseconds = [long]$effectiveTimeout * 1000
            $waitWatch = [Diagnostics.Stopwatch]::StartNew()
            & $writeProgressCommand -Progress $progress -CandidateResultPath ([string]$spec.candidate_result_path) -ProcessTreeLive $true
            $exited = $process.HasExited
            while (-not $exited) {
                $remaining = $timeoutMilliseconds - $waitWatch.ElapsedMilliseconds
                if ($remaining -le 0) { $exited = $process.HasExited; break }
                $slice = [int][Math]::Min(5000, [Math]::Max(1, $remaining))
                $exited = $process.WaitForExit($slice)
                if (-not $exited) {
                    & $writeProgressCommand -Progress $progress -CandidateResultPath ([string]$spec.candidate_result_path) -ProcessTreeLive $true
                }
            }
            $timedOut = -not $exited
            $exitCode = if ($exited) { $process.ExitCode } else { $null }
            & $StopContainment $descriptor $(if ($timedOut) { $TerminationGraceSeconds } else { 0 })
            if (-not $process.HasExited) { [void]$process.WaitForExit(5000) }
            $streamsClosed = $stdoutDrain.Wait(5000) -and $stderrDrain.Wait(5000)
            $containmentEmpty = [bool](& $WaitContainmentEmpty $descriptor 5000)
            $rootDead = & $testDeadCommand -ProcessId $process.Id
            $cleanupVerified = [bool](& $CleanupContainment $descriptor)
            $terminationVerified = $streamsClosed -and $containmentEmpty -and $rootDead -and $cleanupVerified
            $outputActivity = & $testOutputActivityCommand -CandidateResultPath ([string]$spec.candidate_result_path)
            if ($timedOut) {
                return [pscustomobject]@{
                    runtime_outcome = 'timed-out'; termination_verified = $terminationVerified; containment = $(if ($containmentVerified) { 'verified' } else { 'unknown' })
                    failure_reason = $(if ($terminationVerified) { "timeout after $effectiveTimeout seconds; $Containment process tree verified dead, streams closed, containment cleaned" } else { "timeout after $effectiveTimeout seconds; termination verification failed" })
                    process_tree_live = (-not $terminationVerified); output_activity = $outputActivity; streams_closed = $streamsClosed; cleanup_verified = $cleanupVerified
                }
            }
            if (-not $terminationVerified) {
                return [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = $false; containment = 'unknown'; failure_reason = "$Containment termination, stream closure, or cleanup verification failed"; process_tree_live = $true; output_activity = $outputActivity; streams_closed = $streamsClosed; cleanup_verified = $cleanupVerified; exit_code = $exitCode }
            }
            $outcome = if ($exitCode -eq 0) { 'completed' } else { 'terminated' }
            return [pscustomobject]@{
                runtime_outcome = $outcome; termination_verified = $true; containment = 'verified'
                failure_reason = $(if ($exitCode -eq 0) { $null } else { "reviewer-process-exit-code:$exitCode" })
                process_tree_live = $false; output_activity = $outputActivity; streams_closed = $streamsClosed; cleanup_verified = $cleanupVerified; exit_code = $exitCode
            }
        }
        catch {
            $why = $_.Exception.Message
            if (-not $started) { return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = ("$Platform-runtime-launch-failed:" + $why); process_tree_live = $false; output_activity = $false } }
            try { $process.StandardInput.Close() } catch { $null = $_ }
            if ($null -ne $descriptor) { try { & $StopContainment $descriptor 0 } catch { $null = $_ } }
            try { if (-not $process.HasExited) { [void]$process.WaitForExit(5000) } } catch { $null = $_ }
            $streamsClosed = try { $stdoutDrain.Wait(5000) -and $stderrDrain.Wait(5000) } catch { $false }
            $containmentEmpty = if ($null -ne $descriptor) { try { [bool](& $WaitContainmentEmpty $descriptor 5000) } catch { $false } } else { $false }
            $rootDead = try { & $testDeadCommand -ProcessId $process.Id } catch { $false }
            $cleanupVerified = if ($null -ne $descriptor) { try { [bool](& $CleanupContainment $descriptor) } catch { $false } } else { $false }
            $verified = $streamsClosed -and $containmentEmpty -and $rootDead -and $cleanupVerified
            return [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = $verified; containment = $(if ($containmentVerified) { 'verified' } else { 'unknown' }); failure_reason = ("$Platform-runtime-failed:" + $why); process_tree_live = (-not $verified); output_activity = $false; streams_closed = $streamsClosed; cleanup_verified = $cleanupVerified }
        }
        finally {
            if ($null -ne $descriptor) { try { & $CleanupContainment $descriptor | Out-Null } catch { $null = $_ } }
            if (-not [string]::IsNullOrWhiteSpace($readyPath)) { try { Remove-Item -LiteralPath $readyPath -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
            if ($null -ne $process) { try { $process.Dispose() } catch { $null = $_ } }
        }
    }.GetNewClosure()

    $recover = { param($receipt) & $RecoverContainment $receipt }.GetNewClosure()

    return [pscustomobject]@{ id = $RuntimeId; platform = $Platform; containment = $Containment; preflight = $preflight; invoke = $invoke; recover = $recover }
}
