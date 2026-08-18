#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W24 (2026-08-18 calculator walk, reproduced against this project's own campaign): a CLEAN review
# could not be signed off. `--pause-choice 2` ("stop here") records an `accept-current` human
# disposition, and that writer refused any result whose verdict was not `findings`, so a round that
# found nothing threw and left the human unable to close.
#
# The surface makes it worse by recommending exactly that action on a clean round: "Nothing was found.
# Stopping here completes your sign-off." Engine advice the machinery then refuses.
#
# The guard's real job is to stop a human accepting something that is not a reviewed outcome. The
# complete + valid + current check immediately above already does that, so the verdict clause only
# ever excluded `pass` - the best possible result was the one you could not close on.
#
# Written against REAL authority-store facts on disk rather than a mocked reader: the reader is part
# of what this guard depends on, and the walk's failure surfaced through it.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\review-campaign-orchestrator.ps1')

    function New-DispositionFixture {
        param(
            [Parameter(Mandatory)][string]$Verdict,
            [string]$Completion = 'complete',
            [string]$Validation = 'valid',
            [string]$Currentness = 'current'
        )
        $storeRoot = Join-Path ([IO.Path]::GetTempPath()) ('w24-' + [guid]::NewGuid().ToString('N'))
        $campaignId = 'cmp-w24'
        $runId = 'run-w24'
        $runDir = Join-Path $storeRoot ("campaigns/$campaignId/runs/$runId")
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        # The store validates the full ReviewResult contract, so the fixture carries every required
        # field. approval prerequisites are only claimed when the result genuinely is complete,
        # valid and current - asserting otherwise would make the store refuse for the wrong reason.
        # `can_approve_current` is about whether the BOUNDARY can be approved, and the contract refuses
        # to let a result claim it while findings are open - which is exactly why "stop here" exists as
        # the way to dispose of them. Only a clean, complete, valid, current result claims it.
        $approvable = ($Completion -eq 'complete' -and $Validation -eq 'valid' -and $Currentness -eq 'current' -and
            $Verdict -eq 'pass')
        # A `findings` verdict with an empty findings array is self-contradictory and the store says so,
        # so the fixture carries one real-shaped finding for that case.
        # Assigned outside an if-expression on purpose: an `if` block whose value is `@()` emits nothing,
        # so the variable would land as $null and the store would refuse `wrong-type:findings:array` -
        # a fixture defect that reads exactly like a product one.
        $findings = @()
        if ($Verdict -eq 'findings') {
            $findings = @([ordered]@{
                    finding_id = 'finding-w24fixture0001'; lineage_id = 'lin-w24fixture0001'
                    severity = 'minor'; title = 'Fixture finding'; description = 'A fixture finding for the sign-off guard.'
                    location = 'src/fixture.ps1:1'; relevance = 'current'; resolution = 'open'
                    source_local_id = 'f1'; demoted = $false; demoted_from = $null
                })
        }
        $result = [ordered]@{
            schema_version = '1.0'; campaign_id = $campaignId; run_id = $runId
            verdict = $Verdict; completion = $Completion; validation = $Validation; currentness = $Currentness
            target_digest = 'f4afeac915050803e3dd92326860734d72c187ea'
            findings = @($findings); runtime_outcome = 'completed'; can_approve_current = $approvable
            harness_id = 'copilot-cli-file-primary'; termination_verified = $true; containment = 'verified'
            summary = 'Fixture result for the clean-review sign-off guard.'
            started_at = '2026-08-18T00:00:00.0000000+00:00'; ended_at = '2026-08-18T00:07:35.0000000+00:00'
            duration_ms = 455594; failure_reason = $null
        }
        [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ StoreRoot = $storeRoot; CampaignId = $campaignId; RunId = $runId }
    }

    function Invoke-Disposition {
        param([Parameter(Mandatory)]$Fixture, [string]$Decision = 'accept-current')
        try {
            $null = Add-ReviewCampaignHumanDisposition -StoreRoot $Fixture.StoreRoot -CampaignId $Fixture.CampaignId `
                -RunId $Fixture.RunId -Decision $Decision -AuthorizedBy 'human' -AuthorizationRef 'ref-w24' `
                -Rationale 'closing a clean review'
            return [pscustomobject]@{ threw = $false; reason = '' }
        }
        catch { return [pscustomobject]@{ threw = $true; reason = [string]$_.Exception.Message } }
        finally { Remove-Item -LiteralPath $Fixture.StoreRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W24 a clean review is closeable' {
    It 'accepts a pass verdict, so a round that found nothing can still be signed off' {
        $outcome = Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'pass')
        $outcome.reason | Should -Not -Match 'requires-findings'
        $outcome.threw | Should -BeFalse
    }

    It 'still accepts a findings verdict, which is the case the guard was written for' {
        (Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'findings')).threw | Should -BeFalse
    }

    It 'still refuses a verdict that is not a reviewed outcome' {
        $outcome = Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'failed')
        $outcome.threw | Should -BeTrue
        $outcome.reason | Should -Match 'accept-requires-reviewed-result'
    }

    It 'still refuses an incomplete, invalid or stale result whatever its verdict' {
        # These are refused by the store's own ReviewResult contract before the verdict clause is
        # reached, which is correct and worth pinning: the refusal is what matters, not which layer
        # produced it. Widening `accept-current` to `pass` did not open any of these.
        foreach ($fixture in @(
                (New-DispositionFixture -Verdict 'pass' -Completion 'partial'),
                (New-DispositionFixture -Verdict 'pass' -Validation 'invalid'),
                (New-DispositionFixture -Verdict 'pass' -Currentness 'stale'))) {
            (Invoke-Disposition -Fixture $fixture).threw | Should -BeTrue
        }
    }

    It 'refuses when the run has no result at all' {
        $fixture = New-DispositionFixture -Verdict 'pass'
        Remove-Item -LiteralPath (Join-Path $fixture.StoreRoot ("campaigns/$($fixture.CampaignId)/runs/$($fixture.RunId)/result.json")) -Force
        $outcome = Invoke-Disposition -Fixture $fixture
        $outcome.threw | Should -BeTrue
        $outcome.reason | Should -Match 'result-missing'
    }
}
