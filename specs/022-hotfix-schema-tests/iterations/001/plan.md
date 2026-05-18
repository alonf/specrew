# Iteration Plan: 001

**Schema**: v1
**Feature**: 022-hotfix-schema-tests  
**Branch**: 022-hotfix-schema-tests  
**Status**: planning
**Capacity**: 9/20 story_points
**Started**: 2026-05-18
**Completed**:
**Created**: 2026-05-18  
**Updated**: 2026-05-18

## Overview

Iteration 001 is the only authorized delivery slice for Feature 022. It keeps the hotfix bounded to the three confirmed restart defects plus regression coverage and stops at the plan-completion boundary for human review.

**Scope**: FR-001 through FR-019 inside one iteration only. This artifact allocates execution capacity and grouped work packages, but it does **not** open `/speckit.tasks` or implementation by itself.

## Task Summary

Primary planned scope: **9.0 SP**  
Repair reserve: **1.0 SP**  
Locked capacity ceiling: **10.0 SP**

Total grouped work packages: 5  
Total effort estimate: 9.0 Story Points (+ 1.0 SP repair reserve)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| I1-W001 | Scope lock, contracts, and stewardship-role reconciliation | FR-005, FR-014, FR-016..FR-019 | US1, US2, US3 | 1.0 | Spec Steward | `specs/022-hotfix-schema-tests/**`, `.squad/decisions.md` | planned | Spec Steward | 0.0 | PLANNED |
| I1-W002 | Closeout identity schema parity repair | FR-001..FR-004, FR-010 | US3 | 2.0 | Implementer | `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, `scripts/internal/sync-boundary-state.ps1`, `.squad/identity/now.md` | planned | Implementer | 0.0 | PLANNED |
| I1-W003 | Seven-boundary sync restoration and observability | FR-006..FR-010 | US2 | 2.5 | Implementer | `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md`, `scripts/internal/sync-boundary-state.ps1`, `.squad/decisions.md` | planned | Implementer | 0.0 | PLANNED |
| I1-W004 | Restart recovery UX and `--recover` lane | FR-011..FR-015 | US1 | 2.0 | Implementer | `scripts/specrew-start.ps1`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md` | planned | Implementer | 0.0 | PLANNED |
| I1-W005 | Standalone regression suites and hardening evidence | FR-004, FR-009, FR-015, SC-001..SC-005 | US1, US2, US3 | 1.5 | Reviewer | `tests/integration/*.ps1`, `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md` | planned | Reviewer | 0.0 | PLANNED |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used for the hotfix capacity lock, grouped work packages, and later retro variance |
| Capacity per Iteration | 20 | Repository default from `.specrew/iteration-config.yml` |
| Feature Slice Capacity | 10.0 | Human-locked capacity for this single-iteration hotfix |
| Planned Effort | 9.0 | Primary work before repair reserve |
| Repair Reserve | 1.0 | Explicit reserve held inside the 10 SP ceiling |
| Iteration Bounding | scope | Feature 022 stays single-iteration only |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No silent widening beyond the 10 SP slice |
| Defer Strategy | manual | Any deferral must stay inside approved scope and must not open Iteration 002 |
| Calibration Enabled | true | Retro should compare actual delivery against the locked 10 SP slice |
| Repair Policy | 3 cycles | Feature 021 carry-forward default remains active |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Governance and contract reconciliation | 1.0 | Role mapping, scope lock, hardening gate planning, Proposal 054 alignment notes |
| Runtime hotfix delivery | 6.5 | Closeout schema writer, boundary wiring, restart recovery flow |
| Regression and review evidence | 1.5 | Three standalone PowerShell integration scripts and hardening-gate evidence |
| Rework reserve | 1.0 | Bounded quality repair only; no scope growth |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Stewardship labels remain descriptive only; execution ownership is intentionally mapped onto the baseline roster.
- Workstream separability exists between governance/contracts, runtime repair, and regression evidence, but W002 through W004 still overlap on shared session-state and restart surfaces.
- Shared-surface conflict risk is elevated across `scripts/internal/sync-boundary-state.ps1`, `scripts/specrew-start.ps1`, and `.squad/identity/now.md`; keep runtime work serial unless a later task breakdown proves safe isolation.
- Recommendation: keep the hotfix serial through grouped planning and allow parallelism only if later executable tasks preserve the owner globs above without reopening scope.

## Scope Guardrails

- **Single iteration only**: do not open Iteration 002.
- **Three confirmed bugs only**: keep Feature 022 bounded to schema parity, seven-boundary sync, and restart recovery UX plus regression coverage.
- **Deferred items stay deferred**: do not reopen FR-005 broader schema auditing or FR-019 inbox-to-ledger / Scribe follow-up.
- **Stewardship labels are descriptive**: planning artifacts map them onto baseline Squad roles instead of expanding the roster.
- **Standalone regression scripts are mandatory**: plan FR-004, FR-009, and FR-015 as `tests/integration/closeout-identity-schema-parity.tests.ps1`, `tests/integration/lifecycle-boundary-sync.tests.ps1`, and `tests/integration/start-recovery-flow.tests.ps1`.
- **Carry-forward defaults stay active**: push after every commit, pre-handoff origin verification, pre-handoff artifact checks, live bookkeeping, and the 3-cycle repair policy remain mandatory.
- **Hardening scaffold is mandatory**: `iterations/001/quality/hardening-gate.md` remains the canonical pre-implementation quality gate artifact.

## Authorization

- **Planning approval**: Alon Fliess authorized Feature 022 planning.
- **Clarify handoff**: planning starts from the accepted clarify-completion state already recorded for Feature 022.
- **Scope source**: `specs/022-hotfix-schema-tests/spec.md` remains authoritative for this iteration plan.
- **Boundary stop**: stop at plan completion and wait for fresh human authorization before `/speckit.tasks`.

## Notes

- This plan intentionally uses grouped work packages instead of executable tasks so the planning boundary remains intact.
- The baseline-role mapping in `specs/022-hotfix-schema-tests/plan.md` is the authoritative stewardship-label interpretation for implementation planning.
- The hardening gate currently records planning-time analysis only; runtime evidence remains pending.
