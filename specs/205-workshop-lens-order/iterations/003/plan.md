# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 7/20 story_points
**Started**: 2026-11-15
**Completed**: 2026-11-16

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
| FR-030 | The code-implementation lens refreshed from official release notes: a sources-checked date per stack, one "last checked" line per stack when it runs, stale after 90 days; version numbers only in that line and in Source Notes. | US6 |
| FR-031 | Proposal 220's status history records the iteration change and the order agreed after iteration 002. | US6 |
| FR-032 | The agenda shows its selected lenses under three headings from index.yml's `space` tag, each with a text label and one coloured marker; skipped lenses in their own list. | US6 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T027 | Code-lens freshness test, red-first; verification plan re-pointed | FR-030 | US6 | 1.25 | implementer | — | done | — | — | — |
| T028 | Agenda grouping test, red-first | FR-032 | US6 | 0.75 | implementer | — | done | — | — | — |
| T029 | Six per-stack rules refreshed from release notes; Source Notes | FR-030 | US6 | 1.5 | implementer | — | done | — | — | — |
| T030 | Line function, lens conduct (with the confirm-at-the-point-of-choice sentence), skill exception | FR-030 | US6 | 0.75 | implementer | — | done | — | — | — |
| T031 | Grouped agenda renderer, UTF-8 output, skill template and marker | FR-032 | US6 | 0.75 | implementer | — | done | — | — | — |
| T032 | Proposal 220 status history and INDEX row | FR-031 | US6 | 0.5 | implementer | — | done | — | — | — |
| T033 | Copies, hash record, green, regression, CI steps | FR-030, FR-032 | US6 | 1 | implementer | — | done | — | — | — |
| T034 | Recorded render check in a scratch project (last) | FR-032 | US6 | 0.5 | implementer | — | done | — | — | — |

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
- Technology and scope signals: PowerShell 7 scripts, lens markdown, the code-rules YAML catalog and tests (the scaffold read "frontend", the resolver misread; DRIFT-003).
- Task dependency graph: T027 and T028 first, committed red; T027 before T029 and T030, T029 before T030; T028 before T031; T032 independent; T029 to T032 before T033; T034 last.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: serial, single implementer; the tasks share the lens catalog, the skill and the agenda script, so parallel same-specialty work would conflict.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Amendment A2, design analysis (Option A), this plan |
| Discovery/Spikes | 0 | the release-notes lookups are inside T029 |
| Implementation | 7 | T027 to T034 |
| Review | 0 | the review-signoff crossing is not planned capacity (iteration 002 retro, calibration); the retro reports its actual cost |
| Rework | 2 | rework buffer (iteration 002 retro calibration) |

## Traceability Summary

- Requirement scope: FR-030, FR-031, FR-032.
- User stories represented in current scope: US6 (FR-030 to FR-032 cut across).
- Success criteria: SC-011 (FR-030) and FR-032's test clause.
- Tasks T027 to T034 are detailed in `tasks.md` ("Iteration 003 tasks"), with dependencies. FR-030: T027, T029, T030,
  T033. FR-031: T032. FR-032: T028, T031, T033, T034. SC-011: T027, T029, T033.

## Notes

- Planned effort 9 story_points against a 20 cap: 7 in tasks (the Capacity line, which the governance check sums
  from the task table) and the 2 SP rework buffer from the iteration 002 retro's calibration, held in the Phase
  Baseline rather than as a task row.
- The scope above was written by hand; the scaffold left it empty (DRIFT-002, H-024).
- The review-signoff crossing is not planned capacity; the retro reports its actual cost.
- Keep Status: planning until the tasks are approved.
