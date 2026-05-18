# Feature Specification: Specrew Slash-Command Surface

**Feature Branch**: `021-specrew-slash-commands`  
**Created**: 2026-05-18  
**Status**: Draft  
**Input**: User description: "Generate the initial feature specification for Specrew Slash-Command Surface from file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md with governance carryforward from Feature 020 and stop at specify completion for human review."

## Problem Statement

Specrew currently lacks a first-class `/specrew.*` command surface inside Squad and Copilot CLI sessions even though `/speckit.*` commands are already visible. That asymmetry creates an identity-equity problem because observers can misread Specrew as secondary rather than as a complementary governance methodology with its own command vocabulary, validators, and lifecycle artifacts. It also creates an adoption-equity problem because users who rely on discoverable slash commands are forced into workarounds instead of receiving the same direct entry experience as Spec Kit users.

This feature uses file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md as the authoritative source for the initial Specrew slash-command surface. It must compose with the shipped distribution baseline described in file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md and file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md, preserve the boundary discipline established in file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/spec.md, and remain additive to the project-status and session-state foundations defined in file:///C:/Dev/Specrew/specs/017-velocity-dashboard/spec.md, file:///C:/Dev/Specrew/specs/018-velocity-dashboard-visual-richness/spec.md, and file:///C:/Dev/Specrew/specs/020-session-state-durability/spec.md. This specify boundary stops after the initial spec so human review can occur on branch `021-specrew-slash-commands` before planning begins.

## Clarifications

### Session 2026-05-18

- Q: DP-001 - V1 catalog breadth → A: Ship the full 7-command v1 catalog.
- Q: DP-002 - Output handling model → A: Preserve raw/native command output by default, with only minimal slash-command wrapper context.
- Q: DP-005 - Argument forwarding policy → A: Forward only documented per-command arguments; reject unsupported extras with help guidance.
- Q: DP-007 - Minimum compatibility pin → A: Pin compatibility to the first published Specrew release that ships Feature 021 slash commands.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover Specrew as a First-Class Command Surface (Priority: P1)

A contributor working inside a Squad or Copilot CLI session wants to discover Specrew commands the same way they discover Spec Kit commands. They can type the Specrew command prefix or open Specrew help and immediately see a trustworthy, complete catalog of Specrew capabilities.

**Why this priority**: This directly addresses the proposal's identity-equity and adoption-equity framing. If discovery is missing, the feature fails its primary purpose even if command execution works underneath.

**Independent Test**: In a project that has received the Specrew slash-command surface, a tester can discover the Specrew catalog from the session command surface alone, identify the seven v1 commands, understand that `/specrew.status` is an alias for `/specrew.where`, and choose an appropriate next action without leaving the session.

**Acceptance Scenarios**:

1. **Given** a project with the Specrew slash-command surface enabled, **When** the user requests Specrew command discovery from the session command interface, **Then** the surface presents `/specrew.where`, `/specrew.status`, `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version`
2. **Given** a contributor who is new to Specrew, **When** they run `/specrew.help`, **Then** they see a full catalog that explains each command's purpose, notes the `/specrew.status` alias, and points them toward the right next action
3. **Given** a host environment where inline command suggestions are incomplete or unavailable, **When** a user asks for Specrew help, **Then** the product still provides a deterministic catalog experience instead of leaving the user without a discovery path

---

### User Story 2 - Execute the Core Specrew Command Catalog Directly (Priority: P1)

A contributor wants to invoke Specrew's core workflows directly from slash commands instead of relying on natural-language interpretation, shell escapes, or memorized workarounds. Each v1 command should trigger the correct Specrew capability while preserving the intent of the underlying workflow.

**Why this priority**: A discoverable catalog without dependable execution would still leave Specrew feeling ornamental rather than first-class.

**Independent Test**: In an initialized project with active Specrew context, a tester can run each v1 slash command and verify that it reaches the intended Specrew workflow, including alias parity between `/specrew.status` and `/specrew.where`.

**Acceptance Scenarios**:

1. **Given** an initialized project with active Specrew context, **When** the user runs `/specrew.where`, **Then** they receive the project status view associated with Specrew's existing "where am I?" experience
2. **Given** the same project, **When** the user runs `/specrew.status`, **Then** they receive the same semantic result as `/specrew.where` and the product treats it as an alias rather than a separate status model
3. **Given** a user who wants maintenance, team, review, help, or version information, **When** they run `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, or `/specrew.version`, **Then** each command reaches the intended Specrew workflow without being misrouted to an unrelated capability

---

### User Story 3 - Receive the Slash-Command Surface Through Standard Specrew Setup (Priority: P1)

A new or returning user wants the Specrew slash-command surface to arrive through normal Specrew setup and update flows rather than through one-off manual copying. When Specrew is installed or refreshed, the command surface should become part of the expected project experience.

**Why this priority**: The proposal explicitly ties the slash-command surface to Specrew distribution. If the commands require bespoke setup, adoption equity remains broken.

**Independent Test**: In a fresh project, a tester can complete standard Specrew setup, open a session, and discover the Specrew slash commands without any extra manual installation step. In an existing project, a tester can refresh Specrew and receive command-surface updates without losing existing project context.

**Acceptance Scenarios**:

1. **Given** a fresh project using the distributed Specrew baseline, **When** the user performs standard Specrew setup, **Then** the Specrew slash-command surface becomes available as part of that setup
2. **Given** an existing project already using Specrew, **When** the user refreshes the project's Specrew assets, **Then** the slash-command catalog is updated through the supported refresh path without requiring ad hoc copying steps
3. **Given** a project whose installed Specrew baseline cannot support the slash-command surface, **When** the user tries to use the new commands, **Then** the product explains the compatibility problem and the supported remediation path

---

### User Story 4 - Use `/specrew.*` and `/speckit.*` Side by Side (Priority: P2)

A contributor wants to use Specrew operational commands and Spec Kit lifecycle commands in the same session without collisions, ambiguity, or accidental boundary advancement. The two namespaces should feel complementary rather than competitive.

**Why this priority**: Coexistence is one of the proposal's five pillars and is essential to preserving Feature 016's human boundary discipline.

**Independent Test**: In a live Specrew project, a tester can use `/specrew.where` and `/speckit.plan` in the same session, confirm that both remain available, and verify that Specrew commands do not silently authorize or skip a lifecycle boundary.

**Acceptance Scenarios**:

1. **Given** a session where both Specrew and Spec Kit command surfaces are available, **When** the user invokes commands from both namespaces, **Then** each namespace remains intact and unambiguous
2. **Given** a contributor at the specify-complete review boundary, **When** they use a Specrew slash command, **Then** the system does not treat that action as approval to advance into planning or implementation
3. **Given** a user invokes `/specrew.review`, **When** a human review boundary is still required, **Then** the command supports the review workflow without bypassing the required human decision point

---

### User Story 5 - Govern a Stable and Extensible V1 Command Contract (Priority: P3)

A product steward wants the v1 slash-command surface to be stable enough for users to trust now and structured enough for future commands such as audit or metrics to be added later without rethinking the whole surface.

**Why this priority**: This is lower priority than discovery and execution, but it protects the feature from becoming a one-off patch that cannot evolve.

**Independent Test**: A reviewer can inspect the v1 command contract, confirm that every shipped command has defined discovery/help semantics and routing expectations, and confirm that future expansion rules are documented without changing the v1 command names.

**Acceptance Scenarios**:

1. **Given** the v1 command catalog, **When** a reviewer inspects the surface definition, **Then** every shipped command has a canonical name, user-facing description, and stated behavioral intent
2. **Given** future command expansion is considered, **When** a reviewer examines the v1 rules, **Then** the feature documents how new Specrew commands can be added without colliding with `/speckit.*` or renaming the v1 catalog

---

### Edge Cases

- What happens when a user invokes `/specrew.where` or `/specrew.review` in a project that has not completed standard Specrew setup?
- How does the product behave when the host session cannot provide prefix discovery or tab suggestions for `/specrew.` even though the command catalog exists?
- What happens when a user calls `/specrew.version` in a project whose installed Specrew baseline and project baseline do not match?
- How does the product respond when a slash command receives unsupported or ambiguous arguments?
- What happens when a project refresh updates part of the command catalog but leaves the session on an older command surface until the next session start?
- How does the product prevent `/specrew.review` from being interpreted as approval to cross a human review boundary?

### Integration Test Strategy

- **Catalog discovery suite**: verify the seven-command v1 catalog is discoverable through the session command surface or an explicit fallback catalog path
- **Routing suite**: verify each v1 command reaches its intended Specrew workflow, including alias parity between `/specrew.status` and `/specrew.where`
- **Coexistence suite**: verify `/specrew.*` and `/speckit.*` remain independently callable in the same session without naming collisions or accidental lifecycle advancement
- **Distribution suite**: verify fresh setup and supported refresh flows provide the slash-command surface without manual copying
- **Compatibility suite**: verify unsupported or outdated project baselines fail clearly and guide the user toward the supported remediation path
- **Observability suite**: verify command registration, routing, and compatibility failures are explicit and leave reviewer-visible diagnostics rather than silent failure

## Requirements *(mandatory)*

### Functional Requirements

#### Pillar 1: Slash-Command Definitions

- **FR-001**: The feature MUST define a v1 Specrew slash-command catalog containing `/specrew.where`, `/specrew.status`, `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version`. **Owner role**: Product steward. **Delivery window**: Iteration 001.
- **FR-002**: Each v1 command MUST have a canonical user-facing definition that states its purpose, expected usage shape, and help/discovery text. **Owner role**: Product steward. **Delivery window**: Iteration 001.
- **FR-003**: `/specrew.status` MUST behave as an alias for `/specrew.where` rather than introducing a separate status experience. **Owner role**: Product steward. **Delivery window**: Iteration 001.
- **FR-004**: The command-definition contract MUST preserve `/specrew.<command>` as the canonical namespace for every v1 user-facing command, including the `/specrew.status` alias, and MUST NOT introduce dash-style alternatives such as `/specrew-where` as parallel canonical names. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-005**: The v1 command-definition contract MUST describe an additive expansion path in which future commands such as `/specrew.audit` or `/specrew.metrics` are introduced as explicit new `/specrew.<command>` entries without renaming the shipped v1 catalog, without wildcard routing, and without colliding with `/speckit.*`. **Owner role**: Governance steward. **Delivery window**: Iteration 001.

#### Pillar 2: Invocation Routing

- **FR-006**: Each v1 slash command MUST route to its intended Specrew workflow in the current project context rather than relying on natural-language interpretation as the primary path. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-007**: The routed behavior for `/specrew.where` and `/specrew.status` MUST preserve the current Specrew project-status semantics established by file:///C:/Dev/Specrew/specs/017-velocity-dashboard/spec.md, file:///C:/Dev/Specrew/specs/018-velocity-dashboard-visual-richness/spec.md, and file:///C:/Dev/Specrew/specs/020-session-state-durability/spec.md. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-008**: `/specrew.update`, `/specrew.team`, `/specrew.review`, `/specrew.help`, and `/specrew.version` MUST each invoke the corresponding Specrew capability without being misrouted to a different command intent. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-009**: The routing contract MUST define how documented per-command arguments are accepted and forwarded, and MUST reject unsupported or ambiguous extras with clear help guidance instead of silently ignoring them. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-010**: If a routed command cannot run because project context or compatibility prerequisites are missing, the product MUST stop with a clear remediation message. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.
- **FR-011**: Routing and validation failures MUST emit reviewer-visible diagnostics so validators and humans can distinguish a routing fault from a missing command or missing setup condition. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.

#### Pillar 3: Discovery and Help

- **FR-012**: Users MUST be able to discover the v1 Specrew slash-command catalog from the session command surface or an explicit fallback help path in every supported host experience. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-013**: `/specrew.help` MUST present the full v1 catalog, brief descriptions, alias guidance for `/specrew.status`, and next-step guidance for first-time users. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-014**: `/specrew.help` MUST remain the canonical Specrew catalog, and broader session help such as `/help` MAY reference `/specrew.help` but MUST NOT absorb or replace the full Specrew catalog in a way that obscures `/speckit.*` lifecycle commands. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-015**: Discovery guidance MUST make it clear that native `/specrew.` prefix discovery is the preferred user experience when the host supports it, that manual catalog registration may be used only to enable that host-native discovery path, and that `/specrew.help` remains the canonical fallback catalog whenever inline suggestions are incomplete or unavailable. **Owner role**: UX steward. **Delivery window**: Iteration 001.

#### Pillar 4: Distribution Bundling

- **FR-016**: The Specrew slash-command surface MUST be provisioned through the standard Specrew distribution and project-setup experience described in file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md and file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md. **Owner role**: Distribution steward. **Delivery window**: Iteration 001.
- **FR-017**: A fresh project that receives the supported Specrew baseline MUST gain the slash-command surface without manual copying of command-definition assets. **Owner role**: Distribution steward. **Delivery window**: Iteration 001.
- **FR-018**: The supported project refresh path MUST update the slash-command surface safely and report command-surface changes clearly to the user. **Owner role**: Distribution steward. **Delivery window**: Iteration 001.
- **FR-019**: The slash-command surface MUST declare the first published Specrew release that ships Feature 021 slash commands as the minimum compatible v1 baseline and MUST explain incompatibility when a project or installed baseline is older than that requirement. **Owner role**: Distribution steward. **Delivery window**: Iteration 001.
- **FR-020**: Supported PowerShell 7+ operating environments MUST follow the cross-platform baseline already established in file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md for Windows 11, WSL Ubuntu, Linux Ubuntu, and macOS; where a host cannot provide identical prefix-discovery behavior, command execution and `/specrew.help` MUST still work with explicit user guidance about the degraded discovery path. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.

#### Pillar 5: Coexistence with `/speckit.*`

- **FR-021**: `/specrew.*` and `/speckit.*` MUST coexist in the same session without name collisions, hidden commands, or ambiguous routing. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-022**: The new slash-command surface MUST remain additive to the natural-language routing baseline and MUST NOT remove existing non-slash access paths. **Owner role**: Product steward. **Delivery window**: Iteration 001.
- **FR-023**: No Specrew slash command MAY implicitly authorize a new lifecycle boundary or bypass the human review checkpoints defined by file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/spec.md. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-024**: `/specrew.review` MUST support review-oriented work while preserving explicit human approval at the review boundary. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-025**: Decisions that change slash-command scope, policy defaults, or compatibility rules during this feature MUST be recorded in file:///C:/Dev/Specrew/.squad/decisions.md using Feature 021-prefixed governance entries. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-026**: The feature MUST create the pre-implementation quality scaffold at file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md before planning begins. **Owner role**: Quality steward. **Delivery window**: Iteration 001.

### Decision Points Requiring Human Review

- **DP-001 - V1 catalog breadth**: Resolved to ship all seven proposed commands in v1.
- **DP-002 - Output handling model**: Resolved so slash commands preserve command-native output with only minimal wrapper context by default.
- **DP-003 - Namespace convention**: Resolved so `/specrew.<command>` remains the canonical naming convention because it matches the proposal and mirrors `/speckit.*` namespace shape.
- **DP-004 - Discovery mechanism**: Resolved so native prefix discovery is preferred when the host supports it, manual catalog registration is only an enabling implementation detail, and `/specrew.help` remains the required fallback.
- **DP-005 - Argument forwarding policy**: Resolved so only documented arguments are forwarded and ambiguous extras are rejected with help guidance.
- **DP-006 - Help integration boundary**: Resolved so `/specrew.help` is the canonical Specrew catalog and broader help can reference it without absorbing the full Specrew catalog.
- **DP-007 - Minimum compatibility pin**: Resolved so the minimum compatible baseline is the first published Specrew release that ships Feature 021 slash commands and mismatches fail clearly with upgrade guidance.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to functional requirements: US1 → FR-001 through FR-005 and FR-012 through FR-015; US2 → FR-006 through FR-011; US3 → FR-016 through FR-020; US4 → FR-021 through FR-024; US5 → FR-005, FR-025, and FR-026.
- **TG-002**: Owner roles are defined inline per requirement and cover product, runtime, UX, distribution, reliability, governance, and quality stewardship responsibilities.
- **TG-003**: This feature is scoped as a single-iteration delivery with all v1 requirements targeted for Iteration 001; approximately 10% of iteration capacity is reserved for repair and artifact-quality assurance per carried governance defaults from Feature 020.
- **TG-004**: If planning reveals conflict between slash-command scope and the shipped distribution baseline, the reconciliation path is to preserve the seven-command catalog and adjust distribution compatibility or rollout sequencing rather than silently shrinking the namespace without recorded human approval in file:///C:/Dev/Specrew/.squad/decisions.md.

### Key Entities *(include if feature involves data)*

- **Specrew Slash Command Catalog**: The user-facing list of canonical Specrew slash commands, their alias relationships, and their discovery/help text.
- **Slash Command Definition**: The authored metadata that explains one command's name, purpose, usage shape, and routing intent.
- **Invocation Request**: A user's session-level attempt to run a Specrew slash command, optionally with supported arguments.
- **Compatibility Baseline**: The minimum distributed Specrew setup state required for the slash-command surface to be available and reliable.
- **Namespace Policy**: The governance rule that keeps `/specrew.*` additive to `/speckit.*` and prevents accidental command-surface collisions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a project with the supported Specrew baseline, a first-time user can discover the full v1 Specrew command catalog in under 30 seconds using either prefix discovery or `/specrew.help`.
- **SC-002**: The acceptance suite succeeds for all seven v1 commands, including alias parity between `/specrew.status` and `/specrew.where`, with zero command-routing collisions against `/speckit.*`.
- **SC-003**: A fresh supported project can receive the slash-command surface through the standard Specrew setup flow in one pass without manual copying of command-definition assets.
- **SC-004**: A supported project refresh preserves access to the slash-command surface and clearly reports any compatibility or update issue instead of failing silently.
- **SC-005**: Human reviewers can confirm that all seven decision points are resolved before planning starts, leaving no unrecorded v1 policy blocker at the `/speckit.plan` boundary.
- **SC-006**: Reviewers can demonstrate that Specrew commands and Spec Kit commands operate side by side in the same session without unauthorized lifecycle advancement.

## Assumptions

- file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md remains the authoritative scope source for the initial slash-command surface.
- The shipped distribution baseline in file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md is the foundation for provisioning this command surface; this feature does not reopen module-packaging scope.
- The v1 catalog is the seven commands named in the proposal.
- The boundary discipline and review-stop behavior from file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/spec.md remain mandatory for every Specrew slash command.
- Dashboard and session-state behavior already defined in file:///C:/Dev/Specrew/specs/017-velocity-dashboard/spec.md, file:///C:/Dev/Specrew/specs/018-velocity-dashboard-visual-richness/spec.md, and file:///C:/Dev/Specrew/specs/020-session-state-durability/spec.md remain the semantic source for `/specrew.where` and `/specrew.status`.
- `/specrew.help` remains the canonical Specrew catalog even when broader session help references it.
- The minimum compatible baseline for this feature is the first published Specrew release that ships Feature 021 slash commands.
- Supported PowerShell 7+ operating environments follow the Windows 11, WSL Ubuntu, Linux Ubuntu, and macOS baseline already established in file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md.

## Non-Goals (Explicit Scope Boundaries)

- This feature does **not** replace existing natural-language routing or shell-based invocation paths; it adds a first-class slash-command surface alongside them.
- This feature does **not** ship future command families such as `/specrew.audit` or `/specrew.metrics`; it only establishes the additive v1 expansion contract they must follow.
- This feature does **not** redesign the underlying project-status, team-management, review, update, or version capabilities beyond the command-surface changes needed to expose them as slash commands.
- This feature does **not** authorize planning, implementation, or review advancement automatically; moving beyond file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md still requires explicit lifecycle invocation and preserved human boundary discipline.

## Risk Register

- **Risk 1 - Command-definition complexity grows too quickly**: If the command contract becomes overly elaborate in v1, maintainers may struggle to add or validate commands consistently. **Mitigation**: keep the v1 contract narrow, ship only the seven-command catalog, and record any expansion rules explicitly in file:///C:/Dev/Specrew/.squad/decisions.md.
- **Risk 2 - Output handling feels inconsistent across commands**: If routed slash commands produce surprising output shapes, users may distrust the surface. **Mitigation**: lock output expectations in the acceptance suite and preserve the resolved raw-output default unless a future feature records a different policy.
- **Risk 3 - Prefix discovery is unreliable in some hosts**: If the host does not surface `/specrew.` suggestions cleanly, the discovery promise weakens. **Mitigation**: treat `/specrew.help` as a mandatory fallback and test both discovery paths.
- **Risk 4 - Distribution and compatibility drift**: If projects receive the command catalog without the right baseline, slash commands may appear broken. **Mitigation**: define a clear compatibility pin, validate refresh/setup paths, and fail visibly with remediation guidance.
- **Risk 5 - Namespace confusion with `/speckit.*`**: If the two command surfaces overlap or imply different boundary rules, users may accidentally cross governance lines. **Mitigation**: preserve additive namespace rules, keep coexistence testing mandatory, and enforce Feature 016 boundary discipline.

## Cross-References

- **Authoritative source**: file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md
- **Distribution dependency**: file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md
- **Feature 016 - Boundary discipline**: file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/spec.md
- **Feature 017 - Project status baseline**: file:///C:/Dev/Specrew/specs/017-velocity-dashboard/spec.md
- **Feature 018 - Richer status presentation**: file:///C:/Dev/Specrew/specs/018-velocity-dashboard-visual-richness/spec.md
- **Feature 019 - Shipped distribution baseline**: file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md
- **Feature 020 - Durable session-state baseline**: file:///C:/Dev/Specrew/specs/020-session-state-durability/spec.md

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess (feature sponsor and human review authority for the initial specification)
- **Iteration Facilitator**: Alon Fliess (accountable for cadence, blockers, and specify-to-plan review sequencing)
- **Capacity Model**: Story Points (SP); estimated 5-8 SP in a single iteration, with approximately 10% of capacity reserved for repair and artifact-quality assurance
- **Drift Signals**: Loss of the seven-command catalog, namespace changes without recorded approval, missing command discovery fallback, compatibility ambiguity, silent validator failures, missing Feature 021-prefixed governance entries, or any authored prose that drops required file:/// references indicate drift
- **Human Oversight Points**:
  - Specify-complete human review on branch `021-specrew-slash-commands` before `/speckit.plan`
  - Resolution of DP-001 through DP-007 with structured decision logging in file:///C:/Dev/Specrew/.squad/decisions.md
  - Verification that file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md exists as the iteration kickoff quality scaffold
  - Push-after-every-commit discipline for spec and plan artifacts before the next review boundary
