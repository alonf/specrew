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

| Concern | Category | Status | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- |
| `chain-counting-integrity` | `logic` | `requires-evidence` | `true` | Implementer chain counting must correctly identify distinct owners and activate the cap at exactly the configured threshold. Planning documents expected control (test fixtures T014, test coverage T015, integration test suite in `tests/integration/lockout-chain-cap.ps1`), but post-implementation review must verify actual behavior against spec acceptance scenarios 1-3. | — |
| `cap-activation-routing` | `logic` | `requires-evidence` | `true` | Post-cap routing must enforce human or explicitly approved alternate owner, with no synthesis of additional specialists. Planning documents expected control and test coverage, but execution evidence from T017 implementation and test results must be reviewed before closure. | — |
| `decision-ledger-recording` | `governance` | `requires-evidence` | `true` | Every cap activation must record decision evidence in `.squad/decisions.md` with affected feature, iteration, rationale, and approving human. Planning documents the interface (T018 task, `shared-governance.ps1` helpers), but actual post-implementation ledger entries must be inspected for completeness and accuracy. | — |
| `handoff-visibility` | `user-experience` | `requires-evidence` | `true` | Locked-out agents, cap status, and planned next-owner path must be visible in user-facing outputs, iteration state, and decisions ledger. Planning documents the surfaces (T019 task, `scaffold-reviewer-artifacts.ps1`, `specrew-review.ps1`, `.squad/routing.md`), but actual rendered output and state artifacts must be reviewed post-implementation. | — |
| `us1-integration-correctness` | `integration` | `requires-evidence` | `true` | Chain counting and cap implementation must correctly read and respect the active reviewer-regression state established by Iteration 002 US1 completion. Planning documents the dependency and state contract (reviewed-regression-state managed block in iteration state), but execution evidence of correct integration must be demonstrated in test results and runtime behavior. | — |
| `deferred-us3-dependencies` | `scope` | `addressed` | `false` | User Story 3 withdrawal/carry-forward/known-traps logic is deferred to Iteration 004. Planning explicitly documents this deferral and the dependency rationale (US3 requires stable US1 event logging and US2 cap enforcement). No implementation of US3 behavior is in scope for this iteration. | — |

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
