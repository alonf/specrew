# Iteration 005 State

**Feature**: 197-continuous-co-review
**Iteration**: 005
**Schema**: v1
**Current Phase**: iteration-closeout
**Iteration Status**: complete
**Last Completed Task**: iteration-closeout — iteration 005 CLOSED (review-signoff approved + retro done)
**Tasks Remaining**: (none — iteration 005 complete) -> next: plan Iteration 006 (real reviewer + full-findings reporting)
**In Progress**: (none)
**Baseline Ref**: cdc9d7f8
**Updated**: 2026-06-24

## Review-signoff verdict — APPROVED (2026-06-24)

Maintainer APPROVED for review-signoff (iteration-005), independently verified: navigator 17/0 (own
run), 197's own commits all-Alon/zero-probe, both 145 reviews real (affirmative-pass soundness + the
catalog-drift MAJOR). Honest residual accepted. Decision: **close 005 -> retro -> iteration-closeout,
then plan Iteration 006**. Two maintainer corrections recorded:

- The 4 `probe` commits are ALREADY on protected `origin/main` (F-185), not 197-only -> accept +
  document as a pre-existing cosmetic blemish; do NOT rewrite protected main. (review.md fixed.)
- The deploy-mechanism carry (`refocus-scopes.json` not synced on `specrew update`) -> file it but
  COORDINATE with Proposal 198 (self-host currency; same class as the Devin `extensions.yml` drift).

**Iteration 006 scope (maintainer-set):** the real reviewer + FULL-FINDINGS REPORTING (the payoff).
Persist a per-run full report (all findings, all severities) DURABLY — STOP deleting it on reap
(`Clear-...Entry` `Remove-Item`) — and point the inject note at it, using Proposal 197's
blackboard/discussion file as the surface. Summary-only is acceptable ONLY while the reviewer is the
no-findings stub. e2e: the meaningful e2e (real findings surfaced) runs at the END of 006.

## Closeout build (maintainer "implement all, fix all", 2026-06-24)

- Navigator hardening (4 findings) + PASS->gate promotion to `.specrew/review/inline/` + the STUB
  EXCLUSION (a stub never promotes -> the gate is not auto-satisfiable by plumbing; guard test). `bc729b67`.
- Dispatcher F-184 (maintainer-authorized): codex clean-args + stop-block merge, 3 copies byte-identical,
  scoped protected-surface-guard exception. `4f02a6c0`.
- FileList: 37 missing `continuous-co-review` + `agent-tasks` deployable files added to Specrew.psd1. `212b33d6`.
- Dogfood fixes (caught by the navigator-on-its-own-code dogfood): `& git` encoding -> Process; huge
  diff arg -> batched. `c2cf8a38`.
- VERIFIED: full CCR + key integration 216/0; navigator 16/0; dogfood mechanism end-to-end; cross-platform.
- RESIDUAL (fast-follow, not a blocker): wire the REAL reviewer (the navigator fires a stub today; the
  manual `specrew review --live` path produces real gate evidence). See closeout-validation.md.

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
