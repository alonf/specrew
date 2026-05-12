# Coordinator Response Guidance

## Purpose

This prompt guidance defines the user-facing handoff contract for the coordinator's top-level response.

## Response-Type Selector

Choose exactly one governed response type:

- **`final-stop-message`** — use only when a real immediate human action is required before the next lifecycle step can continue safely.
- **`in-flight-progress-update`** — use when Squad is still actively working, waiting on background work, or only acknowledging session start with no current human action required.

Mixed transition + true blocker cases still use `final-stop-message`, because the human action is the deciding factor.

## Final Stop Message Contract

Every `final-stop-message` MUST make two ideas explicit:

1. **Current progress status** — what is complete, what changed, what was verified, and what is still open or blocked.
2. **Recommended next step** — the single best immediate action for the human user, Squad, a reviewer, or a manual tester.

Use this three-section handoff:

1. **What I just did**
2. **Why I stopped**
3. **What I need from you**

These sections are the preferred presentation layer for the two required semantic fields:

- **Current progress status** usually lives in **What I just did** and may continue in **Why I stopped** when open risks, blockers, or skipped checks matter.
- **Recommended next step** lives in **What I need from you**.

Use the existing three-section stop-message format unchanged for real human-blocked stops.

## In-Flight Progress Update Contract

An `in-flight-progress-update` MUST:

- stay as concise single-line prose
- state what is happening now
- make it clear Squad is still in motion
- include the forward motion in prose, for example by saying Squad will continue once the active background step finishes
- omit the `What I need from you` section entirely unless the response should instead be a `final-stop-message`

Do **not** turn in-flight progress into a new `Action | Status | Next` structure in this feature.

## Plain-Language-First Principle

- Lead with plain English that a human can act on immediately.
- Do **not** open with three or more governance acronyms, schema-field names, or lifecycle labels without first paraphrasing them in human terms.
- If formal vocabulary matters, move it to a follow-up sentence, a `Formal references` line, or a short footnote.
- Prefer "You need to review the coordinator handoff wording" over "before-implement gate / hardening-gate sign-off / approval evidence reuse".

## Readable Reference Rule

- When authored narration mentions a feature, iteration, task, requirement, corpus row, or commit, pair the identifier with descriptive scope in the same sentence or immediately adjacent text.
- A clearly grouped list may use one shared scope statement when the grouping is unmistakable. Example: `T003 and T004, the validator-and-contract foundation`.
- Commit references need a why-it-matters phrase. Example: `070dd06, the implementation-authorization boundary commit`.
- Exclude verbatim quoted material, code blocks, raw tool output, and Copilot-rendered tool-call result blocks from this readability rule.
- These readable-reference expectations are additive. They do **not** replace the required progress-status and next-step semantics from feature 007.

## Required Content Rules

### 1. Final Stop Message: Completion or Review Boundary

When work is complete but the next step needs human review or approval:

- State what changed and where.
- State what was verified, or say that no verification was needed.
- Name the single best next action.

### 2. Final Stop Message: Blocked Work

When work is blocked:

- Name the blocking condition plainly.
- State what cannot proceed yet.
- Recommend the unblock action before any "continue implementation" suggestion.

### 3. Final Stop Message: Review or Manual Testing

When human review or manual testing is needed:

- Say exactly what should be reviewed or tested.
- Name the owner when it matters.
- Keep the next step concrete and singular.
- If the next step is review of a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.

### 4. Final Stop Message: Verification Gaps

When checks were skipped or failed:

- Say what verification is missing.
- Explain the effect on confidence.
- Recommend the next verification action.

### 5. In-Flight Progress Updates

When Squad is still moving and no human action is currently required:

- Use one line only.
- Say what is happening now.
- Say what Squad will continue doing next.
- Do not use the three-section stop-message format.

### 6. Descriptive References in Narration

When narration includes three or more identifiers:

- keep each identifier readable on first pass
- use one shared scope statement only when the grouped list is unmistakable
- prefer `feature 012, descriptive references in handoffs` over `feature 012`
- prefer `FR-008 and FR-009, the non-blocking governance review requirements` over `FR-008 and FR-009`

Acceptable narration example:

> I finished **feature 012, descriptive references in handoffs**, and aligned **iteration 001, the readable-reference rollout** across **T003 and T004, the validator-and-contract foundation**.

Unacceptable narration example:

> I finished 012, 001, T003, T004, FR-008, and 070dd06.

## Examples

### Final Stop Message Example

**What I just did**  
Updated **feature 014, handoff format scoping**, and aligned **iteration 001, the bounded selector rollout** across the validator guidance and the coordinator template. I verified the in-scope governed artifacts are updated.

**Why I stopped**  
I stopped because I cannot continue to the next lifecycle step until you approve the bounded stop-vs-progress wording.

**What I need from you**  
Review and approve the bounded wording change before Iteration 002 proof work begins.

### In-Flight Progress Update Example

I updated **feature 014, handoff format scoping**, across the prompt surfaces, I am waiting on the preserved validator run to finish, and I will continue with the bounded checklist and agent-alignment edits once it completes.

### First-Acknowledgement Example

I have started **feature 014, handoff format scoping**, and I am reviewing the approved Iteration 001 artifacts now; I will continue with the in-scope edits next.

### Mixed-Case Final Stop Example

**What I just did**  
I finished the bounded guidance updates for **feature 014, handoff format scoping**, and recorded **iteration 001, the selector rollout** state.

**Why I stopped**  
I also have follow-up cleanup available, but I stopped because the next lifecycle step still needs your approval on the scoped handoff wording.

**What I need from you**  
Approve or reject the scoped wording so implementation can continue safely.

### Plain-Language-First Example

Preferred lead:

> We need one human decision before moving forward: confirm the handoff wording is ready for rollout.

Optional follow-up:

> Formal references: before-implement review, hardening-gate evidence, approval record.

## References

- Prompt guidance: `extensions/specrew-speckit/prompts/coordinator-response.md`
- Decision guidance: `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`
- Reusable template: `specs/001-specrew-product/contracts/coordinator-handoff-template.md`
- Governance checklist: `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`
