# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-21T23:42:44Z
**Overall Verdict**: accepted

## Test Strategy

- Review-boundary execution stays requirement-bound and does not reopen the locked implementation suite.
- Accepted implementation proof comes from the committed feature-specific regression lane in `tests/integration/validate-governance-changed-only.tests.ps1` plus scoped governance validation of the review packet itself.

## Evidence Captured

| Evidence | Result | Notes |
| -------- | ------ | ----- |
| `tests/integration/validate-governance-changed-only.tests.ps1` (committed at `eeeb90e`) | accepted committed evidence | Covers explicit `-ChangedOnly`, auto-scope, `origin/HEAD` fallback, `-FullRun`, on-main behavior, no-remote fallback, detached HEAD fallback, and banner/timing expectations. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\030-validator-speedup\iterations\001` | pass | Review-boundary governance validation for the iteration-local packet. |
| Pester implementation suite rerun | not-run by directive | The human review directive explicitly locked implementation at `eeeb90e`, so review did not rerun the implementation suite. |

## Coverage Estimate

- Kind: committed_evidence
- Label: locked_regression
- Tool: PowerShell + governance validator

## Coverage-to-Requirements

| Requirement | Evidence |
| ----------- | -------- |
| FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007 | `tests/integration/validate-governance-changed-only.tests.ps1`; review of `extensions/specrew-speckit/scripts/shared-governance.ps1` and `extensions/specrew-speckit/scripts/validate-governance.ps1` in `edf4104...eeeb90e` |
| FR-008, FR-009, FR-011 | Review of mirrored coordinator/reviewer guidance plus `CHANGELOG.md` in `edf4104...eeeb90e` |
| FR-010 | `tests/integration/validate-governance-changed-only.tests.ps1` committed at `eeeb90e` |
| FR-012 | Diff review across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` plus scoped governance validation |
