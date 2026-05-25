# Finding Disposition Ledger (Iteration 002)

## Scope

Tracks final closure status for the 7 post-release findings in the v0.27.1 patch bundle.

## Findings

| Finding ID | Type | Summary | Affects Requirement(s) | Target Iteration | Iteration 002 Disposition | Evidence Ref | Owner | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | actionable defect | Top-level `--version` / `-v` parity gaps | FR-001, SC-001 | 001 | Carried forward from iteration 001; final regression replay remains scheduled in T029. | `tests/integration/validate-versions-cli-behavior.ps1` | Implementer | done |
| F2 | actionable defect | False warning when version is determinable | FR-002, SC-002 | 001 | Carried forward from iteration 001; final regression replay remains scheduled in T029. | `tests/integration/validate-versions-cli-behavior.ps1` | Implementer | done |
| F3 | actionable defect | `specrew start` missing catalog auto-repair gap | FR-004, SC-003 | 001 | Carried forward from iteration 001; final regression replay remains scheduled in T029. | `tests/integration/start-recovery-flow.tests.ps1` | Implementer | done |
| F4 | actionable defect | `specrew init` gap handling exits early | FR-005, SC-003 | 001 | Carried forward from iteration 001; final regression replay remains scheduled in T029. | `tests/integration/start-recovery-flow.tests.ps1` | Implementer | done |
| F5 | actionable defect | Brownfield `.squad/agents/` canonical-source classification | FR-006, SC-004 | 002 | Implemented. Self-hosting projects with `extensions/specrew-speckit/` and existing `.squad/agents/` preserve baseline roles as canonical source; non-self-hosting projects still surface baseline-role conflicts. | `tests/integration/brownfield-conflict-handling.ps1`; `extensions/specrew-speckit/scripts/brownfield-merge.ps1`; `.specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1` | Implementer | done |
| F6 | stale review finding | Non-actionable review comment resolved as stale | FR-003 | 002 | Closed as stale. No runtime change was attached beyond the actionable F5 brownfield ownership fix; the stale item remains documented for audit rather than altering behavior. | This ledger; iteration 002 traceability matrix; T020 brownfield evidence | Reviewer | done |
| F7 | stale review finding | Documentation-only clarification tracked as stale defect | FR-003, FR-007 | 002 | Closed through operator guidance only. The stale finding did not require new runtime behavior; docs now explain update paths, force and publisher-check boundaries, and init redeploy triggers. | `docs/getting-started.md`; `docs/user-guide.md`; `quickstart.md`; `quality/update-guidance-review.md` | Doc Steward | done |

## Notes

- FR-008 governance integrity applies across all dispositions.
- Iteration 002 closes F5-F7 without reopening iteration 001 artifacts.
- Proposal 119 is effort-convention context only; no Proposal 119 implementation work is part of this ledger.
- Bounded-scope note: this feature remains a v0.27.1 bug-fix bundle. The documentation updates clarify how to apply the patch safely; they do not introduce a new update command, a new lifecycle boundary, or a new installer policy.
