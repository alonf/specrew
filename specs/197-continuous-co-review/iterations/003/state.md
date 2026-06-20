# Iteration 003 State

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T058
**Tasks Remaining**: T059, T060, Stop-hook trigger (pulled forward, to be tasked), T061, T062, T063, T064
**In Progress**: T059
**Updated**: 2026-06-20

## Execution Summary

- Before-implement approved 2026-06-20; green baseline confirmed (continuous-co-review suite 134/0, spawn fix zero regressions).
- **T058 DONE** (FR-027): `review-run.json` carries `diff_hash` + `reviewed_ref`; `Get-ContinuousCoReviewLastPassingReviewState` resolves the last passing review from `.specrew/review/inline`; the orchestrator rebaselines each review to the last passing `reviewed_ref` (opt-in `-RebaselineToLastPass`) and records `reviewed_ref = HEAD`. Tests: rebaseline 1/1, run-index-writer 5/5, spine 4/4.
- **Resequence approved 2026-06-20** (D-197-I003-002): critical path is now T059 dispatcher → T060 run-wiring → Stop-hook trigger (delivers automatic per-stop run) → T061 gate floor as backstop. This pulls the F-184-protected Stop hook into Iteration 003 under the authorized coordination.
- **185 coordination (2026-06-20):** F-185 merges FIRST (host-neutral hook/refocus/gate foundation); 197's gate-floor WIRING (into `sync-boundary-state.ps1`) and the Stop-hook TRIGGER rebase onto merged 185 and register into 185's host-neutral Stop-hook seat. The every-stop-packet enforcement is handed to 185 (its FR-011 domain). 197 stays in its `continuous-co-review/` namespace pre-merge.
- **T061 decision logic DONE** (FR-025): `Get-ContinuousCoReviewSignoffGateDecision` / `Assert-ContinuousCoReviewSignoffGate` in `review-signoff-evidence-gate.ps1` — deterministic "no signoff on un-reviewed state" keyed on `diff_hash` freshness. **Wiring into `Invoke-SpecrewBoundaryStateSync` is the one-liner deferred to post-185-merge.**
- **Fresh-context Proposal 145 review run on T058/T061 (D-197-I003-003)** — found 2 BLOCKING defects + 5 advisories/nits; ALL fixed: F1 untracked-file false-allow (gate now blocks `unreviewed-working-tree`), F2 missing feature/iteration scoping (new `scope` field + filter; resolver/gate/orchestrator thread it; live-command `--scope` exposure deferred with the continuous wiring), F3 reviewed_ref provenance comment, F4 trace tags corrected, F5 falsifying tests added (gate 4→8), F6 robust DateTime sort, F7 diff_hash over the reviewable (post-exclusion) change-set. Full continuous-co-review suite **148/0**. Re-review pending.

## Scope

Phase A of the always-on extension: the 197-owned deterministic gate floor plus the
gate-keyed dispatcher, with no F-184 protected-surface edits. The live Stop-hook
trigger (Phase B) is Iteration 004. See [plan.md](plan.md) and
[design-analysis.md](design-analysis.md).

## Pending Human Decisions

- Plan-boundary approval for Iteration 003 (Phase A).
- Whether to commit the spec amendment and these iteration artifacts now, or hold them
  in the working tree.
