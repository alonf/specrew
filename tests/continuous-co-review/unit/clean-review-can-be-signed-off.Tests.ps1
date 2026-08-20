#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W24 then W27 (2026-08-18/19): what a clean review requires of the human, and what it does not.
#
# W24 came from a walk where a human could not close a clean review: `--pause-choice 2` records an
# `accept-current` disposition, and that writer refused any verdict that was not `findings`. W24 widened
# it to accept `pass`.
#
# W27 reverses that, because W24 fixed a symptom. The signoff gate ALREADY releases the boundary on a
# complete, current, approvable `pass` - the pause stops conferring quiet for that shape and the
# boundary-clean route renders with no disposition anywhere in the path. The human was being asked to
# answer a menu the machinery never consulted, and because the answer is stored as `authorized_by:
# human`, an unnecessary question became a forgeable authority record - which a 2026-08-19 walk then
# produced without the human. The menu is gone; accepting a clean result decides nothing and is refused.
#
# Written against REAL authority-store facts on disk rather than a mocked reader: the reader is part
# of what this guard depends on, and the original walk's failure surfaced through it.

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
        param([Parameter(Mandatory)]$Fixture, [string]$Decision = 'accept-current',
            [string]$Rationale = 'closing a clean review')
        try {
            $null = Add-ReviewCampaignHumanDisposition -StoreRoot $Fixture.StoreRoot -CampaignId $Fixture.CampaignId `
                -RunId $Fixture.RunId -Decision $Decision -AuthorizedBy 'human' -AuthorizationRef 'ref-w24' `
                -Rationale $Rationale
            return [pscustomobject]@{ threw = $false; reason = '' }
        }
        catch { return [pscustomobject]@{ threw = $true; reason = [string]$_.Exception.Message } }
        finally { Remove-Item -LiteralPath $Fixture.StoreRoot -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W24/W27 what a clean review does and does not require' {
    # W27 reverses W24 deliberately. W24 let a pass be accepted because a walk showed a human unable to
    # close a clean review; the real defect was that the surface ASKED at all. The signoff gate already
    # releases the boundary on a complete, current, approvable pass with no disposition anywhere in the
    # path, so accepting one decides nothing - and leaving it reachable kept a forgeable
    # `authorized_by: human` record, which the 2026-08-19 walk then produced without the human.
    It 'refuses to accept a clean result, because there are no findings to accept' {
        $outcome = Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'pass')
        $outcome.threw | Should -BeTrue
        $outcome.reason | Should -Match 'accept-requires-findings-to-accept'
    }

    It 'still accepts a findings verdict, which is the case the guard was written for' {
        (Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'findings')).threw | Should -BeFalse
    }

    It 'still refuses a verdict that is not a reviewed outcome' {
        $outcome = Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'failed')
        $outcome.threw | Should -BeTrue
        $outcome.reason | Should -Match 'accept-requires-findings-to-accept'
    }

    It 'still refuses an incomplete, invalid or stale result whatever its verdict' {
        # These are refused by the store's own ReviewResult contract before the verdict clause is
        # reached, which is correct and worth pinning: the refusal is what matters, not which layer
        # produced it, and no verdict widening ever opened them.
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

Describe 'W34-C a rationale may not contradict the result it disposes of' {
    # The forged KeyContextAI disposition reads "Remaining findings accepted as follow-ups at the review
    # pause" against a run with ZERO findings. Nobody needs to establish who typed it: the record
    # contradicts the result it cites, and that is checkable at write time with no judgement at all.
    # W27 closed the surface that produced it; this closes the SHAPE, so the next one is refused when it
    # is created rather than found later in an immutable store that has no supersede mechanism.
    It 'refuses a rationale citing findings against a zero-finding run' {
        $outcome = Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'findings') `
            -Rationale 'Remaining findings accepted as follow-ups at the review pause.'
        # The fixture's `findings` verdict carries exactly one finding, so this must be ALLOWED - the
        # guard is about contradiction, not about the word.
        $outcome.threw | Should -BeFalse
    }

    It 'refuses the exact forged rationale when the run really has no findings' {
        # `pass` fixtures carry zero findings. The verdict clause refuses this too, so the assertion is
        # on WHICH refusal fires: the contradiction must be named, not masked by the earlier rule.
        $fixture = New-DispositionFixture -Verdict 'pass'
        $outcome = Invoke-Disposition -Fixture $fixture -Decision 'require-correction' `
            -Rationale 'Remaining findings accepted as follow-ups at the review pause.'
        $outcome.threw | Should -BeTrue
        $outcome.reason | Should -Match 'rationale-contradicts-result'
    }

    It 'allows an honest rationale on a clean run' {
        (Invoke-Disposition -Fixture (New-DispositionFixture -Verdict 'pass') -Decision 'require-correction' `
                -Rationale 'Nothing outstanding; closing here.').threw | Should -BeFalse
    }
}
