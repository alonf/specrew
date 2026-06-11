# Iteration Plan: 009 — Hook-primary rolling handover (delta-authored, section-owned)

**Schema**: v1
**Status**: executing
**Capacity**: 13/20 story_points
**Started**: 2026-06-11
**Feature**: 174-hook-driven-session-bootstrap
**Opened**: 2026-06-11 (maintainer direction, after the iter-008 cross-host dogfood)
**Baseline**: iter-008 HEAD (mirror-skew + anchorless-workshop fixes landed)

## Why this iteration

The iter-008 cross-host validation (T050) proved the resume RE-ANCHOR works across
exit/restart and host switches, but the rolling-handover BODY is hollow in practice:
84/84 and 15/15 `hollow-handover-at-stop` across the dogfood worktrees, and the single
most valuable moment — `notekeep-claude` mid-implement with `notekeep.py` + tests written
and UNCOMMITTED — carried a fully hollow handover. A kill there loses everything.

Root cause (proven from source): the Stop provider is deliberately transcript-blind, so
the only author is the agent via `Write-SpecrewHandoverContext` (FR-022), triggered only
when the agent "renders a boundary packet." Build turns, workshop turns, and kill-mid-flight
never render a packet, so they never author → placeholder. The kill case can NEVER be
agent-covered (no turn to author). The original "transcript-blind → defer to agent" decision
conflated "no transcript" with "nothing to write" — but the git/filesystem delta is right
there, host-universal, and needs neither a transcript nor agent cooperation.

## Approach (maintainer-agreed)

The Stop hook becomes the **primary author**. The agent path drops from *the mechanism* to
*optional enrichment*. Section ownership resolves the preserve-vs-clobber tension:

- **Mechanical sections (hook-owned, refreshed every material stop from the git/fs delta):**
  *What I just did*, *Why I'm stopping*, *Recommended next-immediate-step*,
  *Context the receiving host needs*. Never hollow; no transcript, no agent.
- *What I just did* **accumulates** the recent activity across the boundary window
  (bounded ring), reset on a boundary crossing — so a long between-gate build carries its
  whole arc, not just the last turn. (Your point: between-gate info is meaningful.)
- **Interpretive sections (agent-owned, optional):** *Open questions*, *Working hypothesis*.
  The hook writes a non-placeholder soft default; if the agent authored them
  (tracked per-section via an `authored_by_agent` frontmatter list), they are PRESERVED
  durably across subsequent hook stops.
- **Real `from_host`:** read the `--host-kind` the dispatcher already passes (line 535) and
  stamp it, fixing the `from_host: host` provenance gap (15/15 in the dogfood).
- **Safe replace (your ask):** the single write path stays the atomic
  `[IO.File]::Replace` + `.old` backup + plain-Set-Content fallback. BOTH the hook and the
  agent author go through `Write-SpecrewRollingHandoverContent` — no raw delete+recreate.
- **SessionStart read (your ask):** the bootstrap surfaces the hook-captured mechanical
  content as resume context and stops mislabeling it `[!] HOLLOW HANDOVER … REDUCED`. The
  hollow warning recalibrates to fire only when the hook captured literally nothing.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T001 | Section-ownership model + per-section provenance in `HandoverStore.ps1` (mechanical refresh, interpretive preserve, `from_commit`) | FR-009, FR-021 | US-1 | 3 | Implementer | done |
| T002 | `Get-SpecrewSessionDelta` accessor (changed files, recent commits, uncommitted, branch/HEAD; fail-safe) | FR-010 | US-1 | 2 | Implementer | done |
| T003 | Stop provider authors mechanical sections from the delta, accumulates across the boundary window, real `from_host` | FR-009, FR-010, FR-021 | US-1 | 3 | Implementer | done |
| T004 | Bootstrap render surfaces hook-captured content (no false "hollow"); multi-line indented | FR-002, FR-004 | US-1 | 2 | Implementer | done |
| T005 | Tests: delta, accumulation, boundary reset, `from_host`, agent-preserve, atomic `.old` | SC-004 | US-1 | 2 | Implementer | done |
| T006 | iter-9.1 multi-source core save — extract `Update-SpecrewRollingHandover` (one save path) activated by the Stop hook, a new `PostToolUse` hook (mid-workshop refresh), and the workshop skill; dispatcher passes `--source-event`. The workshop-state-saving fix | FR-009, FR-010, SC-004 | US-1 | 1 | Implementer | done |

**Capacity: 13/20** (T001 3 + T002 2 + T003 3 + T004 2 + T005 2 + T006 1 = 13). Hand-driven dev iteration;
bootstrap suite 21/21, PostToolUse dispatch e2e-proven.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Out of scope (fast-follow)

- Transcript-tail enrichment (lift the rendered packet / last user instruction from the
  Claude `transcript_path`) — strictly additive on top of the git-delta base; deferred so
  the base lands clean and low-risk.
- Folding `Write-SpecrewHandoverContext` into the gate-stop / workshop skills as the
  curated overlay (it already exists; the hook no longer depends on it).

## Live dogfood findings (2026-06-11, claude on a fresh trial) → iter-9.1

Capture-on-Stop is PROVEN (non-hollow body, real `from_host`, git delta). But the live
run showed the hook does not get to RUN often enough:

1. **No Stop events during the workshop (the big one).** The design workshop interacts
   via AskUserQuestion pickers = mid-turn tool calls, not end-of-turn Stops. On the Claude
   host the deployed hooks are `SessionStart + Stop` only, so the handover is FROZEN for
   the entire workshop phase (proven: one write ever; stale `branch master` while actually
   on `001-cross-platform-casio`). The agent-side per-lens checkpoint is the
   "agent-dependent residual" and Claude isn't doing it.
2. **A hard kill fires no Stop** → exit mid-turn captures nothing new.
3. **Managed-dir noise in the delta** — `specrew init`'s ~53 uncommitted scaffolding files
   (`.agents/.claude/.copilot/.cursor/.github/...`) drown the real work; the user source
   (`casio-watch/index.html`) was pushed past the file cap. `Get-SpecrewSessionDelta`
   should exclude/deprioritize the Specrew-managed dirs.
   (Side note, separate from handover: the run reproduced the free-run governance miss —
   Claude built `casio-watch/index.html` on `master` before being steered into the workshop.)

## Design direction (maintainer, 2026-06-11) — IMPLEMENTED as iter-9.1 (T006)

Multi-source, single-core handover save:
- **Core abstraction (NEW)** in the bootstrap component layer — one orchestrator, e.g.
  `Update-SpecrewRollingHandover -ProjectRoot -HostKind -Source` — owning resolve-context →
  material-change gate → `Get-SpecrewSessionDelta` → mechanical author + accumulate →
  atomic `Write-SpecrewRollingHandoverContent` → hollow journal. THE single save path
  (currently inline in the Stop provider; extract it).
- **Thin trigger adapters, all call the core:**
  - Stop hook (`specrew-handover-provider.ps1`) — Stop/agentStop/stop. [exists → refactor to call core]
  - **PostToolUse hook** — NEW: add `PostToolUse` to the handover provider's events + wire a
    Claude PostToolUse host hook; material-gated so it stays cheap. Covers the workshop
    (refreshes on each tracked lens-record write).
  - **Workshop skill** — the agent invokes a small script that calls the core per lens (and
    may pass interpretive content). Same save path as the hooks.
- Layering: `Write-SpecrewRollingHandoverContent` (atomic byte writer) < core orchestrator <
  trigger adapters. Concurrency: material gate + atomic replace = last-writer-wins-safe.
