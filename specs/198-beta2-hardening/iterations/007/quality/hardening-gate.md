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
**Reviewed At**: 2026-07-18
**Post-Implementation Verification**: complete — all 16 tasks are delivered; the 57-suite registry, scoped governance, exact no-spend preflight, and hosted three-OS CI are green; T060 records truthful live evidence for four harness/OS paths; T061 run 10 supplies clean independent exact-digest signoff

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | External frozen Git worktree; original repository unchanged; Specrew suppressed in reviewer; bounded environment/prompt; raw file candidate; no secrets/raw prompt persistence; Job Object/cgroup/process-group containment; controller-only terminal publication. | `true` | Trusted-but-fallible reviewers and external CLIs never acquired code or result authority in deterministic or live evidence. | `auth-b3798462` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Full five-adapter malformed matrix; wrong identity/version/shape fails closed; timeout publishes only after verified tree death/stream closure; invalid/missing output remains visible and non-authoritative. | `true` | T060/T061 preserved invalid, partial, timeout, failure, finding, and pass outcomes without salvage. | `auth-b3798462` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | Human-only slot grants; preflight before spend; one run ID per invocation; no hidden retry; five slots are best-case floor; every T061 correction rerun stops for a new grant. | `true` | The complete T061 ledger shows ten unique attempts, eight provider invocations/spends, and no hidden retry. | `auth-b3798462` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Paired fixtures, all-adapter matrix on three OSes, real process-tree tests, one paid smoke per harness, at least one live run per OS, unavailable remains unproven, final exact-digest signoff. | `true` | All 57 registry suites, three-OS CI, T060 live paths, and clean T061 run 10 are recorded. | `auth-b3798462` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Windows Job Object, Linux cgroup, macOS process group; descendant kill/verify, stream closure, explicit privilege/unavailable errors, bounded cleanup, deterministic recovery. | `true` | Native containment and termination are proved on all three platforms; final T061 uses verified Job Object containment. | `auth-b3798462` |
| `capture-ledger-and-pending-verdict-integrity` | `authorization-integrity` | `addressed` | `runtime-evidence` | `recorded` | T030–T033 exclude machinery/quotes, reproduce fabrication, append exact entry/crossing corrections, bind one scoped crossing to current commit/Git tree, keep repeat phrase/marker semantics stable, and reject bare-number authorization. | `true` | T061 independently passed; DRIFT-198-I007-025 truthfully defers the newly observed injected-turn capture-selection defect to the later mechanism-repair slice. | `auth-b3798462` |
| `currentness-partial-and-retro-usefulness` | `integrity` | `addressed` | `runtime-evidence` | `recorded` | Exact target digest/currentness; moved/partial findings advisory and visible; only complete valid current pass approves; retro consumes validated controller facts with provenance. | `true` | Final run 10 binds the current commit/digest; all earlier outcomes remain immutable retrospective inputs. | `auth-b3798462` |
| `workshop-stop-scope` | `interaction-integrity` | `addressed` | `runtime-evidence` | `recorded` | Durable active lens/pending-question identity; narrow suppression only; fabricated phrase rejected; lifecycle boundary precedence; interrupted handover retains context. | `true` | Workshop/routine Stop behavior is implemented; the broader discussion-smoothness and capture repair remains explicit later work. | `auth-b3798462` |
| `performance-and-observability` | `performance` | `addressed` | `runtime-evidence` | `recorded` | Cheap preflight, shared-object target, bounded prompt, stages/heartbeat/timing, valid-checkpoint finding counts, safe optional usage, explicit unavailable metrics; stability/integrity remain P0. | `false` | Attempt durations, progress, failures, findings, and eight T061 spends are retained without weakening integrity. | `auth-b3798462` |
| `scope-and-release-dependency-honesty` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Iteration 007 claims code-review adapters/runtimes only; FR-048/FR-049/SC-015 remains an explicit separate Beta2 slice and blocks T029/feature closeout. | `true` | Review evidence keeps the open Beta2 dependency visible and does not claim feature closeout. | `auth-b3798462` |

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
- Runtime evidence for T030–T034b and T051–T061 is verified. T060 has live file-primary/native-containment evidence for Codex/macOS, Cursor/Windows, Antigravity/Windows, and Copilot/Linux; only the pinned clean runs approve their own snapshots, and Cursor is explicitly not claimed clean after free-credit exhaustion. The disabled barrier, campaign activation, local 57-suite registry, scoped governance, final hosted CI `29625537074`, and exact-commit preflight are green. T061 run 10 reviewed commit `fc1054b54badcfe2abded0203a1d785eeec0c59b` / digest `5fc6318a300afc654bb09d986d82c8c925506ed3` and returned complete/pass/current/valid evidence with verified containment/termination and zero findings. T034b/T059 deterministic compatibility does not substitute for live evidence.
- No implementation concern remains open inside Iteration 007. DRIFT-198-I007-025 is an explicitly deferred stop/capture-mechanism follow-up observed while recording this boundary; it does not alter the reviewed tree or provider result. The command-plan dependency is a separate feature-level slice, not a hidden deferral from this iteration.
