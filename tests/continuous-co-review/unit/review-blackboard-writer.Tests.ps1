$ErrorActionPreference = 'Stop'

Describe 'Proposal 197 T024 TG-011 review blackboard writer obeys implementation-rules.yml durable thread protocol' {
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
        $script:CreatedAt = [datetime] '2026-06-17T22:24:00Z'
    }

    function Get-T024BlackboardWriterCommand {
        $command = Get-Command -Name 'Write-ContinuousCoReviewBlackboardThread' -ErrorAction SilentlyContinue
        $null = ($command | Should Not BeNullOrEmpty)
        return $command
    }

    function New-T024FindingsResult {
        param(
            [string] $RunId = 'run-t024-blackboard'
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
                    finding_id       = 'finding-t024-blocking'
                    source_run_id    = $RunId
                    fingerprint      = 'sha256:finding-t024-blocking'
                    location         = [pscustomobject][ordered]@{
                        path       = 'scripts/internal/continuous-co-review/review-blackboard-writer.ps1'
                        line_start = 24
                        line_end   = 30
                    }
                    severity         = 'blocking'
                    kind             = 'durable-thread-contract'
                    design_reference = 'FR-004'
                    comment          = 'Blocking finding must be durable in the inline review blackboard.'
                    disposition      = 'open'
                    resolution       = [pscustomobject][ordered]@{
                        state            = 'unresolved'
                        fix_evidence_ref = $null
                        rationale        = $null
                    }
                }
                [pscustomobject][ordered]@{
                    finding_id       = 'finding-t024-advisory'
                    source_run_id    = $RunId
                    fingerprint      = 'sha256:finding-t024-advisory'
                    location         = [pscustomobject][ordered]@{
                        path       = 'tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1'
                        line_start = 1
                        line_end   = 1
                    }
                    severity         = 'advisory'
                    kind             = 'documentation-follow-up'
                    design_reference = 'SC-004'
                    comment          = 'Advisory finding is intentionally rejected with rationale in this fixture.'
                    disposition      = 'open'
                    resolution       = [pscustomobject][ordered]@{
                        state            = 'unresolved'
                        fix_evidence_ref = $null
                        rationale        = $null
                    }
                }
            )
            result_hash    = 'sha256:t024-findings-result'
            created_at     = '2026-06-17T22:24:00Z'
        }
    }

    function New-T024DispositionTrail {
        return @(
            [pscustomobject][ordered]@{
                disposition_id   = 'disp-t024-blocking-open'
                finding_id       = 'finding-t024-blocking'
                state            = 'open'
                rationale        = $null
                fix_evidence_ref = $null
                review_round     = 0
                actor_role       = 'reviewer'
                recorded_at      = '2026-06-17T22:24:00Z'
            }
            [pscustomobject][ordered]@{
                disposition_id   = 'disp-t024-blocking-accepted'
                finding_id       = 'finding-t024-blocking'
                state            = 'accepted_fix_pending'
                rationale        = $null
                fix_evidence_ref = 'diffs/run-t024/finding-t024-blocking.patch'
                review_round     = 1
                actor_role       = 'implementer'
                recorded_at      = '2026-06-17T22:25:00Z'
            }
            [pscustomobject][ordered]@{
                disposition_id   = 'disp-t024-blocking-resolved'
                finding_id       = 'finding-t024-blocking'
                state            = 'resolved'
                rationale        = $null
                fix_evidence_ref = 'diffs/run-t024/finding-t024-blocking.patch'
                review_round     = 1
                actor_role       = 'reviewer'
                recorded_at      = '2026-06-17T22:26:00Z'
            }
            [pscustomobject][ordered]@{
                disposition_id   = 'disp-t024-advisory-open'
                finding_id       = 'finding-t024-advisory'
                state            = 'open'
                rationale        = $null
                fix_evidence_ref = $null
                review_round     = 0
                actor_role       = 'reviewer'
                recorded_at      = '2026-06-17T22:24:00Z'
            }
            [pscustomobject][ordered]@{
                disposition_id   = 'disp-t024-advisory-rejected'
                finding_id       = 'finding-t024-advisory'
                state            = 'rejected_with_rationale'
                rationale        = 'Advisory suggestion conflicts with the approved TG-011 fixture scope.'
                fix_evidence_ref = $null
                review_round     = 1
                actor_role       = 'implementer'
                recorded_at      = '2026-06-17T22:25:30Z'
            }
        )
    }

    function Invoke-T024BlackboardWriter {
        param(
            [string] $RepoRoot,
            $FindingsResult,
            [AllowNull()]
            $DispositionTrail
        )

        $command = Get-T024BlackboardWriterCommand
        return & $command `
            -RepoRoot $RepoRoot `
            -CheckpointId 'checkpoint-t024' `
            -FindingsResult $FindingsResult `
            -DispositionTrail $DispositionTrail `
            -SchemaRoot $script:SchemaRoot `
            -CreatedAt $script:CreatedAt
    }

    It 'declares the T024 blackboard writer command before T027 durable artifacts are implemented' {
        Get-T024BlackboardWriterCommand | Should Not BeNullOrEmpty
    }

    It 'writes FindingsResult and ReviewThread under .specrew/review/inline/<run-id> with valid FR-004 DS-002 artifacts' {
        $repoRoot = Join-Path $TestDrive 'repo'
        New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null

        $result = Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult (New-T024FindingsResult) -DispositionTrail (New-T024DispositionTrail)
        $runRoot = Join-Path $repoRoot '.specrew/review/inline/run-t024-blackboard'
        $findingsPath = Join-Path $runRoot 'findings-result.json'
        $threadPath = Join-Path $runRoot 'review-thread.json'

        Test-Path -LiteralPath $runRoot -PathType Container | Should Be $true
        Test-Path -LiteralPath $findingsPath -PathType Leaf | Should Be $true
        Test-Path -LiteralPath $threadPath -PathType Leaf | Should Be $true
        $result.run_id | Should Be 'run-t024-blackboard'
        $result.blackboard_root | Should Be $runRoot

        $persistedFindings = Read-ReviewerContractJson -Path $findingsPath
        $persistedThread = Read-ReviewerContractJson -Path $threadPath

        (Test-ReviewerContractObject -ContractName 'FindingsResult' -SchemaRoot $script:SchemaRoot -InputObject $persistedFindings).Valid | Should Be $true
        (Test-ReviewerContractObject -ContractName 'ReviewThread' -SchemaRoot $script:SchemaRoot -InputObject $persistedThread).Valid | Should Be $true
        $persistedThread.run_id | Should Be 'run-t024-blackboard'
        $persistedThread.checkpoint_id | Should Be 'checkpoint-t024'
        ($persistedThread.findings -contains 'finding-t024-blocking') | Should Be $true
        ($persistedThread.findings -contains 'finding-t024-advisory') | Should Be $true
    }

    It 'preserves complete finding fields required by FR-005 OBS-002 SC-004' {
        $repoRoot = Join-Path $TestDrive 'repo-complete-fields'
        New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
        Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult (New-T024FindingsResult) -DispositionTrail (New-T024DispositionTrail) | Out-Null

        $persistedFindings = Read-ReviewerContractJson -Path (Join-Path $repoRoot '.specrew/review/inline/run-t024-blackboard/findings-result.json')
        $finding = @($persistedFindings.findings | Where-Object { $_.finding_id -eq 'finding-t024-blocking' })[0]

        foreach ($requiredField in @('finding_id', 'source_run_id', 'fingerprint', 'location', 'severity', 'kind', 'design_reference', 'comment', 'disposition', 'resolution')) {
            (Test-ReviewerContractPropertyExists -Object $finding -Name $requiredField) | Should Be $true
        }
        $finding.location.path | Should Be 'scripts/internal/continuous-co-review/review-blackboard-writer.ps1'
        $finding.location.line_start | Should Be 24
        $finding.location.line_end | Should Be 30
        $finding.severity | Should Be 'blocking'
        $finding.design_reference | Should Be 'FR-004'
        $finding.resolution.state | Should Be 'unresolved'
    }

    It 'records disposition trail rationale on rejection and fix evidence refs for SC-004' {
        $repoRoot = Join-Path $TestDrive 'repo-dispositions'
        New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
        Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult (New-T024FindingsResult) -DispositionTrail (New-T024DispositionTrail) | Out-Null

        $thread = Read-ReviewerContractJson -Path (Join-Path $repoRoot '.specrew/review/inline/run-t024-blackboard/review-thread.json')
        $blockingTrail = @($thread.dispositions | Where-Object { $_.finding_id -eq 'finding-t024-blocking' })
        $rejection = @($thread.dispositions | Where-Object { $_.state -eq 'rejected_with_rationale' })[0]
        $resolved = @($thread.dispositions | Where-Object { $_.state -eq 'resolved' })[0]

        @($blockingTrail).Count | Should Be 3
        ($blockingTrail.state -contains 'open') | Should Be $true
        ($blockingTrail.state -contains 'accepted_fix_pending') | Should Be $true
        ($blockingTrail.state -contains 'resolved') | Should Be $true
        $rejection.finding_id | Should Be 'finding-t024-advisory'
        $rejection.rationale | Should Match '\S'
        $resolved.fix_evidence_ref | Should Be 'diffs/run-t024/finding-t024-blocking.patch'
    }

    It 'is idempotent for identical durable writes by run id and rejects accidental overwrite drift' {
        $repoRoot = Join-Path $TestDrive 'repo-idempotent'
        New-Item -ItemType Directory -Path $repoRoot -Force | Out-Null
        $findings = New-T024FindingsResult
        $dispositions = New-T024DispositionTrail

        Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult $findings -DispositionTrail $dispositions | Out-Null
        $threadPath = Join-Path $repoRoot '.specrew/review/inline/run-t024-blackboard/review-thread.json'
        $firstHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $threadPath).Hash
        Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult $findings -DispositionTrail $dispositions | Out-Null
        $secondHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $threadPath).Hash

        $firstHash | Should Be $secondHash
        @((Get-ChildItem -LiteralPath (Join-Path $repoRoot '.specrew/review/inline') -Directory)).Count | Should Be 1

        $conflictingFindings = New-T024FindingsResult
        $conflictingFindings.findings[0].comment = 'Conflicting durable content for the same run id must not overwrite prior evidence.'
        { Invoke-T024BlackboardWriter -RepoRoot $repoRoot -FindingsResult $conflictingFindings -DispositionTrail $dispositions } | Should Throw 'Durable review artifact already exists with different content'
    }
}
