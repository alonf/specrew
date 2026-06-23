# Iteration 005 State

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: DOGFOOD (mechanism validated end-to-end on iter-005's own code; 2 bugs caught + fixed)
**Tasks Remaining**: T081 (closeout: 4 reviewer findings + 3 flagged gaps + formal tests + 145 review)
**In Progress**: T081 closeout (pending maintainer pace decision after the dogfood checkpoint)
**Updated**: 2026-06-24

## Dogfood outcome (full detail: dogfood-result.md)

Ran the navigator on its OWN code with a real `claude -p` reviewer: FIRED -> materialized the live
tree in a `$TEMP` worktree -> a real 51s claude review -> substantive verdict (4 findings) -> reap.
The mechanism works end-to-end. The dogfood CAUGHT + FIXED 2 production bugs the unit tests missed:
(1) `& git` throws in the redirected-provider context (non-console UTF-8 `[Console]::OutputEncoding`)
-> `Invoke-ContinuousCoReviewGit` rewritten to an explicit `System.Diagnostics.Process`; (2) the
reviewable git-diff passed all changed paths as args -> command-line limit on a real repo -> batched
(`git diff` has no `--pathspec-from-file`). Both validated: diff-provider 6/0, digest 10/0, gate 11/0,
navigator 8/0; full reap re-run clean. F-184: none.

## Open gaps flagged by the T078/T079 implementer (tracked for T081/closeout)

1. **FileList (closeout blocker):** `tests/integration/filelist-completeness.tests.ps1` is RED — 37
   deployable files missing from `Specrew.psd1` (all of `continuous-co-review/**` + `agent-tasks/**`;
   the already-shipped `specrew review` depends on the unshipped `_load.ps1`). Fix before ship.
2. **Stop-block collision (dispatcher/F-184):** `$stopBlockReason` is last-writer-wins; navigator (50)
   after conformance (40) overwrites a co-occurring conformance block. Needs a dispatcher merge/priority
   policy. Defer to a planner/proposal decision.
3. **`--event-json` codex gap (dispatcher/F-184):** the navigator falls to the dispatcher else-branch and
   gets `--event-json`, which on codex Stop blows the Windows cmdline limit -> the provider silently never
   launches. Fix = add `co-review-navigator` to the clean-args allow-list (`specrew-hook-dispatcher.ps1`
   ~L932). Blocks the codex host-neutral claim; NOT the Claude dogfood.
4. **PASS->runs/ promotion DEFERRED (by design this cut):** the reap deletes the pending run dir; auto-fired
   PASS verdicts do NOT yet feed the Iteration-004 signoff gate. Navigator = pair-programming feedback; the
   deterministic gate floor remains the authority. Connecting them (promote PASS to runs/) is a follow-on.

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
