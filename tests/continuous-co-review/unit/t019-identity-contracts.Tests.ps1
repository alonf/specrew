$ErrorActionPreference = 'Stop'

# T019 characterization slice (2026-07-13): these tests exercise the PURE, UNWIRED contract functions
# in review-identity-contracts.ps1 against the three fixture families (DRIFT-002 digest-A-vs-B,
# in-flight dedup + out-of-order completion, and the FR-045 Stop-ordering state matrix). They assert
# the CONTRACT the shipped runtime must satisfy once wired (step 6). Nothing here touches a live
# navigator / Stop / orchestrator path.
Describe 'T019 review-identity + artifact-lifecycle contracts (characterization slice, UNWIRED)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-identity-contracts.ps1')
        $script:FixtureDir = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/t019'
        function Get-Fixture([string]$name) {
            Get-Content -LiteralPath (Join-Path $script:FixtureDir $name) -Raw | ConvertFrom-Json
        }
        function Test-HasProp($obj, [string]$name) { $null -ne $obj.PSObject.Properties[$name] }
    }

    Context 'Step 3 — DRIFT-198-I003-002: digest-A evidence vs a digest-B review' {
        It 'classifies every case exactly as the fixture specifies (exact-inject, full-mismatch, partial-subset)' {
            $fx = Get-Fixture 'drift-002-digest-a-vs-b.json'
            foreach ($case in $fx.cases) {
                $isSubset = Test-HasProp $case 'injected_subset'
                $r = Test-ContinuousCoReviewEvidenceInjectable -EvidenceDigest $case.evidence_digest -ReviewDigest $case.review_digest -IsSubset:$isSubset
                $r.injectable | Should -Be $case.expected_injected -Because "case '$($case.name)' injectable"
                $r.classification | Should -Be $case.expected_classification -Because "case '$($case.name)' classification"
            }
        }

        It 'a partial subset of digest-A evidence is NEVER injectable into a digest-B review (never presented as clean)' {
            $r = Test-ContinuousCoReviewEvidenceInjectable -EvidenceDigest 'aaaa' -ReviewDigest 'bbbb' -IsSubset
            $r.injectable | Should -BeFalse
            $r.classification | Should -Be 'partial-injection-mismatch-surfaced'
        }

        It 'only an EXACT digest match is injectable' {
            (Test-ContinuousCoReviewEvidenceInjectable -EvidenceDigest 'abc123' -ReviewDigest 'abc123').injectable | Should -BeTrue
            (Test-ContinuousCoReviewEvidenceInjectable -EvidenceDigest '' -ReviewDigest '').injectable | Should -BeFalse -Because 'an empty digest never matches (fail-closed)'
        }
    }

    Context 'Step 4 — in-flight dedup + out-of-order completion' {
        It 'a second fire on a lineage with a running review does NOT launch; a different lineage may' {
            $fx = Get-Fixture 'inflight-dedup-out-of-order.json'
            foreach ($case in @($fx.cases | Where-Object { Test-HasProp $_ 'new_fire_lineage_id' })) {
                $r = Test-ContinuousCoReviewInFlightDuplicate -LineageId $case.new_fire_lineage_id -InFlightRegistry $fx.in_flight_registry
                $r.launch | Should -Be $case.expected_launch -Because "case '$($case.name)' launch"
                $r.action | Should -Be $case.expected_action -Because "case '$($case.name)' action"
            }
        }

        It 'a completion is authoritative ONLY when its digest equals the current tree (out-of-order older = superseded)' {
            $fx = Get-Fixture 'inflight-dedup-out-of-order.json'
            foreach ($case in @($fx.cases | Where-Object { Test-HasProp $_ 'completing_digest' })) {
                $r = Test-ContinuousCoReviewResultSuperseded -CompletingDigest $case.completing_digest -CurrentDigest $case.current_reviewed_digest
                $r.authoritative | Should -Be $case.expected_authoritative -Because "case '$($case.name)' authoritative"
                $r.classification | Should -Be $case.expected_classification -Because "case '$($case.name)' classification"
            }
        }

        It 'the dedup decision keys on lineage_id AND running status (a done run does not dedup)' {
            $reg = @([pscustomobject]@{ run_id = 'r1'; lineage_id = 'L'; status = 'done' })
            (Test-ContinuousCoReviewInFlightDuplicate -LineageId 'L' -InFlightRegistry $reg).is_duplicate | Should -BeFalse -Because 'a completed run is not in flight'
            $reg2 = @([pscustomobject]@{ run_id = 'r2'; lineage_id = 'L'; status = 'running' })
            $d = Test-ContinuousCoReviewInFlightDuplicate -LineageId 'L' -InFlightRegistry $reg2
            $d.is_duplicate | Should -BeTrue
            $d.existing_run_id | Should -Be 'r2'
        }
    }

    Context 'Step 5 — FR-045 Stop-ordering state matrix' {
        It 'routes every state exactly as the matrix specifies' {
            $fx = Get-Fixture 'fr045-stop-ordering-matrix.json'
            foreach ($row in $fx.matrix) {
                $r = Resolve-ContinuousCoReviewStopRouting -ReviewTerminal $row.review_terminal -ReviewOutcome $row.review_outcome -DigestMatchesCurrent $row.digest_matches_current -InFlightPresent $row.in_flight_present
                $r.render_packet | Should -Be $row.expected.render_packet -Because "state '$($row.state)' render_packet"
                $r.render_marker | Should -Be $row.expected.render_marker -Because "state '$($row.state)' render_marker"
                $r.launch_review | Should -Be $row.expected.launch_review -Because "state '$($row.state)' launch_review"
                $r.action | Should -Be $row.expected.action -Because "state '$($row.state)' action"
                $r.capturable_as_verdict | Should -Be $row.expected.capturable_as_verdict -Because "state '$($row.state)' capturable_as_verdict"
            }
        }

        It 'enforces the invariant: EXACTLY ONE state is capturable, and render_marker implies capturable + terminal + clean + current' {
            $fx = Get-Fixture 'fr045-stop-ordering-matrix.json'
            $capturable = @($fx.matrix | Where-Object { $_.expected.capturable_as_verdict })
            $capturable.Count | Should -Be 1 -Because 'only clean-current-digest may be captured as a verdict'
            $capturable[0].state | Should -Be 'clean-current-digest'
            foreach ($row in @($fx.matrix | Where-Object { $_.expected.render_marker })) {
                $row.expected.capturable_as_verdict | Should -BeTrue -Because 'a marker always implies capturable'
                $row.review_terminal | Should -BeTrue
                $row.review_outcome | Should -Be 'clean'
                $row.digest_matches_current | Should -BeTrue
            }
        }

        It 'launch_review is NEVER true on the Stop path (the navigator owns firing); a running review always waits' {
            $fx = Get-Fixture 'fr045-stop-ordering-matrix.json'
            foreach ($row in $fx.matrix) { $row.expected.launch_review | Should -BeFalse }
            (Resolve-ContinuousCoReviewStopRouting -ReviewTerminal $false -ReviewOutcome 'running' -DigestMatchesCurrent $true).action | Should -Be 'wait-poll-existing'
        }

        It 'an unknown terminal outcome fails closed (no packet, no marker, not capturable)' {
            $r = Resolve-ContinuousCoReviewStopRouting -ReviewTerminal $true -ReviewOutcome 'something-new' -DigestMatchesCurrent $true
            $r.render_packet | Should -BeFalse
            $r.capturable_as_verdict | Should -BeFalse
        }
    }

    Context 'Step 1 — per-finding identity binds finding to reviewed tree AND baseline' {
        It 'composes the global finding identity from the finding + its run record' {
            $finding = [pscustomobject]@{ finding_id = 'f1'; source_run_id = 'run-A'; fingerprint = 'sha256:deadbeef' }
            $run = [pscustomobject]@{ reviewed_tree_id = 'tree-A'; baseline_ref = '029fd862' }
            $id = Get-ContinuousCoReviewFindingIdentity -Finding $finding -RunRecord $run
            $id.finding_id | Should -Be 'f1'
            $id.source_run_id | Should -Be 'run-A'
            $id.reviewed_tree_id | Should -Be 'tree-A' -Because 'the finding is bound to the reviewed tree via its run'
            $id.baseline_ref | Should -Be '029fd862' -Because 'and to the baseline, so a mixed run set distinguishes stale from valid per-finding'
            $id.fingerprint | Should -Be 'sha256:deadbeef'
        }

        It 'tolerates the status.json spelling (reviewed_digest_tree_id) when the durable reviewed_tree_id is absent' {
            $finding = [pscustomobject]@{ finding_id = 'f2'; source_run_id = 'run-B' }
            $run = [pscustomobject]@{ reviewed_digest_tree_id = 'tree-B'; baseline_ref = 'abc' }
            (Get-ContinuousCoReviewFindingIdentity -Finding $finding -RunRecord $run).reviewed_tree_id | Should -Be 'tree-B'
        }
    }

    Context 'Step 2 — artifact lifecycle classes' {
        It 'classifies every on-disk family by its shipped tracked/ephemeral reality' {
            (Get-ContinuousCoReviewArtifactClass '.specrew/review/pending/r1.json').base_class | Should -Be 'transient'
            (Get-ContinuousCoReviewArtifactClass '.specrew/runtime/co-review-navigator-state.json').base_class | Should -Be 'transient'
            (Get-ContinuousCoReviewArtifactClass 'somewhere/.review/changes.diff').base_class | Should -Be 'transient'
            $inline = Get-ContinuousCoReviewArtifactClass '.specrew/review/inline/20260713T000000000-abc/findings-result.json'
            $inline.base_class | Should -Be 'durable'
            $inline.git_tracked | Should -BeTrue
            $inline.supersedable | Should -BeTrue
            (Get-ContinuousCoReviewArtifactClass '.specrew/review/test-evidence/deadbeef.json').base_class | Should -Be 'durable'
            $gate = Get-ContinuousCoReviewArtifactClass '.specrew/review/signoff-gate/latest.json'
            $gate.base_class | Should -Be 'durable'
            $gate.supersedable | Should -BeFalse -Because 'signoff-gate latest.json is overwritten and history is append-only'
            (Get-ContinuousCoReviewArtifactClass 'src/schema.ps1').base_class | Should -Be 'unknown' -Because 'an unclassified path is a contract gap, not silently durable'
        }

        It 'resolves a durable record to one of the five lifecycle dispositions' {
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'transient' | Should -Be 'prunable'
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'durable' -IsLatestForLineage $true | Should -Be 'durable'
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'durable' -IsLatestForLineage $false | Should -Be 'superseded' -Because 'obsolete but retained until a policy decides'
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'durable' -IsLatestForLineage $false -ObsoletePolicy 'archive' | Should -Be 'archived'
            Resolve-ContinuousCoReviewRecordDisposition -BaseClass 'durable' -IsLatestForLineage $false -ObsoletePolicy 'prune' | Should -Be 'prunable'
        }
    }
}
