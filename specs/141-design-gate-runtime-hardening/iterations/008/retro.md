# Retrospective: Iteration 008

**Schema**: v1
**Date**: 2026-06-05

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 5 | 5 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 4 | 4 | 0 |
| T005 | 2 | 2 | 0 |

**Average variance**: 0 on planned tasks (17/17 delivered). No in-iteration rework — the dogfood-found surfacing gap was dispositioned by the maintainer to iteration 009 (Amendment A6), not corrected in-iteration.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis (Option B, workshop-settled). |
| Implementation | 11 | 11 | 0 | Catalog + reader; emit helper + gitignore; intake-reference + Rule 9b. |
| Review | 6 | 6 | 0 | SC-023 tests (4) + the SC-022 visual dogfood (2). |
| Rework | 0 | 0 | 0 | The surfacing gap was carried to i9 (A6), not reworked here. |

## Drift Summary

- Total drift events: 1 (SC-022 surfacing clause unmet at runtime — the conduct under-drove in-band surfacing).
- Resolution: **deferred to iteration 009** (Amendment A6), maintainer-dispositioned; canonical defer entry in `.squad\decisions.md`. See [drift-log.md](drift-log.md).

## What Went Well

- **The deterministic floor held exactly as designed.** Catalog + emit helper + intake-reference are pure, LLM/network-free, and unit-tested (15 assertions); `index.yml` stayed pure; the temp dir is gitignored. The honest behavioral/deterministic split (the i7 pattern) was reused cleanly.
- **The dogfood paid off again — it caught a value-defeating gap a green suite could not.** The SC-023 tests all passed AND the capability demonstrably failed to deliver its value (no diagram seen). That gap lives entirely in the behavioral surface, so only the real run exposed it. Second consecutive iteration where the dogfood was the true gate-completeness check (the Proposal 145 / Shape-8 thesis).
- **Report-falsification worked.** The review downgraded its own "SC-022 met" claim to "carried" against the transcript, rather than asserting success from the unit floor.

## What Didn't Go Well (the load-bearing lesson)

- **A behavioral capability whose conduct merely PERMITS ("MAY") will under-fire — a passing deterministic floor does not make it deliver value.** Rule 9b said the agent *may* render and surface a diagram; the emit helper correctly returns a `file:///` ref; yet the agent wrote the diagram to disk and never surfaced the link, so the maintainer saw nothing and the ui-ux lens produced no visual. The catalog (SC-023) was necessary, not sufficient. For a behavioral capability whose whole point is an *experience* (the user SEES a diagram), the conduct must COMPEL the surfacing (MUST, in-band) and the dogfood — not the floor — is the acceptance gate. This is the direct mandate for Amendment A6's Rule 9b strengthening.
- **Same shape as i7's lesson, one layer out:** i7 = a gate wired to the wrong artifact (silent no-op); i8 = conduct that permits instead of compels (silent under-fire). Both: form present, runtime value absent; both caught only by the dogfood.

## Improvement Actions

1. Owner: Spec Steward/Implementer | Phase: spec/implement | Type: conduct-strength | Expected effect: for a behavioral capability whose value is an experience the human must perceive, phrase the conduct as MUST with an explicit in-band surfacing obligation (a clickable `file:///` link and/or an inline render), never "MAY" — and name the lenses where it is expected. Landed as Amendment A6 / iteration 009.
2. Owner: Reviewer | Phase: review-signoff | Type: process | Expected effect: keep treating the runtime dogfood as the gate-completeness check for any behavioral capability and the completion report as a claim to falsify (145) — confirmed load-bearing two iterations running.
3. Owner: Spec Steward | Phase: spec | Type: scope-discipline | Expected effect: a dogfood that surfaces a broad method gap (here: the workshop runs as a questionnaire, not a co-design) gets explicitly dispositioned by the maintainer (inside-feature amendment vs new proposal) before it is filed — not silently routed to "future work". Done: A6 (inside 141) for collaboration + surfacing; a separate proposal for the two-tier model.

## Calibration Suggestion

- Planned tasks held at 0 variance again; the signal is not estimation but conduct-strength (PERMIT vs COMPEL) for behavioral capabilities. No estimate-model change; carry the conduct-strength rule into A6 planning.

## Notes

- Iteration 8 closes on its delivered + tested capability (the per-lens diagram vocabulary + tiered emit + intake-reference + the SC-023 floor). The review followed Proposal 145 (7-phase + matrix + claim-ledger + design-trace + falsification).
- Forward (iteration 009 / Amendment A6): collaborative design-analysis (co-design the component/responsibility/flow map; offer the design-method discussion) + the Rule 9b visual-surfacing strengthening. The two-tier app-then-feature workshop (dogfood #6) is a separate proposal. See [review.md](review.md) Follow-ups.
