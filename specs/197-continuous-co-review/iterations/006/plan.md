# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 19.00/20 story_points
**Started**: 2026-06-24
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

The PAYOFF of continuous co-review: replace the iteration-005 verdict-emitting STUB with the REAL
policy-driven reviewer, and surface the reviewer's COMPLETE findings (all severities) durably so the
developer actually sees them. This is WIRING the Phase A reviewer infrastructure (catalog, selection,
adapters, execution engine, blackboard writer) into the iteration-005 async navigator seam — NOT
building new reviewer infrastructure.

| Requirement | Summary |
| ----------- | ------- |
| FR-026 | The Stop-hook navigator reviews each real implement checkpoint; now via a REAL reviewer, not the stub. |
| FR-030 | The navigator reuses the host-neutral abstraction; reviewer-host selection stays host-neutral (`Select-...ReviewerCandidate`). |
| FR-031 | The checkpoint-boundary trigger fires the real reviewer (no PostToolUse / per-file regression). |
| FR-004 | Route the reviewer's FULL findings to the existing blackboard thread under `.specrew/review/inline/<run-id>/`. |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ |
| T082 | Wire the REAL reviewer: replace the STUB in `Build-ContinuousCoReviewNavigatorReviewerCommand` with the policy-driven path. Run `Select-ContinuousCoReviewReviewerCandidate` IN-REPO at fire (where catalog/install-probe/auth resolve), pass the chosen code-writer-INDEPENDENT host/model into a detached reviewer `-Command` that dot-sources the resolved Specrew module base, runs `Invoke-ContinuousCoReviewReviewerExecution` against the materialized worktree, and emits FindingsResult.v1 to stdout. SETTLE the execution-engine mutation-guard posture on the detached-worktree path against the guard body (it hashes Specrew-own roots + reads `git status`, both absent in the worktree; the read-only export is the primary guarantee, so SKIP is the likely call — re-aiming makes it inert, leaving it at the repo root risks a concurrent-edit false-trip). Raise the navigator co-review timeout config so a real reviewer run can complete (iter-002 proved ~300s for a real codex review; the default 120s kills it). Budget HONESTLY for the FIRST live end-to-end reviewer run (cf. iter-002's codex live-path repair). | FR-026, FR-030, FR-031 | Real reviewer | 6.00 | Implementer | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | planned |
| T083 | Route the FULL findings to the durable blackboard. In the reap done-branch (in-repo, where `$RepoRoot` + the parsed verdict are available), call `Write-ContinuousCoReviewBlackboardThread` with the complete parsed FindingsResult (`$verdict.raw`), run_id NORMALIZED to the registry run-id so findings co-locate with the gate record under `.specrew/review/inline/<run-id>/` (findings-result.json + review-thread.json). ALL severities (blocking, advisory, nit), every disposition. EXCLUDE the stub (no real findings). FAIL-OPEN (a malformed/absent FindingsResult degrades to the summary note; the navigator never throws to the dispatcher). The reap deletes only `pending/<run-id>/`; the blackboard `inline/` dir is SEPARATE and survives — NO reap-ordering change. | FR-004 | Full-findings report | 2.00 | Implementer | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | planned |
| T084 | Surface the blackboard at the inject note. Point the reap's inject_note (and the blocking STOP-BLOCK directive) at the durable blackboard thread (`.specrew/review/inline/<run-id>/review-thread.json` + findings-result.json) so the developer sees ALL findings, replacing the one-line `N finding(s): <first comment>` summary. Keep the no-thread / stub path on the existing summary note. | FR-026, FR-004 | Full-findings report | 1.50 | Reviewer | `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | planned |
| T085 | Tests + closeout-validation + Proposal 145 review + the MEANINGFUL E2E. Deterministic coverage: candidate selection threaded into the fired `-Command`; module-base resolution; run_id normalization (findings + gate record co-located); timeout config honored; all-severity findings reach the blackboard; fail-open on malformed FindingsResult; the inject note points at the thread; the chosen mutation-guard posture does not false-invalidate a real run under a concurrent repo edit (and the worktree carries no `.git`/`.specrew/`). The E2E fires through the LIVE DISPATCHER on a real host (NOT a direct function call — the green-but-inert lesson) and proves a MULTI-severity reviewer result lands durably in `inline/` AND surfaces all findings to the developer. E2E reviewer-host: codex (live-validated iter-002), with the ~300s timeout. GATED on T086 (the navigator must be able to select a real host). | FR-026, FR-030, FR-031, FR-004, SC-006 | Validation and E2E | 4.50 | Reviewer | `tests/continuous-co-review/**`; `specs/197-continuous-co-review/iterations/006/**` | planned |
| T086 | PERSISTED HUMAN-AUTHORIZATION seam (the iter-002-class gap the live-not-mocked e2e found; the honest completion of T082). Today the navigator's auto-fire path cannot obtain a reviewer authorization — the default catalog ships every host `allowed=$false`, the plan-builder calls `Get-...ReviewerHostCatalog` with NO config, and nothing persists a runtime authorization — so it NEVER fires a real review (T082's deterministic tests MOCKED `Select-...ReviewerCandidate`, hiding it). FIX (Option A): (1) the EXISTING `specrew review --host/--authorization-ref` HUMAN path PERSISTS its built catalog config to `.specrew/reviewer-hosts.json` (catalog shape, `allowed=$true` + `authorization_ref` = the human-provenance anchor); (2) `New-ContinuousCoReviewNavigatorReviewerPlan` LOADS it READ-ONLY and passes it to `Get-...ReviewerHostCatalog -Configuration` (absent/unreadable -> default -> FAIL-OPEN, never a stub). The navigator NEVER writes/self-authorizes (no agent self-authorization — Proposal 190 hole; `authorization_ref` records the human). Mandatory NON-MOCKED test: a real un-mocked config -> authorized codex selected; empty/unauthorized -> fail-open (do NOT mock the selection in the test that proves selection). | FR-026, FR-030, FR-031 | Persisted authorization | 5.00 | Implementer | `scripts/specrew-review.ps1`; `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1`; `tests/continuous-co-review/**` | planned |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Restored project-global cap; iteration 005's 30 was a one-off maintainer-authorized override that does not carry forward. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded wiring iteration. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Concurrency Rationale

- T082 is the spine and must land first: T083/T084 surface what the real reviewer produces, and the
  meaningful E2E (T085) needs a real reviewer to fire.
- T083 and T084 are COUPLED — both edit the reap done-branch in `continuous-co-review-navigator.ps1`
  (T083 writes the blackboard from the parsed verdict before `Clear-...Entry`; T084 points the inject
  note at that just-written thread). Sequence T083 then T084; they form one semantic-commit group.
- T085 is the closeout/validation task and remains last; its live-dispatcher E2E is the iteration's
  acceptance evidence and must not be a direct-call dogfood.

## Semantic-commit cadence (for the Implementer)

Land each boundary's work as a discrete commit, not one mega-commit:

1. T082 — the real reviewer wiring (navigator `-Command` + selection + execution + timeout).
2. T083 + T084 — the findings→blackboard routing and the inject-note surfacing (one coupled commit).
3. T085 — the test suite + closeout-validation + 145 review + the live-dispatcher E2E evidence.

## Traceability Summary

- In-scope requirements: FR-026, FR-030, FR-031 (navigator real reviewer), FR-004 (blackboard
  full-findings reporting). No new FR/SC; this implements existing requirements the iteration-005 stub
  deferred.
- Built: the real policy-driven reviewer on the iteration-005 launcher seam; full-findings durable
  reporting on the existing blackboard writer; the inject-note surfacing.
- Reused (NOT built): the Phase A catalog/selection/adapters/execution-engine/blackboard-writer
  (`scripts/internal/continuous-co-review/`), the iteration-005 isolated-task launcher
  (`scripts/internal/agent-tasks/`), and the `specrew review --live` orchestrator pattern
  (`checkpoint-review-orchestrator.ps1`) as the wiring blueprint.
- Capacity status: PASS, 14.00/20 story_points (slack retained deliberately — the first live reviewer
  run is where surprises live; T082/T085 are not estimated to consume the cap).

## Notes

- **Reviewer-host selection stays HOST-NEUTRAL.** `Select-ContinuousCoReviewReviewerCandidate` picks a
  code-writer-INDEPENDENT host (claude->codex, codex->claude); codex is only the E2E's concrete host
  (live-validated iteration 002), chosen unless another code-writer-independent host is confirmed
  installed and working. No host-name literal enters the navigator's selection logic.
- **NO spec amendment expected.** This implements FR-026/030/031 (navigator) and FR-004 (blackboard)
  that iteration 005's stub explicitly deferred (see iteration-005 closeout-validation, the
  "Findings-reporting surface" residual).
- **Load-bearing fact (proven, folded in — do NOT re-litigate):** the reaped `$runDir` is
  `.specrew/review/pending/<RunId>/`; the blackboard is `.specrew/review/inline/<run-id>/` — a SEPARATE
  durable dir. The reap's `Clear-...Entry` `Remove-Item $runDir` deletes only `pending/`, never the
  blackboard. Routing findings to the blackboard is the small fix; NO reap-ordering change is needed.
- **Timeout is a real E2E risk.** The navigator default `TimeoutSec=120` is below the ~300s a real
  codex review needed in iteration 002 (a 120s rerun timed out). T082 must raise the co-review timeout
  config; T085's E2E setup must use it.
- **Out of scope (carry):** the deploy-mechanism gap (`refocus-scopes.json` not re-synced on
  `specrew update`) is a SEPARATE proposal coordinated with Proposal 198 — NOT iteration 006.
- **F-184 footprint: NONE.** All edits are in the non-protected `continuous-co-review/` scripts and
  tests; no protected hook/dispatcher/registry/refocus surface is touched. The iteration-005 dispatcher
  edits already landed; iteration 006 adds no new protected-surface edit.
