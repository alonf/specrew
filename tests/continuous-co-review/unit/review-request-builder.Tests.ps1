$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T014 TG-011 review request builder obeys implementation-rules.yml contract fields' {
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
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T014ReviewRequestCommand {
                $command = Get-Command -Name 'New-ContinuousCoReviewRequest' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T014ChangeSet {
                param(
                    [string[]] $ChangedPaths = @('scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1')
                )

                return [pscustomobject][ordered]@{
                    baseline_ref          = 'baseline-t014'
                    diff_ref              = 'diffs/run-t014.diff'
                    diff_inline           = "diff --git a/file.ps1 b/file.ps1`n+changed`n"
                    diff_content          = "diff --git a/file.ps1 b/file.ps1`n+changed`n"
                    diff_hash             = 'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                    changed_paths         = $ChangedPaths
                    reviewable_path_count = $ChangedPaths.Count
                    excluded_paths        = @()
                }
            }

        function New-T014ProviderRequest {
                return [pscustomobject][ordered]@{
                    requested_host    = 'fixture'
                    requested_model   = 'fixture-reviewer'
                    authorization_ref = 'local-fixture-only'
                    timeout_seconds   = 60
                    fallback_policy   = 'none'
                }
            }

        function Invoke-T014RequestBuilder {
                param(
                    [object] $ChangeSet = (New-T014ChangeSet),
                    [string] $RunId = 'run-t014-001'
                )

                $command = Get-T014ReviewRequestCommand
                return & $command `
                    -RunId $RunId `
                    -CheckpointId 'checkpoint-t014' `
                    -BaselineRef 'baseline-t014' `
                    -ChangeSet $ChangeSet `
                    -DesignContextRefs @(
                        'specs/197-continuous-co-review/spec.md',
                        'specs/197-continuous-co-review/implementation-rules.yml'
                    ) `
                    -AllowedPaths @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/') `
                    -ForbiddenPaths @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1') `
                    -ProviderRequest (New-T014ProviderRequest) `
                    -CreatedAt ([datetime] '2026-06-17T21:00:00Z')
            }
}

    

    

    

    

    It 'declares the T014 review request builder command before ReviewRequest DTOs are consumed' {
        Get-T014ReviewRequestCommand | Should -Not -BeNullOrEmpty
    }

    It 'builds a schema-valid ReviewRequest with run, checkpoint, baseline, code-change-set kind, contract, and timestamp' {
        $request = Invoke-T014RequestBuilder
        $validation = Test-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $script:SchemaRoot -InputObject $request

        $validation.Valid | Should -Be $true
        @($validation.Errors).Count | Should -Be 0
        $request.schema_version | Should -Be '2.0'
        $request.run_id | Should -Be 'run-t014-001'
        $request.checkpoint_id | Should -Be 'checkpoint-t014'
        $request.baseline_ref | Should -Be 'baseline-t014'
        $request.review_kind | Should -Be 'code-change-set'
        $request.output_contract | Should -Be 'FindingsResult.v1'
        $request.created_at | Should -Be '2026-06-17T21:00:00Z'
        $request.reviewer_instruction.canonical_path | Should -Be 'scripts/internal/continuous-co-review/code-review-agent.md'
        $request.reviewer_instruction.content_hash | Should -Match '^sha256:[0-9a-f]{64}$'
        $request.design_context.content | Should -Match 'specs/197-continuous-co-review/spec.md'
        @($request.design_context.sources).Count | Should -BeGreaterThan 0
        $request.round_number | Should -Be 1
        @($request.prior_findings).Count | Should -Be 0
        $request.visibility_policy.policy_id | Should -Be 'proposal-197-review-visibility.v1'
        $request.do_policy.policy_id | Should -Be 'proposal-197-review-do-policy.v1'
    }

    It 'carries deterministic change-set, allowed path, and forbidden path policy for SC-011' {
        $request = Invoke-T014RequestBuilder

        $request.change_set.diff_hash | Should -Be 'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        $request.change_set.diff_content | Should -Match 'diff --git'
        ($request.change_set.changed_paths -contains 'scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1') | Should -Be $true
        ($request.allowed_paths -contains 'scripts/internal/continuous-co-review/') | Should -Be $true
        ($request.allowed_paths -contains 'tests/continuous-co-review/') | Should -Be $true
        ($request.forbidden_paths -contains 'hosts/') | Should -Be $true
        ($request.forbidden_paths -contains 'extensions/specrew-speckit/scripts/provider-adapter.ps1') | Should -Be $true
    }

    It 'carries explicit provider request authorization and timeout fields without provider transcript data' {
        $request = Invoke-T014RequestBuilder
        $requestJson = $request.provider_request | ConvertTo-Json -Depth 20

        $request.provider_request.requested_host | Should -Be 'fixture'
        $request.provider_request.requested_model | Should -Be 'fixture-reviewer'
        $request.provider_request.authorization_ref | Should -Be 'local-fixture-only'
        $request.provider_request.timeout_seconds | Should -Be 60
        $request.provider_request.fallback_policy | Should -Be 'none'
        $requestJson | Should -Not -Match '(?i)raw[_ -]?transcript|raw_stdout|raw_stderr'
    }

    It 'rejects a request whose change-set crosses forbidden path policy' {
        $command = Get-T014ReviewRequestCommand
        $forbiddenChangeSet = New-T014ChangeSet -ChangedPaths @('hosts/_registry.ps1')

        $threw = $false
        try {
            & $command `
                -RunId 'run-t014-forbidden' `
                -CheckpointId 'checkpoint-t014' `
                -BaselineRef 'baseline-t014' `
                -ChangeSet $forbiddenChangeSet `
                -DesignContextRefs @('specs/197-continuous-co-review/spec.md') `
                -AllowedPaths @('scripts/internal/continuous-co-review/') `
                -ForbiddenPaths @('hosts/') `
                -ProviderRequest (New-T014ProviderRequest) `
                -CreatedAt ([datetime] '2026-06-17T21:00:00Z')
        }
        catch {
            $threw = $true
        }

        $threw | Should -Be $true
    }

    It 'derives a stable request hash from request content and changes it when the request changes' {
        $first = Invoke-T014RequestBuilder -RunId 'run-t014-hash'
        $second = Invoke-T014RequestBuilder -RunId 'run-t014-hash'
        $changed = Invoke-T014RequestBuilder -RunId 'run-t014-hash-changed'

        $first.request_hash | Should -Match '^sha256:[0-9a-f]{64}$'
        $second.request_hash | Should -Be $first.request_hash
        $changed.request_hash | Should -Not -Be $first.request_hash
    }
}
