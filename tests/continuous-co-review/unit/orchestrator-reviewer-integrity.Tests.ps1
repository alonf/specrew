#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FR-010 (203 W3) — orchestrator behaviour after the maintainer's option-1 SIMPLIFICATION (2026-07-11).
# The orchestrator no longer auto-runs declared verification, copies a sandbox, or re-runs commands per
# review (those cases live as regression evidence in bounded-verification.Tests.ps1). Instead it applies
# a REVIEWER-INVOCATION INTEGRITY check: it hashes source + authoritative reviewer inputs immediately
# before and after the reviewer runs, permits ONLY the reviewer's own output (.review/findings.jsonl),
# and FAILS the review on any other mutation (the reviewer must inspect, not edit, the certified tree).
# This is MONITORED confinement, not OS-enforced isolation.
Describe 'orchestrator does NOT auto-run verification, and integrity-checks the reviewer invocation (FR-010)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')

        # RunDir OUTSIDE the fixture repo (the reviewed-state digest includes untracked non-ignored files).
        function script:New-RunDir { return (Join-Path ([System.IO.Path]::GetTempPath()) ('ri-runs-' + [guid]::NewGuid().ToString('N'))) }

        function script:New-TempGitRepo {
            $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('ri-' + [guid]::NewGuid().ToString('N'))
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
        function script:StubHost { Mock -CommandName Resolve-ContinuousCoReviewReviewerHost -MockWith { [pscustomobject]@{ host = 'stub'; model = 'm'; independence = 'independent'; selection_reason = 'test' } } }
        function script:ReviewerResult { param($id) [pscustomobject]@{ exit_code = 0; stdout = ('{"schema_version":"1.0","run_id":"' + $id + '","status":"findings","findings":[]}'); stderr = ''; telemetry = $null } }
    }

    It 'NEVER calls the bounded-verification helper automatically, and injects no verification results' {
        $repo = script:New-TempGitRepo; $rd = script:New-RunDir
        try {
            script:StubHost
            $script:sawResultsFile = $null
            Mock -CommandName Invoke-ContinuousCoReviewBoundedVerification -MockWith { @() }
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                $script:sawResultsFile = Test-Path -LiteralPath (Join-Path $WorktreePath '.review/verification/results.json')
                script:ReviewerResult 'ri-noauto'
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'ri-noauto' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done'
            $script:sawResultsFile | Should -Be $false -Because 'the orchestrator no longer injects orchestrator-run verification results'
            Should -Invoke -CommandName Invoke-ContinuousCoReviewBoundedVerification -Times 0 -Because 'the helper is opt-in only and must never run automatically'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FAILS the review (reviewer-tampered-tree) when the reviewer mutates a SOURCE file' {
        $repo = script:New-TempGitRepo; $rd = script:New-RunDir
        try {
            script:StubHost
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                Set-Content -LiteralPath (Join-Path $WorktreePath 'app.txt') -Value 'REVIEWER-EDITED' -NoNewline   # editing the tree it certifies
                script:ReviewerResult 'ri-tamper'
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'ri-tamper' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Be 'reviewer-tampered-tree'
            [string]$st.message | Should -Match 'app\.txt'
            [bool]$st.provider_spend | Should -Be $true -Because 'the model WAS invoked - invoked-failed class'
            [bool]$st.round_consumed | Should -Be $true
            (Get-Content -LiteralPath (Join-Path $rd 'result.out') -Raw) | Should -BeNullOrEmpty -Because 'a tampering reviewer''s findings are discarded'
            $rs = Get-ContinuousCoReviewRoundState -RepoRoot $repo
            @($rs.dispositions | Where-Object { $_.state -eq 'reviewer-tampered-tree' }).Count | Should -BeGreaterThan 0
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FAILS the review when the reviewer rewrites an AUTHORITY input (.review/changes.diff)' {
        $repo = script:New-TempGitRepo; $rd = script:New-RunDir
        try {
            script:StubHost
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                Set-Content -LiteralPath (Join-Path $WorktreePath '.review/changes.diff') -Value 'FORGED' -NoNewline
                script:ReviewerResult 'ri-auth'
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'ri-auth' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'failed'
            [string]$st.failure_reason | Should -Be 'reviewer-tampered-tree'
            [string]$st.message | Should -Match 'changes\.diff'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'ALLOWS the reviewer to write ONLY its own output (.review/findings.jsonl) - review completes' {
        $repo = script:New-TempGitRepo; $rd = script:New-RunDir
        try {
            script:StubHost
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                Set-Content -LiteralPath (Join-Path $WorktreePath '.review/findings.jsonl') -Value '{"finding_id":"f1"}' -NoNewline
                script:ReviewerResult 'ri-output'
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'ri-output' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done' -Because 'the reviewer''s own findings output is the ONE permitted write'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does NOT false-flag volatile reviewer-HOST runtime dirs (.codex, .antigravitycli, ...)' {
        $repo = script:New-TempGitRepo; $rd = script:New-RunDir
        try {
            script:StubHost
            Mock -CommandName Invoke-ContinuousCoReviewWorktreeReviewer -MockWith {
                New-Item -ItemType Directory -Path (Join-Path $WorktreePath '.codex') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $WorktreePath '.codex/session.json') -Value '{}' -NoNewline   # the host's own ephemeral state
                script:ReviewerResult 'ri-host'
            }
            $st = Invoke-ContinuousCoReviewWorktreeReviewRun -RepoRoot $repo -RunDir $rd -RunId 'ri-host' -TimeoutSeconds 60
            [string]$st.status | Should -Be 'done' -Because 'host session churn is not source tampering'
        }
        finally { Remove-Item -LiteralPath $repo, $rd -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'the slim prompt states strict read-only + monitored confinement honestly (FR-010/FR-013)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'tells the reviewer it is under integrity check, strictly read-only except .review/findings.jsonl' {
        $p = Get-ContinuousCoReviewSlimPrompt -RunId 'x'
        $p | Should -Match '(?i)READ-ONLY'
        $p | Should -Match '\.review/findings\.jsonl'
        $p | Should -Match '(?si)hashed\b.*before and after'
    }

    It 'no longer claims orchestrator-observed verification results, nor an OS sandbox' {
        $p = Get-ContinuousCoReviewSlimPrompt -RunId 'x'
        $p | Should -Not -Match 'BOUNDED VERIFICATION RESULTS'
        $p | Should -Not -Match '(?i)orchestrator-observed'
        $p | Should -Not -Match '(?i)cannot\s+(escape|reach)'
    }
}
