# Hardening Gate: Iteration 007

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/007`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Maintainer (human verdict) and Planner
**Reviewed At**: 2026-07-16
**Post-Implementation Verification**: in progress — T030–T034b and T051–T059 verified; hosted three-OS deterministic CI is green; T060–T061 live proof remains pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | External frozen Git worktree; original repository unchanged; Specrew suppressed in reviewer; bounded environment/prompt; raw file candidate; no secrets/raw prompt persistence; Job Object/cgroup/process-group containment; controller-only terminal publication. | `true` | Trusted-but-fallible reviewers and external CLIs must never acquire code or result authority. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Full five-adapter malformed matrix; wrong identity/version/shape fails closed; timeout publishes only after verified tree death/stream closure; invalid/missing output remains visible and non-authoritative. | `true` | Provider output and process failures cannot be converted into approval. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Human-only slot grants; preflight before spend; one run ID per invocation; no hidden retry; five slots are best-case floor; every T061 correction rerun stops for a new grant. | `true` | Review time/tokens are paid and retries alter authority history. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Paired fixtures, all-adapter matrix on three OSes, real process-tree tests, one paid smoke per harness, at least one live run per OS, unavailable remains unproven, final exact-digest signoff. | `true` | Fake adapters or source presence cannot earn Beta2 production support. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Windows Job Object, Linux cgroup, macOS process group; descendant kill/verify, stream closure, explicit privilege/unavailable errors, bounded cleanup, deterministic recovery. | `true` | A root-process timeout alone does not prove reviewer termination. | `—` |
| `capture-ledger-and-pending-verdict-integrity` | `authorization-integrity` | `addressed` | `runtime-evidence` | `recorded` | T030–T033 exclude machinery/quotes, reproduce fabrication, append exact entry/crossing corrections, bind one scoped crossing to current commit/Git tree, keep repeat phrase/marker semantics stable, and reject bare-number authorization. | `true` | Dedicated paired correction tests and all 46 F-198 suites pass; T061 still reviews the final tree independently. | `—` |
| `currentness-partial-and-retro-usefulness` | `integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Exact target digest/currentness; moved/partial findings advisory and visible; only complete valid current pass approves; retro consumes validated controller facts with provenance. | `true` | Findings may stay useful after change while approval must not. | `—` |
| `workshop-stop-scope` | `interaction-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Durable active lens/pending-question identity; narrow suppression only; fabricated phrase rejected; lifecycle boundary precedence; interrupted handover retains context. | `true` | The workshop exception must eliminate duplicate packets without opening an enforcement bypass. | `—` |
| `performance-and-observability` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Cheap preflight, shared-object target, bounded prompt, stages/heartbeat/timing, valid-checkpoint finding counts, safe optional usage, explicit unavailable metrics; stability/integrity remain P0. | `false` | Timeouts and token cost matter, but optimization cannot weaken authority or containment. | `—` |
| `scope-and-release-dependency-honesty` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Iteration 007 claims code-review adapters/runtimes only; FR-048/FR-049/SC-015 remains an explicit separate Beta2 slice and blocks T029/feature closeout. | `true` | Retro projection or old T019 text must not be misreported as the missing command-plan supplier/injection path. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | On 2026-07-16 the maintainer explicitly wrote `approved for before-implement` against task-boundary commit `d9cdd16457e322628957ea74de959a5457358852`. No stale matcher entry, stale `session_state`, option number, or numeric alias is used as evidence. | T030–T034b and T051–T061 implementation is authorized. Provider invocations remain separately gated one slot at a time. |
| `condition-b-traceability` | `met` | 16/16 tasks map to valid scoped requirements and 25/25 scoped requirements have coverage in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md. | Any later orphan/uncovered requirement reopens the gate. |
| `condition-c-fail-direction-review` | `met` | Authority, schema, currentness, timeout, containment, capture, and recovery uncertainty is explicitly non-authoritative/fail-closed. | A fail-direction change requires drift and human replan. |
| `condition-d-capacity-discipline` | `met` | 20.25/26 SP includes deterministic proof, live validation, independent review, and expected engineering rework. | Do not raise the cap or drop P0 proof silently. |
| `condition-e-live-state-safety` | `met-with-scoped-control` | The explicit tasks verdict names plan commit `9fd802b7`; stale global state, option numbers, and numeric aliases are not used. T033 appended the two real stale-use corrections while retaining raw history and current `before-implement` authority. | Every crossing requires explicit `approved for <boundary>` text against the current scoped commit/tree; T061 independently verifies final-tree behavior. |
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

## T059 Verification

- The deterministic workflow, fake-provider safety seam, strict-ingress/timeout cases, authority-store concurrency, spend allowance, target/currentness, recovery, and native runtime suites are implemented as one bounded Windows/Linux/macOS CI job.
- Local Windows and Linux evidence is green, including real Job Object and delegated cgroup-v2 containment. The full 54-suite F198 registry and packaged deploy gate are green.
- Hosted run `29536313910` ran all three OS jobs: Windows passed; macOS passed the 13-case adapter matrix before exposing two containment portability defects; Ubuntu exposed insufficient parent-only cgroup delegation. That run remains immutable failed evidence.
- Hosted run `29537492190` and check suite `79984185680` completed `success` against exact correction commit `27015b9e060e9f9696132ff3ed58631d9c538e38`. The bounded deterministic test and cleanup steps passed on hosted Windows, Ubuntu, and macOS, including the production Job Object, cgroup-v2, and macOS process-group paths. T059 is complete and T060's deterministic dependency is satisfied.
- No provider was invoked. Deterministic evidence does not promote live support.

## Notes

- `Overall Verdict: ready` records completed planning-time hardening. The separate fresh human verdict in `condition-a-human-authorization` authorizes Iteration 007 implementation but no provider invocation.
- Runtime evidence for T030–T034b and T051–T059 is verified; T060–T061 live evidence remains pending until separately authorized provider slots execute. T034b/T059 deterministic compatibility does not substitute for T060's later live current-digest evidence.
- No concern is deferred inside Iteration 007; the command-plan dependency is a separate feature-level slice, not a hidden deferral from this iteration.
