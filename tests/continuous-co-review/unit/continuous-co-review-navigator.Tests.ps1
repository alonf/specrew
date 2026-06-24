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
            $userCfg.Count | Should Be 0
        }
        finally { Pop-Location }
    }

    It 'FIRE then REAP (happy path): a real checkpoint fires a dummy reviewer; the next reap surfaces the PASS verdict and retires the entry' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-for-review'
            $cmd = script:New-DummyReviewerCommand

            # FIRE: a Stop in the implement window at a real checkpoint.
            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $fire.reason | Should Be 'registered-checkpoint'
            $fire.fired_run_id | Should Not BeNullOrEmpty
            $fire.fired_tree_id | Should Not BeNullOrEmpty
            # A pending registry entry exists immediately (the fire->reap signaling file).
            $regPath = Join-Path $root (".specrew/review/pending/$($fire.fired_run_id).json")
            Test-Path -LiteralPath $regPath | Should Be $true

            # Let the detached supervisor finish (verdict written to result.out, worktree discarded).
            $st = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire.fired_run_id
            $st | Should Not BeNullOrEmpty
            $st.status | Should Be 'done'

            # REAP on the next stop: the navigator surfaces the PASS verdict as an inject note and retires
            # the entry. No new fire (the tree-id is unchanged -> dedup), so action is no-op.
            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            ($reap.inject_notes -join "`n") | Should Match 'PASSED'
            $reap.stop_block | Should BeNullOrEmpty
            $reap.reaped_run_ids -contains $fire.fired_run_id | Should Be $true
            # The pending entry is retired (deleted).
            Test-Path -LiteralPath $regPath | Should Be $false
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a BLOCKING verdict surfaces as the 185 <<<SPECREW-STOP-BLOCK>>> sentinel from the navigator PROVIDER' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-blocking'
            $cmd = script:New-DummyReviewerCommand -Blocking

            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $st = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire.fired_run_id
            $st.status | Should Be 'done'

            # REAP via the decision object: a blocking done-verdict yields a stop_block directive.
            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $reap.stop_block | Should Not BeNullOrEmpty
            $reap.stop_block | Should Match 'BLOCKING'
            $reap.stop_block | Should Match 'dummy blocking finding'

            # And end-to-end through the PROVIDER script: the dispatcher contract is the literal sentinel
            # on stdout. Re-fire a fresh blocking review (the prior was reaped), let it finish, then run
            # the provider as the dispatcher would (cwd = project, --source-event stop) and assert stdout.
            script:Add-NavigatorIncrement -Root $root -Content 'changed-blocking-2'
            $fire2 = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $fire2.action | Should Be 'fired'
            $null = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire2.fired_run_id

            $provider = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1'
            Push-Location $root
            try {
                $stdout = & pwsh -NoProfile -NonInteractive -File $provider --host-kind claude --source-event stop 2>$null
            }
            finally { Pop-Location }
            ($stdout -join "`n") | Should Match '<<<SPECREW-STOP-BLOCK>>>'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'STOP-BLOCK COLLISION (documented last-writer-wins): the navigator still emits its blocking sentinel even when a conformance-material condition co-exists this Stop' {
        # The dispatcher's $stopBlockReason is last-writer-wins with no merge logic, and the navigator
        # (order 50) runs AFTER conformance (order 40). So a navigator blocking-co-review verdict
        # OVERWRITES a co-occurring conformance block. This test pins that REALITY (so the inverted-claim
        # regression cannot recur and a reviewer sees it is known): with a blocking verdict reaped AND a
        # material-work surface present (changed files since trunk, the conformance material trigger), the
        # navigator's provider still emits its own <<<SPECREW-STOP-BLOCK>>>. (Whether the dispatcher should
        # MERGE the two is a flagged Planner design question; it is an out-of-glob dispatcher change.)
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-collision'   # material surface = changed files
            $cmd = script:New-DummyReviewerCommand -Blocking
            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $null = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire.fired_run_id

            # The navigator decision yields a stop_block (its blocking verdict), irrespective of conformance.
            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $reap.stop_block | Should Not BeNullOrEmpty
            $reap.stop_block | Should Match 'co-review navigator block'
            # It is the navigator's OWN block (not a boundary marker) - the comment's invariant.
            $reap.stop_block | Should Match 'do NOT emit a SPECREW-VERDICT-BOUNDARY marker'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'DEDUP: an unchanged reviewed tree-id does NOT fire a second review' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-once'
            $cmd = script:New-DummyReviewerCommand

            $first = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $first.action | Should Be 'fired'
            $null = script:Wait-NavigatorRunTerminal -Root $root -RunId $first.fired_run_id
            # Reap+retire the first so only the dedup gate can stop the second.
            $null = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd

            # SAME tree-id (no new increment) -> the dedup gate blocks a second fire.
            $second = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $second.action | Should Be 'no-op'
            $second.reason | Should Be 'dedup-unchanged-tree-id'

            # A NEW increment changes the tree-id -> a fresh fire is allowed again.
            script:Add-NavigatorIncrement -Root $root -Content 'changed-twice'
            $third = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
            $third.action | Should Be 'fired'
            $null = script:Wait-NavigatorRunTerminal -Root $root -RunId $third.fired_run_id
            $null = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride $cmd
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ORPHAN reap: a past-deadline entry with a LIVE supervisor is killed and its worktree cleaned' {
        $root = script:New-NavigatorProject
        try {
            # Plant an orphan: a fake worktree dir + a long-lived sleeper as the "supervisor", with a
            # registry whose deadline is already in the past + status running.
            $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('nav-orphan-wt-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $fakeWt -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $fakeWt 'leftover.txt') -Value 'orphan' -Encoding UTF8

            $sleeper = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60') -PassThru -WindowStyle Hidden
            $runId = 'orphan-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $regPath = Join-Path $pendingDir "$runId.json"
            ([ordered]@{
                    schema_version = '1.0'
                    run_id         = $runId
                    supervisor_pid = $sleeper.Id
                    worktree_path  = $fakeWt
                    run_dir        = (Join-Path $pendingDir $runId)
                    deadline       = ((Get-Date).ToUniversalTime().AddMinutes(-5).ToString('o'))
                    status         = 'running'
                } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

            # A Stop reap: the past-deadline + alive entry is Stopped (kill + clean) and retired.
            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30
            $reap.reaped_run_ids -contains $runId | Should Be $true

            Start-Sleep -Milliseconds 500
            # supervisor killed.
            $alive = $null
            try { $alive = Get-Process -Id $sleeper.Id -ErrorAction Stop } catch { $alive = $null }
            $alive | Should Be $null
            # worktree cleaned + entry retired.
            Test-Path -LiteralPath $fakeWt | Should Be $false
            Test-Path -LiteralPath $regPath | Should Be $false
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'SessionStart SWEEP: a planted stale (supervisor-gone) pending entry is cleaned cross-session' {
        $root = script:New-NavigatorProject
        try {
            # A prior-session orphan: status running, but the supervisor pid is long dead (no live proc),
            # and a leaked worktree. The SessionStart sweep must clean it (supervisor gone + no terminal).
            $fakeWt = Join-Path ([System.IO.Path]::GetTempPath()) ('nav-stale-wt-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $fakeWt -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $fakeWt 'stale.txt') -Value 'prior-session' -Encoding UTF8

            # A pid that is essentially certain to be dead (a short-lived process we just ended).
            $deadProc = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru -WindowStyle Hidden
            $deadProc.WaitForExit()
            $deadPid = $deadProc.Id

            $runId = 'stale-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $regPath = Join-Path $pendingDir "$runId.json"
            ([ordered]@{
                    schema_version = '1.0'
                    run_id         = $runId
                    supervisor_pid = $deadPid
                    worktree_path  = $fakeWt
                    run_dir        = (Join-Path $pendingDir $runId)
                    deadline       = ((Get-Date).ToUniversalTime().AddMinutes(5).ToString('o'))  # not past-deadline; the GONE supervisor is what triggers the sweep
                    status         = 'running'
                } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

            $sweep = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -SessionStart
            $sweep.mode | Should Be 'sweep'
            $sweep.reaped_run_ids -contains $runId | Should Be $true
            # No verdict surfacing on a cross-session sweep.
            $sweep.stop_block | Should BeNullOrEmpty
            @($sweep.inject_notes).Count | Should Be 0
            # worktree cleaned + entry retired.
            Test-Path -LiteralPath $fakeWt | Should Be $false
            Test-Path -LiteralPath $regPath | Should Be $false
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'NO-OP on a non-checkpoint stop: no reviewable change -> no fire, no output, nothing perturbs the dispatcher' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            # In the implement window, but NO increment beyond trunk -> merge-base diff is empty -> casual
            # yield (no-op). And the PROVIDER must emit NOTHING to stdout.
            $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30
            $dec.action | Should Be 'no-op'
            @('no-reviewable-checkpoint', 'dedup-unchanged-tree-id', 'digest-failed') -contains $dec.reason | Should Be $true
            $dec.stop_block | Should BeNullOrEmpty
            @($dec.inject_notes).Count | Should Be 0

            $provider = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1'
            Push-Location $root
            try {
                $stdout = & pwsh -NoProfile -NonInteractive -File $provider --host-kind claude --source-event stop 2>$null
            }
            finally { Pop-Location }
            ([string]::Join('', @($stdout))).Trim() | Should Be ''
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'NO-OP outside the implement window: a plan-stage cursor never fires the implement reviewer' {
        $root = script:New-NavigatorProject -BoundaryType 'plan' -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-but-not-implementing'
            $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30
            $dec.action | Should Be 'no-op'
            $dec.reason | Should Be 'not-in-implement-stage'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # ----------------------------------------------------------------------------------------------
    # Hardening (dogfood findings 1-3) + the PASS->durable-evidence promotion (Part 2).
    # (FINDING 1 runs LAST - it removes Start-SpecrewIsolatedTask from the session function table, and a
    #  Pester-scoped restore is fragile, so no fire-dependent test must follow it.)
    # ----------------------------------------------------------------------------------------------

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
            $reap.reaped_run_ids -contains $runId | Should Be $false
            Test-Path -LiteralPath $regPath | Should Be $true
            Test-Path -LiteralPath $fakeWt | Should Be $true
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
            $reap.reaped_run_ids -contains $runId | Should Be $true
            Test-Path -LiteralPath $regPath | Should Be $false
            Test-Path -LiteralPath $fakeWt | Should Be $false
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'PART 2 (PASS promotion): a reaped non-blocking PASS writes a durable runs record the signoff gate ACCEPTS' {
        # The real requirement is not "a record whose reviewed_tree_id matches" - it is "the signoff gate
        # ALLOWS at this state". So after a PASS reap we assert BOTH the durable record (correct tree-id
        # + status=pass) AND that Get-ContinuousCoReviewSignoffGateDecision returns allow/fresh-and-covered.
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-for-pass-promotion'
            $cmd = script:New-DummyReviewerCommand   # non-blocking PASS

            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $firedTreeId = $fire.fired_tree_id
            $st = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire.fired_run_id
            $st.status | Should Be 'done'

            # REAP -> surfaces the PASS AND promotes it to durable evidence.
            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            ($reap.inject_notes -join "`n") | Should Match 'PASSED'
            $reap.stop_block | Should BeNullOrEmpty
            @($reap.promoted_run_ids).Count | Should Be 1
            $promotedId = @($reap.promoted_run_ids)[0]

            # The durable run record exists at the path the gate reader walks (inline/), with the fired
            # tree-id and status=pass.
            $runRecPath = Join-Path $root ".specrew/review/inline/$promotedId/review-run.json"
            Test-Path -LiteralPath $runRecPath | Should Be $true
            $rec = Get-Content -LiteralPath $runRecPath -Raw | ConvertFrom-Json
            $rec.reviewed_tree_id | Should Be $firedTreeId
            $rec.status | Should Be 'pass'
            $rec.reviewed_ref | Should Match '^[0-9a-f]{40}$'
            $rec.baseline_ref | Should Match '^[0-9a-f]{40}$'

            # THE REQUIREMENT: the signoff gate now ALLOWS this state (fresh + covered).
            $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -TrunkName 'main'
            $gate.decision | Should Be 'allow'
            $gate.reason | Should Be 'fresh-and-covered'
            $gate.matched_run_id | Should Be $promotedId
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'PART 2 (stub NOT promoted): the DEFAULT placeholder stub (no override) is advisory-only and does NOT promote — the gate stays unsatisfied' {
        # Closeout flag 2: the production path fires with NO ReviewerCommandOverride, so the default
        # Build-...ReviewerCommand stub (reviewer='stub') always emits pass WITHOUT reviewing. It must
        # NOT become gate evidence, else the governance gate is auto-satisfiable by plumbing.
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-for-stub-no-promote'
            # NO -ReviewerCommandOverride -> the default reviewer stub fires.
            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main'
            $fire.action | Should Be 'fired'
            $st = script:Wait-NavigatorRunTerminal -Root $root -RunId $fire.fired_run_id
            $st.status | Should Be 'done'

            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main'
            # Advisory only: NOT promoted, and the signoff gate stays unsatisfied (no evidence written).
            @($reap.promoted_run_ids).Count | Should Be 0
            ($reap.inject_notes -join "`n") | Should Match 'real reviewer is not wired'
            $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -TrunkName 'main'
            $gate.decision | Should Not Be 'allow'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'PART 2 (blocking NOT promoted): a reaped BLOCKING verdict writes NO durable runs record and the gate still BLOCKS' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-blocking-no-promote'
            $cmd = script:New-DummyReviewerCommand -Blocking

            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $firedRunId = $fire.fired_run_id
            $null = script:Wait-NavigatorRunTerminal -Root $root -RunId $firedRunId

            $reap = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            $reap.stop_block | Should Not BeNullOrEmpty   # a blocking verdict still surfaces
            @($reap.promoted_run_ids).Count | Should Be 0  # but is NOT promoted

            # No durable inline record was written for the fired run.
            $inlineDir = Join-Path $root '.specrew/review/inline'
            $hasRecord = $false
            if (Test-Path -LiteralPath $inlineDir -PathType Container) {
                foreach ($d in @(Get-ChildItem -LiteralPath $inlineDir -Directory -ErrorAction SilentlyContinue)) {
                    if (Test-Path -LiteralPath (Join-Path $d.FullName 'review-run.json') -PathType Leaf) { $hasRecord = $true; break }
                }
            }
            $hasRecord | Should Be $false

            # The signoff gate has no passing evidence -> it BLOCKS.
            $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -TrunkName 'main'
            $gate.decision | Should Be 'block'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'PART 2 PRODUCTION SCOPE: the PROVIDER child (loads only the navigator) reaps a PASS, promotes it, and the gate ALLOWS' {
        # The in-process Part-2 test pre-loads _load.ps1 (BeforeAll), so the promotion writer is already
        # defined and Add-...PassRunRecord's LAZY load path NEVER runs there. This test exercises the REAL
        # production load shape: the dispatcher-facing PROVIDER is spawned as a child pwsh that dot-sources
        # ONLY the navigator (NOT _load.ps1). If the lazy in-scope dot-source of _load.ps1 inside
        # Add-...PassRunRecord is wrong (e.g. a separate Initialize-deps helper whose scope dies on
        # return), the writer is undefined in the child, NO record is written, and the gate stays blocked.
        # So this is the test that actually guards the scope fix.
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-for-prod-promotion'
            $cmd = script:New-DummyReviewerCommand   # non-blocking PASS

            # FIRE in-process, then let the detached supervisor finish (verdict at result.out).
            $fire = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -TrunkName 'main' -ReviewerCommandOverride $cmd
            $fire.action | Should Be 'fired'
            $firedTreeId = $fire.fired_tree_id
            $firedRunId = $fire.fired_run_id
            $st = script:Wait-NavigatorRunTerminal -Root $root -RunId $firedRunId
            $st.status | Should Be 'done'

            # REAP + PROMOTE via the PROVIDER child (the production entry-point). cwd = the project; the
            # provider dedups (same tree-id, already fired) so it does NOT re-fire - it only reaps+promotes.
            $provider = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1'
            Push-Location $root
            try {
                $stdout = & pwsh -NoProfile -NonInteractive -File $provider --host-kind claude --source-event stop 2>$null
            }
            finally { Pop-Location }
            # A PASS surfaces as an inject note (no stop-block); the provider prints it.
            ([string]::Join("`n", @($stdout))) | Should Match 'PASSED'

            # The durable record was written BY THE CHILD (production scope) - the lazy load worked.
            $runRecPath = Join-Path $root ".specrew/review/inline/$firedRunId/review-run.json"
            Test-Path -LiteralPath $runRecPath | Should Be $true
            $rec = Get-Content -LiteralPath $runRecPath -Raw | ConvertFrom-Json
            $rec.reviewed_tree_id | Should Be $firedTreeId
            $rec.status | Should Be 'pass'

            # THE REQUIREMENT, end-to-end through the real provider: the signoff gate ALLOWS.
            $gate = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $root -TrunkName 'main'
            $gate.decision | Should Be 'allow'
            $gate.reason | Should Be 'fresh-and-covered'
            $gate.matched_run_id | Should Be $firedRunId
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FINDING 1 (supersede only when firing): a launcher-unavailable stop does NOT kill a prior running review' {
        # The supersede (Stop the prior running review) must run AFTER the launcher-availability check,
        # so a stop that CANNOT fire a replacement leaves the prior review intact (the old order killed
        # it then no-op'd - a strictly-worse state). Plant a live "running" entry (a sleeper as its
        # supervisor, future deadline), make a real checkpoint so execution reaches the launcher check,
        # remove Start-SpecrewIsolatedTask so firing is impossible, and assert the prior survives.
        # NOTE: this test removes Start-SpecrewIsolatedTask from the session function table; it runs LAST
        # so the (Pester-scope-fragile) restore is not load-bearing for any following fire test.
        $root = script:New-NavigatorProject -FileContent 'base'
        $sleeper = $null
        try {
            script:Add-NavigatorIncrement -Root $root -Content 'changed-needs-fire'   # a real checkpoint

            $sleeper = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'Start-Sleep -Seconds 60') -PassThru -WindowStyle Hidden
            $runId = 'prior-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            $regPath = Join-Path $pendingDir "$runId.json"
            ([ordered]@{
                    schema_version = '1.0'
                    run_id         = $runId
                    supervisor_pid = $sleeper.Id
                    worktree_path  = (Join-Path ([System.IO.Path]::GetTempPath()) ('nav-prior-wt-' + [guid]::NewGuid().ToString('N')))
                    run_dir        = (Join-Path $pendingDir $runId)
                    deadline       = ((Get-Date).ToUniversalTime().AddMinutes(10).ToString('o'))  # NOT past-deadline
                    status         = 'running'
                    tree_id        = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
                } | ConvertTo-Json) | Set-Content -LiteralPath $regPath -Encoding UTF8

            # Make firing impossible for this call.
            if (Get-Command Start-SpecrewIsolatedTask -ErrorAction SilentlyContinue) {
                Remove-Item Function:\Start-SpecrewIsolatedTask -ErrorAction SilentlyContinue
            }

            $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 -ReviewerCommandOverride (script:New-DummyReviewerCommand)
            $dec.action | Should Be 'no-op'
            $dec.reason | Should Be 'launcher-unavailable'
            # The prior running entry was NOT superseded (still on disk) and NOT reaped.
            Test-Path -LiteralPath $regPath | Should Be $true
            $dec.reaped_run_ids -contains $runId | Should Be $false
            # The sleeper (its supervisor) is untouched.
            $alive = $null
            try { $alive = Get-Process -Id $sleeper.Id -ErrorAction Stop } catch { $alive = $null }
            ($null -ne $alive) | Should Be $true
        }
        finally {
            if ($sleeper) { try { Stop-Process -Id $sleeper.Id -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # FINDING 3 lives in its OWN Context so its throw-Mock on Invoke-ContinuousCoReviewNavigatorReap is
    # torn down at the Context boundary (Pester 3.4 reliably clears mocks at Context exit; an It-scoped
    # mock on a script-scope function can otherwise leak into later It blocks). Keep this LAST.
    Context 'FINDING 3 outer fail-open (isolated mock)' {
        It 'an internal throw returns a no-op decision, NOT an exception (Set-StrictMode on inside)' {
            # The whole body is wrapped so the navigator NEVER throws to the dispatcher (fail-open is the
            # contract, independent of the loader). Force an internal throw (the reap) and assert a clean
            # no-op decision comes back with every field present.
            $root = script:New-NavigatorProject -FileContent 'base'
            try {
                Mock Invoke-ContinuousCoReviewNavigatorReap { throw 'simulated-internal-failure' }

                # Call directly (NOT inside a Should-Not-Throw scriptblock, whose child scope would
                # swallow the assignment) and capture both the result and any escaped exception.
                $dec = $null
                $threw = $false
                try { $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TimeoutSec 30 }
                catch { $threw = $true }

                $threw | Should Be $false   # the navigator must NOT throw to the caller
                $dec | Should Not BeNullOrEmpty
                $dec.action | Should Be 'no-op'
                $dec.reason | Should Match 'navigator-error'
                $dec.reason | Should Match 'simulated-internal-failure'
                # Shape preserved (no partial/strict-mode-broken object): the merged result fields exist.
                $dec.stop_block | Should BeNullOrEmpty
                @($dec.inject_notes).Count | Should Be 0
                $dec.fired_run_id | Should BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
