$ErrorActionPreference = 'Stop'

# Trace: T078 (FR-026/FR-030 the async navigator: fast reap-then-fire dispatcher) + T079 (FR-030/FR-031
# the pending registry + reaper: next-stop reap, blocking-verdict STOP-BLOCK, orphan kill+clean, the
# SessionStart cross-session sweep, dedup-by-reviewed-tree-id, one-pending-at-a-time concurrency).
#
# The navigator LOGIC (scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1) is the
# unit under test. It dot-sources the T077 launcher + the CCR _load.ps1 itself; these tests dot-source
# the navigator (which loads the launcher) and the _load (for the digest + dispatch fns). Real isolated
# tasks are fired against throwaway git repos in $TEMP; the SAME Wait-SupervisorTerminal barrier as the
# launcher suite guarantees no live subprocess leaks into the next test.
#
# Harness note (per task constraint): run THIS file in its own fresh
#   pwsh -NoProfile -NonInteractive  with  $env:TEMP/$env:TMP -> <repo>\.scratch\pestertmp
#   and  $env:SPECREW_MODULE_PATH=(Get-Location).Path
# git identity is supplied PER-INVOCATION via `git -c user.*` in TEMP repos ONLY - this suite never runs
# git config/commit/add against the Specrew repo (asserted clean at the end).

Describe 'T078/T079 continuous co-review navigator (reap + fire + dedup + orphan/cross-session sweep)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        # The navigator dot-sources the launcher; _load brings the digest + gate-dispatch fns it reuses.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

        # A self-contained governed "project": a real git repo (so the digest + merge-base resolve) with
        # a .specrew/ dir + a start-context.json whose boundary_type puts us in the implement window.
        # Uses `git -c user.*` per-invocation - never mutates a real repo's config.
        function script:New-NavigatorProject {
            param([string]$BoundaryType = 'before-implement', [string]$FileContent = 'v0')
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('nav-proj-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            & git -C $root init -q 2>&1 | Out-Null
            & git -C $root branch -m main 2>&1 | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'src/app.txt') -Value $FileContent -Encoding UTF8 -NoNewline
            & git -C $root -c user.name='nav-test' -c user.email='nav@test.local' add -A 2>&1 | Out-Null
            & git -C $root -c user.name='nav-test' -c user.email='nav@test.local' commit -q -m 'trunk' 2>&1 | Out-Null
            # Diverge onto a feature branch so `merge-base main HEAD` is the TRUNK tip (the real dogfood
            # shape) - otherwise, committing increments straight onto main makes the merge-base == HEAD
            # and the baseline->worktree diff is always empty (no checkpoint ever detected).
            & git -C $root -c user.name='nav-test' -c user.email='nav@test.local' checkout -q -b feature 2>&1 | Out-Null
            # .specrew governed surfaces.
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
            $sc = [ordered]@{ session_state = [ordered]@{ boundary_type = $BoundaryType } } | ConvertTo-Json -Depth 6
            Set-Content -LiteralPath (Join-Path $root '.specrew/start-context.json') -Value $sc -Encoding UTF8
            return $root
        }

        # Add a NEW commit on top of trunk so the merge-base baseline -> HEAD diff is a real checkpoint.
        function script:Add-NavigatorIncrement {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Content)
            Set-Content -LiteralPath (Join-Path $Root 'src/app.txt') -Value $Content -Encoding UTF8 -NoNewline
            & git -C $Root -c user.name='nav-test' -c user.email='nav@test.local' add -A 2>&1 | Out-Null
            & git -C $Root -c user.name='nav-test' -c user.email='nav@test.local' commit -q -m ('inc-' + [guid]::NewGuid().ToString('N').Substring(0, 6)) 2>&1 | Out-Null
        }

        # BARRIER: wait until the detached supervisor for a fired run has FULLY finished (process exited
        # AND its registry/status reached a terminal value). The supervisor writes the terminal status
        # LAST (in its finally, after the slow worktree removal). Mirrors the launcher suite's barrier so
        # this test leaks no live subprocess. $RunId is the launcher-generated id (decision.fired_run_id).
        # The barrier waits on BOTH the registry terminal status AND the supervisor process exit (mirrors
        # the launcher suite). On Windows each fire is two COLD `pwsh` spawns (supervisor -> reviewer
        # child) plus the tar worktree materialize/dispose, which under background CI load runs ~40-50s
        # per fire; the timeout is generous so the barrier never returns null on a slow-but-healthy run.
        # Returns the parsed terminal REGISTRY (it carries the terminal status the reaper reads).
        function script:Wait-NavigatorRunTerminal {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$RunId, [int]$TimeoutSec = 120)
            $statusPath = Join-Path $Root (".specrew/review/pending/$RunId/status.json")
            $registryPath = Join-Path $Root (".specrew/review/pending/$RunId.json")
            $terminal = @('done', 'timed-out', 'failed', 'reaped', 'crashed')
            $deadline = (Get-Date).AddSeconds($TimeoutSec)
            while ((Get-Date) -lt $deadline) {
                $supPid = $null
                if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
                    try {
                        $reg = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
                        if ($reg.PSObject.Properties.Name -contains 'supervisor_pid') { $supPid = $reg.supervisor_pid }
                        if (($reg.PSObject.Properties.Name -contains 'status') -and ($reg.status -in $terminal)) {
                            # Registry is terminal (written LAST, in the supervisor's finally) -> fully done.
                            return $reg
                        }
                    }
                    catch { $null = $_ }
                }
                # Secondary signal: status.json is terminal AND the supervisor process has exited.
                $procGone = $true
                if ($supPid) { try { $null = Get-Process -Id ([int]$supPid) -ErrorAction Stop; $procGone = $false } catch { $procGone = $true } }
                if ($procGone -and (Test-Path -LiteralPath $statusPath -PathType Leaf)) {
                    try {
                        $st = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
                        if (($st.PSObject.Properties.Name -contains 'status') -and ($st.status -in $terminal)) {
                            Start-Sleep -Milliseconds 400  # let the registry finally settle
                            if (Test-Path -LiteralPath $registryPath -PathType Leaf) {
                                try { return (Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json) } catch { $null = $_ }
                            }
                            return $st
                        }
                    }
                    catch { $null = $_ }
                }
                Start-Sleep -Milliseconds 200
            }
            return $null
        }

        # A fast dummy reviewer -Command that emits a verdict JSON to STDOUT (captured to result.out).
        # $Blocking toggles a blocking finding. This is the reviewer-command seam the navigator passes
        # through to the launcher.
        function script:New-DummyReviewerCommand {
            param([switch]$Blocking)
            if ($Blocking) {
                return @'
$v = [ordered]@{ schema_version='1.0'; status='findings'; disposition='reject'; blocking=$true; findings=@(@{ id='F1'; severity='blocking'; location='src/app.txt'; comment='dummy blocking finding'; disposition='blocking' }) }
[Console]::Out.Write(($v | ConvertTo-Json -Depth 6 -Compress))
'@
            }
            return @'
$v = [ordered]@{ schema_version='1.0'; status='no_findings'; disposition='pass'; blocking=$false; findings=@() }
[Console]::Out.Write(($v | ConvertTo-Json -Depth 6 -Compress))
'@
        }
    }

    AfterAll {
        # The suite must never leave git identity on the Specrew repo (the fan-out hygiene rule).
        Push-Location $script:RepoRoot
        try {
            $userCfg = @(& git config --local --get-regexp '^user\.' 2>$null)
            $userCfg.Count | Should -Be 0
        }
        finally { Pop-Location }
    }

    It 'FINDING 2 (conservative reap): a TRANSIENT Get-Process error does NOT reap a running entry' {
        # The reap must treat ONLY an unambiguous "no such process" as supervisor-gone. A transient
        # Get-Process FAILURE (e.g. permission/other) must leave the entry PENDING for the next reap,
        # not prematurely kill a genuinely-running review. We plant a non-past-deadline running entry
        # and Mock Get-Process to throw a NON-not-found error; the entry must survive.
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $runId = 'transient-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('nav-transient-wt-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $fakeWt -Force | Out-Null
            $pendingDir = Join-Path $root '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $regPath = Join-Path $pendingDir "$runId.json"
            ([ordered]@{
                    schema_version = '1.0'
                    run_id         = $runId
                    supervisor_pid = 424242    # the pid the mocked Get-Process throws transiently for
                    worktree_path  = $fakeWt
                    run_dir        = (Join-Path $pendingDir $runId)
                    deadline       = ((Get-Date).ToUniversalTime().AddMinutes(10).ToString('o'))  # NOT past-deadline
                    status         = 'running'
                } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

            # Transient (NON-ObjectNotFound) failure: a bare throw -> RuntimeException, category
            # OperationStopped, FQID 'transient-probe-error' - neither matches the not-found discriminator.
            Mock Get-Process { throw 'transient-probe-error' } -ParameterFilter { $Id -eq 424242 }

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            # NOT reaped: the entry survives + its worktree is untouched.
            $reap.reaped_run_ids -contains $runId | Should -Be $false
            Test-Path -LiteralPath $regPath | Should -Be $true
            Test-Path -LiteralPath $fakeWt | Should -Be $true
        }
        finally {
            # The fake worktree lives OUTSIDE $root (ephemeral-worktree semantics) and is intentionally
            # NOT reaped by the test, so clean it explicitly here.
            if ($fakeWt) { Remove-Item -LiteralPath $fakeWt -Recurse -Force -ErrorAction SilentlyContinue }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'FINDING 2 control: a DEFINITELY-ABSENT supervisor (not-found) IS still reaped' {
        # The conservative discriminator must NOT regress the orphan reap: a genuinely dead pid (which
        # throws NoProcessFoundForGivenId) is still classified absent -> reaped + cleaned.
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $deadProc = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru -WindowStyle Hidden
            $deadProc.WaitForExit()
            $deadPid = $deadProc.Id
            $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('nav-absent-wt-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $fakeWt -Force | Out-Null
            $runId = 'absent-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $regPath = Join-Path $pendingDir "$runId.json"
            ([ordered]@{
                    schema_version = '1.0'
                    run_id         = $runId
                    supervisor_pid = $deadPid
                    worktree_path  = $fakeWt
                    run_dir        = (Join-Path $pendingDir $runId)
                    deadline       = ((Get-Date).ToUniversalTime().AddMinutes(10).ToString('o'))  # NOT past-deadline; absence triggers
                    status         = 'running'
                } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.reaped_run_ids -contains $runId | Should -Be $true
            Test-Path -LiteralPath $regPath | Should -Be $false
            Test-Path -LiteralPath $fakeWt | Should -Be $false
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
