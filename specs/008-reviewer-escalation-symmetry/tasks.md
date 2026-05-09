# Tasks: Reviewer Escalation Symmetry and Lockout-Chain Cap

**Input**: Design documents from `C:\Dev\Specrew\specs\008-reviewer-escalation-symmetry\`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts\reviewer-regression-governance.md`, `specs\001-specrew-product\contracts\iteration-artifacts.md`  
**Tests**: Deterministic PowerShell integration coverage is required because `spec.md`, `plan.md`, and `quickstart.md` define explicit validation scenarios for reviewer-regression routing, lockout-cap handling, withdrawal, and carry-forward behavior.  
**Scope Boundary**: Keep implementer-side FR-027 behavior unchanged, treat reviewer regressions as soft-warning events unless an FR-004 or FR-010 hold path is active, and never auto-create `.specrew\quality\known-traps.md` when the corpus is absent.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story tasks as `[US1]`, `[US2]`, or `[US3]`
- **[Owner]**: Primary owner role aligned to `spec.md` Requirement Ownership & Delivery
- **[Effort]**: Relative implementation effort estimate (`S`, `M`, `L`)
- Every task keeps explicit traceability to at least one requirement, traceability-governance item, or user-story acceptance target

## Phase 1: Setup (Project Initialization)

**Purpose**: Create the reviewer-regression artifact surface and reusable scratch fixtures before shared governance code changes begin.

- [ ] T001 [Owner: Governance artifact maintainer] [Effort: S] Create the reviewer-regression ledger seed and managed-block contract examples in `.specrew\reviewer-regression-log.md` and `specs\001-specrew-product\contracts\iteration-artifacts.md` (Trace: FR-006, FR-014, contract Iteration State Mirror)
- [ ] T002 [P] [Owner: Review-operations maintainer] [Effort: M] Create baseline scratch-project fixtures for reviewer-regression scenarios in `tests\integration\fixtures\reviewer-regression-event\project\.specrew\iteration-config.yml`, `tests\integration\fixtures\lockout-chain-cap\project\.squad\decisions.md`, `tests\integration\fixtures\reviewer-regression-withdrawal\project\specs\008-sample\iterations\001\state.md`, and `tests\integration\fixtures\carry-forward-closed-iteration\project\specs\008-sample\iterations\001\state.md` (Trace: quickstart.md, US1 independent test, US2 independent test, US3 independent test, TG-001, TG-002, TG-003)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared helpers and runtime plumbing that every reviewer-regression story depends on.

**⚠️ CRITICAL**: No user-story implementation should begin until this phase is complete.

- [ ] T003 [Owner: Governance artifact maintainer] [Effort: M] Add reviewer-regression ledger parsing, `reviewer-regression-state` managed-block helpers, and structured decision-type support in `extensions\specrew-speckit\scripts\shared-governance.ps1` (Trace: FR-006, FR-008, FR-011)
- [ ] T004 [Owner: Lifecycle-routing maintainer] [Effort: M] Create the `report`, `resolve`, `withdraw`, `project`, and `get` mode shell in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` (Trace: contract Script Interface, FR-001, FR-008, FR-014, TG-001, TG-003)
- [ ] T005 [P] [Owner: Runtime routing maintainer] [Effort: S] Extend runtime model-routing sync for `reviewerRegressionState` in `extensions\specrew-speckit\scripts\sync-squad-model-overrides.ps1` and `.squad\config.json` without changing `activeEscalation` behavior (Trace: FR-013, contract Runtime Config Sync)
- [ ] T006 [P] [Owner: Governance artifact maintainer] [Effort: M] Extend governance validation for reviewer-regression ledger, state, and decisions invariants in `extensions\specrew-speckit\scripts\validate-governance.ps1` (Trace: FR-007, FR-011, FR-015)
- [ ] T007 [P] [Owner: Coordinator handoff maintainer] [Effort: M] Surface reviewer-regression escalation and routing-fallback signals in `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1` and `scripts\specrew-review.ps1` (Trace: FR-011, SC-004)

**Checkpoint**: Shared ledger parsing, state projection, runtime sync, governance validation, and reviewer replay surfaces are ready for story-specific behavior.

---

## Phase 3: User Story 1 - Escalate review after a reviewer regression (Priority: P1) 🎯 MVP

**Goal**: Record human-found reviewer regressions and move the feature's remaining review work to a stronger reviewer path, or hold for human direction when no safe path remains.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\reviewer-regression-event.ps1` and `pwsh -NoProfile -File .\tests\integration\reviewer-regression-ledger.ps1` to confirm reviewer-regression events are logged, stronger-class routing is selected when available, same-class fallback requires an independent owner, and maximum-strength cases hold for human direction.

### Tests for User Story 1

- [ ] T008 [P] [US1] [Owner: Review-operations maintainer] [Effort: S] Build stronger-class, same-class-fallback, and maximum-strength-hold fixtures in `tests\integration\fixtures\reviewer-regression-event\project\.specrew\iteration-config.yml`, `tests\integration\fixtures\reviewer-regression-event\project\.specrew\role-assignments.yml`, and `tests\integration\fixtures\reviewer-regression-event\project\specs\008-sample\iterations\001\state.md` (Trace: US1 acceptance scenarios 2-4)
- [ ] T009 [P] [US1] [Owner: Review-operations maintainer] [Effort: M] Add event-reporting and reviewer-routing regression coverage in `tests\integration\reviewer-regression-event.ps1` (Trace: FR-001, FR-002, FR-003, FR-004)
- [ ] T010 [P] [US1] [Owner: Governance artifact maintainer] [Effort: M] Add ledger and active-chain projection assertions in `tests\integration\reviewer-regression-ledger.ps1` (Trace: FR-005, FR-006, FR-015)

### Implementation for User Story 1

- [ ] T011 [US1] [Owner: Reviewer-governance policy maintainer] [Effort: L] Implement reviewer-regression event logging, chain deduplication, and strongest-class selection from `.specrew\iteration-config.yml` and `.specrew\role-assignments.yml` in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` (Trace: FR-001, FR-002, FR-003, FR-015)
- [ ] T012 [US1] [Owner: Lifecycle-routing maintainer] [Effort: M] Implement same-class independent-owner fallback, maximum-strength human-direction hold, and active-chain readback in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` (Trace: FR-003, FR-004, FR-005)
- [ ] T013 [P] [US1] [Owner: Coordinator handoff maintainer] [Effort: M] Update routed reviewer/coordinator guidance for stronger-class escalation and human-direction hold in `extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, `.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md`, `extensions\specrew-speckit\squad-templates\agents\reviewer\charter.md`, `.specify\extensions\specrew-speckit\squad-templates\agents\reviewer\charter.md`, `.squad\agents\reviewer\charter.md`, and `.github\agents\squad.agent.md` (Trace: FR-002, FR-004, TG-006)

**Checkpoint**: User Story 1 is complete when a reported reviewer miss immediately produces auditable routing to a stronger reviewer path or an explicit human-direction hold.

---

## Phase 4: User Story 2 - Bound implementer lockout growth after repeated reviewer-missed defects (Priority: P1)

**Goal**: Stop unlimited implementer rotation after reviewer regressions by enforcing the configured cap and making the next-owner path visible everywhere the workflow relies on it.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\lockout-chain-cap.ps1`, `pwsh -NoProfile -File .\tests\integration\reviewer-closeout-governance.ps1`, and `pwsh -NoProfile -File .\tests\integration\review-command.ps1` to confirm the cap activates after the default two extra rotations, only human or explicitly approved alternate ownership is allowed after the cap, and the resulting state is visible in handoff outputs.

### Tests for User Story 2

- [ ] T014 [P] [US2] [Owner: Review-operations maintainer] [Effort: S] Build cap-hit, alternate-owner-approved, and awaiting-human-owned-revision fixtures in `tests\integration\fixtures\lockout-chain-cap\project\.squad\decisions.md`, `tests\integration\fixtures\lockout-chain-cap\project\.squad\config.json`, and `tests\integration\fixtures\lockout-chain-cap\project\specs\008-sample\iterations\001\state.md` (Trace: US2 acceptance scenarios 1-3)
- [ ] T015 [P] [US2] [Owner: Review-operations maintainer] [Effort: M] Add implementer lockout-cap regression coverage in `tests\integration\lockout-chain-cap.ps1` (Trace: FR-009, FR-010)
- [ ] T016 [P] [US2] [Owner: Coordinator handoff maintainer] [Effort: M] Extend reviewer closeout and replay assertions for cap visibility and next-owner summary in `tests\integration\reviewer-closeout-governance.ps1` and `tests\integration\review-command.ps1` (Trace: FR-011, SC-004)

### Implementation for User Story 2

- [ ] T017 [US2] [Owner: Runtime routing maintainer] [Effort: L] Implement lockout-chain counting, cap activation, and post-cap human or approved-alternate-owner routing in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` (Trace: FR-009, FR-010)
- [ ] T018 [US2] [Owner: Decisions-ledger maintainer] [Effort: M] Record `lockout-cap` and reviewer-routing evidence entries through `extensions\specrew-speckit\scripts\shared-governance.ps1` and `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` into `.squad\decisions.md` (Trace: FR-010, FR-011, contract Decisions Ledger)
- [ ] T019 [US2] [Owner: Coordinator handoff maintainer] [Effort: M] Surface locked-out agents, cap status, and planned next-owner path in `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1`, `scripts\specrew-review.ps1`, and `.squad\routing.md` (Trace: FR-011, TG-005)

**Checkpoint**: User Story 2 is complete when the implementer chain cannot grow past the configured cap without explicit human-owned or approved alternate-owner routing and the cap is visible in reviewer-facing outputs.

---

## Phase 5: User Story 3 - Preserve governance memory and recover from misreports (Priority: P2)

**Goal**: Keep reviewer regressions auditable, support clean-pass de-escalation and closed-iteration carry-forward, and handle withdrawals without rewriting completed history.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\reviewer-regression-withdrawal.ps1`, `pwsh -NoProfile -File .\tests\integration\carry-forward-closed-iteration.ps1`, `pwsh -NoProfile -File .\tests\integration\reviewer-regression-ledger.ps1`, and `pwsh -NoProfile -File .\tests\integration\gap-governance.ps1` to confirm withdrawal reverses only pending state, confirmed events remain auditable, candidate-trap behavior degrades cleanly when the corpus is absent, and post-close reports seed the next active iteration.

### Tests for User Story 3

- [ ] T020 [P] [US3] [Owner: Governance artifact maintainer] [Effort: M] Build withdrawal, duplicate-report, carry-forward, and corpus-disabled fixtures in `tests\integration\fixtures\reviewer-regression-withdrawal\project\.squad\decisions.md`, `tests\integration\fixtures\carry-forward-closed-iteration\project\specs\008-sample\iterations\001\state.md`, and `tests\integration\fixtures\reviewer-regression-ledger\project\.specrew\reviewer-regression-log.md` (Trace: US3 acceptance scenarios 1-5)
- [ ] T021 [P] [US3] [Owner: Review-operations maintainer] [Effort: M] Add withdrawal and misreport regression coverage in `tests\integration\reviewer-regression-withdrawal.ps1` (Trace: FR-008)
- [ ] T022 [P] [US3] [Owner: Spec-governance maintainer] [Effort: M] Add closed-iteration carry-forward regression coverage in `tests\integration\carry-forward-closed-iteration.ps1` (Trace: FR-014)
- [ ] T023 [P] [US3] [Owner: Quality-governance maintainer] [Effort: M] Extend ledger consistency and known-traps degraded-path assertions in `tests\integration\reviewer-regression-ledger.ps1` and `tests\integration\gap-governance.ps1` (Trace: FR-006, FR-012, FR-015)

### Implementation for User Story 3

- [ ] T024 [US3] [Owner: Governance artifact maintainer] [Effort: L] Implement withdrawal reversal, clean-pass de-escalation, and repeated-event consolidation in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` (Trace: FR-005, FR-008, FR-015)
- [ ] T025 [US3] [Owner: Quality-governance maintainer] [Effort: M] Implement conditional candidate-trap proposal and unapproved-trap cleanup against `.specrew\quality\known-traps.md` in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` and `extensions\specrew-speckit\scripts\validate-governance.ps1` (Trace: FR-012, TG-008)
- [ ] T026 [US3] [Owner: Spec-governance maintainer] [Effort: M] Preserve closed-iteration history while projecting unresolved reviewer-regression state into the next active iteration in `extensions\specrew-speckit\scripts\manage-reviewer-regression.ps1` and `specs\001-specrew-product\contracts\iteration-artifacts.md` (Trace: FR-014, TG-003)

**Checkpoint**: User Story 3 is complete when reviewer-regression history stays auditable, withdrawals clean up only pending state, and closed-iteration reports carry forward without reopening historical artifacts.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Re-run the full validation lane and update user-facing documentation after all reviewer-regression flows land.

- [ ] T027 [P] [Owner: Review-operations maintainer] [Effort: M] Run the reviewer-regression validation lane in `tests\integration\reviewer-regression-event.ps1`, `tests\integration\lockout-chain-cap.ps1`, `tests\integration\reviewer-regression-ledger.ps1`, `tests\integration\reviewer-regression-withdrawal.ps1`, `tests\integration\carry-forward-closed-iteration.ps1`, `tests\integration\gap-governance.ps1`, and `extensions\specrew-speckit\scripts\validate-governance.ps1` (Trace: quickstart validation commands, FR-001, FR-006, FR-008, FR-009, FR-012, FR-014, TG-001, TG-002, TG-003, SC-001, SC-003, SC-004, SC-006)
- [ ] T028 [P] [Owner: Coordinator handoff maintainer] [Effort: S] Document reviewer-regression routing, lockout-cap behavior, and withdrawal semantics in `README.md` and `docs\user-guide.md` (Trace: FR-002, FR-008, FR-010, FR-011, FR-013, SC-001, SC-004, TG-006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 (US1)**: Depends on Phase 2.
- **Phase 4 (US2)**: Depends on Phase 2; implementation tasks also rely on the active reviewer-regression chain introduced in US1.
- **Phase 5 (US3)**: Depends on Phase 2; implementation tasks build on the event logging and state projection from US1.
- **Phase 6 (Polish)**: Depends on the user stories that are in scope for the release.

### User Story Dependencies

- **US1 (P1)**: Starts immediately after the foundational phase and delivers the MVP reviewer-regression routing path.
- **US2 (P1)**: Fixture and test work can start after the foundational phase, but runtime cap enforcement should land after US1 has created the active reviewer-regression chain.
- **US3 (P2)**: Fixture and test work can start after the foundational phase, but withdrawal and carry-forward logic should land after US1 event logging is stable.

### Within Each User Story

- Test fixtures before test assertions.
- Tests should fail before implementation changes land.
- `manage-reviewer-regression.ps1` mode shell (`T004`) before any story-specific runtime behavior.
- Shared-governance helpers (`T003`) before decisions/state-writing tasks.
- Runtime sync and reviewer replay surfaces (`T005`-`T007`) before final validation in `T027`.

---

## Parallel Opportunities

- `T001` and `T002` can run in parallel.
- `T005`, `T006`, and `T007` can run in parallel after `T003` and `T004`.
- `T008`, `T009`, and `T010` can run in parallel once the baseline fixtures from `T002` exist.
- `T014`, `T015`, and `T016` can run in parallel once the foundational phase is complete.
- `T020`, `T021`, `T022`, and `T023` can run in parallel once the foundational phase is complete.
- `T027` and `T028` can run in parallel after the implementation stories are complete.

---

## Parallel Example: User Story 1

```text
Task: "T008 [US1] Build stronger-class, same-class-fallback, and maximum-strength-hold fixtures in tests\integration\fixtures\reviewer-regression-event\..."
Task: "T009 [US1] Add event-reporting and reviewer-routing regression coverage in tests\integration\reviewer-regression-event.ps1"
Task: "T010 [US1] Add ledger and active-chain projection assertions in tests\integration\reviewer-regression-ledger.ps1"
```

## Parallel Example: User Story 2

```text
Task: "T014 [US2] Build cap-hit, alternate-owner-approved, and awaiting-human-owned-revision fixtures in tests\integration\fixtures\lockout-chain-cap\..."
Task: "T015 [US2] Add implementer lockout-cap regression coverage in tests\integration\lockout-chain-cap.ps1"
Task: "T016 [US2] Extend reviewer closeout and replay assertions in tests\integration\reviewer-closeout-governance.ps1 and tests\integration\review-command.ps1"
```

## Parallel Example: User Story 3

```text
Task: "T020 [US3] Build withdrawal, duplicate-report, carry-forward, and corpus-disabled fixtures in tests\integration\fixtures\reviewer-regression-withdrawal\..., tests\integration\fixtures\carry-forward-closed-iteration\..., and tests\integration\fixtures\reviewer-regression-ledger\..."
Task: "T021 [US3] Add withdrawal and misreport regression coverage in tests\integration\reviewer-regression-withdrawal.ps1"
Task: "T022 [US3] Add closed-iteration carry-forward regression coverage in tests\integration\carry-forward-closed-iteration.ps1"
Task: "T023 [US3] Extend ledger consistency and known-traps degraded-path assertions in tests\integration\reviewer-regression-ledger.ps1 and tests\integration\gap-governance.ps1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Stop and run the US1 independent test lane before adding lockout-cap or withdrawal work.

### Incremental Delivery

1. Ship the shared reviewer-regression artifact and runtime plumbing.
2. Deliver US1 so reviewer misses immediately change review routing.
3. Add US2 so implementer rotation is capped and visible.
4. Add US3 so withdrawals, carry-forward, and candidate-trap behavior are deterministic.
5. Finish with the full validation lane and documentation updates.

### Guardrails

- Do **not** change `extensions\specrew-speckit\scripts\manage-escalation-state.ps1` except for compatibility verification; FR-027 remains authoritative.
- Do **not** auto-create `.specrew\quality\known-traps.md`; only integrate with it when the corpus already exists and is enabled.
- Do **not** reopen closed iterations implicitly; carry-forward must seed the next active iteration instead.

---

## Notes

- All tasks use the required checklist format `- [ ] T### ...` with added `[Owner: ...]` and `[Effort: ...]` governance metadata.
- Setup, Foundational, and Polish tasks intentionally omit story labels.
- User-story tasks use `[US1]`, `[US2]`, or `[US3]` for direct traceability to `spec.md`.
- `[P]` marks tasks that can run in parallel once the stated prerequisites are satisfied.
- `[Owner: ...]` values align to the owner-role groupings defined in `spec.md` Requirement Ownership & Delivery.
- `[Effort: ...]` values provide the missing size estimate required by the after-tasks governance gate.
- Every task names concrete repository paths so an implementation agent can execute the work without re-deriving scope from the plan.
