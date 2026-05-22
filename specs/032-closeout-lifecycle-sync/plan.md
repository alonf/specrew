# Feature Plan: Closeout Lifecycle Sync Commands

**Feature**: 032
**Proposal**: [Proposal 090](../../proposals/090-closeout-lifecycle-sync-commands.md)
**Branch**: `chore-090-closeout-lifecycle-sync-commands`
**Created**: 2026-05-22
**Version**: v0.24.3 (process-optimization bundle, slot 1)

## Goal

Close the architectural gap exposed by F-030/083: the closeout half of Specrew's lifecycle (review-signoff, retro, iteration-closeout, feature-closeout) has no automated sync coverage. The Crew has been bypassing the canonical `Invoke-SpecrewBoundaryStateSync` script, producing state-file drift (non-canonical strings, missing field updates, contradictions). This feature adds 4 new sync commands + a validator rule that catches the bypass bug class going forward.

## Scope

In scope:

1. 4 new sync command files (and mirror)
2. `extension.yml` `provides.commands` update (and mirror)
3. `sync-boundary-state.ps1` ValidateSet extension to include `retro` at 4 sites
4. New validator rule `Test-SessionStateBoundaryCanonical`
5. Charter updates (4 roles + coordinator governance prompt)
6. Integration tests
7. CHANGELOG + INDEX

Out of scope (per spec.md Out of Scope section):

- Migration of existing legacy `feature-closed`/`iteration-closed` strings
- Auto-invocation via daemon
- Slash-command discoverability UX changes

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

## Iteration Breakdown

Single iteration (small feature). Iteration 001 = all of FR-001 through FR-011.

## Phase Breakdown

| Phase | Effort | Tasks |
| ----- | ------ | ----- |
| Core artifacts (commands, ValidateSet, validator rule) | 3.0 SP | T002, T003, T004, T005 |
| Methodology surface (charters, coordinator prompt) | 1.0 SP | T006, T007 |
| Testing | 1.5 SP | T008, T009 |
| Mirror parity + closeout polish | 0.5 SP | T010, T011 |

**Total: 6.0 story_points** (aligned with Proposal 090's 5-8 SP estimate).

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration: 6 |
| Iteration Bounding | scope | Keep requirements fixed |
| Time Limit (hours) | n/a | Uses scope-based bounding |
| Overcommit Threshold | 1.0 | Warn when planned > capacity |
| Defer Strategy | manual | Explicit deferral if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

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

## Dependencies

### Prerequisite Infrastructure (Already Shipped)

- Proposal 083 Local Validator Auto-Scope (provides `Get-SpecrewLocalScopeBaseRef` reused by validator rule)
- Proposal 032 Specrew Slash-Command Surface (provides the slash-command infrastructure)
- F-029 baseline-hygiene (provides `Clear-SpecrewActiveFeature` + `active=false` logic that the new sync-feature-closeout command will trigger)
- `chore(validator-perf-feature-json-exclusion)` (removes `.specify/feature.json` from forcing fallback)

### Composes With (Queued)

- Proposal 086 Pillar 1 Memoization (the new validator rule benefits from cache when 086 P1 ships)
- Proposal 088 Markdown Lint Pre-Boundary (same architectural pattern: gate-at-boundary-with-directive)
- Proposal 089 PR Review Integration (sibling process-optimization slice)

---

## Tasks Summary

See `iterations/001/tasks.md` for the detailed task table.

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
