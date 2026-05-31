# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Feature Tasks**: [../../tasks.md](../../tasks.md)
**Status**: planning
**Capacity**: 8.75/20 story_points
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
| FR-001 | Specrew MUST surface `/speckit.checklist` as a first-class lifecycle-adjacent command before planning for substantive feature work. | US1 |
| FR-002 | Specrew MUST explain `/speckit.checklist` in plain language as a requirements-quality aid that helps users catch vague, incomplete, inconsistent, or missing requirements before planning. | US1 |
| FR-003 | Specrew MUST make the recommended before-plan use of `/speckit.checklist` discoverable across the user-facing lifecycle guidance updated by this feature. | US1 |
| FR-004 | Specrew MUST preserve proportional guidance for `/speckit.checklist`, so users can tell when the command is recommended for substantive work and when it is optional for smaller slices. | US1 |
| FR-005 | Specrew MUST surface `/speckit.analyze` as a first-class lifecycle-adjacent command with clear guidance about the qualitative and cross-artifact issues it is intended to catch across `spec.md`, `plan.md`, and `tasks.md`. | US2 |
| FR-006 | Specrew MUST place `/speckit.analyze` at the `before-implement` lifecycle boundary, only after `/speckit.tasks` has successfully produced a complete `tasks.md`, and reflect that timing consistently across lifecycle guidance and documentation. | US2 |
| FR-007 | Specrew MUST explain that `/speckit.analyze` complements existing governance validation instead of replacing it. | US2 |
| FR-008 | Specrew MUST ensure users are only guided toward `/speckit.analyze` when `spec.md`, `plan.md`, and `tasks.md` all exist, and MUST tell them to return at `before-implement` if they encounter it before `/speckit.tasks` completes. | US2 |
| FR-009 | Specrew MUST improve command-discovery material so users can find the actively surfaced Spec Kit lifecycle-adjacent commands and understand when to use each one without referring back to the proposal. | US3 |
| FR-010 | Specrew MUST explicitly state that `/speckit.taskstoissues` is deferred for a later version and is not part of the default lifecycle in this feature slice. | US3 |
| FR-011 | The lifecycle timing, purpose, and deferment status described for these commands MUST remain consistent across every user-facing discovery surface updated by this feature. | US1, US2, US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create the quality-evidence scaffold and reserve evidence links | FR-009, FR-011, SC-004 | US3 | 0.25 | Planner | `specs/054-activate-spec-surfaces/iterations/001/quality/*`, `specs/054-activate-spec-surfaces/iterations/001/plan.md` | planned | — | — | — |
| T002 | Align mirrored extension metadata for surfaced and deferred commands | FR-001, FR-005, FR-010, FR-011 | US1, US2, US3 | 0.50 | Spec Steward | `extensions/specrew-speckit/extension.yml`, `.specify/extensions/specrew-speckit/extension.yml` | planned | — | — | — |
| T003 | Extend lifecycle-boundary sync coverage for checklist/analyze placement | FR-006, FR-008, FR-011, SC-003 | US2, US3 | 0.50 | Reviewer | `tests/integration/lifecycle-boundary-sync.tests.ps1` | planned | — | — | — |
| T004 | Extend validation-contract coverage for discovery wording and deferment | FR-009, FR-010, FR-011, TG-001, SC-005 | US3 | 0.50 | Reviewer | `tests/integration/validation-contract-lane.ps1`, `specs/054-activate-spec-surfaces/contracts/*.md` | planned | — | — | — |
| T005 | Add before-plan checklist regression coverage | FR-001, FR-002, FR-003, FR-004, SC-001, SC-002 | US1 | 0.50 | Reviewer | `tests/integration/slash-command-routing.tests.ps1` | planned | — | — | — |
| T006 | Update mirrored before-plan command surfaces | FR-001, FR-002, FR-004, SC-001, SC-002 | US1 | 0.50 | Planner | `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md`, `.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md` | planned | — | — | — |
| T007 | Revise planning/checklist handoff guidance | FR-001, FR-002, FR-003, FR-004 | US1 | 0.50 | Spec Steward | `.github/agents/speckit.plan.agent.md`, `.github/prompts/speckit.checklist.prompt.md` | planned | — | — | — |
| T008 | Update checklist agent discovery copy | FR-002, FR-003, FR-004, SC-002 | US1 | 0.25 | Spec Steward | `.github/agents/speckit.checklist.agent.md` | planned | — | — | — |
| T009 | Add before-implement analyze regression coverage | FR-005, FR-006, FR-007, FR-008, SC-003 | US2 | 0.50 | Reviewer | `tests/integration/slash-command-coexistence.tests.ps1` | planned | — | — | — |
| T010 | Update mirrored before-implement command surfaces | FR-005, FR-006, FR-007, FR-008, SC-003 | US2 | 0.50 | Planner | `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md`, `.specify/extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md` | planned | — | — | — |
| T011 | Revise tasks/analyze guidance prompts | FR-005, FR-006, FR-007, FR-008 | US2 | 0.50 | Spec Steward | `.github/agents/speckit.tasks.agent.md`, `.github/prompts/speckit.analyze.prompt.md` | planned | — | — | — |
| T012 | Update analyze agent discovery copy | FR-005, FR-007, FR-008, SC-003 | US2 | 0.25 | Spec Steward | `.github/agents/speckit.analyze.agent.md` | planned | — | — | — |
| T013 | Add lifecycle-adjacent discovery coverage for surfaced vs deferred commands | FR-009, FR-010, FR-011, SC-004, SC-005 | US3 | 0.50 | Reviewer | `tests/integration/slash-command-discovery.tests.ps1` | planned | — | — | — |
| T014 | Update lifecycle-adjacent command docs and matrix | FR-009, FR-010, FR-011, SC-004, SC-005 | US3 | 0.75 | Spec Steward | `README.md`, `docs/user-guide.md` | planned | — | — | — |
| T015 | Update taskstoissues deferred-status guidance | FR-010, FR-011, SC-005 | US3 | 0.50 | Spec Steward | `.github/agents/speckit.taskstoissues.agent.md`, `.github/prompts/speckit.taskstoissues.prompt.md` | planned | — | — | — |
| T016 | Run markdownlint and record evidence | FR-009, FR-011, SC-004 | US3 | 0.50 | Implementer | `README.md`, `docs/user-guide.md`, `.github/agents/*.md`, `.github/prompts/*.md`, `specs/054-activate-spec-surfaces/*.md`, `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` | planned | — | — | — |
| T017 | Run integration lanes and record quality evidence | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, SC-001, SC-002, SC-003, SC-004, SC-005 | US1, US2, US3 | 0.75 | Implementer | `tests/integration/*.ps1`, `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` | planned | — | — | — |
| T018 | Run mechanical checks and record findings | FR-009, FR-011 | US3 | 0.50 | Reviewer | `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1`, `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1`, `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` | planned | — | — | — |

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
- Technology and scope signals: Mixed governance, docs, mirrored-extension, and regression-test work dominates the slice.
- Task dependency graph: `T001-T004` establish evidence targets and lifecycle parity first; US1/US2/US3 then fan out; `T016-T018` close the slice with evidence capture.
- Workstream separability: After the foundational work lands, US2 and US3 can proceed alongside the bounded US1 follow-up tasks called out in `tasks.md`.
- Shared-surface conflict risk: moderate around mirrored `extensions/` and `.specify/` command surfaces, so mirrored edits should stay serial within each story lane.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: keep the baseline team and use only the explicit parallel slots already declared in the generated task package (`T003/T004`, `T008`, `T012`, `T015`, and `T016/T017`).

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | `spec.md`, `plan.md`, and `tasks.md` are generated and synchronized for the tasks-boundary package. |
| Discovery/Spikes | 0 | No additional spike work is planned; lifecycle placement and contract decisions are already captured in the feature artifacts. |
| Implementation | 8.75 | Sum of planned tasks `T001-T018`. |
| Review | ~1 | Reviewer pass across the surfaced guidance, mirrored metadata, and recorded quality evidence after implementation. |
| Rework | buffer | Any repair must stay inside the approved `T001-T018` surface or return for a fresh human verdict. |

## Traceability Summary

- Requirement scope for this iteration: FR-001 through FR-011.
- User stories represented in current scope: US1, US2, and US3, plus setup/foundational/polish work.
- Traceability check: PASS — every planned task `T001-T018` maps to at least one scoped requirement or success criterion, and every scoped FR has at least one planned task in [../../tasks.md](../../tasks.md).
- Overcommit guardrail: planned effort is 8.75 story_points versus 20 story_points of capacity, so no deferral is required at the tasks boundary.

## Notes

- This plan reflects the generated F-054 task package at the `tasks` boundary and does not authorize `before-implement`, implementation, or later lifecycle work.
- Planned evidence outputs remain bounded to [quality/quality-evidence.md](quality/quality-evidence.md) and [quality/mechanical-findings.json](quality/mechanical-findings.json).
- Keep Status: planning until human approval opens `before-implement`; only then should the iteration advance to `executing`.
- If scope changes later, update the task table, phase baseline, and traceability summary together in the same planning repair.
