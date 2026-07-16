# Hardening Gate: Iteration 006

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/006`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Maintainer (human verdict) and Planner
**Reviewed At**: 2026-07-16
**Post-Implementation Verification**: T049 foundation evidence recorded; T050 independent review pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | External disposable Git worktree; origin HEAD/state pre/post verification; Specrew disabled in reviewer workspace; bounded conformance-backed environment; no raw environment, prompt, credential, or default raw-output persistence; strict candidate schema and run/target identity; repository-only review-state mutation; uncertainty is never permission. | `true` | The reviewer is trusted but fallible. Stability is prioritized while origin integrity, secret minimization, and authority proof remain fail-closed. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Missing/malformed/unsupported/conflicting facts, invalid candidate JSON, wrong run/target identity, containment violation, timeout, incomplete result, and reconciliation ambiguity each produce an explicit non-authoritative terminal/failure classification. Timeout publication occurs only after full-tree termination is verified and streams close. | `true` | The failed design promoted missing helpers and parseable substitutes. The replacement must make every uncertainty loud and unable to approve. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Every retry is a visible new ReviewRun; human grants/reservations/spend are immutable; pre-invocation failure may release a reservation; post-invocation failure consumes a slot; valid partial findings remain advisory; a complete rerun is mandatory for approval; reconciliation is deterministic and idempotent. | `true` | Hidden retries waste time/tokens and erase authority history. Unique immutable facts preserve every attempt and make replay deterministic. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Positive/negative paired tests, exhaustive pure transition tables, barrier-synchronized multi-process fixtures, exact Git-origin/currentness fixtures, candidate-ingress abuse fixtures, and digest-bound command evidence. No pass counts are inferred from console prose and fake fixtures cannot earn live support claims. | `true` | The foundation must falsify authority, concurrency, currentness, recovery, and schema invariants before real adapters are trusted. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Dependency-free immutable JSON facts; atomic `FileMode.CreateNew`; run-owned claim generations; no generic lock/CAS/database/event store; deterministic crash-window reconciliation; bounded cleanup; synchronous orchestration; directly observed per-attempt timing; actionable progress/failure categories. | `true` | Review invocations consume real runtime and tokens. The controller must recover honestly without adding services or fragile mutable coordination. | `—` |
| `concurrency-authority` | `concurrency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Single-winner reservation and claim creation; immutable held/released/abandoned generations; conflicting facts fail closed; no process-owner handoff; multi-process barriers prove winners and crash recovery. | `true` | The former lease failed because read/validate/write transitions were inconsistently atomic. Concurrency correctness is a central P0 requirement, not non-applicable. | `—` |
| `result-currentness-and-ingress` | `integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Pre/post HEAD plus canonical reviewed-state digest; `snapshot-moved` classification; bounded candidate JSON; exact run/target binding; controller-only authoritative publication; partial/stale/moved evidence cannot approve current code. | `true` | Useful findings may outlive their snapshot, but result authority must never do so. | `—` |
| `performance-and-spend` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preflight before spend; shared-object worktrees; bounded prompts; minimal required hashing; per-phase timing; low-cost progress contract; duplicate warning; optional usage metrics only when safely available; stability/integrity remain higher priority. | `false` | Timeout and token costs matter, but optimizations cannot weaken currentness, termination, schema, or allowance proof. | `—` |
| `scope-and-proof-honesty` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 006 claims only the foundation and fake-runtime proof. T049 must assert SC-019 remains incomplete. Five real harnesses, three production OS runtimes, five live smokes, three-OS matrix, progress/retro projection, and legacy cutover completion stay Iteration 007. | `true` | A partial foundation must not recreate the earlier overbroad `verified` support claims. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The maintainer selected option 1 on 2026-07-16: **approved for before-implement**, against task-boundary commit `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`. The stale Iteration 003 matcher entry is not used as evidence. | Iteration 006 T041–T050 implementation is authorized; Iteration 007 and scope expansion are not. |
| `condition-b-traceability` | `met` | T041–T050 map to FR-057–FR-065 and SC-017–SC-021 in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md; the after-tasks check must confirm both directions. | Any orphan or uncovered requirement blocks implementation readiness. |
| `condition-c-fail-direction-review` | `met` | Every authority, schema, currentness, timeout, containment, and recovery uncertainty is specified as non-authoritative/fail-closed in the plan and tasks. | A fail-direction change reopens design and is recorded in the drift log before code proceeds. |
| `condition-d-capacity-discipline` | `met` | 16/26 story_points including 1.0 verification and 1.5 independent-review/rework capacity. Core integrity work has no silent defer candidate. | A spill triggers a human replan; do not raise the cap or drop proof. |
| `condition-e-live-state-safety` | `met` | The stale cross-iteration authorization match is recorded as DRIFT-198-I006-001. The ledger was not hand-edited; task fixtures must use isolated project roots. | Do not use this live session state as a test fixture or as implementation authorization. |

## Required Evidence at Review

- Pure campaign/run/acceptance/lineage transition results.
- Barrier-synchronized reservation/claim/reconciliation results.
- Git target isolation, unchanged-origin, digest/currentness, and non-code-fixture results.
- Candidate-ingress and single-authoritative-publication abuse results.
- End-to-end fake harness/runtime success, timeout, crash, partial, rerun, and moved-target results.
- Exact committed-tree quality commands and digest-bound evidence.
- Independent Claude result bound to the current committed tree.

## Notes

- `Overall Verdict: ready` records completed planning-time hardening analysis. The separate fresh human verdict in `condition-a-human-authorization` now authorizes Iteration 006 implementation.
- T049 runtime evidence is recorded in `quality/foundation-evidence.md`; the concern rows remain `pending-post-implementation` until independent T050 evidence exists.
- The generic quality resolver's non-applicable concurrency/recovery inference is overridden by the explicit campaign allowance, atomic claim, timeout, and crash-reconciliation requirements.
- No concern is deferred and no new dependency is approved.
