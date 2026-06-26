$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T016 TG-011 review result normalizer obeys implementation-rules.yml failure taxonomy' {
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
        $script:CreatedAt = [datetime] '2026-06-17T21:20:00Z'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T016NormalizerCommand {
                $command = Get-Command -Name 'ConvertTo-ContinuousCoReviewNormalizedResult' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T016FindingsResultJson {
                param(
                    [string] $Disposition = 'open',
                    [string] $Status = 'findings'
                )

                $result = [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = 'run-t016'
                    status         = $Status
                    reviewer       = [pscustomobject][ordered]@{
                        host       = 'fixture'
                        model      = 'fixture-reviewer'
                        adapter_id = 'reviewer-host-adapter-fixture'
                    }
                    findings       = @(
                        [pscustomobject][ordered]@{
                            finding_id       = 'finding-t016-001'
                            source_run_id    = 'run-t016'
                            location         = [pscustomobject][ordered]@{
                                path       = 'scripts/internal/continuous-co-review/review-result-normalizer.ps1'
                                line_start = 1
                                line_end   = 3
                            }
                            severity         = 'blocking'
                            kind             = 'design-contract-violation'
                            design_reference = 'FR-002'
                            comment          = 'Fixture blocking finding.'
                            disposition      = $Disposition
                            resolution       = [pscustomobject][ordered]@{
                                state            = 'unresolved'
                                fix_evidence_ref = $null
                                rationale        = $null
                            }
                        }
                    )
                    created_at     = '2026-06-17T21:20:00Z'
                }

                return ($result | ConvertTo-Json -Depth 100)
            }

        function Invoke-T016Normalizer {
                param(
                    [string] $Stdout,
                    [int] $ExitCode = 0,
                    [bool] $TimedOut = $false
                )

                $command = Get-T016NormalizerCommand
                return & $command `
                    -RunId 'run-t016' `
                    -InvocationId 'invocation-t016' `
                    -ExitCode $ExitCode `
                    -Stdout $Stdout `
                    -TimedOut:$TimedOut `
                    -SchemaRoot $script:SchemaRoot `
                    -CreatedAt $script:CreatedAt
            }
}

    

    

    

    It 'declares the T016 result normalizer command before provider stdout is consumed' {
        Get-T016NormalizerCommand | Should -Not -BeNullOrEmpty
    }

    It 'normalizes valid findings JSON into a schema-valid FindingsResult' {
        $normalized = Invoke-T016Normalizer -Stdout (New-T016FindingsResultJson)
        $validation = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $normalized.findings_result

        $normalized.kind | Should -Be 'findings-result'
        $validation.Valid | Should -Be $true
        @($validation.Errors).Count | Should -Be 0
        $normalized.findings_result.status | Should -Be 'findings'
        $normalized.infrastructure_failure | Should -Be $null
    }

    It 'turns invalid JSON into an InfrastructureFailure instead of no findings' {
        $normalized = Invoke-T016Normalizer -Stdout '{not-json'

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'invalid-json'
        $normalized.findings_result | Should -Be $null
    }

    It 'turns empty stdout into an InfrastructureFailure instead of no findings' {
        $normalized = Invoke-T016Normalizer -Stdout ''

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'empty-stdout'
        $normalized.findings_result | Should -Be $null
    }

    It 'turns schema mismatch into an InfrastructureFailure with contract-safe details' {
        $mismatchedJson = ([pscustomobject][ordered]@{
                schema_version = '1.0'
                run_id         = 'run-t016'
                status         = 'findings'
                created_at     = '2026-06-17T21:20:00Z'
            } | ConvertTo-Json -Depth 100)

        $normalized = Invoke-T016Normalizer -Stdout $mismatchedJson

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'schema-mismatch'
        $normalized.infrastructure_failure.safe_details.contract | Should -Be 'FindingsResult'
    }

    It 'turns timeout into an InfrastructureFailure before considering stdout content' {
        $normalized = Invoke-T016Normalizer -Stdout (New-T016FindingsResultJson) -TimedOut $true

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'timeout'
        $normalized.findings_result | Should -Be $null
    }

    It 'turns nonzero exit into an InfrastructureFailure before treating stdout as safe' {
        $normalized = Invoke-T016Normalizer -Stdout (New-T016FindingsResultJson) -ExitCode 2

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'nonzero-exit'
        $normalized.infrastructure_failure.safe_details.exit_code | Should -Be 2
        $normalized.findings_result | Should -Be $null
    }

    It 'treats an unknown blocking disposition as schema-mismatch infrastructure failure' {
        $normalized = Invoke-T016Normalizer -Stdout (New-T016FindingsResultJson -Disposition 'silently_ignored')

        $normalized.kind | Should -Be 'infrastructure-failure'
        $normalized.infrastructure_failure.category | Should -Be 'schema-mismatch'
        $normalized.findings_result | Should -Be $null
    }

    It 'emits deterministic InfrastructureFailure output with no raw stdout, stderr, prompt, transcript, environment, or token data' {
        $stdout = 'token=TOP_SECRET raw transcript prompt should not persist'
        $first = Invoke-T016Normalizer -Stdout $stdout
        $second = Invoke-T016Normalizer -Stdout $stdout
        $failureJson = $first.infrastructure_failure | ConvertTo-Json -Depth 100
        $validation = Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $first.infrastructure_failure

        $validation.Valid | Should -Be $true
        $first.infrastructure_failure.failure_id | Should -Be $second.infrastructure_failure.failure_id
        $failureJson | Should -Not -Match 'TOP_SECRET'
        $failureJson | Should -Not -Match '(?i)raw stdout|raw_stdout|stderr|prompt|transcript|environment|token'
    }
}
