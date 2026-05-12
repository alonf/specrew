# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/013-validator-hardening/spec.md`
**Iteration Ref**: `specs/013-validator-hardening/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: ready
**Approval Ref**: —
**Reviewed By**: pending
**Reviewed At**: pending
**Post-Implementation Verification**: pending
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Reuse the existing repo-root path resolution and local-file-only validator model; do not add any network, auth, or privilege-changing behavior to approval-reuse, over-claim, or classifier logic. | `false` | Iteration 002 extends the validator with local-artifact scanning and git-status checking, neither of which introduce new trust boundaries, credential flows, or external input paths. Approval-reuse normalization is pure string matching on repository-local content. Over-claim detection is a local directory and artifact presence check. Bookkeeping classifier diffs local file content against git. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T016, T020, T024 must wrap approval-reuse, over-claim, and classifier parse failures, missing files, and unexpected conditions in structured FAIL output (file path, line number when known, category, message, remediation hint) with non-zero exit behavior; no raw PowerShell exceptions. | `false` | Iteration 001 established the structured FAIL surface; Iteration 002 extends it for the three new rules. Fixtures covering malformed approval quotes, missing evidence artifacts, git-status errors, and classifier diff parsing failures are already scoped into the iteration-2 harness and will be required before implementation is accepted. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Keep approval-reuse scanning, over-claim validation, and bookkeeping classifier read-only and stateless so repeated runs against the same tree produce the same result set without side effects. | `false` | None of the three rules perform write operations, external calls, or retry orchestration. Re-running the validator is expected to be idempotent by construction because approval-reuse normalizes quotes consistently, over-claim checks are deterministic file/directory checks, and classifier diffs are deterministic git operations. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T014-T015, T018-T019, T022-T023 must provide violating and compliant fixtures, scaffold/replay-path assertions, and user-visible evidence for approval-reuse, over-claim, and bookkeeping-classifier rules. | `false` | The iteration-2 harness is already planned to exercise compliant pass cases (no reused quotes, clean evidence, bookkeeping-only diffs) and violation cases (duplicate normalized quotes, missing review/retro, behavior-affecting diffs) by invoking the real `validate-governance.ps1` surface and asserting on emitted PASS and FAIL output. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preserve iteration 001's `validate-governance.ps1` arguments, PASS/FAIL formatting, exit-code behavior, and grandfathering expectations while adding the new approval-reuse, over-claim, and classifier rules. | `false` | The new rules are scoped to feature ordinal `013` and later, keeping pre-feature-013 iterations grandfathered and unaffected. Approval-reuse detection is optional for iterations without blanket-scope declarations. Over-claim detection only activates for closed-status iterations. Bookkeeping classifier is integrated into `specrew-start.ps1` restart guidance as additive-only validation. | — |
| `over-claim-detection-correctness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T018-T020 must prove the closeout-evidence validation rules (review presence, retrospective presence, hardening-gate post-implementation verification), the scoped dirty-tree filtering (iteration-directory only, `.squad/decisions.md` and `.squad/identity/now.md` excluded as evidence-only), and the closed-status detection without false positives on historical iterations. | `true` | Planning confirms that iteration 001 provides no over-claim checking, so this is a new-in-iteration-002 rule. Fixtures will cover missing review, missing retro, missing hardening evidence, clean vs. dirty iteration directory, repo-level changes (to prove they are excluded), and various closed-status keyword patterns. Blocking because over-claim is a critical governance trap that recurs in dogfooding. | — |
| `approval-reuse-detection-correctness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T014-T016 must prove the whitespace-normalization and markdown-emphasis-stripping rules for quote matching, the blanket-scope exemption criteria (explicit multi-iteration authorization declarations only), and the duplicate-quote detection without false positives or over-matching distinct legitimate quotes. | `true` | Planning confirms iteration 001 provides no approval-reuse checking, so this is a new-in-iteration-002 rule. Fixtures will cover identical quotes with whitespace drift, markdown-emphasis variations, distinct quotes that should not match after normalization, and explicit blanket-scope declarations that exempt specific iterations. Blocking because approval-reuse is a documented corpus trap and a common iteration lifecycle error. | — |
| `bookkeeping-classifier-accuracy` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T022-T025 must prove the `.github/copilot-instructions.md` classifier correctly distinguishes bookkeeping-only changes (timestamp updates, `## Active Technologies`, `## Recent Changes` sections) from behavior-affecting changes without false positives. The classifier must integrate into `specrew-start.ps1` restart guidance and optionally into validator additive-compatibility validation. | `true` | Planning confirms the spec exactly defines three bookkeeping-only change categories; the classifier logic must match this list precisely. Fixtures will cover timestamp-only changes, section-header-only changes, mixed bookkeeping+behavior changes, behavior-only changes, and edge cases like manual edits within bookkeeping sections. Blocking because classifier accuracy determines restart guidance correctness and user confusion about when restarts are necessary. | — |
| `corpus-graduation-completeness` | `governance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T017, T021, and T027 must mark approval-reuse, over-claim, canonical-schema, and canonical-concern rows in `.specrew/quality/known-traps.md` as validator-enforced with citations to requirements, tests, and implementation files. | `true` | Iteration 001 closed without full corpus graduation (the canonical-schema and canonical-concern rows are still in the corpus as guidance, not yet marked `validator-enforced`). Iteration 002 completes the corpus for its rules and carries the iteration 001 graduation task inside the same final authorized iteration. Blocking because incomplete corpus graduation creates stale guidance and makes trap reapplication difficult in later features. | — |
| `regression-preservation` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Implementation-start baseline capture, iteration-001 re-run, and iteration-2 post-implementation validation must show that `validate-governance.ps1 -ProjectPath .` stays green across the full historical corpus, `tests/integration/validator-hardening-iteration1.ps1` stays green on iteration 001 logic, and the full validation lane remains unbroken. | `true` | Iteration 002 extends shared helpers (`shared-governance.ps1`, `validate-governance.ps1`) that iteration 001 depends on, creating regression risk. Implementation-start baseline and post-implementation full-lane validation are required blocking evidence. The review will explicitly re-run iteration 001 tests and the repo-wide validator to prove no regression. | — |

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
- Post-implementation concern verification will be recorded upon implementation completion within iteration 002

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 002 is the final authorized iteration. Complete remaining feature scope (T014-T029) covering approval-evidence reuse detection, unsupported closeout-claim blocking, `.github/copilot-instructions.md` bookkeeping-vs-behavior classification, canonical corpus graduation, final documentation updates, and full governance-lane validation.

**Pre-Implementation Planning Summary**: Planning is complete. The five canonical concerns are present in required order with pre-implementation evaluations. Five feature-specific concerns follow (over-claim-detection-correctness blocking, approval-reuse-detection-correctness blocking, bookkeeping-classifier-accuracy blocking, corpus-graduation-completeness blocking, regression-preservation blocking). The nine-column schema is in use. Planning boundary is honest: implementation, review, retrospective, and final closeout remain future steps but within the same iteration 002 scope. All planning ambiguities have been resolved (FR-003, FR-004, FR-006 are spec-clarified; fixture scopes are explicit in T014, T018, T022; effort is 15.5/20 story_points under the existing iteration-capacity model). Task descriptions trace to exact requirements with no drift. Baseline Ref will be captured at implementation start. State.md uses canonical iteration 001 schema with no deviations.

## Sign-Off Evidence (Pending)

**Authority**: Alon Fliess  
**Reviewed By**: pending  
**Reviewed At**: pending  
**Evidence Statement**: pending — to be recorded upon approval  

---

**Hardening-Gate Planning Status**: Planning-phase artifact complete with scope consolidated into single final iteration (iteration 002). Overall Verdict: ready. Planning boundaries are honest (implementation, review, retrospective, and closeout remain future steps within iteration 002). All five canonical concerns and five feature-specific concerns documented and blocking. Sign-off and implementation authorization required before execution advances.
