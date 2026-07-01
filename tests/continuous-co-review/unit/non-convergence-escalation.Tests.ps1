$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T026 TG-011 non-convergence escalation obeys implementation-rules.yml review/fix cap' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')   # brings New-ContinuousCoReviewCeilingEscalationResult (D-010)
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:CreatedAt = [datetime] '2026-06-17T22:26:00Z'
    

        # v5: helpers moved here so they are visible inside It blocks (Discovery/Run split).
        function Get-T026GateEvaluatorCommand {
                $command = Get-Command -Name 'Invoke-ContinuousCoReviewInlineGateEvaluator' -ErrorAction SilentlyContinue
                $null = ($command | Should -Not -BeNullOrEmpty)
                return $command
            }

        function New-T026BlockingFindingsResult {
                param(
                    [string] $RunId,
                    [string] $SourceRunId = $RunId,
                    [string] $Comment = 'Same blocking finding remains unresolved.'
                )

                return [pscustomobject][ordered]@{
                    schema_version = '1.0'
                    run_id         = $RunId
                    status         = 'findings'
                    reviewer       = [pscustomobject][ordered]@{
                        host       = 'fixture'
                        model      = 'fixture-reviewer'
                        adapter_id = 'reviewer-host-adapter-fixture'
                    }
                    findings       = @(
                        [pscustomobject][ordered]@{
                            finding_id       = 'finding-t026-stable-blocker'
                            source_run_id    = $SourceRunId
                            fingerprint      = 'sha256:finding-t026-stable-blocker'
                            location         = [pscustomobject][ordered]@{
                                path       = 'scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1'
                                line_start = 26
                                line_end   = 32
                            }
                            severity         = 'blocking'
                            kind             = 'non-convergence'
                            design_reference = 'NFR-005'
                            comment          = $Comment
                            disposition      = 'open'
                            resolution       = [pscustomobject][ordered]@{
                                state            = 'unresolved'
                                fix_evidence_ref = $null
                                rationale        = $null
                            }
                        }
                    )
                    result_hash    = "sha256:$RunId"
                    created_at     = '2026-06-17T22:26:00Z'
                }
            }

        function New-T026ReviewThread {
                param(
                    [string] $RunId,
                    [int] $LatestReviewRound,
                    [bool] $IncludeFixAttempt = $false
                )

                $dispositions = @(
                    [pscustomobject][ordered]@{
                        disposition_id   = "disp-$RunId-open-round-0"
                        finding_id       = 'finding-t026-stable-blocker'
                        state            = 'open'
                        rationale        = $null
                        fix_evidence_ref = $null
                        review_round     = 0
                        actor_role       = 'reviewer'
                        recorded_at      = '2026-06-17T22:26:00Z'
                    }
                )

                if ($IncludeFixAttempt) {
                    $dispositions += @(
                        [pscustomobject][ordered]@{
                            disposition_id   = "disp-$RunId-accepted-round-1"
                            finding_id       = 'finding-t026-stable-blocker'
                            state            = 'accepted_fix_pending'
                            rationale        = $null
                            fix_evidence_ref = 'diffs/run-t026/fix-attempt.patch'
                            review_round     = 1
                            actor_role       = 'implementer'
                            recorded_at      = '2026-06-17T22:27:00Z'
                        }
                        [pscustomobject][ordered]@{
                            disposition_id   = "disp-$RunId-still-open-round-1"
                            finding_id       = 'finding-t026-stable-blocker'
                            state            = 'open'
                            rationale        = $null
                            fix_evidence_ref = $null
                            review_round     = $LatestReviewRound
                            actor_role       = 'reviewer'
                            recorded_at      = '2026-06-17T22:28:00Z'
                        }
                    )
                }

                return [pscustomobject][ordered]@{
                    schema_version     = '1.0'
                    thread_id          = "thread-$RunId"
                    run_id             = $RunId
                    checkpoint_id      = 'checkpoint-t026'
                    findings           = @('finding-t026-stable-blocker')
                    dispositions       = @($dispositions)
                    resolution_summary = 'T026 non-convergence fixture.'
                    escalation_ref     = $null
                    created_at         = '2026-06-17T22:26:00Z'
                    updated_at         = '2026-06-17T22:28:00Z'
                }
            }

        function Invoke-T026GateEvaluator {
                param(
                    [string] $RunId,
                    $FindingsResult,
                    $ReviewThread,
                    [AllowNull()]
                    $PriorFindingsResult
                )

                $command = Get-T026GateEvaluatorCommand
                return & $command `
                    -RunId $RunId `
                    -CheckpointId 'checkpoint-t026' `
                    -FindingsResult $FindingsResult `
                    -ReviewThread $ReviewThread `
                    -PriorFindingsResult $PriorFindingsResult `
                    -MaxReviewRounds 2 `
                    -SchemaRoot $script:SchemaRoot `
                    -CreatedAt $script:CreatedAt
            }
}

    

    

    

    

    It 'declares the T026 gate evaluator seam used to enforce the non-convergence cap' {
        Get-T026GateEvaluatorCommand | Should -Not -BeNullOrEmpty
    }

    It 'blocks after the initial review without escalating before the single allowed fix-verification round' {
        $runId = 'run-t026-initial'

        $verdict = Invoke-T026GateEvaluator `
            -RunId $runId `
            -FindingsResult (New-T026BlockingFindingsResult -RunId $runId) `
            -ReviewThread (New-T026ReviewThread -RunId $runId -LatestReviewRound 0) `
            -PriorFindingsResult $null

        $verdict.state | Should -Be 'blocked'
        $verdict.round_count | Should -Be 1
        $verdict.unresolved_blocking_count | Should -Be 1
        ($verdict.blocking_finding_ids -contains 'finding-t026-stable-blocker') | Should -Be $true
        $verdict.escalation_ref | Should -Be $null
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $verdict).Valid | Should -Be $true
    }

    It 'escalates to a human when the same blocking finding remains unresolved after one fix-verification round' {
        $priorRunId = 'run-t026-initial'
        $verificationRunId = 'run-t026-verification'
        $priorFindings = New-T026BlockingFindingsResult -RunId $priorRunId
        $verificationFindings = New-T026BlockingFindingsResult `
            -RunId $verificationRunId `
            -SourceRunId $priorRunId `
            -Comment 'The same stable fingerprint remains unresolved after the allowed fix-verification round.'
        $thread = New-T026ReviewThread -RunId $verificationRunId -LatestReviewRound 1 -IncludeFixAttempt:$true

        $verdict = Invoke-T026GateEvaluator `
            -RunId $verificationRunId `
            -FindingsResult $verificationFindings `
            -ReviewThread $thread `
            -PriorFindingsResult $priorFindings

        $verdict.state | Should -Be 'escalated'
        $verdict.round_count | Should -Be 2
        $verdict.unresolved_blocking_count | Should -Be 1
        ($verdict.blocking_finding_ids -contains 'finding-t026-stable-blocker') | Should -Be $true
        $verdict.escalation_ref | Should -Match 'human'
        $verdict.escalation_ref | Should -Match 'finding-t026-stable-blocker'
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $verdict).Valid | Should -Be $true
    }

    It 'a ceiling-halt emits a VISIBLE escalation finding (never a 0-findings clean pass) — false-green guard D-197-I009-010' {
        $json = New-ContinuousCoReviewCeilingEscalationResult -RunId 'run-ceiling-1' -Round 3 -MaxRounds 2
        $json | Should -Not -BeNullOrEmpty
        $obj = $json | ConvertFrom-Json
        # the whole point: a halt is NOT zero findings / clean — it carries exactly one VISIBLE escalation
        @($obj.findings).Count | Should -Be 1
        $f = @($obj.findings)[0]
        $f.severity | Should -Be 'blocking'
        $f.kind | Should -Be 'escalation'
        $f.disposition | Should -Be 'escalated_to_human'   # parked -> gate does not deadlock, but it IS surfaced
        $f.comment | Should -Match '(?i)not reviewed'
        $f.comment | Should -Match '(?i)ceiling'
        $f.comment | Should -Match '(?i)false-green'
        # schema-conformant (no D-002-style additionalProperties violation)
        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $obj).Valid | Should -Be $true
    }
}
