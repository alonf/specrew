# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-25
**Overall Verdict**: accepted

## Test Strategy

Iteration 001 uses focused integration regression coverage because the changed behavior is CLI entry-point routing and project-local filesystem repair. The tests exercise externally visible command behavior rather than isolated helper mocks.

## Tests Run

| Command | Result | Exit Code | Requirement Coverage | Notes |
| ------- | ------ | --------- | -------------------- | ----- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/validate-versions-cli-behavior.ps1` | pass | 0 | FR-001, FR-002, SC-001, SC-002, SC-006 | Covers `specrew version`, `--version`, `-v`, `--project-path`, Spec Kit probe fallback, and false-warning suppression. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/start-recovery-flow.tests.ps1` | pass | 0 | FR-004, FR-005, SC-003, SC-006 | Covers stale-state recovery, start auto-repair, init non-force repair, and init force repair validation. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath . -IterationPath specs/045-v0271-bugfix-bundle/iterations/001` | pass | 0 | FR-003, FR-008, SC-006 | Generated zero mechanical findings. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | pass | 0 | FR-008 | Active iteration passed; only pre-existing closed-iteration dashboard warnings remain. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Confidence: high for iteration 001 US1 surface

## Coverage-to-Requirements

| Requirement | Evidence |
| ----------- | -------- |
| FR-001 | Version alias parity assertions in `validate-versions-cli-behavior.ps1`. |
| FR-002 | False-warning suppression assertion in `validate-versions-cli-behavior.ps1`. |
| FR-003 | Finding ledger plus mechanical checks. |
| FR-004 | Start missing-root repair assertion in `start-recovery-flow.tests.ps1`. |
| FR-005 | Init force and non-force missing-root repair assertions in `start-recovery-flow.tests.ps1`. |
| FR-008 | Mirror parity evidence plus full validator pass for active iteration. |

## Residual Risk

- FR-006 and FR-007 are intentionally not covered in iteration 001 because they are deferred to iteration 002.
- The start repair failure branch remains warning-based to preserve existing non-fatal start behavior; init paths enforce final success validation.
