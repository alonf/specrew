# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-10

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 2 | 2 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 2 | 2.5 | +0.5 (constrained-YAML round-trip parser was the hardest piece) |
| T005 | 1.5 | 1.5 | 0 |
| T006 | 0.5 | 0.5 | 0 |
| T007 | 0.5 | 0.5 | 0 |
| T008 | 0.75 | 0.75 | 0 |
| T009 | 0.5 | 0.5 | 0 |
| T010 | 1.5 | 1.5 | 0 |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 1 | 1 | 0 |
| T013 | 0.5 | 0.5 | 0 |
| T014 | 0.75 | 0.75 | 0 |
| T015 | 0.5 | 0.5 | 0 |

**Average variance**: ~+0.5 SP on T004; plus ~+0.75 SP of review-phase work not in the original
14.0 (FR-011 plan-block wiring + the Proposal-145 audit fixes: `.specrew-managed` markers + i18n
test). Net actual ≈ 14.75 SP vs 14.0 planned — within noise, single iteration held.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Spec/plan/tasks via the lifecycle boundaries; design settled at design-analysis (Option B). |
| Discovery/Spikes | 0 | 0.25 | +0.25 | An up-front YAML round-trip smoke test (PoC) de-risked the parser before the suite. |
| Implementation | 9.5 | 10 | +0.5 | T004 parser; otherwise as-planned. |
| Review | 4.5 | 5 | +0.5 | The 145 audit found + fixed the FR-011 wiring gap, the untracked markers, and added the i18n test. |
| Rework | TBD | 0.75 | n/a | FR-011 wiring + 145 fixes (found in review, fixed-now — no needs-work loop). |

## Drift Summary

- Total drift events: 3 (D-001 FR-007/156 deferral; D-002 FR-008/162 deferral; D-003 quality-stack mis-inference)
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 2 (D-001, D-002 — forward-compatible shape only; runtime wiring to 156/162)
- Escalated to human decision: 1 (D-003 — maintainer approved the PowerShell quality bar at design-analysis)

## What Went Well

- **PoC-up-front de-risked the riskiest piece.** A throwaway YAML round-trip smoke test ran before the
  Pester suite and confirmed the co-designed emitter+reader (embedded-quote escaping, depth selection,
  research-block) — catching parser risk early instead of in the suite.
- **The design-analysis gate template was honored before plan.** Conforming `design-analysis.md` to the
  validator's exact shape (Option A/B/C + six required fields + Applicable-Lenses Addressed entries +
  the draft/decision commit split) meant the pre-plan gate passed first try.
- **The Proposal-145 self-audit caught real gaps the narrative review missed** — the FR-011
  implemented-but-unwired enforcement, the untracked `.specrew-managed` markers, and the missing i18n
  proof. 145's value (per-dimension enforcement vs single-pass narrative) showed up concretely.
- **Honest form-vs-runtime boundary.** FR-003/006/012 were not over-claimed as unit-tested — they are
  recorded as conduct, proven by the on-host beta dogfood. The Shape-8 negative cases (the gate is
  proven to FAIL for its defect class) were present.

## What Didn't Go Well

- **Edited deploy-output before finding the committed source.** I first hand-edited the four host
  `SKILL.md` copies, then discovered the canonical source is `squad-templates/skills/design-workshop.md`
  (host copies are verbatim deploy-output). Corrected by propagating from the source + mirror, but the
  detour cost time and risked a source/deploy divergence.
- **Left the four `.specrew-managed` markers untracked** when committing the host `SKILL.md` copies —
  only the Proposal-145 Phase-1 audit caught it. Deploy-output must be committed completely.
- **Hardening-gate enum values needed two validator round-trips** (`planning-time-analysis` /
  `pending-post-implementation` / `not-needed`) — the exact tokens were not obvious from the scaffold.
- **The quality-profile resolver mis-inferred a react-spa stack** from the repo `package.json` — needed
  a maintainer-approved override (D-003) to the PowerShell bar.
- **FR-011 was implemented but not wired** to actually block plan — a real "implemented ≠ enforced" gap
  the structured review caught.

## Improvement Actions

1. Owner: Implementer | Phase: implement | Type: process | When changing a managed skill, edit the
   `squad-templates/skills/<name>.md` SOURCE (+ `.specify` mirror) first and propagate to host copies —
   never hand-edit deploy-output as the source.
2. Owner: Implementer | Phase: implement | Type: process | Commit deploy-output COMPLETELY (the
   `.specrew-managed` marker travels with the `SKILL.md`).
3. Owner: Implementer | Phase: implement | Type: implementation | Wire an enforcement function to its
   gate in the SAME task that builds it (an "implemented ≠ enforced" check), so the review does not have
   to discover the gap.
4. Owner: Reviewer | Phase: review | Type: process | Run the Proposal-145 Phase-1 dirty-state
   classification + Shape-8 negative-case check as a standing pre-review-signoff step.

## Calibration Suggestion

- Suggested capacity adjustment: keep the 20 SP iteration cap; 14.0 planned vs ~14.75 actual is a clean
  estimate. No change.
- Rationale: estimates held to within ~5%; the only overrun was the YAML parser (+0.5) and the
  review-phase rework (+0.75), both small and absorbed in one iteration.

## Carried into closeout (maintainer instructions, review-signoff verdict 2026-06-09)

- **FR-003 / FR-006 / FR-012 remain conduct-proof-pending** until the on-host beta dogfood proves them.
- **Do NOT claim stable readiness** before the on-host beta dogfood passes.
- **The PR must contain ONLY feature-176 changes** — exclude the classified pre-existing deploy churn
  and per-boundary session-state churn (Phase-1 classification in `review.md`).
- **Before merge/beta**: push the branch, open the PR, run/observe CI + automated review, and address
  comments.
- **145 findings captured** (maintainer-requested): the untracked `.specrew-managed` markers (fixed),
  the dirty-state classification gap (classified), and the i18n/UTF-8 test addition.

## Notes

- 145's full machine-readable artifacts (`review-report.yml`, `workshop-decision-conformance.yml`, etc.)
  are unshipped (candidate) and therefore not required for this feature; the discipline was applied as
  prose in `review.md` and accepted by the maintainer as sufficient.
- Signals for next iteration: the product-domain phase's runtime quality (capture / reframe / summary)
  is the beta dogfood's job; carry the "implemented ≠ enforced" check forward.
