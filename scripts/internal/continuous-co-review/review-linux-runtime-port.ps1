$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'New-ReviewPosixRuntimePort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-posix-runtime-common.ps1')
}

function Resolve-ReviewLinuxCgroupRoot {
    [CmdletBinding()]
    param([string]$CgroupRoot)
    if (-not $IsLinux) { throw 'linux-cgroup-wrong-platform' }
    $candidate = $CgroupRoot
    if ([string]::IsNullOrWhiteSpace($candidate)) { $candidate = $env:SPECREW_REVIEW_CGROUP_ROOT }
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $entry = Get-Content -LiteralPath '/proc/self/cgroup' -ErrorAction Stop | Where-Object { $_ -match '^0::(?<path>/.*)$' } | Select-Object -First 1
        if ([string]::IsNullOrWhiteSpace([string]$entry)) { throw 'linux-cgroup-v2-membership-missing' }
        $relative = ([regex]::Match([string]$entry, '^0::(?<path>/.*)$').Groups['path'].Value).TrimStart('/')
        $candidate = Join-Path '/sys/fs/cgroup' $relative
    }
    $resolved = [IO.Path]::GetFullPath($candidate)
    if (-not [IO.Directory]::Exists($resolved) -or -not [IO.File]::Exists((Join-Path $resolved 'cgroup.controllers'))) {
        throw "linux-cgroup-v2-root-invalid:$resolved"
    }
    return $resolved
}

function New-ReviewLinuxCgroupDescriptor {
    param([string]$CgroupRoot)
    $root = Resolve-ReviewLinuxCgroupRoot -CgroupRoot $CgroupRoot
    $path = Join-Path $root ('specrew-review-' + [guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($path)
    foreach ($name in @('cgroup.procs', 'cgroup.events', 'cgroup.kill')) {
        if (-not [IO.File]::Exists((Join-Path $path $name))) {
            try { [IO.Directory]::Delete($path) } catch { $null = $_ }
            throw "linux-cgroup-required-interface-missing:$name"
        }
    }
    return [pscustomobject]@{ path = $path; root = $root; mode = 'cgroup-v2' }
}

function Get-ReviewLinuxCgroupPids {
    param([Parameter(Mandatory)]$Descriptor)
    $path = Join-Path ([string]$Descriptor.path) 'cgroup.procs'
    if (-not [IO.File]::Exists($path)) { return @() }
    $pids = [Collections.Generic.List[int]]::new()
    foreach ($line in @(Get-Content -LiteralPath $path -ErrorAction Stop)) {
        $observed = 0
        if ([int]::TryParse(([string]$line).Trim(), [ref]$observed) -and $observed -gt 0 -and -not $pids.Contains($observed)) { $pids.Add($observed) }
    }
    return @($pids)
}

function Wait-ReviewLinuxCgroupEmpty {
    param([Parameter(Mandatory)]$Descriptor, [ValidateRange(100, 30000)][int]$TimeoutMilliseconds = 5000)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while ($watch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        if (-not [IO.Directory]::Exists([string]$Descriptor.path)) { return $true }
        try {
            $events = [IO.File]::ReadAllText((Join-Path ([string]$Descriptor.path) 'cgroup.events'))
            if ($events -match '(?m)^populated\s+0\s*$' -and @(Get-ReviewLinuxCgroupPids -Descriptor $Descriptor).Count -eq 0) { return $true }
        }
        catch { return $false }
        [Threading.Thread]::Sleep(25)
    }
    return $false
}

function Stop-ReviewLinuxCgroup {
    param([Parameter(Mandatory)]$Descriptor, [ValidateRange(0, 10)][int]$GraceSeconds = 5)
    if (-not [IO.Directory]::Exists([string]$Descriptor.path)) { return }
    $kill = Get-Command -Name kill -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $kill) {
        foreach ($processId in @(Get-ReviewLinuxCgroupPids -Descriptor $Descriptor)) {
            try { & $kill.Source -TERM $processId 2>$null } catch { $null = $_ }
        }
    }
    if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
    try { [IO.File]::WriteAllText((Join-Path ([string]$Descriptor.path) 'cgroup.kill'), '1', [Text.UTF8Encoding]::new($false)) } catch { $null = $_ }
}

function Remove-ReviewLinuxCgroup {
    param([Parameter(Mandatory)]$Descriptor)
    if (-not [IO.Directory]::Exists([string]$Descriptor.path)) { return $true }
    if (-not (Wait-ReviewLinuxCgroupEmpty -Descriptor $Descriptor -TimeoutMilliseconds 1000)) { return $false }
    try { [IO.Directory]::Delete([string]$Descriptor.path); return -not [IO.Directory]::Exists([string]$Descriptor.path) }
    catch { return $false }
}

function Test-ReviewLinuxCgroupMembership {
    param([Parameter(Mandatory)]$Descriptor, [Parameter(Mandatory)]$Ready, [Parameter(Mandatory)][int]$ProcessId)
    if ([string]$Ready.containment_id -cne [string]$Descriptor.path) { return $false }
    return $ProcessId -in @(Get-ReviewLinuxCgroupPids -Descriptor $Descriptor)
}

function Test-ReviewLinuxCgroupAvailability {
    [CmdletBinding()]
    param([string]$CgroupRoot)
    if (-not $IsLinux) { return [pscustomobject]@{ ok = $false; reason = 'linux-cgroup-wrong-platform' } }
    $descriptor = $null; $probe = $null
    try {
        $root = Resolve-ReviewLinuxCgroupRoot -CgroupRoot $CgroupRoot
        $descriptor = New-ReviewLinuxCgroupDescriptor -CgroupRoot $root
        $sleep = Resolve-ReviewPosixExecutable -CommandName sleep
        $startInfo = [Diagnostics.ProcessStartInfo]::new(); $startInfo.FileName = $sleep; [void]$startInfo.ArgumentList.Add('30')
        $startInfo.UseShellExecute = $false; $startInfo.CreateNoWindow = $true
        $probe = [Diagnostics.Process]::new(); $probe.StartInfo = $startInfo
        if (-not $probe.Start()) { throw 'linux-cgroup-probe-start-failed' }
        [IO.File]::WriteAllText((Join-Path ([string]$descriptor.path) 'cgroup.procs'), [string]$probe.Id, [Text.UTF8Encoding]::new($false))
        if ($probe.Id -notin @(Get-ReviewLinuxCgroupPids -Descriptor $descriptor)) { throw 'linux-cgroup-probe-membership-failed' }
        Stop-ReviewLinuxCgroup -Descriptor $descriptor -GraceSeconds 0
        [void]$probe.WaitForExit(5000)
        if (-not (Wait-ReviewLinuxCgroupEmpty -Descriptor $descriptor -TimeoutMilliseconds 5000)) { throw 'linux-cgroup-probe-kill-failed' }
        return [pscustomobject]@{ ok = $true; reason = 'linux-cgroup-v2-ready'; root = $root }
    }
    catch { return [pscustomobject]@{ ok = $false; reason = ('linux-cgroup-v2-unavailable:' + $_.Exception.Message) } }
    finally {
        if ($null -ne $probe) {
            try { if (-not $probe.HasExited) { $probe.Kill($true); [void]$probe.WaitForExit(5000) } } catch { $null = $_ }
            try { $probe.Dispose() } catch { $null = $_ }
        }
        if ($null -ne $descriptor) { try { Remove-ReviewLinuxCgroup -Descriptor $descriptor | Out-Null } catch { $null = $_ } }
    }
}

function New-ReviewLinuxRuntimePort {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [ValidateRange(0, 10)][int]$TerminationGraceSeconds = 5,
        [string]$CgroupRoot,
        [scriptblock]$CapabilityProbe
    )
    $availabilityCommand = ${function:Test-ReviewLinuxCgroupAvailability}
    $newDescriptorCommand = ${function:New-ReviewLinuxCgroupDescriptor}
    $membershipCommand = ${function:Test-ReviewLinuxCgroupMembership}
    $stopCommand = ${function:Stop-ReviewLinuxCgroup}
    $waitCommand = ${function:Wait-ReviewLinuxCgroupEmpty}
    $cleanupCommand = ${function:Remove-ReviewLinuxCgroup}
    if (-not $CapabilityProbe) { $CapabilityProbe = { & $availabilityCommand -CgroupRoot $CgroupRoot }.GetNewClosure() }
    $setup = { param($invocation) & $newDescriptorCommand -CgroupRoot $CgroupRoot }.GetNewClosure()
    $verify = { param($descriptor, $ready, $processId) & $membershipCommand -Descriptor $descriptor -Ready $ready -ProcessId $processId }.GetNewClosure()
    $stop = { param($descriptor, $grace) & $stopCommand -Descriptor $descriptor -GraceSeconds $grace }.GetNewClosure()
    $wait = { param($descriptor, $timeout) & $waitCommand -Descriptor $descriptor -TimeoutMilliseconds $timeout }.GetNewClosure()
    $cleanup = { param($descriptor) & $cleanupCommand -Descriptor $descriptor }.GetNewClosure()
    return New-ReviewPosixRuntimePort -RuntimeId 'linux-cgroup-v2-runtime' -Platform linux -Containment cgroup-v2 -HostMode linux-cgroup `
        -TimeoutSeconds $TimeoutSeconds -TerminationGraceSeconds $TerminationGraceSeconds -CapabilityProbe $CapabilityProbe `
        -SetupContainment $setup -VerifyContainment $verify -StopContainment $stop -WaitContainmentEmpty $wait -CleanupContainment $cleanup
}
