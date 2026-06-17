# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18.00/20 story_points
**Started**: 2026-06-17
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
| FR-001 | The feature MUST define a host-neutral | — |
| FR-002 | The feature MUST define a forced findings JSON schema that includes | — |
| FR-003 | The feature MUST compute review change-sets from `git diff` against | — |
| FR-004 | The feature MUST provide a blackboard review-thread protocol and | — |
| FR-005 | The feature MUST define editor dispositions for each finding: | — |
| FR-006 | The feature MUST define a standalone deterministic gate validator | — |
| FR-007 | The gate validator MUST treat malformed blackboard state, invalid | — |
| FR-008 | The first iteration MUST trigger inline review from the orchestrator | — |
| FR-009 | The first iteration MUST use rung 2b as the default reviewer mode: | — |
| FR-010 | The reviewer MUST be least-privilege and read-only with respect to | — |
| FR-011 | The design context supplied to the reviewer MUST include the current | — |
| FR-012 | The feature MUST add new headless-floor spawn adapter artifacts for | — |
| FR-013 | The first iteration MUST avoid editing F-184-protected hook, | — |
| FR-014 | The feature MUST make Proposal 145 review-signoff remain the final | — |
| FR-015 | The feature MUST document how Proposal 197 later graduates to | — |
| FR-016 | The feature MUST require explicit reviewer provider/model | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create additive directories `scripts/internal/continuous-co-review/`, `tests/continuous-co-r... | FR-013 | Shared | 0.25 | Architect | scripts/internal/continuous-co-review/ | planned | — | — | — |
| T002 | Add `scripts/internal/continuous-co-review/_load.ps1` to dot-source only Proposal 197 review... | FR-013 | Shared | 0.50 | Implementer | scripts/internal/continuous-co-review/_load.ps1 | planned | — | — | — |
| T003 | Add `tests/continuous-co-review/README.md` describing local Pester invocation, fixture owner... | SC-011 | Shared | 0.25 | Spec Steward | tests/continuous-co-review/README.md | planned | — | — | — |
| T004 | Add producer/consumer JSON fixtures for `ReviewRequest`, `FindingsResult`, `ReviewThread`, `... | FR-001 | Shared | 0.50 | Architect | ReviewRequest | planned | — | — | — |
| T005 | Add Pester contract tests in `tests/continuous-co-review/contracts/reviewer-contracts.Tests.... | FR-001 | Shared | 0.50 | Reviewer | tests/continuous-co-review/contracts/reviewer-contracts.Tests.ps1 | planned | — | — | — |
| T006 | Implement `scripts/internal/continuous-co-review/reviewer-contracts.ps1` with schema loading... | FR-001 | Shared | 0.50 | Architect | scripts/internal/continuous-co-review/reviewer-contracts.ps1 | planned | — | — | — |
| T007 | Add forced-findings Pester coverage in `tests/continuous-co-review/contracts/findings-result... | FR-002 | Shared | 0.25 | Reviewer | tests/continuous-co-review/contracts/findings-result.Tests.ps1 | planned | — | — | — |
| T008 | Add forced-findings helper functions to `scripts/internal/continuous-co-review/reviewer-cont... | FR-002 | Shared | 0.25 | Implementer | scripts/internal/continuous-co-review/reviewer-contracts.ps1 | planned | — | — | — |
| T009 | Add infrastructure-failure fixture tests in `tests/continuous-co-review/contracts/infrastruc... | FR-007 | Shared | 0.25 | Reviewer | tests/continuous-co-review/contracts/infrastructure-failure.Tests.ps1 | planned | — | — | — |
| T010 | Implement infrastructure-failure constructors in `scripts/internal/continuous-co-review/revi... | FR-007 | Shared | 0.25 | Implementer | scripts/internal/continuous-co-review/reviewer-contracts.ps1 | planned | — | — | — |
| T011 | Add deterministic SC-006 guard test in `tests/continuous-co-review/governance/protected-surf... | SC-006 | Shared | 0.50 | Spec Steward | tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1 | planned | — | — | — |
| T012 | Add `tests/continuous-co-review/unit/checkpoint-diff-provider.Tests.ps1` covering `git diff`... | FR-003 | US1 | 0.50 | Reviewer | tests/continuous-co-review/unit/checkpoint-diff-provider.Tests.ps1 | planned | — | — | — |
| T013 | Add `tests/continuous-co-review/unit/design-context-collector.Tests.ps1` proving spec/worksh... | FR-011 | US1 | 0.50 | Reviewer | tests/continuous-co-review/unit/design-context-collector.Tests.ps1 | planned | — | — | — |
| T014 | Add `tests/continuous-co-review/unit/review-request-builder.Tests.ps1` covering `ReviewReque... | FR-001 | US1 | 0.50 | Reviewer | tests/continuous-co-review/unit/review-request-builder.Tests.ps1 | planned | — | — | — |
| T015 | Add `tests/continuous-co-review/unit/review-run-workspace-manager.Tests.ps1` covering unique... | FR-008 | US1 | 0.50 | Reviewer | tests/continuous-co-review/unit/review-run-workspace-manager.Tests.ps1 | planned | — | — | — |
| T016 | Add `tests/continuous-co-review/unit/review-result-normalizer.Tests.ps1` covering valid find... | FR-002 | US1 | 0.50 | Reviewer | tests/continuous-co-review/unit/review-result-normalizer.Tests.ps1 | planned | — | — | — |
| T017 | Add `tests/continuous-co-review/integration/fixture-reviewer-path.Tests.ps1` for the control... | FR-006 | US1 | 0.50 | Reviewer | tests/continuous-co-review/integration/fixture-reviewer-path.Tests.ps1 | planned | — | — | — |
| T018 | Implement `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1` to resolve a ... | FR-003 | US1 | 0.50 | Implementer | scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1 | planned | — | — | — |
| T019 | Implement `scripts/internal/continuous-co-review/design-context-collector.ps1` and `scripts/... | FR-011 | US1 | 0.50 | Spec Steward | scripts/internal/continuous-co-review/design-context-collector.ps1 | planned | — | — | — |
| T020 | Implement `scripts/internal/continuous-co-review/review-request-builder.ps1` to assemble det... | FR-001 | US1 | 0.50 | Implementer | scripts/internal/continuous-co-review/review-request-builder.ps1 | planned | — | — | — |
| T021 | Implement `scripts/internal/continuous-co-review/review-run-workspace-manager.ps1` to create... | FR-008 | US1 | 0.50 | Implementer | scripts/internal/continuous-co-review/review-run-workspace-manager.ps1 | planned | — | — | — |
| T022 | Implement `scripts/internal/continuous-co-review/review-result-normalizer.ps1` to parse stdo... | FR-002 | US1 | 0.50 | Implementer | scripts/internal/continuous-co-review/review-result-normalizer.ps1 | planned | — | — | — |
| T023 | Implement `scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1` and fixt... | SC-001 | US1 | 0.50 | Implementer | scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1 | planned | — | — | — |
| T024 | Add `tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1` for `.specrew/revie... | FR-004 | US2 | 0.50 | Reviewer | tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1 | planned | — | — | — |
| T025 | Add `tests/continuous-co-review/unit/inline-review-gate-evaluator.Tests.ps1` for pass, block... | FR-006 | US2 | 0.50 | Reviewer | tests/continuous-co-review/unit/inline-review-gate-evaluator.Tests.ps1 | planned | — | — | — |
| T026 | Add `tests/continuous-co-review/unit/non-convergence-escalation.Tests.ps1` proving the initi... | FR-005 | US2 | 0.25 | Reviewer | tests/continuous-co-review/unit/non-convergence-escalation.Tests.ps1 | planned | — | — | — |
| T027 | Implement `scripts/internal/continuous-co-review/review-blackboard-writer.ps1` to persist `R... | FR-004 | US2 | 0.50 | Implementer | scripts/internal/continuous-co-review/review-blackboard-writer.ps1 | planned | — | — | — |
| T028 | Implement `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1` as a stan... | FR-006 | US2 | 0.50 | Reviewer | scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1 | planned | — | — | — |
| T029 | Implement `scripts/internal/continuous-co-review/review-run-index-writer.ps1` to write `Revi... | FR-002 | US2 | 0.50 | Implementer | scripts/internal/continuous-co-review/review-run-index-writer.ps1 | planned | — | — | — |
| T030 | Add `tests/continuous-co-review/fixtures/dispositions/README.md` documenting accept-and-fix,... | FR-005 | US2 | 0.25 | Spec Steward | tests/continuous-co-review/fixtures/dispositions/README.md | planned | — | — | — |
| T031 | Add `tests/continuous-co-review/unit/reviewer-host-catalog.Tests.ps1` covering non-secret ho... | FR-016 | US3 | 0.50 | Reviewer | tests/continuous-co-review/unit/reviewer-host-catalog.Tests.ps1 | planned | — | — | — |
| T032 | Add `tests/continuous-co-review/unit/reviewer-host-adapter-registry.Tests.ps1` proving only ... | FR-012 | US3 | 0.25 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-registry.Tests.ps1 | planned | — | — | — |
| T033 | Add Claude adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-c... | FR-012 | US3 | 0.25 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-claude-prompt.Tests.ps1 | planned | — | — | — |
| T034 | Add Codex adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-co... | FR-012 | US3 | 0.25 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-codex-exec.Tests.ps1 | planned | — | — | — |
| T035 | Deferred to Iteration 002: add Copilot adapter fixture tests in `tests/continuous-co-review... | FR-012 | US3 | 0.00 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-copilot-prompt.Tests.ps1 | deferred | — | — | — |
| T036 | Deferred to Iteration 002: add Cursor adapter fixture tests in `tests/continuous-co-review/... | FR-012 | US3 | 0.00 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-cursor-agent-prompt.Tests.ps1 | deferred | — | — | — |
| T037 | Deferred to Iteration 002: add Antigravity adapter fixture tests in `tests/continuous-co-re... | FR-012 | US3 | 0.00 | Reviewer | tests/continuous-co-review/unit/reviewer-host-adapter-antigravity-prompt.Tests.ps1 | deferred | — | — | — |
| T038 | Add `tests/continuous-co-review/unit/reviewer-execution-engine.Tests.ps1` covering synchrono... | FR-009 | US3 | 0.50 | Reviewer | tests/continuous-co-review/unit/reviewer-execution-engine.Tests.ps1 | planned | — | — | — |
| T039 | Add `tests/continuous-co-review/unit/fresh-context-readonly-boundary.Tests.ps1` proving revi... | FR-009 | US3 | 0.25 | Reviewer | tests/continuous-co-review/unit/fresh-context-readonly-boundary.Tests.ps1 | planned | — | — | — |
| T040 | Implement `scripts/internal/continuous-co-review/reviewer-host-catalog.ps1`, `scripts/intern... | FR-016 | US3 | 0.50 | Implementer | scripts/internal/continuous-co-review/reviewer-host-catalog.ps1 | planned | — | — | — |
| T041 | Implement `scripts/internal/continuous-co-review/reviewer-execution-engine.ps1` and `scripts... | FR-008 | US3 | 0.50 | Implementer | scripts/internal/continuous-co-review/reviewer-execution-engine.ps1 | planned | — | — | — |
| T042 | Implement phase-1 Claude and Codex real headless adapter files; defer Copilot/Cursor/Antigr... | FR-012 | US3 | 0.50 | Implementer | scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1; scripts/internal/continuous-co-review/reviewer-host-adapter-codex-exec.ps1 | planned | — | — | — |
| T043 | Implement `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1` to wire... | FR-008 | US3 | 0.50 | Implementer | scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1 | planned | — | — | — |
| T044 | Add `tests/continuous-co-review/integration/continuous-co-review-spine.Tests.ps1` to run the... | FR-001 | Shared | 0.25 | Reviewer | tests/continuous-co-review/integration/continuous-co-review-spine.Tests.ps1 | planned | — | — | — |
| T045 | Add `specs/197-continuous-co-review/quality/iteration-001-quality-evidence.md` summarizing `... | FR-014 | Shared | 0.25 | Spec Steward | specs/197-continuous-co-review/quality/iteration-001-quality-evidence.md | planned | — | — | — |
| T046 | Run `pwsh -NoProfile -Command "Invoke-Pester -Path tests/continuous-co-review"` and record a... | SC-001 | Shared | 0.25 | Reviewer | pwsh -NoProfile -Command "Invoke-Pester -Path tests/continuous-co-review" | planned | — | — | — |
| T047 | Run the SC-006 guard from `tests/continuous-co-review/governance/protected-surface-guard.Tes... | SC-006 | Shared | 0.25 | Spec Steward | tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1 | planned | — | — | — |
| T048 | Update this file `specs/197-continuous-co-review/tasks.md` only if implementation re-plannin... | SC-011 | Shared | 0.00 | Planner | specs/197-continuous-co-review/tasks.md | planned | — | — | — |

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
- Task dependency graph: Phase 1 setup precedes foundational contracts and the SC-006 guard; user stories depend on the contract spine; polish follows selected story scope.
- Workstream separability: Approved task decomposition identifies 24 parallel-safe Iteration 001 tasks after the dependency spine is satisfied; baseline roles remain sufficient for Iteration 001.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.75 | Task generation, traceability, capacity, and boundary synchronization |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | 18.00 | Approved task spine after deferring lower-priority Copilot/Cursor/Antigravity adapter breadth to Iteration 002 |
| Review | TBD | Review effort will be recorded from execution evidence and Proposal 145 signoff |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for Iteration 001: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016
- User stories represented in current scope: US1, US2, US3, plus shared setup/foundational/polish work.
- Task decomposition: 48 tasks in specs/197-continuous-co-review/tasks.md, with 45 planned for Iteration 001 and T035, T036, and T037 deferred to Iteration 002; all tasks remain mapped to at least one FR/SC and implementation-rules.yml.
- Capacity guardrail: planned Iteration 001 task effort is 18.00 SP after the approved lower-priority real-adapter breadth deferral.

## Notes

- This plan mirrors the approved tasks boundary and remains in planning status until before-implement authorization.
- Task rows are summarized from tasks.md; tasks.md remains the detailed execution checklist.
- Keep Status: planning until the plan is fully decomposed and approved.
- Feature-local capacity status: 18.00/18 SP meets the approved Iteration 001 spine budget after the human-approved deferral of T035, T036, T037, and Copilot/Cursor/Antigravity implementation breadth from T042 to Iteration 002.
