---
proposal: 165
title: PreToolUse Render-Gate Hook — host-specific non-discretionary enforcement of render-before-a-menu (Claude Code) — RESEARCH-NEEDED
status: candidate
phase: phase-2
estimated-sp: 8-15 (research/tuning-dependent; see Research Needed)
priority-tier: 2
discussion: surfaced 2026-06-06 at Feature 141 iteration-012 closeout. The A8 governing model (open-discussion renders hold on Claude; before-a-menu renders skim — the AskUserQuestion tool-gravity) was established empirically across six dogfood edits, and the residual before-a-menu cases (the lens agenda; the design-analysis-stop component map) were dispositioned accept-as-minor. A PreToolUse hook is the ONLY non-discretionary lever (it enforces at the tool-call boundary, outside the model's context) and is the deliberate, optional follow-up. Research-flavored: the detection robustness is the crux, not the mechanism.
---

# PreToolUse Render-Gate Hook (Claude Code)

## Why

Feature 141 (Amendments A4–A8) hardened the design workshop and converged on a **governing model**, proven
empirically across the testLenses dogfood series:

- Content whose next move is **open discussion** (a per-lens open: present + an open question) **renders
  reliably on Claude**.
- Content that must render **right before a structured menu** (the lens catalog/agenda before the
  agenda-confirm; a component map before its approve menu) is defeated by the **`AskUserQuestion`
  tool-gravity** — the model puts the thing-being-confirmed *into* the call's `question`/option fields instead
  of rendering it first — and **skims on Claude**.

Six conduct edits (prose rules, the exact anti-pattern named, fill-in templates, open-question-first) could not
make the *before-a-menu* render hold on Claude, because every one of them lives **inside the model's context**,
where the model can skim or reinterpret it. The iteration-12 maintainer disposition was **accept-as-minor** for
the residual cases, with the hook recorded as the optional reliable fix.

This proposal captures that fix. A **PreToolUse hook** is the only lever that is **non-discretionary** — it
lives in Claude Code's runtime, *outside* the model's context, and gates the tool call itself. The model cannot
skim a shell script that decides whether its `AskUserQuestion` is allowed to run.

## What

A Claude Code **PreToolUse hook** matched to the **`AskUserQuestion`** tool that, for workshop confirm-menus,
**denies the call when the content it confirms was not rendered first**, returning a render-first reason the
model must satisfy before the menu can run.

### Mechanism

- **Config** (`.claude/settings.json`): a `PreToolUse` entry with `matcher: "AskUserQuestion"` pointing at a
  `command` hook (a script shipped with Specrew).
- **The hook receives** (stdin JSON): `tool_name`, `tool_input` (the question + options), and
  `transcript_path` (the conversation so far).
- **Detection** (the crux — see Research Needed):
  1. Is this a **workshop confirm-menu**? — e.g., the question is about a lens agenda, a component map, or an
     options set; detected via the question text, the active boundary/skill in session state, or an explicit
     marker the skill emits.
  2. Was the **content rendered** in the model's preceding assistant message(s)? — read `transcript_path` and
     check whether the agenda list / the component-map block actually appears before the call, versus the menu
     standing on a bare reference ("above", "as shown", a bare count like "8 lenses" / "13 components").
- **Decision**: if it is a workshop confirm-menu AND the content was not rendered, **deny** with a
  `permissionDecisionReason` of *"render the agenda / component map in your message first, then re-raise the
  menu."* The model renders and re-asks; the second attempt passes.
- **Default-allow**: anything that is not a detected unrendered workshop confirm-menu passes untouched. The hook
  must be conservative — a false deny that blocks a legitimate menu is worse than a missed skim.

### Deployment + host posture

- The hook script and the `.claude/settings.json` entry deploy per-project alongside the
  `specrew-design-workshop` skill (the F-021/F-044 deploy loop).
- **Claude-only by design.** Hooks are a Claude Code feature; Copilot/Squad, Codex, and Antigravity do not have
  this exact mechanism — and they do not need it (they render in prose naturally; the before-a-menu skim is
  Claude-specific). This composes with the **host-neutral** skill: the skill carries the conduct for every host,
  and the hook is a Claude-only *enforcement accelerator* layered on top — the Proposal 145 posture that
  instruction files teach while validators/hooks enforce where the host supports them.

## The central question: detection robustness (RESEARCH-NEEDED)

The mechanism is clear; the **detection is the crux**, and it is what makes this research-flavored rather than a
straight build:

1. **"Is this a workshop confirm-menu?"** — too broad a match gates every `AskUserQuestion` (intrusive,
   fragile); too narrow misses the cases. Candidate signals: the question text, the active boundary/skill in
   session state, or an explicit marker the skill emits.
2. **"Was the content rendered?"** — parsing `transcript_path` to decide whether the agenda/map appears before
   the call. A heuristic on the menu text (catch "above" / a bare count) is cheap but imperfect; transcript
   inspection is stronger but more work.
3. **False-positive tolerance** — a wrong deny blocks a legitimate menu and frustrates the user, so the gate
   must bias hard toward allow.

## Research Needed (before spec conversion) — maintainer-flagged

**Convert to a spec only after the detection design is settled.** The decisive choice:

1. **Marker-driven vs transcript-parsing.** The cleanest design has the **skill emit a machine-readable marker**
   (e.g., a sentinel in the message, or a session-state flag) at each confirm point, turning the hook's fuzzy
   "is this a workshop confirm + was it rendered?" inference into a **deterministic check**. Validate this
   against transcript-parsing (the hook reasons from the conversation alone) on robustness, testability, and
   false-positive rate.
2. **The Claude Code hook contract** — confirm the current `PreToolUse` stdin schema and the
   deny/`permissionDecision` output shape against the live docs (the hook API evolves), plus the exact
   `.claude/settings.json` shape and merge semantics.
3. **Deployment** — how the settings entry + script land in downstream projects **without clobbering** a user's
   existing hooks; mirror-parity (Proposal 132) for the hook artifact.
4. **Scope** — workshop confirm-menus only, or a general render-before-a-menu gate for any Specrew menu (the
   verdict menu, etc.)? Keep v1 narrow; design the interface for later breadth.
5. **Whether it is worth it at all** — the maintainer dispositioned the residual as accept-as-minor; this
   proposal must clear that bar (does reliable agenda/map rendering on Claude matter enough to justify
   host-specific machinery).

## Composition map

- **Feature 141 / Amendment A8** — the governing model + the accept-as-minor disposition this proposal would buy
  back; the `specrew-design-workshop` skill is the conduct layer the hook enforces.
- [[145-structured-multi-phase-reviewer]] — the host-capability-matrix posture (Claude has the richest hooks;
  instruction files teach, validators/hooks enforce); 145 also wants hooks for context refresh.
- [[146-specrew-refocus-slash-command]] — a sibling Claude-hook use (auto-refocus at PreCompact/PostCompact);
  both are "hooks as host-specific accelerators on top of host-neutral content."
- [[132-mirror-parity-validator-enforcement]] — protects the hook artifact from host drift.
- **Proposal 058** (plugin-based distribution) — the per-host deploy of the hook + settings.

## Sizing

~8–15 SP, research/tuning-dependent: the hook script and the detection logic (the bulk — the research lives
here), the `.claude/settings.json` deploy wiring (merge, not overwrite), tests (the deny fires on an unrendered
workshop menu, allows a rendered one, and allows a non-workshop menu), and a Claude-host dogfood (the agenda/map
now render before the menu). The lower end if the skill emits a marker the hook keys on (deterministic); the
upper end if the detection must parse the transcript heuristically.

## Open questions

- Marker-driven (the skill emits a machine-readable "about to confirm X" marker the hook checks) vs
  transcript-parsing (the hook infers from the conversation)? Marker is more deterministic and testable.
- Workshop-only vs a general render-before-a-menu gate?
- Deny-and-retry vs `ask` (downgrade to a permission prompt the human resolves)?
- How to avoid clobbering a downstream user's own `.claude/settings.json` hooks (merge strategy).
- Does it stay Claude-only, or do Codex/Gemini hook surfaces (per 145's matrix) warrant parallel adapters later?

## Risks

- **False positives** — a wrong deny blocks a legitimate menu; the gate must bias to allow, and a marker-driven
  design reduces this risk versus fuzzy text-detection.
- **Host-specific + maintenance** — the hook is Claude-only and rides Claude Code's evolving hook API; it needs
  a currency check against the docs.
- **Over-enforcement / annoyance** — gating tool calls is intrusive; the value (reliable agenda/map render) must
  clear the accept-as-minor bar the maintainer already set.
- **Deploy collision** — injecting into `.claude/settings.json` must merge with, not overwrite, a user's hooks.
- **Scope creep** — "a general menu-render gate" could balloon; keep v1 to the workshop confirm-menus.
