#requires -Version 7.0
# T092/R2 (FR-034): the generous-budget heuristic (large diff -> bigger DEFAULT budget, tiered + capped) and the
# explicit-config guard (an explicit co_review_timeout_seconds is human intent and is NEVER silently overridden).

BeforeAll {
    . (Join-Path $PSScriptRoot '..' '..' '..' 'scripts' 'internal' 'continuous-co-review' 'worktree-reviewer.ps1')
}

Describe 'Get-ContinuousCoReviewGenerousBudget (T092/R2)' {
    It 'keeps the default for a small change-set' {
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 5000 -ChangedCount 3 -DefaultSeconds 900 | Should -Be 900
    }
    It 'bumps 1.5x at tier 1 (>=200KB OR >=40 files)' {
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 250000 -ChangedCount 3 -DefaultSeconds 900 | Should -Be 1350
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 1000 -ChangedCount 40 -DefaultSeconds 900 | Should -Be 1350
    }
    It 'bumps 2x at tier 2 (>=500KB OR >=100 files)' {
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 600000 -ChangedCount 3 -DefaultSeconds 900 | Should -Be 1800
    }
    It 'caps at CapSeconds even for a huge change-set (tier 3 would exceed it)' {
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 5000000 -ChangedCount 500 -DefaultSeconds 900 | Should -Be 1800
        Get-ContinuousCoReviewGenerousBudget -DiffBytes 5000000 -ChangedCount 500 -DefaultSeconds 900 -CapSeconds 3600 | Should -Be 2700
    }
}

Describe 'Test-ContinuousCoReviewExplicitTimeoutConfigured (T092/R2 - respect explicit human intent)' {
    BeforeEach {
        $script:proj = Join-Path ([System.IO.Path]::GetTempPath()) ("ccr-cfg-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:proj '.specrew') -Force | Out-Null
    }
    AfterEach { Remove-Item -LiteralPath $script:proj -Recurse -Force -ErrorAction SilentlyContinue }

    It 'returns false when there is no config file (default budget -> heuristic eligible)' {
        Test-ContinuousCoReviewExplicitTimeoutConfigured -RepoRoot $script:proj | Should -BeFalse
    }
    It 'returns false when config has no co_review_timeout_seconds' {
        Set-Content -LiteralPath (Join-Path $script:proj '.specrew/config.yml') -Value "other_key: 1`nco_review_gate_enforcement: true" -Encoding UTF8
        Test-ContinuousCoReviewExplicitTimeoutConfigured -RepoRoot $script:proj | Should -BeFalse
    }
    It 'returns TRUE when co_review_timeout_seconds is explicitly set (NOT overridden by the heuristic)' {
        Set-Content -LiteralPath (Join-Path $script:proj '.specrew/config.yml') -Value "co_review_timeout_seconds: 1200" -Encoding UTF8
        Test-ContinuousCoReviewExplicitTimeoutConfigured -RepoRoot $script:proj | Should -BeTrue
    }
    It 'returns false for a commented-out setting (not active human intent)' {
        Set-Content -LiteralPath (Join-Path $script:proj '.specrew/config.yml') -Value "# co_review_timeout_seconds: 1200" -Encoding UTF8
        Test-ContinuousCoReviewExplicitTimeoutConfigured -RepoRoot $script:proj | Should -BeFalse
    }
}
