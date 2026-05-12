# Coordinator Handoff Template

Use this as the default copy-paste starting point for any final coordinator response.

## Three-Section Format

### What I just did

**Current progress status**  
[State what changed, where work stands, and what was verified.]  
Reference: [feature / artifact group / no files changed if that matters]

### Why I stopped

[State whether the work is complete, paused, blocked, waiting for review, or waiting for validation.]  
[If there is a blocker, skipped check, failed check, or known risk, state it plainly.]

### What I need from you

**Recommended next step**  
[State the single best immediate action.]  
Owner: [user | Squad | reviewer | manual tester | no further action needed]

## Descriptive Reference Rules

- When you mention a feature, iteration, task, requirement, corpus row, or commit, pair the identifier with a short plain-language explanation in the same sentence or immediately adjacent text.
- A clearly grouped list may use one shared scope statement when the grouping is unmistakable. Example: `T003 and T004, the validator-and-contract foundation`.
- Commit references need a why-it-matters phrase, not just the hash. Example: `070dd06, the implementation-authorization boundary commit`.
- These descriptive-reference rules are additive. They do **not** replace the required **Current progress status** and **Recommended next step** fields.

## Pattern Library

### 1. Completion Pattern

**What I just did**  
Completed [task or change] in [feature / artifact group]. Pair numeric references with scope, for example `feature 012, descriptive references in handoffs` or `iteration 001, the readable-reference rollout`. Verified [check run or review basis].

**Why I stopped**  
This approved slice is complete. No open blockers remain in the current scope.

**What I need from you**  
Review [specific files or behavior] before the next iteration starts. If the review target is a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.  
Owner: user

### 2. Blocked Pattern

**What I just did**  
Finished the in-scope work for [artifact group] and recorded the current state. If you cite commits or task IDs, explain what each one covers.

**Why I stopped**  
I stopped because [plain-language blocker]. The blocked item is [decision / gate / missing input].

**What I need from you**  
Provide [approval / clarification / dependency] so work can continue.  
Owner: user

### 3. Partial / Verification-Gap Pattern

**What I just did**  
Completed [implemented or documented work] in [artifact group]. If several identifiers share one explanation, keep the shared scope in the same sentence or immediately adjacent text.

**Why I stopped**  
[Check name] was not run or did not pass, so confidence is partial until that verification gap is closed.

**What I need from you**  
Run or review [specific validation or scenario] next.  
Owner: reviewer

### 4. Lightweight Pattern

[Current progress status in one sentence, including whether files changed.] Next step: [single action, or `no further action needed`].

## Usage Rules

- Keep the lead sentence plain-language-first.
- If formal lifecycle terms are needed, place them after the plain-language explanation.
- Always make both semantic fields explicit, even in compact replies.
- Keep identifier references readable: `feature 012` alone is not enough; prefer `feature 012, descriptive references in handoffs`.
- When you cite a grouped list such as `T003-T005`, add one shared explanation for the whole group.
- When you cite a commit, explain why that commit matters to the handoff.
- When review is recommended, say what to review.
- When review points to a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.
- When manual testing is recommended, say what scenario or risk to test.
- When no files changed and that affects the user's decision, say so directly.
