$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 reviewer contracts' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:FixtureRoot = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/contracts'
        $script:Contracts = @(
            @{ Name = 'ReviewRequest'; Prefix = 'review-request' }
            @{ Name = 'FindingsResult'; Prefix = 'findings-result' }
            @{ Name = 'ReviewThread'; Prefix = 'review-thread' }
            @{ Name = 'GateVerdict'; Prefix = 'gate-verdict' }
            @{ Name = 'InfrastructureFailure'; Prefix = 'infrastructure-failure' }
            @{ Name = 'SpawnInvocation'; Prefix = 'spawn-invocation' }
        )
    }

    It 'loads every contract schema from the feature contract directory' {
        foreach ($contract in $script:Contracts) {
            $schema = Get-ReviewerContractSchema -ContractName $contract.Name -SchemaRoot $script:SchemaRoot
            $schema.title | Should Be $contract.Name
            ($schema.required.Count -gt 0) | Should Be $true
        }
    }

    It 'round-trips producer and consumer fixtures through the matching contract validators' {
        foreach ($contract in $script:Contracts) {
            foreach ($role in @('producer', 'consumer')) {
                $fixturePath = Join-Path $script:FixtureRoot "$($contract.Prefix).$role.valid.json"
                $result = Test-ReviewerContractJson -ContractName $contract.Name -SchemaRoot $script:SchemaRoot -Json (Get-Content -LiteralPath $fixturePath -Raw)

                $result.Valid | Should Be $true
                @($result.Errors).Count | Should Be 0
            }
        }
    }

    It 'rejects unknown major schema versions before a checkpoint can consume the DTO' {
        $fixturePath = Join-Path $script:FixtureRoot 'review-request.producer.valid.json'
        $dto = Read-ReviewerContractJson -Path $fixturePath
        $dto.schema_version = '3.0'

        $result = Test-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $script:SchemaRoot -InputObject $dto

        $result.Valid | Should Be $false
        ($result.Errors -join "`n") | Should Match 'Unknown schema major version'
    }

    It 'rejects missing required contract fields' {
        $fixturePath = Join-Path $script:FixtureRoot 'review-request.producer.valid.json'
        $dto = Read-ReviewerContractJson -Path $fixturePath
        $dto.PSObject.Properties.Remove('run_id')

        $result = Test-ReviewerContractObject -ContractName 'ReviewRequest' -SchemaRoot $script:SchemaRoot -InputObject $dto

        $result.Valid | Should Be $false
        ($result.Errors -join "`n") | Should Match '\$\.run_id is required'
    }

    It 'rejects missing forced findings fields' {
        $fixturePath = Join-Path $script:FixtureRoot 'findings-result.producer.valid.json'
        $dto = Read-ReviewerContractJson -Path $fixturePath
        $dto.findings[0].PSObject.Properties.Remove('design_reference')

        $result = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto

        $result.Valid | Should Be $false
        ($result.Errors -join "`n") | Should Match 'design_reference is required'
    }

    It 'rejects array contract fields supplied as scalar objects' {
        $fixturePath = Join-Path $script:FixtureRoot 'findings-result.producer.valid.json'
        $dto = Read-ReviewerContractJson -Path $fixturePath
        $dto.findings = $dto.findings[0]

        $result = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto

        $result.Valid | Should Be $false
        ($result.Errors -join "`n") | Should Match '\$\.findings has the wrong JSON type'
    }

    It 'does not introduce dependency imports or protected-surface dot-sourcing' {
        $scriptPaths = @(
            (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
            (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewer-contracts.ps1')
        )

        $combined = (($scriptPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join "`n")

        $combined | Should Not Match '(?im)^\s*#requires\s+-modules'
        $combined | Should Not Match '(?im)^\s*Import-Module\b'
        $combined | Should Not Match '(?im)\bInstall-Module\b'
        $combined | Should Not Match 'hosts/'
        $combined | Should Not Match 'validate-governance\.ps1'
        $combined | Should Not Match 'provider-adapter\.ps1'
        $combined | Should Not Match 'shared-governance\.ps1'
    }
}
