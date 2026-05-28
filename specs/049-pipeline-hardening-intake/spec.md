# Feature Specification: Release Pipeline Hardening + Substantive Intake Slice

**Feature Branch**: `049-pipeline-hardening-intake`  
**Created**: 2026-05-27  
**Status**: Approved  
**Approved By**: User approval on 2026-05-27 authorizing before-plan readiness for Feature 049 / Iteration 003 at committed HEAD `264b40a6`.  
**Input**: F-049 user request: Docker pre-publish version-update validation, durable troubleshooting guide docs, persona-driven `/speckit.specify` intake, approved Proposal 120 five-pillar bypass-detection scope reserved for Iteration 004, and Proposal 141 capability-dial/persona-lens correction reserved for Iteration 005.

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
5. **Given** a project with pre-existing Squad roles in `.squad/team.md` and `.squad/routing.md`, **When** `specrew update` is executed, **Then** no duplicate rows are appended (regression test asserts no duplicates appear).
6. **Given** a user running `specrew update --info`, **When** executed, **Then** it queries the actual PSGallery feed and returns the true latest version instead of a local manifest-mocked UpstreamLatest.

---

### User Story 2 - Troubleshooting Guide and Documentation (Priority: P2)

To empower users to recover gracefully from environment issues, local conflicts, or package managers caching side-by-side installations, we will author a durable, comprehensive troubleshooting document.

**Why this priority**: Ensures supportability. When FileList omissions or side-by-side installations occur, developers need clear, structured recovery sequences instead of flying blind.

**Independent Test**: Readability and cross-reference check in the generated docs. Verification that `docs/troubleshooting.md` is registered in `Specrew.psd1` FileList in the same commit, linked from the primary onboarding docs, and includes the approved Shape-5 lesson.

**Acceptance Scenarios**:

1. **Given** a new developer experiencing a broken or incomplete package install, **When** they inspect the codebase documentation, **Then** they find `docs/troubleshooting.md` detailing standard recovery flows.
2. **Given** `docs/troubleshooting.md` is created, **When** a commit is authored, **Then** it must include the addition of `docs/troubleshooting.md` in `Specrew.psd1`'s `FileList`.
3. **Given** the documentation is updated, **When** a user browses `README.md`, `docs/getting-started.md`, or `docs/user-guide.md`, **Then** clear cross-references point to the new troubleshooting guide.
4. **Given** a user confused between `specrew update` and `Update-Module Specrew`, **When** they consult `docs/troubleshooting.md`, **Then** they find a clear, explicit comparison of their separate scopes (project deployment vs. module upgrade).
5. **Given** a maintainer needs to understand the PlanningPoC Shape-5 failure mode, **When** they consult `docs/troubleshooting.md`, **Then** they find a concrete lesson explaining that accepted review evidence must match committed tree state, not only working-tree state.

---

### User Story 3 - Persona-Driven Substantive Specification Intake with Expertise-Aware Depth and Capability/Confidence Dials (Priority: P3)

To ensure that the initial specify phase (`/speckit.specify`) captures realistic scope, technology constraints, and organizational context—while respecting each user's expertise level—it must utilize an **engine + data architecture** where a discrete intake engine orchestrates question flow, persona application, and auto-decision resolution, while all persona definitions, question banks, depth rules, and auto-decision defaults are persisted as YAML data outside engine code. The intake architecture continues to use 4 internal persona lenses, while the human-facing profile experience presents 4 capability/confidence dials that control question depth without asking the user to identify as an internal job title.

**Why this priority**: Substantially reduces clarify-phase back-and-forth by ensuring that the spec is born stack-aware, persona-aligned, and expertise-adapted. High-expertise users receive nuanced senior-level questions; low-expertise users receive auto-decisions surfaced via transparency (Proposal 053 pattern). All users set their profile once and reuse it across all Specrew projects. The engine + data separation enables future expansion (new personas, categories, domain bundles, stack-specific defaults) as **data-only additions** without code rewrites. Proposal 141 adds a bounded correction so the user profile clearly measures decision capability/confidence, while preserving the internal lens architecture and persisted schema from Iteration 003.

**Persona Lenses**: The system applies **4 sequential lenses** (not user choices) during intake, each covering 12 categories from a different perspective:

- **Lens 1: Product Manager** — Business rules, prioritization, P1/P2 journeys, MVP milestones, Go/No-Go criteria.
- **Lens 2: UX/UI Specialist** — Interface state, Enter key reloads, accessibility, micro-animations, user workflows.
- **Lens 3: Architect** — Schemas, data contracts, system integration boundaries, clean-architecture rules, deployment topology.
- **Lens 4: AI Researcher / Project Manager** — Team capacity planning, specialist pairings, safe-parallelism, agent charters, long-term skill growth.

All 12 categories are covered from all 4 perspectives, but depth and auto-decision behavior adapt to the user's capability/confidence dial for each lens. User-facing profile wording MUST frame the same 4 decision areas as **Product Strategy**, **UX/UI Design**, **Software Architecture**, and **AI Delivery Planning**. These visible labels are display metadata only; they do not rename internal persona IDs or persisted schema keys.

**Per-Lens Mode Branching (Key Clarification)**: Mode A/B/C evaluation is **per-lens**, not global. Each persona lens is independently evaluated against its own expertise dial and that lens's content completeness (percentage of substantive answers across its 12 categories). The intake engine references `.specify/intake/depth-rules.yml` (v1 starter thresholds: dial ≥7 + ≥75% completeness → Mode A; dial 4-6 or 40-74% completeness → Mode B; dial ≤3 or <40% completeness → Mode C) to resolve each lens's mode independently. When lenses conflict on modes, most-conservative-wins (C > B > A) applies—ensuring that low-expertise or incomplete lenses drive the overall intake depth rather than being bypassed. This per-lens approach prevents global mode selection from creating vestigial bypass paths and addresses the asymmetric expertise problem: users may be expert in architecture but novice in UX/UI, and the intake should reflect that nuance.

**Engine + Data Architecture**: The intake system is architecturally partitioned into:

- **Discrete Intake Engine** (`Invoke-SpecifyIntake.ps1`): Handles persona-cycle logic, per-lens depth-rule application, question-bank traversal, auto-decision resolution, and annotation rendering. Thin orchestrators (prompt, agent, workflow) invoke the engine; they do not contain inline persona definitions, category lists, question banks, depth rules, or auto-decision defaults.
- **Intake Catalogs** (YAML data): Persona definitions, category specifications, question banks (per-persona), depth rules, and auto-decision defaults are persisted in `.specify/intake/` as pure data. Adding a persona/category/question/depth-rule refinement/default is achievable as a YAML-only data addition without touching engine scripts, prompts, agents, or workflows.
- **Future Extension Hooks**: Domain bundles (`.specify/intake/domain-bundles/<domain>.yml`) and solution-type bundles (`.specify/intake/solution-type-bundles/<type>.yml`) are reserved for future opt-in loading; v1 ships with empty directories only.
- **Stack-Aware Auto-Decision Defaults**: Engine detects repo stack signals and selects `.specify/intake/auto-decision-defaults/<stack>.yml` (e.g., `dotnet.yml`, `python.yml`, `nodejs.yml`), falling back to `generic.yml`. v1 ships only `generic.yml` plus stack-detection mechanism; stack-specific files land later as data-only additions.

**Capability/Confidence Dials** (4 user-facing decision areas, 1-10 scale, persisted to `~/.specrew/user-profile.yml` using stable schema keys):

- **7-10 (Senior Level)**: System surfaces senior-level nuanced questions requiring deep judgment; minimal auto-decisions.
- **4-6 (Standard Level)**: System surfaces standard questions plus explicit decision-confirmation prompts.
- **1-3 (Learning Level)**: System auto-decides with stack-aware defaults and surfaces decisions via Proposal 053 transparency pattern; no silent defaults.
- **"I'm new, you decide"**: User-facing escape hatch; system auto-decides for all questions in this persona.

**Engine + Data Composition**: The intake engine calls dedicated sub-helpers for persona-catalog loading, category-catalog loading, per-lens depth-rule application, question-bank traversal, auto-decision resolution, and annotation rendering. This design enables the following critical property: **adding a 5th persona or new categories/questions/depth-rules requires only data-YAML additions**, not engine rewrites. User expertise profile location and schema remain identical to the current specification.

**Independent Test**: Execute the new `/speckit.specify` command under various user expertise levels and input states, verifying that (a) capability/confidence dials control question depth per lens, (b) per-lens mode evaluation produces the most-conservative mode as overall intake depth, (c) auto-decisions surface with transparency, (d) user-profile.yml persists across invocations, and (e) correct persona-driven spec layout is generated.

**Acceptance Scenarios**:

1. **Given** a user running `specrew start` for the first time (user-profile.yml absent), **When** the bootstrap completes, **Then** the system prompts for capability/confidence self-rating across the 4 decision areas (**Product Strategy**, **UX/UI Design**, **Software Architecture**, **AI Delivery Planning**) using the existing persisted schema keys, saves the profile, and surfaces a profile summary that distinguishes those capability dials from Specrew's internal persona lenses.
2. **Given** a user with an existing user-profile.yml, **When** they run `specrew start`, **Then** the profile is read without migration and a profile summary (with `/specrew-user-profile edit` or `/specrew-user-profile reset` guidance) is surfaced using the capability-area labels rather than job-title identity wording.
3. **Given** a user initiating `/speckit.specify`, **When** the agent begins intake, **Then** it applies all 4 sequential internal persona lenses to the same input, covering all 12 categories from each perspective, while the user's saved capability/confidence dials determine depth and auto-decision behavior for those lenses.
4. **Given** a chosen capability dial (e.g., Software Architecture: 7), **When** intake questions are presented:
   - **7-10 (Senior)**: Questions focus on nuanced architectural tradeoffs, edge cases, and team-level concerns.
   - **4-6 (Standard)**: Questions include confirmation checkpoints for key decisions.
   - **1-3 (Learning)**: System auto-decides using stack-aware defaults from [[feedback-stack-aware-tool-selection]] and surfaces the decision via Proposal 053 transparency pattern.
5. **Given** any question during intake, **When** the user is unsure, **Then** they can choose `"Other"` or `"I don't know, you decide"` to trigger proactive agent domain research or auto-derivation of stack-aware defaults.
6. **Given** intake mode branching (Mode A/B/C) is evaluated **per-lens**, **When** the system evaluates each persona lens against its own expertise dial and the completeness of that lens's content:
   - **Mode A (Sufficient)**: Lens has high expertise (dial ≥7) AND ≥75% substantive answers across 12 categories → Directly generates lens-tailored spec section with minimal questions.
   - **Mode B (Targeted Clarify)**: Lens has mid-range expertise (dial 4-6) OR has 40-74% substantive answers → Asks 2-3 targeted clarifications respecting expertise thresholds.
   - **Mode C (Full Interview)**: Lens has low expertise (dial ≤3) OR has <40% substantive answers → Launches guided interview for that lens's perspective.
   - **Conflict Resolution**: When lenses conflict on modes, the most-conservative mode wins (C > B > A), ensuring that low-expertise or low-completeness lenses drive the overall intake depth.
7. **Given** low-expertise auto-decisions (dial 1-3), **When** the spec is generated, **Then** each auto-decision is annotated with `[AUTO-DECIDED: <decision>]` so the user sees what the system chose and can escalate to clarification if needed.
8. **Given** a legacy `user-profile.yml` created before the capability-wording correction, **When** it is loaded by `specrew start`, `/specrew-user-profile`, or `/speckit.specify`, **Then** the same persisted keys and internal persona IDs remain valid, the same depth behavior is preserved, and only the visible labels/explanatory text change.

---

### User Story 4 - Governance Bypass Detection Before Closeout (Priority: P4)

To ensure iterations cannot appear complete while bypassing Specrew runtime discipline or citing uncommitted production work as accepted evidence, governance validation must detect the approved five bypass-detection pillars before closeout proceeds.

**Why this priority**: This is the approved final slice of F-049 because the family of bypasses undermines trust in boundary state, audit trails, and — in the Pillar 5 case — can permanently lose delivered code if uncommitted work is mistaken for shipped work.

**Independent Test**: Run governance validation against prepared fixtures covering all five bypass shapes and verify that closeout remains blocked whenever accepted review evidence cites production files that are not present in the cited tree.

**Acceptance Scenarios**:

1. **Given** a boundary or lifecycle stop occurs without a preceding `=== SPECREW HANDOFF ===` block, **When** governance validation runs, **Then** it emits a visible warning identifying the missing handoff evidence.
2. **Given** a closed iteration has the normal closeout artifacts except a trigger-driven artifact such as `dashboard.md`, **When** governance validation runs, **Then** it classifies the gap as a non-Specrew-managed bypass rather than only a generic missing-artifact warning.
3. **Given** canonical feature artifacts are written into an ephemeral host session-scratch location instead of the feature directory, **When** governance validation runs, **Then** it warns that the artifact is in the wrong location and points maintainers back to the canonical specs path.
4. **Given** a human-judgment boundary advances in recorded state without matching human verdict history, **When** governance validation or boundary sync evaluates the transition, **Then** the unauthorized advance is surfaced and the state change is not allowed to stand silently.
5. **Given** an accepted `review.md` cites production files as evidence for a specific Tree Under Review, **When** those files are absent from the cited tree, **Then** validation fails loudly enough to stop iteration closeout until the work is committed or the evidence is corrected.

---

## Edge Cases

- **Docker Harness Timeout/Network Latency**: The pre-publish harness might hit a network timeout pulling the previous version from PSGallery. The test must gracefully retry or cache baseline layouts.
- **PSGallery Side-by-Side Cache Invalidation**: Package managers might return cached, stale layout versions during local `Save-Module` updates. The troubleshooting guide must outline how to force-clean the NuGet cache.
- **Aborted Intake Mode**: If a user aborts during a Mode C interactive interview, the system must retain partial progress in `.specify/feature.json` so it can be resumed.
- **Legacy Capability Label Compatibility**: Existing `user-profile.yml` files created before Iteration 005 may still contain the stable `expertise.ai_research_project_management` key. The system must load them without migration, preserve the same internal lens routing, and display the updated **AI Delivery Planning** label in user-facing summaries.
- **Legacy Governance History**: Older iterations may predate newer handoff or verdict-history rules. Bypass-detection coverage must distinguish legacy history from newly governed closeouts so maintainers can act on present-day signals without rewriting old records.
- **Review Evidence Scope Mismatch**: Review evidence may cite both production files and test files. The closeout gate must treat missing production-file evidence as a blocking integrity failure while allowing lower-severity treatment for test-only mismatches.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Iteration 1: Docker Pre-Publish Verification

- **FR-001**: System MUST supply a Docker-based test runner using a Linux-based PowerShell container (`mcr.microsoft.com/powershell:lts-ubuntu-22.04`).
- **FR-002**: The harness MUST download and install the previous stable version (`0.27.6`) in a clean environment as the baseline.
- **FR-003**: The harness MUST verify that **every** item listed in the packaged candidate's `Specrew.psd1` `FileList` successfully unpacked on disk.
- **FR-004**: The harness MUST run `specrew update` and verify that the local project structure is updated cleanly, and mirror parity checks return `PASS`.
- **FR-005**: `.github/workflows/publish-module.yml` MUST execute this Docker harness as a blocker before any release is pushed to PSGallery.
- **FR-012**: The pre-publish verification suite MUST detect manifest version-pin drift before publication proceeds, so module and runtime version declarations cannot silently diverge.
- **FR-013**: The system MUST prevent `specrew update` from duplicating Squad team/routing entries. The template merge logic inside `scripts/specrew-update.ps1` / `deploy-squad-runtime.ps1` MUST perform a clean merge instead of appending duplicate role rows.
- **FR-014**: `specrew update --info` MUST default to checking and showing the actual latest version published on **PSGallery**, rather than using a hardcoded or misleading `UpstreamLatest` from local manifests (promotes Proposal 049).

#### Iteration 2: Troubleshooting Guide

- **FR-006**: System MUST contain `docs/troubleshooting.md` addressing: PSGallery side-by-side caches, FileList drops, deploy-script exceptions, stale-state recovery, and clean-reinstall flows.
- **FR-007**: `docs/troubleshooting.md` MUST be registered in `Specrew.psd1` `FileList` immediately upon creation.
- **FR-015**: `docs/troubleshooting.md` MUST explicitly document the naming distinction and functional boundary between `specrew update` (project environment deployment) and `Update-Module Specrew` (module software upgrade).
- **FR-016**: `README.md`, `docs/getting-started.md`, and `docs/user-guide.md` MUST cross-reference `docs/troubleshooting.md` so recovery guidance is discoverable from the primary onboarding and usage paths.
- **FR-017**: `docs/troubleshooting.md` MUST capture the Shape-5 lesson that accepted review evidence must match committed tree state, so maintainers understand why working-tree-only files are not durable delivery.

#### Iteration 3: Persona-Driven Intake with Expertise Dials, User Profile Persistence, and Engine + Data Architecture

- **FR-008**: `/speckit.specify` MUST apply **4 sequential persona lenses** (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager) to every intake, covering all 12 categories from each perspective. Personas are internal lenses, not user choices; the single user receives all 4 perspectives even when profile prompts use different user-facing capability/confidence labels.
- **FR-009**: The system MUST supply a **12-category intake catalog** representing comprehensive software parameters, evaluated from each of the 4 persona perspectives.
- **FR-010**: Intake MUST evaluate mode branching **per-lens**: each persona lens is independently assessed against its own expertise dial and lens-completeness percentage (substantive answers across the lens's 12 categories). Based on the thresholds defined in `.specify/intake/depth-rules.yml` (v1 starter: Mode A ≥7 dial + ≥75% completeness; Mode B 4-6 dial or 40-74% completeness; Mode C ≤3 dial or <40% completeness), each lens resolves to its own Mode A/B/C. When lenses conflict, most-conservative-wins (C > B > A) applies to ensure low-expertise or sparse-content lenses drive overall intake depth. Final spec composition respects the most-conservative mode across all 4 lenses.
- **FR-011**: Intake forms MUST support `"Other"` and `"I don't know, you decide"` options, triggering proactive agent domain research or stack-aware auto-derivation when selected.
- **FR-023**: `/speckit.specify` MUST prompt the user to self-rate their expertise on a 1-10 scale for each of the 4 user-facing capability areas (**Software Architecture**, **UX/UI Design**, **Product Strategy**, **AI Delivery Planning**), with an escape hatch option `"I'm new, you decide"` per area.
- **FR-024**: System MUST persist user expertise profile in a YAML file (`user-profile.yml`) at:
  - Windows: `$env:USERPROFILE\.specrew\user-profile.yml`
  - Mac/Linux: `~/.specrew/user-profile.yml`
  
  Schema fields: `schema`, `specrew_version_at_creation`, `created_at`, `last_updated_at`, `user_name` (optional), `expertise.software_architecture` (1-10 or null), `expertise.ui_ux` (1-10 or null), `expertise.product_management` (1-10 or null), `expertise.ai_research_project_management` (1-10 or null), `preferences.preferred_intake_depth` (auto|always-full|always-minimal).
- **FR-025**: System MUST deploy `/specrew-user-profile` slash command with subcommands: `show` (display current profile), `edit` (interactive update), `reset` (clear and restart). Command MUST be deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` using the existing F-021 slash-command machinery.
- **FR-026**: `specrew start` MUST detect first-run (user-profile.yml absent), prompt for capability/confidence self-rating before bootstrap completes, save the profile, and surface a profile summary in `start-context.json` and `start-summary.md`. On subsequent runs, `specrew start` MUST read the profile and surface the profile summary plus reset/edit guidance.
- **FR-027**: `/speckit.specify` MUST consume the persisted `user-profile.yml` and apply capability/expertise-level-driven question depth rules:
  - **7-10 (Senior)**: Surface senior-level nuanced questions requiring deep judgment; minimal auto-decisions.
  - **4-6 (Standard)**: Surface standard questions plus explicit decision-confirmation prompts.
  - **1-3 (Learning)**: Auto-decide using stack-aware defaults from [[feedback-stack-aware-tool-selection]]; surface each decision via Proposal 053 transparency pattern with `[AUTO-DECIDED: <decision>]` annotations in the generated spec.

The `specrew start` first-run capability/confidence intake and the `/specrew-user-profile` command enable durable user profiling across all Specrew projects (user-level, not project-level). `/speckit.specify` consumes this profile to personalize question depth and auto-decision behavior per persona lens.

**Engine + Data Architecture (Iteration 003 Architectural Foundation)**:

- **FR-028**: System MUST implement a discrete intake engine (`Invoke-SpecifyIntake.ps1`) in `extensions/specrew-speckit/scripts/intake/`, with a mirror copy in `.specify/extensions/specrew-speckit/scripts/intake/`. The engine MUST provide sub-helpers for:
  - Persona-catalog loading (from `personas.yml`)
  - Category-catalog loading (from `categories.yml`)
  - Per-lens depth-rule application (from `depth-rules.yml`): evaluate each persona lens independently against its expertise dial and lens-completeness, resolve each lens to Mode A/B/C, apply most-conservative-wins conflict resolution
  - Question-bank traversal (from `questions/<persona>.yml`)
  - Auto-decision resolution (from `auto-decision-defaults/<stack>.yml`)
  - Annotation rendering (for `[AUTO-DECIDED: ...]` and other metadata)
  
  The engine MUST be the sole location where persona logic, category definitions, question flow, per-lens mode evaluation, and auto-decision rules are evaluated. Prompts, agents, and workflows MUST be thin orchestrators that call the engine; they MUST NOT contain inline persona definitions, category lists, question banks, depth rules, or auto-decision defaults.

- **FR-029**: System MUST provide intake catalogs as YAML data in `.specify/intake/`:
  - `personas.yml` — Persona definitions (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager)
  - `categories.yml` — Category specifications (12 categories)
  - `depth-rules.yml` — Per-lens mode evaluation thresholds (v1 starter: Mode A dial ≥7 + ≥75% completeness; Mode B dial 4-6 or 40-74% completeness; Mode C dial ≤3 or <40% completeness; most-conservative-wins conflict resolution). This file is the authoritative source for tunable mode thresholds; refinements require no engine changes.
  - `questions/<persona>.yml` — Question banks per persona (one file per persona; v1 ships with 3 questions/persona minimum)
  - `auto-decision-defaults/generic.yml` — Stack-agnostic auto-decision defaults (v1 default fallback)
  
  Adding a persona, category, question, depth-rule refinement, or auto-decision default MUST be achievable as a pure YAML-only data addition, without requiring changes to engine scripts, prompts, agents, workflows, or version manifests.

- **FR-030**: System MUST reserve future extension hooks via opt-in domain bundles (`.specify/intake/domain-bundles/<domain>.yml`) and solution-type bundles (`.specify/intake/solution-type-bundles/<type>.yml`). These directories MUST exist in v1 but remain empty. The intake engine MUST skip loading them until explicitly enabled by a later feature iteration. v1 ships with zero domain bundles and zero solution-type bundles; future feature work adds data only without engine changes.

- **FR-031**: Auto-decision default resolution MUST be stack-aware: the intake engine MUST detect repo stack signals (e.g., `.csproj` files for dotnet, `pyproject.toml` for python, `package.json` for nodejs) and select `.specify/intake/auto-decision-defaults/<stack>.yml` based on detected signals, falling back to `generic.yml`. v1 ships with only `generic.yml` plus stack-detection mechanism. Stack-specific defaults (e.g., `dotnet.yml`, `python.yml`, `nodejs.yml`) MUST be added later as data-only additions without engine rewrites.

#### Iteration 4: Five-Pillar Bypass Detection

- **FR-018**: Governance validation MUST detect missing `=== SPECREW HANDOFF ===` evidence at boundary or lifecycle stops and surface the gap as an explicit handoff warning.
- **FR-019**: Governance validation MUST distinguish trigger-bypass artifact gaps from generic missing-artifact failures when an iteration otherwise appears fully closed.
- **FR-020**: Governance validation MUST detect canonical Specrew artifacts written into ephemeral host session-scratch locations and warn that they are outside the canonical feature path.
- **FR-021**: Governance validation and boundary enforcement MUST detect state advances across human-judgment boundaries that lack matching human verdict history, preventing silent state progression from being treated as valid.
- **FR-022**: Governance validation MUST compare accepted review evidence against the cited Tree Under Review and block iteration closeout if production files cited as delivered evidence are absent from that tree; test-only evidence mismatches may remain warning-level findings.

#### Iteration 5: Capability Dial / Persona Lens Separation Correction

- **FR-032**: `specrew start`, `/specrew-user-profile`, `/speckit.specify`, and any first-run/profile summaries MUST describe the 4 user inputs as capability/confidence dials for the decision areas **Product Strategy**, **UX/UI Design**, **Software Architecture**, and **AI Delivery Planning**, not as job titles or identity claims the user must personally hold.
- **FR-033**: The correction slice MUST preserve all persisted schema keys and internal persona lens IDs, including `expertise.product_management`, `expertise.ui_ux`, `expertise.software_architecture`, `expertise.ai_research_project_management`, and the internal persona ID `ai-researcher-project-manager`. No key migration, ID rename, or schema rewrite is allowed in this slice.
- **FR-034**: The fourth visible capability dial MUST be labeled **AI Delivery Planning** everywhere the profile is presented to the user. This visible label MUST map to the existing fourth internal lens (`AI Researcher / Project Manager`) and continue to cover capacity planning, safe parallelism, specialist pairing, agent charters, delivery risk, and AI-agent workflow design.
- **FR-035**: Profile summaries, intake guidance, and related help text MUST explicitly distinguish **your capability/confidence dials** from **Specrew's internal persona lenses**. The copy MUST explain that dials control question depth and auto-decision behavior, do not create user-selected personas, and do not split the internal four-lens architecture.
- **FR-036**: Documentation, slash-command skills, and reviewer/operator guidance for substantive intake MUST explain the dial semantics consistently: all four visible labels are capability areas, personas remain internal intake/review lenses, Proposal 120 remains Iteration 004, and display-label handling is a user-facing layer over unchanged internal IDs and persisted keys.
- **FR-037**: Tests and scripted evidence MUST prove compatibility for pre-existing `user-profile.yml` files by showing that legacy profiles load without migration, preserve the same internal lens routing and question-depth behavior, and surface the updated capability-area wording in user-facing output.

---

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001, FR-002, FR-003, FR-004, FR-005, FR-012, FR-013, FR-014, and SC-001.
- **TG-002**: User Story 2 maps to FR-006, FR-007, FR-015, FR-016, FR-017, and SC-002.
- **TG-003**: User Story 3 maps to FR-008, FR-009, FR-010, FR-011, FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033, FR-034, FR-035, FR-036, FR-037, SC-003, SC-005, SC-006, and SC-007.
- **TG-004**: User Story 4 maps to FR-018, FR-019, FR-020, FR-021, FR-022, and SC-004.
- **TG-005**: Expected Owner roles: Spec Steward (F-049 specs/clarification), Planner (planning iteration), Implementer (code/docs), and Reviewer (E2E PR audit).
- **TG-006**: F-049 is an approved **five-iteration** feature. Iterations 001-003 are closed; Iteration 004 remains the reserved Proposal 120 bypass-detection slice; Iteration 005 is the approved Proposal 141 capability-dial/persona-lens correction slice.
- **TG-007**: Iteration delivery window:
  - **Iteration 001 (closed)**: FR-001 to FR-005, FR-012, FR-013, FR-014 (Docker harness + release hardening regressions).
  - **Iteration 002 (closed)**: FR-006, FR-007, FR-015, FR-016, FR-017 (Troubleshooting, cross-references, and Shape-5 lesson).
  - **Iteration 003 (closed)**: FR-008 to FR-011, FR-023 to FR-031 (Persona-driven specify intake with expertise dials, user profile persistence, slash command, and **engine + data architecture foundation**).
  - **Iteration 004**: FR-018 to FR-022 (Proposal 120 full five-pillar bypass detection).
  - **Iteration 005**: FR-032 to FR-037 (Proposal 141 capability-dial/persona-lens separation correction without schema or lens-architecture changes).
- **TG-008**: Iteration 004 scope is anchored to Proposal 120 at main commit `4da969bc`; planning/tasking for this feature MUST preserve all five pillars, including Pillar 5 working-tree-only-state detection.
- **TG-009**: FR-023 (capability/confidence self-rating) is the intake foundation; FR-024 (user-profile.yml) enables persistence; FR-025 (`/specrew-user-profile`) enables user control.
- **TG-010**: FR-026 (specrew start first-run integration) surfaces capability/confidence intake at bootstrap time; FR-027 (`/speckit.specify` profile consumption) applies the profile to question depth and auto-decision behavior.
- **TG-011**: Capability/expertise semantics follow the 7-10 / 4-6 / 1-3 / "I'm new" rules; low-expertise auto-decisions MUST be surfaced via Proposal 053 transparency pattern, never silent.
- **TG-012**: User-profile.yml is user-level (persisted across all Specrew projects), NOT project-level; it is the user-level analogue to Proposal 047 project-governance profile.
- **TG-013**: **Architectural Foundation (Iteration 003)**: FR-028 is the engine foundation; FR-029 is the data layer; FR-030 and FR-031 are v1-supported-but-data-empty extensions enabling future growth without engine changes. This modular design is a **critical architectural pivot** required after rejection: the system MUST architect for data-driven extensibility from the outset, not retrofit it later.
- **TG-014**: **Mirror Parity Requirement**: Engine scripts MUST maintain mirror parity between `extensions/specrew-speckit/scripts/intake/*` (shipped in module) and `.specify/extensions/specrew-speckit/scripts/intake/*` (project-local override path). Both paths must be kept synchronized; any engine enhancement MUST update both mirrors simultaneously.
- **TG-015**: **Minimal Question Banks for Capacity**: v1 question banks are intentionally minimal (3 questions per persona) for capacity reasons within the 21-25 SP Iteration 003 soft cap. Future growth (additional personas, expanded question banks, domain bundles, solution-type bundles) MUST land as data-only additions without engine changes. This constraint ensures that capacity is invested in architectural foundation (FR-028 engine) and base data structure (FR-029 catalogs) rather than question volume.
- **TG-016**: Proposal 120 remains fully anchored to **Iteration 004**. Adding Iteration 005 MUST NOT reduce, reinterpret, or defer any of FR-018, FR-019, FR-020, FR-021, FR-022, SC-004, or TG-008.
- **TG-017**: Proposal 141 is a bounded **Iteration 005 follow-on correction slice**, not a reopening of Iteration 003. Iteration 005 updates user-facing wording, guidance, and compatibility evidence only; it does not split persona architecture, add a fifth lens, or migrate persisted profile data.
- **TG-018**: Display-label handling for Iteration 005 is fixed as follows: user-facing capability labels are **Product Strategy**, **UX/UI Design**, **Software Architecture**, and **AI Delivery Planning**; internal lens execution remains **Product Manager**, **UX/UI Specialist**, **Architect**, and **AI Researcher / Project Manager**; persisted keys and persona IDs remain unchanged.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of missing FileList or corrupt layouts in packaged candidates are blocked **before** PSGallery upload occurs (0% escaped omissions).
- **SC-002**: `docs/troubleshooting.md` exists, is registered in `Specrew.psd1` `FileList`, is cross-referenced from `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`, and explains both the `specrew update` vs. `Update-Module Specrew` distinction and the Shape-5 durability lesson.
- **SC-003**: `/speckit.specify` with capability/confidence dials generates highly contextual specs tailored to the 4 internal persona lenses, respecting user expertise levels (senior, standard, learning), with less than 2 subsequent clarify questions in 90% of runs when the relevant dial is 4+.
- **SC-004**: All five approved bypass-detection pillars surface during governance validation, and 0 accepted iteration closeouts may rely on production evidence files that are absent from the cited committed tree.
- **SC-005**: Expertise dials and user-profile.yml persistence deliver empirical evidence of question reduction and per-lens mode branching effectiveness:
  - **≥30% reduction** in intake question count for high-expertise users (dial 7-10) in relevant persona lens vs. Mode C baseline (full interview depth).
  - **≥40% reduction** in user-faced decision count for low-expertise users (dial 1-3) in relevant persona lens via auto-decide + transparency pattern.
  - **No regression** in first-iteration spec quality: measured by clarify-question count in `/speckit.clarify` or per-lens specify-mode-A rate remaining ≥70% across all expertise levels (i.e., at least 70% of lenses resolve to Mode A even when overall conflict resolution selects Mode B or C).
- **SC-006**: **Engine + Data Extensibility Proof**: Adding a 5th persona (beyond the initial 4) MUST be demonstrably achievable by:
  - Adding one row to `.specify/intake/personas.yml` (persona name, description, key focus areas)
  - Creating one new file `.specify/intake/questions/<new-persona>.yml` (3 questions minimum, following existing question schema)
  - Running `/speckit.specify` and verifying that the new persona lens is applied and questions are surfaced
  - **Zero modifications** to engine scripts, prompts, agents, workflows, or version manifests

  This MUST be proven empirically with a test fixture in the test suite (e.g., a temporary 5th persona added, intake executed, then removed). The test fixture MUST verify that the persona is recognized, questions are loaded, and expertise-dial behavior adapts correctly—all without touching non-YAML code.
- **SC-007**: Proposal 141 correction success is achieved when **100%** of audited first-run/profile/help surfaces use the capability-area labels (**Product Strategy**, **UX/UI Design**, **Software Architecture**, **AI Delivery Planning**) instead of job-title identity wording, and **100%** of legacy `user-profile.yml` compatibility fixtures load without key migration while preserving the same internal lens routing and question-depth behavior as before the wording correction.

---

## Assumptions

- **Docker availability**: The CI runners and local developer environments have Docker/Moby engine installed and accessible.
- **PSGallery accessibility**: The Docker environment can reach `https://www.powershellgallery.com` to download previous versions.
- **Main branch branching**: All feature work for F-049 branches from `main` and is merged via merge commits (`--merge`).
- **Repository history availability**: Governance validation can inspect committed tree metadata and review artifacts for the active feature when evaluating closeout evidence.

---

## Out of Scope *(F-049 explicitly excludes)*

- **Implicit expertise detection** from answer quality or interaction patterns (remains Proposal 015 future scope).
- **Cross-persona expertise inference** (e.g., deriving Product Management dial from Architect dial).
- **5th or later personas** as fully integrated features for v1 (e.g., Data Engineer, DevOps/SRE, Security Engineer, Domain Expert personas remain listed as future expansion candidates but are out of scope for this feature). **Important**: Adding new personas post-v1 MUST occur as data-only YAML additions to `personas.yml` and `questions/<persona>.yml` without engine rewrites. SC-006 proves this extensibility empirically.
- **Project-level expertise overrides** (Iteration 003 implements user-level only; project-level overrides remain future scope).
- **Multi-user shared profile** (user-profile.yml is single-user only; shared team profiles remain future scope).
- **Extra `/speckit.specify` triggers** beyond the existing single-invocation intake scope (e.g., mid-spec re-interview remains out of scope).
- **Domain bundles and solution-type bundles** beyond empty-directory reservations (v1 ships with `.specify/intake/domain-bundles/` and `.specify/intake/solution-type-bundles/` directories reserved but empty; opt-in loading and domain-specific data additions land in future feature iterations as data-only additions).
- **Stack-specific auto-decision defaults** beyond `generic.yml` (v1 ships with stack-detection mechanism and `generic.yml` fallback only; stack-specific defaults like `dotnet.yml`, `python.yml`, `nodejs.yml` land later as data-only additions without engine changes).

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

### Session 2026-05-27 (Post-Restart Alignment)

#### duplicate-row deploy bug (Bug 1)

- **Question**: How do we verify and prevent duplication of squad team and routing rows?
- **Decision**: Fix Squad-template merge logic in `scripts/specrew-update.ps1` and `deploy-squad-runtime.ps1`. Implement a dedicated integration test that attempts a redundant update and asserts no duplicates are added to `.squad/team.md` or `.squad/routing.md`.

#### specrew update --info version-check (Bug 2)

- **Question**: How do we unify the version check source for `--info`?
- **Decision**: Unify version check logic around the PSGallery API. Promoted Proposal 049 (Version-Check Source Unification) to draft. `--info` will fetch the actual latest version from PSGallery as the default.

#### specrew update vs Update-Module Specrew (Bug 3)

- **Question**: How do we resolve user naming confusion?
- **Decision**: Add an explicit troubleshooting section in `docs/troubleshooting.md` outlining the difference in scope and execution between the two.

### Session 2026-05-27 (Iteration Expansion Approval)

#### Feature roadmap truth

- **Question**: How should F-049 reflect the human-approved post-Iteration-001 roadmap?
- **Decision**: Treat F-049 as a **five-iteration** feature. Preserve Iterations 001-003 as closed, keep Iteration 004 reserved for Proposal 120's full five-pillar bypass-detection scope, and add Iteration 005 for Proposal 141's bounded capability-dial/persona-lens correction.

#### Proposal 120 scope anchor

- **Question**: Which Proposal 120 scope is in-bounds for Iteration 004?
- **Decision**: Use Proposal 120 at main commit `4da969bc`, including all five pillars and especially Pillar 5 reviewer-working-tree-only-state detection that blocks closeout when cited production evidence is not present in the committed tree.

### Session 2026-05-28 (Expertise Dial Design - Human-Approved Iteration 003 Refresh)

#### Persona Lenses: Sequential vs. User Choice

- **Question**: Should users choose one persona or receive all 4 persona perspectives?
- **Decision (Human-Approved)**: **Option B with light Option C overlay**: The 4 personas are **sequential lenses**, not user choices. The system applies all 4 perspectives to every intake, ensuring comprehensive 12-category coverage from each lens. The user is single; they receive all lenses. This preserves the originally approved "substantive" intent while adding expertise-aware depth adaptation.

#### Per-Persona Expertise Dials

- **Question**: How should expertise be represented and used?
- **Decision (Human-Approved)**: Implement per-persona expertise dials (1-10 scale) for the 4 personas, persisted to a user-level `~/.specrew/user-profile.yml` file. Expertise levels drive question depth and auto-decision behavior:
  - **7-10 (Senior)**: Senior-level nuanced questions, minimal auto-decisions.
  - **4-6 (Standard)**: Standard questions + confirmation checkpoints.
  - **1-3 (Learning)**: Auto-decide with stack-aware defaults + Proposal 053 transparency (never silent).
  - **"I'm new, you decide"**: Escape hatch; auto-decide for all questions in this persona.

#### User-Level Expertise Profile Persistence

- **Question**: Where and how should expertise dial state be saved?
- **Decision (Human-Approved)**: Implement a one-time user-level expertise profile file:
  - **Location**: `$env:USERPROFILE\.specrew\user-profile.yml` (Windows), `~/.specrew/user-profile.yml` (Mac/Linux).
  - **Scope**: User-level (persists across all Specrew projects), not project-level.
  - **Schema**: `schema`, `specrew_version_at_creation`, `created_at`, `last_updated_at`, `user_name` (optional), `expertise.*` (4 dimensions), `preferences.preferred_intake_depth`.
  - **Reuse**: First `specrew start` run when user-profile.yml is absent prompts for expertise self-rating, saves the profile, and surfaces summary. Subsequent runs read and surface the profile.

#### `/specrew-user-profile` Slash Command

- **Question**: How should users manage their expertise profile?
- **Decision (Human-Approved)**: Implement `/specrew-user-profile` slash command with subcommands: `show` (display current profile), `edit` (interactive update), `reset` (clear and restart). Deploy via F-021 slash-command machinery to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`.

#### Integration with `/speckit.specify`

- **Question**: How should `/speckit.specify` consume the user expertise profile?
- **Decision (Human-Approved)**: `/speckit.specify` reads `user-profile.yml` and applies expertise-level-driven question depth per persona. Low-expertise auto-decisions are surfaced via Proposal 053 transparency pattern with `[AUTO-DECIDED: <decision>]` annotations; no silent defaults. Defaults use [[feedback-stack-aware-tool-selection]] for stack-aware choices.

#### Iteration 003 Scope Boundary

- **Question**: How much should Iteration 003 absorb from Proposal 015 (Implicit Expertise Detection)?
- **Decision (Human-Approved)**: Iteration 003 **partially absorbs** Proposal 015 explicit-dial + user-level persistence **only**. Full Proposal 015 implicit expertise detection (inferring expertise from answer quality) remains future work and is excluded. Lane independence preserved: Iteration 004 FR-018..FR-022 remain unchanged.

### Session 2026-05-28 (Proposal 141 Correction Slice Alignment)

#### User-facing capability labels

- **Question**: Should the other three user-facing labels also be framed as capability areas rather than persona/job-title identities?
- **Decision (Authoritative)**: Yes. All four user-facing profile dials are capability/confidence areas: **Product Strategy**, **UX/UI Design**, **Software Architecture**, and **AI Delivery Planning**.

#### Persisted schema and internal IDs

- **Question**: Should Proposal 141 rename keys or internal IDs to match the new user-facing labels?
- **Decision (Authoritative)**: No. Persisted `user-profile.yml` keys and internal persona IDs remain unchanged, including `expertise.ai_research_project_management` and `ai-researcher-project-manager`. Proposal 141 is display-language correction only.

#### Persona architecture boundary

- **Question**: Should Proposal 141 split `AI Researcher / Project Manager` into separate internal personas or otherwise reopen Iteration 003 architecture?
- **Decision (Authoritative)**: No. The four-lens architecture stays intact. Iteration 005 is a follow-on wording/guidance/evidence slice and does not reopen Iteration 003 or alter Iteration 004.

#### Display-label handling

- **Question**: How should the spec constrain the display-label implementation without forcing a schema migration?
- **Decision (Authoritative)**: The spec fixes the external contract rather than a storage redesign: every user-facing profile surface must render the four capability labels above, those labels must map deterministically to the existing persisted keys and internal lenses, and planning/implementation must preserve this mapping without changing schema keys or persona IDs.

---

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward (Antigravity Coordinator)
- **Iteration Facilitator**: Retro Facilitator (Antigravity Coordinator)
- **Capacity Model**: 51-63 SP total across 5 iterations (Iteration 005 adds a bounded 3-5 SP correction slice on top of the approved Iteration 004 reservation):
  - **Iteration 001 (closed)**: 17 SP actual (Docker harness 12 SP + Prop 134 pin assertion + duplicate-row fix + Proposal 049 PSGallery info check 5 SP)
  - **Iteration 002 (closed)**: 4-6 SP (Troubleshooting guide + README/getting-started/user-guide cross-references + `specrew update` vs `Update-Module` confusion section + Shape-5 lesson)
  - **Iteration 003 (closed)**: 21-25 SP medium-large slice (Persona lenses + expertise/capability dials [FR-008-FR-011] + user-profile.yml persistence [FR-024] + `/specrew-user-profile` slash command [FR-025] + `specrew start` first-run integration [FR-026] + `/speckit.specify` profile consumption [FR-027] + capability/confidence self-rating intake [FR-023] + **discrete intake engine [FR-028] + intake catalogs [FR-029] + extension hooks [FR-030] + stack-aware defaults [FR-031]**). The architectural pivot from inline logic to engine + data architecture adds 4-5 SP to build modular foundation, justified by enabling future 5th+ personas and domain bundles as data-only additions.
  - **Iteration 004**: 6-10 SP (Proposal 120 full five-pillar bypass detection, including Pillar 5 working-tree-only-state detection)
  - **Iteration 005**: 3-5 SP (Proposal 141 capability/confidence wording correction, stable-key compatibility proof, docs/skills/reviewer guidance refresh)
  - **Remaining Capacity**: Reduced by 3-5 SP versus the prior four-iteration model because Iteration 005 is an approved follow-on correction slice.
- **Roadmap Truth**: Iterations 001-003 are complete; Iteration 004 remains the reserved Proposal 120 slice; Iteration 005 is the approved Proposal 141 correction lane.
- **Drift Signals**: Detected via the governance validator `validate-governance.ps1`, the Docker E2E pre-publish harness, and Iteration 004 bypass-detection rules that cross-check closeout evidence against canonical repository state.
- **Composition Notes** (post-Iteration 003 scope anchored here; remain future work):
  - Iteration 003 **partially absorbs** Proposal 015 explicit-dial + user-level persistence only; full Proposal 015 implicit expertise detection (from answer quality) remains future work and is excluded from this feature.
  - Low-expertise auto-decisions **MUST** surface via Proposal 053 transparency pattern; no silent defaults.
  - Low-expertise defaults **MUST** use [[feedback-stack-aware-tool-selection]] to derive stack-aware choices.
  - **Engine + Data Separation** is the new required architectural foundation: Future 5th+ personas, additional categories, domain bundles, solution-type bundles, and stack-specific defaults MUST land as YAML-only data additions (files in `.specify/intake/`) rather than engine rewrites. This design decision is baked into FR-028, FR-029, FR-030, FR-031, and verified empirically in SC-006.
  - `user-profile.yml` is the user-level analogue to Proposal 047 project-governance profile; user-level persistence enables reuse across all Specrew projects.
  - `/specrew-user-profile` command **MUST** use F-021 slash-command machinery for deployment to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`.
- **Human Oversight Points**:
  - Spec/Clarify boundary check (this step).
  - Pre-implementation iteration planning approval.
  - Review / PR merge approval.
  - Manual test PASS/FAIL validation (Step 11).
  - Explicit review of any Pillar 5 closeout failure before iteration-closeout is re-attempted.
