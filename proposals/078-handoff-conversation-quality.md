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
- feature-closeout (when blocked)
- Mid-implementation clarify questions (already partially covered)
- Conditional pause from F-011 on session resume

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

Internal names remain in `state.md`, `decisions.md`, audit trails, and validator-error categories. They MUST NOT appear in the prose Squad speaks to the user, except as a parenthetical for audit traceability if absolutely needed: "Awaiting your signoff (boundary: REVIEW-VERDICT-SIGNOFF)".

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
>   1. **approve** — accept the verdict and advance to retro
>   2. **reject** — return to implementation with specific concerns
>   3. **request changes** — accept conditionally with notes
>   4. **Other (specify)** — short alternative answer
>   5. **More chat instructions** — back to standard prompt for richer input

The "More chat instructions" path is the **methodological replacement for the file-pointer workaround** documented in memory `[[feedback-long-handoff-via-file-pointer]]`. When 078 ships, that workaround becomes unnecessary — the user picks option 5 and the prompt widens back to rich-input mode.

**Composes with Proposal 063 (Substantive Intake Questioning)**: Squad's preference is to ask multiple short MCQs rather than one giant free-form question, matching the intake interview pattern. When rich input IS needed, the "More chat instructions" escape is available without losing the structured conversation flow.

The exact verb-set depends on the boundary; the structural pattern (1-3 boundary options + Other + More-instructions) is consistent.

### Pillar 4: Substance-first prose ordering

Squad's prose must lead with **the substantive outcome of the work**, not the procedural boundary state:

**Before** (buries substance under ceremony):

> Feature closeout is blocked. The feature cannot be closed truthfully yet.
> Files changed: .squad\decisions.md, .squad\agents\spec-steward\history.md.
> Blockers:
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
- WARNING when internal gate names leak into user prose
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
- **AC3**: No internal gate names (`REVIEW-BOUNDARY`, `RETRO-BOUNDARY`, `ITERATION-CLOSEOUT`, etc.) appear in user-facing prose — confirmed by validator grader
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
