$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T025 TG-011 inline review gate evaluator obeys implementation-rules.yml deterministic gate semantics' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'
        $script:CreatedAt = [datetime] '2026-06-17T22:25:00Z'
    }

    function Get-T025GateEvaluatorCommand {
        $command = Get-Command -Name 'Invoke-ContinuousCoReviewInlineGateEvaluator' -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T025FindingsResult {
        param(
            [string] $RunId = 'run-t025-gate',
            [string] $Status = 'findings',
            [bool] $IncludeFinding = $true,
            [string] $FindingId = 'finding-t025',
            [string] $Severity = 'blocking',
            [string] $Disposition = 'open',
            [string] $ResolutionState = 'unresolved',
            [AllowNull()]
            [string] $FixEvidenceRef = $null,
            [AllowNull()]
            [string] $Rationale = $null
        )

        $findings = @()
        if ($IncludeFinding) {
            $findings = @(
                [pscustomobject][ordered]@{
                    finding_id       = $FindingId
                    source_run_id    = $RunId
                    fingerprint      = "sha256:$FindingId"
                    location         = [pscustomobject][ordered]@{
                        path       = 'scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1'
                        line_start = 25
                        line_end   = 31
                    }
                    severity         = $Severity
                    kind             = 'gate-semantics'
                    design_reference = 'FR-006'
                    comment          = "T025 fixture for $Severity $Disposition."
                    disposition      = $Disposition
                    resolution       = [pscustomobject][ordered]@{
                        state            = $ResolutionState
                        fix_evidence_ref = $FixEvidenceRef
                        rationale        = $Rationale
                    }
                }
            )
        }

        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            status         = $Status
            reviewer       = [pscustomobject][ordered]@{
                host       = 'fixture'
                model      = 'fixture-reviewer'
                adapter_id = 'reviewer-host-adapter-fixture'
            }
            findings       = @($findings)
            result_hash    = "sha256:$RunId"
            created_at     = '2026-06-17T22:25:00Z'
        }
    }

    function New-T025ReviewThread {
        param(
            [string] $RunId = 'run-t025-gate',
            [string] $CheckpointId = 'checkpoint-t025',
            [string] $FindingId = 'finding-t025',
            [string] $State = 'open',
            [AllowNull()]
            [string] $FixEvidenceRef = $null,
            [AllowNull()]
            [string] $Rationale = $null
        )

        $dispositions = @()
        $findings = @()
        if (-not [string]::IsNullOrWhiteSpace($FindingId)) {
            $findings = @($FindingId)
            $dispositions = @(
                [pscustomobject][ordered]@{
                    disposition_id   = "disp-$FindingId-$State"
                    finding_id       = $FindingId
                    state            = $State
                    rationale        = $Rationale
                    fix_evidence_ref = $FixEvidenceRef
                    review_round     = 0
                    actor_role       = 'reviewer'
                    recorded_at      = '2026-06-17T22:25:00Z'
                }
            )
        }

        return [pscustomobject][ordered]@{
            schema_version     = '1.0'
            thread_id          = "thread-$RunId"
            run_id             = $RunId
            checkpoint_id      = $CheckpointId
            findings           = @($findings)
            dispositions       = @($dispositions)
            resolution_summary = "T025 $State gate fixture."
            escalation_ref     = $null
            created_at         = '2026-06-17T22:25:00Z'
            updated_at         = '2026-06-17T22:25:00Z'
        }
    }

    function New-T025SkippedRun {
        param(
            [string] $RunId = 'run-t025-skipped'
        )

        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            checkpoint_id  = 'checkpoint-t025'
            baseline_ref   = 'baseline-t025'
            reason         = 'no-reviewable-diff'
            diff_hash      = 'sha256:0000000000000000000000000000000000000000000000000000000000000000'
        }
    }

    function Invoke-T025GateEvaluator {
        param(
            [string] $RunId = 'run-t025-gate',
            [string] $CheckpointId = 'checkpoint-t025',
            [AllowNull()]
            $FindingsResult,
            [AllowNull()]
            $ReviewThread,
            [AllowNull()]
            $SkippedRun
        )

        $command = Get-T025GateEvaluatorCommand
        if ($null -ne $SkippedRun) {
            return & $command `
                -RunId $RunId `
                -CheckpointId $CheckpointId `
                -SkippedRun $SkippedRun `
                -SchemaRoot $script:SchemaRoot `
                -CreatedAt $script:CreatedAt
        }

        return & $command `
            -RunId $RunId `
            -CheckpointId $CheckpointId `
            -FindingsResult $FindingsResult `
            -ReviewThread $ReviewThread `
            -SchemaRoot $script:SchemaRoot `
            -CreatedAt $script:CreatedAt
    }

    It 'declares the T025 standalone gate evaluator command before T028 implementation' {
        Get-T025GateEvaluatorCommand | Should Not BeNullOrEmpty
    }

    It 'passes when the FindingsResult is explicit no_findings for FR-006 SC-003' {
        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult (New-T025FindingsResult -Status 'no_findings' -IncludeFinding:$false) `
            -ReviewThread (New-T025ReviewThread -FindingId '')

        $verdict.state | Should Be 'pass'
        $verdict.unresolved_blocking_count | Should Be 0
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $verdict).Valid | Should Be $true
    }

    It 'blocks checkpoint advancement while an unresolved blocking finding exists for SC-002' {
        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult (New-T025FindingsResult -Severity 'blocking' -Disposition 'open' -ResolutionState 'unresolved') `
            -ReviewThread (New-T025ReviewThread -State 'open')

        $verdict.state | Should Be 'blocked'
        $verdict.unresolved_blocking_count | Should Be 1
        ($verdict.blocking_finding_ids -contains 'finding-t025') | Should Be $true
    }

    It 'marks malformed blackboard state unsafe instead of passing by default' {
        $thread = New-T025ReviewThread
        $thread.run_id = 'run-t025-mismatched-thread'

        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult (New-T025FindingsResult) `
            -ReviewThread $thread

        $verdict.state | Should Be 'unsafe'
        ($verdict.unsafe_reasons -contains 'malformed-durable-state') | Should Be $true
    }

    It 'marks invalid FindingsResult schema unsafe for NFR-001 and FR-007' {
        $invalidFindings = New-T025FindingsResult
        $invalidFindings.findings[0].PSObject.Properties.Remove('design_reference')

        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult $invalidFindings `
            -ReviewThread (New-T025ReviewThread)

        $verdict.state | Should Be 'unsafe'
        ($verdict.unsafe_reasons -contains 'invalid-findings-schema') | Should Be $true
    }

    It 'marks an unknown blocking disposition unsafe rather than silently passing it' {
        $unknownDisposition = New-T025FindingsResult -Severity 'blocking' -Disposition 'deferred_without_authorization' -ResolutionState 'unresolved'

        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult $unknownDisposition `
            -ReviewThread (New-T025ReviewThread -State 'open')

        $verdict.state | Should Be 'unsafe'
        ($verdict.unsafe_reasons -contains 'unknown-blocking-disposition') | Should Be $true
    }

    It 'passes when blocking findings are resolved with fix evidence for SC-003' {
        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult (New-T025FindingsResult -Severity 'blocking' -Disposition 'resolved' -ResolutionState 'resolved' -FixEvidenceRef 'diffs/run-t025/fix.patch') `
            -ReviewThread (New-T025ReviewThread -State 'resolved' -FixEvidenceRef 'diffs/run-t025/fix.patch')

        $verdict.state | Should Be 'pass'
        $verdict.unresolved_blocking_count | Should Be 0
        @($verdict.blocking_finding_ids).Count | Should Be 0
    }

    It 'passes advisory-only findings without unresolved blocking count' {
        $verdict = Invoke-T025GateEvaluator `
            -FindingsResult (New-T025FindingsResult -FindingId 'finding-t025-advisory' -Severity 'advisory' -Disposition 'open' -ResolutionState 'unresolved') `
            -ReviewThread (New-T025ReviewThread -FindingId 'finding-t025-advisory' -State 'open')

        $verdict.state | Should Be 'pass'
        $verdict.unresolved_blocking_count | Should Be 0
    }

    It 'emits an explicit skipped pass/no-op verdict for no-reviewable-diff SC-009 without reviewer findings' {
        $skippedRun = New-T025SkippedRun

        $verdict = Invoke-T025GateEvaluator -RunId $skippedRun.run_id -SkippedRun $skippedRun

        $verdict.state | Should Be 'skipped'
        $verdict.unresolved_blocking_count | Should Be 0
        $verdict.round_count | Should Be 0
        @($verdict.blocking_finding_ids).Count | Should Be 0
        @($verdict.unsafe_reasons).Count | Should Be 0
        (Test-ReviewerContractObject -ContractName 'GateVerdict' -SchemaRoot $script:SchemaRoot -InputObject $verdict).Valid | Should Be $true
    }
}
