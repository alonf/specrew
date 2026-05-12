# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/013-validator-hardening/spec.md`
**Iteration Ref**: `specs/013-validator-hardening/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: ready
**Approval Ref**: —
**Reviewed By**: Alon Fliess
**Reviewed At**: 2026-05-12
**Post-Implementation Verification**: ✅ implementation boundary validated; blocking and non-blocking concerns satisfied with runtime evidence
**Verified At**: 2026-05-12

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Reuse the existing repo-root path resolution and local-file-only validator model; do not add any network, auth, or privilege-changing behavior to approval-reuse, over-claim, or classifier logic. | `false` | Iteration 002 extends the validator with local-artifact scanning and git-status checking, neither of which introduce new trust boundaries, credential flows, or external input paths. Approval-reuse normalization is pure string matching on repository-local content. Over-claim detection is a local directory and artifact presence check. Bookkeeping classifier diffs local file content against git. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Approval-reuse, over-claim, and classifier failures now emit structured FAIL records with file path, line number when known, category, message, remediation hint, and non-zero exit behavior; raw PowerShell exception formatting stays suppressed. | `false` | `tests\integration\validator-hardening-iteration2.ps1` now exercises duplicate approvals, missing closeout evidence, dirty-tree failures, and classifier/start integration without leaking raw exceptions. | ✅ satisfied |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Keep approval-reuse scanning, over-claim validation, and bookkeeping classifier read-only and stateless so repeated runs against the same tree produce the same result set without side effects. | `false` | None of the three rules perform write operations, external calls, or retry orchestration. Re-running the validator is expected to be idempotent by construction because approval-reuse normalizes quotes consistently, over-claim checks are deterministic file/directory checks, and classifier diffs are deterministic git operations. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Violating and compliant approval-reuse, over-claim, classifier, and start-guidance fixtures must run through the real validator/start entrypoints with user-visible assertions. | `false` | `tests\integration\validator-hardening-iteration2.ps1` now drives real validator and `specrew-start.ps1` replay paths for duplicate approvals, blanket exemptions, closeout evidence failures, repo-level dirt exclusions, bookkeeping-only prompt updates, and behavior-triggered restart pauses. | ✅ satisfied |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Preserve iteration 001's `validate-governance.ps1` arguments, PASS/FAIL framing, exit-code behavior, and grandfathering while adding the new approval-reuse, over-claim, and classifier rules. | `false` | The implementation keeps the validator additive, scopes new checks to feature ordinal `013` and later, and leaves repo-wide `validate-governance.ps1 -ProjectPath .` green. | ✅ satisfied |
| `over-claim-detection-correctness` | `validation` | `addressed` | `runtime-evidence` | `recorded` | Closed-status iteration validation must require accepted review, retro, recorded hardening-gate verification, and clean canonical iteration artifacts while ignoring repo-level evidence-only dirt. | `true` | The iteration-2 harness now proves clean closeout PASS coverage, missing review/retro failures, pending hardening evidence failures, dirty iteration-artifact failures, and `.squad/decisions.md` dirt exclusions through the live validator surface. | ✅ satisfied |
| `approval-reuse-detection-correctness` | `validation` | `addressed` | `runtime-evidence` | `recorded` | Approval evidence must compare normalized quotes (whitespace-collapsed, markdown-emphasis-stripped), reject sibling reuse, and honor explicit blanket multi-iteration authorization scope lines only. | `true` | `shared-governance.ps1` now extracts approval evidence records from `Implementation Authorization` / `Implementation Approval` blocks, and the harness proves duplicate, blanket-scope, and distinct-quote scenarios against the real validator. | ✅ satisfied |
| `bookkeeping-classifier-accuracy` | `validation` | `addressed` | `runtime-evidence` | `recorded` | The `.github/copilot-instructions.md` helper must classify timestamp / `## Active Technologies` / `## Recent Changes` edits as bookkeeping, classify any other section change as behavior, and drive `specrew-start.ps1` pause behavior accordingly. | `true` | `Test-CopilotInstructionsChangeType.ps1` now proves timestamp-only, Active Technologies-only, Recent Changes-only, behavior-only, and mixed edits directly; `specrew-start.ps1` no-launch replay coverage confirms bookkeeping-only updates do not pause while behavior changes do. | ✅ satisfied |
| `corpus-graduation-completeness` | `governance` | `addressed` | `runtime-evidence` | `recorded` | `.specrew/quality/known-traps.md` must mark approval-reuse, over-claim, canonical-schema, and canonical-concern rows as validator-enforced with citations to FRs, implementation files, and replay-path tests. | `true` | The targeted known-traps rows now cite the implementing scripts and `tests\integration\validator-hardening-iteration2.ps1` / `validator-hardening-iteration1.ps1`, replacing advisory-only guidance with validator-enforced status. | ✅ satisfied |
| `regression-preservation` | `compatibility` | `addressed` | `runtime-evidence` | `recorded` | Iteration-001 replay coverage, Specrew start regressions, and repo-wide `validate-governance.ps1 -ProjectPath .` must remain green after the shared helper and validator extensions land. | `true` | The implementation reruns `validator-hardening-iteration1.ps1`, the Specrew start regression suite, the six-script governance lane, and repo-wide validator validation successfully on the current tree. | ✅ satisfied |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Approval-reuse detection**: FR-003, FR-005, FR-008 slice 2, FR-010 slice 2 via T014-T017
- **Over-claim detection**: FR-004, FR-005, FR-008 slice 2, FR-010 slice 2 via T018-T021
- **Bookkeeping classifier**: FR-006, FR-010 slice 2 via T022-T026
- **Iteration boundary**: T014-T029; all remaining feature scope is included in iteration 002, the final authorized iteration

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `validator-core` | `extensions/specrew-speckit/scripts/validate-governance.ps1` | Yes | T016, T020, T025 |
| `validator-shared-helpers` | `extensions/specrew-speckit/scripts/shared-governance.ps1` | Yes | T016, T020 |
| `restart-policy` | `scripts/specrew-start.ps1` | Yes | T024 |
| `classifier-helper` | `extensions/specrew-speckit/scripts/Test-CopilotInstructionsChangeType.ps1` | Yes | T024, T025 |
| `contracts` | `specs/013-validator-hardening/contracts/*.md` | Stable | Iteration 001 contracts carry forward; no new contracts required for iteration 002 |
| `integration-harness` | `tests/integration/validator-hardening-iteration2.ps1` | Yes | T015, T019, T023 |
| `iteration-2-fixtures` | `tests/integration/fixtures/013-validator-hardening/approval-reuse-*`, `overclaim-*`, `copilot-instructions-*` | Yes | T014, T018, T022 |

## Deferral Note

No deferrals. Iteration 002 is the final authorized iteration and includes all remaining feature scope:
- Approval-reuse detection core implementation and corpus graduation (T014-T017)
- Over-claim detection core implementation and corpus graduation (T018-T021)
- Bookkeeping-vs-behavior classifier core implementation (T022-T026)
- Canonical-schema and canonical-concern corpus graduation (T027)
- Final documentation updates (T028)
- Full closeout validation lane rerun (T029)
- Post-implementation concern verification is now recorded on the implementation-boundary tree; review, retrospective, and final closeout remain future lifecycle steps.

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 002 is the final authorized iteration. Complete remaining feature scope (T014-T029) covering approval-evidence reuse detection, unsupported closeout-claim blocking, `.github/copilot-instructions.md` bookkeeping-vs-behavior classification, canonical corpus graduation, final documentation updates, and full governance-lane validation.

**Pre-Implementation Planning Summary**: Planning is complete. The five canonical concerns are present in required order with pre-implementation evaluations. Five feature-specific concerns follow (over-claim-detection-correctness blocking, approval-reuse-detection-correctness blocking, bookkeeping-classifier-accuracy blocking, corpus-graduation-completeness blocking, regression-preservation blocking). The nine-column schema is in use. Planning boundary is honest: implementation is now complete on the current tree, while review, retrospective, and final closeout remain future lifecycle steps. All planning ambiguities were resolved without scope expansion, the baseline ref is captured in `state.md`, and the implementation slice now has runtime evidence for every blocking concern.

## Sign-Off Evidence

**Authority**: Alon Fliess  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-12  
**Evidence Statement**: The five canonical concerns are in canonical order, the five feature-specific concerns are blocking, and the 15.5/20 capacity math matches the repo's established S=0.5/M=1/L=2 mapping.

---

**Hardening-Gate Planning Status**: Planning-phase artifact complete with scope consolidated into single final iteration (iteration 002). Overall Verdict remains `ready`; implementation-boundary verification is now recorded on 2026-05-12 with runtime evidence for all blocking and non-blocking concerns. Review, retrospective, and closeout remain future lifecycle steps within iteration 002.
