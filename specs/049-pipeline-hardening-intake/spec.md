# Feature Specification: Release Pipeline Hardening + Substantive Intake Slice

**Feature Branch**: `049-pipeline-hardening-intake`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: F-049 user request: Docker pre-publish version-update validation, durable troubleshooting guide docs, and persona-driven `/speckit.specify` intake.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pre-Publish Docker Harness Verification (Priority: P1)

To ensure that no release ever ships with a corrupt module layout or missing FileList entries (which would break downstream users), the release pipeline must run a fresh Docker-based E2E harness before publishing the module to PSGallery.

**Why this priority**: Highly critical regression guard. Within the last 48 hours, 4 critical FileList packaging omissions have shipped to production (e.g., hooks/ omissions in v0.25.0+ and docs omissions in v0.27.6-beta.1). This pre-publish block will catch layout corruption deterministically.

**Independent Test**: Can be fully tested locally and in CI by running the Docker build/test harness against a packaged module candidate.

**Acceptance Scenarios**:

1. **Given** a packaged Specrew module candidate (`.nupkg` / `.zip`), **When** the Docker harness bootstraps, **Then** it installs the previous stable version (v0.27.6) in a clean Linux PowerShell container.
2. **Given** a clean project initialized with `specrew init` under the candidate version, **When** the harness scans the layout, **Then** it verifies that **every** single entry declared in `Specrew.psd1`'s `FileList` was correctly unpacked and exists on disk.
3. **Given** a candidate project layout, **When** `specrew update` is executed, **Then** all files are updated/preserved correctly and absolute mirror parity is preserved.
4. **Given** a failing layout assertion inside the Docker test execution, **When** the publish workflow (`publish-module.yml`) runs, **Then** the workflow is **blocked** and halts immediately before publishing to PSGallery.

---

### User Story 2 - Troubleshooting Guide and Documentation (Priority: P2)

To empower users to recover gracefully from environment issues, local conflicts, or package managers caching side-by-side installations, we will author a durable, comprehensive troubleshooting document.

**Why this priority**: Ensures supportability. When FileList omissions or side-by-side installations occur, developers need clear, structured recovery sequences instead of flying blind.

**Independent Test**: Readability and cross-reference check in the generated docs. Verification that `docs/troubleshooting.md` is registered in `Specrew.psd1` FileList in the same commit.

**Acceptance Scenarios**:

1. **Given** a new developer experiencing a broken or incomplete package install, **When** they inspect the codebase documentation, **Then** they find `docs/troubleshooting.md` detailing standard recovery flows.
2. **Given** `docs/troubleshooting.md` is created, **When** a commit is authored, **Then** it must include the addition of `docs/troubleshooting.md` in `Specrew.psd1`'s `FileList`.
3. **Given** the documentation is updated, **When** a user browses `README.md`, `docs/getting-started.md`, or `docs/user-guide.md`, **Then** clear cross-references point to the new troubleshooting guide.

---

### User Story 3 - Persona-Driven Substantive Specification Intake (Priority: P3)

To ensure that the initial specify phase (`/speckit.specify`) captures realistic scope, technology constraints, and organizational context, it must utilize an interactive, multi-mode, persona-driven intake process.

**Why this priority**: Substantially reduces clarify-phase back-and-forth by ensuring that the spec is born stack-aware, persona-aligned, and structurally complete.

**Independent Test**: Execute the new `/speckit.specify` command under various input states (full, partial, empty/vibe) and assert the correct persona-driven spec template and catalog layout are generated.

**Acceptance Scenarios**:

1. **Given** a user initiating `/speckit.specify`, **When** the agent prompts for project scope, **Then** the user can select one of **4 distinct personas** (PM, UX, Architect, AI Researcher / Project Manager) to govern the template style and questions.
2. **Given** a chosen persona, **When** intake begins, **Then** it presents the **12-category intake catalog** (covering stack selections, safe-parallelism, auth/security parameters, deployment, and testing boundaries).
3. **Given** a user input, **When** the intake mode is evaluated:
   - **Mode A (Sufficient)**: Directly generates the `spec.md` and displays a confirmation pass.
   - **Mode B (Partial)**: Asks 2-3 highly targeted clarifications before generating.
   - **Mode C (Vibe coding)**: Launches a structured interactive interview to guide the user.
4. **Given** any question during intake, **When** the user is unsure, **Then** they can choose `"Other"` or `"I don't know, you decide"` to let the agent auto-derive optimal defaults based on stack-aware analysis.

---

## Edge Cases

- **Docker Harness Timeout/Network Latency**: The pre-publish harness might hit a network timeout pulling the previous version from PSGallery. The test must gracefully retry or cache baseline layouts.
- **PSGallery Side-by-Side Cache Invalidation**: Package managers might return cached, stale layout versions during local `Save-Module` updates. The troubleshooting guide must outline how to force-clean the NuGet cache.
- **Aborted Intake Mode**: If a user aborts during a Mode C interactive interview, the system must retain partial progress in `.specify/feature.json` so it can be resumed.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Iteration 1: Docker Pre-Publish Verification

- **FR-001**: System MUST supply a Docker-based test runner using a Linux-based PowerShell container (`mcr.microsoft.com/powershell:lts-ubuntu-22.04`).
- **FR-002**: The harness MUST download and install the previous stable version (`0.27.6`) in a clean environment as the baseline.
- **FR-003**: The harness MUST verify that **every** item listed in the packaged candidate's `Specrew.psd1` `FileList` successfully unpacked on disk.
- **FR-004**: The harness MUST run `specrew update` and verify that the local project structure is updated cleanly, and mirror parity checks return `PASS`.
- **FR-005**: `.github/workflows/publish-module.yml` MUST execute this Docker harness as a blocker before any release is pushed to PSGallery.

#### Iteration 2: Troubleshooting Guide

- **FR-006**: System MUST contain `docs/troubleshooting.md` addressing: PSGallery side-by-side caches, FileList drops, deploy-script exceptions, stale-state recovery, and clean-reinstall flows.
- **FR-007**: `docs/troubleshooting.md` MUST be registered in `Specrew.psd1` `FileList` immediately upon creation.

#### Iteration 3: Persona-Driven Intake

- **FR-008**: `/speckit.specify` MUST support **4 target personas**:
  - **Product Manager**: Focuses on business rules, prioritization, P1/P2 journeys, and MVP milestones.
  - **UX/UI Specialist**: Focuses on interface state, Enter key reloads, accessibility, and micro-animations.
  - **Architect**: Focuses on schemas, data contracts, system integration boundaries, and clean-architecture rules.
  - **AI Researcher / Project Manager**: Focuses on team capacity planning, specialist pairings, safe-parallelism, and agent charters.
- **FR-009**: The system MUST supply a **12-category intake catalog** representing comprehensive software parameters.
- **FR-010**: Intake MUST dynamically branch into **Mode A (Direct Confirmation)**, **Mode B (Targeted Clarify)**, or **Mode C (Full Interview)** based on the completeness of initial input.
- **FR-011**: Intake forms MUST support `"Other"` and `"I don't know, you decide"` options, triggering proactive agent domain research when selected.

---

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001, FR-002, FR-003, FR-004, FR-005, and SC-001.
- **TG-002**: User Story 2 maps to FR-006, FR-007, and SC-002.
- **TG-003**: User Story 3 maps to FR-008, FR-009, FR-010, FR-011, and SC-003.
- **TG-004**: Expected Owner roles: Spec Steward (F-049 specs/clarification), Planner (planning iteration), Implementer (code/docs), and Reviewer (E2E PR audit).
- **TG-005**: Iteration delivery window:
  - **Iteration 001**: FR-001 to FR-005 (Docker harness).
  - **Iteration 002**: FR-006 to FR-007 (Troubleshooting).
  - **Iteration 003**: FR-008 to FR-011 (Persona intake).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of missing FileList or corrupt layouts in packaged candidates are blocked **before** PSGallery upload occurs (0% escaped omissions).
- **SC-002**: `docs/troubleshooting.md` exists, is registered in `Specrew.psd1` `FileList`, and is fully cross-referenced in `README.md`.
- **SC-003**: `/speckit.specify` generates highly contextual specs tailored to one of the 4 personas with less than 2 subsequent clarify questions in 90% of runs.

---

## Assumptions

- **Docker availability**: The CI runners and local developer environments have Docker/Moby engine installed and accessible.
- **PSGallery accessibility**: The Docker environment can reach `https://www.powershellgallery.com` to download previous versions.
- **Main branch branching**: All feature work for F-049 branches from `main` and is merged via merge commits (`--merge`).

---

## Clarifications

### Session 2026-05-27

#### Proposal 134 Scope Incremental Integration Decision

- **Question**: Should we integrate Proposal 134 Pillars 1+3 (version pinning drift detection + per-developer-vs-shared file classification) into F-049 Iteration 1?
- **Decision**: Yes! Since the Docker harness built in Iteration 1 is designed to verify project initialization (`specrew init`) and update (`specrew update`) behaviors, it shares identical surface area with version pin verification. We will add a **"manifest pin drift detection"** assertion inside F-049 Iteration 1's Docker E2E test suite. This will catch mismatches in `specrew_version`, `speckit_version`, and `squad_version` across `.specrew/config.yml` and `Specrew.psd1` for free. Full-scale F-051 features remain deferred, but the drift-checking harness will be built now.

#### Interactive Specify Mode C UX Console Behavior

- **Question**: How should the specify Mode C interactive interview prompt users for choices inside a non-GUI console window?
- **Decision**: Standard Powershell console input (`Read-Host` for text/free-form inputs) and numbered list menus with standard validation for choices. This keeps the interface fully lightweight, highly compatible with cross-platform shells (Linux, Windows, MacOS), and completely deterministic for testing.

#### Docker Harness CI Image Caching

- **Question**: Should the pre-publish Docker E2E test suite pull and compile a customized tag or utilize standard official base images?
- **Decision**: To avoid maintenance drift and maintain speed, the CI harness will pull standard `mcr.microsoft.com/powershell:lts-ubuntu-22.04` and reuse cached layers of previous actions. Testing will install the module candidate directly into this container.

---

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward (Antigravity Coordinator)
- **Iteration Facilitator**: Retro Facilitator (Antigravity Coordinator)
- **Capacity Model**: 28-31 SP total across 3 iterations:
  - **Iteration 001**: 12 SP (Docker pre-publish harness + Prop 134 pin assertion)
  - **Iteration 002**: 5 SP (Troubleshooting guide + cross-references)
  - **Iteration 003**: 11 SP (Persona-driven /speckit.specify intake)
- **Drift Signals**: Detected via the governance validator `validate-governance.ps1` and the newly designed Docker E2E pre-publish harness.
- **Human Oversight Points**:
  - Spec/Clarify boundary check (this step).
  - Pre-implementation iteration planning approval.
  - Review / PR merge approval.
  - Manual test PAS/FAIL validation (Step 11).
