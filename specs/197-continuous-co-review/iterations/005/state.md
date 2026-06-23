# Iteration 005 State

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T077 (isolated-task launcher — verified cross-platform)
**Tasks Remaining**: T078, T079, T080, T081
**In Progress**: T078 (the co-review navigator provider + registration)
**Updated**: 2026-06-24

## Execution

- T076 SPIKE PASSED CROSS-PLATFORM — Windows 10 AND WSL Ubuntu 24.04 (pwsh 7.6.1), the SAME
  scripts on both: provider exits ~1.7s, launcher runs DETACHED (outlives its parent), SELF-LIMITS
  (kills the child on timeout), NO orphan (child_still_alive=False). VERDICT detached+fast=True on
  both.
- **CRITICAL cross-platform defect caught (a Windows-only spike MISSED it):** on Linux the provider
  initially BLOCKED 18.2s (not 1.7s) because the spawned child inherits the parent's stdout/stderr
  PIPES and the parent cannot exit until the whole tree releases them. Windows detaches by default,
  so the bug was invisible there — shipping on the Windows-only result would have HUNG the Stop
  hook on Linux/macOS.
- **FIX (load-bearing for T077):** the spawn MUST redirect stdio
  (`-RedirectStandardOutput`/`-RedirectStandardError` to files) at BOTH hops (provider->launcher,
  launcher->reviewer). With it, the provider exits ~1.7s on Linux too.
- **macOS inferred** (same Unix/.NET CoreCLR stdio model + the same fix); a CI/Mac run is the final
  confirmation, tracked for T081.
- Other lesson: `Start-Process -Wait` waits for the whole process TREE, so the provider fires-and-
  returns (no `-Wait`); the launcher owns the timeout/kill loop in plain PowerShell (cross-platform),
  not OS process-group flags. Spike scripts: `.scratch/spike/` (throwaway, gitignored).
- T077 DONE (isolated-task launcher, the 139 foundation): `Start-SpecrewIsolatedTask` (review path
  built; `read-write`/`merge`/`preserve` throw with documented seam comments) + a detached
  `isolated-task-supervisor.ps1` + `Stop-SpecrewIsolatedTask` reaper, in the general
  `scripts/internal/agent-tasks/`. Stdio-redirect at both hops + no `-Wait` + the supervisor timeout
  loop. Two build findings folded in: `git archive | tar` corrupts binary through a pwsh pipe (fixed:
  `--output <tar>` then `tar -xf`); `pwsh -Command <string>` loses embedded quotes on Linux (fixed:
  write `harness.ps1`, run `pwsh -File`). Verified independently: Windows Pester 4/0; Linux (WSL)
  end-to-end probe — FIRE returns 0.11s, reviewer ran in the materialized tree, worktree in `/tmp`
  discarded, terminal status `done`/no-orphan. No F-184.

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
