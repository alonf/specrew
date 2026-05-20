---
description: "Tasks for Feature 024: Slash-Command Multi-Host Correctness"
---

# Tasks: Slash-Command Multi-Host Correctness

**Feature Branch**: `024-slash-command-multi-host-correctness`  
**Input**: Design documents from `/specs/024-slash-command-multi-host-correctness/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/multi-host-deployment.md`, `contracts/frontmatter-validity.md`, `contracts/migration-safety.md`, `contracts/discovery-contract.md`

**Tests**: Tests are required for this feature. Migrate the existing slash-command validation scripts and add the three new integration scripts before implementation closes.

**Organization**: Tasks are grouped by user story so each slice can be implemented, validated, and reviewed against its own acceptance criteria.

## Format: `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] Description with exact file path(s)`

- **[P]**: Task can run in parallel once dependencies are satisfied
- **[US#]**: Present only for user-story work (`[US1]`, `[US2]`, `[US3]`)
- **[Owner]**: Primary baseline roster owner (`planner`, `implementer`, `reviewer`, `spec-steward`, `retro-facilitator`, or `Alon` only when genuinely human-owned)
- **[Effort]**: Lightweight relative effort estimate (`S`, `M`, `L`)
- Existing phase/story sequencing and requirement traceability remain authoritative; this metadata makes execution ownership explicit without changing scope

## Phase 1: Setup

**Purpose**: Create the governance/evidence scaffolding needed for implementation and release validation.

- [X] T001 [Owner: planner] [Effort: S] Create prerelease smoke checklist scaffold in specs/024-slash-command-multi-host-correctness/checklists/v0.24.0-beta.1-smoke.md
- [X] T002 [Owner: planner] [Effort: S] Create quality evidence scaffolds in specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md and specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md

---

## Phase 2: Foundational

**Purpose**: Establish the shared deployment catalog and helper structure that blocks all user-story work.

**⚠️ CRITICAL**: Complete this phase before changing story-specific deployment, migration, or release surfaces.

- [X] T003 [Owner: implementer] [Effort: M] Add the canonical seven-command catalog, active target-path matrix, and deployment result structure to extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1
- [X] T004 [Owner: implementer] [Effort: S] Mirror the canonical catalog and deployment helper structure in .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1

**Checkpoint**: Shared slash-command deployment primitives exist in both runtime copies, so story work can layer on one source of truth.

---

## Phase 3: User Story 1 - Discover working slash commands after bootstrap (Priority: P1) 🎯 MVP

**Goal**: Fresh `specrew init` deploys all seven commands to the three supported skill roots with valid YAML frontmatter and hyphenated `/specrew-*` discovery copy.

**Independent Test**: Run `specrew init` in a clean project, verify `.claude/skills/`, `.github/skills/`, and `.agents/skills/` each contain the seven commands with byte-identical `SKILL.md` files, then confirm `/specrew-where` is the published discovery form.

### Tests for User Story 1

- [X] T005 [P] [US1] [Owner: implementer] [Effort: S] Migrate three-path distribution assertions in tests/integration/slash-command-distribution.tests.ps1
- [X] T006 [P] [US1] [Owner: implementer] [Effort: S] Migrate `/specrew-*` discovery assertions and Feature 024 contract references in tests/integration/slash-command-discovery.tests.ps1
- [X] T007 [P] [US1] [Owner: implementer] [Effort: M] Create clean-bootstrap multi-path coverage in tests/integration/slash-command-multi-path.tests.ps1
- [X] T008 [P] [US1] [Owner: implementer] [Effort: M] Create YAML frontmatter validity coverage in tests/integration/slash-command-frontmatter.tests.ps1

### Implementation for User Story 1

- [X] T009 [P] [US1] [Owner: implementer] [Effort: M] Refresh YAML frontmatter and `/specrew-*` body guidance in extensions/specrew-speckit/squad-templates/skills/specrew-where/SKILL.md, extensions/specrew-speckit/squad-templates/skills/specrew-status/SKILL.md, extensions/specrew-speckit/squad-templates/skills/specrew-update/SKILL.md, extensions/specrew-speckit/squad-templates/skills/specrew-team/SKILL.md, extensions/specrew-speckit/squad-templates/skills/specrew-review/SKILL.md, extensions/specrew-speckit/squad-templates/skills/specrew-help/SKILL.md, and extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md
- [X] T010 [P] [US1] [Owner: implementer] [Effort: S] Update frontmatter and multi-host template guidance in extensions/specrew-speckit/squad-templates/skills/README.md and extensions/specrew-speckit/squad-templates/README.md
- [X] T011 [US1] [Owner: implementer] [Effort: L] Implement content-identical three-path slash-command deployment and frontmatter-safe copy flow in extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 and .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1
- [X] T012 [US1] [Owner: implementer] [Effort: M] Update bootstrap/runtime slash-command messaging in scripts/specrew-init.ps1, scripts/specrew.ps1, and scripts/specrew-version.ps1

**Checkpoint**: User Story 1 is complete when bootstrap deploys the restored slash-command surface and the migrated/new bootstrap tests pass independently.

---

## Phase 4: User Story 2 - Upgrade existing projects without orphaned legacy skills (Priority: P2)

**Goal**: `specrew update` removes only Specrew-managed legacy `.copilot/skills/specrew-*` directories, preserves unmanaged content, and repopulates the three supported roots safely.

**Independent Test**: Seed managed and unmanaged legacy `.copilot/skills/specrew-*` content, run `specrew update`, verify only managed content is removed, and confirm the new three-path deployment is repopulated.

### Tests for User Story 2

- [X] T013 [P] [US2] [Owner: implementer] [Effort: S] Migrate hyphenated multi-host compatibility assertions in tests/integration/slash-command-compatibility.tests.ps1
- [X] T014 [P] [US2] [Owner: implementer] [Effort: S] Migrate active slash-command spelling and supported-path assertions in tests/integration/slash-command-coexistence.tests.ps1
- [X] T015 [P] [US2] [Owner: implementer] [Effort: M] Create managed-versus-unmanaged legacy cleanup coverage in tests/integration/slash-command-legacy-migration.tests.ps1

### Implementation for User Story 2

- [X] T016 [US2] [Owner: implementer] [Effort: L] Implement managed-marker ownership classification, safe legacy removal, preserved-leftover reporting, and idempotent update migration in extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 and .specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1
- [X] T017 [US2] [Owner: implementer] [Effort: M] Update migration reporting and supported-root messaging in scripts/specrew-update.ps1

**Checkpoint**: User Story 2 is complete when `specrew update` safely migrates legacy `.copilot/skills/` content and the migration-focused tests pass independently.

---

## Phase 5: User Story 3 - Keep release messaging and governance truthful (Priority: P3)

**Goal**: Release/version surfaces, active docs, and governance/proposal artifacts all describe the restored slash-command surface truthfully for Claude Code, GitHub Copilot CLI, and host-neutral `.agents/skills/` deployment.

**Independent Test**: Review active references for deprecated `/specrew.*` and legacy deployment claims, confirm the migrated/new slash tests pass, and verify the `v0.24.0-beta.1` smoke evidence is captured before stable promotion.

### Implementation for User Story 3

- [X] T018 [P] [US3] [Owner: implementer] [Effort: S] Bump version-bearing release surfaces in Specrew.psd1, .specrew/config.yml, extensions/specrew-speckit/extension.yml, and .specify/extensions/specrew-speckit/extension.yml for the v0.24.0 and v0.24.0-beta.1 line
- [X] T019 [P] [US3] [Owner: spec-steward] [Effort: M] Update truthful slash-surface messaging in CHANGELOG.md, README.md, SECURITY.md, docs/getting-started.md, .github/copilot-instructions.md, extensions/specrew-speckit/README.md, .specify/extensions/specrew-speckit/README.md, .specify/extensions/specrew-speckit/squad-templates/README.md, and .specify/extensions/specrew-speckit/squad-templates/skills/README.md
- [X] T020 [P] [US3] [Owner: spec-steward] [Effort: L] Reframe host-coverage and proposal/governance references in proposals/058-plugin-based-multi-host-distribution.md, proposals/064-slash-command-multi-host-correctness.md, proposals/050-version-surface-discoverability.md, proposals/056-specrew-readonly-mode.md, proposals/047-project-governance-profile.md, proposals/033-specrew-governance-cli.md, proposals/009-velocity-dashboard.md, proposals/INDEX.md, .github/ISSUE_TEMPLATE/bug_report.yml, extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md, and .specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
- [X] T021 [US3] [Owner: reviewer] [Effort: S] Capture v0.24.0-beta.1 prerelease commands, manual `/specrew-where` smoke criteria, and evidence placeholders in specs/024-slash-command-multi-host-correctness/checklists/v0.24.0-beta.1-smoke.md and specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md
- [X] T022 [US3] [Owner: reviewer] [Effort: S] Record the Feature 024 hardening and release-readiness decision in specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md

**Checkpoint**: User Story 3 is complete when the release line, active documentation, and governance/proposal surfaces all match the implemented behavior and smoke-gate expectations.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Close residual active references, run the full validation lane, and lock the final evidence pack.

- [X] T023 [Owner: implementer] [Effort: S] Update residual active slash-command references in tests/integration/slash-command-routing.tests.ps1, tests/integration/bootstrap-to-iteration.ps1, and tests/unit/slash-command-arg-whitelist.tests.ps1
- [X] T024 [Owner: reviewer] [Effort: M] Run tests/integration/slash-command-distribution.tests.ps1, tests/integration/slash-command-discovery.tests.ps1, tests/integration/slash-command-compatibility.tests.ps1, tests/integration/slash-command-coexistence.tests.ps1, tests/integration/slash-command-multi-path.tests.ps1, tests/integration/slash-command-frontmatter.tests.ps1, and tests/integration/slash-command-legacy-migration.tests.ps1 and append the results to specs/024-slash-command-multi-host-correctness/iterations/001/quality/quality-evidence.md
- [X] T025 [Owner: reviewer] [Effort: S] Run extensions/specrew-speckit/scripts/validate-governance.ps1 against the repo and update specs/024-slash-command-multi-host-correctness/iterations/001/quality/hardening-gate.md with the final pass/fail disposition

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2)**: Depends on T001-T002 and blocks all story work.
- **User Story 1 (Phase 3)**: Depends on T003-T004.
- **User Story 2 (Phase 4)**: Depends on T003-T004 and the restored multi-host deployment from T011.
- **User Story 3 (Phase 5)**: Depends on User Story 1 and User Story 2 so release/governance messaging reflects implemented behavior.
- **Polish (Phase 6)**: Depends on all user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Starts after the foundational deployment catalog exists; no dependency on later stories.
- **US2 (P2)**: Builds on the active three-path deployment introduced in US1, then adds safe legacy migration.
- **US3 (P3)**: Uses the final runtime/test truth from US1 and US2 to align release messaging, proposals, and prerelease evidence.

### Within Each User Story

- Write or migrate the listed tests before closing the implementation tasks in that story.
- Refresh canonical templates before wiring deployment or migration logic that copies them.
- Capture prerelease evidence before declaring the release line truthful.
- Run the full validation lane only after all residual active-reference fixes are complete.

## Parallel Opportunities

- **US1 tests**: T005-T008 can run in parallel because each script is independent.
- **US1 content refresh**: T009 and T010 can run in parallel because they touch different markdown surfaces.
- **US2 tests**: T013-T015 can run in parallel because each script covers a separate migration concern.
- **US3 release/doc work**: T018-T020 can run in parallel because version files, docs, and proposal/governance files are separate surfaces.

## Parallel Example(s)

### User Story 1

```text
T005 tests/integration/slash-command-distribution.tests.ps1
T006 tests/integration/slash-command-discovery.tests.ps1
T007 tests/integration/slash-command-multi-path.tests.ps1
T008 tests/integration/slash-command-frontmatter.tests.ps1
```

### User Story 3

```text
T018 Specrew.psd1 + .specrew/config.yml + extensions/specrew-speckit/extension.yml + .specify/extensions/specrew-speckit/extension.yml
T019 CHANGELOG.md + README.md + SECURITY.md + docs/getting-started.md + .github/copilot-instructions.md + extension readmes
T020 proposals/058-plugin-based-multi-host-distribution.md + proposals/064-slash-command-multi-host-correctness.md + proposals/INDEX.md + governance references
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Deliver User Story 1 only.
3. Run T024 for the US1-related scripts and confirm fresh bootstrap succeeds.
4. Stop and validate `/specrew-where` discoverability before taking on migration or release messaging.

### Incremental Delivery

1. **US1** restores fresh bootstrap correctness.
2. **US2** makes upgrade behavior safe for existing projects.
3. **US3** aligns release/governance truth with the implemented runtime.
4. **Phase 6** closes residual references and locks the evidence pack.

### Suggested MVP Scope

- **MVP**: T001-T012
- **Next increment**: T013-T017
- **Release closeout**: T018-T025

## Notes

- Every checklist item now follows the required `- [ ] T### [P?] [US#?] [Owner: ...] [Effort: ...] Description with exact file path(s)` format.
- Setup, Foundational, and Polish tasks intentionally omit story labels.
- User-story tasks are dependency-ordered in P1 → P2 → P3 sequence to match the approved spec slices.
- The final evidence pack lives under specs/024-slash-command-multi-host-correctness/iterations/001/quality/ and is ready for the mandatory after-tasks governance step.
