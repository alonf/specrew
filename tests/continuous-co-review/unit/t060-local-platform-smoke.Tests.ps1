Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'T060 local Windows and Linux smoke package' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
        $script:RunnerPath = Join-Path $script:RepoRoot 'scripts/t060-local-platform-smoke.ps1'
        $script:Source = Get-Content -LiteralPath $script:RunnerPath -Raw
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
        $script:Source | Should -Match 'Get-ContinuousCoReviewReviewedStateDigest'
    }

    It 'throttles non-semantic heartbeats while preserving every progress event' {
        $script:Source | Should -Match '\$progressEvents\.Add\(\$event\)'
        $script:Source | Should -Match '60000'
        $script:Source | Should -Match '\$isHeartbeat'
    }
}
