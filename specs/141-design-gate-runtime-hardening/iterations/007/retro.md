# Retrospective: Iteration 007

**Schema**: v1
**Date**: 2026-06-04

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 4 | 4 | 0 |
| T002 | 4 | 4 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 4 | 4 | 0 |
| T006 | 2 | 2 | 0 |

**Average variance**: 0 on planned tasks (19/19 delivered) + ~2 SP unplanned rework (the SC-021 re-home fix the dogfood forced).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis (Option B + 5 instructions). |
| Implementation | 13 | 13 | 0 | Agenda gen + schema/gate + conduct rule + flow. |
| Review | 6 | 6 | 0 | Deterministic-floor tests + the runtime dogfood. |
| Rework | 0 | ~2 | +2 | Unplanned: the SC-021 specify-boundary re-home (`a0b78cbc`) the dogfood forced. |

## Drift Summary

- Total drift events: 1 (the SC-021 enforcement-point fix), resolved this iteration (not deferred).
- Resolution: implementation-corrected (re-homed the floor to the specify boundary + a real-layout test).

## What Went Well

- **The runtime dogfood paid off twice.** It validated the workshop conduct (SC-020) — the core, behavioral value the maintainer asked for — AND caught the SC-021 floor not firing. A green unit test would never have surfaced it; only the real feature-vs-iteration artifact layout did.
- **Report-falsification (Proposal 145) worked in practice.** The pre-dogfood report would have claimed "SC-021 enforced." Treating that as a claim-under-test (the 145 discipline) is exactly what flipped it to a fix.
- **Honest behavioral/deterministic split held.** The conduct shipped as a prompt rule with the dogfood as its acceptance gate; the deterministic floor (generator/schema/gate) was unit-tested. Neither over-claimed.

## What Didn't Go Well (the load-bearing lesson)

- **A unit test that models a convenient layout, not the real one, gives false assurance.** The SC-021 test put `workshop_intake` at the iteration directory; the real workshop artifact is feature-level (the iteration-level is the design-analysis questionnaire). So the test passed while the gate, in the real flow, resolved the wrong artifact and no-opped. This is the **Shape-8 gate-completeness pattern** (does the gate cover what its spec claims?) — and the gate was *for* enforcing the workshop floor, which it silently wasn't. The dogfood, not the test, was the gate-completeness check.

## Improvement Actions

1. Owner: Reviewer/Implementer | Phase: implement/test | Type: verification | Expected effect: a test for a gate's WIRING must model the **real artifact layout** the gate runs against (here: feature-level workshop vs iteration-level design-analysis), not a single convenient directory — otherwise it asserts the function in isolation while the integration silently no-ops. The new specify-gate test now models the real split.
2. Owner: Reviewer | Phase: review-signoff | Type: process | Expected effect: for any deterministic gate added to guard a behavioral capability, the review MUST run the **runtime dogfood** as the gate-completeness check (a green unit suite is necessary, not sufficient) — and treat the completion report as a claim to falsify (Proposal 145), not testimony.

## Calibration Suggestion

- Planned tasks held at 0 variance; the signal is the +2 unplanned rework from the dogfood-found SC-021 gap — an integration/wiring miss, not an estimation miss. No estimate-model change.

## Notes

- Iteration 7 closes on its delivered + validated scope (the per-lens workshop conduct + the deterministic floor). The review followed Proposal 145 (7-phase + matrix + claim-ledger + design-trace + falsification).
- Forward (not i7 gaps): the workshop visuals → Amendment A5 / Iteration 8; FR-026 emphasis tolerance + installed-vs-dev module resolution → small follow-ups. See review.md Follow-ups.
