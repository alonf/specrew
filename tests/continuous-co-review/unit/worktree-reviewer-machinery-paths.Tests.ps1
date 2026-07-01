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
    }

    It 'does strip the continuous-co-review runtime for downstream projects' {
        $repo = Join-Path $TestDrive 'downstream-project'
        New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain 'scripts/internal/continuous-co-review'
    }

    It 'requires the Specrew module manifest and co-review loader before treating a repo as Specrew source' {
        $repo = Join-Path $TestDrive 'lookalike-project'
        New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'Specrew.psd1') -Value '@{}' -Encoding UTF8

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain 'scripts/internal/continuous-co-review'
    }
}
