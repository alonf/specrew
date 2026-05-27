# Tasks: F-049 Release Pipeline Hardening + Substantive Intake Slice

**Input**: Design documents from `specs/049-pipeline-hardening-intake/`  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/pipeline-hardening-intake.md`, `quickstart.md`, `proposals/120-handoff-block-validator-enforcement.md`, `iterations/001/retro.md`  
**Roadmap Guardrail**: Four iterations total. Iteration `001` is closed history and MUST NOT be reopened. Iteration `002` stays limited to troubleshooting docs, onboarding cross-references, `specrew update` vs `Update-Module Specrew` clarification, and the Shape-5 durability lesson. Iteration `003` stays limited to the bounded Proposal `063` persona-driven `/speckit.specify` slice. Iteration `004` delivers Proposal `120` full five-pillar bypass detection, explicitly including Pillar `5` committed-tree versus working-tree-only-state enforcement.

**Organization**: Remaining executable tasks are grouped by approved user story / iteration so each slice can be completed and reviewed independently without reopening closed Iteration `001`.

---

## Phase 1: Closed History - Iteration 001 (Delivered, Do Not Reopen)

**Purpose**: Preserve the already accepted release-hardening work as historical context only.

**Delivered scope**:

- Iteration `001` closed with delivered task IDs `T001-T007` and `T018-T020`.
- Delivered history is authoritative in `specs/049-pipeline-hardening-intake/iterations/001/retro.md`.
- No executable tasks are reopened in this refresh.

---

## Phase 2: Foundational Guardrails for Remaining Iterations

**Purpose**: Keep Iterations `002-004` aligned to the approved four-iteration roadmap without adding new shared infrastructure scope.

**Guardrails**:

- Reuse the delivered Iteration `001` publish-harness and release-hardening baseline.
- Keep traceability explicit for `TG-006`, `TG-007`, and `TG-008`.
- Reserve all Proposal `120` five-pillar enforcement work for Iteration `004`.

---

## Phase 3: User Story 2 - Troubleshooting Guide and Documentation (Priority: P2) / Iteration 002

**Goal**: Deliver the durable troubleshooting and onboarding recovery slice without expanding beyond the approved documentation focus.

**Independent Test**: `docs/troubleshooting.md` exists, is listed in `Specrew.psd1`, is linked from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`, and explicitly explains both `specrew update` vs `Update-Module Specrew` and the Shape-5 committed-tree durability lesson.

- [ ] T008 [US2] [assigned_to: Implementer] [effort: 1.75 SP] Draft `docs/troubleshooting.md` with sections for PSGallery side-by-side cache cleanup, FileList omissions, deploy-script exceptions, clean reinstall flows, `specrew update` vs `Update-Module Specrew` scope boundaries, and the Shape-5 lesson that accepted review evidence must match committed tree state. (Trace: FR-006, FR-015, FR-017, TG-006, TG-007, SC-002)
- [ ] T009 [US2] [assigned_to: Implementer] [effort: 0.50 SP] Register `docs/troubleshooting.md` in `Specrew.psd1` `FileList` in the same change that introduces the guide. (Trace: FR-007, TG-006, TG-007, SC-002)
- [ ] T010 [US2] [assigned_to: Implementer] [effort: 1.00 SP] Add onboarding cross-reference links to `docs/troubleshooting.md` from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`. (Trace: FR-016, TG-006, TG-007, SC-002)
- [ ] T011 [US2] [assigned_to: Reviewer] [effort: 0.75 SP] Review `docs/troubleshooting.md`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, and `Specrew.psd1`, then record Iteration `002` documentation acceptance evidence in `specs/049-pipeline-hardening-intake/iterations/002/quality/quality-evidence.md`. (Trace: FR-006, FR-007, FR-015, FR-016, FR-017, TG-006, TG-007, SC-002)

**Checkpoint**: Iteration `002` is complete when recovery guidance is durable, discoverable, and explicitly teaches the Shape-5 durability lesson without changing runtime behavior.

---

## Phase 4: User Story 3 - Persona-Driven Substantive Specification Intake with Expertise Dials (Priority: P3) / Iteration 003

**Goal**: Deliver the unified 17-20 SP medium slice that combines persona-driven `/speckit.specify` intake (FR-008..FR-011) with user-level expertise-profile persistence and consumption (FR-023..FR-027), enabling durable expertise-dial-driven question depth adaptation without silently widening into the full proposal footprint or adding project-level profile scope.

**Independent Test**: 
1. The `/speckit.specify` flow presents only the approved four personas, uses the 12-category intake catalog, branches cleanly across Modes A/B/C, and supports `"Other"` / `"I don't know, you decide"` defaults.
2. `specrew start` detects first-run (user-profile.yml absent), prompts for expertise self-rating across the 4 personas (1-10 or "I'm new, you decide"), persists the profile to cross-platform `user-profile.yml`, and surfaces a profile summary.
3. `/specrew-user-profile show` displays the current profile, `edit` allows interactive updates, and `reset` clears and restarts the profile; all changes persist across projects.
4. `/speckit.specify` consumes the persisted expertise profile and applies question-depth rules: 7-10 (Senior) with nuanced questions, 4-6 (Standard) with confirmation prompts, 1-3 (Learning) with auto-decisions + `[AUTO-DECIDED: ...]` transparency annotations.
5. SC-005 success metrics are evidenced: ≥30% question reduction for dial 7-10, ≥40% decision-count reduction for dial 1-3, no clarify-regression, and all auto-decisions annotated.

### Persona-Driven `/speckit.specify` Intake (FR-008..FR-011, SC-003)

- [ ] T012 [P] [US3] [assigned_to: Reviewer] [effort: 1.50 SP] Add failing bounded-slice persona intake coverage to `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/integration/skill-templates.tests.ps1` for all 4 sequential persona lenses (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager) applied to every intake, verifying that the single user receives all 4 perspectives covering all 12 categories from each lens. (Trace: FR-008, FR-009, TG-006, TG-007, SC-003)
- [ ] T013 [US3] [assigned_to: Implementer] [effort: 1.50 SP] Update `.github/prompts/speckit.specify.prompt.md` and `.github/agents/speckit.specify.agent.md` so `/speckit.specify` applies all 4 sequential persona lenses (not user choices) to every intake, with each lens covering the same 12-category catalog from its unique perspective (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager), and stays bounded to the Proposal `063` intake slice. (Trace: FR-008, TG-006, TG-007, SC-003)
- [ ] T014 [US3] [assigned_to: Implementer] [effort: 2.00 SP] Update `.specify/workflows/speckit/workflow.yml` and `.specify/workflow-registry.json` to drive the approved 12-category intake catalog without widening beyond the Iteration `003` slice. (Trace: FR-009, TG-006, TG-007, SC-003)
- [ ] T015 [US3] [assigned_to: Implementer] [effort: 2.00 SP] Implement Mode A / Mode B / Mode C branching and prompt sequencing in `.github/prompts/speckit.specify.prompt.md` and `.specify/workflows/speckit/workflow.yml` evaluated against both input completeness and user expertise level: Mode A (Direct Confirmation) for high-expertise users with complete input, Mode B (Targeted Clarify) for 2-3 targeted questions respecting expertise thresholds, Mode C (Full Interview) for low-expertise users or vague input. (Trace: FR-010, TG-006, TG-007, SC-003)
- [ ] T016 [US3] [assigned_to: Implementer] [effort: 1.50 SP] Add `"Other"` and `"I don't know, you decide"` fallback guidance plus stack-aware defaulting behavior in `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, and `.specify/workflows/speckit/workflow.yml`. (Trace: FR-011, TG-006, TG-007, SC-003)
- [ ] T017 [US3] [assigned_to: Reviewer] [effort: 1.00 SP] Run the bounded persona-intake regression path with `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/integration/skill-templates.tests.ps1`, then record persona-intake verification evidence in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md`. (Trace: FR-008, FR-009, FR-010, FR-011, TG-006, TG-007, SC-003)

### User-Level Expertise Profile Persistence (FR-023, FR-024, TG-009, TG-012)

- [ ] T018 [US3] [assigned_to: Implementer] [effort: 1.00 SP] Create `~/.specrew/user-profile.yml` schema and cross-platform path-handling logic in `scripts/specrew-start.ps1` for Windows (`$env:USERPROFILE\.specrew\user-profile.yml`) and Unix (`~/.specrew/user-profile.yml`). Initialize schema with fields: `schema`, `specrew_version_at_creation`, `created_at`, `last_updated_at`, `user_name` (optional), `expertise` (software_architecture, ui_ux, product_management, ai_research_project_management each 1-10 or null), `preferences.preferred_intake_depth` (auto|always-full|always-minimal). (Trace: FR-024, TG-009, TG-012)
- [ ] T019 [US3] [assigned_to: Implementer] [effort: 1.25 SP] Implement `specrew start` first-run detection and expertise self-rating prompt in `scripts/specrew-start.ps1`: detect user-profile.yml absence, prompt user for 1-10 expertise self-rating on each of the 4 personas (Software Architecture, UI/UX, Product Management, AI Research / Project Management), offer "I'm new, you decide" escape hatch per persona, persist the profile, and return success/failure signal. (Trace: FR-023, FR-026, TG-009, TG-010, TG-012)
- [ ] T020 [US3] [assigned_to: Implementer] [effort: 0.75 SP] Update `scripts/specrew-start.ps1` to surface profile summary in `start-context.json` and `start-summary.md` on first-run and on subsequent runs; include profile metadata (creation date, last update) and guidance for `/specrew-user-profile edit` and `/specrew-user-profile reset`. (Trace: FR-026, TG-010)

### `/specrew-user-profile` Slash Command Deployment (FR-025, TG-009)

- [ ] T018a [P] [US3] [assigned_to: Implementer] [effort: 0.50 SP] Create `/specrew-user-profile` slash command skill in `.claude/skills/specrew-user-profile.md` with `show` (display current profile), `edit` (interactive update), and `reset` (clear and restart) subcommands. Implement logic to read/write user-profile.yml and surface clarity on profile scope (user-level, not project-level). (Trace: FR-025, TG-009)
- [ ] T018b [P] [US3] [assigned_to: Implementer] [effort: 0.50 SP] Create `/specrew-user-profile` slash command skill in `.github/skills/specrew-user-profile.md` with identical `show`, `edit`, `reset` subcommands and user-profile.yml persistence logic. Verify that changes persist across projects and that the command works in all three deployment locations. (Trace: FR-025, TG-009)
- [ ] T018c [P] [US3] [assigned_to: Implementer] [effort: 0.50 SP] Create `/specrew-user-profile` slash command skill in `.agents/skills/specrew-user-profile.md` with identical `show`, `edit`, `reset` subcommands and user-profile.yml persistence logic. Verify mirror parity across `.claude/skills/`, `.github/skills/`, and `.agents/skills/` deployment locations. (Trace: FR-025, TG-009)

### `/speckit.specify` Expertise Dial Consumption and Question Depth Adaptation (FR-027, SC-005, TG-010, TG-011)

- [ ] T019a [US3] [assigned_to: Implementer] [effort: 1.50 SP] Update `/speckit.specify` workflow and prompt to read persisted user-profile.yml and apply expertise-level-driven question depth rules: 7-10 (Senior) surface senior-level nuanced questions with minimal auto-decisions; 4-6 (Standard) surface standard questions plus explicit decision-confirmation prompts; 1-3 (Learning) auto-decide using stack-aware defaults and surface decisions via Proposal 053 transparency pattern. Modify `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, and `.specify/workflows/speckit/workflow.yml` to load the profile and route question sequencing based on expertise dials. (Trace: FR-027, SC-005, TG-010, TG-011)
- [ ] T019b [US3] [assigned_to: Implementer] [effort: 0.75 SP] Implement Proposal 053 transparency annotations in `/speckit.specify`: when expertise dial 1-3 (Learning) triggers an auto-decision, annotate the generated spec with `[AUTO-DECIDED: <decision context>]` so the user sees what the system chose and can escalate to clarification if needed. Ensure annotations are visible in the final generated spec.md and do not cause parse/syntax errors. (Trace: FR-027, SC-005, TG-010, TG-011)

### Integration Testing and SC-005 Evidence (SC-005, TG-010, TG-011)

- [ ] T020a [P] [US3] [assigned_to: Reviewer] [effort: 1.00 SP] Add failing test coverage to `tests/integration/substantive-interaction-model-iteration2.ps1` and `tests/integration/skill-templates.tests.ps1` for expertise-dial scenarios: (1) first-run profile creation and persistence across projects, (2) `/specrew-user-profile show` displays correct expertise values, (3) `/specrew-user-profile edit` updates profile persists changes, (4) `/specrew-user-profile reset` clears profile and forces first-run re-prompt on next `specrew start`, (5) Windows and Unix cross-platform path handling for user-profile.yml. (Trace: FR-024, FR-025, FR-026, SC-005)
- [ ] T020b [US3] [assigned_to: Reviewer] [effort: 1.25 SP] Add integration tests for expertise-dial-driven question depth: (1) dial 7-10 (Senior) generates senior-level questions and spec skips low-expertise auto-decisions, (2) dial 4-6 (Standard) includes confirmation prompts, (3) dial 1-3 (Learning) auto-decides on eligible questions and surfaces `[AUTO-DECIDED: ...]` annotations in spec.md, (4) "I'm new, you decide" escape hatch triggers auto-decide for all personas. Run tests and capture question-count and decision-count deltas from Mode C baseline to measure SC-005 ≥30%/≥40% reduction targets. (Trace: FR-027, SC-005, TG-010, TG-011)
- [ ] T020c [US3] [assigned_to: Reviewer] [effort: 0.75 SP] Run the complete expertise-dial regression suite and record Iteration `003` full acceptance evidence in `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md`: persona-intake gate passes + expertise-dial persistence gates + question-depth routing gates + SC-003 success metric (measure and record that ≤2 clarify questions occur in ≥90% of test runs when expertise dial ≥4) + SC-005 success metrics (question reduction %, decision reduction %, no clarify regression, annotation presence). (Trace: FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, FR-026, FR-027, SC-003, SC-005, TG-006, TG-007, TG-009, TG-010, TG-011, TG-012)

**Checkpoint**: Iteration `003` is complete when the persona-driven intake slice + expertise-dial integration works end-to-end, remains visibly bounded to the approved scope (no project-level profiles, no 5th persona, no multi-trigger expansion), and SC-005 success metrics are evidenced.

---

## Phase 5: User Story 4 - Governance Bypass Detection Before Closeout (Priority: P4) / Iteration 004

**Goal**: Deliver the full Proposal `120` five-pillar bypass-detection slice, including fail-closed Pillar `5` enforcement for committed-tree versus working-tree-only-state mismatches.

**Independent Test**: Governance validation surfaces all five approved bypass pillars, and accepted closeout evidence fails when `review.md` cites production files that are absent from the committed `Tree Under Review`.

- [ ] T021 [P] [US4] [assigned_to: Reviewer] [effort: 1.25 SP] Extend `tests/integration/non-specrew-session-bypass.tests.ps1` with red-path coverage for all five Proposal `120` pillars, including a Pillar `5` case where `review.md` cites production files absent from the committed `Tree Under Review`. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-006, TG-007, TG-008, SC-004)
- [ ] T022 [P] [US4] [assigned_to: Implementer] [effort: 1.00 SP] Add shared helper support to `extensions/specrew-speckit/scripts/shared-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` for handoff detection, verdict-history lookup, and review-evidence versus tree inspection used by the five pillars. (Trace: FR-018, FR-021, FR-022, TG-007, TG-008, SC-004)
- [ ] T023 [US4] [assigned_to: Implementer] [effort: 1.00 SP] Implement Pillar `1` missing-handoff detection and Pillar `2` trigger-bypass classification in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-018, FR-019, TG-007, TG-008, SC-004)
- [ ] T024 [US4] [assigned_to: Implementer] [effort: 0.75 SP] Implement Pillar `3` ephemeral-host wrong-location detection and canonical-path remediation messaging in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-020, TG-007, TG-008, SC-004)
- [ ] T025 [US4] [assigned_to: Implementer] [effort: 1.00 SP] Add Pillar `4` state-advance-without-verdict enforcement to `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`, and `.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1` so human-judgment boundary advances require matching verdict history. (Trace: FR-021, TG-007, TG-008, SC-004)
- [ ] T026 [US4] [assigned_to: Implementer] [effort: 1.25 SP] Implement Pillar `5` committed-tree versus working-tree-only-state enforcement in `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, blocking accepted closeout evidence when production files cited in `review.md` are absent from the committed `Tree Under Review` while leaving test-only mismatches as warnings. (Trace: FR-022, TG-007, TG-008, SC-004)
- [ ] T027 [P] [US4] [assigned_to: Reviewer] [effort: 0.75 SP] Add or update governance fixtures under `tests/integration/fixtures/` and `tests/unit/fixtures/` to exercise handoff gaps, trigger-bypass artifact gaps, ephemeral-location artifacts, verdict-history gaps, and Pillar `5` review-evidence mismatches. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-007, TG-008, SC-004)
- [ ] T028 [US4] [assigned_to: Reviewer] [effort: 1.00 SP] Run `tests/integration/non-specrew-session-bypass.tests.ps1` and `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`, verify mirror parity between `extensions/` and `.specify/extensions/`, and record Iteration `004` closeout-blocking evidence in `specs/049-pipeline-hardening-intake/iterations/004/quality/quality-evidence.md`. (Trace: FR-018, FR-019, FR-020, FR-021, FR-022, TG-006, TG-007, TG-008, SC-004)

**Checkpoint**: Iteration `004` is complete only when all five pillars surface correctly and Pillar `5` blocks closeout on working-tree-only production evidence.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Preserve roadmap discipline and avoid adding unapproved scope while the remaining iterations close in order.

- No additional polish tasks are authorized in this refresh; finish Iterations `002`, `003`, and `004` exactly as scoped above.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Closed History)**: Already delivered; reference only.
- **Phase 2 (Guardrails)**: Informational guardrails for all remaining work.
- **Phase 3 / Iteration 002**: Starts immediately; unblocks the approved documentation slice.
- **Phase 4 / Iteration 003**: Starts after Iteration `002` acceptance to preserve the approved bounded roadmap.
- **Phase 5 / Iteration 004**: Starts after Iteration `003` acceptance; contains all Proposal `120` five-pillar enforcement work.
- **Phase 6 (Polish)**: No additional execution scope.

### User Story Dependencies

- **US2 / Iteration 002**: No dependency on new code changes; relies on the delivered Iteration `001` baseline.
- **US3 / Iteration 003**: Depends on roadmap continuity after Iteration `002`; must remain bounded to Proposal `063` intake scope.
- **US4 / Iteration 004**: Depends on the approved final Proposal `120` slice and MUST preserve `TG-008` Pillar `5` enforcement.

### Within Each User Story

- Validation-first tasks run before implementation changes where applicable.
- Content / prompt / validator implementation follows after red-path coverage is defined.
- Verification evidence is recorded only after the slice passes its independent test.
- For Iteration `003`: Persona-intake (T012-T017) runs as a prerequisite layer, then expertise-profile persistence (T018-T020, T018a-T018c) runs, then expertise-dial consumption (T019a-T019b) runs, then integration testing (T020a-T020c) runs with evidence recording at the end (T020c).

### Iteration 003 Task Dependencies

- **T012** is the prerequisite for the persona-intake layer because red-path test coverage must exist before implementation changes land.
- **T013** depends on **T012** and must complete before **T014-T015** because catalog and mode logic must follow implementation of the 4 sequential persona lenses (not user choices).
- **T014** and **T015** both depend on **T013** and can proceed in parallel once persona selection is stable.
- **T016** depends on **T014-T015** because escape-hatch options are layered on top of the existing catalog and mode-branching structure.
- **T017** depends on **T012-T016** because verification evidence must validate the complete committed intake slice, not partial working-tree state.
- **T018, T019, T020** depend on **T017** (persona-intake completion) before expertise-profile work begins; these three can proceed in parallel.
- **T018a, T018b, T018c** (slash-command skills) are all [P] parallelizable and depend on **T018** (profile schema definition) to ensure consistent schema/path handling.
- **T019a, T019b** (/speckit.specify expertise consumption) depend on **T019** (first-run prompt implementation) and **T018a-T018c** (slash-command show/edit/reset) being stable, so that the workflow can read and display the profile correctly.
- **T020a, T020b** (expertise integration tests) depend on **T019a-T019b** being complete; they can proceed in parallel once expertise-consumption is stable.
- **T020c** (full SC-005 evidence) depends on **T020a-T020b** and all implementation tasks (T012-T020b) being in the committed tree.

### Parallel Opportunities

**Iteration 003 Persona-Intake Layer** (before expertise dials begin):
- `T012` can run in parallel with early persona-scope review before prompt/workflow edits begin.
- `T014` and `T015` can run in parallel once `T013` (4-persona lens implementation) is stable.

**Iteration 003 Expertise-Profile Persistence Layer**:
- `T018`, `T019`, `T020` can start in parallel once persona-intake (T012-T017) is complete.
- `T018a`, `T018b`, `T018c` (the three skill deployments) are all [P] parallelizable and can proceed in parallel once `T018` (schema/path) is defined.

**Iteration 003 Expertise-Dial Integration Layer**:
- `T019a` and `T019b` depend on each other sequentially (T019a defines routing, T019b adds annotations).
- `T020a` and `T020b` (expertise test coverage and integration tests) can start in parallel once `T019a-T019b` are stable.

**Iteration 003 Verification Layer**:
- `T020c` (full SC-005 evidence) depends on all implementation and testing tasks being complete.

---

## Parallel Examples

### Iteration 003 Expertise-Profile Deployment (after persona-intake T017 completes)

```text
Task: "T018 Create user-profile.yml schema and cross-platform path handling"
Task: "T019 Implement specrew start first-run detection and expertise prompt"
Task: "T020 Update specrew start to surface profile summary"
```

These three can proceed in parallel once persona-intake verification (T017) is complete, since they handle different aspects of profile initialization.

### Iteration 003 Slash-Command Deployment (once T018 schema is stable)

```text
Task: "T018a Create /specrew-user-profile skill in .claude/skills/"
Task: "T018b Create /specrew-user-profile skill in .github/skills/"
Task: "T018c Create /specrew-user-profile skill in .agents/skills/"
```

All three [P] skill deployments are parallelizable and can proceed simultaneously once `T018` (schema/path definition) is stable.

### Iteration 003 Question-Depth Testing (once T019a-T019b consumption is stable)

```text
Task: "T020a Add expertise-dial test coverage to integration tests (cross-platform paths, profile persistence, slash commands)"
Task: "T020b Add expertise-dial question-depth routing tests (7-10 vs 4-6 vs 1-3, annotations, SC-005 metrics)"
```

Both test tasks can proceed in parallel once expertise consumption (T019a-T019b) is complete.

### Iteration 004 Governance Bypass Detection

```text
Task: "T021 Extend tests/integration/non-specrew-session-bypass.tests.ps1 with five-pillar red coverage"
Task: "T022 Add shared helper support in extensions/.../shared-governance.ps1 and .specify/.../shared-governance.ps1"
Task: "T027 Add/update governance fixtures under tests/integration/fixtures/ and tests/unit/fixtures/"
```

These three can proceed in parallel because test red paths, shared helper scaffolding, and fixtures touch different files.

---

## Implementation Strategy

### Approved Roadmap: Four Iterations

1. Preserve Iteration `001` as closed history.
2. Complete Iteration `002` documentation tasks `T008-T011` (troubleshooting & discoverability).
3. Stop and validate discoverability before touching `/speckit.specify`.
4. Complete Iteration `003` unified medium slice:
   - Phase A: Persona-driven intake (T012-T017, 9.5 SP)
   - Phase B: Expertise-profile persistence (T018-T020, T018a-T018c, 3.0 SP)
   - Phase C: Expertise-dial consumption (T019a-T019b, 2.25 SP)
   - Phase D: Integration testing and SC-005 evidence (T020a-T020c, 3.0 SP)
   - Total Iteration `003`: ~19.25 SP (within 17-20 SP target band)
5. Complete Iteration `004` Proposal `120` five-pillar enforcement (T021-T028, 8.0 SP).

### Incremental Delivery Strategy

**Phase 1: Iteration 002 (Documentation, 4.0 SP)**
1. Draft `docs/troubleshooting.md` with recovery guidance and Shape-5 durability lesson (T008).
2. Register the guide in `Specrew.psd1` FileList (T009).
3. Add onboarding cross-references from primary docs (T010).
4. Review and record acceptance evidence (T011).

**Phase 2: Iteration 003 (Persona Intake, 9.5 SP)**
1. Establish failing test coverage for persona selection, 12-category catalog, and Mode A/B/C branching (T012).
2. Implement persona-selection surface in prompts/agent (T013).
3. Implement 12-category catalog structure and Mode A/B/C branching in workflow (T014-T015).
4. Add escape-hatch options and stack-aware defaulting (T016).
5. Record persona-intake verification evidence (T017).

**Phase 3: Iteration 003 (Expertise Profile Persistence, 3.0 SP)**
1. Create user-profile.yml schema and cross-platform path handling (T018).
2. Implement `specrew start` first-run detection and expertise prompting (T019).
3. Surface profile summary in start-context.json and start-summary.md (T020).
4. Deploy `/specrew-user-profile` slash command to all three surfaces in parallel (T018a-T018c, [P]).

**Phase 4: Iteration 003 (Expertise Dial Consumption, 2.25 SP)**
1. Update `/speckit.specify` to read and apply expertise-driven question depth routing (T019a).
2. Implement Proposal 053 transparency annotations for auto-decisions (T019b).

**Phase 5: Iteration 003 (Integration Testing & SC-005, 3.0 SP)**
1. Add expertise-dial persistence tests and cross-platform path verification (T020a).
2. Add expertise-dial question-depth routing tests and SC-005 metrics capture (T020b).
3. Run complete regression suite and record SC-005 success criteria evidence (T020c).

**Phase 6: Iteration 004 (Five-Pillar Bypass Detection, 8.0 SP)**
1. Extend test coverage for all five bypass pillars (T021, [P]).
2. Add shared helper support for governance validation (T022, [P]).
3. Implement Pillars 1-2 (handoff detection, trigger bypass) (T023).
4. Implement Pillar 3 (ephemeral-host wrong-location) (T024).
5. Implement Pillar 4 (state-advance without verdict) (T025).
6. Implement Pillar 5 (committed-tree enforcement) (T026).
7. Add/update governance fixtures (T027, [P]).
8. Run final validation and record Iteration `004` closeout evidence (T028).

### Team Strategy

- **Spec Steward**: Ensures scope alignment with spec.md and roadmap guardrails throughout all phases.
- **Implementer**: Executes Iterations `002-004` code/prompt/workflow changes in the approved sequence.
- **Reviewer**: Owns red-path test coverage, green-path verification, integration testing, and evidence recording.
- **Parallelization**: Use [P] markers to run independent file-touching tasks simultaneously (e.g., T018a-T018c slash-command skills, T021/T022 test/helper setup, T027 fixtures).

---

## Notes

- Task IDs `T001-T007` remain closed historical records for Iteration `001`.
- Iteration `002` executable work: `T008-T011` (4.0 SP).
- **Iteration `003` executable work: `T012-T020c` (19.25 SP total, expanded to meet 17-20 SP capacity target)**:
  - Persona intake (original scope): `T012-T017` (9.5 SP)
  - **Expertise profile persistence (NEW)**: `T018-T020`, `T018a-T018c` (3.0 SP, with `T018a-T018c` [P] parallelizable)
  - **Expertise dial consumption (NEW)**: `T019a-T019b` (2.25 SP)
  - **Integration testing & SC-005 evidence (NEW)**: `T020a-T020c` (3.0 SP)
- Iteration `004` executable work: `T021-T028` (8.0 SP, with `T021`, `T022`, `T027` [P] parallelizable).
- `[P]` marks tasks that can run in parallel without conflicting file ownership.
- `[US2]`, `[US3]`, and `[US4]` map directly to the approved remaining user stories / iterations.
- **This refresh expands Iteration `003` from 9.5 SP (persona intake only, T012-T017) to 19.25 SP (T012-T020c)**, capturing all of FR-023..FR-027 expertise-dial requirements plus SC-005 success metrics.
- Iteration `004` remains unchanged and preserves all five Proposal `120` pillars with Pillar `5` fail-closed enforcement (T021-T028 unchanged).
- This refresh intentionally avoids reopening Iteration `001` or widening Iterations `002` and `004` beyond the approved roadmap.
