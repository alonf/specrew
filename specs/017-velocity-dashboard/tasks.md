# Tasks: Velocity Dashboard (Feature 017)

**Feature**: Velocity Dashboard ("Where Am I?")  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Branch**: `017-velocity-dashboard`  
**Story Points Total**: ~22 SP across 2 iterations (Iteration 1: ~14 SP, Iteration 2: ~8 SP)

---

## Format: `- [ ] T### [P?] [US#?] [assigned_to: ...] [effort: ...] Description with exact file path(s) or action (Trace: ...)`

- **[P]**: Task can run in parallel once dependencies are satisfied
- **[US#]**: Present only for user-story work (`[US1]`, `[US2]`, `[US3]`)
- **[assigned_to]**: Primary owner role aligned to `spec.md`
- **[effort]**: Relative effort estimate (`S`, `M`, `L`)
- Every task includes explicit traceability to at least one requirement, governance requirement, success criterion, or user story from `spec.md`

---

## Iteration 1: Core Dashboard, Roadmap Source, and Semantic Theme (~14 SP)

### Delivery Goals

- Implement the shared dashboard renderer accessible via `specrew where`, `specrew status` alias, dedicated script entry point, and project-status Squad routing.
- Establish the structured `.specrew/roadmap.yml` source with phase-based schema and derived shipped progress.
- Deliver compact 24-line rendering with semantic color and monochrome fallback.
- Implement resilient partial-data handling and future-team placeholder behavior.
- Add summary-line rendering, derived feature status, consistent iteration naming, current-phase highlight, multi-scope ETA projection, confidence mapping, and drifted-over roadmap handling.
- Covers FR-001 through FR-018 and FR-034 through FR-046.

### Independent Test Criteria

- Dashboard renders consistently across all four invocation surfaces (CLI, alias, script, Squad routing).
- Dashboard produces meaningful output in repositories with complete data, sparse history, missing roadmap, and malformed artifacts.
- Compact mode stays within 24-line budget.
- Color behavior respects `NO_COLOR`, `--no-color`, dumb-terminal detection, and non-TTY output.
- `--Team` invocation explains limitation and falls back gracefully to personal dashboard.
- Summary line renders active feature, phase, velocity, and ETA scopes.
- Iteration naming follows `feature-NNN.iter-MM` across shipped, variance, and history sections.
- Velocity confidence maps to 1–3 low, 4–9 moderate, 10+ high with no premature high claims.
- Projection displays active-feature, current-phase, and roadmap ETA scopes.

---

## Phase 1: Setup and Infrastructure

- [X] T001 [assigned_to: CLI steward] [effort: S] Create `scripts/specrew-where.ps1` dedicated dashboard entry point that loads shared renderer logic without duplicating implementation (Trace: FR-001, FR-024)

- [X] T002 [P] [assigned_to: CLI steward] [effort: M] Establish shared dashboard module/function in `scripts/` (e.g., `scripts/internal/dashboard-renderer.ps1`) to serve `specrew where`, `specrew status`, `scripts/specrew-where.ps1`, and future Squad routing with no duplication (Trace: FR-001, FR-030)

- [X] T003 [P] [assigned_to: Governance steward] [effort: S] Create `.specify/templates/tasks-template.md` reference for Feature 017 task template structure (this file) (Trace: TG-004, TG-005)

- [X] T004 [assigned_to: CLI steward] [effort: S] Extend `scripts/specrew.ps1` to wire `where` command to shared dashboard renderer following existing switch-dispatch pattern (Trace: FR-001, FR-029)

---

## Phase 2: Roadmap Schema and Data Aggregation (Foundational)

- [X] T005 [assigned_to: Roadmap steward] [effort: M] Design and document `.specrew/roadmap.yml` schema in code comments and inline help, following the contract defined in `contracts/roadmap-schema-contract.md` (Trace: FR-010, FR-014)

- [X] T006 [P] [assigned_to: Roadmap steward] [effort: M] Implement roadmap YAML parser in PowerShell that reads `.specrew/roadmap.yml` with graceful degradation when file is missing or malformed (Trace: FR-010, FR-013)

- [X] T007 [P] [assigned_to: Data steward] [effort: L] Implement canonical-record aggregator that collects: (Trace: FR-002)
  - Active feature pointer from `.specify/feature.json`
  - Feature specs and iteration state from `specs/` directory
  - Retrospective records where available
  - Product configuration (`iteration-config.yml`)

- [X] T008 [P] [assigned_to: Roadmap steward] [effort: M] Implement shipped-progress derivation logic that calculates closed story points from canonical iteration history and maps them to roadmap phases by feature ref (Trace: FR-011)

- [X] T009 [assigned_to: Documentation steward] [effort: S] Create example `.specrew/roadmap.yml` file in repository root demonstrating all phase statuses and feature references for developer onboarding (Trace: FR-010, FR-014, SC-005)

- [X] T010 [P] [assigned_to: Governance steward] [effort: M] Implement roadmap-drift detection function that identifies mismatch between declared phase status and derived shipped progress, emitting soft warnings instead of hard failures (Trace: FR-012, FR-031)

---

## Phase 3: Dashboard Rendering Engine (User Story 1 — Understand Current Position)

**User Story 1 [US1]**: Understand current project position quickly (Priority: P1)  
**Acceptance Goals**: Dashboard renders current work, recent shipments, velocity trend, roadmap status, and remaining effort in one consistent view across all invocation surfaces.

- [X] T011 [US1] [assigned_to: Product steward] [effort: S] Implement repository-identity context section that displays repository, branch, and current-time metadata clearly at dashboard header (Trace: US1, FR-003)

- [ ] T012 [P] [US1] [assigned_to: Data steward] [effort: M] **Repair-pending**: Active-work section must show derived status, phase highlight, and in-flight totals from canonical artifacts (Trace: US1, FR-002, FR-003, FR-035, FR-036, FR-038, FR-044)

- [ ] T013 [US1] [assigned_to: Product steward] [effort: M] **Repair-pending**: Velocity headline must use expanded sample window and confidence mapping (Trace: US1, FR-003, FR-039, FR-040, NFR-007)

- [ ] T014 [P] [US1] [assigned_to: Product steward] [effort: M] **Repair-pending**: Recently shipped section must adopt unified iteration naming (Trace: US1, FR-003, FR-004, FR-037)

- [ ] T015 [P] [US1] [assigned_to: Product steward] [effort: M] **Repair-pending**: Plan-vs-reality table must use unified iteration naming (Trace: US1, FR-003, FR-005, FR-037)

- [ ] T016 [US1] [assigned_to: Product steward] [effort: M] **Repair-pending**: Full-history summary must use unified iteration naming (Trace: US1, FR-003, FR-004, FR-037)

- [ ] T017 [P] [US1] [assigned_to: Roadmap steward] [effort: M] **Repair-pending**: Roadmap-progress must include effective status, drifted-over handling, and current-phase highlight (Trace: US1, FR-003, FR-011, FR-017, FR-041, FR-042)

- [ ] T018 [US1] [assigned_to: Product steward] [effort: M] **Repair-pending**: Projection section must include multi-scope ETA output (Trace: US1, FR-003, FR-004, FR-043, FR-045, FR-046)

- [X] T019 [P] [US1] [assigned_to: Reliability steward] [effort: M] Implement data-quality warnings section that surfaces bounded, calm guidance when artifacts are missing, malformed, or drift from expectations (instead of crashing) (Trace: US1, FR-008, NFR-004)

---

## Phase 4: Rendering Modes and Color Semantics (User Story 1 Continued)

- [X] T020 [US1] [assigned_to: UX steward] [effort: M] Implement semantic color theme with foreground/background colors for sections, progress bars, and status indicators (Trace: US1, FR-006, FR-015, FR-016, SC-003)

- [X] T021 [US1] [assigned_to: UX steward] [effort: M] Implement monochrome fallback that renders readable output when color is unavailable or intentionally disabled (honors `NO_COLOR`, `--no-color`, dumb-terminal, non-TTY) (Trace: US1, FR-006, FR-018, NFR-002)

- [X] T022 [P] [US1] [assigned_to: UX steward] [effort: M] Implement compact rendering mode that preserves all essential dashboard sections within a fixed 24-line budget suitable for iteration-closeout handoffs (Trace: US1, FR-007)

- [X] T023 [US1] [assigned_to: Product steward] [effort: S] Implement `--Team` reserved path that explains team mode is not yet available and then renders the personal dashboard without failure (Trace: US1, FR-009, NFR-005)

- [X] T024 [P] [US1] [assigned_to: CLI steward] [effort: S] Add `--compact` flag support to `specrew where` and alias commands that triggers compact rendering mode (Trace: US1, FR-007, FR-024)

- [X] T025 [P] [US1] [assigned_to: UX steward] [effort: S] Add `--no-color` flag support to `specrew where` and alias commands that forces monochrome rendering regardless of terminal capability (Trace: US1, FR-018)

---

## Phase 4b: Fidelity Repair Cycle (Iteration 1 Additions)

- [ ] T083 [US1] [assigned_to: Product steward] [effort: M] Add top summary line with active feature, phase highlight, velocity, and ETA cues (Trace: US1, FR-034, FR-038)

- [ ] T084 [US1] [assigned_to: Governance steward] [effort: S] Derive feature status from iteration/review/retro artifacts instead of spec frontmatter (Trace: US1, FR-036)

- [ ] T085 [P] [US1] [assigned_to: UX steward] [effort: S] Unify iteration identifiers to `feature-NNN.iter-MM` across active, shipped, variance, and history views (Trace: US1, FR-037)

- [ ] T086 [US1] [assigned_to: Data steward] [effort: S] Expand velocity sample window and enforce confidence mapping (Trace: US1, FR-039, FR-040)

- [ ] T087 [P] [US1] [assigned_to: Roadmap steward] [effort: S] Add `drifted-over` effective status and current-phase markers in roadmap progress (Trace: US1, FR-041, FR-042)

- [ ] T088 [US1] [assigned_to: Product steward] [effort: M] Add multi-scope ETA projection (active feature, current phase, roadmap) with graceful fallbacks (Trace: US1, FR-043, FR-044, FR-045, FR-046)

## Phase 5: Resilience and Partial-Data Handling (User Story 2 — Trust the Dashboard)

**User Story 2 [US2]**: Trust the dashboard as a faithful summary (Priority: P1)  
**Acceptance Goals**: Dashboard derives data from canonical records, stays resilient when records are incomplete, surfaces uncertainty without crashing or misleading.

- [X] T026 [US2] [assigned_to: Roadmap steward] [effort: S] Implement missing-roadmap-file graceful degradation that renders all non-roadmap sections and shows setup guidance message (Trace: US2, FR-008, FR-013, FR-028)

- [X] T027 [US2] [assigned_to: Reliability steward] [effort: M] Implement malformed-artifact handling in data aggregator that skips unusable records, logs bounded warnings, and continues rendering remaining sections (Trace: US2, FR-008)

- [X] T028 [P] [US2] [assigned_to: Reliability steward] [effort: M] Implement partial-history resilience that handles repositories with sparse closed iterations (< 3 recent iterations) by reducing confidence language and avoiding overclaiming precision (Trace: US2, FR-008, NFR-007)

- [X] T029 [US2] [assigned_to: Product steward] [effort: S] Implement empty-state messaging for repositories with no closed features yet, explaining the absence without implying project failure (Trace: US2, FR-008, SC-002)

- [X] T030 [P] [US2] [assigned_to: Governance steward] [effort: M] Implement roadmap-drift visibility by showing derived shipped effort versus declared phase status, surfacing warnings when they materially conflict (Trace: US2, FR-012, FR-031)

- [X] T031 [US2] [assigned_to: Reliability steward] [effort: S] Implement active-feature-without-history handling for when active feature pointer exists but iteration history is sparse, showing active work without inventing detail (Trace: US2, FR-002, FR-008)

- [X] T032 [P] [US2] [assigned_to: Test steward] [effort: M] Create integration test fixture for malformed-history repository state that validates partial rendering and bounded-warning behavior (Trace: US2, TG-002, FR-032, SC-002)

- [X] T033 [P] [US2] [assigned_to: Test steward] [effort: M] Create integration test fixture for missing-roadmap repository state that validates all other sections render correctly (Trace: US2, FR-032, SC-002)

---

## Phase 6: Command-Surface Parity and Integration (User Story 1 Completion)

- [X] T034 [US1] [P] [assigned_to: CLI steward] [effort: S] Test `specrew where` canonical command produces expected dashboard output against healthy test repository (Trace: US1, TG-001, FR-001, SC-001)

- [X] T035 [US1] [assigned_to: CLI steward] [effort: S] Test `specrew status` alias produces behaviorally equivalent output to `specrew where` against same test repository (Trace: US1, FR-001, FR-029)

- [X] T036 [US1] [assigned_to: CLI steward] [effort: S] Test `scripts/specrew-where.ps1` dedicated entry point invokes same renderer and produces identical output (Trace: US1, FR-001, FR-024)

- [X] T037 [P] [assigned_to: Interaction steward] [effort: S] Document Squad routing contract that limits project-status requests to repository/project-scoped queries (defer unrelated conversational routing) (Trace: US1, FR-030)

- [X] T038 [assigned_to: Documentation steward] [effort: M] Update help text for `specrew where` to explain dashboard sections, interpretation guidance, and maintenance of `.specrew/roadmap.yml` (Trace: US1, FR-024)

- [X] T039 [P] [assigned_to: Documentation steward] [effort: S] Create example command invocations document showing compact mode, no-color mode, and team-fallback behavior with expected outputs (Trace: US1, FR-024, FR-025)

---

## Phase 7: Integration Foundation for Iteration 2

- [X] T040 [assigned_to: Test steward] [effort: S] Establish test fixtures directory structure under `tests/integration/fixtures/` with healthy-repository, sparse-repository, malformed-repository, and no-roadmap repository templates (Trace: FR-032)

- [X] T041 [P] [assigned_to: Test steward] [effort: M] Create `tests/integration/feature-017-dashboard-core.ps1` test harness that exercises all dashboard modes and edge cases against fixture repositories (Trace: FR-032)

- [X] T042 [assigned_to: Test steward] [effort: S] Validate that dashboard rendering completes without errors across all supported flag combinations (Trace: FR-032, SC-002)

- [X] T043 [P] [assigned_to: Artifact steward] [effort: S] Document dashboard artifact storage plan for iteration-closeout integration (`specs/<feature>/iterations/<NNN>/dashboard.md`) with example schema and notice text (Trace: FR-020, FR-021)

---

## Iteration 2: Lifecycle Integration, Education, and Validation (~8 SP)

### Delivery Goals

- Integrate dashboard generation into iteration-closeout and feature-closeout workflows.
- Create durable immutable dashboard snapshots as iteration and feature artifacts.
- Extend validator to detect and warn on roadmap drift, missing dashboard artifacts, and schema mismatches.
- Complete user-facing education (help, documentation, discovery routing).
- Verify non-crashing behavior across all repository states.
- Covers FR-019 through FR-033 and SC-001 through SC-007.

### Independent Test Criteria

- Dashboard generates automatically at iteration-closeout and is stored in expected location.
- Stored snapshots remain immutable and are never silently regenerated.
- Validator detects at least one intentionally stale-roadmap fixture as misleading.
- Dashboard appears in natural workflow and is explained by user-facing documentation.
- New maintainer can add roadmap phases using written documentation without consulting code.

---

## Phase 8: Iteration-Closeout Integration (User Story 3 — Lifecycle Integration)

**User Story 3 [US3]**: Receive dashboard as part of normal lifecycle work (Priority: P2)  
**Acceptance Goals**: Dashboard integrates naturally into iteration-closeout, stored artifacts are immutable, documentation explains all sections.

- [X] T044 [US3] [assigned_to: Governance steward] [effort: M] Implement iteration-closeout hook in `extensions/specrew-speckit/scripts/` that renders and stores dashboard snapshot at `specs/<feature>/iterations/<NNN>/dashboard.md` (Trace: US3, TG-003, FR-019, FR-020, SC-004)

- [X] T045 [US3] [assigned_to: Governance steward] [effort: M] Implement feature-closeout hook in `extensions/specrew-speckit/scripts/` that renders and stores dashboard snapshot at `specs/<feature>/closeout-dashboard.md` (Trace: US3, FR-021, SC-007)

- [X] T046 [P] [US3] [assigned_to: Artifact steward] [effort: S] Add historical-notice header to stored iteration-closeout dashboard artifacts explaining they are snapshots captured at specific moment and do not reflect live current state (Trace: US3, FR-020)

- [X] T047 [P] [US3] [assigned_to: Artifact steward] [effort: S] Add historical-notice header to stored feature-closeout dashboard artifacts explaining they are final snapshots from feature completion (Trace: US3, FR-021)

- [X] T048 [US3] [assigned_to: Artifact steward] [effort: M] Implement stored-artifact-immutability check: verify that ad hoc dashboard reruns do not silently overwrite historical closeout artifacts (Trace: US3, FR-020, SC-004)

- [X] T049 [P] [US3] [assigned_to: Governance steward] [effort: M] Extend mirrored extension scripts under `.specify/extensions/specrew-speckit/` to maintain parity with `extensions/specrew-speckit/` closeout integration (Trace: US3, FR-019, FR-023)

- [X] T050 [US3] [assigned_to: Documentation steward] [effort: S] Document iteration-closeout workflow change in `docs/user-guide.md` explaining when dashboard artifacts are generated and how to interpret them (Trace: US3, FR-025, FR-026, SC-007)

- [X] T051 [P] [assigned_to: Documentation steward] [effort: L] Create `docs/dashboard-guide.md` comprehensive guide to dashboard sections, interpretation, roadmap maintenance, and common edge cases (Trace: US3, FR-025, FR-027, SC-005)

---

## Phase 9: Validator and Drift Detection Integration

- [X] T052 [assigned_to: Validator steward] [effort: M] Extend `extensions/specrew-speckit/validators/` to add dashboard-schema-version check validating stored artifacts match current renderer version (Trace: FR-022, FR-031)

- [X] T053 [P] [assigned_to: Governance steward] [effort: S] Extend `.specrew/quality/known-traps.md` with dashboard-specific traps: stale roadmap, missing post-feature dashboard artifacts, declared-status drift (Trace: FR-031, SC-006)

- [X] T054 [assigned_to: Validator steward] [effort: M] Implement validator rule that checks for material mismatch between declared roadmap phase status and derived shipped progress (Trace: FR-012, FR-031, SC-006)

- [X] T055 [P] [assigned_to: Validator steward] [effort: M] Implement validator rule that warns when post-feature iterations lack expected `dashboard.md` artifacts (grandfathering pre-feature iterations) (Trace: FR-022, NFR-006)

- [X] T056 [assigned_to: Validator steward] [effort: S] Add validator soft-warning emission for roadmap file schema violations (extra fields, malformed structure) without hard-blocking (Trace: FR-022, FR-031)

- [X] T057 [P] [assigned_to: Governance steward] [effort: S] Document known-traps reapplication in `specs/017-velocity-dashboard/quality/trap-reapplication.md` with evidence that Feature 017 follows validator discipline (Trace: FR-031)

---

## Phase 10: Hardening Gate and Quality Evidence

- [X] T058 [assigned_to: Governance steward] [effort: S] Create `specs/017-velocity-dashboard/iterations/001/quality/hardening-gate.md` documenting command-surface parity, compact-line budget, partial-data resilience, closeout-latency evidence, roadmap-drift warnings, snapshot-artifact contracts, and mirror-sync verification (Trace: FR-033, NFR-001, SC-004, SC-006)

- [X] T059 [P] [assigned_to: Product steward] [effort: S] Verify all five stack surfaces from plan are covered: (Trace: FR-033)
  - CLI dispatch and rendering (`scripts/specrew.ps1`, `scripts/specrew-where.ps1`)
  - Dashboard data and roadmap (`.specify/feature.json`, `specs/*/spec.md`, `.specrew/roadmap.yml`)
  - Closeout and validator integration (`extensions/specrew-speckit`, `.specify/extensions/specrew-speckit`)
  - Documentation and discovery (`docs/`, help output, `.github/copilot-instructions.md`)
  - Test fixtures and replay (`tests/integration/`, `tests/unit/`, fixture directories)

- [X] T060 [assigned_to: Governance steward] [effort: S] Create `specs/017-velocity-dashboard/iterations/001/quality/quality-evidence.md` documenting manual governance review findings on dashboard truthfulness, messaging clarity, and closeout semantics (Trace: FR-033, SC-001, SC-007)

- [X] T061 [P] [assigned_to: Validator steward] [effort: S] Execute repo validator run (`validate-governance.ps1`) after dashboard and validator changes are in place, confirming clean results (Trace: FR-031, FR-022, SC-006)

- [X] T062 [assigned_to: Maintainability steward] [effort: S] Run optional `Invoke-ScriptAnalyzer` across all new PowerShell code in `scripts/`, `extensions/`, and `.specify/` following `tests/README.md` guidelines (Trace: FR-033, NFR-003)

---

## Phase 11: Documentation and Discovery

- [X] T063 [assigned_to: Documentation steward] [effort: S] Update `README.md` main entry with `specrew where` command in Getting Started section (Trace: US3, FR-026, FR-029)

- [X] T064 [P] [assigned_to: Interaction steward] [effort: S] Update `.github/copilot-instructions.md` with project-status routing guidance for Squad, explaining that dashboard is the authoritative project-status surface (Trace: US3, FR-030)

- [X] T065 [assigned_to: Documentation steward] [effort: M] Create `docs/getting-started.md` section on running dashboard and interpreting velocity/roadmap sections (Trace: US3, FR-025, FR-027)

- [X] T066 [P] [assigned_to: Documentation steward] [effort: M] Add help text to `specrew where --help` explaining: (Trace: US3, FR-024)
  - Dashboard sections and their meaning (active, velocity, shipped, variance, history, roadmap, projection, warnings)
  - How to maintain `.specrew/roadmap.yml`
  - Interpretation guidance for velocity metrics and uncertainty language
  - Compact and no-color mode availability

- [X] T067 [assigned_to: Documentation steward] [effort: M] Create `docs/roadmap-maintenance.md` guide for adding/updating roadmap phases with: (Trace: US3, FR-014, FR-025, SC-005)
  - YAML schema example from contract
  - How shipped progress is derived (not manual entry)
  - Common phase status transitions
  - Validation warnings explained

- [X] T068 [P] [assigned_to: Documentation steward] [effort: S] Document compact rendering mode in `docs/` with example showing all sections fit within 24 lines (Trace: US3, FR-024, FR-025)

- [X] T069 [assigned_to: Documentation steward] [effort: M] Add FAQ section to docs covering: (Trace: US3, FR-025, FR-028)
  - "Why is velocity showing as low?" (sparse history, anomalies, confidence language)
  - "What if roadmap shows wrong phase status?" (drift warning explanation, how to verify canonical records)
  - "What if no closed features yet?" (empty-state handling)
  - "Why doesn't team mode work?" (future multi-developer deferral, fallback behavior)

---

## Phase 12: Test Coverage and Fixture Verification

- [X] T070 [P] [assigned_to: Test steward] [effort: M] Create healthy-repository fixture with multiple complete iterations, roadmap file, and active feature for baseline validation (Trace: US2, FR-032, SC-002)

- [X] T071 [assigned_to: Test steward] [effort: S] Create sparse-repository fixture with < 3 closed iterations to test low-confidence rendering (Trace: US2, FR-032, SC-002)

- [X] T072 [P] [assigned_to: Test steward] [effort: M] Create malformed-repository fixture with invalid YAML, missing key fields, and partial history to test graceful degradation (Trace: US2, FR-032, SC-002)

- [X] T073 [assigned_to: Test steward] [effort: S] Create no-roadmap-repository fixture with no `.specrew/roadmap.yml` to test non-roadmap sections render correctly (Trace: US2, FR-032, SC-002)

- [X] T074 [P] [assigned_to: Test steward] [effort: M] Run integration test harness `tests/integration/feature-017-dashboard-core.ps1` against all four fixture types, verifying: (Trace: US2, FR-032, SC-002)
  - All sections render with expected structure
  - Bounded warnings appear where expected
  - Compact mode stays within 24 lines
  - Monochrome mode produces readable output
  - No crashes on missing/malformed data

- [X] T075 [assigned_to: Test steward] [effort: M] Create unit-style tests in `tests/unit/` for isolated renderer functions: (Trace: US2, FR-016, FR-018, FR-032)
  - Color-mode decision logic (NO_COLOR, dumb-terminal detection, TTY checks)
  - Velocity calculation and confidence levels
  - Roadmap-drift detection
  - Artifact-immutability verification

- [X] T076 [P] [assigned_to: Test steward] [effort: S] Verify `--team` invocation against fixture repository produces expected fallback message followed by personal dashboard (Trace: US2, FR-009, FR-032)

- [X] T077 [assigned_to: Documentation steward] [effort: S] Create quickstart verification commands in `tests/` documenting how reviewer can manually validate dashboard behavior: (Trace: US3, FR-025, SC-007)
  - Run dashboard in healthy repository and spot-check sections
  - Run dashboard with `--compact` flag and count lines
  - Run dashboard with `--no-color` flag and verify monochrome readability
  - Run dashboard in no-roadmap repository and verify setup guidance
  - Complete an iteration-closeout and verify `dashboard.md` artifact is generated

---

## Phase 13: Post-Feature Readiness and Deferred Boundaries

- [X] T078 [assigned_to: Governance steward] [effort: S] Update `.specify/feature.json` to mark Feature 017 as `shipped` after all tasks complete (Trace: US3, SC-007)

- [X] T079 [P] [assigned_to: Governance steward] [effort: S] Document Iteration 2 forward-looking deferrals in `specs/017-velocity-dashboard/iterations/002/`: (Trace: TG-005, US3)
  - Full multi-developer aggregation deferred (reserved `--Team` path only)
  - Browser/HTML visualization deferred
  - Dense analytics and predictive prioritization deferred
  - Quality-drift automation beyond dashboard-specific checks deferred

- [X] T080 [assigned_to: Product steward] [effort: S] Create placeholder for Proposal 013 (Methodology Site) integration noting that future work may reuse dashboard snapshots as showcase material (Trace: US3, FR-033)

- [X] T081 [P] [assigned_to: Governance steward] [effort: S] Confirm no new constitutional violations introduced: (Trace: TG-004, FR-023)
  - Dashboard remains console-first (no browser UI)
  - No new boundary type introduced
  - All governance surfaces use supported extension/prompt mechanisms
  - One-boundary discipline maintained

- [X] T082 [assigned_to: Product steward] [effort: S] Archive proof-of-concept script reference and cross-link final implementation to original source intent (Trace: FR-033)

---

## Task Organization Summary

### Total Task Count
- **82 tasks** across two iterations
- **Iteration 1 (Setup through Integration Foundation)**: T001–T043 (~11 SP)
- **Iteration 2 (Closeout Integration through Readiness)**: T044–T082 (~8 SP)

### Task Count by User Story
- **User Story 1 (Understand Position)**: T012–T039, T043 (~20 tasks) — Dashboard rendering, modes, command parity
- **User Story 2 (Trust the Dashboard)**: T026–T033, T052–T057, T070–T076 (~21 tasks) — Resilience, validation, test coverage
- **User Story 3 (Lifecycle Integration)**: T044–T051, T063–T069, T077–T082 (~26 tasks) — Closeout, docs, discovery

### Parallel Execution Opportunities

**Iteration 1**:
- **Parallel Set 1** (T002–T010): Shared module design, roadmap parser, data aggregator, shipped-progress derivation, example roadmap, drift detection (all independent foundational work)
- **Parallel Set 2** (T012–T018): Dashboard sections (active work, velocity, shipped, plan-vs-reality, history, roadmap, projection, warnings) can be developed in parallel
- **Parallel Set 3** (T020–T025): Rendering modes (color, monochrome, compact, team-fallback) independent of section implementations
- **Parallel Set 4** (T026–T032): Resilience/partial-data handling can proceed once data aggregator is complete
- **Parallel Set 5** (T034–T039): Command-surface testing can run after renderer is stable

**Iteration 2**:
- **Parallel Set 1** (T044–T051): Iteration-closeout hook, feature-closeout hook, notices, immutability check, mirrored scripts, documentation
- **Parallel Set 2** (T052–T062): Validator integration, known-traps updates, hardening gate, quality evidence, ScriptAnalyzer runs
- **Parallel Set 3** (T063–T069): Documentation updates and discovery (README, instructions, guides, help text, FAQs)
- **Parallel Set 4** (T070–T077): Test fixtures (healthy, sparse, malformed, no-roadmap) and test suite execution
- **Parallel Set 5** (T078–T082): Post-feature readiness and deferral documentation

### Implementation Strategy (MVP First)

**Phase 1 MVP** (Minimum deliverable for Feature 017 Iteration 1):
1. Shared dashboard renderer (T002, T005–T010)
2. Command wiring (T001, T004)
3. Core sections (T011–T018)
4. Color/monochrome (T020–T021)
5. Compact mode (T022)
6. Basic tests (T034–T035)

**Phase 2 Extension** (Complete Iteration 1):
7. All remaining rendering modes (T023–T025)
8. Full resilience (T026–T032)
9. Test coverage (T032–T033, T040–T043)
10. Command parity verification (T036–T039)

**Phase 3 Integration** (Iteration 2):
11. Closeout hooks (T044–T051)
12. Validator integration (T052–T062)
13. Comprehensive documentation (T063–T069)
14. Full test fixture coverage (T070–T077)

---

## Dependencies

### Hard Dependencies
- **Feature 013 — Validator Hardening**: Soft-warning patterns and validation structure
- **Feature 014 — Handoff Format Scoping**: Iteration-closeout structure
- **Feature 015 — Public-Readiness Pass**: Documentation surfaces
- **Feature 016 — Substantive Interaction Model**: Console-first behavior

### Within-Feature Dependencies
- Tasks T001–T010 (setup, schema, aggregation) must complete before T011–T025 (rendering)
- Tasks T011–T025 must stabilize before T026–T039 (resilience, command parity, testing)
- Tasks T001–T043 (Iteration 1) must complete before T044+ (Iteration 2 integration)
- Tasks T044–T062 (closeout, validator) can proceed in parallel with T063–T069 (docs) and T070–T077 (tests)

### Forward-Looking Complements
- **Proposal 013 — Methodology Site**: May reuse dashboard snapshots as showcase material
- **Multi-Developer Reconciliation**: Will activate the reserved `--Team` path

---

## Success Criteria

### Iteration 1 Acceptance Gates

1. ✓ Dashboard renders consistently across `specrew where`, `specrew status`, dedicated script, and Squad routing
2. ✓ Compact mode stays within 24-line budget
3. ✓ Color behavior respects `NO_COLOR`, dumb-terminal, non-TTY, and explicit `--no-color`
4. ✓ Partial-data handling: malformed artifacts, missing roadmap, sparse history all produce bounded warnings + partial rendering
5. ✓ No crashes on any supported invocation or flag combination
6. ✓ Help text explains dashboard sections, roadmap maintenance, and mode availability
7. ✓ Example `.specrew/roadmap.yml` exists and is documented

### Iteration 2 Acceptance Gates

1. ✓ Iteration-closeout generates and stores `specs/<feature>/iterations/<NNN>/dashboard.md`
2. ✓ Feature-closeout generates and stores `specs/<feature>/closeout-dashboard.md`
3. ✓ Stored artifacts remain immutable (ad hoc reruns do not overwrite)
4. ✓ Validator detects roadmap drift, missing artifacts, schema violations with soft warnings
5. ✓ Integration test suite covers healthy, sparse, malformed, no-roadmap fixtures with passing results
6. ✓ New maintainer can add roadmap phase using documentation alone
7. ✓ Dashboard appears naturally in next real iteration-closeout and feature-closeout flows
8. ✓ Repo validator runs clean after Feature 017 changes

---

## Verification Commands (for implementation review)

```powershell
# Run dashboard in healthy repository
pwsh -NoProfile -File .\scripts\specrew.ps1 where

# Test compact mode
pwsh -NoProfile -File .\scripts\specrew.ps1 where --compact

# Test monochrome
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color

# Test alias
pwsh -NoProfile -File .\scripts\specrew.ps1 status

# Test dedicated entry point
pwsh -NoProfile -File .\scripts\specrew-where.ps1

# Run integration test suite
pwsh -NoProfile -File tests/integration/feature-017-dashboard-core.ps1

# Run validator
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .

# Run ScriptAnalyzer (optional)
if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path . -Recurse -IncludeDefaultRules }
```

---

## Notes for Implementation Review

1. **Traceability**: Each task now includes explicit `(Trace: ...)` metadata that maps it to at least one requirement, governance requirement, success criterion, or user story from `spec.md`. Tasks remain organized by story to enable independent implementation and testing.

2. **Checklist Format**: All tasks now follow the strict format: `- [ ] T### [P?] [US#?] [assigned_to: ...] [effort: ...] Description with clear file path or action (Trace: ...)`.

3. **Parallelization**: Tasks marked with `[P]` are parallelizable (no blocking dependencies, work on different files/subsystems). Unmarked tasks depend on prior tasks in their phase.

4. **Story Independence**: User stories are independently implementable once foundational phases (T001–T010) complete. US1 (Understand Position) can ship standalone in Iteration 1; US2 (Trust) and US3 (Lifecycle) extend it without requiring each other.

5. **Testing as Verification**: Rather than separate test tasks, acceptance criteria are built into the work itself. Integration test fixtures (T070–T077) verify behavior without requiring separate TDD test-writing tasks.

6. **Graceful Degradation**: Dashboard resilience (US2 / T026–T032) is designed to degrade gracefully rather than fail, so partial data produces warnings + best-effort rendering instead of empty output.

7. **Immutability Guarantee**: T048 ensures stored closeout artifacts are never silently regenerated, preserving historical truth.

8. **Deferred Boundaries**: Multi-developer support, browser views, predictive analytics, and ambient automation are explicitly deferred to future work with placeholders for forward compatibility.
