$ErrorActionPreference = 'Stop'

# Trace: T053, FR-018, FR-019, INT-010, INT-013, OBS-010, IMPL-009, SC-014, SC-015, TG-013, TG-014.
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T053 ReviewRequest.v2 prompt composer' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:CreatedAt = [datetime] '2026-06-19T00:53:00Z'
    }

    function New-T053ProviderRequest {
        return [pscustomobject][ordered]@{
            requested_host    = 'fixture'
            requested_model   = 'fixture-reviewer'
            authorization_ref = 'local-fixture-only'
            timeout_seconds   = 60
            fallback_policy   = 'none'
        }
    }

    function New-T053ChangeSet {
        return [pscustomobject][ordered]@{
            baseline_ref          = 'baseline-t053'
            diff_ref              = 'diffs/run-t053.diff'
            diff_inline           = "diff --git a/scripts/internal/continuous-co-review/review-prompt-composer.ps1 b/scripts/internal/continuous-co-review/review-prompt-composer.ps1`n+compose prompt`n"
            diff_content          = "diff --git a/scripts/internal/continuous-co-review/review-prompt-composer.ps1 b/scripts/internal/continuous-co-review/review-prompt-composer.ps1`n+compose prompt`n"
            diff_hash             = 'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
            changed_paths         = @('scripts/internal/continuous-co-review/review-prompt-composer.ps1')
            reviewable_path_count = 1
            excluded_paths        = @()
        }
    }

    function New-T053Request {
        return New-ContinuousCoReviewRequest `
            -RunId 'run-t053' `
            -CheckpointId 'checkpoint-t053' `
            -BaselineRef 'baseline-t053' `
            -ChangeSet (New-T053ChangeSet) `
            -DesignContextRefs @('specs/197-continuous-co-review/spec.md', 'specs/197-continuous-co-review/implementation-rules.yml') `
            -AllowedPaths @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/') `
            -ForbiddenPaths @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1') `
            -ProviderRequest (New-T053ProviderRequest) `
            -RoundNumber 2 `
            -PriorFindings @([pscustomobject][ordered]@{ finding_id = 'finding-prior-001'; status = 'accepted_fix_pending' }) `
            -SchemaRoot $script:SchemaRoot `
            -CreatedAt $script:CreatedAt
    }

    It 'builds schema-valid ReviewRequest.v2 with instruction, design, diff, round, policy, and output contract fields' {
        $request = New-T053Request
        $validation = Test-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $script:SchemaRoot -InputObject $request

        $validation.Valid | Should Be $true
        $request.schema_version | Should Be '2.0'
        $request.reviewer_instruction.canonical_path | Should Be 'scripts/internal/continuous-co-review/code-review-agent.md'
        $request.reviewer_instruction.content_hash | Should Match '^sha256:[0-9a-f]{64}$'
        $request.design_context.content | Should Match 'FR-017'
        @($request.design_context.sources).Count | Should BeGreaterThan 1
        $request.change_set.diff_content | Should Match 'compose prompt'
        $request.round_number | Should Be 2
        $request.prior_findings[0].finding_id | Should Be 'finding-prior-001'
        $request.visibility_policy.policy_id | Should Be 'proposal-197-review-visibility.v1'
        $request.do_policy.policy_id | Should Be 'proposal-197-review-do-policy.v1'
        $request.output_contract | Should Be 'FindingsResult.v1'
    }

    It 'composes the exact adapter-bound prompt from canonical instruction and ReviewRequest.v2 fields' {
        $request = New-T053Request
        $prompt = New-ContinuousCoReviewPrompt -Request $request -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt
        $content = $prompt.prompt_content

        $prompt.review_request_hash | Should Be $request.request_hash
        $prompt.reviewer_instruction_hash | Should Be $request.reviewer_instruction.content_hash
        $prompt.diff_hash | Should Be $request.change_set.diff_hash
        $prompt.round_number | Should Be 2
        ($prompt.prior_finding_ids -contains 'finding-prior-001') | Should Be $true
        $content | Should Match 'Proposal 145 Rubric Phases'
        $content | Should Match 'FR-017'
        $content | Should Match 'diff --git'
        $content | Should Match 'finding-prior-001'
        $content | Should Match 'Visibility Policy'
        $content | Should Match 'Do Policy'
        $content | Should Match 'FindingsResult.v1'
    }

    It 'rejects empty or missing exact diff content before prompt composition' {
        $request = New-T053Request
        $request.change_set.diff_content = ''
        $thrown = $false
        try {
            New-ContinuousCoReviewPrompt -Request $request -SchemaRoot $script:SchemaRoot -CreatedAt $script:CreatedAt | Out-Null
        }
        catch {
            $thrown = $true
        }
        $thrown | Should Be $true
    }
}