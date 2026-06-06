# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 2 | 1.5 | -0.5 |
| T007 | 0.5 | 0.5 | 0 |
| T008 | 1 | 1 | 0 |
| T009 | 0.5 | 1 | +0.5 |

**Average variance**: ~0 (8 SP estimated, ~8 SP actual; T006 came in under
because the fix shape was fully determined by the verdict evidence; T009 ran
over by the review-signoff send-back round)

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 SP | 1 SP | 0 | Spec/plan/tasks/before-implement all single-pass; three boundary approvals carried instructions, none required rework. |
| Discovery/Spikes | 3 SP | 3 SP | 0 | Harness + reachability were the discovery; the F-160-aware re-framing at clarify avoided duplicating shipped work. |
| Implementation | 2.5 SP | 2 SP | -0.5 | Fix shape fell directly out of the evidence (signature of the real historical artifacts). |
| Review | 1.5 SP | 2 SP | +0.5 | One send-back: quality-evidence.md lagged the post-fix state; reconciliation + revalidation cost the extra half point. |
| Rework | 0 SP | 0.5 SP | +0.5 | The send-back was evidence-truth rework, not code rework. |

## Drift Summary

- Total drift events: 2
- Resolved via spec update: 1 (CI workflow surface, plan-level)
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 1 (S7-not-S4 promotion target — stricter fix shape)

## What Went Well

- Review verdict recorded as **accepted** before retrospective started.
- **Repro-first discipline paid for itself**: the deploy-level harness flipped
  the investigation from "plausible hypothesis" to "reachable bug with a real
  artifact" in one task, and the verdict gate kept the fix budget locked until
  the human saw the evidence — exactly the no-speculative-fix contract from
  the tasks-gate instructions.
- **Reachability analysis sharpened the proposal's guess**: the reachable
  branch turned out to be the generic-kind equality fallback, not the
  front-matter heuristic the proposal suspected — and the per-kind asymmetry
  (generic frozen, slash recovered) made the stricter fix shape an informed
  human choice instead of a default.
- **F-160 layering worked**: building on the shipped classifier fix +
  fixture (regression guard) meant zero duplicated coverage and zero
  regressions across both fixtures.
- The no-loss invariant (S2/S8 byte-preserved) held in every state without a
  single counter-instance.

## What Didn't Go Well

- **Evidence files lagged state transitions**: quality-evidence.md kept
  verdict-era wording ("planning", "planned", "S7 frozen", "fix pending")
  after the fix landed — caught by the human at review-signoff, costing a
  send-back round. Same failure class as the F-051 stale-phrase lessons:
  artifacts that mirror other artifacts must be re-swept after every state
  flip, not only the primary record.
- **`scaffold-reviewer-artifacts -Force` hung** (killed after ~12 minutes, no
  partial writes); digest fields had to be hand-trued. Tooling signal worth a
  look — likely its reviewer test_commands re-run in a non-interactive child.
- **`git add -A` swept in classified-untracked generated outputs**
  (`.cursor/rules`, version-check cache), requiring an untrack commit. Stage
  explicitly when a hygiene classification is in force.
- `scaffold-iteration-artifacts` still skips the `quality/` tree (known
  gotcha) — hardening gate + quality stubs were hand-authored.

## Improvement Actions

1. Owner: Implementer | Phase: next iteration | Type: process | Expected
   effect: after any state-flipping event (fix lands, verdict changes), grep
   the iteration tree for the stale-phrase CLASS (`pending|planned|planning|
   frozen`) before the boundary commit — kills the send-back class caught here.
2. Owner: Spec Steward | Phase: next planning | Type: tooling follow-up |
   Expected effect: file the `scaffold-reviewer-artifacts -Force` hang and the
   `scaffold-iteration-artifacts` quality-tree skip as a tooling chore
   candidate (~1-2 SP) so downstream iterations stop hand-authoring gates.
3. Owner: Implementer | Phase: next iteration | Type: process | Expected
   effect: never `git add -A` while a hygiene classification is active; stage
   paths explicitly.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline -> keep 20 SP cap; keep
  ~10.5 SP/day velocity anchor.
- Rationale: 8 SP declared vs ~8 SP actual in a single day-session; variance
  came from evidence-truth rework, not estimation error. The conditional-fix
  budget pattern (declared but verdict-gated) priced the uncertainty correctly
  and is worth reusing for investigation slices.

## Signals for Next Iteration

- The S4/S4g residual (F161-DEFER-001) is closed-as-deferred; reopen only if
  a future Specrew version ever produces marker-less front-matter skill dirs
  in a legacy root.
- Follow-up candidates surfaced but out of scope: gitignore entries for
  `.cursor/rules` + `.specrew/version-check-cache.json`; the two scaffolder
  tooling issues above.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
