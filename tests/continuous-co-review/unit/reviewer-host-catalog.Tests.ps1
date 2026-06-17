$ErrorActionPreference = 'Stop'

# Trace: T031, FR-016, INT-006, INT-007, INT-008, OPS-004, SC-010, TG-011.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T031 TG-011 reviewer host catalog obeys implementation-rules.yml non-secret authorization policy' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:ReviewerModuleRoot = Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review'
    }

    function Get-T031Command {
        param(
            [Parameter(Mandatory)]
            [string] $Name
        )

        $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T031CatalogConfig {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            hosts          = @(
                [pscustomobject][ordered]@{
                    host              = 'copilot'
                    model             = 'review-class-strong'
                    adapter_id        = 'reviewer-host-adapter-copilot-prompt'
                    allowed           = $true
                    installed         = $true
                    review_class_rank = 100
                    model_source      = 'explicit-config'
                    cost_class        = 'paid'
                    authorization_ref = 'authz-copilot-strong'
                    fallback_allowed  = $true
                }
                [pscustomobject][ordered]@{
                    host              = 'claude'
                    model             = 'human-entered-future-reviewer-model-999'
                    adapter_id        = 'reviewer-host-adapter-claude-prompt'
                    allowed           = $true
                    installed         = $true
                    review_class_rank = 80
                    model_source      = 'human-entered'
                    cost_class        = 'non-default'
                    authorization_ref = 'authz-claude-future'
                    fallback_allowed  = $true
                }
                [pscustomobject][ordered]@{
                    host              = 'fixture'
                    model             = 'fixture-reviewer'
                    adapter_id        = 'reviewer-host-adapter-fixture'
                    allowed           = $true
                    installed         = $true
                    review_class_rank = 10
                    model_source      = 'explicit-config'
                    cost_class        = 'default'
                    authorization_ref = 'local-fixture-only'
                    fallback_allowed  = $false
                }
            )
        }
    }

    It 'declares catalog, selection, and authorization commands before reviewer host execution' {
        Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog' | Should Not BeNullOrEmpty
        Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate' | Should Not BeNullOrEmpty
        Get-T031Command -Name 'Test-ContinuousCoReviewReviewerAuthorization' | Should Not BeNullOrEmpty
    }

    It 'loads only non-secret host/model configuration and never carries credentials, tokens, or provider transcripts' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)
        $catalogJson = $catalog | ConvertTo-Json -Depth 100

        $catalog.schema_version | Should Be '1.0'
        @($catalog.hosts).Count | Should Be 3
        $catalogJson | Should Not Match '(?i)credential|secret|token|api[_-]?key|raw[_-]?prompt|transcript|stdout|stderr'
    }

    It 'registers only reviewer-domain adapter ids and rejects provider-adapter or F-184 provider naming' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)
        $adapterIds = @($catalog.hosts | ForEach-Object { $_.adapter_id })

        foreach ($adapterId in $adapterIds) {
            $adapterId | Should Match '^reviewer-host-adapter-[a-z0-9-]+$'
        }
        ($adapterIds -join ',') | Should Not Match 'provider-adapter|provider-generic|provider-github|host-runtime|shared-governance'
    }

    It 'treats volatile model ids as configuration data instead of hardcoded contract policy' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)

        $configuredFutureModel = @($catalog.hosts | Where-Object { $_.host -eq 'claude' })[0]
        $configuredFutureModel.model | Should Be 'human-entered-future-reviewer-model-999'
        $configuredFutureModel.model_source | Should Be 'human-entered'
    }

    It 'prefers the strongest available authorized review-class model without requiring cross-host review' {
        $catalogCommand = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $selectCommand = Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate'
        $catalog = & $catalogCommand -Configuration (New-T031CatalogConfig)

        $selection = & $selectCommand -Catalog $catalog -RequestedHost $null -RequestedModel $null

        $selection.host | Should Be 'copilot'
        $selection.model | Should Be 'review-class-strong'
        $selection.adapter_id | Should Be 'reviewer-host-adapter-copilot-prompt'
        $selection.authorization_ref | Should Be 'authz-copilot-strong'
        $selection.selection_reason | Should Match 'review-class'
    }

    It 'requires explicit authorization before paid, external, non-default, or newly added reviewer spawning' {
        $authorizationCommand = Get-T031Command -Name 'Test-ContinuousCoReviewReviewerAuthorization'
        $candidate = [pscustomobject][ordered]@{
            host              = 'antigravity'
            model             = 'newly-added-reviewer-model'
            adapter_id        = 'reviewer-host-adapter-antigravity-prompt'
            cost_class        = 'paid'
            model_source      = 'human-entered'
            authorization_ref = $null
        }

        $authorization = & $authorizationCommand -Candidate $candidate

        $authorization.authorized | Should Be $false
        $authorization.category | Should Be 'unauthorized-provider'
        ($authorization | ConvertTo-Json -Depth 20) | Should Not Match '(?i)token|secret|credential'
    }

    It 'does not depend on live web search for runtime reviewer catalog discovery' {
        $sourcePath = Join-Path $script:ReviewerModuleRoot 'reviewer-host-catalog.ps1'
        (Test-Path -LiteralPath $sourcePath -PathType Leaf) | Should Be $true
        $source = Get-Content -LiteralPath $sourcePath -Raw

        $source | Should Not Match '(?i)web_search|Invoke-WebRequest|Invoke-RestMethod|curl\s+https?|fetch\s*\(|live web'
    }
}
