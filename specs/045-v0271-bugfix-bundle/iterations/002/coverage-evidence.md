# Coverage Evidence: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-25
**Reviewed At**: 2026-05-25T18:12:24Z
**Overall Verdict**: accepted

## Test Strategy

Iteration 002 uses focused regression coverage for the v0.27.1 patch bundle. The review replay covers the changed brownfield classification behavior plus carried-forward version and start/init flows required by SC-006.

## Tests Run

| Command | Result | Exit Code | Requirement Coverage | Notes |
| ------- | ------ | --------- | -------------------- | ----- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/brownfield-conflict-handling.ps1` | pass | 0 | FR-006, SC-004, SC-006 | Self-hosting `.squad/agents/` reported no baseline role conflicts; non-self-hosting fixtures still reported conflicts; existing brownfield checks passed. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/validate-versions-cli-behavior.ps1` | pass | 0 | SC-001, SC-002, SC-006 | Top-level `--version` and `-v` parity remains green with no false warning noise. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/start-recovery-flow.tests.ps1` | pass | 0 | SC-003, SC-006 | Start auto-repair and init force/non-force deployable-gap behaviors remain green. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IterationPath specs/045-v0271-bugfix-bundle/iterations/002 -NoCacheRead` | pass | 0 | FR-008 | Scoped governance validation passed before review artifact authoring. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Confidence: high for the approved patch scope
- Residual Risk: no automated timer measures SC-005 in real time; the guided review artifact records a 2m05s reviewer run against the updated docs.

## Coverage-to-Requirements

| Requirement / Criterion | Test Files / Evidence |
| ----------------------- | --------------------- |
| FR-003 | `finding-disposition.md`, `CHANGELOG.md` |
| FR-006 / SC-004 | `tests/integration/brownfield-conflict-handling.ps1`; primary and mirror `brownfield-merge.ps1` |
| FR-007 / SC-005 | `quality/update-guidance-review.md`; `docs/getting-started.md`; `docs/user-guide.md`; `quickstart.md` |
| FR-008 | mirror parity, mechanical findings, scoped governance validation |
| SC-006 | `validate-versions-cli-behavior.ps1`; `start-recovery-flow.tests.ps1`; `brownfield-conflict-handling.ps1` |
