# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 6/20 story_points
**Started**: 2026-05-22
**Completed**: 2026-05-22

## Summary

Iteration 001 delivers the full scope of Proposal 090: 4 new sync commands + extension.yml registration + `retro` added to canonical ValidateSet + new validator rule `Test-SessionStateBoundaryCanonical` + charter updates (4 roles + coordinator prompt) + integration tests + mirror parity + CHANGELOG + INDEX update.

**Primary Focus**: Closing the architectural gap where the closeout half of Specrew's lifecycle has no automated sync coverage, leading to the Crew-bypass bug class (4 manifestations on F-030/083 alone).

**Target User Stories**: US-1 through US-5 (all P1/P2 user stories from spec.md).

**Success Criteria**: 4 sync commands present + extension.yml updated + ValidateSet extended + validator rule rejecting non-canonical strings AND active/boundary contradictions + charter prose referencing new commands + mirror parity verified + integration tests passing.

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner |
|----------|-------------|----------------|-------|
| FR-001 | 4 new sync command files | ✅ T002 | Implementer |
| FR-002 | extension.yml update | ✅ T003 | Implementer |
| FR-003 | ValidateSet extension for `retro` | ✅ T004 | Implementer |
| FR-004 | Command file template fidelity | ✅ T002 | Implementer |
| FR-005 | Validator rule Test-SessionStateBoundaryCanonical | ✅ T005 | Implementer |
| FR-006 | Auto-scope via Proposal 083 | ✅ T005 (reuses existing helper) | Implementer |
| FR-007 | Charter updates (4 roles) | ✅ T006 | Spec Steward |
| FR-008 | Coordinator governance prompt update | ✅ T007 | Spec Steward |
| FR-009 | Integration tests | ✅ T008, T009 | Test Owner |
| FR-010 | Mirror parity | ✅ T010 | Implementer |
| FR-011 | CHANGELOG entry | ✅ T011 | Spec Steward |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to FR-001 through FR-011 from spec.md |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements |
| **Ownership** | ✅ PASS | Tasks assigned to Implementer / Spec Steward / Test Owner roles |
| **Capacity** | ✅ PASS | 6 SP within 20 SP iteration capacity (30%) |
| **Terminology** | ✅ PASS | All new prose uses "the Crew" per 2026-05-21 naming decision |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| t001-context | Verify implementation context + locate all surfaces | All FRs (orientation) | All US | 0.25 | Spec Steward | done |
| t002-sync-commands | Create 4 new sync command .md files + mirror | FR-001, FR-004 | US-1, US-2 | 1.0 | Implementer | done |
| t003-extension-yml | Update extension.yml provides.commands list + mirror | FR-002 | US-1, US-2 | 0.25 | Implementer | done |
| t004-validateset-retro | Add `retro` to ValidateSet at 4 sites in sync-boundary-state.ps1 | FR-003 | US-2 | 0.5 | Implementer | done |
| t005-validator-rule | Add Test-SessionStateBoundaryCanonical validator rule + mirror | FR-005, FR-006 | US-3, US-4 | 1.5 | Implementer | done |
| t006-charter-updates | Update 4 agent charters with new command instructions + mirrors | FR-007 | US-5 | 0.5 | Spec Steward | done |
| t007-coordinator-prompt | Update coordinator governance prompt rule 5 + mirror | FR-008 | US-5 | 0.25 | Spec Steward | done |
| t008-test-sync-commands | Integration test for 4 new sync commands | FR-009 | US-1, US-2 | 1.0 | Test Owner | done |
| t009-test-validator-rule | Integration test for canonical-string + active/boundary contradiction assertions | FR-009 | US-3, US-4 | 0.5 | Test Owner | done |
| t010-mirror-parity | Mirror parity verification sweep | FR-010 | All | 0.25 | Implementer | done |
| t011-changelog-index | CHANGELOG entry + INDEX update + closeout artifacts | FR-011 | All | 0.25 | Spec Steward | done |
| t012-pr-merge | Branch push + PR + Copilot review + merge | closeout | All | 0.25 | Spec Steward | done |

**Total Effort (Planned)**: 6.5 story_points (Proposal 090's "small feature" slice estimate)

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 6.5 |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-2-process-optimization`
**Inferred Quality Profile**: `quality-profile.lifecycle-integrity`
**Recognized Stack**: PowerShell + Markdown + YAML

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
|---|---|---|---|
| 4 sync commands present (+ mirror) | structural | `extensions/specrew-speckit/commands/sync-*.md` | pending |
| extension.yml updated | structural | `extensions/specrew-speckit/extension.yml` | pending |
| ValidateSet includes `retro` | structural | `scripts/internal/sync-boundary-state.ps1` | pending |
| Validator rule rejects non-canonical strings | integration | `tests/integration/session-state-boundary-canonical.tests.ps1` | pending |
| Validator rule rejects active/boundary contradiction | integration | same test file | pending |
| Mirror parity preserved | structural | `Compare-Object` between primary and mirror | pending |
| Charter prose references new commands | methodology-text | grep `extensions/specrew-speckit/squad-templates/...` | pending |

---

## Deferred Out of Scope

- Migration of existing legacy `feature-closed`/`iteration-closed` strings (queued as separate chore)
- Auto-invocation via daemon (out of scope per spec.md)
- Slash-command discoverability UX changes (relies on Spec Kit's existing discovery)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
