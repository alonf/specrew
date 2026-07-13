$ErrorActionPreference = 'Stop'

# T019 characterization slice (2026-07-13) + CONTRACT-CORRECTION pass (maintainer needs-rework review). These
# tests exercise the PURE, UNWIRED contract functions in review-identity-contracts.ps1 against the fixture
# families and assert the CORRECTED contracts (baseline tree-id vs commit ancestry; absolute digest-mismatch
# precedence; fail-closed finding joins; run-state-gated pruning; deterministic lineage id + monotonic
# same-digest authority; envelope + embedded digest validation). Nothing here touches a live runtime path.
Describe 'T019 review-identity + artifact-lifecycle contracts (corrected, UNWIRED)' {
    BeforeAll {
        Set-StrictMode -Version Latest
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-identity-contracts.ps1')
        $script:FixtureDir = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/t019'
        function Get-Fixture([string]$name) { Get-Content -LiteralPath (Join-Path $script:FixtureDir $name) -Raw | ConvertFrom-Json }
        function Test-HasProp($obj, [string]$name) { $null -ne $obj.PSObject.Properties[$name] }
    }

    Context 'Correction 6 + DRIFT-002 — envelope AND embedded digest validation' {
        It 'classifies every case exactly as the fixture specifies' {
            $fx = Get-Fixture 'drift-002-digest-a-vs-b.json'
            foreach ($case in $fx.cases) {
                $p = @{ EnvelopeDigest = $case.envelope_digest; ReviewDigest = $case.review_digest }
                if (Test-HasProp $case 'embedded_digests') { $p.EmbeddedDigests = @($case.embedded_digests) }
                if (Test-HasProp $case 'injected_subset') { $p.IsSubset = $true }
                $r = Test-ContinuousCoReviewEvidenceInjectable @p
                $r.injectable | Should -Be $case.expected_injected -Because "case '$($case.name)' injectable"
                $r.classification | Should -Be $case.expected_classification -Because "case '$($case.name)' classification"
            }
        }
        It 'an envelope that MATCHES but embeds a foreign run digest is a surfaced mismatch (not injected)' {
            $r = Test-ContinuousCoReviewEvidenceInjectable -EnvelopeDigest 'abc' -ReviewDigest 'abc' -EmbeddedDigests @('abc', 'xyz')
            $r.injectable | Should -BeFalse
            $r.classification | Should -Be 'embedded-digest-mismatch-surfaced'
        }
        It 'empty digests fail closed' {
            (Test-ContinuousCoReviewEvidenceInjectable -EnvelopeDigest '' -ReviewDigest '').injectable | Should -BeFalse
        }
    }

    Context 'Correction 2 — absolute digest-mismatch precedence (FR-045 matrix, every outcome)' {
        It 'routes every state exactly as the matrix specifies' {
            $fx = Get-Fixture 'fr045-stop-ordering-matrix.json'
            foreach ($row in $fx.matrix) {
                $r = Resolve-ContinuousCoReviewStopRouting -ReviewTerminal $row.review_terminal -ReviewOutcome $row.review_outcome -DigestMatchesCurrent $row.digest_matches_current -InFlightPresent $row.in_flight_present
                $r.render_packet | Should -Be $row.expected.render_packet -Because "state '$($row.state)' render_packet"
                $r.render_marker | Should -Be $row.expected.render_marker -Because "state '$($row.state)' render_marker"
                $r.launch_review | Should -Be $row.expected.launch_review -Because "state '$($row.state)' launch_review"
                $r.action | Should -Be $row.expected.action -Because "state '$($row.state)' action"
                $r.capturable_as_verdict | Should -Be $row.expected.capturable_as_verdict -Because "state '$($row.state)' capturable"
            }
        }
        It 'a STALE result of ANY outcome is superseded — never blocks, decides, reports, or authorizes' {
            foreach ($outcome in @('clean', 'actionable', 'human-judgment', 'infra-failure')) {
                $r = Resolve-ContinuousCoReviewStopRouting -ReviewTerminal $true -ReviewOutcome $outcome -DigestMatchesCurrent $false
                $r.render_packet | Should -BeFalse -Because "stale $outcome must not render a packet"
                $r.render_marker | Should -BeFalse -Because "stale $outcome must not carry a marker"
                $r.capturable_as_verdict | Should -BeFalse -Because "stale $outcome is never capturable"
                $r.action | Should -Be 're-review-current-digest' -Because "stale $outcome is superseded, not routed to its outcome action"
            }
        }
        It 'the invariant holds: exactly one capturable state, and a mismatch forces packet/marker/capturable false for every outcome' {
            $fx = Get-Fixture 'fr045-stop-ordering-matrix.json'
            @($fx.matrix | Where-Object { $_.expected.capturable_as_verdict }).Count | Should -Be 1
            foreach ($row in @($fx.matrix | Where-Object { -not $_.digest_matches_current })) {
                $row.expected.render_packet | Should -BeFalse
                $row.expected.render_marker | Should -BeFalse
                $row.expected.capturable_as_verdict | Should -BeFalse
            }
            foreach ($row in $fx.matrix) { $row.expected.launch_review | Should -BeFalse }
        }
    }

    Context 'Correction 3 — finding->run joins fail closed' {
        It 'validates every finding-join case per the fixture' {
            $fx = Get-Fixture 'finding-join-and-disposition.json'
            foreach ($case in $fx.finding_join_cases) {
                $id = Get-ContinuousCoReviewFindingIdentity -Finding $case.finding -RunRecord $case.run
                $id.valid | Should -Be $case.expected_valid -Because "case '$($case.name)' valid"
                if (Test-HasProp $case 'expected_reason_contains') {
                    $id.reason | Should -BeLike "*$($case.expected_reason_contains)*" -Because "case '$($case.name)' reason"
                }
            }
        }
        It 'a mismatched source_run_id is rejected even when tree + baseline are present' {
            $id = Get-ContinuousCoReviewFindingIdentity -Finding ([pscustomobject]@{ finding_id = 'f'; source_run_id = 'X' }) -RunRecord ([pscustomobject]@{ run_id = 'Y'; reviewed_tree_id = 't'; baseline_tree_id = 'b' })
            $id.valid | Should -BeFalse
        }
    }

    Context 'Correction 4 — transient artifacts prunable only after the owning run is terminal/reaped/abandoned' {
        It 'resolves every disposition case per the fixture' {
            $fx = Get-Fixture 'finding-join-and-disposition.json'
            foreach ($case in $fx.disposition_cases) {
                $p = @{ BaseClass = $case.base_class }
                if (Test-HasProp $case 'is_latest_for_lineage') { $p.IsLatestForLineage = [bool]$case.is_latest_for_lineage }
                if (Test-HasProp $case 'obsolete_policy') { $p.ObsoletePolicy = $case.obsolete_policy }
                if (Test-HasProp $case 'owning_run_state') { $p.OwningRunState = $case.owning_run_state }
                (Resolve-ContinuousCoReviewRecordDisposition @p) | Should -Be $case.expected -Because "case '$($case.name)'"
            }
        }
        It 'a transient artifact of a RUNNING run is never prunable' {
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'transient' -OwningRunState 'running' | Should -Be 'transient'
        }
    }

    Context 'Correction 5 — deterministic lineage id + monotonic same-digest authority' {
        It 'the lineage id is deterministic and anchor+target sensitive' {
            $fx = (Get-Fixture 'inflight-dedup-out-of-order.json').lineage_id_determinism
            $a = Get-ContinuousCoReviewLineageId -AnchorRef $fx.anchor_ref -TargetRef $fx.target_ref
            $b = Get-ContinuousCoReviewLineageId -AnchorRef $fx.anchor_ref -TargetRef $fx.target_ref
            $a | Should -Be $b -Because 'same inputs -> same id'
            $a | Should -Match '^lin-[0-9a-f]{16}$'
            (Get-ContinuousCoReviewLineageId -AnchorRef $fx.different_anchor_ref -TargetRef $fx.target_ref) | Should -Not -Be $a
        }
        It 'exactly one same-digest terminal run is authoritative (max run_id); others + wrong-digest + non-terminal are superseded/ineligible' {
            $fx = (Get-Fixture 'inflight-dedup-out-of-order.json').same_digest_concurrent
            $r = Resolve-ContinuousCoReviewSameDigestAuthority -Runs $fx.runs -CurrentDigest $fx.current_reviewed_digest
            $r.authoritative_run_id | Should -Be $fx.expected_authoritative_run_id
            @($r.superseded_run_ids) | Should -Be @($fx.expected_superseded_run_ids)
        }
        It 'no eligible run yields a null authority (fail-closed)' {
            (Resolve-ContinuousCoReviewSameDigestAuthority -Runs @() -CurrentDigest 'x').authoritative_run_id | Should -BeNullOrEmpty
        }
    }

    Context 'Correction 1 — auto-fire baseline is the last-accepted reviewed TREE (separate from commit ancestry)' {
        It 'resolves the baseline tree-id from the last accepted run' {
            $fx = (Get-Fixture 'inflight-dedup-out-of-order.json').auto_fire_baseline
            $r = Resolve-ContinuousCoReviewAutoFireBaselineTreeId -AcceptedRuns $fx.accepted_runs
            $r.baseline_tree_id | Should -Be $fx.expected_baseline_tree_id
            $r.from_run_id | Should -Be $fx.expected_from_run_id
        }
        It 'no accepted run yields a null baseline tree-id (runtime falls back to the merge-base commit ref)' {
            (Resolve-ContinuousCoReviewAutoFireBaselineTreeId -AcceptedRuns @()).baseline_tree_id | Should -BeNullOrEmpty
        }
    }

    Context 'in-flight dedup + out-of-order supersession (retained cases)' {
        It 'a second fire on a running lineage does not launch; a different lineage may' {
            $fx = Get-Fixture 'inflight-dedup-out-of-order.json'
            foreach ($case in @($fx.cases | Where-Object { Test-HasProp $_ 'new_fire_lineage_id' })) {
                $r = Test-ContinuousCoReviewInFlightDuplicate -LineageId $case.new_fire_lineage_id -InFlightRegistry $fx.in_flight_registry
                $r.launch | Should -Be $case.expected_launch -Because "case '$($case.name)'"
                $r.action | Should -Be $case.expected_action
            }
        }
        It 'an out-of-order older completion (digest != current) is superseded' {
            $fx = Get-Fixture 'inflight-dedup-out-of-order.json'
            foreach ($case in @($fx.cases | Where-Object { Test-HasProp $_ 'completing_digest' })) {
                $r = Test-ContinuousCoReviewResultSuperseded -CompletingDigest $case.completing_digest -CurrentDigest $case.current_reviewed_digest
                $r.authoritative | Should -Be $case.expected_authoritative -Because "case '$($case.name)'"
                $r.classification | Should -Be $case.expected_classification
            }
        }
    }

    Context 'artifact lifecycle base classes' {
        It 'classifies every on-disk family by its shipped tracked/ephemeral reality' {
            (Get-ContinuousCoReviewArtifactClass '.specrew/review/pending/r1.json').base_class | Should -Be 'transient'
            (Get-ContinuousCoReviewArtifactClass 'x/.review/changes.diff').base_class | Should -Be 'transient'
            $inline = Get-ContinuousCoReviewArtifactClass '.specrew/review/inline/r/findings-result.json'
            $inline.base_class | Should -Be 'durable'; $inline.git_tracked | Should -BeTrue; $inline.supersedable | Should -BeTrue
            (Get-ContinuousCoReviewArtifactClass '.specrew/review/signoff-gate/latest.json').supersedable | Should -BeFalse
            (Get-ContinuousCoReviewArtifactClass 'src/schema.ps1').base_class | Should -Be 'unknown'
        }
    }
}
