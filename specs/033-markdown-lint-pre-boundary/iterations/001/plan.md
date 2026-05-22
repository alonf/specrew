# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 5/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers the full scope of Proposal 088: 2 new helpers in `shared-governance.ps1` (+ mirror) + integration into `Invoke-SpecrewBoundaryStateSync` as pre-sync gate + integration tests + mirror parity + CHANGELOG + INDEX.

**Primary Focus**: Catching markdown lint violations at boundary-sync time so they never reach PR-CI Lint and cause the catch-fix-retry cycle.

**Target User Stories**: US-1 through US-4 (all P1/P2 user stories from spec.md).

**Success Criteria**: Gate auto-fixes + HALTs on auto-fixable violations; surfaces unfixable violations with file:line; graceful degradation when markdownlint-cli unavailable; auto-scoped to changed `.md` files only.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Get-ChangedMarkdownFiles helper | ✅ T002 | Implementer |
| FR-002 | Invoke-MarkdownLintAutoFix helper | ✅ T003 | Implementer |
| FR-003 | Boundary-sync pre-sync gate integration | ✅ T004 | Implementer |
| FR-004 | Gate behavior (auto-fix + HALT, unfixable + HALT) | ✅ T004 | Implementer |
| FR-005 | Graceful degradation when markdownlint-cli unavailable | ✅ T003 (in helper) | Implementer |
| FR-006 | Mirror parity | ✅ T006 | Implementer |
| FR-007 | Integration tests | ✅ T005 | Test Owner |
| FR-008 | CHANGELOG entry | ✅ T007 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 through FR-008 |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements |
| **Ownership** | ✅ PASS | Implementer / Test Owner / Spec Steward |
| **Capacity** | ✅ PASS | 5 SP within 20 SP iteration capacity (25%) |
| **Terminology** | ✅ PASS | All new prose uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-context | Verify implementation context + locate surfaces | All FRs (orientation) | All US | 0.25 | Spec Steward | done |
| t002-changed-md-helper | Add Get-ChangedMarkdownFiles helper to shared-governance.ps1 + mirror | FR-001 | US-4 | 0.5 | Implementer | done |
| t003-autofix-helper | Add Invoke-MarkdownLintAutoFix helper with graceful degradation | FR-002, FR-005 | US-1, US-2, US-3 | 1.0 | Implementer | done |
| t004-boundary-integration | Integrate pre-sync gate into Invoke-SpecrewBoundaryStateSync | FR-003, FR-004 | US-1, US-2 | 1.0 | Implementer | done |
| t005-integration-tests | Integration test suite for gate behavior | FR-007 | US-1, US-2, US-3, US-4 | 1.5 | Test Owner | done |
| t006-mirror-parity | Mirror parity sweep | FR-006 | All | 0.25 | Implementer | done |
| t007-changelog-index | CHANGELOG entry + INDEX update + closeout artifacts | FR-008 | All | 0.5 | Spec Steward | done |
| t008-pr-merge | Branch push + PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 5.25 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 5.25 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.boundary-gates`
**Recognized Stack**: PowerShell + Markdown + Node.js (markdownlint-cli via npx)

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| Get-ChangedMarkdownFiles helper present (+ mirror) | structural | `extensions/specrew-speckit/scripts/shared-governance.ps1` | pending |
| Invoke-MarkdownLintAutoFix helper present (+ mirror) | structural | same | pending |
| Boundary-sync gate integration | structural | `scripts/internal/sync-boundary-state.ps1` | pending |
| Gate auto-fixes + HALTs | integration | `tests/integration/boundary-sync-markdownlint-gate.tests.ps1` | pending |
| Gate handles unfixable violations | integration | same | pending |
| Graceful degradation when markdownlint-cli unavailable | integration | same | pending |
| Mirror parity preserved | structural | `Compare-Object` between primary and mirror | pending |

---

## Deferred Out of Scope

- Memoization composition (waits for Proposal 086 P1)
- Auto-commit of fixes (intentional design choice for audit trail)
- Pre-commit git hook (boundary-sync gate is the canonical enforcement point)
- PSScriptAnalyzer auto-fix (limited tool support)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
