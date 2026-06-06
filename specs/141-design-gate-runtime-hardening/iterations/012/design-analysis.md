# Design Analysis: Iteration 012 (Amendment A8 / FR-041)

**Schema**: v1
**Status**: decided
**Decision**: Option A — front-loaded catalog (structural) + open-question-first (conduct); reuse the existing lens definitions; no command, no hook in i12.

## Problem

i11's consolidated dogfood (testLenses8 + testLenses11) proved render-before-the-menu **conduct** is defeated
on Claude by the `AskUserQuestion` tool-gravity: the call's `question` + option `description` fields are a
content sink, so the agent puts the thing-being-confirmed *into* the call instead of rendering it first. Prose
AND fill-in templates both skimmed for the same reason. FR-041 is the corrected implementation of FR-037/FR-040.

## Options considered

- **Option A (CHOSEN): front-loaded catalog + open-question-first.**
  - (a) Present all 9 lenses + the one-line decision each raises ONCE at workshop open — *structural*
    front-loading. It decouples "show the lenses" from "confirm the selection"; the later applicability menu is
    informed by content already on screen, so it holds *by construction* (not by the agent finally obeying
    render-before-menu). Reuse `index.yml` (the lens list) + each `design-lenses/<id>.md` (the one-liner) — no
    parallel catalog that can drift.
  - (b) Each lens opens with a presentation + an **open (free-text) question**, never an `AskUserQuestion` menu
    as the first move — the strongest available *conduct* lever: binary (a lens either opened with a menu or it
    didn't) and not satisfiable by stuffing the menu's question field. Behavioral, not a guarantee.
- **Option B (REJECTED): a `workshop show` print-command.** For generated content (the component map) the
  render is conduct either way; a print-command adds machinery without adding enforcement — conduct dressed as
  mechanism (advisor).
- **Option C (DEFERRED): a host-specific `PreToolUse` hook** that blocks an `AskUserQuestion` with no preceding
  render. The ONLY actually-non-discretionary lever on Claude, but host-specific real work. Deferred as the
  **pre-committed escalation** IF the dogfood shows the component map still stuffed into the menu — decided with
  the maintainer, not built speculatively for a finding the maintainer called minor.

## The honest split (advisor-checked pre-build)

- (a) catalog-at-open is **structural** — it works by front-loading information. The agenda WILL hold on every host.
- (b) open-question-first is **conduct** — the best available (binary), but behavioral; the **component-map
  render is the case the dogfood (SC-028) actually tests**. FR-041 / SC-028 were refined (commit `26ef631e`) to
  read this honestly so i12's own review does not walk into the form-vs-substance trap i11's closeout documented.

## Acceptance

- **Deterministic:** presence-lock the catalog-at-open step + the open-question-first rule in the skill (T003).
- **Behavioral:** the consolidated cross-host re-dogfood (T004 — SC-028 + carried SC-027), maintainer-run.
