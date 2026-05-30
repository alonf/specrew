# Iteration Plan: 003 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 3/20 story_points
**Started**: 2026-05-30
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

Iteration 003 = documentation + manual live-Cursor smoke (the feature's final slice). Closes FR-008 (docs) and provides the human-verified end-to-end evidence for SC-001/002/003/005/007 that earlier iterations could only assert via unit/integration tests.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-008 | Cursor quickstart + caveats in `docs/getting-started.md`; interaction-model section in `docs/user-guide.md` (no slash palette; AGENTS.md coordinator + .cursor/rules context; --allow-all->--force; interactive launch) | US1, US2, US4 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T014 | Add "Cursor Quickstart" + caveats (no slash palette; AGENTS.md-driven; install cursor-agent) to `docs/getting-started.md` | FR-008 | US1 | 1 | Implementer | `docs/getting-started.md` | done | claude | — | pass |
| T015 | Add Cursor interaction-model section to `docs/user-guide.md` (rules-context vs slash commands; interactive launch; --allow-all->--force) | FR-008 | US1, US2 | 1 | Implementer | `docs/user-guide.md` | done | claude | — | pass |
| T016 | Manual end-to-end smoke: `specrew start --host cursor "<feature>"` on this machine; capture human-verified evidence (HUMAN step) | FR-008 | US1, US4 | 1 | Implementer + Human | (evidence in iteration review) | in-progress | claude | — | — |

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
- Technology and scope signals: Backend/service-oriented signals dominate the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: The scoped requirements suggest multiple potentially separable workstreams, so same-specialty expansion may be justified after task decomposition.
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

- Requirement scope for iteration 003: FR-008 (docs) + human-verified SC-001/002/003/005/007 via manual smoke (T016).
- User stories represented: US1 (launch), US2 (skills->rules), US4 (menu). FR-001..FR-007 + FR-009..FR-011 delivered in iters 001-002.
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- Iteration 003 = docs (getting-started quickstart + user-guide interaction model) + manual live-Cursor smoke. Final feature slice before feature-closeout.
- Add task rows only for work that is traceable to the scoped requirements above.
- T016 is a HUMAN-verified manual smoke (actually launch `specrew start --host cursor`). Keep Status: planning until human grants before-implement approval.
- Feature-closeout (after iter-003): rebase onto post-F-049 main (169-commit lag), resolve any core-file conflicts, re-run suite, PR, beta-before-stable.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.