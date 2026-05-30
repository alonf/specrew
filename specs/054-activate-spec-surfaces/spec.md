# Feature Specification: Discoverable Spec Kit Surfaces

**Feature Branch**: `054-activate-spec-surfaces`  
**Created**: 2026-05-31  
**Status**: Draft  
**Input**: User description: "Proposal 138: Activate two currently-deployed but underused Spec Kit capabilities as first-class, discoverable Specrew surfaces, and optionally a third. Specifically: 1) /speckit.checklist — make it discoverable and position it in the lifecycle where it adds value; 2) /speckit.analyze — make it discoverable and integrate it where it provides value; 3) /speckit.taskstoissues — not in scope yet; defer to v2 unless trivial during this iteration. Also improve docs/discovery so Specrew users know these lifecycle-adjacent commands exist and when to use them."
**Proposal Source**: `proposals/138-spec-kit-underutilized-surfaces.md`
**Confirmed Intake Decision**: `/speckit.checklist` lands before-plan for this feature slice.

## Clarifications

### Session 2026-05-30

- Q: Where should `/speckit.analyze` be positioned for this feature slice? → A: At `before-implement`, after `/speckit.tasks` has produced a complete `tasks.md` and the full `spec.md`/`plan.md`/`tasks.md` artifact set exists.

## Scope Boundaries

### In Scope

- Make `/speckit.checklist` a first-class, discoverable Specrew surface before planning begins.
- Make `/speckit.analyze` a first-class, discoverable Specrew surface at a clearly defined lifecycle point.
- Improve lifecycle guidance and documentation so users understand what these commands do, when to use them, and how they relate to Specrew's existing governance checks.
- Explicitly communicate that `/speckit.taskstoissues` is deferred for a later version and is not part of the default lifecycle in this slice.

### Out of Scope

- Activating `/speckit.taskstoissues` as a default workflow step.
- Expanding this slice into issue-sync behavior, parent/child issue management, or external tracker integration.
- Replacing Specrew's existing governance validation with Spec Kit commands.
- Changing Specrew's constitution workflow.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Discover checklist before planning (Priority: P1)

As a Specrew user preparing to move from specification into planning, I want `/speckit.checklist` to be surfaced before-plan with a clear explanation of its purpose so that I know to use it to improve requirements quality before planning begins.

**Why this priority**: The user has already confirmed this placement for the current slice, and it delivers the most immediate value by preventing weak requirements from flowing into planning.

**Independent Test**: A user following the normal lifecycle can reach the pre-plan step, see `/speckit.checklist`, understand that it validates requirements-writing quality, and identify whether to run it without consulting the proposal or source code.

**Acceptance Scenarios**:

1. **Given** a substantive feature specification is ready for planning, **When** the user reaches the before-plan boundary, **Then** Specrew surfaces `/speckit.checklist` with guidance that it improves requirement quality before planning starts.
2. **Given** a user sees `/speckit.checklist`, **When** they read the guidance shown there, **Then** they understand it checks requirement clarity, completeness, consistency, and edge-case coverage rather than implementation correctness.
3. **Given** a lightweight or low-risk slice, **When** the user reaches the same boundary, **Then** Specrew does not misrepresent checklist use as mandatory if the feature does not merit that overhead.

---

### User Story 2 - Discover analyze at the right lifecycle point (Priority: P2)

As a Specrew user moving through the lifecycle, I want `/speckit.analyze` to appear at the stage where it adds the most value so that I can use it as an additive quality and consistency check rather than an ambiguous extra command.

**Why this priority**: `/speckit.analyze` adds value only once the full artifact set exists. Positioning it at `before-implement` keeps it aligned with its cross-artifact analysis role and avoids surfacing it too early.

**Independent Test**: A user can identify where `/speckit.analyze` belongs in the lifecycle, what artifacts it evaluates, and why it complements rather than replaces existing governance validation.

**Acceptance Scenarios**:

1. **Given** a user reaches `before-implement` after `/speckit.tasks` has produced a complete `tasks.md`, **When** Specrew surfaces `/speckit.analyze`, **Then** the guidance explains that it checks cross-artifact consistency and quality across `spec.md`, `plan.md`, and `tasks.md`.
2. **Given** a user encounters `/speckit.analyze`, **When** they review its description, **Then** they understand it is additive to Specrew's existing governance checks rather than a replacement.
3. **Given** the required artifacts for analysis are not yet available, **When** a user looks for `/speckit.analyze`, **Then** Specrew explains that the command is not yet relevant and points to the stage where it becomes useful.

---

### User Story 3 - Understand surfaced vs deferred lifecycle-adjacent commands (Priority: P2)

As a Specrew user or maintainer, I want the documentation and lifecycle guidance to explain which Spec Kit commands Specrew actively surfaces, which ones are deferred, and when to use each surfaced command so that I can follow the intended workflow without guessing.

**Why this priority**: The feature is about discoverability as much as activation. Without consistent guidance, users will still miss the commands or misread Specrew's intended workflow.

**Independent Test**: A user can review the updated lifecycle guidance and correctly distinguish the actively surfaced commands from deferred ones, including the fact that `/speckit.taskstoissues` is not part of the default workflow for this slice.

**Acceptance Scenarios**:

1. **Given** a user consults Specrew's lifecycle guidance or command-discovery material, **When** they look for lifecycle-adjacent Spec Kit commands, **Then** they can find `/speckit.checklist` and `/speckit.analyze` with plain-language guidance on when to use each one.
2. **Given** a user looks for `/speckit.taskstoissues`, **When** they review the same guidance, **Then** they see that it is intentionally deferred for a later version rather than silently omitted or implied to be active.
3. **Given** multiple user-facing discovery surfaces are updated by this feature, **When** a user compares them, **Then** the recommended lifecycle timing and purpose of each surfaced command are consistent.

---

### Edge Cases

- A small, low-risk slice reaches before-plan and the user should not receive misleading guidance that a heavyweight requirements-quality pass is always necessary.
- A user looks for `/speckit.analyze` before the required lifecycle artifacts exist and needs guidance about when it becomes relevant instead of a dead-end recommendation.
- One discovery surface recommends a command at one lifecycle point while another recommends it at a different point, creating workflow drift.
- Deferred commands such as `/speckit.taskstoissues` are mistaken for active default workflow steps because the documentation does not state their status clearly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST surface `/speckit.checklist` as a first-class lifecycle-adjacent command before planning for substantive feature work.
  - **Owner**: Spec Steward, Planner
  - **Delivery Window**: Feature slice delivery

- **FR-002**: Specrew MUST explain `/speckit.checklist` in plain language as a requirements-quality aid that helps users catch vague, incomplete, inconsistent, or missing requirements before planning.
  - **Owner**: Spec Steward, Reviewer
  - **Delivery Window**: Feature slice delivery

- **FR-003**: Specrew MUST make the recommended before-plan use of `/speckit.checklist` discoverable across the user-facing lifecycle guidance updated by this feature.
  - **Owner**: Spec Steward, Planner
  - **Delivery Window**: Feature slice delivery

- **FR-004**: Specrew MUST preserve proportional guidance for `/speckit.checklist`, so users can tell when the command is recommended for substantive work and when it is optional for smaller slices.
  - **Owner**: Spec Steward
  - **Delivery Window**: Feature slice delivery

- **FR-005**: Specrew MUST surface `/speckit.analyze` as a first-class lifecycle-adjacent command with clear guidance about the qualitative and cross-artifact issues it is intended to catch across `spec.md`, `plan.md`, and `tasks.md`.
  - **Owner**: Spec Steward, Reviewer
  - **Delivery Window**: Feature slice delivery

- **FR-006**: Specrew MUST place `/speckit.analyze` at the `before-implement` lifecycle boundary, only after `/speckit.tasks` has successfully produced a complete `tasks.md`, and reflect that timing consistently across lifecycle guidance and documentation.
  - **Owner**: Spec Steward, Reviewer
  - **Delivery Window**: Feature slice delivery

- **FR-007**: Specrew MUST explain that `/speckit.analyze` complements existing governance validation instead of replacing it.
  - **Owner**: Reviewer
  - **Delivery Window**: Feature slice delivery

- **FR-008**: Specrew MUST ensure users are only guided toward `/speckit.analyze` when `spec.md`, `plan.md`, and `tasks.md` all exist, and MUST tell them to return at `before-implement` if they encounter it before `/speckit.tasks` completes.
  - **Owner**: Planner, Reviewer
  - **Delivery Window**: Feature slice delivery

- **FR-009**: Specrew MUST improve command-discovery material so users can find the actively surfaced Spec Kit lifecycle-adjacent commands and understand when to use each one without referring back to the proposal.
  - **Owner**: Spec Steward
  - **Delivery Window**: Feature slice delivery

- **FR-010**: Specrew MUST explicitly state that `/speckit.taskstoissues` is deferred for a later version and is not part of the default lifecycle in this feature slice.
  - **Owner**: Spec Steward
  - **Delivery Window**: Feature slice delivery

- **FR-011**: The lifecycle timing, purpose, and deferment status described for these commands MUST remain consistent across every user-facing discovery surface updated by this feature.
  - **Owner**: Spec Steward, Reviewer
  - **Delivery Window**: Feature slice delivery

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
  - User Story 1 → FR-001, FR-002, FR-003, FR-004
  - User Story 2 → FR-005, FR-006, FR-007, FR-008
  - User Story 3 → FR-009, FR-010, FR-011

- **TG-002**: Each requirement MUST identify expected owner role(s).
  - All functional requirements include owner roles under each item.

- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
  - FR-001 through FR-005 and FR-007 through FR-011 target this feature slice.
  - FR-006 is clarified and targets this feature slice with `before-implement` timing after successful task generation.

- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
  - `/speckit.checklist` placement is resolved for this slice: before-plan is authoritative.
  - `/speckit.analyze` placement is resolved for this slice: `before-implement` is authoritative, and the command is only relevant after `/speckit.tasks` has produced a complete `tasks.md`.
  - `/speckit.taskstoissues` is explicitly deferred and MUST NOT be treated as active default-scope work during planning unless a later clarification re-scopes it as trivial and tightly coupled.

### Key Entities *(include if feature involves data)*

- **Lifecycle-Adjacent Command Surface**: A user-facing Specrew touchpoint that makes a Spec Kit command visible, explains its purpose, and places it at the right stage of the workflow.
- **Boundary Guidance Entry**: The user-facing explanation that tells a person when a command should be used, why it matters, and whether it is recommended, optional, or deferred.
- **Discovery Surface**: Any user-facing Specrew documentation, command catalog, or lifecycle guide updated to help users find and understand lifecycle-adjacent commands.
- **Deferred Command Decision**: The explicit statement that a known command exists but is intentionally not activated as part of the default lifecycle in the current slice.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In every user-facing lifecycle surface updated by this feature, `/speckit.checklist` is described consistently as a before-plan command and no updated surface recommends it at a conflicting stage.
- **SC-002**: After reading the updated before-plan guidance once, a Specrew user can explain the purpose of `/speckit.checklist` and when to use it without needing the proposal as reference.
- **SC-003**: Every updated discovery surface describes `/speckit.analyze` consistently as a `before-implement` command that runs only after `/speckit.tasks` has produced a complete `tasks.md`, while preserving the same additive-positioning explanation for that command.
- **SC-004**: A user can identify the active surfaced commands covered by this feature and their recommended lifecycle timing within 2 minutes of consulting Specrew's standard lifecycle guidance.
- **SC-005**: No updated discovery surface presents `/speckit.taskstoissues` as part of the default lifecycle for this slice; all such surfaces describe it as deferred when it is mentioned.

## Assumptions

- Specrew already has working underlying `/speckit.checklist` and `/speckit.analyze` capabilities; this slice is about surfacing, positioning, and explaining them.
- `/speckit.analyze` depends on the complete `spec.md`/`plan.md`/`tasks.md` set and therefore becomes relevant only at `before-implement` after successful task generation.
- Proposal 138 is the primary source for the business rationale, but the confirmed intake decision that `/speckit.checklist` lands before-plan overrides earlier tentative placement language for this slice.
- `/speckit.taskstoissues` remains deferred unless a later clarification explicitly re-scopes it as trivial and tightly coupled to this work.
- Existing governance validation remains the primary structural guardrail; any surfaced Spec Kit command in this slice is additive guidance rather than a replacement.
- This is brownfield-new work and must fit the current Specrew lifecycle without introducing unrelated lifecycle changes.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess — accountable for scope integrity, proposal alignment, and preserving the explicit deferment boundary for `/speckit.taskstoissues`.
- **Iteration Facilitator**: Planner and Reviewer roles for this slice — accountable for keeping the `before-implement` placement of `/speckit.analyze` and its additive guidance consistent across discovery surfaces.
- **Capacity Model**: Small brownfield feature slice, estimated at 5-8 effort points if limited to checklist activation, analyze surfacing, and discovery/documentation updates within one delivery cycle.
- **Drift Signals**:
  - `/speckit.checklist` is surfaced before-plan in one place but omitted or repositioned elsewhere.
  - `/speckit.analyze` is described anywhere other than `before-implement` after successful task generation.
  - `/speckit.taskstoissues` appears as active default workflow scope despite being deferred in this slice.
  - Discovery material explains a command's purpose differently across lifecycle surfaces, causing user confusion.
- **Human Oversight Points**:
  1. `/speckit.clarify` records the authoritative `before-implement` placement for `/speckit.analyze` before planning begins.
  2. Pre-plan review confirms `/speckit.checklist` is surfaced with the agreed before-plan timing and correct explanation.
  3. Planning review confirms discovery and deferment guidance remain internally consistent before implementation work is approved.
