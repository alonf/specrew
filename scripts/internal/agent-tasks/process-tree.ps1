# Cross-platform graceful process-TREE kill, shared by the isolated-task supervisor (the async watchdog)
# AND the inline reviewer spawn (continuous-co-review/worktree-reviewer.ps1) - ONE kill mechanism, not two
# divergent ones (T091/FR-037, "consolidate on the supervisor"). The reviewer (claude -p / codex exec) may
# be a GRANDCHILD of the spawned process, so a single-pid kill orphans it; this snapshots the descendant
# tree and does graceful SIGTERM -> flush window -> SIGKILL so an in-flight finding (R1) can flush first.
Set-StrictMode -Version Latest

function Get-SpecrewProcessTreeDescendants {
    # Snapshot the full descendant tree BEFORE any kill - so a grandchild that the kill would re-parent
    # is still in the snapshot. Returns descendants only (NOT $RootPid), deepest-first. Cross-platform:
    # one CIM parent-map pass on Windows (T091: the dead-root belt needs a REAL snapshot there too),
    # BFS via `pgrep -P` on Unix.
    param([Parameter(Mandatory)][int]$RootPid)
    $ordered = [System.Collections.Generic.List[int]]::new()
    if ($IsWindows) {
        # One enumeration, then BFS the parent map in memory (N processes, not N queries).
        $byParent = @{}
        try {
            foreach ($p in (Get-CimInstance Win32_Process -ErrorAction Stop | Select-Object ProcessId, ParentProcessId)) {
                $pp = [int]$p.ParentProcessId
                if (-not $byParent.ContainsKey($pp)) { $byParent[$pp] = [System.Collections.Generic.List[int]]::new() }
                $byParent[$pp].Add([int]$p.ProcessId)
            }
        }
        catch { return , (@()) }
        $frontier = @($RootPid)
        while ($frontier.Count -gt 0) {
            $next = [System.Collections.Generic.List[int]]::new()
            foreach ($p in $frontier) {
                if ($byParent.ContainsKey([int]$p)) {
                    foreach ($k in $byParent[[int]$p]) { if (-not $ordered.Contains($k)) { $ordered.Add($k); $next.Add($k) } }
                }
            }
            $frontier = $next.ToArray()
        }
        $ordered.Reverse()
        return , ($ordered.ToArray())
    }
    $frontier = @($RootPid)
    while ($frontier.Count -gt 0) {
        $next = [System.Collections.Generic.List[int]]::new()
        foreach ($p in $frontier) {
            $kids = @()
            try {
                $raw = & pgrep -P $p 2>$null
                $kids = @($raw | ForEach-Object { $i = 0; if ([int]::TryParse(($_.ToString().Trim()), [ref]$i)) { $i } } | Where-Object { $_ -gt 0 })
            }
            catch { $kids = @() }
            foreach ($k in $kids) { if (-not $ordered.Contains($k)) { $ordered.Add($k); $next.Add($k) } }
        }
        $frontier = $next.ToArray()
    }
    $ordered.Reverse()
    return , ($ordered.ToArray())
}

function Initialize-SpecrewProcessContainmentRuntime {
    # T091 root-cause fix: the Job Object P/Invoke type compiles on FIRST use (Add-Type, 1-3s). If that
    # first use happens AFTER the child spawn (inside New-SpecrewProcessContainment), the child can fork
    # a grandchild DURING the compile - before job assignment - and escape containment (the empirically
    # caught pre-assignment window). Call this BEFORE spawning: the compile happens while no child
    # exists, so assignment lands within ms of the spawn. No-op on Unix and on repeat calls.
    if ($IsWindows) { try { Initialize-SpecrewJobObjectType } catch { $null = $_ } }
}

function Stop-SpecrewProcessTree {
    # Kill $RootPid AND its descendant(s), gracefully (SIGTERM -> flush) then hard (SIGKILL). Cross-platform.
    param([Parameter(Mandatory)][int]$RootPid, [int]$GraceSeconds = 5)
    if ($IsWindows) {
        $snapshot = @(Get-SpecrewProcessTreeDescendants -RootPid $RootPid)                 # while the root is alive
        try { & taskkill /PID $RootPid /T 2>&1 | Out-Null } catch { $null = $_ }          # graceful close
        if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
        try { & taskkill /PID $RootPid /T /F 2>&1 | Out-Null } catch { $null = $_ }        # force the tree
        # Dead-root belt (T091): /T cannot resolve the tree of an already-dead root, so a descendant
        # whose parent died first would survive it. The pre-kill snapshot still names it - force it.
        foreach ($p in $snapshot) { try { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
        return
    }
    # Unix. `kill` is a Stop-Process ALIAS in PowerShell, so resolve the Application binary explicitly.
    $killBin = Get-Command -Name 'kill' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $killBin) {
        foreach ($p in (@(Get-SpecrewProcessTreeDescendants -RootPid $RootPid) + @($RootPid))) { try { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
        return
    }
    # The kill order matters because of a spawn race: a descendant (the reviewer) can appear just before the
    # deadline, AND once the root dies its orphan re-parents to init and falls out of `pgrep -P` reach. So:
    # Pass 1 - graceful SIGTERM of the current descendants (the reviewer's flush window); the ROOT stays alive.
    foreach ($p in (Get-SpecrewProcessTreeDescendants -RootPid $RootPid)) { try { & $killBin.Source -TERM $p 2>$null } catch { $null = $_ } }
    if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
    # Pass 2 - RE-enumerate while the root is still alive (catches a descendant the first snapshot raced past) + SIGKILL.
    foreach ($p in (Get-SpecrewProcessTreeDescendants -RootPid $RootPid)) { try { & $killBin.Source -KILL $p 2>$null } catch { $null = $_ } }
    # Pass 3 - SIGKILL the root LAST (killing it earlier would orphan a late descendant out of pgrep's view).
    try { & $killBin.Source -KILL $RootPid 2>$null } catch { $null = $_ }
}

# --- T100/FR-039 (design N2, Option A): OS-native atomic containment ------------------------------
# The poll-then-kill walk above is a best-effort SNAPSHOT - a grandchild forked between snapshot and
# kill escapes it (the 1h12m field hang). These primitives make the tree die by OS construct instead:
#   Windows - a Job Object with JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE: every descendant is IN the job by
#             inheritance; TerminateJobObject is atomic, and if the supervisor itself dies the closed
#             handle kills the whole job (no orphan even on supervisor crash - by construction).
#   Unix    - the child is spawned as its own session/process-group leader (setsid exec, see the
#             supervisor's spawn); `kill -- -PGID` then reaches every descendant that did not itself
#             setsid. The snapshot walk stays as the belt-and-suspenders second pass. A cgroup kill
#             would also catch setsid escapees, but cgroup-v2 delegation is not available to an
#             unprivileged supervisor on stock WSL/dev boxes - documented seam, not built.
# Stop-SpecrewProcessTree stays the universal fallback (mode 'tree-kill') when neither is available.

function Initialize-SpecrewJobObjectType {
    # Compile the kernel32 P/Invoke surface once per process. Windows-only caller.
    if ('SpecrewJobNative' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class SpecrewJobNative
{
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetInformationJobObject(IntPtr hJob, int infoClass, IntPtr lpInfo, uint cbInfo);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool TerminateJobObject(IntPtr hJob, uint uExitCode);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_BASIC_LIMIT_INFORMATION
    {
        public long PerProcessUserTimeLimit;
        public long PerJobUserTimeLimit;
        public uint LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public uint ActiveProcessLimit;
        public UIntPtr Affinity;
        public uint PriorityClass;
        public uint SchedulingClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct IO_COUNTERS
    {
        public ulong ReadOperationCount;
        public ulong WriteOperationCount;
        public ulong OtherOperationCount;
        public ulong ReadTransferCount;
        public ulong WriteTransferCount;
        public ulong OtherTransferCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
    {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }

    public const int JobObjectExtendedLimitInformation = 9;
    public const uint JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
    public const uint PROCESS_SET_QUOTA = 0x0100;
    public const uint PROCESS_TERMINATE = 0x0001;
}
'@
}

function Get-SpecrewProcessGroupId {
    # Unix: the PGID of $TargetPid via `ps` (POSIX; present on Linux/WSL/macOS). $null on any failure.
    param([Parameter(Mandatory)][int]$TargetPid)
    if ($IsWindows) { return $null }
    try {
        $raw = (& ps -o pgid= -p $TargetPid 2>$null | Out-String).Trim()
        $pgid = 0
        if ([int]::TryParse($raw, [ref]$pgid) -and $pgid -gt 0) { return $pgid }
    }
    catch { $null = $_ }
    return $null
}

function New-SpecrewProcessContainment {
    <#
        Wrap a just-spawned child in OS-native containment. Returns a descriptor consumed by
        Stop-/Close-SpecrewProcessContainment:
          @{ mode; child_pid; child_pgid; job_handle }
        mode: 'job-object' (Win, atomic) | 'pgid' (Unix, child is its own group leader) |
              'tree-kill' (fallback: snapshot walk only - containment could not be established).
        NEVER throws - a containment failure degrades to 'tree-kill' so the spawn still proceeds
        (the walk is the iter-009 behavior; containment is strictly additive).
    #>
    param([Parameter(Mandatory)][int]$ChildPid)

    if ($IsWindows) {
        $job = [IntPtr]::Zero
        $proc = [IntPtr]::Zero
        try {
            Initialize-SpecrewJobObjectType
            $job = [SpecrewJobNative]::CreateJobObject([IntPtr]::Zero, $null)
            if ($job -eq [IntPtr]::Zero) { throw 'CreateJobObject failed' }

            # KILL_ON_JOB_CLOSE: the last handle closing (incl. supervisor death) kills the whole job.
            # VALUE-TYPE TRAP: `$info.BasicLimitInformation.LimitFlags = ...` sets the flag on a COPY
            # of the nested struct (silently lost - verified: flags stay 0). Copy out, set, copy back.
            $info = New-Object SpecrewJobNative+JOBOBJECT_EXTENDED_LIMIT_INFORMATION
            $basic = $info.BasicLimitInformation
            $basic.LimitFlags = [SpecrewJobNative]::JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
            $info.BasicLimitInformation = $basic
            $size = [System.Runtime.InteropServices.Marshal]::SizeOf($info)
            $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
            try {
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($info, $buf, $false)
                if (-not [SpecrewJobNative]::SetInformationJobObject($job, [SpecrewJobNative]::JobObjectExtendedLimitInformation, $buf, [uint32]$size)) {
                    throw 'SetInformationJobObject failed'
                }
            }
            finally { [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf) }

            $proc = [SpecrewJobNative]::OpenProcess(([SpecrewJobNative]::PROCESS_SET_QUOTA -bor [SpecrewJobNative]::PROCESS_TERMINATE), $false, $ChildPid)
            if ($proc -eq [IntPtr]::Zero) { throw "OpenProcess($ChildPid) failed" }
            if (-not [SpecrewJobNative]::AssignProcessToJobObject($job, $proc)) { throw 'AssignProcessToJobObject failed' }

            # Children the harness spawns from here on are in the job by inheritance. The only escape
            # window is a grandchild forked BEFORE this assignment (~ms after spawn, vs pwsh's ~100ms+
            # boot) - covered by the belt-and-suspenders walk in Stop-SpecrewProcessContainment.
            return [pscustomobject]@{ mode = 'job-object'; child_pid = $ChildPid; child_pgid = $null; job_handle = $job; degraded_reason = $null }
        }
        catch {
            $why = $_.Exception.Message
            if ($job -ne [IntPtr]::Zero) { try { $null = [SpecrewJobNative]::CloseHandle($job) } catch { $null = $_ } }
            # degraded_reason: WHY containment fell back - recorded so a field report can distinguish
            # "job objects unavailable here" from a code defect (never silently degrade).
            return [pscustomobject]@{ mode = 'tree-kill'; child_pid = $ChildPid; child_pgid = $null; job_handle = $null; degraded_reason = $why }
        }
        finally {
            if ($proc -ne [IntPtr]::Zero) { try { $null = [SpecrewJobNative]::CloseHandle($proc) } catch { $null = $_ } }
        }
    }

    # Unix: the SPAWN (setsid exec, supervisor-side) made the child a session/group leader; here we
    # only VERIFY it. pgid == pid proves leadership; anything else (setsid absent, probe failure,
    # child already exited) degrades honestly to the snapshot walk.
    $pgid = Get-SpecrewProcessGroupId -TargetPid $ChildPid
    if ($null -ne $pgid -and $pgid -eq $ChildPid) {
        return [pscustomobject]@{ mode = 'pgid'; child_pid = $ChildPid; child_pgid = $pgid; job_handle = $null; degraded_reason = $null }
    }
    return [pscustomobject]@{ mode = 'tree-kill'; child_pid = $ChildPid; child_pgid = $null; job_handle = $null; degraded_reason = 'not-a-group-leader-or-pgid-probe-failed' }
}

function Stop-SpecrewProcessContainment {
    # The ONE kill: graceful (flush window for an in-flight finding, R1) -> atomic OS kill -> the
    # snapshot walk as the final sweep. Safe on any descriptor state; never throws.
    param([Parameter(Mandatory)][psobject]$Containment, [int]$GraceSeconds = 5)
    $rootPid = [int]$Containment.child_pid

    if ($Containment.mode -eq 'job-object' -and $Containment.job_handle -and ($Containment.job_handle -ne [IntPtr]::Zero)) {
        # Snapshot the descendants WHILE THE ROOT IS ALIVE: a grandchild forked in the pre-assignment
        # window is outside the job AND unreachable via /T once its parent dies - only a live snapshot
        # names it (the empirically caught escape; see Initialize-SpecrewProcessContainmentRuntime).
        $snapshot = @(Get-SpecrewProcessTreeDescendants -RootPid $rootPid)
        # Graceful close first (taskkill /T posts WM_CLOSE / console ctrl to the tree), then the
        # ATOMIC job kill - every job member dies in one kernel call, no walk, no race.
        try { & taskkill /PID $rootPid /T 2>&1 | Out-Null } catch { $null = $_ }
        if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
        try { $null = [SpecrewJobNative]::TerminateJobObject($Containment.job_handle, 137) } catch { $null = $_ }
        # Belt-and-suspenders for pre-assignment escapees: tree-kill while a live root can resolve it,
        # then force every snapshot survivor individually (a dead root resolves no tree).
        try { & taskkill /PID $rootPid /T /F 2>&1 | Out-Null } catch { $null = $_ }
        foreach ($p in $snapshot) { try { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
        return
    }

    if ($Containment.mode -eq 'pgid' -and $Containment.child_pgid) {
        $killBin = Get-Command -Name 'kill' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($killBin) {
            $pgid = [int]$Containment.child_pgid
            # Pre-kill snapshot (same rationale as the job branch): a descendant that re-setsid'd out
            # of the group is invisible to the group signal AND to a post-kill walk of a dead root.
            $snapshot = @(Get-SpecrewProcessTreeDescendants -RootPid $rootPid)
            # Graceful group TERM (the whole session flushes), grace, then group KILL - one signal
            # reaches every group member atomically (no snapshot race for non-setsid descendants).
            try { & $killBin.Source -TERM -- "-$pgid" 2>$null } catch { $null = $_ }
            if ($GraceSeconds -gt 0) { Start-Sleep -Seconds $GraceSeconds }
            try { & $killBin.Source -KILL -- "-$pgid" 2>$null } catch { $null = $_ }
            # Belt: force any snapshot survivor (group escapees), root-last semantics preserved by the
            # group KILL above having already taken the root.
            foreach ($p in $snapshot) { try { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
            return
        }
    }

    # Fallback ('tree-kill' / no handle / no kill binary): iter-009 snapshot walk.
    Stop-SpecrewProcessTree -RootPid $rootPid -GraceSeconds $GraceSeconds
}

function Close-SpecrewProcessContainment {
    # Finally-time straggler reap after the child ENDED (either way): a background process the
    # harness left behind must not outlive the run ("no orphans" applies to clean exits too).
    #   Windows: closing the last job handle IS the reap (KILL_ON_JOB_CLOSE).
    #   Unix: one silent group-KILL sweep; pgid reuse in the seconds-scale window is the same
    #         (accepted) exposure the snapshot walk already has.
    param([Parameter(Mandatory)][psobject]$Containment)
    if ($Containment.mode -eq 'job-object' -and $Containment.job_handle -and ($Containment.job_handle -ne [IntPtr]::Zero)) {
        try { $null = [SpecrewJobNative]::CloseHandle($Containment.job_handle) } catch { $null = $_ }
        return
    }
    if ($Containment.mode -eq 'pgid' -and $Containment.child_pgid) {
        $killBin = Get-Command -Name 'kill' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($killBin) { try { & $killBin.Source -KILL -- ("-{0}" -f [int]$Containment.child_pgid) 2>$null } catch { $null = $_ } }
    }
}
