# Iteration 005 State

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T076 spike (detached self-limiting spawn — PROVEN)
**Tasks Remaining**: T077, T078, T079, T080, T081
**In Progress**: T077 (the general isolated-task launcher)
**Updated**: 2026-06-23

## Execution

- T076 SPIKE PASSED (Windows): `Start-Process -PassThru` fire + a launcher with its own
  timeout loop -> provider exits 1.4s, launcher runs DETACHED to 10.7s, SELF-LIMITS (kills the
  child on timeout), NO orphan (child_still_alive=False), cleans up. VERDICT detached+fast=True.
  **Implementation notes (load-bearing):** (1) `Start-Process -Wait` waits for the whole process
  TREE, so the provider MUST fire-and-return (no `-Wait`); a test harness must observe PIDs
  independently, not via `-Wait`. (2) The launcher owns the timeout/kill loop in plain PowerShell
  (cross-platform), not OS process-group flags. Spike scripts: `.scratch/spike/` (throwaway).

## Scope (Phase B part 2 — the always-on async navigator)

The deferred high-risk piece: make co-review **auto-fire** at every implement checkpoint as a
pair-programming navigator, registered host-neutrally into the merged F-185 dispatcher, WITHOUT
blocking the Stop hook (the ~20s provider budget; #2885). Delivers FR-026/030/031 +
SC-019/020/021/022's auto-fire half.

Approved design (Iteration 004 decision, 2026-06-23):

1. **Self-limiting watchdog reviewer** — the provider spawns the reviewer wrapped in a watchdog
   that kills it + writes a status/result after N seconds, so it NEVER orphans by construction.
2. **Pending-review registry** — `.specrew/review/pending/<run-id>.json` ({pid, host, checkpoint,
   started_at, deadline, status}).
3. **Reaper** — the next-stop provider + a SessionStart sweep collect results, surface verdicts
   (185's `<<<SPECREW-STOP-BLOCK>>>` if blocking), kill zombies.
4. **Host-agnostic** — registered as a provider in `refocus-scopes.json` (185's dispatcher);
   detached spawn + watchdog via PowerShell 7 cross-platform primitives.

## Carried from Iteration 004

- Non-blocking 145 follow-ups: `TrunkName='main'` default + the F2 nested-key fail-safe.
- SC-012 maintainer real-host smoke test after this auto-fire lands.
