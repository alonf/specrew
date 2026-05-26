# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-26
**Overall Verdict**: accepted

## Test Strategy

- Focused regression coverage for the seven trust-hardening bug-bash items.
- Verify validator outputs at the behavior boundary, not only by source inspection.
- Verify mirrored extension scripts are byte-identical where `.specify/` parity is required.
- Verify lifecycle artifacts stay internally consistent before requesting human review-signoff.

## Tests Run

| Command | Result | Notes |
| ------- | ------ | ----- |
| Modified PowerShell parse checks | pass | Parsed modified scripts and integration tests without syntax errors. |
| SHA256 mirror parity checks | pass | Verified `shared-governance.ps1`, `validate-governance.ps1`, and `scaffold-reviewer-artifacts.ps1` match across extension surfaces. |
| `.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` | pass | Wrote `quality/mechanical-findings.json`. |
| `tests/integration/non-specrew-session-bypass.tests.ps1` | pass | Covers missing handoff, post-compaction handoff drop, wrong-location artifacts, missing Mermaid WARN, internal-reference WARN, dashboard diagnosis split, empty skill roots, tasks-progress regeneration, closeout template sequence, and reviewer charter directive. |
| `tests/integration/reviewer-artifacts.ps1` | pass | Covers Mermaid fallback skeleton behavior. |
| `tests/integration/substantive-interaction-model-handoff-test.ps1` | pass | Regression coverage for handoff behavior. |
| `tests/integration/start-command.ps1` | pass | Regression coverage for start/session behavior. |
| Scoped `validate-governance.ps1` | pass | Passed for project path and iteration 001 before review artifact authoring. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Confidence: high for modified governance surfaces; broader product-wide regression coverage was not rerun.

## Coverage-to-Requirements

| Requirement | Evidence |
| ----------- | -------- |
| FR-001, FR-002, FR-003, FR-004, FR-009, FR-016 | `tests/integration/non-specrew-session-bypass.tests.ps1`; validator WARN behavior. |
| FR-005, FR-006, FR-007 | `tests/integration/non-specrew-session-bypass.tests.ps1`; `tests/integration/reviewer-artifacts.ps1`; reviewer charter/template diffs. |
| FR-008, FR-011 | Coordinator prompt/template diffs and closeout sequence assertions. |
| FR-010, FR-012 | Empty skill-root and tasks-progress regeneration assertions. |
| FR-013 | `findings.md` durable ledger with implemented statuses and evidence pointers. |
| FR-014, SC-010 | SHA256 mirror parity checks for modified extension scripts. |
| FR-015 | Version bump across manifests, README, and CHANGELOG. |
