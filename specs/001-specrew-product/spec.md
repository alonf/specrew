# Feature Specification: Specrew — Spec-Governed AI Crew Operating Model

**Feature Branch**: `001-specrew-product`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Build a project called Specrew — a spec-governed operating model for AI crews combining Spec Kit as the specification/governance layer with Squad as the persistent multi-agent runtime layer."

## Problem Statement

AI agent teams today suffer from a governance gap. Tools like Squad provide multi-agent orchestration — routing work, spawning specialists, managing memory — but they have no built-in concept of a specification as the authoritative source of truth. Tools like Spec Kit provide structured specification authoring and governance workflows, but they have no way to drive a persistent agent crew from the artifacts they produce.

The result is that:

- Agent teams drift from what was specified, making undocumented decisions that silently replace the intended design.
- There is no reliable way to plan iterations, measure effort, or run structured delivery cycles with AI crews.
- Human stakeholders lose visibility into whether the crew is building what was agreed upon.
- There is no standard way to evaluate whether an AI crew's process and output actually conform to a specification.

No existing product bridges these two layers. Users are forced to manually translate between spec artifacts and agent instructions, losing traceability and governance along the way.

## Product Vision

Specrew lets users run an AI crew from the spec. It connects Spec Kit (the specification and governance layer) with Squad (the persistent multi-agent runtime layer) so that a single source of truth — the spec — governs what the crew builds, how it plans, how it executes, and how it is evaluated.

Specrew is built as a Spec Kit extension plus Squad-native configuration surfaces. The Spec Kit extension (`specrew-speckit`) governs spec lifecycle, governance artifacts, and drift detection. Squad integration uses Squad's native runtime surfaces: skills deployed to `.copilot/skills/specrew-*/`, ceremonies and directives registered in `.squad/` config files, and team roles merged into `.squad/team.md`. In v1, all Squad integration is Markdown-based (skills, ceremony definitions, directive references); SDK-defined team configuration (`squad.config.ts`) is deferred to post-MVP. Together they create a structured operating model where every iteration is planned from the spec, every task is traceable to a requirement, and every review checks alignment between implementation and intent.

Specrew currently targets GitHub Copilot because Squad currently supports that path, but it is architected for future compatibility if Squad later supports other coding-agent runtimes.

## Clarifications

### Session 2026-04-17

- Q: Should drift detection be active (per-task hook), passive (review gate only), or hybrid? → A: Active — Spec Steward checks alignment after each task completes via a Squad post-task hook.
- Q: How should iteration artifacts (plans, drift logs, retros, evaluation reports) be stored? → A: Markdown files in the spec feature directory (e.g., `specs/001-feature/iterations/001/plan.md`).
- Q: How should mid-iteration failures (crew crash, task failure) be handled? → A: Resumable — persist task state to disk after each task; provide a resume command that picks up from the last completed task.
- Q: What is the default crew composition at bootstrap? → A: Five predefined roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) as the baseline. Each downstream project can add domain-specific team members via Squad configuration based on the target project and its domain.
- Q: Should Specrew own dependency setup, and how should it handle brownfield projects? → A: Yes. Specrew owns dependency setup via `specrew init`. It pins to Spec Kit >= 0.7.3 and Squad >= 0.9.1. On greenfield it installs both. On brownfield it detects existing installations, validates version compatibility, and either proceeds (compatible) or reports a clear upgrade path (incompatible). Existing specs, governance, and team config are preserved — Specrew merges its baseline roles rather than overwriting.
- Q: How is the Specrew project itself managed during its own development? → A: The Specrew product is developed in a private GitHub repository and managed using GitHub Projects V2. This is a Specrew project-development choice only. Downstream projects created with Specrew are not required to use GitHub Projects and may use other tracking systems such as Jira, Azure DevOps, GitHub Projects, or local tasks.md.
- Q: Should Specrew rely on scaffolding helpers or use official upstream extension structures directly? → A: Use the official Spec Kit extension starter template directly for the Spec Kit side. For the Squad side, use Squad's officially documented extension structure (skills/, ceremonies/, directives/, README.md) and build the Squad plugin manually. Specrew should not depend on third-party scaffolding tools for its runtime architecture.
- Q: When should Squad be introduced into Specrew's own development lifecycle? → A: From Iteration 0 — use Squad skills and directives to develop Specrew itself from day one, dogfooding the product immediately.
- Q: Should local tasks.md remain authoritative for Specrew planning, or should tasks sync to GitHub Issues? → A: tasks.md is the source of truth for implementation order and status. GitHub Issues are created for visibility and tracking (via `speckit.taskstoissues`) but tasks.md drives the implementation workflow.
- Q: Should the project owner be formally tracked as a human reviewer in the crew, or is standard GitHub PR review sufficient? → A: Standard GitHub PR review only. No formal crew role assignment — this keeps the crew model agent-focused while the human reviews through normal GitHub workflow.
- Q: Should Specrew assume Squad's built-in GitHub Projects V2 workflow suffices for board management, or should a Spec Kit-side project-management extension be considered? → A: Squad's built-in workflow plus manual board management is sufficient. No Spec Kit-side project-management extension is needed for MVP or planned as a dependency.
- Q: Is `specrew init` a Spec Kit extension command or a standalone CLI? → A: Standalone CLI/script at the repo root. It must work before Spec Kit or Squad are installed. It orchestrates `specify init` and `squad init` as sub-steps, then installs/configures the Specrew extensions. Spec Kit extension behavior begins only after `.specify/` exists; Squad extension behavior begins only after `.squad/` exists. `specrew init` is the orchestration layer above both.
- Q: Should Specrew's GitHub Projects V2 board use custom columns (like a "Review" column) or Squad's documented default board layout? → A: Use Squad's documented default board layout without customization. Any custom columns are not a Specrew requirement.
- Q: What is the correct iteration-to-FR mapping? (TG-003 vs plan Section 14 conflict) → A: Adopt plan's mapping. Iteration 0 (Foundation): FR-001, FR-013. MVP (Iteration 1): FR-002–FR-006, FR-008–FR-011, FR-018. Iteration 2: FR-007, FR-017, FR-019, FR-020. Iteration 3: FR-012, FR-014–FR-016. Brownfield (FR-020) is post-MVP; drift/review/retro (FR-008–FR-010) are essential for MVP's iteration loop.
- Q: If the Squad post-task hook is unavailable after Iteration 0 validation, what is the canonical fallback for drift detection? → A: Drift-check skill runs as an automated step within the Review/Demo ceremony (batch per-iteration). Drift is still caught within the same iteration — at review time rather than per-task. This uses only documented extension surfaces (skills + ceremonies) with no SDK dependency.
- Q: What is the Retro Facilitator's responsibility if Squad's built-in Retrospective ceremony is reused? → A: Squad's retro ceremony provides the infrastructure (scheduling, flow). The Retro Facilitator provides Specrew-specific governance content: prompting for estimation accuracy, drift summary, process adherence review, and improvement actions. It also owns generating the `retro.md` artifact.
- Q: Should the evaluation harness be delivered all at once in Iteration 3 or staged incrementally? → A: Staged. Process-quality scorer (artifact existence, ceremony adherence, drift detection verification) in Iteration 2. Outcome-quality scorer (requirement coverage, acceptance pass rate) + full end-to-end harness in Iteration 3. This matches the risk mitigation strategy and avoids building on unstable foundations.
- Q: Should the Spec Kit extension include an empty `commands/` folder in its Iteration 0 skeleton? → A: No. Remove `commands/` from the Iteration 0 skeleton and MVP scope. Specrew v1 defines no Spec Kit extension commands. Add commands/ only if/when a concrete command is designed in a future iteration.
- Q: Should iteration artifacts have versioned machine-readable schemas or remain pure prose Markdown? → A: Markdown-native versioning. Each artifact type includes a `**Schema**: v1` metadata line (consistent with R4's bold key-value convention). Mandatory vs. optional fields are marked in data-model.md. No YAML frontmatter or secondary format introduced.
- Q: What is the brownfield rollback strategy if `specrew init` fails mid-execution? → A: Resume-safe idempotency. Since all writes are additive-only (never overwrite existing files), a partial run leaves the workspace in a valid but incomplete state. Re-running `specrew init` completes remaining steps and skips already-done ones. No backup directory or rollback mechanism needed for MVP.
- Q: Which collision classes does `specrew init` check at bootstrap (MVP) vs. the full Iter 3 detector? → A: Bootstrap checks hook name and role name collisions only (these cause immediate breakage if undetected). Command name, artifact path, and ceremony name collisions are deferred to the full collision detector in Iteration 3 (FR-012).
- Q: What is the downstream user interaction model after `specrew init`? → A: Direct dual-surface. Users work with Spec Kit slash commands for specification authoring (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`), then Squad ceremonies for iteration execution (planning, review/demo, retrospective). Specrew hooks fire automatically during Spec Kit workflows to enforce governance. No wrapper commands needed.

## Personas

### P1 — Solo Builder

A developer or indie hacker who wants to run an AI crew on their own project. They write a spec, bootstrap Specrew, and let the crew deliver iteratively while they act as stakeholder, reviewer, and Spec Steward. They value speed and low ceremony but still want to know the crew is building what was specified.

### P2 — Tech Lead

A technical leader setting up an AI-assisted development workflow for a team or project. They care about governance, traceability, and iteration discipline. They assign the Spec Steward role, configure capacity, and use review/demo/retro ceremonies to keep the crew aligned. They want confidence that the AI crew's output matches the agreed spec — especially when multiple humans are involved.

### P3 — Extension Author

A developer who builds on top of Specrew by creating additional Spec Kit or Squad extensions. They need clear extension boundaries, stable integration surfaces, and documentation of what Specrew owns vs. what it delegates. They must be able to add capabilities without colliding with Specrew's governance model.

### P4 — Project Stakeholder

A non-technical or semi-technical person who wants visibility into what the AI crew is doing. They review demo outputs, read iteration summaries, and approve or redirect scope. They never interact with the crew directly — they work through the spec and the Spec Steward.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Bootstrap Specrew in a New Project (Priority: P1)

A user has an empty or existing repository. They run `specrew init`, which detects whether Spec Kit and Squad are already present, installs or validates compatible versions, then scaffolds the necessary governance artifacts (constitution placeholder, iteration config, role assignments) and configures the Squad team with the five baseline roles and default crew composition. For brownfield projects with existing Spec Kit specs or Squad team config, Specrew merges its baseline into the existing setup without overwriting. The user can then begin specifying features using Spec Kit workflows.

**Why this priority**: Without bootstrap, nothing else works. This is the entry point for all users and must work reliably before any other story delivers value.

**Independent Test**: Create a new empty repository, run `specrew init`, and verify that Spec Kit and Squad are installed at compatible versions, all expected artifacts exist, the Squad team is configured with the five baseline roles, and the Spec Steward role is assigned. Repeat with a brownfield repo that has existing Spec Kit config and verify merging preserves existing artifacts.

**Acceptance Scenarios**:

1. **Given** a repository with Spec Kit and Squad installed but no Specrew configuration, **When** the user runs the Specrew bootstrap command, **Then** Specrew creates governance scaffolding (iteration config, role assignments, downstream constitution placeholder) and configures the Squad team with the Spec Steward agent and default crew.
2. **Given** a repository that already has Specrew bootstrapped, **When** the user runs bootstrap again, **Then** Specrew detects the existing configuration and offers to repair or skip without overwriting user customizations.
3. **Given** a repository with existing Spec Kit extensions or Squad plugins that conflict with Specrew, **When** the user runs bootstrap, **Then** Specrew identifies the collision, explains the conflict clearly, and asks the user how to proceed.
4. **Given** an empty repository with no Spec Kit or Squad, **When** the user runs `specrew init`, **Then** Specrew installs Spec Kit and Squad at pinned compatible versions and proceeds with full bootstrap.
5. **Given** a brownfield repository with existing Spec Kit specs and Squad team config at compatible versions, **When** the user runs `specrew init`, **Then** Specrew preserves all existing specs, governance artifacts, and team config, and merges the five baseline roles into the existing Squad team without overwriting.
6. **Given** a repository with Spec Kit or Squad at incompatible versions, **When** the user runs `specrew init`, **Then** Specrew reports the version conflict, names the required minimum versions, and suggests an upgrade path without proceeding.

---

### User Story 2 — Run a Planned Iteration (Priority: P1)

A user has a spec with requirements and wants the AI crew to deliver against it in a structured iteration. They start an iteration, the crew plans tasks from the spec's requirements, estimates effort, and the user (or Spec Steward) approves the iteration plan. The crew then executes tasks, and the iteration concludes with a review/demo gate and a retrospective.

**Why this priority**: This is the core value loop — spec-to-delivery with governance. Without it, Specrew is just scaffolding.

**Independent Test**: Bootstrap Specrew, create a spec with 3+ requirements, start an iteration, verify the crew produces a plan with tasks mapped to requirements and effort estimates, execute at least one task, run the review gate, and verify the retro captures learnings.

**Acceptance Scenarios**:

1. **Given** a bootstrapped project with a spec containing functional requirements, **When** the user starts an iteration, **Then** the crew generates an iteration plan with tasks mapped to spec requirements, each task having an effort estimate and an assigned owner.
2. **Given** an approved iteration plan, **When** the crew executes tasks, **Then** each completed task is linked back to its source requirement and the iteration progress is visible.
3. **Given** a completed iteration, **When** the review/demo gate runs, **Then** the review checks whether each delivered task aligns with its source requirement and produces a pass/needs-work/blocked verdict per task.
4. **Given** a completed review, **When** the retrospective runs, **Then** it captures what went well, what drifted, estimation accuracy, and improvement actions for the next iteration.

---

### User Story 3 — Spec Steward Detects and Resolves Drift (Priority: P1)

During an iteration, an AI agent makes an implementation decision that diverges from what the spec says. The Spec Steward detects this drift — either during execution or at the review gate — surfaces it to the user with a clear explanation of the discrepancy, and proposes a resolution path: update the spec, revert the implementation, or flag for human decision.

**Why this priority**: Drift detection is the governance backbone. Without it, the spec is advisory rather than authoritative, which defeats Specrew's core premise.

**Independent Test**: Bootstrap Specrew, start an iteration, deliberately introduce an implementation that contradicts a spec requirement, and verify the Spec Steward detects and surfaces the drift with a resolution proposal.

**Acceptance Scenarios**:

1. **Given** an active iteration where a task's output contradicts its source requirement, **When** the Spec Steward reviews progress, **Then** it identifies the drift, cites the specific requirement and the specific deviation, and proposes resolution options.
2. **Given** a detected drift, **When** the user chooses to update the spec, **Then** the spec is amended with a change record and all downstream artifacts (plan, tasks) are flagged for reconciliation.
3. **Given** a detected drift, **When** the user chooses to revert the implementation, **Then** the task is marked as needs-rework and re-enters the iteration backlog.

---

### User Story 4 — Configure Effort Measurement and Iteration Capacity (Priority: P2)

A user configures how task effort is measured (the effort unit) and how much capacity an iteration has. The crew uses these settings when planning iterations — estimating task effort and ensuring the iteration plan fits within capacity. The user can adjust the effort model over time as calibration data from past iterations accumulates.

**Why this priority**: Capacity planning prevents overcommitment and makes iterations predictable, but Specrew can function with rough defaults before this is fully tuned.

**Independent Test**: Bootstrap Specrew, configure an effort unit and iteration capacity, start an iteration, verify the plan respects capacity limits, then adjust the model and verify subsequent plans reflect the change.

**Acceptance Scenarios**:

1. **Given** a bootstrapped project with default effort settings, **When** the user configures a custom effort unit and iteration capacity, **Then** subsequent iteration plans respect the configured capacity limit.
2. **Given** a completed iteration with actual vs. estimated effort data, **When** the retrospective runs, **Then** it reports estimation accuracy and suggests calibration adjustments.
3. **Given** an iteration plan that exceeds configured capacity, **When** the crew presents the plan, **Then** it flags the overcommitment and suggests which tasks to defer based on requirement priority.

---

### User Story 5 — Separate Self-Governance from Downstream Governance (Priority: P2)

Specrew has its own governance (its own constitution, its own spec authority). But when a user bootstraps Specrew in a downstream project, Specrew must generate or suggest governance artifacts appropriate for *that* project — not blindly copy its own constitution. The user can see and customize the downstream governance artifacts independently.

**Why this priority**: Confusing self-governance with downstream governance would produce incorrect defaults and undermine trust in the governance model.

**Independent Test**: Bootstrap Specrew in a new project, verify the generated downstream constitution placeholder is clearly distinct from Specrew's own constitution, and verify the user can customize it without affecting Specrew's internal governance.

**Acceptance Scenarios**:

1. **Given** a new project being bootstrapped with Specrew, **When** Specrew generates governance artifacts, **Then** the downstream constitution is a customizable template clearly labeled as project-specific, not a copy of Specrew's own constitution.
2. **Given** a bootstrapped project with a customized downstream constitution, **When** Specrew is upgraded, **Then** the user's downstream constitution is preserved and not overwritten.
3. **Given** a user inspecting governance artifacts, **When** they compare Specrew's own governance with the downstream governance, **Then** each is clearly scoped and labeled (e.g., "Specrew Project Governance" vs. "Your Project Governance").

---

### User Story 6 — Evaluate Specrew End-to-End (Priority: P2)

A user (or CI pipeline) runs Specrew's evaluation harness. The harness creates a new project, bootstraps Specrew, runs several iterations against a reference spec, and produces an evaluation report covering both process quality (were ceremonies followed? was drift detected?) and outcome quality (did deliverables match requirements?).

**Why this priority**: Automated evaluation makes Specrew self-verifying and gives users and contributors confidence in its reliability, but it is not required for basic operation.

**Independent Test**: Run the evaluation harness against a reference spec and verify it produces a structured report with pass/fail assessments for process and outcome criteria.

**Acceptance Scenarios**:

1. **Given** the Specrew evaluation harness and a reference spec, **When** the harness runs, **Then** it bootstraps a fresh project, executes at least 2 iterations, and produces a structured evaluation report.
2. **Given** a completed evaluation run, **When** the user reads the report, **Then** it contains separate sections for process quality (ceremony adherence, drift detection, capacity accuracy) and outcome quality (requirement coverage, deliverable alignment).
3. **Given** an evaluation run where drift was deliberately introduced, **When** the report is generated, **Then** it correctly identifies the drift events and scores process quality accordingly.

---

### User Story 7 — Extension Coexistence and Collision Detection (Priority: P3)

A user has other Spec Kit or Squad extensions installed alongside Specrew. Specrew operates without interfering unless there is a hard-stop collision (e.g., two extensions trying to own the same lifecycle hook or the same governance artifact). When a collision occurs, Specrew stops and tells the user what conflicts, which extensions are involved, and how to resolve it.

**Why this priority**: Extension hygiene matters for ecosystem health but is an edge case for most users initially.

**Independent Test**: Install Specrew alongside a mock extension that claims the same lifecycle hook, verify Specrew detects the collision and surfaces a clear error message.

**Acceptance Scenarios**:

1. **Given** a project with Specrew and another Spec Kit extension that does not conflict, **When** both are active, **Then** Specrew operates normally without warnings.
2. **Given** a project with Specrew and another extension that claims the same lifecycle hook, **When** the collision is detected, **Then** Specrew halts the conflicting operation, identifies both extensions, and describes the resolution options.
3. **Given** a project with Specrew and a Squad plugin whose ceremonies overlap with Specrew ceremonies, **When** the user runs an iteration, **Then** Specrew lists the overlapping ceremonies and asks the user which to use.

---

### Edge Cases

- What happens when the spec is empty or has no functional requirements when an iteration is started? Specrew should refuse to plan and prompt the user to complete the spec first.
- What happens when the Spec Steward role is unassigned? Specrew should block iteration start and require assignment.
- What happens when Squad is unavailable or not installed? Specrew's Spec Kit extension should still function for governance workflows, but should clearly inform the user that crew execution requires Squad.
- What happens when an iteration is abandoned mid-execution? Specrew should mark incomplete tasks as deferred, record the abandonment reason, and make them available for the next iteration.
- What happens when the crew crashes or a task fails unexpectedly mid-execution? Specrew persists task state to disk after each task completes, so the user can run a resume command to pick up from the last completed task without losing progress.
- What happens when multiple specs exist in a project? Specrew should scope iteration planning to a single spec at a time and require the user to select which spec to deliver against.
- What happens when a brownfield project has Spec Kit at an incompatible version? `specrew init` reports the version requirement, suggests the upgrade command, and does not proceed until the user upgrades.
- What happens when a brownfield project has a Squad team with custom roles that overlap with Specrew's baseline role names? `specrew init` detects the overlap, warns the user, and asks whether to merge (adopt existing role config) or rename (suffix the existing role).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a Spec Kit extension (built from the official Spec Kit extension starter template) and Squad-native configuration surfaces. Squad integration MUST use Squad's native runtime layout: skills deployed to `.copilot/skills/specrew-*/SKILL.md`, ceremonies registered in `.squad/ceremonies.md`, and directives referenced via agent charters in `.squad/agents/*/charter.md`. Specrew MUST NOT create a separate `extensions/specrew-squad/` package or rely on Squad's marketplace plugin system for bundled distribution. Specrew MUST NOT depend on third-party scaffolding tools for its runtime architecture.
- **FR-002**: System MUST provide a standalone `specrew init` CLI/script (not a Spec Kit extension command) that works before Spec Kit or Squad are installed. It MUST own the full dependency lifecycle: detect existing Spec Kit and Squad installations, install missing dependencies at pinned compatible versions (Spec Kit >= 0.7.3, Squad >= 0.9.1), run `specify init` and `squad init` as needed to create `.specify/` and `.squad/` directories, validate version compatibility of existing installations, then install/configure the Specrew Spec Kit extension, deploy Squad skills to `.copilot/skills/specrew-*/`, register ceremonies in `.squad/ceremonies.md`, scaffold governance artifacts (downstream constitution placeholder, iteration configuration, role assignments), and configure the Squad team with five predefined baseline roles: Spec Steward, Planner, Implementer, Reviewer, and Retro Facilitator. Each downstream project MUST be able to add additional domain-specific team members via Squad configuration without modifying the baseline.
- **FR-003**: The spec MUST be the authoritative source of truth. Agent memory, team decisions, and implementation artifacts MUST NOT silently replace or contradict the spec without going through a tracked change process.
- **FR-004**: System MUST define and assign a Spec Steward role responsible for keeping spec, plan, tasks, decisions, and implementation aligned.
- **FR-005**: System MUST support an iteration lifecycle with four phases: planning, execution, review/demo, and retrospective. Planning and Review/Demo are Specrew-defined ceremonies. Retrospective leverages Squad's built-in Retrospective ceremony mechanism. Execution is a phase but not a ceremony — it is routed work dispatched to agents. The three ceremony phases use Squad's ceremony infrastructure; execution uses Squad's task routing and skill invocation.
- **FR-006**: During planning, the system MUST generate an iteration plan with tasks mapped to spec requirements, each task having an effort estimate, an assigned owner, and traceability to its source requirement.
- **FR-007**: System MUST support configurable effort measurement with a defined effort unit and iteration capacity limit. *(Specrew v1 default: story points. This is a Specrew design choice, not a platform-level concept.)*
- **FR-008**: During execution, the Spec Steward MUST actively monitor for drift after each task completes (intended implementation: a Squad post-task hook — exact hook shape to be validated against Squad's SDK surface during Iteration 0). If the post-task hook surface is unavailable, the canonical fallback is: the drift-check skill runs as an automated step within the Review/Demo ceremony, checking all tasks in batch. Drift is still caught within the same iteration. Surfaced drift MUST include a specific citation of the requirement and the deviation.
- **FR-009**: During review/demo, the system MUST evaluate each delivered task against its source requirement and produce a per-task verdict (pass / needs-work / blocked).
- **FR-010**: During retrospective, the system MUST capture estimation accuracy, drift events, process adherence, and improvement actions.
- **FR-011**: System MUST distinguish between Specrew's own project governance and the governance artifacts it generates for downstream projects. It MUST NOT use its own constitution as the default for downstream projects.
- **FR-012**: System MUST detect hard-stop collisions with other Spec Kit or Squad extensions and inform the user with a clear explanation of the conflict and resolution options. It MUST NOT silently override other extensions.
- **FR-013**: System MUST integrate exclusively through Spec Kit extension capabilities and Squad extension/config/SDK capabilities — not through Copilot-specific or VS Code-specific APIs.
- **FR-014**: System MUST be architecturally separable from GitHub Copilot so that if Squad later supports other coding-agent runtimes, Specrew can adapt without a rewrite.
- **FR-015**: System MUST include an evaluation harness that can bootstrap a fresh project, run multiple iterations against a reference spec, and produce a structured report covering process quality and outcome quality. The harness is staged: the process-quality scorer (artifact checks, ceremony adherence, drift detection verification) is delivered in Iteration 2; the outcome-quality scorer (requirement coverage, acceptance scenario pass rate) and full end-to-end harness are delivered in Iteration 3.
- **FR-016**: System MUST preserve user customizations (downstream constitution, iteration config, role assignments) across Specrew upgrades.
- **FR-017**: When an iteration plan exceeds configured capacity, the system MUST flag the overcommitment and suggest task deferral based on requirement priority.
- **FR-018**: Each completed task MUST record the requirement it traces to, the agent that executed it, the effort spent, and the review verdict.
- **FR-019**: The system MUST persist iteration task state to disk after each task completes and provide a resume command that continues execution from the last completed task after a failure or interruption.
- **FR-020**: On brownfield projects, `specrew init` MUST detect existing Spec Kit specs, governance artifacts, Squad team config, and installed extensions, and MUST merge Specrew's baseline roles and config into the existing setup without overwriting user data. When existing dependency versions are incompatible, it MUST report the conflict and suggest an upgrade path without proceeding.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
  - US-1 (Bootstrap) → FR-001, FR-002, FR-003, FR-004, FR-011, FR-013, FR-020
  - US-2 (Iteration) → FR-005, FR-006, FR-007, FR-009, FR-010, FR-017, FR-018, FR-019
  - US-3 (Drift) → FR-003, FR-008
  - US-4 (Capacity) → FR-007, FR-017
  - US-5 (Governance separation) → FR-011, FR-016
  - US-6 (Evaluation) → FR-015
  - US-7 (Coexistence) → FR-012, FR-013
- **TG-002**: Each requirement MUST identify expected owner role(s).
  - FR-001–FR-002: Specrew maintainers (extension packaging)
  - FR-003–FR-004, FR-008: Spec Steward role implementation
  - FR-005–FR-007, FR-009–FR-010, FR-017–FR-018: Iteration engine
  - FR-011, FR-016: Governance scaffold subsystem
  - FR-012–FR-014: Extension integration layer
  - FR-015: Evaluation harness
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
  - Iteration 0 (Foundation): FR-001, FR-013
  - Iteration 1 (MVP): FR-002, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009, FR-010, FR-011, FR-018
  - Iteration 2: FR-007, FR-015 (process scorer), FR-017, FR-019, FR-020
  - Iteration 3: FR-012, FR-014, FR-015 (outcome scorer + full harness), FR-016
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path. None identified at this time.

### Non-Goals

- **NG-001**: Specrew does NOT build a new coding-agent runtime. It relies on Squad.
- **NG-002**: Specrew does NOT replace Spec Kit or Squad. It extends both.
- **NG-003**: Specrew does NOT provide a graphical dashboard or UI in the initial version. Governance visibility is through spec artifacts and iteration reports.
- **NG-004**: Specrew does NOT support non-GitHub-Copilot runtimes in v1. Architectural compatibility is required, but runtime support is not.
- **NG-005**: Specrew does NOT enforce a specific programming language, framework, or project type for downstream projects.
- **NG-006**: Specrew does NOT manage CI/CD pipelines. It may produce artifacts that CI/CD consumes, but pipeline configuration is out of scope.
- **NG-007**: Specrew does NOT attempt to resolve all drift automatically. It surfaces drift and proposes options; the human decides.

### Downstream User Flow

After `specrew init`, the user interacts with two existing surfaces — Spec Kit and Squad — with Specrew hooks providing automatic governance. No Specrew-specific wrapper commands exist.

| Step | Surface | Action | Specrew Governance |
| ---- | ------- | ------ | ------------------ |
| 1 | CLI | `specrew init` | Bootstrap: scaffold config, install extensions, assign roles |
| 2 | Spec Kit | `/speckit.specify` | Write feature spec |
| 3 | Spec Kit | `/speckit.plan` | Create implementation plan. `before_plan` hook validates spec has requirements |
| 4 | Spec Kit | `/speckit.tasks` | Generate tasks. `after_tasks` hook verifies traceability |
| 5 | Squad | Planning ceremony | Crew generates iteration plan from spec + tasks |
| 6 | Squad | Task execution | Crew executes tasks. Drift-check skill runs per-task (if post-task hook available) or at review |
| 7 | Squad | Review/Demo ceremony | Per-task verdicts. Drift-check skill runs as batch fallback if not per-task |
| 8 | Squad | Retrospective ceremony | Retro Facilitator generates `retro.md` artifact |
| 9 | — | Repeat from step 5 | Next iteration cycle |

### User-Visible Command Inventory (MVP)

**Standalone CLI**:

- `specrew init` — Bootstrap command (flags: `--dry-run`, `--force`, `--help`)

**Spec Kit Extension**:

- No Specrew-specific commands in v1. Governance is delivered entirely via hooks:
  - `before_plan` — Validates spec contains requirements before planning proceeds
  - `after_tasks` — Verifies task-to-requirement traceability after task generation
  - `before_implement` — Pre-implementation governance check

**Squad Extension**:

- Ceremonies: Planning, Review/Demo (reuses Squad built-in with Specrew governance content)
- Skills: `drift-check`, `capacity-planning`, `traceability-check`, `iteration-resume`
- Directives: `spec-authority`, `traceability`, `drift-reporting`

### Key Entities

All iteration artifacts are stored as Markdown files within the spec feature directory (e.g., `specs/001-feature/iterations/001/`), following Spec Kit conventions for human readability and git-diffability.

- **Specrew Configuration**: The bootstrap-generated state that ties the Spec Kit extension and Squad extension together for a given project. Includes iteration settings, role assignments, and governance artifact locations.
- **Downstream Constitution**: A governance template generated for the user's project, distinct from Specrew's own project constitution. Customizable by the user.
- **Iteration**: A time-boxed or scope-boxed delivery cycle with four phases (planning, execution, review/demo, retrospective). Scoped to a single spec.
- **Iteration Plan**: A set of tasks for one iteration, each mapped to a spec requirement, with effort estimates, assigned owners, and traceability links.
- **Spec Steward**: A dedicated role (assigned to an AI agent, a human, or both) responsible for monitoring alignment between spec, plan, tasks, decisions, and implementation.
- **Drift Event**: A recorded instance where implementation or agent behavior diverges from the spec. Includes the specific requirement, the deviation, and the resolution path chosen.
- **Evaluation Report**: The output of the evaluation harness. Contains separate assessments for process quality and outcome quality across one or more iterations.
- **Collision Record**: A detected conflict between Specrew and another extension, including the conflicting resource, the involved extensions, and the resolution options presented to the user.
- **Crew Composition**: The set of agent roles active in a project. The baseline consists of five predefined roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator). The Retro Facilitator provides Specrew-specific governance prompts (estimation accuracy, drift summary, process adherence, improvement actions) and owns `retro.md` generation — Squad's built-in Retrospective ceremony provides the infrastructure. Each project can extend this with domain-specific team members (e.g., Security Analyst, UX Designer, DBA) configured through Squad team configuration. Baseline roles cannot be removed, only supplemented.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new project can be bootstrapped with Specrew (both extensions installed, governance artifacts scaffolded, Squad team configured) in under 10 minutes of user effort.
- **SC-002**: An AI crew can run at least 3 consecutive iterations against a spec, producing working deliverables traced to requirements in each iteration.
- **SC-003**: Spec drift is detected and surfaced to the user within the same iteration it occurs — not discovered only during final review.
- **SC-004**: The evaluation harness can run against a reference spec, complete at least 2 iterations, and produce a structured pass/fail report in a single automated session.
- **SC-005**: 100% of completed tasks in an iteration are traceable to a specific spec requirement (no orphan tasks).
- **SC-006**: Iteration capacity overcommitment is flagged before execution begins in at least 90% of cases.
- **SC-007**: Users report that the Specrew governance model is understandable without reading source code — validated by having a new user bootstrap and run one iteration using only documentation.
- **SC-008**: Specrew coexists with at least one other Spec Kit extension and one other Squad plugin in the same project without interference.
- **SC-009**: Downstream governance artifacts are clearly distinguishable from Specrew's own governance in 100% of bootstrapped projects.

## Assumptions

- Specrew owns the dependency lifecycle via `specrew init`. Users do not need to pre-install Spec Kit or Squad — Specrew installs them at pinned compatible versions if not already present.
- The target runtime for v1 is GitHub Copilot via Squad. Other runtimes are a future concern.
- The Spec Steward role can be assigned to an AI agent, a human, or a combination — the assignment is made by the user during bootstrap and can be changed at any time.
- Iteration length is configurable. The default is scope-boxed (a set of tasks) rather than time-boxed, because AI crews do not have fixed working hours.
- The evaluation harness will use a controlled reference spec with predetermined requirements. It does not need to evaluate arbitrary user specs.

## Platform Facts vs. Specrew v1 Design Decisions

The following are **documented platform capabilities** confirmed in public Spec Kit and Squad sources:

- Spec Kit provides a structured flow: install → init → constitution → specify → clarify → plan → tasks → implement.
- Spec Kit’s extension model supports namespaced commands, lifecycle hooks, config layering, and template presets.
- Squad currently supports GitHub Copilot as its coding-agent runtime.
- Squad’s extension model packages reusable behavior as skills, ceremonies, and directives.
- Squad ships with built-in **Design Review** and **Retrospective** ceremonies.

The following are **Specrew v1 design decisions** that build on those platforms but are not externally documented platform facts:

- Pinned minimum versions: Spec Kit >= 0.7.3, Squad >= 0.9.1. *(Chosen based on versions current at Specrew design time. Subject to revision as both platforms evolve.)*
- Five baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) as the canonical default crew. *(A Specrew product choice, not a Squad-mandated default.)*
- Story points as the default effort unit, with configurable alternatives. *(A Specrew default, not a platform-level concept.)*
- Active post-task drift detection via a Squad post-task hook. *(Specrew’s intended use of Squad’s hook pipeline. The exact hook shape must be validated against Squad’s current SDK surface during implementation.)*
- Planning and Review/Demo as Specrew-defined ceremonies, distinct from Squad’s built-in Design Review and Retrospective. *(Specrew adds these; it does not restate existing Squad behavior.)*
- The Specrew project itself is managed via a private GitHub repository and GitHub Projects V2. *(This is a Specrew project-development choice. Downstream projects are not required to use GitHub Projects and may use Jira, Azure DevOps, GitHub Projects, or local tasks.md.)*
- Specrew uses the official Spec Kit extension starter template for its Spec Kit extension and Squad's documented extension structure (skills/, ceremonies/, directives/, README.md) for its Squad plugin. *(No third-party scaffolding tools for runtime architecture.)*
- Squad is used to develop Specrew itself from Iteration 0 — dogfooding from day one. *(Ensures the product is validated against its own development process.)*
- Local tasks.md is the authoritative source of truth for Specrew planning. GitHub Issues are created for visibility/tracking via `speckit.taskstoissues` but do not drive implementation order or status. *(A project-development workflow choice. Downstream projects may use any tracking system.)*
- Human review of Specrew is handled through standard GitHub PR review. No formal "Human Reviewer" crew role is assigned. *(Keeps the crew model agent-focused; human oversight occurs through normal PR and iteration approval gates.)*
- Specrew's GitHub Projects V2 board is managed through Squad's built-in workflow plus manual board management. No Spec Kit-side project-management extension is needed. *(If a Spec Kit project-management extension emerges later, it can be adopted opportunistically but is not a dependency.)*
- `specrew init` is a standalone CLI/script at the monorepo root — not a Spec Kit extension command. It must work before `.specify/` or `.squad/` exist. It calls `specify init` and `squad init` as sub-steps, then installs the Specrew Spec Kit extension and deploys Squad skills/ceremonies/directives into Squad's native runtime locations. *(The Spec Kit extension activates only after `.specify/` exists; Squad skills/ceremonies activate only after `.squad/` exists. `specrew init` is the orchestration layer above both.)*
- Specrew's GitHub Projects V2 board uses Squad's documented default board layout without custom columns. *(No custom "Review" column or other board customizations are required.)*

## Governance Alignment *(mandatory)*

- **Spec Steward**: Assigned by the user during bootstrap. Can be an AI agent role, a human, or both. Responsible for spec integrity across all phases.
- **Iteration Facilitator**: The user or an assigned human who starts iterations, approves plans, and participates in review/demo/retro. May be the same person as the Spec Steward for solo users.
- **Capacity Model**: Effort units per iteration (Specrew v1 default: story points, configurable). Default iteration is scope-boxed. Capacity is set by the user and calibrated by retro data over time.
- **Drift Signals**: The Spec Steward monitors task outputs against source requirements during execution. The review/demo gate performs a formal alignment check. Drift events are recorded with citations.
- **Human Oversight Points**: (1) Iteration plan approval before execution starts, (2) review/demo verdicts before an iteration closes, (3) retro sign-off before the next iteration begins, (4) any drift resolution that involves changing the spec.
- **Constitution Stability**: The project constitution is intended to remain stable and principle-oriented. Product behavior, defaults, and operational detail belong in the spec and plan — not the constitution. Future detail growth should be directed to spec/plan artifacts rather than amending the constitution.
