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
}
