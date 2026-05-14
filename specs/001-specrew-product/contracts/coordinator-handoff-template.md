# Coordinator Handoff Template

Use this as the default copy-paste starting point for any coordinator response.

## Response-Type Selector

Choose exactly one:

- **Final stop message** — use only when the human is the immediate blocker for the next lifecycle step. Preserve the existing three-section stop-message format unchanged.
- **In-flight progress update** — use when Squad is still actively working, waiting on background work, or only acknowledging session start with no human action required. Keep it as concise single-line prose and omit the user-action section entirely.
- **Mixed transition + true blocker** — the real human blocker wins, so use the final stop message.

## Final Stop Message: Three-Section Format

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

### 1. Review-Blocked Stop Pattern

**What I just did**  
Completed [task or change] in [feature / artifact group]. Pair numeric references with scope, for example `feature 014, handoff format scoping` or `iteration 001, the bounded selector rollout`. Verified [check run or review basis].

**Why I stopped**  
I stopped because the next lifecycle step needs a real human review or approval before it can continue safely.

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

### 4. In-Flight Progress Pattern

[Current progress status in one sentence, including whether files changed.] [State the active wait or transition plainly.] [State what Squad will continue doing next.]

Example:

> I updated **feature 014, handoff format scoping**, across the coordinator guidance, I am waiting on the preserved validator run to finish, and I will continue with the bounded checklist alignment once it completes.

### 5. First-Acknowledgement Progress Pattern

> I have started **feature 014, handoff format scoping**, and I am reviewing the approved Iteration 001 artifacts now; I will continue with the in-scope edits next.

## Feature 016 Boundary Worked Examples

Use these as concrete examples for the seven per-iteration handoff boundaries.

### 1. Planning boundary

- State the planned scope, the main artifacts updated, and the exact planning
  stop reason.
- Request a verdict on the planning artifacts using `file:///` links.

### 2. Hardening-gate sign-off

- Summarize the active concerns, current verdict, and what still needs human
  inspection.
- Request sign-off on the gate artifact before implementation begins.

### 3. Implementation boundary

- Summarize the code, docs, fixtures, and validation updates that landed.
- State that post-commit verification reran on the exact committed tree.
- Request the next review-boundary verdict with `file:///` inspection targets.

### 4. Review boundary

- Summarize what the reviewer should inspect and what validations already ran.
- Call out any remaining risk or defer explicitly.

### 5. Review-verdict sign-off

- Summarize the review outcome and the exact fixes or accepted defers.
- Request explicit sign-off on the verdict artifact.

### 6. Retro boundary

- Summarize the outcome, lessons, and any carryovers promoted into durable
  corpus guidance.
- Request review of the retro artifact and the carryover decision.

### 7. Iteration closeout

- Summarize the final implemented scope, evidence state, and what remains
  intentionally deferred.
- Request the closeout verdict on the iteration packet.

## Post-Commit Verification Checklist

For implementation, review, retro, and closeout boundaries that cite committed
artifacts:

1. synchronize `Commit Reference` from `pending` to the real boundary hash
2. normalize `Recorded At` to UTC seconds precision
3. run a stale-reference scan on every cited `file:///` target
4. rerun the governed validation commands on the exact committed tree
5. disclose any remaining defer explicitly in the handoff

## Usage Rules

- Keep the lead sentence plain-language-first.
- If formal lifecycle terms are needed, place them after the plain-language explanation.
- Use the three-section format only for real human-blocked stops.
- Keep in-flight progress updates to single-line prose.
- Keep identifier references readable: `feature 012` alone is not enough; prefer `feature 012, descriptive references in handoffs`.
- When you cite a grouped list such as `T003-T005`, add one shared explanation for the whole group.
- When you cite a commit, explain why that commit matters to the handoff.
- When review is recommended, say what to review.
- When review points to a local repository file in this Windows workflow, include a `file:///` URI using the absolute Windows path.
- When manual testing is recommended, say what scenario or risk to test.
- When no files changed and that affects the user's decision, say so directly.
