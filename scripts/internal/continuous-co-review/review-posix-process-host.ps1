[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('linux-cgroup', 'process-group')][string]$Mode,
    [Parameter(Mandatory)][string]$ReadyPath,
    [string]$CgroupPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'Wait-ReviewRuntimeOutputDrains' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-runtime-contract.ps1')
}

function Initialize-ReviewPosixSessionType {
    if ('SpecrewReviewPosixSessionNative' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class SpecrewReviewPosixSessionNative
{
    [DllImport("libc", SetLastError = true)]
    public static extern int setsid();
}
'@
}

try {
    if ($IsWindows) { throw 'posix-host-wrong-platform' }
    if ($Mode -ceq 'linux-cgroup') {
        if ([string]::IsNullOrWhiteSpace($CgroupPath)) { throw 'posix-host-cgroup-path-missing' }
        $procsPath = Join-Path ([IO.Path]::GetFullPath($CgroupPath)) 'cgroup.procs'
        if (-not [IO.File]::Exists($procsPath)) { throw 'posix-host-cgroup-procs-missing' }
        [IO.File]::WriteAllText($procsPath, [string]$PID, [Text.UTF8Encoding]::new($false))
        $containmentId = [IO.Path]::GetFullPath($CgroupPath)
    }
    else {
        Initialize-ReviewPosixSessionType
        $sessionId = [SpecrewReviewPosixSessionNative]::setsid()
        if ($sessionId -ne $PID) { throw "posix-host-setsid-failed:$([Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
        $containmentId = [string]$sessionId
    }

    $ready = [ordered]@{ schema_version = '1.0'; mode = $Mode; pid = $PID; containment_id = $containmentId }
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($ReadyPath), ($ready | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))

    # The controller sends the launch payload only after containment is verified and the immutable
    # invocation claim is recorded. The rendered prompt therefore travels over this pipe, never a file.
    $payloadText = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($payloadText)) { exit 124 }
    $payload = $payloadText | ConvertFrom-Json -Depth 20
    foreach ($name in @('executable', 'argument_list', 'working_directory', 'environment_delta', 'prompt_transport', 'timeout_seconds')) {
        if (-not $payload.PSObject.Properties[$name]) { throw "posix-host-payload-missing:$name" }
    }
    if ([string]$payload.prompt_transport -cnotin @('stdin', 'argument')) { throw 'posix-host-prompt-transport-invalid' }
    [int]$timeoutSeconds = 0
    if (-not [int]::TryParse([string]$payload.timeout_seconds, [ref]$timeoutSeconds) -or $timeoutSeconds -lt 1 -or $timeoutSeconds -gt 7200) {
        throw 'posix-host-timeout-invalid'
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [IO.Path]::GetFullPath([string]$payload.executable)
    foreach ($argument in @($payload.argument_list)) { [void]$startInfo.ArgumentList.Add([string]$argument) }
    $startInfo.WorkingDirectory = [IO.Path]::GetFullPath([string]$payload.working_directory)
    $startInfo.UseShellExecute = $false; $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true; $startInfo.RedirectStandardOutput = $true; $startInfo.RedirectStandardError = $true
    $startInfo.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($entry in @($payload.environment_delta.PSObject.Properties)) {
        if ([string]$entry.Name -cnotin @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')) { throw "posix-host-environment-key-invalid:$($entry.Name)" }
        $startInfo.Environment[[string]$entry.Name] = [string]$entry.Value
    }

    $reviewer = [Diagnostics.Process]::new(); $reviewer.StartInfo = $startInfo
    if (-not $reviewer.Start()) { throw 'posix-host-reviewer-start-failed' }
    $stdoutDrain = $reviewer.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null)
    $stderrDrain = $reviewer.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
    if ([string]$payload.prompt_transport -ceq 'stdin' -and $payload.PSObject.Properties['stdin_text']) {
        $reviewer.StandardInput.Write([string]$payload.stdin_text)
    }
    $reviewer.StandardInput.Close()
    $reviewerTimedOut = -not $reviewer.WaitForExit($timeoutSeconds * 1000)
    if ($reviewerTimedOut) {
        try { $reviewer.Kill($true) } catch { $null = $_ }
        try { [void]$reviewer.WaitForExit(5000) } catch { $null = $_ }
    }
    $exitCode = if ($reviewer.HasExited) { $reviewer.ExitCode } else { 125 }
    $streamState = Wait-ReviewRuntimeOutputDrains -StdoutDrain $stdoutDrain -StderrDrain $stderrDrain -TimeoutMilliseconds 5000
    try { $reviewer.StandardOutput.Close() } catch { $null = $_ }
    try { $reviewer.StandardError.Close() } catch { $null = $_ }
    $reviewer.Dispose()
    if ($reviewerTimedOut) { exit 124 }
    if (-not $streamState.all_closed) { exit 125 }
    exit $exitCode
}
catch {
    try { [Console]::Error.WriteLine(('specrew-posix-host:' + $_.Exception.Message)) } catch { $null = $_ }
    exit 125
}
