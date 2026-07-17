$ErrorActionPreference = 'Stop'

# Trace: T041 / FR-057 / FR-065 / SC-017.
Describe 'Review authority cutover is singular and fail closed' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-cutover.ps1')

        function script:Write-AuthorityFixture {
            param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Json)
            $path = Join-Path $TestDrive ($Name + '.json')
            Set-Content -LiteralPath $path -Value $Json -Encoding UTF8 -NoNewline
            return $path
        }
    }

    It 'maps every valid mode without ever enabling both authorities' -ForEach @(
        @{ mode = 'legacy';   legacy = $true;  campaign = $false }
        @{ mode = 'disabled'; legacy = $false; campaign = $false }
        @{ mode = 'campaign'; legacy = $false; campaign = $true }
    ) {
        $path = Write-AuthorityFixture -Name $mode -Json (([ordered]@{ schema_version = '1.0'; mode = $mode }) | ConvertTo-Json -Compress)
        $decision = Get-ContinuousCoReviewAuthorityDecision -ConfigPath $path

        $decision.valid | Should -BeTrue
        $decision.mode | Should -Be $mode
        $decision.legacy_promotion_enabled | Should -Be $legacy
        $decision.campaign_authority_enabled | Should -Be $campaign
        ($decision.legacy_promotion_enabled -and $decision.campaign_authority_enabled) | Should -BeFalse
        (Test-ContinuousCoReviewAuthorityEnabled -Authority legacy -Decision $decision) | Should -Be $legacy
        (Test-ContinuousCoReviewAuthorityEnabled -Authority campaign -Decision $decision) | Should -Be $campaign
    }

    It 'fails closed for missing, malformed, unsupported, unknown, oversized, and substitute shapes' -ForEach @(
        @{ name = 'missing';     kind = 'missing'; json = ''; reason = 'authority-config-missing' }
        @{ name = 'malformed';   kind = 'json'; json = '{'; reason = 'authority-config-invalid-json' }
        @{ name = 'unsupported'; kind = 'json'; json = '{"schema_version":"2.0","mode":"legacy"}'; reason = 'authority-config-unsupported-version' }
        @{ name = 'unknown';     kind = 'json'; json = '{"schema_version":"1.0","mode":"other"}'; reason = 'authority-config-invalid-mode' }
        @{ name = 'extra';       kind = 'json'; json = '{"schema_version":"1.0","mode":"legacy","permit":true}'; reason = 'authority-config-invalid-shape' }
        @{ name = 'oversized';   kind = 'large'; json = ''; reason = 'authority-config-too-large' }
    ) {
        $path = Join-Path $TestDrive ($name + '.json')
        if ($kind -eq 'json') { Set-Content -LiteralPath $path -Value $json -Encoding UTF8 -NoNewline }
        elseif ($kind -eq 'large') { Set-Content -LiteralPath $path -Value ('x' * 4097) -Encoding UTF8 -NoNewline }

        $decision = Get-ContinuousCoReviewAuthorityDecision -ConfigPath $path
        $decision.valid | Should -BeFalse
        $decision.mode | Should -Be 'disabled'
        $decision.reason | Should -Be $reason
        $decision.legacy_promotion_enabled | Should -BeFalse
        $decision.campaign_authority_enabled | Should -BeFalse
    }

    It 'ships with campaign authority active and never derives authority from environment variables' {
        $env:SPECREW_REVIEW_AUTHORITY_MODE = 'campaign'
        try {
            $decision = Get-ContinuousCoReviewAuthorityDecision
            $decision.valid | Should -BeTrue
            $decision.mode | Should -Be 'campaign'
            $decision.legacy_promotion_enabled | Should -BeFalse
            $decision.campaign_authority_enabled | Should -BeTrue
        }
        finally {
            Remove-Item Env:SPECREW_REVIEW_AUTHORITY_MODE -ErrorAction SilentlyContinue
        }
    }

    It 'enforces the one-way legacy to disabled to campaign transition' {
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode legacy -ProposedMode campaign).permitted | Should -BeFalse
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode legacy -ProposedMode campaign).reason | Should -Be 'campaign-cutover-requires-disabled-stage'
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode legacy -ProposedMode disabled).permitted | Should -BeTrue
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode disabled -ProposedMode campaign).permitted | Should -BeTrue
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode campaign -ProposedMode legacy).permitted | Should -BeFalse
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode disabled -ProposedMode legacy -CampaignFactCount 1).reason | Should -Be 'legacy-reactivation-refused-after-campaign-facts'
        (Resolve-ContinuousCoReviewAuthorityTransition -CurrentMode disabled -ProposedMode legacy -CampaignFactCount 0).permitted | Should -BeTrue
    }

    It 'requires two persisted setter calls and refuses legacy reactivation after campaign facts exist' {
        $repo = Join-Path $TestDrive 'setter-repo'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        $path = Write-AuthorityFixture -Name 'setter' -Json '{"schema_version":"1.0","mode":"legacy"}'
        { Set-ContinuousCoReviewAuthorityMode -ConfigPath $path -Mode campaign -RepoRoot $repo } | Should -Throw -ExpectedMessage '*campaign-cutover-requires-disabled-stage*'
        (Set-ContinuousCoReviewAuthorityMode -ConfigPath $path -Mode disabled -RepoRoot $repo).mode | Should -Be 'disabled'
        (Set-ContinuousCoReviewAuthorityMode -ConfigPath $path -Mode campaign -RepoRoot $repo).mode | Should -Be 'campaign'
        (Set-ContinuousCoReviewAuthorityMode -ConfigPath $path -Mode disabled -RepoRoot $repo).mode | Should -Be 'disabled'
        $factDirectory = Join-Path $repo '.specrew/review/authority/campaigns/cmp-demo'
        New-Item -ItemType Directory -Path $factDirectory -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $factDirectory 'fact.json'), '{}')
        { Set-ContinuousCoReviewAuthorityMode -ConfigPath $path -Mode legacy -RepoRoot $repo } | Should -Throw -ExpectedMessage '*legacy-reactivation-refused-after-campaign-facts*'
    }

    It 'keeps the approved component and port map explicit' {
        $map = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'specs/198-beta2-hardening/iterations/006/foundation-map.md') -Raw
        foreach ($required in @(
            'CampaignRepository', 'RunRepository', 'ClaimRepository', 'ReviewTargetPort',
            'HarnessPort', 'RuntimePort', 'ClockPort', 'review-authority-core.ps1',
            'review-authority-store.ps1', 'review-result-ingestor.ps1', 'review-campaign-orchestrator.ps1'
        )) {
            $map | Should -Match ([regex]::Escape($required))
        }
    }
}

Describe 'Legacy service consumes the authority cutover before spawning' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/co-review-service.ps1')
    }

    It 'suppresses the obsolete service before creating state when campaign authority is active' {
        $repo = Join-Path $TestDrive 'campaign-service'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Mock -CommandName Get-ContinuousCoReviewAuthorityDecision -MockWith {
            [pscustomobject]@{
                mode = 'campaign'; valid = $true; legacy_promotion_enabled = $false
                campaign_authority_enabled = $true; reason = 'authority-mode-campaign'
            }
        }
        Mock -CommandName Start-Process -MockWith { throw 'legacy spawn must not be reached' }

        $result = Start-ContinuousCoReviewServiceRun -RepoRoot $repo -RunId 'must-not-run' -TreeId ('a' * 40) -Detached
        $result.status | Should -Be 'suppressed'
        $result.spawned | Should -BeFalse
        $result.authority_mode | Should -Be 'campaign'
        $result.suppressed_reason | Should -Match 'legacy-authority-disabled'
        Test-Path -LiteralPath (Join-Path $repo '.specrew') | Should -BeFalse
        Should -Invoke Start-Process -Times 0 -Exactly
    }
}
