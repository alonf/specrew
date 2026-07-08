#requires -Version 7.0
# T108 / FR-033 (D-197-I009-015): retry ONCE on an EMPTY exit-0 reviewer result before the run can be
# declared no-parseable-findings. Host-GENERIC (the field failure was codex-observed, but any host can
# drop its final blob; the core names no harness). The diagnostic distinguishes a finalization/capture
# gap (incremental findings present, stdout lost) from a produced-nothing run. NEVER-FALSE-GREEN holds:
# a still-empty retry stays empty and the orchestrator fails the run loudly.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    $script:FindingsJson = '{"schema_version":"1.0","run_id":"t108","status":"findings","findings":[]}'
}

Describe 'T108 empty-exit0 retry-once at the reviewer invocation seam' {

    It 'retries once and recovers when the second attempt produces the result' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('t108a-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        $flag = Join-Path $wt 'first-attempt.flag'
        try {
            # Stateful fake: attempt 1 -> exit 0 with NO output; attempt 2 -> the findings JSON.
            $fakeScript = "if (-not (Test-Path -LiteralPath '$($flag -replace "'","''")')) { Set-Content -LiteralPath '$($flag -replace "'","''")' -Value 'x'; exit 0 } [Console]::Out.Write('$($script:FindingsJson -replace "'","''")')"
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt -RunId 't108' -HostName 'stub' -TimeoutSeconds 30
            $r.stdout | Should -Match '"run_id":"t108"' -Because 'the retry recovered the result'
            $r.telemetry.empty_result_retry.retried | Should -BeTrue
            $r.telemetry.empty_result_retry.first_attempt.probable_cause | Should -Be 'no-output-produced'
            $r.telemetry.empty_result_retry.retry_still_empty | Should -BeFalse
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a still-empty retry stays empty (never-false-green: the orchestrator then fails the run loudly)' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('t108b-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            $fakeScript = 'exit 0'
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt -RunId 't108' -HostName 'stub' -TimeoutSeconds 30
            [string]::IsNullOrWhiteSpace([string]$r.stdout) | Should -BeTrue -Because 'the retry must never fabricate a result'
            $r.telemetry.empty_result_retry.retried | Should -BeTrue
            $r.telemetry.empty_result_retry.retry_still_empty | Should -BeTrue
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'diagnoses a finalization/capture gap when incremental findings exist but stdout was empty' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('t108c-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        $flag = Join-Path $wt 'first-attempt.flag'
        try {
            # Attempt 1: writes .review/findings.jsonl (the reviewer DID work) but emits nothing.
            $fakeScript = "if (-not (Test-Path -LiteralPath '$($flag -replace "'","''")')) { Set-Content -LiteralPath '$($flag -replace "'","''")' -Value 'x'; New-Item -ItemType Directory -Path (Join-Path `$PWD.Path '.review') -Force | Out-Null; Set-Content -LiteralPath (Join-Path `$PWD.Path '.review/findings.jsonl') -Value '{}'; exit 0 } [Console]::Out.Write('$($script:FindingsJson -replace "'","''")')"
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt -RunId 't108' -HostName 'stub' -TimeoutSeconds 30
            $r.telemetry.empty_result_retry.first_attempt.incremental_findings_present | Should -BeTrue
            $r.telemetry.empty_result_retry.first_attempt.probable_cause | Should -Be 'finalization-or-capture-gap'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does NOT retry a non-empty result (single spawn, no retry telemetry)' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('t108d-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        $countFile = Join-Path $wt 'spawn-count.txt'
        try {
            $fakeScript = "Add-Content -LiteralPath '$($countFile -replace "'","''")' -Value 'spawn'; [Console]::Out.Write('$($script:FindingsJson -replace "'","''")')"
            $pwshPath = (Get-Process -Id $PID).Path
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt -RunId 't108' -HostName 'stub' -TimeoutSeconds 30
            $r.stdout | Should -Match '"run_id":"t108"'
            @(Get-Content -LiteralPath $countFile).Count | Should -Be 1 -Because 'a healthy result must not be re-run'
            ($r.telemetry.PSObject.Properties.Name -contains 'empty_result_retry') | Should -BeFalse
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
