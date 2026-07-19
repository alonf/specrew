$ErrorActionPreference = 'Stop'

# Trace: T065 / FR-048, FR-049 / SC-015, NFR-007.
Describe 'Supplier to campaign deterministic end-to-end project matrix (T065)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/verification-plan-materializer.ps1')

        function script:New-T065Command {
            param(
                [Parameter(Mandatory)][string]$Id,
                [Parameter(Mandatory)][string]$Kind,
                [Parameter(Mandatory)][string]$Source,
                [AllowNull()][string]$Profile,
                [AllowNull()][string]$Provider,
                [AllowNull()][string]$WorkingDirectory,
                [int]$ExitCode = 0
            )
            $provenance = [ordered]@{ kind = $Kind; source = $Source }
            if (-not [string]::IsNullOrWhiteSpace($Profile)) { $provenance.profile = $Profile }
            if (-not [string]::IsNullOrWhiteSpace($Provider)) { $provenance.provider = $Provider }
            $command = [ordered]@{
                command_id = $Id
                executable = 'pwsh'
                arguments = @('-NoProfile', '-Command', "exit $ExitCode")
                timeout_seconds = 30
                provenance = $provenance
                label = "T065 $Id"
            }
            if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $command.working_directory = $WorkingDirectory }
            return [pscustomobject]$command
        }

        function script:New-T065Plan {
            param([Parameter(Mandatory)][string]$PlanId, [Parameter(Mandatory)][object[]]$Commands)
            return [pscustomobject]@{ schema_version = '1.0'; plan_id = $PlanId; commands = @($Commands) }
        }

        function script:New-T065Catalog {
            param([Parameter(Mandatory)][string]$Path)
            $source = Join-Path $script:RepoRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json'
            $catalog = [IO.File]::ReadAllText($source) | ConvertFrom-Json

            $metadata = @($catalog.project_metadata)[0]
            $metadata.plan.commands = @(
                (New-T065Command -Id 'metadata-first' -Kind 'project-detected' -Source 'package-json.scripts-test.v1'),
                (New-T065Command -Id 'metadata-second' -Kind 'project-detected' -Source 'package-json.scripts-test.v1')
            )
            foreach ($row in @($catalog.quality_profiles)) {
                $profileId = [string]$row.profile_id
                $row.plan.commands = @((New-T065Command -Id 'profile-check' -Kind 'profile-selected' -Source $profileId -Profile $profileId))
            }
            $providerId = 'fixture-forge'
            $catalog.providers = @([pscustomobject]@{
                    entry_id = 'provider.fixture-forge.v1'
                    provider_id = $providerId
                    plan = (New-T065Plan -PlanId 'verification.provider.fixture-forge.v1' -Commands @(
                            (New-T065Command -Id 'provider-check' -Kind 'provider-gated' -Source $providerId -Provider $providerId)
                        ))
                })
            [IO.File]::WriteAllText($Path, ($catalog | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
            return $Path
        }

        function script:New-T065Repo {
            param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Shape)
            [IO.Directory]::CreateDirectory($Path) | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'app.txt'), "fixture=$Shape")
            switch ($Shape) {
                'metadata' { [IO.File]::WriteAllText((Join-Path $Path 'package.json'), '{"scripts":{"test":"project-owned-test"}}') }
                'mixed' {
                    [IO.File]::WriteAllText((Join-Path $Path 'package.json'), '{"scripts":{"test":"project-owned-test"}}')
                    [IO.File]::WriteAllText((Join-Path $Path 'service.py'), 'print("fixture")')
                    [IO.File]::WriteAllText((Join-Path $Path 'Fixture.csproj'), '<Project Sdk="Microsoft.NET.Sdk" />')
                }
                'provider' {
                    $governance = Join-Path $Path '.specrew/repository-governance.yml'
                    [IO.Directory]::CreateDirectory((Split-Path -Parent $governance)) | Out-Null
                    [IO.File]::WriteAllText($governance, "provider:`n  name: fixture-forge`n")
                }
                'safe-path' {
                    $safe = Join-Path $Path 'safe area'
                    [IO.Directory]::CreateDirectory($safe) | Out-Null
                    [IO.File]::WriteAllText((Join-Path $safe '.keep'), 'tracked safe working directory')
                }
            }
            & git -C $Path -c user.name=t065-test -c user.email=t065@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=t065-test -c user.email=t065@example.invalid commit -qm initial 2>&1 | Out-Null
            return $Path
        }

        function script:Set-T065ExplicitPlan {
            param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)]$Plan)
            $path = Join-Path $Repo '.specrew/verification-plan.json'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.File]::WriteAllText($path, ($Plan | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
        }

        function script:New-T065Context {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Token)
            $store = Join-Path $Root 'store'; $staging = Join-Path $Root 'staging'; $targets = Join-Path $Root 'targets'
            [IO.Directory]::CreateDirectory($Root) | Out-Null
            $prompt = Join-Path $Root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded T065 fixture prompt')
            $config = Join-Path $Root 'authority.json'; [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}')
            $campaignId = "cmp-t065-$Token"
            $grant = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'grant'; campaign_id = $campaignId; grant_id = "grant-$Token"
                slots = 1; authority_kind = 'human'; authorization_ref = "fixture-$Token"; observed_at = '2026-07-19T00:00:00Z'
            }
            Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant | Out-Null
            return [pscustomobject]@{
                store = $store; staging = $staging; targets = $targets; prompt = $prompt; config = $config
                campaign_id = $campaignId; run_id = "run-t065-$Token"; reservation_id = "res-t065-$Token"
            }
        }

        function script:New-T065Harness {
            param([Parameter(Mandatory)]$Capture)
            $preflight = {
                param($invocation)
                $Capture.preflight_count++
                $evidencePath = Join-Path ([string]$invocation.snapshot_path) '.review/implementer-evidence.json'
                if ([IO.File]::Exists($evidencePath)) { $Capture.evidence = [IO.File]::ReadAllText($evidencePath) | ConvertFrom-Json }
                return [pscustomobject]@{ ok = $true; reason = 'fixture-ready' }
            }.GetNewClosure()
            $invoke = {
                param($invocation, $environment)
                $Capture.invoke_count++
                $candidate = [pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = [string]$invocation.run_id; target_digest = [string]$invocation.target_digest
                    completion = 'complete'; verdict = 'pass'; summary = 'fixture pass'; findings = @()
                }
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                return [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
            return [pscustomobject]@{ id = 'fixture-t065'; contract_version = '1.0'; preflight = $preflight; invoke = $invoke }
        }

        function script:Invoke-T065Campaign {
            param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)]$Context, [Parameter(Mandatory)]$Capture)
            return Invoke-ReviewCampaignRun -StoreRoot $Context.store -StagingRoot $Context.staging `
                -CampaignId $Context.campaign_id -RunId $Context.run_id -ReservationId $Context.reservation_id `
                -TargetLineage "lin-$($Context.run_id)" -TargetPort (New-GitReviewTargetPort -OriginRepo $Repo -ExternalRoot $Context.targets) `
                -HarnessPort (New-T065Harness -Capture $Capture) -RuntimePort (New-ReviewFixtureRuntimePort) `
                -VerificationPort (New-ReviewProductionVerificationPort) -ClockPort (New-ReviewSystemClockPort) `
                -PromptPath $Context.prompt -TimeoutSeconds 60 -AuthorityConfigPath $Context.config
        }
    }

    It 'selects, executes, records, and injects a <source_kind> plan for a <shape> project' -ForEach @(
        @{ shape = 'explicit'; source_kind = 'project-config'; profile = $null; expected = @('explicit-check') },
        @{ shape = 'metadata'; source_kind = 'project-detected'; profile = $null; expected = @('metadata-first', 'metadata-second') },
        @{ shape = 'profile'; source_kind = 'profile-selected'; profile = 'quality-profile.python-fastapi-service.v1'; expected = @('profile-check') },
        @{ shape = 'provider'; source_kind = 'provider-gated'; profile = $null; expected = @('provider-check') },
        @{ shape = 'mixed'; source_kind = 'project-detected'; profile = 'quality-profile.python-fastapi-service.v1'; expected = @('metadata-first', 'metadata-second') },
        @{ shape = 'safe-path'; source_kind = 'project-config'; profile = $null; expected = @('safe-path-check') }
    ) {
        $root = Join-Path $TestDrive "source-$shape"; $repo = New-T065Repo -Path (Join-Path $root 'origin') -Shape $shape
        $catalogPath = New-T065Catalog -Path (Join-Path $root 'catalog.json')
        if ($shape -in @('explicit', 'safe-path')) {
            $workingDirectory = if ($shape -eq 'safe-path') { 'safe area' } else { $null }
            Set-T065ExplicitPlan -Repo $repo -Plan (New-T065Plan -PlanId "t065.$shape.v1" -Commands @(
                    (New-T065Command -Id $expected[0] -Kind 'project-config' -Source '.specrew/verification-plan.json' -WorkingDirectory $workingDirectory)
                ))
        }
        $materialize = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $repo -CatalogPath $catalogPath -QualityProfileId $profile
        $materialize.state | Should -Be 'selected' -Because $materialize.warning
        $materialize.selection.source_kind | Should -Be $source_kind

        $context = New-T065Context -Root (Join-Path $root 'controller') -Token $shape
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; evidence = $null }
        $headBefore = (& git -C $repo rev-parse HEAD).Trim(); $statusBefore = @(& git -C $repo status --porcelain=v1 --untracked-files=all)
        $result = Invoke-T065Campaign -Repo $repo -Context $context -Capture $capture

        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.result.can_approve_current | Should -BeTrue
        $capture.invoke_count | Should -Be 1
        @($capture.evidence.runs | ForEach-Object { [string]$_.command_id }) | Should -Be $expected
        @($capture.evidence.runs | Where-Object { -not [bool]$_.command_succeeded }).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId $context.campaign_id -Kind spend).Count | Should -Be 1
        (& git -C $repo rev-parse HEAD).Trim() | Should -Be $headBefore
        @(& git -C $repo status --porcelain=v1 --untracked-files=all) | Should -Be $statusBefore
    }

    It 'stops <case> before command or provider side effects' -ForEach @(
        @{ case = 'no-source'; shape = 'no-source'; plan = $null; reason = 'verification-not-configured*' },
        @{ case = 'invalid-explicit'; shape = 'explicit'; plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'invalid'; commands = @([pscustomobject]@{ command_id = 'never-run'; executable = 'pwsh'; arguments = 'not-an-array'; provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' } }) }; reason = 'verification-not-configured:*schema-invalid*' },
        @{ case = 'escaping-path'; shape = 'explicit'; plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'escape'; commands = @([pscustomobject]@{ command_id = 'never-escape'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); working_directory = '../outside'; timeout_seconds = 30; provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' }; label = 'T065 escape refusal' }) }; reason = 'verification-not-configured:*schema-invalid*' }
    ) {
        $root = Join-Path $TestDrive "stop-$case"; $repo = New-T065Repo -Path (Join-Path $root 'origin') -Shape $shape
        $catalogPath = New-T065Catalog -Path (Join-Path $root 'catalog.json')
        if ($null -ne $plan) { Set-T065ExplicitPlan -Repo $repo -Plan $plan }
        $materialize = Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $repo -CatalogPath $catalogPath
        if ($case -eq 'no-source') { $materialize.state | Should -Be 'verification-not-configured' }
        else { $materialize.state | Should -Be 'invalid' }

        $context = New-T065Context -Root (Join-Path $root 'controller') -Token $case
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; evidence = $null }
        $result = Invoke-T065Campaign -Repo $repo -Context $context -Capture $capture

        $result.status | Should -Be 'failed'
        $result.reason | Should -BeLike $reason
        $result.invoked | Should -BeFalse
        $capture.preflight_count | Should -Be 0
        $capture.invoke_count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId $context.campaign_id -Kind spend).Count | Should -Be 0
    }

    It 'keeps every ordered attempt and prevents approval when one configured command fails' {
        $root = Join-Path $TestDrive 'failed-command'; $repo = New-T065Repo -Path (Join-Path $root 'origin') -Shape explicit
        $catalogPath = New-T065Catalog -Path (Join-Path $root 'catalog.json')
        Set-T065ExplicitPlan -Repo $repo -Plan (New-T065Plan -PlanId 't065.failure.v1' -Commands @(
                (New-T065Command -Id 'passes-first' -Kind 'project-config' -Source '.specrew/verification-plan.json'),
                (New-T065Command -Id 'fails-second' -Kind 'project-config' -Source '.specrew/verification-plan.json' -ExitCode 7),
                (New-T065Command -Id 'passes-third' -Kind 'project-config' -Source '.specrew/verification-plan.json')
            ))
        (Invoke-ContinuousCoReviewVerificationPlanMaterialization -RepoRoot $repo -CatalogPath $catalogPath).state | Should -Be 'selected'
        $context = New-T065Context -Root (Join-Path $root 'controller') -Token 'failed-command'
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; evidence = $null }

        $result = Invoke-T065Campaign -Repo $repo -Context $context -Capture $capture

        $result.status | Should -Be 'terminal'
        @($capture.evidence.runs | ForEach-Object { [string]$_.command_id }) | Should -Be @('passes-first', 'fails-second', 'passes-third')
        @($capture.evidence.runs | Where-Object { -not [bool]$_.command_succeeded } | ForEach-Object command_id) | Should -Be @('fails-second')
        $result.result.completion | Should -Be 'partial'
        $result.result.verdict | Should -Be 'incomplete'
        $result.result.can_approve_current | Should -BeFalse
        $result.result.failure_reason | Should -Match 'VERIFICATION_FAILED.*fails-second'
    }
}
