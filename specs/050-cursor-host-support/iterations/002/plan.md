# Iteration Plan: 002 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 2.5/20 story_points
**Started**: 2026-05-29
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

Iteration 002 = test-coverage hardening. FR-005 unit tests were already authored alongside the functions in iter-001 (`tests/integration/host-cursor.tests.ps1`); this iteration adds the dedicated launch integration smoke (FR-006) and formalizes cursor in the multi-host detection matrix (FR-007). Reconciled test paths per DRIFT-003 (no `tests/hosts/` dir; convention is `tests/integration/host-*.tests.ps1`).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-005 | Unit tests cover all 5 contract functions with mock + real-`cursor-agent` fixtures (delivered iter-001 `tests/integration/host-cursor.tests.ps1`; iter-002 adds a real-binary version-probe fixture, skip-guarded) | US1, US3 |
| FR-006 | Integration smoke `tests/integration/host-cursor-launch.tests.ps1` for the `specrew start --host cursor` launch-invocation path (skip-guarded without `cursor-agent`) | US1 |
| FR-007 | Cursor included in the multi-host detection/probe matrix (host-registry + multi-host-launch-path updated iter-001; iter-002 adds an explicit cursor assertion to `host-detection-ux.tests.ps1` if missing) | US4 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T011 | Add real-`cursor-agent` version-probe fixture (skip-guarded) to `host-cursor.tests.ps1` | FR-005 | US1 | 0.5 | Implementer | `tests/integration/host-cursor.tests.ps1` | done | claude | — | pass |
| T012 | Author `tests/integration/host-cursor-launch.tests.ps1` launch-path integration smoke (skip-guarded without binary) | FR-006 | US1 | 1.5 | Implementer | `tests/integration/host-cursor-launch.tests.ps1` | done | claude | — | pass |
| T013 | Ensure cursor appears in the detection matrix: add explicit cursor assertion to `host-detection-ux.tests.ps1` (host-registry + multi-host-launch-path already updated iter-001) | FR-007 | US4 | 0.5 | Implementer | `tests/integration/host-detection-ux.tests.ps1` | done | claude | — | pass |

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
| Planning | done | Iteration plan + hardening gate prepared; small test-only slice |
| Discovery/Spikes | 0 | No spikes; contract + launch shape settled in iter-001 |
| Implementation | 2.5 | Sum of T011–T013 |
| Review | ~0.5 | Cross-reviewer signoff (Charter Item 8) |
| Rework | buffer | Within 2.5/20 capacity headroom |

## Traceability Summary

- Requirement scope for iteration 002: FR-005 (real-binary fixture top-up), FR-006 (launch integration smoke), FR-007 (detection-matrix cursor assertion).
- User stories represented: US1 (launch path), US4 (detection/menu).
- FR-008 (docs) remains for iteration 003. FR-001/002/003/004/009/010/011 delivered in iter-001.
- Traceability: every iter-002 task (T011–T013) maps to ≥1 in-scope FR; each in-scope FR has ≥1 task.
- Overcommit guardrail: planned 2.5 SP vs capacity 20 — well under; no deferrals.

## Notes

- Iteration 002 = test-coverage hardening (launch integration smoke + real-binary fixture + detection-matrix assertion). Test-only; no production code changes.
- Hardening gate ([quality/hardening-gate.md](./quality/hardening-gate.md)) Overall Verdict: ready.
- Parallel-Work Charter still active (ModuleVersion 0.29.0; F-049 PR merges first; beta-before-stable; cross-reviewer at signoff). The iter-001 mirror-parity item remains the tracked feature-closeout action.
- Keep Status: planning until human grants before-implement approval; then advance to executing.