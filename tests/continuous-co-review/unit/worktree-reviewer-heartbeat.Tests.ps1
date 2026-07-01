$ErrorActionPreference = 'Stop'

Describe 'worktree reviewer heartbeat telemetry' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:PwshPath = (Get-Process -Id $PID).Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'emits running telemetry while the reviewer process is still executing' {
        $worktree = Join-Path $TestDrive 'review-worktree'
        New-Item -ItemType Directory -Path $worktree -Force | Out-Null

        Mock -CommandName Get-ContinuousCoReviewAgentCommand -MockWith {
            [pscustomobject]@{
                file             = $script:PwshPath
                pre_args         = @('-NoProfile', '-Command', "Start-Sleep -Seconds 6; Write-Output 'DONE'")
                prompt_via_stdin = $true
            }
        }

        $heartbeats = [System.Collections.Generic.List[object]]::new()
        $result = Invoke-ContinuousCoReviewAgentInWorktree `
            -WorktreePath $worktree `
            -Prompt 'ignored by synthetic reviewer' `
            -HostName 'stub' `
            -TimeoutSeconds 12 `
            -Heartbeat { param($Telemetry) [void]$heartbeats.Add($Telemetry) }

        $heartbeats.Count | Should -BeGreaterThan 0
        $heartbeats[0].reviewer_host | Should -Be 'stub'
        $heartbeats[0].running | Should -BeTrue
        $heartbeats[0].timed_out | Should -BeFalse
        $heartbeats[0].elapsed_seconds | Should -BeGreaterOrEqual 4.5
        $result.exit_code | Should -Be 0
        $result.stdout.Trim() | Should -Be 'DONE'
        $result.telemetry.running | Should -BeFalse
        $result.telemetry.timed_out | Should -BeFalse
        $result.telemetry.elapsed_seconds | Should -BeGreaterOrEqual 6
    }
}
