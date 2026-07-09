#requires -Version 7.0
# T091 / FR-037 (design N1): ONE process manager. The inline reviewer spawn
# (Invoke-ContinuousCoReviewAgentInWorktree - the seam BOTH doors drive: `specrew review --live` inline
# and the navigator's detached entry) is contained by the SAME OS-native primitives the isolated-task
# supervisor uses (T100): Job Object w/ KILL_ON_JOB_CLOSE (Win) / setsid+PGID (Unix). The divergent
# `$proc.Kill($true)` fallback is DELETED; a timeout kills the reviewer TREE (grandchild included) with
# no orphan; the telemetry instruments the containment (the N1 "instrument the live escape" evidence);
# and the reaper can kill a dead detached-entry's reviewer tree via the telemetry in status.json.
# Cross-platform: this file is part of the T091 WSL hard-gate evidence (run on Windows AND WSL).

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')

    function script:Test-ProcAlive {
        param([Parameter(Mandatory)][int]$ProcId)
        try { $null = Get-Process -Id $ProcId -ErrorAction Stop; return $true } catch { return $false }
    }
}

Describe 'T091 inline reviewer spawn - OS-native containment (one process manager)' {

    It 'kills the reviewer GRANDCHILD on timeout (no orphan) and instruments the containment' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-t091c-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        $gcPidFile = Join-Path $wt 'gcpid.txt'
        try {
            # The fake reviewer spawns a long-sleeping GRANDCHILD (hidden on Windows), records its pid,
            # then sleeps past the timeout - the exact shape of the claude/codex grandchild escape.
            $fakeScript = "`$sp = @{ FilePath='pwsh'; ArgumentList=@('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru=`$true }; if (`$IsWindows) { `$sp.WindowStyle='Hidden' }; `$gc = Start-Process @sp; Set-Content -LiteralPath '$($gcPidFile -replace "'","''")' -Value `$gc.Id; Start-Sleep -Seconds 300"
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'review this' -HostName 'claude' -TimeoutSeconds 4

            $r.stderr | Should -Be 'timeout'
            # N1 instrumentation: the telemetry names the containment that held the reviewer.
            if ($IsWindows) { $r.telemetry.containment | Should -Be 'job-object' }
            else {
                $r.telemetry.containment | Should -Be 'pgid'
                [int]$r.telemetry.child_pgid | Should -Be ([int]$r.telemetry.child_pid) -Because 'setsid exec makes the reviewer its own group leader'
            }
            $r.telemetry.timed_out | Should -BeTrue

            Test-Path -LiteralPath $gcPidFile | Should -BeTrue -Because 'the fake reviewer must have recorded the grandchild before the timeout'
            $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())
            # Allow the graceful->hard kill to settle, then the grandchild must be GONE.
            $deadline = (Get-Date).AddSeconds(5)
            while ((script:Test-ProcAlive -ProcId $gcPid) -and ((Get-Date) -lt $deadline)) { Start-Sleep -Milliseconds 200 }
            script:Test-ProcAlive -ProcId $gcPid | Should -BeFalse -Because 'the OS-native kill must take the grandchild with the tree (the live-escape class)'
        }
        finally {
            if (Test-Path -LiteralPath $gcPidFile) {
                try { Stop-Process -Id ([int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())) -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
            }
            Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'records containment telemetry on a clean run too' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-t091b-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            # Sleep briefly so the reviewer is still alive when containment is established (mirrors a
            # real reviewer's minutes-long run; the stdin-blocked window makes this deterministic anyway).
            $fakeScript = "Start-Sleep -Seconds 1; [Console]::Out.Write('CLEAN-DONE')"
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'review this' -HostName 'claude' -TimeoutSeconds 30

            $r.exit_code | Should -Be 0
            $r.stdout | Should -Match 'CLEAN-DONE'
            if ($IsWindows) { $r.telemetry.containment | Should -Be 'job-object' }
            else { $r.telemetry.containment | Should -Be 'pgid' }
        }
        finally {
            Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'the divergent inline $proc.Kill fallback is DELETED (one kill mechanism)' {
        # N1 acceptance is a DELETION - assert it stays deleted. The only sanctioned kill surfaces in
        # the reviewer engine are the shared containment helpers (process-tree.ps1).
        $src = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $src | Should -Not -Match '\.Kill\(' -Because 'N1 deleted the divergent inline kill; the containment helper is the ONE kill'
        $src | Should -Match 'Stop-SpecrewProcessContainment' -Because 'the shared OS-native containment is the kill mechanism'
    }

    It 'the reaper kills a dead detached-entry''s reviewer tree via status.json telemetry' {
        # The detached-ENTRY path records the reviewer's pids only via heartbeat telemetry in
        # status.json (its registry has no child_*). Simulate: dead entry (stale supervisor_pid),
        # live reviewer child+grandchild, telemetry in status.json -> Stop-SpecrewIsolatedTask must
        # kill the tree and mark the registry terminal.
        $runDir = Join-Path ([System.IO.Path]::GetTempPath()) ('t091-reap-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $gcPidFile = Join-Path $runDir 'gcpid.txt'
        $childPid = $null
        $gcPid = $null
        try {
            # A live "reviewer": pwsh that spawns its own sleeper child (the tree the reap must take).
            $reviewerScript = "`$sp = @{ FilePath='pwsh'; ArgumentList=@('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru=`$true }; if (`$IsWindows) { `$sp.WindowStyle='Hidden' }; `$gc = Start-Process @sp; Set-Content -LiteralPath '$($gcPidFile -replace "'","''")' -Value `$gc.Id; Start-Sleep -Seconds 300"
            $spawnArgs = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile', '-NonInteractive', '-Command', $reviewerScript); PassThru = $true }
            if ($IsWindows) { $spawnArgs.WindowStyle = 'Hidden' }
            $reviewer = Start-Process @spawnArgs
            $childPid = [int]$reviewer.Id

            $deadline = (Get-Date).AddSeconds(15)
            while (-not (Test-Path -LiteralPath $gcPidFile) -and ((Get-Date) -lt $deadline)) { Start-Sleep -Milliseconds 150 }
            Test-Path -LiteralPath $gcPidFile | Should -BeTrue
            $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())

            # status.json as the heartbeat would leave it (child_pgid null here: the fake reviewer was
            # not setsid-spawned; the tree-kill path must still take the whole tree via the walk).
            ([pscustomobject]@{ status = 'running'; reviewer_telemetry = [pscustomobject]@{ child_pid = $childPid; child_pgid = $null; containment = 'tree-kill' } } |
                ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $runDir 'status.json') -Encoding UTF8

            # The registry of a DEAD entry: supervisor_pid points at a process that no longer exists.
            $deadArgs = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile', '-NonInteractive', '-Command', 'exit 0'); PassThru = $true }
            if ($IsWindows) { $deadArgs.WindowStyle = 'Hidden' }
            $deadPidProc = Start-Process @deadArgs
            $deadPidProc.WaitForExit()
            $regPath = Join-Path $runDir 'registry.json'
            ([pscustomobject]@{ schema_version = '1.0'; run_id = 't091-reap'; supervisor_pid = $deadPidProc.Id; run_dir = $runDir; status = 'running' } |
                ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $regPath -Encoding UTF8

            $null = Stop-SpecrewIsolatedTask -RegistryPath $regPath -Reason 'crashed'

            $deadline = (Get-Date).AddSeconds(10)
            while (((script:Test-ProcAlive -ProcId $childPid) -or (script:Test-ProcAlive -ProcId $gcPid)) -and ((Get-Date) -lt $deadline)) {
                Start-Sleep -Milliseconds 200
            }
            script:Test-ProcAlive -ProcId $childPid | Should -BeFalse -Because 'the reaper must kill the reviewer via the telemetry child_pid'
            script:Test-ProcAlive -ProcId $gcPid | Should -BeFalse -Because 'the tree walk must take the grandchild too'

            $regEnd = Get-Content -LiteralPath $regPath -Raw | ConvertFrom-Json
            $regEnd.status | Should -Be 'crashed'
            $regEnd.terminal_reason | Should -Be 'crashed'
        }
        finally {
            foreach ($p in @($childPid, $gcPid)) {
                if ($p) { try { Stop-Process -Id ([int]$p) -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
            }
            Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
