#requires -Version 7.0
# T100 / FR-039 (design N2, Option A): OS-native atomic containment for the isolated-task supervisor.
#   Windows: the reviewer child is assigned to a Job Object with KILL_ON_JOB_CLOSE - the tree dies
#            atomically on TerminateJobObject AND on supervisor death (closed handle).
#   Unix:    the child is spawned as its own session/process-group leader (setsid exec) - one group
#            signal kills the tree; the recorded child_pgid makes a DEAD supervisor's orphan
#            killable by the reaper (Stop-SpecrewIsolatedTask), which the Windows job covers natively.
# Every terminal write records terminal_reason (completed | child-exit-nonzero | hard-timeout |
# supervisor-error | <reap reason>); the pending registry is the session-scoped pidfile (child_pid /
# child_pgid / containment / session_id) the SessionStart sweep reads.
# Cross-platform: this file is the WSL-gated evidence for the T100 acceptance (run on Windows AND WSL).

Describe 'T100 isolated-task OS-native containment' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/process-tree.ps1')

        function script:New-TempTreeIdRepo {
            param([Parameter(Mandatory)][string]$MarkerContent)
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('itask-src-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'MARKER.txt') -Value $MarkerContent -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='itask-test' -c user.email='itask@test.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='itask-test' -c user.email='itask@test.local' commit -q -m 'seed' 2>&1 | Out-Null
            $tree = (& git -C $repo rev-parse 'HEAD^{tree}').Trim()
            return [pscustomobject]@{ Repo = $repo; TreeId = $tree }
        }

        function script:Wait-SupervisorTerminal {
            param([Parameter(Mandatory)][psobject]$Run, [int]$TimeoutSec = 45)
            $deadline = (Get-Date).AddSeconds($TimeoutSec)
            $terminal = @('done', 'timed-out', 'failed', 'reaped', 'crashed')
            $reg = $null
            while ((Get-Date) -lt $deadline) {
                $procGone = $true
                if ($Run.supervisor_pid) {
                    try { $null = Get-Process -Id ([int]$Run.supervisor_pid) -ErrorAction Stop; $procGone = $false }
                    catch { $procGone = $true }
                }
                $regTerminal = $false
                if (Test-Path -LiteralPath $Run.registry_path) {
                    try {
                        $reg = Get-Content -LiteralPath $Run.registry_path -Raw | ConvertFrom-Json
                        if ($reg.status -in $terminal) { $regTerminal = $true }
                    }
                    catch { $regTerminal = $false }
                }
                if ($procGone -and $regTerminal) { return $reg }
                Start-Sleep -Milliseconds 150
            }
            return $reg
        }

        # Barrier for the mid-run tests: wait until the SUPERVISOR recorded the child pids onto the
        # registry (its first running-update, right after spawn + containment).
        function script:Wait-RegistryChildInfo {
            param([Parameter(Mandatory)][psobject]$Run, [int]$TimeoutSec = 20)
            $deadline = (Get-Date).AddSeconds($TimeoutSec)
            while ((Get-Date) -lt $deadline) {
                if (Test-Path -LiteralPath $Run.registry_path) {
                    try {
                        $reg = Get-Content -LiteralPath $Run.registry_path -Raw | ConvertFrom-Json
                        if (($reg.PSObject.Properties.Name -contains 'child_pid') -and $reg.child_pid) { return $reg }
                    }
                    catch { $null = $_ }
                }
                Start-Sleep -Milliseconds 150
            }
            return $null
        }

        function script:Test-ProcAlive {
            param([Parameter(Mandatory)][int]$ProcId)
            try { $null = Get-Process -Id $ProcId -ErrorAction Stop; return $true } catch { return $false }
        }
    }

    It 'records OS-native containment + terminal_reason=completed on a clean run' {
        $src = script:New-TempTreeIdRepo -MarkerContent 'containment-clean'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))

        # The harness sleeps briefly so it is still ALIVE when the supervisor establishes containment
        # (a real reviewer runs minutes; a child that exits before assignment degrades honestly to
        # 'tree-kill' with degraded_reason - correct, but not the path this test proves).
        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -TimeoutSec 30 -Command 'Start-Sleep -Seconds 2; [Console]::Out.Write(''ok'')' -RunDir $runDir -SessionId 'sess-t100'

        $regEnd = script:Wait-SupervisorTerminal -Run $run
        $regEnd | Should -Not -BeNullOrEmpty
        $regEnd.status | Should -Be 'done'
        $regEnd.terminal_reason | Should -Be 'completed'
        $regEnd.session_id | Should -Be 'sess-t100'
        $regEnd.child_pid | Should -Not -BeNullOrEmpty

        $status = Get-Content -LiteralPath $run.status_path -Raw | ConvertFrom-Json
        $status.terminal_reason | Should -Be 'completed'
        if ($IsWindows) {
            # The Windows guarantee IS the Job Object - a tree-kill fallback would be a regression.
            $status.containment | Should -Be 'job-object'
        }
        else {
            # The Linux/WSL guarantee IS the process group (setsid exec -> pgid == pid).
            $status.containment | Should -Be 'pgid'
            [int]$status.child_pgid | Should -Be ([int]$status.child_pid)
        }

        Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'hard-timeout kills the GRANDCHILD atomically and records terminal_reason=hard-timeout' {
        $src = script:New-TempTreeIdRepo -MarkerContent 'containment-timeout'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $gcPidFile = Join-Path $runDir 'gcpid.txt'

        $command = @"
`$sp = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru = `$true }
if (`$IsWindows) { `$sp.WindowStyle = 'Hidden' }   # no visible console on Windows; param unsupported on Unix
`$gc = Start-Process @sp
Set-Content -LiteralPath '$($gcPidFile -replace "'","''")' -Value `$gc.Id
Start-Sleep -Seconds 300
"@
        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -TimeoutSec 3 -Command $command -RunDir $runDir

        $regEnd = script:Wait-SupervisorTerminal -Run $run
        $regEnd | Should -Not -BeNullOrEmpty
        $regEnd.status | Should -Be 'timed-out'
        $regEnd.terminal_reason | Should -Be 'hard-timeout'

        Test-Path -LiteralPath $gcPidFile | Should -BeTrue -Because 'the harness must have recorded the grandchild before the timeout'
        $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())
        script:Test-ProcAlive -ProcId $gcPid | Should -BeFalse -Because 'the OS-native kill must take the grandchild with the tree (no orphan)'

        Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Windows: a DEAD supervisor cannot orphan the reviewer tree (KILL_ON_JOB_CLOSE)' -Skip:(-not $IsWindows) {
        $src = script:New-TempTreeIdRepo -MarkerContent 'containment-supkill-win'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $gcPidFile = Join-Path $runDir 'gcpid.txt'

        $command = @"
`$sp = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru = `$true }
if (`$IsWindows) { `$sp.WindowStyle = 'Hidden' }   # no visible console on Windows; param unsupported on Unix
`$gc = Start-Process @sp
Set-Content -LiteralPath '$($gcPidFile -replace "'","''")' -Value `$gc.Id
Start-Sleep -Seconds 300
"@
        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -TimeoutSec 300 -Command $command -RunDir $runDir

        try {
            $reg = script:Wait-RegistryChildInfo -Run $run
            $reg | Should -Not -BeNullOrEmpty -Because 'the supervisor must record child_pid/containment onto the registry'
            $reg.containment | Should -Be 'job-object'
            $childPid = [int]$reg.child_pid

            # Wait for the grandchild to exist, then MURDER THE SUPERVISOR (simulates a crashed
            # dispatcher/host). The closing job handle must reap child + grandchild with NO reaper.
            $deadline = (Get-Date).AddSeconds(15)
            while (-not (Test-Path -LiteralPath $gcPidFile) -and ((Get-Date) -lt $deadline)) { Start-Sleep -Milliseconds 150 }
            Test-Path -LiteralPath $gcPidFile | Should -BeTrue
            $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())

            Stop-Process -Id ([int]$run.supervisor_pid) -Force

            $deadline = (Get-Date).AddSeconds(10)
            while (((script:Test-ProcAlive -ProcId $childPid) -or (script:Test-ProcAlive -ProcId $gcPid)) -and ((Get-Date) -lt $deadline)) {
                Start-Sleep -Milliseconds 200
            }
            script:Test-ProcAlive -ProcId $childPid | Should -BeFalse -Because 'KILL_ON_JOB_CLOSE must kill the child when the supervisor dies'
            script:Test-ProcAlive -ProcId $gcPid | Should -BeFalse -Because 'KILL_ON_JOB_CLOSE must kill the grandchild too (atomic containment)'
        }
        finally {
            # The supervisor died before its finally: clean the leftovers via the reaper helper.
            try { $null = Stop-SpecrewIsolatedTask -RegistryPath $run.registry_path -Reason 'crashed' } catch { $null = $_ }
            Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Unix: the reaper kills a DEAD supervisor''s orphaned reviewer GROUP via the recorded pgid' -Skip:($IsWindows) {
        $src = script:New-TempTreeIdRepo -MarkerContent 'containment-supkill-unix'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $gcPidFile = Join-Path $runDir 'gcpid.txt'

        $command = @"
`$sp = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru = `$true }
if (`$IsWindows) { `$sp.WindowStyle = 'Hidden' }   # no visible console on Windows; param unsupported on Unix
`$gc = Start-Process @sp
Set-Content -LiteralPath '$($gcPidFile -replace "'","''")' -Value `$gc.Id
Start-Sleep -Seconds 300
"@
        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -TimeoutSec 300 -Command $command -RunDir $runDir

        try {
            $reg = script:Wait-RegistryChildInfo -Run $run
            $reg | Should -Not -BeNullOrEmpty -Because 'the supervisor must record child_pid/child_pgid onto the registry'
            $reg.containment | Should -Be 'pgid'
            $childPid = [int]$reg.child_pid
            [int]$reg.child_pgid | Should -Be $childPid -Because 'setsid exec makes the child its own group leader'

            $deadline = (Get-Date).AddSeconds(15)
            while (-not (Test-Path -LiteralPath $gcPidFile) -and ((Get-Date) -lt $deadline)) { Start-Sleep -Milliseconds 150 }
            Test-Path -LiteralPath $gcPidFile | Should -BeTrue
            $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())

            # Murder the supervisor: on Unix NOTHING watches the group now - the honest orphan gap
            # the session-scoped registry exists for.
            Stop-Process -Id ([int]$run.supervisor_pid) -Force
            Start-Sleep -Milliseconds 500
            script:Test-ProcAlive -ProcId $childPid | Should -BeTrue -Because 'without the reaper the orphan survives (that is the gap being covered)'

            # The reaper (SessionStart sweep path) kills the whole group via the recorded pgid.
            $null = Stop-SpecrewIsolatedTask -RegistryPath $run.registry_path -Reason 'crashed'

            $deadline = (Get-Date).AddSeconds(10)
            while (((script:Test-ProcAlive -ProcId $childPid) -or (script:Test-ProcAlive -ProcId $gcPid)) -and ((Get-Date) -lt $deadline)) {
                Start-Sleep -Milliseconds 200
            }
            script:Test-ProcAlive -ProcId $childPid | Should -BeFalse -Because 'the reaper must kill the orphaned child via the recorded pgid'
            script:Test-ProcAlive -ProcId $gcPid | Should -BeFalse -Because 'the group signal must take the grandchild too'

            $regEnd = Get-Content -LiteralPath $run.registry_path -Raw | ConvertFrom-Json
            $regEnd.status | Should -Be 'crashed'
            $regEnd.terminal_reason | Should -Be 'crashed'
        }
        finally {
            try { $null = Stop-SpecrewIsolatedTask -RegistryPath $run.registry_path -Reason 'crashed' } catch { $null = $_ }
            Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
