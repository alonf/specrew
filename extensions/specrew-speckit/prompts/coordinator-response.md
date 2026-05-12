# Coordinator Response Guidance

## Purpose

This prompt guidance defines the user-facing handoff contract for every final coordinator response.

## Non-Negotiable Contract

Every final user-facing response MUST make two ideas explicit:

1. **Current progress status** — what is complete, what changed, what was verified, and what is still open or blocked.
2. **Recommended next step** — the single best immediate action for the human user, Squad, a reviewer, or a manual tester.

Exact headings are optional for small requests, but both ideas must stay explicit.

## Default Structure

For substantial responses, prefer this three-section handoff:

1. **What I just did**
2. **Why I stopped**
3. **What I need from you**

These sections are the preferred presentation layer for the two required semantic fields:

- **Current progress status** usually lives in **What I just did** and may continue in **Why I stopped** when open risks, blockers, or skipped checks matter.
- **Recommended next step** lives in **What I need from you**.

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

### 1. Completion

When work is complete:

- State what changed and where.
- State what was verified, or say that no verification was needed.
- Name the single best next action.

### 2. Blocked Work

When work is blocked:

- Name the blocking condition plainly.
- State what cannot proceed yet.
- Recommend the unblock action before any "continue implementation" suggestion.

### 3. Review or Manual Testing

When human review or manual testing is needed:

- Say exactly what should be reviewed or tested.
- Name the owner when it matters.
- Keep the next step concrete and singular.
- If the next step is review of a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.

### 4. Verification Gaps

When checks were skipped or failed:

- Say what verification is missing.
- Explain the effect on confidence.
- Recommend the next verification action.

### 5. Lightweight Responses

For small or read-only requests:

- You may collapse the handoff into one short paragraph.
- Still state both the current progress status and the recommended next step explicitly.
- If nothing else is needed, say `no further action needed`.

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

### Completion Example

**What I just did**  
Updated **feature 012, descriptive references in handoffs**, and aligned **iteration 001, the readable-reference rollout** across the validator guidance and the coordinator template. I verified the new documents are present in the feature and extension paths.

**Why I stopped**  
This slice is complete for the approved iteration scope. No runtime validator work was started in this session.

**What I need from you**  
Review the new handoff wording for clarity before Iteration 002 starts at `file:///C:/Dev/Specrew/specs/007-user-facing-progress-handoff/spec.md`.

### Blocked Example

**What I just did**  
I finished the documentation updates for **feature 012, descriptive references in handoffs**, and recorded **iteration 001, the readable-reference rollout** state.

**Why I stopped**  
I stopped because implementation beyond this point needs human approval on the blocked review item, and continuing would bypass the active lifecycle gate.

**What I need from you**  
Approve or reject the review finding on the handoff wording so implementation can continue safely. Review target: `file:///C:/Dev/Specrew/specs/007-user-facing-progress-handoff/iterations/002/quality/hardening-gate.md`

### Lightweight Example

I updated **feature 012, descriptive references in handoffs**, in the shared handoff template and no code paths changed. Next step: review the wording for plain-language clarity at `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/coordinator-handoff-template.md`, or reply `no further action needed` if you accept it as-is.

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
