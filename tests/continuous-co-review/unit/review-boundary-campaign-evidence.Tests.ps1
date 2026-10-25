$ErrorActionPreference = 'Stop'

# Dogfood regression: an implementer wrote review.md itself after the reviewer harness never ran.
# The file was committed with Overall Verdict: accepted, so the pending-boundary evidence check saw
# review.md and offered a verdict even though the active campaign held no completed, valid result.
# These cases exercise the real shared boundary-evidence reader against real Git trees and campaign
# store directories. An unrelated campaign result must never satisfy the active feature/iteration.
Describe 'Review boundary campaign evidence is required before a verdict can be offered' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')

        function script:Invoke-EvidenceGit {
            param([string]$Root, [string[]]$Arguments)
            $output = @(& git -C $Root @Arguments 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw ("Fixture git failed: git {0}`n{1}" -f ($Arguments -join ' '), ($output -join "`n"))
            }
            return @($output)
        }

        function script:New-EvidenceRepo {
            param([string]$Name)
            $root = Join-Path $TestDrive $Name
            $iteration = Join-Path $root 'specs/001-test-feature/iterations/001'
            New-Item -ItemType Directory -Path $iteration -Force | Out-Null
            [IO.File]::WriteAllText(
                (Join-Path $iteration 'review.md'),
                "# Iteration Review: 001`n`n**Overall Verdict**: accepted`n",
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-EvidenceGit -Root $root -Arguments @('init', '-q') | Out-Null
            Invoke-EvidenceGit -Root $root -Arguments @('add', '-A') | Out-Null
            Invoke-EvidenceGit -Root $root -Arguments @(
                '-c', 'user.name=fixture', '-c', 'user.email=fixture@example.invalid',
                'commit', '-qm', 'review artifact'
            ) | Out-Null
            return [pscustomobject]@{
                Root = $root
                FeaturePath = Join-Path $root 'specs/001-test-feature'
                Tree = [string](Invoke-EvidenceGit -Root $root -Arguments @('rev-parse', 'HEAD^{tree}') | Select-Object -First 1)
            }
        }

        function script:Write-CampaignResult {
            param(
                [string]$Root,
                [string]$CampaignId,
                [string]$RunId,
                [string]$Completion,
                [string]$Validation
            )
            $runRoot = Join-Path $Root ".specrew/review/authority/campaigns/$CampaignId/runs/$RunId"
            New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
            $result = [ordered]@{
                schema_version = '1.0'
                campaign_id = $CampaignId
                run_id = $RunId
                target_digest = 'fixture-digest'
                completion = $Completion
                validation = $Validation
            }
            [IO.File]::WriteAllText(
                (Join-Path $runRoot 'result.json'),
                ($result | ConvertTo-Json -Compress),
                [Text.UTF8Encoding]::new($false)
            )
        }
    }

    It 'refuses review-signoff when review.md exists but the active campaign has no result' {
        $fixture = New-EvidenceRepo -Name 'no-campaign-result'

        $evidence = Get-SpecrewBoundaryStageEvidence -ProjectRoot $fixture.Root -Boundary 'review-signoff' `
            -FeaturePath $fixture.FeaturePath -IterationNumber '001' -ArtifactStateId $fixture.Tree

        $evidence.Checked | Should -BeTrue
        $evidence.Satisfied | Should -BeFalse
        $evidence.Unverifiable | Should -BeFalse
        ($evidence.Missing -join ' ') | Should -Match 'completed, valid campaign result'
    }

    It 'refuses completion=none and validation=not-produced for the active campaign' {
        $fixture = New-EvidenceRepo -Name 'invalid-active-result'
        Write-CampaignResult -Root $fixture.Root -CampaignId 'cmp-001-test-feature-i001' -RunId 'run-invalid' `
            -Completion 'none' -Validation 'not-produced'

        $state = Get-SpecrewReviewCampaignEvidenceState -ProjectRoot $fixture.Root `
            -FeatureRef '001-test-feature' -IterationNumber '001'

        $state.Checked | Should -BeTrue
        $state.Satisfied | Should -BeFalse
        $state.Unverifiable | Should -BeFalse
        $state.ResultCount | Should -Be 1
        $state.ValidResultCount | Should -Be 0
    }

    It 'does not borrow a valid result from another campaign' {
        $fixture = New-EvidenceRepo -Name 'unrelated-result'
        Write-CampaignResult -Root $fixture.Root -CampaignId 'cmp-999-other-i001' -RunId 'run-valid' `
            -Completion 'complete' -Validation 'valid'

        $state = Get-SpecrewReviewCampaignEvidenceState -ProjectRoot $fixture.Root `
            -FeatureRef '001-test-feature' -IterationNumber '001'

        $state.Satisfied | Should -BeFalse
        $state.ResultCount | Should -Be 0
        $state.CampaignId | Should -Be 'cmp-001-test-feature-i001'
    }

    It 'allows the artifact check after the active campaign records a completed, valid result' {
        $fixture = New-EvidenceRepo -Name 'valid-active-result'
        Write-CampaignResult -Root $fixture.Root -CampaignId 'cmp-001-test-feature-i001' -RunId 'run-valid' `
            -Completion 'complete' -Validation 'valid'

        $state = Get-SpecrewReviewCampaignEvidenceState -ProjectRoot $fixture.Root `
            -FeatureRef '001-test-feature' -IterationNumber '001'
        $evidence = Get-SpecrewBoundaryStageEvidence -ProjectRoot $fixture.Root -Boundary 'review-signoff' `
            -FeaturePath $fixture.FeaturePath -IterationNumber '001' -ArtifactStateId $fixture.Tree

        $state.Satisfied | Should -BeTrue
        $state.ValidResultCount | Should -Be 1
        $evidence.Satisfied | Should -BeTrue
        $evidence.Missing | Should -BeNullOrEmpty
    }
}
