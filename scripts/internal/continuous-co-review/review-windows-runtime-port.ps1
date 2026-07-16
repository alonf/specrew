$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-SpecrewProcessContainment' -ErrorAction SilentlyContinue)) {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'agent-tasks/process-tree.ps1')
}
if (-not (Get-Command -Name 'Test-ReviewRuntimeProcessSpec' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-runtime-contract.ps1')
}

function Initialize-ReviewWindowsJobQueryType {
    if ('SpecrewReviewJobQueryNative' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class SpecrewReviewJobQueryNative
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool QueryInformationJobObject(IntPtr hJob, int infoClass, IntPtr lpInfo, uint cbInfo, IntPtr lpReturnLength);

    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
    {
        public long TotalUserTime;
        public long TotalKernelTime;
        public long ThisPeriodTotalUserTime;
        public long ThisPeriodTotalKernelTime;
        public uint TotalPageFaultCount;
        public uint TotalProcesses;
        public uint ActiveProcesses;
        public uint TotalTerminatedProcesses;
    }

    public const int JobObjectBasicAccountingInformation = 1;
}
'@
}

function Get-ReviewWindowsJobActiveProcessCount {
    param([Parameter(Mandatory)][IntPtr]$JobHandle)
    if (-not $IsWindows -or $JobHandle -eq [IntPtr]::Zero) { return $null }
    try {
        Initialize-ReviewWindowsJobQueryType
        $info = New-Object SpecrewReviewJobQueryNative+JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
        $size = [Runtime.InteropServices.Marshal]::SizeOf($info)
        $buffer = [Runtime.InteropServices.Marshal]::AllocHGlobal($size)
        try {
            if (-not [SpecrewReviewJobQueryNative]::QueryInformationJobObject($JobHandle, [SpecrewReviewJobQueryNative]::JobObjectBasicAccountingInformation, $buffer, [uint32]$size, [IntPtr]::Zero)) { return $null }
            $observed = [Runtime.InteropServices.Marshal]::PtrToStructure($buffer, [type]'SpecrewReviewJobQueryNative+JOBOBJECT_BASIC_ACCOUNTING_INFORMATION')
            return [int]$observed.ActiveProcesses
        }
        finally { [Runtime.InteropServices.Marshal]::FreeHGlobal($buffer) }
    }
    catch { return $null }
}

function Test-ReviewWindowsJobObjectAvailability {
    if (-not $IsWindows) { return [pscustomobject]@{ ok = $false; reason = 'windows-runtime-wrong-platform' } }
    $job = [IntPtr]::Zero
    try {
        Initialize-SpecrewProcessContainmentRuntime
        $job = [SpecrewJobNative]::CreateJobObject([IntPtr]::Zero, $null)
        if ($job -eq [IntPtr]::Zero) { return [pscustomobject]@{ ok = $false; reason = 'windows-job-object-create-failed' } }
        $active = Get-ReviewWindowsJobActiveProcessCount -JobHandle $job
        if ($null -eq $active) { return [pscustomobject]@{ ok = $false; reason = 'windows-job-object-query-failed' } }
        return [pscustomobject]@{ ok = $true; reason = 'windows-job-object-ready' }
    }
    catch { return [pscustomobject]@{ ok = $false; reason = ('windows-job-object-preflight-failed:' + $_.Exception.Message) } }
    finally {
        if ($job -ne [IntPtr]::Zero) { try { $null = [SpecrewJobNative]::CloseHandle($job) } catch { $null = $_ } }
    }
}

function Wait-ReviewWindowsJobEmpty {
    param([Parameter(Mandatory)][IntPtr]$JobHandle, [ValidateRange(100, 30000)][int]$TimeoutMilliseconds = 5000)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        $active = Get-ReviewWindowsJobActiveProcessCount -JobHandle $JobHandle
        if ($null -eq $active) { return $false }
        if ($active -eq 0) { return $true }
        [Threading.Thread]::Sleep(25)
    }
    return $false
}

function Test-ReviewProcessDead {
    param([Parameter(Mandatory)][int]$ProcessId)
    try { return $null -eq (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) }
    catch { return $true }
}

function Resolve-ReviewWindowsProcessLaunch {
    param([Parameter(Mandatory)][string]$CommandName)
    $commands = @(Get-Command -Name $CommandName -CommandType Application -All -ErrorAction SilentlyContinue)
    $native = @($commands | Where-Object { [IO.Path]::GetExtension([string]$_.Source) -cin @('.exe', '.com') } | Select-Object -First 1)
    if ($native.Count -eq 1) { return [pscustomobject]@{ file = [string]$native[0].Source; pre_arguments = @(); resolution = 'native' } }

    $shim = @($commands | Where-Object { [IO.Path]::GetExtension([string]$_.Source) -cin @('.cmd', '.bat') } | Select-Object -First 1)
    if ($shim.Count -ne 1) { throw "runtime-command-unavailable:$CommandName" }
    $shimPath = [IO.Path]::GetFullPath([string]$shim[0].Source)
    $info = [IO.FileInfo]$shimPath
    if ($info.Length -gt 8192) { throw "runtime-command-shim-too-large:$CommandName" }
    $text = [IO.File]::ReadAllText($shimPath, [Text.UTF8Encoding]::new($false, $true))
    $match = [regex]::Match($text, '(?im)^\s*%SystemRoot%\\System32\\WindowsPowerShell\\v1\.0\\powershell\.exe\s+-NoProfile\s+-ExecutionPolicy\s+Bypass\s+-File\s+"%SCRIPT_DIR%\\(?<script>[^"\\/]+\.ps1)"\s+%\*\s*$')
    if (-not $match.Success) { throw "runtime-command-shim-unsupported:$CommandName" }
    $scriptPath = [IO.Path]::GetFullPath((Join-Path $info.DirectoryName $match.Groups['script'].Value))
    if (-not [IO.File]::Exists($scriptPath) -or [IO.Path]::GetDirectoryName($scriptPath) -cne $info.DirectoryName) {
        throw "runtime-command-shim-target-invalid:$CommandName"
    }
    $windowsPowerShell = Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell\v1.0\powershell.exe'
    if (-not [IO.File]::Exists($windowsPowerShell)) { throw 'runtime-windows-powershell-missing' }
    return [pscustomobject]@{ file = $windowsPowerShell; pre_arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath); resolution = 'bounded-powershell-shim' }
}

function New-ReviewWindowsRuntimePort {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [ValidateRange(0, 30)][int]$TerminationGraceSeconds = 5,
        [scriptblock]$CapabilityProbe
    )
    if (-not $CapabilityProbe) { $CapabilityProbe = ${function:Test-ReviewWindowsJobObjectAvailability} }
    $validateSpecCommand = ${function:Test-ReviewRuntimeProcessSpec}
    $initializeContainmentCommand = ${function:Initialize-SpecrewProcessContainmentRuntime}
    $newContainmentCommand = ${function:New-SpecrewProcessContainment}
    $stopContainmentCommand = ${function:Stop-SpecrewProcessContainment}
    $closeContainmentCommand = ${function:Close-SpecrewProcessContainment}
    $waitJobEmptyCommand = ${function:Wait-ReviewWindowsJobEmpty}
    $testProcessDeadCommand = ${function:Test-ReviewProcessDead}
    $resolveLaunchCommand = ${function:Resolve-ReviewWindowsProcessLaunch}

    $preflight = {
        param($invocation)
        $capability = & $CapabilityProbe
        if (-not $capability.ok) { return $capability }
        if ($null -eq $invocation -or -not [IO.Directory]::Exists([string]$invocation.snapshot_path)) {
            return [pscustomobject]@{ ok = $false; reason = 'windows-runtime-snapshot-missing' }
        }
        return [pscustomobject]@{ ok = $true; reason = 'windows-job-object-runtime-ready' }
    }.GetNewClosure()

    $invoke = {
        param($harness, $invocation, $onStarted, $environment)
        $process = $null; $containment = $null; $started = $false
        $stdoutDrain = $null; $stderrDrain = $null
        try {
            if ($null -eq $harness -or -not $harness.PSObject.Properties['build_process'] -or $harness.build_process -isnot [scriptblock]) {
                return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = 'runtime-harness-process-contract-missing'; process_tree_live = $false; output_activity = $false }
            }
            $spec = & $harness.build_process $invocation $environment
            $specValidation = & $validateSpecCommand -Spec $spec -Invocation $invocation
            if (-not $specValidation.valid) {
                return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = ('runtime-process-spec-invalid:' + ($specValidation.errors -join ',')); process_tree_live = $false; output_activity = $false }
            }
            & $initializeContainmentCommand
            $launch = & $resolveLaunchCommand -CommandName ([string]$spec.command)
            $startInfo = [Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = [string]$launch.file
            foreach ($argument in @($launch.pre_arguments)) { [void]$startInfo.ArgumentList.Add([string]$argument) }
            foreach ($argument in @($spec.argument_list)) { [void]$startInfo.ArgumentList.Add([string]$argument) }
            $startInfo.WorkingDirectory = [string]$spec.working_directory
            $startInfo.UseShellExecute = $false; $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardInput = $true; $startInfo.RedirectStandardOutput = $true; $startInfo.RedirectStandardError = $true
            $startInfo.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
            foreach ($key in @($spec.environment_delta.Keys)) { $startInfo.Environment[[string]$key] = [string]$spec.environment_delta[$key] }

            $process = [Diagnostics.Process]::new(); $process.StartInfo = $startInfo
            if (-not $process.Start()) { throw 'process-start-returned-false' }
            $started = $true
            $stdoutDrain = $process.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null)
            $stderrDrain = $process.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
            $containment = & $newContainmentCommand -ChildPid $process.Id
            try { & $onStarted }
            catch {
                & $stopContainmentCommand -Containment $containment -GraceSeconds 0
                [void]$process.WaitForExit(5000)
                $streamsClosed = $stdoutDrain.Wait(5000) -and $stderrDrain.Wait(5000)
                $jobEmpty = if ($containment.mode -ceq 'job-object') { & $waitJobEmptyCommand -JobHandle $containment.job_handle } else { $false }
                return [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = ($streamsClosed -and $jobEmpty -and (& $testProcessDeadCommand -ProcessId $process.Id)); containment = $(if ($containment.mode -ceq 'job-object') { 'verified' } else { 'unknown' }); failure_reason = ('runtime-start-callback-failed:' + $_.Exception.Message); process_tree_live = $false; output_activity = [IO.File]::Exists([string]$spec.candidate_result_path) }
            }
            if ($containment.mode -cne 'job-object') {
                & $stopContainmentCommand -Containment $containment -GraceSeconds 0
                [void]$process.WaitForExit(5000); $streamsClosed = $stdoutDrain.Wait(5000) -and $stderrDrain.Wait(5000)
                return [pscustomobject]@{ runtime_outcome = 'containment-violated'; termination_verified = ($streamsClosed -and (& $testProcessDeadCommand -ProcessId $process.Id)); containment = 'violated'; failure_reason = ('windows-job-object-assignment-failed:' + [string]$containment.degraded_reason); process_tree_live = $false; output_activity = [IO.File]::Exists([string]$spec.candidate_result_path) }
            }
            if ([string]$spec.prompt_transport -ceq 'stdin') {
                try { $process.StandardInput.Write([string]$spec.stdin_text) } catch { $null = $_ }
            }
            try { $process.StandardInput.Close() } catch { $null = $_ }

            $effectiveTimeout = [Math]::Min($TimeoutSeconds, [int]$spec.timeout_seconds)
            $exited = $process.WaitForExit($effectiveTimeout * 1000)
            $timedOut = -not $exited
            $exitCode = if ($exited) { $process.ExitCode } else { $null }
            & $stopContainmentCommand -Containment $containment -GraceSeconds $(if ($timedOut) { $TerminationGraceSeconds } else { 0 })
            if (-not $process.HasExited) { [void]$process.WaitForExit(5000) }
            $streamsClosed = $stdoutDrain.Wait(5000) -and $stderrDrain.Wait(5000)
            $jobEmpty = & $waitJobEmptyCommand -JobHandle $containment.job_handle
            $rootDead = & $testProcessDeadCommand -ProcessId $process.Id
            $terminationVerified = $streamsClosed -and $jobEmpty -and $rootDead
            $outputActivity = [IO.File]::Exists([string]$spec.candidate_result_path) -and ([IO.FileInfo]([string]$spec.candidate_result_path)).Length -gt 0
            if ($timedOut) {
                return [pscustomobject]@{
                    runtime_outcome = 'timed-out'; termination_verified = $terminationVerified; containment = 'verified'
                    failure_reason = $(if ($terminationVerified) { "timeout after $effectiveTimeout seconds; Windows Job Object process tree verified dead and streams closed" } else { "timeout after $effectiveTimeout seconds; termination verification failed" })
                    process_tree_live = (-not $terminationVerified); output_activity = $outputActivity; streams_closed = $streamsClosed
                }
            }
            if (-not $terminationVerified) {
                return [pscustomobject]@{
                    runtime_outcome = 'abandoned'; termination_verified = $false; containment = 'unknown'
                    failure_reason = 'Windows Job Object termination or stream-closure verification failed'
                    process_tree_live = $true; output_activity = $outputActivity; streams_closed = $streamsClosed; exit_code = $exitCode
                }
            }
            $outcome = if ($exitCode -eq 0) { 'completed' } else { 'terminated' }
            return [pscustomobject]@{
                runtime_outcome = $outcome; termination_verified = $terminationVerified; containment = 'verified'
                failure_reason = $(if ($exitCode -eq 0) { $null } else { "reviewer-process-exit-code:$exitCode" })
                process_tree_live = (-not $terminationVerified); output_activity = $outputActivity; streams_closed = $streamsClosed; exit_code = $exitCode
            }
        }
        catch {
            if (-not $started) { return [pscustomobject]@{ runtime_outcome = 'launch-failed'; termination_verified = $true; containment = 'unknown'; failure_reason = ('runtime-launch-failed:' + $_.Exception.Message); process_tree_live = $false; output_activity = $false } }
            if ($null -ne $containment) { try { & $stopContainmentCommand -Containment $containment -GraceSeconds 0 } catch { $null = $_ } }
            if ($null -ne $process) { try { [void]$process.WaitForExit(5000) } catch { $null = $_ } }
            return [pscustomobject]@{ runtime_outcome = 'abandoned'; termination_verified = $(if ($null -ne $process) { & $testProcessDeadCommand -ProcessId $process.Id } else { $false }); containment = 'unknown'; failure_reason = ('windows-runtime-failed:' + $_.Exception.Message); process_tree_live = $false; output_activity = $false }
        }
        finally {
            if ($null -ne $containment) { try { & $closeContainmentCommand -Containment $containment } catch { $null = $_ } }
            if ($null -ne $process) { try { $process.Dispose() } catch { $null = $_ } }
        }
    }.GetNewClosure()

    return [pscustomobject]@{ id = 'windows-job-object-runtime'; platform = 'windows'; containment = 'job-object'; preflight = $preflight; invoke = $invoke }
}
