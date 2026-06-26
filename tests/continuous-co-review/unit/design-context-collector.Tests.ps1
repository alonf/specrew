$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T013 TG-011 design context collector obeys implementation-rules.yml redaction boundaries' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T013DesignContextCommand {
        $command = Get-Command -Name 'Get-ContinuousCoReviewDesignContext' -ErrorAction SilentlyContinue
        $null = ($command | Should -Not -BeNullOrEmpty)
        return $command
    }

function New-T013FeatureWorkspace {
        $repoPath = Join-Path $TestDrive 'design-context-repo'
        $featureRoot = Join-Path $repoPath 'specs/197-continuous-co-review'
        New-Item -ItemType Directory -Path (Join-Path $featureRoot 'workshop') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $featureRoot 'iterations/001') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $repoPath '.scratch/tmp') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $repoPath '.local/tokens') -Force | Out-Null

        Set-Content -LiteralPath (Join-Path $featureRoot 'spec.md') -Value '# Spec including FR-011' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $featureRoot 'workshop/product-domain.md') -Value '# Workshop decision: review contract' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $featureRoot 'iterations/001/design-analysis.md') -Value '# Design analysis: checkpoint diff provider' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $featureRoot 'implementation-rules.yml') -Value @'
selections:
  - id: code-rule.secure-coding-defaults
    checked: true
  - id: code-rule.simple-trustworthy-tests
    checked: true
  - id: code-rule.testing-posture
    checked: true
'@ -Encoding UTF8

        Set-Content -LiteralPath (Join-Path $repoPath '.env') -Value 'PROPOSAL_197_SECRET=TOP_SECRET_VALUE' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repoPath 'raw-prompt.md') -Value 'RAW PROMPT: include TOP_SECRET_VALUE' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repoPath 'provider-transcript.log') -Value 'RAW TRANSCRIPT token=TOP_SECRET_VALUE' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repoPath '.local/tokens/provider.json') -Value '{"token":"TOP_SECRET_VALUE"}' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repoPath '.scratch/tmp/unrelated.tmp') -Value 'unrelated temp state TOP_SECRET_VALUE' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $repoPath 'ambient-machine-state.json') -Value '{"computerName":"ambient-host","env":"TOP_SECRET_VALUE"}' -Encoding UTF8

        return [pscustomobject]@{
            RepoRoot           = $repoPath
            FeatureRoot        = 'specs/197-continuous-co-review'
            AbsoluteFeatureRoot = $featureRoot
        }
    }
}

    

    

    It 'declares the T013 design context collector command before bounded context is consumed' {
        Get-T013DesignContextCommand | Should -Not -BeNullOrEmpty
    }

    It 'includes spec, workshop, design-analysis, and quality-rule references required by FR-011' {
        $workspace = New-T013FeatureWorkspace

        $command = Get-T013DesignContextCommand
        $context = & $command -RepoRoot $workspace.RepoRoot -FeatureRoot $workspace.FeatureRoot -CheckpointId 'checkpoint-t013-includes'

        ($context.design_context_refs -contains 'specs/197-continuous-co-review/spec.md') | Should -Be $true
        ($context.design_context_refs -contains 'specs/197-continuous-co-review/workshop/product-domain.md') | Should -Be $true
        ($context.design_context_refs -contains 'specs/197-continuous-co-review/iterations/001/design-analysis.md') | Should -Be $true
        ($context.design_context_refs -contains 'specs/197-continuous-co-review/implementation-rules.yml') | Should -Be $true
        ($context.quality_rule_refs -contains 'code-rule.secure-coding-defaults') | Should -Be $true
        ($context.quality_rule_refs -contains 'code-rule.simple-trustworthy-tests') | Should -Be $true
        ($context.quality_rule_refs -contains 'code-rule.testing-posture') | Should -Be $true
    }

    It 'excludes secrets, raw prompts, raw transcripts, token stores, temp files, and unrelated ambient state from context refs' {
        $workspace = New-T013FeatureWorkspace
        $env:PROPOSAL_197_DO_NOT_BUNDLE = 'ENVIRONMENT_SECRET_VALUE'

        $command = Get-T013DesignContextCommand
        $context = & $command -RepoRoot $workspace.RepoRoot -FeatureRoot $workspace.FeatureRoot -CheckpointId 'checkpoint-t013-excludes'

        $allRefs = (@($context.design_context_refs) + @($context.excluded_refs)) -join "`n"
        $contextJson = $context | ConvertTo-Json -Depth 100

        $allRefs | Should -Not -Match '(?i)\.env'
        $allRefs | Should -Not -Match '(?i)raw-prompt'
        $allRefs | Should -Not -Match '(?i)transcript'
        $allRefs | Should -Not -Match '(?i)\.local/tokens'
        $allRefs | Should -Not -Match '(?i)\.scratch/tmp/unrelated'
        $allRefs | Should -Not -Match '(?i)ambient-machine-state'
        $contextJson | Should -Not -Match 'TOP_SECRET_VALUE'
        $contextJson | Should -Not -Match 'ENVIRONMENT_SECRET_VALUE'
    }

    It 'records the redaction boundary as structured evidence without persisting ambient machine state' {
        $workspace = New-T013FeatureWorkspace

        $command = Get-T013DesignContextCommand
        $context = & $command -RepoRoot $workspace.RepoRoot -FeatureRoot $workspace.FeatureRoot -CheckpointId 'checkpoint-t013-redaction-boundary'
        $propertyNames = @($context.PSObject.Properties.Name)
        $contextJson = $context | ConvertTo-Json -Depth 100

        ($propertyNames -contains 'redaction_policy') | Should -Be $true
        $context.redaction_policy.omits_raw_prompts | Should -Be $true
        $context.redaction_policy.omits_raw_transcripts | Should -Be $true
        $context.redaction_policy.omits_environment_variables | Should -Be $true
        $context.redaction_policy.omits_token_stores | Should -Be $true
        $contextJson | Should -Not -Match '(?i)computername|hostname|userprofile|ambient-host'
    }
}
