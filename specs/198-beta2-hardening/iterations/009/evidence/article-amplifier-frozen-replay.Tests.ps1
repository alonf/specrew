$ErrorActionPreference = 'Stop'

# Environment-specific dogfood replay. This is intentionally not part of the
# portable registry: CI does not own the consumer evidence repository. The
# generic candidate-fidelity class is covered by reviewed-state-digest and
# review-target-port tests; this file proves the fix against the maintainer's
# frozen Article Amplifier evidence without mutating it.
Describe 'F13/F16 frozen Article Amplifier round-15 replay' {
    BeforeAll {
        $script:EvidenceRoot = [string]$env:SPECREW_FROZEN_CONSUMER_ROOT
        $script:EngineRoot = [string]$env:SPECREW_ENGINE_SOURCE_ROOT
        if ([string]::IsNullOrWhiteSpace($script:EvidenceRoot) -or
            -not (Test-Path -LiteralPath $script:EvidenceRoot -PathType Container)) {
            throw 'SPECREW_FROZEN_CONSUMER_ROOT must name the read-only consumer evidence repository.'
        }
        if ([string]::IsNullOrWhiteSpace($script:EngineRoot) -or
            -not (Test-Path -LiteralPath $script:EngineRoot -PathType Container)) {
            throw 'SPECREW_ENGINE_SOURCE_ROOT must name the Specrew source repository.'
        }
        . (Join-Path $script:EngineRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    It 'turns the historical 164-path blocking candidate into an exact scope-respecting snapshot' {
        $historicalRunId = '20260725T234822895-d38a8704'
        $historicalStatusPath = Join-Path $script:EvidenceRoot ".specrew/review/pending/$historicalRunId/status.json"
        $historical = Get-Content -LiteralPath $historicalStatusPath -Raw | ConvertFrom-Json
        [int]$historical.round | Should -Be 15
        [bool]$historical.blocking | Should -BeTrue
        @($historical.changed_paths).Count | Should -Be 164
        @($historical.changed_paths) | Should -Contain '.claude/settings.local.json'

        $evidenceHeadBefore = (& git -C $script:EvidenceRoot rev-parse HEAD).Trim()
        $evidenceStatusBefore = @(& git -C $script:EvidenceRoot status --porcelain=v1 --untracked-files=all)
        $copy = Join-Path $TestDrive 'article-amplifier-copy'
        & git clone -q --no-hardlinks $script:EvidenceRoot $copy
        $LASTEXITCODE | Should -Be 0

        $settingsTarget = Join-Path $copy '.claude/settings.local.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $settingsTarget) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:EvidenceRoot '.claude/settings.local.json') -Destination $settingsTarget

        # Reproduce the untracked review-runtime evidence that was also present
        # at the consumer end state. Canonical machinery stripping must exclude
        # it independently of the explicit settings exclusion.
        $pendingParent = Join-Path $copy '.specrew/review/pending'
        New-Item -ItemType Directory -Path $pendingParent -Force | Out-Null
        Copy-Item -LiteralPath (Split-Path -Parent $historicalStatusPath) -Destination $pendingParent -Recurse

        $snapshot = New-GitReviewTargetSnapshot `
            -OriginRepo $copy `
            -RunId 'run-frozen15' `
            -ExternalRoot (Join-Path $TestDrive 'review-targets') `
            -ExcludedPathPatterns @('.claude/settings.local.json')
        try {
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path '.claude/settings.local.json') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path ".specrew/review/pending/$historicalRunId/status.json") | Should -BeFalse
            @($snapshot.excluded_path_patterns) | Should -Be @('.claude/settings.local.json')
            [string]$snapshot.excluded_path_patterns_sha256 | Should -Match '^[a-f0-9]{64}$'
            $current = Test-GitReviewTargetCurrentness -Snapshot $snapshot
            [string]$current.classification | Should -Be 'current'
            [bool]$current.exact | Should -BeTrue
        }
        finally {
            (Remove-GitReviewTargetSnapshot -Snapshot $snapshot).removed | Should -BeTrue
        }

        (& git -C $script:EvidenceRoot rev-parse HEAD).Trim() | Should -Be $evidenceHeadBefore
        @(& git -C $script:EvidenceRoot status --porcelain=v1 --untracked-files=all) | Should -Be $evidenceStatusBefore
    }
}
