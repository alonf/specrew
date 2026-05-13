# Feature Specification: Descriptive References in Handoffs

**Feature Branch**: `012-keep-descriptive-refs`  
**Created**: 2026-05-11  
**Status**: Complete
**Input**: User description: "Generate a specification from the approved source spec at `C:\Temp\squad-descriptive-references.md`, focused on keeping descriptive references alongside numeric IDs in user-facing handoffs."

## Clarifications

### Session 2026-05-11

- Q: What threshold should trigger the governance readability warning for opaque numeric IDs? → A: The warning applies when Squad-authored user-facing narration or stop messages contain three or more un-described numeric IDs.
- Q: When can a grouped list or range use one shared description instead of per-item descriptions? → A: A single shared scope statement is allowed only when it clearly labels the full grouped list or range in the same sentence or immediately adjacent text, so the grouping is distinguishable from omission.
- Q: Which excluded surfaces count as tool-call output for readability detection? → A: Exclusions include verbatim quoted material, code blocks, raw tool output, and Copilot-rendered tool-call result blocks.
- Q: Which user-facing surfaces are in scope for this feature? → A: The feature remains limited to Squad-authored user-facing narration and stop messages.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Readable in-flight narration (Priority: P1)

A human following Squad's progress narration can understand what a feature number, iteration number, task code, or other numeric reference means without opening another artifact, because each numeric reference is paired with a brief descriptive label.

**Why this priority**: In-flight narration is the most frequent user-facing surface. Improving it reduces confusion throughout the session, not just at the end.

**Independent Test**: Review a sample narration that mentions multiple features, iterations, tasks, and commits. Confirm that each numeric reference includes nearby descriptive context that explains its meaning to a first-time reader.

**Acceptance Scenarios**:

1. **Given** a narration line references a feature by number, **When** the message is shown to the user, **Then** the feature number is accompanied by a brief description of the feature's purpose.
2. **Given** a narration line references an iteration by number, **When** the message is shown to the user, **Then** the iteration number is accompanied by a brief description of the slice being delivered.
3. **Given** a narration line references a task code, requirement code, corpus row, or commit, **When** the message is shown to the user, **Then** the reference is accompanied by plain-language context explaining what that item represents.
4. **Given** a narration line introduces a list or range of numeric references, **When** the list is shown to the user, **Then** the message includes a single shared scope statement that explains the full group in the same sentence or immediately adjacent text.

---

### User Story 2 - Readable stop messages and handoffs (Priority: P1)

A human reading Squad's stop message can understand what work was completed, what is blocked, and what needs a decision without having to translate opaque numeric IDs into meaning.

**Why this priority**: Stop messages are decision points. If their references are unclear, the human cannot confidently approve, redirect, or continue work.

**Independent Test**: Review a stop message containing feature numbers, iteration numbers, task codes, requirement references, and commits. Confirm that a reviewer can identify each referenced item from the handoff text alone.

**Acceptance Scenarios**:

1. **Given** a stop message includes feature, iteration, task, or requirement references, **When** the user reads the handoff, **Then** each reference includes nearby descriptive scope in the same sentence or immediately adjacent text.
2. **Given** a stop message includes one or more commits, **When** those commits are mentioned, **Then** each commit reference includes a brief summary of why that commit matters to the handoff.
3. **Given** a stop message includes a list of blocked items or requested follow-ups, **When** numeric references appear in that list, **Then** the handoff explains what each item covers without requiring the user to open planning artifacts.

---

### User Story 3 - Governance checks reinforce readable references (Priority: P2)

A maintainer responsible for handoff quality wants Squad-authored narration and stop messages with three or more opaque numeric references lacking descriptive scope to be flagged automatically, so the readability rule remains durable over time.

**Why this priority**: Clear guidance helps initially, but lightweight governance feedback is needed to prevent regressions as the system evolves.

**Independent Test**: Compare one sample Squad-authored narration or stop message containing three or more numeric references without descriptive scope and one sample message with descriptive scope. Confirm that the first is flagged for readability review and the second is accepted.

**Acceptance Scenarios**:

1. **Given** a Squad-authored narration or stop message contains three or more numeric references without descriptive scope, **When** it is reviewed by the handoff-governance check, **Then** the message is flagged for missing descriptive context.
2. **Given** a Squad-authored narration or stop message contains the same numeric references with clear descriptive scope, **When** it is reviewed, **Then** it passes without a readability warning.
3. **Given** numeric references appear only inside verbatim tool output, Copilot-rendered tool-call result blocks, or quoted material, **When** the response is reviewed, **Then** those verbatim references are excluded from the readability check.

---

### Edge Cases

- How should the system handle a long list or range of numeric references? A single shared scope statement should be allowed only when it clearly labels the full grouped list or range in the same sentence or immediately adjacent text.
- How should the system handle repeated mentions of the same numeric reference in one paragraph? The first mention may carry the descriptive scope, and later mentions in the same short context may rely on that earlier explanation.
- How should the system handle numeric prose that is not acting as an identifier? Ordinary counting language should not trigger the descriptive-reference rule.
- How should the system handle verbatim quoted content, code blocks, raw tool-rendered output, or Copilot-rendered tool-call result blocks? Those surfaces are out of scope for this rule because they are not authored narration or stop-message prose.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST present every feature number used in Squad-authored user-facing narration and stop messages with a brief descriptive scope that explains the feature's purpose. **Owner role**: Coordinator and handoff-governance maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-002**: The system MUST present every iteration number used in Squad-authored user-facing narration and stop messages with a brief descriptive scope that explains the iteration slice. **Owner role**: Coordinator and handoff-governance maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-003**: The system MUST present every task code, requirement code, corpus reference, or commit reference used in Squad-authored user-facing narration and stop messages with plain-language context that explains what the reference means to the reader. **Owner role**: Coordinator and handoff-governance maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-004**: The system MUST allow a single shared scope statement to satisfy the rule for a clearly grouped list or range of numeric references only when that statement clearly labels the full group in the same sentence or immediately adjacent text. **Owner role**: Coordinator and handoff-governance maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-005**: The system MUST render user-facing work labels and handoff references as descriptive phrases rather than opaque internal-only identifiers. **Owner role**: Coordinator maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-006**: The system MUST apply the descriptive-reference rule only to Squad-authored user-facing narration and stop messages and MUST exclude verbatim tool output, Copilot-rendered tool-call result blocks, quoted material, and code blocks from the rule. **Owner role**: Handoff-governance maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-007**: The system MUST provide guidance and worked examples that show acceptable and unacceptable ways to pair numeric references with descriptive scope in narration and stop messages. **Owner role**: Prompt, template, and checklist maintainers. **Delivery window**: Initial rollout of descriptive-reference behavior.
- **FR-008**: The system MUST provide a non-blocking governance review that flags Squad-authored narration and stop messages containing three or more un-described numeric references without descriptive scope, while preserving the existing low-noise behavior of handoff review. **Owner role**: Handoff-governance maintainers. **Delivery window**: Follow-on enforcement slice within the same feature.
- **FR-009**: The governance review MUST distinguish between missing descriptive scope in authored narration or stop-message prose and identifiers that appear only inside excluded verbatim content, including Copilot-rendered tool-call result blocks. **Owner role**: Handoff-governance maintainers. **Delivery window**: Follow-on enforcement slice within the same feature.
- **FR-010**: The descriptive-reference feature MUST be additive and MUST NOT weaken existing handoff-governance expectations that already protect clarity and completeness. **Owner role**: Spec steward and handoff-governance maintainers. **Delivery window**: Throughout delivery and review.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001 through FR-006 and FR-007.
- **TG-002**: User Story 2 maps to FR-001 through FR-007 and FR-010.
- **TG-003**: User Story 3 maps to FR-006, FR-008, FR-009, and FR-010.
- **TG-004**: The feature MUST remain bounded to improving human readability of Squad-authored user-facing narration and stop messages; changing tool-rendered output, Copilot-rendered tool-call result blocks, other user-facing surfaces, or historical transcripts is out of scope.
- **TG-005**: The feature MUST preserve compatibility with existing handoff-governance review behavior by adding descriptive-reference coverage without removing other clarity checks.
- **TG-006**: Readiness for later planning requires each planned slice to show how user-facing examples, governance review, and sampled acceptance checks stay aligned.

### Key Entities *(include if feature involves data)*

- **Numeric Reference**: A user-facing identifier such as a feature number, iteration number, task code, requirement code, corpus reference, or commit reference.
- **Descriptive Scope**: A brief plain-language phrase near a numeric reference that tells the reader what the reference means.
- **Shared Scope Statement**: A single descriptive phrase that labels an entire grouped list or range of numeric references in the same sentence or immediately adjacent text.
- **User-Facing Handoff**: Progress narration or a stop message intended for a human reviewer making decisions during or after Squad work.
- **Governance Review**: A non-blocking readability check that warns when three or more opaque numeric references appear without descriptive scope in Squad-authored narration or stop messages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a review sample of at least 20 user-facing narration and handoff messages, 100% of feature and iteration references include descriptive scope understandable on first read.
- **SC-002**: In the same review sample, 100% of task, requirement, corpus, and commit references either include their own descriptive scope or are covered by a clear shared scope statement for the full list.
- **SC-003**: In at least 5 dogfood sessions after rollout, reviewers can correctly identify the meaning of sampled numeric references from the handoff text alone in at least 90% of spot checks.
- **SC-004**: The non-blocking governance review flags all seeded examples containing three or more opaque numeric references without descriptive scope in Squad-authored narration or stop messages and does not flag seeded examples that provide adequate descriptive scope or contain identifiers only inside excluded verbatim content.

## Assumptions

- Existing Squad progress narration and stop-message patterns remain the primary user-facing surfaces for this feature.
- Numeric references will continue to appear in those surfaces because they are useful for traceability and cross-reference.
- The coordinator can access enough surrounding context to attach short descriptive labels to the numeric references it presents.
- This feature applies to future Squad-authored narration and stop messages and does not require rewriting or revalidating historical transcripts.
- Tool-rendered output, Copilot-rendered tool-call result blocks, quoted material, and code blocks remain out of scope for descriptive-reference enforcement.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess, as the maintainer who identified the readability gap and approves the boundary for descriptive-reference behavior in user-facing handoffs.
- **Iteration Facilitator**: Specrew handoff-governance maintainers responsible for keeping narration guidance, stop-message expectations, and governance review behavior aligned.
- **Capacity Model**: One bounded feature delivered in small slices: first establish readable descriptive-reference behavior in user-facing wording, then reinforce it with governance review and acceptance coverage.
- **Drift Signals**: User-facing narration or stop messages fall back to numeric-only references, work labels become opaque again, or governance review stops distinguishing authored prose from excluded verbatim content.
- **Human Oversight Points**: Human review of worked examples before rollout, human approval of seeded readability-review examples, and human confirmation that the feature remains limited to authored handoff prose.
