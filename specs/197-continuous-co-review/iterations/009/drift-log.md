# Drift Log: Iteration 009

**Schema**: v1
**Spec**: file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/spec.md

Tracks divergences between the approved specification, plan, task table, and implementation evidence for Iteration 009. Drift is logged here before review concludes; it is not silently absorbed into implementation.

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: One DEPLOY-DRIFT defect found + fixed: the deployed co-review navigator provider was stale (pre-iter-008), so the AUTO co-review had been dark on every Stop — the feature silently not running. This is deployment/mirror drift, not requirement or source-implementation drift.

## Events

### D-197-I009-001 - The auto co-review navigator was DARK (stale deployed mirror, never re-synced after the iter-008 cutover)

**Status**: resolved
**Detected by**: maintainer question 2026-06-28 ("how come the co-reviewer is not running on this branch") -> empirical trace (ran the navigator decision + the deployed provider directly, per advisor guidance, after two wrong static guesses).

**Drift**: The DEPLOYED navigator provider `file:///C:/Dev/197-continuous-co-review/.specify/extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1` was the pre-iter-008 version — it loads `continuous-co-review-navigator.ps1` and calls `Invoke-ContinuousCoReviewNavigator` (both LEGACY), while the SOURCE provider was updated in the iter-008 worktree cutover to load `worktree-navigator.ps1` and call `Invoke-ContinuousCoReviewWorktreeNavigator`. The cutover updated source but **never re-synced the `.specify` deployed mirror**, so at every Stop the deployed provider emitted `WARN CO_REVIEW_NAVIGATOR_UNAVAILABLE ... Invoke-ContinuousCoReviewNavigator is undefined; co-review navigator dark this event` (to stderr — silent in practice) and exited fail-open. The auto co-review had NOT fired since 2026-06-23 (`co-review-navigator-state.json`); the 35+ pending runs were MANUAL `specrew review --live` invocations, which masked the dead auto-path.

**Evidence the source logic was fine** (so the bug was purely deploy-drift): the navigator's own decision, run on this checkout's live state, returned stage=implement + a fresh tree-id + not-deduped = WOULD-FIRE.

**Resolution**: re-synced the deployed provider to source (mirror parity restored). **PROVEN**: re-running the deployed provider fired a fresh review — new run `20260628T015643287-e4cb96e3`, `last_fired_tree_id` updated to the current tree-id (`f1bfe721…`), a new `.specrew/review/pending/` dir created.

**Trace**: FR-026, FR-030, FR-031 (the always-on auto-fire the deploy-drift silently broke), SC-022.

**Durable follow-ups (the bugs behind the bug)**: (1) **[ADDRESSED 2026-06-28]** the parity-coverage gap is closed by file:///C:/Dev/197-continuous-co-review/tests/continuous-co-review/governance/deployed-mirror-parity.Tests.ps1 — it asserts the F-197-owned deployed extension files are content-identical to source, PROVEN to catch drift (fails on an injected change, passes in parity); the deploy-completeness test only validated a fresh deploy, never the committed mirror. (2) **[NEXT]** "navigator dark" is emitted only to stderr (invisible), so it failed silently for days — being surfaced now (the second follow-up). (3) the 35-run stale pending backlog chokes the reap (~2 min) — cleared this session (37 -> 2); a durable backlog cap remains owed.

### Watch carry-over (from scaffolding)

## Watch Items

- **WSL-validation is a hard gate** for the R5 hard-kill (T091) — do NOT mark T091 done on Windows-only evidence.
- **"Any review > nothing"** — every degraded path must surface partial findings + the remediation menu; the signoff gate must never block on "no parseable verdict".
- **Provider ownership** — T096 edits `specrew-co-review-navigator-provider.ps1` (created by F-197 iter-005, 197-owned). Confirm via the protected-surface guard that this is NOT an F-184-protected provider edit before committing; if the guard flags it, route through the 197-owned navigator seam.
- **No F-184 protected-surface edits** (host/hook/registry/refocus/shared-governance).
