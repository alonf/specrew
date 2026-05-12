# Feature Specification: Human Architecture Intent Checkpoint

**Feature Branch**: `008-quality-profile-foundation`  
**Created**: 2026-05-09  
**Status**: Draft  
**Input**: User description: "Add a human-controlled architecture / implementation intent checkpoint between specification and planning. Specrew must give the human developer or architect explicit control over important implementation decisions before Squad turns a completed feature spec into an implementation plan."

## Problem Statement

Specrew's current workflow allows Squad to generate plan.md directly from a completed spec.md without requiring human approval of the implementation strategy. This creates the risk that Squad bakes architectural assumptions, design choices, API contracts, data model decisions, and ownership model decisions into the plan before the human architect has seen or approved them.

When architectural decisions are implicit or hidden in early planning phases, they become expensive to change. By the time they surface during implementation or review, rewrites are costly. Specrew needs an explicit checkpoint where:

1. The human architect sees the proposed implementation strategy before planning is finalized
2. Architectural decisions and trade-offs are made transparent
3. The human can approve, redirect, or constrain high-impact design choices
4. The resulting plan reflects the human's architectural direction, not just Squad's assumptions

This feature preserves Squad's autonomy for local implementation details while restoring human control over architecture, public APIs, persistence models, security posture, and other decisions that are expensive to reverse.

## Relationship to Existing Features

This feature complements and reinforces the existing Specrew lifecycle:

- **Spec clarification** (`/speckit.clarify`) runs before this checkpoint and ensures the feature description is complete
- **Planning** (`/speckit.plan`) is the entry point; it automatically invokes this checkpoint as a mandatory pre-step
  - **SEQUENCING**: The checkpoint runs WITHIN `/speckit.plan`, after spec loading and before plan body generation (the flow is: load spec → run checkpoint → record approval → generate plan body including Architecture Intent Review section → finalize plan.md)
  - User/human must interact with the checkpoint to approve or redirect architecture before `/speckit.plan` can finalize plan.md
- **This checkpoint** (new) runs as an automatic blocking pre-step inside `/speckit.plan` and surfaces architecture intent for human approval
- **Pre-implementation approval** (existing) runs after plan.md is finalized and before implementation starts

**EXPLICIT FLOW**: spec.md (complete) → `/speckit.plan` invoked → checkpoint generates brief → human reviews/decides → decision recorded in planning context → plan.md body generated including Architecture Intent Review section → plan.md finalized → (later) pre-implementation approval → implementation

The checkpoint does not replace any of these; it adds a required decision gate inside planning, before plan.md is finalized.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Architect approves implementation direction before planning (Priority: P1)

As a human architect, I want Squad to explain how it intends to implement the feature—what modules it will change, what APIs it will create, what persistence model it will use, what dependencies it will add—before it creates the plan. This lets me approve, correct, constrain, or redirect major implementation decisions while they are still cheap to change.

**Why this priority**: Without this story, Squad still bakes architectural assumptions into the plan without explicit human approval, and the checkpoint provides no value.

**Independent Test**: After a clarified spec, trigger the architecture intent checkpoint and verify that Squad presents a structured brief showing proposed design approach, affected modules, expected changes to data/APIs/workflows, major dependency/tooling choices, and asks for human direction on key decisions before generating plan.md.

**Acceptance Scenarios**:

1. **Given** a completed and clarified feature spec, **When** Squad is about to generate plan.md, **Then** Squad first presents an architecture intent brief instead of proceeding directly to planning.
2. **Given** Squad presents an implementation strategy, **When** the human provides explicit approval, **Then** the resulting plan.md documents the approved direction explicitly and reflects it in task breakdown, agent routing, and validation strategy.
3. **Given** the human rejects a proposed approach, **When** Squad generates the plan, **Then** the rejected approach is not used unless the human later changes the decision.
4. **Given** Squad detects that implementation will conflict with the approved direction, **When** the conflict is discovered, **Then** Squad pauses and asks for a new decision instead of silently diverging.

---

### User Story 2 - Human constraints and forbidden paths are recorded and enforced (Priority: P1)

As a human architect, I want my constraints and decisions to be recorded in the governance artifacts—not just remembered in chat. This ensures that the plan, tasks, and implementation stay aligned with my direction, and that any future review can see what decisions were made and why.

**Why this priority**: Without explicit recording, human constraints are easily forgotten, and the checkpoint becomes a conversation without ongoing enforceability.

**Independent Test**: After human provides architecture direction, verify that plan.md documents accepted decisions, rejected alternatives, human constraints, and links to decision ledger (if project uses `.squad/decisions.md`). Verify that these recorded constraints appear in related planning and validation artifacts.

**Acceptance Scenarios**:

1. **Given** the human provides architectural direction or constraints, **When** plan.md is created, **Then** the plan documents the accepted decisions, rejected alternatives, human constraints, and any unresolved questions in an Architecture Intent Review section.
2. **Given** a feature has recorded human constraints, **When** implementation or review work proceeds, **Then** the constraints are visible in the active planning and review artifacts so they can be enforced.
3. **Given** the human forbids a particular approach (e.g., "do not use ORM for this data model"), **When** implementation choices conflict with this, **Then** the conflict is caught before implementation proceeds.

---

### User Story 3 - Squad respects minimal interruption and local autonomy (Priority: P1)

As a Squad agent, I want to avoid asking the human for approval on every local implementation detail. I should only interrupt for decisions that are expensive or risky to reverse: architecture, public APIs, persistence, dependencies, security posture, migration strategy, and behavior changes that affect users. For routine local details, I should proceed with existing conventions unless the spec already gives clear direction.

**Why this priority**: If the checkpoint requires human approval for every decision, it becomes a bottleneck. Squad must remain autonomous for small reversible choices.

**Independent Test**: For a feature with no meaningful architecture choices (e.g., a small bug fix), verify that Squad can state it will follow existing conventions and ask only for confirmation or constraints. For a feature with significant choices, verify that Squad asks for direction only on decisions that are expensive to reverse.

**Acceptance Scenarios**:

1. **Given** a feature with no meaningful architecture choices, **When** the checkpoint runs, **Then** Squad may state that it will follow existing conventions and ask only for confirmation, constraints, or explicit direction.
2. **Given** a decision is local and easily reversible (e.g., choice of internal function names), **When** Squad is planning, **Then** Squad may proceed without blocking on human input for that detail.
3. **Given** a decision affects public contract, persistence, dependencies, or security, **When** Squad encounters such a decision, **Then** Squad asks for human direction at the checkpoint.

---

### Edge Cases

- What happens when the human requests changes to the approved direction during implementation? → The human can request a new architecture decision, which Squad must honor. Any conflicts between the new direction and work already completed must be surfaced and resolved.
- What if Squad discovers that the approved direction is impossible or unsafe during implementation? → Squad must pause, explain the conflict, and ask for a new decision rather than silently diverging.
- What if a feature has no clear implementation strategy (e.g., spec is too vague)? → The checkpoint should reject advancement and recommend returning to spec clarification before attempting to surface architectural choices.
- What if the human is unavailable to approve the direction? → Squad may wait, or the feature may be paused until the human is available. Proceeding without approval is not allowed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Architecture Intent Brief**: Inside `/speckit.plan`, after spec loading and before plan body generation, Squad must produce a structured brief that includes:
  - Intended architecture or design approach (1–2 paragraph summary)
  - Affected modules, services, files, or boundaries (list with brief justification)
  - Expected data model, API, CLI, UI, workflow, or storage changes (structured list with before/after or impact)
  - Important dependency, framework, or tooling choices
  - Security, reliability, migration, performance, and compatibility implications where relevant
  - Known assumptions and constraints
  - Meaningful alternatives considered (with brief trade-off analysis), WHEN alternative approaches meaningfully differ in cost, risk, or reversibility
  - Explicit questions for decisions that require human preference or authority

- **FR-002: Human Decision Boundary**: Squad must ask for human input on decisions that are expensive or risky to reverse:
  - Architecture or subsystem boundaries
  - Public APIs or contracts (REST endpoints, function signatures, event schemas, CLI arguments)
  - Persistence model or schema changes (new tables, significant column/field changes, migration paths)
  - Major dependency additions (libraries, services, frameworks)
  - Authentication, authorization, or security posture changes
  - Concurrency, retry, idempotency, or consistency semantics (when these are material to the feature)
  - Migration and rollback strategy (when relevant to breaking changes)
  - Behavior changes that affect user-facing workflows
  - Large refactors or ownership boundary changes
  - Squad should NOT block on routine local implementation details (internal function names, local variable scope, choice of iteration pattern for reversible internal work) unless they materially affect the above.

- **FR-003: Decision Recording**: Human responses must be recorded in the governing artifacts, not only in chat. At minimum, the resulting plan.md must include:
  - Accepted implementation direction (concise statement of the approved approach)
  - Rejected alternatives and the reasons they were rejected (when materially relevant)
  - Human constraints or forbidden paths (explicit list of what must or must not be done)
  - Unresolved architecture questions, if any
  - Links or references to decision ledger entries when the project uses `.squad/decisions.md` or similar governance artifact

- **FR-004: Planning Reflects Human Direction**: plan.md, task breakdown, validation strategy, and agent routing must reflect the accepted architecture direction. If Squad discovers that the approved direction is unsafe, impossible, or inconsistent with the spec, Squad must stop and return to the human with a focused explanation and proposed alternatives before proceeding.

- **FR-005: Minimal Interruption**: The checkpoint must avoid turning every implementation detail into a human approval request. When the feature follows existing conventions with no expensive-to-reverse decisions (small bug fixes, routine refactors following established patterns), Squad may present a brief stating the routine nature and ask only for confirmation or explicit constraints rather than requiring alternative generation. For features with meaningful architecture choices, Squad must present alternatives only when those alternatives materially differ in cost, risk, or reversibility. Squad may proceed without alternatives when:
  - The decision is local and easily reversible
  - The approach follows existing project conventions (and this is evident in the spec or prior planning)
  - No public contract, persistence, dependency, or security boundary changes are involved
  - The spec already gives clear direction (in which case the checkpoint notes this and proceeds)

- **FR-006: Pre-Implementation Approval Remains Required**: After the human approves the architecture intent and plan.md is finalized, Squad must still request explicit pre-implementation approval. That approval summary must reference the accepted implementation direction so the final gate is aware of what architectural path was chosen.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements. All user stories (P1, P2, P3) must have clear acceptance scenarios that verify the requirement is met.
- **TG-002**: The checkpoint MUST be visibly present in the Specrew workflow documentation and integrated into the `/speckit.plan` command or a preceding `pre-plan` step.
- **TG-003**: Human decisions recorded in plan.md MUST be traceable back to the checkpoint conversation or a persistent decision ledger.
- **TG-004**: Any conflict between spec, checkpoint direction, and implementation MUST include an explicit escalation path (return to human with options).

### Key Entities *(include if feature involves data)*

- **Architecture Intent Brief**: Structured document showing proposed implementation direction, alternatives, and open questions. Generated by Squad, presented to human for approval.
- **Decision Record**: Human-approved decision or constraint recorded in plan.md or external decision ledger. Governs all downstream planning, task breakdown, and implementation.
- **Architectural Boundary**: Module, service, file structure, or system boundary that is materially affected by the feature. Must be visible in the brief so the human can assess scope and risk.
- **Public Contract**: API endpoint, function signature, event schema, CLI argument, or other surface that external consumers or downstream code depends on. Requires explicit human approval if new or changed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of non-trivial features (excluding small bug fixes and routine refactors) receive an explicit architecture intent brief before plan.md is generated, as measured by presence of an Architecture Intent Review section in plan.md.

- **SC-002**: Human architects can identify and block or redirect major implementation decisions in the checkpoint without waiting for code review, as measured by checkpoint completion with recorded approval (clean approval or approval-with-constraints both count as success; rejection or deferral count as engagement-requiring-revision).

- **SC-003**: Fewer late-stage implementation rewrites due to hidden architectural assumptions, as measured by reduction in plan/task/implementation divergence issues compared to prior Specrew workflow (baseline: current issue frequency if tracked; target: reduction by 50% or more over next 3 feature delivery cycles).

- **SC-004**: Plans contain explicit architecture intent instead of only task lists, as measured by presence of accepted decisions, rejected alternatives, and constraints sections in all post-checkpoint plan.md files.

- **SC-005**: Squad remains autonomous for local reversible decisions, as measured by checkpoint taking no more than 1 human interaction per feature on average (excluding clarification questions).

- **SC-006**: Human approval of architecture direction completes without requiring implementation to begin, as measured by time between checkpoint approval and plan finalization (target: same session, no blocking delays).

## Clarifications

### Session 2026-05-09

- Q: How is the architecture intent checkpoint invoked? Is it a separate command or integrated into an existing flow? → A: The checkpoint is invoked as an AUTOMATIC pre-step inside `/speckit.plan`. When a user runs `/speckit.plan` after spec clarification, the plan command automatically runs the checkpoint first, surfaces the architecture brief to the human, waits for human decision/approval, then continues with task generation. The checkpoint is not a separate invocation; it is a blocking internal phase within the planning workflow.

## Assumptions

- The human developer or architect is available to approve architecture intent before planning proceeds. If not available, the feature pauses at the checkpoint and does not advance to planning.
- Squad has sufficient context from the spec and repository to generate a meaningful brief. Vague specs that do not allow Squad to propose any direction are rejected at the checkpoint and returned to clarification.
- The project has or will develop a stable process for recording human decisions (e.g., in plan.md, in .squad/decisions.md, or in chat logs). Initial implementation records decisions in plan.md; future integration with decision ledger is a follow-on.
- The existing pre-implementation approval gate remains in place and unchanged. This checkpoint is an additional gate, not a replacement.
- "Easy to reverse" and "hard to reverse" are assessed using reasonable engineering judgment and project conventions. Guidelines will be published as part of the implementation plan.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Human developer or architect responsible for approving architecture intent and recorded decisions in plan.md.
- **Iteration Facilitator**: Specrew process owner responsible for ensuring the checkpoint is invoked within `/speckit.plan` (after spec loading and before plan body generation/finalization) and for resolving deadlocks if the human is unavailable. The Architecture Intent Review is part of finalized `plan.md`.
- **Checkpoint Invocation**: The checkpoint is an automatic mandatory pre-step within the `/speckit.plan` command. When a user runs `/speckit.plan` after spec clarification is complete, the plan command automatically:
  1. Loads the completed spec.md
  2. Invokes Squad to generate an architecture intent brief
  3. Surfaces the brief to the human for review and decision
  4. Waits for human input (approval, approval-with-constraints, redirects, or rejection)
  5. Records human decisions in the planning context
  6. Proceeds to plan body generation (including Architecture Intent Review section) and plan.md finalization if approved, or returns to spec/checkpoint if rejected
  
  **EXPLICIT SEQUENCING**: The checkpoint runs within `/speckit.plan`, after spec loading and before plan body generation. The checkpoint completes and records approval, then plan body generation proceeds (including Architecture Intent Review section). The finalized plan.md MUST include the Architecture Intent Review section showing the approved direction, constraints, and rejected alternatives. Task generation happens after plan.md exists and is approved.
- **Capacity Model**: The checkpoint is expected to require 1 human interaction per feature on average, adding ~15–30 minutes to the planning phase depending on feature complexity. This is in addition to existing planning time.
- **Drift Signals**: If plan.md lacks an Architecture Intent Review section, or if tasks are created before checkpoint approval is recorded, these are drift signals that the checkpoint was bypassed.
- **Human Oversight Points**: Mandatory approval by human architect/developer before plan.md advances. Optional re-engagement if implementation conflicts are discovered. Optional escalation if the human is unavailable or the spec is too vague.
