# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 11/20 story_points
**Started**: 2026-05-24
**Completed**: 2026-05-24

> **Retroactive backfill disclaimer**: This iteration plan was reconstructed at closeout (2026-05-24) from git commit history, not authored live. SP estimates and Phase Baseline reflect post-hoc reconstruction matching the actual scope shipped, not real-time planning. The "Actual" column equals "Estimated" because no live tracking happened — variance is necessarily 0. Future iterations follow live SP tracking.

## Scope Summary

Implements **9 of 13 FRs** from `../../spec.md`. Category A coordinator-content migration (FR-008, FR-009, FR-011) was deliberately deferred to a follow-up slice; FR-010 (Category B stays host-native) was a design constraint honored as no-op. See [scope.md](./scope.md) for full FR allocation table.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | host-history.json schema | US1 |
| FR-002 | Host-selection priority chain | US1 |
| FR-003 | First-run probe enumerates available hosts | US1 |
| FR-004 | history update on every selection | US1 |
| FR-005 | `specrew host list` | US2 |
| FR-006 | `specrew host use <kind>` | US2 |
| FR-007 | `specrew host status` per-host install state | US2 |
| FR-012 | `host_resolution` field in start-context.json | US1 |
| FR-013 | Non-TTY guidance | US1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Spec + plan boundary artifacts | (intake) | US1, US2 | 1 | Spec Steward | specs/043-multi-host-onboarding/spec.md; plan.md | done | claude | 1 | pass |
| T002 | host-history schema + draft helpers | FR-001, FR-003 | US1 | 2 | Implementer | scripts/internal/host-history.ps1 (draft) | done | claude | 2 | pass |
| T003 | `specrew host` CLI surface | FR-005, FR-006, FR-007 | US2 | 3 | Implementer | scripts/specrew-host.ps1 | done | claude | 3 | pass |
| T004 | host-history persistence (Update-SpecrewHostHistory) | FR-004 | US1 | 2 | Implementer | scripts/internal/host-history.ps1 | done | claude | 2 | pass |
| T005 | Host-selection chain wiring in specrew-start.ps1 | FR-002, FR-012, FR-013 | US1 | 3 | Implementer | scripts/specrew-start.ps1 (host-gate block lines 3668-3745) | done | claude | 3 | pass |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Specrew project default; see `.specrew/iteration-config.yml`. |
| Iteration Bounding | scope | All 9-of-13 FRs in iteration scope; 4 deferred explicitly (see scope.md). |
| Time Limit (hours) | n/a | Scope-bounded iteration. |
| Overcommit Threshold | 1.0 | 11/20 = 0.55 — well under threshold. |
| Defer Strategy | manual | FR-008/009/011 deferred manually with rationale. |
| Calibration Enabled | true | Backfill — no live calibration data; future iterations track honestly. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- F-043 work co-evolved with F-044 (per-host architecture refactor) on the same branch; tasks here depend on F-044 Phase A-B substrate being in place (registry + handler dispatch).
- Serial execution; no Junior/Senior same-specialty pair.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | 1 | Spec + plan + tasks decomposition (T001). |
| Discovery/Spikes | 0 | No spikes; spec defaults resolved at clarify time. |
| Implementation | 10 | T002 + T003 + T004 + T005. |
| Review | 0 | Bundled into F-044 iter-001 4-agent deep review (retroactive — no live review). |
| Rework | 0 | A-1 bug introduced by T005 was caught and fixed in F-044 iter-002 (cross-feature attribution). |

## Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| F-043 implementation lenses | n/a (retroactive backfill) | n/a | n/a | No live routing decisions; work shipped before methodology was applied. |

## Traceability Summary

- Task coverage: 5 tasks cover all 9 in-scope FRs + the 2 ACs (FR-012, FR-013 testability).
- Traceability check: PASS (retroactive reconstruction matches `tasks.md` from the same iteration).
- Overcommit guardrail: 11/20 SP = 55% capacity. Well under threshold. No deferrals required at iteration-plan time; 4-FR deferral happened at spec time, not capacity time.

## Notes

- This iteration was developed on the `multi-host-integration-refactor` branch alongside F-044. Cross-feature entanglement documented in [scope.md](./scope.md) § "Cross-feature entanglement".
- The A-1 host-gate `-NoLaunch` carve-out bug was introduced by T005 (commit `755c87f1`) and incidentally fixed by F-044 iter-002. Not counted here as Rework SP because the fix lived in another feature's iteration.
- Retroactive backfill — see disclaimer above.
