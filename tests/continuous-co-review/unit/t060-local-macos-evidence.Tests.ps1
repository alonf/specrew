$ErrorActionPreference = 'Stop'

Describe 'T060 local-macOS smoke package and digest-bound validator' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ValidatorPath = Join-Path $script:RepoRoot 'scripts/validate-t060-local-macos-evidence.ps1'
        $script:RunnerPath = Join-Path $script:RepoRoot 'scripts/t060-local-macos-smoke.ps1'
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:Commit = '0123456789abcdef0123456789abcdef01234567'
        $script:RunId = 'run-t060-macos-fixture'
        $script:CampaignId = 'cmp-198-beta2-hardening-i007'
        $script:AuthorizationRef = 'human-slot-t060-macos-fixture'
        $script:Digest = '89abcdef0123456789abcdef0123456789abcdef'

        function script:Write-T060FixtureJson {
            param([string]$Path, $Value)
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
            [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 30) + "`n"), [Text.UTF8Encoding]::new($false))
        }

        function script:Get-T060FixtureHash {
            param([string]$Path)
            return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
        }

        function script:New-T060FixturePackage {
            param(
                [Parameter(Mandatory)][string]$Root,
                [ValidateSet('pass', 'findings')][string]$Verdict = 'pass',
                [string]$EvidenceSource = 'local-machine'
            )
            [IO.Directory]::CreateDirectory($Root) | Out-Null
            $store = Join-Path $Root 'authority'
            $grant = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'grant'; campaign_id = $script:CampaignId; grant_id = 'grant-t060-macos-fixture'
                slots = 1; authority_kind = 'human'; authorization_ref = $script:AuthorizationRef; observed_at = '2026-07-17T09:00:00Z'
            }
            Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant | Out-Null
            $reservation = Request-ReviewCampaignReservationFact -StoreRoot $store -CampaignId $script:CampaignId -RunId $script:RunId `
                -ReservationId 'res-t060-macos-fixture' -ObservedAt '2026-07-17T09:00:01Z'
            $reservation.acquired | Should -BeTrue
            $spend = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'spend'; campaign_id = $script:CampaignId
                reservation_id = 'res-t060-macos-fixture'; run_id = $script:RunId; invocation_started_at = '2026-07-17T09:00:02Z'
            }
            Write-ReviewCampaignSpendFact -StoreRoot $store -Fact $spend | Out-Null
            [object[]]$findings = @()
            if ($Verdict -ceq 'findings') {
                $findings = @([pscustomobject][ordered]@{
                    finding_id = 'finding-t060-fixture'; source_local_id = 'mac-1'; lineage_id = 'lin-t060-fixture'
                    severity = 'major'; title = 'Fixture finding'; description = 'A valid finding keeps the package useful but prevents clean smoke acceptance.'
                    location = 'scripts/example.ps1:1'; relevance = 'current'; resolution = 'open'
                })
            }
            $result = [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = $script:RunId; target_digest = $script:Digest
                harness_id = 'codex-cli-file-primary'; completion = 'complete'; verdict = $Verdict; runtime_outcome = 'completed'
                termination_verified = $true; containment = 'verified'; currentness = 'current'; validation = 'valid'
                can_approve_current = ($Verdict -ceq 'pass'); failure_reason = $null; summary = 'Fixture terminal result.'; findings = $findings
                started_at = '2026-07-17T09:00:02Z'; ended_at = '2026-07-17T09:01:02Z'; duration_ms = 60000
            }
            $published = Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId $script:RunId -Fact $result
            $authorityRunRoot = Split-Path -Parent $published.path
            $authorityReport = Join-Path $authorityRunRoot 'report.md'
            [IO.File]::WriteAllText($authorityReport, "# T060 fixture report`n", [Text.UTF8Encoding]::new($false))
            $resultPath = Join-Path $Root 'result.json'; $reportPath = Join-Path $Root 'report.md'; $progressPath = Join-Path $Root 'progress.json'
            [IO.File]::Copy($published.path, $resultPath)
            [IO.File]::Copy($authorityReport, $reportPath)
            Write-T060FixtureJson -Path $progressPath -Value ([pscustomobject][ordered]@{ schema_version = '1.0'; events = @() })
            $platform = [pscustomobject][ordered]@{ os = 'macos'; os_version = 'macOS fixture'; architecture = 'arm64' }
            $preflight = [pscustomobject][ordered]@{
                schema_version = '1.0'; evidence_kind = 't060-local-macos-preflight'; evidence_source = $EvidenceSource
                generated_at = '2026-07-17T08:59:00Z'; provider_invoked = $false
                target = [pscustomobject][ordered]@{ repository_url = 'https://github.com/alonf/specrew.git'; head_commit = $script:Commit; reviewed_state_digest = $script:Digest; clean = $true }
                platform = $platform
                harness = [pscustomobject][ordered]@{ host = 'codex'; harness_id = 'codex-cli-file-primary'; cli_version = 'codex-cli 0.fixture'; auth_status = 'authenticated'; ready = $true; reason = 'codex-file-primary-ready' }
                runtime = [pscustomobject][ordered]@{ runtime_id = 'macos-process-group-runtime'; ready = $true; reason = 'macos-process-group-ready' }
            }
            $preflightPath = Join-Path $Root 'preflight.json'
            Write-T060FixtureJson -Path $preflightPath -Value $preflight
            $authorityConfigPath = Join-Path $Root 'campaign-authority.json'
            Write-T060FixtureJson -Path $authorityConfigPath -Value ([pscustomobject][ordered]@{ schema_version = '1.0'; mode = 'campaign' })
            $manifest = [pscustomobject][ordered]@{
                schema_version = '1.0'; evidence_kind = 't060-local-macos-smoke'; evidence_source = $EvidenceSource; generated_at = '2026-07-17T09:01:03Z'
                target = [pscustomobject][ordered]@{ repository_url = 'https://github.com/alonf/specrew.git'; head_commit = $script:Commit; reviewed_state_digest = $script:Digest; clean_before = $true; clean_after = $true; head_unchanged = $true }
                platform = $platform
                harness = [pscustomobject][ordered]@{ host = 'codex'; harness_id = 'codex-cli-file-primary'; cli_version = 'codex-cli 0.fixture'; auth_status = 'authenticated' }
                authorization = [pscustomobject][ordered]@{ reference = $script:AuthorizationRef; invocation_count = 1 }
                run = [pscustomobject][ordered]@{
                    campaign_id = $script:CampaignId; run_id = $script:RunId; status = 'terminal'; reason = 'terminal-result-published'; invoked = $true
                    preflight_file = 'preflight.json'; result_file = 'result.json'; report_file = 'report.md'; progress_file = 'progress.json'
                    preflight_sha256 = Get-T060FixtureHash $preflightPath; result_sha256 = Get-T060FixtureHash $resultPath
                    report_sha256 = Get-T060FixtureHash $reportPath; progress_sha256 = Get-T060FixtureHash $progressPath
                }
                controller = [pscustomobject][ordered]@{
                    authority_mode = 'external-t060-campaign-config'; authority_config_file = 'campaign-authority.json'
                    authority_config_sha256 = Get-T060FixtureHash $authorityConfigPath; runtime_id = 'macos-process-group-runtime'
                    timeout_seconds = 600; terminal_result_contract_valid = $true
                }
            }
            Write-T060FixtureJson -Path (Join-Path $Root 'manifest.json') -Value $manifest
            return [pscustomobject]@{ root = $Root; manifest = $manifest; result_path = $resultPath }
        }

        function script:Invoke-T060FixtureValidator {
            param([Parameter(Mandatory)][string]$Root, [string]$Commit = $script:Commit, [string]$Run = $script:RunId, [string]$Authorization = $script:AuthorizationRef)
            $text = (& pwsh -NoProfile -File $script:ValidatorPath -PackagePath $Root -ExpectedCommit $Commit -ExpectedRunId $Run -ExpectedAuthorizationRef $Authorization 2>&1 | Out-String).Trim()
            $exitCode = $LASTEXITCODE
            return [pscustomobject]@{ exit_code = $exitCode; result = ($text | ConvertFrom-Json -Depth 20) }
        }
    }

    It 'accepts a raw local-machine package bound to the expected commit, digest, run, grant, and one spend' {
        $fixture = New-T060FixturePackage -Root (Join-Path $TestDrive 'valid')
        $validated = Invoke-T060FixtureValidator -Root $fixture.root
        $validated.exit_code | Should -Be 0
        $validated.result.package_valid | Should -BeTrue -Because ($validated.result.errors -join ',')
        $validated.result.smoke_clean | Should -BeTrue
        $validated.result.evidence_source | Should -Be 'local-machine'
        $validated.result.finding_count | Should -Be 0
    }

    It 'keeps a valid findings result as usable evidence without misreporting a clean smoke' {
        $fixture = New-T060FixturePackage -Root (Join-Path $TestDrive 'findings') -Verdict findings
        $validated = Invoke-T060FixtureValidator -Root $fixture.root
        $validated.exit_code | Should -Be 0
        $validated.result.package_valid | Should -BeTrue -Because ($validated.result.errors -join ',')
        $validated.result.smoke_clean | Should -BeFalse
        $validated.result.verdict | Should -Be 'findings'
        $validated.result.finding_count | Should -Be 1
    }

    It 'rejects result tampering even when the JSON remains schema-valid' {
        $fixture = New-T060FixturePackage -Root (Join-Path $TestDrive 'tampered')
        Add-Content -LiteralPath $fixture.result_path -Value ' ' -NoNewline
        $validated = Invoke-T060FixtureValidator -Root $fixture.root
        $validated.exit_code | Should -Be 1
        $validated.result.package_valid | Should -BeFalse
        $validated.result.errors | Should -Contain 'result-hash-mismatch'
    }

    It 'rejects hosted-runner attribution and a mismatched expected commit' {
        $fixture = New-T060FixturePackage -Root (Join-Path $TestDrive 'hosted') -EvidenceSource hosted-runner
        $validated = Invoke-T060FixtureValidator -Root $fixture.root -Commit '1111111111111111111111111111111111111111'
        $validated.exit_code | Should -Be 1
        $validated.result.errors | Should -Contain 'evidence-source-must-be-local-machine'
        $validated.result.errors | Should -Contain 'commit-mismatch'
    }

    It 'keeps preflight non-spending and exposes exactly one deliberate provider-capable call' {
        $source = Get-Content -LiteralPath $script:RunnerPath -Raw
        $source | Should -Match "ValidateSet\('Preflight', 'Invoke'\)"
        $source | Should -Match 't060-local-macos-smoke-requires-macos'
        $source | Should -Match 't060-invoke-explicit-acknowledgement-required'
        $source | Should -Match 'provider_invoked = \$false'
        ([regex]::Matches($source, '(?m)^\$campaignRun\s*=\s*Invoke-ReviewCampaignCommand\b')).Count | Should -Be 1
        $source | Should -Not -Match 'Start-Job|Start-ThreadJob|Register-ObjectEvent'
    }
}
