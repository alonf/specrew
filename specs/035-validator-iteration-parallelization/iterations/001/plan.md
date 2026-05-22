# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 7/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers Proposal 084 — Validator Iteration Parallelization. Cold-cache validator wall-clock drops from ~22min to ~4min on 44-iteration corpus at throttle 6. Warm-cache runs preserved by serial pre-pass.

**Target User Stories**: US-1 through US-5
**Success Criteria**: cold-cache speedup ~5× at throttle 6; warm-cache no regression; deterministic output ordering; `-NoParallel` opt-out works; cache file survives concurrent writes.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Invoke-WithFileLock helper | ✅ T001 | Implementer |
| FR-002 | Set-ValidatorCacheEntry uses lock | ✅ T002 | Implementer |
| FR-003 | -NoParallel + -ThrottleLimit params | ✅ T003 | Implementer |
| FR-004 | -NoParallel falls back to serial | ✅ T003, T004 | Implementer |
| FR-005 | Pre-pass cache check | ✅ T004 | Implementer |
| FR-006 | Parallel-misses subprocess invocation | ✅ T004 | Implementer |
| FR-007 | Subprocess result capture | ✅ T005 | Implementer |
| FR-008 | Deterministic sort by path | ✅ T005 | Implementer |
| FR-009 | Mirror parity | ✅ T007 | Implementer |
| FR-010 | Integration tests | ✅ T006 | Test Owner |
| FR-011 | CHANGELOG entry | ✅ T007 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 through FR-011 |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements |
| **Ownership** | ✅ PASS | Implementer / Test Owner / Spec Steward |
| **Capacity** | ✅ PASS | 7 SP within 20 SP iteration capacity (35%) |
| **Terminology** | ✅ PASS | All new prose uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-context | Verify implementation context | All FRs (orientation) | All US | 0.25 | Spec Steward | done |
| t002-file-lock-helper | Add Invoke-WithFileLock helper | FR-001 | US-4 | 1.0 | Implementer | done |
| t003-cache-lock-wrap | Wrap Set-ValidatorCacheEntry in file lock | FR-002 | US-4 | 0.5 | Implementer | done |
| t004-validator-params | Add -NoParallel + -ThrottleLimit parameters | FR-003 | US-3, US-5 | 0.5 | Implementer | done |
| t005-parallel-loop | Pre-pass + parallel misses path | FR-004..FR-008 | US-1, US-2, US-3, US-4 | 2.5 | Implementer | done |
| t006-tests | Integration tests | FR-010 | All US | 1.5 | Test Owner | done |
| t007-mirror-changelog | Mirror parity + CHANGELOG | FR-009, FR-011 | All | 0.5 | Spec Steward | done |
| t008-closeout | INDEX + closeout artifacts | All | All | 0.25 | Spec Steward | done |
| t009-pr-merge | PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 7.0 SP

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 7 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.validator-performance`
**Recognized Stack**: PowerShell 7+ (ForEach-Object -Parallel) + JSON cache

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| Invoke-WithFileLock helper present (+ mirror) | structural | `extensions/specrew-speckit/scripts/shared-governance.ps1` | done |
| -NoParallel + -ThrottleLimit params | structural | `extensions/specrew-speckit/scripts/validate-governance.ps1` | done |
| Pre-pass + parallel path implementation | structural | same | done |
| Concurrent cache write integrity | integration | `tests/integration/validator-parallelization.tests.ps1` | done |
| -NoParallel opt-out works | integration | same | done |
| Mirror parity preserved | structural | `Compare-Object` between primary and mirror | done |

---

## Deferred Out of Scope

- In-process runspace parallelism (subprocess approach pragmatic for v1)
- Per-rule parallelization within a single iteration
- Auto-tune of ThrottleLimit
- Cross-machine distributed validation

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
