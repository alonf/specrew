# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-05-31
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
| FR-001 | Specrew MUST surface `/speckit.checklist` as a first-class lifecycle-adjacent command before planning for substantive feature work. | — |
| FR-002 | Specrew MUST explain `/speckit.checklist` in plain language as a requirements-quality aid that helps users catch vague, incomplete, inconsistent, or missing requirements before planning. | — |
| FR-003 | Specrew MUST make the recommended before-plan use of `/speckit.checklist` discoverable across the user-facing lifecycle guidance updated by this feature. | — |
| FR-004 | Specrew MUST preserve proportional guidance for `/speckit.checklist`, so users can tell when the command is recommended for substantive work and when it is optional for smaller slices. | — |
| FR-005 | Specrew MUST surface `/speckit.analyze` as a first-class lifecycle-adjacent command with clear guidance about the qualitative and cross-artifact issues it is intended to catch across `spec.md`, `plan.md`, and `tasks.md`. | — |
| FR-006 | Specrew MUST place `/speckit.analyze` at the `before-implement` lifecycle boundary, only after `/speckit.tasks` has successfully produced a complete `tasks.md`, and reflect that timing consistently across lifecycle guidance and documentation. | — |
| FR-007 | Specrew MUST explain that `/speckit.analyze` complements existing governance validation instead of replacing it. | — |
| FR-008 | Specrew MUST ensure users are only guided toward `/speckit.analyze` when `spec.md`, `plan.md`, and `tasks.md` all exist, and MUST tell them to return at `before-implement` if they encounter it before `/speckit.tasks` completes. | — |
| FR-009 | Specrew MUST improve command-discovery material so users can find the actively surfaced Spec Kit lifecycle-adjacent commands and understand when to use each one without referring back to the proposal. | — |
| FR-010 | Specrew MUST explicitly state that `/speckit.taskstoissues` is deferred for a later version and is not part of the default lifecycle in this feature slice. | — |
| FR-011 | The lifecycle timing, purpose, and deferment status described for these commands MUST remain consistent across every user-facing discovery surface updated by this feature. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: No single specialty dominates yet; treat the slice as general product work until task decomposition adds sharper evidence.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
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

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011
- User stories represented in current scope:
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
