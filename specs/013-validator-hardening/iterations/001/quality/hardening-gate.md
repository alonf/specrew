# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/013-validator-hardening/spec.md`
**Iteration Ref**: `specs/013-validator-hardening/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: ready
**Approval Ref**: —
**Reviewed By**: Alon Fliess
**Reviewed At**: 2026-05-12
**Post-Implementation Verification**: pending
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Reuse the existing repo-root path resolution and local-file-only validator model; do not add any network, auth, or privilege-changing behavior. | `false` | Iteration 001 modifies only repository-local validator parsing, reporting, contracts, and fixture coverage. No new trust boundary, credential flow, or external input path is introduced beyond the existing project-root resolution already in use. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T003 must wrap parse failures, missing files, schema deviations, and unexpected conditions in structured FAIL output with file path, line number when known, category, message, remediation hint, and non-zero exit behavior. | `false` | Planning evidence: graceful structured error reporting is one of the iteration's primary delivery goals, and the approved task slice already binds malformed, missing-file, and schema-deviation handling to the shared validator foundation before any rule-specific work proceeds. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | Keep the validator read-only and stateless so repeated runs against the same tree produce the same result set without side effects. | `false` | Iteration 001 introduces no write path, no external calls, and no retry orchestration. Re-running the validator is expected to be idempotent by construction because the feature only evaluates tracked files and emits structured results. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T004 and T006-T013 must provide violating and compliant fixtures, scaffold/replay-path assertions, and reviewer-recorded evidence for both canonical-schema and canonical-concern rules. | `false` | Planning evidence: the approved iteration slice includes the harness, fixture, assertion, implementation, and reviewer-proof tasks needed to prove both new rules through deterministic replay rather than ad hoc spot checks. | — |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preserve current `validate-governance.ps1` arguments, PASS/FAIL formatting, exit-code behavior, and grandfathering expectations while adding the new rules. | `false` | Planning evidence: this slice hardens validator behavior but keeps the existing entrypoint and rollout assumptions intact, so operational resilience centers on additive behavior rather than new runtime dependencies. | — |
| `canonical-schema-rule-correctness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T006-T009 must prove the eight-field canonical header, missing-field enumeration, non-canonical-label detection, extra-narrative tolerance, and grandfathered-iteration exemptions against the actual validator surface. | `true` | Planning evidence: the triggering failure for this feature line was a validator crash on non-canonical iteration metadata, so iteration 001 explicitly binds contract alignment, fixtures, assertions, implementation, and reviewer proof to the schema rule before any closeout claim is possible. | — |
| `graceful-error-reporting-completeness` | `error-reporting` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T003 and T004 must cover malformed input, empty values, and missing files so every failure mode stays within structured FAIL output and no raw PowerShell exception reaches the user. | `true` | Planning evidence: FR-005 is central to this slice, and the planned foundation requires shared exception-wrapping helpers plus replay-path assertions that validate user-visible FAIL output rather than only internal helper behavior. | — |
| `validator-cli-surface-stability` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T001, T003, T009, and T013 must show that arguments, defaults, PASS/FAIL formatting, and exit-code expectations remain additive while the new rules land. | `false` | Planning evidence: the validator is already embedded in the governance workflow, so the approved tasks explicitly preserve the current command contract while adding only new fail-closed checks and evidence capture. | — |
| `test-coverage-via-scaffold-replay-path` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T004 and T006-T013 must route proof through `tests/integration/validator-hardening-iteration1.ps1` with assertions on actual user-visible validator output rather than runtime state only. | `true` | Planning evidence: corpus row 6 requires scaffold/replay-path proof for new validator rules, and iteration 001 already assigns that proof to the shared harness plus the rule-specific fixture and reviewer tasks. | — |
| `regression-preservation` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T001 must capture the baseline and T009/T013 must re-run `validate-governance.ps1 -ProjectPath .` to prove feature 007 handoff checks, feature 012 readable-reference detection, and existing validator behavior stay intact. | `true` | Planning evidence: iteration 001 changes the central validator surface, so baseline capture and post-implementation revalidation are built into the approved slice to prevent regressions in existing governance checks while the new rules land. | — |

## Pre-Implementation Planning Evidence

### Requirement Traceability

- **Canonical schema rule**: FR-001, FR-005, FR-008, FR-009 via T003-T009
- **Canonical concern rule**: FR-002, FR-005, FR-008, FR-009 via T003-T005 and T010-T013
- **CLI compatibility and additive behavior**: FR-010 via T001, T003, T004, T009, and T013
- **Iteration boundary**: T001-T013 only; approval reuse, over-claim detection, bookkeeping classification, and corpus graduation are deferred to iteration 002

### Stack-Ready Analysis

| Stack Surface | Path | In Scope | Evidence |
| --- | --- | --- | --- |
| `validator-core` | `extensions/specrew-speckit/scripts/validate-governance.ps1` | Yes | T003, T008, and T012 |
| `validator-shared-helpers` | `extensions/specrew-speckit/scripts/shared-governance.ps1` | Yes | T003, T008, and T012 |
| `contracts` | `specs/013-validator-hardening/contracts/*.md` | Yes | T005 keeps normative references aligned |
| `integration-harness` | `tests/integration/validator-hardening-iteration1.ps1`, `tests/integration/validator-hardening-iteration2.ps1` | Yes | T004 scaffolds shared replay assertions |
| `iteration-1-fixtures` | `tests/integration/fixtures/013-validator-hardening/state-*`, `hardening-gate-*` | Yes | T006, T010 |

## Deferral Note

- Approval-evidence reuse, over-claim enforcement, bookkeeping classification, and corpus graduation are explicitly deferred to iteration 002.
- Post-implementation concern verification is pending because implementation has not been authorized or started.

## Hardening-Gate Status

**Overall Verdict**: ready

**Scope**: Iteration 001 canonical-schema and graceful-error slice (T001-T013) covering canonical iteration metadata enforcement, canonical hardening-gate concern enforcement, structured FAIL output, and iteration-1 replay coverage.

**Post-Implementation Verification Summary**: Pending implementation, review, and closeout evidence.

## Sign-Off Evidence

**Authority**: Alon Fliess  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-12  
**Evidence Statement**: I sign off on the iteration 001 pre-implementation hardening gate at file:///C:/Dev/Specrew/specs/013-validator-hardening/iterations/001/quality/hardening-gate.md for feature 013 validator-hardening (the canonical-schema and graceful-error slice that enforces canonical iteration state.md schema, enforces canonical hardening-gate concerns first in required order, and replaces PowerShell exceptions with structured FAIL lines). The five canonical concerns are present in the required order with honest pre-implementation evaluations, the five feature-specific concerns follow (canonical-schema-rule-correctness blocking, graceful-error-reporting-completeness blocking, validator-cli-surface-stability, test-coverage-via-scaffold-replay-path blocking, regression-preservation blocking), the nine-column schema is in use, the iter-005-of-008 richer pre-sign-off convention is applied, the canonical state.md schema lesson from feature 012 iter 001 carried forward correctly (no schema deviation), the validator passes cleanly, and the Baseline Ref correctly points at the task-backlog commit 977bc79.

---

**Hardening-Gate Planning Status**: signed off on 2026-05-12; implementation authorization recorded separately in the iteration plan and state artifacts.
