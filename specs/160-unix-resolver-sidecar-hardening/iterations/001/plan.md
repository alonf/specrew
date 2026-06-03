# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 19.5/20 story_points
**Started**: 2026-06-03
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
| FR-001 | Create resolver-path repro evidence before any resolver change | US1 |
| FR-002 | Prove embedded-backslash semantics via Unix/macOS PowerShell or deterministic fixture | US1 |
| FR-003 | Use separator-safe path construction only if confirmed | US1 |
| FR-004 | Windows + Unix regression coverage only after a confirmed resolver fix | US1 |
| FR-005 | Create managed-refresh fixture covering deploy-squad-runtime + mirrors | US2 |
| FR-006 | Prove marker creation and recognition correctness | US2 |
| FR-007 | Fix only marker-controlled refresh/preserve behavior if confirmed broken | US2 |
| FR-008 | Refresh + preserve regression coverage only after a confirmed sidecar fix | US2 |
| FR-009 | Record not-confirmed evidence and change nothing for unreproduced findings | US3 |
| FR-010 | No push, no unrelated-file churn, docs only on confirmed behavior change | US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Classify dirty tree; record unrelated files to exclude | FR-010 | US3 | 0.5 | Implementer | — | done | claude | — | accepted |
| T002 | Create Iteration 001 evidence note with two finding headings | FR-001 | US3 | 0.5 | Spec Steward | `specs/160-unix-resolver-sidecar-hardening/iterations/001/**` | done | claude | — | accepted |
| T003 | Inspect resolver path surfaces; record candidate expressions | FR-002 | US1 | 1.0 | Implementer | `Specrew.psm1`, `scripts/specrew.ps1` | done | claude | — | accepted |
| T004 | Add deterministic resolver path-semantics probe (pre-fix) | FR-002 | US1 | 2.0 | Implementer | `tests/integration/unix-resolver-path-semantics.tests.ps1` | done | claude | — | accepted |
| T005 | Run resolver probe; record confirmed/not-confirmed/blocked | FR-001 | US1 | 1.0 | Reviewer | `tests/integration/unix-resolver-path-semantics.tests.ps1` | done | claude | — | accepted |
| T006 | Inspect managed-refresh + marker surfaces; record files | FR-006 | US2 | 1.0 | Implementer | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, `hosts/**` | done | claude | — | accepted |
| T007 | Add direct deploy-logic fixture for marker create/recognize | FR-005 | US2 | 2.5 | Implementer | `tests/integration/managed-runtime-sidecar.tests.ps1` | done | claude | — | accepted |
| T008 | Run sidecar fixture; record confirmed/not-confirmed/blocked | FR-005 | US2 | 1.0 | Reviewer | `tests/integration/managed-runtime-sidecar.tests.ps1` | done | claude | — | accepted |
| T009 | No-blind-fix gate: verify dispositions; activate/skip fixes | FR-009 | US3 | 1.0 | Reviewer | `specs/160-unix-resolver-sidecar-hardening/iterations/001/**` | done | claude | — | accepted |
| T010 | Conditional resolver fix (only if confirmed) | FR-003 | US1 | 1.5 | Implementer | `Specrew.psm1`, `scripts/specrew.ps1` | done | claude | — | accepted |
| T011 | Conditional resolver regression proof (only if T010 ran) | FR-004 | US1 | 1.0 | Reviewer | `tests/integration/unix-resolver-path-semantics.tests.ps1` | done | claude | — | accepted |
| T012 | Conditional sidecar fix (only if confirmed broken) | FR-007 | US2 | 1.5 | Implementer | `hosts/**`, `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | done | claude | — | accepted |
| T013 | Conditional sidecar regression proof (only if T012 ran) | FR-008 | US2 | 1.0 | Reviewer | `tests/integration/managed-runtime-sidecar.tests.ps1` | done | claude | — | accepted |
| T014 | Conditional docs update (only on confirmed behavior change) | FR-010 | US3 | 1.0 | Spec Steward | `docs/**`, `README.md` | done | claude | — | accepted |
| T015 | Run focused tests + governance validation; record results | FR-010 | US3 | 1.0 | Reviewer | `tests/integration/**` | done | claude | — | accepted |
| T016 | Assemble review evidence + final dispositions | FR-009 | US3 | 0.75 | Reviewer | `specs/160-unix-resolver-sidecar-hardening/iterations/001/**` | done | claude | — | accepted |
| T017 | Update drift log on scope/environment/source divergence | FR-009 | US3 | 0.5 | Spec Steward | `specs/160-unix-resolver-sidecar-hardening/iterations/001/drift-log.md` | done | claude | — | accepted |
| T018 | Complete reviewer readiness before review signoff | FR-010 | US3 | 0.75 | Reviewer | `specs/160-unix-resolver-sidecar-hardening/iterations/001/**` | done | claude | — | accepted |

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

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator (single-agent runtime: all delegated to claude).
- Technology and scope signals: PowerShell module resolver + host-runtime deploy surfaces; two independent investigation slices (resolver path, managed-refresh sidecar).
- Task dependency graph: resolver chain T003->T004->T005 and sidecar chain T006->T007->T008 are independent after T001/T002; both converge at the T009 no-blind-fix gate before any conditional fix.
- Workstream separability: the two investigation slices use separate fixtures and disjoint owner file globs, so they are safely separable. The runtime is single-agent, so they execute serially without same-specialty parallel expansion.
- Shared-surface conflict risk: low — resolver tasks own `Specrew.psm1`/`scripts/specrew.ps1`; sidecar tasks own `hosts/**`/`deploy-squad-runtime.ps1`. No overlapping owner globs.
- Prior reviewer ownership/hotspot evidence: this is an F-140 fast-follow; F-140 ran the install/launch path but did not run the resolver path/marker fixtures, so no prior reviewer hotspot for these exact surfaces.
- Recommendation: keep the work serial under the single-agent runtime. Conditional fix tasks stay inert until the T009 gate activates them per confirmed disposition.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Planning completed at plan/tasks boundaries; no in-iteration planning SP |
| Discovery/Spikes | 9.5 | T001-T009: hygiene, evidence note, both investigations, no-blind-fix gate |
| Implementation | 5.0 | T010, T012 conditional fixes + T011, T013 conditional regression proofs |
| Review | 2.0 | T016 review evidence + T018 reviewer readiness |
| Rework | 3.0 | T014 docs + T015 validation + T017 drift buffer for confirmed-fix follow-through |

## Phase 2 Hardening and Lens Activation

This iteration carries Phase 2 hardening scope because runtime deployment writes
agent/runtime files that may be user-owned, and the resolver decides whether stale
installed-module code runs. The hardening gate and lens activation below are the
required Phase 2 evidence surfaces for this iteration.

- **Hardening gate**: `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/hardening-gate.md`
- **Quality evidence**: `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/quality-evidence.md`
- **Mechanical findings**: `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/mechanical-findings.json`

### Lens Activation Plan

| Lens Ref | Activation | Evidence |
| -------- | ---------- | -------- |
| `security-baseline@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/lenses/test-integrity.md` |

## Traceability Summary

- Requirement scope for this iteration: FR-001 through FR-010 (TG-001..TG-005 governed via spec + this plan).
- User stories represented in current scope: US1 (resolver path), US2 (managed refresh marker), US3 (close unconfirmed without fixes).
- Detailed task-to-requirement mapping lives in `../../tasks.md` Traceability Matrix; every task above carries a requirement ref and owner.
- Overcommit guardrail: 19.5 planned SP <= 20 capacity; no deferral required. Conditional fix SP (T010-T013, 5.0 SP) is evidence-skipped rather than repurposed if a finding is not confirmed.

## Notes

- This iteration is investigation-first. A valid, complete outcome includes zero
  shipped behavior change if neither suspicion reproduces (spec Assumption #1, US3).
- Capacity line counts the full 19.5 SP including conditional fix capacity. Skipped
  conditional tasks reduce actual consumed effort recorded at retro; they are not
  reallocated to speculative work.
- Keep Status: planning until the before-implement gate is approved and execution
  starts, at which point Status moves to executing.
- Conditional fix tasks (T010-T013) remain inert until the T009 no-blind-fix gate
  activates the corresponding finding as confirmed.
