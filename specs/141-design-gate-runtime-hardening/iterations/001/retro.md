# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-02
**Review Verdict**: accepted (after an external-smoke send-back and fixes)
**Smoke Send-Back Fixes Commit**: `eedf1604`
**Review Redo Commit**: `a227e08f`

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 3 | 3 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 3 | 3 | 0 |
| T006 | 2 | 2 | 0 |
| T007 | 2 | 2 | 0 |
| T009 | 2 | 2 | 0 |
| T010 | 1 | 1 | 0 |
| T011 | 1 | 1 | 0 |

**Average variance**: 0 per task on the planned in-scope work. The real overrun was a
post-review **rework cycle** (~5 SP) driven by the external smoke send-back, captured
in Phase Variance below, not per-task estimation error. T008 (lens) deferred-within-feature.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Scope and Option B stable. |
| Discovery/Spikes | 0 | 0 | 0 | No spikes. |
| Implementation | 13 | 13 | 0 | First cycle landed the helpers + tests as planned. |
| Review | 4 | 5 | +1 | Structured review + Proposal 145 addendum; in-repo validator caught structure/arithmetic issues. |
| Rework | 2 | 5 | +3 | External smoke send-back: wire packet/pre-plan into the enforced flow, decision-commit integrity, design-principle handoff, smoke artifact, review redo. |

## Drift Summary

- Total drift events: 1 (form-vs-runtime: helpers implemented but not wired into the enforced flow).
- Resolved via spec update: 1 (FR-020 elevated "preferred" -> required-in-flow; FR-004/FR-008 refinements; recorded as the 2026-06-02 smoke amendment).
- Resolved via revert: 0
- Deferred: 0 in-scope (FR-009/FR-010 lens were pre-deferred, not a drift event)
- Escalated to human decision: 0 (the maintainer's external smoke drove the send-back)

## What Went Well

- The human-felt gate flow genuinely improved: the smoke confirmed clean start-packet paths, design-analysis.md before plan.md, the option-decision stop, the `approved for plan with Option B` mapping, and plan.md only after the decision (smoke observations 1-5 PASS).
- The in-repo validator was a strong structural backstop during the first cycle — it caught a non-canonical hardening-gate concern, a wrong Evidence Basis, an iteration-plan capacity arithmetic mismatch, a non-canonical phase value, and a misplaced deferred-gap-ledger entry, each before review-signoff.
- Feature 141 was dogfooded against its own gate: it now has a real `gates/` packet and its own pre-plan gate passes.
- Feature 140 regression stayed green throughout; the validator-robustness changes broadened acceptance only.

## What Didn't Go Well

- **Form-vs-runtime gap (load-bearing lesson).** The packet renderer/validator/persist and the pre-plan validator were implemented and unit-tested, but they were **callable, optional helpers — not wired into the enforced flow**. The real flow never rendered/persisted a packet (no `gates/` artifact) and never visibly invoked the pre-plan validator. Direct-helper unit tests passed, the in-repo validator passed, and the Proposal 145 addendum I authored classified FR-020 as "implemented" — yet the runtime did not exercise them. Only the **external manual smoke** caught it.
- **Decision-commit metadata drift.** The Human Decision recorded the design-analysis *draft* commit as the decision commit (smoke: `a30fed5` instead of `2c1956a`); Feature 141's own artifact had the same drift. Evidence-integrity drift that self-review missed.
- **Review over-trusted helper-presence + unit tests as proof of runtime behavior.** Same family as prior form-without-runtime-compliance findings — passing structural checks is not proof the behavior is exercised in the real flow.

## Improvement Actions

1. Owner: Implementer | Phase: implement | Type: testing | Expected effect: for runtime-surfacing features, add an end-to-end flow test exercising the full sequence (scaffold -> decision -> render -> validate -> persist -> pre-plan-call -> plan), not only direct helper unit tests, so "unused helper" gaps fail in-repo.
2. Owner: Reviewer | Phase: review | Type: discipline | Expected effect: review must verify each helper is INVOKED by the enforced flow (grep the flow/guidance plus a gate-fails-without-it test), not merely present — an explicit anti-"unused helper" check.
3. Owner: Spec Steward | Phase: future slice | Type: methodology | Expected effect: treat an external manual smoke against the real runtime as a required gate for runtime-surfacing features before claiming accepted, consistent with the "beta validation must test the runtime deliverable" discipline.
4. Owner: Spec Steward | Phase: future iteration | Type: scope | Expected effect: keep FR-009/FR-010 lens activation and the four smoke-bundle defects (FR-011-FR-014) as named later-iteration obligations within Feature 141, not vague future work.

## Calibration Suggestion

- Suggested capacity adjustment: keep 20 story_points (Iteration 1 ran at 18 firm).
- Rationale: the overrun was a methodology gap (runtime wiring + evidence honesty), not throughput. The fix is the review/testing discipline above, not a capacity change.

## Notes

- The strongest single lesson this iteration: a passing in-repo validator + green unit tests + a self-authored Proposal 145 compliance addendum can ALL still miss a runtime-wiring/honesty gap. The external manual smoke was the load-bearing catch.
