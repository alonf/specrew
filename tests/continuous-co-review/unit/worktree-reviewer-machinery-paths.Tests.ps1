$ErrorActionPreference = 'Stop'

# Trace: F-185 dogfood repair, FR-025, SC-019, SC-020.
# Specrew's own co-review runtime is product source when reviewing Specrew itself, but
# remains methodology machinery and is stripped from downstream project reviews.
Describe 'worktree reviewer machinery path policy' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
    }

    It 'does not strip the continuous-co-review runtime when reviewing the Specrew source repo' {
        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $script:RepoRoot)

        $paths | Should -Not -Contain 'scripts/internal/continuous-co-review'
        $paths | Should -Contain '.specrew'
        $paths | Should -Contain '.specify'
        $paths | Should -Contain '.antigravitycli' -Because 'Antigravity host runtime pointers are controller machinery, not product source'
        $paths | Should -Contain '.claude/settings.local.json' -Because 'canonical machine-local hook config is per-session machinery'
        $paths | Should -Not -Contain '.claude/settings.json' -Because 'ordinary Claude project settings remain reviewable source'
    }

    It 'does strip the continuous-co-review runtime for downstream projects' {
        $repo = Join-Path $TestDrive 'downstream-project'
        New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain 'scripts/internal/continuous-co-review'
    }

    It 'does not enumerate marker-detected machinery inside a Git-ignored tree' {
        # DRIFT-198-I009-009: a scratch area holding whole project copies contributed 539 marker
        # paths, pushing the list past the RecoveryFact cap (too-many:machinery_paths:512) and
        # killing the review at runtime start with zero provider invocation. Ignored content is
        # already outside the candidate, so enumerating it buys no exclusion.
        $repo = Join-Path $TestDrive 'ignored-tree-project'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Push-Location $repo
        try {
            git init --quiet 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo '.gitignore') -Value ".scratch/`n" -Encoding UTF8
            foreach ($rel in @('.scratch/copy-one/.github/skills/specrew-a', '.github/skills/specrew-real')) {
                New-Item -ItemType Directory -Path (Join-Path $repo $rel) -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo "$rel/.specrew-managed") -Value 'x' -Encoding UTF8
            }

            $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

            $paths | Should -Contain '.github/skills/specrew-real' -Because 'tracked deployed machinery must still be stripped'
            $paths | Should -Not -Contain '.scratch/copy-one/.github/skills/specrew-a' -Because 'Git already excludes ignored trees from the candidate'
            @($paths | Where-Object { $_ -like '.scratch/*' }).Count | Should -Be 0
        }
        finally { Pop-Location }
    }

    It 'requires the Specrew module manifest and co-review loader before treating a repo as Specrew source' {
        $repo = Join-Path $TestDrive 'lookalike-project'
        New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'Specrew.psd1') -Value '@{}' -Encoding UTF8

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain 'scripts/internal/continuous-co-review'
    }
}
