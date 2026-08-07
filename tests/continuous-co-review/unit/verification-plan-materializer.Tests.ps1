Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    . (Join-Path $repoRoot 'scripts/internal/continuous-co-review/verification-plan-materializer.ps1')

    function New-MaterializerProject {
        param([Parameter(Mandatory)][string]$Name)
        $path = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        return $path
    }

    function Write-PackageTestScript {
        param([Parameter(Mandatory)][string]$Project, [AllowNull()][string]$TestScript)
        $package = if ($null -eq $TestScript) { [ordered]@{ name = 'fixture' } } else { [ordered]@{ name = 'fixture'; scripts = [ordered]@{ test = $TestScript } } }
        [System.IO.File]::WriteAllText((Join-Path $Project 'package.json'), ($package | ConvertTo-Json -Depth 5 -Compress), [System.Text.UTF8Encoding]::new($false))
    }

    function Get-MaterializerPlanPath { param([string]$Project) return (Join-Path $Project '.specrew/verification-plan.json') }
    function Get-MaterializerMarkerPath { param([string]$Project) return (Join-Path $Project '.specrew/verification-plan.generated.json') }

    function Write-MaterializerCatalog {
        param([Parameter(Mandatory)][string]$Path, [scriptblock]$Change)
        $catalog = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json') -Raw | ConvertFrom-Json
        if ($null -ne $Change) { & $Change $catalog }
        [System.IO.File]::WriteAllText($Path, ($catalog | ConvertTo-Json -Depth 30), [System.Text.UTF8Encoding]::new($false))
        return $catalog
    }
}

Describe 'T063 verification-plan materialization and guarded refresh' {
    It 'recognizes only a real package.json scripts.test declaration' {
        $valid = New-MaterializerProject 'detector-valid'
        Write-PackageTestScript $valid 'node test.js'
        Get-ContinuousCoReviewProjectMetadataIds $valid | Should -Be @('package-json.scripts-test.v1')

        $placeholder = New-MaterializerProject 'detector-placeholder'
        Write-PackageTestScript $placeholder 'echo "Error: no test specified" && exit 1'
        @(Get-ContinuousCoReviewProjectMetadataIds $placeholder).Count | Should -Be 0

        $extensionBait = New-MaterializerProject 'detector-extension-bait'
        [System.IO.File]::WriteAllText((Join-Path $extensionBait 'tests.py'), 'assert True')
        @(Get-ContinuousCoReviewProjectMetadataIds $extensionBait).Count | Should -Be 0
    }

    It 'materializes a canonical plan and ownership marker, then becomes byte-idempotent' {
        $project = New-MaterializerProject 'fresh'
        Write-PackageTestScript $project 'node test.js'
        $first = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project
        $planPath = Get-MaterializerPlanPath $project
        $markerPath = Get-MaterializerMarkerPath $project
        $beforePlan = Get-Content -LiteralPath $planPath -Raw
        $beforeMarker = Get-Content -LiteralPath $markerPath -Raw
        $second = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project

        $first.action | Should -Be 'created-generated-plan'
        $first.selection.source_kind | Should -Be 'project-detected'
        (Test-ContinuousCoReviewVerificationPlan -Plan ($beforePlan | ConvertFrom-Json) -RepoRoot $project).valid | Should -BeTrue
        $second.action | Should -Be 'generated-plan-current'
        $second.mutated | Should -BeFalse
        (Get-Content -LiteralPath $planPath -Raw) | Should -BeExactly $beforePlan
        (Get-Content -LiteralPath $markerPath -Raw) | Should -BeExactly $beforeMarker
    }

    It 'reports a dry-run creation without mutating the project' {
        $project = New-MaterializerProject 'preview'
        Write-PackageTestScript $project 'node test.js'
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project -PreviewOnly

        $result.action | Should -Be 'would-create-generated-plan'
        $result.mutated | Should -BeFalse
        Test-Path -LiteralPath (Get-MaterializerPlanPath $project) | Should -BeFalse
        Test-Path -LiteralPath (Get-MaterializerMarkerPath $project) | Should -BeFalse
    }

    It 'preserves a valid explicit plan byte-for-byte and never writes a generated marker' {
        $project = New-MaterializerProject 'explicit'
        New-Item -ItemType Directory -Path (Join-Path $project '.specrew') | Out-Null
        $explicitBytes = '{ "schema_version": "1.0", "plan_id": "user-plan", "commands": [{ "command_id": "user", "executable": "custom-tool", "arguments": [], "provenance": { "kind": "project-config", "source": "user" } }] }'
        [System.IO.File]::WriteAllText((Get-MaterializerPlanPath $project), $explicitBytes, [System.Text.UTF8Encoding]::new($false))
        Write-PackageTestScript $project 'node test.js'
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project

        $result.action | Should -Be 'preserved-explicit-plan'
        $result.mutated | Should -BeFalse
        (Get-Content -LiteralPath (Get-MaterializerPlanPath $project) -Raw) | Should -BeExactly $explicitBytes
        Test-Path -LiteralPath (Get-MaterializerMarkerPath $project) | Should -BeFalse
    }

    It 'preserves an invalid explicit plan and refuses lower-precedence package metadata' {
        $project = New-MaterializerProject 'invalid-explicit'
        New-Item -ItemType Directory -Path (Join-Path $project '.specrew') | Out-Null
        $invalidBytes = '{"schema_version":"1.0","plan_id":"invalid","commands":[{"command_id":"bad","executable":"x","arguments":"x --test"}]}'
        [System.IO.File]::WriteAllText((Get-MaterializerPlanPath $project), $invalidBytes, [System.Text.UTF8Encoding]::new($false))
        Write-PackageTestScript $project 'node test.js'
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project

        $result.state | Should -Be 'invalid'
        $result.action | Should -Be 'preserved-invalid-explicit-plan'
        $result.selection.source_kind | Should -Be 'project-config'
        (Get-Content -LiteralPath (Get-MaterializerPlanPath $project) -Raw) | Should -BeExactly $invalidBytes
        Test-Path -LiteralPath (Get-MaterializerMarkerPath $project) | Should -BeFalse
    }

    It 'refreshes an unchanged generated plan when the reviewed catalog changes' {
        $project = New-MaterializerProject 'refresh'
        Write-PackageTestScript $project 'node test.js'
        $catalogPath = Join-Path $project 'catalog.json'
        Write-MaterializerCatalog -Path $catalogPath | Out-Null
        $null = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project -CatalogPath $catalogPath
        $before = Get-Content -LiteralPath (Get-MaterializerPlanPath $project) -Raw
        Write-MaterializerCatalog -Path $catalogPath -Change { param($catalog) $catalog.project_metadata[0].plan.commands[0].label = 'Updated catalog label' } | Out-Null
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project -CatalogPath $catalogPath
        $after = Get-Content -LiteralPath (Get-MaterializerPlanPath $project) -Raw

        $result.action | Should -Be 'refreshed-generated-plan'
        $result.mutated | Should -BeTrue
        $after | Should -Not -BeExactly $before
        ($after | ConvertFrom-Json).commands[0].label | Should -Be 'Updated catalog label'
    }

    It 'warns and preserves a project-modified generated plan byte-for-byte' {
        $project = New-MaterializerProject 'modified'
        Write-PackageTestScript $project 'node test.js'
        $null = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project
        $planPath = Get-MaterializerPlanPath $project
        $modified = (Get-Content -LiteralPath $planPath -Raw) + ' '
        [System.IO.File]::WriteAllText($planPath, $modified, [System.Text.UTF8Encoding]::new($false))
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project

        $result.state | Should -Be 'preserved-modified'
        $result.action | Should -Be 'preserved-modified-generated-plan'
        $result.warning | Should -Match 'preserving both files byte-for-byte'
        (Get-Content -LiteralPath $planPath -Raw) | Should -BeExactly $modified
    }

    It 'removes only an unchanged generated plan when its trustworthy source disappears' {
        $project = New-MaterializerProject 'source-removed'
        Write-PackageTestScript $project 'node test.js'
        $null = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project
        Write-PackageTestScript $project $null
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project

        $result.state | Should -Be 'verification-not-configured'
        $result.action | Should -Be 'removed-unconfigured-generated-plan'
        Test-Path -LiteralPath (Get-MaterializerPlanPath $project) | Should -BeFalse
        Test-Path -LiteralPath (Get-MaterializerMarkerPath $project) | Should -BeFalse
        $result.warning | Should -Match 'Create \.specrew/verification-plan\.json'
    }

    It 'materializes an explicitly supplied supported quality profile' {
        $project = New-MaterializerProject 'profile'
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project -QualityProfileId 'quality-profile.python-fastapi-service.v1'

        $result.state | Should -Be 'selected'
        $result.selection.source_kind | Should -Be 'profile-selected'
        $result.selection.plan.commands[0].executable | Should -Be 'python'
    }

    It 'reads the recorded project provider but selects it only when a catalog row exists' {
        $project = New-MaterializerProject 'provider'
        New-Item -ItemType Directory -Path (Join-Path $project '.specrew') | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $project '.specrew/repository-governance.yml'), "repository_governance:`n  provider: fixture-forge`n")
        $catalogPath = Join-Path $project 'provider-catalog.json'
        Write-MaterializerCatalog -Path $catalogPath -Change {
            param($catalog)
            $catalog.providers = @([pscustomobject]@{
                    entry_id = 'provider.fixture-forge.v1'
                    provider_id = 'fixture-forge'
                    plan = [pscustomobject]@{
                        schema_version = '1.0'; plan_id = 'provider-plan'
                        commands = @([pscustomobject]@{
                                command_id = 'provider-check'; executable = 'fixture-tool'; arguments = @('--check')
                                provenance = [pscustomobject]@{ kind = 'provider-gated'; source = 'fixture-forge'; provider = 'fixture-forge' }
                            })
                    }
                })
        } | Out-Null
        $result = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $project -CatalogPath $catalogPath

        Get-ContinuousCoReviewActiveProjectProviders $project | Should -Be @('fixture-forge')
        $result.state | Should -Be 'selected'
        $result.selection.source_kind | Should -Be 'provider-gated'
    }

    It 'is wired into both real init and update production callers' {
        $init = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/specrew-init.ps1') -Raw
        $update = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/specrew-update.ps1') -Raw
        $init | Should -Match 'Invoke-ContinuousCoReviewVerificationPlanMaterialization\s+-RepoRoot\s+\$resolvedProjectPath\s+-PreviewOnly:\$DryRun'
        $update | Should -Match 'Invoke-ContinuousCoReviewVerificationPlanMaterialization\s+-RepoRoot\s+\$resolvedProjectPath'
    }
}
