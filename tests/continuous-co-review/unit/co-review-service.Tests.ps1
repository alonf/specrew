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
