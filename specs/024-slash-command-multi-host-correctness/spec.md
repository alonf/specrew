# Feature Specification: Slash-Command Multi-Host Correctness

**Feature Branch**: `024-slash-command-multi-host-correctness`  
**Created**: 2026-05-19  
**Status**: Approved  
**Approved By**: User request on 2026-05-19 authorizing planning with bound before-plan inputs for Feature 024.  
**Input**: User description: "Restore F-021's slash-command surface by deploying command skills to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`; add valid YAML frontmatter to every `SKILL.md`; replace `/specrew.X` with `/specrew-X`; migrate Specrew-managed legacy `.copilot/skills/specrew-*` content on `specrew update`; add deployment/frontmatter/migration coverage; and reframe Proposal 058 to non-skill scope for v0.24.0."

## Clarifications

### Session 2026-05-19

- Q: Should v0.24.0 claim Codex CLI discoverability now, or limit the public release claim to Claude Code + GitHub Copilot CLI while still deploying `.agents/skills/` as a host-neutral path? → A: Limit v0.24.0 discoverability claims to Claude Code and GitHub Copilot CLI, and ship `.agents/skills/` as a host-neutral future-proof deployment path without treating Codex CLI discoverability as a current acceptance guarantee.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover working slash commands after bootstrap (Priority: P1)

As a Specrew maintainer bootstrapping a fresh project, I want the published slash-command catalog to be deployed in every supported project skill location with valid metadata, so the commands Specrew advertises are actually discoverable in Claude Code and GitHub Copilot CLI instead of only appearing correct on disk.

**Why this priority**: This is the core promise being restored. If fresh bootstrap does not produce a discoverable slash-command surface, the feature has not fixed the form-vs-meaning failure that triggered Feature 024.

**Independent Test**: Can be fully tested by running `specrew init` in a clean project, confirming that all seven existing commands are deployed to the three supported project skill locations with matching content, and validating that Claude Code or GitHub Copilot CLI can discover `/specrew-where`.

**Acceptance Scenarios**:

1. **Given** a clean project with no existing slash-command deployment, **When** the maintainer runs `specrew init`, **Then** all seven existing Specrew slash commands are deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`.
2. **Given** a deployed command definition, **When** the maintainer validates its metadata, **Then** the `SKILL.md` contains valid YAML frontmatter with a hyphenated `name` that matches the directory and a non-empty `description`.
3. **Given** Claude Code or GitHub Copilot CLI is available after bootstrap, **When** the maintainer opens slash-command discovery, **Then** the published commands appear in the `/specrew-*` form rather than the deprecated `/specrew.*` form.

---

### User Story 2 - Upgrade existing projects without orphaned legacy skills (Priority: P2)

As a Specrew maintainer upgrading an existing project, I want `specrew update` to remove obsolete Specrew-managed legacy skill directories without deleting user-authored content, so the project is cleaned up safely during migration.

**Why this priority**: Existing users must not be left with non-discoverable legacy directories or risky cleanup behavior. Safe migration makes the fix credible for already-initialized projects, not only greenfield ones.

**Independent Test**: Can be fully tested by seeding a project with managed and unmanaged legacy `.copilot/skills/specrew-*` content, running `specrew update`, and verifying that only the Specrew-managed legacy directories are removed while the new three-path deployment is populated.

**Acceptance Scenarios**:

1. **Given** a project seeded with Specrew-managed legacy `.copilot/skills/specrew-*` directories, **When** the maintainer runs `specrew update`, **Then** the managed legacy directories are removed and the three supported deployment paths are repopulated.
2. **Given** a project containing unmanaged or third-party content under `.copilot/skills/`, **When** the maintainer runs `specrew update`, **Then** that unmanaged content remains untouched and is surfaced as non-discoverable leftover content rather than deleted.

---

### User Story 3 - Keep release messaging and governance truthful (Priority: P3)

As a release owner preparing v0.24.0, I want tests, docs, changelog language, and proposal references to describe the restored slash-command surface truthfully for Claude Code, GitHub Copilot CLI, and host-neutral `.agents/skills/` deployment, so Specrew's published guidance matches actual runtime behavior and Proposal 058 is narrowed correctly.

**Why this priority**: Feature 024 is partly a trust repair. The slash surface, release notes, and proposal landscape must all describe the same reality or the feature will recreate the same mismatch in a different form.

**Independent Test**: Can be fully tested by reviewing active references for deprecated `/specrew.*` usage, confirming the new tests pass, verifying the v0.24.0 prerelease smoke cycle succeeds for Claude Code or GitHub Copilot CLI discoverability plus `.agents/skills/` deployment, and checking that Proposal 058 is reframed to non-skill scope only.

**Acceptance Scenarios**:

1. **Given** the active code, tests, docs, and governance artifacts for v0.24.0, **When** they are reviewed, **Then** active references use `/specrew-*` and historical pre-v0.24.0 artifacts retain their original dot-form record unchanged.
2. **Given** the v0.24.0 release line is being prepared, **When** prerelease validation is run from a clean install, **Then** the restored Claude Code or GitHub Copilot CLI slash-command surface, host-neutral `.agents/skills/` deployment, metadata validity, and migration behavior are confirmed before stable promotion.
3. **Given** Proposal 058 is updated after Feature 024, **When** its scope is reviewed, **Then** it covers only non-skill per-host instruction-file harmonization and references Feature 024 as resolving the skill-surface concern.

---

### Edge Cases

- A project contains both Specrew-managed and unmanaged `specrew-*` directories under the legacy `.copilot/skills/` path.
- One or more target deployment paths already exist from a prior init or partial update and must be re-synchronized without drifting content.
- A deployed `SKILL.md` is missing frontmatter or uses a `name` that does not match its directory.
- Historical specs, archived decisions, or older changelog entries still contain `/specrew.*` references that should remain as historical record.
- Claude Code or GitHub Copilot CLI manual validation is unavailable during prerelease smoke; release evidence must still capture automated deployment, metadata, and migration checks.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Fresh project bootstrap MUST deploy each of the seven existing Specrew slash commands (`where`, `status`, `update`, `team`, `review`, `help`, `version`) to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`.
  - **Acceptance criteria**: A clean bootstrap produces one deployed `SKILL.md` per command in each of the three supported project skill locations.
  - **Expected owner role(s)**: Runtime maintainer, release verifier
  - **Intended delivery window**: Feature 024 single iteration
- **FR-002**: The deployed command definitions across the three supported project skill locations MUST remain content-identical and managed as one logical deployment set.
  - **Acceptance criteria**: Deployment and update flows keep the three copies synchronized with no command-specific divergence between hosts.
  - **Expected owner role(s)**: Runtime maintainer
  - **Intended delivery window**: Feature 024 single iteration
- **FR-003**: Every deployed `SKILL.md` MUST include YAML frontmatter with a lowercase-hyphen `name`, a non-empty `description`, and optional `allowed-tools` where tool restrictions are part of the command contract; the existing body guidance MUST remain intact.
  - **Acceptance criteria**: Frontmatter validation succeeds for every deployed command definition, and body guidance still exposes inputs, outputs, argument rules, and failure guidance.
  - **Expected owner role(s)**: Template steward, QA owner
  - **Intended delivery window**: Feature 024 single iteration
- **FR-004**: All active user-facing, operational, and governance references to the slash-command catalog MUST use the `/specrew-X` hyphenated form, while historical pre-v0.24.0 records remain unchanged.
  - **Acceptance criteria**: Active references contain no `/specrew.X` spelling, and archived historical materials are preserved as record rather than rewritten.
  - **Expected owner role(s)**: Documentation owner, governance steward
  - **Intended delivery window**: Feature 024 single iteration
- **FR-005**: `specrew update` MUST remove legacy `.copilot/skills/specrew-*` directories only when they are confirmed to be Specrew-managed; unmanaged or third-party content MUST be preserved and surfaced as leftover non-discoverable content.
  - **Acceptance criteria**: Managed legacy directories are removed during update, while unmanaged content remains intact and is not silently deleted.
  - **Expected owner role(s)**: Runtime maintainer, migration verifier
  - **Intended delivery window**: Feature 024 single iteration
- **FR-006**: Automated validation MUST add three new integration tests covering multi-path deployment, frontmatter validity, and legacy-path migration.
  - **Acceptance criteria**: Each new test exercises the restored surface and fails if deployment, metadata, or migration behavior regresses.
  - **Expected owner role(s)**: QA owner, integration-test steward
  - **Intended delivery window**: Feature 024 single iteration
- **FR-007**: All pre-existing slash-command validation coverage MUST remain active and pass against the hyphenated, multi-host surface with no skipped assertions.
  - **Acceptance criteria**: Existing slash-command-related test coverage passes after being updated for the new canonical form and deployment shape.
  - **Expected owner role(s)**: QA owner
  - **Intended delivery window**: Feature 024 single iteration
- **FR-008**: Release readiness for v0.24.0 MUST include a prerelease validation cycle through v0.24.0-beta.1 in a clean PowerShell session, verifying bootstrap deployment, frontmatter validity, migration behavior, and manual `/specrew-where` discoverability in Claude Code or GitHub Copilot CLI before stable promotion.
  - **Acceptance criteria**: Stable promotion is blocked until prerelease smoke evidence confirms the restored Claude Code or GitHub Copilot CLI slash-command surface, host-neutral `.agents/skills/` deployment, and required migration behavior.
  - **Expected owner role(s)**: Release owner, smoke-test verifier
  - **Intended delivery window**: Feature 024 single iteration and release closeout
- **FR-009**: The v0.24.0 release line MUST truthfully describe this fix in release metadata, including restored slash-command discoverability in Claude Code and GitHub Copilot CLI, host-neutral `.agents/skills/` deployment, and cleanup of managed legacy `.copilot/skills/` directories on update.
  - **Acceptance criteria**: The module version line, extension baseline, Specrew version metadata, and changelog all describe the same narrowed, evidence-backed host coverage.
  - **Expected owner role(s)**: Release owner, documentation owner
  - **Intended delivery window**: Feature 024 closeout
- **FR-010**: Proposal 058 MUST be reframed to non-skill per-host instruction-file harmonization only, with explicit cross-reference that Feature 024 resolves the skill-surface portion.
  - **Acceptance criteria**: Proposal 058 status and body no longer frame skill deployment as unresolved work and instead focus on `AGENTS.md`, `copilot-instructions.md`, and `CLAUDE.md` harmonization.
  - **Expected owner role(s)**: Product steward, proposal owner
  - **Intended delivery window**: Feature 024 single iteration
- **FR-011**: The specification and downstream lifecycle artifacts MUST preserve the form-vs-meaning rationale for this feature: slash commands are not considered restored when files merely exist on disk; they are restored only when the published surface is discoverable and the messaging is truthful.
  - **Acceptance criteria**: Lifecycle artifacts, release messaging, and retro language all treat discoverability and truthfulness as first-class acceptance evidence.
  - **Expected owner role(s)**: Spec steward, retro facilitator
  - **Intended delivery window**: Feature 024 through retro
- **FR-012**: Public host-coverage wording for Feature 024 MUST claim slash-command discoverability only for Claude Code and GitHub Copilot CLI in v0.24.0, while still deploying `.agents/skills/` as a host-neutral future-proof path and explicitly deferring Codex CLI discoverability claims until its project-skill guidance stabilizes.
  - **Acceptance criteria**: The narrowed wording is applied consistently in the specification, proposal updates, changelog language, release messaging, and prerelease validation expectations.
  - **Expected owner role(s)**: Product steward, release owner
  - **Intended delivery window**: Clarify before planning

### Acceptance Alignment (Source AC1-AC10)

- **AC1 alignment**: Fresh bootstrap deploys every existing slash command to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`, with content-identical `SKILL.md` files across the three paths.
- **AC2 alignment**: Every deployed `SKILL.md` contains valid YAML frontmatter with a directory-matching lowercase-hyphen `name` and a non-empty `description`.
- **AC3 alignment**: No active code, test, documentation, or governance artifact uses `/specrew.X` after the fix, while historical Feature 021 artifacts and pre-v0.24.0 records remain unchanged.
- **AC4 alignment**: `specrew update` removes Specrew-managed legacy `.copilot/skills/specrew-*` directories but preserves non-Specrew content.
- **AC5 alignment**: Existing slash-command-related tests pass after being updated for the restored surface.
- **AC6 alignment**: Three new integration tests are added and pass: multi-path deployment, frontmatter validity, and migration.
- **AC7 alignment**: A clean prerelease install of v0.24.0-beta.1 validates bootstrap deployment, metadata, migration, host-neutral `.agents/skills/` deployment, and manual `/specrew-where` discoverability in Claude Code or GitHub Copilot CLI.
- **AC8 alignment**: The v0.24.0 release line updates the required version-bearing artifacts together so the published baseline is internally consistent.
- **AC9 alignment**: `CHANGELOG.md` gains a truthful v0.24.0 entry describing restored discoverability in Claude Code and GitHub Copilot CLI, host-neutral `.agents/skills/` deployment, and cleanup of legacy managed `.copilot/skills/` paths on update.
- **AC10 alignment**: Proposal 058 is updated so its scope is explicitly limited to non-skill host harmonization, with Feature 024 cited as the skill-surface resolution.

### Story Traceability

- **User Story 1** maps to **FR-001**, **FR-002**, **FR-003**, **FR-004**, **FR-006**, **FR-007**, **FR-008**, and **FR-011**.
- **User Story 2** maps to **FR-005**, **FR-006**, **FR-007**, **FR-008**, and **FR-011**.
- **User Story 3** maps to **FR-004**, **FR-008**, **FR-009**, **FR-010**, **FR-011**, and **FR-012**.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements, and the mapping MUST remain explicit in this specification and downstream tasks.
- **TG-002**: Each functional requirement MUST identify expected owner role(s) so accountability is visible before planning begins.
- **TG-003**: Each functional requirement MUST identify its intended delivery window within the single-iteration Feature 024 lifecycle.
- **TG-004**: Any conflict between restored slash-command claims and actual host evidence MUST include an explicit reconciliation path before stable release, with FR-012's narrowed host-coverage wording remaining the governing truth source for v0.24.0.

### Key Entities *(include if feature involves data)*

- **Slash Command Definition**: One of the seven existing Specrew commands, expressed as a directory-scoped `SKILL.md` with a canonical hyphenated name, discovery description, optional tool constraints, and retained body guidance.
- **Deployment Target**: A supported project skill location (`.claude/skills/`, `.github/skills/`, or `.agents/skills/`) that receives the same command definition set.
- **Legacy Skill Directory**: A pre-v0.24.0 `.copilot/skills/specrew-*` directory that may be Specrew-managed or unmanaged and therefore requires different migration behavior.
- **Validation Evidence Pack**: The combined set of automated test results, prerelease smoke findings, and release-messaging checks used to prove the restored surface has meaning rather than only form.
- **Proposal Reference**: A forward-looking proposal whose scope or messaging must remain aligned with Feature 024, especially Proposal 058.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a clean bootstrap, all seven published slash commands are deployed to every supported project skill location, with 100% content parity across those locations.
- **SC-002**: 100% of deployed command definitions pass metadata validation for directory-matching hyphenated names and non-empty descriptions.
- **SC-003**: 100% of validated migration scenarios remove obsolete Specrew-managed legacy directories while preserving seeded unmanaged content.
- **SC-004**: Zero active references to the slash-command catalog use the deprecated `/specrew.*` spelling by release readiness review.
- **SC-005**: Stable v0.24.0 promotion does not proceed until prerelease smoke evidence confirms restored slash-command discoverability in Claude Code or GitHub Copilot CLI, host-neutral `.agents/skills/` deployment, metadata validity, and migration behavior.

## Assumptions

- Feature 024 preserves Feature 021's existing seven-command catalog and does not add new slash commands.
- The three supported project skill locations receive content-identical command definitions; host-specific divergence is out of scope for this release.
- Codex CLI discoverability is not a v0.24.0 acceptance guarantee; `.agents/skills/` is shipped as a host-neutral future-proof path until Codex publishes stable project-skill guidance.
- Managed-marker detection from existing Specrew hygiene tooling remains the authority for deciding whether legacy `.copilot/skills/` content is safe to remove.
- Manual host discovery validation may be performed in Claude Code or GitHub Copilot CLI during prerelease smoke; automated host-menu verification remains deferred to later integration-test expansion.
- The release follows the normal Specrew lifecycle for a single iteration: specify → clarify → plan → tasks → implement → review → retro → iteration-closeout → feature-closeout, with merge-commit closeout after prerelease validation and smoke success.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess with the Specrew spec-steward role accountable for preserving source-draft intent and AC1-AC10 substance.
- **Iteration Facilitator**: The Feature 024 Specrew squad facilitator accountable for keeping the single-iteration lifecycle moving and surfacing blockers quickly.
- **Capacity Model**: One normal feature iteration, estimated at 5-7 story points, culminating in v0.24.0 after prerelease validation via v0.24.0-beta.1.
- **Drift Signals**: Surviving `/specrew.*` references in active materials, missing or invalid `SKILL.md` frontmatter, non-identical deployment content across supported paths, unmanaged content deleted during migration, or Proposal 058 language that still treats skills as unresolved.
- **Human Oversight Points**: Approve prerelease smoke evidence before stable promotion; review PR-at-feature-close; confirm changelog and proposal wording keep FR-012's narrowed host-coverage claim intact before merge.
