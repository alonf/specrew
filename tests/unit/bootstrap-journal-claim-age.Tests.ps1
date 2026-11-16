#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# Feature 203 T016: HookRenderDedupe I4b on Linux CI (run 43739142768, 2026-11-15): sixteen concurrent journal
# appends all reported success, and only fifteen rows were in the journal. The append claim's stale check read the
# claim's age from [System.IO.File]::GetLastWriteTimeUtc, and when the claim vanished between the existence check
# and that read (its owner had just finished), the platform's sentinel time (1601-01-01) made it look centuries old,
# so it was "reclaimed". If a third writer created a fresh claim in that moment, the reclaimer renamed the live claim
# away (POSIX allows renaming an open file) and two writers appended at once: one row lost, both reporting success.
Describe 'the bootstrap journal append claim age (T016)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HookJournalAccessor.ps1')
        $script:Root = Join-Path ([System.IO.Path]::GetTempPath()) ('journal-claim-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Root -Force | Out-Null
    }

    AfterAll { Remove-Item -LiteralPath $script:Root -Recurse -Force -ErrorAction SilentlyContinue }

    It 'a claim that no longer exists has no age, so it is never judged stale' {
        $missing = Join-Path $script:Root 'vanished.append.lock'
        Get-SpecrewJournalClaimAgeSeconds -ClaimPath $missing | Should -BeNullOrEmpty -Because 'a vanished claim is gone, not ancient; reclaiming on it can rename a live claim away'
    }

    It 'a fresh claim is young' {
        $fresh = Join-Path $script:Root 'fresh.append.lock'
        Set-Content -LiteralPath $fresh -Value 'x'
        (Get-SpecrewJournalClaimAgeSeconds -ClaimPath $fresh) | Should -BeLessThan 30
    }

    It 'an old claim is old' {
        $old = Join-Path $script:Root 'old.append.lock'
        Set-Content -LiteralPath $old -Value 'x'
        [System.IO.File]::SetLastWriteTimeUtc($old, [DateTime]::UtcNow.AddMinutes(-5))
        (Get-SpecrewJournalClaimAgeSeconds -ClaimPath $old) | Should -BeGreaterOrEqual 290
    }
}
