#requires -Version 7.0
# T096 / FR-038 (iter-009 D6/R6): the remediation menu - ONE surface for every review problem
# (timeout / partial / same-host / blocking / failed), carried via co-review-round-state.json:
#   1 more-time  2 different-host  3 narrow-scope (code|process|path:|function:)  4 accept-partial
#   5 override-block (DEGRADED runs only, D5).
# The choice is ONE-SHOT: consumed by the next run (which is never auto-ceiling-halted), the scoped
# rerun is honestly labelled partial (T094), accept-partial records the T094 first-class ack, and
# override-block refuses full+independent blocks.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')

    function script:New-TempGitRepo {
        $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('t096-repo-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'content' -Encoding UTF8
        & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
        & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m seed 2>&1 | Out-Null
        return $repo
    }
}

Describe 'T096 remediation choice carrier (round-state)' {

    It 'records, preserves across per-run rewrites, and consumes ONE-SHOT' {
        $repo = script:New-TempGitRepo
        try {
            $rem = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'more-time' -TimeoutSeconds 1234 -AuthorizedBy 'Alon'
            $rem.choice | Should -Be 'more-time'

            # A per-run Set- rewrite must PRESERVE the un-consumed choice.
            Set-ContinuousCoReviewRoundState -RepoRoot $repo -ChangedPaths @('a.ps1') -Round 1 -Blocking $false -Findings $null
            (Get-ContinuousCoReviewRoundState -RepoRoot $repo).remediation.choice | Should -Be 'more-time'

            # ONE-SHOT consume: first read returns it, second read gets nothing.
            $consumed = Read-ContinuousCoReviewRemediationChoice -RepoRoot $repo
            $consumed.choice | Should -Be 'more-time'
            [int]$consumed.timeout_seconds | Should -Be 1234
            Read-ContinuousCoReviewRemediationChoice -RepoRoot $repo | Should -BeNullOrEmpty
            # ...and the rest of the round-state survives the consume.
            (Get-ContinuousCoReviewRoundState -RepoRoot $repo).round | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'accept-partial records the T094 first-class ack immediately' {
        $repo = script:New-TempGitRepo
        try {
            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'accept-partial' -RunId 'run-x' -Reason 'partial findings are enough for this doc slice' -AuthorizedBy 'Alon'
            $ack = Get-ContinuousCoReviewDegradedAck -RepoRoot $repo -RunId 'run-x'
            $ack | Should -Not -BeNullOrEmpty
            $ack.authorized_by | Should -Be 'Alon'
            # accept-partial does NOT queue a rerun.
            Read-ContinuousCoReviewRemediationChoice -RepoRoot $repo | Should -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'override-block clears the sticky blocking round-state for a DEGRADED run and records the override' {
        $repo = script:New-TempGitRepo
        try {
            # A degraded (partial) terminal status for the run + a sticky blocking round-state.
            $runDir = Join-Path $repo '.specrew/review/pending/run-d'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            ([pscustomobject]@{ status = 'done'; completeness = 'partial'; reviewer_independence = 'independent' } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $runDir 'status.json') -Encoding UTF8
            Set-ContinuousCoReviewRoundState -RepoRoot $repo -ChangedPaths @('a.ps1') -Round 2 -Blocking $true -Findings '{}'

            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'override-block' -RunId 'run-d' -Reason 'low-confidence partial finding; shipping consciously' -AuthorizedBy 'Alon'

            (Get-ContinuousCoReviewRoundState -RepoRoot $repo).blocking | Should -BeFalse -Because 'the override unblocks the sticky loop (D5)'
            Test-Path -LiteralPath (Join-Path $repo '.specrew/review/inline/run-d/degraded-block-override.json') | Should -BeTrue -Because 'the override is RECORDED, never silent'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'override-block REFUSES a full+independent review''s block (D5: degraded only)' {
        $repo = script:New-TempGitRepo
        try {
            $runDir = Join-Path $repo '.specrew/review/pending/run-f'
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            ([pscustomobject]@{ status = 'done'; completeness = 'full'; reviewer_independence = 'independent' } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $runDir 'status.json') -Encoding UTF8

            { Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'override-block' -RunId 'run-f' -Reason 'nope' -AuthorizedBy 'Alon' } | Should -Throw -ExpectedMessage '*FULL INDEPENDENT*'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'T096 remediation application at the next run' {

    It 'applies more-time (budget) and different-host (selection), one-shot, visible in status.json' {
        $repo = script:New-TempGitRepo
        try {
            # more-time: the no-auth repo fails at host selection, but the applied budget is recorded.
            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'more-time' -TimeoutSeconds 1234 -AuthorizedBy 'Alon'
            $st1 = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r1') -RunId 't096-a' -TimeoutSeconds 30
            [int]$st1.timeout_seconds | Should -Be 1234 -Because 'more-time shapes the run budget'
            [string]$st1.remediation_applied | Should -Be 'more-time'
            Read-ContinuousCoReviewRemediationChoice -RepoRoot $repo | Should -BeNullOrEmpty -Because 'the choice is one-shot'

            # different-host: the requested host is honoured into selection (surfaced when unavailable).
            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'different-host' -HostName 'codex' -AuthorizedBy 'Alon'
            $st2 = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r2') -RunId 't096-b' -TimeoutSeconds 30
            [string]$st2.failure_reason | Should -Match '^requested-host-not-available.*codex' -Because 'the remediation host rides into the T093 honour-or-surface selection'
            [string]$st2.remediation_applied | Should -Be 'different-host'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'narrow-scope threads the human scope into the reviewer prompt and labels the run partial' {
        # Prompt rendering (the honoured scope instruction).
        $prompt = Get-ContinuousCoReviewSlimPrompt -RunId 'x' -HumanScope 'path:src/app.ps1'
        $prompt | Should -Match 'HUMAN-DIRECTED SCOPE'
        $prompt | Should -Match ([regex]::Escape('src/app.ps1'))

        $promptFn = Get-ContinuousCoReviewSlimPrompt -RunId 'x' -HumanScope 'function:Invoke-Thing'
        $promptFn | Should -Match 'Invoke-Thing'

        # Application: a scoped run is honestly PARTIAL + carries the scope in status.json - proven
        # end-to-end with a stubbed reviewer + stubbed host selection.
        $repo = script:New-TempGitRepo
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"t096-c","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'narrow-scope' -Scope 'path:app.txt' -AuthorizedBy 'Alon'
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r3') -RunId 't096-c' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done'
            [string]$st.human_scope | Should -Be 'path:app.txt'
            [string]$st.completeness | Should -Be 'partial' -Because 'a human-scoped review covers a subset - never silent full evidence'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a human-directed rerun is never auto-ceiling-halted' {
        $repo = script:New-TempGitRepo
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"t096-d","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            # Feature-branch shape so the run's baseline (merge-base with main) yields a REAL diff -
            # a repo that is its own trunk diffs empty and the lineage overlap can never fire.
            & git -C $repo branch -M main 2>&1 | Out-Null
            & git -C $repo checkout -q -b feature 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'changed by feature' -Encoding UTF8
            & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m feat 2>&1 | Out-Null
            # A sticky over-ceiling blocking lineage on the SAME path the run's diff produces.
            Set-ContinuousCoReviewRoundState -RepoRoot $repo -ChangedPaths @('app.txt') -Round 9 -Blocking $true -Findings '{"findings":[]}'

            # WITHOUT a remediation the run ceiling-halts...
            $halted = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r4') -RunId 't096-halt' -TimeoutSeconds 60
            [bool]$halted.ceiling_halted | Should -BeTrue

            # ...WITH one it proceeds (the menu is the ceiling's escape hatch).
            $null = Set-ContinuousCoReviewRemediationChoice -RepoRoot $repo -Choice 'more-time' -TimeoutSeconds 90 -AuthorizedBy 'Alon'
            Set-ContinuousCoReviewRoundState -RepoRoot $repo -ChangedPaths @('app.txt') -Round 9 -Blocking $true -Findings '{"findings":[]}'
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r5') -RunId 't096-d' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done'
            $stJson = [string]($st | ConvertTo-Json -Depth 8)
            $stJson | Should -Not -Match '"ceiling_halted"\s*:\s*true' -Because 'the human-directed rerun must not be auto-halted'
            $stJson | Should -Not -Match '"reviewed"\s*:\s*false' -Because 'the rerun actually reviewed (the stub ran)'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'T096 the reap surfaces ONE remediation menu on a problem run' {

    It 'emits the menu (all five options) for a timed-out run' {
        $repo = script:New-TempGitRepo
        try {
            $runId = 't096-menu'
            $pendingDir = Join-Path $repo '.specrew/review/pending'
            New-Item -ItemType Directory -Path $pendingDir -Force | Out-Null
            ([pscustomobject]@{ schema_version = '1.0'; run_id = $runId; status = 'timed-out'; result_path = $null; run_dir = (Join-Path $pendingDir $runId); tree_id = 'x' } |
                ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $pendingDir "$runId.json") -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $repo
            $notes = @($reap.inject_notes) -join ' || '
            $notes | Should -Match 'REMEDIATION MENU'
            $notes | Should -Match '--remediate more-time'
            $notes | Should -Match '--remediate different-host'
            $notes | Should -Match '--remediate narrow-scope'
            $notes | Should -Match '--remediate accept-partial'
            $notes | Should -Match '--remediate override-block'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does NOT emit the menu for a clean full+independent pass' {
        $repo = script:New-TempGitRepo
        try {
            $runId = 't096-clean'
            $runDir = Join-Path $repo ".specrew/review/pending/$runId"
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $resultPath = Join-Path $runDir 'result.out'
            Set-Content -LiteralPath $resultPath -Value '{"disposition":"needs-work","blocking":false,"summary":"minor nit"}' -Encoding UTF8
            ([pscustomobject]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; result_path = $resultPath; run_dir = $runDir; tree_id = 'x'; reviewer_independence = 'independent' } |
                ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $repo ".specrew/review/pending/$runId.json") -Encoding UTF8
            ([pscustomobject]@{ status = 'done'; completeness = 'full' } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $runDir 'status.json') -Encoding UTF8

            $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $repo
            $notes = @($reap.inject_notes) -join ' || '
            $notes | Should -Not -Match 'REMEDIATION MENU' -Because 'a healthy non-blocking review has no problem to remediate'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
