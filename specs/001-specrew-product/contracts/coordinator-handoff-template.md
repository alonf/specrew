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

## Pattern Library

### 1. Completion Pattern

**What I just did**  
Completed [task or change] in [feature / artifact group]. Verified [check run or review basis].

**Why I stopped**  
This approved slice is complete. No open blockers remain in the current scope.

**What I need from you**  
Review [specific files or behavior] before the next iteration starts.  
Owner: user

### 2. Blocked Pattern

**What I just did**  
Finished the in-scope work for [artifact group] and recorded the current state.

**Why I stopped**  
I stopped because [plain-language blocker]. The blocked item is [decision / gate / missing input].

**What I need from you**  
Provide [approval / clarification / dependency] so work can continue.  
Owner: user

### 3. Partial / Verification-Gap Pattern

**What I just did**  
Completed [implemented or documented work] in [artifact group].

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
- When review is recommended, say what to review.
- When manual testing is recommended, say what scenario or risk to test.
- When no files changed and that affects the user's decision, say so directly.
