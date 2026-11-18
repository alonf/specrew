# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-11-11
**Overall Verdict**: accepted: two rounds, three findings, all three fixed failing-test first; stopped by the
maintainer's typed `stop the review here`; signed off under the maintainer's partial-coverage approval because round
2's fix (`d5d1ae06`) landed after round 2

## Independent review

Campaign `cmp-205-workshop-lens-order-i001`, reviewer codex, code writer Claude. Each round was started by the
maintainer's own typed `approved for review round`.

| Round | Run | Target | Findings | Outcome |
| --- | --- | --- | --- | --- |
| (none) | `run-20261110-221211306-a1cb90e2` | `5e76d374` | none published | Preflight failed: it ran feature 202's verification plan (DRIFT-008). Not a round; the plan was re-pointed to 205 in `d5037d6b` |
| 1 | `run-20261110-235625865-4ea53fb9` | `0fddf1cc` | 2 major (reviewer), shown as minor by the engine | Both fixed: `3ed79b33` and `c840aaed` |
| 2 | `run-20261111-012900593-ccd284fa` | `bf289776` | 1 minor | Fixed in `d5d1ae06` |

Round 1's two findings were reported as major by codex. The engine demoted both to minor for lack of a literal
failure-scenario clause (B5F-017). The maintainer ruled they count at the reviewer's severity.

- **finding-240eb6ececd80a71** (major, engine minor), `tests/unit/lens-order-parity.tests.ps1`: the full-list check
  extracted members with a pattern built from index.yml, so an extra or retired lens in a full list was invisible.
  Fix `3ed79b33`: each full surface is parsed independently of the catalog, then compared for membership and order.
- **finding-bec438b62d3ba0ef** (major, engine minor), `scripts/internal/lens-applicability.ps1`: the applicability
  selector put every always-on lens before every yes-gated lens, a second order. Fix `c840aaed`: computed selections
  and the rendered section follow index.yml; the parity test now checks the computed orders too.
- **finding-0ab5fe9975dc3b84** (minor), `tests/unit/lens-order-parity.tests.ps1`: a selector exception in a computed
  case ended the run before any collected mismatch was printed. Fix `d5d1ae06`: the exception becomes a mismatch record
  and the run continues; a new self-test removes a lens from the catalog with the computed check on.

Each fix was written failing-test first; the red and green runs are in
`specs/205-workshop-lens-order/iterations/001/quality/quality-evidence.md`. All three workflows passed on `d5d1ae06`.

## How the Review Stopped

- The maintainer typed `stop the review here` after round 2. The engine refused at first because the tree had moved
  since round 2 (`latest-result-not-current`): `d5d1ae06`, the round 2 fix, had landed after it.
- The maintainer then approved partial coverage: `approved for partial review signoff - the change after round 2 is
  the fix for that round's finding, in one test file, read by my reviewer, with all three workflows green on
  d5d1ae06`.
- The final check ran on the current files and sign-off completed (request `override-0154fc5b01bd0d281913edfa`, tree
  `c515195b`). The record is `.specrew/review/signoff-gate/latest.json`, committed in `eec3745b`.
- At the pause the engine saved the remaining findings as follow-ups: disposition
  `disposition-0a33382d2c827f0de53c` (`accept-current`, target `bf289776`), which is round 2's finding.

## What This Sign-off Claims, and What It Does Not

- **It claims** every finding from both rounds is fixed behind a test that failed first.
- **It claims** the 205 verification plan passes and all three workflows passed on `d5d1ae06`.
- **It does not claim** a round read `d5d1ae06`. The maintainer's reviewer read it; the partial-coverage approval
  covers it.
- **It does not claim** proposal 220's iterations 2 and 3. This iteration delivers the single order, the space tags
  and the parity test only.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001, FR-005, FR-015, FR-018, FR-019, SC-003 | pass | `lens-order-parity`; extended by all three review fixes. |
| T002 | FR-001, FR-019 | pass | The parity self-tests, including multi-mismatch reporting. |
| T003 | SC-001 | pass | Red-first run recorded: 72 mismatches on the unchanged tree. |
| T017 | FR-021 | pass | Baseline of every existing workshop test before the change. |
| T004 | FR-016, FR-013 | pass | `workshop-agenda-confirmation`: refusal, in-order, old-order resume. |
| T005 | FR-015 | pass | index.yml in problem-first order with a space per lens. |
| T006 | FR-005, FR-004, FR-015, FR-020 | pass | 11 lens files tagged; gap list written. |
| T007 | FR-016, FR-013 | pass | The agenda writer refuses an out-of-order agenda; a stored agenda keeps its order. |
| T008 | FR-017, FR-018 | pass | Skill list, index.yml-wins sentence, problem-first conduct. |
| T009 | FR-017, FR-001 | pass | Methodology lists rewritten. |
| T010 | FR-001 | pass | before-specify and catalog README lists. |
| T011 | FR-001, FR-019 | pass | Deployed copies refreshed through the two deploy scripts. |
| T012 | SC-001, SC-002, SC-004 | pass | Parity 0 mismatches; SC-002 extractor counts match for all 11 lenses. |
| T013 | FR-021 | pass | 31 existing workshop tests pass; one expectation updated for the new order. |
| T014 | FR-021, SC-005 | pass | 10 named steps in `specrew-ci.yml`. |
| T015 | FR-022 | pass | Proposal 220 `status: active`, `shipped-as: feature-205`. |
| T016 | SC-005 | pass | Gates exit 0 before every push, except one maintainer-approved exception at review-signoff (DRIFT-012, DRIFT-013); all three workflows green on `d5d1ae06`. |

## Gap Ledger

- **finding-0ab5fe9975dc3b84**: fixed-now in `d5d1ae06`; saved by the engine as a follow-up; no round read the fix.

## Open Outside This Review

These are drift-log items, not review findings:

- **H-001**: hand-over to feature 203: the review preflight can run suites that write the real home hook files
  (DRIFT-008, DRIFT-009).
- **H-002 to H-004**: hand-overs to feature 203 about this record itself: the derived independence block cannot match
  both locally and in CI (DRIFT-012); the sync needs this record with the pre-review phase lines, which the governance
  check refuses (DRIFT-013); the deployed-file check names 5 of 18 drifted files (DRIFT-014).
- **H-005 and H-006**: a session resume rewrote state.md (DRIFT-017); review-runtime tests that depend on runner speed
  (DRIFT-018).
- **History of this record**: first committed in `cf173030`, removed by the revert `e2748a53` on a wrong reading of the
  sync, and restored with the phase lines still pre-review so the review-signoff sync can bind to it (DRIFT-013). That
  commit is knowingly red in Specrew CI Lint, as feature 202 iteration 003's `a7e2b74c` was.
- **Class closures**: DRIFT-001 and DRIFT-004 to DRIFT-018 have their class closure open.

## Independence

This record carries no derived independence block. The block is computed from the review store, which exists only on
the machine that ran the review, so the local check and CI derive different text (DRIFT-012). The maintainer approved
leaving it out. In plain words, this record's independence rests on:

- **The two Codex rounds, for the trees they read.** Round 1 read `0fddf1cc` and round 2 read `bf289776`. They are
  evidence about those trees, not about the code as it stands.
- **The maintainer's partial-coverage approval, for the change after round 2.** `d5d1ae06`, the fix for round 2's
  finding, landed after round 2 and no campaign run read it. The maintainer's own reviewer read it, and the approval
  covers it.
- **Not on the record itself.** This record was written by the implementing session (Claude, the code writer), not by
  the reviewer, so it adds no independence of its own.
