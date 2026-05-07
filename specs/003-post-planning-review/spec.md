# Feature Specification: Post-Planning Review

**Feature Branch**: `[003-post-planning-review]`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: User description: "After the planning phase completes successfully, Specrew should automatically present the human developer with a compact but useful planning summary before implementation starts. The human developer should have clear control to review the plan, request changes, ask questions, and only then explicitly approve implementation."

## Problem Statement

Specrew currently completes planning by producing the expected Spec Kit artifacts, but a human developer may still need to open several files or infer the next safe action before implementation begins. This creates governance risk: implementation can feel like the default next step even when the developer still needs to review, question, or revise the planned work. This feature adds a post-planning review checkpoint that makes the plan understandable, keeps the human in control, and requires explicit approval before implementation can begin.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review the completed plan at a glance (Priority: P1)

After planning, task generation, and the required planning governance gates succeed, a human developer wants Specrew to immediately present a concise summary of what is about to be built so they can understand the execution shape without opening multiple artifacts first.

**Why this priority**: The feature provides little value unless successful planning automatically ends in a clear review checkpoint instead of an implicit handoff to implementation.

**Independent Test**: Complete a successful planning flow and verify that Specrew automatically shows a compact post-planning summary with the execution shape and key artifact paths before implementation begins.

**Acceptance Scenarios**:

1. **Given** planning, task generation, and the relevant planning governance gates have all succeeded, **When** the planning phase completes, **Then** Specrew automatically presents a concise post-planning summary before any implementation starts.
2. **Given** a completed planning flow, **When** the summary is shown, **Then** it identifies the key artifact paths for the specification, plan, tasks, and iteration execution plan, or clearly states if any expected artifact is not available.
3. **Given** a completed planning flow, **When** the summary is shown, **Then** the summary explains the intended execution shape in compact language without requiring the developer to read every artifact first.
4. **Given** the stack-aware quality-bar capability is active for the feature, **When** the post-planning summary is shown, **Then** it surfaces the active quality profile, active required quality gates and lenses, and any not-applicable items with rationale in the same review checkpoint.

---

### User Story 2 - Decide the next step before implementation (Priority: P1)

A human developer reviewing the finished plan wants clear control over what happens next: review the plan in detail, ask questions, request changes, regenerate planning artifacts if needed, or explicitly approve implementation when satisfied.

**Why this priority**: Human approval is the core governance safeguard. Without a clear approval gate and guided next actions, the summary would be informational but not controlling.

**Independent Test**: After a successful planning flow, verify that implementation remains blocked until the user explicitly approves it and that Specrew suggests clear next actions for review, questions, and plan changes.

**Acceptance Scenarios**:

1. **Given** the post-planning summary has been shown, **When** the user reviews the summary without giving implementation approval, **Then** Specrew does not start implementation.
2. **Given** the post-planning summary has been shown, **When** the user asks a question or requests to inspect the full plan, **Then** Specrew treats that as review activity and keeps implementation blocked.
3. **Given** the post-planning summary has been shown, **When** the user is ready to proceed, **Then** Specrew requires an explicit go-ahead before invoking implementation.
4. **Given** the post-planning summary has been shown, **When** Specrew suggests next actions, **Then** the suggestions include a small set of likely prompts such as showing the full plan, changing a requirement, changing the plan, regenerating tasks, or starting implementation.

---

### User Story 3 - Replan safely after review feedback (Priority: P2)

While reviewing the summary, a human developer may decide that requirements or planning decisions need to change. They want Specrew to route those requests through the correct replanning path so the artifacts remain consistent and implementation stays blocked until the updated plan is reviewed and approved.

**Why this priority**: The review checkpoint only preserves governance if change requests trigger the right artifact updates and a fresh approval cycle instead of letting stale plans move straight into implementation.

**Independent Test**: After a successful planning flow, request both a requirement change and a plan-only change, and verify that each request triggers the correct artifact regeneration path, re-runs the necessary planning gates, re-presents the updated summary, and still requires renewed approval before implementation.

**Acceptance Scenarios**:

1. **Given** the developer changes a requirement after planning, **When** Specrew processes the request, **Then** it routes back through the relevant specification, clarification, planning, and task-generation steps so the artifacts stay aligned.
2. **Given** the developer changes the plan without changing requirements, **When** Specrew processes the request, **Then** it reruns planning, task generation, and the required planning governance gates without forcing unnecessary requirement edits.
3. **Given** replanning completes successfully, **When** the updated planning artifacts are ready, **Then** Specrew presents an updated post-planning summary and continues to block implementation until the user explicitly approves the new plan.
4. **Given** the developer expresses a change request in natural language, **When** Specrew interprets the request, **Then** it routes the request to the correct replanning path or asks for a minimal clarification before changing artifacts.

---

### Edge Cases

- Planning or task generation fails, or a required planning governance gate fails; Specrew must not present the feature as ready for implementation.
- One of the expected planning artifacts is unavailable or not regenerated; the summary must clearly surface that state instead of implying a complete plan set.
- The user asks for a change in natural language that could mean either a requirement change or a plan-only change; Specrew must avoid silently choosing the wrong replanning path.
- The user previously approved implementation for an earlier plan, but the plan changed afterward; the earlier approval must not carry forward to the updated plan.
- The user asks a question or requests review-only detail repeatedly without ever approving; implementation must remain blocked until a clear go-ahead is given.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When planning, task generation, and the relevant planning governance gates succeed, Specrew MUST automatically present a post-planning review checkpoint before implementation begins.
- **FR-002**: The post-planning review checkpoint MUST include a compact summary of the resulting plan that helps a human developer understand the expected execution shape without first opening multiple artifacts. The summary SHOULD remain roughly scannable in a conventional terminal, such as fitting within about 40 lines on an 80x24 display or an equivalent concise bound.
- **FR-003**: The post-planning summary MUST identify the key artifact paths for the specification, plan, tasks, and iteration execution plan, and it MUST clearly surface when any expected artifact is unavailable.
- **FR-003a**: If the stack-aware quality-bar capability is active for the feature, the post-planning summary MUST also surface the active quality profile, the active required quality gates and bug-hunter lenses, and any quality dimensions or lenses marked not applicable together with their recorded rationale.
- **FR-004**: The post-planning summary MUST state that the user can review the plan, ask questions, request changes, regenerate planning artifacts where appropriate, or explicitly approve implementation.
- **FR-005**: Specrew MUST NOT start implementation automatically when planning completes successfully.
- **FR-006**: Specrew MUST require an explicit user approval that occurs after the latest successful post-planning summary before invoking implementation. Implementation approval MUST use a narrow deterministic form such as a dedicated command, a fixed approval phrase, or an explicit confirmation prompt; ambiguous natural-language statements MUST NOT be treated as approval.
- **FR-007**: If the user reviews artifacts, asks questions, or requests more detail without giving approval, Specrew MUST keep implementation blocked and treat those interactions as part of the review checkpoint.
- **FR-008**: The post-planning review checkpoint MUST suggest a small set of likely next actions, including reviewing the full plan, changing a requirement, changing the plan, regenerating tasks, and starting implementation.
- **FR-009**: If the user changes a requirement after planning, Specrew MUST route the request through the relevant specification, clarification, planning, and task-generation steps so the resulting artifacts remain consistent.
- **FR-010**: If the user changes the plan without changing requirements, Specrew MUST rerun planning, task generation, and the required planning governance gates while preserving unchanged requirements. In the minimum standalone form for this feature, those required gates are the planning-governance checks that run immediately before plan generation and immediately after task generation.
- **FR-011**: After any successful replanning cycle, Specrew MUST present the updated post-planning summary again, MUST invalidate any prior implementation approval for that feature, and MUST continue blocking implementation until the user explicitly approves the updated plan.
- **FR-012**: When a post-planning user request is expressed in natural language, Specrew MUST interpret whether it is a review action, a requirement change, a plan change, or a task-regeneration request, and MUST ask for a minimal clarification before acting when the intent is not safely distinguishable. Implementation approval requests are governed by FR-006's explicit approval form rather than inferred from ambiguous language.
- **FR-013**: This feature MUST preserve Spec Kit as the source workflow and artifact system for specification, planning, and task artifacts.
- **FR-014**: This feature MUST remain bounded to the post-planning review, approval, and replanning loop and MUST NOT expand into intake hardening, general escalation redesign, or implementation-phase changes beyond the approval gate and replanning loop.
- **FR-015**: Replanning performed under this feature MUST update the active feature's planning surfaces without rewriting already-closed iteration directories. If the workflow needs new execution planning after a closed iteration exists, it MUST create forward-going iteration artifacts rather than mutating closed snapshots.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-001 through FR-004, FR-003a, and FR-013.
- **TG-002**: User Story 2 MUST be covered by FR-004 through FR-008.
- **TG-003**: User Story 3 MUST be covered by FR-009 through FR-012, FR-014, and FR-015.
- **TG-004**: Every implementation start after planning MUST be traceable to an explicit user approval that occurred after the latest successful post-planning summary.
- **TG-005**: Every post-planning change request MUST be traceable as either a requirement change path or a plan-only change path, including which planning artifacts and governance gates were rerun.
- **TG-006**: The post-planning review checkpoint MUST make human control explicit by showing that review, questions, changes, and approval are all valid next steps.

### Requirement Ownership & Delivery Windows

| Requirement | Expected owner role(s) | Intended delivery window |
| --- | --- | --- |
| FR-001 to FR-004, FR-003a | Specrew coordinator, human developer | Immediate handoff after successful planning completion |
| FR-005 to FR-008 | Specrew coordinator, human developer | Review checkpoint before any implementation invocation |
| FR-009 to FR-012 | Specrew coordinator, Spec Steward, Planner, human developer | Replanning loop triggered during post-planning review |
| FR-013 to FR-015 | Spec Steward, iteration facilitator | Ongoing governance for this feature slice |

### Non-Goals

- Redesigning how requirements are gathered before specification starts.
- Replacing Spec Kit artifacts or commands with a separate planning system.
- General escalation-policy redesign outside the post-planning review checkpoint.
- Changing implementation-phase behavior beyond blocking start until explicit approval and re-running the review loop after replanning.

### Key Entities *(include if feature involves data)*

- **Post-Planning Summary**: The concise review artifact shown automatically after successful planning, containing the execution shape, readiness context, and key artifact paths.
- **Planning Artifact Set**: The current authoritative collection of specification, plan, tasks, and iteration-execution-plan artifacts associated with the feature being reviewed.
- **Iteration Execution Plan**: The Specrew-managed iteration plan artifact for the active feature, typically located under `specs/<feature>/iterations/<NNN>/plan.md`. In workflows where it does not yet exist, the summary must explicitly say so rather than implying a complete artifact set.
- **Implementation Approval Decision**: The explicit human go-ahead that authorizes implementation after the latest successful post-planning summary.
- **Replanning Request**: A user instruction made during review that asks Specrew to change requirements, alter the plan, regenerate tasks, or otherwise update planning artifacts before implementation.
- **Review Checkpoint State**: The current post-planning status showing whether the latest plan is under review, awaiting clarification, or approved for implementation.
- **Specrew Coordinator**: The orchestration layer that manages the post-planning checkpoint, routes review and replanning actions, and enforces the approval gate. It is a workflow responsibility, not a new baseline team member role.

### Change Classification Examples

- **Clearly requirement change**:
  - "Replace database X with Y."
  - "Add deployment as a supported requirement."
  - "This feature must also support offline editing."
- **Clearly plan-only change**:
  - "Move T-204 before T-203."
  - "Regenerate the tasks with a different execution order."
  - "Split this plan into two smaller implementation slices without changing the requirements."
- **Ambiguous and requires clarification**:
  - "This will not work because of X."
  - "Add a deployment task."
  - "Use a different code style."

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of successful planning runs, Specrew presents the post-planning summary before any implementation invocation is allowed.
- **SC-002**: In 100% of post-planning implementation attempts, implementation starts only after an explicit user approval recorded after the latest successful plan summary.
- **SC-003**: In representative user validation sessions, at least 90% of developers can identify where to find the specification, plan, tasks, and iteration execution plan within 30 seconds of seeing the summary.
- **SC-003a**: In representative validation sessions where the stack-aware quality-bar capability is active, 100% of post-planning summaries surface the active quality profile, required quality gates and lenses, and any not-applicable items with rationale before implementation approval is accepted.
- **SC-004**: In representative user validation sessions, at least 90% of developers can correctly choose a next step from the summary guidance without consulting separate workflow documentation.
- **SC-005**: In representative replanning tests, 100% of requirement changes follow the specification-to-tasks regeneration path, 100% of plan-only changes rerun planning and task generation with the required governance gates, and implementation remains blocked until renewed approval in every case.
- **SC-006**: In representative validation runs, 100% of implementation approvals are expressed through the explicit approval form, and 0 ambiguous natural-language review statements are accepted as implementation approval.
- **SC-007**: In representative review sessions, at least 90% of post-planning summaries stay within the intended compact bound for terminal presentation.

## Assumptions

- Specrew already knows when planning, task generation, and the relevant planning governance gates have succeeded for a feature.
- The planning workflow continues to produce authoritative Spec Kit artifacts that can be referenced directly in a compact summary.
- Users may express review questions and change requests in natural language, but implementation approval can be constrained to an explicit narrow form.
- This feature targets Specrew-managed projects. When the iteration execution plan is absent, the summary can surface that absence explicitly without redefining the workflow.
- If Spec 002 (planning-flow hardening) ships first, this feature can reuse its named planning-governance gates directly; if not, FR-010's minimum gate definition is sufficient for standalone implementation.
- This feature does not redefine delegated routing policy; replanning work continues to follow the repository's existing routing/governance policy.
- If the default-specialty-pairing feature is also active, the post-planning review checkpoint should remain a single surface that includes team composition, pairing exceptions, and team approval scope alongside plan readiness. A single explicit approval may cover both plan and team when both are presented together.
- If the stack-aware quality-bar feature is also active, the quality profile, required gates and lenses, and any not-applicable-with-rationale items already exist in planning artifacts and can be surfaced additively in the same post-planning review checkpoint.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Maintains the integrity of the post-planning review rules, ensures replanning paths preserve artifact consistency, and protects the boundary that Spec Kit remains authoritative.
- **Iteration Facilitator**: Confirms that successful planning ends in a human review checkpoint rather than automatic implementation and decides whether any newly discovered scope belongs in a separate follow-on feature.
- **Capacity Model**: One bounded governance and UX slice focused on the handoff between successful planning and approved implementation.
- **Drift Signals**: Implementation starting without a fresh approval, summaries that omit key artifact paths, summaries that omit the active quality profile or required quality gates and lenses when that capability is active, replanning that does not regenerate the required artifacts, or stale approvals being reused after plan changes.
- **Human Oversight Points**: Human review of the summary, human choice to inspect or question the plan, human review of surfaced quality-governance expectations when active, human decision to request replanning, and explicit human approval after the latest successful post-planning summary.
