# Feature Specification: Specrew User-Facing Progress Handoff

**Feature Branch**: `007-user-facing-progress-handoff`  
**Created**: 2026-05-09  
**Status**: Draft  
**Input**: User description: "Each time the Squad finishes executing a request and addresses the user, it should provide the current progress status and suggest the recommended next steps, such as human review, manual test run, or another reasonable next action."

## Problem Statement

Specrew currently depends on the quality of each coordinator response to communicate where work stands and what should happen next. When the final user-facing response omits progress status, users must infer whether work is complete, blocked, partially verified, or still awaiting review. When the response omits a recommended next step, users may not know whether they should review changes, run manual tests, approve a gate, clarify a decision, or continue with another request.

This feature establishes a durable handoff contract for Squad's final user-facing responses so every completion, pause, or factual answer ends with an explicit statement of current progress and the best immediate next action.

## Relationship to Existing Features

This feature applies across Specrew's existing response patterns, including Direct, Lightweight, Standard, Full, Spec Kit, implementation, review, and lifecycle coordination flows.

- It governs the coordinator's final response to the human user.
- It complements existing review findings, lifecycle gates, implementation briefings, and status summaries rather than replacing them.
- It allows specialized response formats to remain concise or domain-specific as long as they still communicate both required handoff concepts explicitly.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive a clear completion handoff (Priority: P1)

A human user receives a Squad response after work completes and can immediately understand what changed, what state the work is in, and what should happen next.

**Why this priority**: Every completed interaction needs a reliable handoff so the user does not have to infer progress or next actions.

**Independent Test**: Run a Squad request that performs analysis, implementation, review, or lifecycle work. Verify the final user-facing response includes both the current progress status and a recommended next step.

**Acceptance Scenarios**:

1. **Given** Squad completes a request, **When** it addresses the user, **Then** the response includes the current progress status.
2. **Given** Squad completes a request, **When** it addresses the user, **Then** the response includes one recommended next step.
3. **Given** Squad changed artifacts, **When** it reports progress status, **Then** it identifies the relevant feature, phase, or artifact group.
4. **Given** no files were changed, **When** Squad responds, **Then** it explicitly states that no files were changed if that affects the user's next decision.

---

### User Story 2 - Understand blockers and review needs (Priority: P1)

A human user receives a response after a blocked, deferred, or review-heavy request and can tell whether they need to approve, review, test, or clarify something.

**Why this priority**: Specrew lifecycle gates sometimes require explicit human action, and unclear handoffs can cause avoidable delays or unsafe continuation.

**Independent Test**: Simulate a blocked gate, failed validation, review finding, or deferred decision. Verify the final response states the blocker or risk and recommends the immediate unblock action.

**Acceptance Scenarios**:

1. **Given** work is blocked, **When** Squad responds, **Then** the progress status identifies the blocking condition.
2. **Given** human approval is required, **When** Squad recommends a next step, **Then** it names the approval or review decision needed.
3. **Given** manual testing is required, **When** Squad recommends a next step, **Then** it describes the specific manual test focus.
4. **Given** automated verification failed or was skipped, **When** Squad responds, **Then** it states the verification gap and recommends the next verification action.
5. **Given** human review of a local repository file is recommended in this Windows environment, **When** Squad names the file to review, **Then** it includes a `file:///` URI using the absolute Windows path so the reviewer can open it directly from compatible clients.

---

### User Story 3 - Keep lightweight responses fluent (Priority: P2)

A human user receives a concise but complete handoff even for small requests, without unnecessary ceremony or duplicated status noise.

**Why this priority**: The handoff rule should improve usability without forcing every small response into a bulky status report.

**Independent Test**: Run a direct factual request, a read-only review, and a small implementation task. Verify each response includes progress and next step in a compact form appropriate to the task size.

**Acceptance Scenarios**:

1. **Given** the request is small, **When** Squad responds, **Then** progress status and next step may be expressed in one concise paragraph.
2. **Given** the request is substantial, **When** Squad responds, **Then** progress status and next step are visually scannable.
3. **Given** the recommended next step is obvious, **When** Squad responds, **Then** it still states the action explicitly.
4. **Given** a factual or read-only answer is fully complete, **When** Squad recommends the next step, **Then** it MAY explicitly state that no further action is needed.

---

### Edge Cases

- What happens when Squad provides a pure factual or direct answer with no artifact work? → The final response still includes explicit progress status and a recommended next step, even if the status is simply that no repository changes were made.
- What happens when a factual or read-only answer is fully complete and needs no follow-up? → The recommended next step may explicitly be `no further action needed`.
- What happens when multiple next actions are possible? → Squad identifies the single best immediate next step and may mention secondary options only after the primary action is clear.
- What happens when automated checks were not run because the task was read-only? → The handoff states that no verification run was needed or performed and recommends the most relevant follow-up action, if any.
- What happens when a specialized format already contains status information but omits the next step? → The response is considered incomplete until both concepts are explicit.
- What happens when the next step is to review a local file and the client surface may not make plain paths clickable? → In this Windows environment, the response includes a `file:///` URI with the absolute Windows path as the primary review reference. Additional fallbacks may be included, but the URI is the required baseline.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Final Handoff Coverage**: Every final user-facing Squad response after executing a request MUST include explicit current progress status and a recommended next step.
- **FR-002: Universal Scope**: This handoff requirement MUST apply to Direct, Lightweight, Standard, Full, Spec Kit, implementation, review, lifecycle coordination, and pure factual/direct answer flows.
- **FR-003: Progress Status Content**: Current progress status MUST state the present work or lifecycle state and summarize meaningful completed work.
- **FR-004: Artifact Visibility**: When work changed, reviewed, or inspected artifacts, the progress status MUST identify the relevant feature, artifact group, or work area. When no files changed and that affects the user's decision, the status MUST say so explicitly.
- **FR-005: Open Issues Disclosure**: When blockers, known risks, deferred decisions, skipped checks, or failed checks exist, the progress status MUST state them explicitly.
- **FR-006: Actionable Next Step**: The recommended next step MUST identify the single best immediate action and MUST be concrete enough for the user or Squad to act on. For fully complete factual or read-only answers with no follow-up work, `no further action needed` is a valid explicit recommendation.
- **FR-007: Ownership Clarity**: The recommended next step SHOULD identify the owner of the next action when ownership matters, such as human user, Squad, reviewer, or manual tester.
- **FR-008: Review Guidance**: If human review is recommended, the response MUST state what should be reviewed.
- **FR-009: Manual Test Guidance**: If manual testing is recommended, the response MUST state what scenario, behavior, or risk should be tested.
- **FR-010: Verification Gap Guidance**: If automated verification failed or was skipped, the response MUST state the gap and recommend the next verification action.
- **FR-011: Blocked vs. Continue Logic**: If implementation is blocked, the response MUST recommend the unblock action before suggesting continued implementation. If implementation can continue safely, the response SHOULD recommend the next implementation or verification action.
- **FR-012: Flexible Wording**: Exact headings are not required. Compact inline wording is acceptable for small requests as long as current progress status and recommended next step are both explicit.
- **FR-013: Final Response Ownership**: The requirement MUST apply to the coordinator's final user-facing response, not only to internal logs, status artifacts, or subagent output.
- **FR-014: Durable Rollout**: Specrew MUST update its coordinator guidance, generated agent instructions, and quality review surfaces so this handoff behavior persists across future Squad sessions.
- **FR-015: Specialized Format Compatibility**: Existing specialized response formats MAY satisfy this requirement only if they explicitly include both current progress status and recommended next step.
- **FR-016: Soft Quality Warning**: Missing current progress status or missing recommended next step MUST be treated as a soft quality warning for governance or prompt validation, not as a hard failure that automatically invalidates the overall response.
- **FR-017: Review File Navigation**: When the recommended next step asks the user to review a local repository file in this Windows environment, the response MUST include a `file:///` URI using the absolute Windows path. Additional fallbacks such as the plain path or `code --goto` MAY be included, but the `file:///` URI is the required review reference.

### Response Contract

A compliant final handoff contains these two semantic fields:

- **Current progress status**: What is complete, where the work stands, what was verified, and what remains blocked or open.
- **Recommended next step**: The single best immediate action for the user or Squad. For fully complete factual or read-only answers with nothing further to do, this may explicitly be `no further action needed`.

The response does not need to use exact headings when the task is small, but the information must remain explicit.

### Requirement Ownership & Delivery *(mandatory)*

- **FR-001 to FR-005** — **Owner roles**: Squad coordinator response-contract maintainers. **Delivery window**: Initial rollout of the user-facing handoff contract.
- **FR-006 to FR-011** — **Owner roles**: Squad coordinator maintainers and reviewers of final-response quality. **Delivery window**: Initial rollout, with validation during representative response sampling.
- **FR-012 to FR-017** — **Owner roles**: Prompt-template maintainers and governance/checklist maintainers. **Delivery window**: Same rollout so the contract stays durable across future sessions.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001, FR-003, FR-004, FR-006, FR-012, and FR-013.
- **TG-002**: User Story 2 maps to FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, and FR-016.
- **TG-002A**: Review-file navigation behavior in User Story 2 maps to FR-008 and FR-017.
- **TG-003**: User Story 3 maps to FR-002, FR-006, FR-012, FR-015, and FR-016.
- **TG-004**: Any conflict between a specialized response format and this handoff contract MUST be reconciled in favor of keeping both semantic fields explicit in the final user-facing response.

### Key Entities *(include if feature involves data)*

- **Final User-Facing Handoff**: The last Squad/coordinator message that addresses the human user after work concludes, pauses, or is handed back.
- **Current Progress Status**: The semantic part of the handoff that states what happened, what state the work is in, and what remains open or blocked.
- **Recommended Next Step**: The semantic part of the handoff that names the single best immediate action and, when needed, the person responsible for taking it.
- **Review File Reference**: A navigation-ready file reference for human review requests in this Windows environment, expressed as a `file:///` URI with the absolute Windows path.
- **Verification Gap**: Any skipped, incomplete, or failed check that materially affects confidence in the outcome and must be surfaced in the handoff.

### Non-Goals

- This feature does not require a persistent dashboard.
- This feature does not require changing unrelated product feature specifications.
- This feature does not require every internal subagent message to include a user-facing handoff.
- This feature does not replace detailed implementation briefings, review findings, or lifecycle gate artifacts.
- This feature does not guarantee that every client surface renders local file references as clickable links; it standardizes the required `file:///` format that works in the supported Windows workflow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In sampled Squad completions across at least five request types, 100% of final user-facing responses include explicit current progress status.
- **SC-002**: In sampled Squad completions across at least five request types, 100% of final user-facing responses include an explicit recommended next step.
- **SC-003**: In sampled blocked or gated responses, 100% clearly identify the blocker and the approval, review, clarification, or test action required to proceed.
- **SC-004**: In sampled completed implementation responses, 100% identify completed verification and recommend either manual testing, review, or the next safe implementation step.
- **SC-005**: In sampled read-only analysis or factual responses, 100% disclose that no files changed when that affects the user's next decision.
- **SC-006**: In sampled small responses, at least 95% keep the handoff to one concise paragraph or similarly compact form while still preserving both required concepts.
- **SC-007**: In sampled responses that ask the user to review a local file, 100% include a `file:///` URI using the absolute Windows path.

## Clarifications

### Session 2026-05-09

- Q: Should this apply to pure factual answers that perform no artifact work? → A: Yes. The handoff rule applies to all final user-facing responses, including pure factual or direct answers.
- Q: Must the response use exact headings such as "Current progress status" and "Recommended next step"? → A: No. Exact headings are not required; compact inline wording is acceptable as long as both concepts are explicit.
- Q: Is a missing handoff field a hard governance failure? → A: No. Missing handoff fields are treated as a soft quality warning, not a hard governance failure.
- Q: What recommended next step is valid for a fully complete factual or read-only answer? → A: `no further action needed` is a valid explicit recommended next step.

### Session 2026-05-10

- Q: How should the soft handoff validator be implemented? → A: Use a hybrid model. Update coordinator prompt/guidance to reinforce the handoff contract during response generation, then add a post-response soft validator/checker that flags missing handoff fields or three-or-more governance acronyms in the lead without hard-blocking the response. This preserves response integrity while maintaining quality oversight.

### Session 2026-05-11

- Q: What file reference format should Squad use when asking the user to review a local repository file from this Windows environment? → A: Use a `file:///` URI with the absolute Windows path as the required review reference. Additional fallbacks may be included, but the URI is the baseline.

## Assumptions

- "Final user-facing response" means the last coordinator message that addresses the human after Squad finishes, pauses, or hands back work for the current request.
- Existing specialized response formats can be updated to preserve their domain-specific content while still making both handoff concepts explicit.
- When multiple reasonable follow-up actions exist, Squad chooses the single best immediate next action rather than presenting an unprioritized list.
- When a factual or read-only answer is fully complete and no follow-up is needed, the recommended next step may explicitly say that no further action is needed.
- Read-only and factual responses may have minimal progress states, but they still benefit from an explicit handoff.
- Governance review may warn on missing handoff fields without blocking every otherwise useful response.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess, as requesting maintainer and reviewer of the user-facing handoff contract.
- **Iteration Facilitator**: Specrew coordinator/prompt maintainers responsible for keeping final-response behavior aligned across response modes and lifecycle flows.
- **Capacity Model**: One cross-cutting coordination slice spanning final-response guidance, sampling, and governance review within a single delivery iteration.
- **Drift Signals**: Final user-facing responses omit either progress status or recommended next step; specialized formats keep one concept but drop the other; governance checks treat the issue more harshly or more loosely than the spec allows.
- **Human Oversight Points**: Human review of representative final responses before rollout, plus approval of any governance language that changes how missing handoff fields are reported.
