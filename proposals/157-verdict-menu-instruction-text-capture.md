---
proposal: 157
title: Verdict-Menu Instruction-Text Capture
status: candidate
phase: phase-2
estimated-sp: 5-8
discussion: surfaced 2026-06-02 during Feature 141; escalated 2026-06-03 (maintainer-explicit "add the need to fix") after it recurred ~5x in one session — selecting an instruction-bearing verdict records the choice but collects no instruction text, forcing a wasted round-trip each time.
---

# Verdict-Menu Instruction-Text Capture

## Why

The boundary verdict menu (rendered via the Claude Code `AskUserQuestion` verdict contract
— Rule 53 / Proposals 007 / 151 / 155) offers **instruction-bearing verdicts** such as
**"Approve with instructions"**, **"Start with instructions"**, and **"Discuss prompt #N"**.
Selecting one records the *selection* but provides **no place to enter the instruction text,
and transmits none**. The agent then has to report "no instruction text came through" and ask
again — a wasted round-trip on every use.

This recurred ~5 times in a single Feature-141 session, and again at Feature-141 iteration-3
plan approval (2026-06-03), at which point the maintainer supplied the instructions manually
and directed that the fix-need be recorded. It is a confirmed, maintainer-prioritized gap in
the verdict-menu **rendering contract** — not a lifecycle-runtime bug.

The cost is structural: the entire point of an "…with instructions" verdict is to carry the
maintainer's steering **into** the next turn. When the text is dropped, the verdict degrades
to a plain approve/start and the steering is lost until an extra prompt recovers it — exactly
the kind of friction the verdict contract exists to remove.

## What

Make instruction-bearing verdicts collect their free-form text **inline, before the turn
returns**, so the instructions arrive together with the selection.

Affected verdicts (any verdict whose semantics include caller-supplied text):

- `approve with instructions`
- `start with instructions`
- `discuss prompt #N`
- any future instruction-bearing verdict

Required behavior on **both** rendering paths:

1. **Claude-host `AskUserQuestion` path** — selecting an instruction-bearing verdict MUST
   collect free-form text in the same interaction (e.g., the option carries a text field, or
   the menu immediately re-prompts for the text), so the selection **and** its text return in
   one turn.
2. **Textual fallback path** (non-`AskUserQuestion` hosts / degraded rendering) — the menu MUST
   prompt for the instruction text inline after the selection, before the turn returns.

Until the fix ships, the documented workaround stands: when a user picks an "…with
instructions" verdict and no text arrives, ask once concisely for the instructions rather than
proceeding on a guess.

## Scope / Non-goals

- **In:** the verdict-menu rendering contract + both rendering paths; the instruction-bearing
  verdict set; the agent-side handling that today reports "no text came through."
- **Out:** the verdict vocabulary / boundary semantics themselves (Proposals 007 / 151 / 155);
  verdict-boundary naming discipline (separate 2026-05-22 feedback).

## Composes with

- Proposals **007 / 151 / 155** — the verdict-menu / boundary-verdict contract this amends.
- **Verdict-boundary naming discipline** (2026-05-22 feedback) — same menu, adjacent concern.

## Acceptance

- Selecting each instruction-bearing verdict returns **both** the selection and the free-form
  text in a single turn, on the `AskUserQuestion` path and the textual fallback.
- No "no instruction text came through → ask again" round-trip remains for these verdicts.
- A regression check exercises an instruction-bearing verdict and asserts the text is captured
  and transmitted.
