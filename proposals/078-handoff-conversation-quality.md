---
proposal: 078
title: Handoff Conversation Quality at All Boundary Stops
status: candidate
phase: phase-2
estimated-sp: 10-15
discussion: tbd
---

# Handoff Conversation Quality at All Boundary Stops

## Why

Specrew's value proposition for downstream users is **clear, substantive interaction at every lifecycle pause**. F-014 (Handoff Format Scoping, shipped) established a three-section handoff format — **What I just did / Why I stopped / What I need from you** — and required it at the three primary approval handoffs (specify→plan, tasks→implement, implementation→review).

Empirical evidence from a 2026-05-21 snake-game smoke test running v0.24.0 shows that **at all OTHER boundary stops (review→signoff, signoff→retro, retro→iteration-closeout, iteration-closeout→feature-closeout)**, Squad's prose to the user defaults to **internal gate-name language without the three-section structure and without offered options**.

### Concrete observations from the smoke log

| What Squad said to the user | What's wrong |
|---|---|
| "Next boundary: REVIEW-VERDICT-SIGNOFF and it still requires explicit human authorization." | Uses internal gate name. No "what I just did," no offered options, no verb the user can type |
| "Next boundary: REVIEW-BOUNDARY." | Same — bare boundary name. User has to guess what to type |
| "Iteration 005 implementation is complete. ... Next boundary: REVIEW-BOUNDARY." | Has "what was done" but lacks "what I need from you" with verbs |
| "Feature closeout is blocked. ... Blockers: 1. tasks.md still has T035-T038 open ..." | Substance is buried in a list; user had to ask "explain what is the blocker" because the prose led with the boundary name |
| (2026-05-21 F-029 post-merge) "Feature 029 is merged. PR #386 landed on main with merge commit ... Scribe is done. The merge outcome is now recorded in `.squad/log/`..." | Reports "I'm done" but provides NO "what comes next" — user had to ask explicitly what the next slice should be. No three-section structure at the post-merge completion state. User's words: "the way it answers requires the user to think or to ask what coming next" |

The user had to **infer what to type** at each pause — typing `approved`, `signed`, `continue`, `close it`, `explain what is the blocker` — by trial and error. A downstream developer using Specrew will hit this same friction repeatedly. The "substantive interaction model" F-016 established is undercut when the prose at each pause is opaque.

### User direction (2026-05-21)

> "What I see that is a bit problematic is the conversation with the user. It talks with the names of the gates, not with What I just did, Why I stopped, What I need from you. It does not offer options. It is not so clear for the user."

This is a first-class downstream-user concern, not an internal-developer-of-Specrew concern. Fixing it is methodology-critical for the MVP/RD adoption window.

## What (5 Pillars)

### Pillar 1: Three-section format mandatory at EVERY user-facing pause

Generalize F-014's scope from "three primary approval handoffs" to "every Squad pause requiring human input":

- review→signoff
- signoff→retro
- retro→iteration-closeout
- iteration-closeout→feature-closeout
- **feature-closeout normal path (added 2026-05-26)** — HANDOFF must emit push + PR + Copilot review + merge as `HUMAN ACTION NEEDED` per the PR-at-feature-close SDLC pattern (memory `[[feedback-pr-at-feature-close-sdlc]]`). Not just "approve to advance the boundary." Empirical motivation: 2026-05-26 F-046 Antigravity emitted feature-closeout handoff with "Review the dashboard and findings" as the only human action — no awareness of the PR cycle, missing the entire SDLC pattern. F-045 Codex at the same gate correctly emitted the push/PR/merge sequence. Host-inconsistency in operational awareness is itself a Pillar 1 gap.
- feature-closeout (when blocked)
- **feature-merged-to-main → next-slice-authorization** (post-merge completion state — added 2026-05-21)
- Mid-implementation clarify questions (already partially covered)
- Conditional pause from F-011 on session resume
- **Any voluntary pause-to-report state** — when the Crew completes work and reports back, even if no formal lifecycle gate fired (e.g., scribe-agent completion, validator-warning surfacing, "I'm done with what you asked, what next?")
- **Operational waits (added 2026-05-26)** — when the agent is waiting on a long-running tool, background task, polling external state, or another non-lifecycle resource. Four sub-cases, each with required third-section text:
  - **Background task awaiting completion** (e.g., test runner started in background): "No action needed — I will re-emit when X completes (~N sec/min). You may interrupt with Ctrl+C."
  - **Synchronous wait the user must trigger** (e.g., manual command in another terminal): "Action required: run `<command>` in another terminal, then type 'done'."
  - **External-state polling** (e.g., waiting for PR merge, CI completion, file upload): "Polling X every N sec. Will report when status changes. You may interrupt with Ctrl+C."
  - **Agent self-paused without clear reason** (the worst flavor — agent emits no continuation): this is the failure mode this pillar prevents; should never occur if rules above are honored.

Empirical motivation for operational-pause taxonomy: 2026-05-26 F-046 Antigravity session emitted "I am pausing to let the updated integration test run" and then continued autonomously after the test completed — agent didn't actually need user input but communicated like it was waiting. The user wasted cycles wondering whether to intervene. Captured in detail at [[f046-operational-pause-gap-2026-05-26]] memory; classification as four sub-cases is the durable resolution.

Every pause must include all three sections:

- **What I just did** — substantive summary of work, results, evidence (lead with outcome, not procedure)
- **Why I stopped** — boundary semantics in plain language (not the gate's internal name)
- **What I need from you** — explicit verbs the user can type, ideally a multiple-choice menu

### Pillar 2: No internal gate names in user-facing prose

Replace internal boundary identifiers in user-facing prose:

| Internal name (keep in metadata/state.md) | User-facing prose |
|---|---|
| `REVIEW-BOUNDARY` | "Reviewing the implementation" |
| `REVIEW-VERDICT-SIGNOFF` | "Awaiting your signoff on the reviewer's verdict" |
| `RETRO-BOUNDARY` | "Capturing lessons-learned for this iteration" |
| `ITERATION-CLOSEOUT` | "Closing out this iteration" |
| `FEATURE-CLOSEOUT` | "Closing the feature" |
| `IMPLEMENTATION-APPROVAL` / `BEFORE-IMPLEMENT` | "Ready to start implementation; needs your approval" |
| `POST-MERGE` / `FEATURE-MERGED` (implicit) | "Feature merged to main; ready for next slice" |
| `SCRIBE-COMPLETE` / `AGENT-IDLE` (implicit) | "Background work logged; ready for direction" |

Internal names remain in `state.md`, `decisions.md`, audit trails, and validator-error categories. They MUST NOT appear in the prose Squad speaks to the user, except as a parenthetical for audit traceability if absolutely needed: "Awaiting your signoff (boundary: REVIEW-VERDICT-SIGNOFF)".

### Pillar 2b: No internal Specrew feature/proposal references in downstream-project user-facing prose (added 2026-05-26)

The same principle generalizes from internal gate names to **internal Specrew implementation identifiers**. Downstream-project users do not know (and should not need to know) what "Feature 016" or "Proposal 105" refers to. These are Specrew development artifacts; they have no place in the prose a downstream-project user reads when their agent emits a handoff block.

Replace internal Specrew identifiers with the methodology concept being referenced:

| Bad (leaks Specrew internals) | Good (methodology concept) |
|---|---|
| "Feature 016 only allows one human approval to advance one boundary" | "The methodology allows one human approval to advance one boundary at a time — so the next boundary needs a fresh verdict from you" |
| "Per Proposal 065, this gate requires explicit boundary authorization" | "This gate requires your explicit boundary authorization" |
| "Proposal 055's slice-type catalog says this is a bug-fix-repair slice" | "This is a bug-fix repair (one of the standard slice types in this methodology)" |
| "F-039 Launch-Mode Boundary Enforcement requires…" | "Boundary enforcement requires…" |
| "Per F-046's bug-bash retro lesson…" | "Per the bug-bash retro lesson…" or just drop the citation entirely |
| "Refer to Proposal 119's effort-convention table" | "Refer to the methodology's effort-convention table" |

**Why this matters**: Specrew's downstream users are running THEIR project through Specrew. They don't read Specrew's own roadmap. References like "Feature 016" are accidental noise that erodes trust — the user perceives Specrew as leaking implementation details into their workflow, contradicting the "methodology is the product" promise.

**Where the leak happens**: typically in installed instruction files (per Proposal 099 Installed-File SDLC Instruction Audit) and in coordinator-prompt rules. Auditing + rewriting those files to use methodology-concept language instead of Specrew-internal references is the corrective work.

**Empirical motivation**: 2026-05-26 PlanningPoC downstream-project handoff block emitted "I stopped at the retro boundary because Feature 016 only allows one human approval to advance one boundary." The user has no idea what Feature 016 is and shouldn't need to. The agent should have said "The methodology only allows one human approval to advance one boundary at a time — review-signoff is done, and starting the retrospective needs a fresh verdict from you."

**Exception** — Specrew's OWN repo (this one) is its own downstream project, but the maintainer (the same person developing Specrew) DOES know what Feature 016 is. The rule applies to **downstream-project user-facing prose**, not to internal Specrew development sessions where the audience knows the lineage. The way to distinguish: would a user who installed Specrew via `Install-Module Specrew` and is running their own project benefit from this reference? If no → drop the reference and use the methodology concept.

### Pillar 3: Multiple-choice options with explicit verbs + escape routes

Every user-facing pause offers a menu structured for both quick decisions AND richer input when needed:

```text
What I need from you:

  1. <option A — boundary-specific verb>
  2. <option B>
  3. <option C>
  4. Other (specify) — type a short answer for this specific question
  5. More chat instructions — return to standard prompt for richer input

Type 1-5, a verb, or a longer directive.
```

The two escape routes matter:

- **"Other (specify)"** handles the case where the user's answer doesn't fit the offered options but IS short enough for the constrained input slot. They pick "Other" and type the brief alternative.
- **"More chat instructions"** handles the case where the user needs to provide a richer/longer response than the constrained input slot accepts. Squad acknowledges and **returns to the standard conversational prompt** — the same Copilot CLI prompt the user gets at session start, which accepts arbitrary-length input. No file-pointer hacks, no session restart, no information loss.

Example transformation:

**Before** (current v0.24.0 behavior, observed in 2026-05-21 smoke log):

> Next boundary: REVIEW-VERDICT-SIGNOFF and it still requires explicit human authorization.

**After** (this proposal):

> **What I need from you**:
>
> 1. **approve** — accept the verdict and advance to retro
> 2. **reject** — return to implementation with specific concerns
> 3. **request changes** — accept conditionally with notes
> 4. **Other (specify)** — short alternative answer
> 5. **More chat instructions** — back to standard prompt for richer input

The "More chat instructions" path is the **methodological replacement for the file-pointer workaround** documented in memory `[[feedback-long-handoff-via-file-pointer]]`. When 078 ships, that workaround becomes unnecessary — the user picks option 5 and the prompt widens back to rich-input mode.

**Composes with Proposal 063 (Substantive Intake Questioning)**: Squad's preference is to ask multiple short MCQs rather than one giant free-form question, matching the intake interview pattern. When rich input IS needed, the "More chat instructions" escape is available without losing the structured conversation flow.

The exact verb-set depends on the boundary; the structural pattern (1-3 boundary options + Other + More-instructions) is consistent.

### Pillar 4: Substance-first prose ordering

Squad's prose must lead with **the substantive outcome of the work**, not the procedural boundary state:

**Before** (buries substance under ceremony):

> Feature closeout is blocked. The feature cannot be closed truthfully yet.
> Files changed: .squad\decisions.md, .squad\agents\spec-steward\history.md.
> Blockers:
>
> 1. tasks.md still has T035-T038 open.
> ...

**After** (lead with substance, then boundary state):

> **Feature 001 cannot close yet — 4 blockers found:**
>
> 1. 4 implementation tasks still open (T035-T038)
> 2. 2 known gaps unresolved (G001 FR-013, G002 FR-014)
> 3. Closeout dashboard stale (reflects only earlier slice)
>
> **What I need from you**: run a new iteration to close T035-T038, resolve G001/G002, refresh the dashboard. OR explicitly waive each blocker with human-approved feature-level rationale.

This is the principle Proposal 053 (Autopilot Decision Transparency) applies to decisions; this proposal applies it to boundary pauses.

### Pillar 5: Validator-enforced handoff-prose grading

Add a validator rule (composes with Proposal 030 Quality Hardening Bundle) that grades handoff prose at boundary stops:

- Three sections present? (form check)
- No internal gate names in user-facing prose? (regex check against known internals)
- At least one offered verb/option? (heuristic check)
- Substance-lead ordering (leads with outcome before ceremony)?

Grades severity:

- HARD-FAIL when all three sections are missing
- WARNING when internal gate names leak into user prose (Pillar 2)
- WARNING when internal Specrew feature/proposal references leak into downstream-project user prose (Pillar 2b — regex check for `\bF-\d{3,}\b` or `\bProposal \d{3,}\b` or `\bFeature \d{3,}\b` patterns)
- WARNING when no options offered
- INFO when prose is structured but could be sharper

The grader runs at the pre-handoff boundary, similar to how F-028's pre-review commit gate runs. If a handoff is graded HARD-FAIL, Squad's coordinator-governance prompt instructs it to repair before emitting to the user.

## How (one-iteration plan)

- Feature branch from `main`
- Squad drives specify → clarify → plan → tasks → implement → review → retro → closeout
- New files / changes:
  - `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` — update Pillar 1, 2, 3, 4 instructions for Squad's coordinator (instruct on prose format + language + options at all boundaries)
  - `extensions/specrew-speckit/scripts/grade-handoff-prose.ps1` (new) — Pillar 5 grader
  - `extensions/specrew-speckit/scripts/validate-governance.ps1` — invoke the grader as a new validator rule
  - `extensions/specrew-speckit/data/boundary-language-map.yml` (new) — maps internal gate names to user-facing prose
  - Tests at `tests/integration/handoff-prose-grading.tests.ps1` (new) — cover passing prose, missing-section, internal-name leak, no-options
- CHANGELOG entry
- INDEX update at feature-closeout (candidate → shipped)

Estimated: 10-15 SP. Phase 2. Could be staged into a v0.24.x patch release or rolled into v0.25.0 depending on F-029 timing.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-014 (Handoff Format Scoping, shipped)** | This proposal extends F-014's three-section format from the three approval handoffs to ALL human-facing boundary pauses. F-014's format is preserved; the scope of where it applies widens |
| **F-016 (Substantive Interaction Model, shipped)** | This proposal sharpens F-016's prose-quality dimension. F-016 ensures Squad PAUSES where human judgment is required; this proposal ensures the prose at those pauses is genuinely substantive and actionable |
| **Proposal 029 (Handoff Format Scoping Refinement, candidate)** | **SUBSUMED.** 029's scope (narrow the format to actual stops; add soft-validator detection) is wholly contained within this proposal's Pillar 1 + Pillar 5. When 078 ships, 029 marks status as "absorbed-into-078" |
| **Proposal 053 (Autopilot Decision Transparency, candidate)** | Parallel concern — 053 sharpens DECISION prose; 078 sharpens BOUNDARY prose. Composable; both can ship independently |
| **Proposal 077 (Session Resume UX, candidate)** | 077's Pillar 4 (context-rich resume prompt) is a specific case of 078's general principle. When 078 ships, 077's Pillar 4 reduces to "apply 078's pattern at the resume boundary" |
| **Proposal 030 (Quality Hardening Bundle, draft)** | Pillar 5 grader plugs into 030's form-vs-meaning surface — extends the form-vs-meaning principle to handoff prose quality |
| **Proposal 067 (Small-Fix Slice Type)** | Some prose-quality fixes (e.g., a single boundary's language) could ship as small-fix slices. 078 is the substantial-feature version |

## Acceptance signals

- **AC1**: A `specrew start` session resuming after a shipped feature surfaces prose like "Feature F-NNN was shipped; no active feature now — what would you like to do?" rather than the internal `feature-closeout` boundary name with bare "continue?" prompt
- **AC2**: Every Squad boundary pause emits all three sections (What I did / Why I stopped / What I need)
- **AC3**: No internal gate names (`REVIEW-BOUNDARY`, `RETRO-BOUNDARY`, `ITERATION-CLOSEOUT`, etc.) appear in user-facing prose — confirmed by validator grader (Pillar 2)
- **AC3b**: No internal Specrew feature/proposal references (`F-016`, `Proposal 065`, `Feature 046`, etc.) appear in downstream-project user-facing prose — confirmed by validator grader's regex check (Pillar 2b); installed instruction files audit per Proposal 099 ensures source language is methodology-concept-based
- **AC4**: Every user-facing pause offers at least one verb/option the user can type — confirmed by validator grader
- **AC5**: The smoke project's iteration-005 review boundary, replayed under this proposal, produces prose matching the "approve / reject / request changes / provide context" pattern with substantive "what I just did" leading the message
- **AC6**: Validator grader emits HARD-FAIL when handoff prose violates form (missing all three sections); WARNING when internal-name leak or no-options detected
- **AC7**: `boundary-language-map.yml` covers all currently-known internal gate names with user-facing translations
- **AC8**: Existing F-014-scoped handoffs (the three primary approval handoffs) continue to pass — no regression of the established baseline

## Out of scope

- Prose-quality improvements to the SUBSTANCE of clarify questions (that's F-029 Substantive Intake territory)
- Prose-quality improvements to README, user-guide, or other static docs
- Animation, emoji, color, or other formatting beyond markdown
- Localization beyond English

## Cross-references

- **Empirical motivation**: 2026-05-21 snake-game smoke trial showing boundary pauses using bare internal names without three-section format or offered options. User direction in 2026-05-21 conversation: "It talks with the names of the gates, not with What I just did, Why I stopped, What I need from you. It does not offer options."
- Proposal 005 (Handoff Format Scoping, shipped — F-014): file:///C:/Dev/Specrew/proposals/005-handoff-format-scoping.md
- Proposal 007 (Substantive Interaction Model, shipped — F-016): file:///C:/Dev/Specrew/proposals/007-substantive-interaction-model.md
- Proposal 029 (Handoff Format Scoping Refinement, **subsumed by this proposal**): file:///C:/Dev/Specrew/proposals/029-handoff-format-scoping-refinement.md
- Proposal 030 (Quality Hardening Bundle): file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- Proposal 053 (Autopilot Decision Transparency): file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md
- Proposal 077 (Session Resume UX): file:///C:/Dev/Specrew/proposals/077-session-resume-ux.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
