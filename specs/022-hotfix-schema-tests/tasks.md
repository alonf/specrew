# Tasks: Feature 022 Hotfix + Schema Tests

**Input**: Design documents from `specs/022-hotfix-schema-tests/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `iterations/001/plan.md`, `iterations/001/quality/hardening-gate.md`  
**Tests**: Mandatory. Keep the three standalone regression scripts independently invocable for Proposal 054 composition.

**Primary scope lock**: 9.0 SP of executable work plus a 1.0 SP implicit repair reserve inside the 10.0 SP ceiling.  
**Work-package decomposition**: I1-W001..I1-W005 are decomposed below as executable tasks I1-T001..I1-T016.  
**Concurrency rule**: Keep W002, W003, and W004 serial because they overlap on shared session-state and restart surfaces. Only the isolated regression-script tasks are marked `[P]`.

## Task Format

Each task follows this structure:

```text
- [ ] I1-T### [P?] [US#?] [assigned_to: Role] [effort: N SP] Title: ... with exact file path(s) (Covers: ...; Story coverage: ...; Depends on: ...; Owner file globs: ...)
```

---

## Phase 1: Setup (Scope Lock and Governance)

**Purpose**: Freeze the accepted hotfix scope, preserve carry-forward governance, and reconcile stewardship ownership before runtime work starts.

- [ ] I1-T001 [assigned_to: Spec Steward] [effort: 0.5 SP] Title: Record Feature 022 scope lock and deferred-scope ledger entries in `.squad/decisions.md` (Covers: FR-005, FR-014, FR-016, FR-017, FR-018, FR-019; Story coverage: US1, US2, US3; Depends on: none; Owner file globs: `.squad/decisions.md`, `specs/022-hotfix-schema-tests/**`)
- [ ] I1-T002 [assigned_to: Spec Steward] [effort: 0.5 SP] Title: Update stewardship-role reconciliation and work-package crosswalk in `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md` for I1-W001..I1-W005 ownership and concurrency guardrails (Covers: FR-016, FR-017, TG-002; Story coverage: US1, US2, US3; Depends on: I1-T001; Owner file globs: `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md`, `specs/022-hotfix-schema-tests/**`)

**Checkpoint**: Scope, roles, and hotfix guardrails are explicit before shared runtime surfaces change.

---

## Phase 2: Foundational (Shared Session-State Baseline)

**Purpose**: Repair the shared closeout state-writing foundation that later lifecycle sync and restart recovery both depend on.

**⚠️ CRITICAL**: No user-story runtime work should start until this phase is complete.

- [ ] I1-T003 [assigned_to: Implementer] [effort: 0.5 SP] Title: Extend the closeout/session-state helper contract in `scripts/internal/sync-boundary-state.ps1` so `.squad/identity/now.md` can carry the required `session_state_*` fields without widening the audit scope (Covers: FR-001, FR-002, FR-005, FR-010; Story coverage: US3 primary, supports US1 and US2; Depends on: I1-T002; Owner file globs: `scripts/internal/sync-boundary-state.ps1`, `.squad/identity/now.md`)
- [ ] I1-T004 [assigned_to: Implementer] [effort: 1.0 SP] Title: Update `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` to write dual-surface closeout frontmatter and preserve the human-readable body in `.squad/identity/now.md` via the shared helper (Covers: FR-001, FR-002, FR-003; Story coverage: US3 primary, supports US1 and US2; Depends on: I1-T003; Owner file globs: `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, `scripts/internal/sync-boundary-state.ps1`, `.squad/identity/now.md`)

**Checkpoint**: The closeout writer can emit machine-readable and human-readable identity state from one shared path.

---

## Phase 3: User Story 2 - Keep Lifecycle State in Sync Across All Boundaries (Priority: P1)

**Goal**: Restore ordered synchronization across all seven lifecycle boundaries so restart validation and ledger evidence agree on current state.

**Independent Test**: Run a simulated lifecycle through specify, clarify, plan, tasks, review-signoff, iteration closeout, and feature closeout, then verify `tests/integration/lifecycle-boundary-sync.tests.ps1` proves seven ordered `Boundary sync:` entries with visible drift on failure.

- [ ] I1-T005 [US2] [assigned_to: Implementer] [effort: 0.5 SP] Title: Audit the seven lifecycle sync injection points across `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md`, `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-clarify.md`, `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-plan.md`, `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-tasks.md`, `scripts/specrew-review.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, and `scripts/internal/sync-boundary-state.ps1`, then capture the approved repair map in `.squad/decisions.md` (Covers: FR-006, FR-007, FR-008; Story coverage: US2; Depends on: I1-T004; Owner file globs: `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md`, `scripts/specrew-review.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, `scripts/internal/sync-boundary-state.ps1`, `.squad/decisions.md`)
- [ ] I1-T006 [US2] [assigned_to: Implementer] [effort: 0.75 SP] Title: Restore specify, clarify, plan, and tasks boundary sync calls in the four `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md` wrappers so each boundary invokes `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` at the correct completion point (Covers: FR-006, FR-007, FR-008; Story coverage: US2; Depends on: I1-T005; Owner file globs: `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md`, `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`)
- [ ] I1-T007 [US2] [assigned_to: Implementer] [effort: 0.75 SP] Title: Restore review-signoff, iteration-closeout, and feature-closeout sync sequencing in `scripts/specrew-review.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, and `scripts/internal/sync-boundary-state.ps1`, including durable `auth_commit_hash` capture before cleanup (Covers: FR-006, FR-007, FR-008, FR-010; Story coverage: US2; Depends on: I1-T006; Owner file globs: `scripts/specrew-review.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, `scripts/internal/sync-boundary-state.ps1`, `.squad/decisions.md`)
- [ ] I1-T008 [US2] [assigned_to: Implementer] [effort: 0.5 SP] Title: Make skipped or misplaced late-boundary sync observable in `scripts/internal/sync-boundary-state.ps1` and `scripts/specrew-start.ps1` so restart validation and `.squad/decisions.md` expose the mismatch instead of silently passing (Covers: FR-009, FR-010; Story coverage: US2; Depends on: I1-T007; Owner file globs: `scripts/internal/sync-boundary-state.ps1`, `scripts/specrew-start.ps1`, `.squad/decisions.md`)
- [ ] I1-T009 [P] [US2] [assigned_to: Reviewer] [effort: 0.5 SP] Title: Create `tests/integration/lifecycle-boundary-sync.tests.ps1` as the FR-009 / Proposal 054 Scenario C regression lane using `specs/022-hotfix-schema-tests/contracts/lifecycle-boundary-sync-contract.md` as the executable contract (Covers: FR-009, SC-002; Story coverage: US2; Depends on: I1-T008; Owner file globs: `tests/integration/lifecycle-boundary-sync.tests.ps1`, `specs/022-hotfix-schema-tests/contracts/lifecycle-boundary-sync-contract.md`)

**Checkpoint**: The seven lifecycle boundaries are wired, late-boundary drift is visible, and the standalone boundary-sync regression lane exists.

---

## Phase 4: User Story 1 - Restart Safely After Ship or Closeout (Priority: P1)

**Goal**: Make stale-state recovery actionable at `specrew start`, including the interactive A/B/C path and an explicit `--recover` bypass that stays orthogonal to approval behavior.

**Independent Test**: Simulate a shipped or closeout stale-state condition, run `specrew start`, and verify the operator can complete the A/B/C flow or use `specrew start --recover` to enter recovery mode without startup dead-end behavior.

- [ ] I1-T010 [US1] [assigned_to: Implementer] [effort: 0.75 SP] Title: Implement actionable stale-state A/B/C selection handling in `scripts/specrew-start.ps1` and `extensions/specrew-speckit/scripts/resume-iteration.ps1` so the operator can choose and continue instead of exiting on detection (Covers: FR-011, FR-013; Story coverage: US1; Depends on: I1-T008; Owner file globs: `scripts/specrew-start.ps1`, `extensions/specrew-speckit/scripts/resume-iteration.ps1`)
- [ ] I1-T011 [US1] [assigned_to: Implementer] [effort: 0.75 SP] Title: Add explicit `--recover` routing in `scripts/specrew-start.ps1` and `scripts/internal/coordinator-resume.ps1` so recovery mode bypasses the stale-state gate without changing best-guess or autopilot behavior (Covers: FR-012, FR-014; Story coverage: US1; Depends on: I1-T010; Owner file globs: `scripts/specrew-start.ps1`, `scripts/internal/coordinator-resume.ps1`)
- [ ] I1-T012 [US1] [assigned_to: Implementer] [effort: 0.5 SP] Title: Persist recovery diagnostics and next-step messaging through `scripts/specrew-start.ps1`, `.specrew/start-context.json`, and `.specrew/last-start-prompt.md` for both detected stale state and explicit recovery entry (Covers: FR-013, FR-015, SC-001, SC-004; Story coverage: US1; Depends on: I1-T011; Owner file globs: `scripts/specrew-start.ps1`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md`)
- [ ] I1-T013 [P] [US1] [assigned_to: Reviewer] [effort: 0.5 SP] Title: Create `tests/integration/start-recovery-flow.tests.ps1` as the FR-015 / Proposal 054 Scenario A regression lane covering interactive recovery, invalid input visibility, and `--recover` semantics (Covers: FR-015, SC-001, SC-004; Story coverage: US1; Depends on: I1-T012; Owner file globs: `tests/integration/start-recovery-flow.tests.ps1`, `specs/022-hotfix-schema-tests/contracts/restart-recovery-contract.md`)

**Checkpoint**: Restart recovery no longer dead-ends and the standalone recovery regression lane exists.

---

## Phase 5: User Story 3 - Preserve Schema Parity Between Human and Machine State (Priority: P2)

**Goal**: Keep `.squad/identity/now.md` human-readable while guaranteeing the same closeout frontmatter is consumable by the stale-state/session-state parser.

**Independent Test**: Generate closeout identity state, parse its frontmatter via the same restart/session-state parser, and verify the file stays readable to a human without any closeout-only parsing path.

- [ ] I1-T014 [US3] [assigned_to: Implementer] [effort: 0.5 SP] Title: Reuse the stale-state/session-state parser in `scripts/specrew-start.ps1` against the closeout identity contract from `scripts/internal/sync-boundary-state.ps1` so `.squad/identity/now.md` requires no special-case parser path (Covers: FR-003, FR-004; Story coverage: US3; Depends on: I1-T004; Owner file globs: `scripts/specrew-start.ps1`, `scripts/internal/sync-boundary-state.ps1`, `.squad/identity/now.md`)
- [ ] I1-T015 [P] [US3] [assigned_to: Reviewer] [effort: 0.25 SP] Title: Create `tests/integration/closeout-identity-schema-parity.tests.ps1` as the FR-004 / Proposal 054 Scenario B regression lane using `specs/022-hotfix-schema-tests/contracts/closeout-identity-state-contract.md` (Covers: FR-004, SC-003; Story coverage: US3; Depends on: I1-T014; Owner file globs: `tests/integration/closeout-identity-schema-parity.tests.ps1`, `specs/022-hotfix-schema-tests/contracts/closeout-identity-state-contract.md`)

**Checkpoint**: Closeout identity state remains dual-surface and independently verifiable.

---

## Phase 6: Polish & Cross-Cutting Evidence

**Purpose**: Close the task-generation slice with hardening evidence that references all three standalone regression lanes without widening scope.

- [ ] I1-T016 [assigned_to: Reviewer] [effort: 0.25 SP] Title: Update `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md` with runtime evidence placeholders, proposal-composition references, and pass/fail recording instructions for `tests/integration/closeout-identity-schema-parity.tests.ps1`, `tests/integration/lifecycle-boundary-sync.tests.ps1`, and `tests/integration/start-recovery-flow.tests.ps1` (Covers: FR-004, FR-009, FR-015, FR-017, SC-001, SC-002, SC-003, SC-004, SC-005; Story coverage: US1, US2, US3; Depends on: I1-T009, I1-T013, I1-T015; Owner file globs: `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md`, `tests/integration/*.ps1`)

---

## Dependencies & Execution Order

### Work-Package Mapping

- **I1-W001** → I1-T001, I1-T002
- **I1-W002** → I1-T003, I1-T004, I1-T014
- **I1-W003** → I1-T005, I1-T006, I1-T007, I1-T008
- **I1-W004** → I1-T010, I1-T011, I1-T012
- **I1-W005** → I1-T009, I1-T013, I1-T015, I1-T016

### Critical Path

```text
I1-T001 → I1-T002 → I1-T003 → I1-T004 → I1-T005 → I1-T006 → I1-T007 → I1-T008 → I1-T010 → I1-T011 → I1-T012 → I1-T013 → I1-T016
```

**Critical-path explanation**: W002, W003, and W004 stay serial because they all modify shared session-state and restart surfaces. The lifecycle-sync and restart-recovery lanes must land before the recovery regression and final hardening evidence can complete. US3 implementation (I1-T014) and the isolated regression lanes (I1-T009, I1-T015) are intentionally off the runtime critical path, but I1-T016 still waits for all three regression suites.

### Story Dependencies

- **US2** starts after the foundational phase because lifecycle sync repair depends on the shared closeout/session-state writer.
- **US1** starts after US2 because stale-state recovery must consume the repaired boundary-sync observability path.
- **US3** can finish after the P1 lanes because its parser-reuse task depends only on the foundational closeout writer and does not reopen the shared runtime critical path.

---

## Parallel Execution Opportunities

Only surface-isolated regression-script tasks are approved for parallel execution:

- **Parallel lane 1**: I1-T009 updates only `tests/integration/lifecycle-boundary-sync.tests.ps1` after I1-T008
- **Parallel lane 2**: I1-T013 updates only `tests/integration/start-recovery-flow.tests.ps1` after I1-T012
- **Parallel lane 3**: I1-T015 updates only `tests/integration/closeout-identity-schema-parity.tests.ps1` after I1-T014

### Parallel Example

```text
Task I1-T009 -> tests/integration/lifecycle-boundary-sync.tests.ps1
Task I1-T013 -> tests/integration/start-recovery-flow.tests.ps1
Task I1-T015 -> tests/integration/closeout-identity-schema-parity.tests.ps1
```

---

## Implementation Strategy

### Safe Hotfix MVP

1. Complete Phase 1 (scope lock) and Phase 2 (shared state foundation)
2. Complete Phase 3 (US2 lifecycle-sync restoration)
3. Complete Phase 4 (US1 restart recovery)
4. Validate I1-T009 and I1-T013 before widening to Phase 5

> **Why this MVP shape**: US1 is the operator-facing blocker, but the accepted concurrency rationale says W002-W004 must stay serial on shared session-state surfaces. Restoring lifecycle sync before final recovery UX keeps the hotfix safe and aligned with the approved root-cause order.

### Incremental Delivery

1. Scope/governance lock (`I1-T001`..`I1-T002`)
2. Shared closeout-schema foundation (`I1-T003`..`I1-T004`)
3. Seven-boundary sync restoration (`I1-T005`..`I1-T009`)
4. Restart recovery UX (`I1-T010`..`I1-T013`)
5. Schema-parity parser proof (`I1-T014`..`I1-T015`)
6. Hardening evidence closeout (`I1-T016`)

---

## Task Count Summary

- **Setup**: 2 tasks, 1.0 SP
- **Foundational**: 2 tasks, 1.5 SP
- **US2**: 5 tasks, 3.0 SP
- **US1**: 4 tasks, 2.5 SP
- **US3**: 2 tasks, 0.75 SP
- **Polish/Cross-Cutting**: 1 task, 0.25 SP

### Work-Package Totals

- **I1-W001**: 2 tasks, 1.0 SP
- **I1-W002**: 3 tasks, 2.0 SP
- **I1-W003**: 4 tasks, 2.5 SP
- **I1-W004**: 3 tasks, 2.0 SP
- **I1-W005**: 4 tasks, 1.5 SP

**Primary planned work**: 16 tasks, 9.0 SP  
**Implicit repair reserve**: 1.0 SP inside the 10.0 SP ceiling  
**Capacity verdict**: The executable checklist matches the accepted 9.0 SP primary scope and preserves the separate 1.0 SP repair reserve without widening Feature 022.

---

## Format Validation

✅ All tasks use the required checklist form: `- [ ] I1-T### [P?] [US#?] [assigned_to: ...] [effort: ...] ...`  
✅ Every task includes a title, requirement coverage, user-story coverage, effort estimate, owner role, dependencies, and owner file globs  
✅ User-story labels appear only on user-story phase tasks  
✅ Exact standalone regression paths are preserved for Proposal 054 composition  
✅ Critical path and constrained parallel lanes are explicit
