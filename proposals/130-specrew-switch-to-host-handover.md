---
proposal: 130
title: /specrew-switch-to Slash Command + handover.md Context Bridge (Host-Switch Hand-off Helper)
status: candidate
phase: phase-2
estimated-sp: 15-23 (4 pillars; Pillar 1 alone is ~3-5 SP if ship-incremental; Pillar 4 hook-based any-exit + any-launch adds ~5-8 SP)
priority-tier: 1
discussion: surfaced 2026-05-26 during F-046/F-047 multi-host dogfooding; user observation that host switches have been smooth (~5+ this session) but require manual exit + re-launch + cognitive load to remember what context to bring across; user-confirmed refinement that handover.md captures conversation context that session_state.json structurally cannot. **Amended 2026-05-31** to add Pillar 4 (hook-based any-exit handover authoring + any-launch context injection) — generalizes from "user-initiated host-switch only" to "ANY session-end and ANY host-launch", making Specrew governance robust to launcher-bypass AND closing the compaction-vulnerability bug class structurally (F-024 / F-046 / F-048 Shape 3c). Priority promoted Tier 3 → Tier 1.
---

# /specrew-switch-to Slash Command + handover.md Context Bridge

## Why

Multi-host expansion (Proposals 069 shipped F-040, 104, 124) makes host-switching a first-class user behavior. The 2026-05-25 / 2026-05-26 dogfooding session demonstrated this empirically: 5+ manual host switches across one session (Codex → Claude → Antigravity → Claude → Claude → Codex), each requiring:

1. User exits the current host (Ctrl+D / `/quit`)
2. User retypes `specrew start --host <kind> "<description>"` with the right description
3. User mentally tracks what state should carry across (in-flight discussion, open questions, agent hypotheses)
4. New host bootstraps fresh from artifacts + start-context.json; **the conversation thread is lost**

The cognitive load is real but small per switch. **The conversation-context loss is the larger gap.** session_state.json captures the cursor (where in the lifecycle), boundary_enforcement captures the verdict ledger (audit trail), and lifecycle artifacts capture committed decisions — but none of these carry:

- **Conversation tail** — what was just discussed; what the user said in the last few turns
- **In-flight hypotheses** — what the agent was about to check / consider
- **Open questions** — what the agent needs to ask the user before proceeding
- **Agent's "where I am" mental model** — the working understanding that informs next-step decisions
- **Next-immediate-step recommendation** — the agent's view of what should happen first after resumption

A receiving host has to reconstruct all of this from artifacts alone, which means re-reading + re-deriving the context the previous agent already had. Often the user has to re-explain, slowing the switch from "smooth" to "smooth-but-with-friction."

### Reframe (added 2026-05-31): handover.md value applies to ANY exit, not just user-initiated switch

The original scope (Pillars 1 / 2 / 3) covered USER-INITIATED host-switch only — fires when the user types `/specrew-switch-to <host>`. Empirical refinement: the SAME handover.md value applies to ANY session-end, regardless of whether the user explicitly invoked the switch command:

| Exit path | Original scope covers? | Pillar 4 covers? |
| --------- | ---------------------- | ---------------- |
| User `/specrew-switch-to <host>` | ✓ (Pillar 1) | (already covered) |
| Compaction event (context overflow) | ✗ | **YES — most painful, no warning, traced to F-024/F-046/F-048 Shape 3c discipline-drop** |
| `/clear` | ✗ | yes |
| `/exit` or Ctrl+D | ✗ | yes |
| Normal session-end | ✗ | yes |
| Crash | ✗ | best-effort (no hook guarantee) |

**Compaction is the most acute case.** Specrew has documented incidents (F-024 boundary-compaction breach, F-046 Antigravity 4-gate autopilot bypass, F-048 Codex branch-push discipline gap) ALL traced to post-compaction discipline drop. Handover-on-compaction (Pillar 4a) closes this bug class structurally: the receiving (or post-compaction-reloaded) agent reads a freshly-authored handover and continues with the right context instead of operating from a half-empty context.

### Reframe (added 2026-05-31): SessionStart hook makes Specrew unbypassable at host launch

Today's launch path: `specrew start --host <kind>` wraps the host launch, builds `.specrew/start-context.json`, and emits coordinator-prompt context. **Bypass risk:** if a developer just types `claude` (or `codex` / `cursor-agent` / etc.) directly in the project directory, none of Specrew's launch machinery fires — no start-context, no coordinator-prompt, no boundary-discipline orientation. The user gets a fresh-context agent with zero Specrew awareness, even inside a Specrew-managed project.

**SessionStart hook closes this gap (Pillar 4b):** when the host's start hook fires (on ANY host-launch in the project directory, regardless of whether `specrew start` was the launcher), the hook script reads `.specrew/start-context.json` (most recent) AND/OR the most recent handover.md, then briefs the host via the hook's context-injection mechanism. End result: Specrew governance applies whether you launch via `specrew start` OR directly via the host CLI.

Architectural shift: Specrew governance becomes **defensively bypassable-only-by-explicit-opt-out** — same pattern as git hooks (once installed, they fire regardless of how the user invokes git). The launcher remains the recommended path (it does more — explicit `--host` selection, prompt-approval mode, intake-grounding pause), but bypass no longer means context-loss.

## What

Three pillars. Ship Pillar 1 first as the foundation; Pillars 2 + 3 build on it.

### Pillar 1: `/specrew-switch-to <host>` slash command (~3-5 SP)

New slash command deployed to all per-host catalogs (`.claude/skills/`, `.github/skills/`, `.agents/skills/`, plus future host catalogs from Proposal 124).

Invocation: `/specrew-switch-to claude` (or `codex` / `antigravity` / `aider` / etc.)

Behavior:

1. Persist current session state via `sync-boundary-state.ps1` (or equivalent) — ensures `session_state` + `boundary_enforcement` + `.squad/identity/now.md` are current on disk
2. Validate target host availability via the host registry (Proposal 069 / F-040 infrastructure)
3. Emit a paste-ready exit + relaunch block:

```text
=== SPECREW HOST SWITCH ===
Current host: <from>  (session state persisted at <commit-hash>)
Target host:  <to>
Handover record: file:///<path-to-handover.md>  (created if Pillar 2 active; otherwise empty)

To complete the switch:
  1. Type /quit (or Ctrl+D) to exit <from>
  2. Run: specrew start --host <to> --resume
```

No orchestration in Pillar 1 — the user is the bridge between exit and re-launch. Mode 1 of the design discussion. Low risk, ships independently.

### Pillar 2: `handover.md` format + receiving-host bootstrap integration (~4-6 SP)

When `/specrew-switch-to <host>` fires, write a structured `.specrew/handover/<timestamp>-<from>-to-<to>.md` file with:

```markdown
---
schema: v1
from_host: <from>
to_host: <to>
recorded_at: <ISO-8601>
from_commit: <hash>
active_feature: <feature-ref>
active_boundary: <boundary-name>
---

# Host Switch Handover

## What I just did (last 3-5 turns or last boundary work)

<bullet summary of recent agent actions and user inputs>

## Why I'm stopping (the switch trigger)

<user's stated reason, OR agent-inferred reason>

## Open questions / pending clarifications

<bullets — questions the next host should resolve with the user>

## Agent's working hypothesis / mental model

<short paragraph — what the agent currently believes about the situation>

## Recommended next-immediate-step

<what the receiving host should do first, before re-reading bootstrap>

## Context the receiving host needs that artifacts don't carry

<bullets — anything the next agent should know that's NOT in spec/plan/tasks/state>
```

Receiving-host bootstrap is updated to:

1. After reading `.specrew/last-start-prompt.md` and `.specrew/start-context.json`, **also check `.specrew/handover/` for the most recent `<timestamp>-*-to-<this-host>.md` file with `recorded_at` within the last N hours (configurable; default 24h)**
2. If found, read it BEFORE any other action; the handover sections inform the agent's initial orientation
3. Reference the handover in the welcome-back prose: "Resuming from <from-host>'s handover at <timestamp>; <recommended next step>"

Coordinator-prompt rules (45-47, post-F-040 Wave A1) extended:

> Rule 48 (added): When `/specrew-switch-to <host>` fires, you MUST author `.specrew/handover/<timestamp>-<from-host>-to-<to-host>.md` with the 5 sections above, populated from the actual session state (no template-shaped stubs). The receiving host will rely on this file as its primary context bridge. If you cannot populate a section meaningfully, write `(no relevant content)` rather than omit the section.

### Pillar 3: Audit-trail preservation (~2-3 SP)

Handover files are durable:

- Never auto-deleted
- Indexed by `.specrew/handover/index.yml` (timestamp + from-host + to-host + active-feature + active-boundary + exit-source for Pillar 4 events)
- Included in `specrew where` dashboard's "Recent activity" surface as a sub-row when host switches OR significant exit events (compaction, switch) occurred during the iteration
- Surfaced in iteration retro template as a "host-switch + significant-exit events during this iteration" section — informs retro discussion about whether switches/compactions were beneficial or disruptive
- Optional: validator rule (soft INFO) flags handover files older than 90 days for cleanup consideration (operator decision, not auto-removal)

### Pillar 4: Hook-based any-exit + any-launch handover (added 2026-05-31) (~5-8 SP)

Pillars 1-3 cover user-initiated switch via the slash command. Pillar 4 generalizes to ALL session-end and session-start paths via host-native hook surfaces. Composes with **Proposal 105 (Host-Native Hook Deployment)** — 105 ships the hook substrate; Pillar 4 ships the Specrew handover hook scripts that use 105's deployment mechanism.

#### Pillar 4a: SessionEnd hook — any-exit handover authoring

Hook script fires on session termination via the host's exit/end hook. Behavior:

1. Read source-matcher (e.g., Claude Code's `source: startup | resume | clear | compact`) to discriminate handover detail level:
   - `compact` → best-effort handover ("transcript dropped by compaction; reconstructed from artifacts + git status + start-context.json")
   - `clear` / `exit` → full 5-section handover (Pillar 2 format)
   - `startup` / `resume` (rare termination paths) → log + minimal handover
2. Read current Specrew state: `.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.squad/identity/now.md`, recent git commits, current iteration state.md
3. Write `.specrew/handover/<timestamp>-session-end-<source>-from-<host>.md` with the appropriate detail level
4. Update `.specrew/handover/index.yml`
5. Exit 0 (don't break session-end on failure; warn via stderr)

The script is HOST-AGNOSTIC at the I/O layer — it reads/writes the same files regardless of which host's hook invokes it. Per-host adaptation lives in the hook-registration template (Proposal 105 territory) that wires the script into each host's hook config.

#### Pillar 4b: SessionStart hook — any-launch context injection

Hook script fires on session launch via the host's start hook (regardless of whether `specrew start` was the launcher). Behavior:

1. Detect Specrew-project context (`.specrew/` directory exists in current working directory)
2. Read `.specrew/start-context.json` (most recent) + most-recent handover within freshness window (default 24h, configurable)
3. Brief the host via the hook's context-injection mechanism (e.g., Claude Code's `additionalContext` / `sessionTitle`; per-host equivalents)
4. If start-context.json is stale (>N hours since last write) OR doesn't reflect current git state, two options (configurable):
   - Soft mode (default): brief the agent with "start-context is stale; consider running `specrew start --resume` to refresh"
   - Strict mode (opt-in): exit non-zero with instructions to run `specrew start --resume`; lets the user fall back to direct launch only after explicit refresh

**Closes the launch-bypass gap:** developer typing `claude` (or any host CLI) directly in a Specrew project gets the same orientation as via `specrew start`. Specrew governance applies regardless of launch path.

#### Per-host hook-surface awareness (research deferred to Proposal 105 + per-host adapters)

Hook surfaces vary by host and are evolving. V1 of Pillar 4 ships Claude Code first because its hook surface is fully documented:

- **Claude Code**: `SessionStart` + `SessionEnd` documented (<https://code.claude.com/docs/en/hooks.md>); source matcher discriminates `startup | resume | clear | compact`; config in `.claude/settings.json`
- **Codex CLI / Copilot CLI / Cursor / Antigravity / Aider / Amp / OpenCode**: hook surfaces not yet researched in detail; Proposal 105 territory. Per-host adapter ships incrementally as each host's hook surface is documented + adapter authored
- **Hosts without hook surface**: degraded-mode — no auto-handover-on-exit; no auto-context-injection-on-launch; user must use `/specrew-switch-to` slash command (Pillar 1) for user-initiated switch. `specrew start` remains the recommended launch path for these hosts.

#### Gotchas (acknowledged, NOT hidden)

- **Hook runs AFTER session closes** — transcript not directly available; hook reads files from disk + git state, not live conversation. Reconstruction is best-effort from durable artifacts.
- **No crash guarantee** — process hard-killed (OOM, system shutdown, signal-9) = no hook fire; handover.md missing for that exit. Mitigation: handover-on-clean-exit is the primary path; crash recovery falls back to existing artifact-based bootstrap.
- **No access to compacted content** — compaction drops conversation before the hook fires; compaction-source handover is best-effort from artifact + git-state reconstruction. The handover explicitly notes "compaction occurred; transcript not available" so the resuming agent doesn't infer false context.
- **Timeout** — hooks have execution timeout (Claude Code: configurable, default 600s; recommend 30s for handover scripts to keep session-end responsive)
- **Source-matcher coverage varies by host** — different hosts will expose different exit signals; hook script must handle missing/unknown source-matcher gracefully (fall back to "exit reason unknown")
- **Hook deployment churn** — `.claude/settings.json` (and per-host equivalents) are managed by Specrew during init; bypass risk that user manually edits and removes hooks. Mitigation: `specrew init` re-installs on every run; validator soft-warns if hooks are missing in a hook-capable host.

## How

Single-iteration shape. Total ~15-23 SP (was 10-15; +5-8 for Pillar 4). Splittable: Pillars 1-3 ship as V1a (~10-15 SP); Pillar 4 ships as V1b (~5-8 SP) once Proposal 105 hook infrastructure is in place.

| Step | File | Effort |
|---|---|---|
| Pillar 1 slash command body | `extensions/specrew-speckit/skills/specrew-switch-to/SKILL.md` (new) | 1 SP |
| Pillar 1 persistence wrapper | `scripts/internal/host-switch.ps1` (new) — invokes sync + validates target + emits paste-ready block | 2 SP |
| Pillar 1 host-availability check | reuses Proposal 069 / F-040 host registry | 0.5 SP |
| Pillar 1 deployment to per-host skill catalogs | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` extension | 1 SP |
| Pillar 2 handover.md schema + scaffolder | `scripts/internal/host-switch.ps1` (extends Pillar 1) — generate + populate sections from session state + recent conversation summary (agent fills the 5 sections per coordinator-prompt rule 48) | 2 SP |
| Pillar 2 receiving-host bootstrap | `scripts/specrew-start.ps1` Welcome-Back snapshot — detect `.specrew/handover/*-to-<this-host>.md` files and surface | 2 SP |
| Pillar 2 coordinator-prompt rule 48 | per-host coordinator-prompt templates — instruct on the 5-section population | 1 SP |
| Pillar 3 audit-trail index + `specrew where` integration | `.specrew/handover/index.yml` + `scripts/specrew-where.ps1` extension | 1-2 SP |
| Pillar 3 retro-template extension | reviewer-artifacts scaffolder — add "Host-switch + significant-exit events during this iteration" section | 0.5 SP |
| Pillar 4a SessionEnd hook script | `scripts/internal/hooks/specrew-handover-on-end.ps1` (new) — source-matcher discrimination + handover authoring + index update | 2 SP |
| Pillar 4b SessionStart hook script | `scripts/internal/hooks/specrew-resume-on-start.ps1` (new) — read start-context + most-recent handover + brief host via context-injection | 2 SP |
| Pillar 4 hook deployment + per-host config wiring | `extensions/specrew-speckit/scripts/deploy-hooks.ps1` (new OR extends 105's deployment) — wire SessionEnd + SessionStart into `.claude/settings.json` (V1 Claude); per-host extension via Proposal 105 adapter pattern | 1-2 SP |
| Pillar 4 integration tests | `tests/integration/hook-handover.tests.ps1` (new) — covers SessionEnd handover authoring across all source-matcher values; SessionStart context-injection on direct-CLI-launch (bypass `specrew start`); hook idempotency + safe failure | 2 SP |
| Integration tests (Pillars 1-3) | `tests/integration/host-switch-handover.tests.ps1` (new) — covers slash command emission, handover.md format, receiving-host bootstrap, index update | 2 SP |
| Mirror parity | all `extensions/specrew-speckit/scripts/*` and `.specify/extensions/...` edits byte-identical | (within each step) |
| Docs | `docs/user-guide.md` host-switching section + `docs/how-to/switch-hosts.md` (new) + `docs/how-to/launch-bypass-safety.md` (Pillar 4b coverage of direct-CLI launch) | 1-2 SP |

## Acceptance criteria

- **AC1**: `/specrew-switch-to claude` (or any registered host) fires from any host with a slash-command surface; emits the paste-ready exit + relaunch block; Copilot (no slash-command surface) gets equivalent via `specrew host switch --to <kind>` CLI fallback
- **AC2**: Slash command invokes session-state persistence before emitting the block; `session_state.boundary_type` + `boundary_enforcement` are current on disk when the user exits
- **AC3**: Invalid target host (e.g., `/specrew-switch-to fake`) emits clear error listing registered hosts (per Proposal 069 / F-040 registry)
- **AC4** (Pillar 2): `/specrew-switch-to <host>` writes `.specrew/handover/<timestamp>-<from>-to-<to>.md` with all 5 sections populated (or `(no relevant content)` markers); coordinator-prompt rule 48 prevents template-shaped stubs
- **AC5** (Pillar 2): Receiving host's Welcome-Back snapshot reads the matching `handover/*-to-<this-host>.md` file and surfaces "Resuming from <from-host>'s handover at <timestamp>; <recommended next step>"
- **AC6** (Pillar 2): If multiple handover files match (rare — host switched to A then to B then back to A within the window), receiving host reads the most recent and notes the chain in welcome-back prose
- **AC7** (Pillar 3): `.specrew/handover/index.yml` is maintained on every switch; `specrew where` dashboard surfaces a "Recent host switches" sub-row when any switch occurred during the active iteration
- **AC8** (Pillar 3): Retro template includes a "Host switch events during this iteration" section auto-populated from the index
- **AC9**: Mirror parity preserved
- **AC10**: Backward-compatible — sessions that never use `/specrew-switch-to` see no change in behavior; the slash command is opt-in
- **AC11** (Pillar 4a): SessionEnd hook fires on ANY host-end (exit / clear / compact / normal end) for hook-capable hosts; writes `.specrew/handover/<timestamp>-session-end-<source>-from-<host>.md` with source-discriminated detail level; compaction-source handover explicitly acknowledges "transcript lost; reconstructed from artifacts"; index updated
- **AC12** (Pillar 4b): SessionStart hook fires on ANY host-launch in a Specrew project (where `.specrew/` directory exists), INCLUDING direct host CLI invocation that bypasses `specrew start`; reads `.specrew/start-context.json` + most-recent-handover within freshness window; briefs the host via the hook's context-injection surface; agent receives Specrew orientation even when `specrew start` was not the launcher
- **AC13** (Pillar 4): Hook deployment is automatic during `specrew init` for hook-capable hosts (Claude Code V1; others as Proposal 105 adapters ship); manual install instruction provided in `docs/how-to/launch-bypass-safety.md` for hosts not in the Specrew-managed bootstrap
- **AC14** (Pillar 4): Hook scripts exit 0 on success; non-zero exit does NOT break the host session (`specrew init` warns but doesn't fail). Crash-killed sessions don't fire hooks (acknowledged gotcha; existing artifact-based bootstrap covers crash recovery)
- **AC15** (Pillar 4): Multi-host degraded-mode — for hosts without documented hook surface, Pillar 4 is a no-op; Pillars 1-3 (slash command path) remain the user-initiated path; validator soft-warns when a hook-capable host is configured without Specrew hooks installed
- **AC16** (Pillar 4): Stale start-context handling — when SessionStart hook detects start-context.json older than configurable threshold (default 24h) OR git HEAD has advanced significantly, hook briefs the agent to suggest `specrew start --resume` (soft mode default) OR exits non-zero with refresh instructions (strict mode opt-in)

## Out of scope

- **Orchestrated host switch (Mode 2 of design discussion)** — slash command actually spawns new host process, exits current. Bigger architectural shift; needs a session-supervisor layer that sits between user and host. Future proposal (likely depends on Proposal 024 Multi-Host CORE shipping)
- **Cross-host conversation history preservation** — each host owns its own conversation log; handover.md is a structured summary, not a full conversation export
- **Automatic conversation-tail summarization** — Pillar 2 requires the agent to populate the sections; not LLM-based summarization of past turns. (Future enhancement: a `specrew-summarize-recent-turns` skill could auto-populate the "What I just did" section, but Pillar 2 ships with agent-author population per coordinator-prompt rule 48)
- **Host-state migration** (different model, different conversation memory format) — handover.md is markdown; receiving host parses freely
- **Cancelling/undoing a switch** — once the user exits the source host, the switch is committed. Don't model "switch rollback"

## Composition

- **Proposal 069 (Multi-Host Launch Path, shipped F-040)** — direct dependency; uses the same host registry for `--host` validation and the `--resume` semantics
- **Proposal 064 (Slash-Command Multi-Host Correctness)** — direct dependency; needs the slash command to deploy to every host's catalog correctly (YAML frontmatter, hyphen-namespace, multi-deploy)
- **Proposal 035 (Session-State Durability)** — composes; handover.md is a higher-level overlay on session-state durability; the `--resume` semantics rely on 035's durability primitives
- **Proposal 078 (Handoff Conversation Quality)** — composes deeply; handover.md uses the same three-section structure Pillar 1 prescribes (What I did / Why I stopped / What I need from you) plus 2 additional sections (Working hypothesis + Recommended next step)
- **Proposal 105 (Host-Native Hook Deployment)** — **direct dependency for Pillar 4**: 105 ships the hook substrate + per-host adapter pattern; Pillar 4 ships the SessionEnd + SessionStart Specrew handover hook scripts that USE 105's deployment mechanism. V1 of Pillar 4 ships Claude-first (105 + Claude SessionStart/SessionEnd docs both available); other hosts get Pillar 4 incrementally as 105 ships per-host adapters
- **Proposal 143 (Session Start Welcome Orientation + Reset Surface)** — **direct composer for Pillar 4b**: 143's "Welcome Orientation rendered before first intake/resume question" is the user-facing equivalent of Pillar 4b's hook-driven context injection. Both ship Specrew orientation to the launched agent; Pillar 4b makes it work even on launcher-bypass (direct host-CLI launch), 143 ensures the orientation is rich + reset-capable when it does fire
- **Proposal 133 (Specrew Primer for Compaction Recovery)** — **direct composer for Pillar 4a**: 133 is the primer that re-injects methodology after compaction-triggered context loss; Pillar 4a's compaction-source handover IS the artifact 133 reads on resume. Together they close the compaction-vulnerability bug class (F-024 / F-046 / F-048 Shape 3c discipline-drop) — 4a writes the handover at compaction-exit; 133 reads it on resume to re-orient
- **Proposal 124 (Multi-Host Catalog Expansion — Tier 1)** — composes; new hosts (Aider, Amp, OpenCode, Cursor) get the slash command + handover behavior for free per the established adapter pattern
- **Proposal 010 (Multi-Developer Reconciliation)** — different problem (multi-user concurrent edits); handover.md is single-user-cross-host, not multi-user. Adjacent but not overlapping
- **Proposal 024 (Multi-Host Runtime Abstraction)** — endgame; Mode 2 orchestrated switch would naturally live in 024's full architecture

## Risks

- **Handover.md drift** — agent populates the file but receiving host doesn't read it (rule 48 not honored). Mitigation: Welcome-Back snapshot extension is mandatory; receiving host MUST surface the handover in its first response
- **Stale handover.md** — file exists from a switch days ago; receiving host reads it as current. Mitigation: 24h freshness window default (configurable); older handovers logged but not surfaced as "current context"
- **Multiple agents auto-creating handovers in conflicting patterns** — host-A switches to B, B switches back to A within minutes. Mitigation: AC6 covers the chain; timestamp-based dedup
- **Handover.md becomes a dumping ground** — agents stuff too much detail into "Context the receiving host needs." Mitigation: section length guidance in coordinator-prompt rule 48 (5-15 lines per section; longer goes to artifacts not handover)
- **Slash-command discoverability on Codex** — Codex has no user-defined slash-command surface (per F-040 / Proposal 064 research). Mitigation: AC1's `specrew host switch --to <kind>` CLI fallback covers Codex; users get the same behavior via CLI
- **Conversation-context summarization quality** — agent-populated sections may be lazy/sparse. Mitigation: rule 48 examples in coordinator-prompt + retro discussion if handover quality regresses
- **Backward compatibility on existing sessions** — sessions that never use the slash command should see no change. Mitigation: AC10; slash command is opt-in; receiving-host bootstrap only acts when a matching handover file exists

## Empirical motivation

2026-05-25 / 2026-05-26 dogfooding session demonstrated the gap concretely: 5+ host switches in one session.

| Switch | From | To | Reason | Context lost |
|---|---|---|---|---|
| 1 | Codex (F-045) | Claude (review-repair) | Codex token quota exhausted | F-045 closeout state, in-flight retro discussion |
| 2 | Claude | Antigravity (F-046 start) | User chose Antigravity for new feature | Tonight's full conversation context up to F-046 launch |
| 3 | Antigravity (F-046) | Claude (PR #934 review-repair) | Antigravity autopilot bypass; needed retroactive review | F-046 substantive work context + Antigravity's mental model |
| 4 | Claude | Claude (proposals sweep — fresh session) | New focused work | The 13-proposal context from the sweep |
| 5 | Claude | Codex (F-047) | User chose Codex for lifecycle-tooling | F-047 brief context + reasoning behind item ordering |

Each switch required user to re-explain or the receiving agent to reconstruct from artifacts. Net: smooth-but-friction. Pillar 2 would have carried structured context across 4 of the 5 switches; switch #4 (fresh Claude session for a focused new task) genuinely benefits from a clean slate.

The user observation that drove this proposal: "switching from Claude to Codex was smooth, but with a switch command it can be smoother, because we can create a hand over md file with more context."

## Cross-references

- file:///C:/Dev/Specrew/proposals/064-slash-command-multi-host-correctness.md
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/035-session-state-durability.md
- file:///C:/Dev/Specrew/proposals/078-handoff-conversation-quality.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md — Pillar 4 dependency (hook deployment infrastructure)
- file:///C:/Dev/Specrew/proposals/124-multi-host-catalog-expansion-tier-1.md
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md
- file:///C:/Dev/Specrew/proposals/133-specrew-primer-persistent-host-instructions.md — Pillar 4a composes (compaction-source handover IS the artifact 133's primer reads on resume)
- file:///C:/Dev/Specrew/proposals/143-session-start-welcome-orientation-reset-surface.md — Pillar 4b composes (welcome orientation surface; Pillar 4b is the hook-driven implementation that makes it work on launcher-bypass)
- **Claude Code Hooks reference**: <https://code.claude.com/docs/en/hooks.md> — `SessionStart` + `SessionEnd` events documented; source matcher (`startup | resume | clear | compact`); config in `.claude/settings.json`
- **Empirical compaction-vulnerability incidents (Pillar 4a motivation)**: F-024 boundary-compaction breach (`[[project_f024_boundary_compaction_breach_2026_05_20]]`); F-046 Antigravity 4-gate autopilot bypass; F-048 Codex branch-push discipline gap — all traced to Shape 3c post-compaction discipline drop

## Status history

- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep + design refinement from user. Three-pillar structure scoped after user observation that handover.md is the killer feature beyond bare slash-command relaunch. Pillar 1 ships independently as foundation; Pillars 2 + 3 sequence after.
- 2026-05-31: **amendment — Pillar 4 added (hook-based any-exit + any-launch handover).** User-driven reframe during F-051 work: original scope covered USER-INITIATED switch only via the `/specrew-switch-to` slash command; the same handover-md value applies to ANY session-end (compaction / clear / exit / normal end) AND any session-start (including direct host-CLI invocation that bypasses `specrew start`). Pillar 4a wires SessionEnd hook → handover authoring with source-matcher discrimination (compaction-source gets best-effort handover acknowledging dropped transcript). Pillar 4b wires SessionStart hook → automatic context injection regardless of launcher (closes the `claude`-in-directory bypass gap). Composes deeply with Proposal 105 (hook deployment substrate), Proposal 143 (welcome orientation), Proposal 133 (compaction primer). SP impact: 10-15 → 15-23 (+5-8 SP for Pillar 4). Priority: Tier 3 → Tier 1 (compaction-vulnerability bug class is empirically painful — F-024 / F-046 / F-048 incidents; launch-bypass gap is empirically real on multi-host setups). Multi-host scope: V1 ships Claude-first because Claude Code's `SessionStart` + `SessionEnd` hooks are fully documented; other hosts ship incrementally via Proposal 105's per-host adapter pattern as their hook surfaces are researched. Architectural framing: SessionStart hook makes Specrew governance defensively bypassable-only-by-explicit-opt-out (same pattern as git hooks — once installed, fire regardless of how the user invokes).
