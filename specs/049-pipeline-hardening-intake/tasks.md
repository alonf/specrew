# Tasks: Release Pipeline Hardening + Substantive Intake Slice (Iteration 003)

**Feature**: `049-pipeline-hardening-intake`  
**Iteration**: `003`  
**Input**: Design documents from `specs/049-pipeline-hardening-intake/`  
**Prerequisites**: plan.md, spec.md, data-model.md, research.md, contracts/

**Organization**: Tasks are grouped by architectural layers and user story requirements to enable independent implementation and testing.

**Architecture-First Approach**: Iteration 003 builds the **engine + data foundation** that enables future extensibility. Engine (`Invoke-SpecifyIntake.ps1`) orchestrates persona-driven intake; data (YAML catalogs) defines personas, categories, depth rules, questions, and auto-decision defaults. This separation ensures future personas/questions/domains land as **data-only YAML additions** without engine rewrites (SC-006 proof).

---

## Format: `- [ ] T### [P?] [US#?] Description with exact file path(s) (Trace: ...)`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US3]**: User Story 3 (Persona-driven intake with engine + data architecture)
- Include exact file paths in descriptions
- Include explicit traceability metadata in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test infrastructure foundation for Iteration 003

**Verification**: Run `Invoke-Pester tests/integration/substantive-interaction-model-iteration2.ps1 -Verbose` and confirm baseline test harness exists

- [ ] T001 [US3] Add failing test coverage for engine + data architecture foundation in tests/integration/substantive-interaction-model-iteration2.ps1 (Trace: FR-028, FR-029, FR-030, FR-031, SC-006, TG-013, TG-014)

---

## Phase 2: Engine Foundation (FR-028 - Critical Path)

**Purpose**: Build discrete intake engine with mirror parity—the architectural foundation that enables all other work

**⚠️ CRITICAL**: This is the PRIMARY work of Iteration 003. All orchestrators, data catalogs, and user-profile features depend on this engine foundation.

**Independent Test**: Invoke the intake engine directly with minimal test data and verify it can load persona/category catalogs, apply depth rules, traverse questions, resolve auto-decisions, and render annotations

**Verification**: Run `pwsh -File extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1 -TestMode` and verify engine executes without errors

- [ ] T002 [US3] Create discrete intake engine shell Invoke-SpecifyIntake.ps1 with mirror parity in extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1 and .specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1 (Trace: FR-028, TG-013, TG-014)
- [ ] T003 [P] [US3] Create Load-PersonaCatalog.ps1 helper in extensions/specrew-speckit/scripts/intake/helpers/Load-PersonaCatalog.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Load-PersonaCatalog.ps1 (Trace: FR-028, FR-029, TG-013, TG-014)
- [ ] T004 [P] [US3] Create Load-CategoryCatalog.ps1 helper in extensions/specrew-speckit/scripts/intake/helpers/Load-CategoryCatalog.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Load-CategoryCatalog.ps1 (Trace: FR-028, FR-029, TG-013, TG-014)
- [ ] T005 [P] [US3] Create Resolve-PerLensMode.ps1 helper implementing per-lens Mode A/B/C evaluation + most-conservative-wins conflict resolution in extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1 (Trace: FR-010, FR-028, TG-013, TG-014)
- [ ] T006 [P] [US3] Create Traverse-QuestionBank.ps1 helper in extensions/specrew-speckit/scripts/intake/helpers/Traverse-QuestionBank.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Traverse-QuestionBank.ps1 (Trace: FR-028, TG-013, TG-014, TG-015)
- [ ] T007 [P] [US3] Create Resolve-AutoDecision.ps1 helper in extensions/specrew-speckit/scripts/intake/helpers/Resolve-AutoDecision.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-AutoDecision.ps1 (Trace: FR-028, FR-031, TG-013, TG-014)
- [ ] T008 [P] [US3] Create Render-Annotation.ps1 helper for Proposal 053 transparency pattern in extensions/specrew-speckit/scripts/intake/helpers/Render-Annotation.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Render-Annotation.ps1 (Trace: FR-027, FR-028, TG-011, TG-013, TG-014)

**Checkpoint**: Engine foundation complete - data catalogs and orchestrators can now consume the engine

---

## Phase 3: Data Catalogs (FR-029 - Data Layer)

**Purpose**: Create YAML catalogs defining personas, categories, depth rules, questions, and auto-decision defaults

**Independent Test**: Load each YAML catalog independently and verify schema correctness, completeness, and data integrity

**Verification**: Run `pwsh -Command "Get-Content .specify/intake/personas.yml | ConvertFrom-Yaml"` for each catalog and verify valid YAML with expected schema

- [ ] T009 [P] [US3] Create personas.yml defining 4 personas (Product Manager, UX/UI Specialist, Architect, AI Researcher/Project Manager) in .specify/intake/personas.yml (Trace: FR-008, FR-029, TG-013, TG-015)
- [ ] T010 [P] [US3] Create categories.yml defining 12 intake categories in .specify/intake/categories.yml (Trace: FR-009, FR-029, TG-013, TG-015)
- [ ] T011 [P] [US3] Create depth-rules.yml defining per-lens mode thresholds (dial ≥7 + ≥75% completeness → Mode A; dial 4-6 or 40-74% completeness → Mode B; dial ≤3 or <40% completeness → Mode C; most-conservative-wins) in .specify/intake/depth-rules.yml (Trace: FR-010, FR-029, TG-013, TG-015)
- [ ] T012 [P] [US3] Create product-manager.yml question bank with 3 questions minimum in .specify/intake/questions/product-manager.yml (Trace: FR-029, TG-013, TG-015)
- [ ] T013 [P] [US3] Create ux-ui-specialist.yml question bank with 3 questions minimum in .specify/intake/questions/ux-ui-specialist.yml (Trace: FR-029, TG-013, TG-015)
- [ ] T014 [P] [US3] Create architect.yml question bank with 3 questions minimum in .specify/intake/questions/architect.yml (Trace: FR-029, TG-013, TG-015)
- [ ] T015 [P] [US3] Create ai-researcher-project-manager.yml question bank with 3 questions minimum in .specify/intake/questions/ai-researcher-project-manager.yml (Trace: FR-029, TG-013, TG-015)
- [ ] T016 [P] [US3] Create generic.yml auto-decision defaults (stack-agnostic fallback) in .specify/intake/auto-decision-defaults/generic.yml (Trace: FR-029, FR-031, TG-013)

**Checkpoint**: Data catalogs complete - engine can now load personas, categories, depth rules, questions, and auto-decision defaults

---

## Phase 4: Extension Hooks & Stack Detection (FR-030, FR-031 - Future Extensibility)

**Purpose**: Reserve extension hooks and implement stack-detection mechanism for future growth

**Independent Test**: Verify empty bundle directories exist and engine skips loading them; verify stack-detection correctly identifies repo signals

**Verification**: Run `Test-Path .specify/intake/domain-bundles`, `Test-Path .specify/intake/solution-type-bundles`, and test stack-detection with various repo fixtures

- [ ] T017 [P] [US3] Create empty domain-bundles/ directory in .specify/intake/domain-bundles/ with .gitkeep (Trace: FR-030, TG-013)
- [ ] T018 [P] [US3] Create empty solution-type-bundles/ directory in .specify/intake/solution-type-bundles/ with .gitkeep (Trace: FR-030, TG-013)
- [ ] T019 [P] [US3] Implement Detect-RepoStack.ps1 helper to detect .csproj (dotnet), pyproject.toml (python), package.json (nodejs) in extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1 and .specify/extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1 (Trace: FR-031, TG-013, TG-014)

**Checkpoint**: Extension hooks reserved and stack-detection ready - future domain bundles and stack-specific defaults can land as data-only additions

---

## Phase 5: User Profile Persistence (FR-024, FR-026 - Cross-Project Profile)

**Purpose**: Implement user-level expertise profile persistence and specrew start integration

**Independent Test**: Create/read/update user-profile.yml on Windows and Unix paths; verify first-run prompts expertise self-rating; verify profile summary appears in start-context.json and start-summary.md

**Verification**: Run `specrew start` in a clean environment (no user-profile.yml), complete expertise rating, verify profile created at correct path, run again and verify profile summary displayed

- [ ] T020 [US3] Create user-profile.yml schema with cross-platform path handling (Windows $env:USERPROFILE\.specrew\user-profile.yml, Unix ~/.specrew/user-profile.yml) in scripts/specrew-start.ps1 (Trace: FR-024, TG-009, TG-012)
- [ ] T021 [US3] Implement specrew start first-run expertise self-rating prompt (4 personas, 1-10 scale or "I'm new, you decide") in scripts/specrew-start.ps1 (Trace: FR-023, FR-026, TG-009, TG-010)
- [ ] T022 [US3] Update specrew start to surface profile summary in start-context.json and start-summary.md with /specrew-user-profile edit/reset guidance in scripts/specrew-start.ps1 (Trace: FR-026, TG-010)

**Checkpoint**: User profile persistence complete - expertise ratings saved and reused across all Specrew projects

---

## Phase 6: Slash Command Deployment (FR-025 - User Profile Management)

**Purpose**: Deploy /specrew-user-profile slash command for show/edit/reset subcommands

**Independent Test**: Invoke each subcommand and verify correct behavior: show displays profile, edit updates profile.yml, reset clears profile

**Verification**: Run `/specrew-user-profile show`, `/specrew-user-profile edit`, `/specrew-user-profile reset` in each host environment and verify functionality

- [ ] T023 [P] [US3] Create /specrew-user-profile show/edit/reset in .claude/skills/specrew-user-profile.md (Trace: FR-025, TG-009)
- [ ] T024 [P] [US3] Create /specrew-user-profile show/edit/reset in .github/skills/specrew-user-profile.md (Trace: FR-025, TG-009)
- [ ] T025 [P] [US3] Create /specrew-user-profile show/edit/reset in .agents/skills/specrew-user-profile.md (Trace: FR-025, TG-009)

**Checkpoint**: Slash command deployed - users can view/edit/reset their expertise profile from any host environment

---

## Phase 7: Thin Orchestrators (FR-027, FR-028 - Engine Consumption)

**Purpose**: Update prompts/agents/workflows to invoke intake engine (thin orchestrators only, no inline logic)

**Independent Test**: Verify each orchestrator invokes Invoke-SpecifyIntake.ps1 and passes correct parameters; verify no inline persona/category/question/depth-rule/auto-decision logic exists in orchestrator files

**Verification**: Search orchestrator files for inline persona definitions or category lists (should be zero matches); run intake end-to-end and verify engine is invoked

- [ ] T026 [US3] Update speckit.specify.prompt.md to invoke Invoke-SpecifyIntake.ps1 (thin orchestrator, no inline logic) in .github/prompts/speckit.specify.prompt.md (Trace: FR-027, FR-028, TG-013)
- [ ] T027 [US3] Update speckit.specify.agent.md to invoke Invoke-SpecifyIntake.ps1 (thin orchestrator, no inline logic) in .github/agents/speckit.specify.agent.md (Trace: FR-027, FR-028, TG-013)
- [ ] T028 [US3] Update workflow.yml to invoke Invoke-SpecifyIntake.ps1 (thin orchestrator, no inline logic) in .specify/workflows/speckit/workflow.yml (Trace: FR-027, FR-028, TG-013)
- [ ] T029 [US3] Add "Other" and "I don't know, you decide" fallback guidance with agent domain research trigger to prompts/agents in .github/prompts/speckit.specify.prompt.md and .github/agents/speckit.specify.agent.md (Trace: FR-011, TG-006, TG-007)

**Checkpoint**: Thin orchestrators complete - all intake logic resides in engine + YAML catalogs, not in prompts/agents/workflows

---

## Phase 8: Integration Testing & Acceptance (SC-003, SC-005, SC-006)

**Purpose**: Validate end-to-end functionality, expertise-dial behavior, and extensibility proof

**Independent Test**: Run complete intake with various expertise dials and verify question depth adapts correctly; add 5th persona as YAML-only and verify engine recognizes it; measure SC-005 metrics

**Verification**: Run full test suite `Invoke-Pester tests/integration/substantive-interaction-model-iteration2.ps1 -Verbose` and verify all gates pass

- [ ] T030 [P] [US3] Add failing tests for user-profile persistence + slash command in tests/integration/substantive-interaction-model-iteration2.ps1 (Trace: FR-024, FR-025, FR-026, SC-005)
- [ ] T031 [P] [US3] Add integration tests for expertise-dial-driven question depth (7-10 Senior, 4-6 Standard, 1-3 Learning + transparency annotations) in tests/integration/substantive-interaction-model-iteration2.ps1 (Trace: FR-027, SC-005, TG-010, TG-011)
- [ ] T032 [P] [US3] Add 5th-persona extensibility proof test: add temporary 5th persona to personas.yml + questions/<new-persona>.yml, run intake, verify persona recognized without touching engine code, remove persona in tests/integration/substantive-interaction-model-iteration2.ps1 (Trace: FR-028, FR-029, SC-006, TG-013)
- [ ] T033 [P] [US3] Add per-lens mode branching correctness test: verify each persona lens evaluates independently against dial + lens-completeness, verify most-conservative-wins (C > B > A) applies when lenses conflict in tests/integration/substantive-interaction-model-iteration2.ps1 (Trace: FR-010, TG-013)
- [ ] T034 [US3] Run complete engine + data + expertise-dial regression suite and record acceptance evidence in specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md (Trace: FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, SC-003, SC-005, SC-006, TG-003, TG-006, TG-007, TG-009, TG-010, TG-011, TG-012, TG-013, TG-014, TG-015)

**Checkpoint**: All tests pass, SC-005 metrics documented (≥30% question reduction for dial 7-10, ≥40% decision reduction for dial 1-3, no clarify-question regression), SC-006 extensibility proof complete (5th persona added as YAML-only without engine changes)

---

## Dependencies

### Critical Path (Sequential)

1. **Phase 1 (Setup)** → MUST complete before any implementation
2. **Phase 2 (Engine Foundation)** → MUST complete before all other phases (this is the architectural foundation)
3. **Phase 3 (Data Catalogs)** → Can start once engine shell exists (T002 complete), but MUST complete before orchestrators (Phase 7) can invoke engine
4. **Phase 4 (Extension Hooks)** → Can run parallel with Phase 3, MUST complete before Phase 8 extensibility tests
5. **Phase 5 (User Profile)** → Can run parallel with Phase 3-4, but MUST complete before orchestrators (Phase 7) consume profiles
6. **Phase 6 (Slash Command)** → Depends on Phase 5 (user profile schema), can run parallel with Phase 7
7. **Phase 7 (Thin Orchestrators)** → MUST wait for Phase 2 (engine) + Phase 3 (data catalogs) + Phase 5 (user profile)
8. **Phase 8 (Testing)** → MUST wait for all prior phases; T034 is the final acceptance gate

### Parallel Opportunities

- **Phase 2**: All engine helpers (T003-T008) can run parallel once T002 (engine shell) exists
- **Phase 3**: All YAML catalogs (T009-T016) can run parallel
- **Phase 4**: Extension hooks (T017-T019) can run parallel with Phase 3
- **Phase 5**: Profile tasks (T020-T022) are sequential but can run parallel with Phase 3-4
- **Phase 6**: All slash command deployments (T023-T025) can run parallel once Phase 5 complete
- **Phase 7**: Orchestrator updates (T026-T029) can run parallel once Phase 2+3+5 complete
- **Phase 8**: Test additions (T030-T033) can run parallel, but T034 must run last (acceptance gate)

---

## Implementation Strategy

**MVP First**: Phase 2 (Engine Foundation) is the MVP critical path. Complete the engine + mirror parity before building data catalogs or orchestrators.

**Incremental Delivery**:

1. Deliver engine foundation (Phase 2) + minimal data catalogs (Phase 3) → engine can load personas/categories/depth-rules/questions
2. Add user profile persistence (Phase 5) → expertise dials work end-to-end
3. Deploy slash command (Phase 6) → users can manage profiles
4. Update orchestrators (Phase 7) → thin consumers invoke engine
5. Validate acceptance (Phase 8) → SC-005 metrics + SC-006 extensibility proof

**Parallelization**: Within each phase, leverage [P] markers to run independent tasks simultaneously (different files, no dependencies)

---

## Task Count Summary

- **Total Tasks**: 34
- **Phase 1 (Setup)**: 1 task
- **Phase 2 (Engine Foundation)**: 7 tasks (Critical Path)
- **Phase 3 (Data Catalogs)**: 8 tasks
- **Phase 4 (Extension Hooks)**: 3 tasks
- **Phase 5 (User Profile)**: 3 tasks
- **Phase 6 (Slash Command)**: 3 tasks
- **Phase 7 (Thin Orchestrators)**: 4 tasks
- **Phase 8 (Testing & Acceptance)**: 5 tasks

**Parallel Opportunities**: 22 tasks marked [P] can run in parallel within their phase constraints

**User Story Coverage**:

- **US3 (Persona-Driven Intake)**: All 34 tasks trace to US3
- **FR Coverage**: FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031
- **TG Coverage**: TG-003, TG-006, TG-007, TG-009, TG-010, TG-011, TG-012, TG-013, TG-014, TG-015
- **SC Coverage**: SC-003, SC-005, SC-006

**Explicit SC-006 Coverage**: T032 proves 5th-persona extensibility by adding/removing a persona as YAML-only without touching engine code

**Explicit TG-014 Coverage**: Mirror parity enforced in T002-T008, T019 (every engine file has twin in both locations)

**Explicit Per-Lens Mode Coverage**: T005 (Resolve-PerLensMode.ps1 helper), T011 (depth-rules.yml), T033 (per-lens mode test)
