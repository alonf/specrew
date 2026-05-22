# Tasks: Launch-Mode Boundary Enforcement

**Input**: Design documents from `specs/039-launch-mode-boundary-enforcement/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/enforcement-hook-interface.md`, `quickstart.md`  
**Tests**: Required — Proposal 065 and `spec.md` require explicit coverage for AC1 through AC11  
**Capacity Target**: 7.0 story points (Proposal 065 upper-bound single-iteration slice)

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently while preserving Proposal 065 scope rows as separately trackable work items.

## Format

`- [ ] T### [P?] [US#?] [assigned_to: ...] [effort: ...] Description with exact file path(s) (Trace: ...)`

---

## Phase 1: Setup

**Purpose**: Lock the exact enforcement surfaces before code changes begin.

- [X] T001 [assigned_to: Reviewer] [effort: 0.25 SP] Audit boundary-entry surfaces in `scripts\specrew-start.ps1`, `scripts\internal\sync-boundary-state.ps1`, `scripts\specrew-where.ps1`, `extensions\specrew-speckit\scripts\shared-governance.ps1`, `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`, and `extensions\specrew-speckit\extension.yml` to confirm the nine canonical boundaries plus proposal-065 scope lock before implementation starts (Trace: FR-001, FR-002, FR-006, AC10)

**Independent Test**: Reviewer can point to the exact launcher, shared-governance, dashboard, validator, and command surfaces that will carry F-039 without adding out-of-scope files.

---

## Phase 2: Foundational

**Purpose**: Establish the shared schema and canonical boundary vocabulary that all user stories depend on.

**⚠️ CRITICAL**: User-story work starts only after the canonical nine-boundary schema and migration approach are in place.

- [X] T002 [assigned_to: Implementer] [effort: 0.75 SP] Extend `scripts\specrew-start.ps1`, `scripts\internal\sync-boundary-state.ps1`, `extensions\specrew-speckit\scripts\shared-governance.ps1`, `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`, and `tests\integration\session-state-boundary-canonical.tests.ps1` for `boundary_enforcement` schema v2, pre-065 migration flow, fail-closed reads, and canonical nine-boundary validation including `retro` and `before-implement` (Trace: FR-001, FR-006, FR-008, AC6, AC7, AC10)

**Checkpoint**: `start-context.json` schema, canonical vocabulary, and migration semantics are ready for helper and gate work.

---

## Phase 3: User Story 1 - Lifecycle Boundary Protection During Autonomous Mode (Priority: P1) 🎯 MVP

**Goal**: Mechanically block unauthorized lifecycle advancement even when the agent chains tool calls in one turn.

**Independent Test**: A chained `plan -> tasks` or `clarify -> plan -> tasks` run stops at the unauthorized boundary, emits the deterministic directive sentinel, and leaves the boundary uncrossed.

### Implementation for User Story 1

- [X] T003 [US1] [assigned_to: Implementer] [effort: 0.50 SP] Implement `Test-SpecrewBoundaryAuthorization` in `extensions\specrew-speckit\scripts\shared-governance.ps1` and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` per `specs\039-launch-mode-boundary-enforcement\contracts\enforcement-hook-interface.md` section 1 so authorization checks normalize canonical boundaries, detect bypass-attempt evidence, and fail closed on malformed state (Trace: FR-001, FR-002, FR-003, FR-005, FR-006, FR-007, AC1, AC8)
- [X] T004 [US1] [assigned_to: Implementer] [effort: 0.50 SP] Implement `Add-SpecrewBoundaryAuthorization` in `extensions\specrew-speckit\scripts\shared-governance.ps1` and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` per `specs\039-launch-mode-boundary-enforcement\contracts\enforcement-hook-interface.md` section 2 to append atomic verdict-history rows, update `last_authorized_boundary`, and clear `pending_next_boundary` correctly (Trace: FR-003, FR-006, FR-008, AC2, AC9)
- [X] T005 [US1] [assigned_to: Implementer] [effort: 0.50 SP] Implement `Parse-SpecrewBoundaryVerdict` in `extensions\specrew-speckit\scripts\shared-governance.ps1` and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` per `specs\039-launch-mode-boundary-enforcement\contracts\enforcement-hook-interface.md` section 3 for approved, rejected, parked, ambiguous, and compound `AND` verdict forms (Trace: FR-003, FR-007, AC2, AC3, AC9)
- [X] T006 [US1] [assigned_to: Spec Steward] [effort: 0.25 SP] Implement `Write-SpecrewBoundaryAuthorizationDirective` in `extensions\specrew-speckit\scripts\shared-governance.ps1` and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` per `specs\039-launch-mode-boundary-enforcement\contracts\enforcement-hook-interface.md` section 4 so sentinel-first directives render stable blocked, bypassed, and unrecognized-verdict guidance (Trace: FR-003, FR-005, AC1, AC3, AC8)
- [X] T007 [US1] [assigned_to: Implementer] [effort: 1.25 SP] Insert the authorization gate into `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-specify.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-clarify.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-plan.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-tasks.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-review-signoff.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-retro.md`, `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-iteration-closeout.md`, and `extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-feature-closeout.md` plus the matching `.specify\extensions\specrew-speckit\commands\` mirrors so all FR-001 boundaries block before advancement logic runs (Trace: FR-001, FR-002, FR-003, FR-005, FR-007, AC1, AC2, AC8, AC9)

**Checkpoint**: Boundary helpers exist, directive sentinels are stable, and every canonical boundary surface blocks unauthorized entry.

---

## Phase 4: User Story 2 - Boundary Enforcement Configuration and Observability (Priority: P2)

**Goal**: Persist auditable enforcement state, surface enforcement history, and support emergency bypass without silent privilege escalation.

**Independent Test**: Enforcement events appear in `.squad/decisions.md`, `specrew where` shows the current enforcement summary, and bypass requires an explicit reason while logging every bypassed boundary.

### Implementation for User Story 2

- [X] T008 [US2] [assigned_to: Spec Steward] [effort: 1.00 SP] Add enforcement-event logging and dashboard summary support in `extensions\specrew-speckit\scripts\shared-governance.ps1`, `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`, `scripts\internal\sync-boundary-state.ps1`, and `scripts\specrew-where.ps1` so `.squad\decisions.md` receives FR-004 fields and `specrew where` reports current boundary status, last enforcement timestamp, and total events (Trace: FR-004, FR-008, FR-009, AC5, AC7, AC10)
- [X] T009 [US2] [assigned_to: Implementer] [effort: 0.75 SP] Implement the session-scoped emergency bypass path in `scripts\specrew-start.ps1`, `extensions\specrew-speckit\scripts\shared-governance.ps1`, and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` for `--bypass-boundary-enforcement --reason "<text>"`, activation/usage history rows, and hard-error rejection when `--reason` is missing (Trace: FR-010, AC4, AC5, AC6)

**Checkpoint**: Boundary events are auditable, dashboard state is derived correctly, and bypass is explicit, session-scoped, and reviewable.

---

## Phase 5: User Story 3 - Boundary Classification Integration (Priority: P3)

**Goal**: Preserve Proposal 038 extensibility without weakening MVP hard-stop behavior.

**Independent Test**: With no valid policy config, all nine boundaries still behave as `human-judgment-required`; with future config plumbing, the lookup seam is localized and testable.

### Implementation for User Story 3

- [X] T010 [US3] [assigned_to: Spec Steward] [effort: 0.25 SP] Add the conservative Proposal-038 policy lookup seam in `extensions\specrew-speckit\scripts\shared-governance.ps1`, `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`, and `.specrew\config.yml` so boundary classification defaults to hard-stop behavior until class-aware policy is explicitly configured (Trace: FR-003, FR-006, AC8)

**Checkpoint**: Future classification support is isolated behind a fail-closed adapter with no MVP behavior regression.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish the test, replay, and release-quality work that cuts across all user stories.

- [X] T011 [P] [assigned_to: Test Owner] [effort: 0.50 SP] Add/extend integration coverage in `tests\integration\launch-mode-boundary-enforcement.tests.ps1`, `tests\integration\session-state-boundary-canonical.tests.ps1`, and `tests\integration\start-command.ps1` for AC1 through AC10, including ambiguous verdict rejection, compound verdict parsing, bypass reason enforcement, schema migration, fail-safe faults, and dashboard/audit evidence (Trace: FR-001, FR-003, FR-004, FR-006, FR-008, FR-009, FR-010, AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10)
- [X] T012 [assigned_to: Test Owner] [effort: 0.25 SP] Add a dedicated replay named `Replay 2026-05-22 chain-past-plan incident` to `tests\integration\launch-mode-boundary-enforcement.tests.ps1` using the `specs\039-launch-mode-boundary-enforcement\iterations\001\drift-log.md` evidence chain so `clarify -> plan -> tasks` succeeds only through `plan` and blocks at `tasks` (Trace: FR-001, FR-002, FR-003, AC11)
- [X] T013 [P] [assigned_to: Reviewer] [effort: 0.25 SP] Complete mirror parity and release-surface updates in `extensions\specrew-speckit\scripts\shared-governance.ps1`, `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`, touched command-file mirrors under both command trees, `CHANGELOG.md`, `proposals\065-launch-mode-boundary-enforcement.md`, and `proposals\INDEX.md` (Trace: FR-004, FR-010, AC10)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Surface audit first so schema work only touches approved files.
- **Phase 2 → Phase 3/4/5**: Schema + canonical vocabulary block all story work.
- **Phase 3**: MVP enforcement mechanics must land before observability or policy seam validation can be trusted.
- **Phase 4**: Depends on helper/gate plumbing from Phase 3.
- **Phase 5**: Can begin after Phase 2, but should validate against the helper behavior from Phase 3.
- **Phase 6**: Depends on Phases 3-5 being code-complete.

### User Story Dependencies

- **US1 (P1)**: Starts immediately after Phase 2 and delivers the MVP boundary stop.
- **US2 (P2)**: Depends on US1 helper/gate semantics so logs and bypass reflect real enforcement outcomes.
- **US3 (P3)**: Depends on the canonical boundary vocabulary from Phase 2; can trail US1/US2.

### Parallel Opportunities

- `T011` can run in parallel with `T013` once implementation surfaces stabilize.
- Documentation/release updates in `T013` can proceed while `T011` finalizes automated evidence.
- Within the implementation sequence, only explicitly mirrored doc/release work is parallel-safe; helper tasks share the same mirrored governance files and should remain sequential.

---

## Parallel Example: User Story 2

```text
Task: T011 Add/extend integration coverage in tests\integration\launch-mode-boundary-enforcement.tests.ps1, tests\integration\session-state-boundary-canonical.tests.ps1, and tests\integration\start-command.ps1
Task: T013 Complete mirror parity and release-surface updates in CHANGELOG.md, proposals\065-launch-mode-boundary-enforcement.md, and proposals\INDEX.md
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup audit.
2. Complete Phase 2 schema/canonical-boundary foundation.
3. Complete Phase 3 helper + gate insertion work.
4. Run `T011`/`T012` evidence for AC1, AC2, AC3, AC8, AC9, and AC11.
5. Stop for before-implement authorization once the tasks-boundary work is complete.

### Incremental Delivery

1. Foundation (`T001-T002`)
2. Core enforcement mechanics (`T003-T007`) → validate MVP
3. Observability and bypass (`T008-T009`)
4. Future-proof policy seam (`T010`)
5. Cross-cutting tests + parity + release surfaces (`T011-T013`)

### Suggested MVP Scope

**User Story 1 only** (`T003-T007`) after `T001-T002` completes.

---

## Traceability Coverage

| Spec Ref | Covered By |
| --- | --- |
| FR-001 | T001, T002, T003, T007, T011, T012 |
| FR-002 | T001, T003, T007, T012 |
| FR-003 | T003, T004, T005, T006, T007, T010, T011, T012 |
| FR-004 | T008, T011, T013 |
| FR-005 | T003, T006, T007 |
| FR-006 | T001, T002, T003, T007, T010, T011 |
| FR-007 | T003, T005, T007 |
| FR-008 | T002, T004, T008, T011 |
| FR-009 | T008, T011 |
| FR-010 | T001, T009, T011, T013 |
| AC1 | T003, T006, T007, T011 |
| AC2 | T004, T005, T007, T011 |
| AC3 | T005, T006, T011 |
| AC4 | T009, T011 |
| AC5 | T008, T009, T011 |
| AC6 | T002, T009, T011 |
| AC7 | T002, T008, T011 |
| AC8 | T003, T006, T007, T010, T011 |
| AC9 | T004, T005, T007, T011 |
| AC10 | T002, T008, T011, T013 |
| AC11 | T012 |

---

## Notes

- All checklist items use exact task IDs, explicit owners, story points, and trace metadata.
- Helper-contract work remains separated into four distinct tasks as required by the enforcement-hook contract.
- The nine gated boundary skills are explicitly enumerated in `T007`, including `retro`.
- AC11 is preserved as its own named replay task (`T012`) rather than being buried in the general test bucket.
