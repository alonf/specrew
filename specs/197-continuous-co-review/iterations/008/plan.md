# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: abandoned
**Capacity**: 0/20 story_points
**Started**: 2026-06-27
**Completed**:

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 008 (reviewer-context redesign exploration + the dogfood hard-gate repair slice
T087–T089). This plan.md is a POST-HOC reconstruction for governance completeness: 008 delivered
the hard-gate repair slice (validated, 148 tests) and explored the reviewer-context redesign, then
**pivoted to iteration 009 before running its own review/retro/signoff cycle**, so it never
authored a forward task plan or tracked story points. Tasks below are the delivered work recorded
in [state.md](state.md); effort is nominal (`0.00`). Recorded as `abandoned` — its planned cycle
did not complete — with delivered fixes carried into 009. Repair narrative in
[drift-log.md](drift-log.md) (D-197-I008-001).

| Requirement / Issue | Summary | Slice |
| ------------------- | ------- | ----- |
| FR-025 / SC-015 / FR-034 | Dogfood hard-gate repair: default-on signoff gate, self-review source visibility, reviewer-runtime telemetry. | delivered |
| FR-026 | Reviewer-context redesign exploration. | pivoted to 009 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T087 | Review-signoff gate default-on in the 197-owned co-review wiring; explicit `false` config is informational, not a bypass. | FR-025 | Hard-gate repair | 0.00 | Implementer | `scripts/internal/continuous-co-review/**` | done |
| T088 | Specrew self-review keeps `scripts/internal/continuous-co-review/**` visible as product source while downstream project reviews still strip deployed methodology runtime. | SC-015 | Hard-gate repair | 0.00 | Implementer | `scripts/internal/continuous-co-review/**` | done |
| T089 | Persist reviewer-runtime telemetry, smart budget guidance, artifact paths, phase timings, and reviewer invocation metadata for long-running co-review runs. | FR-034 | Hard-gate repair | 0.00 | Implementer | `scripts/internal/continuous-co-review/**` | done |
| T090 | Reviewer-context redesign exploration → pivot to iteration 009. | FR-026 | Reviewer-context redesign | 0.00 | Planner | `specs/197-continuous-co-review/iterations/009/**` | deferred |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded slice. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Traceability Summary

- Delivered: T087–T089 (hard-gate repair slice), 148 continuous-co-review tests passing (2026-06-27).
- Pivoted (OUT of 008): the reviewer-context redesign → iteration 009.
- Status: `abandoned` (pivoted before this iteration's own review/retro/signoff cycle); delivered fixes carried forward.

## Notes

- Reconstructed post-hoc; the authoritative record is [state.md](state.md) and [drift-log.md](drift-log.md). Effort is nominal because 008 never SP-planned.
