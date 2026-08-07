#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FR-009 (203 W2) / SC-002 — reviewer context origin-path hygiene (F-198 iteration 003, T014):
# the reviewer-visible context (copied process/design snapshots) must RELATIVIZE origin-absolute
# paths to '<project>' so the confined reviewer never learns the real project location - while
# keeping the path STRUCTURE reviewable (relativize, never remove). Paired: origin paths in every
# form are neutralized; content without origin paths is left untouched (no over-scrub).
Describe 'reviewer context origin-path hygiene (FR-009 / SC-002)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1')
    }

    It 'relativizes file:/// origin URLs to the project placeholder' {
        $origin = 'C:\Dev\specrew-beta2-hardening'
        $content = 'See file:///C:/Dev/specrew-beta2-hardening/specs/198/iterations/003/state.md for state.'
        $out = ConvertTo-ContinuousCoReviewOriginRelativized -Content $content -OriginRoots @($origin)
        $out | Should -Be 'See file:///<project>/specs/198/iterations/003/state.md for state.'
        $out | Should -Not -Match 'specrew-beta2-hardening'
    }

    It 'relativizes bare absolute origin paths in both separator forms, case-insensitively' {
        $origin = 'C:\Dev\specrew-beta2-hardening'
        $fwd = 'path C:/Dev/specrew-beta2-hardening/scripts/x.ps1'
        $bwd = 'path C:\Dev\specrew-beta2-hardening\scripts\x.ps1'
        $lower = 'path c:/dev/specrew-beta2-hardening/scripts/x.ps1'
        (ConvertTo-ContinuousCoReviewOriginRelativized -Content $fwd -OriginRoots @($origin)) | Should -Be 'path <project>/scripts/x.ps1'
        (ConvertTo-ContinuousCoReviewOriginRelativized -Content $bwd -OriginRoots @($origin)) | Should -Be 'path <project>\scripts\x.ps1'
        (ConvertTo-ContinuousCoReviewOriginRelativized -Content $lower -OriginRoots @($origin)) | Should -Be 'path <project>/scripts/x.ps1'
    }

    It 'leaves content WITHOUT origin paths unchanged (no over-scrub of relative paths)' {
        $origin = 'C:\Dev\specrew-beta2-hardening'
        $content = "Relative refs stay: specs/198/state.md, .review/process/plan.md, and a different path C:/Other/repo/x."
        $out = ConvertTo-ContinuousCoReviewOriginRelativized -Content $content -OriginRoots @($origin)
        $out | Should -Be $content -Because 'only the origin prefix is neutralized; relative and foreign paths are untouched'
    }

    It 'relativizes against multiple origin roots (governance root + git top-level)' {
        $gov = 'C:\Dev\repo\nested-project'
        $git = 'C:\Dev\repo'
        $content = 'gov C:/Dev/repo/nested-project/a and git C:/Dev/repo/b'
        $out = ConvertTo-ContinuousCoReviewOriginRelativized -Content $content -OriginRoots @($gov, $git)
        # The longer (governance) root is applied first so the nested path collapses correctly.
        $out | Should -Be 'gov <project>/a and git <project>/b'
    }

    It 'is a no-op on empty/whitespace content' {
        (ConvertTo-ContinuousCoReviewOriginRelativized -Content '' -OriginRoots @('C:\x')) | Should -Be ''
    }

    It 'END-TO-END: the materialized change-set diff itself is scrubbed of origin-absolute paths (finding 9e3a44f1)' {
        # The helper tests above use synthetic strings; this proves the REAL bundle: a change whose
        # CONTENT embeds this repo's own origin-absolute path must not leak it through .review/changes.diff.
        $repo = Join-Path ([System.IO.Path]::GetTempPath()) ('ohyg-' + [guid]::NewGuid().ToString('N'))
        $wtPath = $null
        try {
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            & git -C $repo init -q 2>&1 | Out-Null
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value 'base' -Encoding UTF8
            & git -C $repo -c user.name='t' -c user.email='t@t.local' add -A 2>&1 | Out-Null
            & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -q -m base 2>&1 | Out-Null
            $baseline = (& git -C $repo rev-parse HEAD).Trim()
            $repoFwd = $repo -replace '\\', '/'
            Set-Content -LiteralPath (Join-Path $repo 'app.txt') -Value ("see file:///$repoFwd/secrets/state.md and path $repo\deep\x.ps1") -Encoding UTF8
            & git -C $repo -c user.name='t' -c user.email='t@t.local' commit -aq -m leak 2>&1 | Out-Null

            $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $repo -BaselineRef $baseline
            $wtPath = $wt.worktree_path
            $diff = Get-Content -LiteralPath (Join-Path $wtPath '.review/changes.diff') -Raw

            $diff | Should -Match 'secrets/state\.md' -Because 'the real change content is still under review'
            $diff | Should -Match '<project>' -Because 'the origin prefix was relativized, not the structure'
            $diff | Should -Not -Match ([regex]::Escape($repoFwd)) -Because 'SC-002: zero origin-absolute paths (forward form) in the reviewer bundle'
            $diff | Should -Not -Match ([regex]::Escape($repo)) -Because 'SC-002: zero origin-absolute paths (backslash form) in the reviewer bundle'
        }
        finally {
            if ($wtPath) { Remove-Item -LiteralPath $wtPath -Recurse -Force -ErrorAction SilentlyContinue }
            Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
