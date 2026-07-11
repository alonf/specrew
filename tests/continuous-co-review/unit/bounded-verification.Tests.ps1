#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FR-010 (203 W3) — reviewer BOUNDED in-worktree verification (F-198 iteration 003, T015):
# the reviewer runs ONLY declared verification commands, each with a timeout + process containment,
# a UTF-8 BYTE output cap, and pre/post mutation evidence (add/delete/modify all count; a new file is
# exempt only via an explicit output-path allowlist). Paired coverage across every constraint.
Describe 'reviewer bounded in-worktree verification (FR-010)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')

        function script:New-Worktree {
            $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('bv-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $wt -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wt 'app.txt') -Value 'original source' -Encoding UTF8 -NoNewline
            return $wt
        }
    }

    It 'runs a declared command, captures its result, and records NO mutation on a read-only run' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Write-Output "verified ok"; exit 0') -TimeoutSeconds 30)
            $r.Count | Should -Be 1
            $r[0].exit_code | Should -Be 0
            $r[0].timed_out | Should -Be $false
            $r[0].output | Should -Match 'verified ok'
            $r[0].source_mutated | Should -Be $false
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ENFORCES the timeout: a hung command is killed and marked timed_out' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Start-Sleep -Seconds 60') -TimeoutSeconds 2)
            $r[0].timed_out | Should -Be $true
            $r[0].exit_code | Should -Be $null
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'kills the ENTIRE process tree on timeout (a spawned child is reaped)' {
        $wt = script:New-Worktree
        $pidFile = Join-Path $wt 'grandchild.pid'
        try {
            $esc = $pidFile -replace "'", "''"
            $cmd = "`$p = Start-Process pwsh -ArgumentList '-NoProfile','-NonInteractive','-Command','Start-Sleep 120' -PassThru -NoNewWindow; `$p.Id | Set-Content -LiteralPath '$esc'; Start-Sleep 120"
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @($cmd) -TimeoutSeconds 5 -AllowedOutputPaths @('grandchild.pid'))
            $r[0].timed_out | Should -Be $true
            Start-Sleep -Milliseconds 800
            $gcPid = 0; if (Test-Path -LiteralPath $pidFile) { $gcPid = [int]((Get-Content -LiteralPath $pidFile -Raw).Trim()) }
            $gcPid | Should -BeGreaterThan 0 -Because 'the child must have started and recorded its PID'
            (Get-Process -Id $gcPid -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty -Because 'Kill(entireProcessTree) must reap the spawned child, not only the direct command'
        }
        finally {
            if (Test-Path -LiteralPath $pidFile) { $gc = [int]((Get-Content -LiteralPath $pidFile -Raw).Trim()); if ($gc) { Stop-Process -Id $gc -Force -ErrorAction SilentlyContinue } }
            Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'CAPS the captured output at MaxOutputBytes (UTF-8 bytes)' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @("Write-Output ('x' * 5000)") -TimeoutSeconds 30 -MaxOutputBytes 500)
            $r[0].output_truncated | Should -Be $true
            ([System.Text.Encoding]::UTF8.GetByteCount($r[0].output)) | Should -BeLessOrEqual 500
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'records a MODIFIED existing file as a mutation' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Set-Content -LiteralPath app.txt -Value "MUTATED" -NoNewline') -TimeoutSeconds 30)
            $r[0].source_mutated | Should -Be $true
            $r[0].mutated_paths | Should -Contain 'app.txt'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'records a DELETED existing file as a mutation' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Remove-Item -LiteralPath app.txt -Force') -TimeoutSeconds 30)
            $r[0].source_mutated | Should -Be $true
            $r[0].mutated_paths | Should -Contain 'app.txt'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'records an ADDED file as a mutation when it is NOT in the output allowlist' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Set-Content -LiteralPath planted-source.ps1 -Value "evil()" -NoNewline') -TimeoutSeconds 30)
            $r[0].source_mutated | Should -Be $true -Because 'a new unexplained file could steer the verification'
            $r[0].mutated_paths | Should -Contain 'planted-source.ps1'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a new file IN the output allowlist is NOT a mutation' {
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Set-Content -LiteralPath test-output.log -Value "results" -NoNewline') -TimeoutSeconds 30 -AllowedOutputPaths @('*.log'))
            $r[0].source_mutated | Should -Be $false -Because 'a NEW file matching the explicit output allowlist is expected test output'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'runs ONLY the declared commands (an empty declared set runs nothing)' {
        $wt = script:New-Worktree
        try {
            (@(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @())).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
