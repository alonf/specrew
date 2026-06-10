# Iteration Plan: 009 — Hook-primary rolling handover (delta-authored, section-owned)

**Schema**: v1
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

| ID | Status | Description | Traces |
| --- | --- | --- | --- |
| T001 | planned | Section-ownership model + per-section provenance (`authored_by_agent`) in `HandoverStore.ps1` (parser emits/reads it; writer merges hook-mechanical + preserved-agent). | FR-009, FR-021 |
| T002 | planned | `Get-SpecrewSessionDelta` accessor: changed-file count, recent commit subjects, uncommitted summary, branch/HEAD — pure-ish, fail-safe on git error. | FR-010 |
| T003 | planned | Stop provider authors mechanical sections from the delta, accumulates *What I just did* across the boundary window (reset on boundary change), stamps real `from_host` from `--host-kind`. Recalibrate hollow journaling to truly-empty only. | FR-009, FR-010, FR-021 |
| T004 | planned | Bootstrap render (`specrew-bootstrap-provider.ps1`): surface hook-captured content as resume context; soften the placeholder warning; render multi-line section content with indentation. | FR-002, FR-004 |
| T005 | planned | Tests: delta→not-hollow, accumulation, boundary reset, real from_host, agent-section preserve, atomic `.old` fallback; bootstrap suite stays green. | SC-004 |

## Out of scope (fast-follow)

- Transcript-tail enrichment (lift the rendered packet / last user instruction from the
  Claude `transcript_path`) — strictly additive on top of the git-delta base; deferred so
  the base lands clean and low-risk.
- Folding `Write-SpecrewHandoverContext` into the gate-stop / workshop skills as the
  curated overlay (it already exists; the hook no longer depends on it).
