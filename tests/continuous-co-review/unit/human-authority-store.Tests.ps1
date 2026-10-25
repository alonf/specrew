$ErrorActionPreference = 'Stop'

Describe 'Review-signoff partial override human authority store' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        $script:TreeA = ('a' * 64)
        $script:TreeB = ('b' * 64)
        $script:Campaign = 'cmp-001-human-authority-i001'
        $script:Verdict = 'approved for partial review signoff - provider unavailable; maintainer accepts the named residual risk'
    }

    BeforeEach {
        $script:Project = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:Project -Force | Out-Null
        Write-SpecrewReviewSignoffOverrideRequest -ProjectRoot $script:Project -TargetTreeId $script:TreeA `
            -CampaignId $script:Campaign -RunId 'run-001' -NowUtc '2026-08-14T10:00:00Z' | Out-Null
    }

    It 'captures an exact typed prompt-entry verdict and returns it only for its tree and campaign' {
        $written = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response $script:Verdict -HostKind 'copilot' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-14T10:01:00Z'

        $written.authority_kind | Should -Be 'human'
        $written.verdict_text | Should -BeExactly $script:Verdict
        $read = Get-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -ExpectedTargetTreeId $script:TreeA -ExpectedCampaignId $script:Campaign
        $read.rationale | Should -Match 'maintainer accepts'
        (Get-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -ExpectedTargetTreeId $script:TreeB -ExpectedCampaignId $script:Campaign) | Should -BeNullOrEmpty
    }

    It 'ignores non-prompt events, injected hook text, and malformed phrases' {
        (Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project -Response $script:Verdict `
            -HostKind 'fixture' -SourceEvent 'Stop') | Should -BeNullOrEmpty
        (Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response ('<hook_prompt>' + $script:Verdict + '</hook_prompt>') -HostKind 'fixture' `
            -SourceEvent 'UserPromptSubmit') | Should -BeNullOrEmpty
        (Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response 'approved for partial review signoff' -HostKind 'fixture' `
            -SourceEvent 'UserPromptSubmit') | Should -BeNullOrEmpty
    }

    It 'is idempotent for the same captured reply and rejects conflicting authority' {
        $first = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response $script:Verdict -HostKind 'copilot' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-14T10:01:00Z'
        $again = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response $script:Verdict -HostKind 'copilot' -SourceEvent 'UserPromptSubmit' -NowUtc '2026-08-14T10:02:00Z'
        $again.response_hash | Should -BeExactly $first.response_hash

        { Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
                -Response 'approved for partial review signoff - a different rationale cannot rewrite immutable authority' `
                -HostKind 'copilot' -SourceEvent 'UserPromptSubmit' } | Should -Throw '*authorization-conflict*'
    }

    It 'detects content tampering instead of trusting a well-shaped hash field' {
        $written = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
            -Response $script:Verdict -HostKind 'copilot' -SourceEvent 'UserPromptSubmit'
        $path = Join-Path (Join-Path (Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $script:Project) 'override-authorizations') `
            (([string]$written.request_id) + '.json')
        $fact = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $fact.verdict_text = 'approved for partial review signoff - tampered rationale that was never typed by the human'
        $fact | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8

        { Get-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $script:Project `
                -ExpectedTargetTreeId $script:TreeA -ExpectedCampaignId $script:Campaign } |
            Should -Throw '*authorization-content-invalid*'
    }
}
