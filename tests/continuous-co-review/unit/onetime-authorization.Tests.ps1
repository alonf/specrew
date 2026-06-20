$ErrorActionPreference = 'Stop'

# Trace: T062, FR-028, FR-029, SC-021, NFR-005, SEC-004, TG-013.
# FR-028: a navigator authorized ONCE (a recorded authorization_ref in project/run config) is
# authorized on every automatic run with no per-run re-prompt. FR-029/NFR-005: a blocking
# finding stops advancement and escalates after the two-round cap (the inline gate evaluator).
# Rules: specs/197-continuous-co-review/implementation-rules.yml
Describe 'Proposal 197 T062 one-time navigator authorization + blocking escalation' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    }

    It 'FR-028: an authorized candidate stays authorized across repeated automatic runs (no re-prompt)' {
        $candidate = [pscustomobject][ordered]@{ host = 'claude'; model = 'opus'; adapter_id = 'reviewer-host-adapter-claude-prompt'; cost_class = 'default'; model_source = 'config'; authorization_ref = 'human-approved-once-2026-06-20' }
        # Three automatic runs in a row -> deterministically authorized, no state, no prompt.
        foreach ($run in 1..3) {
            $a = Test-ContinuousCoReviewReviewerAuthorization -Candidate $candidate
            $a.authorized | Should Be $true
            $a.authorization_ref | Should Be 'human-approved-once-2026-06-20'
        }
    }

    It 'SEC-004: a candidate with NO recorded authorization is unauthorized (must be authorized before spawning)' {
        $candidate = [pscustomobject][ordered]@{ host = 'codex'; model = 'gpt'; adapter_id = 'reviewer-host-adapter-codex-exec'; cost_class = 'paid'; model_source = 'human-entered'; authorization_ref = $null }
        $a = Test-ContinuousCoReviewReviewerAuthorization -Candidate $candidate
        $a.authorized | Should Be $false
        $a.category | Should Be 'unauthorized-provider'
    }

    It 'FR-029/NFR-005: an unresolved blocking finding escalates after the two-round cap' {
        $runId = 'run-esc'
        $checkpointId = 'cp-esc'
        $blockingFinding = [pscustomobject][ordered]@{
            finding_id = 'f1'; severity = 'blocking'; kind = 'design-violation'; design_reference = 'D-1'
            disposition = 'open'; fingerprint = 'fp1'; source_run_id = $runId
            location = [pscustomobject]@{ path = 'a.ps1'; line_start = 1; line_end = 2 }
            comment = 'violates decision D-1'
            resolution = [pscustomobject]@{ state = 'unresolved'; rationale = $null; fix_evidence_ref = $null }
        }
        $findingsResult = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'changes_requested'; reviewer = [pscustomobject]@{ host = 'fixture'; model = 'fixture'; adapter_id = 'reviewer-host-adapter-fixture' }; findings = @($blockingFinding); created_at = '2026-06-20T00:00:00Z' }
        # Same blocking finding seen at round 2 (a prior unresolved blocking of the same id) -> escalate.
        $thread = [pscustomobject][ordered]@{ schema_version = '1.0'; thread_id = "thread-$runId"; run_id = $runId; checkpoint_id = $checkpointId; findings = @('f1'); dispositions = @([pscustomobject]@{ disposition_id = 'd1'; finding_id = 'f1'; state = 'open'; rationale = $null; fix_evidence_ref = $null; review_round = 1; actor_role = 'reviewer'; recorded_at = '2026-06-20T00:00:00Z' }); resolution_summary = 'x'; escalation_ref = $null; created_at = '2026-06-20T00:00:00Z'; updated_at = '2026-06-20T00:00:00Z' }
        $prior = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'changes_requested'; reviewer = $findingsResult.reviewer; findings = @($blockingFinding); created_at = '2026-06-20T00:00:00Z' }

        $verdict = Invoke-ContinuousCoReviewInlineGateEvaluator -RunId $runId -CheckpointId $checkpointId -FindingsResult $findingsResult -ReviewThread $thread -PriorFindingsResult $prior -MaxReviewRounds 2
        $verdict.state | Should Be 'escalated'
        $verdict.escalation_ref | Should Not BeNullOrEmpty
    }
}
