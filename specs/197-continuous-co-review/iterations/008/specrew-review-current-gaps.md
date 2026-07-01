# Current `specrew-review` command — tested gaps (iter-008 refactor input)

**Date**: 2026-06-26 · **Method**: ran `scripts/specrew-review.ps1 --live` against a real change-set + read the `--live` path.
**Conclusion**: `/specrew-review --live` is a SEPARATE, divergent implementation from the navigator — it must be
refactored into a *second door into the same detached worktree pipeline* (component-design decision), not patched.

## Gaps (each implement task should trace to a G-id)

- **G1 — no auto-resolution.** Requires explicit `--host` AND `--design-context-ref`; errors `--host ... is
  required` and `ReviewRequest.v2 requires at least one design context source`. The navigator auto-resolves both
  (reviewer-hosts.json + the INT-006 workshop-lens bridge for the host; `Get-...NavigatorDesignContextRefs` for
  the design context). *Refactor: share the navigator's auto-resolution.*
- **G2 — runs IN-PLACE, no worktree, no sandbox.** Builds a request-bundle at `.specrew/review/tmp/_request-bundles`
  and runs the reviewer with cwd = the REAL repo (isolated-worktree count unchanged 75→75). The navigator uses a
  detached `git archive` READ-ONLY worktree. So the manual path has no isolation/mutation boundary. *Refactor:
  drive the same detached read-only worktree pipeline.*
- **G3 — synchronous / blocking.** Runs `Invoke-ContinuousCoReviewCheckpointReview` inline; no detached-async,
  no result-delivery loop, no rounds. *Refactor: same detached fire + the human-gated result/round loop.*
- **G4 — its OWN hardcoded source-layout contract resolution** (specrew-review.ps1 line 273:
  `Split-Path -Parent $PSScriptRoot / specs/197-continuous-co-review/contracts`) — NOT the deploy-aware
  `Get-ContinuousCoReviewContractRoot` resolver fixed for the navigator → breaks on a deployed project (same bug
  class). *Refactor: use the shared deploy-aware resolver.*
- **G5 — not deployed at a runnable path.** `scripts/specrew-review.ps1` is absent in a deployed project
  (EnglishIntake). The deploy ships the engine but not the manual entry-point. *Refactor: deploy it (extends the
  iter-007 deploy-completeness fix `49f88717`).*
- **G6 — shares the fragile diff model.** Same curated-diff + crammed-prompt + scaffolding-exclusion heuristic +
  byte-cap that iter-008 removes (the diff becomes a `.review/changes.diff` file in the worktree). *Refactor:
  removed by the shared pipeline.*

## Side-findings

- ~75 leftover `specrew-itask-*` worktree dirs + `.tar` under `$TEMP` — the worktree cleanup leaves DEBRIS;
  the redesign's worktree lifecycle must dispose reliably (relevant to component-design's worktree-materialize).
- On a self-host repo the scaffolding-exclusion heuristic blinds the review to its own product source (another
  reason G6's heuristic must go).
