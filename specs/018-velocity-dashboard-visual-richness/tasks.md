# Tasks: Velocity Dashboard Visual Richness + PoC-Parity Restoration

**Input**: Design documents from `specs/018-velocity-dashboard-visual-richness/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/dashboard-rich-rendering-contract.md`, `contracts/dashboard-artifact-encoding-contract.md`

**Tests**: This feature requires fixture-backed unit, integration, validator, artifact, performance, and manual verification coverage.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently while preserving the approved single-iteration scope.

## Format

Every task in this file follows the required checklist format:

`- [ ] T### optional [P] optional [US#] [Owner: role] [Effort: S|M|L] Description with exact file path(s) (Trace: requirement/story/governance refs)`

---

## Phase 1: Setup

**Purpose**: Create the feature-specific quality and fixture scaffolding used by the implementation.

- [X] T001 [Owner: Reliability steward] [Effort: S] Create feature quality evidence scaffolding in `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` and `specs/018-velocity-dashboard-visual-richness/quality/quality-evidence.md` (Trace: FR-018, TG-004, SC-004)
- [X] T002 [P] [Owner: Test steward] [Effort: S] Create Feature 018 fixture roots in `tests/integration/fixtures/feature-018-dashboard/rich-capable-repository/`, `tests/integration/fixtures/feature-018-dashboard/monochrome-repository/`, `tests/integration/fixtures/feature-018-dashboard/closeout-repository/`, and `tests/integration/fixtures/feature-018-dashboard/performance-repository/` (Trace: FR-016, FR-017, SC-004)

**Checkpoint**: Feature-specific quality artifacts and fixture directories exist.

---

## Phase 2: Foundational

**Purpose**: Add the shared option plumbing and renderer policy needed before story work can proceed.

**⚠️ CRITICAL**: Complete this phase before starting user-story implementation.

- [X] T003 [Owner: CLI steward] [Effort: M] Extend CLI parsing and help text for `--ASCII`, `--RecentCount`, and `--BarWidth` in `scripts/specrew-where.ps1` (Trace: FR-005, FR-008, FR-019)
- [X] T004 [Owner: CLI steward] [Effort: M] Thread render-option arguments from `scripts/specrew.ps1` and `scripts/specrew-where.ps1` into `scripts/internal/dashboard-renderer.ps1` (Trace: FR-001, FR-005, FR-008, TG-004)
- [X] T005 [Owner: UX steward] [Effort: M] Add shared rendering-profile, terminal-capability, and snapshot-option helpers in `scripts/internal/dashboard-renderer.ps1` (Trace: FR-004, FR-005, TG-004)

**Checkpoint**: The command surface and renderer share one bounded rendering-policy path.

---

## Phase 3: User Story 1 - Read a richer dashboard at a glance (Priority: P1) 🎯 MVP

**Goal**: Restore PoC-level information density with richer live rendering while keeping the dashboard bounded to the approved five pillars.

**Independent Test**: Render the dashboard in a rich-capability terminal and verify one screen reveals the active feature, recent shipped items, velocity context, roadmap intent, and footer guidance without opening other artifacts.

### Tests for User Story 1

- [X] T006 [US1] [Owner: Test steward] [Effort: M] Create rich-mode unit assertions for Unicode primitives, header context, section emphasis, roadmap descriptions, and the velocity sparkline in `tests/unit/feature-018-dashboard.tests.ps1` (Trace: US1, FR-004, FR-006, FR-011, FR-013, SC-001)
- [X] T007 [US1] [Owner: Test steward] [Effort: M] Create rich dashboard integration replay coverage and expected rich output in `tests/integration/feature-018-rich-dashboard.ps1` and `tests/integration/fixtures/feature-018-dashboard/rich-capable-expected.txt` (Trace: US1, FR-004, FR-008, FR-011, FR-013, SC-001)

### Implementation for User Story 1

- [X] T008 [US1] [Owner: UX steward] [Effort: M] Implement rich-mode glyph palettes, horizontal rules, and section emphasis in `scripts/internal/dashboard-renderer.ps1` (Trace: US1, FR-004, SC-001)
- [X] T009 [US1] [Owner: UX steward] [Effort: M] Implement `Today:` and `Captured:` header context, active-feature arrow emphasis, and richer footer guidance in `scripts/internal/dashboard-renderer.ps1` (Trace: US1, FR-006, FR-007, FR-012, SC-001)
- [X] T010 [US1] [Owner: Product steward] [Effort: L] Implement Recent Shipped density restoration with feature labels, delivered story points, iteration counts, close dates, and `--RecentCount` / `--BarWidth` rendering in `scripts/internal/dashboard-renderer.ps1` (Trace: US1, FR-008, SC-001)
- [X] T011 [US1] [Owner: Product steward] [Effort: M] Implement velocity sample-basis text and the velocity-only sparkline in `scripts/internal/dashboard-renderer.ps1` (Trace: US1, FR-009, FR-013, FR-014, SC-001)
- [X] T012 [US1] [Owner: Roadmap steward] [Effort: M] Implement roadmap status markers, progress summaries, per-phase description lines, and 80-character truncation in `scripts/internal/dashboard-renderer.ps1` (Trace: US1, FR-011, SC-001)
- [X] T013 [US1] [Owner: Test steward] [Effort: S] Populate representative rich fixture repository data in `tests/integration/fixtures/feature-018-dashboard/rich-capable-repository/` and `tests/integration/fixtures/feature-018-dashboard/rich-capable-expected.txt` (Trace: US1, FR-016, SC-004)

**Checkpoint**: Rich-capable terminals show the denser dashboard with the approved sparkline-only addition.

---

## Phase 4: User Story 2 - Trust the dashboard across terminal capabilities (Priority: P1)

**Goal**: Keep the dashboard readable and semantically stable across rich and monochrome environments without changing lifecycle or closeout behavior.

**Independent Test**: Render once in a rich-capability environment and once in a monochrome-safe environment, then verify both outputs preserve the same meaning while the fallback remains ANSI-free and ASCII-safe.

### Tests for User Story 2

- [X] T014 [US2] [Owner: Test steward] [Effort: M] Create monochrome fallback integration assertions and expected ASCII output in `tests/integration/feature-018-rich-dashboard.ps1` and `tests/integration/fixtures/feature-018-dashboard/monochrome-expected.txt` (Trace: US2, FR-005, FR-014, FR-017, SC-004)
- [X] T015 [US2] [Owner: Test steward] [Effort: M] Create artifact-encoding unit assertions for ANSI stripping, Unicode preservation, and fixed empty states in `tests/unit/feature-018-dashboard.tests.ps1` (Trace: US2, FR-004, FR-017, SC-004)

### Implementation for User Story 2

- [X] T016 [US2] [Owner: UX steward] [Effort: M] Implement rich-eligibility detection honoring `--ASCII`, `--no-color`, `NO_COLOR`, `NO_UNICODE`, `TERM=dumb`, redirected output, `LANG`, and Windows virtual-terminal support in `scripts/internal/dashboard-renderer.ps1` (Trace: US2, FR-005, TG-004)
- [X] T017 [US2] [Owner: UX steward] [Effort: M] Implement ASCII-safe substitute markers and explicit empty-state messages for Active Work, Recent Shipped, Velocity, Roadmap, and Warnings in `scripts/internal/dashboard-renderer.ps1` (Trace: US2, FR-005, FR-007, FR-008, FR-009)
- [X] T018 [US2] [Owner: Product steward] [Effort: M] Preserve Feature 017 section order plus plan-vs-reality, full-history, projection, and warning semantics while layering fallback-safe formatting in `scripts/internal/dashboard-renderer.ps1` (Trace: US2, FR-001, FR-010, TG-004)
- [X] T019 [US2] [Owner: UX steward] [Effort: S] Strip ANSI sequences while preserving Unicode glyphs in stored dashboard artifacts generated by `scripts/internal/dashboard-renderer.ps1` (Trace: US2, FR-004, SC-004)
- [X] T020 [US2] [Owner: Reliability steward] [Effort: M] Keep closeout snapshot scaffolds aligned with fallback and artifact rules in `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, `.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, and `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` (Trace: US2, FR-001, FR-004, TG-004)

**Checkpoint**: Rich mode stays opt-in by capability, fallback remains trustworthy, and stored snapshots preserve closeout semantics.

---

## Phase 5: User Story 3 - Adopt the richer view without regressions (Priority: P2)

**Goal**: Prove the richer dashboard can ship without regressing Feature 017 behavior, validator expectations, documentation clarity, or the 1.5 second render budget.

**Independent Test**: Run the existing dashboard suite plus the new rich/monochrome fixtures on representative repositories and confirm the renderer still meets the 1.5 second budget.

### Tests for User Story 3

- [X] T021 [P] [US3] [Owner: Test steward] [Effort: M] Extend regression assertions for Feature 017 parity and new flag defaults in `tests/unit/feature-017-dashboard.tests.ps1` and `tests/unit/feature-018-dashboard.tests.ps1` (Trace: US3, FR-015, SC-003)
- [X] T022 [P] [US3] [Owner: Test steward] [Effort: M] Extend integration coverage for validator compatibility, closeout immutability, and artifact encoding in `tests/integration/feature-017-dashboard-core.ps1`, `tests/integration/feature-018-rich-dashboard.ps1`, and `tests/integration/fixtures/feature-018-dashboard/closeout-repository/` (Trace: US3, FR-015, FR-016, FR-017, SC-003, SC-004)

### Implementation for User Story 3

- [X] T023 [US3] [Owner: Reliability steward] [Effort: M] Update validator artifact checks for ANSI-free, Unicode-preserving dashboard snapshots in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` (Trace: US3, FR-015, FR-016, SC-004)
- [X] T024 [US3] [Owner: Reliability steward] [Effort: M] Add the 16-feature render-budget harness and performance fixture data in `tests/integration/feature-018-render-budget.ps1` and `tests/integration/fixtures/feature-018-dashboard/performance-repository/` (Trace: US3, FR-018, SC-002)
- [X] T025 [US3] [Owner: Reliability steward] [Effort: S] Capture hardening-gate and manual governance evidence in `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` and `specs/018-velocity-dashboard-visual-richness/quality/quality-evidence.md` (Trace: US3, TG-004, SC-004, SC-005)
- [X] T026 [US3] [Owner: Documentation steward] [Effort: M] Update manual verification flows for rich default mode, ASCII fallback, artifact capture, and performance checks in `tests/manual/feature-017-dashboard-quickstart.md` and `specs/018-velocity-dashboard-visual-richness/quickstart.md` (Trace: US3, FR-019, FR-020, SC-005)
- [X] T027 [US3] [Owner: Documentation steward] [Effort: M] Update user-facing guidance for rich rendering, fallback rules, new flags, snapshot behavior, and validation expectations in `docs/dashboard-guide.md` and `README.md` (Trace: US3, FR-019, FR-020, SC-005)

**Checkpoint**: The richer dashboard remains verifiably compatible, documented, and within budget.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run the full verification lane, confirm deferrals stayed deferred, and finish the cross-cutting evidence trail.

- [X] T028 [P] [Owner: Reliability steward] [Effort: M] Replay automated dashboard validation via `tests/unit/feature-017-dashboard.tests.ps1`, `tests/unit/feature-018-dashboard.tests.ps1`, `tests/integration/feature-017-dashboard-core.ps1`, `tests/integration/feature-018-rich-dashboard.ps1`, and `tests/integration/feature-018-render-budget.ps1` (Trace: FR-015, FR-016, FR-017, FR-018, SC-002, SC-003, SC-004)
- [X] T029 [P] [Owner: Reliability steward] [Effort: M] Replay governance snapshot validation via `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1`, and `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` (Trace: FR-001, FR-004, FR-015, TG-004, SC-004)
- [X] T030 [Owner: Spec Steward] [Effort: S] Confirm explicit deferrals stay excluded and summarize final verification results in `specs/018-velocity-dashboard-visual-richness/quality/quality-evidence.md`, `docs/dashboard-guide.md`, and `README.md` (Trace: FR-001, FR-002, FR-003, TG-004, SC-005)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Setup creates the quality and fixture scaffolding used by foundational work.
- **Phase 2 → Phases 3-5**: Foundational CLI and renderer policy changes block all user stories.
- **Phase 3 and Phase 4**: US1 and US2 can begin after Phase 2 and may run in parallel if staffed.
- **Phase 5**: US3 depends on US1 and US2 surfaces being present because it validates regression, performance, docs, and artifact compatibility across the completed rendering changes.
- **Phase 6**: Polish depends on all desired story phases being complete.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational; no dependency on other user stories.
- **US2 (P1)**: Starts after Foundational; no dependency on US1 for execution, but its results must remain semantically aligned with US1.
- **US3 (P2)**: Starts after US1 and US2 implementation surfaces exist.

### Delivery Graph

`Setup → Foundational → {US1, US2} → US3 → Polish`

---

## Parallel Opportunities

- `T002` can run in parallel with `T001` after the task file is accepted.
- `T021` and `T022` can run in parallel during US3 because they touch separate unit and integration surfaces.
- `T028` and `T029` can run in parallel during final verification because they replay different validation lanes.
- US1 and US2 can be implemented in parallel once Phase 2 is complete, provided shared renderer edits are coordinated.

### Parallel Example: User Story 1

```text
Task: T006 Create rich-mode unit assertions in tests/unit/feature-018-dashboard.tests.ps1
Task: T007 Create rich dashboard integration replay coverage in tests/integration/feature-018-rich-dashboard.ps1 and tests/integration/fixtures/feature-018-dashboard/rich-capable-expected.txt
```

### Parallel Example: User Story 2

```text
Task: T014 Create monochrome fallback integration assertions in tests/integration/feature-018-rich-dashboard.ps1 and tests/integration/fixtures/feature-018-dashboard/monochrome-expected.txt
Task: T015 Create artifact-encoding unit assertions in tests/unit/feature-018-dashboard.tests.ps1
```

### Parallel Example: User Story 3

```text
Task: T021 Extend regression assertions in tests/unit/feature-017-dashboard.tests.ps1 and tests/unit/feature-018-dashboard.tests.ps1
Task: T022 Extend integration coverage in tests/integration/feature-017-dashboard-core.ps1, tests/integration/feature-018-rich-dashboard.ps1, and tests/integration/fixtures/feature-018-dashboard/closeout-repository/
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1
4. Validate the rich-capable dashboard end to end before moving on

### Incremental Delivery

1. Finish Setup + Foundational once
2. Deliver US1 for rich at-a-glance value
3. Deliver US2 to lock in compatibility and closeout trust
4. Deliver US3 to prove regression safety, documentation clarity, and performance
5. Finish Polish with the full validation replay

### Suggested MVP Scope

- **MVP**: Phase 1, Phase 2, and Phase 3 (User Story 1)
- **Do not pull in deferred scope**: working-days projection, MVP-versus-1.0 dual horizons, minimum-days sample stretching, bootstrapped-date schema changes, configurable velocity sample windows, or additional visualizations beyond the single velocity sparkline

---

## Hardening & Verification Surfaces

- `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md`
- `specs/018-velocity-dashboard-visual-richness/quality/quality-evidence.md`
- `tests/integration/feature-018-rich-dashboard.ps1`
- `tests/integration/feature-018-render-budget.ps1`
- `tests/unit/feature-018-dashboard.tests.ps1`
- `extensions/specrew-speckit/scripts/validate-governance.ps1`
- `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`

## Explicit Deferrals To Preserve

- No working-days projection changes
- No MVP-versus-1.0 dual-horizon logic
- No minimum-days velocity sample stretching
- No bootstrapped-date schema updates
- No configurable velocity sample windows
- No new visualizations outside the single Velocity sparkline
- No lifecycle-trigger or closeout-semantics expansion beyond Feature 017 behavior
