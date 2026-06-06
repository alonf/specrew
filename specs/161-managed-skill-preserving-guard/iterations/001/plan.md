# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 8/20 story_points
**Started**: 2026-06-06
**Completed**: 2026-06-06

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
| FR-001 | Deterministic, re-runnable, deploy-level repro harness in a temp sandbox | US1 |
| FR-002 | Scenarios: marker-present, user-authored, current-canonical, stale-canonical probe | US1 |
| FR-003 | Recorded CONFIRMED/REFUTED verdict with exact code-path citation | US1, US3 |
| FR-004 | Conditional narrow provenance-authoritative fix (only if CONFIRMED) | US2 |
| FR-005 | User-authored skills preserved (byte-identical) in every state | US2, US3 |
| FR-006 | Tests cover refresh-managed + preserve-user-edited; F-160 fixture unchanged | US3 |
| FR-007 | Scope guard: no F-141/F-159/F-160 edits; no release/tag/merge/PR/push-to-main | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Boundary hygiene verification + scope-guard record | FR-007 | US3 | 0.5 | Spec Steward | — | done | claude | — | — |
| T002 | Iteration evidence note (scenarios, reachability, verdict headings) | FR-003 | US3 | 0.5 | Spec Steward | — | done | claude | — | — |
| T003 | Deploy-level repro harness S1–S6 (`managed-skill-stuck-preserving.tests.ps1`) | FR-001, FR-002 | US1 | 2 | Implementer | `tests/integration/managed-skill-stuck-preserving.tests.ps1` | done | claude | — | — |
| T004 | Reachability analysis from template + deploy-script git history | FR-003 | US1 | 1 | Implementer | — | done | claude | — | — |
| T005 | Verdict record (probe outcome × reachability) — gates T006/T007 | FR-003 | US1 | 1 | Reviewer | — | done | claude | — | — |
| T006 | Conditional narrow classification fix + `.specify` mirror parity | FR-004 | US2 | 2 | Implementer | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, `.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | done | claude | — | — |
| T007 | Conditional pre/post fix evidence; S4 probe → regression assertion | FR-004, FR-005 | US2 | 0.5 | Implementer | `tests/integration/managed-skill-stuck-preserving.tests.ps1` | done | claude | — | — |
| T008 | Regression set: harness ×2, F-160 fixture, mechanical checks, validator | FR-005, FR-006 | US3 | 1 | Implementer | — | done | claude | — | — |
| T009 | Review evidence assembly + scope-guard proof + briefing | FR-003, FR-007 | US3 | 0.5 | Reviewer | — | done | claude | — | — |

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
- Technology and scope signals: single-surface PowerShell deploy-logic investigation; one
  implementer owns the harness and any conditional fix.
- Task dependency graph: strictly serial through the verdict gate
  (T001→T002→{T003,T004}→T005→[T006→T007]→T008→T009); T003 and T004 are the only
  safely parallel pair (disjoint surfaces: new test file vs git-history reading).
- Workstream separability: no safe same-specialty parallelism beyond T003∥T004; no
  Junior/Senior expansion proposed at 8 SP.
- Shared-surface conflict risk: none — conditional fix surface (deploy script + mirror) is
  exclusive to T006.
- Prior reviewer ownership/hotspot evidence: F-160 review owned the same deploy-script surface;
  its fixture is the regression guard here.
- Recommendation: keep serial execution with the single T003∥T004 exception.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 SP | Feature-level spec/plan/tasks complete; this iteration plan + hardening gate |
| Discovery/Spikes | 3 SP | T003 harness + T004 reachability (the investigation IS the discovery) |
| Implementation | 2.5 SP | Conditional T006/T007 — released only by CONFIRMED verdict |
| Review | 1.5 SP | T005 verdict + T008 regression + T009 evidence |
| Rework | 0 SP | Buffer absorbed by the conditional budget when verdict = REFUTED |

## Traceability Summary

- Requirement scope for this iteration: FR-001..FR-007 (FR-004 conditional)
- User stories represented in current scope: US1, US2 (conditional), US3
- specrew-traceability-check: PASS at the tasks boundary (100% FR/SC coverage, no orphans)
- Overcommit guardrail: 8/20 SP — no deferrals required.

## Notes

- T006/T007 carry Status `blocked` by design: the blocker is the T005 verdict gate
  (human instruction at tasks→before-implement approval: CONFIRMED requires
  misclassified AND reachable; misclassification alone is insufficient). On REFUTED they
  flip to `deferred` with the refutation evidence and the iteration closes at 5.5 SP consumed.
- The no-loss invariant (S2 byte-preserved in every outcome branch) is mandatory per the same
  human instruction and is enforced via the hardening gate `security-surface` concern.
- Declared capacity counts all 9 tasks (8 SP) including the conditional budget.
