# Finding Disposition Ledger (Iteration 001)

## Scope

Tracks closure status for the 7 post-release findings in the v0.27.1 patch bundle.

## Findings

| Finding ID | Type | Summary | Affects Requirement(s) | Disposition | Evidence Ref | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | actionable defect | Top-level `--version` / `-v` parity gaps | FR-001, SC-001 | Implement and verify parity | tests/integration + code diff | Implementer | pending |
| F2 | actionable defect | False warning when version is determinable | FR-002, SC-002 | Fix warning guard conditions | tests/integration + code diff | Implementer | pending |
| F3 | actionable defect | `specrew start` missing catalog auto-repair gap | FR-004, SC-003 | Add/verify startup auto-repair | tests/integration + code diff | Implementer | pending |
| F4 | actionable defect | `specrew init` gap handling exits early | FR-005, SC-003 | Route to deploy flow for gaps | tests/integration + code diff | Implementer | pending |
| F5 | actionable defect | Brownfield `.squad/agents/` canonical-source classification | FR-006, SC-004 | Correct ownership/conflict detection | tests/fixtures + code diff | Implementer | pending |
| F6 | stale review finding | Non-actionable review comment resolved as stale | FR-003 | Close with explicit rationale only | this file + review artifacts | Reviewer | pending |
| F7 | stale review finding | Documentation-only clarification tracked as stale defect | FR-003, FR-007 | Close without runtime behavior change | this file + docs diff | Doc Steward | pending |

## Notes

- FR-008 governance integrity applies across all dispositions.
- Update Status, Evidence Ref, and Disposition as work completes.
