# Retrospective: Iteration 006

**Schema**: v1
**Date**: 2026-06-04

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 4 | 4 | 0 |
| T003 | 3 | 0 (deferred → iter-7) | -3 |
| T004 | 3 | 3 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 4 | 4 | 0 |
| T007 | 1 | 1 | 0 |

**Average variance**: 0 on the six delivered tasks; T003 (3 SP) deferred (subsumed by the A4 workshop)
→ **16/20 SP delivered**, not 19/20.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis gate (Option B + placement rule). |
| Implementation | 11 | 8 | -3 | Dial→depth + enforced specify gate + FR-026 resolution + FR-029. **T003 flow (3) deferred → iter-7 (the workshop is the decision-point flow).** |
| Review | 7 | 7 | 0 | FR-028 + tests + the human-experience dogfood. |
| Rework | 0 | ~3 | +3 | Unplanned: the expertise-transparency surfacing (maintainer "bring it back") + the A4 workshop re-scope discovery. |

## Drift Summary

- Total drift events: 0 mid-flight. The expertise-transparency surfacing and the A4 re-scope were both
  taken UP FRONT (committed / spec-amended) after the maintainer's run, not as silent in-flight scope.
- Resolved via spec update: 1 (Amendment A4 — workshop re-scope → Iteration 7).
- Deferred forward: **T003 / FR-009 decision-point flow** and the per-lens workshop interaction model
  (both A4/Iteration 7 — the workshop *is* the decision-point flow); two side findings parked
  out-of-feature (Rule 46 packet collapse → handoff track) or for confirmation (expertise line runtime).
- State-truth reconciliation at closeout: T003 had been left `planned` in the iteration ledger while a
  working task-pane marked it done. Caught during the closeout audit and reconciled to `deferred` (not
  silently passed) — delivered capacity corrected 19→16/20. A minor instance of the ledger-vs-working-state
  drift the 005 closeout flagged; the whole-file re-read at closeout caught it.

## What Went Well

- **Iteration 005's improvement action *worked* — the meta-process improved.** 005's retro required a
  human-experience dogfood (not only a mechanics dogfood) for interaction features. The maintainer ran
  exactly that, and it caught the workshop gap the mechanics could never reveal. The process change paid
  off on its very next use.
- **The deterministic engine is solid and reusable.** The dial→depth helper, the enforced
  specify-boundary lens gate (with a committed scripted proof — prompt-only correctly judged
  insufficient), and the FR-026 feature/iteration resolution all landed at estimate, tested, validator
  7/7. They become the engine beneath the Iteration-7 workshop, unchanged.
- **Honest accounting under re-scope (again).** Rather than defend the questionnaire, the response was
  to re-scope to the workshop (A4) and retain the engine — and to flag the expertise line as
  runtime-unverified instead of claiming it from a green unit test.

## What Didn't Go Well (the load-bearing lesson)

- **An interactive questionnaire satisfied the A3 wording but still missed the intent.** A3's FR-025
  said "ask the human, adapt depth, don't auto-resolve" — which a binary yes/no applicability quiz
  satisfies on a literal reading, yet the maintainer's intent was a *facilitated per-lens workshop*
  (infer applicability, then discuss each lens until "move on"). Specifying WHO/WHEN/HOW-flows (A3) was
  necessary but not sufficient; the **depth/conduct** has to be specified too (A4 now does).
- **Gates enforce anti-omission, not anti-shallowness.** The decisive structural finding: the agent
  emitted a structurally valid `lens-applicability.json` that the FR-026 coverage gate **PASSES**, while
  the behavior was exactly what the maintainer rejected. Interaction *quality* is behavioral — no
  deterministic, LLM/network-free gate can catch a shallow-but-well-formed artifact. This is the
  form-vs-runtime pattern (F-054 class) at the interaction layer: the only check for conduct is a
  runtime human-experience dogfood, and Iteration 7 must be reviewed on that basis, not on a green unit
  run.

## Improvement Actions

1. Owner: Spec Steward | Phase: specify/clarify | Type: requirements | Expected effect: when a
   requirement's value is a human *interaction*, the spec MUST specify the **depth/conduct** (workshop
   vs questionnaire; infer-vs-ask; iterate-until-the-human-is-done), not only who answers / when / how
   answers flow — so a shallow literal reading (a yes/no quiz) cannot satisfy it. (A4 applies this to
   FR-025.)
2. Owner: Reviewer | Phase: review-signoff | Type: verification | Expected effect: for behavioral /
   interaction capabilities, do NOT record `accepted` on unit/mechanics evidence; require the runtime
   human-experience dogfood as the acceptance gate, and state explicitly in the review which surfaces
   are behavioral (unit-unprovable) vs deterministic (gate-checkable). (Iteration 6's review does this;
   Iteration 7 inherits it.)
3. Owner: Planner | Phase: planning | Type: scope | Expected effect: pair every deterministic gate that
   guards an interaction feature with an explicit note of its boundary (anti-omission, not
   anti-shallowness) so the gate is not mistaken for a quality guarantee — and budget the runtime
   dogfood as the real acceptance evidence, not a formality.

## Calibration Suggestion

- Planned-task estimates held at 0 variance (consistent with the calibrated ~0-delta velocity). The real
  signal is again the +3 unplanned (transparency surfacing + A4 re-scope) — a requirements-intent
  refinement, not an estimation miss. No estimate-model change.

## Notes

- Iteration 6 closes on its delivered scope (the deterministic interactive intake + enforcement +
  transparency surfacing). The per-lens workshop is Iteration 7 (Amendment A4, maintainer-directed).
- Carried forward: the expertise-transparency line needs a fresh-start runtime confirmation; the Rule 46
  packet-collapse is filed to the handoff-quality track (out of Feature 141).
