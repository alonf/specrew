#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FR-010 (203 W3) — the bounded-verification wrapper is WIRED onto the REAL orchestrator path
# (F-198 iteration 003, T015; co-review finding run bfc7b5c5). The finding: the wrapper had NO
# production caller and the prompt FALSELY claimed the reviewer's own shell runs were wrapped. The fix,
# proven here end-to-end:
#   1. Invoke-ContinuousCoReviewWorktreeReviewRun RUNS the declared verification commands through
#      Invoke-ContinuousCoReviewBoundedVerification and injects the HOST-OBSERVED results into the
#      worktree (.review/verification/results.json) BEFORE the reviewer is spawned - it is not a
#      fixture-only helper.
#   2. A declared command that mutates reviewed source is RECORDED as a mutation on that real path.
#   3. With no declared commands, NOTHING is injected and the prompt flag is false (no pointer to an
#      absent file).
#   4. The slim prompt tells the truth: the reviewer's OWN runs are contained by the HOST BOUNDARY
#      (isolated worktree + containment monitor), never falsely claimed to be wrapped.
Describe 'orchestrator wires bounded verification onto the real review path (FR-010)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

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
    }

    It 'RUNS the declared commands through the wrapper and injects host-observed results before the reviewer is spawned' {
        $repo = script:New-TempGitRepo
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            $script:capturedResults = $null
            $script:capturedFlag = $null
            # Capture what the orchestrator injected + the flag it passed, WHILE the worktree still exists.
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $null = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r1') -RunId 'bvw' -TimeoutSeconds 60 -DeclaredVerificationCommands @('Write-Output "declared-ran"; exit 0')
            $script:capturedFlag | Should -Be $true -Because 'the orchestrator injected results, so the reviewer prompt flag must be set'
            @($script:capturedResults).Count | Should -Be 1
            @($script:capturedResults)[0].exit_code | Should -Be 0
            @($script:capturedResults)[0].source_mutated | Should -Be $false
            @($script:capturedResults)[0].output | Should -Match 'declared-ran'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RECORDS a declared verification that mutates reviewed source (containment on the real path)' {
        $repo = script:New-TempGitRepo
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            $script:capturedResults = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $vp = Join-Path $WorktreePath '.review/verification/results.json'
                if (Test-Path -LiteralPath $vp) { $script:capturedResults = Get-Content -LiteralPath $vp -Raw | ConvertFrom-Json }
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw2","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            # A declared command that edits existing source: the host-observed record must flag it, so an
            # agent-requested verification that tampers with the reviewed tree cannot pass unrecorded.
            $null = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r2') -RunId 'bvw2' -TimeoutSeconds 60 -DeclaredVerificationCommands @('Set-Content -LiteralPath app.txt -Value "TAMPERED" -NoNewline')
            @($script:capturedResults)[0].source_mutated | Should -Be $true -Because 'a declared command that edits reviewed source is recorded as a mutation on the real path'
            @($script:capturedResults)[0].mutated_paths | Should -Contain 'app.txt'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'injects NOTHING and sets the flag FALSE when no commands are declared (no false pointer)' {
        $repo = script:New-TempGitRepo
        try {
            Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith {
                [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' }
            }
            $script:capturedFlag = $null
            $script:fileExisted = $null
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:capturedFlag = [bool]$VerificationResultsPresent
                $script:fileExisted = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/verification/results.json')
                [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"bvw3","status":"findings","findings":[]}'; stderr = ''; telemetry = $null }
            }
            $null = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir (Join-Path $repo '.runs/r3') -RunId 'bvw3' -TimeoutSeconds 60   # no -DeclaredVerificationCommands
            $script:capturedFlag | Should -Be $false
            $script:fileExisted | Should -Be $false -Because 'the prompt block is gated on real injection - never a pointer to an absent file'
        }
        finally { Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'the slim prompt states the host boundary honestly, not a false wrapper claim (FR-010/FR-013)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'does NOT claim the reviewer''s own runs are wrapped; it states the HOST BOUNDARY + containment monitor' {
        $p = Get-ContinuousCoReviewSlimPrompt -RunId 'x'
        $p | Should -Match 'HOST BOUNDARY'
        $p | Should -Match '(?i)containment monitor RECORDS'
        $p | Should -Not -Match 'Each such run is executed with a timeout and process containment'
    }

    It 'renders the orchestrator-observed results block ONLY when results were injected' {
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x' -VerificationResultsPresent) | Should -Match 'BOUNDED VERIFICATION RESULTS'
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x' -VerificationResultsPresent) | Should -Match '\.review/verification/results\.json'
        (Get-ContinuousCoReviewSlimPrompt -RunId 'x') | Should -Not -Match 'BOUNDED VERIFICATION RESULTS'
    }
}
