# Coordinator Decision Guidance

## Purpose

Use these decision rules to choose the right coordinator response type for the coordinator's top-level user-facing output.

## Decision Trees

### 1. Response-Type Selector

**If** the next lifecycle step is blocked on a real immediate human action  
**Then**

1. Use a `final-stop-message`.
2. Preserve the existing three-section format:
   - **What I just did**
   - **Why I stopped**
   - **What I need from you**
3. Make the user action substantive and singular.

**If** Squad is still actively working, waiting on background work, or only acknowledging session start with no current human action required  
**Then**

1. Use an `in-flight-progress-update`.
2. Keep it to concise single-line prose.
3. Omit the user-action section entirely.
4. Make the forward motion explicit, for example by saying Squad will continue once the background step finishes.

**If** the response mixes transition status with a real human blocker  
**Then**

- Use the `final-stop-message`, because the immediate human action is the deciding factor.

Examples:

- **Correct final stop message**: "I updated the scoped guidance and validator wording. I stopped because I cannot continue to the next lifecycle step until you approve the selector wording. What I need from you: review and approve the bounded wording change."
- **Correct in-flight progress update**: "I updated the scoped guidance, I am waiting on the validator run to finish, and I will continue once it completes."
- **Correct first acknowledgement**: "I have started the bounded Iteration 001 work and I am reviewing the approved artifacts now; I will continue with the in-scope edits next."

### 2. Final Stop Message: Blocker Decision

**If** work cannot continue safely  
**Then**

1. Put the plain-language blocker in **Why I stopped**.
2. State the blocked work or withheld step.
3. In **What I need from you**, recommend the single unblock action.
4. Do not suggest continued implementation until the unblock action is named first.

### 3. Final Stop Message: Review Decision

**If** human review is the best next action  
**Then**

1. Summarize what changed in **What I just did**.
2. In **What I need from you**, say exactly what should be reviewed.
3. If the review target is a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.
4. Name the owner when it matters.

Example next step:

> Review the new handoff wording in the coordinator prompt, template, and Squad agent contract. Start with `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/coordinator-handoff-template.md`.

### 4. Final Stop Message: Manual Test Decision

**If** manual testing is needed  
**Then**

1. State the relevant completion or verification status.
2. Name the scenario, behavior, or risk to test.
3. Recommend that single manual test as the next action.

Example next step:

> Manually check that a blocked stop message starts with plain language before any lifecycle labels.

### 5. Final Stop Message: Verification Gap Decision

**If** automated verification was skipped or failed  
**Then**

1. Say which check was skipped or failed.
2. State the confidence gap in plain language.
3. Recommend the next verification action before broader rollout.

### 5A. Stop-vs-Progress Decision

**If** a real blocker prevents safe continuation  
**Then**

- Use the three-section `final-stop-message` and recommend the unblock action.

**If** Squad can continue safely without a human action  
**Then**

- Use a single-line `in-flight-progress-update`.
- State the current transition plainly.
- State what Squad will continue doing next.

### 6. Readable Reference Decision

**If** the handoff mentions three or more feature, iteration, task, requirement, corpus, or commit references  
**Then**

1. Give each identifier descriptive scope in the same sentence or immediately adjacent text.
2. Use one shared scope statement only when the grouped list is unmistakable.
3. Explain why each commit reference matters to the stop message.
4. Keep quoted material, code blocks, raw tool output, and Copilot-rendered tool-call result blocks outside this readability check.
5. Preserve the existing progress-status, blocker/risk, and next-step semantics while adding the descriptive-reference wording.

## Response-Type Semantics Mapping

| Scenario | Response Type | Format | Required Semantics |
|---|---|---|---|
| Human approval, clarification, review, or manual action is required now | `final-stop-message` | Existing three-section stop-message format | substantive progress, real stop reason, one substantive human action |
| Automated verification was skipped or failed and human review or approval is now required before proceeding | `final-stop-message` | Existing three-section stop-message format | explicit confidence gap plus the immediate human next step |
| Squad is still working, waiting on a background run, or transitioning internally | `in-flight-progress-update` | Concise single-line prose | current status plus explicit forward motion |
| Session-opening acknowledgement with no current human action required | `in-flight-progress-update` | Concise single-line prose | acknowledge start, state current work, and indicate continued motion |
| Mixed transition plus true human blocker | `final-stop-message` | Existing three-section stop-message format | the real human blocker wins over the transition note |

## Plain-Language Guardrail

- Start each section with human-readable meaning first.
- Move formal terms such as gate names, schema labels, or approval labels after the plain-language sentence.
- If three or more governance acronyms or field names would appear in the lead, rewrite before sending.
- If three or more identifiers would appear in the handoff, add descriptive scope before sending.

## Escalation Examples

### Review-Blocked Stop Message

- **What I just did**: Updated **feature 012, descriptive references in handoffs**, and aligned **iteration 001, the readable-reference rollout** template with the prompt guidance.
- **Why I stopped**: The approved slice is implemented, but the wording still needs a human review pass.
- **What I need from you**: Review the wording in the prompt, template, and Squad agent section for clarity and consistency. Start with `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/coordinator-handoff-template.md`.

### Verification-Gap Stop Message

- **What I just did**: Finished the documentation changes for **iteration 001, the readable-reference rollout**.
- **Why I stopped**: I did not run runtime validator coverage because that work belongs to Iteration 002, so rollout confidence is limited to document review in this slice.
- **What I need from you**: Confirm this iteration should stop at the documentation boundary and carry runtime validation into Iteration 002.

### In-Flight Progress Update

> I updated the selector guidance and I am waiting on the preserved validator run to finish; I will continue with the bounded checklist and agent-alignment edits once it completes.

### First Acknowledgement

> I have started the bounded Iteration 001 implementation review and I am checking the approved artifacts now; I will continue with the in-scope prompt and validator edits next.

### Readable Stop-Message Example

Acceptable:

> I finished **feature 012, descriptive references in handoffs**, and completed **T009 and T010, the stop-message guidance updates**. I stopped before **070dd06, the implementation-authorization boundary commit**, is followed by the restart-triggered Squad startup guidance edits.

Unacceptable:

> I finished 012, 001, T009, T010, and 070dd06.
