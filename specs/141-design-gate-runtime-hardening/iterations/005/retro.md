# Retrospective: Iteration 005

**Schema**: v1
**Date**: 2026-06-04

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 3 | 3 | 0 |
| T003 | 4 | 4 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 4 | 4 | 0 |
| T006 | 2 | 2 | 0 |

**Average variance**: +/- 0 on planned tasks.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis gate (Option B). |
| Implementation | 11 | 11 | 0 | Extractor + enriched render + FR-026 gate + template nudge. |
| Review | 6 | 6 | 0 | Tests + docs + dogfood + discriminator. |
| Rework | 0 | ~3 | +3 | Unplanned: the Proposal 145 Phase 5 grandfather-bypass fix (explicit marker), the main-merge integration, and the A3 re-scope discovery. |

## Drift Summary

- Total drift events: 0 mid-flight (the spec was amended UP FRONT — A2 — then re-scoped UP FRONT after the manual test — A3).
- Resolved via spec update: 1 (Amendment A3 — re-scope to Iteration 6).
- Deferred: the placement/interaction/sequencing re-scope → Iteration 6 (human-directed, A3).

## What Went Well

- **The FR-026 mechanics are sound.** Selector + decision-point extractor + enriched render + the coverage gate are tested (38/38), deterministic, grandfather-safe (after the Phase-5 fix), and reused as Iteration 6's engine.
- **The Phase-5 send-back caught a real gate-completeness hole** (grandfather-by-absence = silent bypass) before it shipped, and the fix is verified (bypass closed 4/4).
- **Honest accounting under re-scope.** When the maintainer's manual test showed the feature missed its intent, the response was to re-scope correctly (A3) and retain the engine — not to defend the placement or discard the work.

## What Didn't Go Well (the load-bearing lesson)

- **The Crew dogfood validated the MECHANICS, not the feature's INTENT.** Iteration 4 and 5 dogfooded the selector/render/gate on their own artifacts and the discriminator passed — but the feature's *core intent* (an interactive, expertise-adapted lens intake run BEFORE clarify that shapes the lifecycle) was never exercised, because the questionnaire was auto-answered at the design-analysis stop. The gap was invisible to the Crew's dogfood and was caught only by the maintainer's **manual end-to-end greenfield run**.
- **Form-without-value, one layer up.** This is the same class as the Iteration-4 "list of names" miss and the broader runtime-vs-form pattern: a green dogfood of the implementation is not evidence the *human experience* or the *requirement's intent* is met. Dogfooding the mechanics ≠ validating the feature.

## Improvement Actions

1. Owner: Reviewer | Phase: review-signoff | Type: verification | Expected effect: for any feature whose value is a **human interaction or lifecycle placement**, the review-signoff dogfood MUST include a human-experience run (the actual interactive flow, at the actual lifecycle position), not only a mechanics dogfood on the artifact. A passing mechanics dogfood is necessary, not sufficient.
2. Owner: Spec Steward | Phase: specify/clarify | Type: requirements | Expected effect: when a requirement's intent is "interact with the human" (e.g. a questionnaire), the spec MUST state WHO answers, WHEN in the lifecycle, and HOW the answers flow downstream — so "auto-answered, late, isolated" cannot satisfy it on a literal reading (the A1/A2 FR-025 wording allowed exactly that).

## Calibration Suggestion

- Planned-task estimates held at 0 variance; the real signal is the +3 unplanned rework from the Phase-5 fix + the A3 re-scope. The re-scope was a requirements-intent miss, not an estimation miss.

## Notes

- Iteration 5 closes on its delivered scope (the FR-009/FR-026 mechanics). The interactive, pre-clarify intake re-scope is Iteration 6 (Amendment A3, maintainer-directed).
- Two cross-feature flow bugs the manual test exposed (downstream `Specrew.psd1` FileList-sort warning; handoff-validator `token/token` bare-path false-positive) are bundled into the Iteration 6 scope (FR-029 + FR-028).
