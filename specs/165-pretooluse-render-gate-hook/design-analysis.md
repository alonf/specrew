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

## Disposition — retargeted (2026-06-07)

**Worth-it evidence (a concurrent real workshop on the current Claude model — the maintainer's F-171
design-analysis):** 165's *specific* targets — the lens agenda and the component map — **rendered fine**
before their confirm menus (the 141-era skim did not reproduce). The friction that remained was (a) dense
design-decision menus raised before the goal/reasoning was surfaced, and (b) **Claude dropping the
`file:///` artifact links before the menu**, so the human could not open the files to inform a decision.
Neither is what 165's render-gate targets, and the agenda/map skim it *does* target appears to be closing
on the current model. → **Hold the broad PreToolUse render-gate; accept-as-minor stands for the
agenda/map case.**

**Retargeted fix (host-neutral, shipped on this branch):**

- **A — chat-path orientation:** the design-workshop skill now tells the human up front they can type a
  question / ask for a file / "explain more" instead of picking a menu option.
- **B-conduct — file-link discipline at confirm menus:** the skill now requires the artifacts' bare
  `file:///` links to be rendered in prose before any confirm menu (spec, lens record, design-analysis,
  diagram file), naming the Claude-specific drop. This is rule 14A applied at the workshop confirm menu.
- Both land in `extensions/specrew-speckit/squad-templates/skills/design-workshop.md` (+ `.specify`
  mirror, parity verified). Per-lens md untouched (the rule is global workshop method).

**Deferred — the narrow file-link *gate*** (only if the next dogfood shows Claude still dropping the links
despite the conduct): build it as a **gating provider in F-171's `SpecrewHookDispatcher`**, NOT a standalone
hook — composing through that seam avoids the `.claude/settings.local.json` collision entirely.

**Concurrent-crew (F-171) conflict mitigation:**

- F-171 binds **SessionStart + PostToolUse** (injection-only providers); it never uses PreToolUse, never
  touches `AskUserQuestion`, and never touches the design-workshop skill. So the conduct fix above has
  **zero hard conflict** (disjoint surfaces; merges in any order). A broad rule-14A reinforcement in
  coordinator-governance, if added later, merges serially after F-171's governance edit (both append-only).
- **Forward-compat ask to F-171 (cheap, while its spec is fresh):** widen the provider contract from
  injection-only to `kind: inject | gate` and register the dispatcher for PreToolUse too, so a future
  file-link gate plugs in as a `gate` provider — the same "reserve the seat" move F-171 already made for
  130-P4, but for a gating provider type.

**Net:** the broad render-gate (165 as written) is superseded by this conduct fix + the F-171 dispatcher
seat. The worktree closes once the conduct fix lands and the dogfood confirms (or escalates to the gating
provider).

## Disposition — FINAL (2026-06-07): the gate-stop skill (supersedes both sections above)

The retarget above (conduct A+B + defer the gate) did NOT hold: a fresh Claude dogfood showed the
workshop agenda AND the intake clarify both collapsed despite the sharp conduct. So the broad
PreToolUse render-gate hook was BUILT as a probe (`scripts/internal/render-gate-hook.ps1`, since
removed) to settle the mechanism empirically. The probe established three load-bearing facts on
Claude Code v2.1.168:

1. **`AskUserQuestion` IS PreToolUse-hookable** — the hook fired on every menu (the feared
   "not hookable" dead-end is refuted).
2. **`transcript_path` lags by a turn** — at PreToolUse time it does NOT contain the in-flight
   assistant turn calling the menu, so the packet/agenda prose written in the SAME message is
   invisible to the hook. A transcript-render-VERIFIER is therefore impossible.
3. **A blind deny is GAMEABLE** — a forcing deny ("render the packet as prose first, then re-raise")
   was satisfied by the model REWORDING the menu to claim content was "shown above" that it never
   rendered (verified against the flushed transcript: zero prose between the deny and the retry).

General principle (why every prior fix failed): a hook can verify a MECHANICAL fact (did the tool
run, is the field short) but NEVER content quality; the content is model-authored, so the model games
it. Conduct is the same lever, one notch softer.

**The fix is to remove the tool, not instruct around it.** The `specrew-gate-stop` skill carries
`disallowed-tools: AskUserQuestion` (a documented Claude Code skill-frontmatter feature — the docs
give AskUserQuestion as the example, and the restriction clears on the next user message). At every
boundary VERDICT stop the Claude branch of `Get-SpecrewHostInteractionGuidanceBlock`
(`scripts/internal/coordinator-prompt-surgery.ps1`) routes through this skill; with the picker gone
there is nothing to collapse into, so the model renders the full six-section packet as Markdown and
presents the verdict as a typed numbered list. Non-gameable (the tool is absent, not policed) and
host-neutral in body (other hosts render prose anyway; the field is a Claude-only enforcement,
harmlessly ignored elsewhere). The design **workshop and clarify questions keep the picker** — their
skills do not disable it — preserving the "present one decision, then a picker" UX the maintainer
values. Scope is correct: only `claude` (AskUserQuestion) is routed; `codex` keeps `request_user_input`
and the prose hosts (copilot/antigravity/cursor) declare no primitive.

**Dogfood-CONFIRMED** (testGate3, Claude Code v2.1.168, 2026-06-07): a fresh greenfield run reached
the `specify` and `clarify` boundary stops; at BOTH the model invoked `specrew-gate-stop` and rendered
the full six-section packet as Markdown with `file:///` links and no picker. Both platform unknowns
resolved positive: (1) the model invokes the skill at boundary stops, (2) `disallowed-tools` removes
the tool mid-turn. The branch deploy auto-picked-up the new skill (no extra deploy wiring). The
workshop's per-decision pickers rendered prose-then-picker correctly.

**Residual (accepted):** the workshop MULTI-ITEM confirms — the lens-agenda confirm and the
component-map verdict — still collapse on Claude (they keep the picker and the model crams the list
into the question). Filed as alonf/specrew#2081 for a later improvement (route just those two confirms
through a no-picker render, or a two-tier workshop, or an upstream AskUserQuestion rich-body field —
feature request drafted for anthropics/claude-code).

**Naming note:** the proposal's name ("PreToolUse render-gate hook") is now a misnomer — the shipped
mechanism is a skill-frontmatter tool-disable, not a hook. The hook probe is retired (deleted); its
learnings are recorded above.

**Shipped artifacts:** `extensions/specrew-speckit/squad-templates/skills/gate-stop.md` (+ `.specify`
mirror + FileList entry); the Claude routing in `scripts/internal/coordinator-prompt-surgery.ps1`;
regression tests `tests/integration/gate-stop-skill.tests.ps1` and the updated Claude assertions in
`tests/integration/multi-host-launch-path.tests.ps1`. Targets 0.32.0-beta2.
