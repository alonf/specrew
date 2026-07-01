# P-145 step 1 — the orchestrator PRODUCES and THREADS a non-empty digest through to the gate. The step-1 unit test
# hand-feeds the gate a digest it computed in the test shell; it never runs the NEW producer code (the orchestrator
# computing the digest at its start, writing status.json, the inline return carrying it). That gap is exactly how a
# detached-path regression slipped earlier (verified-by-reading, broken-in-scope). This test runs the WHOLE
# orchestrator for real with ONLY the slow agentic reviewer stubbed, then asserts the threaded digest is non-empty,
# equals the gate's digest, and promotes to a fresh decision.

BeforeAll {
    $script:ccr = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review')).Path
    # Load ONLY co-review-service (navigator + orchestrator). Do NOT globally load _load: the orchestrator's digest
    # lazy-load must resolve Get-...ReviewedStateDigest itself, replicating the real detached-entry scope.
    . (Join-Path $script:ccr 'co-review-service.ps1')

    function New-ThreadFx {
        $fx = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-thread-' + [System.Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $fx '.specrew') -Force | Out-Null
        Push-Location $fx
        try {
            git init -b main -q
            git -c user.email=t@t -c user.name=t commit --allow-empty -q -m base
            git checkout -q -b feature
            'code' | Set-Content (Join-Path $fx 'app.txt')
            git add app.txt
            git -c user.email=t@t -c user.name=t commit -q -m feature
        }
        finally { Pop-Location }
        # authorize an independent reviewer (claude), in the hosts[] catalog schema the navigator reads
        '{"schema_version":"1.0","hosts":[{"host":"claude","model":"opus","adapter_id":"reviewer-host-adapter-claude-prompt","allowed":true,"installed":true,"review_class_rank":85,"model_source":"human-entered","cost_class":"non-default","authorization_ref":"test","fallback_allowed":false}]}' | Set-Content (Join-Path $fx '.specrew\reviewer-hosts.json')
        return $fx
    }
}

Describe 'the orchestrator produces + threads a non-empty digest (real detached-path code, reviewer stubbed)' {
    It 'a full stubbed run threads a non-empty digest that equals the gate digest and promotes to allow' {
        $fx = New-ThreadFx
        # Stub the slow agentic reviewer -> the WHOLE orchestrator runs real (materialize + DIGEST + status + return).
        Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
            param($WorktreePath, $RunId, $HostName, $RoundNumber, $MaxRounds, $PriorFindings, $TimeoutSeconds, $Heartbeat)
            if ($Heartbeat) {
                & $Heartbeat ([pscustomobject][ordered]@{
                        reviewer_host    = $HostName
                        command_file     = 'stub-reviewer'
                        command_args     = @('--stub')
                        prompt_via_stdin = $true
                        timeout_seconds  = $TimeoutSeconds
                        started_at       = '2026-06-27T00:00:00Z'
                        updated_at       = '2026-06-27T00:00:00Z'
                        elapsed_seconds  = 0.5
                        running          = $true
                        timed_out        = $false
                    })
            }
            [pscustomobject]@{
                exit_code = 0
                stdout    = '{"schema_version":"1.0","run_id":"r","status":"no_findings","findings":[]}'
                stderr    = ''
                telemetry = [pscustomobject][ordered]@{
                    reviewer_host    = $HostName
                    command_file     = 'stub-reviewer'
                    command_args     = @('--stub')
                    prompt_via_stdin = $true
                    timeout_seconds  = $TimeoutSeconds
                    started_at       = '2026-06-27T00:00:00Z'
                    updated_at       = '2026-06-27T00:00:01Z'
                    elapsed_seconds  = 1.0
                    running          = $false
                    timed_out        = $false
                }
            }
        }
        try {
            $run = Start-ContinuousCoReviewServiceRun -RepoRoot $fx -RunId 'thread1' -CodeWriterHost 'copilot'
            $run.status | Should -Be 'done'
            $run.reviewed_digest_tree_id | Should -Not -BeNullOrEmpty
            $run.elapsed_seconds | Should -Not -BeNullOrEmpty
            $run.timeout_seconds | Should -Be 900
            $status = Get-Content (Join-Path $run.run_dir 'status.json') -Raw | ConvertFrom-Json
            $status.reviewed_digest_tree_id | Should -Not -BeNullOrEmpty
            $status.started_at | Should -Not -BeNullOrEmpty
            $status.updated_at | Should -Not -BeNullOrEmpty
            $status.elapsed_seconds | Should -Not -BeNullOrEmpty
            $status.timeout_seconds | Should -Be 900
            $status.soft_budget_seconds | Should -BeGreaterThan 0
            $status.budget_policy | Should -Match 'implementer validation evidence'
            $status.artifacts.run_dir | Should -Be $run.run_dir
            $status.artifacts.result_out | Should -Be (Join-Path $run.run_dir 'result.out')
            $status.phase_durations_seconds.'reviewer-execution' | Should -Not -BeNullOrEmpty
            $status.reviewer_telemetry.command_file | Should -Be 'stub-reviewer'
            $status.reviewer_telemetry.elapsed_seconds | Should -Be 1.0

            # the threaded digest MUST equal what the gate computes (load _load now, for the gate + digest)
            . (Join-Path $script:ccr '_load.ps1')
            $gateDigest = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $fx).tree_id
            $status.reviewed_digest_tree_id | Should -Be $gateDigest

            # and promoting it yields a FRESH gate decision (the whole chain: produce -> thread -> promote -> accept)
            $null = Add-ContinuousCoReviewNavigatorPassRunRecord -RepoRoot $fx -RunId $run.run_id -TreeId $status.reviewed_digest_tree_id -TrunkName 'main' -Now ([datetime]::UtcNow)
            (Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $fx -TrunkName 'main').decision | Should -Be 'allow'
        }
        finally {
            Remove-Item function:global:Invoke-ContinuousCoReviewWorktreeReviewer -ErrorAction SilentlyContinue
        }
    }
}
