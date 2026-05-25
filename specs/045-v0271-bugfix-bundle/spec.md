# Feature Specification: Specrew v0.27.1 Bug-Fix Bundle

**Feature Branch**: `045-v0271-bugfix-bundle`  
**Created**: 2026-05-25  
**Status**: Draft  
**Input**: User description: "Specrew v0.27.1 patch — bug-fix bundle for 7 post-release findings from the 2026-05-25 v0.27.0 release work... Composes with Proposal 110 and Proposal 116."

## Clarifications

### Session 2026-05-25

- Q: What is the formal SC-006 pass/fail definition for regression quality? → A: 0 failing P0/P1 regression tests in patch test suite.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reliable Patch Behavior for Core Commands (Priority: P1)

A maintainer or contributor runs key lifecycle commands (`specrew --version`, `specrew version`, `specrew start`, and `specrew init`) and gets correct, non-misleading outcomes across both initialized and non-initialized project contexts.

**Why this priority**: These issues are release regressions in primary entry points. If they remain unresolved, trust in patch quality and basic command behavior is reduced immediately.

**Independent Test**: Execute version, start, and init commands in both project and non-project directories and confirm expected behavior for each path without relying on other patch items.

**Acceptance Scenarios**:

1. **Given** a user invokes the top-level CLI with `--version` or `-v`, **When** the command is parsed, **Then** the version output is shown consistently and matches the canonical version command.
2. **Given** a user runs `specrew version` outside a project, **When** version is resolved, **Then** no misleading warning about undetermined version is shown unless the version is truly unavailable.
3. **Given** a user runs `specrew start` in a project missing one or more skill catalog directories, **When** startup validation runs, **Then** the missing directories are auto-repaired and startup continues with a usable team runtime.
4. **Given** a user runs `specrew init` with or without force, **When** missing skill catalog directories are detected, **Then** execution falls through to deployment behavior instead of early exiting as if validation passed.

---

### User Story 2 - Accurate Conflict and Brownfield Detection (Priority: P1)

A maintainer running initialization in brownfield/self-hosting setups gets conflict decisions that reflect canonical source ownership rules, including extension-based self-hosting layouts.

**Why this priority**: Incorrect conflict detection blocks legitimate setups and can push maintainers into unsafe manual workarounds.

**Independent Test**: Run brownfield detection against repositories with and without `extensions/specrew-speckit/` and confirm canonical-source classification of `.squad/agents/` is correct in both conditions.

**Acceptance Scenarios**:

1. **Given** a project contains `extensions/specrew-speckit/` and existing `.squad/agents/`, **When** brownfield conflict checks run, **Then** `.squad/agents/` is treated as canonical source and not reported as a conflict.
2. **Given** a project does not contain the self-hosting extension signal, **When** brownfield conflict checks run, **Then** existing conflicting managed paths are still surfaced according to standard protection rules.

---

### User Story 3 - Clear Update and Redeployment Guidance (Priority: P2)

A maintainer updating an installed module can quickly choose the correct update path, understand risk flags, and know when a re-deploy/init pass is required to close runtime gaps.

**Why this priority**: Patch correctness alone is insufficient if operators cannot safely apply and operationalize updates.

**Independent Test**: Follow the update documentation from a clean and an existing installation and verify that expected update decisions and redeployment triggers are explicit and actionable.

**Acceptance Scenarios**:

1. **Given** a user reads the update guide, **When** deciding between install/update options, **Then** the guide clearly explains standard update flow, force behavior, publisher-check bypass implications, and safe usage boundaries.
2. **Given** a user has an environment with skill catalog deployment gaps, **When** reviewing update guidance, **Then** the guide explicitly states when a re-deployment/init run is required and why.

---

### Edge Cases

- Version output is requested from environments without project metadata, module metadata, or repository context, and the command still avoids false-warning noise.
- Only a subset of expected skill catalog directories is missing, and auto-repair still restores all required directories in one pass.
- Brownfield detection is evaluated in nested or partially migrated repositories where self-hosting signals and legacy artifacts coexist.
- Patch item intake includes stale review comments alongside real defects, and only actionable defects alter behavior.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST accept both `--version` and `-v` as top-level aliases for version display with output parity to `specrew version`.
- **FR-002**: The version command MUST suppress the "version could not be determined" warning when the version is determinable even outside an initialized project.
- **FR-003**: The patch bundle MUST resolve all 7 post-release findings by applying behavior changes only for actionable defects and explicitly closing stale review findings without changing runtime behavior.
- **FR-004**: Startup behavior MUST auto-repair missing skill catalog directories during `specrew start` before continuing normal flow.
- **FR-005**: Initialization validation MUST treat missing skill catalog directories as deployable gaps and proceed into deployment flow for both no-force and force entry paths.
- **FR-006**: Brownfield conflict detection MUST treat existing `.squad/agents/` as canonical source (not conflicting) when project-root self-hosting extension presence indicates that ownership model.
- **FR-007**: The update documentation MUST describe module install/update behavior, force and publisher-check semantics, init re-deployment triggers, and the recurring skill-catalog deployment-gap pattern.
- **FR-008**: The patch MUST preserve established mirror/governance expectations across lifecycle artifacts, including active feature pointer consistency for downstream phases.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Story 1 maps to FR-001, FR-002, FR-003, FR-004, and FR-005.
- **TG-002**: Story 2 maps to FR-006.
- **TG-003**: Story 3 maps to FR-007.
- **TG-004**: FR-008 applies across all stories as a governance integrity constraint.
- **TG-005**: Expected owner roles:
  - **Implementer**: Command behavior fixes, startup/init flow corrections, conflict logic updates
  - **Reviewer**: Regression verification, stale-comment closure validation, patch-scope integrity checks
  - **Doc Steward**: Update guidance completeness and operator-facing clarity
- **TG-006**: Intended delivery window: two patch iterations (iter 001 = US1 + foundational; iter 002 = US2 + US3 + polish); v0.27.1 release tag follows iter 002 closeout.
- **TG-007**: Known reconciliation path: patch scope composes with Proposal 110 and Proposal 116; any overlap must preserve proposal intent while prioritizing this patch’s user-visible bug-fix outcomes.

### Key Entities *(include if feature involves data)*

- **RuntimeEntryPointContext**: Captures whether invocation path is start/init/version, project state, and missing-runtime-surface detection outcomes.
- **SkillCatalogState**: Represents required catalog directory presence and repair status at lifecycle entry points.
- **BrownfieldOwnershipSignal**: Represents self-hosting indicators used to classify whether existing agent directories are canonical source or conflict candidates.
- **PatchFindingRecord**: Represents each post-release finding with status (actionable defect or stale review artifact) and closure disposition.
- **UpdateGuidanceDecisionPath**: Represents operator update choices and redeployment trigger conditions described in documentation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of version-invocation checks for `--version`, `-v`, and `specrew version` return consistent version output in supported invocation contexts.
- **SC-002**: 0 false-positive "version could not be determined" warnings appear in validation scenarios where version data is available.
- **SC-003**: In patch regression tests, 100% of scenarios with missing required skill catalog directories self-repair successfully at lifecycle entry without manual directory creation.
- **SC-004**: Brownfield detection accuracy reaches 100% across defined self-hosting and non-self-hosting test fixtures for `.squad/agents/` classification.
- **SC-005**: Documentation validation confirms maintainers can identify the correct update path and redeployment trigger in under 3 minutes during guided review.
- **SC-006**: 0 failing P0/P1 regression tests in patch test suite.

## Assumptions

- The v0.27.1 patch remains scoped to post-release fixes and documentation needed to safely apply those fixes.
- Existing lifecycle command expectations for non-patch behavior remain unchanged unless directly required to resolve listed findings.
- Maintainers applying updates have access to standard module-management workflows and can run follow-up initialization when required.
- Proposal 110 and Proposal 116 remain authoritative context and are compatible with this patch’s scope and sequencing.

## Composition with Other Proposals *(mandatory)*

- **Proposal 110**: This patch composes by preserving previously established lifecycle and governance intent while correcting post-release defects.
- **Proposal 116**: This patch composes by maintaining compatible entry-point behavior and expected artifact governance while applying bug-fix corrections.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Codex (session executor) under requestor authority from Alon Fliess
- **Iteration Facilitator**: Squad Coordinator
- **Capacity Model**: Patch-iteration model with defect-bundle closure before release tagging
- **Drift Signals**: Spec-to-plan/task mismatch, unresolved finding dispositions, pointer drift in active feature metadata, and mirror artifact divergence
- **Human Oversight Points**: Specify completion confirmation, pre-plan readiness gate, patch verification signoff, release-readiness signoff
