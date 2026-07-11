# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 9.25/26 story_points
**Started**: 2026-07-11
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | One shared deterministic authorization delta primitive, no host-hook dependency | US1 |
| FR-002 | Sync refuses a second unapproved advance; loud, names boundary + both doors | US1 |
| FR-003 | Validator FAIL finding on unreconciled skip | US1 |
| FR-004 | Resume/start awaiting-verdict re-confirm surface | US1 |
| FR-005 | Reconciliation: retroactive approval recorded distinctly; revert behind explicit confirm | US1 |
| FR-006 | Hooks stay surfacing-only for enforcement | US1 |
| FR-007 | The honest one-boundary limit documented and taught | US1 |
| FR-020 | Fail-closed tracker honesty check; announced gate-level bypass (mechanism b) | US3 |
| FR-021 | Downgrade warning at resolution time, keyed off the RESOLVED value | US3 |
| FR-022 | Catalog default_timeout_seconds rows + resolution chain + 600 floor + teaching per amended UX | US3 |
| FR-023 | Live-door env cascade + independence_source provenance | US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T007 | Boundary ratchet + shared primitive (sync + validator call sites) | FR-001, FR-002, FR-003, FR-006 | US1 | 1.5 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/**, scripts/internal/sync-boundary-state.ps1, tests/** | done | — | 2 | pass |
| T008 | Reconciliation flows (retroactive entries; revert behind confirm; honest-limit teaching) | FR-005, FR-007 | US1 | 1.5 | Implementer | scripts/internal/sync-boundary-state.ps1, extensions/specrew-speckit/refocus/**, tests/** | done | — | 1 | pass |
| T009 | Resume/start awaiting-verdict re-confirm surface | FR-004 | US1 | 0.5 | Implementer | scripts/internal/**, extensions/specrew-speckit/scripts/**, tests/** | done | — | 1.5 | pass |
| T010 | Tracker honesty check + announced gate-level bypass (paired tests) | FR-020 | US3 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/**, tests/** | done | — | 2 | pass |
| T011 | Catalog budget rows + BudgetResolver chain + W14 warning + timeout teaching (amended UX) | FR-021, FR-022 | US3 | 1.0 | Implementer | scripts/internal/continuous-co-review/reviewer-host-catalog.ps1, scripts/internal/continuous-co-review/**, tests/** | done | — | 1 | pass |
| T012 | Live-door independence defaulting + provenance | FR-023 | US3 | 0.5 | Implementer | scripts/internal/continuous-co-review/**, scripts/specrew-review.ps1, tests/** | done | — | 0.75 | pass |
| T019a | Stale-verdict surfacing (pulled forward, maintainer-approved) | FR-017 | US3 | 1.0 | Implementer | scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 | done | — | 1 | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 26 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 26 story_points (capacity 26 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Backend/service-oriented signals dominate the scoped requirements.
- Task dependency graph (as executed): T007 first (the shared primitive), then T008/T009 building on its plumbing; T010, T011, T012 independent of the US1 chain; T019a independent (navigator surface). All serial under one Implementer — no same-specialty parallelism was proposed or needed.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: Latest reviewer hotspots: specs/198-beta2-hardening/iterations/001/design-analysis.md (307 changed lines); specs/198-beta2-hardening/plan.md (254 changed lines)
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | light | Actual: light. Design-analysis + iteration plan passed their gates first-try (001 form lessons held). |
| Discovery/Spikes | 0 | Actual: 0. No spikes planned; the cycle-reset discovery emerged inside T009 (Gap Ledger, review.md). |
| Implementation | 6.5 | Actual: 7.25. Spread across T007/T009/T012; T009 carried the cycle-reset scope growth. |
| Review | 1.0 | Actual: 1.75. One codex flake, one ceiling latch + more-time, one evidence-staleness re-round that caught a real bug. |
| Rework | 0 | Actual: 0.25. Test 5 hermeticity fix, same hour as its catch (run 485cbb03). |

## Traceability Summary

- Requirement scope delivered: FR-001..FR-007, FR-020, FR-021, FR-022, FR-023, plus FR-017's navigator-surfacing half (T019a, maintainer-approved pull-forward)
- User stories represented: US1 (one approval advances one boundary), US3 (review rounds spend human budget honestly)
- Detailed planning completed before execution: task table decomposed (7 tasks, 8.0 SP planned), capacity and traceability verified at the tasks/before-implement gates.
- Overcommit outcome: 8.0 planned SP against the 26 SP cap — no deferrals required; final consumed 9.25 SP, within cap.

## Notes

- Iteration closed through review-signoff: review.md accepted (7/7 pass), signoff evidence chain 237849f1 -> 485cbb03 (real catch) -> 8bf11302 (clean, promoted); variance and lessons in retro.md.
- T019a entered this iteration by maintainer decision (stale-verdict surfacing pulled forward from T019).
- These closing sections (Phase Baseline, Concurrency Rationale, Traceability, Notes) were replaced with completion truth at retro after a maintainer send-back caught the scaffold text still standing — the same scaffold-staleness class this iteration's improvement action 3 now targets with a deterministic check.
