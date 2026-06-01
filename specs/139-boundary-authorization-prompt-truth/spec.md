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

**Independent Test**: Inspect generated coordinator instructions and stop templates to confirm they require the six human re-entry sections and one to three contextual, decision-reducing discussion prompts.

**Acceptance Scenarios**:

1. **Given** a generated human-judgment boundary stop, **When** the coordinator emits its handoff, **Then** it includes `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`.
2. **Given** a clarify-to-plan stop, **When** the coordinator emits its handoff, **Then** it explains that planning will convert the spec into architecture and task direction and asks whether the spec should be corrected, constrained, expanded, or discussed before planning.
3. **Given** a stop with a known decision, tradeoff, package choice, risk, or uncertainty, **When** prompts are generated, **Then** at least one prompt targets that issue rather than only asking for generic approval.
4. **Given** a stop with no known specific dilemma, **When** prompts are generated, **Then** the packet asks a general review question such as "Before I plan from this spec, is there anything you want corrected, constrained, expanded, or discussed?"

---

### User Story 3 - Regression Coverage Blocks Backsliding (Priority: P2)

As a release maintainer, I need tests or validator checks that catch prompt-truth regressions and thin boundary handoffs before another beta smoke bypasses a human-judgment boundary.

**Why this priority**: The failing behavior was user-visible in beta smoke and must be prevented by automated checks before beta3.

**Independent Test**: Run focused regression tests against prompt generation and handoff compliance fixtures, including a beta2-bad prompt seed.

**Acceptance Scenarios**:

1. **Given** a beta2-bad prompt fixture containing `only gate that HARD-BLOCKS`, **When** prompt regression tests run, **Then** the fixture is rejected.
2. **Given** a prompt that says to `continue automatically through` plan and tasks while human-judgment boundaries are configured, **When** tests run, **Then** the prompt is rejected.
3. **Given** a boundary handoff that only says "approve to continue", **When** compliance tests or reviewer instructions evaluate it, **Then** it is non-compliant because it lacks review targets, next-step preview, or discussion affordance.
4. **Given** a boundary handoff without `Why I stopped`, **When** compliance tests or reviewer instructions evaluate it, **Then** it is non-compliant because it does not tell the human exactly why the agent stopped.
5. **Given** a boundary handoff whose discussion prompts lack context, **When** there is a known decision, assumption, risk, tradeoff, or unclear future direction, **Then** it is non-compliant unless it uses the general no-known-dilemma review question.

---

### Edge Cases

- Boundary policy is absent, incomplete, or missing `policy_classes`; the generated prompt must use a conservative fallback that does not understate human-judgment boundaries.
- Autonomous mode or an explicit recorded authorization exists; the prompt may explain the exception without erasing the default human-judgment rule.
- A readiness helper emits only warnings; the prompt must not describe those warnings as authorization to cross the next lifecycle boundary.
- An agent-authored artifact status repair attempts to set `Status: Approved`; generated guidance must steer agents to non-approval readiness wording unless a human verdict is recorded.
- Structured verdict menus are unavailable in a host; generated guidance must still preserve a free-form discussion or feedback path.
- A human gives free-form discussion or feedback without explicitly approving the next boundary; the coordinator must treat that as discussion, not authorization.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `specrew start` MUST NOT generate text claiming that only `before-implement`, `review-signoff`, `iteration-closeout`, and `feature-closeout` hard-block when configured boundary policy marks earlier boundaries as `human-judgment-required`.
- **FR-002**: Generated `last-start-prompt.md` MUST describe boundary authorization from the resolved `boundary_enforcement.policy_classes` snapshot, which MUST be derived from the authoritative `.specrew/config.yml` policy source rather than from a hard-coded four-gate list.
- **FR-003**: Generated instructions MUST NOT tell the coordinator to continue automatically from clarify through `before-plan`, `plan`, `tasks`, and `after-tasks` when `clarify -> plan` and `plan -> tasks` are human-judgment boundaries.
- **FR-004**: Generated instructions MUST require a boundary stop after clarify before plan generation unless autonomous mode or an explicit recorded authorization exists for `clarify -> plan`.
- **FR-005**: Generated instructions MUST distinguish readiness status from human approval; agent-authored readiness repairs MAY use wording such as `Ready for Planning` but MUST NOT set `Status: Approved` without a recorded human verdict.
- **FR-006**: Sync command docs, coordinator governance, and generated start prompt MUST agree on the same boundary vocabulary and authorization semantics.
- **FR-007**: Regression tests MUST fail if a generated start prompt contains the beta2-bad phrases `only gate that HARD-BLOCKS` or `continue automatically through` in a context that bypasses human-judgment boundaries.
- **FR-008**: Generated instructions MUST define the canonical human-judgment boundary stop as a human re-entry packet, not only an approval request.
- **FR-009**: Every human re-entry packet MUST include all six canonical sections: `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`.
- **FR-010**: The `What I just did` section MUST summarize the meaningful past outcome, including artifacts created or changed, committed evidence, decisions captured, assumptions added, scope changes, and notable risks or uncertainties discovered.
- **FR-011**: The `Why I stopped` section MUST name the exact lifecycle boundary and explain concretely why human judgment is required before the next step.
- **FR-012**: The `What needs your review` section MUST point to targeted review surfaces using bare `file:///` links and exact sections worth inspecting, high-impact choices, assumptions made, uncertainties, and what can be safely skimmed.
- **FR-013**: The `What happens next` section MUST preview the next lifecycle phase, artifacts to be produced, whether code will be written or only planning/tasks, which decisions become harder to change afterward, and the next expected boundary stop.
- **FR-014**: Every human re-entry packet MUST include one to three contextual, proactive, decision-reducing discussion prompts; prompts SHOULD surface decisions, assumptions, risks, tradeoffs, package choices, architectural dilemmas, or unclear future direction, and otherwise MUST use a general no-known-dilemma improvement question.
- **FR-015**: Each targeted discussion prompt SHOULD include the short context that triggered the question, the question, the recommended/default path when one exists, and the consequence of changing direction when relevant.
- **FR-016**: The `What I need from you` section MUST give the allowed response shapes: approve as-is, approve with added instructions, send back with requested changes, or discuss first / answer one of the prompts.
- **FR-017**: Approval MUST be explicit; free-form discussion or feedback MUST NOT be treated as approval unless the human clearly authorizes the next boundary.
- **FR-018**: Generated instructions MUST encourage short discussion before continuing when the human wants to refine scope, validate a tradeoff, or add instructions, and MUST NOT frame approval as the only normal path.
- **FR-019**: Structured verdict menus, when available, MUST include or preserve an affordance for discussion or free-form feedback before continuation.
- **FR-020**: Generated state MUST include the resolved `boundary_enforcement.policy_classes` snapshot used by the prompt so the prompt, lifecycle state, and policy evidence can be audited together.
- **FR-021**: A narrow automated or validator check MUST flag `Status: Approved` in feature artifacts when no matching human verdict evidence exists.
- **FR-022**: Release closeout MUST include committed beta3 smoke evidence demonstrating the fixed clarify-to-plan stop, human re-entry packet, and absence of substantive `plan.md` before approval.
- **FR-023**: The future generated gate format MUST use the human re-entry packet as the primary stop contract and MUST NOT require duplicating the same stop with the legacy `=== SPECREW HANDOFF ===` block.
- **FR-024**: Primary packet review targets MUST include bare `file:///` links, not only relative paths or markdown links.
- **FR-025**: The `What needs your review` section MUST identify high-impact or release-blocking items, including the `Status: Approved` check and beta3 smoke evidence when they are in scope, rather than only listing task numbers.
- **FR-026**: `Discussion prompts` MUST be shown together and MUST tell the human they can answer any prompt that should change direction or approve with the defaults.
- **FR-027**: When the human chooses to discuss one prompt, generated guidance MUST instruct the agent to enter a short discussion loop for that item only, summarize the agreed decision, and ask again for explicit boundary approval. Free-form discussion remains non-approval unless the human clearly authorizes the boundary.
- **FR-028**: Response options MUST support approve as-is, approve with instructions, send back, and discuss prompt `#N`.

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
| FR-011 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-012 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-013 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-014 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-015 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-016 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-017 | Spec Steward, Reviewer | Iteration 001 |
| FR-018 | Spec Steward, Reviewer | Iteration 001 |
| FR-019 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-020 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-021 | Implementer, Reviewer | Iteration 001 |
| FR-022 | Implementer, Reviewer | Iteration 001 |
| FR-023 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-024 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-025 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-026 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-027 | Spec Steward, Implementer, Reviewer | Iteration 001 |
| FR-028 | Spec Steward, Implementer, Reviewer | Iteration 001 |
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
- **Human Re-entry Packet**: The required six-section stop packet and contextual discussion prompts emitted before a human-judgment boundary can proceed.
- **Verdict Evidence**: A recorded human authorization in the accepted durable evidence surfaces, such as `boundary_enforcement.verdict_history` or `.squad/decisions.md` when applicable.

## Human Re-entry Packet Contract *(mandatory)*

Boundary stops are human re-entry points. The generated coordinator guidance must ensure the human can understand what happened without opening every artifact, know exactly why the agent stopped, know what to review and where, understand what happens next if they approve, and easily discuss, refine, or add instructions before continuing. One approval advances at most one lifecycle boundary.

Every human-judgment boundary stop MUST emit this canonical packet:

### What I just did

Summarize the meaningful past outcome, not just file names. Include artifacts created or changed, committed evidence, decisions captured, assumptions added, scope changes, and notable risks or uncertainties discovered.

### Why I stopped

Name the exact lifecycle boundary and explain why human judgment is required before the next step. The explanation must be concrete, such as: "I stopped at clarify -> plan because planning will convert the spec into architecture and task direction, so spec mistakes become downstream work."

### What needs your review

Point the human to targeted review surfaces, not vague "read the artifact" directions. Include bare `file:///` links, exact sections worth inspecting, high-impact choices, assumptions the agent made, anything the agent is uncertain about, and what can be safely skimmed.

### What happens next

Preview the future if the human approves. Include the next lifecycle phase, what artifacts will be produced, whether code will be written or only planning/tasks, which decisions become harder to change afterward, and the next expected boundary stop.

### Discussion prompts

Ask one to three proactive prompts before asking for approval. These prompts must reduce the AI decision surface by inviting the human to refine, challenge, or confirm direction.

Each targeted prompt should include short context about the decision, assumption, or risk that triggered the question; the question itself; the recommended/default path when there is one; and the consequence of changing direction, if relevant.

If there is a known decision, tradeoff, package choice, architectural dilemma, risk, or uncertainty, ask targeted questions about it. If there is no known specific dilemma, ask a general review question such as: "Before I plan from this spec, is there anything you want corrected, constrained, expanded, or discussed?"

### What I need from you

Give the allowed response shapes: approve as-is, approve with added instructions, send back with requested changes, or discuss first / answer one of the prompts.

Approval must be explicit. Free-form discussion or feedback is not approval unless the human clearly authorizes the next boundary.

The future generated packet is the primary stop contract. It must not require duplicating the same stop with the legacy `=== SPECREW HANDOFF ===` block, although the legacy block can remain in current transitional behavior until this feature is implemented. The packet must show discussion prompts together and explicitly state: "You can answer any prompt that should change direction, or approve with the defaults." If the human chooses `discuss prompt #N`, the agent should discuss only that prompt, summarize the agreed decision, then request explicit boundary approval again.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A fresh generated `last-start-prompt.md` lists or summarizes every boundary configured as `human-judgment-required`, including `clarify` and `plan` under the default policy.
- **SC-002**: Prompt regression tests reject the beta2-bad phrases `only gate that HARD-BLOCKS` and `continue automatically through` when they imply bypassing human-judgment boundaries.
- **SC-003**: Generated lifecycle guidance explicitly states that `clarify -> plan` requires human authorization under the default policy.
- **SC-004**: Generated lifecycle guidance includes all six human re-entry packet section names, including `Why I stopped`.
- **SC-005**: A generated clarify-to-plan stop explains that planning will turn the spec into architecture/tasks and includes at least one proactive question inviting the human to correct, constrain, expand, or discuss the spec before planning.
- **SC-006**: A beta3 smoke for a fresh greenfield Copilot/Squad run stops after clarify, requests plan approval, emits the human re-entry packet, and does not create a substantive `plan.md` before approval.
- **SC-007**: Automated or reviewer checks catch an agent-authored `Status: Approved` artifact change when there is no matching recorded human verdict.
- **SC-008**: A stop packet without `Why I stopped` is rejected by tests or reviewer instructions as non-compliant.
- **SC-009**: A stop packet that asks only "approve?" without discussion prompts is rejected by tests or reviewer instructions as non-compliant.
- **SC-010**: A stop packet whose discussion prompts lack context is rejected unless no known dilemma exists and the packet uses the general no-known-dilemma review question.
- **SC-011**: Committed beta3 smoke evidence demonstrates the fixed clarify-to-plan stop and confirms no substantive `plan.md` exists before approval.
- **SC-012**: Generated future stop guidance uses the six-section packet as the primary stop contract and does not require legacy `=== SPECREW HANDOFF ===` duplication.
- **SC-013**: Generated packet guidance requires bare `file:///` review target links and highlights release-blocking review items such as `Status: Approved` evidence checks and beta3 smoke evidence.
- **SC-014**: Generated discussion-prompt guidance shows prompts together, includes the "approve with the defaults" affordance, and supports `discuss prompt #N` as a response option.
- **SC-015**: Generated discussion-loop guidance says a prompt-specific discussion must end with a summarized decision and a renewed request for explicit boundary approval.

## Assumptions

- The current default downstream boundary policy treats all canonical lifecycle boundaries as `human-judgment-required` unless explicitly configured otherwise.
- `.specrew/config.yml` remains the authoritative boundary policy source.
- `start-context.json` must include the resolved `boundary_enforcement.policy_classes` snapshot generated from `.specrew/config.yml`.
- This feature updates newly generated prompts and related prompt-generation tests; historical handoff migration remains out of scope.
- The fix should be small enough for one iteration and should not introduce hook-based runtime enforcement.
- Host-specific structured menus can vary, but the generated instructions must preserve discussion/free-text affordance where available.

## Clarifications

### Session 2026-06-01

- Q: Should implementation add `boundary_enforcement.policy_classes` into generated `start-context.json`, or is reading `.specrew/config.yml` during prompt generation sufficient? A: `.specrew/config.yml` remains the authoritative policy source, and `start-context.json` must include the resolved `boundary_enforcement.policy_classes` snapshot.
- Q: For `Status: Approved` without human verdict evidence, should this feature include a validator-level check or only prompt guidance and regression tests? A: Include a narrow check for `Status: Approved` without human verdict evidence.
- Q: For beta3 smoke evidence, should acceptance require committed downstream smoke evidence or only documented manual smoke results? A: Require committed beta3 smoke evidence.
- Q: What is the canonical human re-entry packet shape? A: Use the six-section packet: `What I just did`, `Why I stopped`, `What needs your review`, `What happens next`, `Discussion prompts`, and `What I need from you`.
- Q: What scope limits remain binding? A: Keep full Proposal 150, hook enforcement, and broad historical Proposal 151 migration out of scope.
- Q: Should the future generated gate format duplicate the packet with the legacy `=== SPECREW HANDOFF ===` block? A: No. The human re-entry packet is the primary future stop contract. The legacy block is acceptable only as current transitional behavior before this feature is implemented.
- Q: What response options and prompt behavior should the final generated packet support? A: It must support approve as-is, approve with instructions, send back, and discuss prompt `#N`; discussion prompts must be shown together with a note that the human can answer any prompt that should change direction or approve with the defaults.
- Q: What happens after a human discusses one prompt? A: The agent should run a short discussion loop for that prompt only, summarize the agreed decision, then ask again for explicit boundary approval. Free-form discussion is not approval unless the human clearly authorizes the boundary.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns boundary vocabulary, prompt semantics, scope boundaries, and clarification of policy-source truth.
- **Iteration Facilitator**: Planner coordinates one tight iteration and stops for human approval at the clarify-to-plan boundary before substantive planning.
- **Capacity Model**: 5-8 SP feature, planned as one iteration with capacity confirmed before implementation.
- **Drift Signals**: Drift is indicated by any mismatch between configured policy, sync command docs, generated prompt text, tests, and reviewer evidence.
- **Human Oversight Points**: Human review is required after clarify before planning, after plan before tasks if the active policy requires it, before implementation, at review signoff, at iteration closeout, and at feature closeout.
