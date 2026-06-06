# Retrospective: Iteration 011

**Schema**: v1
**Date**: 2026-06-05

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 (SC-026 floor + wiring) | 4 | 4 | 0 |
| T002 (FR-038 invariant) | 3 | 3 | 0 |
| T003 (squad.agent.md rule) | 3 | 3 | 0 |
| T004 (FR-040 intake UX) | 3 | 3 | 0 |
| T005 (tests) | 3 | 3 | 0 |
| T007 (render conduct, folded in) | 2 | ~5 | +3 |

**Average variance**: 0 on the A7 deterministic tasks (16/16). The +3 is all **T007**: the render-before-the-menu conduct was revised ~5× (diagram-scoped → generalized-to-the-mechanism → component-map template → agenda template) chasing a Claude failure that **conduct cannot fix**. That churn is the signal, not a bad estimate — see below.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Design-analysis (Option B, decision `3ea67b32`). |
| Implementation | 15 | ~18 | +3 | A7 deterministic on estimate; T007 render conduct over by +3 (the wasted instruction iterations). |
| Review | 5 | ~3 | -2 | The behavioral acceptance (T006) is deferred to i12, not run here. |

## Drift Summary

- **Lifecycle-metadata drift (fixed at closeout):** `state.md` read "build starting, T001 in progress" while `tasks-progress.yml` + git log showed T001–T005 + T007 committed and done. The 145 "report is an artifact under test" stance caught it — verifying state against artifacts, not the session summary. Corrected at closeout.
- No spec drift: the render-ceiling finding is recorded as Amendment A8, not left as silent implementation divergence.

## What Went Well

- **The deterministic A7 work landed clean.** The SC-026 provenance floor (grandfather-safe, wiring-tested through the real gate entry), the FR-038 integrity invariant + count self-check, the FR-040 intake UX, and — the root-cause lever — the `squad.agent.md` stopping-completeness rule in the governance template. 16/16 on estimate, four suites green.
- **The refocus + 145 discipline caught my own drift.** Before re-scoping I re-grounded (146 corpus + 145), then verified i11's real state against `tasks-progress.yml` + git log rather than trusting the stale `state.md` / the summary — surfacing the metadata drift and confirming exactly what was delivered before claiming anything.

## What Didn't Go Well (the load-bearing lesson)

- **Conduct cannot make Claude render before a menu — proven twice, after ~five instruction iterations.** T007 tried prose ("render before you ask"), then named the exact anti-pattern, then shipped fill-in templates (component map, then agenda). testLenses8 and testLenses11 both failed the same way on Claude: the agent put the thing-being-confirmed *into* the `AskUserQuestion` question/option fields ("approve 13 components", "8 lenses shown") instead of rendering it first. **Root cause (advisor-confirmed): the AskUserQuestion tool-gravity** — the call's fields are a content sink, and every conduct rule shares the shape "render somewhere other than the call," which is exactly what the gravity defeats. So prose and template fail for the *same* reason; a 7th instruction won't help. It holds on Copilot + Antigravity (they render in prose first), so the behavior is **host-dependent**.
- **The meta-lesson:** for host-robust in-band rendering, **conduct is not the lever — a non-discretionary mechanism is** (the render must be the output of an action, not a thing the agent chooses to do). That is Amendment A8 / FR-041 / iteration 012. The advisor's earlier warning applies in hindsight: when a conduct rule fails a dogfood, escalate the *mechanism*, don't discover the resistance an Nth time by writing instruction N+1.
- **Only the dogfood surfaced it.** The SC-026 unit floor + the T007 presence-locks were all green; presence ≠ obedience. The cross-host dogfood is the only gate that sees conversation flow.

## Improvement Actions

1. Owner: Implementer / Spec Steward | Phase: implement | Type: process | Expected effect: **a conduct rule that fails a behavioral dogfood twice is escalated to a mechanism, not re-worded.** Two failed dogfood rounds on the same conduct = stop writing instructions; change the mechanism (here: non-discretionary presentation). Codified as Amendment A8.
2. Owner: maintainer | Phase: review-signoff | Type: process | Expected effect: **the consolidated all-confirm-points cross-host re-dogfood (anti-whack-a-mole)** is the gate — stress every confirm point (agenda, per-lens move-on, component map, options, verdict) in ONE run per host, so a list-vs-diagram scoping miss (the testLenses8→11 whack-a-mole) is caught in one pass.
3. Owner: Implementer | Phase: iteration 012 | Type: fix | Expected effect: the **mechanical render** (FR-041) — the lens catalog/agenda as a mechanical opening surface + each lens opening with a rendered presentation + an open question (never a menu as the first move); the structured menu retained, only after content is on screen.

## Calibration Suggestion

- The A7 deterministic tasks held 0 variance; the +3 is T007's instruction churn, whose cause is diagnostic (conduct can't fix the tool-gravity), not an estimation error. No estimate-model change; the fix is the escalate-to-mechanism rule (action 1).

## Notes

- Iteration 11 closes on its delivered + tested **deterministic** scope (the A7 confirmation-integrity floor + conduct + the root-cause `squad.agent.md` lever). The **behavioral** acceptance — SC-027 (no synthetic agreement on Squad) + SC-028 (confirm-point content rendered before its menu, cross-host) — consolidates into **iteration 012's** single cross-host re-dogfood, after the A8 mechanical render lands. The dogfood did its job: it found the gap conduct could not close.
- Forward: **iteration 012** — Amendment A8 / FR-041, the non-discretionary confirm-point presentation. Design-analysis next.
