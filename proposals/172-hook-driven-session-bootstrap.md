---
proposal: 172
title: Hook-Driven Session Bootstrap (SessionStart Hook as Primary Bootstrap; SessionEnd Handover; Agent-Rendered Resume/New/Pick Menu)
status: draft
phase: phase-2
estimated-sp: 8-13 (net-new integration; +5-8 if Proposal 130 Pillar 4 has not shipped and 172 must carry the handover scripts)
priority-tier: 1
discussion: surfaced 2026-06-08 immediately after Feature 171 (Proposal 146) shipped the host hook dispatcher substrate to v0.33.0-beta1. Maintainer-directed: the SessionStart hook should BECOME the primary session bootstrap (orientation + handover-read + a Resume/New/Pick menu), the SessionEnd hook should write the handover, and `specrew start` should be KEPT for backward-compat + explicit host launch rather than remaining the sole orientation path. This is a thin SYNTHESIS/delivery proposal — it does NOT re-specify the orientation surface (Proposal 143), the resume menu (Proposal 077), or the handover format + SessionEnd/SessionStart hook scripts (Proposal 130 Pillar 4). It owns only the three things that live in no existing proposal and all postdate them: (1) the posture inversion (hook = primary, launcher = compat), (2) the hook-injects-directive -> agent-renders-menu interaction shape forced by F-171's "hooks are non-interactive one-shot injectors" lesson, (3) the escalation of F-171's already-shipped B2 launch trigger from a lightweight refocus digest into a full bootstrap. Composes with 130 / 143 / 077 / 078 / 146 (shipped F-171) / 165.
---

# Hook-Driven Session Bootstrap

## Why

Feature 171 (Proposal 146) shipped the host hook dispatcher to v0.33.0-beta1: a single
`SpecrewHookDispatcher` registered once per host event, kill-switch-first, self-gating on `.specrew/`,
with a per-session circuit breaker + journal. Its **B2 launch/resume trigger** (`SessionStart` with
`source: startup | resume | clear`) already fires on **any** host launch in a Specrew project — including
a developer typing `claude` / `codex` / `cursor-agent` directly, bypassing `specrew start`. Today B2 injects
only the **lightweight general refocus digest** (a re-grounding pointer set), not a session bootstrap.

That is the gap. The dispatcher is now the one piece of Specrew that fires reliably on every launch and
every exit, regardless of how the host was started — exactly the property `specrew start` never had (it only
runs when the user remembers to use it). So the bootstrap experience the user expects at the start of a
session — *where am I, what was I doing, what do I want to do now* — should be delivered **by the hook**, not
gated behind a launcher the user can skip.

Maintainer direction (2026-06-08), four points:

1. The SessionStart hook should **replace** `specrew start` as the primary bootstrap — or, if it cannot fully
   replace it, `specrew start` is **kept for backward-compat + a nice way to select the host**, not as the
   sole orientation path. (Resolved: keep `specrew start`; demote it — see What.)
2. The SessionEnd hook should **write the handover** `.md` file.
3. The SessionStart hook should, besides everything `specrew start` does for orientation, **read the handover**
   `.md` if one exists.
4. The SessionStart hook needs to drive the **Resume / New / Pick-feature menu** (the A/B/C menu).

Three of these four are already specified elsewhere and only need wiring: the handover write/read is
**Proposal 130 Pillar 4a/4b**; the orientation content is **Proposal 143**; the Resume/New/Pick choice is
**Proposal 077**. What is genuinely new — and what this proposal owns — is the *integration posture* that turns
F-171's shipped dispatcher into a launcher-grade bootstrap, plus the one hard architectural constraint F-171
taught us about how a non-interactive hook can drive an interactive menu.

## What (the three things 172 owns; everything else is referenced)

### 1. Posture inversion — hook is the primary bootstrap; `specrew start` is kept and demoted

This is the normative claim no existing proposal can make without contradicting itself. **Proposal 130 Pillar 4b
explicitly says "the launcher remains the recommended path."** This proposal **inverts** that:

- The **SessionStart hook (B2) is the primary bootstrap.** It fires on every launch (launcher OR direct host
  CLI) and delivers orientation + handover-read + the Resume/New/Pick menu.
- **`specrew start` is KEPT** for: (a) backward compatibility, (b) explicit `--host <kind>` selection +
  per-host flag pass-through (Proposal 069 / 147), (c) the explicit intake-grounding pause some users want. It
  is **demoted from "the orientation path" to "a launch convenience."** It must not duplicate or fight the hook
  bootstrap when both run (launcher-then-hook in the same session must be idempotent — the hook's per-session
  dedupe from F-171 governs).
- **Deprecation is explicitly NOT proposed.** `specrew start` stays. (Maintainer decision 2026-06-08: "keep
  for compat + host launch.")

Because this contradicts 130 Pillar 4b's standing wording, 130 carries an explicit amendment note pointing here
(Proposal 167 post-ship/cross-proposal amendment discipline — the inversion must not sit silently across two
proposals).

### 2. Hook-injects-directive -> agent-renders-menu (the F-171 constraint)

F-171 established — and Proposal 165 / F-165 reinforced — that **host hooks are non-interactive one-shot
injectors**: they read an event JSON on stdin and emit `additionalContext` on stdout under a timeout. **A hook
cannot run an interactive menu, wait for a keypress, or branch on the user's answer.** Therefore the
Resume/New/Pick menu does **not** live in the hook. The hook injects a **bootstrap directive** (a structured
instruction + the orientation/handover payload); the **agent renders the menu and collects the choice** in the
conversation, exactly as the boundary-verdict packet works post-F-165.

This is the load-bearing interaction shape, and it composes with the open F-165 lesson:

- The bootstrap directive instructs the agent to render the orientation (Proposal 143 content) and then the
  A/B/C menu **as visible prose first**, and only then offer a structured pick.
- Whether the structured pick should use the host's selection UI (`AskUserQuestion` on Claude) or stay
  prose-only is an **OPEN** question (see below) — because F-165 showed the Claude picker can collapse a packet
  that was not rendered first. The A/B/C menu is a *new feature*, not a boundary verdict, so it is **not**
  automatically under the `specrew-gate-stop` `disallowed-tools` rule — but it may hit the same tool-gravity.

### 3. B2 escalation — from lightweight digest to full bootstrap

F-171's B2 trigger currently injects `["general"]` digest scope only. This proposal **escalates B2** (on the
launch/cold-start sources) to inject the full bootstrap directive: orientation + handover-read pointer + the
menu directive. This **changes shipped behavior**, so it needs a home and a controlled rollout — that home is
172.

Escalation must be **conditional**, not unconditional (the dispatcher's budget + dedupe guardrails apply):

- **No active session anchored** (fresh project, or last feature merged/closed) -> full bootstrap with the
  Resume/New/Pick menu.
- **Active session anchored + recent** -> lighter "welcome back, resume at `<boundary>`?" path (closer to
  today's digest + a single resume confirm), not the full three-way menu.
- The escalate-vs-stay-lightweight **trigger threshold is OPEN** (see below).

`B1` (post-compaction) and `B3` (boundary-cross) keep their F-171 behavior unchanged — this proposal touches
**B2 only**, plus adds the SessionEnd handover write.

## What 172 explicitly does NOT re-specify (referenced, not re-opened)

| Concern | Owner (do not duplicate here) |
| ------- | ----------------------------- |
| Handover `.md` format, path, freshness window, SessionEnd source-matcher discrimination | **Proposal 130 Pillar 4a** — adopt as-is. 130 already chose **SessionEnd** (not `Stop`) and defined the schema + `index.yml`. 172 does not re-open the event choice. |
| SessionStart any-launch context injection (read handover + brief host) | **Proposal 130 Pillar 4b** — adopt as-is; B2 is the trigger that carries it. |
| Welcome orientation content (version + host + project state + lifecycle position + profile dial summary + reset hints) | **Proposal 143 Pillar 1** — the bootstrap directive renders 143's orientation; 172 does not redefine it. |
| Resume / New / Pick-feature menu semantics + the recovery (A/B/C) variant | **Proposal 077** (resume/new/pick) + **Proposal 143** (recovery menu). 172 wires them into the hook directive; it does not redesign the menu. |
| Handoff-prose quality at the bootstrap pause | **Proposal 078** — the bootstrap directive's prose follows 078's three-section + menu conventions. |
| The hook dispatcher, deploy loop, kill-switch, breaker, journal, dedupe | **Proposal 146 / Feature 171 (shipped)** — reused verbatim; 172 adds one provider (bootstrap) to B2 and one SessionEnd registration. |

## How (one-iteration shape, depends on 130 Pillar 4 status)

- Add a **bootstrap provider** to the dispatcher's B2 seat that emits the bootstrap directive (orientation +
  handover-read + menu directive) instead of, or layered above, the general digest — gated by the
  active-session-anchored condition.
- Register the **SessionEnd handover-write** hook (Proposal 130 Pillar 4a script) through F-171's existing
  per-host deploy loop (`Invoke-RefocusHookDeployment` + the same `.specrew-managed` marker discipline).
- Add a **bootstrap digest / directive template** under `extensions/specrew-speckit/refocus/` (sibling to the
  existing general + per-stage digests) that names its sources (143 orientation, 130 handover, 077 menu) so it
  stays within the F-171 token-budget cap and currency rule.
- Coordinator / agent instruction: render orientation + menu **as prose first**, then offer the pick (F-165
  render-before-menu discipline).
- Demote `specrew start`'s orientation role in its generated prompt; keep its host-selection + `--resume`
  behavior; ensure launcher-then-hook idempotency via the existing dedupe.
- Tests: B2 escalation fires the bootstrap on no-active-session and the lighter path on active-session;
  SessionEnd writes a handover that B2 reads on next launch (round-trip); launcher-then-hook does not
  double-bootstrap; menu is rendered before any structured pick.

**Dependency note:** if Proposal 130 Pillar 4 has not yet shipped when 172 is implemented, 172 carries the
SessionEnd/SessionStart handover scripts itself (+5-8 SP, the 130 Pillar 4 estimate). If 130 Pillar 4 ships
first, 172 is pure integration (~8 SP). Either way 172 does not re-author the handover *format* — that stays
130's.

## Open questions (only the ones 130/143/077 do NOT answer)

- **Start <-> hook division of labor.** Exactly what does `specrew start` still own once the hook is primary?
  Host selection + `--resume` + intake-grounding pause is the proposed split; confirm at design-analysis. Does
  `specrew start` short-circuit the hook bootstrap (because it already oriented), or always defer to it?
- **Does the A/B/C menu render per-host, or collapse under tool-gravity?** This is the real risk. F-165 showed
  the Claude `AskUserQuestion` picker collapses content that was not rendered first. The bootstrap menu is a new
  feature, not a boundary verdict, so it is not auto-covered by `specrew-gate-stop` — but it may need the same
  render-first-then-pick (or prose-only) treatment, possibly the Proposal 165 PreToolUse lever. Empirically
  verify per host (Claude / Codex / Copilot / Cursor) before locking the menu shape.
- **B2 escalate-vs-stay-lightweight trigger.** What precisely distinguishes "fresh / no active session -> full
  bootstrap" from "active session anchored + recent -> light welcome-back"? Candidate signal: presence of a
  valid anchored session in `start-context.json` whose feature is not merged/closed AND whose last write is
  within a freshness window. Needs the same staleness check 130 Pillar 4b already contemplates — reuse it.
- **Which SessionEnd sources write a handover.** 130 Pillar 4a discriminates `clear | exit | compact`. Confirm
  this set is what 172's round-trip relies on (the riskiest unknown is whether the host actually fires
  SessionEnd on the relevant exits, per-host — verify the same way F-171 verified its triggers, against live
  host docs).

## Composition

- **Proposal 146 / Feature 171 (shipped, v0.33.0-beta1)** — the substrate. 172 reuses the dispatcher, deploy
  loop, kill-switch, breaker, journal, dedupe, and budget machinery verbatim; it adds a B2 bootstrap provider
  and a SessionEnd registration. file:///C:/Dev/Specrew/proposals/146-specrew-refocus-slash-command.md
- **Proposal 130 (Pillar 4a/4b)** — the dominant composer: owns the handover format + the SessionEnd/SessionStart
  hook scripts. 172 **inverts 130 Pillar 4b's "launcher remains recommended" posture** (130 carries an explicit
  amendment note). file:///C:/Dev/Specrew/proposals/130-specrew-switch-to-host-handover.md
- **Proposal 143** — orientation surface + recovery (A/B/C) menu; rendered by 172's bootstrap directive.
  file:///C:/Dev/Specrew/proposals/143-session-start-welcome-orientation-reset-surface.md
- **Proposal 077** — resume/new/pick menu semantics; wired into the bootstrap directive.
  file:///C:/Dev/Specrew/proposals/077-session-resume-ux.md
- **Proposal 078** — handoff-prose conventions the bootstrap pause follows.
  file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md
- **Proposal 165 / Feature 165 (shipped)** — render-before-menu discipline; the open risk that the bootstrap
  menu may need the same treatment. file:///C:/Dev/Specrew/proposals/165-pretooluse-render-gate-hook.md

## Acceptance signals

- **AC1**: Launching a host directly (`claude` / `codex` / `cursor-agent`) in a Specrew project — bypassing
  `specrew start` — produces the full bootstrap (orientation + handover-read + Resume/New/Pick menu) when no
  active session is anchored, via the SessionStart (B2) hook.
- **AC2**: `specrew start` still works, still selects the host + supports `--resume`, and does NOT double-bootstrap
  when its launch is immediately followed by the hook (F-171 dedupe holds).
- **AC3**: On clean exit (per 130 Pillar 4a source set), a handover `.md` is written; on the next launch the
  bootstrap reads it and surfaces "resuming from `<when>`; `<recommended next step>`."
- **AC4**: The A/B/C menu is rendered as visible prose before any structured pick is offered (no menu-before-render
  collapse), verified on each hook-bound host.
- **AC5**: With an active, recent, anchored session, B2 takes the lighter welcome-back path, not the full menu.
- **AC6**: `specrew start`'s generated prompt no longer claims sole ownership of orientation; the hook is the
  documented primary bootstrap.

## Out of scope

- Re-specifying the handover format, the orientation content, or the resume-menu semantics (owned by 130 / 143 / 077).
- Deprecating or removing `specrew start` (explicitly kept per maintainer decision).
- B1 (post-compaction) and B3 (boundary-cross) behavior changes — unchanged from F-171.
- Orchestrated host switch (Mode 2) — remains 130 / 024 territory.
- The B4 pre-compaction capture trigger and the Antigravity binding (both deferred-with-path by F-171; not
  reopened here).

## Cross-references

- file:///C:/Dev/Specrew/proposals/146-specrew-refocus-slash-command.md (shipped — Feature 171, v0.33.0-beta1)
- file:///C:/Dev/Specrew/proposals/130-specrew-switch-to-host-handover.md
- file:///C:/Dev/Specrew/proposals/143-session-start-welcome-orientation-reset-surface.md
- file:///C:/Dev/Specrew/proposals/077-session-resume-ux.md
- file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md
- file:///C:/Dev/Specrew/proposals/165-pretooluse-render-gate-hook.md
- file:///C:/Dev/Specrew/proposals/167-post-ship-proposal-amendment-discipline.md (amendment discipline applied to the 130 posture inversion)
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
