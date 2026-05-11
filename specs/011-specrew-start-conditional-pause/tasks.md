# Tasks: Conditional Pause on specrew-start When Session-Loaded Files Changed

**Input**: Design documents from `C:\Dev\Specrew\specs\011-specrew-start-conditional-pause\`  
**Prerequisites**: `plan.md`, `spec.md`  
**Tests**: Deterministic PowerShell integration coverage is required because `spec.md` defines explicit validation scenarios for change detection, pause-and-confirm behavior, parameter handling, and auto-continue preservation.  
**Scope Boundary**: Keep change detector focused on session-loaded paths only; treat auto-continue preservation as non-negotiable for routine resumes; scaffold-replay-path assertions required for visibility output (pause messages, file lists, custom directives) per test-integrity corpus guidance from specs/005-stack-aware-quality-bar.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story tasks as `[US1]`, `[US2]`, or `[US3]`
- **[Owner]**: Primary owner role aligned to `spec.md` Requirement Ownership & Delivery
- **[Effort]**: Relative implementation effort estimate (`S`, `M`, `L`)
- Every task keeps explicit traceability to at least one requirement (FR-*) or user story

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Prepare test fixtures and baseline artifacts before detector and pause-and-confirm logic implementation begins.

- [ ] T029 [Owner: Infrastructure maintainer] [Effort: S] Create baseline tracking structure documentation and examples showing `.specrew/last-start-prompt.md` YAML frontmatter with `baseline_commit_hash` field format in `specs/011-specrew-start-conditional-pause/quickstart.md` (Trace: FR-002)
- [ ] T030 [P] [Owner: Test-infrastructure maintainer] [Effort: S] Create test fixture directory structure and template scaffolds in `tests/integration/fixtures/specrew-start-detector/` for change-detection test scenarios (no changes, with changes, bootstrap case) (Trace: FR-001, FR-002)
- [ ] T031 [Owner: Quality governance maintainer] [Effort: S] Create planning-time hardening-gate.md artifact at `specs/011-specrew-start-conditional-pause/quality/hardening-gate.md` documenting Phase 1 quality concerns (detector accuracy, baseline tracking durability, auto-continue preservation, signature stability, error fidelity) with evidence expectations and pending sign-off structure; use richer pre-sign-off schema with Overall Verdict: `ready` and explicit pending fields per governance convention (Trace: FR-010)

---

## Phase 2: Foundational (Blocking Prerequisites for Iteration 001)

**Purpose**: Implement the core change detector logic and baseline tracking mechanism before pause-and-confirm and parameter features are added.

**⚠️ CRITICAL**: Iteration 001 (detector + baseline + preservation) must complete before Iteration 002 user-facing features begin.

- [ ] T032 [Owner: Script maintainer] [Effort: M] Implement `git diff --name-only` change detector against baseline commit in `scripts/specrew-start.ps1`, scanning session-loaded paths (`.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, `.squad/agents/*/charter.md`) and returning list of changed files or empty list on first run (Trace: FR-001)
- [ ] T033 [Owner: Script maintainer] [Effort: M] Implement baseline commit tracking in `.specrew/last-start-prompt.md` YAML frontmatter: read existing `baseline_commit_hash` field, validate 40-character git SHA format, update to current HEAD after detector runs, handle missing/empty field by defaulting to HEAD (Trace: FR-002)
- [ ] T034 [Owner: Script maintainer] [Effort: S] Preserve auto-continue directive when detector reports zero changes (revert to spec 001 Session 2026-05-04 behavior for routine resumes, no changes = auto-continue) in `scripts/specrew-start.ps1` (Trace: FR-004)
- [ ] T035 [Owner: Script maintainer] [Effort: S] Verify `specrew-start.ps1` signature, documented arguments, and defaults remain unchanged (no breaking changes except new optional `-PostRestartDirective` parameter in Iteration 002) in `scripts/specrew-start.ps1` (Trace: FR-006)
- [ ] T036 [Owner: Script maintainer] [Effort: S] Preserve all existing error messages ("Project is not fully bootstrapped", "Session state invalid", etc.) in their current locations and add new pause-and-confirm messages additively (no modification to existing error paths) in `scripts/specrew-start.ps1` (Trace: FR-007)

**Checkpoint**: Planning-time hardening-gate artifact created and ready for Iteration 001 sign-off; test fixtures and baseline documentation prepared.

---

## Phase 3: Iteration 001 - User Story 1 - Auto-continue behavior is preserved for routine resumes (Priority: P1) 🎯 MVP

**Goal**: Verify that change detection infrastructure does not break existing auto-continue behavior for sessions where no session-loaded files have changed since the last run.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\specrew-start-change-detector.ps1` and `pwsh -NoProfile -File .\tests\integration\specrew-start-auto-continue-preservation.ps1` to confirm detector correctly identifies zero changes in routine resumes and auto-continue directive is preserved in all cases.

### Tests for User Story 1 (Mandatory - TDD Approach)

- [ ] T037 [P] [US1] [Owner: Test infrastructure maintainer] [Effort: M] Write test fixtures and scaffolds for routine resume scenarios (no commits to session-loaded paths, multiple runs in same session state) in `tests/integration/fixtures/specrew-start-detector/routine-resume/` (Trace: SC-001, SC-002)
- [ ] T038 [P] [US1] [Owner: Test infrastructure maintainer] [Effort: M] Write deterministic tests in `tests/integration/specrew-start-change-detector.ps1` asserting that detector returns empty list when no session-loaded files have changed between runs (Trace: FR-001, SC-001, SC-002)
- [ ] T039 [P] [US1] [Owner: Test infrastructure maintainer] [Effort: M] Write deterministic tests in `tests/integration/specrew-start-auto-continue-preservation.ps1` asserting that regenerated `.specrew/last-start-prompt.md` includes auto-continue directive when no changes detected (Trace: FR-004, SC-001)
- [ ] T040 [P] [US1] [Owner: Test infrastructure maintainer] [Effort: M] Write baseline tracking tests in `tests/integration/specrew-start-baseline-tracking.ps1` asserting YAML frontmatter serialization/deserialization of `baseline_commit_hash` field survives round-trip (read, update, write, reread) (Trace: FR-002, SC-002)

### Implementation for User Story 1

- [ ] T041 [US1] [Owner: Script maintainer] [Effort: L] Integrate change detector logic from T032, baseline tracking from T033, auto-continue preservation from T034 into single cohesive flow in `scripts/specrew-start.ps1` ensuring detector runs after bootstrap check but before handoff directive generation (Trace: FR-001, FR-002, FR-004)
- [ ] T042 [P] [US1] [Owner: Review-operations maintainer] [Effort: M] Run test suite for T037-T040 against T041 implementation and verify all tests pass (zero changes detected = auto-continue preserved) (Trace: SC-001, SC-002)

**Checkpoint**: User Story 1 complete — routine resumes preserve auto-continue behavior unchanged; detector logic is correct and baseline tracking is durable.

---

## Phase 4: Iteration 002 - User Story 2 - Session-loaded file changes trigger pause-and-confirm, allowing user directives (Priority: P1)

**Goal**: When committed changes to session-loaded files are detected, the regenerated handoff pauses with a clear message, lists which files changed, and asks the user to confirm or provide directives before Squad's coordinator auto-continues.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\specrew-start-pause-and-confirm.ps1` to confirm pause-and-confirm directive is injected when changes detected, message is clear and lists files, and user can read and respond before coordinator continues.

### Tests for User Story 2 (Mandatory - TDD Approach)

- [ ] T043 [P] [US2] [Owner: Test infrastructure maintainer] [Effort: M] Write test fixtures for session-loaded file change scenarios (committed change to `.github/agents/squad.agent.md`, committed changes to `.squad/agents/*/charter.md`, mixed changes) in `tests/integration/fixtures/specrew-start-detector/with-changes/` (Trace: SC-003)
- [ ] T044 [P] [US2] [Owner: Test infrastructure maintainer] [Effort: M] Write deterministic tests in `tests/integration/specrew-start-pause-and-confirm.ps1` asserting that pause-and-confirm directive is injected when detector reports changed session-loaded files and message format includes file list (Trace: FR-003, FR-009, SC-003)
- [ ] T045 [P] [US2] [Owner: Test infrastructure maintainer] [Effort: M] Write scaffold-replay-path visibility tests in `tests/integration/specrew-start-pause-and-confirm.ps1` invoking `scaffold-reviewer-artifacts.ps1` and `specrew-review.ps1` to assert pause messages render correctly in handoff output (per test-integrity corpus from specs/005) (Trace: FR-009, FR-010, TG-006)
- [ ] T046 [P] [US2] [Owner: Test infrastructure maintainer] [Effort: S] Write tests in `tests/integration/specrew-start-change-detector.ps1` confirming detector correctly identifies changed session-loaded paths via `git diff --name-only` (Trace: FR-001)

### Implementation for User Story 2

- [ ] T047 [US2] [Owner: Script maintainer] [Effort: L] Implement pause-and-confirm directive injection in `scripts/specrew-start.ps1` when detector reports changed files: clear message stating "Session-loaded files changed:", file list from `git diff --name-only` output, user confirmation/directive prompt (Trace: FR-003)
- [ ] T048 [US2] [Owner: Script maintainer] [Effort: M] Implement detector visibility output in `.specrew/last-start-prompt.md` YAML frontmatter and/or markdown section showing structured field with list of changed files (e.g., `## Session-Loaded Files Changed: .github/agents/squad.agent.md`) for user readback (Trace: FR-009)
- [ ] T049 [P] [US2] [Owner: Review-operations maintainer] [Effort: M] Run test suite for T043-T046 against T047-T048 implementation and verify pause-and-confirm messages render correctly in scaffold-replay-path output (Trace: SC-003)

**Checkpoint**: User Story 2 complete — session-loaded file changes trigger pause-and-confirm; user sees clear message, file list, and can inject directives before coordinator continues.

---

## Phase 5: Iteration 002 - User Story 3 - User can prepend custom post-restart directives via `-PostRestartDirective` parameter (Priority: P2)

**Goal**: Power users can supply a `-PostRestartDirective` parameter on the `specrew-start.ps1` command line to prepend a custom first-message directive (e.g., "Focus on reviewer performance validation") to the regenerated handoff, appearing before any pause-and-confirm or auto-continue logic.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\specrew-start-parameter-handling.ps1` and `pwsh -NoProfile -File .\tests\integration\specrew-start-end-to-end.ps1` to confirm parameter is accepted, custom directive appears verbatim as first instruction, prepending works correctly with both changed and unchanged session-loaded files, and parameter is optional (empty string handled gracefully).

### Tests for User Story 3 (Mandatory - TDD Approach)

- [ ] T050 [P] [US3] [Owner: Test infrastructure maintainer] [Effort: S] Write test fixtures for parameter scenarios (with parameter + no changes, with parameter + with changes, without parameter, empty parameter string) in `tests/integration/fixtures/specrew-start-detector/parameter-variants/` (Trace: SC-004, SC-005)
- [ ] T051 [P] [US3] [Owner: Test infrastructure maintainer] [Effort: M] Write deterministic tests in `tests/integration/specrew-start-parameter-handling.ps1` asserting `-PostRestartDirective` parameter is accepted, custom directive prepended verbatim, parameter is optional, empty/null handled gracefully (Trace: FR-005, SC-004, SC-005)
- [ ] T052 [P] [US3] [Owner: Test infrastructure maintainer] [Effort: M] Write end-to-end tests in `tests/integration/specrew-start-end-to-end.ps1` asserting parameter prepending works correctly in combined scenarios (baseline → no changes → custom directive → auto-continue; baseline → changes → custom directive → pause-and-confirm → resume) per SC-006 acceptance scenario (Trace: FR-005, SC-004, SC-005, SC-006)

### Implementation for User Story 3

- [ ] T053 [US3] [Owner: Script maintainer] [Effort: M] Implement `-PostRestartDirective` parameter support in `scripts/specrew-start.ps1` parameter list (optional string, default empty), prepend parameter value to regenerated `.specrew/last-start-prompt.md` before pause-and-confirm or auto-continue logic, ensure prepended text appears verbatim (Trace: FR-005)
- [ ] T054 [P] [US3] [Owner: Review-operations maintainer] [Effort: M] Run test suite for T050-T052 against T053 implementation and verify parameter is accepted, custom directives render correctly in handoff, parameter optional behavior correct (Trace: SC-004, SC-005, SC-006)

**Checkpoint**: User Story 3 complete — `-PostRestartDirective` parameter prepends custom directives correctly; optional parameter behavior is graceful; all visibility output is correct in real handoff scenarios.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Seed known-traps corpus entry, run comprehensive validation lane, and update documentation.

- [ ] T055 [Owner: Quality governance maintainer] [Effort: M] Seed known-traps corpus entry in `.specrew/quality/known-traps.md` documenting the "auto-handoff bypass when session-loaded files change" pattern (discovery date 2026-05-11, category: governance, broken pattern, detection method, remediation guidance) per FR-008 requirements (Trace: FR-008)
- [ ] T056 [Owner: Review-operations maintainer] [Effort: M] Run comprehensive integration test lane: `tests\integration\specrew-start-change-detector.ps1`, `tests\integration\specrew-start-baseline-tracking.ps1`, `tests\integration\specrew-start-auto-continue-preservation.ps1`, `tests\integration\specrew-start-pause-and-confirm.ps1`, `tests\integration\specrew-start-parameter-handling.ps1`, and `tests\integration\specrew-start-end-to-end.ps1` on committed state (Trace: FR-010, quickstart.md validation commands)
- [ ] T057 [P] [Owner: Documentation maintainer] [Effort: S] Update `README.md` and `docs/getting-started.md` with documentation of change detection behavior, pause-and-confirm workflow, and optional `-PostRestartDirective` parameter usage, including practical examples (Trace: FR-001, FR-003, FR-005, FR-009)

**Checkpoint**: Corpus entry seeded, validation lane passes, documentation updated, feature 011 ready for final review.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks Iteration 001 user story implementation.
- **Phase 3 (Iteration 001 - US1)**: Depends on Phase 2; completes detector + baseline + preservation infrastructure.
- **Phase 4 (Iteration 002 - US2)**: Depends on Phase 2 and Phase 3 (uses detector infrastructure); adds pause-and-confirm user-facing behavior.
- **Phase 5 (Iteration 002 - US3)**: Depends on Phase 2 and Phase 3 (uses detector infrastructure); adds optional parameter support.
- **Phase 6 (Polish)**: Depends on Iteration 001 and Iteration 002 implementations.

### Iteration Dependencies

- **Iteration 001** (Phases 1-2-3, T029-T042): Planning-time hardening-gate creation, detector logic, baseline tracking, auto-continue preservation. 10-12 story points. Must complete (including gate sign-off) before Iteration 002 begins.
- **Iteration 002** (Phases 4-5-6, T043-T057): Pause-and-confirm injection, optional parameter, comprehensive tests, corpus seeding, documentation. 8-10 story points. Can only begin after Iteration 001 is approved.

### Within Each User Story

- Test fixtures before test assertions.
- Tests written first (TDD approach) and must fail before implementation changes land.
- Detector logic (T032) before baseline tracking (T033) before integration (T041).
- Auto-continue preservation (T034) verified independently before pause logic lands (T047).

---

## Parallel Opportunities

- **T029, T030, and T031** can run in parallel (documentation, fixture setup, and planning-time hardening-gate creation).
- **T032, T033, T034, T035, T036** can be coded in parallel but tested sequentially (T041-T042 integrates all).
- **T037, T038, T039, T040** can run in parallel (test fixtures and assertions for different concerns).
- **T043, T044, T045, T046** can run in parallel (test fixtures and assertions for pause-and-confirm).
- **T050, T051, T052** can run in parallel (test fixtures and assertions for parameter handling).
- **T055, T056, T057** can run in parallel after all implementation is complete (polish lane).

---

## Parallel Example: Iteration 001 Foundational Tests

```text
Task: "T037 [US1] Write test fixtures for routine resume scenarios in tests\integration\fixtures\specrew-start-detector\routine-resume\"
Task: "T038 [US1] Write deterministic tests for zero-change detection in tests\integration\specrew-start-change-detector.ps1"
Task: "T039 [US1] Write auto-continue preservation tests in tests\integration\specrew-start-auto-continue-preservation.ps1"
Task: "T040 [US1] Write baseline tracking round-trip tests in tests\integration\specrew-start-baseline-tracking.ps1"
```

These can be written and run in parallel; T041 integrates all results.

---

## Parallel Example: Iteration 002 - US2 Pause-and-Confirm Tests

```text
Task: "T043 [US2] Write test fixtures for session-loaded file changes in tests\integration\fixtures\specrew-start-detector\with-changes\"
Task: "T044 [US2] Write pause-and-confirm injection tests in tests\integration\specrew-start-pause-and-confirm.ps1"
Task: "T045 [US2] Write scaffold-replay-path visibility tests in tests\integration\specrew-start-pause-and-confirm.ps1"
Task: "T046 [US2] Write changed-file detection tests in tests\integration\specrew-start-change-detector.ps1"
```

These can be written in parallel; T047-T048 implement pause-and-confirm logic.

---

## Parallel Example: Iteration 002 - US3 Parameter Tests

```text
Task: "T050 [US3] Write test fixtures for parameter scenarios in tests\integration\fixtures\specrew-start-detector\parameter-variants\"
Task: "T051 [US3] Write parameter handling tests in tests\integration\specrew-start-parameter-handling.ps1"
Task: "T052 [US3] Write end-to-end parameter tests in tests\integration\specrew-start-end-to-end.ps1"
```

These can be written in parallel; T053 implements parameter support.

---

## Implementation Strategy

### MVP First (Iteration 001 Only)

1. Complete Phase 1: Setup (fixtures and documentation).
2. Complete Phase 2: Foundational (detector logic, baseline tracking, preservation).
3. Complete Phase 3: Iteration 001 - US1 (write tests, integrate, verify auto-continue).
4. Stop and run the US1 independent test lane before adding US2 or US3 features.

### Incremental Delivery

1. Ship Iteration 001: Detector infrastructure and baseline tracking without pause-and-confirm (preserves existing auto-continue).
2. Ship Iteration 002: Pause-and-confirm injection, optional parameter, comprehensive test coverage, and known-traps corpus entry.
3. Final Polish: Validation lane re-run and documentation updates.

### Guardrails

- **Auto-continue preservation is non-negotiable** — If Iteration 001 changes auto-continue behavior for routine resumes (zero changes detected), reject the implementation. This is a regression of spec 001 Session 2026-05-04.
- **Visibility output must be testable via scaffold-replay-path** — Pause messages, file lists, and custom directives must be asserted in real handoff scenarios (T044, T048, T053) using `scaffold-reviewer-artifacts.ps1` and `specrew-review.ps1`, not just runtime state inspection.
- **Tests are mandatory and come first** — TDD approach required. All test fixtures and assertions written before implementation changes land. Tests must fail before implementation.
- **No breaking changes to signature** — Iteration 001 must not change `specrew-start.ps1` documented arguments or defaults (except new optional `-PostRestartDirective` in Iteration 002).
