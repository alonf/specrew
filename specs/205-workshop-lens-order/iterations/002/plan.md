# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 20/20 story_points
**Started**: 2026-11-13
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
| FR-023 | product-domain covers six cross-cutting facts; the compliance regime is asked at every depth, the other five are recommendation lines at Light with stated defaults ("not stated" where nothing shows). | US6 |
| FR-024 | Each product-domain fact is handed forward as the later lens's recommended answer, naming product-domain, including "not stated". | US6 |
| FR-025 | Twelve lens-specific problem questions added under their lenses' problem headings. | US6 |
| FR-026 | Every added or changed question ships with a recommended answer, its reason and its consumer; one block per lens, closed by one reply. | US6 |
| FR-027 | Touched lenses define Light, Standard and Deep; added problem questions default to Light as recommendation lines. | US6 |
| FR-028 | A length test reports must-answer points, typed replies and recommendation lines per depth; Light capped at 51 and 18; other numbers change only with their record. | US6 |
| FR-029 | Every added question names a consumer that exists today (a spec.md section or a later lens); a test proves it. | US6 |

FR-030 (the code-implementation lens refresh) is iteration 003. FR-031 (proposal 220's status line) is proposed for
iteration 003 as a trim; see the feature plan's "Sizes and the point over the cap".

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T018 | Length and consumer test, red-first | FR-028, FR-029 | US6 | 4 | implementer | — | planned | — | — | — |
| T019 | product-domain: six facts, compliance at every depth, depth content | FR-023, FR-027 | US6 | 2 | implementer | — | planned | — | — | — |
| T020 | Hand-forward lines in the receiving lenses | FR-024 | US6 | 2 | implementer | — | planned | — | — | — |
| T021 | Twelve lens-specific questions with recommendations and consumers | FR-025, FR-026, FR-029 | US6 | 3 | implementer | — | planned | — | — | — |
| T022 | Depth content for the touched lenses | FR-027 | US6 | 2.5 | implementer | — | planned | — | — | — |
| T023 | Workshop skill: one block, accept closes | FR-026 | US6 | 1.5 | implementer | — | planned | — | — | — |
| T024 | Spec template Problem Context and copies | FR-029 | US6 | 1 | implementer | — | planned | — | — | — |
| T025 | Parity, extractor counts, workshop regression, CI steps, copies | FR-025, FR-028 | US6 | 2 | implementer | — | planned | — | — | — |
| T026 | Recorded Light workshop run (last) | FR-026, FR-023 | US6 | 2 | implementer | — | planned | — | — | — |

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
- Technology and scope signals: lens markdown, the spec template, the workshop skill text and PowerShell 7 tests (the scaffold's "frontend" reading is the resolver misread, DRIFT-001).
- Task dependency graph: the test file and its red-first runs come first; product-domain (FR-023) before the hand-forward lines (FR-024); the lens questions and depth content before the length numbers are recorded; the recorded Light run last.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: serial, single implementer; every change touches the lens files and the one test file, so parallel same-specialty work would conflict.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | workshop, Amendment A1, design analysis (Option A), this plan |
| Discovery/Spikes | 0 | the product-domain `areas` schema is free-form; checked at planning |
| Implementation | 20 | FR-023 to FR-029, parity and regression, and the recorded Light workshop run (T026, last) |
| Review | 0 | the review-signoff crossing is not planned capacity in this iteration (maintainer, 2026-11-13); the retro reports its actual cost |
| Rework | 0 | no buffer left at 20/20; rework comes out of the iteration 003 slot if needed |

## Traceability Summary

- Requirement scope: FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029 (FR-031 proposed for iteration 003).
- User stories represented in current scope: US6.
- Success criteria: SC-007 to SC-010 and SC-012 (SC-011 is iteration 003).
- The task table is filled at the tasks stage; specrew-capacity-planning and specrew-traceability-check run then.

## Notes

- Planned effort 20 story_points against a 20 cap. The governance check refuses a plan over capacity, so nothing can
  be carried as an overrun.
- The review-signoff crossing (2 SP in the iteration 001 retro's calibration line) is not planned capacity in this
  iteration. The maintainer chose this at 13:19 local on 2026-11-13 ("2", relayed by the reviewer session with the
  question it answered). The retro reports the crossing's actual cost, as iteration 001's did. This reverses that
  calibration line for this iteration only (iteration 002 DRIFT-004).
- The recorded Light workshop run is back in this iteration as T026, last (SC-012). Iteration 003 keeps the
  code-implementation lens refresh (FR-030) and the proposal 220 status line (FR-031).
- No rework buffer at 20/20.
- Keep Status: planning until the plan is approved.
