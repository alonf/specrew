# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 4/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers Proposal 086 Pillar 5 — Validator Repetition Detector. Logs invocations; warns on 3rd consecutive identical (target_hash, code_hash). Pillars 2/3/4 of Proposal 086 deferred to follow-up features.

**Target User Stories**: US-1 through US-3
**Success Criteria**: helpers present + idempotent + FIFO; validator emits warning on 3rd consecutive identical invocation; corrupt log handled gracefully.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Add-SpecrewCommandInvocation (JSONL + FIFO + lock) | ✅ T001 | Implementer |
| FR-002 | Get-SpecrewRecentCommandInvocations | ✅ T001 | Implementer |
| FR-003 | Test-SpecrewCommandRepetition | ✅ T001 | Implementer |
| FR-004 | Validator entry logs + warns | ✅ T002 | Implementer |
| FR-005 | Detector failure non-fatal | ✅ T002 | Implementer |
| FR-006 | Target+code hash composition | ✅ T002 | Implementer |
| FR-007 | Mirror parity | ✅ T002 | Implementer |
| FR-008 | Integration tests | ✅ T003 | Test Owner |
| FR-009 | CHANGELOG entry | ✅ T004 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001..FR-009 |
| **Traceability** | ✅ PASS | Each task maps to specific FRs |
| **Ownership** | ✅ PASS | Implementer + Test Owner + Spec Steward |
| **Capacity** | ✅ PASS | 4 SP within 20 SP capacity (20%) |
| **Terminology** | ✅ PASS | Uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-helpers | Add 4 repetition-detector helpers | FR-001..FR-003 | US-2, US-3 | 1.5 | Implementer | done |
| t002-validator-integration | Validator entry logs + warns + non-fatal try/catch | FR-004..FR-007 | US-1, US-3 | 1.0 | Implementer | done |
| t003-tests | Integration tests | FR-008 | All | 1.0 | Test Owner | done |
| t004-changelog | CHANGELOG + INDEX + proposal status | FR-009 | All | 0.25 | Spec Steward | done |
| t005-pr-merge | PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 4.0 SP

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 4 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.validator-performance`
**Recognized Stack**: PowerShell + JSON Lines

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| 4 helpers present (+ mirror) | structural | shared-governance.ps1 | pending |
| Validator entry integration | structural | validate-governance.ps1 | pending |
| Detector failure non-fatal | integration | tests/integration/validator-repetition-detector.tests.ps1 | pending |
| FIFO eviction at 20 | integration | same | pending |
| Repetition count correctness | integration | same | pending |
| Mirror parity | structural | Compare-Object | pending |

---

## Deferred Out of Scope

- Pillars 2, 3, 4 of Proposal 086 (future feature; this PR ships only Pillar 5)
- Auto-suggesting `-NoCacheRead` based on detection
- Cross-CI repetition tracking

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
