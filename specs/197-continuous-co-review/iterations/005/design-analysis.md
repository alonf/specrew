# Design Analysis: Iteration 005 (Phase B part 2 — async Stop-hook navigator)

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Date**: 2026-06-23
**Base**: Iteration 004 close (`cdc9d7f8`)

## The challenge

Make co-review **auto-fire** at every real implement checkpoint (FR-026/030/031) WITHOUT
(a) blocking the Stop hook — 185 runs Stop providers synchronously inside a shared ~20s budget,
and a reviewer spawn is 30s+ — and (b) ever leaking an orphaned reviewer process, across all
five hosts. (b) is the crux: it is the exact orphan/timeout concern this feature opened on.

## F-184 footprint

NONE. Registration is a row in the non-protected `refocus-scopes.json` REGISTRY plus a
197-owned provider script under `scripts/internal/continuous-co-review/`; the dispatcher,
shared-governance, and refocus discipline are untouched (confirmed in Iteration 004's seam
investigation).

## The design (approved in principle, Iteration 004)

### 1. Provider registration (host-neutral)

A `co-review-navigator` row in `refocus-scopes.json` (`events: [Stop, agentStop, stop]`, an
`order` after conformance) -> `continuous-co-review-provider.ps1`. The dispatcher passes
`--host-kind`, `--source-event`, `--transcript-path`; the provider returns stdout (normal inject)
or a `<<<SPECREW-STOP-BLOCK>>>` sentinel (force-continue), exit 0 (fail-open). This is the SAME
contract the conformance provider uses, so it composes with 185's machinery with no dispatcher edit.

### 2. The provider is a FAST dispatcher, never the reviewer

On each Stop the provider does only cheap work (well inside the budget):

1. **Reap** prior pending reviews (step 4) and surface any completed verdict.
2. If this stop is a **real implement checkpoint** (reuse the Phase A
   `Invoke-ContinuousCoReviewGateDispatch` real-checkpoint-vs-casual-yield logic), **fire** a
   detached reviewer (step 3) and return immediately.
3. Otherwise no-op.

It NEVER waits for a review. Respecting #2885, it adds ~no synchronous cost.

### 3. Self-limiting watchdog reviewer (no orphans BY CONSTRUCTION)

The provider does not spawn the reviewer directly; it spawns a **watchdog wrapper**
(`reviewer-watchdog.ps1`) detached, then returns. The watchdog:

- launches the reviewer adapter (the Phase A spawn) with its own timeout,
- on timeout OR completion, kills the reviewer process tree and writes a terminal
  `status` + result into the run dir,
- exits.

Because the watchdog enforces the timeout itself, the reviewer **cannot run forever even if no
reaper ever runs** — orphan-prevention does not depend on the reaper. The reaper is for
collecting results + zombies, not for safety.

### 4. Pending-review registry + reaper

- **Registry:** `.specrew/review/pending/<run-id>.json` = `{run_id, pid, host, checkpoint_id,
  started_at, deadline, status}`, written when a review fires.
- **Reaper (next-stop):** the provider, on its next invocation, reads the registry: `done` ->
  collect the result, surface the verdict (emit `<<<SPECREW-STOP-BLOCK>>>` if blocking), clear;
  `past-deadline && pid alive` -> kill + mark failed; `pid gone && no result` -> mark crashed.
- **Reaper (SessionStart sweep):** a SessionStart provider reaps cross-session orphans (a review
  still pending when a prior session ended).

### 5. Verdict surfacing

Checkpoint N's review surfaces at stop N+1 (the navigator nudge; force-continue via STOP-BLOCK
when blocking) AND the Iteration-004 gate floor enforces at review-signoff. The developer sees
the prior checkpoint's verdict on their next yield — the pair-programming-navigator cadence.

## Key design decisions (pending maintainer input)

1. **The detached self-limiting spawn (the highest-risk mechanism).** Candidates: (a)
   `Start-Process -PassThru` (no `-Wait`) launching the watchdog, which then governs the
   reviewer; (b) a PowerShell background job; (c) a fully detached `System.Diagnostics.Process`
   with `CREATE_NEW_PROCESS_GROUP`/no-wait. (a) is the most cross-platform + testable in PS7 and
   keeps the timeout logic in plain PowerShell (the watchdog) rather than OS flags. **Recommend
   (a).** Spike + test on win/mac/linux before committing.
2. **Registry concurrency:** one pending review at a time (a new checkpoint supersedes — kills +
   replaces — an un-reaped prior) vs many. **Recommend one-at-a-time** (the navigator reviews the
   latest increment; simpler lifecycle, bounded process count).
3. **Watchdog timeout N:** a fixed default (e.g., 120s) vs config. **Recommend** a config scalar
   (mirroring `co_review_gate_enforcement`) with a safe default.
4. **Checkpoint cadence:** fire on every real implement checkpoint vs throttle (skip if a review
   for the same/near tree already ran). **Recommend** dedup by reviewed-tree-id (reuse the
   Iteration-004 digest) so an unchanged increment does not re-spawn.

## Capacity / sequencing (to set at plan time)

Likely tasks: provider + registration; the watchdog spawn (spike first); the registry; the
reaper (next-stop + SessionStart); dedup-by-tree-id; tests (fire/reap/orphan-kill/cross-session
sweep, per-host spawn). Plus the Iteration-004 145 carries (TrunkName, F2). Estimate ~14-18 SP.
