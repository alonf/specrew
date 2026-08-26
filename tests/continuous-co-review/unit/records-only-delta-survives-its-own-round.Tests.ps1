#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W74 / round-30 finding, graded BLOCKING: A RECORDS-ONLY COMMIT DURING A ROUND STILL KILLED ITS PASS.
#
# The records-only exemption preserves a reviewed state across a commit that only wrote records. It
# gated that preservation on `can_approve_current`, which is a FROZEN flag composed as
# (complete AND currentness='current' AND verdict='pass' AND termination verified). If a records-only
# commit lands WHILE the reviewer runs, currentness is stamped snapshot-moved at ingest, so the flag is
# false for a complete, valid, passing, contained result - and the exemption then refuses to preserve
# the very pass it exists to preserve.
#
# THE SIBLING OF THE READER I FIXED ONE COMMIT EARLIER. W72 stopped the independence selector reading
# the frozen field as the answer; this reader does the same thing for the same reason, and I did not
# check it - under method rule 10, which that same commit recorded.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-authority-core.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1')

    function script:New-PassingResult {
        param([string]$Currentness = 'current', [bool]$CanApprove = $true)
        # EVERY field the result contract requires, not just the ones this case reasons about. The
        # first cut carried only the interesting ones and the gate answered
        # `campaign-result-invalid:schema-invalid` - so all three cases failed for a reason that had
        # nothing to do with the defect. Third time in this feature that an under-shaped fixture read
        # as a defect in the code.
        return [pscustomobject]@{
            schema_version = '1.0'; campaign_id = 'cmp-w74'; run_id = 'run-20260826-000000001-aaaaaaaa'
            harness_id = 'codex-cli-file-primary'
            runtime_outcome = 'completed'; completion = 'complete'; validation = 'valid'
            verdict = 'pass'; containment = 'verified'; termination_verified = $true
            currentness = $Currentness; can_approve_current = $CanApprove
            target_digest = 'aaaa1111'; findings = @(); examined_paths = @('src/Engine.cs')
            started_at = '2026-08-26T10:00:00.0000000+00:00'; ended_at = '2026-08-26T10:15:00.0000000+00:00'
            duration_ms = 900000; failure_reason = 'none'; summary = 'fixture'
        }
    }
}

Describe 'W74 a records-only commit during a round does not take the pass away' {
    It 'RED-FIRST: a complete, valid, passing, contained result is preserved even when the frozen flag says otherwise' {
        # The round ran, passed, and examined source. A governance-required records commit landed while
        # it was running, so ingest stamped snapshot-moved and can_approve_current=false. The delta is
        # records-only and verified as such. The pass must survive.
        $result = New-PassingResult -Currentness 'snapshot-moved' -CanApprove $false
        $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-w74' -CurrentDigest 'bbbb2222' `
            -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
            -OrderedRunIds @('run-20260826-000000001-aaaaaaaa') -Results @($result) -ActiveRun $null `
            -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')
        [string]$decision.reason | Should -Be 'records-only-delta-does-not-stale' -Because 'writing down what a review found must not invalidate it, however the frozen flag was stamped'
        [bool]$decision.gate_allows | Should -BeTrue
    }

    It 'still refuses to PROMOTE a result that never authorized on its own terms' {
        # The round-5 regression this branch already guards, and it must survive the fix: the exemption
        # preserves an authorizing result, it never manufactures one. A findings verdict is not a pass.
        $result = New-PassingResult -Currentness 'snapshot-moved' -CanApprove $false
        $result.verdict = 'findings'
        $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-w74' -CurrentDigest 'bbbb2222' `
            -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
            -OrderedRunIds @('run-20260826-000000001-aaaaaaaa') -Results @($result) -ActiveRun $null `
            -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')
        [string]$decision.reason | Should -Be 'records-only-delta-over-non-authorizing-result' -Because 'the records-only rule is about staleness, never about authority'
    }

    It 'still refuses when containment was not verified' {
        # The other half of "authorizes on its own terms": a review that may have read outside its
        # frozen copy is not evidence about that copy, whatever verdict it published.
        $result = New-PassingResult -Currentness 'snapshot-moved' -CanApprove $false
        $result.containment = 'unknown'
        $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-w74' -CurrentDigest 'bbbb2222' `
            -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
            -OrderedRunIds @('run-20260826-000000001-aaaaaaaa') -Results @($result) -ActiveRun $null `
            -ChangedPathsSinceResult @('specs/199-beta3-stabilization/iterations/001/drift-log.md')
        [string]$decision.reason | Should -Be 'records-only-delta-over-non-authorizing-result' -Because 'containment is part of authorizing on its own terms, and the frozen flag used to carry it'
    }

    It 'a SOURCE delta still stales, so the exemption has not been widened' {
        $result = New-PassingResult
        $decision = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-w74' -CurrentDigest 'bbbb2222' `
            -RepoRoot $script:RepoRoot -FeatureId '199-beta3-stabilization' `
            -OrderedRunIds @('run-20260826-000000001-aaaaaaaa') -Results @($result) -ActiveRun $null `
            -ChangedPathsSinceResult @('scripts/internal/bootstrap/HumanAuthorityStore.ps1')
        [string]$decision.reason | Should -Not -Be 'records-only-delta-does-not-stale' -Because 'source moving is exactly what should stale a review'
    }
}
