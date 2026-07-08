$ErrorActionPreference = 'Stop'

# Trace: T077 (FR-024..031 async co-review navigator), Proposal 139 multi-agent foundation.
# The general isolated-task launcher - the supervised, isolated, disposable process seam. Tests
# fire a fast dummy harness in an ephemeral worktree materialized from a real git tree-id and
# assert: the worktree materialized the tree-id content, the provider (Start-SpecrewIsolatedTask)
# returned FAST + detached, the registry + terminal status + result appeared, discard deleted the
# worktree, and a timeout case is killed with status 'timed-out' and NO orphan.
#
# CROSS-PLATFORM: the same file is run on Linux (via WSL) to prove the provider returns fast
# (~sub-second), not the ~18s the Windows-only (no-stdio-redirect) bug causes on Unix. This is the
# whole point of the redirect-at-every-hop rule the T076 spike proved.
#
# Harness note (per task constraint): run THIS file in its own fresh
#   pwsh -NoProfile -NonInteractive  with  $env:TEMP/$env:TMP -> <repo>\.scratch\pestertmp
#   and  $env:SPECREW_MODULE_PATH=(Get-Location).Path
# git identity is supplied PER-INVOCATION via `git -c user.*` in a TEMP repo ONLY - this suite
# never runs git config/commit/add against the Specrew repo.

Describe 'T077 Start-SpecrewIsolatedTask - review path (read-only + discard + code-review)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')

        # Helper: build a throwaway git repo in $TEMP with a known marker file, return its repo root
        # + the committed tree-id. Uses `git -c user.*` (per-invocation identity) - never mutates
        # any real repo's config.
        function script:New-TempTreeIdRepo {
            param([Parameter(Mandatory)][string]$MarkerContent)
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('itask-src-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            # A known file the worktree must materialize, plus a .specrew/ path to prove the worktree
            # carries whatever is IN the tree (the digest-strip of .specrew happens upstream when the
            # tree-id is computed, not here).
            Set-Content -LiteralPath (Join-Path $repo 'MARKER.txt') -Value $MarkerContent -Encoding UTF8 -NoNewline
            New-Item -ItemType Directory -Path (Join-Path $repo 'src') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'src/app.txt') -Value 'app-content' -Encoding UTF8 -NoNewline
            & git -C $repo -c user.name='itask-test' -c user.email='itask@test.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='itask-test' -c user.email='itask@test.local' commit -q -m 'seed' 2>&1 | Out-Null
            $tree = (& git -C $repo rev-parse 'HEAD^{tree}').Trim()
            return [pscustomobject]@{ Repo = $repo; TreeId = $tree }
        }

        # BARRIER: wait until the detached supervisor has fully FINISHED. The supervisor writes the
        # registry's terminal status LAST - in its `finally`, AFTER the (slow) worktree removal - so
        # "registry status is terminal" can only be true once the finally completed. We additionally
        # wait for the supervisor PROCESS to exit. Without this barrier a test returns while its
        # supervisor is still mid-finally, leaking a live subprocess into the NEXT test (which both
        # races the registry read AND pollutes the next test). Returns the parsed terminal registry.
        function script:Wait-SupervisorTerminal {
            param(
                [Parameter(Mandatory)][psobject]$Run,
                [int]$TimeoutSec = 45
            )
            $deadline = (Get-Date).AddSeconds($TimeoutSec)
            $terminal = @('done', 'timed-out', 'failed', 'reaped')
            $reg = $null
            while ((Get-Date) -lt $deadline) {
                # 1) supervisor process gone?
                $procGone = $true
                if ($Run.supervisor_pid) {
                    try { $null = Get-Process -Id ([int]$Run.supervisor_pid) -ErrorAction Stop; $procGone = $false }
                    catch { $procGone = $true }
                }
                # 2) registry terminal?
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
    }

    It 'materializes the tree-id, returns FAST + detached, records registry/status/result, then discards the worktree' {
        $marker = 'hello-from-tree-' + [guid]::NewGuid().ToString('N')
        $src = script:New-TempTreeIdRepo -MarkerContent $marker
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))

        # The harness command: assert it is RUNNING INSIDE the materialized worktree (cwd) and the
        # tree-id content is present, then echo the marker it read back as its "review result".
        # `$PWD` here is the supervisor-set working directory = the worktree.
        $proof = Join-Path $runDir 'in-worktree-proof.txt'
        $command = @"
Set-Content -LiteralPath '$($proof -replace "'","''")' -Value (`$PWD.Path) -Encoding UTF8
`$m = Get-Content -LiteralPath (Join-Path `$PWD.Path 'MARKER.txt') -Raw
[Console]::Out.Write('REVIEW_RESULT:' + `$m)
"@

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -Access 'read-only' -Disposition 'discard' -TaskKind 'code-review' `
            -TimeoutSec 30 -Command $command -RunDir $runDir
        $sw.Stop()

        # FAST + detached: the provider must return well under the ~18s Unix bug (the whole point).
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 8
        $run.run_id | Should -Not -BeNullOrEmpty
        $run.supervisor_pid | Should -Not -BeNullOrEmpty
        $run.status | Should -Be 'running'
        # Worktree is OUTSIDE the repo (ephemeral $TEMP), never inside it.
        $run.worktree_path.StartsWith($src.Repo) | Should -Be $false

        # Registry entry exists immediately (the fire->reap signaling file), status running.
        Test-Path -LiteralPath $run.registry_path | Should -Be $true
        $reg0 = Get-Content -LiteralPath $run.registry_path -Raw | ConvertFrom-Json
        $reg0.tree_id | Should -Be $src.TreeId
        $reg0.task_kind | Should -Be 'code-review'
        $reg0.access | Should -Be 'read-only'

        # BARRIER: wait until the detached supervisor has FULLY finished (process exited + registry
        # terminal). This is the synchronization point - all post-run assertions follow it, and it
        # guarantees this test leaks no live subprocess into the next test.
        $regEnd = script:Wait-SupervisorTerminal -Run $run
        $regEnd | Should -Not -BeNullOrEmpty
        $regEnd.status | Should -Be 'done'
        $regEnd.worktree_gone | Should -Be $true

        # Terminal status.json (the reviewer's result is at result.out, captured by the redirect).
        Test-Path -LiteralPath $run.status_path | Should -Be $true
        $status = Get-Content -LiteralPath $run.status_path -Raw | ConvertFrom-Json
        $status.status | Should -Be 'done'
        $status.timed_out | Should -Be $false
        $status.child_exit | Should -Be 0

        # The worktree MATERIALIZED the tree-id content: the harness ran inside it and read MARKER.
        Test-Path -LiteralPath $proof | Should -Be $true
        $cwdSeen = (Get-Content -LiteralPath $proof -Raw).Trim()
        $cwdSeen | Should -Be $run.worktree_path

        # The child's stdout IS the reviewer result, captured to a file.
        Test-Path -LiteralPath $run.result_path | Should -Be $true
        $result = Get-Content -LiteralPath $run.result_path -Raw
        $result.Trim() | Should -Be "REVIEW_RESULT:$marker"

        # discard: the ephemeral worktree is GONE after completion (no orphan).
        Test-Path -LiteralPath $run.worktree_path | Should -Be $false

        Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'times out a slow harness: kills it, status timed-out, worktree discarded, NO orphan' {
        $src = script:New-TempTreeIdRepo -MarkerContent 'timeout-case'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))

        # A harness that records its own PID then sleeps WAY past the timeout. The supervisor must
        # kill it on deadline.
        $childPidFile = Join-Path $runDir 'child.pid'
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $command = @"
Set-Content -LiteralPath '$($childPidFile -replace "'","''")' -Value `$PID -Encoding ascii
Start-Sleep -Seconds 60
"@

        $run = Start-SpecrewIsolatedTask -RepoRoot $src.Repo -TreeId $src.TreeId `
            -Access 'read-only' -Disposition 'discard' -TaskKind 'code-review' `
            -TimeoutSec 3 -Command $command -RunDir $runDir

        # BARRIER: wait for the supervisor to FULLY finish (process exited + registry terminal). The
        # terminal status must arrive a few s after the 3s timeout, NOT after the child's 60s sleep.
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $regEnd = script:Wait-SupervisorTerminal -Run $run
        $sw.Stop()
        $regEnd | Should -Not -BeNullOrEmpty
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 35   # timed out, not slept-to-completion (60s)
        $regEnd.status | Should -Be 'timed-out'

        Test-Path -LiteralPath $run.status_path | Should -Be $true
        $status = Get-Content -LiteralPath $run.status_path -Raw | ConvertFrom-Json
        $status.status | Should -Be 'timed-out'
        $status.timed_out | Should -Be $true

        # NO orphan: the harness child the supervisor launched is gone.
        if (Test-Path -LiteralPath $childPidFile) {
            $cpid = (Get-Content -LiteralPath $childPidFile -Raw).Trim()
            if ($cpid -match '^\d+$') {
                $alive = $null
                try { $alive = Get-Process -Id ([int]$cpid) -ErrorAction Stop } catch { $alive = $null }
                $alive | Should -Be $null
            }
        }

        # discard ran in the finally even though the run was killed: worktree GONE.
        Test-Path -LiteralPath $run.worktree_path | Should -Be $false

        Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'throws not-implemented for the deferred policy seams (read-write / merge / preserve)' {
        $src = script:New-TempTreeIdRepo -MarkerContent 'seam-guard'
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))
        $repo = $src.Repo
        $tree = $src.TreeId

        # NOTE on assertion style: `Should -Throw` does NOT register thrown exceptions in THIS harness
        # (Pester 3.4 on PowerShell 7.x here) - even a bare `{ throw 'boom' } | Should -Throw` fails to
        # register. So we use explicit try/catch asserting the SPECIFIC message. This is strictly
        # stronger than `Should -Throw` (it only passes if the EXACT guard fires), and verifies each
        # deferred seam distinctly. (The function throws correctly - confirmed independently.)
        function script:Assert-SeamThrows {
            param([scriptblock]$Call, [string]$Match)
            $threw = $false; $msg = $null
            try { & $Call } catch { $threw = $true; $msg = $_.Exception.Message }
            $threw | Should -Be $true
            $msg | Should -Match $Match
        }

        script:Assert-SeamThrows -Match 'read-write' -Call {
            Start-SpecrewIsolatedTask -RepoRoot $repo -TreeId $tree -Access 'read-write' -TimeoutSec 5 -Command 'exit 0' -RunDir $runDir
        }
        script:Assert-SeamThrows -Match 'merge' -Call {
            Start-SpecrewIsolatedTask -RepoRoot $repo -TreeId $tree -Disposition 'merge' -TimeoutSec 5 -Command 'exit 0' -RunDir $runDir
        }
        script:Assert-SeamThrows -Match 'preserve' -Call {
            Start-SpecrewIsolatedTask -RepoRoot $repo -TreeId $tree -Disposition 'preserve' -TimeoutSec 5 -Command 'exit 0' -RunDir $runDir
        }

        Remove-Item -LiteralPath $src.Repo -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'Stop-SpecrewIsolatedTask reaps a registry entry: kills supervisor, removes worktree, marks terminal' {
        # Simulate an orphan: a fake worktree dir + a registry pointing at a long-lived "supervisor"
        # process (a detached sleeper), then reap it.
        $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('itask-orphan-wt-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $fakeWt -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fakeWt 'leftover.txt') -Value 'orphan' -Encoding UTF8

        # -WindowStyle is Windows-only (NotSupported on Unix pwsh) - the first real WSL run caught this.
        $sleeperArgs = @{ FilePath = 'pwsh'; ArgumentList = @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60'); PassThru = $true }
        if ($IsWindows) { $sleeperArgs.WindowStyle = 'Hidden' }
        $sleeper = Start-Process @sleeperArgs
        $runDir = Join-Path $script:RepoRoot ('.scratch/pestertmp/run-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $regPath = Join-Path $runDir 'orphan.json'
        ([ordered]@{
                schema_version = '1.0'
                run_id         = 'orphan-run'
                supervisor_pid = $sleeper.Id
                worktree_path  = $fakeWt
                status         = 'running'
            } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

        $reap = Stop-SpecrewIsolatedTask -RegistryPath $regPath -Reason 'reaped'

        $reap.worktree_gone | Should -Be $true
        Test-Path -LiteralPath $fakeWt | Should -Be $false
        # The supervisor process was killed.
        Start-Sleep -Milliseconds 400
        $alive = $null
        try { $alive = Get-Process -Id $sleeper.Id -ErrorAction Stop } catch { $alive = $null }
        $alive | Should -Be $null
        # Registry marked terminal.
        $reg = Get-Content -LiteralPath $regPath -Raw | ConvertFrom-Json
        $reg.status | Should -Be 'reaped'

        Remove-Item -LiteralPath $runDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
