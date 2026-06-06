# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 2/20 story_points
**Started**: 2026-06-06
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
| FR-001 | The repository MUST NOT contain a tracked top-level `evaluation/` directory (AC1). | US1 |
| FR-002 | The process-quality scorer MUST live at `tests/support/process-quality-scorer.ps1`, classified as test infrastructure — not product runtime, not a public evaluation harness (workshop decision, human-confirmed). | US2 |
| FR-003 | `tests/integration/process-quality-scorer.ps1` MUST pass using the moved scorer (AC2). | US2 |
| FR-004 | `tests/integration/process-quality-report.ps1` MUST pass and write its generated report outside any tracked top-level surface (AC3). | US2 |
| FR-005 | The multi-host lifecycle smoke test MUST parse the moved scorer and preserve the Linux-safe forward-slash path assertion (AC4). | US2 |
| FR-006 | User-facing docs MUST NOT advertise `evaluation/` as a current public workflow; explanatory retirement wording is permitted (AC5). | US1 |
| FR-007 | Maintainer-facing proposal/index surfaces MUST record why the scorer was moved rather than deleted (AC6). | US3 |
| FR-008 | Historical specs, retros, and frozen test fixtures referencing `evaluation/` MUST remain unmodified (history preservation). | US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Structural verification: no tracked `evaluation/`; scorer at `tests/support/` | FR-001, FR-002 | US1, US2 | 0.25 | Implementer | (read-only verification) | planned | claude | | |
| T002 | Run process-quality-scorer integration test (exit 0, run log) | FR-003 | US2 | 0.25 | Implementer | (read-only verification) | planned | claude | | |
| T003 | Run process-quality-report integration test; assert untracked report placement | FR-004 | US2 | 0.25 | Implementer | (read-only verification) | planned | claude | | |
| T004 | Run multi-host smoke suite + path-resolution regression | FR-005 | US2 | 0.25 | Implementer | (read-only verification) | planned | claude | | |
| T005 | Active-surface `evaluation/` reference scan; classify every hit | FR-006 | US1 | 0.25 | Implementer | (read-only verification) | planned | claude | | |
| T006 | Audit trail (proposal/index) + history immutability diff | FR-007, FR-008 | US3 | 0.25 | Spec Steward | (read-only verification) | planned | claude | | |
| T007 | Mechanical checks + consolidate quality-evidence.md; fix and re-verify any gap | FR-001..FR-008 | US1, US2, US3 | 0.5 | Implementer | `specs/170-retire-evaluation-surface/iterations/001/quality/**` | planned | claude | | |

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
- Task dependency graph: T001 precedes T002-T004; T005/T006 independent; T007 last.
- Workstream separability: 2 SP single-session slice — serial execution; no
  same-specialty expansion warranted.
- Shared-surface conflict risk: none — verification tasks are read-only except
  T007's evidence writes under the iteration quality directory.
- Recommendation: serial execution by the delegated Implementer (claude), with
  T006 under Spec Steward ownership per the routing plan.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 SP | Spec/plan/tasks/design-analysis (consumed pre-iteration) |
| Discovery/Spikes | 0 SP | None — implementation pre-exists as adoption snapshot |
| Implementation | 2 SP | T001-T007 per the task table (arithmetic: 6 x 0.25 + 0.5 = 2.0) |
| Review | 0.5 SP | Reviewer artifacts + SC-004 re-check |
| Rework | 0.25 SP | Buffer for gaps surfaced by verification |

## Traceability Summary

- Requirement scope for this iteration: FR-001..FR-008 — every FR has >=1 task; every task traces to >=1 FR (see tasks.md mapping).
- User stories represented in current scope: US1 (T001, T005), US2 (T001-T004), US3 (T006); T007 is the cross-cutting evidence layer.
- Capacity arithmetic check: per-task effort sums to 2.0 SP = declared `2/20 story_points` (Shape 9 rule).
- Overcommit guardrail: 2/20 — no deferrals required.

## Notes

- Verification-first iteration: the implementation pre-exists (adoption
  snapshot `3b6a3e0d`); tasks prove FRs empirically and fix gaps.
- Keep Status: planning until the before-implement gate passes with human
  authorization; then flip to executing.
