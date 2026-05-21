---
proposal: 077
title: Session Resume UX for Downstream Specrew Users
status: candidate
phase: phase-2
estimated-sp: 10-15
discussion: tbd
---

# Session Resume UX

## Why

Specrew's value proposition is "manage AI-driven SDLC for developers." But a real developer using Specrew on their project will stop and restart sessions constantly — daily, mid-feature, after interruptions, across machines. The session-resume UX is therefore not a developer-of-Specrew concern; it's a **first-class concern for every downstream Specrew user**. If `specrew start` after a stop produces confusing prompts, missing context, or constrained input slots, users will bounce.

### Empirical motivation (2026-05-21)

While developing F-028 itself, the Specrew developer (Alon) hit four distinct session-resume pain points in a single session:

| Pain point | What happened | What should have happened |
|---|---|---|
| **Stale active-feature reference** | After F-028 shipped, `specrew start` triggered F-011's conditional pause and asked "Continue the lifecycle for feature 028-review-evidence-integrity?" — even though F-028 had merged | "No active feature. What would you like to start?" |
| **F-011 misfires on benign churn** | 4 sync-agent files showed up as "session-loaded files changed" — these were the result of a previous chore deploying them; not user-meaningful | F-011's change detection filters benign tooling churn from user-meaningful change |
| **Directive prompt too short for rich answer** | When asked "Provide a directive," the input slot only accepts a short line. A multi-pillar handoff didn't fit — the user pasted a compact 4-pillar directive, omitting Pillar E | A standard convention: "if your directive is long, write to `.specrew/staged-directive.md` and Squad reads it" |
| **No discoverable session state** | The user had to read `.specrew/start-context.json` manually to understand where the lifecycle was paused | A `specrew resume --status` command (or context-rich F-011 prompt) summarizes "Last touched F-NNN at <boundary>; last action was <X>; pending decisions: <Y>" |

These are all gaps a downstream Specrew user will hit. The methodology fix needs to be **systemic** — built into Specrew's launch/resume surface — not adhoc workarounds the user has to invent.

### User direction (2026-05-21)

> "The main concern is not how we develop Specrew. The main concern is the developers that will use Specrew for their project. What will be their experience when they will stop and restart a session."

That reframe is correct. This proposal addresses the four pain points as a coherent surface.

## What (5 Pillars)

### Pillar 1: Smarter F-011 change detection

In `scripts/specrew-start.ps1`'s conditional-pause logic (F-011 surface):

- **Filter benign churn from "session-loaded files changed" trigger**: changes to skill `.agent.md` files newly deployed by `specrew update`, `decisions.md` routing-evidence entries, `last-start-prompt.md` itself, `last-validator-summary.json` should NOT trigger the pause
- **Preserve user-meaningful triggers**: changes to user-authored skill content, charter changes, baseline-roster edits, coordinator-governance prompt overrides, `.squad/identity/wisdom.md` SHOULD trigger
- Tighter trigger surface = fewer false-positive pauses; users only get prompted when something they care about changed

Composes with the global-state-list refinement chore (currently in flight as v0.24.2). Same principle: distinguish load-bearing change from session-state churn.

### Pillar 2: Pivot directive convention

When a user is mid-feature but wants to pivot:

- Add explicit prompt option in F-011's pause: "Pause F-NNN and start something else"
- New flag: `specrew start --pivot "<short directive>"` OR `specrew start --pivot-from-file <path>` to accept a longer pivot directive without exiting and restarting the session
- Pivot semantics: gracefully marks the in-flight feature as "paused — pivoted on YYYY-MM-DD", preserves state for later resume, switches focus to the new directive
- Resume-after-pivot: `specrew start --resume F-NNN` (or similar) returns to the paused feature when ready

The pivot surface acknowledges that real users don't always finish what they start. Currently they have to manually edit state files or live with Squad still pointing at the old feature.

### Pillar 3: Long-directive file convention

Specrew documents and consumes a canonical convention for long directives that don't fit a prompt slot:

- Designated path: `.specrew/staged-directive.md` (gitignored or in `.gitignore` template)
- When user wants to provide a rich, multi-paragraph directive at `specrew start`, they write the directive to this file ahead of time
- `specrew start` reads it automatically if present; processes the directive; archives the file (renames to `.specrew/staged-directive.archived-<timestamp>.md` for audit) or deletes
- Squad's "Provide a directive" prompt offers a third option: "Read from `.specrew/staged-directive.md`" alongside "short text" and "multiple choice"
- Documented in `docs/user-guide.md` with examples

This makes the file-pointer pattern (currently a private workaround for the Specrew-developer) a first-class downstream convention.

### Pillar 4: Context-rich F-011 resume prompt

Replace the bare "Continue the lifecycle for feature X?" with a contextual summary:

```text
=== Specrew Session Resume ===

You're picking up work in Specrew project: <project-name>

Last touched: Feature 029 (Substantive Intake Questioning)
Last completed boundary: speckit.clarify (Q3 answered)
Last action: 2026-05-22T14:30:00Z by alonf
Next valid step: speckit.specrew-speckit.before-plan
Pending decisions: 3 clarify questions (Q4, Q5, Q6)
Validator state: clean

What would you like to do?
  1. Continue lifecycle (next step: before-plan boundary)
  2. Pause F-029 and start something else
  3. Inspect current state without advancing
  4. Provide a directive (short)
  5. Read staged directive from .specrew/staged-directive.md
```

User sees what they were doing without having to recall it. Especially valuable after multi-day gaps.

### Pillar 5: `specrew resume --status` discovery command

Standalone command that surfaces session state WITHOUT launching Squad:

```text
$ specrew resume --status
Current session state for C:\path\to\project:
  Active feature: F-029 (Substantive Intake Questioning)
  Boundary: clarify
  Last action: 2026-05-22T14:30:00Z
  Worktree: C:\path\to\worktree-029
  Pending decisions: 3 clarify questions awaiting answer
  Validator state: clean
  Squad-managed model overrides: none active

Suggested next action: cd to worktree, run 'specrew start' to advance lifecycle
```

This lets a user check "where did I leave off?" before committing to a full Squad session. Cheap pre-flight check. Composes with `specrew where` (which shows the velocity dashboard but not session state).

## How (one-iteration plan)

- Feature branch from `main`
- Squad drives specify → clarify → plan → tasks → implement → review → retro → closeout
- New files / changes:
  - `scripts/specrew-start.ps1` — Pillars 1 (smarter change detection), 2 (pivot flag), 3 (staged-directive reading), 4 (context-rich prompt)
  - `scripts/specrew-resume.ps1` (new) OR extension of `scripts/specrew-where.ps1` — Pillar 5
  - `docs/user-guide.md` — document staged-directive convention + pivot semantics + resume command
  - `.specrew/staged-directive.md.template` (committed empty template) + `.gitignore` entry for the live file
  - New integration tests: F-011 false-positive scenarios; pivot end-to-end; staged-directive file flow; resume-status output shape
- CHANGELOG entry
- INDEX update at feature-closeout (candidate → shipped)

Estimated: 10-15 SP. Plus 1-2 SP if Pillar 5 needs new CLI dispatcher infrastructure (depends on Proposal 033's CLI shape).

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-011 (Specrew-start Conditional Pause, shipped)** | This proposal sharpens F-011's behavior (Pillars 1 and 4 are direct refinements). Composes naturally |
| **035 (Session-State Durability, draft)** | Provides the underlying state-durability surface this proposal's resume-status command reads. Strong composition; 077 may be absorbed into 035 if 035 enters the lifecycle first |
| **Pillar E of v0.24.2 chore** (Feature-closeout active-pointer hygiene) | Directly addresses one specific case (post-closeout stale pointer). Pillar 1 of this proposal generalizes the change-detection-quality concern |
| **033 (Specrew Governance CLI, draft)** | Pillar 5's `specrew resume --status` lands in 033's CLI dispatcher |
| **F-029 (Substantive Intake)** | Resume into a clarify boundary is one of the most common scenarios for downstream users; this proposal's Pillar 4 prompt explicitly handles it |
| **053 (Autopilot Decision Transparency)** | Pillar 4's "pending decisions: 3" list draws on 053's auto-resolution surface when 053 ships |
| **025 (JIT Codebase Cartography)** | For brownfield projects on Specrew, the resume prompt could include "code state at last action" — defer to 025 |

## Acceptance signals

- **AC1**: After feature-closeout, `specrew start` does NOT ask "continue F-NNN?" for the shipped feature; instead surfaces "no active feature, what next?" (covers Pillar 4 + Pillar E of the v0.24.2 chore)
- **AC2**: Changes to sync-agent files, decisions.md routing entries, last-start-prompt.md do NOT trigger F-011's pause (Pillar 1 filter)
- **AC3**: Changes to charter files, baseline-roster, coordinator-governance, wisdom.md DO trigger F-011's pause (Pillar 1 preserved)
- **AC4**: `specrew start --pivot "build feature X"` pauses the current feature with a recorded pivot timestamp and switches focus to the new directive without losing the prior state
- **AC5**: Writing a long directive to `.specrew/staged-directive.md` and running `specrew start` consumes it correctly and archives the file with a timestamp
- **AC6**: F-011's resume prompt includes the contextual summary (last feature, boundary, last action, pending decisions, validator state)
- **AC7**: `specrew resume --status` returns a parseable summary of session state without launching Squad
- **AC8**: Integration tests exercise all five pillars with realistic fixtures (post-closeout, mid-feature, post-pivot, post-staged-directive consumption)

## Out of scope

- Multi-developer reconciliation (Proposal 010) — what happens when two developers resume the same project simultaneously
- Cross-machine state sync — out of scope; users handle via git
- Pivot history visualization in the dashboard — Proposal 048 territory if it grows
- Automatic pivot suggestions ("you've paused F-029 for 7 days; reconsider?") — too smart for v1; defer

## Cross-references

- **Empirical motivation**: 2026-05-21 session at C:\Dev\Specrew where the user hit four resume pain points back-to-back
- **User direction**: 2026-05-21 conversation, "The main concern is not how we develop Specrew. The main concern is the developers that will use Specrew for their project."
- Memory: `[[feedback-long-handoff-via-file-pointer]]` — captured the file-pointer pattern as developer-of-Specrew workaround; this proposal makes it a downstream-user convention
- Proposal 011 (Specrew-start Conditional Pause, shipped — F-011): file:///C:/Dev/Specrew/proposals/002-specrew-start-conditional-pause.md
- Proposal 035 (Session-State Durability, draft): file:///C:/Dev/Specrew/proposals/035-session-state-durability.md
- Proposal 033 (Governance CLI, draft): file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md
- Proposal 053 (Autopilot Decision Transparency, candidate): file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md
- Pillar E of v0.24.2 chore (queued as small follow-up): see `[[project-post-f028-sequencing-locked-2026-05-21]]`
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
