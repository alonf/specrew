# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 6/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers Proposal 086 Pillar 1 — validator result memoization cache. Edit-validate-edit loops drop from ~30s to <100ms on cache hits.

**Target User Stories**: US-1 through US-4
**Success Criteria**: Cache hit fast path < 100ms; iteration content change invalidates per-entry; validator code change wipes cache; `-NoCacheRead` flag works; cache is gitignored.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Get-ValidatorCacheKey helper | ✅ T002 | Implementer |
| FR-002 | Get-ValidatorCacheEntry helper | ✅ T002 | Implementer |
| FR-003 | Set-ValidatorCacheEntry helper (LRU) | ✅ T002 | Implementer |
| FR-004 | Get-ValidatorCodeHash helper | ✅ T002 | Implementer |
| FR-005 | Validator cache integration | ✅ T004 | Implementer |
| FR-006 | -NoCacheRead switch | ✅ T005 | Implementer |
| FR-007 | .gitignore entry | ✅ T005 | Implementer |
| FR-008 | Mirror parity | ✅ T007 | Implementer |
| FR-009 | Integration tests | ✅ T006 | Test Owner |
| FR-010 | CHANGELOG entry | ✅ T008 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 through FR-010 |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements |
| **Ownership** | ✅ PASS | Implementer / Test Owner / Spec Steward |
| **Capacity** | ✅ PASS | 6 SP within 20 SP iteration capacity (30%) |
| **Terminology** | ✅ PASS | All new prose uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-context | Verify implementation context | All FRs (orientation) | All US | 0.25 | Spec Steward | done |
| t002-cache-helpers | Add 4 cache helpers (key, read, write, code-hash) | FR-001..FR-004 | US-1, US-2, US-3 | 2.0 | Implementer | done |
| t003-resolve-cache-path | Add .specrew/.cache/ path resolution helper | FR-002, FR-003 | US-1 | 0.25 | Implementer | done |
| t004-validator-integration | Integrate cache lookup into validator iteration loop | FR-005 | US-1 | 1.5 | Implementer | done |
| t005-nocache-gitignore | -NoCacheRead flag + .gitignore entry | FR-006, FR-007 | US-3, US-4 | 0.5 | Implementer | done |
| t006-tests | Integration tests for cache behavior | FR-009 | All US | 1.5 | Test Owner | done |
| t007-mirror-parity | Mirror parity sweep | FR-008 | All | 0.25 | Implementer | done |
| t008-closeout | CHANGELOG + INDEX + closeout artifacts | FR-010 | All | 0.5 | Spec Steward | done |
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
**Recognized Stack**: PowerShell + JSON (cache file)

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| 4 cache helpers present (+ mirror) | structural | `extensions/specrew-speckit/scripts/shared-governance.ps1` | pending |
| Validator integration in main flow | structural | `extensions/specrew-speckit/scripts/validate-governance.ps1` | pending |
| -NoCacheRead flag works | integration | `tests/integration/validator-memoization.tests.ps1` | pending |
| Cache hit fast path | integration | same | pending |
| Cache invalidation correctness | integration | same | pending |
| .gitignore prevents cache commits | structural | `.gitignore` | pending |
| Mirror parity preserved | structural | `Compare-Object` between primary and mirror | pending |

---

## Deferred Out of Scope

- Cross-developer cache sharing (out of scope per spec.md)
- Per-rule memoization (Pillar 2 territory)
- TTL or manual purge (LRU eviction is sufficient at 500 entries)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
