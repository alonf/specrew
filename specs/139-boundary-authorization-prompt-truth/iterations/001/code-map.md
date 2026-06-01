# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-01
**Baseline Ref**: c6898fb2ad5cc363a301d1e0335abee461270a5e
**Review Ref**: e02e89e01137cd45010128b2b8d068a32d2762f7
**Test-to-Code Signal**: focused governance regression coverage

## Primary Implementation Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `scripts/specrew-start.ps1` | Generates lifecycle prompt and start-context artifacts. | T004-T021 |
| `extensions/specrew-speckit/scripts/shared-governance.ps1` | Resolves boundary policy classes and shapes boundary enforcement state. | T004-T006 |
| `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | Mirrored deployed/shared governance helper. | T004-T006 |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | Adds narrow approved-status contradiction validation. | T025-T026 |
| `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | Mirrored validator surface. | T025-T026 |
| `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Enforces six-section packet and contextual discussion prompts in handoff fixtures. | T011-T024 |
| `.specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Mirrored handoff validator surface. | T011-T024 |
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Coordinator governance template for future generated stops. | T007-T021 |
| `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Mirrored coordinator template. | T007-T021 |

## Test and Fixture Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `tests/unit/boundary-authorization-prompt-truth.tests.ps1` | Main Feature 139 focused regression suite. | T003, T006, T010, T016, T021, T026, T028 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/missing-why-stopped.md` | Negative handoff fixture missing `Why I Stopped`. | T022 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/approve-only-without-discussion.md` | Negative handoff fixture asking only for approval. | T023 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/context-free-discussion-prompt.md` | Negative handoff fixture with context-free targeted prompt. | T024 |

## Evidence and Documentation Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md` | Automated pre-publish beta3 smoke evidence. | T027 |
| `specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md` | Implementation test and gap evidence. | T028-T029 |
| `specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md` | Drift classification, including send-back D-003. | T001-T002, T029 |
| `README.md` | Adjacent Feature 016 Post-Commit Verification Protocol repair. | D-003 |

## Public API Delta

### Added

- `Get-SpecrewBoundaryPolicyClassMap`
- `Test-ApprovedFeatureStatusVerdictEvidence`
- `Test-UsesHumanReentryPacketCandidate`
- `Get-MissingHumanReentryPacketSections`
- `Test-DiscussionPromptsCompliant`

### Removed

- None.

## Review Notes

- No package manifests changed.
- No broad lifecycle redesign, hook enforcement, full Proposal 150 implementation, or broad historical Proposal 151 migration was introduced.
- Mirrors remain identical according to Feature 139 unit tests.
