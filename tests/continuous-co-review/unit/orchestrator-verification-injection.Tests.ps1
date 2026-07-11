#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FR-010 (203 W3) — bounded verification WIRED onto the REAL orchestrator path (F-198 iteration 003,
# T015; co-review finding run bfc7b5c5 + the round-3 escalation 855f2c20, both maintainer-adjudicated).
# The finding: the wrapper had NO production caller and the prompt FALSELY claimed the reviewer's own
# shell runs were wrapped. Proven here end-to-end, per the maintainer's four test obligations:
#   1. RECORDED commands reach the production orchestrator path: Invoke-ContinuousCoReviewWorktreeReviewRun
#      runs them through Invoke-ContinuousCoReviewBoundedVerification and injects the HOST-OBSERVED
#      results (.review/verification/results.json) BEFORE the reviewer is spawned. Supply is the
#      maintainer-directed MINIMAL path: caller-explicit wins; else ONLY commands EXPLICITLY recorded in
#      the digest-matched implementer evidence (suites[].command, verbatim).
#   2. MISSING declarations run nothing and are REPORTED HONESTLY (verification_source/counts in status;
#      no results file; no prompt flag).
#   3. Commands are NEVER INFERRED: suite names without literal command strings supply nothing; digest-
#      mismatched evidence supplies nothing.
#   4. Timeout bounds, byte-capped output, and mutation evidence REMAIN ENFORCED on this path (verbatim
#      transport + timeout asserted at the wrapper call; a mutating supplied command is recorded; the
#      wrapper's own suite covers the cap/stream/kill mechanics).
# Plus: the slim prompt states the confinement contract honestly (isolated snapshot + origin-reference
# removal + T016 monitoring - never an OS-enforced sandbox, never "cannot escape").
Describe 'orchestrator wires bounded verification onto the real review path (FR-010)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/test-evidence-recorder.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

        # RunDir must live OUTSIDE the fixture repo: the reviewed-state digest includes untracked
        # non-ignored files, so an in-repo .runs/ created at run start would MOVE the digest away from
        # the one the evidence was recorded against (orphaning it - correctly, but not what these
        # fixtures are testing).
        function script:New-RunDir { return (Join-Path ([System.IO.Path]::GetTempPath()) ('bvw-runs-' + [guid]::NewGuid().ToString('N'))) }

        function script:New-TempGitRepo {
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('bvw-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'content' -Encoding UTF8
            New-Item -ItemType Directory -Path (Join-Path $repo 'specs/042-widget') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'specs/042-widget/spec.md') -Value '# widget spec' -Encoding UTF8
            New-Item -ItemType Directory -Path (Join-Path $repo '.specify') -Force | Out-Null
            ([pscustomobject]@{ feature_directory = 'specs/042-widget' } | ConvertTo-Json) |
                Set-Content -LiteralPath (Join-Path $repo '.specify/feature.json') -Encoding UTF8
            & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m seed 2>&1 | Out-Null
            return $repo
        }

        function script:New-StubReviewerMocks {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
        }
    }

    It 'RUNS caller-declared commands through the wrapper and injects host-observed results before the reviewer is spawned' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            script:New-StubReviewerMocks
            $script:capturedResults = $null
            $script:capturedFlag = $null
            # Capture what the orchestrator injected + the flag it passed, WHILE the worktree still exists.
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw' -TimeoutSeconds 60 -DeclaredVerificationCommands @('Write-Output "declared-ran"; exit 0')
            $script:capturedFlag | Should -Be $true -Because 'the orchestrator injected results, so the reviewer prompt flag must be set'
            @($script:capturedResults).Count | Should -Be 1
            @($script:capturedResults)[0].exit_code | Should -Be 0
            @($script:capturedResults)[0].source_mutated | Should -Be $false
            @($script:capturedResults)[0].output | Should -Match 'declared-ran'
            [string]$st.verification_source | Should -Be 'caller'
            [int]$st.verification_declared_count | Should -Be 1
            [int]$st.verification_run_count | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'EVIDENCE-RECORDED commands reach the production path when the caller declares none (minimal supply)' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            # The REAL recorder binds the command to the CURRENT tree digest (evidence lives under
            # .specrew/review/, which is digest-excluded - recording does not change the identity).
            $rec = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-a' -Passed 3 -ExitCode 0 -DurationSeconds 1.1 -Command 'Write-Output "evidence-cmd-ran"; exit 0'
            $rec | Should -Not -BeNullOrEmpty -Because 'the fixture must record real digest-bound evidence'
            script:New-StubReviewerMocks
            $script:capturedResults = $null
            $script:capturedFlag = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-ev","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-ev' -TimeoutSeconds 60   # no -DeclaredVerificationCommands
            [bool]$st.implementer_evidence | Should -Be $true -Because 'the digest-matched evidence must have been injected first'
            $script:capturedFlag | Should -Be $true
            @($script:capturedResults).Count | Should -Be 1
            @($script:capturedResults)[0].output | Should -Match 'evidence-cmd-ran' -Because 'the RECORDED command must be the one that ran, verbatim'
            [string]$st.verification_source | Should -Be 'implementer-evidence'
            [int]$st.verification_declared_count | Should -Be 1
            [int]$st.verification_run_count | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'NEVER infers commands: evidence with suite names but NO command strings supplies nothing' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            # Suite recorded WITHOUT -Command (the recorder persists command=null): a name like a test
            # path must never be rewritten into an invocation.
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'tests/unit/some.Tests.ps1' -Passed 5 -ExitCode 0
            script:New-StubReviewerMocks
            $script:capturedFlag = $null
            $script:fileExisted = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $script:fileExisted = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/verification/results.json')
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-ni","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-ni' -TimeoutSeconds 60
            [bool]$st.implementer_evidence | Should -Be $true -Because 'the evidence itself IS digest-matched and injected'
            $script:capturedFlag | Should -Be $false -Because 'a suite NAME is not a command - nothing may be inferred from it'
            $script:fileExisted | Should -Be $false
            [string]$st.verification_source | Should -Be 'none'
            [int]$st.verification_declared_count | Should -Be 0
            [int]$st.verification_run_count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'DIGEST-MISMATCHED evidence supplies nothing (stale commands never run against a different tree)' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-a' -Passed 3 -ExitCode 0 -Command 'Write-Output "stale-cmd"'
            # Change the tree AFTER recording: the digest moves, the evidence is orphaned by design.
            Add-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'post-evidence edit'
            script:New-StubReviewerMocks
            $script:capturedFlag = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-dm","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-dm' -TimeoutSeconds 60
            [bool]$st.implementer_evidence | Should -Be $false -Because 'orphaned evidence is never injected'
            $script:capturedFlag | Should -Be $false
            [string]$st.verification_source | Should -Be 'none'
            [int]$st.verification_run_count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'CALLER-explicit declarations win over evidence-recorded commands (no double spend)' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-a' -Passed 3 -ExitCode 0 -Command 'Write-Output "evidence-cmd-should-not-run"'
            script:New-StubReviewerMocks
            $script:capturedResults = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-cw","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-cw' -TimeoutSeconds 60 -DeclaredVerificationCommands @('Write-Output "caller-cmd-ran"')
            [string]$st.verification_source | Should -Be 'caller'
            @($script:capturedResults).Count | Should -Be 1
            @($script:capturedResults)[0].output | Should -Match 'caller-cmd-ran'
            @($script:capturedResults)[0].output | Should -Not -Match 'evidence-cmd-should-not-run'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RECORDS a mutating verification command AND the reviewer inputs stay untouched (disposable-copy verification)' {
        # Finding 97a93603-2 / escalation ffb729f2: a declared command that mutates source must be
        # RECORDED for the reviewer to judge - but it must be structurally UNABLE to alter the tree the
        # reviewer is then handed (source, .review/changes.diff, design context). The orchestrator runs
        # declared commands in a disposable sibling COPY, never the reviewer worktree.
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            # Supplied via the EVIDENCE path so mutation evidence is proven where the supply lands.
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-mut' -Passed 1 -ExitCode 0 -Command 'Set-Content -LiteralPath app.txt -Value "TAMPERED" -NoNewline'
            script:New-StubReviewerMocks
            $script:capturedResults = $null
            $script:reviewerAppTxt = $null
            $script:reviewerDiffExists = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                $script:reviewerAppTxt = Get-Content -LiteralPath (Join-Path $WorktreePath 'app.txt') -Raw
                $script:reviewerDiffExists = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/changes.diff')
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-mut","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $null = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-mut' -TimeoutSeconds 60
            @($script:capturedResults)[0].source_mutated | Should -Be $true -Because 'a supplied command that edits reviewed source is recorded as a mutation on the real path'
            @($script:capturedResults)[0].mutated_paths | Should -Contain 'app.txt'
            $script:reviewerAppTxt | Should -Match 'content' -Because 'the reviewer must see the certified fire-time content'
            $script:reviewerAppTxt | Should -Not -Match 'TAMPERED' -Because 'a mutating declaration must be UNABLE to alter the tree the reviewer reviews'
            $script:reviewerDiffExists | Should -Be $true -Because 'the review inputs (.review/changes.diff) must survive a hostile declared command'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'THREADS the timeout bound and the commands VERBATIM into the wrapper (timeout remains enforced)' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-a' -Passed 1 -ExitCode 0 -Command 'Write-Output "exact-cmd-1"'
            $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit-b' -Passed 1 -ExitCode 0 -Command 'Write-Output "exact-cmd-2"'
            script:New-StubReviewerMocks
            $script:wrapperTimeout = $null
            $script:wrapperCommands = $null
            Mock -CommandName Invoke-ContinuousCoReviewBoundedVerification -MockWith {
                $script:wrapperTimeout = $TimeoutSeconds
                $script:wrapperCommands = @($DeclaredCommands)
                @([pscustomobject]@{ command = 'x'; exit_code = 0; timed_out = $false; output = ''; output_truncated = $false; source_mutated = $false; mutated_paths = @() })
            }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-th","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $null = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-th' -TimeoutSeconds 60
            $script:wrapperTimeout | Should -Be 60 -Because 'per-command timeout = max(30, min(run timeout, 300)) - never unbounded'
            $script:wrapperTimeout | Should -BeGreaterOrEqual 30
            $script:wrapperTimeout | Should -BeLessOrEqual 300
            @($script:wrapperCommands) | Should -Contain 'Write-Output "exact-cmd-1"' -Because 'recorded strings are transported VERBATIM, never rewritten'
            @($script:wrapperCommands) | Should -Contain 'Write-Output "exact-cmd-2"'
            @($script:wrapperCommands).Count | Should -Be 2
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FAILS with verification-tampered-reviewer-tree when verification reaches OUT of the sandbox into the reviewer tree' {
        # Finding 4b124d0e-1: the disposable copy is not an OS boundary - a command with ambient
        # authority can reach the reviewer worktree by absolute/.. path. The orchestrator hashes the
        # certified reviewer tree before/after and REFUSES if it changed. Deterministic proof: the
        # reviewer-tree hash differs between the pre and post snapshot (simulating that out-of-sandbox
        # reach), and the run must fail before the reviewer is invoked.
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            script:New-StubReviewerMocks
            Mock -CommandName Invoke-ContinuousCoReviewBoundedVerification -MockWith {
                @([pscustomobject]@{ command = 'escape'; exit_code = 0; timed_out = $false; output = ''; output_truncated = $false; source_mutated = $false; mutated_paths = @() })
            }
            $script:hashCall = 0
            Mock -CommandName Get-ContinuousCoReviewWorktreeSourceHashes -MockWith {
                $script:hashCall++
                if ($script:hashCall -le 1) { return @{ 'app.txt' = 'HASH-BEFORE' } }
                return @{ 'app.txt' = 'HASH-AFTER-OUT-OF-SANDBOX-WRITE' }   # the reviewer tree changed during verification
            }
            $script:reviewerInvoked = $false
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:reviewerInvoked = $true
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-esc","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-esc' -TimeoutSeconds 60 -DeclaredVerificationCommands @("Get-ChildItem `$env:TEMP -Filter 'ccr-worktree-*' | ForEach-Object { Set-Content `"`$(`$_.FullName)/app.txt`" 'ESCAPED' }")
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Be 'verification-tampered-reviewer-tree'
            [string]$st.message | Should -Match 'app\.txt' -Because 'the tampered path must be named'
            $script:reviewerInvoked | Should -Be $false -Because 'a reviewer must NEVER inspect a tree a declared command could have steered'
            [bool]$st.provider_spend | Should -Be $false
            [bool]$st.verification_injected | Should -Be $false
            (Get-ContinuousCoReviewRoundState -RepoRoot $repo) | Should -BeNullOrEmpty -Because 'a tamper refusal latches no round-state'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FAILS LOUDLY before the reviewer when declared verification cannot be executed (never silent absence)' {
        # Finding 06cb3c64-2: an engine failure to EXECUTE or RECORD declared verification must not
        # degrade into "no results" silence - the reviewer would proceed and could pass a clean review.
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            script:New-StubReviewerMocks
            Mock -CommandName Invoke-ContinuousCoReviewBoundedVerification -MockWith { throw 'forced wrapper failure' }
            $script:reviewerInvoked = $false
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:reviewerInvoked = $true
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw-lf","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw-lf' -TimeoutSeconds 60 -DeclaredVerificationCommands @('Write-Output "will not run"')
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Be 'verification-not-executed'
            [string]$st.message | Should -Match 'forced wrapper failure' -Because 'the failure must be diagnosable, not swallowed'
            $script:reviewerInvoked | Should -Be $false -Because 'a run whose declared verification could not execute must never reach a passable review'
            [bool]$st.provider_spend | Should -Be $false -Because 'the model was never invoked - the T020 preflight class consumes neither budget'
            [bool]$st.round_consumed | Should -Be $false
            [bool]$st.verification_injected | Should -Be $false
            [int]$st.verification_declared_count | Should -Be 1
            (Get-ContinuousCoReviewRoundState -RepoRoot $repo) | Should -BeNullOrEmpty -Because 'an engine infrastructure failure latches no round-state'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'injects NOTHING and reports the account honestly when nothing is declared anywhere' {
        $repo = script:New-TempGitRepo
        $rd = script:New-RunDir
        try {
            script:New-StubReviewerMocks
            $script:capturedFlag = $null
            $script:fileExisted = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $script:fileExisted = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/verification/results.json')
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw3","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'bvw3' -TimeoutSeconds 60   # no declarations, no evidence
            $script:capturedFlag | Should -Be $false
            $script:fileExisted | Should -Be $false -Because 'the prompt block is gated on real injection - never a pointer to an absent file'
            [string]$st.verification_source | Should -Be 'none' -Because 'missing declarations are reported honestly, never silently'
            [int]$st.verification_declared_count | Should -Be 0
            [int]$st.verification_run_count | Should -Be 0
            [bool]$st.verification_injected | Should -Be $false
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'the slim prompt states the confinement contract honestly (FR-010/FR-013)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'states isolation as snapshot + reference removal - never an OS sandbox, never "cannot escape/reach"' {
        $p = Get-ContinuousCoReviewSlimPrompt -RunId 'x'
        $p | Should -Match '(?i)not an OS-enforced sandbox'
        $p | Should -Match 'WORKTREE CONFINEMENT'
        $p | Should -Not -Match '(?i)cannot\s+(escape|reach)'
        $p | Should -Not -Match 'Each such run is executed with a timeout and process containment' -Because 'the false per-run wrapper claim must stay dead'
        $p | Should -Not -Match '(?i)containment monitor RECORDS' -Because 'no live-monitor claim before T016 lands'
    }

    It 'renders the orchestrator-observed results block ONLY when results were injected' {
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x' -VerificationResultsPresent) | Should -Match 'BOUNDED VERIFICATION RESULTS'
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x' -VerificationResultsPresent) | Should -Match '\.review/verification/results\.json'
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x') | Should -Not -Match 'BOUNDED VERIFICATION RESULTS'
    }
}
