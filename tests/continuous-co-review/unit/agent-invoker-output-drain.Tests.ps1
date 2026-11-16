#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# Feature 203 T017 (DRIFT-014, DRIFT-016): Invoke-ContinuousCoReviewAgentInWorktree starts ReadToEndAsync on the
# child's stdout and stderr, waits for the process to exit, and then took each stream only if its read task had
# ALREADY completed - without waiting for it. A child that exits while its last output is still in the pipe returned
# exit code 0 with an EMPTY stdout: the "empty-exit0" shape behind the flaky reviewer-hook-suppression case 1 and
# empty-result-retry.Tests.ps1:29, and, on the legacy review path, a lost reviewer result. These cases use a real
# child process (an executable fixture, not a mock of the reader) that writes more than a pipe buffer and exits at
# once, so the read is still in flight when the exit is observed.
Describe 'the agent invoker returns everything an exited child wrote (T017)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        # Several pipe buffers' worth, so the child is still writing until just before it exits.
        $script:PayloadChars = 4MB
        $script:PwshPath = (Get-Process -Id $PID).Path
    }

    It 'waits for output still in the pipe when the child exits 0 before its last write lands (deterministic)' {
        # The child starts a grandchild that inherits its stdout (no redirect, so .NET hands down the parent's
        # handles), writes EARLY and exits 0 at once. The grandchild writes LATE about 1.5 s later and only then
        # closes the pipe. The read cannot finish before that, so a caller that takes stdout at exit without
        # waiting returns it empty - the race, made deterministic with real processes and no mock of the reader.
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('drain-late-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            $grandchild = "Start-Sleep -Milliseconds 1500; [Console]::Out.Write('LATE')"
            $psiLines = @(
                '$p = [System.Diagnostics.ProcessStartInfo]::new(''' + ($script:PwshPath -replace "'", "''") + ''')'
                '$p.UseShellExecute = $false'
                '[void]$p.ArgumentList.Add(''-NoProfile''); [void]$p.ArgumentList.Add(''-NonInteractive''); [void]$p.ArgumentList.Add(''-Command'')'
                '[void]$p.ArgumentList.Add(''' + ($grandchild -replace "'", "''") + ''')'
                '[void][System.Diagnostics.Process]::Start($p)'
                '[Console]::Out.Write(''EARLY''); [Console]::Out.Flush(); exit 0'
            )
            $script:ChildScript = $psiLines -join '; '
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $script:PwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $script:ChildScript); prompt_via_stdin = $true }
            }
            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'ignored-by-the-stub' -HostName 'stub' -TimeoutSeconds 60
            [int]$r.exit_code | Should -Be 0
            [string]$r.stdout | Should -Be 'EARLYLATE' -Because 'output still being read when the child exits must be waited for, not returned as empty'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'returns the whole stdout of a child that writes several MB and exits 0 at once' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('drain-out-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            $script:ChildScript = "[Console]::Out.Write(('x' * $($script:PayloadChars)) + 'END-OF-STDOUT'); exit 0"
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $script:PwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $script:ChildScript); prompt_via_stdin = $true }
            }
            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'ignored-by-the-stub' -HostName 'stub' -TimeoutSeconds 60
            [int]$r.exit_code | Should -Be 0
            ([string]$r.stdout).Length | Should -Be ($script:PayloadChars + 'END-OF-STDOUT'.Length) -Because 'an exited child''s output still in the pipe must be read, not dropped as empty'
            [string]$r.stdout | Should -Match 'END-OF-STDOUT$'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'returns the whole stderr of a child that writes several MB to stderr and exits 0 at once' {
        $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('drain-err-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $wt -Force | Out-Null
        try {
            $script:ChildScript = "[Console]::Error.Write(('y' * $($script:PayloadChars)) + 'END-OF-STDERR'); [Console]::Out.Write('ok'); exit 0"
            Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
                [pscustomobject]@{ file = $script:PwshPath; pre_args = @('-NoProfile', '-NonInteractive', '-Command', $script:ChildScript); prompt_via_stdin = $true }
            }
            $r = Invoke-ContinuousCoReviewAgentInWorktree -WorktreePath $wt -Prompt 'ignored-by-the-stub' -HostName 'stub' -TimeoutSeconds 60
            [int]$r.exit_code | Should -Be 0
            [string]$r.stdout | Should -Be 'ok'
            ([string]$r.stderr).Length | Should -Be ($script:PayloadChars + 'END-OF-STDERR'.Length) -Because 'stderr is drained the same way as stdout'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
