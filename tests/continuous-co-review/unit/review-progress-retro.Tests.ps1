$ErrorActionPreference = 'Stop'

# Trace: T058 / FR-062, FR-063 / SC-020, SC-021 / NFR-002.
Describe 'Informational review progress and retrospective evidence projection (T058)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-progress-projection.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-retro-projection.ps1')

        function script:New-T058Finding {
            param(
                [string]$FindingId,
                [string]$LineageId = 'lin-shared-problem',
                [string]$Severity = 'major',
                [string]$Relevance = 'current',
                [string]$Resolution = 'open'
            )
            return [pscustomobject][ordered]@{
                finding_id = $FindingId; source_local_id = 'local-problem'; lineage_id = $LineageId
                severity = $Severity; title = 'Shared problem'; description = 'A validated review problem.'
                location = 'src/app.ps1:10'; relevance = $Relevance; resolution = $Resolution
            }
        }

        function script:New-T058Result {
            param(
                [string]$RunId,
                [string]$HarnessId,
                [string]$Completion = 'complete',
                [string]$Verdict = 'findings',
                [string]$RuntimeOutcome = 'completed',
                [string]$Currentness = 'current',
                [AllowNull()]$FailureReason = $null,
                [object[]]$Findings = @()
            )
            return [pscustomobject][ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-retro'; run_id = $RunId; target_digest = 'digest-reviewed'; harness_id = $HarnessId
                completion = $Completion; verdict = $Verdict; runtime_outcome = $RuntimeOutcome; termination_verified = $true
                containment = 'verified'; currentness = $Currentness; validation = 'valid'; can_approve_current = $false
                failure_reason = $FailureReason; summary = 'validated terminal result'; findings = @($Findings)
                started_at = '2026-07-16T00:00:00Z'; ended_at = '2026-07-16T00:00:01Z'; duration_ms = 1000
            }
        }
    }

    It 'projects only bounded non-authoritative fields and honest optional usage' {
        $usage = [ordered]@{ input_tokens = 12; output_tokens = 5; total_tokens = 17; cost_usd = '0.0042'; api_key = 'must-not-project' }
        $event = New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage running -ObservedAt '2026-07-16T00:00:00Z' `
            -ElapsedMilliseconds 1250 -TimeoutSeconds 2 -Message ('x' * 800) -ProcessTreeLive $true -OutputActivity $false -ValidatedFindingCount 3 -Usage $usage

        $event.authority | Should -BeFalse
        $event.elapsed_ms | Should -Be 1250
        $event.remaining_ms | Should -Be 750
        $event.message.Length | Should -Be 500
        $event.validated_finding_count | Should -Be 3
        $event.usage.status | Should -Be 'available'
        $event.usage.total_tokens | Should -Be 17
        $event.usage.cost_usd | Should -Be ([decimal]'0.0042')
        ($event | ConvertTo-Json -Depth 8) | Should -Not -Match 'api_key|must-not-project'

        $missing = New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-two -Stage running -ObservedAt '2026-07-16T00:00:01Z' `
            -ElapsedMilliseconds 0 -Usage ([ordered]@{ input_tokens = -1; cost_usd = 'not-a-number'; secret = 'hidden' })
        $missing.usage.status | Should -Be 'unavailable'
        $missing.usage.input_tokens | Should -BeNullOrEmpty
        $missing.validated_finding_count | Should -BeNullOrEmpty
    }

    It 'contains sink failures and preserves a terminal event in the bounded collector' {
        $collector = New-ReviewProgressCollector -ExternalSink { param($event) throw 'renderer unavailable' } -MaximumEvents 16
        { foreach ($i in 0..15) { & $collector.sink (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage running -ObservedAt '2026-07-16T00:00:00Z' -ElapsedMilliseconds $i) } } | Should -Not -Throw
        { & $collector.sink (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage terminal -ObservedAt '2026-07-16T00:00:01Z' -ElapsedMilliseconds 20) } | Should -Not -Throw

        @($collector.events).Count | Should -Be 16
        @($collector.events | Where-Object { [string]$_.stage -ceq 'terminal' }).Count | Should -Be 1
        @($collector.events | Where-Object { $_.authority }).Count | Should -Be 0

        $mutating = New-ReviewProgressCollector -ExternalSink { param($event) $event.authority = $true; $event.message = 'renderer rewrite' }
        $original = New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-two -Stage requested -ObservedAt '2026-07-16T00:00:00Z' -ElapsedMilliseconds 0 -Message 'controller message'
        & $mutating.sink $original
        $original.authority | Should -BeTrue -Because 'the fixture renderer mutated only its own argument'
        $mutating.events[0].authority | Should -BeFalse
        $mutating.events[0].message | Should -Be 'controller message'
    }

    It 'derives timing, heartbeat, duplicate, and safe usage diagnostics without authority' {
        $events = @(
            (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage requested -ObservedAt '2026-07-16T00:00:00Z' -ElapsedMilliseconds 0),
            (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage duplicate-warning -ObservedAt '2026-07-16T00:00:00Z' -ElapsedMilliseconds 100),
            (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage running -ObservedAt '2026-07-16T00:00:01Z' -ElapsedMilliseconds 250 -ProcessTreeLive $true),
            (New-ReviewProgressEvent -CampaignId cmp-demo -RunId run-one -Stage terminal -ObservedAt '2026-07-16T00:00:02Z' -ElapsedMilliseconds 1000 -ProcessTreeLive $false -Usage ([ordered]@{ total_tokens = 42 }))
        )
        $diagnostics = Get-ReviewProgressDiagnostics -Events $events

        $diagnostics.authority | Should -BeFalse
        $diagnostics.event_count | Should -Be 4
        $diagnostics.elapsed_ms | Should -Be 1000
        $diagnostics.heartbeat_count | Should -Be 1
        $diagnostics.duplicate_warning | Should -BeTrue
        $diagnostics.usage.status | Should -Be 'available'
        $diagnostics.usage.total_tokens | Should -Be 42
        ($diagnostics.phase_durations | Measure-Object duration_ms -Sum).Sum | Should -Be 1000
        (Format-ReviewProgressEvent -Event $events[2]) | Should -Match 'tree=live'
    }

    It 'deduplicates complete and partial findings by lineage while retaining every validated source' {
        $complete = New-T058Result -RunId run-complete -HarnessId claude -Findings @(
            (New-T058Finding -FindingId finding-complete -Severity major -Relevance current -Resolution resolved)
        )
        $partial = New-T058Result -RunId run-partial -HarnessId codex -Completion partial -Verdict incomplete -RuntimeOutcome timed-out `
            -Currentness snapshot-moved -FailureReason 'timeout after verified process-tree kill' -Findings @(
                (New-T058Finding -FindingId finding-partial -Severity blocking -Relevance snapshot-moved -Resolution open)
            )

        $projection = ConvertTo-ReviewRetrospectiveEvidence -Results @($complete, $partial)
        $projection.source_kind | Should -Be 'validated-review-result-json'
        $projection.authority | Should -BeFalse
        $projection.problem_count | Should -Be 1
        $projection.problems[0].lineage_id | Should -Be 'lin-shared-problem'
        $projection.problems[0].severity | Should -Be 'blocking'
        $projection.problems[0].source_count | Should -Be 2
        @($projection.problems[0].sources.run_id) | Should -Contain run-complete
        @($projection.problems[0].sources.run_id) | Should -Contain run-partial
        @($projection.problems[0].sources.harness_id) | Should -Contain claude
        @($projection.problems[0].sources.harness_id) | Should -Contain codex
        @($projection.problems[0].sources.completion) | Should -Contain partial
        @($projection.problems[0].sources.currentness) | Should -Contain snapshot-moved
        @($projection.problems[0].sources.relevance) | Should -Contain snapshot-moved
        @($projection.problems[0].sources.resolution) | Should -Contain resolved
        @($projection.problems[0].sources.failure_reason) | Should -Contain 'timeout after verified process-tree kill'

        $reverse = ConvertTo-ReviewRetrospectiveEvidence -Results @($partial, $complete)
        ($reverse | ConvertTo-Json -Depth 12 -Compress) | Should -Be ($projection | ConvertTo-Json -Depth 12 -Compress)
    }

    It 'reads controller result JSON from the immutable store and rejects invalid result shapes' {
        $store = Join-Path $TestDrive 'retro-store'
        $result = New-T058Result -RunId run-store -HarnessId copilot -Findings @((New-T058Finding -FindingId finding-store))
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId cmp-retro -RunId run-store -Fact $result | Out-Null
        [IO.File]::WriteAllText((Join-Path $store 'untrusted-report.md'), '# fake Markdown finding', [Text.UTF8Encoding]::new($false))

        $projection = Get-ReviewCampaignRetrospectiveEvidence -StoreRoot $store -CampaignId cmp-retro
        $projection.problem_count | Should -Be 1
        $projection.problems[0].sources[0].run_id | Should -Be run-store

        $invalid = $result.PSObject.Copy()
        $invalid | Add-Member -NotePropertyName markdown_claim -NotePropertyValue 'pass'
        { ConvertTo-ReviewRetrospectiveEvidence -Results @($invalid) } | Should -Throw -ExpectedMessage '*review-retro-invalid-result*unknown-field:markdown_claim*'
    }
}
