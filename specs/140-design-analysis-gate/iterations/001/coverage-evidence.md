# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-02
**Overall Verdict**: accepted

## Tests Run

| Command | Result | Notes |
| --- | --- | --- |
| `pwsh -File tests/unit/design-analysis-gate.tests.ps1` | pass | Parses helper/sync/start surfaces; validates artifact shape, sections, alternatives, option fields, recommendation, Human Decision, commit hash, legacy compatibility, and lifecycle guidance. |
| `pwsh -File tests/integration/design-analysis-boundary.tests.ps1` | pass | Proves active substantive plan sync blocks before state advancement, passes after valid evidence, skips legacy baseline, and is scoped to the active feature. |
| `pwsh -File tests/integration/boundary-sync-atomic.tests.ps1` | pass | Confirms cursor, last-authorized boundary, and verdict history remain atomic. |
| `pwsh -File tests/integration/filelist-completeness.tests.ps1` | pass | Confirms the new helper is declared in `Specrew.psd1`. |
| `pwsh -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -FeaturePath specs/140-design-analysis-gate -IterationPath specs/140-design-analysis-gate/iterations/001` | pass | Wrote `mechanical-findings.json` with zero findings. |
| `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -NoCacheRead` | pass | Iteration 001 passed; remaining warnings are pre-existing dashboard/session-evidence warnings outside this slice. |

## Supplemental Regression Checks

| Command | Result | Notes |
| --- | --- | --- |
| `pwsh -File tests/unit/boundary-authorization-prompt-truth.tests.ps1` | pass | Ran during implementation; unaffected by final T014 deferral. |
| `pwsh -File tests/integration/lifecycle-boundary-sync.tests.ps1` | pass | Ran during implementation; confirms broader lifecycle sync behavior still works. |

## Coverage-to-Requirements

| Requirement Area | Evidence |
| --- | --- |
| Artifact creation/shape: FR-003, FR-004, FR-013, FR-014, SC-001, SC-002, SC-010 | Unit tests for valid artifact, missing artifact, and missing required sections. |
| Options and fields: FR-005, FR-006, FR-007, FR-015, SC-003, SC-004, SC-005 | Unit tests for one-option rejection, missing option field rejection, diagram evidence, and conditional By-the-book acceptance. |
| Recommendation and decision: FR-008, FR-009, FR-011, FR-016, SC-006, SC-008 | Unit tests for placeholder recommendation, missing Human Decision, missing commit hash, selected option extraction. |
| Plan-boundary enforcement: FR-001, FR-010, FR-017, SC-007 | Integration test proves missing artifact blocks before state advancement and valid artifact advances. |
| Compatibility: FR-002, FR-018, FR-021, SC-012, SC-013 | Integration tests prove legacy `0.0.0` baseline and unrelated active feature are not hard-failed. |
| Scope exclusions: FR-019, FR-020, SC-011 | Review confirmed no Unix install, shell wrapper, bootstrap, beta publish, stable publish, or release workflow files were modified. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Confidence: high for the protected T003-T012 core; moderate for future broad rollout because that surface is intentionally deferred.
