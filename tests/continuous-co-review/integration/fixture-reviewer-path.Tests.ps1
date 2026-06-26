$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T017 TG-011 fixture reviewer path obeys implementation-rules.yml without live host dependency' {
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
        function Get-T017FixturePathCommand {
                $command = Get-Command -Name 'Invoke-ContinuousCoReviewFixtureReviewerPath' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T017Request {
                return [pscustomobject][ordered]@{
                    schema_version       = '1.0'
                    run_id               = 'run-t017-fixture'
                    checkpoint_id        = 'checkpoint-t017'
                    baseline_ref         = 'baseline-t017'
                    review_kind          = 'code-change-set'
                    change_set           = [pscustomobject][ordered]@{
                        baseline_ref          = 'baseline-t017'
                        diff_ref              = 'diffs/run-t017-fixture.diff'
                        diff_hash             = 'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
                        changed_paths         = @('scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1')
                        reviewable_path_count = 1
                        excluded_paths        = @()
                    }
                    design_context_refs  = @(
                        'specs/197-continuous-co-review/spec.md',
                        'specs/197-continuous-co-review/implementation-rules.yml'
                    )
                    allowed_paths        = @('scripts/internal/continuous-co-review/', 'tests/continuous-co-review/')
                    forbidden_paths      = @('hosts/', 'extensions/specrew-speckit/scripts/provider-adapter.ps1')
                    provider_request     = [pscustomobject][ordered]@{
                        requested_host    = 'fixture'
                        requested_model   = 'fixture-reviewer'
                        authorization_ref = 'local-fixture-only'
                        timeout_seconds   = 60
                        fallback_policy   = 'none'
                    }
                    output_contract      = 'FindingsResult.v1'
                    request_hash         = 'sha256:request-t017-fixture'
                    created_at           = '2026-06-17T21:25:00Z'
                }
            }

        function New-T017FixtureFindingsJson {
                $result = [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = 'run-t017-fixture'
                    status         = 'findings'
                    reviewer       = [pscustomobject][ordered]@{
                        host       = 'fixture'
                        model      = 'fixture-reviewer'
                        adapter_id = 'reviewer-host-adapter-fixture'
                    }
                    findings       = @(
                        [pscustomobject][ordered]@{
                            finding_id       = 'finding-t017-blocking'
                            source_run_id    = 'run-t017-fixture'
                            location         = [pscustomobject][ordered]@{
                                path       = 'scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1'
                                line_start = 10
                                line_end   = 12
                            }
                            severity         = 'blocking'
                            kind             = 'design-contract-violation'
                            design_reference = 'FR-006'
                            comment          = 'Fixture blocking finding prevents checkpoint advancement.'
                            disposition      = 'open'
                            resolution       = [pscustomobject][ordered]@{
                                state            = 'unresolved'
                                fix_evidence_ref = $null
                                rationale        = $null
                            }
                        }
                    )
                    created_at     = '2026-06-17T21:25:00Z'
                }

                return ($result | ConvertTo-Json -Depth 100)
            }
}

    

    

    

    It 'declares the T017 controlled fixture reviewer path command before integration fixtures are consumed' {
        Get-T017FixturePathCommand | Should -Not -BeNullOrEmpty
    }

    It 'runs request bundle to fixture findings result to review thread to blocked gate verdict without a live host' {
        $command = Get-T017FixturePathCommand
        $result = & $command `
            -RepoRoot $script:RepoRoot `
            -RunRoot (Join-Path $TestDrive 'fixture-path-valid') `
            -Request (New-T017Request) `
            -FixtureStdout (New-T017FixtureFindingsJson) `
            -FixtureExitCode 0 `
            -SchemaRoot $script:SchemaRoot

        $result.live_host_invoked | Should -Be $false
        $result.request_bundle.run_id | Should -Be 'run-t017-fixture'
        $result.findings_result.findings[0].severity | Should -Be 'blocking'
        $result.review_thread.run_id | Should -Be 'run-t017-fixture'
        ($result.review_thread.findings -contains 'finding-t017-blocking') | Should -Be $true
        $result.gate_verdict.state | Should -Be 'blocked'
        $result.gate_verdict.unresolved_blocking_count | Should -Be 1
        ($result.gate_verdict.blocking_finding_ids -contains 'finding-t017-blocking') | Should -Be $true

        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $result.findings_result).Valid | Should -Be $true
        (Test-ReviewerContractObject -ContractName 'ReviewThread' -SchemaRoot $script:SchemaRoot -InputObject $result.review_thread).Valid | Should -Be $true
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $result.gate_verdict).Valid | Should -Be $true
    }

    It 'runs the same fixture path into deterministic infrastructure failure and unsafe gate verdict' {
        $command = Get-T017FixturePathCommand
        $result = & $command `
            -RepoRoot $script:RepoRoot `
            -RunRoot (Join-Path $TestDrive 'fixture-path-failure') `
            -Request (New-T017Request) `
            -FixtureStdout '{not-json' `
            -FixtureExitCode 0 `
            -SchemaRoot $script:SchemaRoot

        $result.live_host_invoked | Should -Be $false
        $result.infrastructure_failure.schema_version | Should -Be '1.0'
        $result.infrastructure_failure.category | Should -Be 'invalid-json'
        $result.findings_result | Should -Be $null
        $result.gate_verdict.state | Should -Be 'unsafe'
        $result.gate_verdict.unresolved_blocking_count | Should -Be 0
        ($result.gate_verdict.unsafe_reasons -contains 'invalid-json') | Should -Be $true
        $result.infrastructure_failure.failure_id | Should -Match '^failure-[0-9a-f]{16}$'

        (Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $result.infrastructure_failure).Valid | Should -Be $true
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $result.gate_verdict).Valid | Should -Be $true
    }

    It 'does not persist raw provider stdout, transcript, token, environment, or live-host command evidence in the fixture path' {
        $command = Get-T017FixturePathCommand
        $result = & $command `
            -RepoRoot $script:RepoRoot `
            -RunRoot (Join-Path $TestDrive 'fixture-path-redaction') `
            -Request (New-T017Request) `
            -FixtureStdout 'token=TOP_SECRET raw transcript prompt' `
            -FixtureExitCode 0 `
            -SchemaRoot $script:SchemaRoot
        $resultJson = $result | ConvertTo-Json -Depth 100

        $result.live_host_invoked | Should -Be $false
        $resultJson | Should -Not -Match 'TOP_SECRET'
        $resultJson | Should -Not -Match '(?i)raw stdout|raw_stdout|raw_stderr|transcript|prompt|environment|token'
        $result.provider_invocation.adapter_id | Should -Be 'reviewer-host-adapter-fixture'
    }
}
