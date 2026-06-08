# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-08

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 2 | 2 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | Spec + design-analysis (Option B) + tasks landed cleanly. |
| Discovery/Spikes | 0 | 0 | 0 | No spike; design resolved at the workshop. |
| Implementation | 12 | 12 | 0 | Per-task estimates exact; IDesign seams made each component small. |
| Review | 2 | 3 | +1 | Proposal-145 review + the defer-entry validator schema cost an extra point. |
| Rework | 2 | 1 | -1 | Only the 3 PSScriptAnalyzer fixes; no needs-work loops. |

## Drift Summary

- Total drift events: 1
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 1 (D-001 downstream extension-tree deploy; self-host wiring resolved + proven)
- Escalated to human decision: 0

## What Went Well

- **IDesign volatility-based decomposition paid off immediately.** Keeping
  ClassificationEngine/DirectiveEngine pure made every bootstrap-mode path a fast in-memory
  unit test; estimates landed at 0 variance across all 7 tasks.
- **The live wiring closed cleanly via the F-171 provider-row model.** A dispatcher smoke
  proved the B2 bootstrap fires for real on SessionStart (silent on compact), not just in unit
  tests - 62 assertions + a real integration smoke.
- **Proposal-145 earned its keep.** The 7-phase structured review found 3 real PSScriptAnalyzer
  issues and the coverage-evidence test-drift that a single-pass narrative review would have
  signed off without noticing.

## What Didn't Go Well

- **Test-convention discovery was late.** The local Pester is a stale 3.4.0 and the project's
  `.Tests.ps1` files are actually plain-PowerShell assert scripts, not Pester - found only after
  writing 3 Pester suites that errored. Cost a rewrite.
- **The reviewer-artifact scaffolder seeded the wrong test evidence.** `coverage-evidence.md`'s
  auto-populated `Tests Run` listed only framework tests, not the deliverable suites (the F-050
  drift class). Caught by the 145 Phase-5 check, but the scaffolder default is a trap.
- **The gap-ledger defer-entry validator schema was opaque.** It required `Type: defer`, an
  exact `Affected Iteration` path, AND each entry under its own dated `###` heading (the ledger
  parser only starts an entry on a dated heading). Cost several validator-fix iterations to learn.
- **Stale iteration baseline in state.md** (pointed at the clarify commit) triggered a
  form-vs-meaning warning.

## Improvement Actions

1. Owner: Implementer | Phase: next iteration | Type: process | Detect the project's test
   convention (Pester vs plain-script) before authoring any test.
2. Owner: Reviewer | Phase: review-signoff | Type: process | The coverage-evidence scaffolder
   should seed the deliverable suites, not only framework `test_commands` - scaffolder-fix
   proposal candidate.
3. Owner: Planner | Phase: implement-start | Type: process | Refresh state.md baseline to the
   before-implement commit when execution starts, so the form-vs-meaning check is accurate.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 12 SP/iteration baseline (0 variance this iteration).
- Rationale: every task estimate was exact; the 3-iteration split (12/11/12) was correctly sized
  and no iteration came near the 20 SP cap.

## Signals For Next Iteration (002)

- Iteration 002 (handover round-trip + welcome-back + launcher dedupe) is additive over the
  existing seams: extend ValidationEngine + ClassificationEngine with the handover-first stage,
  add SessionEndHandoverManager + LauncherIntegration. The IDesign boundaries are already in place.
- Carry the 4 deferred items into iteration 003 (downstream deploy, merged-branch-deleted
  detection, FR-005 per-host, FR-014 sync-side).

## Notes

- Real lessons recorded; no TBD placeholders remain.
