# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: abandoned
**Capacity**: 0/20 story_points
**Started**: 2026-06-26
**Completed**:

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 007 (real-reviewer wiring + nested-project + deploy-completeness). This plan.md is a
POST-HOC reconstruction for governance completeness: iteration 007 ran as an exploratory,
drive-the-real-path iteration and **pivoted to iteration 008 before running its own review/retro/
signoff cycle**, so it never authored a forward task plan or tracked story points. The tasks below
are the real delivered commits (see each row); effort is nominal (`0.00`) because no SP plan was
made. The iteration is recorded as `abandoned` — its planned cycle did not complete — with its
delivered fixes carried forward into 008/009. Full narrative in
[state.md](state.md).

| Requirement / Issue | Summary | Slice |
| ------------------- | ------- | ----- |
| FR-030 / FR-031 | Drive the real reviewer end-to-end on a real deployed (nested) project; find + fix deploy-completeness and change-set-scoping gaps. | delivered |
| FR-026 | Reviewer-context flow found architecturally fragile → pivot. | pivoted to 008 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T101 | Subtree-scoped change-set diff for nested governance roots (`81b7070e`). | FR-030 | Real-reviewer wiring | 0.00 | Implementer | `scripts/internal/continuous-co-review/**` | done |
| T102 | Scaffolding exclusion + large-diff cap + adapter input-size guard + state-the-reason diagnostics (`85c12930`). | FR-030 | Real-reviewer wiring | 0.00 | Implementer | `scripts/internal/continuous-co-review/**` | done |
| T103 | Deploy-completeness: ship the co-review runtime + isolated-task launcher + `atomic-write.ps1` to deployed projects (`49f88717`). | FR-031 | Deploy-completeness | 0.00 | Implementer | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | done |
| T104 | Pester v4→v5.5.0 migration (`85c12930`), 44 CCR files, count-parity verified. | SC-006 | Test-suite integrity | 0.00 | Reviewer | `tests/continuous-co-review/**` | done |
| T105 | Reviewer-context architecture finding → pivot to iteration 008. | FR-026 | Reviewer-context redesign | 0.00 | Planner | `specs/197-continuous-co-review/iterations/008/**` | deferred |

<!-- 2026-07-01: these post-hoc task IDs were renumbered T091-T095 -> T101-T105 to resolve the collision with iteration 009's canonical, commit-cited T090-T098 (T101-T105 is the next free block above iter-009's T099/T100). The delivered commits are unchanged; only the post-hoc labels moved. Mirrors the iter-009 T095 resolution of the earlier T083-T085 collision. -->

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

- Delivered: subtree-scoped diff, scaffolding-exclusion + guards, deploy-completeness, Pester v5 migration, and a real 5-finding claude review on a deployed nested project.
- Pivoted (OUT of 007): the reviewer-context redesign → iteration 008 → iteration 009.
- Status: `abandoned` (pivoted before this iteration's own review/retro/signoff cycle); delivered fixes carried forward.

## Notes

- Reconstructed post-hoc; the authoritative record of what shipped is [state.md](state.md) and the cited commits. Effort is nominal because 007 never SP-planned.
