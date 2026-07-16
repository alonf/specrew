# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Design Decision**: Option B, authorized at file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/gates/design-analysis-005.md
**Reconciliation**: [iteration-003-reconciliation.md](iteration-003-reconciliation.md)
**Status**: executing
**Capacity**: 20.25/26 story_points
**Started**: 2026-07-16
**Completed**:

## Objective

Finish the approved Beta2 code-review architecture as a production system: one public campaign/run command, all five real reviewer harnesses, production process-tree control on Windows/Linux/macOS, deterministic progress and retrospective projections, truthful three-OS proof, and a one-way cutover from legacy authority. Preserve the Iteration 006 immutable authority foundation and reconcile the unfinished Iteration 003 governance work without wiring the superseded mutable lease design.

This iteration proves code review only. Generic gate/artifact target adapters remain Beta3 work under FR-065.

## Scope Summary

| Requirement | Iteration 007 obligation | Completion claim |
| --- | --- | --- |
| FR-012, FR-017 | Preserve the landed design-context containment and exact target/run identity while proving the remaining T034b campaign-path compatibility | Final compatibility residual only; no re-cherry-pick |
| FR-041–FR-043 | Carry T030–T032 unchanged: exclude machinery turns, tighten approval capture, and reproduce the exact fabrication sequence | Complete capture-integrity proof |
| FR-044 | Deliver T033 as an append-only correction/invalidation door honored by effective-state readers | Explicit disposition vehicle for `DRIFT-198-I006-001`; no quiet matcher point-fix |
| FR-045 | Gate verdict packets on authoritative campaign/run state and current exact-digest review evidence | Supersedes the unwired T019 packet-gate implementation path |
| FR-055, FR-056 | Preserve honest ordinary Stop classification and add the narrow workshop-intermediate Stop | Complete deterministic workshop exception with boundary precedence |
| FR-057, FR-058 | Preserve campaign/run and immutable allowance/claim facts through the production command/cutover | Foundation regression plus production wiring |
| FR-059 | Preserve external frozen Git targets, origin non-mutation, exact digest, and visible `snapshot-moved` relevance | Production-path proof |
| FR-060 | Finish the common process/file contract for Claude, Codex, Copilot, Cursor, and Antigravity | All five production adapters; full strict malformed-output matrix |
| FR-061 | Implement Windows Job Object, Linux cgroup, and macOS process-group runtime ports | Kill descendants, verify death/stream closure, then publish timeout |
| FR-062 | Expose advisory partial findings, visible rerun lineage, deterministic recovery, and retro evidence | Complete production behavior; no hidden retry |
| FR-063 | Add cheap preflight, stage progress/heartbeat, timing, duplicate warning, bounded prompts, and safe optional usage | Informational only; missing progress/usage cannot invalidate a result |
| FR-064 | Prove every adapter deterministically on all three OSes and run one bounded live smoke per harness across the three OSes | Unavailable or unexecuted remains unproven |
| FR-065 | Complete the Beta2 code-review adapter/runtime boundary and retain the Beta3 generic-target deferral | No gate/artifact production adapter implementation |
| SC-017, SC-018 | Preserve allowance/claim/recovery and exact isolated-target invariants after production wiring | Required non-regression proof |
| SC-019 | Five real harnesses plus Windows/Linux/macOS production support | Required completion boundary |
| SC-020 | Seeded timeout, partial evidence, complete rerun, interruption recovery, and moved target | Required end-to-end proof |
| SC-021 | Diagnostics, cost/timing, progress, and retrospective provenance | Required end-to-end proof |
| NFR-002, NFR-007 | Keep agent actions visible and pair every honesty invariant with positive/negative tests | Cross-cutting acceptance rule |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| T030 | Machinery-turn exclusion from verdict evidence (carried from Iteration 003) | FR-041, NFR-002, NFR-007 | US1 | 0.75 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/integration/** | done | Codex | 0.75 | Genuine/isMeta identical-text pair, synthetic-envelope guard, shared transcript/handover tests, and all 45 F-198 suites pass |
| T031 | Approval-tokenizer tightening, temporal ordering, and cursor-invariant guards (carried) | FR-042, NFR-007 | US1 | 0.5 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/integration/** | done | Codex | 0.5 | Leading explicit-verdict tokenizer; quote/mention/teach and bare-number rejection; human-after-packet/current-cursor fallback core; artifact teaching updated; all 45 F-198 suites pass |
| T032 | Exact fabrication-sequence regression fixtures (carried) | FR-043, NFR-007 | US1 | 0.5 | Implementer | tests/integration/verdict-capture-blocks.tests.ps1, tests/integration/** | done | Codex | 0.5 | Both July 11 packet→machinery-user-turn→no-human-reply incidents replay through the authority writer; ledger/context and pending artifact remain byte-identical; all 45 F-198 suites pass |
| T033 | Append-only ledger correction/invalidation door and effective-state readers (promoted carry) | FR-044, NFR-002, NFR-007 | US1 | 1.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, tests/** | done | Codex | 1.0 | Raw verdicts preserved; exact entry/crossing corrections appended; commit/tree-scoped pending state; every effective reader and stable packet covered; 46-suite registry green; independent T061 review pending |
| T034b | Strict design-context final campaign-path regression and live compatibility proof (carried residual) | FR-012, FR-017, FR-059, FR-060, SC-018 | US2 | 0.5 | Implementer | scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | done | Codex | 0.5 | Shared strict selector/physical containment; fail-before-port/grant/spend mixed/all-invalid matrix; bounded controller-enforced empty-context partial; exact frozen target/ref propagation; Windows + focused POSIX + 53-suite registry green; T060 retains later live-digest evidence |
| T051 | Public campaign command, one-way authority cutover, and campaign-aware verdict-packet gate | FR-045, FR-057, FR-058, FR-059, FR-062, FR-065, SC-017, SC-018, SC-020 | US1 | 1.5 | Implementer | scripts/specrew-review.ps1, scripts/internal/continuous-co-review/review-authority-cutover.ps1, scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1, scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1, tests/continuous-co-review/** | done | Codex | 1.5 | Singular public delegation; repository-derived one-way cutover; strict claim-ordered current/partial/stale/finding/timeout routes; exact human disposition; origin/digest unchanged; 47-suite registry green |
| T052 | Workshop-aware intermediate Stop with ordinary and boundary-stop non-regression | FR-055, FR-056, NFR-002, NFR-007 | US1 | 0.75 | Implementer | extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, scripts/internal/bootstrap/**, tests/integration/** | done | Codex | 0.75 | Exact feature/active-iteration/first-remaining-lens marker proof; lifecycle-boundary precedence; bounded handover context; stale/fabricated/outside-state abuse cases; skill/provider mirror parity; all 47 F-198 suites green |
| T053 | Shared production harness contract/catalog, remaining Claude hardening, and full malformed-output matrix | FR-060, FR-063, FR-064, SC-019, SC-021, NFR-007 | US2 | 1.5 | Implementer | scripts/internal/continuous-co-review/review-*-harness-port.ps1, scripts/internal/continuous-co-review/review-harness-contract.ps1, scripts/internal/continuous-co-review/review-authority-core.ps1, scripts/internal/continuous-co-review/review-result-ingestor.ps1, scripts/internal/continuous-co-review/reviewer-*.md, scripts/internal/continuous-co-review/reviewer-host-catalog.ps1, tests/continuous-co-review/** | done | Codex | 1.5 | One bounded file-primary contract/prompt and five-vector catalog; Claude reduced to a thin adapter; strict UTF-8/duplicate/prose/fence/trailing/malformed/oversize/unknown/identity matrix; stdout non-authority and one-call/no-hidden-retry proof; all 48 registry suites green |
| T054 | Codex and Copilot production harness adapters | FR-060, FR-063, FR-064, SC-019, SC-021 | US2 | 2.0 | Implementer | scripts/internal/continuous-co-review/review-codex-harness-port.ps1, scripts/internal/continuous-co-review/review-copilot-harness-port.ps1, tests/continuous-co-review/** | done | Codex | 2.0 | Thin catalog adapters preserve exact validated argument ordering, append the bounded prompt once, write only the raw candidate file, ignore stdout for authority, preflight without spend, and invoke exactly once; all 49 registry suites green |
| T055 | Cursor and Antigravity production harness adapters | FR-060, FR-063, FR-064, SC-019, SC-021 | US2 | 2.0 | Implementer | scripts/internal/continuous-co-review/review-cursor-harness-port.ps1, scripts/internal/continuous-co-review/review-antigravity-harness-port.ps1, tests/continuous-co-review/** | done | Codex | 2.0 | Local no-model help confirms Cursor `--print --trust --force` and Antigravity print-mode flags; thin adapters preserve exact order/prompt placement, file-only authority, unavailable preflight, and one invocation; all 50 registry suites green; live proof remains T060/T061 |
| T056 | Windows Job Object runtime adapter and descendant-tree termination proof | FR-061, FR-063, FR-064, SC-019, SC-020, SC-021 | US2 | 1.25 | Implementer | scripts/internal/continuous-co-review/review-windows-runtime-port.ps1, tests/continuous-co-review/** | done | Codex | 1.25 | Real Job Object preflight and descendant-tree fixtures prove clean-exit reap, timeout kill, stream closure, and terminal publication only after verified death; all 51 registry suites green |
| T057 | Linux cgroup and macOS process-group runtime adapters | FR-061, FR-063, FR-064, SC-019, SC-020, SC-021 | US2 | 2.0 | Implementer | scripts/internal/continuous-co-review/review-linux-runtime-port.ps1, scripts/internal/continuous-co-review/review-macos-runtime-port.ps1, tests/continuous-co-review/** | done | Codex | 2.0 | Pre-provider containment handshake; Linux cgroup v2 membership/atomic kill/cleanup proved under privileged WSL; unprivileged absence fails before spend; portable native process-group mechanism proved on Unix; all 52 registry suites green; macOS-specific proof remains T059 |
| T058 | Progress, heartbeat, timing/usage, duplicate warning, and retrospective evidence projection | FR-062, FR-063, SC-020, SC-021, NFR-002 | US3 | 1.5 | Implementer | scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1, scripts/internal/continuous-co-review/review-progress*.ps1, scripts/internal/continuous-co-review/review-retro*.ps1, scripts/specrew-review.ps1, tests/continuous-co-review/** | done | Codex | 1.5 | Bounded non-authoritative stages/heartbeats and wall timing; safe optional usage with honest unavailable; duplicate warning before spend; complete-valid-only counts; deterministic validated-JSON retro lineage/provenance; Windows and real WSL containment proof; all 53 registry suites green |
| T059 | Deterministic all-adapter fault suite on the Windows/Linux/macOS CI matrix | FR-060, FR-061, FR-062, FR-064, SC-017, SC-018, SC-019, SC-020, SC-021, NFR-007 | US3 | 1.5 | Implementer | .github/workflows/cross-platform-validation.yml, tests/continuous-co-review/**, specs/198-beta2-hardening/iterations/007/quality/** | done | Codex | 1.5 | GitHub Actions run `29537492190` and its check suite completed `success` at correction commit `27015b9e`; the bounded deterministic review step passed on hosted Windows, Ubuntu, and macOS, including native Job Object, cgroup-v2, and macOS process-group proof; provider spend remained zero |
| T060 | Live-smoke campaign and first four harness runs across three OSes, truthful support state, campaign cutover commit, and operator docs | FR-059, FR-060, FR-061, FR-064, FR-065, SC-018, SC-019, SC-020, SC-021, NFR-002 | US3 | 1.5 | Implementer | scripts/internal/continuous-co-review/review-authority-mode.json, scripts/internal/continuous-co-review/host-support-*.ps1, docs/**, specs/198-beta2-hardening/iterations/007/**, .specrew/review/** | in-progress | Codex | — | No-spend discovery complete at `55cf338a`: Windows is ready; Ubuntu 24.04 needs PowerShell plus bounded cgroup bootstrap; hosted macOS needs one installed CLI plus a dedicated provider credential secret. Proposed order is Cursor/Windows, Antigravity/Windows, Copilot/Linux, Codex/macOS; Claude/Windows remains T061. Zero provider slots granted or spent. |
| T061 | Fifth harness smoke as independent exact-digest review, bounded correction allowance, and signoff evidence | FR-041, FR-042, FR-043, FR-044, FR-045, FR-056, FR-057, FR-058, FR-059, FR-060, FR-061, FR-062, FR-063, FR-064, FR-065, SC-017, SC-018, SC-019, SC-020, SC-021 | US3 | 1.5 | Reviewer | scripts/internal/continuous-co-review/**, extensions/specrew-speckit/scripts/**, .specify/extensions/specrew-speckit/scripts/**, tests/**, .specrew/review/**, specs/198-beta2-hardening/iterations/007/** | planned | — | — | — |

T030–T034b retain their feature-global identifiers; task authoring moves their remaining ownership to Iteration 007 rather than cloning them. New identifiers continue after T050. The separate feature task artifact is updated only after the plan-to-tasks verdict.

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Repository-configured unit |
| Capacity per Iteration | 26 | Current project cap |
| Planned Effort | 20.25 | Includes carried governance, production delivery, verification, independent review, and expected correction |
| Overcommit Threshold | 1.0 | No overcommit allowed |
| Capacity Status | ok | 5.75 SP headroom; no cap change required |
| Iteration Bounding | scope | Five-harness/three-OS production completeness is the coherent boundary |
| Time Limit (hours) | n/a | Scope-bounded iteration |
| Defer Strategy | manual | Integrity and completeness tasks are not silently deferrable |
| Calibration Enabled | true | Retro records engineering variance and provider wall time separately |

### Estimate Reconciliation

The approved design estimated 17 SP for production completeness. Iteration 006 pulled forward 0.5 SP of Claude file-primary delivery and the exact prose-file rejection/raw-file acceptance pair. The T019 reconciliation adds back a 0.5 SP campaign-aware FR-045 packet-gate residual, so the production slice remains 17.0 SP without duplicate Claude work. T030–T032, T033, and the residual T034b add 3.25 SP, producing 20.25 SP total.

### Phase Baseline

| Phase | Estimated Effort | Included work |
| --- | ---: | --- |
| Taskable discovery/cutover inspection | 0.5 | T051 legacy/campaign call-site and packet-gate inspection |
| Carried capture, correction, and compatibility work | 3.25 | T030–T034b |
| Production command, Stop, harness, runtime, progress, and retro implementation | 12.0 | Remaining T051 plus T052–T058 |
| Deterministic integration verification | 1.5 | T059 three-OS fixture matrix |
| Live validation and truthful cutover/docs | 1.5 | T060 five provider smokes |
| Independent review | 0.75 | T061 current committed digest |
| Expected rework | 0.75 | T061 bounded corrections and deterministic re-verification |
| **Total** | **20.25** | Matches planned capacity consumption |

### Paid Provider and Wall-Time Budget

- Base budget: exactly five paid live invocations, one each for Claude, Codex, Copilot, Cursor, and Antigravity. Each slot requires a separate human authorization; this plan grants none.
- T060 runs four harnesses, commits the proved public path/support/docs and campaign mode, and T061 runs the fifth harness against that exact committed digest. The fifth smoke is also independent signoff, so the base plan does not pay for a sixth duplicate review.
- Expected wall time: about 52 minutes, extrapolating the Iteration 006 valid-result average of 10 minutes 22 seconds across five runs.
- Scheduled ceiling: 60 minutes for the five base runs, using current catalog defaults (50 minutes total) plus bounded controller overhead. A 15-minute scheduling contingency may be reserved for one possible rerun, but there are zero preauthorized rerun slots.
- Findings, invalid output, timeout, or unavailable harness stop the paid sequence and return to the human. No adapter or controller performs a hidden retry.

### Deferral Rule

The five harnesses, three production runtimes, strict ingress, timeout/death ordering, campaign cutover, capture integrity, T033 correction door, deterministic matrix, and five live smokes form the required scope and cannot be dropped to fit execution. P1 safe usage metrics may report `unavailable`; live finding-count progress may be absent where a harness offers no cheap valid checkpoint. Those absences must remain visible and must not weaken result authority. If a P0 task exceeds estimate, stop and replan.

## Iteration 003 Reconciliation Rules

The detailed disposition is in [iteration-003-reconciliation.md](iteration-003-reconciliation.md). Its binding outcomes are:

1. Do not wire T019's old per-lineage mutable lease or navigator ownership. Iteration 006 immutable claim generations and repository-only authority supersede it.
2. Re-express the still-live FR-045 packet gate through T051 and current campaign/run facts.
3. Do not add T019 automatic retention/pruning; FR-058 keeps Beta2 immutable history and forbids a new pruning subsystem.
4. Carry T030–T032 and T034b exactly as directed; T034b is only the remaining campaign/live compatibility proof because its strict-resolution code already landed.
5. Use T033 as the only Iteration 007 vehicle for `DRIFT-198-I006-001`. Until T033 is complete, fresh scoped verdict evidence—not the stale global ledger—governs this iteration.

## Architecture and Execution Order

1. T030–T033 close the capture/correction authority gaps before any new boundary or paid-review evidence can depend on them.
2. T034b verifies the landed design-context containment contract against the new campaign path; it does not reapply the Devin patch.
3. T051 makes `specrew review` delegate through the campaign application service and campaign-aware signoff gate. Cutover remains `legacy -> disabled -> campaign`; neither path may promote while mode is missing, malformed, or `disabled`.
4. T052 adds only the narrow durable-workshop exception; lifecycle boundaries continue to override it.
5. T053 freezes the production adapter template and fixture matrix. All adapters write raw JSON to the run-owned candidate path; stdout is telemetry only and is never parsed for authority.
6. T054–T055 implement the four remaining harnesses without host conditionals in core policy.
7. T056–T057 implement OS-specific containment behind one runtime port. A timeout result is written only after descendants are dead and streams are closed.
8. T058 projects informational progress and validated findings into CLI and retrospective inputs without becoming an authority source.
9. T059 proves every adapter/failure contract on Windows, Linux, and macOS. T060 then runs four serialized harness smokes across all three OSes, records support truth, and commits the proved public path/docs with authority mode `campaign`.
10. T061 runs the fifth harness through that committed campaign path and uses the same exact-digest result as independent signoff. A failure leaves the iteration/release blocked; corrections require deterministic suites plus a new explicitly authorized run.

## Cutover and Compatibility

- The checked-in mode stays `legacy` through T059. T060 may commit `campaign` only after the public path, the all-adapter deterministic matrix, and four live harnesses across all three OSes are proven. T061 immediately proves the fifth harness against that exact campaign-mode commit; failure blocks iteration/release completion.
- Transition order is `legacy -> disabled -> campaign`; missing, malformed, unsupported, or conflicting mode enables neither authority.
- Existing legacy lease/results remain read-only historical evidence and are never imported, promoted, deleted, or used to infer campaign facts.
- Rollback before campaign facts exist may restore legacy for diagnosis. Once campaign facts exist, reactivating legacy requires a separately reviewed migration decision.
- Repository code is the sole code mutation authority. Review repositories are the sole review-state mutation authority. Reviewers never edit the original repository.

## Concurrency Rationale

- One Implementer owns the delivery path; stability and authority correctness are P0, so work remains serial through T058.
- Adapter pairs are grouped by shared contract but are not planned as same-specialty parallel work. The common T053 contract lands first to prevent divergence.
- T059 exercises parallel/process contention only in fixtures. It is proof, not a plan for concurrent implementation.
- T060 live runs are serialized so allowance, cost, output, and OS provenance remain attributable. No duplicate harness invocation is allowed.

## Quality Planning

**Profile**: `quality-profile.custom-composition.v1`, bounded for the PowerShell/Markdown/YAML/JSON repository and external CLI/runtime surface.

| Quality dimension | Status | Required evidence |
| --- | --- | --- |
| Code quality and separation | required | Pure core remains host/OS-neutral; adapters depend inward through ports |
| Verification confidence | required | Paired positive/negative fixtures, full malformed matrix, and exact live evidence |
| Maintainability | required | One harness catalog, one invocation/result contract, one runtime interface, one authority-mode decision |
| Security and origin integrity | required | External worktree, Specrew suppression, environment minimization, no reviewer code mutation, no secrets/raw prompt persistence |
| Concurrency correctness | required | Existing claim/reservation single-winner suite remains green after public wiring |
| Resiliency and recovery | required | Descendant kill, verified death, partial publication, interruption reconciliation, and visible rerun lineage |
| Retry/idempotency | required | No hidden retry; every paid invocation has a new run ID and explicit human slot |
| Observability and cost | required | Cheap preflight, stage/heartbeat/timing records, truthful unavailable usage/counts, retro provenance |

Required Phase 1 gates are `dead-field`, `anti-pattern`, `test-integrity`, `stack-tooling-evidence`, and `quality-lens-review`. The before-implementation hardening gate must address the external process/security surface, three-OS failure semantics, malformed result ingress, allowance/retry control, cross-platform test evidence, and cutover rollback. Runtime-only evidence may be pending before implementation, but every concern needs a named task and fail-closed acceptance rule.

## Verification Strategy

- Preserve the Iteration 006 93-test authority suite and the full F-198 registry before adding production behavior.
- For each harness: no-spend availability/preflight; raw file-primary JSON acceptance; prose/fence/trailing-text/malformed/oversize/unknown-field/wrong-run/wrong-digest rejection; zero-findings and findings results; timeout/partial behavior; stdout non-authority.
- For each runtime: descendant process tree, timeout, grace, verified death, stream closure, launch failure, interruption, and cleanup residue. Linux proves cgroup membership/kill; macOS proves process-group isolation; Windows proves Job Object assignment/termination.
- CI runs the deterministic adapter/runtime matrix on Windows, Linux, and macOS. OS-unsupported simulations never count as production proof.
- Live proof uses five separately authorized runs, one per harness and at least one per OS. Each records harness/model, OS, run ID, target digest, timeout, duration, currentness, containment, termination, validation, and result path.
- Progress/retro tests prove that incomplete or moved findings remain useful/advisory while only a complete, valid, current, contained, terminated pass can approve.
- T033 tests prove an appended invalidation changes every effective-state reader without mutating prior ledger events; quoted/stale/fabricated approvals remain ineffective.
- T052 tests the five FR-056 cases, including lifecycle-boundary precedence and interrupted-workshop handover.

## Traceability and Truthful Completion

- Every planned task carries at least one exact FR/SC/NFR reference and every scoped requirement is covered by a task.
- FR-057/FR-058 and SC-017/SC-018 are regression obligations from Iteration 006, not work to replace the foundation.
- FR-060/FR-061/FR-064 and SC-019 are complete only after deterministic and live proof; adapter source alone is insufficient.
- A result against an earlier digest remains readable and may contain relevant findings, but it is labeled `snapshot-moved` and cannot approve the current tree.
- The exact Claude prose-file/raw-file pair delivered in Iteration 006 is referenced, not recreated. T053 covers the remaining matrix and cross-adapter conformance.
- FR-048/FR-049/SC-015 verification-plan supplier work remains a separate Beta2 release dependency; Iteration 007 does not resurrect T019's legacy injection wiring or claim whole-feature closeout.
- FR-054 remains deferred to issue #3084 and is not reopened.

## Planning Notes

- The canonical scaffold helper again parsed only undecorated headings and rejected decorated identifiers such as `FR-060 (common reviewer contract...)`. The scaffold/template was used first, then the approved exact scope was populated manually; the product spec was not weakened for the parser.
- Existing Wave-B feature artifacts are updated to reflect the approved campaign/run architecture. No new architecture option was selected during planning.
- Plan approval authorizes only task artifact decomposition. Implementation still requires the later tasks and before-implement verdicts.
