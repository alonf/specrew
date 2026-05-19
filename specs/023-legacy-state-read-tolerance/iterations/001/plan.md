# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 17/20 story_points
**Started**: 2026-05-19
**Completed**:

## Scope Summary

This iteration plan now reflects the active execution state for Feature 023 after the AI-owned implementation tasks landed. The remaining work is the bounded set of human-owned review and approval tasks recorded in `tasks.md`.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | System MUST add an explicit `schema: v1` field to every Specrew-managed state file written after this feature ships | — |
| FR-002 | System MUST treat any state file lacking a schema field as schema version 0 (v0) for backward compatibility | — |
| FR-003 | System MUST distinguish between extension content version and schema version in file:///[project]/.specify/extensions/specrew-speckit/extension.yml | — |
| FR-004 | System MUST use hashtable-based data structures (not PSCustomObject) when parsing JSON and YAML state files | — |
| FR-005 | System MUST NOT throw exceptions when accessing optional fields that don't exist in a state file | — |
| FR-006 | System MUST provide schema-version-aware dispatch logic when reader behavior differs between v0 and v1+ | — |
| FR-007 | System MUST maintain a test fixture corpus under file:///C:/Dev/Specrew/tests/fixtures/legacy-versions/ containing representative state files from each shipped Specrew version (0.18.0, 0.19.0, 0.20.0, 0.21.0, 0.22.0, and future versions) | — |
| FR-008 | System MUST execute all state reader functions against all legacy fixtures in continuous integration (CI) on every pull request | — |
| FR-009 | System MUST add a new fixture directory when any feature bumps a schema version | — |
| FR-010 | System MUST provide a validator rule (gap #11 extending Proposal 004) that enforces hashtable-based JSON parsing in state readers | — |
| FR-011 | Validator rule MUST provide clear violation messages with remediation guidance | — |
| FR-012 | System MUST provide documentation at file:///C:/Dev/Specrew/docs/data-contracts.md explaining schema versioning discipline, reader tolerance principles, and how to add new fixtures | — |
| FR-013 | System MUST update the feature closeout template to include a reminder: "If this feature modified any state file schema, add a legacy fixture for the current Specrew version" | — |
| FR-014 | System MUST test all reader changes on both Windows and Linux explicitly | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T009-T014 | Schema markers for active state writers | FR-001, FR-003 | US-1, US-3 | 3.0 | Implementer | `scripts/**`, `.specify/extensions/**`, `extensions/**` | done | Implementer | AI | pass |
| T021-T024 | Legacy reader regression lane + Linux CI | FR-002, FR-008, FR-014 | US-1, US-2 | 2.5 | Implementer | `tests/**`, `.github/workflows/**` | done | Implementer | AI | pass |
| T025-T027 | Reader-tolerance validator rule + CI enforcement | FR-010, FR-011 | US-1 | 2.5 | Implementer | `.specify/extensions/**`, `extensions/**`, `.github/workflows/**` | done | Implementer | AI | pass |
| T029, T031 | Data-contracts doc + closeout reminder | FR-012, FR-013 | US-3 | 1.5 | Implementer | `docs/**`, `.specify/templates/**`, `templates/specify/**` | done | Implementer | AI | pass |
| T020, T028, T030, T034 | Fixture / validator / docs / dispatch reviews | FR-006, FR-007, FR-010, FR-012 | US-1, US-2, US-3 | 3.0 | Human Steward | `specs/023-legacy-state-read-tolerance/**`, `docs/**` | done | Human Steward | Human | pass |

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
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: execution is effectively serial at this point because only the human-owned review tasks remain.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | complete | Feature-level planning artifacts were generated before execution started |
| Discovery/Spikes | complete | Reader audit and fixture corpus discovery completed during execution |
| Implementation | 17 SP complete | All AI-owned implementation tasks through T031 are complete |
| Review | pending human approvals | Remaining work is fixture, dispatch, validator, and docs review by Human Steward |
| Rework | TBD | Only needed if the pending human reviews find actionable gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014
-- User stories represented in current scope: US-1, US-2, US-3
-- Detailed execution is now tracked in `specs/023-legacy-state-read-tolerance/tasks.md`; this iteration plan is a truth surface for current state, not a pre-execution stub.
-- No scope deferral was recorded in this implementation pass; the remaining tasks are human-owned follow-through items rather than deferred requirement slices.

## Notes

- This plan was normalized after implementation to reflect the actual execution state of the iteration.
- Retro boundary reached; Status transitioned from `reviewing` to `retro`. Iteration-closeout and feature-closeout remain unopened.
- If any human review reopens implementation work, update the task rows and Phase Baseline table before proceeding.
