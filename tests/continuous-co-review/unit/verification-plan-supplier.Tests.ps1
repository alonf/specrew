Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/verification-plan-contract.ps1')
. (Join-Path $repoRoot 'scripts/internal/continuous-co-review/verification-plan-supplier.ps1')

function Get-SupplierCatalog {
    return (Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json') -Raw | ConvertFrom-Json)
}

function New-SupplierPlan {
    param([string]$PlanId = 'fixture.explicit', [string]$Executable = 'fixture-tool')
    return [pscustomobject]@{
        schema_version = '1.0'
        plan_id = $PlanId
        commands = @([pscustomobject]@{
                command_id = 'fixture-command'
                executable = $Executable
                arguments = @('--verify')
                provenance = [pscustomobject]@{ kind = 'project-config'; source = 'fixture' }
            })
    }
}

function Add-SupplierProviderRow {
    param([Parameter(Mandatory)]$Catalog, [string]$ProviderId = 'fixture-forge', [switch]$InvalidPlan)
    $plan = New-SupplierPlan -PlanId 'fixture.provider-plan' -Executable 'fixture-provider-tool'
    $plan.commands[0].provenance = [pscustomobject]@{ kind = 'provider-gated'; source = $ProviderId; provider = $ProviderId }
    if ($InvalidPlan) { $plan.commands[0].arguments = 'not-an-array' }
    $row = [pscustomobject]@{
        entry_id = 'provider.fixture-forge.v1'
        provider_id = $ProviderId
        plan = $plan
    }
    $Catalog.providers = @($Catalog.providers) + @($row)
    return $Catalog
}
}

Describe 'T062 deterministic verification-plan supplier' {
    It 'selects a valid explicit plan first and does not mutate the caller plan' {
        $catalog = Add-SupplierProviderRow -Catalog (Get-SupplierCatalog)
        $explicit = New-SupplierPlan
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -ExplicitPlanPresent -ExplicitPlan $explicit -DetectedMetadataIds @('package-json.scripts-test.v1') -QualityProfileId 'quality-profile.python-fastapi-service.v1' -ActiveProviders @('fixture-forge')

        $result.state | Should -Be 'selected'
        $result.source_kind | Should -Be 'project-config'
        $result.plan.commands[0].provenance.source | Should -Be '.specrew/verification-plan.json'
        @($result.skipped_sources).Count | Should -Be 0
        $explicit.commands[0].provenance.source | Should -Be 'fixture'
    }

    It 'fails closed on a present invalid explicit plan without falling through' {
        $catalog = Get-SupplierCatalog
        $invalid = New-SupplierPlan
        $invalid.commands[0].arguments = 'fixture-tool --verify'
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -ExplicitPlanPresent -ExplicitPlan $invalid -DetectedMetadataIds @('package-json.scripts-test.v1') -QualityProfileId 'quality-profile.python-fastapi-service.v1'

        $result.state | Should -Be 'invalid'
        $result.failure_reason | Should -Be 'verification-plan-invalid'
        $result.source_kind | Should -Be 'project-config'
        $result.plan | Should -BeNullOrEmpty
        $result.action | Should -Match 'Repair or remove the explicit'
    }

    It 'selects only a named project-owned metadata detector and records safe provenance' {
        $catalog = Get-SupplierCatalog
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('package-json.scripts-test.v1')

        $result.state | Should -Be 'selected'
        $result.source_kind | Should -Be 'project-detected'
        $result.source_identity.detector_id | Should -Be 'package-json.scripts-test.v1'
        $result.plan.commands[0].executable | Should -Be 'npm'
        $result.plan.commands[0].arguments | Should -Be @('test')
        $result.plan.commands[0].provenance.kind | Should -Be 'project-detected'
        (Test-ContinuousCoReviewVerificationPlan -Plan $result.plan -RepoRoot $TestDrive).valid | Should -BeTrue
    }

    It 'ignores unknown detector names and extension-only bait' {
        $catalog = Get-SupplierCatalog
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('files-only.py.v1', 'unknown-package-shape.v1')

        $result.state | Should -Be 'verification-not-configured'
        $result.source_kind | Should -BeNullOrEmpty
        $result.failure_reason | Should -Be 'verification-not-configured'
    }

    It 'selects an explicitly named supported quality profile after metadata is ineligible' {
        $catalog = Get-SupplierCatalog
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('unknown.v1') -QualityProfileId 'quality-profile.python-fastapi-service.v1'

        $result.state | Should -Be 'selected'
        $result.source_kind | Should -Be 'profile-selected'
        $result.plan.commands[0].executable | Should -Be 'python'
        $result.plan.commands[0].arguments | Should -Be @('-m', 'pytest')
        $result.plan.commands[0].provenance.profile | Should -Be 'quality-profile.python-fastapi-service.v1'
        @($result.skipped_sources).source_kind | Should -Be @('project-config', 'project-detected')
    }

    It 'does not use an absent or unsupported quality profile' {
        $catalog = Get-SupplierCatalog
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -QualityProfileId 'quality-profile.unsupported.v1'

        $result.state | Should -Be 'verification-not-configured'
        @($result.skipped_sources | Where-Object source_kind -eq 'profile-selected').reason | Should -Be 'no eligible explicit profile'
    }

    It 'selects a provider-gated row only when that exact provider is active' {
        $catalog = Add-SupplierProviderRow -Catalog (Get-SupplierCatalog)
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -ActiveProviders @('FIXTURE-FORGE')

        $result.state | Should -Be 'selected'
        $result.source_kind | Should -Be 'provider-gated'
        $result.source_identity.provider_id | Should -Be 'fixture-forge'
        $result.plan.commands[0].provenance.provider | Should -Be 'fixture-forge'
        @($result.skipped_sources).source_kind | Should -Be @('project-config', 'project-detected', 'profile-selected')
    }

    It 'ignores provider rows when their provider is inactive' {
        $catalog = Add-SupplierProviderRow -Catalog (Get-SupplierCatalog)
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -ActiveProviders @('different-forge')

        $result.state | Should -Be 'verification-not-configured'
        @($result.skipped_sources | Where-Object source_kind -eq 'provider-gated').reason | Should -Be 'no eligible active provider row'
    }

    It 'fails closed when the eligible provider catalog plan is invalid' {
        $catalog = Add-SupplierProviderRow -Catalog (Get-SupplierCatalog) -InvalidPlan
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -ActiveProviders @('fixture-forge')

        $result.state | Should -Be 'invalid'
        $result.source_kind | Should -Be 'provider-gated'
        $result.failure_reason | Should -Be 'verification-plan-invalid'
    }

    It 'rejects unrecognized catalog fields instead of carrying hidden values' {
        $catalog = Get-SupplierCatalog
        $catalog | Add-Member -NotePropertyName hidden_configuration -NotePropertyValue 'SECRET-SENTINEL-DO-NOT-COPY'
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('package-json.scripts-test.v1')

        $result.state | Should -Be 'invalid'
        $result.failure_reason | Should -Be 'verification-plan-invalid'
        ($result | ConvertTo-Json -Depth 10 -Compress) | Should -Not -Match 'SECRET-SENTINEL'
    }

    It 'returns an actionable no-source state without a Specrew or Pester default' {
        $catalog = Get-SupplierCatalog
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog

        $result.state | Should -Be 'verification-not-configured'
        $result.plan | Should -BeNullOrEmpty
        $result.action | Should -Match '\.specrew/verification-plan\.json'
        $result.action | Should -Not -Match 'Pester'
        @($result.skipped_sources).source_kind | Should -Be @('project-config', 'project-detected', 'profile-selected', 'provider-gated')
    }

    It 'produces stable selection and plan identities for identical normalized inputs' {
        $catalog = Get-SupplierCatalog
        $one = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('unknown.v1', 'PACKAGE-JSON.SCRIPTS-TEST.V1') -ActiveProviders @('zeta', 'alpha')
        $two = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @('package-json.scripts-test.v1', 'UNKNOWN.V1') -ActiveProviders @('ALPHA', 'ZETA')

        $one.selection_id | Should -BeExactly $two.selection_id
        $one.plan_digest | Should -BeExactly $two.plan_digest
        (ConvertTo-ContinuousCoReviewSupplierCanonicalJson $one.plan) | Should -BeExactly (ConvertTo-ContinuousCoReviewSupplierCanonicalJson $two.plan)
    }

    It 'keeps source identity and provenance free of supplied secret values' {
        $catalog = Get-SupplierCatalog
        $sentinel = 'SECRET-SENTINEL-DO-NOT-COPY'
        $result = Select-ContinuousCoReviewVerificationPlan -RepoRoot $TestDrive -Catalog $catalog -DetectedMetadataIds @($sentinel, 'package-json.scripts-test.v1') -ActiveProviders @($sentinel)
        $safeProjection = [pscustomobject]@{
            source_identity = $result.source_identity
            skipped_sources = $result.skipped_sources
            provenance = $result.plan.commands[0].provenance
        } | ConvertTo-Json -Depth 10 -Compress

        $safeProjection | Should -Not -Match $sentinel
    }

    It 'ships an exact catalog mirror with a valid bounded catalog' {
        $source = Join-Path $repoRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json'
        $mirror = Join-Path $repoRoot '.specify/extensions/specrew-speckit/data/verification-plan-catalog.json'
        (Get-Content -LiteralPath $source -Raw) | Should -BeExactly (Get-Content -LiteralPath $mirror -Raw)
        (Test-ContinuousCoReviewVerificationPlanCatalog (Get-SupplierCatalog)).valid | Should -BeTrue
        @((Get-SupplierCatalog).providers).Count | Should -Be 0 -Because 'no provider command is safe to invent by default'
    }
}
