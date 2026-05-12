# Feature Specification: Handoff Format Scoping

**Feature Branch**: `014-handoff-format-scoping`  
**Created**: 2026-05-12  
**Status**: Draft  
**Input**: User description: "Open the next feature from the source draft at `C:\Temp\handoff-format-scoping.md`, create it as `014-handoff-format-scoping`, and keep the source scope intact."

## Problem Statement

Specrew's human-facing handoff format currently applies the three-section stop-message structure too broadly. A format intended for genuine human-blocked stop points is being reused for in-flight progress transitions, which creates false "stop" claims and repeated "nothing yet" user-action sections that add noise without helping the developer decide what to do next.

This feature refines the scope of that handoff rule so Squad clearly distinguishes between:

- a **final stop message**, where the human is now the blocker and an action is required, and
- an **in-flight progress update**, where Squad is still actively working and no human action is needed yet.

## Scope Boundaries

### In Scope

- Distinguishing final stop messages from in-flight progress updates in Squad's coordinator-facing governance guidance.
- Defining the required format for each response type.
- Adding soft-warning detection for empty or placeholder user-action sections.
- Adding soft-warning detection for transitional narration presented as a stop.
- Updating related governance guidance, examples, templates, and corpus rows so the scoping rule is consistent across prompt, template, validator, and quality artifacts.
- Extending the existing handoff identifier-context rule so its scope clearly covers both final stop messages and in-flight progress updates.

### Out of Scope

- Changing the underlying three-section stop-message format itself.
- Changing tool-call output rendering or Copilot-rendered result blocks.
- Converting these rules from soft warnings into hard validator failures.
- Real-time interruption or token-stream monitoring while Squad is still generating a response.
- Extending this rule to unrelated agent-to-human handoff formats beyond Squad's governed coordinator-response pattern.

## Relationship to Existing Features

- **Feature 007 — user-facing progress handoff**: Established the three-section stop-message format that this feature now scopes more precisely.
- **Feature 012 — descriptive ID handoffs**: Introduced the `human-handoff-id-context` corpus row whose applicability now needs clearer wording.
- **Feature 013 — validator hardening**: Established the hardened validator and test discipline this refinement builds on.

## Clarifications

### Session 2026-05-12

- Q: Should first-response acknowledgements be exempt from the new warning rules when they conventionally say no user action is needed? → A: [NEEDS CLARIFICATION: Should session-opening acknowledgement responses be exempt from the new scoping warnings, or must they follow the same stop-vs-progress distinction as every other response?]
- Q: Which authored responses are in scope for the rule? → A: [NEEDS CLARIFICATION: Does this feature govern only the coordinator's top-level response, or every Squad-authored response shown to the human, including sub-agent narration?]
- Q: How should placeholder user-action phrases be governed? → A: [NEEDS CLARIFICATION: Should placeholder phrases such as "Nothing yet," "No action needed," and "Stand by" come from a fixed repository-maintained list or a human-extensible configuration surface?]

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use the right response type (Priority: P1)

A human developer receives a genuine stop message only when their action is actually required, while ordinary progress transitions remain short in-flight updates.

**Why this priority**: The main problem is daily workflow noise. Correctly scoping the response type immediately improves every session.

**Independent Test**: Review governed response examples and synthetic scenarios showing both a human-blocked stop and an in-flight transition, then confirm each uses the correct format and wording.

**Acceptance Scenarios**:

1. **Given** Squad has completed a work segment and cannot continue until the human authorizes the next lifecycle step, **When** Squad responds, **Then** it uses the three-section stop-message format and each section contains substantive content.
2. **Given** Squad is still mid-work and is waiting on a background validation, sub-agent, or internal transition, **When** Squad responds, **Then** it emits a single-line progress update instead of the three-section stop-message format.

---

### User Story 2 - Detect handoff-format misuse (Priority: P1)

A human developer reviewing validator output is warned when Squad uses the three-section stop-message format with an empty user-action section or with transitional narration disguised as a stop.

**Why this priority**: Prompt guidance alone is not enough; the misuse must also be detectable so recurring noise patterns can be corrected and tracked.

**Independent Test**: Run governed fixtures that include both violating and compliant responses and verify the validator emits warnings only for the violating cases.

**Acceptance Scenarios**:

1. **Given** a Squad-authored response uses the three-section format and the user-action section is empty or contains placeholder text, **When** the validator checks the response, **Then** it emits `soft-warning.empty-user-action-section`.
2. **Given** a Squad-authored response uses "Why I stopped" to describe an in-flight wait or transition rather than a true human-blocked stop, **When** the validator checks the response, **Then** it emits `soft-warning.transitional-stop-claim`.
3. **Given** a Squad-authored response is a legitimate stop message with a concrete human action, **When** the validator checks the response, **Then** it does not emit either new soft warning.

---

### User Story 3 - Keep governance artifacts aligned (Priority: P2)

A governance maintainer can trace the scoping rule consistently across the coordinator guidance, handoff template, corpus rows, and integration fixtures without conflicting interpretations.

**Why this priority**: The refinement will drift quickly if prompt, validator, template, and corpus artifacts disagree about when the stop-message format applies.

**Independent Test**: Compare the prompt guidance, template examples, corpus-row wording, and known-traps entry for the same synthetic scenarios and confirm they classify the response types consistently.

**Acceptance Scenarios**:

1. **Given** a maintainer reviews the coordinator guidance and handoff template, **When** they inspect the worked examples, **Then** each response type is shown with the correct format and rationale.
2. **Given** a maintainer reviews the handoff identifier-context corpus row and the known-traps catalog, **When** they inspect the updated applicability text, **Then** both final stop messages and in-flight progress updates are unambiguously covered.

---

### Edge Cases

- A legitimate stop message may contain a very short but still substantive user action, such as a brief approval request; the warning rules must not treat brevity alone as misuse.
- A single response may contain both a transitional status update and a genuine human blocker; the guidance must make clear which response type should win in mixed cases.
- Session-opening acknowledgements may currently use conventional no-action wording and need an explicit rule boundary before planning proceeds.
- Sub-agent-authored narrative text may surface to the human developer and needs a clear inclusion or exclusion boundary.
- Placeholder phrases may evolve over time, so warning logic must remain understandable enough for humans to verify why a warning fired.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define two governed response types for Squad's human-facing coordination output: **final stop message** and **in-flight progress update**. A final stop message applies only when the human is the bottleneck for the next lifecycle step and MUST use the existing three-section format with substantive content in all three sections. An in-flight progress update applies when Squad is still actively working, waiting on a background process, or transitioning between work stages and MUST omit the user-action section in favor of a concise progress note. **Owner role**: Governance prompt stewards. **Delivery window**: Iteration 1.
- **FR-002**: The system MUST update the coordinator governance guidance with explicit decision criteria for choosing between the two response types, including at least one worked example for each type and an explanation of why the chosen format is correct. **Owner role**: Governance prompt stewards. **Delivery window**: Iteration 1.
- **FR-003**: The system MUST update the governed handoff template so it captures both response types, includes explicit examples of correct usage, and preserves the existing three-section format unchanged for genuine stop points. **Owner role**: Handoff-template stewards. **Delivery window**: Iteration 1.
- **FR-004**: The system MUST emit `soft-warning.empty-user-action-section` when a governed Squad-authored response uses the three-section format but the "What I need from you" section is empty, contains a placeholder such as "Nothing yet" or "No action needed," or otherwise communicates no substantive human action. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1.
- **FR-005**: The system MUST emit `soft-warning.transitional-stop-claim` when a governed Squad-authored response uses "Why I stopped" to describe in-flight work, waiting, or transition-state narration rather than a true human-blocked stop, especially when no substantive human action is identified. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1.
- **FR-006**: The system MUST keep both new warning rules low-noise, advisory, and additive: warnings are evaluated per response, MUST NOT fire on legitimate substantive stop messages, and MUST preserve the existing soft-warning workflow rather than blocking the response. **Owner role**: Validator maintainers. **Delivery window**: Iteration 1.
- **FR-007**: The system MUST update the `human-handoff-id-context` corpus row so its scope-of-applicability explicitly covers both final stop messages and in-flight progress updates, removing ambiguity about whether transitional narration is in scope. **Owner role**: Governance corpus stewards. **Delivery window**: Iteration 1.
- **FR-008**: The system MUST record the pattern "three-section stop-message format misapplied to in-flight transitions" in the known-traps catalog as a validator-enforced governance trap with citations to the governing rules and proving tests. **Owner role**: Governance corpus stewards. **Delivery window**: Iteration 2.
- **FR-009**: The system MUST provide deterministic integration coverage for both new warning rules using violating and compliant fixtures, including at least one violating fixture and one compliant fixture per rule, and MUST calibrate the rules against a historical-response sample so false positives stay acceptably low. **Owner role**: Test maintainers and validator maintainers. **Delivery window**: Iteration 2.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001, FR-002, and FR-003.
- **TG-002**: User Story 2 maps to FR-004, FR-005, FR-006, and FR-009.
- **TG-003**: User Story 3 maps to FR-002, FR-003, FR-007, FR-008, and FR-009.
- **TG-004**: Any implementation choice made during planning for acknowledgement-message handling, scope-of-applicability, or placeholder-phrase governance MUST reconcile the open clarification decisions recorded in this specification before work begins.

### Key Entities *(include if feature involves data)*

- **Final Stop Message**: A human-facing Squad response where the human is the actual blocker for the next lifecycle step and the existing three-section format is required.
- **In-Flight Progress Update**: A human-facing Squad response sent while Squad is still actively working, waiting on background work, or transitioning between internal steps and therefore should not claim a true stop.
- **Empty User-Action Section Warning**: A soft-warning outcome that flags three-section messages whose user-action section contains no substantive request.
- **Transitional Stop Claim Warning**: A soft-warning outcome that flags three-section messages whose stop rationale is really a progress update.
- **Handoff Identifier-Context Rule**: The existing governance corpus rule whose applicability must clearly cover both governed response types.

## Non-Functional Constraints

- **NFR-001**: Warning emissions must remain advisory so validation still succeeds when only soft warnings are present.
- **NFR-002**: Warning logic must remain transparent enough for a human reviewer to understand what phrase or pattern caused the emission.
- **NFR-003**: The refinement must remain backward-compatible with the current validator's soft-warning reporting shape so downstream consumers do not require a workflow change.
- **NFR-004**: The refinement must not materially increase day-to-day validation friction for typical response volumes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After rollout, a typical Squad iteration of roughly 30 emitted responses shows no more than 2 misapplied three-section stop-message responses, down from the observed baseline of roughly 7 misapplications per iteration.
- **SC-002**: Each new warning rule emits on its violating fixtures and does not emit on its compliant fixtures, and the per-rule false-positive rate stays below 5% on a calibration set of at least 20 historical Squad responses.
- **SC-003**: A fresh-context reviewer can read the updated coordinator guidance and correctly classify both worked examples as either final stop messages or in-flight progress updates with no ambiguity.
- **SC-004**: The updated handoff template provides worked examples for both response types, and a synthetic scenario walkthrough confirms the template supports the same classification logic as the coordinator guidance.
- **SC-005**: A fresh-context reviewer can read the updated `human-handoff-id-context` applicability text and correctly determine that both final stop messages and in-flight progress updates are covered.
- **SC-006**: The known-traps catalog records the misapplied-format pattern as validator-enforced and cites the governing rules and proving tests.
- **SC-007**: The repository's existing 48 integration tests continue to pass after the refinement is added.

## Assumptions

- Feature 013 is closed before this feature moves beyond specification into planning and execution.
- The existing three-section stop-message format remains valid and unchanged for genuine human-blocked stop points.
- Tool-call rendering and Copilot-produced result blocks remain outside the validator scope for this feature.
- Existing governance prompt, validator, handoff-template, and corpus mechanisms remain the authoritative surfaces this feature updates rather than introducing a new governance channel.
- The current feature is expected to fit into two bounded iterations totaling roughly 12 story points.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess as requesting product steward, with governance prompt stewards maintaining rule integrity in downstream artifacts.
- **Iteration Facilitator**: Squad coordinator and designated governance maintainers for the affected prompt, validator, and corpus surfaces.
- **Capacity Model**: Two iterations, approximately 12 total story points, with the first iteration focused on scoping guidance and warning rules and the second on tests, corpus graduation, and documentation alignment.
- **Drift Signals**: Repeated three-section misuse in live sessions, validator warnings that lack corresponding prompt guidance, prompt-template-corpus wording mismatches, and fixture regressions against the new warning rules.
- **Human Oversight Points**: Clarify the unresolved scoping decisions before planning, approve planned reconciliation of the open questions, and review completed guidance and warning behavior before implementation closeout.
