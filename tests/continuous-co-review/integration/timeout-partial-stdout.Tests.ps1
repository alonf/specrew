#requires -Version 7.0
# BLOCKING co-review finding (T090/R1): on a reviewer TIMEOUT, Invoke-ContinuousCoReviewAgentInWorktree must
# return the stdout it captured BEFORE the kill (not '') so the prose-salvage floor has the in-pipe reasoning to
# fall back on. The old timeout branch returned stdout='' and dropped $outTask, so salvage was INERT on the exact
# failure (timeout) the iteration was built for. partial-harvest.Tests.ps1 masked this by feeding RawStdout to the
# harvest function directly; this test drives the REAL path: spawn -> async read -> timeout -> tree-kill -> harvest.

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review' 'worktree-reviewer.ps1')
}

Describe 'Invoke-ContinuousCoReviewAgentInWorktree timeout harvests pre-kill stdout (T090/R1)' {

    It 'returns the reviewer output captured before the kill (not empty) on a timeout' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-timeout-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            # A fake reviewer: write a line straight to stdout + flush, THEN sleep well past the timeout, so the
            # function must kill it and harvest the already-flushed stdout from $outTask.
            $fakeScript = "[Console]::Out.WriteLine('PARTIAL-REASONING-BEFORE-TIMEOUT'); [Console]::Out.Flush(); Start-Sleep -Seconds 30"
            $pwshPath = (Get-Process -Id $PID).Path
            # prompt_via_stdin = $true (like the claude host) so $Prompt is written to stdin, NOT appended as a
            # positional arg that would corrupt the fake -Command script.
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $pwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $fakeScript); prompt_via_stdin = $true }
            }

            $start = [datetime]::UtcNow
            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'review this' -HostName 'claude' -TimeoutSeconds 3
            $elapsed = ([datetime]::UtcNow - $start).TotalSeconds

            $r.stderr | Should -Be 'timeout' -Because 'the run timed out'
            $r.stdout | Should -Match 'PARTIAL-REASONING-BEFORE-TIMEOUT' -Because 'the pre-kill reviewer output must be harvested for prose-salvage, not dropped'
            $elapsed | Should -BeLessThan 20 -Because 'it was killed near the 3s timeout (+ grace + harvest), not allowed to run the 30s sleep'
        }
        finally {
            Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
