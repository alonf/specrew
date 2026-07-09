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
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T031Command {
                param(
                    [Parameter(Mandatory)]
                    [string] $Name
                )

                $command = Get-Command -Name $Name -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
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

        function New-T031IndependentReviewerConfig {
                return [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    hosts          = @(
                        [pscustomobject][ordered]@{
                            host              = 'claude'
                            model             = 'opus-4.8-1m-context'
                            adapter_id        = 'reviewer-host-adapter-claude-prompt'
                            allowed           = $true
                            installed         = $true
                            review_class_rank = 85
                            model_source      = 'explicit-config'
                            cost_class        = 'default'
                            authorization_ref = 'authz-claude-reviewer'
                            fallback_allowed  = $false
                        }
                        [pscustomobject][ordered]@{
                            host              = 'codex'
                            model             = 'chatgpt'
                            adapter_id        = 'reviewer-host-adapter-codex-exec'
                            allowed           = $true
                            installed         = $true
                            review_class_rank = 85
                            model_source      = 'explicit-config'
                            cost_class        = 'default'
                            authorization_ref = 'authz-codex-reviewer'
                            fallback_allowed  = $false
                        }
                        [pscustomobject][ordered]@{
                            host              = 'copilot'
                            model             = 'gpt-5.5-or-claude-4.8'
                            adapter_id        = 'reviewer-host-adapter-copilot-prompt'
                            allowed           = $true
                            installed         = $true
                            review_class_rank = 80
                            model_source      = 'explicit-config'
                            cost_class        = 'default'
                            authorization_ref = 'authz-copilot-reviewer'
                            fallback_allowed  = $false
                        }
                    )
                }
            }
}

    

    

    

    It 'declares catalog, selection, and authorization commands before reviewer host execution' {
        Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog' | Should -Not -BeNullOrEmpty
        Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate' | Should -Not -BeNullOrEmpty
        Get-T031Command -Name 'Test-ContinuousCoReviewReviewerAuthorization' | Should -Not -BeNullOrEmpty
    }

    It 'loads only non-secret host/model configuration and never carries credentials, tokens, or provider transcripts' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)
        $catalogJson = $catalog | ConvertTo-Json -Depth 100

        $catalog.schema_version | Should -Be '1.0'
        @($catalog.hosts).Count | Should -Be 3
        $catalogJson | Should -Not -Match '(?i)credential|secret|token|api[_-]?key|raw[_-]?prompt|transcript|stdout|stderr'
    }

    It 'registers only reviewer-domain adapter ids and rejects provider-adapter or F-184 provider naming' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)
        $adapterIds = @($catalog.hosts | ForEach-Object { $_.adapter_id })

        foreach ($adapterId in $adapterIds) {
            $adapterId | Should -Match '^reviewer-host-adapter-[a-z0-9-]+$'
        }
        ($adapterIds -join ',') | Should -Not -Match 'provider-adapter|provider-generic|provider-github|host-runtime|shared-governance'
    }

    It 'treats volatile model ids as configuration data instead of hardcoded contract policy' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration (New-T031CatalogConfig)

        $configuredFutureModel = @($catalog.hosts | Where-Object { $_.host -eq 'claude' })[0]
        $configuredFutureModel.model | Should -Be 'human-entered-future-reviewer-model-999'
        $configuredFutureModel.model_source | Should -Be 'human-entered'
    }

    It 'ranks Codex plus ChatGPT and Claude plus Opus 4.8 1M as peer top reviewers above Copilot and other hosts' {
        $command = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $catalog = & $command -Configuration $null -CommandResolver { param([string]$CommandName) return $true }
        $byHost = @{}
        foreach ($entry in @($catalog.hosts)) {
            $byHost[$entry.host] = $entry
        }

        $byHost['codex'].review_class_rank | Should -Be 85
        $byHost['codex'].model | Should -Be 'chatgpt'
        $byHost['claude'].review_class_rank | Should -Be 85
        $byHost['claude'].model | Should -Be 'opus-4.8-1m-context'
        $byHost['copilot'].review_class_rank | Should -Be 80
        $byHost['copilot'].model | Should -Be 'gpt-5.5-or-claude-4.8'
        $byHost['cursor-agent'].review_class_rank | Should -BeLessThan 80
        $byHost['antigravity'].review_class_rank | Should -BeLessThan 80
    }

    It 'prefers the strongest available authorized review-class model without requiring cross-host review' {
        $catalogCommand = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $selectCommand = Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate'
        $catalog = & $catalogCommand -Configuration (New-T031CatalogConfig)

        $selection = & $selectCommand -Catalog $catalog -RequestedHost $null -RequestedModel $null

        $selection.host | Should -Be 'copilot'
        $selection.model | Should -Be 'review-class-strong'
        $selection.adapter_id | Should -Be 'reviewer-host-adapter-copilot-prompt'
        $selection.authorization_ref | Should -Be 'authz-copilot-strong'
        $selection.selection_reason | Should -Match 'review-class'
    }

    It 'prefers Codex review when Claude wrote the code' {
        $catalogCommand = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $selectCommand = Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate'
        $catalog = & $catalogCommand -Configuration (New-T031IndependentReviewerConfig)

        $selection = & $selectCommand -Catalog $catalog -RequestedHost $null -RequestedModel $null -CodeWriterHost 'claude'

        $selection.host | Should -Be 'codex'
        $selection.model | Should -Be 'chatgpt'
        $selection.selection_reason | Should -Be 'preferred-independent-reviewer-for-code-writer-host'
    }

    It 'prefers Claude review when Codex wrote the code' {
        $catalogCommand = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $selectCommand = Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate'
        $catalog = & $catalogCommand -Configuration (New-T031IndependentReviewerConfig)

        $selection = & $selectCommand -Catalog $catalog -RequestedHost $null -RequestedModel $null -CodeWriterHost 'codex'

        $selection.host | Should -Be 'claude'
        $selection.model | Should -Be 'opus-4.8-1m-context'
        $selection.selection_reason | Should -Be 'preferred-independent-reviewer-for-code-writer-host'
    }

    It 'uses the single available harness when no independent peer reviewer is eligible' {
        $catalogCommand = Get-T031Command -Name 'Get-ContinuousCoReviewReviewerHostCatalog'
        $selectCommand = Get-T031Command -Name 'Select-ContinuousCoReviewReviewerCandidate'
        $configuration = New-T031IndependentReviewerConfig
        foreach ($entry in @($configuration.hosts)) {
            if ($entry.host -ne 'claude') {
                $entry.allowed = $false
            }
        }
        $catalog = & $catalogCommand -Configuration $configuration

        $selection = & $selectCommand -Catalog $catalog -RequestedHost $null -RequestedModel $null -CodeWriterHost 'claude'

        $selection.host | Should -Be 'claude'
        $selection.model | Should -Be 'opus-4.8-1m-context'
        # T093/FR-035: the single-harness case IS the same-host fallback - it fires (never blocks) and
        # says so, instead of the old unlabelled generic rank reason.
        $selection.selection_reason | Should -Be 'same-host-fallback-no-independent-authorized'
        $selection.independence | Should -Be 'same-host'
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

        $authorization.authorized | Should -Be $false
        $authorization.category | Should -Be 'unauthorized-provider'
        ($authorization | ConvertTo-Json -Depth 20) | Should -Not -Match '(?i)token|secret|credential'
    }

    It 'invokes the codex reviewer with sandbox bypass (the worktree IS the external sandbox), never the inner workspace-write sandbox' {
        # D-197-I009-009 / T102: codex's inner restricted-token sandbox hangs on per-run worktree trust + needs its
        # helper resolvable; the ephemeral worktree already isolates, so the codex row bypasses it. This locks that in.
        $cmd = Get-T031Command -Name 'Get-ContinuousCoReviewHostAgenticCommand'
        $codex = & $cmd -HostName 'codex'
        $codex.file | Should -Be 'codex'
        @($codex.pre_args) | Should -Contain '--dangerously-bypass-approvals-and-sandbox'
        @($codex.pre_args) | Should -Not -Contain 'workspace-write'
        @($codex.pre_args) | Should -Not -Contain '--sandbox'
        # claude reviewer keeps its own permission-bypass invocation (unchanged by this fix)
        $claude = & $cmd -HostName 'claude'
        @($claude.pre_args) | Should -Contain 'bypassPermissions'
    }

    It 'does not depend on live web search for runtime reviewer catalog discovery' {
        $sourcePath = Join-Path $script:ReviewerModuleRoot 'reviewer-host-catalog.ps1'
        (Test-Path -LiteralPath $sourcePath -PathType Leaf) | Should -Be $true
        $source = Get-Content -LiteralPath $sourcePath -Raw

        $source | Should -Not -Match '(?i)web_search|Invoke-WebRequest|Invoke-RestMethod|curl\s+https?|fetch\s*\(|live web'
    }
}
