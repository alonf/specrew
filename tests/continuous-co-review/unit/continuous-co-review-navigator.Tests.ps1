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
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1')   # T019 piece 3: the fire entry (brings co-review-service + the lease)

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

    BeforeEach {
        # This suite owns the retained legacy navigator. Production HEAD is campaign-authoritative,
        # so legacy behavior must be selected by the fixture rather than inherited accidentally.
        # Individual campaign-suppression cases override this mock in their It scope.
        Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
            [pscustomobject]@{
                mode = 'legacy'; valid = $true; legacy_promotion_enabled = $true
                campaign_authority_enabled = $false; reason = 'authority-mode-legacy'
            }
        }
    }

    It 'campaign intake: a valid pre-feature workspace is an expected silent no-op' {
        $root = script:New-NavigatorProject -BoundaryType '' -FileContent 'base'
        try {
            Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
                [pscustomobject]@{ mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false; campaign_authority_enabled = $true; reason = 'authority-mode-campaign' }
            }
            Mock -CommandName Get-ReviewCampaignVerdictPacketDecision -MockWith { throw 'packet-gate-must-not-run' }

            $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $root
            $decision.action | Should -Be 'no-op'
            $decision.reason | Should -Be 'campaign-not-applicable:no-active-feature'
            $decision.stop_block | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Get-ReviewCampaignVerdictPacketDecision -Times 0 -Exactly
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'campaign intake: an active feature without an iteration is an expected silent no-op' {
        $root = script:New-NavigatorProject -BoundaryType '' -FileContent 'base'
        try {
            $featureRoot = Join-Path $root 'specs/001-demo'
            New-Item -ItemType Directory -Path $featureRoot -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
            '{ "feature_directory": "specs/001-demo" }' | Set-Content -LiteralPath (Join-Path $root '.specify/feature.json') -Encoding UTF8
            Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
                [pscustomobject]@{ mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false; campaign_authority_enabled = $true; reason = 'authority-mode-campaign' }
            }
            Mock -CommandName Get-ReviewCampaignVerdictPacketDecision -MockWith { throw 'packet-gate-must-not-run' }

            $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $root
            $decision.action | Should -Be 'no-op'
            $decision.reason | Should -Be 'campaign-not-applicable:no-active-iteration'
            $decision.stop_block | Should -BeNullOrEmpty
            Assert-MockCalled -CommandName Get-ReviewCampaignVerdictPacketDecision -Times 0 -Exactly
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'campaign intake: malformed active feature state still fails closed through the packet gate' {
        $root = script:New-NavigatorProject -BoundaryType '' -FileContent 'base'
        try {
            New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
            '{' | Set-Content -LiteralPath (Join-Path $root '.specify/feature.json') -Encoding UTF8
            Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
                [pscustomobject]@{ mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false; campaign_authority_enabled = $true; reason = 'authority-mode-campaign' }
            }

            $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $root
            $decision.reason | Should -Be 'campaign-packet-gate-failed'
            $decision.stop_block | Should -Match 'review-campaign-active-feature-unresolved'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'campaign intake: an advanced lifecycle cursor with a missing iteration still fails closed' {
        $root = script:New-NavigatorProject -BoundaryType 'before-implement' -FileContent 'base'
        try {
            $featureRoot = Join-Path $root 'specs/001-demo'
            New-Item -ItemType Directory -Path $featureRoot -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
            '{ "feature_directory": "specs/001-demo" }' | Set-Content -LiteralPath (Join-Path $root '.specify/feature.json') -Encoding UTF8
            Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
                [pscustomobject]@{ mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false; campaign_authority_enabled = $true; reason = 'authority-mode-campaign' }
            }

            $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $root
            $decision.reason | Should -Be 'campaign-packet-gate-failed'
            $decision.stop_block | Should -Match 'review-campaign-active-iteration-unresolved'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
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
            $winStyle = if ($IsWindows) { @{ WindowStyle = 'Hidden' } } else { @{} }   # -WindowStyle is Windows-only
            $deadProc = Start-Process pwsh -ArgumentList @('-NoProfile', '-NonInteractive', '-Command', 'exit 0') -PassThru @winStyle
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

    # T019 step 6 (DRIFT-198-I003-002 root cause): the stale-verdict downgrade at reap time read the registry's
    # `reviewed_tree_id` - a key the live worktree fire path NEVER writes (it writes reviewed_digest_tree_id +
    # tree_id) - so the digest-match-before-blocking was silently skipped and a blocking verdict on an ALREADY-
    # SUPERSEDED tree recurred as a fresh stop-block. These plant a terminal 'done' blocking registry (the
    # live-path spelling, reviewed_digest_tree_id) and assert the fix: a stale tree downgrades to ADVISORY, the
    # current tree still stop-blocks. Before the fix (Get-...RegistryTreeId), the stale case wrongly stop-blocked.
    It 'T019 step 6 (DRIFT-002 root): a done blocking verdict on a STALE tree (reviewed_digest_tree_id != current) surfaces as ADVISORY, not a stop-block' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "dummy blocking finding", "disposition": "blocking" } ] }'
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $currentDigest | Should -Not -BeNullOrEmpty
            $runId = 'stale-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = ('0' * 40) } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -BeNullOrEmpty -Because 'a blocking verdict on a stale tree must NOT be a fresh stop-block'
            (@($reap.inject_notes) -join "`n") | Should -Match 'reviewed an OLDER tree' -Because 'the DRIFT-002 downgrade now fires because the resolver reads the reviewed_digest_tree_id the fire path actually writes'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'T019 step 6 control: a done blocking verdict on the CURRENT tree IS a stop-block (the downgrade does not over-suppress)' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "dummy blocking finding", "disposition": "blocking" } ] }'
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $runId = 'current-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = $currentDigest } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -Not -BeNullOrEmpty -Because 'a blocking verdict at the CURRENT digest is a real stop-block, not downgraded'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'T041 cutover: a legacy terminal result stays advisory when campaign authority is active' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
                [pscustomobject]@{
                    mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false
                    campaign_authority_enabled = $true; reason = 'authority-mode-campaign'
                }
            }
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "legacy finding", "disposition": "blocking" } ] }'
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $runId = 'legacy-after-cutover'
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = $currentDigest } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -BeNullOrEmpty
            (@($reap.inject_notes) -join "`n") | Should -Match 'legacy authority disabled'
            Test-Path -LiteralPath (Join-Path $root ".specrew/review/inline/$runId/review-run.json") | Should -BeFalse -Because 'legacy evidence must not be promoted after campaign cutover'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # T019 step 6 (resolver HARDENING, maintainer 2026-07-13): prefer the EXPLICIT reviewed ids
    # (reviewed_digest_tree_id, then reviewed_tree_id); use the generic tree_id ONLY as a legacy fallback when
    # neither explicit id exists; and if the two explicit ids DISAGREE, fail closed with a named conflict so no
    # caller blocks, promotes, or stamps findings using either value.
    It 'T019 step 6 resolver: precedence (explicit ids first, tree_id legacy-only) + fail-closed conflict' {
        # agreeing explicit ids (a differing legacy tree_id is ignored, no conflict).
        $agree = Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ reviewed_digest_tree_id = 'aaa'; reviewed_tree_id = 'aaa'; tree_id = 'zzz' })
        $agree.conflict | Should -BeFalse
        $agree.tree_id | Should -Be 'aaa'
        # reviewed_digest_tree_id preferred over a differing tree_id (tree_id is NOT an explicit id -> no conflict).
        $pref = Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ reviewed_digest_tree_id = 'aaa'; tree_id = 'zzz' })
        $pref.conflict | Should -BeFalse; $pref.tree_id | Should -Be 'aaa'
        # reviewed_tree_id alone (explicit).
        (Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ reviewed_tree_id = 'bbb' })).tree_id | Should -Be 'bbb'
        # LEGACY: tree_id only (neither explicit) -> legacy fallback.
        (Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ tree_id = 'ccc' })).tree_id | Should -Be 'ccc'
        # CONFLICT: two populated EXPLICIT ids disagree -> fail closed, named conflict, no usable value.
        $conflict = Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ reviewed_digest_tree_id = 'aaa'; reviewed_tree_id = 'bbb' })
        $conflict.conflict | Should -BeTrue
        $conflict.tree_id | Should -BeNullOrEmpty
        $conflict.reason | Should -Match 'reviewed-tree-identity-conflict'
        # none present.
        (Get-ContinuousCoReviewNavigatorRegistryTreeId -Registry ([pscustomobject]@{ run_id = 'x' })).tree_id | Should -BeNullOrEmpty
    }

    It 'T019 step 6 (resolver hardening): a done blocking verdict with CONFLICTING reviewed-tree ids fails closed - no stop-block, a named conflict note' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "dummy", "disposition": "blocking" } ] }'
            $runId = 'conflict-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = ('a' * 40); reviewed_tree_id = ('b' * 40) } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -BeNullOrEmpty -Because 'an ambiguous reviewed-tree identity must NOT block using either value'
            (@($reap.inject_notes) -join "`n") | Should -Match 'reviewed-tree-identity-conflict' -Because 'the conflict is surfaced for a human to reconcile'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # T019 step 6 piece 2c: the reap enforces LEASE authority (verdict authority is not ownership alone) - a
    # completion that is not the current lease OWNER for its generation is advisory only; and the OWNER's terminal
    # retirement RELEASES its lease so the queued pending tree becomes eligible.
    It 'T019 step 6 piece 2c: a NON-OWNER completion is advisory only (not blocked), with a lease-authority note' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $lineage = 'L-nonowner'
            # An in-flight review 'incumbent' OWNS the lease for this lineage + generation (= the current tree).
            (Request-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage -Generation $currentDigest -RunId 'incumbent' -AcquiringPid $PID).acquired | Should -BeTrue
            # A DIFFERENT run completes (blocking) for the same lineage + current digest, but is NOT the lease owner.
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "dummy", "disposition": "blocking" } ] }'
            $runId = 'other-run'
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = $currentDigest; lineage_id = $lineage; generation = $currentDigest; owner_token = 'other-token' } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -BeNullOrEmpty -Because 'a non-lease-owner completion must NOT block using its result'
            (@($reap.inject_notes) -join "`n") | Should -Match 'lease authority' -Because 'the non-owner completion is surfaced as advisory'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a completion whose registry LOST its owner token is advisory only even when its run_id matches the lease - a missing token is not a wildcard (review finding f4, run 20260714T172315119)' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $lineage = 'L-tokenless'
            # The lease is owned by run 'incumbent'. The completing registry NAMES that same run_id but carries
            # NO owner_token (legacy/corrupt registry, or a forger who learned the run id) - previously the
            # empty token was a WILDCARD and this completion could block/promote as the owner.
            (Request-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage -Generation $currentDigest -RunId 'incumbent' -AcquiringPid $PID).acquired | Should -BeTrue
            $blockingVerdict = '{ "schema_version": "1.0", "status": "findings", "disposition": "reject", "blocking": true, "findings": [ { "id": "F1", "severity": "blocking", "location": "src/app.txt", "comment": "dummy", "disposition": "blocking" } ] }'
            $runId = 'incumbent'
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $blockingVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = $currentDigest; lineage_id = $lineage; generation = $currentDigest } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            $reap.stop_block | Should -BeNullOrEmpty -Because 'a token-less completion must NOT block: run-id knowledge alone is not lease ownership'
            (@($reap.inject_notes) -join "`n") | Should -Match 'lease authority' -Because 'the token-less completion is surfaced as advisory'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the blackboard findings-result carrying the reviewed_tree_id stamp VALIDATES against the shipped FindingsResult schema; unknown fields still reject (review finding f6, run 20260714T215545754)' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $schemaRoot = Get-ContinuousCoReviewContractRoot -RepoRoot $script:RepoRoot
            $treeId = ('a' * 40)
            $findings = [pscustomobject]@{
                schema_version   = '1.0'; run_id = 'schema-stamp-run'; status = 'no_findings'; findings = @()
                created_at       = '2026-07-15T00:00:00Z'
                reviewed_tree_id = $treeId
            }
            # the stamped object is SANCTIONED by the evolved schema...
            { Assert-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $schemaRoot -InputObject $findings } | Should -Not -Throw
            # ...while the schema stays CLOSED: an unknown field still rejects.
            $smuggled = [pscustomobject]@{
                schema_version = '1.0'; run_id = 'x'; status = 'no_findings'; findings = @(); created_at = '2026-07-15T00:00:00Z'; smuggled_field = 1
            }
            { Assert-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $schemaRoot -InputObject $smuggled } | Should -Throw
            # PRODUCTION-PATH: the VALIDATED blackboard write persists, and the exact persisted object
            # round-trips through the shipped schema.
            Write-ContinuousCoReviewBlackboardThread -RepoRoot $root -CheckpointId 'nav-schema-stamp-run' -FindingsResult $findings -SchemaRoot $schemaRoot | Out-Null
            $persisted = Get-Content -LiteralPath (Join-Path $root '.specrew/review/inline/schema-stamp-run/findings-result.json') -Raw | ConvertFrom-Json
            [string]$persisted.reviewed_tree_id | Should -Be $treeId
            { Assert-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $schemaRoot -InputObject $persisted } | Should -Not -Throw
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'T019 step 6 piece 2c: the OWNER completion RELEASES its lease on retirement' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $currentDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
            $lineage = 'L-owner'
            $acq = Request-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage -Generation $currentDigest -RunId 'owner-run' -AcquiringPid $PID
            $acq.acquired | Should -BeTrue
            (Get-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage) | Should -Not -BeNullOrEmpty
            $passVerdict = '{ "schema_version": "1.0", "status": "no_findings", "disposition": "pass", "blocking": false, "findings": [] }'
            $runId = 'owner-run'
            $pendingDir = Join-Path $root '.specrew/review/pending'
            $runDir = Join-Path $pendingDir $runId
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value $passVerdict -Encoding UTF8
            ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; reviewed_digest_tree_id = $currentDigest; lineage_id = $lineage; generation = $currentDigest; owner_token = $acq.lease.owner_token } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $null = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $root
            (Get-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage) | Should -BeNullOrEmpty -Because 'the owner completion released the lease on retirement (feeding any pending tree forward)'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # T019 piece 3: the navigator FIRE decision consumes the per-lineage LEASE as the SINGLE in-flight dedup
    # source (not a second competing mechanism). A lineage already under review by an in-flight owner is
    # SUPPRESSED at the lease acquire before any reviewer spawns; the fire must record deduped-by-lease and must
    # NOT advance last_fired_tree_id (else a queued newer tree would be treated as already-fired and never reviewed).
    It 'T019 piece 3: a lineage already under review is deduped-by-lease at fire (no spawn, last_fired_tree_id unchanged)' {
        $root = script:New-NavigatorProject -FileContent 'base'
        try {
            $treeId = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $root
            $treeId | Should -Not -BeNullOrEmpty
            $lineage = Resolve-ContinuousCoReviewRepoLineageId -RepoRoot $root
            # An in-flight review already OWNS the lease for this lineage + generation (= the current tree). This is
            # the DRIFT-198-I003-002 collision class (a concurrent manual --live) that last_fired_tree_id misses.
            (Request-ContinuousCoReviewLineageLease -RepoRoot $root -LineageId $lineage -Generation $treeId -RunId 'incumbent' -AcquiringPid $PID).acquired | Should -BeTrue

            $decision = Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $root
            $decision.action | Should -Be 'no-op' -Because 'a lineage already under review must not spawn a second reviewer'
            $decision.reason | Should -Match 'deduped-by-lease'
            [string](Get-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $root) | Should -BeNullOrEmpty -Because 'a suppressed acquire must NOT advance last_fired_tree_id'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
