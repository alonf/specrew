$ErrorActionPreference = 'Stop'

# Trace: T063, NFR-001, INT-004, TG-013.
# Regression for the spawn-orphan/timeout fix (commit 3230e9e1): a reviewer child that STALLS
# without draining a large stdin payload must still be bounded by the timeout (the stdin write
# is deadline-bounded, not synchronous-unbounded) and its process tree killed (no orphan).
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T063 reviewer-spawn timeout bounds a stalled large-stdin child' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    It 'times out (not hangs) and leaves no orphan when the child never reads a large stdin' {
        $pidFile = Join-Path $TestDrive 'child.pid'
        # A child that records its PID then sleeps WITHOUT reading stdin, so a large stdin
        # payload fills the OS pipe buffer and the write would block unbounded without the fix.
        $childScript = Join-Path $TestDrive 'stall-child.ps1'
        @(
            '$pidPath = $env:CCR_T063_PIDFILE'
            'if ($pidPath) { Set-Content -LiteralPath $pidPath -Value $PID -Encoding ascii }'
            'Start-Sleep -Seconds 60'
        ) | Set-Content -LiteralPath $childScript -Encoding UTF8

        # ~1 MB stdin - larger than the OS pipe buffer, so a non-reading child blocks the write.
        $bigInput = Join-Path $TestDrive 'big-stdin.txt'
        Set-Content -LiteralPath $bigInput -Value ('x' * (1024 * 1024)) -Encoding ascii -NoNewline

        $env:CCR_T063_PIDFILE = $pidFile
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-ContinuousCoReviewAdapterProcess -Executable $childScript -StandardInputPath $bigInput -TimeoutSeconds 3
        $sw.Stop()
        Remove-Item env:CCR_T063_PIDFILE -ErrorAction SilentlyContinue

        # The configured timeout (3s) must fire long before the child's 60s sleep.
        $sw.Elapsed.TotalSeconds | Should -BeLessThan 40
        $result.timed_out | Should -Be $true

        # No orphan: the child process the spawn launched must be gone after the call.
        if (Test-Path -LiteralPath $pidFile) {
            $childPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
            if ($childPid -match '^\d+$') {
                $alive = $null
                try { $alive = Get-Process -Id ([int]$childPid) -ErrorAction Stop } catch { $alive = $null }
                $alive | Should -Be $null
            }
        }
    }

    It 'returns a clean result for a fast child that reads stdin and exits' {
        $childScript = Join-Path $TestDrive 'fast-child.ps1'
        @(
            '$null = [Console]::In.ReadToEnd()'
            '[Console]::Out.Write("{}")'
        ) | Set-Content -LiteralPath $childScript -Encoding UTF8
        $input = Join-Path $TestDrive 'small-stdin.txt'
        Set-Content -LiteralPath $input -Value 'hello' -Encoding UTF8

        $result = Invoke-ContinuousCoReviewAdapterProcess -Executable $childScript -StandardInputPath $input -TimeoutSeconds 30
        $result.timed_out | Should -Be $false
        $result.exit_code | Should -Be 0
        $result.stdout.Trim() | Should -Be '{}'
    }
}
