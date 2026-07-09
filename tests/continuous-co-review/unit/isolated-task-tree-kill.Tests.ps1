#requires -Version 7.0
# T091 / FR-037: the isolated-task supervisor must kill the reviewer GRANDCHILD on timeout, not just the
# harness child (the reviewer claude/codex is a grandchild of the harness pwsh). Before the fix, the Unix
# path used Stop-Process on the single harness pid and ORPHANED the reviewer. This runs the REAL supervisor
# end-to-end with a harness that spawns a long-sleeping grandchild, times out, and asserts no orphan.

Describe 'isolated-task-supervisor tree-kill (T091/FR-037)' {

    BeforeAll {
        $script:Supervisor = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'agent-tasks' 'isolated-task-supervisor.ps1')).Path
    }

    It 'kills the reviewer GRANDCHILD on timeout (no orphan)' {
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-t091-" + [guid]::NewGuid().ToString('N'))
        $wt = Join-Path $tmp 'wt'
        $runDir = Join-Path $tmp 'run'
        $gcPidFile = Join-Path $tmp 'gcpid.txt'
        $null = New-Item -ItemType Directory -Path $wt -Force
        $null = New-Item -ItemType Directory -Path $runDir -Force

        try {
            # The harness (run as `pwsh -File harness.ps1` by the supervisor) spawns a GRANDCHILD that
            # sleeps far past the timeout, records its pid, then sleeps itself so the harness is alive
            # when the supervisor's deadline fires.
            # Hidden on Windows (else every grandchild opens a visible terminal); param unsupported on Unix.
            $command = "`$sp = @{ FilePath='pwsh'; ArgumentList=@('-NoProfile','-NonInteractive','-Command','Start-Sleep -Seconds 300'); PassThru=`$true }; if (`$IsWindows) { `$sp.WindowStyle='Hidden' }; `$gc = Start-Process @sp; Set-Content -LiteralPath '$gcPidFile' -Value `$gc.Id; Start-Sleep -Seconds 300"

            $job = [ordered]@{
                run_id        = 't091-treekill'
                worktree_path = $wt
                run_dir       = $runDir
                status_path   = (Join-Path $runDir 'status.json')
                result_path   = (Join-Path $runDir 'result.out')
                result_err    = (Join-Path $runDir 'result.err')
                registry_path = ''
                timeout_sec   = 2
                command       = $command
                access        = 'read-only'
                disposition   = 'discard'
            }
            $jobPath = Join-Path $runDir 'job.json'
            Set-Content -LiteralPath $jobPath -Value ($job | ConvertTo-Json -Depth 6) -Encoding UTF8

            # Run the REAL supervisor (times out at 2s, then 5s graceful tree-kill, then disposes).
            & pwsh -NoProfile -NonInteractive -File $Supervisor -JobPath $jobPath 2>&1 | Out-Null

            Test-Path -LiteralPath $gcPidFile | Should -BeTrue -Because 'the harness must have spawned + recorded the grandchild before the timeout'
            $gcPid = [int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())

            # The grandchild must be GONE - not orphaned past the supervisor's tree-kill.
            $alive = Get-Process -Id $gcPid -ErrorAction SilentlyContinue
            $alive | Should -BeNullOrEmpty -Because 'Stop-IsolatedTaskTree must kill the reviewer grandchild, not orphan it (the WSL-gated bug)'

            # The supervisor must report the run as timed-out.
            $status = Get-Content -LiteralPath $job.status_path -Raw | ConvertFrom-Json
            $status.timed_out | Should -BeTrue
        }
        finally {
            if (Test-Path -LiteralPath $gcPidFile) {
                try { Stop-Process -Id ([int]((Get-Content -LiteralPath $gcPidFile -Raw).Trim())) -Force -ErrorAction SilentlyContinue } catch { $null = $_ }
            }
            Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
