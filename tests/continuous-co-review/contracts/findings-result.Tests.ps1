$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 forced findings result contract' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:FixtureRoot = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/contracts'
    }

    function Copy-FindingsResultFixture {
        $fixturePath = Join-Path $script:FixtureRoot 'findings-result.producer.valid.json'
        return Read-ReviewerContractJson -Path $fixturePath
    }

    function Get-FindingSchemaRequiredFields {
        $schema = Get-ReviewerContractSchema -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot
        return @($schema.properties.findings.items.required)
    }

    It 'forces every finding to carry traceable metadata required by FR-002 and NFR-003' {
        $requiredFields = Get-FindingSchemaRequiredFields

        foreach ($fieldName in @('finding_id', 'location', 'severity', 'kind', 'design_reference', 'comment', 'disposition', 'resolution')) {
            ($requiredFields -contains $fieldName) | Should Be $true
        }
    }

    It 'rejects findings that omit any forced metadata field' {
        foreach ($fieldName in @('finding_id', 'location', 'severity', 'kind', 'design_reference', 'comment', 'disposition', 'resolution')) {
            $dto = Copy-FindingsResultFixture
            $dto.findings[0].PSObject.Properties.Remove($fieldName)

            $result = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto

            $result.Valid | Should Be $false
            ($result.Errors -join "`n") | Should Match "$fieldName is required"
        }
    }

    It 'accepts only the supported severity and disposition values for forced findings' {
        $schema = Get-ReviewerContractSchema -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot
        $severityValues = @($schema.properties.findings.items.properties.severity.enum)
        $dispositionValues = Get-ContinuousCoReviewFindingDispositionValues

        ($severityValues -join ',') | Should Be 'blocking,advisory,nit'
        ($dispositionValues -join ',') | Should Be 'open,accepted_fix_pending,resolved,rejected_with_rationale,escalated_to_human'

        $dto = Copy-FindingsResultFixture
        $dto.findings[0].severity = 'informational'
        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto).Valid | Should Be $false

        $dto = Copy-FindingsResultFixture
        $dto.findings[0].disposition = 'silently_ignored'
        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto).Valid | Should Be $false
    }

    It 'accepts only supported resolution states and preserves resolution evidence fields' {
        $resolutionStates = Get-ContinuousCoReviewFindingResolutionStates
        ($resolutionStates -join ',') | Should Be 'unresolved,resolved,rejected,escalated'

        $dto = Copy-FindingsResultFixture
        $dto.findings[0].resolution.state = 'resolved'
        $dto.findings[0].resolution.fix_evidence_ref = '.specrew/review/inline/run-197-fixture-001/fix-evidence.md'
        $dto.findings[0].resolution.rationale = 'Fixed by the follow-up diff and rechecked by the reviewer.'

        $result = Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto

        $result.Valid | Should Be $true
        @($result.Errors).Count | Should Be 0

        $dto.findings[0].resolution.state = 'text_only_fixed'
        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $dto).Valid | Should Be $false
    }

    It 'derives a stable finding fingerprint from finding metadata rather than object property order' {
        $dto = Copy-FindingsResultFixture
        $finding = $dto.findings[0]
        $reorderedFinding = [pscustomobject][ordered]@{
            comment          = $finding.comment
            design_reference = $finding.design_reference
            kind             = $finding.kind
            severity         = $finding.severity
            location         = $finding.location
            source_run_id    = $finding.source_run_id
            finding_id       = $finding.finding_id
            disposition      = $finding.disposition
            resolution       = $finding.resolution
        }

        $firstFingerprint = New-ContinuousCoReviewFindingFingerprint -Finding $finding
        $secondFingerprint = New-ContinuousCoReviewFindingFingerprint -Finding $reorderedFinding

        $firstFingerprint | Should Match '^sha256:[0-9a-f]{64}$'
        $secondFingerprint | Should Be $firstFingerprint

        $changedFinding = $finding | Select-Object *
        $changedFinding.comment = 'A materially different reviewer comment.'
        (New-ContinuousCoReviewFindingFingerprint -Finding $changedFinding) | Should Not Be $firstFingerprint
    }
}
