# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 7/26 story_points
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
| T007 | Boundary ratchet + shared primitive (sync + validator call sites) | FR-001, FR-002, FR-003, FR-006 | US1 | 1.5 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/**, scripts/internal/sync-boundary-state.ps1, tests/** | done | — | — | — |
| T008 | Reconciliation flows (retroactive entries; revert behind confirm; honest-limit teaching) | FR-005, FR-007 | US1 | 1.5 | Implementer | scripts/internal/sync-boundary-state.ps1, extensions/specrew-speckit/refocus/**, tests/** | done | — | — | — |
| T009 | Resume/start awaiting-verdict re-confirm surface | FR-004 | US1 | 0.5 | Implementer | scripts/internal/**, extensions/specrew-speckit/scripts/**, tests/** | done | — | — | — |
| T010 | Tracker honesty check + announced gate-level bypass (paired tests) | FR-020 | US3 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/**, tests/** | planned | — | — | — |
| T011 | Catalog budget rows + BudgetResolver chain + W14 warning + timeout teaching (amended UX) | FR-021, FR-022 | US3 | 1.0 | Implementer | scripts/internal/continuous-co-review/reviewer-host-catalog.ps1, scripts/internal/continuous-co-review/**, tests/** | planned | — | — | — |
| T012 | Live-door independence defaulting + provenance | FR-023 | US3 | 0.5 | Implementer | scripts/internal/continuous-co-review/**, scripts/specrew-review.ps1, tests/** | planned | — | — | — |

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
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: Latest reviewer hotspots: specs/198-beta2-hardening/iterations/001/design-analysis.md (307 changed lines); specs/198-beta2-hardening/plan.md (254 changed lines)
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001..FR-007, FR-020, FR-021, FR-022, FR-023
- User stories represented in current scope: US1 (one approval advances one boundary), US3 (review rounds spend human budget honestly)
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
