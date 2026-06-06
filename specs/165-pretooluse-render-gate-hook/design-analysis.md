# Design Analysis: Proposal 165 — PreToolUse Render-Gate Hook

**Feature**: 165-pretooluse-render-gate-hook
**Status**: design-analysis (pre-`specify`; Proposal 165 flagged RESEARCH-NEEDED)
**Date**: 2026-06-06
**Branch**: `165-pretooluse-render-gate-hook` (off `main` @ the #1761 merge)

## Problem (Proposal 165 / Feature 141 Amendment A8)

On Claude, content that must render right before a structured `AskUserQuestion` menu (the
lens agenda before the agenda-confirm; a component map before its approve menu) is defeated
by `AskUserQuestion` tool-gravity — the model folds the thing-being-confirmed into the call's
`question`/`options` fields and skims the render. Six in-context conduct edits (141 A4–A8)
could not make the before-a-menu render hold, because they all live inside the model's
context where it can skim them. A PreToolUse hook is the only **non-discretionary** lever: it
gates the tool call from Claude Code's runtime, outside the model's context. Feature 141
iteration 12 dispositioned the residual **accept-as-minor**; 165 is the optional reliable fix.

## Mechanism viability — CONFIRMED (one corrected finding)

Researched the current Claude Code hook contract (claude-code-guide agent + primary-source
verification of the load-bearing claims):

- **PreToolUse on `AskUserQuestion` is hookable.** stdin provides `tool_name`, `tool_input`,
  `transcript_path` (a JSONL of the conversation so far — enables the render-check),
  `session_id`, `cwd`.
- **Deny → self-correct → retry works.** A `deny` decision with `permissionDecisionReason`
  (JSON on stdout) — or exit 2 with a stderr reason — blocks the call AND feeds the reason
  back to the model, which re-renders and re-raises the menu. `ask` (downgrade to a human
  permission prompt) is also supported. (To hands-on-confirm at spec/implement, per the
  proposal's "confirm against live docs.")
- **Deploy is non-clobbering.** Hooks CONCATENATE across user/project/local `settings.json`
  scopes (most-restrictive-wins); safe deploy = append to `hooks.PreToolUse[]`, never
  overwrite. The `if`-field (Claude Code ≥ v2.1.85) allows narrow per-call matching so the
  gate fires only for the workshop case.
- **CORRECTED — the would-be blocker is fixed.** GitHub issue #12031 ("PreToolUse hooks strip
  `AskUserQuestion` result data" — answers returned empty) was real and Critical, but is
  **FIXED in Claude Code v2.0.76** (Jan 2026; the issue is `closed`/`completed`, with a
  maintainer validation comment confirming the fix with 17 active hooks). The initial research
  summary called it "unresolved as of 2026-06" — stale; primary-source check corrected it.
  #12605 ("AskUserQuestion Hook Support") is also `closed`/`completed`. → The mechanism is
  viable on current Claude Code; downstream deploys should note a minimum version (≥ v2.0.76
  for the fix; ≥ v2.1.85 for the `if`-field).

## Detection — the crux (to settle at spec)

The hook must answer two questions: (1) is this a workshop confirm-menu? (2) was the content
rendered first?

| Approach | (1) confirm-menu? | (2) rendered? | Determinism | False-positive risk |
|---|---|---|---|---|
| Marker-driven | skill emits a sentinel the hook keys on | marker tied to the render step | high | low |
| Transcript-parsing | hook infers from question text | hook scans `transcript_path` for the block | low (heuristic) | higher |
| Hybrid (lean) | marker for "this is a workshop confirm" | transcript-check for "rendered before the call" | high on (1), bounded on (2) | low |

**Lean: marker-anchored.** The `specrew-design-workshop` skill (141) emits a machine-readable
marker at each confirm point; the hook keys on it (deterministic "should I gate this?") and
verifies the render via transcript inspection or a render-bound marker. This is the proposal's
recommendation and minimizes false-positives (a wrong deny blocking a legitimate menu is worse
than a missed skim). The exact marker shape + render-check is the spec's central design.

## Worth-it bar — MAINTAINER'S CALL (Proposal 165 research-question #5)

Feature 141 iteration 12 dispositioned the residual (before-a-menu render skim on Claude)
**accept-as-minor**. 165 must clear that bar:

- **For**: the mechanism is confirmed viable and cheaper than the proposal feared; reliable
  agenda/map render improves the workshop's most information-dense moments on the dominant host.
- **Against**: host-specific machinery (Claude-only, ~8–15 SP) riding Claude Code's evolving
  hook API (needs a currency check) for a UX polish already dispositioned minor.

## Scope + deploy (v1)

- Workshop confirm-menus only; design the interface for later breadth (e.g., the verdict menu).
- Claude-only by design (hooks are Claude-specific; other hosts render in prose naturally).
  Composes with the host-neutral design-workshop skill — the 145 posture: instruction files
  teach every host, validators/hooks enforce where the host supports them.
- Deploy via the F-021/F-044 loop alongside the skill; merge (append) into
  `.claude/settings.json`; mirror-parity (Proposal 132) for the hook artifact.

## Recommendation

The mechanism is viable and marker-anchored detection is the design. The decision that gates
spec conversion is the **worth-it bar**, which the proposal assigns to the maintainer. Proceed
to `speckit.specify` with a marker-anchored, workshop-scoped, Claude-only v1 — or hold
(accept-as-minor stands) if the host-specific cost outweighs the minor UX gain.
