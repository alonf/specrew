# Hardening Gate: Iteration 003 (Draft)

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/008-reviewer-escalation-symmetry/spec.md`
**Iteration Ref**: `specs/008-reviewer-escalation-symmetry/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: — *(pending before-implement assignment)*
**Overall Verdict**: blocked
**Approval Ref**: —
**Reviewed By**: —
**Reviewed At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | This slice does not introduce authentication boundaries, privilege checks, trust domain crossings, or user-controlled paths. It modifies internal routing and governance logic only, so security surface analysis is not applicable for Iteration 003. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents fail-closed cap activation (default to human when cap is hit and no approved alternate exists), robust implementer chain parsing (T014 fixtures for malformed chain state), and explicit error reporting in decisions ledger and handoff messages. | `true` | Pre-implementation review confirms planning-level controls for error paths and fail-closed cap behavior. Post-implementation review must verify T015, T016 test results and actual runtime behavior when cap is activated or chain counting encounters missing or invalid state. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents idempotent cap-activation detection (T017 checks for existing active-cap state before recording new cap event), idempotent decision ledger writes (T018 uses append-once semantics), and deterministic chain counting (counting logic does not depend on execution order). | `true` | Pre-implementation review confirms planning-level idempotency reasoning. Post-implementation review must verify T015 test coverage for repeated cap detection and T018 ledger-recording behavior when called multiple times for the same event. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents deterministic integration coverage for US2 acceptance scenarios 1-3 (T015: `tests/integration/lockout-chain-cap.ps1`), closeout and replay assertions for cap visibility (T016: `tests/integration/reviewer-closeout-governance.ps1`, `tests/integration/review-command.ps1`), and fixture-based reproducibility (T014 baseline fixtures for cap-hit, alternate-owner-approved, awaiting-human-owned-revision scenarios). | `true` | Pre-implementation review confirms planning-level test coverage design. Post-implementation review must verify T015 and T016 test suite passes all US2 acceptance scenarios and T014 fixtures are committed and reusable. | — |
| `operational-resilience-concerns` | `operational` | `not-applicable` | `not-applicable` | `not-needed` | — | `true` | This slice modifies internal governance and routing logic. It does not introduce production runtime dependencies, external service calls, database transactions, or long-lived processes that require operational-resilience analysis. | — |
| `chain-counting-integrity` | `logic` | `requires-evidence` | `planning-time-analysis` | `requires-runtime-proof` | Planning documents expected control: T014 fixtures for distinct implementer chains, T015 integration tests for chain parsing and cap-activation threshold, T017 implementation in `manage-reviewer-regression.ps1` to count only distinct implementer owners and activate cap at exactly two rotations beyond original implementer. | `true` | Implementer chain counting must correctly identify distinct owners and activate the cap at exactly the configured threshold. Post-implementation review must verify actual behavior against spec acceptance scenarios 1-3 using T015 test results and T017 runtime execution evidence. | — |
| `cap-activation-routing` | `logic` | `requires-evidence` | `planning-time-analysis` | `requires-runtime-proof` | Planning documents expected control: T014 fixtures for alternate-owner-approved and awaiting-human-owned-revision scenarios, T015 integration tests for post-cap routing paths, T017 implementation in `manage-reviewer-regression.ps1` to enforce human or explicitly approved alternate owner routing. | `true` | Post-cap routing must enforce human or explicitly approved alternate owner, with no synthesis of additional specialists. Post-implementation review must verify T017 implementation and T015 test results demonstrate correct routing behavior after cap activation. | — |
| `decision-ledger-recording` | `governance` | `requires-evidence` | `planning-time-analysis` | `requires-runtime-proof` | Planning documents expected control: T018 implementation using `shared-governance.ps1` helpers to record cap-activation and alternate-owner approval events in `.squad/decisions.md` with affected feature, iteration, rationale, and approving human. | `true` | Every cap activation must record decision evidence in `.squad/decisions.md` with complete metadata. Post-implementation review must inspect actual ledger entries written by T018 implementation and verify completeness and accuracy. | — |
| `handoff-visibility` | `user-experience` | `requires-evidence` | `planning-time-analysis` | `requires-runtime-proof` | Planning documents expected control: T019 implementation in `scaffold-reviewer-artifacts.ps1`, `specrew-review.ps1`, and `.squad/routing.md` to surface locked-out agents, cap status, and planned next-owner path. | `true` | Locked-out agents, cap status, and planned next-owner path must be visible in user-facing outputs, iteration state, and decisions ledger. Post-implementation review must verify T019 implementation and inspect actual rendered handoff messages and state artifacts. | — |
| `us1-integration-correctness` | `integration` | `requires-evidence` | `planning-time-analysis` | `requires-runtime-proof` | Planning documents expected control: T014 fixtures that include active reviewer-regression state from Iteration 002 US1, T015 integration tests that verify chain counting respects the US1-established state, T017 implementation that reads the reviewed-regression-state managed block in iteration state. | `true` | Chain counting and cap implementation must correctly read and respect the active reviewer-regression state established by Iteration 002 US1 completion. Post-implementation review must verify T015 test results and T017 runtime behavior demonstrate correct integration. | — |
| `deferred-us3-dependencies` | `scope` | `addressed` | `planning-time-analysis` | `not-needed` | User Story 3 withdrawal/carry-forward/known-traps logic is deferred to Iteration 004. Planning explicitly documents this deferral in plan.md, state.md, and drift-log.md with dependency rationale (US3 requires stable US1 event logging and US2 cap enforcement). | `false` | No implementation of US3 behavior is in scope for this iteration. This concern is addressed by explicit deferral documentation and does not block US2 implementation. | — |

## Planning-Phase Notes

- This is a **draft hardening gate** prepared during the planning phase before implementation begins.
- The gate documents **expected quality concerns and planning-level control design** rather than post-implementation evidence.
- Each concern lists the planning artifacts or task descriptions that address it, but actual implementation evidence will be required during the hardening review that occurs after execution.
- The overall verdict and approval are intentionally blank until after before-implement review and after execution begins.

## Expected Post-Implementation Review

After Iteration 003 implementation completes, the hardening gate must be updated with:

1. **Test Results**: Full execution of `tests/integration/lockout-chain-cap.ps1`, `tests/integration/reviewer-closeout-governance.ps1`, and `tests/integration/review-command.ps1` with passing results for all US2 acceptance scenarios.
2. **Implementation Evidence**: Code diffs showing the chain-counting logic, cap-activation routing enforcement, and handoff visibility updates (T017, T018, T019 implementation).
3. **Governance Artifacts**: Actual `.squad/decisions.md` entries recorded during test execution, demonstrating cap-activation event records with required metadata.
4. **Runtime Behavior**: Iteration state (`state.md`) and runtime config (`squad/config.json`) populated with correct reviewer-regression state and lockout-chain status after test execution.
5. **Integration Verification**: Test results confirming that chain counting respects the US1 active reviewer-regression state and that cap implementation does not interfere with US1 routing behavior.

## Deferral Note

- **US3 Withdrawal/Carry-Forward/Known-Traps**: Explicitly deferred to Iteration 004. Any hardening concerns related to withdrawal semantics, closed-iteration carry-forward, or known-traps integration are out of scope for this iteration and will be addressed in the US3 hardening gate.

## Approval Placeholder

Once before-implement review is complete and implementation approval is granted (in plan.md Implementation Approval section), return to this gate and record:

- Reviewed By: `<reviewer-role>`
- Reviewed At: `<ISO-8601-timestamp>`
- Approval Ref: `<reference to plan.md Implementation Approval section>`
- Overall Verdict: `ready` (if all blocking concerns are addressed) or `needs-work` (with remediation plan)
