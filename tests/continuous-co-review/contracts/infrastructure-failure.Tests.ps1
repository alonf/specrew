$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 infrastructure failure contract' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
    }

    function Get-InfrastructureFailureCases {
        return @(
            @{
                Name = 'timeout'
                Category = 'timeout'
                Message = 'Reviewer process exceeded the configured timeout.'
                Retryable = $true
                FallbackAllowed = $true
                SafeDetails = @{ timeout_seconds = 30; adapter_id = 'fixture' }
            },
            @{
                Name = 'nonzero exit'
                Category = 'nonzero-exit'
                Message = 'Reviewer process exited with a nonzero code.'
                Retryable = $true
                FallbackAllowed = $true
                SafeDetails = @{ exit_code = 2; adapter_id = 'fixture' }
            },
            @{
                Name = 'empty stdout'
                Category = 'empty-stdout'
                Message = 'Reviewer process returned no stdout.'
                Retryable = $true
                FallbackAllowed = $true
                SafeDetails = @{ adapter_id = 'fixture' }
            },
            @{
                Name = 'invalid JSON'
                Category = 'invalid-json'
                Message = 'Reviewer stdout was not valid JSON.'
                Retryable = $false
                FallbackAllowed = $false
                SafeDetails = @{ parser = 'ConvertFrom-Json'; adapter_id = 'fixture' }
            },
            @{
                Name = 'schema mismatch'
                Category = 'schema-mismatch'
                Message = 'Reviewer stdout did not match FindingsResult.'
                Retryable = $false
                FallbackAllowed = $false
                SafeDetails = @{ contract = 'FindingsResult'; adapter_id = 'fixture' }
            },
            @{
                Name = 'missing provider'
                Category = 'missing-provider'
                Message = 'No configured reviewer provider was available.'
                Retryable = $false
                FallbackAllowed = $false
                SafeDetails = @{ requested_provider = 'fixture-missing' }
            },
            @{
                Name = 'unauthorized provider/model'
                Category = 'unauthorized-provider'
                Message = 'The requested reviewer provider or model was not authorized by the user.'
                Retryable = $false
                FallbackAllowed = $false
                SafeDetails = @{ requested_provider = 'paid-fixture'; requested_model = 'paid-reviewer' }
            },
            @{
                Name = 'unavailable requested model'
                Category = 'unavailable-requested-model'
                Message = 'The specifically requested reviewer model was unavailable.'
                Retryable = $false
                FallbackAllowed = $false
                SafeDetails = @{ requested_provider = 'fixture'; requested_model = 'missing-model' }
            },
            @{
                Name = 'command invocation failure'
                Category = 'command-invocation-failure'
                Message = 'The reviewer command could not be invoked.'
                Retryable = $true
                FallbackAllowed = $true
                SafeDetails = @{ command = 'fixture-reviewer'; reason = 'not-found' }
            }
        )
    }

    It 'declares every deterministic infrastructure failure category required by INT-005' {
        $schema = Get-ReviewerContractSchema -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot
        $categoryValues = @($schema.properties.category.enum)

        foreach ($case in Get-InfrastructureFailureCases) {
            ($categoryValues -contains $case.Category) | Should Be $true
        }
    }

    It 'constructs schema-valid fixture failures for timeout, process, parser, schema, provider, model, and invocation failures' {
        foreach ($case in Get-InfrastructureFailureCases) {
            $failure = New-ContinuousCoReviewInfrastructureFailure `
                -Category $case.Category `
                -RunId "run-197-$($case.Category)-fixture" `
                -InvocationId "invocation-197-$($case.Category)-fixture" `
                -Message $case.Message `
                -SafeDetails $case.SafeDetails `
                -Retryable $case.Retryable `
                -FallbackAllowed $case.FallbackAllowed

            $result = Test-ReviewerContractObject -ContractName 'InfrastructureFailure' -SchemaRoot $script:SchemaRoot -InputObject $failure

            $result.Valid | Should Be $true
            @($result.Errors).Count | Should Be 0
            $failure.category | Should Be $case.Category
            $failure.message | Should Be $case.Message
            $failure.retryable | Should Be $case.Retryable
            $failure.fallback_allowed | Should Be $case.FallbackAllowed
        }
    }

    It 'keeps infrastructure failures distinct from no-findings review results' {
        foreach ($case in Get-InfrastructureFailureCases) {
            $failure = New-ContinuousCoReviewInfrastructureFailure `
                -Category $case.Category `
                -RunId "run-197-$($case.Category)-fixture" `
                -Message $case.Message `
                -SafeDetails $case.SafeDetails

            (Test-ReviewerContractPropertyExists -Object $failure -Name 'findings') | Should Be $false
            (Test-ReviewerContractPropertyExists -Object $failure -Name 'status') | Should Be $false
            $failure.category | Should Be $case.Category
        }
    }
}
