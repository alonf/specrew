# Finding Disposition Ledger (Iteration 001)

## Scope

Tracks closure status for the 7 post-release findings in the v0.27.1 patch bundle.

## Findings

| Finding ID | Type | Summary | Affects Requirement(s) | Target Iteration | Iteration 001 Disposition | Evidence Ref | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | actionable defect | Top-level `--version` / `-v` parity gaps | FR-001, SC-001 | 001 | Implement and verify parity in US1. | `tests/integration/validate-versions-cli-behavior.ps1` + `scripts/specrew.ps1` diff | Implementer | pending |
| F2 | actionable defect | False warning when version is determinable | FR-002, SC-002 | 001 | Fix warning guard conditions in US1. | `tests/integration/validate-versions-cli-behavior.ps1` + `scripts/specrew-version.ps1` diff | Implementer | pending |
| F3 | actionable defect | `specrew start` missing catalog auto-repair gap | FR-004, SC-003 | 001 | Add and verify startup auto-repair. | `tests/integration/start-recovery-flow.tests.ps1` + `scripts/specrew-start.ps1` diff | Implementer | pending |
| F4 | actionable defect | `specrew init` gap handling exits early | FR-005, SC-003 | 001 | Route force and non-force paths to deployment flow for catalog gaps. | `tests/integration/start-recovery-flow.tests.ps1` + `scripts/specrew-init.ps1` diff | Implementer | pending |
| F5 | actionable defect | Brownfield `.squad/agents/` canonical-source classification | FR-006, SC-004 | 002 | Deferred by approved iteration split; no runtime change in iteration 001. | Iteration 002 plan + brownfield regression evidence | Implementer | deferred |
| F6 | stale review finding | Non-actionable review comment resolved as stale | FR-003 | 002 | Tracked here only; closure narrative deferred with final stale-finding pass. | Iteration 002 disposition update + review artifacts | Reviewer | deferred |
| F7 | stale review finding | Documentation-only clarification tracked as stale defect | FR-003, FR-007 | 002 | Tracked here only; docs and bounded-scope note deferred to US3. | Iteration 002 docs diff + guided review evidence | Doc Steward | deferred |

## Notes

- FR-008 governance integrity applies across all dispositions.
- Iteration 001 is authorized to modify runtime behavior only for F1-F4.
- F5-F7 remain visible in this ledger so iteration 002 can close the bundle without rediscovering stale or deferred findings.
