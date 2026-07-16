# Iteration Plan: 006

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Design Decision**: Option B, authorized at file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/gates/design-analysis-005.md
**Status**: executing
**Capacity**: 16/26 story_points
**Started**: 2026-07-16
**Completed**:

## Objective

Replace the failed mutable process-owned lease with the authority foundation for the approved `ReviewCampaign` / one-invocation `ReviewRun` architecture. This iteration establishes pure policy, immutable JSON facts, exact target identity, validated terminal result publication, and deterministic recovery behind ports. It does not claim five-harness or three-operating-system production completeness.

## Scope Summary

| Requirement | Iteration 006 obligation | Completion claim in this slice |
| --- | --- | --- |
| FR-057 | Campaign/run ownership, pure policy, repository-only review-state mutation | Complete foundation |
| FR-058 | Immutable grants, reservations, spend, claim generations, and deterministic reconciliation | Complete foundation |
| FR-059 | External Git worktree target, pre/post HEAD, canonical reviewed-state digest, and `snapshot-moved` applicability | Complete code-target foundation |
| FR-060 | Versioned invocation/result contracts, candidate validation, identity binding, and controller publication | Common contract complete; five real harness adapters deferred to Iteration 007 |
| FR-061 | Runtime port, terminal-result classification, and timeout publication ordering | Core semantics and executable fake runtime complete; three production OS runtimes deferred to Iteration 007 |
| FR-062 | Rerun allowance, partial-result recovery, and finding-lineage policy | Core policy/reconciliation complete; retrospective projection deferred to Iteration 007 |
| FR-063 | Preflight-before-spend, per-attempt production clock, phase timing contract, and bounded progress model | Foundation complete; optional usage metrics and production heartbeat deferred to Iteration 007 |
| FR-064 | Fail-closed fixture proof and truthful support boundaries | Foundation fixture proof complete; five live harness smokes and three-OS matrix deferred to Iteration 007 |
| FR-065 | Beta2/Beta3 boundary and two-slice delivery | Iteration split enforced; no Beta3 target adapter implementation |
| SC-017 | Concurrent allowance/claim/recovery invariants | Required foundation proof |
| SC-018 | Exact isolated reviewed target and unchanged origin | Required foundation proof |
| SC-019 | Five harnesses and three platforms | Explicitly not claimed until Iteration 007 |
| SC-020 | Timeout, partial evidence, recovery, and moved-snapshot behavior | Core/fake-runtime proof now; production tree-kill proof in Iteration 007 |
| SC-021 | Diagnostic, cost, timing, and retrospective provenance | Timing/preflight foundation now; production progress and retro projection in Iteration 007 |

Partial traceability above is a delivery boundary, not a completion claim. Beta2 remains release-blocked until Iteration 007 completes the five-harness and three-platform proof.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| T041 | Legacy-authority cutover seam and foundation map | FR-057, FR-065, SC-017 | US1 | 1.0 | Implementer | scripts/internal/continuous-co-review/**, specs/198-beta2-hardening/iterations/006/** | completed | Codex | 1.0 | 28 focused tests pass; campaign mode suppresses legacy spawn/promotion |
| T042 | Versioned campaign, run, invocation, result, and finding contracts | FR-057, FR-060, FR-061, SC-020 | US1 | 1.5 | Implementer | scripts/internal/continuous-co-review/review-authority-core.ps1, tests/continuous-co-review/** | completed | Codex | 1.5 | Closed contracts were consolidated into the pure authority core; 29 pure contract/policy tests pass |
| T043 | Pure campaign allowance, reservation, spend, and rerun policy | FR-057, FR-058, FR-062, FR-063, SC-017, SC-021 | US1 | 2.0 | Implementer | scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | completed | Codex | 2.0 | Human-only allowance, released-slot reuse, visible reruns, no hidden retry |
| T044 | Pure run state, result acceptance, currentness, and finding-lineage policy | FR-057, FR-059, FR-061, FR-062, SC-018, SC-020 | US1 | 2.0 | Implementer | scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | completed | Codex | 2.0 | Exhaustive transitions and deterministic finding lineage pass |
| T045 | Immutable JSON repositories, claim generations, and reconciliation | FR-057, FR-058, FR-062, SC-017, SC-020 | US1 | 2.5 | Implementer | scripts/internal/continuous-co-review/**, .specrew/review/**, tests/continuous-co-review/** | completed | Codex | 2.5 | 9 tests include multi-process single-winner and released-slot generations |
| T046 | External Git review target, exact currentness, and thin non-code fixture | FR-059, FR-065, SC-018 | US2 | 1.5 | Implementer | scripts/internal/continuous-co-review/review-target-port.ps1, scripts/internal/continuous-co-review/reviewed-state-digest.ps1, scripts/internal/continuous-co-review/worktree-reviewer.ps1, tests/continuous-co-review/** | completed | Codex | 1.5 | Real external worktree preserves origin and exact dirty-state digest |
| T047 | Candidate result ingress, authoritative terminal publication, and Markdown projection | FR-059, FR-060, FR-061, FR-062, SC-018, SC-020 | US2 | 1.5 | Implementer | scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | completed | Codex | 1.5 | 8 strict ingress/identity/partial/moved/timeout/duration tests pass |
| T048 | Synchronous CLI orchestration with target, harness, runtime, store, and clock ports | FR-057, FR-060, FR-061, FR-063, SC-020, SC-021 | US2 | 1.5 | Implementer | scripts/specrew-review.ps1, scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | completed | Codex | 1.5 | 11 end-to-end scenarios pass, including runtime preflight, claim contention, and shared timeout-ceiling outcomes |
| T049 | Foundation integration, concurrency, crash-recovery, currentness, and quality evidence | FR-063, FR-064, FR-065, SC-017, SC-018, SC-019, SC-020, SC-021 | US3 | 1.0 | Implementer | tests/continuous-co-review/**, specs/198-beta2-hardening/iterations/006/quality/** | completed | Codex | 1.0 | 91/91 foundation tests and all 45 F-198 registry suites green; SC-019 truthfully incomplete |
| T050 | Independent foundation review and bounded correction allowance | FR-062, FR-064, SC-017, SC-018, SC-020, SC-021 | US3 | 1.5 | Reviewer | .specrew/review/**, specs/198-beta2-hardening/iterations/006/** | in-progress | Claude | — | v4 published one timing-contract note; bounded correction is green; exactly one post-commit v5 run is authorized with no hidden retry |

Task identifiers reserve the next feature sequence after deferred T040. The separate task artifact is authored only after the plan-to-tasks verdict.

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Repository-configured unit |
| Capacity per Iteration | 26 | Current project cap |
| Planned Effort | 16.0 | Includes verification, independent review, and expected correction |
| Overcommit Threshold | 1.0 | No overcommit allowed |
| Capacity Status | ok | 10 SP headroom; no cap change required |
| Iteration Bounding | scope | The authority foundation is the coherent completion boundary |
| Time Limit (hours) | n/a | Scope-bounded iteration; no time ceiling is configured |
| Defer Strategy | manual | Core authority/integrity tasks are not silently deferrable |
| Calibration Enabled | true | Retro records phase variance and review cost |

### Phase Baseline

| Phase | Estimated Effort | Included work |
| --- | ---: | --- |
| Planning and discovery | 1.0 | Cutover seam, responsibility map, and executable order in T041 |
| Implementation with paired tests | 12.5 | T042–T048 |
| Integration verification | 1.0 | T049 deterministic fixture and quality evidence suite |
| Independent review | 0.75 | T050 review against the committed current tree |
| Expected rework | 0.75 | T050 bounded corrections and re-verification |
| **Total** | **16.0** | Matches planned capacity consumption |

### Deferral Rule

The authority core, exact target identity, immutable repositories, strict result ingress, recovery, and foundation verification cannot be deferred without reopening the plan. If execution estimates grow, stop and replan rather than raise the cap or remove integrity proof. P1 production heartbeat, safe optional token/usage metrics, retrospective projection, five real harness adapters, three production runtime adapters, live smokes, and cross-OS proof remain in Iteration 007 by design.

## Architecture and Execution Order

1. T041 names one cutover seam. Legacy terminal promotion is disabled before new campaign authority can be enabled; the two paths are never authoritative together.
2. T042 freezes versioned data contracts and identity rules before storage or orchestration code depends on them.
3. T043 and T044 implement pure decisions without filesystem, process, Git, or clock access.
4. T045 implements dependency-free immutable JSON facts using unique paths and atomic `FileMode.CreateNew`; it does not add a generic lock, CAS framework, database, or event store.
5. T046 supplies the production Git target and thin non-code fixture through the same target port.
6. T047 accepts only bounded candidate JSON matching run and target identity, then publishes the sole authoritative terminal result and derived Markdown.
7. T048 composes ports synchronously with fake harness/runtime adapters and a production `SystemClock` read per attempt.
8. T049 proves concurrency, crash recovery, fail-closed invalid facts, unchanged origin, moved snapshots, and partial-result recovery.
9. T050 reviews the exact committed tree. Any correction is followed by a complete new review run within the separately authorized allowance; partial findings remain advisory evidence.

## Cutover and Compatibility

- Existing Iteration 005 lease/result artifacts are read-only historical evidence and never acquire new authority.
- The cutover is fail-closed: missing, malformed, conflicting, or unsupported new facts cannot promote a result.
- No process-owner handoff, shared result filename, or generic lock is carried forward.
- Existing public review commands may retain their surface while delegating authority decisions to the new application/core boundary.
- A rollback before new authority is enabled may restore the legacy code path for diagnosis. After new authority facts exist, rollback requires an explicit migration decision and cannot silently reactivate legacy promotion.

## Concurrency Rationale

- The work is intentionally serial through T045 because contracts, policy, and storage share authority invariants.
- T046 target work and T047 ingress work are logically separable only after T042–T045 are stable; the default remains serial because the current roster has one Implementer and stability is P0.
- T049 uses multi-process fixtures to prove concurrency behavior; this is test concurrency, not same-specialty implementation parallelism.
- No sub-agent or same-specialty expansion is planned. File ownership is kept explicit to reduce merge and semantic-conflict risk.

## Quality Planning

**Profile**: `quality-profile.custom-composition.v1`, bounded for the PowerShell/Markdown/YAML/JSON repository surface.

The generic resolver output is overridden where repository evidence is stronger. `concurrency-correctness`, `resiliency`, and `retry-idempotency-and-recovery` are required—not non-applicable—because allowance reservation, atomic claim creation, crash reconciliation, timeout recovery, and duplicate prevention are central requirements.

| Quality dimension | Status | Required evidence |
| --- | --- | --- |
| Code quality and separation of concerns | required | Pure policy tests plus port/adaptor dependency checks |
| Verification confidence and test integrity | required | Positive/negative paired tests and multi-process barriers; no pass counts inferred from prose |
| Maintainability | required | One contract/catalog truth per volatile dimension; no host/OS conditionals in core policy |
| Security and origin integrity | required | External worktree, unchanged origin, minimal environment, strict ingress, no secret/raw prompt persistence |
| Concurrency correctness | required | Single-winner claim/reservation fixtures and conflicting-fact fail-closed proof |
| Resiliency and recovery | required | Crash-window reconciliation, valid partial-result retention, mandatory complete rerun semantics |
| Retry and idempotency | required | Visible new-run retry, human allowance consumption, deterministic replay without duplicate authority |

Required Phase 1 gates are `dead-field`, `anti-pattern`, `test-integrity`, `stack-tooling-evidence`, and `quality-lens-review`. The pre-implementation hardening gate must additionally address security surface, error/failure semantics, retry/idempotency, test integrity, concurrency, and operational recovery with explicit controls. Runtime-only evidence may remain marked pending before implementation, but every concern must carry a resolved planning status and the overall gate must be `ready` before implementation authorization.

## Verification Strategy

- Pure policy fixtures cover every legal and illegal campaign/run transition.
- Barrier-synchronized multi-process fixtures prove at-most-one claim/reservation winner and fail-closed conflict recovery.
- File fixtures cover torn/invalid/unsupported JSON, interrupted reservation-before-invocation, timeout partials, duplicate run IDs, wrong target IDs, and unique publication paths.
- Git fixtures prove external worktree placement, unchanged origin HEAD/state, exact reviewed digest, `snapshot-moved`, and relevance hints without current approval.
- The thin non-code target fixture proves target neutrality only; production gate/artifact adapters remain Beta3.
- The fake harness/runtime fixtures prove the common contract and timeout ordering. Iteration 006 makes no live-harness or production-OS completeness claim.
- T050 reviews the committed current tree with Claude under authorization `workshop-198-beta2-hardening`.

## Traceability and Truthful Completion

- Every planned task traces to FR-057–FR-065 and/or SC-017–SC-021.
- FR-057/FR-058 and SC-017 are the authority foundation’s primary completion boundary.
- FR-060/FR-061/FR-064 and SC-019 remain partially delivered until Iteration 007 lands all five harness adapters, all three runtime adapters, the three-OS matrix, and five bounded live smokes.
- T029 and Beta2 release remain blocked until Iteration 007 is clean.
- FR-054 remains deferred to issue #3084 and is not reopened.

## Planning Notes

- The canonical scaffold helper could not parse decorated requirement headings such as `FR-057 (campaign/run authority model)` because it accepts only an undecorated bold identifier. The plan therefore uses the existing validated iteration-plan schema and records exact requirement traces manually; the product spec was not weakened to accommodate the helper.
- A separate requirements checklist was not necessary after eight confirmed design lenses, explicit FR-057–FR-065/SC-017–SC-021 acceptance criteria, and a passing design-analysis gate. Requirements ambiguity discovered during task decomposition reopens clarification rather than being invented in code.
- Plan approval authorizes task decomposition only. Implementation still requires the later tasks and before-implement verdicts.
