# Iteration 006 Closeout Validation

**Feature**: 197-continuous-co-review
**Iteration**: 006 (the payoff — real reviewer + full-findings reporting)
**Date**: 2026-06-24

## Scope delivered

| Task | Outcome |
| ---- | ------- |
| T082 | The navigator fires a REAL, policy-selected, code-writer-independent reviewer (replaces the stub). `4bbbaf93` |
| T083 | A real reviewer's COMPLETE findings (all severities) are routed to the durable blackboard. `18557e80` |
| T084 | The inject note + the blocking STOP-BLOCK point the developer at the durable thread. `18557e80` |
| T085 | This closeout-validation + the Proposal 145 review + the LIVE-dispatcher multi-severity e2e. |

## The wiring (reuse, not rebuild)

The async navigator decomposes the Phase A `specrew review` orchestrator at its seams: **select at fire**
(in-repo — `Select-ContinuousCoReviewReviewerCandidate`, host-neutral, claude<->codex, NO host literal),
**host call detached** (the launcher runs `Invoke-ContinuousCoReviewReviewerExecution` against the
materialized read-only worktree, emitting FindingsResult.v1), **persist at reap** (in-repo, real
`$RepoRoot`: the full findings -> the blackboard, run_id normalized to the registry id so they co-locate
with the gate record under one `.specrew/review/inline/<run-id>/`).

## Guardrails honored

- **condition-b (mutation-guard): HONEST SKIP.** The reviewer runs in an isolated `git archive` export
  with no `.git`/`.specrew/`, so it physically cannot reach real repo/gate state — the export IS the
  read-only guarantee. The in-repo guard (which hashes Specrew-own roots + reads `git status`, both
  absent in the worktree) is SKIPPED with an explicit `posture='skipped-isolated-worktree'` + reason
  recorded in the run record — not a silent disable, not an inert-but-claimed control. No STOP tripped.
- **condition-c (timeout): RAISED to 300s** on BOTH the navigator co-review timeout AND the adapter's
  per-candidate `timeout_seconds` (a second timeout the plan did not name; the 30s default would have
  killed a real ~300s codex run).
- **FAIL-OPEN throughout:** a missing reviewer prerequisite -> no real review (NEVER a stub); a
  malformed/unwritable FindingsResult -> degrades to the one-line summary note; the navigator never
  throws to the F-185 dispatcher.

## Deterministic evidence (native Windows pwsh, Pester 3.4.0)

- `continuous-co-review-real-reviewer-wiring.Tests.ps1`: 12/0 (candidate threading, module-base
  resolution in the detached worktree, timeout, mutation-guard SKIP posture).
- `continuous-co-review-navigator.Tests.ps1`: 20/0 (incl. the 3 new findings-reporting guards:
  real-findings -> blackboard run_id-normalized + note-points-at-thread; stub writes no blackboard;
  fail-open degrades without throwing).
- **Full CCR + integration: 232/0** across 42 files (no regression).
- F-184 footprint: NONE (only `continuous-co-review/` + tests).

## The LIVE-dispatcher e2e (condition-d — the meaningful acceptance)

codex-cli 0.142.0 confirmed available (claude 2.1.187 as the alternate). The acceptance e2e MUST fire
through the LIVE DISPATCHER on a real host (NOT a direct function call — the iter-005 green-but-inert
lesson) and prove a MULTI-severity reviewer result lands durably in the blackboard AND surfaces all
findings to the developer. **Status: pending the run** (the maintainer's meaningful manual e2e, or a
scoped automated run). This is the final acceptance step before the 006 review-signoff.

## Proposal 145 review

One adversarial reviewer: **NEEDS-WORK** (1 MAJOR + 2 minor), everything else probed clean — a 21/21
no-mocks durability+surfacing harness confirmed the core requirement. M1 (the code-writer-independence
was not wired end-to-end: the provider discarded `--host-kind`, so production tiebroke alphabetically and
could pick the code-writer's own host) FIXED `ecf7c768` — the provider now threads `--host-kind` ->
`-CodeWriterHost` -> the policy; independence is real-by-logic, env vars are fallback-only; a param-path
test proves it with the env unset. M2 (a non-hermetic CONTROL test) FIXED. M3 (the `probe` commits) is the
known pre-existing main blemish. The NEEDS-WORK is RESOLVED (233/0 CCR). Full detail: review.md.
