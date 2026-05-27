# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 23.45/25 story_points
**Started**: 2026-05-27
**Completed**: 2026-05-28

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Summary

Iteration `003` is the **21-25 SP architectural foundation slice** that implements persona-driven `/speckit.specify` intake with **engine + data architecture** for Feature `049`. The architectural pivot separates intake orchestration (discrete PowerShell engine `Invoke-SpecifyIntake.ps1` with mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`) from intake data (YAML catalogs in `.specify/intake/`: personas, categories, depth-rules, questions, auto-decision-defaults). This modular design enables future 5th+ personas, domain bundles, solution-type bundles, and stack-specific defaults to land as **data-only YAML additions** without engine rewrites (SC-006 extensibility proof). The slice also integrates user-level expertise-profile persistence (FR-023..FR-027): users self-rate expertise across 4 personas, the system persists `user-profile.yml` for reuse across projects, `/specrew-user-profile` slash command enables profile management, `specrew start` surfaces profile summary, and `/speckit.specify` consumes profiles to personalize question depth (7-10 Senior, 4-6 Standard, 1-3 Learning + Proposal 053 transparency).

**Architectural Pivot Rationale**: The previous planning package (19.25/20 SP) focused on inline prompt/workflow changes. After human rejection, the spec was updated to require a discrete engine + data architecture (TG-013, TG-014, FR-028..FR-031). This pivot adds 4-5 SP to build the modular foundation but ensures that future extensibility (5th persona, domain bundles, stack-specific defaults) will not require engine rewrites or module manifest versioning. The upfront investment is justified by SC-006 (5th-persona extensibility proof) and long-term maintenance savings.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-008 | `/speckit.specify` MUST apply exactly 4 sequential persona lenses (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager) to every intake, covering all 12 categories from each perspective. Personas are lenses, not user choices. | US3 |
| FR-009 | The system MUST supply the 12-category intake catalog: (1) Problem/pain, (2) Customer/users, (3) Security/authn/authz, (4) Scale/performance, (5) Hosting model, (6) Framework, (7) Architecture style, (8) Additional NFRs, (9) Time/budget, (10) MVP scope, (11) Technology stack, (12) Domain research. | US3 |
| FR-010 | Intake MUST evaluate mode branching **per-lens**: each persona lens independently assessed against its own expertise dial and lens-completeness percentage. Based on thresholds in `.specify/intake/depth-rules.yml` (v1: Mode A ≥7 dial + ≥75% completeness; Mode B 4-6 dial or 40-74% completeness; Mode C ≤3 dial or <40% completeness), each lens resolves to Mode A/B/C. When lenses conflict, most-conservative-wins (C > B > A). | US3 |
| FR-011 | Intake forms MUST support `"Other"` and `"I don't know, you decide"` options on every question, triggering proactive agent domain research and stack-aware defaulting. | US3 |
| FR-023 | `/speckit.specify` MUST prompt user to self-rate expertise 1-10 scale for each of 4 personas (Software Architecture, UI/UX, Product Management, AI Research/Project Management), with escape hatch `"I'm new, you decide"` per persona. | US3 |
| FR-024 | System MUST persist user expertise profile in YAML file (`user-profile.yml`) at Windows `$env:USERPROFILE\.specrew\user-profile.yml` or Unix `~/.specrew/user-profile.yml`. Schema: `schema`, `specrew_version_at_creation`, `created_at`, `last_updated_at`, `user_name` (optional), `expertise.*` (4 dimensions), `preferences.preferred_intake_depth`. | US3 |
| FR-025 | System MUST deploy `/specrew-user-profile` slash command with subcommands `show`, `edit`, `reset`. Deployed to `.claude/skills/`, `.github/skills/`, `.agents/skills/` using F-021 slash-command machinery. | US3 |
| FR-026 | `specrew start` MUST detect first-run (user-profile.yml absent), prompt expertise self-rating before bootstrap completes, save profile, surface summary in `start-context.json` and `start-summary.md`. Subsequent runs read profile and surface summary plus reset/edit guidance. | US3 |
| FR-027 | `/speckit.specify` MUST consume `user-profile.yml` and apply expertise-level-driven question depth: 7-10 (Senior) nuanced questions with minimal auto-decisions; 4-6 (Standard) standard questions plus decision-confirmation; 1-3 (Learning) auto-decide with stack-aware defaults + Proposal 053 transparency `[AUTO-DECIDED: <decision>]` annotations. | US3 |
| **FR-028** | **[ENGINE]** System MUST implement discrete intake engine (`Invoke-SpecifyIntake.ps1`) in `extensions/specrew-speckit/scripts/intake/` with mirror copy in `.specify/extensions/specrew-speckit/scripts/intake/`. Engine provides sub-helpers: persona-catalog loading, category-catalog loading, per-lens depth-rule application (Mode A/B/C evaluation + most-conservative-wins), question-bank traversal, auto-decision resolution, annotation rendering. Prompts/agents/workflows MUST be thin orchestrators calling engine; MUST NOT contain inline persona definitions, category lists, question banks, depth rules, or auto-decision defaults. | US3 |
| **FR-029** | **[DATA]** System MUST provide intake catalogs as YAML data in `.specify/intake/`: `personas.yml` (4 personas), `categories.yml` (12 categories), `depth-rules.yml` (per-lens mode thresholds with most-conservative-wins), `questions/<persona>.yml` (3 questions/persona minimum for v1), `auto-decision-defaults/generic.yml` (stack-agnostic defaults). Adding persona/category/question/depth-rule refinement/auto-decision default MUST be achievable as YAML-only data addition without engine/prompt/agent/workflow changes. | US3 |
| **FR-030** | **[EXTENSION HOOKS]** System MUST reserve future extension hooks via opt-in domain bundles (`.specify/intake/domain-bundles/<domain>.yml`) and solution-type bundles (`.specify/intake/solution-type-bundles/<type>.yml`). Directories MUST exist in v1 but remain empty. Engine MUST skip loading until explicitly enabled by later feature. v1 ships with zero bundles; future work adds data only without engine changes. | US3 |
| **FR-031** | **[STACK-AWARE DEFAULTS]** Auto-decision default resolution MUST be stack-aware: engine detects repo stack signals (`.csproj` for dotnet, `pyproject.toml` for python, `package.json` for nodejs) and selects `.specify/intake/auto-decision-defaults/<stack>.yml`, falling back to `generic.yml`. v1 ships with only `generic.yml` plus stack-detection mechanism. Stack-specific defaults (e.g., `dotnet.yml`, `python.yml`, `nodejs.yml`) land later as data-only additions without engine rewrites. | US3 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope matches the **engine + data architecture pivot** in `spec.md` TG-013, TG-014, FR-028..FR-031. Iteration `003` roadmap explicitly requires discrete engine (`Invoke-SpecifyIntake.ps1`), YAML catalogs (personas, categories, depth-rules, questions, auto-decision-defaults), mirror parity, stack-detection, and extensibility proof (SC-006). Persona-intake foundation (FR-008..FR-011) and expertise-profile integration (FR-023..FR-027) remain in scope. |
| Traceability | PASS | Every execution task maps to FR-008..FR-011 (persona intake), FR-023..FR-027 (expertise dials + user profile), **FR-028..FR-031 (engine + data architecture)**, plus TG-003, TG-006, TG-007, TG-009, TG-010, TG-011, TG-012, **TG-013 (modular design), TG-014 (mirror parity), TG-015 (minimal question banks for capacity)**, SC-003, SC-005, **SC-006 (5th-persona extensibility proof)**. |
| Capacity | PASS | Authorized slice is **21-25 SP** (increased from 17-20 SP to accommodate engine + data architecture pivot). Inside feature plan's Iteration `003` capacity band. Increase justified by TG-013 (modular design enabling future growth as data-only additions) and SC-006 (extensibility proof). |
| Roadmap Discipline | PASS | Iteration `001` closed; Iteration `002` closed. Iteration `003` now planning with architectural pivot. Iteration `004` remains untouched and reserved for Proposal `120` five-pillar bypass detection (FR-018..FR-022, SC-004). |
| Boundary Slice Discipline | PASS | Iteration `003` explicitly unified: 4 personas + 12-category catalog (FR-008..FR-011) **PLUS** expertise-dial persistence (FR-023..FR-027) **PLUS engine + data architecture foundation (FR-028..FR-031)**. NO multi-trigger expansion, NO project-level profile composition, NO validator integration. Only user-level expertise profiling + architectural foundation are authorized. |
| Before-Implement Readiness | PASS | Task decomposition completed, implementation executed, and review evidence now covers owner assignment, effort, dependency order, bounded file surfaces, mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`, YAML catalog completeness, stack-detection mechanism, and the SC-006 extensibility proof (5th persona added as data-only without engine changes). |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | [P] Add failing test coverage for engine + data architecture foundation | FR-028, FR-029, FR-030, FR-031, SC-006 | US3 | 1.50 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1` | done | | | |
| T002 | Create discrete intake engine shell Invoke-SpecifyIntake.ps1 with mirror parity | FR-028, TG-013, TG-014 | US3 | 2.50 | Implementer | `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` | done | | | |
| T003 | Create Load-PersonaCatalog.ps1 helper with mirror parity | FR-028, TG-013, TG-014 | US3 | 0.25 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Load-PersonaCatalog.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Load-PersonaCatalog.ps1` | done | | | |
| T004 | Create Load-CategoryCatalog.ps1 helper with mirror parity | FR-028, TG-013, TG-014 | US3 | 0.25 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Load-CategoryCatalog.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Load-CategoryCatalog.ps1` | done | | | |
| T005 | Create Resolve-PerLensMode.ps1 helper implementing per-lens Mode A/B/C evaluation + most-conservative-wins | FR-028, FR-010, TG-013, TG-015 | US3 | 0.75 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-PerLensMode.ps1` | done | | | |
| T006 | Create Traverse-QuestionBank.ps1 helper with mirror parity | FR-028, TG-013, TG-014 | US3 | 0.50 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Traverse-QuestionBank.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Traverse-QuestionBank.ps1` | done | | | |
| T007 | Create Resolve-AutoDecision.ps1 helper with mirror parity | FR-028, TG-013, TG-014 | US3 | 0.50 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Resolve-AutoDecision.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Resolve-AutoDecision.ps1` | done | | | |
| T008 | Create Render-Annotation.ps1 helper for Proposal 053 transparency pattern | FR-027, SC-005, TG-010, TG-011 | US3 | 0.25 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Render-Annotation.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Render-Annotation.ps1` | done | | | |
| T009 | Create personas.yml defining 4 personas | FR-029, FR-008, TG-015 | US3 | 0.25 | Implementer | `.specify/intake/personas.yml` | done | | | |
| T010 | Create categories.yml defining 12 intake categories | FR-029, FR-009, TG-015 | US3 | 0.50 | Implementer | `.specify/intake/categories.yml` | done | | | |
| T011 | Create depth-rules.yml defining per-lens mode thresholds + most-conservative-wins | FR-029, FR-010, TG-015 | US3 | 0.75 | Implementer | `.specify/intake/depth-rules.yml` | done | | | |
| T012 | Create product-manager.yml question bank with 3 questions minimum | FR-029, TG-015 | US3 | 0.50 | Implementer | `.specify/intake/questions/product-manager.yml` | done | | | |
| T013 | Create ux-ui-specialist.yml question bank with 3 questions minimum | FR-029, TG-015 | US3 | 0.50 | Implementer | `.specify/intake/questions/ux-ui-specialist.yml` | done | | | |
| T014 | Create architect.yml question bank with 3 questions minimum | FR-029, TG-015 | US3 | 0.50 | Implementer | `.specify/intake/questions/architect.yml` | done | | | |
| T015 | Create ai-researcher-project-manager.yml question bank with 3 questions minimum | FR-029, TG-015 | US3 | 0.50 | Implementer | `.specify/intake/questions/ai-researcher-project-manager.yml` | done | | | |
| T016 | Create generic.yml auto-decision defaults (stack-agnostic fallback) | FR-029, FR-031, TG-013 | US3 | 0.50 | Implementer | `.specify/intake/auto-decision-defaults/generic.yml` | done | | | |
| T017 | Create empty domain-bundles/ directory with .gitkeep | FR-030, TG-013 | US3 | 0.10 | Implementer | `.specify/intake/domain-bundles/.gitkeep` | done | | | |
| T018 | Create empty solution-type-bundles/ directory with .gitkeep | FR-030, TG-013 | US3 | 0.10 | Implementer | `.specify/intake/solution-type-bundles/.gitkeep` | done | | | |
| T019 | Implement Detect-RepoStack.ps1 helper with mirror parity | FR-031, TG-013 | US3 | 0.50 | Implementer | `extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1` | done | | | |
| T020 | Create user-profile.yml schema with cross-platform path handling | FR-024, TG-009, TG-012 | US3 | 1.00 | Implementer | `scripts/specrew-start.ps1` | done | | | |
| T021 | Implement specrew start first-run expertise self-rating prompt | FR-023, FR-026, TG-009, TG-010 | US3 | 1.25 | Implementer | `scripts/specrew-start.ps1` | done | | | |
| T022 | Update specrew start to surface profile summary in start-context.json and start-summary.md | FR-026, TG-010 | US3 | 0.75 | Implementer | `scripts/specrew-start.ps1` | done | | | |
| T023 | Create /specrew-user-profile show/edit/reset in .claude/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.claude/skills/specrew-user-profile.md` | done | | | |
| T024 | Create /specrew-user-profile show/edit/reset in .github/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.github/skills/specrew-user-profile.md` | done | | | |
| T025 | Create /specrew-user-profile show/edit/reset in .agents/skills/ | FR-025, TG-009 | US3 | 0.50 | Implementer | `.agents/skills/specrew-user-profile.md` | done | | | |
| T026 | Update speckit.specify.prompt.md to invoke Invoke-SpecifyIntake.ps1 | FR-028, FR-027, TG-013 | US3 | 0.50 | Implementer | `.github/prompts/speckit.specify.prompt.md` | done | | | |
| T027 | Update speckit.specify.agent.md to invoke Invoke-SpecifyIntake.ps1 | FR-028, FR-027, TG-013 | US3 | 0.50 | Implementer | `.github/agents/speckit.specify.agent.md` | done | | | |
| T028 | Update workflow.yml to invoke Invoke-SpecifyIntake.ps1 | FR-028, FR-027, TG-013 | US3 | 0.50 | Implementer | `.specify/workflows/speckit/workflow.yml` | done | | | |
| T029 | Add 'Other' and 'I don't know, you decide' fallback guidance | FR-011, TG-006, TG-007 | US3 | 0.75 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md` | done | | | |
| T030 | [P] Add failing tests for user-profile persistence + slash command | FR-024, FR-025, FR-026, SC-005 | US3 | 1.00 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1` | done | | | |
| T031 | Add integration tests for expertise-dial-driven question depth | FR-027, SC-005, TG-010, TG-011 | US3 | 1.25 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1` | done | | | |
| T032 | Add 5th-persona extensibility proof test (SC-006) | FR-028, FR-029, SC-006, TG-013 | US3 | 1.25 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1` | done | | | |
| T033 | Add per-lens mode branching correctness test | FR-010, FR-028, TG-013 | US3 | 1.00 | Reviewer | `tests/integration/substantive-interaction-model-iteration2.ps1` | done | | | |
| T034 | Run complete engine + data + expertise-dial regression suite and record acceptance evidence | FR-008..FR-011, FR-023..FR-031, SC-003, SC-005, SC-006, TG-006, TG-007, TG-009..TG-015 | US3 | 1.00 | Reviewer | `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` | done | | | |

**Total Effort**: 23.45 story_points

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| **Engine + data architecture foundation** | required | Discrete intake engine (`Invoke-SpecifyIntake.ps1`) MUST exist with mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`. Engine MUST provide sub-helpers for persona/category loading, per-lens mode evaluation, question traversal, auto-decision resolution, and annotation rendering. |
| **YAML catalog completeness** | required | `.specify/intake/` MUST contain: `personas.yml` (4 personas), `categories.yml` (12 categories), `depth-rules.yml` (per-lens mode thresholds + most-conservative-wins), `questions/<persona>.yml` (3 questions/persona minimum), `auto-decision-defaults/generic.yml` (stack-agnostic). |
| **Extension hooks reservation** | required | `.specify/intake/domain-bundles/` and `.specify/intake/solution-type-bundles/` directories MUST exist (reserved empty for future). Engine MUST skip loading these until explicitly enabled. |
| **Stack-detection mechanism** | required | Engine MUST detect repo stack signals (`.csproj`, `pyproject.toml`, `package.json`) and select appropriate auto-decision defaults file (falling back to `generic.yml`). v1 ships only `generic.yml`; stack-specific defaults land later as data-only additions. |
| **Thin orchestrators** | required | Prompts, agents, workflows MUST invoke engine; MUST NOT contain inline persona definitions, category lists, question banks, depth rules, or auto-decision defaults. All such logic MUST reside in engine + YAML catalogs. |
| **5th-persona extensibility proof (SC-006)** | required | Test fixture MUST verify that adding a 5th persona requires only: (1) adding row to `personas.yml`, (2) creating `questions/<new-persona>.yml`, (3) running `/speckit.specify`. Zero modifications to engine scripts, prompts, agents, workflows, or version manifests. |
| **Per-lens mode branching correctness** | required | Engine MUST evaluate each persona lens independently against its own expertise dial and lens-completeness. Most-conservative-wins (C > B > A) MUST apply when lenses conflict. No vestigial global mode bypass allowed. |
| **User-profile persistence** | required | `user-profile.yml` MUST be created on first `specrew start`, persisted across projects, and readable by `/speckit.specify`. Windows and Unix paths MUST both work. |
| **Expertise-dial application** | required | `/speckit.specify` MUST apply expertise dials to question depth: 7-10 (Senior) with nuanced questions, 4-6 (Standard) with confirmation prompts, 1-3 (Learning) with auto-decisions + transparency annotations. |
| **Slash-command functionality** | required | `/specrew-user-profile show/edit/reset` MUST work in all three deployment locations (`.claude/skills/`, `.github/skills/`, `.agents/skills/`). Changes MUST persist to `user-profile.yml` immediately. |
| **SC-005 success criteria** | required | Evidence of ≥30% question reduction for dial 7-10, ≥40% decision count reduction for dial 1-3, and no regression in clarify-question count. Generated specs MUST include `[AUTO-DECIDED: ...]` annotations for dial 1-3. |
| **Slice boundary discipline** | required | Iteration `003` MUST remain unified but internally scoped: engine + data foundation (FR-028..FR-031) + persona intake (FR-008..FR-011) + expertise dials (FR-023..FR-027). NO clarify-trigger, iteration-kickoff-trigger, mid-feature-pivot-trigger, project-level-profile, or validator-integration expansion. |
| **Acceptance evidence** | required | Iteration `003` verification recorded in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` documenting all gate passes, SC-005 metrics, and SC-006 extensibility proof. |

## Planned Execution Order

### Phase A: Engine + Data Architecture Foundation (T001-T019)

**Why this phase comes first**: The architectural pivot requires building the modular foundation before thin orchestrators can consume it. FR-028..FR-031 are **primary work** in this iteration.

1. **T001 first (red-path test coverage)** — establish failing test coverage for engine + data architecture, YAML catalog completeness, mirror parity, stack-detection, and SC-006 extensibility proof BEFORE implementation changes land.
2. **T002 next (discrete engine shell)** — create `Invoke-SpecifyIntake.ps1` shell with mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`.
3. **T003-T008 (engine sub-helpers)** — implement engine sub-helpers: `Load-PersonaCatalog.ps1`, `Load-CategoryCatalog.ps1`, `Resolve-PerLensMode.ps1` (per-lens mode evaluation + most-conservative-wins), `Traverse-QuestionBank.ps1`, `Resolve-AutoDecision.ps1`, `Render-Annotation.ps1` (Proposal 053 transparency). These can proceed in parallel once T002 engine shell exists.
4. **T009-T011 (YAML catalogs)** — create `personas.yml` (4 personas), `categories.yml` (12 categories), `depth-rules.yml` (per-lens mode thresholds + most-conservative-wins). Can proceed in parallel with T003-T008.
5. **T012-T015 (minimal question banks)** — create 3 questions/persona for product-manager, ux-ui-specialist, architect, ai-researcher-project-manager. Depends on T009 `personas.yml` existing.
6. **T016-T019 (auto-decision defaults + extension hooks + stack-detection)** — create `generic.yml` defaults, empty `domain-bundles/` and `solution-type-bundles/` directories with `.gitkeep`, and `Detect-RepoStack.ps1` helper. These are independent of question banks.

### Phase B: User Profile Persistence (T020-T022)

**Why this phase can run in parallel with Phase A**: User-profile infrastructure touches `scripts/specrew-start.ps1`, which is disjoint from engine + data surfaces.

7. **T020 (profile schema)** — create `user-profile.yml` schema and cross-platform path handling. Can start in parallel with Phase A.
8. **T021 (first-run prompt)** — implement expertise self-rating prompt in `specrew start`. Depends on T020 schema being complete.
9. **T022 (profile summary)** — update `specrew start` to surface profile summary in context and summary artifacts. Depends on T021 prompt being complete.

### Phase C: Slash Command Deployment (T023-T025)

**Why this phase can run in parallel with Phase A and Phase B**: Slash-command deployment touches `.claude/skills/`, `.github/skills/`, `.agents/skills/`, which are disjoint from engine and profile infrastructure.

10. **T023, T024, T025 (slash-command deployment)** — create `/specrew-user-profile` skills in all three deployment locations (.claude, .github, .agents). Can proceed in parallel with Phase A and Phase B once T020 schema is stable. All three tasks can proceed in parallel with each other.

### Phase D: Intake Consumption + Transparency (T026-T029)

**Why this phase comes after Phase A**: Thin orchestrators must consume the engine + data foundation.

11. **T026-T028 (thin orchestrators)** — update `speckit.specify.prompt.md`, `speckit.specify.agent.md`, and `workflow.yml` to invoke engine. Depends on T002-T019 engine + data foundation being complete.
12. **T029 (escape hatches)** — add `"Other"` and `"I don't know, you decide"` fallback guidance in prompts/agents. Depends on T026-T028 thin orchestrators being complete.

### Phase E: Integration Testing + Acceptance (T030-T034)

**Why this phase is last**: Integration testing validates all prior phases integrated.

13. **T030 (red-path profile tests)** — add failing test coverage for user-profile persistence and slash-command functionality. Can start in parallel with Phase B/C but must complete before T034.
14. **T031 (green-path dial tests)** — add tests for expertise-dial-driven question depth and SC-005 metrics. Depends on T029 intake consumption being complete.
15. **T032 (extensibility proof)** — add 5th-persona test fixture (SC-006). Depends on T002-T029 engine + data + orchestrators being present so the proof can verify that only YAML changes are needed.
16. **T033 (per-lens mode branching test)** — add per-lens mode branching correctness test. Depends on T005 (Resolve-PerLensMode.ps1) being complete.
17. **T034 last (full regression + evidence)** — run complete engine + data + expertise-dial regression suite and record Iteration `003` acceptance evidence. Depends on T001-T033 being present in committed tree (not working-tree-only state).

## Boundary Commit Cadence

| Commit Group | Tasks | Why this boundary exists |
| ------------ | ----- | ------------------------ |
| Red-path test baseline (engine + data) | T001 | Establishes failing test coverage for engine + data architecture, YAML catalogs, mirror parity, stack-detection, and SC-006 extensibility proof before any implementation changes land. |
| Discrete engine foundation | T002 | Creates `Invoke-SpecifyIntake.ps1` with mirror parity as the architectural foundation that all subsequent work depends on. |
| Engine sub-helpers + YAML catalogs | T003-T011 | Implements engine logic (persona/category loading, per-lens mode evaluation, question traversal, auto-decision, annotation) and base YAML catalogs (`personas.yml`, `categories.yml`, `depth-rules.yml`) as the modular data layer. |
| Question banks + auto-decision defaults + extension hooks | T012-T019 | Completes the data layer: minimal question banks (3/persona), `generic.yml` defaults, stack-detection, and reserved empty `domain-bundles/` and `solution-type-bundles/` directories. |
| User profile schema + first-run prompt + summary | T020-T022 | Establishes `user-profile.yml` schema, `specrew start` first-run expertise self-rating, and profile summary surfacing as a cohesive user-facing change. |
| Slash-command deployment | T023-T025 | Deploys `/specrew-user-profile` to all three skill locations (`.claude/skills/`, `.github/skills/`, `.agents/skills/`) using F-021 machinery. |
| Thin orchestrators | T026-T028 | Updates prompts/agents/workflows to invoke engine, demonstrating that orchestrators are thin consumers with no inline logic. |
| Escape hatches | T029 | Adds `"Other"` and `"I don't know, you decide"` fallback guidance in prompts/agents as the intake-consumption layer. |
| Red-path profile tests | T030 | Establishes failing test coverage for user-profile persistence and slash-command functionality before final integration tests. |
| Green-path dial tests | T031 | Tests expertise-dial-driven question depth, SC-005 metrics, and acceptance evidence readiness. |
| Extensibility proof | T032 | Adds 5th-persona test fixture (SC-006) proving that future persona additions require only YAML changes, not engine rewrites. |
| Per-lens mode branching test | T033 | Tests per-lens mode branching correctness. |
| Full acceptance | T034 | Records complete Iteration `003` acceptance evidence after all engine + data + expertise-dial surfaces pass integrated regression. |

## Dependencies

### Phase A: Engine + Data Architecture Foundation (T001-T019)

- `T001` is the prerequisite for the whole iteration because red-path test coverage must exist before implementation changes land.
- `T002` depends on `T001` and must complete before all other Phase A tasks because the engine shell is the foundation.
- `T003` through `T008` (engine sub-helpers) both depend on `T002` and can proceed in parallel once the engine shell exists.
- `T009` through `T011` (YAML catalogs) depend on `T002` and can proceed in parallel with engine sub-helpers.
- `T012` through `T015` (question banks) depend on `T009` (`personas.yml`) because question banks reference personas structure.
- `T016` through `T019` (auto-decision defaults + extension hooks + stack-detection) can proceed in parallel with question banks because they don't depend on question banks.

### Phase B: User Profile Persistence (T020-T022)

- `T020` can start in parallel with Phase A because user-profile infrastructure is independent of engine + data surfaces.
- `T021` depends on `T020` because the first-run prompt uses the `user-profile.yml` schema.
- `T022` depends on `T021` because profile summary renders the persisted expertise values from T021.

### Phase C: Slash Command Deployment (T023-T025)

- `T023`, `T024`, `T025` can start in parallel with Phase A and Phase B once `T020` schema is stable because slash-command deployment is independent of engine surfaces.
- All three tasks can proceed in parallel with each other because they deploy to different skill locations.

### Phase D: Intake Consumption + Transparency (T026-T029)

- `T026` through `T028` (thin orchestrators) depend on `T002-T019` (engine + data foundation complete) because thin orchestrators must have something to invoke.
- `T029` (escape hatches) depends on `T026-T028` (thin orchestrators complete) because escape-hatch guidance is added to prompts/agents that invoke the engine.

### Phase E: Integration Testing + Acceptance (T030-T034)

- `T030` (red-path profile tests) can start in parallel with Phase B/C but must complete before `T034`.
- `T031` (green-path dial tests) depends on `T029` (intake consumption complete) because question-depth tests validate the implemented behavior.
- `T032` (extensibility proof) depends on `T002-T029` (engine + data + orchestrators) because the extensibility proof validates that only YAML changes are needed to add a 5th persona.
- `T033` (per-lens mode branching test) depends on `T005` (Resolve-PerLensMode.ps1) being complete.
- `T034` depends on `T001-T033` (all phases complete) because full acceptance evidence validates the entire engine + data + expertise-dial integrated behavior. Evidence must validate committed-tree state, not working-tree-only state.

### Cross-Phase Sequencing

- Phase A (T001-T019) is the critical path because engine + data architecture is the primary work.
- Phase B (T020-T022) and Phase C (T023-T025) can proceed in parallel with Phase A because they touch disjoint file surfaces.
- Phase D (T026-T029) depends on Phase A (engine + data) being complete.
- Phase E (T030-T034) is the final phase and validates all prior phases integrated.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 25 | Maximum planned effort before overcommit guidance applies (from iteration-config.yml). Temporarily increased from 20 to accommodate engine + data architecture pivot. |
| Iteration Bounding | scope | `scope` keeps Iteration `003` fixed to the approved slice: **engine + data architecture foundation (FR-028..FR-031)** + persona intake (FR-008..FR-011) + expertise-profile integration (FR-023..FR-027). |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 25 story_points (capacity 25 x threshold 1.0). Iteration `003` is currently allocated 23.45 SP (within capacity). |
| Defer Strategy | manual | Task decomposition resulted in 23.45 SP against 25 SP capacity (within authorized range). No deferrals required. |
| Calibration Enabled | true | Retrospective variance should be recorded after execution completes. Compare actual effort to estimates for future Specrew capacity planning calibration. |

## Concurrency Rationale

- Current roster snapshot: Implementer and Reviewer are the only active owners for this iteration slice.
- Technology and scope signals: **PowerShell engine scripts (FR-028), YAML catalog design (FR-029), mirror parity maintenance (TG-014), stack-detection mechanism (FR-031)** dominate as architectural foundation work. Spec Kit prompts, agent definitions, workflow YAML configuration, and integration test regression are secondary surfaces consuming the engine.
- Parallel opportunities: Phase B (T020-T022: user-profile infrastructure) and Phase C (T023-T025: slash-command deployment) can proceed in parallel with Phase A (T001-T019: engine + data foundation) because they touch disjoint file surfaces (`scripts/specrew-start.ps1` and `.claude/skills/`, `.github/skills/`, `.agents/skills/` vs `extensions/specrew-speckit/scripts/intake/*` and `.specify/intake/*`).
- Sequential constraints: Phase A (engine + data) is the critical path because Phase D (intake consumption) depends on the engine existing. `T001` must complete first (red-path baseline), then `T002` (engine shell), then `T003-T019` (engine sub-helpers + YAML catalogs + question banks + auto-decision defaults + extension hooks), then Phase D (T026-T029: thin orchestrators + escape hatches), then Phase E (T030-T034: integration testing + acceptance).

## Lessons from Iteration 002

### Applied Lessons

1. **Three-boundary commit cadence retained** — Iteration `002` proved the three-boundary cadence (primary content → packaging/discoverability → evidence) lands exactly to plan and stays audit-friendly. Iteration `003` reuses this pattern adapted to architectural foundation work: red-path baseline → discrete engine → engine sub-helpers + YAML catalogs → question banks + defaults + extension hooks → thin orchestrators → extensibility proof → user-profile infrastructure → slash-command deployment → transparency annotations + escape hatches → integration testing → acceptance evidence.
2. **Manual Pillar 5 discipline as execution baseline** — Iteration `002` applied manual committed-tree presence checks during `T011` before acceptance was claimed. Iteration `003` will follow the same discipline: `T034` verification evidence MUST confirm that all cited production files (engine scripts, YAML catalogs, mirror copies, slash-command skills) exist in the committed tree under review before acceptance is recorded.
3. **Boundary commit discipline enforcement** — Iteration `002` recorded `boundary-commit-discipline-violations: 0`. Iteration `003` will preserve this discipline by ensuring each planned boundary commit group lands as a separate, atomic commit without mixing unrelated surfaces (e.g., engine scripts separate from user-profile infrastructure, YAML catalogs separate from slash-command deployment).

### Explicit Non-Application

- **Mechanized Pillar 5 enforcement** remains deferred to Iteration `004`. Iteration `003` will continue using manual reviewer discipline for committed-tree presence checks rather than implementing validator automation.
- **Approval-vs-tree freshness gate** remains manual during Iteration `003`. The reviewer will verify that the Tree Under Review and cited production files match `HEAD` during `T034`, but validator-side freshness comparison waits for Iteration `004`.

## Explicit Out-of-Scope Boundaries

To keep Iteration `003` visibly unified and internally scoped, the following expansions are explicitly OUT OF SCOPE and deferred beyond F-049's four-iteration roadmap:

| Out-of-Scope Item | Rationale | Future Home |
| ----------------- | --------- | ----------- |
| Full question banks (>3 questions/persona) | Iteration `003` uses minimal question banks (3 questions/persona) for capacity reasons within the 21-25 SP soft cap (TG-015). Future question expansion lands as data-only additions to `questions/<persona>.yml` without engine changes. | Future F-050+ feature when question bank expansion ships |
| Stack-specific auto-decision defaults (dotnet.yml, python.yml, nodejs.yml) | v1 ships only `generic.yml` plus stack-detection mechanism (FR-031). Stack-specific defaults land later as data-only additions without engine rewrites. | Future F-050+ feature when stack-specific defaults ship |
| Domain bundles (`.specify/intake/domain-bundles/<domain>.yml`) | Directories reserved empty (FR-030). Opt-in domain-specific question loading lands later as data-only additions. | Future F-050+ feature when domain-bundle opt-in ships |
| Solution-type bundles (`.specify/intake/solution-type-bundles/<type>.yml`) | Directories reserved empty (FR-030). Opt-in solution-type-specific question loading lands later as data-only additions. | Future F-050+ feature when solution-type-bundle opt-in ships |
| 5th+ personas as fully integrated features | Adding a 5th persona is **proven possible** via SC-006 extensibility test, but 5th+ personas remain out of scope for v1 as fully integrated, production-ready features (TG-013). They land later as data-only additions to `personas.yml` and `questions/<persona>.yml`. | Future F-050+ feature when additional personas ship |
| Multi-trigger expansion (clarify / iteration-kickoff / mid-feature-pivot modes) | Iteration `003` remains scoped to `/speckit.specify` intake + expertise-profile user management only. | Future F-050+ feature or later intake expansion |
| Project-level expertise overrides | Iteration `003` implements user-level profile only (persisted across all Specrew projects). | Future F-050+ feature when project-level profile governance ships |
| Multi-user shared profile | `user-profile.yml` is single-user only; shared team profiles remain out of scope. | Future F-050+ feature when shared governance ships |
| Structured output (`interview.yml`) | Canonical intake record persistence is deferred. | Future F-050+ feature or later intake expansion |
| Implicit expertise detection | Deriving expertise dial from answer quality or interaction patterns (remains Proposal 015 future scope). | Future feature when Proposal 015 ships |

## Notes

- **Iteration `003` is a 21-25 SP architectural foundation slice**, combining the **engine + data architecture pivot (FR-028..FR-031, TG-013, TG-014, TG-015, SC-006)** with the approved persona intake (FR-008..FR-011, SC-003) and user-level expertise-profile persistence (FR-023..FR-027, SC-005). The architectural pivot adds 4-5 SP to build the modular foundation but ensures that future extensibility (5th persona, domain bundles, stack-specific defaults) will not require engine rewrites or module manifest versioning.
- **Engine + data separation is primary work**: `Invoke-SpecifyIntake.ps1` (discrete engine) + helper sub-scripts + YAML catalogs (`personas.yml`, `categories.yml`, `depth-rules.yml`, `questions/<persona>.yml`, `auto-decision-defaults/generic.yml`) + mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*` + stack-detection mechanism + extensibility proof (SC-006). Prompts, agents, workflows are thin orchestrators consuming the engine; they MUST NOT contain inline persona definitions, category lists, question banks, depth rules, or auto-decision defaults.
- **Per-lens mode semantics**: Mode A/B/C evaluation is **per-lens**, not global. Each persona lens is independently evaluated against its own expertise dial and lens-completeness percentage. When lenses conflict, most-conservative-wins (C > B > A) applies—ensuring that low-expertise or incomplete lenses drive the overall intake depth rather than being bypassed.
- **Minimal question banks for capacity**: v1 question banks are intentionally minimal (3 questions per persona) for capacity reasons within the 21-25 SP Iteration 003 soft cap (TG-015). Future growth (additional personas, expanded question banks, domain bundles, solution-type bundles) MUST land as data-only additions without engine changes. This constraint ensures that capacity is invested in architectural foundation (FR-028 engine) and base data structure (FR-029 catalogs) rather than question volume.
- **Expertise-dial semantics**: Users self-rate 1-10 per persona with an "I'm new, you decide" escape hatch. System applies depth rules: 7-10 (Senior) surface nuanced questions with minimal auto-decisions, 4-6 (Standard) include confirmation prompts, 1-3 (Learning) auto-decide with stack-aware defaults + Proposal 053 transparency annotations `[AUTO-DECIDED: ...]`. No silent auto-decisions; all low-expertise choices are surfaced for user review.
- **User-profile.yml is user-level**, persisted at `$env:USERPROFILE\.specrew\user-profile.yml` (Windows) or `~/.specrew/user-profile.yml` (Unix), and reusable across all Specrew projects. This eliminates the need to re-enter expertise for every project while maintaining user control via `/specrew-user-profile show/edit/reset`.
- **Boundary discipline**: Iteration `003` is explicitly bounded to engine + data architecture foundation (FR-028..FR-031) + `/speckit.specify` intake behavior (FR-008..FR-011) + user-profile management (FR-023..FR-027). NO multi-trigger expansion (clarify/iteration-kickoff/mid-feature-pivot), NO project-level profile overrides, NO validator integration. All such expansion remains future work outside F-049's approved roadmap.
- **Slash-command deployment parity**: `/specrew-user-profile` MUST deploy to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` using F-021 machinery. All three locations must have identical behavior and reflect changes to the shared `user-profile.yml`.
- **Mirror parity enforcement (TG-014)**: Engine scripts MUST maintain mirror parity between `extensions/specrew-speckit/scripts/intake/*` (shipped in module) and `.specify/extensions/specrew-speckit/scripts/intake/*` (project-local override path). Both paths must be kept synchronized; any engine enhancement MUST update both mirrors simultaneously. This is enforced during task execution (T002-T019) and validated during acceptance evidence (T034).
- **SC-006 extensibility proof**: Adding a 5th persona MUST be demonstrably achievable by: (1) adding one row to `personas.yml`, (2) creating one new file `questions/<new-persona>.yml`, (3) running `/speckit.specify`, with **zero modifications** to engine scripts, prompts, agents, workflows, or version manifests. This is proven empirically with a test fixture in T032.
- **SC-005 measurement**: Success is empirically measured by (a) ≥30% reduction in question count for dial 7-10 vs Mode C baseline, (b) ≥40% reduction in user-faced decision count for dial 1-3 via auto-decide + transparency, (c) no regression in clarify-question count across all expertise levels, and (d) per-lens specify-mode-A rate remaining ≥70% (spec quality gate).
- **Capacity justification**: 21-25 SP reflects the architectural foundation work (FR-028 engine + FR-029 data catalogs + FR-030 extension hooks + FR-031 stack detection) that enables future extensibility. This is 4-5 SP higher than the old 17-20 SP estimate because the pivot from inline logic to modular engine + data requires upfront investment in sub-helper architecture, mirror parity, and YAML catalog design. The payoff is that future 5th+ personas, domain bundles, solution-type bundles, and stack-specific defaults will land as data-only additions without touching engine code or module manifests.
