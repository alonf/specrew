# Iteration Tasks: 001

**Feature**: [Launch-Mode Boundary Enforcement](../../spec.md)  
**Feature Task Ledger**: [../../tasks.md](../../tasks.md)  
**Iteration Plan**: [plan.md](plan.md)  
**Capacity**: 7.0 story_points  
**Status**: implementation complete; review-boundary unopened

---

## T001: Audit Boundary-Entry Surfaces and Scope Lock (0.25 SP)

**Owner**: Reviewer  
**Status**: done  
**Story**: Setup  
**Trace**: FR-001, FR-002, FR-006, AC10

**Artifact Links**:

- [`scripts\specrew-start.ps1`](../../../../scripts/specrew-start.ps1)
- [`scripts\internal\sync-boundary-state.ps1`](../../../../scripts/internal/sync-boundary-state.ps1)
- [`scripts\specrew-where.ps1`](../../../../scripts/specrew-where.ps1)
- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`../../contracts/enforcement-hook-interface.md`](../../contracts/enforcement-hook-interface.md)

**Acceptance Criteria**:

- The reviewer records the exact launcher, helper, dashboard, and command surfaces that belong to Proposal 065 scope.
- The nine canonical boundary names are verified against Proposal 090-compatible vocabulary before implementation starts.
- No out-of-scope files are added to the implementation target list.

---

## T002: Extend Schema v2 + Canonical Boundary Validation + Migration Flow (0.75 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: Foundation  
**Trace**: FR-001, FR-006, FR-008, AC6, AC7, AC10

**Artifact Links**:

- [`scripts\specrew-start.ps1`](../../../../scripts/specrew-start.ps1)
- [`scripts\internal\sync-boundary-state.ps1`](../../../../scripts/internal/sync-boundary-state.ps1)
- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`tests\integration\session-state-boundary-canonical.tests.ps1`](../../../../tests/integration/session-state-boundary-canonical.tests.ps1)
- [`../../data-model.md`](../../data-model.md)

**Acceptance Criteria**:

- `boundary_enforcement` schema v2 matches the data model, including `enabled`, `last_authorized_boundary`, `pending_next_boundary`, `verdict_history`, and `bypass_history`.
- Pre-065 sessions without `boundary_enforcement` trigger the required migration directive and initialize empty histories after acknowledgment.
- Corrupt or incomplete `boundary_enforcement` payloads fail closed rather than downgrading to permissive mode.
- Canonical validation recognizes all nine boundaries, including `before-implement` and `retro`, in the same order used by Proposal 090.

---

## T003: Implement `Test-SpecrewBoundaryAuthorization` (0.50 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: US1  
**Trace**: FR-001, FR-002, FR-003, FR-005, FR-006, FR-007, AC1, AC8

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`../../contracts/enforcement-hook-interface.md`](../../contracts/enforcement-hook-interface.md)
- [`../../quickstart.md`](../../quickstart.md)

**Acceptance Criteria**:

- The function signature, return shape, and fail-safe semantics match section 1 of the enforcement-hook contract in both mirrored files.
- The helper normalizes canonical boundaries, reads `boundary_enforcement`, and blocks when no matching verdict exists.
- Agent-response snippet analysis only marks bypass evidence; it never authorizes progression by prose alone.
- Missing or malformed authorization state throws or returns blocked semantics exactly as the contract requires.

---

## T004: Implement `Add-SpecrewBoundaryAuthorization` (0.50 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: US1  
**Trace**: FR-003, FR-006, FR-008, AC2, AC9

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`../../contracts/enforcement-hook-interface.md`](../../contracts/enforcement-hook-interface.md)
- [`../../data-model.md`](../../data-model.md)

**Acceptance Criteria**:

- The function signature and return contract match section 2 of the enforcement-hook contract in both mirrors.
- Approved verdict persistence appends an atomic `verdict_history` row with exact verdict text, timestamp, human, and commit anchor.
- `last_authorized_boundary` advances only with a matching persisted verdict row, and `pending_next_boundary` is cleared when appropriate.
- Compound verdict handling does not skip outside canonical order except through the approved contract path.

---

## T005: Implement `Parse-SpecrewBoundaryVerdict` (0.50 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: US1  
**Trace**: FR-003, FR-007, AC2, AC3, AC9

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`../../contracts/enforcement-hook-interface.md`](../../contracts/enforcement-hook-interface.md)
- [`../../spec.md`](../../spec.md)

**Acceptance Criteria**:

- The parser recognizes approved, rejected, parked, and compound `approved for <boundary-A> AND <boundary-B>` verdict shapes.
- Ambiguous verdicts (`looks good`, `yep`, `continue`, `fine`, `okay`) return unauthorized with `SPECREW_BOUNDARY_VERDICT_UNRECOGNIZED`.
- Invalid compound syntax returns unauthorized without silently authorizing any boundary.
- The parser emits only canonical boundary names in its normalized result.

---

## T006: Implement `Write-SpecrewBoundaryAuthorizationDirective` (0.25 SP)

**Owner**: Spec Steward  
**Status**: done  
**Story**: US1  
**Trace**: FR-003, FR-005, AC1, AC3, AC8

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`../../contracts/enforcement-hook-interface.md`](../../contracts/enforcement-hook-interface.md)

**Acceptance Criteria**:

- The first line of every rendered directive is the required sentinel (`BLOCKED`, `AUTHORIZED`, `BYPASS_ACTIVE`, or `VERDICT_UNRECOGNIZED`).
- Blocked and unrecognized-verdict directives show only canonical boundary names and recognized verdict shapes.
- Bypass directives include the session bypass reason when applicable.
- The renderer is pure (no writes) and throws instead of emitting misleading guidance when canonical boundaries are invalid.

---

## T007: Insert Authorization Gate into All Nine Canonical Boundary Skills (1.25 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: US1  
**Trace**: FR-001, FR-002, FR-003, FR-005, FR-007, AC1, AC2, AC8, AC9

**Artifact Links**:

- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-specify.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-clarify.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-plan.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-tasks.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.before-implement.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-review-signoff.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-review-signoff.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-retro.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-retro.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-iteration-closeout.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-iteration-closeout.md)
- [`extensions\specrew-speckit\commands\speckit.specrew-speckit.sync-feature-closeout.md`](../../../../extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-feature-closeout.md)
- [`.specify\extensions\specrew-speckit\commands\`](../../../../.specify/extensions/specrew-speckit/commands)

**Acceptance Criteria**:

- Each listed boundary surface invokes `Test-SpecrewBoundaryAuthorization` before any boundary-advancing work executes.
- Unauthorized results surface the deterministic directive and stop execution without crossing the boundary.
- The retro boundary is included as a first-class gated surface alongside the other eight canonical boundaries.
- Mirrored `.specify` command files receive the same gate semantics as the primary extension command files.

---

## T008: Add Enforcement Ledger + `specrew where` Observability (1.00 SP)

**Owner**: Spec Steward  
**Status**: done  
**Story**: US2  
**Trace**: FR-004, FR-008, FR-009, AC5, AC7, AC10

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`scripts\internal\sync-boundary-state.ps1`](../../../../scripts/internal/sync-boundary-state.ps1)
- [`scripts\specrew-where.ps1`](../../../../scripts/specrew-where.ps1)
- [`../../research.md`](../../research.md)

**Acceptance Criteria**:

- Enforcement events append to `.squad/decisions.md` with timestamp, boundary type, enforcement action, launch mode, and 200-char response snippet.
- `specrew where` surfaces current boundary status, last enforcement timestamp, and total enforcement events for the active feature.
- Dashboard counters are derived from persisted history/ledger data and stay consistent with the state model.
- Logging or dashboard helper failures never weaken boundary enforcement decisions.

---

## T009: Implement Session-Scoped Emergency Bypass with Mandatory Reason (0.75 SP)

**Owner**: Implementer  
**Status**: done  
**Story**: US2  
**Trace**: FR-010, AC4, AC5, AC6

**Artifact Links**:

- [`scripts\specrew-start.ps1`](../../../../scripts/specrew-start.ps1)
- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`tests\integration\start-command.ps1`](../../../../tests/integration/start-command.ps1)
- [`../../quickstart.md`](../../quickstart.md)

**Acceptance Criteria**:

- `specrew start --bypass-boundary-enforcement` hard-fails unless `--reason "<text>"` is supplied.
- The first bypass activation records a session-scoped activation row; every bypassed boundary records a usage row plus a ledger event.
- Bypass remains active only for the current session and does not silently persist into later sessions without the flag.
- Bypass flows preserve auditability even when enforcement is suspended.

---

## T010: Add Proposal-038 Policy Adapter Seam with Hard-Stop Default (0.25 SP)

**Owner**: Spec Steward  
**Status**: done  
**Story**: US3  
**Trace**: FR-003, FR-006, AC8

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specrew\config.yml`](../../../../.specrew/config.yml)
- [`../../research.md`](../../research.md)

**Acceptance Criteria**:

- Boundary-class lookup is isolated behind a helper seam instead of hard-coding future Proposal 038 behavior into verdict history or gate logic.
- Absent or invalid config defaults every boundary to `human-judgment-required`.
- The adapter never creates a permissive path when config parsing fails.

---

## T011: Add Automated Coverage for AC1-AC10 Surfaces (0.50 SP)

**Owner**: Test Owner  
**Status**: done  
**Story**: Polish  
**Trace**: FR-001, FR-003, FR-004, FR-006, FR-008, FR-009, FR-010, AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10

**Artifact Links**:

- [`tests\integration\launch-mode-boundary-enforcement.tests.ps1`](../../../../tests/integration/launch-mode-boundary-enforcement.tests.ps1)
- [`tests\integration\session-state-boundary-canonical.tests.ps1`](../../../../tests/integration/session-state-boundary-canonical.tests.ps1)
- [`tests\integration\start-command.ps1`](../../../../tests/integration/start-command.ps1)
- [`../../quickstart.md`](../../quickstart.md)

**Acceptance Criteria**:

- AC1 through AC10 each have at least one explicit automated assertion or fixture path.
- Coverage includes ambiguous verdict rejection, compound verdict parsing, schema migration, corrupt-state fail-closed behavior, bypass-reason enforcement, and mirror parity checks.
- Tests verify both primary extension and `.specify` mirror behaviors where applicable.
- The suite is organized by enforcement surface so failures point to the correct helper, launcher, or dashboard path.

---

## T012: Replay 2026-05-22 Chain-Past-Plan Incident (AC11) (0.25 SP)

**Owner**: Test Owner  
**Status**: done  
**Story**: Polish  
**Trace**: FR-001, FR-002, FR-003, AC11

**Artifact Links**:

- [`tests\integration\launch-mode-boundary-enforcement.tests.ps1`](../../../../tests/integration/launch-mode-boundary-enforcement.tests.ps1)
- [`drift-log.md`](./drift-log.md)
- [`../../quickstart.md`](../../quickstart.md)

**Acceptance Criteria**:

- The replay scenario is named explicitly after the 2026-05-22 clarify→plan→tasks incident.
- The replay proves `plan` completes but `tasks` blocks when authorization is missing.
- The fixture/evidence references the drift-log chain rather than inventing a synthetic unrelated scenario.

---

## T013: Mirror Parity + CHANGELOG + INDEX (0.25 SP)

**Owner**: Reviewer  
**Status**: done  
**Story**: Polish  
**Trace**: FR-004, FR-010, AC10

**Artifact Links**:

- [`extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`.specify\extensions\specrew-speckit\scripts\shared-governance.ps1`](../../../../.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- [`CHANGELOG.md`](../../../../CHANGELOG.md)
- [`proposals\065-launch-mode-boundary-enforcement.md`](../../../../proposals/065-launch-mode-boundary-enforcement.md)
- [`proposals\INDEX.md`](../../../../proposals/INDEX.md)

**Acceptance Criteria**:

- Every touched mirrored file is updated in both `extensions\specrew-speckit\` and `.specify\extensions\specrew-speckit\`.
- `CHANGELOG.md` and proposal index/status surfaces capture the shipped F-039 slice explicitly rather than as invisible housekeeping.
- Mirror verification is documented as explicit acceptance evidence, not assumed.

---

## Execution Order

1. `T001`
2. `T002`
3. `T003` → `T004` → `T005` → `T006`
4. `T007`
5. `T008` + `T009` + `T010`
6. `T011`
7. `T012`
8. `T013`

**Parallel window**: `T011` and `T013` may overlap once `T007-T010` stabilize because they target test/release surfaces rather than the shared implementation files.

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
