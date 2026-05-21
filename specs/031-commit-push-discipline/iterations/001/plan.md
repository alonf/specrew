# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 5/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers the full Tier 1 (text-only) scope of Proposal 082: coordinator governance prompt rule + 5 agent charter additions + user-guide section + mirror parity + verification test + CHANGELOG entry.

**Primary Focus**: Methodology-surface text edits — no runtime code changes.
**Target User Stories**: US-1 through US-5 (all P1/P2 user stories from spec.md).
**Success Criteria**: SC-001 (instructions visible in 6 files), SC-002 (rejection-cycle reduction), SC-003 (mirror parity), SC-004 (test passes).

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | Coordinator governance prompt rule | ✅ T002 | Spec Steward |
| FR-002 | Implementer charter addition | ✅ T003 | Spec Steward |
| FR-003 | Spec Steward charter addition | ✅ T004 | Spec Steward |
| FR-004 | Reviewer charter addition | ✅ T005 | Spec Steward |
| FR-005 | Retro Facilitator charter addition | ✅ T006 | Spec Steward |
| FR-006 | Planner charter addition (light) | ✅ T007 | Spec Steward |
| FR-007 | User-guide section | ✅ T008 | Spec Steward |
| FR-008 | Mirror parity | ✅ T009 | Implementer |
| FR-009 | Terminology compliance | ✅ Inline in T002-T008 | Spec Steward |
| FR-010 | Verification test | ✅ T010 | Reviewer |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 through FR-010 from spec.md |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements |
| **Ownership** | ✅ PASS | Tasks assigned to Spec Steward / Implementer / Reviewer roles |
| **Capacity** | ✅ PASS | 5 SP within 20 SP iteration capacity (25%) |
| **Terminology** | ✅ PASS | All new prose uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-verify-context | Verify implementation context | All FRs | orientation | 0.25 | Spec Steward | done |
| t002-coordinator-rule | Add coordinator governance prompt rule for commit-push discipline | FR-001, FR-009 | US-5 | 0.5 | Spec Steward | done |
| t003-implementer-charter | Add commit responsibility to Implementer charter | FR-002, FR-009 | US-1 | 0.5 | Spec Steward | done |
| t004-spec-steward-charter | Add boundary-cleanliness oversight to Spec Steward charter | FR-003, FR-009 | US-2 | 0.5 | Spec Steward | done |
| t005-reviewer-charter | Add pre-merge committed-work check to Reviewer charter | FR-004, FR-009 | US-3 | 0.5 | Spec Steward | done |
| t006-retro-facilitator-charter | Add commit-discipline retro prompt to Retro Facilitator charter | FR-005, FR-009 | US-4 | 0.5 | Spec Steward | done |
| t007-planner-charter | Add light commit-cadence reference to Planner charter | FR-006, FR-009 | US-5 | 0.25 | Spec Steward | done |
| t008-user-guide-section | Add Boundary Commit Discipline section to docs/user-guide.md | FR-007, FR-009 | US-1, US-3 | 0.5 | Spec Steward | done |
| t009-mirror-parity | Mirror all 6 modified primary files to .specify/extensions/specrew-speckit/ | FR-008 | All | 0.5 | Implementer | done |
| t010-verification-test | Create boundary-commit-discipline.tests.ps1 verification test | FR-010, SC-001, SC-003, SC-004 | All | 1 | Reviewer | done |
| t011-closeout-artifacts | CHANGELOG entry + INDEX update + review.md + retro.md + state.md + closeout-dashboard | closeout | All | 0.25 | Spec Steward | done |
| t012-pr-merge | Branch push + PR open + merge-commit | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 5.5 story_points (Tier 1 text-only methodology slice)

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 5.5 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned > capacity |
| Defer Strategy | manual | Explicit deferral if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-methodology-integrity`
**Inferred Quality Profile**: `quality-profile.methodology-text-only`
**Recognized Stack**: PowerShell + Markdown + YAML frontmatter

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| Coordinator governance prompt rule present | methodology-text | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | pending |
| 5 charter additions present | methodology-text | `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` | pending |
| User-guide section published | documentation | `docs/user-guide.md` | pending |
| Mirror parity preserved | structural | `Compare-Object` between primary and mirror | pending |
| Verification test passes | integration | `tests/integration/boundary-commit-discipline.tests.ps1` | pending |

---

## Deferred Out of Scope

- Validator rule for `boundary-wip-uncommitted` (Tier 2; future release)
- Hard enforcement in `Invoke-SpecrewBoundaryStateSync` (Tier 3)
- Auto-push hook (Tier 3)
- Configuration via `iteration-config.yml` (Tier 3)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
