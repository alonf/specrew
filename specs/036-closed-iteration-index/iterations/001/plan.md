# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 5/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers Proposal 085 — closed-iteration index that lets validator's full-repo path skip closed iterations unless `-IncludeClosed`. Initial backfill seeded with 41 currently-closed iterations.

**Target User Stories**: US-1 through US-4
**Success Criteria**: index helpers present + idempotent; validator skips closed on full-repo; `-IncludeClosed` overrides; `-RebuildClosedIndex` regenerates; boundary sync appends at iteration-closeout.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Get-SpecrewClosedIterationIndex helper | ✅ T001 | Implementer |
| FR-002 | Add-SpecrewClosedIterationEntry helper (idempotent + file-locked) | ✅ T001 | Implementer |
| FR-003 | Test-SpecrewIterationClosed helper | ✅ T001 | Implementer |
| FR-004 | -IncludeClosed switch | ✅ T002 | Implementer |
| FR-005 | -RebuildClosedIndex switch | ✅ T002 | Implementer |
| FR-006 | Boundary sync appends at iteration-closeout | ✅ T003 | Implementer |
| FR-007 | Closed-skip filter on full-repo path | ✅ T002 | Implementer |
| FR-008 | Banner shows closed-skipped count | ✅ T002 | Implementer |
| FR-009 | Initial backfill | ✅ T004 | Implementer |
| FR-010 | Mirror parity | ✅ T005 | Implementer |
| FR-011 | Integration tests | ✅ T005 | Test Owner |
| FR-012 | CHANGELOG entry | ✅ T006 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001..FR-012 |
| **Traceability** | ✅ PASS | Each task maps to specific FRs |
| **Ownership** | ✅ PASS | Implementer + Test Owner + Spec Steward |
| **Capacity** | ✅ PASS | 5 SP within 20 SP capacity (25%) |
| **Terminology** | ✅ PASS | Uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-helpers | Add 4 closed-iteration-index helpers | FR-001..FR-003 | US-2, US-3 | 1.5 | Implementer | done |
| t002-validator-integration | -IncludeClosed + -RebuildClosedIndex + filter + banner | FR-004..FR-008 | US-1, US-3, US-4 | 1.5 | Implementer | done |
| t003-boundary-sync | iteration-closeout boundary appends to index | FR-006 | US-2 | 0.5 | Implementer | done |
| t004-backfill | Initial backfill via -RebuildClosedIndex | FR-009 | All | 0.25 | Implementer | done |
| t005-tests-mirror | Integration tests + mirror parity | FR-010, FR-011 | All | 1.0 | Test Owner | done |
| t006-changelog-index | CHANGELOG + INDEX + proposal status | FR-012 | All | 0.25 | Spec Steward | done |
| t007-pr-merge | PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 5.0 SP

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 5 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.validator-performance`
**Recognized Stack**: PowerShell + lightweight YAML

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| 4 helpers present (+ mirror) | structural | shared-governance.ps1 | pending |
| -IncludeClosed + -RebuildClosedIndex params | structural | validate-governance.ps1 | pending |
| Closed-iteration filter on full-repo path | structural | validate-governance.ps1 | pending |
| Boundary sync integration | structural | sync-boundary-state.ps1 | pending |
| Add idempotency | integration | tests/integration/closed-iteration-index.tests.ps1 | pending |
| Initial backfill present | structural | .specrew/closed-iterations.yml | pending |
| Mirror parity | structural | Compare-Object | pending |

---

## Deferred Out of Scope

- Cross-iteration validation rules opt-out path (future feature)
- CI workflow `-IncludeClosed` flag (separate small-fix slice)
- Custom git merge driver

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
