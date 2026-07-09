#requires -Version 7.0
# Co-review finding f2 regression (run 20260708T112353271): the non-Windows detached service spawn
# passed Start-Process -WindowStyle Hidden - a Windows-only parameter that throws NotSupported on
# Unix pwsh, so the WSL/Linux Stop-hook detached fire failed BEFORE the reviewer ever started. This
# test drives the REAL Unix branch of Start-ContinuousCoReviewServiceRun -Detached (Windows uses the
# Win32_Process.Create branch and skips here) and asserts the spawn itself succeeds.

BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $env:SPECREW_MODULE_PATH = $script:RepoRoot
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-service.ps1')
}

Describe 'f2: the Unix detached service spawn starts (no Windows-only parameters)' {

    It 'fires the detached entry on Unix and registers a running entry' -Skip:($IsWindows) {
        $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('f2unix-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        & git -C $repo init -q 2>&1 | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'content' -Encoding UTF8
        & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
        & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m seed 2>&1 | Out-Null
        try {
            $run = Start-ContinuousCoReviewServiceRun -RepoRoot $repo -TimeoutSeconds 30 -Detached
            $run.detached | Should -BeTrue
            $run.status | Should -Be 'running' -Because 'the spawn itself must succeed on Unix (the old -WindowStyle Hidden threw NotSupported here)'
            [int]$run.supervisor_pid | Should -BeGreaterThan 0
            Test-Path -LiteralPath (Join-Path $repo ".specrew/review/pending/$($run.run_id).json") | Should -BeTrue
        }
        finally {
            # Reap whatever the detached entry became (it will fail no-authorized-reviewer-host - fine;
            # the SPAWN is the subject here) and clean up.
            try {
                $regPath = Join-Path $repo ".specrew/review/pending/$($run.run_id).json"
                if (Test-Path -LiteralPath $regPath) {
                    . (Join-Path $script:RepoRoot 'scripts/internal/agent-tasks/isolated-task-launcher.ps1')
                    $null = Stop-SpecrewIsolatedTask -RegistryPath $regPath -Reason 'reaped'
                }
            }
            catch { $null = $_ }
            Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
