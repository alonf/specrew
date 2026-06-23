# Design Analysis: Iteration 005 (Phase B part 2 — async co-review navigator)

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Date**: 2026-06-23
**Base**: Iteration 004 close (`cdc9d7f8`)

## The challenge

Make co-review **auto-fire** at every real implement checkpoint (FR-026/030/031) WITHOUT
(a) blocking the Stop hook — 185 runs Stop providers synchronously inside a shared ~20s budget,
and a reviewer spawn is 30s+ — and (b) ever leaking an orphaned process OR worktree, across all
five hosts. (b) is the crux: the orphan/timeout concern this feature opened on.

## F-184 footprint

NONE. Registration is a row in the non-protected `refocus-scopes.json` REGISTRY plus
non-protected scripts; the dispatcher, shared-governance, and refocus discipline are untouched.

## Naming + the general abstraction (maintainer direction, 2026-06-23)

The supervised, isolated, disposable process is NOT a "review watchdog" — it is the general
**isolated-task launcher**, which is the Proposal 139 multi-agent foundation (the Layer-2
headless-process-orchestration seam) arriving early. Review is its FIRST consumer. We design the
general seams now and **implement only the review path**; future consumers plug into the seams
without a rebuild. Build it in a GENERAL location (e.g. `scripts/internal/agent-tasks/`), not
under `continuous-co-review/`, to signal it is shared infrastructure.

### The launcher contract (general)

`Start-SpecrewIsolatedTask` always does three things, parameterized by two policies:

1. **Spawn** a harness process in an **isolated git worktree** materialized from a target
   tree-id, supervised with a timeout (the old "watchdog" role — kill on timeout, write status).
2. **`access` mode** — `read-only` (review) | `read-write` (implementation). RO also launches the
   host in its native read-only mode (`--permission-mode plan` / `--sandbox read-only`) as
   belt-and-suspenders.
3. **`disposition` on completion** — what to do with the worktree:
   - `discard` — delete it (review: nothing to merge). **THE ONLY ONE BUILT NOW.**
   - `merge` — merge the worktree's changes back to base, then delete (concurrent
     implementation / multi-dev). **DESIGNED, DEFERRED** (see Future extension points).
   - `preserve` — keep for human inspection (failed/conflicted task). **DEFERRED.**

The launcher OWNS the full worktree lifecycle (create -> frozen -> dispose), entirely on the
detached path so the provider/Stop-hook never pays for it. The reaper backstops orphaned
worktrees from a dead launcher, exactly as it backstops zombie processes.

## The async navigator (Iteration 005's consumer — what we build)

### Provider = a FAST dispatcher, never the reviewer

A `co-review-navigator` row in `refocus-scopes.json` (`events: [Stop, agentStop, stop]`) ->
`continuous-co-review-provider.ps1`. On each Stop it does only cheap work (well inside the budget):

1. **Reap** prior pending tasks (surface a completed verdict; force-continue via 185's
   `<<<SPECREW-STOP-BLOCK>>>` if blocking; kill zombie processes + orphaned worktrees).
2. If this stop is a **real implement checkpoint** (reuse the Phase A
   `Invoke-ContinuousCoReviewGateDispatch` logic) AND the reviewed tree-id differs from the last
   reviewed one (dedup), **fire** `Start-SpecrewIsolatedTask` with
   `{access: read-only, disposition: discard, task: code-review}` and return immediately.
3. Otherwise no-op. It NEVER waits for a review.

### The review request is artifact-agnostic

The task carries an **artifact + contract** ({kind: code, plan, tasks, spec}, the contract to
review against). Iteration 005 ships the `code` contract; reviewing a plan/tasks/spec is a later
contract registration, NOT a new launcher (DEFERRED — designed via this seam).

### Three-tier file layout

| What | Where | Why |
| ---- | ----- | --- |
| The worktree + the reviewer's scratch | ephemeral `$TEMP`, OUTSIDE the repo, in no tree-id | throwaway per task; never inside the repo it snapshots. |
| The pending-task registry + progress (launcher<->reaper signaling) | stable `.specrew/review/pending/`, gitignored + digest-stripped | must survive the fire->reap gap ACROSS a session boundary so the SessionStart sweep finds prior-session orphans; a volatile `$TEMP` could be cleared. |
| The persistent evidence (passing run records the gate reads) | in-repo `.specrew/review/runs/`, digest-stripped | durable proof the Iteration-004 gate enforces against at signoff. |

Free property: because `.specrew/**` is already stripped from the reviewed tree-id, the worktree
(materialized from that tree-id) is automatically clean of all our bookkeeping — the reviewer
sees only the actual source, no recursion, no special-casing.

## Future extension points (DESIGNED, DEFERRED — documented seams, not built here)

These are captured in the launcher's interface + code comments so later features plug in cleanly:

- **`merge` disposition -> the merge-agent (Proposals 010/134/149).** Concurrent implementation:
  an agent branches a RW worktree from base B; the dev moves main to B'; on success the launcher
  must **3-way merge (B, worktree, B')** back. Clean -> merge + delete; conflict -> `preserve` +
  hand to the merge-agent / human; failed -> discard. That conflict path IS the merge-agent and is
  a feature of its own; matches the memory note "merge on clean finish, cleanup on kill-all."
- **`read-write` access** for implementation tasks (review stays RO).
- **Multi-artifact review contracts** (plan/tasks/spec), via the artifact+contract seam.
- **Multi-task orchestration** (139): many isolated tasks in parallel, each its own worktree +
  disposition; the registry already supports N entries (we run one-at-a-time for review).

## Key design decisions

1. **The detached spawn (highest risk) — SPIKE FIRST.** `Start-Process -PassThru` launching the
   launcher (timeout logic in plain PowerShell, most cross-platform/testable) vs a background job
   vs a raw detached `.NET` process. Recommend Start-Process; PROVE on win/mac/linux before the
   build commits.
2. **Concurrency:** one pending review at a time (a new checkpoint supersedes — kills + replaces —
   an un-reaped prior). The registry schema allows N (for 139); review uses 1.
3. **Timeout:** a config scalar (mirroring `co_review_gate_enforcement`), safe default ~120s.
4. **Cadence:** dedup by reviewed-tree-id (reuse the Iteration-004 digest) so an unchanged
   increment does not re-spawn.

## Scope (what Iteration 005 implements)

The general launcher with BOTH policy seams present, but only `access: read-only` +
`disposition: discard` + `task: code-review` implemented. `merge`/`preserve`/`read-write`/
non-code contracts are interface + comments only (deferred per the table above). Plus: the
provider + registration, the pending registry, the reaper (next-stop + SessionStart sweep), the
tree-id dedup, and the Iteration-004 145 carries (TrunkName, F2). Estimate ~14-18 SP.
