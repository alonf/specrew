# Hardening Gate: Iteration 007

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/007`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-16
**Post-Implementation Verification**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | External frozen Git worktree; original repository unchanged; Specrew suppressed in reviewer; bounded environment/prompt; raw file candidate; no secrets/raw prompt persistence; Job Object/cgroup/process-group containment; controller-only terminal publication. | `true` | Trusted-but-fallible reviewers and external CLIs must never acquire code or result authority. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Full five-adapter malformed matrix; wrong identity/version/shape fails closed; timeout publishes only after verified tree death/stream closure; invalid/missing output remains visible and non-authoritative. | `true` | Provider output and process failures cannot be converted into approval. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Human-only slot grants; preflight before spend; one run ID per invocation; no hidden retry; five slots are best-case floor; every T061 correction rerun stops for a new grant. | `true` | Review time/tokens are paid and retries alter authority history. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Paired fixtures, all-adapter matrix on three OSes, real process-tree tests, one paid smoke per harness, at least one live run per OS, unavailable remains unproven, final exact-digest signoff. | `true` | Fake adapters or source presence cannot earn Beta2 production support. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Windows Job Object, Linux cgroup, macOS process group; descendant kill/verify, stream closure, explicit privilege/unavailable errors, bounded cleanup, deterministic recovery. | `true` | A root-process timeout alone does not prove reviewer termination. | `—` |
| `capture-ledger-and-pending-verdict-integrity` | `authorization-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T030–T033 exclude machinery/quotes, reproduce fabrication, append invalidations, bind one scoped crossing to current commit/artifacts, keep repeat option semantics stable, and reject bare-number authorization. | `true` | Stale `session_state`, divergent packets, and numeric aliases already produced unsafe authority narratives. | `—` |
| `currentness-partial-and-retro-usefulness` | `integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Exact target digest/currentness; moved/partial findings advisory and visible; only complete valid current pass approves; retro consumes validated controller facts with provenance. | `true` | Findings may stay useful after change while approval must not. | `—` |
| `workshop-stop-scope` | `interaction-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Durable active lens/pending-question identity; narrow suppression only; fabricated phrase rejected; lifecycle boundary precedence; interrupted handover retains context. | `true` | The workshop exception must eliminate duplicate packets without opening an enforcement bypass. | `—` |
| `performance-and-observability` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Cheap preflight, shared-object target, bounded prompt, stages/heartbeat/timing, valid-checkpoint finding counts, safe optional usage, explicit unavailable metrics; stability/integrity remain P0. | `false` | Timeouts and token cost matter, but optimization cannot weaken authority or containment. | `—` |
| `scope-and-release-dependency-honesty` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 007 claims code-review adapters/runtimes only; FR-048/FR-049/SC-015 remains an explicit separate Beta2 slice and blocks T029/feature closeout. | `true` | Retro projection or old T019 text must not be misreported as the missing command-plan supplier/injection path. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `open-for-verdict` | The tasks verdict authorizes artifacts only. No fresh `approved for before-implement` verdict exists for commit produced by this boundary. | Do not modify production code or spend provider slots. |
| `condition-b-traceability` | `met` | 16/16 tasks map to valid scoped requirements and 25/25 scoped requirements have coverage in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md. | Any later orphan/uncovered requirement reopens the gate. |
| `condition-c-fail-direction-review` | `met` | Authority, schema, currentness, timeout, containment, capture, and recovery uncertainty is explicitly non-authoritative/fail-closed. | A fail-direction change requires drift and human replan. |
| `condition-d-capacity-discipline` | `met` | 20.25/26 SP includes deterministic proof, live validation, independent review, and expected engineering rework. | Do not raise the cap or drop P0 proof silently. |
| `condition-e-live-state-safety` | `met-with-scoped-control` | The explicit tasks verdict names plan commit `9fd802b7`; stale global state, option numbers, and numeric aliases are not used. T033 owns the permanent correction door. | Until T033 passes, every crossing requires explicit `approved for <boundary>` text against the current commit. |
| `condition-f-provider-authority` | `met` | Five slots are a best-case planning floor and zero invocations are granted by task/implementation approval. | Ask separately before every base or correction invocation. |
| `condition-g-release-dependency` | `met` | FR-048/FR-049/SC-015 is recorded outside Iteration 007 in tasks/state/hardening. | T029 and feature closeout remain blocked until a separate slice closes it. |

## Required Evidence at Review

- T030–T033 paired capture, stale-state, divergent-packet, numeric-alias, and append-only invalidation evidence.
- T034b strict design-context/physical-containment proof through production campaign adapters.
- Public campaign cutover and exact-digest signoff-gate matrix.
- Five-adapter malformed-output, preflight, no-hidden-retry, and safe prompt/environment results.
- Windows Job Object, Linux cgroup, and macOS process-group descendant termination results.
- Progress/heartbeat/timing/usage/retro provenance and non-authority proof.
- Three-OS CI matrix plus five separately authorized live harness results.
- Final T061 complete valid current zero-blocking exact-digest result or an explicit blocked outcome.
- Proof that FR-048/FR-049/SC-015 remains open and was not claimed by closeout artifacts.

## Notes

- `Overall Verdict: ready` means planning-time hardening is complete and ready for the human before-implement decision. It does not authorize implementation or a provider invocation.
- Runtime evidence remains pending until the owning tasks execute.
- No concern is deferred inside Iteration 007; the command-plan dependency is a separate feature-level slice, not a hidden deferral from this iteration.
