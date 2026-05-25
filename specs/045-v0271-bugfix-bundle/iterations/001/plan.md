# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
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
| FR-001 | The CLI MUST accept both `--version` and `-v` as top-level aliases for version display with output parity to `specrew version`. | — |
| FR-002 | The version command MUST suppress the "version could not be determined" warning when the version is determinable even outside an initialized project. | — |
| FR-003 | The patch bundle MUST resolve all 7 post-release findings by applying behavior changes only for actionable defects and explicitly closing stale review findings without changing runtime behavior. | — |
| FR-004 | Startup behavior MUST auto-repair missing skill catalog directories during `specrew start` before continuing normal flow. | — |
| FR-005 | Initialization validation MUST treat missing skill catalog directories as deployable gaps and proceed into deployment flow for both no-force and force entry paths. | — |
| FR-006 | Brownfield conflict detection MUST treat existing `.squad/agents/` as canonical source (not conflicting) when project-root self-hosting extension presence indicates that ownership model. | — |
| FR-007 | The update documentation MUST describe module install/update behavior, force and publisher-check semantics, init re-deployment triggers, and the recurring skill-catalog deployment-gap pattern. | — |
| FR-008 | The patch MUST preserve established mirror/governance expectations across lifecycle artifacts, including active feature pointer consistency for downstream phases. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T001 | Create patch finding ledger for F1-F7 actionable-vs-stale tracking | FR-003, TG-006, TG-007 | Setup | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` | in-progress |
| T003 | Create shared skill-catalog state helpers for repair/deploy gap evaluation | FR-004, FR-005, SC-003 | Foundational | 2 | Implementer | `scripts/internal/skill-catalog-state.ps1` | planned |
| T004 | Wire shared helper into start bootstrap import path | FR-004, FR-008, TG-004 | Foundational | 1 | Implementer | `scripts/specrew-start.ps1` | planned |
| T005 | Wire shared helper into init bootstrap import path | FR-005, FR-008, TG-004 | Foundational | 1 | Implementer | `scripts/specrew-init.ps1` | planned |
| T006 | Validate governance mirror parity for helper imports across mirrored loaders | FR-008, TG-004 | Foundational | 1 | Reviewer | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1` | planned |
| T007 | Extend version CLI regression coverage for alias parity and warning suppression | FR-001, FR-002, SC-001, SC-002, SC-006, TG-001 | US1 | 2 | Implementer | `tests/integration/validate-versions-cli-behavior.ps1` | planned |
| T008 | Extend start/init recovery regression coverage for missing catalog behaviors | FR-004, FR-005, SC-003, SC-006, TG-001 | US1 | 2 | Implementer | `tests/integration/start-recovery-flow.tests.ps1` | planned |
| T009 | Add top-level `--version` and `-v` routing parity through canonical behavior | FR-001, SC-001, TG-001 | US1 | 1 | Implementer | `scripts/specrew.ps1` | planned |
| T010 | Gate version warning emission to true unknown states only | FR-002, SC-002, TG-001 | US1 | 1 | Implementer | `scripts/specrew-version.ps1` | planned |
| T011 | Implement start missing skill-catalog auto-repair continuation flow | FR-004, SC-003, TG-001 | US1 | 2 | Implementer | `scripts/specrew-start.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T012 | Implement init non-force deployable-gap continuation flow | FR-005, SC-003, TG-001 | US1 | 2 | Implementer | `scripts/specrew-init.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T013 | Implement init force deployable-gap continuation without false success | FR-005, SC-003, TG-001 | US1 | 2 | Implementer | `scripts/specrew-init.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T014 | Update CLI behavior contract for implemented command expectations | FR-001, FR-002, FR-004, FR-005, SC-001, SC-002, SC-003, TG-001 | US1 | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/contracts/cli-behavior-contract.md` | planned |
| T015 | Run version/start regression suites and record quality evidence | SC-001, SC-002, SC-003, SC-006, TG-001 | US1 | 1 | Reviewer | `tests/integration/validate-versions-cli-behavior.ps1`, `tests/integration/start-recovery-flow.tests.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |

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
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
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

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008
- User stories represented in current scope: US1, US2, US3 (+ setup/foundational/polish support phases)
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Iteration 001 scope: T001 (Setup: 1 SP) + T003-T006 (Foundational: 5 SP) + T007-T015 (US1 tests + impl + polish: 14 SP) = 20 SP exactly.
- Iteration 002 scope (created at iteration-001 closeout): T002 (Setup traceability: 1 SP) + T016-T020 (US2: 7 SP) + T021-T026 (US3: 8 SP) + T027-T030 (Polish: 4 SP) = 20 SP exactly.
- Sequencing: Iter 001 closes US1 + foundational prerequisites; human checkpoint gate; then iter 002 starts US2 + US3 + feature closeout.
- Two-iteration split enforces human decision checkpoint between CLI defects (US1) and brownfield/docs (US2+US3), per Feature 016 governance discipline.
- Effort convention remains S=1 story point and M=2 story points; iter-001 stores numeric effort values directly for validator compatibility. Current scope: 8 tasks at 1 SP + 6 tasks at 2 SP = 20 SP planned (matches Capacity 20/20).
