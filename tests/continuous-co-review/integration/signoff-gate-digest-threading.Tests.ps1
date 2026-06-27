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
        function global:Invoke-ContinuousCoReviewWorktreeReviewer { param($WorktreePath, $RunId, $HostName, $RoundNumber, $MaxRounds, $PriorFindings, $TimeoutSeconds) [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"r","status":"no_findings","findings":[]}'; stderr = '' } }
        try {
            $run = Start-ContinuousCoReviewServiceRun -RepoRoot $fx -RunId 'thread1' -CodeWriterHost 'copilot'
            $run.status | Should -Be 'done'
            $run.reviewed_digest_tree_id | Should -Not -BeNullOrEmpty
            $status = Get-Content (Join-Path $run.run_dir 'status.json') -Raw | ConvertFrom-Json
            $status.reviewed_digest_tree_id | Should -Not -BeNullOrEmpty

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
