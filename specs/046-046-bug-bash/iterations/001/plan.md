# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18/20 story_points
**Started**: 2026-05-25
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
| FR-001 | The stale-state detector MUST treat `retro` as a valid allowed boundary when `review.md` is accepted. | — |
| FR-002 | `sync-boundary-state.ps1` MUST update `boundary_enforcement.last_authorized_boundary` and append to `boundary_enforcement.verdict_history` inline (Option A atomicity) when boundary enforcement is active. | — |
| FR-003 | The boundary sync helper MUST check if the target boundary is already authorized to avoid duplicate history lines or invalid backward moves. | — |
| FR-004 | All scaffolders MUST check if target files contain populated verdicts (e.g. `Overall Verdict: accepted`) or non-stub verdicts before overwriting, instead writing to a sibling `.pending` file with a console warning. | — |
| FR-005 | `sync-boundary-state.ps1` and `Invoke-SpecrewBoundaryStateSync` MUST remove their static `[ValidateSet(...)]` restriction and dynamically map common prose aliases (`implement` -> `review-signoff`, `spec` -> `specify`, etc.) to canonical names or throw helpful errors. | — |
| FR-006 | Feature-intake documentation MUST record all bug details in a durable `findings.md` ledger. | — |
| FR-007 | Any changes to `extensions/specrew-speckit/scripts/` MUST be mirrored in `.specify/extensions/specrew-speckit/scripts/` to maintain parity. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create stale-state allow-list regression fixtures in tests/integration/stale-state-retro.tests.ps1 | FR-001 | US1 tests | 1 | Implementer | `tests/integration/stale-state-retro.tests.ps1` | planned | Codex | | |
| T002 | Map retro as an allowed boundary in scripts/specrew-start.ps1 and scripts/specrew-review.ps1 allow-lists | FR-001 | US1 implementation | 1 | Implementer | `scripts/specrew-start.ps1`, `scripts/specrew-review.ps1` | planned | Codex | | |
| T003 | Create atomic boundary sync validation fixtures in tests/integration/boundary-sync-atomic.tests.ps1 | FR-002, FR-003 | US2 tests | 2 | Implementer | `tests/integration/boundary-sync-atomic.tests.ps1` | planned | Codex | | |
| T004 | Implement inline verdict writer and Add-SpecrewBoundaryAuthorization call in scripts/internal/sync-boundary-state.ps1 | FR-002, FR-003 | US2 implementation | 2 | Implementer | `scripts/internal/sync-boundary-state.ps1` | planned | Codex | | |
| T005 | Create artifact protection validation tests in tests/integration/scaffolder-protection.tests.ps1 | FR-004 | US3 tests | 2 | Reviewer | `tests/integration/scaffolder-protection.tests.ps1` | planned | Codex | | |
| T006 | Implement Test-SpecrewFileHasPopulatedVerdict check and pending-redirect logic in scaffolders | FR-004 | US3 implementation | 2 | Reviewer | `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `scaffold-review-artifact.ps1`, `scaffold-retro-artifact.ps1` | planned | Codex | | |
| T007 | Mirror scaffolder changes to .specify/extensions/specrew-speckit/scripts/ counterparts | FR-004, FR-007 | US3 implementation | 1 | Reviewer | `.specify/extensions/specrew-speckit/scripts/*` | planned | Codex | | |
| T008 | Create prose alias translation fixtures in tests/integration/prose-alias-sync.tests.ps1 | FR-005 | US4 tests | 1 | Implementer | `tests/integration/prose-alias-sync.tests.ps1` | planned | Codex | | |
| T009 | Remove parameter [ValidateSet] and implement dynamic alias mapping in sync wrappers and internal handlers | FR-005 | US4 implementation | 2 | Implementer | `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`, `scripts/internal/sync-boundary-state.ps1` | planned | Codex | | |
| T010 | Mirror boundary-sync alias changes to .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 wrapper | FR-005, FR-007 | US4 implementation | 1 | Implementer | `.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1` | planned | Codex | | |
| T011 | Complete specs/046-046-bug-bash/findings.md logging all repro, root cause, and validation evidence | FR-006 | US5 documentation | 1 | Doc Steward | `specs/046-046-bug-bash/findings.md` | planned | Codex | | |
| T012 | Run mechanical checks via .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 and validate outputs | FR-007 | Polish | 1 | Reviewer | `specs/046-046-bug-bash/iterations/001/quality/mechanical-findings.json` | planned | Codex | | |
| T013 | Execute governance validation via .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 and record results | FR-007 | Polish | 1 | Reviewer | `specs/046-046-bug-bash/iterations/001/quality/quality-evidence.md` | planned | Codex | | |

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
| Planning | 0 | Scaffolding and planning only |
| Discovery/Spikes | 0 | No spikes required |
| Implementation | 14 | T001-T002, T003-T004, T005-T007, T008-T010, T011 |
| Review | 4 | T012-T013 |
| Rework | 0 | No pre-allocated rework buffer |

## Traceability Summary

- Requirement scope for this iteration: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007
- User stories represented in current scope: US1, US2, US3, US4, US5
- Capacity: 18 story points consumed out of 20 story points capacity. No overcommit.
- Traceability checks: Every task maps to at least one FR and every FR has at least one task.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.