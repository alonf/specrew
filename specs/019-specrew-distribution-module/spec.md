# Feature Specification: Specrew Distribution Module

**Feature Branch**: `019-specrew-distribution-module`  
**Created**: 2026-05-16  
**Status**: Draft  
**Input**: User description: "PowerShell Gallery module packaging for one-line install, removing clone-and-PATH friction before public flip"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Install (Priority: P1)

A new user discovers Specrew (via documentation, blog post, or recommendation) and wants to try it in their project. Instead of cloning a repository and manipulating PATH variables, they run a single PowerShell command and have Specrew ready to use in under 30 seconds.

**Why this priority**: This is the highest-friction onboarding step identified by early contributors (empirical evidence: Venya's feedback). Removing this friction is load-bearing for public-flip success — visitors will bounce if the install step is painful.

**Independent Test**: Can be fully tested by (1) a clean Windows/Linux/Mac machine with PowerShell 7+ installed, (2) running `Install-Module Specrew -Scope CurrentUser`, (3) verifying `specrew` command is available, and (4) running `specrew init` in a test project directory to verify bootstrap succeeds.

**Acceptance Scenarios**:

1. **Given** a clean machine with PowerShell 7+ installed, **When** user runs `Install-Module Specrew -Scope CurrentUser`, **Then** the module installs without errors and `specrew` command becomes available in PATH
2. **Given** Specrew is installed, **When** user runs `specrew init` in an empty project directory, **Then** `.specify/`, `.squad/`, and `.github/` directories are created with all required template files
3. **Given** Specrew is installed on Linux, **When** user runs `specrew init`, **Then** templates are copied with correct cross-platform path handling (no backslash issues)

---

### User Story 2 - Project Bootstrap from Installed Module (Priority: P1)

After installing the Specrew module, a user navigates to their project directory and runs `specrew init`. The command detects it is running from an installed module (not a cloned repo), resolves template paths from the module installation directory, and copies all required templates into the user's project.

**Why this priority**: This is the core bootstrap mechanism. Without it, the module installation delivers no value. Must work on first try.

**Independent Test**: Install module, run `specrew init` in a test project, verify all templates are present and correctly structured (`.specify/templates/`, `.squad/agents/`, `.github/workflows/`, etc.).

**Acceptance Scenarios**:

1. **Given** Specrew module is installed, **When** user runs `specrew init` in a project directory, **Then** templates are copied from `$PSScriptRoot/../templates/` (module path) to the project's `.specify/`, `.squad/`, and `.github/` directories
2. **Given** `specrew init` has already been run, **When** user runs it again, **Then** the command detects existing templates and either skips or prompts for confirmation (idempotent behavior)
3. **Given** a project bootstrapped via `specrew init`, **When** user runs `specrew start`, **Then** the Specrew lifecycle operates normally using the copied templates and project-specific state

---

### User Story 3 - Module Update and Template Refresh (Priority: P2)

An existing Specrew user discovers a new version is available (e.g., via release notes or `Update-Module` notification). They run `Update-Module Specrew` to get the latest scripts and extensions. Then they run `specrew update` in their project directory to refresh templates while preserving user-edited files.

**Why this priority**: Essential for long-term maintainability. Without a clean update path, users are stuck on old versions or must manually reconcile template changes.

**Independent Test**: (1) Install module v0.21, run `specrew init` in a test project, (2) modify a template file (e.g., `.specify/templates/spec-template.md`), (3) update module to v0.22, (4) run `specrew update`, (5) verify new templates are added, user-modified files are preserved with conflict markers, and deletions are flagged.

**Acceptance Scenarios**:

1. **Given** a project initialized with module v0.21, **When** user updates to v0.22 and runs `specrew update`, **Then** new template files are added, existing unmodified files are updated, and user-modified files are preserved with conflict markers for manual review
2. **Given** a template file deleted in v0.22, **When** user runs `specrew update`, **Then** the file is flagged for manual deletion (or automatically removed with a backup)
3. **Given** scripts updated in the module, **When** user runs any `specrew` command after `Update-Module`, **Then** the new script logic takes effect immediately (scripts run from module path, not project path)

_Note: Update story pattern selection pending — see Clarifications Pending section._

---

### User Story 4 - Module Publishing on Feature Closeout (Priority: P2)

A Specrew maintainer completes a feature, follows Rule 15 (version bump, tag, PR), and pushes the tag to origin. A GitHub Action triggers automatically, runs `Publish-Module` with the PSGallery API key, and publishes the new version to PowerShell Gallery. Users can discover the new version via `Find-Module Specrew -AllVersions` or `Update-Module Specrew`.

**Why this priority**: Completes the distribution loop. Without automated publishing, module updates require manual maintainer steps, creating friction and risk of version drift.

**Independent Test**: (1) Create a test tag (e.g., `v0.21.0-test`), push to origin, (2) verify GitHub Action runs, (3) check PSGallery for the new version (or use a test gallery for dry-run validation).

**Acceptance Scenarios**:

1. **Given** a maintainer pushes a `v*.*` tag to origin, **When** the GitHub Action runs, **Then** `Publish-Module` succeeds and the new version appears on PSGallery within 10 minutes
2. **Given** the module version in `Specrew.psd1` matches `.specrew/config.yml` `specrew_version`, **When** `Publish-Module` runs, **Then** the PSGallery listing shows the correct version number
3. **Given** a publishing failure (e.g., API key expired), **When** the GitHub Action runs, **Then** the workflow fails visibly and logs the error for maintainer investigation

_Note: PSGallery API key management and module signing strategy pending — see Clarifications Pending section._

---

### User Story 5 - Cross-Platform Consistency (Priority: P3)

A user installs Specrew on Windows, Linux, and Mac. The module works identically on all three platforms: commands execute without path delimiter issues, templates copy correctly, and scripts resolve module paths using `Join-Path` everywhere.

**Why this priority**: PowerShell 7+ is cross-platform; Specrew should be too. Lower priority because most alpha users are on Windows, but essential for public flip credibility.

**Independent Test**: Run the same `Install-Module Specrew`, `specrew init`, `specrew start` sequence on Windows, Ubuntu, and macOS. Verify no errors and identical output.

**Acceptance Scenarios**:

1. **Given** Specrew installed on Linux, **When** user runs `specrew init`, **Then** template paths use forward slashes and files copy correctly
2. **Given** Specrew installed on macOS, **When** user runs `specrew where`, **Then** file paths display correctly without backslash artifacts
3. **Given** module manifest declares PowerShell ≥ 7 requirement, **When** user tries to install on PowerShell 5.1, **Then** installation fails with a clear error message

_Note: Cross-platform path handling strategy pending — see Clarifications Pending section._

---

### Edge Cases

- What happens when a user runs `specrew init` in a directory that already contains partial `.specify/` or `.squad/` directories from a previous incomplete initialization?
- How does `specrew update` handle a conflict where the user deleted a template file that still exists in the new module version?
- What happens if a user manually modifies `Specrew.psm1` after installation (e.g., to debug an issue)? Does `Update-Module` restore the original, or does it preserve user changes?
- What happens when PSGallery name `Specrew` is already taken by another author? Do we have a fallback name strategy?
- How does the module behave when installed in both `-Scope CurrentUser` and `-Scope AllUsers` simultaneously?

_Note: Module name on PSGallery pending — see Clarifications Pending section._

## Requirements *(mandatory)*

### Functional Requirements

#### Pillar 1: PowerShell Module Packaging

- **FR-001**: Module MUST include a valid `Specrew.psd1` manifest declaring PowerShell ≥ 7 as the minimum version
- **FR-002**: Module MUST export all Specrew CLI commands as PowerShell functions (`specrew`, `specrew-init`, `specrew-start`, `specrew-where`, `specrew-review`, `specrew-team`, `specrew-update`)
- **FR-003**: Manifest MUST declare no external runtime dependencies beyond PowerShell 7
- **FR-004**: Manifest MUST include module metadata: version (matching `.specrew/config.yml` `specrew_version`), author, repository URL, and tags for discoverability
- **FR-005**: Module package MUST be under 5 MB to stay well within PSGallery's 2 GB limit

#### Pillar 2: Template + Resource Bundling

- **FR-006**: Module MUST bundle all Specrew scripts under `scripts/` (entry points + internal utilities)
- **FR-007**: Module MUST bundle the validator extension under `extensions/specrew-speckit/` (validators, governance, coordinator prompts, Squad templates)
- **FR-008**: Module MUST bundle user-facing templates under `templates/` (specify, squad, github subdirectories) that `specrew init` will copy into user projects
- **FR-009**: Module MUST bundle reference documentation (dashboard-guide.md, roadmap-maintenance.md) under `docs/`
- **FR-010**: Module MUST exclude Specrew's own `specs/`, `proposals/`, `tests/`, and repo-metadata artifacts (CHANGELOG, LICENSE, README) from the distributed package

#### Pillar 3: `specrew init` Bootstrap from Module

- **FR-011**: `specrew-init.ps1` MUST detect whether it is running from an installed module or a cloned repository
- **FR-012**: When running from a module, `specrew-init.ps1` MUST resolve template paths from `$PSScriptRoot/../templates/` (the module's bundled templates)
- **FR-013**: `specrew init` MUST copy `templates/specify/*` to `<user-project>/.specify/`
- **FR-014**: `specrew init` MUST copy `templates/squad/*` to `<user-project>/.squad/`
- **FR-015**: `specrew init` MUST copy `templates/github/*` to `<user-project>/.github/`
- **FR-016**: `specrew init` MUST generate per-project files (feature.json baseline, .squad/decisions.md skeleton, .squad/identity/now.md) after copying templates
- **FR-017**: `specrew init` MUST validate the bootstrapped project state and report success/failure
- **FR-018**: `specrew init` MUST be idempotent: running it multiple times in the same directory should not corrupt existing templates or project state

#### Pillar 4: Update Story

- **FR-019**: `Update-Module Specrew` MUST update scripts and extensions in the installed module path, taking effect immediately on next command invocation
- **FR-020**: `specrew update` command MUST implement the selected template-refresh pattern (to be determined at clarify time)
- **FR-021**: If Pattern B is selected at clarify time, `specrew update` MUST detect user-modified template files and preserve them with conflict markers for manual review
- **FR-022**: If Pattern B is selected at clarify time, `specrew update` MUST add new template files from the updated module version
- **FR-023**: If Pattern B is selected at clarify time, `specrew update` MUST flag template files deleted in the new module version for manual review

#### Pillar 5: Publishing + Versioning

- **FR-024**: A `Publish-Module` workflow MUST exist that reads version from `.specrew/config.yml` `specrew_version`
- **FR-025**: The workflow MUST sign the module package with a maintainer API key (PSGallery requirement)
- **FR-026**: The workflow MUST publish to PSGallery on every `v*.*` tag push to origin
- **FR-027**: The workflow MUST integrate with the existing Rule 15 feature-closeout sequence (after tag push, before PR merge)
- **FR-028**: The workflow MUST run as a GitHub Action using a PSGallery API key stored as a GitHub secret
- **FR-029**: The workflow MUST log errors visibly if publishing fails (e.g., API key expired, version collision)

#### Cross-Platform Requirements

- **FR-030**: All scripts MUST use `Join-Path` for path construction to ensure correct delimiters on Windows (`\`) and Linux/Mac (`/`)
- **FR-031**: Module MUST be tested on Windows, Linux (Ubuntu), and macOS before every release
- **FR-032**: Module manifest MUST declare `PSEdition = 'Core'` to enforce PowerShell 7+ requirement

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.

### Key Entities *(include if feature involves data)*

- **Module Manifest (Specrew.psd1)**: Declares module metadata, exported functions, dependencies, and file list. Central source of truth for module identity and versioning.
- **Template Tree**: The set of files under `templates/` in the module that `specrew init` copies into user projects. User-owned post-init; module-owned pre-init.
- **User Project**: A directory where a user has run `specrew init`. Contains `.specify/`, `.squad/`, and `.github/` directories populated from the module's template tree.
- **PSGallery API Key**: A secret credential stored as a GitHub Actions secret, used by `Publish-Module` to authenticate with PowerShell Gallery during automated releases.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: New users can install Specrew with a single `Install-Module Specrew -Scope CurrentUser` command and have it working in under 1 minute
- **SC-002**: `specrew init` succeeds on first try in 95% of test scenarios (Windows, Linux, macOS; empty directory, existing partial directory)
- **SC-003**: Module updates via `Update-Module Specrew` complete in under 30 seconds and new versions take effect on next command invocation
- **SC-004**: Zero clone-and-PATH onboarding friction reports from new users after module launch (measured via GitHub issues, feedback channels)
- **SC-005**: Module publishing via GitHub Action completes within 10 minutes of tag push and new versions appear on PSGallery within 15 minutes
- **SC-006**: Cross-platform parity: identical behavior on Windows, Linux, and macOS for install, init, and update workflows

## Assumptions

- Users have PowerShell 7+ installed (PowerShell Gallery requires pwsh 7 for modern cross-platform modules)
- Users have internet connectivity to access PowerShell Gallery during install and update
- Existing alpha users (who cloned the repo) are willing to migrate to the module-based distribution post-launch; migration path to be defined at clarify time
- The existing Rule 15 sequence is authoritative; the new `Publish-Module` step composes with the existing tag + PR workflow without disrupting it
- Template-update conflict resolution, module signing strategy, PSGallery name selection, and cross-platform path handling approach are open for clarify-time resolution (see Clarifications Pending section)

## Non-Goals (Explicit Scope Boundaries)

**OUT of scope for this feature:**

1. **Slash Commands / Proposal 032**: This feature does NOT implement or integrate with the Slash-Command Surface (Proposal 032). That proposal is blocked until after Multi-Host Runtime Abstraction CORE (Proposal 024). Distribution is orthogonal to Squad/Copilot CLI surface changes.
2. **winget / Chocolatey / Scoop distribution**: Only PowerShell Gallery for v1. Other distribution channels may be added post-public-flip if demand emerges.
3. **Module signing beyond self-sign for v1**: Real codesign certificate acquisition is deferred unless early feedback shows PSGallery trust warnings are a significant blocker.
4. **Alpha-user migration tooling**: No automated `specrew migrate-to-module` command in v1. Manual migration guidance in README is sufficient initially; tooling can be added later if friction reports indicate a need.
5. **Template versioning and backward compatibility**: No complex version-negotiation logic in v1. Templates copied at init time are user-owned; updates are manual or via `specrew update` (Pattern B). If a breaking template change ships, users handle it as a manual migration step.

**IN scope for this feature:**

1. PowerShell Gallery module packaging (Pillar 1)
2. Template + resource bundling in the module (Pillar 2)
3. `specrew init` bootstrap refactor to resolve templates from module install path (Pillar 3)
4. `specrew update` template-refresh story (Pillar 4, pending clarify-time pattern selection)
5. Publishing/versioning workflow integrated into Rule 15 feature-closeout (Pillar 5)

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess (feature sponsor; accountable for spec integrity and clarify-time decisions)
- **Iteration Facilitator**: Alon Fliess (accountable for cadence, blockers, and Phase 2 sequencing)
- **Capacity Model**: Story Points (SP); estimated 10-15 SP total across 5 pillars; single iteration; fits as a focused Monday-Tuesday slot in Phase 2 Quality Hardening Bundle sequencing
- **Drift Signals**: Spec-to-implementation drift detected via (1) Specrew-Speckit extension validators during `/speckit.implement`, (2) integration tests for cross-platform module install/init/update workflows, (3) manual review of PSGallery publish logs post-release
- **Human Oversight Points**: 
  - Clarify-time decisions for the 10 open questions (next `/speckit.clarify` boundary)
  - Planning approval after `/speckit.plan` generates design artifacts
  - Pre-release manual test on Windows/Linux/macOS before first `Publish-Module` run
  - Post-release verification that PSGallery listing is correct and `Install-Module Specrew` works for new users

## Clarifications Pending *(mandatory for Draft status)*

The following 10 questions were identified during specification and require resolution at the next `/speckit.clarify` boundary before proceeding to planning and implementation. **These are open questions; recommendations provided are for context only and do not represent pre-made decisions.**

### Q1: Update Story Pattern

**Context**: When a user updates the Specrew module and wants to refresh templates in their project, how should `specrew update` handle user-modified files?

**Options**:
- **Pattern A (No Auto-Update)**: Templates copied at init are user-owned forever; no `specrew update` template-refresh capability
- **Pattern B (Template-Refresh)**: `specrew update` syncs templates while preserving user edits with conflict markers
- **Pattern C (Scripts-from-Module, Templates-from-Project)**: Cleanest separation; scripts always run from module path, templates are never updated

**Recommended direction** (for clarify-time consideration): Pattern B provides the best UX by balancing update convenience with user control

**Implications**: Affects FR-020 through FR-023 and User Story 3 acceptance scenarios

---

### Q2: Distribution Channel Scope

**Context**: Should v1 support multiple distribution channels, or start with one and expand later?

**Options**:
- PowerShell Gallery only for v1
- PowerShell Gallery + winget for v1
- PowerShell Gallery + winget + Chocolatey + Scoop for v1

**Recommended direction** (for clarify-time consideration): PSGallery only for v1; add other channels post-public-flip if demand emerges

**Implications**: Affects module packaging effort, testing matrix, and maintenance burden

---

### Q3: Module Name on PSGallery

**Context**: What name should we use when registering the module on PowerShell Gallery?

**Options**:
- `Specrew` (exact match with repo name)
- `SpeckitSquad.Specrew` (namespaced to avoid collisions)
- Other variant (e.g., `Specrew-CLI`, `SpeckitSpecrew`)

**Recommended direction** (for clarify-time consideration): Claim `Specrew` exactly if available (we own the name; reserve before public flip)

**Implications**: Affects module manifest name, install command, and user-facing documentation

---

### Q4: PSGallery API Key Management

**Context**: Where should the PSGallery API key be stored for automated publishing?

**Options**:
- GitHub Actions secret (CI-triggered publish on tag push)
- Local maintainer machine (manual publish step)

**Recommended direction** (for clarify-time consideration): GitHub Actions secret for security, automation, and integration with Rule 15

**Implications**: Affects FR-028, publishing workflow design, and maintainer onboarding

---

### Q5: Module Signing Strategy

**Context**: Should the module be signed for PSGallery trust, and if so, how?

**Options**:
- No signing for v1 (fastest to ship, but PSGallery shows "unsigned" warning)
- Self-sign for v1 (quick setup, reduces warnings)
- Acquire real codesign certificate for v1 (most trusted, but adds acquisition lead time)

**Recommended direction** (for clarify-time consideration): Self-sign for v1; revisit for v1.0+ based on user feedback

**Implications**: Affects FR-025, publishing workflow complexity, and user trust on install

---

### Q6: Backward Compatibility with Clone-and-PATH

**Context**: After module distribution launches, should the existing clone-and-PATH approach continue to work?

**Options**:
- Support indefinitely (Spec Kit pattern: both distribution models coexist)
- Deprecate after module lands (module becomes the canonical path; clone-and-PATH sunsets)
- Deprecate immediately (remove clone-and-PATH bootstrap from README)

**Recommended direction** (for clarify-time consideration): Support indefinitely; document migration in README but don't force it

**Implications**: Affects alpha-user migration timeline, documentation, and testing matrix

---

### Q7: Template-Update Conflict Resolution

**Context**: When `specrew update` detects a user-modified template file that also changed in the new module version, what should happen?

**Options**:
- Overwrite (user changes lost)
- Skip (new template changes ignored)
- 3-way merge (complex, requires merge tooling)
- Preserve and flag with explicit diff for manual review

**Recommended direction** (for clarify-time consideration): Preserve and flag with explicit diff — gives users full control and visibility

**Implications**: Affects FR-021 implementation and User Story 3 edge-case handling

---

### Q8: Cross-Platform Path Handling

**Context**: How should scripts handle Windows (`\`) vs Linux/Mac (`/`) path delimiters?

**Options**:
- Use `Join-Path` everywhere for explicit cross-platform correctness
- Rely on PowerShell's automatic path normalization

**Recommended direction** (for clarify-time consideration): Use `Join-Path` everywhere, plus integration tests on Linux for validation

**Implications**: Affects FR-030, code review checklist, and cross-platform testing requirements

---

### Q9: Module Version Policy

**Context**: Should the module version in `Specrew.psd1` be the same as the repo version, or maintained separately?

**Options**:
- Same version: `Specrew.psd1` reads `.specrew/config.yml` `specrew_version` at build time
- Separate version: Module versioning decoupled from repo versioning

**Recommended direction** (for clarify-time consideration): Same version — single source of truth reduces drift risk

**Implications**: Affects FR-024, publishing workflow, and version-sync governance

---

### Q10: Alpha-User Migration Path

**Context**: How should existing alpha users (who cloned the repo) transition to the module-based distribution?

**Options**:
- Provide a `specrew migrate-to-module` command that automates the transition
- Document manual migration steps in README only
- No migration tooling or documentation (users figure it out themselves)

**Recommended direction** (for clarify-time consideration): README documentation initially; add tooling later if friction reports indicate a need

**Implications**: Affects user story prioritization, alpha-user communication timeline, and v1 scope

## Cross-References

- **F-009 (Project Path Resolution in Entry-Point Scripts)**: Foundational path-handling logic that `specrew init` relies on for module-path detection and template resolution.
- **F-011 (Specrew Start Conditional Pause)**: Composes with module's session-state files; no conflicts expected.
- **Proposal 030 (Quality Hardening Bundle)**: Distribution sequences alongside the bundle in Phase 2; benefits from the bundle's quality machinery.
- **Proposal 009 (Velocity Dashboard)**: Composes; dashboard help text would update to mention `Install-Module Specrew` as the canonical install path post-distribution.
- **Proposal 013 (Methodology Site)**: Composes; site would document `Install-Module Specrew` as the one-line install story.
- **Rule 15 (Feature Closeout Sequence)**: Gains a `Publish-Module` step after tag push; composes with recent extension.yml/.specrew/config.yml version-sync drift rule.

## Status History

- **2026-05-16**: Candidate captured after Venya's clone-and-PATH onboarding friction feedback; source spec drafted with 5 pillars + 10 clarify-time questions.
- **2026-05-16**: Spec generated via `/speckit.specify` boundary; status set to Draft; 10 clarify-time questions preserved for next `/speckit.clarify` boundary.
