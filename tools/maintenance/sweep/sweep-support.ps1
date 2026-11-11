# Shared by the feature 203 sweep driver (sweep-full.ps1, run-suites.ps1). Crew maintenance tooling; not packaged.
# Maintainer rulings 2026-11-11 (DRIFT-055 and the index.lock trace):
#   - standby is detected per suite by comparing wall-clock seconds with awake seconds;
#   - while a sweep runs the driver holds a keep-awake request (system required; the display may sleep), released in a
#     finally block;
#   - the sweep runs every suite the sign-off lanes name, with the list it was given.
# Self-test: sweep-driver.tests.ps1 beside this file.

if (-not ('SpecrewSweep.Native' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace SpecrewSweep {
    public static class Native {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct REASON_CONTEXT {
            public uint Version;
            public uint Flags;
            [MarshalAs(UnmanagedType.LPWStr)] public string SimpleReasonString;
        }
        // Interrupt time that excludes time spent asleep or in hibernation (100 ns units). The 900 s suite limit,
        // a Windows wait, did not fire through 58 minutes of Modern Standby on 2026-11-10: waits run on this clock.
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool QueryUnbiasedInterruptTime(out ulong unbiasedTime);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr PowerCreateRequest(ref REASON_CONTEXT context);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool PowerSetRequest(IntPtr request, int requestType);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool PowerClearRequest(IntPtr request, int requestType);
        [DllImport("kernel32.dll", SetLastError = true)] public static extern bool CloseHandle(IntPtr handle);
    }
}
'@
}

$script:SweepPowerRequestSystemRequired = 1   # POWER_REQUEST_TYPE.PowerRequestSystemRequired; the display may still sleep.
$script:SweepStandbyMark = 'spanned standby, rerun'

function Get-SweepAwakeSeconds {
    # Seconds on a clock that does not run while the machine sleeps. Windows: the unbiased interrupt time. Elsewhere: the
    # monotonic clock, which on Linux does not count suspend either.
    [OutputType([double])]
    param()
    if ($IsWindows) {
        $ticks = [uint64]0
        if ([SpecrewSweep.Native]::QueryUnbiasedInterruptTime([ref]$ticks)) { return ([double]$ticks / 1e7) }
    }
    return ([double][Diagnostics.Stopwatch]::GetTimestamp() / [double][Diagnostics.Stopwatch]::Frequency)
}

function Get-SweepStandbyVerdict {
    # '' or the standby mark. A suite whose wall time exceeds its awake time by more than the threshold ran across a
    # sleep: its result is not a pass or a fail, and it is rerun.
    [OutputType([string])]
    param([Parameter(Mandatory)][double]$WallSeconds, [Parameter(Mandatory)][double]$AwakeSeconds, [double]$ThresholdSeconds = 20)
    if (($WallSeconds - $AwakeSeconds) -gt $ThresholdSeconds) { return $script:SweepStandbyMark }
    return ''
}

function Write-SweepKeepAwakeTrace {
    param([string]$Line)
    $trace = [string]$env:SPECREW_SWEEP_KEEPAWAKE_TRACE
    if (-not [string]::IsNullOrWhiteSpace($trace)) {
        try { Add-Content -LiteralPath $trace -Value $Line -Encoding UTF8 } catch { $null = $_ }
    }
}

function Enter-SweepKeepAwake {
    # A system-required power request with Windows, named so `powercfg /requests` shows whose it is. Returns the request;
    # Exit-SweepKeepAwake releases it. Off Windows nothing is held, and the result says so.
    param([Parameter(Mandatory)][string]$Reason)
    $request = [pscustomobject]@{ Handle = [IntPtr]::Zero; Active = $false; Released = $false; Detail = '' }
    if ($IsWindows) {
        $context = New-Object SpecrewSweep.Native+REASON_CONTEXT
        $context.Version = 0          # POWER_REQUEST_CONTEXT_VERSION
        $context.Flags = 1            # POWER_REQUEST_CONTEXT_SIMPLE_STRING
        $context.SimpleReasonString = $Reason
        $handle = [SpecrewSweep.Native]::PowerCreateRequest([ref]$context)
        if ($handle -ne [IntPtr]::Zero -and $handle -ne [IntPtr]::new(-1)) {
            $request.Handle = $handle
            $request.Active = [SpecrewSweep.Native]::PowerSetRequest($handle, $script:SweepPowerRequestSystemRequired)
            $request.Detail = if ($request.Active) { 'system-required request held' } else { 'PowerSetRequest failed: ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error() }
        }
        else { $request.Detail = 'PowerCreateRequest failed: ' + [Runtime.InteropServices.Marshal]::GetLastWin32Error() }
    }
    else { $request.Detail = 'not Windows: no request held' }
    Write-SweepKeepAwakeTrace ('acquire {0} ({1})' -f $(if ($request.Active) { 'held' } else { 'not-held' }), $request.Detail)
    return $request
}

function Exit-SweepKeepAwake {
    # Releases the request once; a second call does nothing.
    param($Request)
    if ($null -eq $Request -or [bool]$Request.Released) { return }
    $Request.Released = $true
    $cleared = $false
    if ($Request.Handle -ne [IntPtr]::Zero) {
        if ([bool]$Request.Active) { $cleared = [SpecrewSweep.Native]::PowerClearRequest($Request.Handle, $script:SweepPowerRequestSystemRequired) }
        $null = [SpecrewSweep.Native]::CloseHandle($Request.Handle)
        $Request.Handle = [IntPtr]::Zero
    }
    Write-SweepKeepAwakeTrace ('release {0}' -f $(if ($cleared) { 'cleared' } else { 'nothing-held' }))
}

function Get-SweepSignoffSuites {
    # Every suite path the sign-off lanes name, as the swept revision has them (.specrew/verification-plan.signoff-lanes.json).
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev)
    $json = (@(& git -C $Repo show ("{0}:.specrew/verification-plan.signoff-lanes.json" -f $Rev) 2>$null) -join "`n")
    if ([string]::IsNullOrWhiteSpace($json)) { throw "The sign-off lanes file could not be read at $Rev." }
    return @([regex]::Matches($json, 'tests/[A-Za-z0-9_./-]+?\.ps1') | ForEach-Object { $_.Value } | Sort-Object -Unique)
}

function Get-SweepSuiteList {
    # The list given, then every sign-off-lane suite it does not already name; each suite once.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$ListPath, [Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev, [switch]$SkipSignoffSuites)
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(Get-Content -LiteralPath $ListPath | ForEach-Object { $_.Trim() } | Where-Object { $_ })) { if ($seen.Add($line)) { $out.Add($line) } }
    if (-not $SkipSignoffSuites) {
        foreach ($suite in @(Get-SweepSignoffSuites -Repo $Repo -Rev $Rev)) { if ($seen.Add($suite)) { $out.Add($suite) } }
    }
    return $out.ToArray()
}

function Get-SweepStandbyEvents {
    # Supporting evidence only (the detection is per suite, above): Windows' Modern Standby entries and exits between two
    # times, from the System log.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][datetime]$From, [Parameter(Mandatory)][datetime]$To)
    if (-not $IsWindows) { return @() }
    try {
        return @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 506, 507; StartTime = $From; EndTime = $To } -ErrorAction Stop |
                Sort-Object TimeCreated | ForEach-Object { '  {0} {1}' -f $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'), $(if ($_.Id -eq 506) { 'entered Modern Standby' } else { 'left Modern Standby' }) })
    }
    catch { return @() }
}
