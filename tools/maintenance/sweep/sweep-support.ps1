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

# CI'S LIST (maintainer ruling 2026-11-11, DRIFT-057's fourth defect): CI on 50bb6fa8 failed a suite the green "full" sweep
# never ran. The sweep now runs every test file CI runs on a push, read at the swept revision: the honesty suite's registry
# (tests/f198-regression-suite.ps1, run by Specrew CI; its runner is expanded into its entries) and every test file the
# push workflows below name. sweep-driver.tests.ps1 case 9 fails when a push workflow that names a test file is not here.
$script:SweepCiWorkflows = @('.github/workflows/specrew-ci.yml', '.github/workflows/test.yml', '.github/workflows/cross-platform-validation.yml')
$script:SweepCiRegistry = 'tests/f198-regression-suite.ps1'

function Get-SweepCiSuites {
    # Every test file CI runs on a push, as the swept revision has them; each once, in a stable order.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev)
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $out = [System.Collections.Generic.List[string]]::new()
    $registry = (@(& git -C $Repo show ("{0}:{1}" -f $Rev, $script:SweepCiRegistry) 2>$null) -join "`n")
    $entries = @([regex]::Matches($registry, "\bpath\s*=\s*'(tests/[^']+?\.ps1)'") | ForEach-Object { $_.Groups[1].Value })
    if ($entries.Count -eq 0) { throw "The honesty suite's registry ($script:SweepCiRegistry) could not be read at $Rev, or names no suite." }
    foreach ($entry in $entries) { if ($seen.Add($entry)) { $out.Add($entry) } }
    foreach ($workflow in $script:SweepCiWorkflows) {
        $text = (@(& git -C $Repo show ("{0}:{1}" -f $Rev, $workflow) 2>$null) -join "`n")
        if ([string]::IsNullOrWhiteSpace($text)) { throw "The workflow $workflow could not be read at $Rev." }
        foreach ($m in [regex]::Matches($text, 'tests/[A-Za-z0-9_./-]+?\.ps1')) {
            if ($m.Value -ceq $script:SweepCiRegistry) { continue }
            if ($seen.Add($m.Value)) { $out.Add($m.Value) }
        }
    }
    return $out.ToArray()
}

function Get-SweepCiMissing {
    # The guard: every test file CI runs on a push that the sweep's list does not name (Ordinal, as git names them).
    [OutputType([string[]])]
    param([AllowEmptyCollection()][string[]]$SuiteList = @(), [Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev)
    $have = [System.Collections.Generic.HashSet[string]]::new([string[]]@($SuiteList | ForEach-Object { ([string]$_).Trim() }), [StringComparer]::Ordinal)
    return @(Get-SweepCiSuites -Repo $Repo -Rev $Rev | Where-Object { -not $have.Contains($_) })
}

function Get-SweepPlanLanes {
    # Every lane in the swept revision's verification plan, in its order (a sweep of the pin's side tip runs the pin's).
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev)
    $json = (@(& git -C $Repo show ("{0}:.specrew/verification-plan.json" -f $Rev) 2>$null) -join "`n")
    if ([string]::IsNullOrWhiteSpace($json)) { throw "The verification plan could not be read at $Rev." }
    $ids = @(($json | ConvertFrom-Json).commands | ForEach-Object { [string]$_.command_id } | Where-Object { $_ })
    if ($ids.Count -eq 0) { throw "The verification plan at $Rev names no lane." }
    return $ids
}

function Get-SweepSuiteList {
    # The list given, then every sign-off-lane suite and every test file CI runs on a push that it does not already name;
    # each suite once. -SkipSignoffSuites (a targeted check) runs only the list given, and such a sweep cannot close a task.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$ListPath, [Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Rev, [switch]$SkipSignoffSuites)
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @(Get-Content -LiteralPath $ListPath | ForEach-Object { $_.Trim() } | Where-Object { $_ })) { if ($seen.Add($line)) { $out.Add($line) } }
    if (-not $SkipSignoffSuites) {
        foreach ($suite in @(Get-SweepSignoffSuites -Repo $Repo -Rev $Rev)) { if ($seen.Add($suite)) { $out.Add($suite) } }
        foreach ($suite in @(Get-SweepCiSuites -Repo $Repo -Rev $Rev)) { if ($seen.Add($suite)) { $out.Add($suite) } }
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

# THE REAL-HOME CHECK (DRIFT-045 item 2, DRIFT-050; widened by the maintainer 2026-11-11, DRIFT-056). The files are those
# a hook deployment writes in a user's home: the fixed list below, and every file under ~/.specrew/hooks/ (the
# content-addressed launcher folders and bindings/) and ~/.specrew/hook-bindings/. Each is copied before a sweep and
# hashed before and after; a file changed, added or removed is reported. The home is a parameter, so the self-test runs
# on a stand-in.
$script:SweepHomeFixedFiles = @(
    '.claude/settings.json', '.claude/settings.local.json', '.codex/hooks.json', '.codex/config.toml', '.copilot/config.json',
    '.copilot/hooks/specrew-refocus.json', '.cursor/hooks.json', '.gemini/settings.json', '.specrew/specrew-hook-launch.ps1')
$script:SweepHomeHookFolders = @('.specrew/hooks', '.specrew/hook-bindings', '.copilot/hooks')

function Get-SweepHomeHookFiles {
    # Absolute paths: the fixed files (present or not) and every file in the hook folders.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$HomeRoot)
    $paths = [System.Collections.Generic.List[string]]::new()
    foreach ($rel in $script:SweepHomeFixedFiles) { $paths.Add([IO.Path]::GetFullPath((Join-Path $HomeRoot $rel))) }
    foreach ($folder in $script:SweepHomeHookFolders) {
        $dir = Join-Path $HomeRoot $folder
        if (Test-Path -LiteralPath $dir -PathType Container) {
            foreach ($f in @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force -ErrorAction SilentlyContinue)) { $paths.Add([IO.Path]::GetFullPath($f.FullName)) }
        }
    }
    return @($paths | Sort-Object -Unique)
}

function Get-SweepHomeSnapshot {
    # One row per file: File, Hash ('absent' for a fixed file that does not exist), Written.
    param([Parameter(Mandatory)][string]$HomeRoot)
    foreach ($f in @(Get-SweepHomeHookFiles -HomeRoot $HomeRoot)) {
        if (Test-Path -LiteralPath $f -PathType Leaf) { [pscustomobject]@{ File = $f; Hash = (Get-FileHash -LiteralPath $f).Hash; Written = (Get-Item -LiteralPath $f).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } }
        else { [pscustomobject]@{ File = $f; Hash = 'absent'; Written = '' } }
    }
}

function Get-SweepHomeChanges {
    # Every file whose state differs between two snapshots: changed, added (absent or unlisted before) or removed.
    param($From, $To)
    $before = @{}; foreach ($r in @($From)) { if ($null -ne $r) { $before[[string]$r.File] = $r } }
    $after = @{}; foreach ($r in @($To)) { if ($null -ne $r) { $after[[string]$r.File] = $r } }
    foreach ($file in @(@($before.Keys) + @($after.Keys) | Sort-Object -Unique)) {
        $b = if ($before.ContainsKey($file)) { [string]$before[$file].Hash } else { 'absent' }
        $a = if ($after.ContainsKey($file)) { [string]$after[$file].Hash } else { 'absent' }
        if ($b -ceq $a) { continue }
        if ($b -ceq 'absent') { '  {0} (added, written {1} local)' -f $file, [string]$after[$file].Written }
        elseif ($a -ceq 'absent') { '  {0} (removed)' -f $file }
        else { '  {0} (changed, written {1} local)' -f $file, [string]$after[$file].Written }
    }
}

function Save-SweepHomeSnapshot {
    # Copies every existing hook file into Destination, each named by its full path with ':' and '\' replaced by '_'.
    param([Parameter(Mandatory)][string]$HomeRoot, [Parameter(Mandatory)][string]$Destination)
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    foreach ($f in @(Get-SweepHomeHookFiles -HomeRoot $HomeRoot)) {
        if (Test-Path -LiteralPath $f -PathType Leaf) { Copy-Item -LiteralPath $f -Destination (Join-Path $Destination ($f -replace '[:\\/]', '_')) -Force }
    }
}
