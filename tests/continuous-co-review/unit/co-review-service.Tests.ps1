$ErrorActionPreference = 'Stop'

# Trace: FR-026, FR-030, FR-025.
# Detached navigator launches must fail loud. If the host cannot spawn the child
# reviewer process, the pending registry must record a failed run with a reason
# instead of leaving no artifact for the gate/reaper/human to inspect.
Describe 'Continuous co-review service detached launch failure evidence' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-service.ps1')
    }

    It 'persists a failed pending registry entry when the detached spawn throws' {
        $repo = Join-Path $TestDrive 'spawn-fails'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null

        # The detached spawn is Win32_Process.Create (Invoke-CimMethod) on Windows, Start-Process on Unix (Issue-1
        # root fix: zero handle inheritance so the review can't hold the host's stdout pipe). Mock the one in use.
        if ($IsWindows) { Mock -CommandName Invoke-CimMethod -MockWith { throw 'fixture spawn failure' } }
        else { Mock -CommandName Start-Process -MockWith { throw 'fixture spawn failure' } }

        {
            Start-ContinuousCoReviewServiceRun `
                -RepoRoot $repo `
                -RunId 'spawnfail1' `
                -TreeId '0123456789abcdef0123456789abcdef01234567' `
                -Detached
        } | Should -Throw

        $registryPath = Join-Path $repo '.specrew/review/pending/spawnfail1.json'
        Test-Path -LiteralPath $registryPath -PathType Leaf | Should -Be $true
        $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $registry.status | Should -Be 'failed'
        $registry.failure_reason | Should -Match 'detached-spawn-failed'
    }
}

# T019 step 6 piece 2b: the reviewer spawn is gated by an ATOMIC per-lineage lease acquire. A failed acquire
# (a duplicate same-generation fire, or a newer tree queued behind a live owner) SUPPRESSES the spawn - no
# reviewer starts, so it consumes neither provider spend nor a review round.
Describe 'Continuous co-review service lease-gated spawn (T019 step 6 piece 2b)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-lineage-lease.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-identity-contracts.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-service.ps1')
    }

    It 'a duplicate same-generation fire is SUPPRESSED before spawn: no reviewer spawns, no pending registry' {
        $repo = Join-Path $TestDrive 'lease-suppress'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        $tree = '0123456789abcdef0123456789abcdef01234567'
        $lineage = 'L-fixture'
        # An in-flight review already OWNS the lease for this lineage + generation.
        (Request-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId $lineage -Generation $tree -RunId 'incumbent').acquired | Should -BeTrue
        # Prove the spawn is NEVER reached: mock it to throw.
        if ($IsWindows) { Mock -CommandName Invoke-CimMethod -MockWith { throw 'SPAWN MUST NOT HAPPEN' } }
        else { Mock -CommandName Start-Process -MockWith { throw 'SPAWN MUST NOT HAPPEN' } }

        $result = Start-ContinuousCoReviewServiceRun -RepoRoot $repo -RunId 'dup-fire' -TreeId $tree -LineageId $lineage -Detached
        $result.status | Should -Be 'suppressed'
        $result.suppressed_reason | Should -Be 'duplicate-same-generation'
        $result.spawned | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $repo '.specrew/review/pending/dup-fire.json') | Should -BeFalse -Because 'a suppressed run never starts, so no pending registry (and no spend/round) is recorded'
    }

    It 'a first fire for a fresh lineage ACQUIRES and reaches the spawn; a spawn failure releases the lease' {
        $repo = Join-Path $TestDrive 'lease-acquire'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        if ($IsWindows) { Mock -CommandName Invoke-CimMethod -MockWith { throw 'reached-spawn' } }
        else { Mock -CommandName Start-Process -MockWith { throw 'reached-spawn' } }
        { Start-ContinuousCoReviewServiceRun -RepoRoot $repo -RunId 'fresh' -TreeId '1111111111111111111111111111111111111111' -LineageId 'L-fresh' -Detached } | Should -Throw
        (Get-ContinuousCoReviewLineageLease -RepoRoot $repo -LineageId 'L-fresh') | Should -BeNullOrEmpty -Because 'the acquire succeeded (reached the spawn) and the lease was RELEASED on the spawn failure, so the lineage is not stuck'
    }
}
