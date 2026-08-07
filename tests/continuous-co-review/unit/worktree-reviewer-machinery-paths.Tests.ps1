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

    It 'does not enumerate marker-detected machinery inside a volatile scratch tree' {
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

    It 'asks Git about ignored paths by ARGUMENT, never through its stdin' {
        # This scan was briefly made subprocess-free on the theory that `git check-ignore` hung the
        # Linux CI review job. There was never a hang: `gh run view --log` truncates per-job output,
        # and that truncated tail was read as silence while the job in fact ran to completion and
        # failed on a real assertion (DRIFT-198-I009-018). What IS real is the pipe-deadlock class of
        # DRIFT-198-I009-001 - writing hundreds of paths to git's stdin while it writes matches back
        # blocks both ends once a buffer fills. So the probe stays, and stays argument-shaped.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $machineryBlock = $source.Substring($source.IndexOf('function Get-ContinuousCoReviewMachineryPaths'), 6000)
        $machineryBlock | Should -Match 'git -C \$RepoRoot check-ignore -- @chunk' -Because 'ignored paths are asked for by argument'
        $machineryBlock | Should -Not -Match 'check-ignore --stdin' -Because 'piping the list to git deadlocks once its stdout buffer fills'
        $machineryBlock | Should -Match '\$prunedRoots' -Because 'the cheap name prune runs first so the subprocess sees a bounded list'
    }

    It 'compares ignored paths by exact identity, never case-insensitively' {
        # Independent-review finding (run-f198-i009-178a3772-codex, major): an OrdinalIgnoreCase
        # match lets an ignored path drop a DISTINCT non-ignored path differing only by case on a
        # case-sensitive worktree, under-stripping deployed machinery into the reviewed candidate.
        # No case-FOLDING comparer may appear anywhere in this policy - not in the ignored-path set
        # and not in the dedup, which would collapse two genuinely distinct machinery directories.
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1') -Raw
        $source | Should -Match 'HashSet\[string\]\]::new\(\[StringComparer\]::Ordinal\)' -Because 'the ignored-path set matches git output by exact identity'
        $source | Should -Not -Match 'HashSet\[string\]\]::new\(\[StringComparer\]::OrdinalIgnoreCase\)'
        $source | Should -Match 'Get-ContinuousCoReviewPathComparer' -Because 'dedup follows the volume, not a hard-coded rule'
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

            # `-ccontains`, never `Should -Contain`: the latter is backed by PowerShell's `-contains`,
            # which FOLDS CASE - so it cannot tell these two paths apart and reports the surviving
            # 'Scratch/...' as a match for the stripped 'scratch/...'. The whole point of this fixture
            # is that the two are distinct, so the assertion has to be case-sensitive to mean anything.
            ($paths -ccontains 'Scratch/host/skills/specrew-a') | Should -BeTrue -Because 'a non-ignored path must survive an ignored path differing only by case'
            ($paths -ccontains 'scratch/host/skills/specrew-a') | Should -BeFalse -Because 'the git-ignored path adds no exclusion and must be stripped'
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
