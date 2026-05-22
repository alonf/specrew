# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 3/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers Proposal 089 minimal viable slice — PR review resolution artifact helper + host detection + soft validator warning. Hard-blocking lifecycle gate explicitly out of scope (follow-up).

**Target User Stories**: US-1 through US-3
**Success Criteria**: helpers present + mirror parity; host detection returns correct hashtable shape; soft warning is non-blocking + only fires under correct preconditions.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Get-SpecrewPrReviewResolutionPath helper | ✅ T001 | Implementer |
| FR-002 | Test-HostProvidesAutomatedPrReview helper | ✅ T001 | Implementer |
| FR-003 | Soft validator warning surface | ✅ T002 | Implementer |
| FR-004 | Hard-blocking explicitly out of scope | ✅ T002 | Implementer |
| FR-005 | Mirror parity | ✅ T001+T002 | Implementer |
| FR-006 | Integration tests | ✅ T003 | Test Owner |
| FR-007 | CHANGELOG entry | ✅ T004 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001..FR-007 |
| **Traceability** | ✅ PASS | Each task maps to specific FRs |
| **Ownership** | ✅ PASS | Implementer + Test Owner + Spec Steward |
| **Capacity** | ✅ PASS | 3 SP within 20 SP capacity (15%) |
| **Terminology** | ✅ PASS | Uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-helpers | Path helper + host-detection helper | FR-001, FR-002 | US-2, US-3 | 1.0 | Implementer | done |
| t002-validator-soft-warning | Validator emits non-blocking soft warning | FR-003, FR-004, FR-005 | US-1 | 1.0 | Implementer | done |
| t003-tests | Integration tests | FR-006 | All | 0.75 | Test Owner | done |
| t004-changelog | CHANGELOG + INDEX + proposal status | FR-007 | All | 0.25 | Spec Steward | done |
| t005-pr-merge | PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 3.25 SP

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 3 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.lifecycle-gate`
**Recognized Stack**: PowerShell

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| Helpers present (+ mirror) | structural | shared-governance.ps1 | pending |
| Validator soft-warning surface | structural | validate-governance.ps1 | pending |
| Soft warning non-blocking | integration | tests/integration/pr-review-integration.tests.ps1 | pending |
| Host detection logic | integration | same | pending |
| Path helper correctness | integration | same | pending |
| Mirror parity | structural | Compare-Object | pending |

---

## Deferred Out of Scope

- Hard-blocking address-pr-review boundary (follow-up)
- New sync command for the boundary (follow-up)
- Multi-host detection beyond GitHub
- Automated Copilot finding extraction
- CI enforcement

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
