# Coordinator Decision Guidance

## Purpose

Use these decision rules to turn coordinator outcomes into clear final handoffs.

## Decision Trees

### 1. Blocker Decision

**If** work cannot continue safely  
**Then**

1. Put the plain-language blocker in **Why I stopped**.
2. State the blocked work or withheld step.
3. In **What I need from you**, recommend the single unblock action.
4. Do not suggest continued implementation until the unblock action is named first.

### 2. Review Decision

**If** human review is the best next action  
**Then**

1. Summarize what changed in **What I just did**.
2. In **What I need from you**, say exactly what should be reviewed.
3. If the review target is a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.
4. Name the owner when it matters.

Example next step:

> Review the new handoff wording in the coordinator prompt, template, and Squad agent contract. Start with `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/coordinator-handoff-template.md`.

### 3. Manual Test Decision

**If** manual testing is needed  
**Then**

1. State the relevant completion or verification status.
2. Name the scenario, behavior, or risk to test.
3. Recommend that single manual test as the next action.

Example next step:

> Manually check that a blocked stop message starts with plain language before any lifecycle labels.

### 4. Verification Gap Decision

**If** automated verification was skipped or failed  
**Then**

1. Say which check was skipped or failed.
2. State the confidence gap in plain language.
3. Recommend the next verification action before broader rollout.

### 5. Blocked-vs-Continue Decision

**If** the blocker prevents safe continuation  
**Then**

- Stop and recommend the unblock action.

**If** the blocker does not prevent safe continuation  
**Then**

- State the open risk in **Why I stopped** and recommend the next safe implementation, review, or verification action.

### 6. Readable Reference Decision

**If** the handoff mentions three or more feature, iteration, task, requirement, corpus, or commit references  
**Then**

1. Give each identifier descriptive scope in the same sentence or immediately adjacent text.
2. Use one shared scope statement only when the grouped list is unmistakable.
3. Explain why each commit reference matters to the stop message.
4. Keep quoted material, code blocks, raw tool output, and Copilot-rendered tool-call result blocks outside this readability check.
5. Preserve the existing progress-status, blocker/risk, and next-step semantics while adding the descriptive-reference wording.

## Handoff Semantics Mapping

| Scenario | What I just did | Why I stopped | What I need from you |
|---|---|---|---|
| Completed work | changed artifacts + verification | complete / no blocker | review, test, or no further action needed |
| Blocked work | work completed so far | blocker and impact | unblock action |
| Review needed | changed artifacts | waiting for review | what to review |
| Manual testing needed | changed artifacts or risk area | automation not enough | what to test |
| Verification gap | completed work so far | skipped/failed check and confidence impact | next verification action |

## Plain-Language Guardrail

- Start each section with human-readable meaning first.
- Move formal terms such as gate names, schema labels, or approval labels after the plain-language sentence.
- If three or more governance acronyms or field names would appear in the lead, rewrite before sending.
- If three or more identifiers would appear in the handoff, add descriptive scope before sending.

## Escalation Examples

### Review Needed

- **What I just did**: Updated **feature 012, descriptive references in handoffs**, and aligned **iteration 001, the readable-reference rollout** template with the prompt guidance.
- **Why I stopped**: The approved slice is implemented, but the wording still needs a human review pass.
- **What I need from you**: Review the wording in the prompt, template, and Squad agent section for clarity and consistency. Start with `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/coordinator-handoff-template.md`.

### Verification Gap

- **What I just did**: Finished the documentation changes for **iteration 001, the readable-reference rollout**.
- **Why I stopped**: I did not run runtime validator coverage because that work belongs to Iteration 002, so rollout confidence is limited to document review in this slice.
- **What I need from you**: Confirm this iteration should stop at the documentation boundary and carry runtime validation into Iteration 002.

### Readable Stop-Message Example

Acceptable:

> I finished **feature 012, descriptive references in handoffs**, and completed **T009 and T010, the stop-message guidance updates**. I stopped before **070dd06, the implementation-authorization boundary commit**, is followed by the restart-triggered Squad startup guidance edits.

Unacceptable:

> I finished 012, 001, T009, T010, and 070dd06.
