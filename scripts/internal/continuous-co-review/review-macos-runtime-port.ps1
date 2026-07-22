$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-ReviewPosixRuntimePort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-posix-runtime-common.ps1')
}

function Initialize-ReviewMacSignalType {
    if ('SpecrewReviewMacSignalNative' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class SpecrewReviewMacSignalNative
{
    [DllImport("libc", SetLastError = true)]
    public static extern int killpg(int pgrp, int sig);
}
'@
}

function Get-ReviewMacProcessGroupPids {
    param([Parameter(Mandatory)][int]$ProcessGroupId)
    if ($ProcessGroupId -lt 1) { return [pscustomobject]@{ ok = $false; pids = @() } }
    $pids = [Collections.Generic.List[int]]::new()
    try {
        $lines = @(& ps -axo 'pid=,pgid=' 2>$null)
        if ($LASTEXITCODE -ne 0) { return [pscustomobject]@{ ok = $false; pids = @() } }
        foreach ($line in $lines) {
            if ([string]$line -match '^\s*(?<pid>\d+)\s+(?<pgid>\d+)\s*$' -and [int]$Matches['pgid'] -eq $ProcessGroupId) {
                $observed = [int]$Matches['pid']
                if (-not $pids.Contains($observed)) { $pids.Add($observed) }
            }
        }
    }
    catch { return [pscustomobject]@{ ok = $false; pids = @() } }
    return [pscustomobject]@{ ok = $true; pids = @($pids) }
}

function Wait-ReviewMacProcessGroupEmpty {
    param([Parameter(Mandatory)]$Descriptor, [ValidateRange(100, 30000)][int]$TimeoutMilliseconds = 5000)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        $observed = Get-ReviewMacProcessGroupPids -ProcessGroupId ([int]$Descriptor.pgid)
        if (-not $observed.ok) { return $false }
        if (@($observed.pids).Count -eq 0) { return $true }
        [Threading.Thread]::Sleep(25)
    }
    return $false
}

function Stop-ReviewMacProcessGroup {
    param([Parameter(Mandatory)]$Descriptor, [ValidateRange(0, 10)][int]$GraceSeconds = 5)
    $pgid = [int]$Descriptor.pgid
    if ($pgid -lt 1) { return }
    Initialize-ReviewMacSignalType
    try { $null = [SpecrewReviewMacSignalNative]::killpg($pgid, 15) } catch { $null = $_ }
    if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
    try { $null = [SpecrewReviewMacSignalNative]::killpg($pgid, 9) } catch { $null = $_ }
}

function Test-ReviewMacProcessGroupMembership {
    param([Parameter(Mandatory)]$Descriptor, [Parameter(Mandatory)]$Ready, [Parameter(Mandatory)][int]$ProcessId)
    if ([int]$Descriptor.pgid -ne $ProcessId -or [int]$Ready.containment_id -ne $ProcessId) { return $false }
    $observed = Get-SpecrewProcessGroupId -TargetPid $ProcessId
    return $null -ne $observed -and [int]$observed -eq $ProcessId
}

function Wait-ReviewMacProcessGroupMembership {
    param(
        [Parameter(Mandatory)]$Descriptor,
        [Parameter(Mandatory)]$Ready,
        [Parameter(Mandatory)][int]$ProcessId,
        [ValidateRange(25, 5000)][int]$TimeoutMilliseconds = 1000,
        [ValidateRange(1, 100)][int]$PollMilliseconds = 25,
        [scriptblock]$MembershipProbe
    )
    if (-not $MembershipProbe) { $MembershipProbe = ${function:Test-ReviewMacProcessGroupMembership} }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    do {
        if (& $MembershipProbe -Descriptor $Descriptor -Ready $Ready -ProcessId $ProcessId) { return $true }
        [Threading.Thread]::Sleep($PollMilliseconds)
    } while ($watch.ElapsedMilliseconds -lt $TimeoutMilliseconds)
    return $false
}

function Test-ReviewMacProcessGroupAvailability {
    if (-not $IsMacOS) { return [pscustomobject]@{ ok = $false; reason = 'macos-process-group-wrong-platform' } }
    foreach ($name in @('ps')) {
        if ($null -eq (Get-Command -Name $name -CommandType Application -ErrorAction SilentlyContinue)) {
            return [pscustomobject]@{ ok = $false; reason = "macos-process-group-command-missing:$name" }
        }
    }
    $process = $null; $readyPath = Join-Path ([IO.Path]::GetTempPath()) ('specrew-macos-pgid-probe-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $startInfo = [Diagnostics.ProcessStartInfo]::new(); $startInfo.FileName = [IO.Path]::GetFullPath((Get-Process -Id $PID).Path)
        foreach ($argument in @('-NoProfile', '-File', (Join-Path $PSScriptRoot 'review-posix-process-host.ps1'), '-Mode', 'process-group', '-ReadyPath', $readyPath)) { [void]$startInfo.ArgumentList.Add($argument) }
        $startInfo.UseShellExecute = $false; $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardInput = $true; $startInfo.RedirectStandardOutput = $true; $startInfo.RedirectStandardError = $true
        $process = [Diagnostics.Process]::new(); $process.StartInfo = $startInfo
        if (-not $process.Start()) { throw 'macos-process-group-probe-start-failed' }
        $stdoutDrain = $process.StandardOutput.BaseStream.CopyToAsync([IO.Stream]::Null); $stderrDrain = $process.StandardError.BaseStream.CopyToAsync([IO.Stream]::Null)
        $ready = Wait-ReviewPosixReadyFile -Path $readyPath -ExpectedMode process-group -TimeoutMilliseconds 5000
        $descriptor = [pscustomobject]@{ pgid = $process.Id; mode = 'process-group' }
        if ($null -eq $ready -or -not (Wait-ReviewMacProcessGroupMembership -Descriptor $descriptor -Ready $ready -ProcessId $process.Id)) { throw 'macos-process-group-probe-membership-failed' }
        $process.StandardInput.Close(); [void]$process.WaitForExit(5000)
        [void]$stdoutDrain.Wait(5000); [void]$stderrDrain.Wait(5000)
        if (-not (Wait-ReviewMacProcessGroupEmpty -Descriptor $descriptor -TimeoutMilliseconds 5000)) { throw 'macos-process-group-probe-cleanup-failed' }
        return [pscustomobject]@{ ok = $true; reason = 'macos-process-group-ready' }
    }
    catch { return [pscustomobject]@{ ok = $false; reason = ('macos-process-group-unavailable:' + $_.Exception.Message) } }
    finally {
        if ($null -ne $process) {
            try { if (-not $process.HasExited) { $process.Kill($true); [void]$process.WaitForExit(5000) } } catch { $null = $_ }
            try { $process.Dispose() } catch { $null = $_ }
        }
        try { Remove-Item -LiteralPath $readyPath -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
    }
}

function New-ReviewMacOSRuntimePort {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [ValidateRange(0, 10)][int]$TerminationGraceSeconds = 5,
        [scriptblock]$CapabilityProbe
    )
    $membershipCommand = ${function:Wait-ReviewMacProcessGroupMembership}
    $stopCommand = ${function:Stop-ReviewMacProcessGroup}
    $waitCommand = ${function:Wait-ReviewMacProcessGroupEmpty}
    $getGroupCommand = ${function:Get-ReviewMacProcessGroupPids}
    if (-not $CapabilityProbe) { $CapabilityProbe = ${function:Test-ReviewMacProcessGroupAvailability} }
    $setup = { param($invocation) [pscustomobject]@{ pgid = 0; mode = 'process-group' } }
    $verify = {
        param($descriptor, $ready, $processId)
        $descriptor.pgid = $processId
        & $membershipCommand -Descriptor $descriptor -Ready $ready -ProcessId $processId
    }.GetNewClosure()
    $stop = { param($descriptor, $grace) & $stopCommand -Descriptor $descriptor -GraceSeconds $grace }.GetNewClosure()
    $wait = { param($descriptor, $timeout) & $waitCommand -Descriptor $descriptor -TimeoutMilliseconds $timeout }.GetNewClosure()
    $cleanup = { param($descriptor) & $waitCommand -Descriptor $descriptor -TimeoutMilliseconds 1000 }.GetNewClosure()
    $recover = {
        param($receipt)
        if ($null -eq $receipt -or [string]$receipt.runtime_id -cne 'macos-process-group-runtime' -or [string]$receipt.platform -cne 'macos' -or [string]$receipt.containment_kind -cne 'process-group') {
            return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = 'macos-recovery-receipt-mismatch' }
        }
        try {
            $pgid = 0
            if (-not [int]::TryParse([string]$receipt.containment_id, [ref]$pgid) -or $pgid -lt 1 -or $pgid -ne [int]$receipt.process_id) {
                return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = 'macos-recovery-process-group-invalid' }
            }
            $root = Get-Process -Id ([int]$receipt.process_id) -ErrorAction SilentlyContinue
            if ($null -ne $root) {
                $start = $root.StartTime.ToUniversalTime()
                $expectedStart = try { ([DateTimeOffset]$receipt.process_started_at).UtcDateTime } catch { $null }
                if ($null -eq $expectedStart) { return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = 'macos-recovery-process-identity-unreadable' } }
                if ($start.Ticks -ne $expectedStart.Ticks) {
                    return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = 'macos-recovery-process-identity-reused' }
                }
            }
            $observed = & $getGroupCommand -ProcessGroupId $pgid
            if (-not $observed.ok) { return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = 'macos-recovery-process-group-unreadable' } }
            if (@($observed.pids).Count -eq 0) { return [pscustomobject]@{ termination_verified = $true; containment = 'verified'; process_tree_live = $false; failure_reason = $null } }
            $descriptor = [pscustomobject]@{ pgid = $pgid; mode = 'process-group' }
            & $stopCommand -Descriptor $descriptor -GraceSeconds $TerminationGraceSeconds
            $empty = [bool](& $waitCommand -Descriptor $descriptor -TimeoutMilliseconds 5000)
            return [pscustomobject]@{
                termination_verified = $empty; containment = $(if ($empty) { 'verified' } else { 'unknown' })
                process_tree_live = (-not $empty); failure_reason = $(if ($empty) { $null } else { 'macos-recovery-process-group-still-live' })
            }
        }
        catch {
            return [pscustomobject]@{ termination_verified = $false; containment = 'unknown'; process_tree_live = $null; failure_reason = ('macos-recovery-failed:' + $_.Exception.Message) }
        }
    }.GetNewClosure()
    return New-ReviewPosixRuntimePort -RuntimeId 'macos-process-group-runtime' -Platform macos -Containment process-group -HostMode process-group `
        -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds $TerminationGraceSeconds -CapabilityProbe $CapabilityProbe `
        -SetupContainment $setup -VerifyContainment $verify -StopContainment $stop -WaitContainmentEmpty $wait -CleanupContainment $cleanup -RecoverContainment $recover
}
