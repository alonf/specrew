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

    It 'never pipes paths into a git subprocess stdin' {
        # Writing many paths to git's stdin while it writes matches back deadlocks once its stdout
        # buffer fills - the same class as DRIFT-198-I009-001. It hung the Linux CI review suite
        # silently: process killed, no failing assertion. Paths go as chunked ARGUMENTS instead.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $source | Should -Not -Match 'check-ignore --stdin'
        $source | Should -Not -Match '\$stdin\s*\|\s*&\s*git'
        $source | Should -Match 'check-ignore -- @chunk'
    }

    It 'still filters ignored trees when the candidate list exceeds one chunk' {
        $repo = Join-Path $TestDrive 'chunked-ignore-project'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Push-Location $repo
        try {
            git init --quiet 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo '.gitignore') -Value ".scratch/`n" -Encoding UTF8
            # Comfortably more than the 100-path chunk so the batching path is exercised.
            foreach ($i in 1..130) {
                $rel = ".scratch/copy-$i/skills/specrew-a"
                New-Item -ItemType Directory -Path (Join-Path $repo $rel) -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo "$rel/.specrew-managed") -Value 'x' -Encoding UTF8
            }
            New-Item -ItemType Directory -Path (Join-Path $repo '.github/skills/specrew-real') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $repo '.github/skills/specrew-real/.specrew-managed') -Value 'x' -Encoding UTF8

            $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

            @($paths | Where-Object { $_ -like '.scratch/*' }).Count | Should -Be 0 -Because 'every ignored path must be filtered across all chunks'
            $paths | Should -Contain '.github/skills/specrew-real'
        }
        finally { Pop-Location }
    }

    It 'compares ignored paths by exact identity, never case-insensitively' {
        # Independent-review finding (run-f198-i009-178a3772-codex, major): an OrdinalIgnoreCase
        # match lets an ignored path drop a DISTINCT non-ignored path differing only by case on a
        # case-sensitive worktree, under-stripping deployed machinery into the reviewed candidate.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $source | Should -Not -Match 'HashSet\[string\]\]::new\(\[StringComparer\]::OrdinalIgnoreCase\)'
        $source | Should -Match 'HashSet\[string\]\]::new\(\[StringComparer\]::Ordinal\)'
    }

    It 'keeps a non-ignored path whose case differs from an ignored one' {
        $repo = Join-Path $TestDrive 'case-collision-project'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        $probe = Join-Path $repo 'CaseProbe'
        New-Item -ItemType Directory -Path $probe -Force | Out-Null
        if (Test-Path -LiteralPath (Join-Path $repo 'caseprobe')) {
            Set-ItResult -Skipped -Because 'this filesystem is case-insensitive; the collision cannot be materialized here'
            return
        }
        Remove-Item -LiteralPath $probe -Recurse -Force
        Push-Location $repo
        try {
            git init --quiet 2>&1 | Out-Null
            # Only the lowercase tree is ignored; the capitalized one is real reviewable machinery.
            Set-Content -LiteralPath (Join-Path $repo '.gitignore') -Value "scratch/`n" -Encoding UTF8
            foreach ($rel in @('scratch/host/skills/specrew-a', 'Scratch/host/skills/specrew-a')) {
                New-Item -ItemType Directory -Path (Join-Path $repo $rel) -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $repo "$rel/.specrew-managed") -Value 'x' -Encoding UTF8
            }

            $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

            $paths | Should -Contain 'Scratch/host/skills/specrew-a' -Because 'a non-ignored path must survive an ignored path differing only by case'
            $paths | Should -Not -Contain 'scratch/host/skills/specrew-a'
        }
        finally { Pop-Location }
    }

    It 'strips generated Codex agent mirrors like every other host mirror' {
        # DRIFT-198-I009-013: .codex was absent from the host-mirror vocabulary and the generated
        # .codex/agents files carry no .specrew-managed marker, so all five entered the frozen
        # candidate and regenerated reviewer instructions could perturb the certified identity.
        $repo = Join-Path $TestDrive 'codex-mirror-project'
        New-Item -ItemType Directory -Path (Join-Path $repo '.codex/agents') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $repo '.codex/skills') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.codex/agents/reviewer.toml') -Value 'generated' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repo '.codex/config.toml') -Value 'user' -Encoding UTF8

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain '.codex/agents' -Because 'generated Codex agent mirrors are machinery, marker or not'
        $paths | Should -Contain '.codex/skills'
        $paths | Should -Not -Contain '.codex/config.toml' -Because 'ordinary user host config stays reviewable'
    }

    It 'requires the Specrew module manifest and co-review loader before treating a repo as Specrew source' {
        $repo = Join-Path $TestDrive 'lookalike-project'
        New-Item -ItemType Directory -Path (Join-Path $repo 'scripts/internal/continuous-co-review') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo 'Specrew.psd1') -Value '@{}' -Encoding UTF8

        $paths = @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $repo)

        $paths | Should -Contain 'scripts/internal/continuous-co-review'
    }
}
