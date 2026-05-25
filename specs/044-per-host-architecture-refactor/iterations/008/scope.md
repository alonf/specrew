# Iteration 008 Scope

**Feature**: F-044 | **Iteration**: 008 — Closeout Documentation + 2-Iteration Calculator Walkthrough + Three-Section Handoff Format Regression Fix (LIVE-TRACKED)

## Bug-by-bug closure

| Issue | Empirical source | Fix |
|---|---|---|
| **Closeout under-documented** | User-flagged at v0.27.0 release-readiness review: "We are missing the important step of closing an iteration and closing a feature. We must explain that this what creates the final artifacts and this what enables you to move to the next iteration or feature." | T001 README closeout extension + T002 getting-started Step 5 + T003 user-guide "Closing iterations + features" major section |
| **No worked example anywhere in docs** | Same user feedback: "and mabe a walkthrough with two iterations, add sin.cos,atn and sqrt to the calculator as the second iteration." | T004 user-guide "Walkthrough: a two-iteration calculator" — narrative-only, iter-1 = basic four ops + memory, iter-2 = sin/cos/atan/sqrt |
| **Three-section handoff format regression** | User manual-test feedback mid-iter-008: "In previous releases we had a clear information for the user in each gate stops. with specific questions answered. What I did, why I stopped, What I need from you. I do not see that anymore." | T006 coordinator-governance.md 14A — replace one-line directive with full canonical template + welcoming-tone mandate. T007 add `### Boundary handoff format` subsection to ALL 5 agent charters (was only in Implementer). T008 docs/user-guide.md "What you'll see at every boundary" section so users know what good UX looks like + how to re-prompt regressions |

## What iter-008 surfaced but is NOT in scope (Proposal 109 candidate)

The user also raised three coupled concerns about open-feature awareness:

- When a user restarts Specrew and starts a "new feature", are older iterations/features automatically closed? Does the user know if they aren't?
- Should Specrew surface all open iterations and features at session start?
- Are features that may never close part of the methodology? How is that tracked?

These share a common machinery (open-feature state-tracking + multi-feature switching discipline) and the user explicitly scoped them as **proposals to draft separately**. Per the "proposals always commit to main, not feature branches" rule, they ship as Proposal 109 candidate(s) committed directly to main after iter-008 lands. Not iter-008 scope.

## Methodology dogfood — fifth LIVE-TRACKED iteration

| Iteration | Pattern | SP planned | SP actual | Variance |
|---|---|---|---|---|
| iter-001 | Backfill | 18 | 18 | 0 (forced) |
| iter-002 | Backfill | 6 | 6 | 0 (forced) |
| iter-003 | Backfill | 4 | 4 | 0 (forced) |
| iter-004 | **LIVE** | 3 | 3 | 0 |
| iter-005 | **LIVE** | 8 | 8 (T007 deferred) | -0.5 |
| iter-006 | **LIVE** | 5.5 | 4 (T002 simpler than planned) | -1.5 |
| iter-007 | **LIVE** | 7 | 7 | 0 |
| iter-008 | **LIVE** | 7 → 10 (mid-iteration expansion) | 10 | 0 (final) |

iter-008's variance pattern is the most informative across the live-tracked set: original plan was 5 tasks at 7 SP. Mid-iteration, user manual-test surfaced a methodology-fundamental regression (three-section format propagation gap). I expanded scope by 3 tasks / 3 SP rather than deferring — because (a) the user explicitly flagged manual re-test conditional on this fix, (b) the v0.27.0 release narrative would have been incomplete without it, (c) the fix was structurally small but high-leverage. Calibration data point: **welcome scope expansion when the new task is methodology-fundamental AND fits inside spare capacity.** The 20-SP capacity meant 7 → 10 SP was still well under threshold.

## Cross-feature bundle disclosure

iter-008 is the final iteration of F-044. Ships in the same PR (#844) as F-043's iter-001 + F-044 iter-001..007. See [closeout-dashboard.md](../../closeout-dashboard.md) for the cross-feature bundle dashboard.
