Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'T060 local Windows and Linux smoke package' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $script:RunnerPath = Join-Path $script:RepoRoot 'scripts/t060-local-platform-smoke.ps1'
        $script:Source = Get-Content -LiteralPath $script:RunnerPath -Raw
        $script:TargetPortSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-target-port.ps1') -Raw
    }

    It 'restricts the runner to the three planned host and platform allocations' {
        $script:Source | Should -Match "ValidateSet\('cursor-agent', 'antigravity', 'copilot'\)"
        $script:Source | Should -Match "HostName -cin @\('cursor-agent', 'antigravity'\)"
        $script:Source | Should -Match 't060-host-platform-mismatch'
        $script:Source | Should -Match 't060-local-platform-smoke-requires-windows-or-linux'
    }

    It 'keeps preflight non-spending and invoke explicitly authorized' {
        $script:Source | Should -Match "ValidateSet\('Preflight', 'Invoke'\)"
        $script:Source | Should -Match 't060-preflight-rejects-provider-authorization-inputs'
        $script:Source | Should -Match 't060-invoke-explicit-acknowledgement-required'
        $script:Source | Should -Match 'provider_invoked = \$false'
        $script:Source | Should -Match 'AcknowledgeProviderInvocation'
        $script:Source | Should -Match 't060-cursor-explicit-model-required'
        $script:Source | Should -Match 't060-cursor-model-unavailable'
        $script:Source | Should -Match 'model = \[string\]\$cliEvidence\.model'
    }

    It 'contains exactly one synchronous provider call and no retry machinery' {
        ([regex]::Matches($script:Source, '(?m)^\$campaignRun\s*=\s*Invoke-ReviewCampaignCommand\b')).Count | Should -Be 1
        $script:Source | Should -Not -Match 'Start-Job|Start-ThreadJob|Register-ObjectEvent|while\s*\(.*retry'
        $script:Source | Should -Match 'every further attempt requires a new run ID'
    }

    It 'fails closed on authority, repository, contract, and clean-result evidence' {
        $script:Source | Should -Match 't060-origin-repository-mutated'
        $script:Source | Should -Match 't060-provider-authority-count-invalid'
        $script:Source | Should -Match 't060-terminal-result-contract-invalid'
        $script:Source | Should -Match 't060-smoke-not-clean'
        $script:Source | Should -Match "t060-smoke-not-clean:verdict=\{0\}:findings=\{1\}"
        $script:Source | Should -Match 'Get-ContinuousCoReviewReviewedStateDigest'
    }

    It 'uses short sibling target and staging roots instead of the long Windows temp prefix' {
        $script:Source | Should -Match '\$externalParent = Split-Path -Parent \$root'
        $script:Source | Should -Match '\$targetRoot\s*=\s*Join-Path\s+\$externalParent\s+''\.t060-targets'''
        $script:Source | Should -Match '\$stagingRoot\s*=\s*Join-Path\s+\$externalParent\s+''\.t060-staging'''
        $script:Source | Should -Match 'New-GitReviewTargetPort -OriginRepo \$root -ExternalRoot \$targetRoot'
        $script:Source | Should -Match '-Ports \$ports'
        $script:Source | Should -Not -Match "GetTempPath\(\).*specrew-review-targets"

        $trackedPaths = @(& git -C $script:RepoRoot ls-tree -r --name-only HEAD)
        $longestTrackedPath = @($trackedPaths | Sort-Object Length -Descending | Select-Object -First 1)[0]
        $legacyPrefix = 'C:\Dev\.t060-targets\review-target-run-t060-cursor-windows-maximum-identifier-01-00000000000000000000000000000000'
        $boundedPrefix = 'C:\Dev\.t060-targets\rt-0000000000000000-00000000000000000000000000000000'
        (Join-Path $legacyPrefix $longestTrackedPath).Length | Should -BeGreaterThan 259
        (Join-Path $boundedPrefix $longestTrackedPath).Length | Should -BeLessThan 260
        $script:TargetPortSource | Should -Match ([regex]::Escape('''rt-{0}-{1}'' -f $runToken'))
    }

    It 'throttles non-semantic heartbeats while preserving every progress event' {
        $script:Source | Should -Match '\$progressEvents\.Add\(\$event\)'
        $script:Source | Should -Match '60000'
        $script:Source | Should -Match '\$isHeartbeat'
    }
}
