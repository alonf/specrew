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

## Per-Boundary Interaction-Model Overlay

- Stop and ask after each named boundary: planning, hardening-gate-and-implementation-auth, implementation, review-boundary, review-verdict-signoff, retro-boundary, and iteration-closeout. `feature-closeout` remains a separate feature-level stop.
- Each boundary commit needs its own immediately preceding authorization. One human authorization advances at most one boundary.
- Treat `continue` as: advance to the next single boundary stop, then halt and ask again.
- Expand a single hardening-gate sign-off + implementation authorization paste into two `.squad/decisions.md` entries: one `sign-off` for `hardening-gate-signoff`, one `authorization` for `implementation`. Both keep the same verbatim authorization text and remain reviewable before advancement.
- Boundary-stop narration must use `file:///` URIs for artifact references outside approved exempt contexts.

For per-boundary handoffs:

- **What I just did** — for planning, implementation, review, and retro: include at least 3 concrete identifiers (`file:///`, commit hash, `FR-###`, `T###`, or authorization reference) **and** at least 50 words. For iteration-closeout and feature-closeout, either threshold is enough.
- **Why I stopped** — explicitly name the boundary being entered.
- **What I need from you** — name the boundary being authorized, cite the inspection targets as `file:///` references, and ask for the verdict required.
- **Feature-closeout release SDLC ownership** — when the boundary is `feature-closeout`, include both rows:
  - `AGENT NEXT ACTION:` executes the release SDLC with human approval at each substantive step: Step 5 push the feature branch; Step 6 create the PR with `gh pr create`; Step 7 self-review the PR and address automated PR review; Step 8 merge with a merge commit after approval/checks; Step 9 tag and push `v<next-version>-beta.1`; Step 10 verify prerelease publication with `Find-Module Specrew -AllowPrerelease`; Step 11 PAUSE for the human manual test PASS/FAIL verdict using `Install-Module Specrew -AllowPrerelease` in a clean shell; Step 12 if FAIL, fix on main, tag the next beta such as `beta.2`, and repeat from Step 9; Step 13 if PASS, tag and push `v<next-version>` stable and verify stable publication; Step 14 stop before any new feature work.
  - `HUMAN ACTION NEEDED:` asks the human to approve each agent action when prompted and, at Step 11, install the prerelease with `Install-Module Specrew -AllowPrerelease`, exercise it, and report PASS or FAIL with evidence.

Worked boundary examples:

- **Compliant seven-step cadence**: authorize planning → authorize hardening-gate-and-implementation-auth → authorize implementation → authorize review-boundary → authorize review-verdict-signoff → authorize retro-boundary → authorize iteration-closeout.
- **Violation**: one `continue` leads to review-boundary, retro-boundary, and iteration-closeout commits without fresh authorizations. Treat this as invalid bundled advance and stop instead.

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

### Substantive Boundary Example

**What I just did**  
I updated **the substantive interaction model**, across **FR-001 through FR-019, the Iteration 001 boundary-discipline, console-substance, and click-through rules**. I aligned `file:///C:/Dev/Specrew/.github/agents/squad.agent.md`, `file:///C:/Dev/Specrew/extensions/specrew-speckit/prompts/coordinator-response.md`, and `file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1`, recorded the canonical authorization shape in `.squad/decisions.md`, and verified the governing integration checks still pass before the next boundary.

**Why I stopped**  
I stopped at the review-boundary because the next lifecycle step is the review boundary, and per-boundary discipline allows only one explicitly authorized boundary advance at a time.

**What I need from you**  
Review `file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/plan.md` and `file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/quality/hardening-gate.md`, then approve or reject advancement to the review-boundary.

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
