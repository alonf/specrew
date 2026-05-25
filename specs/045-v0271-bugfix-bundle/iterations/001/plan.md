# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 40/20 story_points
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
| T001 | Create patch finding ledger for F1-F7 actionable-vs-stale tracking | FR-003, TG-006, TG-007 | Setup | S | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` | planned |
| T002 | Create traceability matrix mapping US1-US3 to FR/SC requirements | TG-001, TG-002, TG-003, TG-004 | Setup | S | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/001/traceability-matrix.md` | planned |
| T003 | Create shared skill-catalog state helpers for repair/deploy gap evaluation | FR-004, FR-005, SC-003 | Foundational | M | Implementer | `scripts/internal/skill-catalog-state.ps1` | planned |
| T004 | Wire shared helper into start bootstrap import path | FR-004, FR-008, TG-004 | Foundational | S | Implementer | `scripts/specrew-start.ps1` | planned |
| T005 | Wire shared helper into init bootstrap import path | FR-005, FR-008, TG-004 | Foundational | S | Implementer | `scripts/specrew-init.ps1` | planned |
| T006 | Validate governance mirror parity for helper imports across mirrored loaders | FR-008, TG-004 | Foundational | S | Reviewer | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1` | planned |
| T007 | Extend version CLI regression coverage for alias parity and warning suppression | FR-001, FR-002, SC-001, SC-002, SC-006, TG-001 | US1 | M | Implementer | `tests/integration/validate-versions-cli-behavior.ps1` | planned |
| T008 | Extend start/init recovery regression coverage for missing catalog behaviors | FR-004, FR-005, SC-003, SC-006, TG-001 | US1 | M | Implementer | `tests/integration/start-recovery-flow.tests.ps1` | planned |
| T009 | Add top-level `--version` and `-v` routing parity through canonical behavior | FR-001, SC-001, TG-001 | US1 | S | Implementer | `scripts/specrew.ps1` | planned |
| T010 | Gate version warning emission to true unknown states only | FR-002, SC-002, TG-001 | US1 | S | Implementer | `scripts/specrew-version.ps1` | planned |
| T011 | Implement start missing skill-catalog auto-repair continuation flow | FR-004, SC-003, TG-001 | US1 | M | Implementer | `scripts/specrew-start.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T012 | Implement init non-force deployable-gap continuation flow | FR-005, SC-003, TG-001 | US1 | M | Implementer | `scripts/specrew-init.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T013 | Implement init force deployable-gap continuation without false success | FR-005, SC-003, TG-001 | US1 | M | Implementer | `scripts/specrew-init.ps1`, `scripts/internal/skill-catalog-state.ps1` | planned |
| T014 | Update CLI behavior contract for implemented command expectations | FR-001, FR-002, FR-004, FR-005, SC-001, SC-002, SC-003, TG-001 | US1 | S | Reviewer | `specs/045-v0271-bugfix-bundle/contracts/cli-behavior-contract.md` | planned |
| T015 | Run version/start regression suites and record quality evidence | SC-001, SC-002, SC-003, SC-006, TG-001 | US1 | S | Reviewer | `tests/integration/validate-versions-cli-behavior.ps1`, `tests/integration/start-recovery-flow.tests.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| T016 | Extend brownfield ownership regression fixtures for self-hosting classification | FR-006, SC-004, SC-006, TG-002 | US2 | M | Implementer | `tests/integration/brownfield-conflict-handling.ps1` | planned |
| T017 | Update brownfield canonical-source logic for `.squad/agents/` in self-hosting repos | FR-006, SC-004, TG-002 | US2 | M | Implementer | `extensions/specrew-speckit/scripts/brownfield-merge.ps1` | planned |
| T018 | Mirror brownfield classification fix in specify governance tree | FR-006, FR-008, SC-004, TG-002, TG-004 | US2 | S | Implementer | `.specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1` | planned |
| T019 | Record F6 closure disposition and evidence pointers | FR-003, FR-006, TG-002, TG-007 | US2 | S | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` | planned |
| T020 | Run brownfield conflict integration suite and append evidence | SC-004, SC-006, TG-002 | US2 | S | Reviewer | `tests/integration/brownfield-conflict-handling.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| T021 | Create update-guidance doc validation checklist and timing rubric | FR-007, SC-005, TG-003 | US3 | S | Doc Steward | `specs/045-v0271-bugfix-bundle/iterations/001/quality/update-guidance-review.md` | planned |
| T022 | Update getting-started update-path and risk-flag guidance | FR-007, SC-005, TG-003 | US3 | M | Doc Steward | `docs/getting-started.md` | planned |
| T023 | Update user-guide redeployment trigger guidance | FR-007, SC-005, TG-003 | US3 | M | Doc Steward | `docs/user-guide.md` | planned |
| T024 | Add stale-finding closure narrative with bounded-scope note | FR-003, FR-007, TG-003, TG-007 | US3 | S | Doc Steward | `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` | planned |
| T025 | Refresh quickstart verification walkthrough for redeploy decisions | FR-007, SC-005, TG-003 | US3 | S | Doc Steward | `specs/045-v0271-bugfix-bundle/quickstart.md` | planned |
| T026 | Execute guided doc review and capture decision-time evidence | SC-005, TG-003 | US3 | S | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/001/quality/update-guidance-review.md` | planned |
| T027 | Run mechanical checks and confirm findings/evidence artifacts | FR-008, SC-006, TG-004 | Polish | S | Reviewer | `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| T028 | Execute governance validation and record result evidence | FR-008, TG-004 | Polish | S | Reviewer | `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| T029 | Verify patch regression suites pass and summarize zero failing P0/P1 status | SC-006, TG-001, TG-002, TG-003 | Polish | S | Reviewer | `tests/integration/validate-versions-cli-behavior.ps1`, `tests/integration/start-recovery-flow.tests.ps1`, `tests/integration/brownfield-conflict-handling.ps1`, `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| T030 | Update v0.27.1 patch notes with bundle closure summary and stale-finding references | FR-003, FR-008, TG-006, TG-007 | Polish | S | Doc Steward | `CHANGELOG.md` | planned |

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
- Status updated to `executing` after full T001-T030 ledger decomposition and branch-alignment correction.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
- Effort conversion for capacity math: S=1 story point, M=2 story points (20xS + 10xM = 40 planned points).