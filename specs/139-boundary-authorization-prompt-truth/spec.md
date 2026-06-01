# Feature Specification: Boundary Authorization Prompt Truth + Human Re-entry Packet

**Feature Branch**: `139-boundary-authorization-prompt-truth`
**Created**: 2026-06-01
**Status**: Draft
**Input**: User description: "Implement Proposal 154: Boundary Authorization Prompt Truth + Human Re-entry Packet."
**Source Proposal**: [Proposal 154](file:///C:/tmp/Specrew-main-boundary-auth/proposals/154-boundary-authorization-prompt-truth.md)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generated Prompt Tells the Boundary Truth (Priority: P1)

As a Specrew coordinator agent starting in a fresh project, I need the generated start prompt to describe human-judgment boundary stops from the configured boundary policy so that I stop at the same lifecycle boundaries the durable governance model requires.

**Why this priority**: The beta2 smoke failure came from generated lifecycle instructions that told agents only four gates hard-block and encouraged automatic continuation from clarify into plan/tasks.

**Independent Test**: Generate or inspect a fresh `last-start-prompt.md` and verify it derives human-judgment boundaries from boundary policy, explicitly covers `clarify -> plan`, and does not contain the beta2-bad four-gate or auto-chain instructions.

**Acceptance Scenarios**:

1. **Given** a downstream project whose boundary policy marks `clarify` and `plan` as `human-judgment-required`, **When** `specrew start` generates `last-start-prompt.md`, **Then** the prompt states that `clarify -> plan` requires human authorization before plan generation.
2. **Given** the generated prompt, **When** a coordinator reads its lifecycle guidance, **Then** it does not claim that only `before-implement`, `review-signoff`, `iteration-closeout`, and `feature-closeout` hard-block.
3. **Given** readiness helpers such as `before-plan` and `after-tasks`, **When** their warning/readiness behavior is described, **Then** the prompt still distinguishes readiness from human authorization for the next lifecycle boundary.

---

### User Story 2 - Boundary Stops Re-enter the Human Cleanly (Priority: P1)

As a human developer reviewing a lifecycle boundary stop, I need a compact packet that summarizes what happened, points me to what to inspect, previews what changes after approval, and invites discussion before continuation.

**Why this priority**: Stopping at the right boundary is insufficient if the stop only asks for approval and does not help the human refine the artifact or future direction.

**Independent Test**: Inspect generated coordinator instructions and stop templates to confirm they require the five human re-entry sections and one to three proactive discussion prompts.

**Acceptance Scenarios**:

1. **Given** a generated human-judgment boundary stop, **When** the coordinator emits its handoff, **Then** it includes `What I just did`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`.
2. **Given** a clarify-to-plan stop, **When** there is no known technical dilemma, **Then** the discussion prompts include a general improvement question inviting the human to correct, constrain, or expand the spec before planning.
3. **Given** a stop with a known decision, tradeoff, package choice, risk, or uncertainty, **When** prompts are generated, **Then** at least one prompt targets that issue rather than only asking for generic approval.

---

### User Story 3 - Regression Coverage Blocks Backsliding (Priority: P2)

As a release maintainer, I need tests or validator checks that catch prompt-truth regressions and thin boundary handoffs before another beta smoke bypasses a human-judgment boundary.

**Why this priority**: The failing behavior was user-visible in beta smoke and must be prevented by automated checks before beta3.

**Independent Test**: Run focused regression tests against prompt generation and handoff compliance fixtures, including a beta2-bad prompt seed.

**Acceptance Scenarios**:

1. **Given** a beta2-bad prompt fixture containing `only gate that HARD-BLOCKS`, **When** prompt regression tests run, **Then** the fixture is rejected.
2. **Given** a prompt that says to `continue automatically through` plan and tasks while human-judgment boundaries are configured, **When** tests run, **Then** the prompt is rejected.
3. **Given** a boundary handoff that only says "approve to continue", **When** compliance tests or reviewer instructions evaluate it, **Then** it is non-compliant because it lacks review targets, next-step preview, or discussion affordance.

---

### Edge Cases

- Boundary policy is absent, incomplete, or missing `policy_classes`; the generated prompt must use a conservative fallback that does not understate human-judgment boundaries.
- Autonomous mode or an explicit recorded authorization exists; the prompt may explain the exception without erasing the default human-judgment rule.
- A readiness helper emits only warnings; the prompt must not describe those warnings as authorization to cross the next lifecycle boundary.
- An agent-authored artifact status repair attempts to set `Status: Approved`; generated guidance must steer agents to non-approval readiness wording unless a human verdict is recorded.
- Structured verdict menus are unavailable in a host; generated guidance must still preserve a free-form discussion or feedback path.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `specrew start` MUST NOT generate text claiming that only `before-implement`, `review-signoff`, `iteration-closeout`, and `feature-closeout` hard-block when configured boundary policy marks earlier boundaries as `human-judgment-required`.
- **FR-002**: Generated `last-start-prompt.md` MUST describe boundary authorization from `boundary_enforcement.policy_classes` or its configured policy source rather than from a hard-coded four-gate list.
- **FR-003**: Generated instructions MUST NOT tell the coordinator to continue automatically from clarify through `before-plan`, `plan`, `tasks`, and `after-tasks` when `clarify -> plan` and `plan -> tasks` are human-judgment boundaries.
- **FR-004**: Generated instructions MUST require a boundary stop after clarify before plan generation unless autonomous mode or an explicit recorded authorization exists for `clarify -> plan`.
- **FR-005**: Generated instructions MUST distinguish readiness status from human approval; agent-authored readiness repairs MAY use wording such as `Ready for Planning` but MUST NOT set `Status: Approved` without a recorded human verdict.
- **FR-006**: Sync command docs, coordinator governance, and generated start prompt MUST agree on the same boundary vocabulary and authorization semantics.
- **FR-007**: Regression tests MUST fail if a generated start prompt contains the beta2-bad phrases `only gate that HARD-BLOCKS` or `continue automatically through` in a context that bypasses human-judgment boundaries.
- **FR-008**: Generated instructions MUST define the canonical human-judgment boundary stop as a human re-entry packet, not only an approval request.
- **FR-009**: Every human re-entry packet MUST summarize the past outcome, identify review targets, preview the next phase, and ask for approve / approve-with-instructions / send-back / discuss-first input.
- **FR-010**: Every human re-entry packet MUST include one to three proactive discussion prompts; prompts SHOULD be specific when there is a known decision, tradeoff, package choice, risk, or uncertainty, and otherwise MUST ask a general improvement question.
- **FR-011**: Generated instructions MUST encourage short discussion before continuing when the human wants to refine scope, validate a tradeoff, or add instructions, and MUST NOT frame approval as the only normal path.
- **FR-012**: Structured verdict menus, when available, MUST include or preserve an affordance for discussion or free-form feedback before continuation.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
- **TG-005**: Planning and review MUST preserve the explicit out-of-scope boundaries: no full Proposal 150, no hook-based runtime enforcement, no broad historical handoff migration from Proposal 151, and no lifecycle model redesign beyond generated prompt truth and the new-prompt stop contract.
- **TG-006**: Review MUST include a gap ledger that classifies lifecycle/governance behavior as implemented, enforced, observable, and documented.

### Requirement Ownership

| Requirement | Owner Role(s) | Delivery Window |
| --- | --- | --- |
| FR-001 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-002 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-003 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-004 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-005 | Spec Steward, Reviewer | Iteration 001 |
| FR-006 | Spec Steward, Planner, Reviewer | Iteration 001 |
| FR-007 | Implementer, Reviewer | Iteration 001 |
| FR-008 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-009 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-010 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-011 | Spec Steward, Reviewer | Iteration 001 |
| FR-012 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| TG-001 | Planner, Reviewer | Iteration 001 |
| TG-002 | Planner, Reviewer | Iteration 001 |
| TG-003 | Planner, Reviewer | Iteration 001 |
| TG-004 | Spec Steward, Reviewer | Iteration 001 |
| TG-005 | Spec Steward, Reviewer | Iteration 001 |
| TG-006 | Reviewer | Iteration 001 |

### Key Entities *(include if feature involves data)*

- **Boundary Policy Class**: A configured lifecycle classification, such as `human-judgment-required`, that determines whether a transition needs a human verdict.
- **Boundary Transition**: A requested movement from one lifecycle boundary to the next, such as `clarify -> plan` or `plan -> tasks`.
- **Start Prompt Lifecycle Guidance**: The generated instructions in `last-start-prompt.md` that tell host agents how to interpret lifecycle stops and authorization.
- **Human Re-entry Packet**: The required stop packet sections and discussion prompts emitted before a human-judgment boundary can proceed.
- **Verdict Evidence**: A recorded human authorization in the accepted durable evidence surfaces, such as `boundary_enforcement.verdict_history` or `.squad/decisions.md` when applicable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A fresh generated `last-start-prompt.md` lists or summarizes every boundary configured as `human-judgment-required`, including `clarify` and `plan` under the default policy.
- **SC-002**: Prompt regression tests reject the beta2-bad phrases `only gate that HARD-BLOCKS` and `continue automatically through` when they imply bypassing human-judgment boundaries.
- **SC-003**: Generated lifecycle guidance explicitly states that `clarify -> plan` requires human authorization under the default policy.
- **SC-004**: Generated lifecycle guidance includes all five human re-entry packet section names.
- **SC-005**: A generated clarify-to-plan stop includes at least one proactive question inviting the human to correct, constrain, expand, or discuss the spec before planning.
- **SC-006**: A beta3 smoke for a fresh greenfield Copilot/Squad run stops after clarify, requests plan approval, emits the human re-entry packet, and does not create a substantive `plan.md` before approval.
- **SC-007**: Automated or reviewer checks catch an agent-authored `Status: Approved` artifact change when there is no matching recorded human verdict.

## Assumptions

- The current default downstream boundary policy treats all canonical lifecycle boundaries as `human-judgment-required` unless explicitly configured otherwise.
- `boundary_enforcement.policy_classes` is the target generated state surface, but implementation may need to read from `.specrew/config.yml` and project the policy into start context if that field is not currently emitted.
- This feature updates newly generated prompts and related prompt-generation tests; historical handoff migration remains out of scope.
- The fix should be small enough for one iteration and should not introduce hook-based runtime enforcement.
- Host-specific structured menus can vary, but the generated instructions must preserve discussion/free-text affordance where available.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns boundary vocabulary, prompt semantics, scope boundaries, and clarification of policy-source truth.
- **Iteration Facilitator**: Planner coordinates one tight iteration and stops for human approval at the clarify-to-plan boundary before substantive planning.
- **Capacity Model**: 5-8 SP feature, planned as one iteration with capacity confirmed before implementation.
- **Drift Signals**: Drift is indicated by any mismatch between configured policy, sync command docs, generated prompt text, tests, and reviewer evidence.
- **Human Oversight Points**: Human review is required after clarify before planning, after plan before tasks if the active policy requires it, before implementation, at review signoff, at iteration closeout, and at feature closeout.
