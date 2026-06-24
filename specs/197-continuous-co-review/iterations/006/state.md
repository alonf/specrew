# Iteration 006 State

**Feature**: 197-continuous-co-review
**Iteration**: 006
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T085 145 review (NEEDS-WORK) + M1/M2 fixes — independence wired end-to-end, test hermetic; 233/0 CCR
**Tasks Remaining**: T085 — the LIVE-dispatcher multi-severity e2e (the meaningful acceptance) + review.md/closeout finalize
**In Progress**: T085 (the live e2e)
**Updated**: 2026-06-24

## T085 145 review + M1/M2 fixes (2026-06-24)

One adversarial 145 reviewer: NEEDS-WORK, 1 MAJOR + 2 minor; everything else probed clean (incl. a 21/21
no-mocks durability+surfacing harness confirming the core). M1 (MAJOR, maintainer chose fix-it): the
code-writer-INDEPENDENT selection was not wired end-to-end — the provider received `--host-kind` but
discarded it, and Specrew never sets `SPECREW_HOST`, so production fell to an alphabetical tiebreak that
could pick the code-writer's own host. FIXED: the provider threads `--host-kind` -> the navigator's new
`-CodeWriterHost` param -> the policy (env vars are fallback-only now); independence is real-by-logic, not
config-incidental. Param-path test added (proves it with the env UNSET). M2 (minor): the real-guard CONTROL
test snapshotted the LIVE repo -> flaked on concurrent writes; FIXED to a hermetic temp repo. M3 (the probe
commits) is the known pre-existing main blemish. 233/0 CCR; provider copies in sync.

## Before-implement verdict — APPROVED (2026-06-24)

Maintainer APPROVED for before-implement (iteration 006), artifact-level verified (all foldings landed
with real reasoning). Guardrails to HOLD during implementation: (1) STOP if neither mutation-guard
posture (skip vs re-aim) is honest — the plan reasoned SKIP (the guard hashes Specrew-own roots + reads
git status, both absent in the detached worktree; the read-only export is the primary guarantee);
(2) raise the co-review timeout above ~300s BEFORE the live e2e; (3) the T085 e2e MUST fire through the
LIVE dispatcher (not a direct call). Specrew-repo carries FILED: validator-grandfathering = alonf/specrew#2902;
refocus-scopes deploy-sync (coordinate with 198) = alonf/specrew#2903. Hardening gate stays Planner-authored
(the independent Reviewer's value is at review-signoff).

## Scope (the payoff: real reviewer + full-findings reporting)

Iteration 005 shipped the async navigator foundation (the isolated-task launcher, the pending registry,
the reaper, the SessionStart sweep, the host-neutral provider registration) but the navigator fires a
verdict-emitting STUB. Iteration 006 is the PAYOFF: replace the stub with the REAL policy-driven reviewer
and surface its COMPLETE findings (all severities) durably, so the developer actually sees them.

Three moves, all WIRING (not building) the Phase A reviewer infrastructure:

1. **Real reviewer (T082):** select a code-writer-independent host in-repo at fire
   (`Select-ContinuousCoReviewReviewerCandidate`), run it through the launcher against the materialized
   worktree (`Invoke-ContinuousCoReviewReviewerExecution`; settle the mutation-guard posture — the
   read-only export is the primary guarantee), emit a real FindingsResult.v1. Raise the co-review
   timeout so a real run completes.
2. **Full-findings report (T083):** in the reap, route the complete parsed FindingsResult to the
   existing blackboard writer (`.specrew/review/inline/<run-id>/`), run_id normalized to the registry
   run-id, fail-open.
3. **Surface (T084):** point the reap inject note at the blackboard thread so the developer sees ALL
   findings, not the one-line `N finding(s): <first>` summary.

## Carried context from iteration 005

- **The residual that opened 006** (iteration-005 closeout-validation, "Findings-reporting surface"):
  the navigator surfaces only a summary and the real reviewer would lose all but the first finding; the
  real-reviewer wiring MUST also persist a per-run full-findings report and point the inject note at it.
- **Load-bearing (proven):** `pending/<run-id>/` (reaped/deleted) is SEPARATE from `inline/<run-id>/`
  (the durable blackboard) — no reap-ordering change needed.
- **Timeout:** iteration 002's live codex review needed ~300s (a 120s rerun timed out); the navigator
  default is 120s.
- **Deploy carry (OUT of 006):** `refocus-scopes.json` is not re-synced on `specrew update` — a separate
  proposal coordinated with Proposal 198.

## Next

- Plan-boundary verdict -> tasks -> before-implement, then execute T082..T085.
- The meaningful E2E (T085) fires through the LIVE DISPATCHER on a real host (codex), not a direct call.
