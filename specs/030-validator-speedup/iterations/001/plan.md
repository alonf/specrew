# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: retro  
**Capacity**: 6/20 story_points  
**Started**: 2026-05-21  
**Completed**: 2026-05-22

## Summary

Iteration 001 captures the locked implementation review scope for Proposal 083. The implementation range is frozen at `edf4104...eeeb90e` on branch `chore-083-local-validator-speedup`; review-boundary work is limited to lifecycle truth, reviewer evidence, and governance validation.

**Primary Focus**: review-boundary truth for the local validator auto-scope slice  
**Target User Stories**: US-1 through US-4  
**Locked Implementation Commit**: `eeeb90e`

---

## Requirements Traceability

| Scope Slice | Requirement | Notes |
| --- | --- | --- |
| validator-auto-scope-core | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007 | Base-ref detection, auto-scope default, `-FullRun` override, banner output, and graceful fallback are locked in the implementation range. |
| governance-doc-sync | FR-008, FR-009, FR-011 | Coordinator guidance, Reviewer charter wording, and `CHANGELOG.md` coverage are present in the reviewed tree. |
| integration-regression-coverage | FR-010 | `tests/integration/validate-governance-changed-only.tests.ps1` covers the required local auto-scope scenarios. |
| mirror-parity-audit | FR-012 | Primary, extension, and `.specify` copies stay aligned in the reviewed diff. |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| validator-auto-scope-core | Deliver local base-ref detection, auto-scope default, `-FullRun`, and banner behavior | FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007 | US-1, US-2, US-3, US-4 | 3.0 | Implementer | done |
| governance-doc-sync | Update coordinator guidance, Reviewer charter wording, and CHANGELOG evidence | FR-008, FR-009, FR-011 | US-1, US-2 | 1.0 | Implementer | done |
| integration-regression-coverage | Extend locked integration coverage for local auto-scope, explicit flags, and fallback paths | FR-010 | US-1, US-2, US-3, US-4 | 1.5 | Test Owner | done |
| mirror-parity-audit | Confirm mirror parity across `extensions/` and `.specify/extensions/` review surfaces | FR-012 | US-1 | 0.5 | Implementer | done |

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Matches the feature-level small-fix slice planning contract. |
| Capacity per Iteration | 20 | Repository iteration-config capacity remains 20 even though this review scope uses 6 planned points. |
| Iteration Bounding | scope | Review-boundary work cannot widen implementation beyond the locked tree. |
| Time Limit (hours) | n/a | Scope-bound review packet, not a time-boxed execution lane. |
| Overcommit Threshold | 1.0 | Any widening requires explicit human re-authorization, not silent carryover. |
| Defer Strategy | manual | Iteration-closeout and later lifecycle work stay unopened until separately authorized. |
| Calibration Enabled | true | Repository iteration-config keeps retrospective calibration enabled for future capacity adjustments after this completed retro. |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | Review-scope iteration repair, traceability packaging, and governance alignment for the locked implementation range. |
| Discovery/Spikes | 0 | No separate spike was authorized for this review-boundary slice. |
| Implementation | 0 | Implementation was already locked at `edf4104...eeeb90e`; this iteration plan does not reopen code changes. |
| Review | 6 | Review-boundary evidence, governance validation, and retrospective preparation for the locked Proposal 083 slice. |
| Rework | 0 | The review verdict accepted the locked implementation without reopening implementation work. |

## Review Boundary Notes

- Review remained constrained to the committed implementation tree `edf4104...eeeb90e`; no new implementation work was authorized in this iteration plan.
- Per the human directive, review-boundary work did not rerun the Pester implementation suite while implementation evidence stayed locked.
- Retrospective is complete; iteration-closeout and feature-closeout remain unopened.

---

**Maintained by**: Reviewer  
**Last Updated**: 2026-05-21
