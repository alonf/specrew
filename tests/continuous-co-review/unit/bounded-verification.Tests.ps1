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
            # Reviewer-authority input (finding 90173dc6-1): hashed like source, so a verification
            # command rewriting its own authority is reported.
            New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $wt '.review/changes.diff') -Value 'diff --git a/app.txt b/app.txt' -Encoding UTF8 -NoNewline
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

    It 'bounds SUSTAINED multibyte output with ZERO-DISK capture (memory AND on-disk capture stay bounded)' {
        # Findings bfc7b5c5-2 + 06cb3c64-1 proof: the child STREAMS ~3 MB of a 3-byte UTF-8 char over
        # 2000 chunks. The pump retains at most MaxOutputBytes per stream in a FIXED buffer and DISCARDS
        # the overflow while still draining the pipe - so neither reviewer memory nor host disk ever
        # holds the flood. captured_*_bytes is the observable retention: it can never exceed the cap by
        # construction, and the capture path writes NO temp files at all. (Slack of 3 bytes on the
        # record: a truncated trailing multibyte sequence degrades to one U+FFFD.)
        $wt = script:New-Worktree
        try {
            $flood = "1..2000 | ForEach-Object { [Console]::Out.Write(([char]0x2122).ToString() * 512) }"
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @($flood) -TimeoutSeconds 60 -MaxOutputBytes 4096)
            $r[0].output_truncated | Should -Be $true
            $bytes = [System.Text.Encoding]::UTF8.GetByteCount($r[0].output)
            $bytes | Should -BeLessOrEqual (4096 + 3) -Because 'the cap holds - the multi-MB flood never lands in the record'
            $bytes | Should -BeGreaterOrEqual (4096 - 3) -Because 'the capture fills up to the cap, proving output actually streamed through'
            $r[0].captured_stdout_bytes | Should -Be 4096 -Because 'retention is pump-bounded at exactly the cap - the other ~3 MB was drained and discarded'
            $r[0].captured_stderr_bytes | Should -BeLessOrEqual 4096
            $r[0].source_mutated | Should -Be $false
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

    It 'REPORTS a mutation of the reviewer-authority inputs (.review/changes.diff) - the authority cannot be rewritten silently' {
        # Finding 90173dc6-1: a declared command that rewrites the very diff/design it verifies against
        # can manufacture a pass; the mutation snapshot therefore INCLUDES the .review/ authority inputs.
        $wt = script:New-Worktree
        try {
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @('Set-Content -LiteralPath .review/changes.diff -Value "FORGED DIFF" -NoNewline') -TimeoutSeconds 30)
            $r[0].source_mutated | Should -Be $true -Because 'rewriting the authority the verification runs against manufactures a pass - it must be reported'
            $r[0].mutated_paths | Should -Contain '.review/changes.diff'
        }
        finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the engine-owned .review/verification/ output area stays exempt (the narrow allowlist)' {
        $wt = script:New-Worktree
        try {
            $cmd = 'New-Item -ItemType Directory -Path .review/verification -Force | Out-Null; Set-Content -LiteralPath .review/verification/probe.json -Value "{}" -NoNewline'
            $r = @(Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt -DeclaredCommands @($cmd) -TimeoutSeconds 30)
            $r[0].source_mutated | Should -Be $false -Because 'the orchestrator-owned results area is the ONLY .review exemption'
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
