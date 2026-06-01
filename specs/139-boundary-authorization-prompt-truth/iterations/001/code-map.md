# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-01
**Baseline Ref**: c6898fb2ad5cc363a301d1e0335abee461270a5e
**D-006 Implementation Review Ref**: 2b84245284f3a530609f24cd24d18f9dbbfee5ee
**Current Evidence / Feature-Closeout Ref**: 62683c15148f2d9602ed75ec4d1755a5536f1f50
**Evidence-Only Delta**: `2b842452..62683c15` changes only Feature 139 evidence artifacts. No product-code, validator, script, prompt, or test implementation files changed in that delta.
**Test-to-Code Signal**: focused governance regression coverage

## Primary Implementation Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `scripts/specrew-start.ps1` | Generates lifecycle prompt and start-context artifacts; D-006 removes contradictory markdown-link guidance and requires visible bare `file:///` URLs; D-007 removes hard-coded host/runtime orientation from the shared core; D-008 records installed `specrew_version`, `runtime_class`, and delegates Rule 53 interaction rendering to host packages; D-009 makes the running module manifest authoritative for prerelease version truth. | T004-T021, D-007, D-008, D-009 |
| `scripts/internal/coordinator-prompt-surgery.ps1` | Host-specific prompt rendering layer; injects selected-host orientation from host metadata, runtime status, installed version, lifecycle position, and host interaction metadata before host launch. | D-007, D-008 |
| `hosts/copilot/host.psd1` | Copilot host manifest; declares `Squad` as the runtime display name used only when `crew_runtime_status` is `squad-runtime`. | D-007 |
| `hosts/codex/host.psd1` | Codex host manifest; declares the `request_user_input` structured question primitive for host-rendered approval guidance. | D-008 |
| `hosts/claude/host.psd1` | Claude host manifest; declares `AskUserQuestion` for Claude-rendered approval guidance. | D-008 |
| `scripts/internal/sync-boundary-state.ps1` | Advances boundary state; D-006 validates supplied handoff text before any boundary state advancement. | D-006 |
| `extensions/specrew-speckit/scripts/shared-governance.ps1` | Resolves boundary policy classes and shapes boundary enforcement state. | T004-T006 |
| `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | Mirrored deployed/shared governance helper. | T004-T006 |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | Adds approved-status contradiction validation and validates latest stored packet evidence text through the handoff validator. | T025-T026, D-004, D-006 |
| `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | Mirrored validator surface. | T025-T026, D-004, D-006 |
| `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Enforces six-section packet, contextual discussion prompts, packet-wide bare-path failures, and D-006 markdown file-link failures. | T011-T024, D-004, D-006 |
| `.specify/extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Mirrored handoff validator surface. | T011-T024, D-004, D-006 |
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Coordinator governance template for future generated stops, including D-004/D-005 exact packet evidence guidance. | T007-T021, D-004, D-005 |
| `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Mirrored coordinator template. | T007-T021, D-004, D-005 |

## Test and Fixture Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `tests/unit/boundary-authorization-prompt-truth.tests.ps1` | Main Feature 139 focused regression suite. | T003, T006, T010, T016, T021, T026, T028 |
| `tests/integration/multi-host-launch-path.tests.ps1` | Host adapter and prompt-surgery coverage, including D-007 host-accurate orientation and D-008 version/lifecycle/interaction rendering for Codex, Claude, and Copilot/Squad. | D-007, D-008 |
| `tests/integration/start-command.ps1` | Generated start artifact coverage, including actual `.specrew/last-start-prompt.md` orientation and interaction parity with `.specrew/start-context.json`, plus D-009 stale same-base installed prerelease regression coverage. | D-007, D-008, D-009 |
| `tests/manual/copilot-squad-smoke.ps1` | Release smoke harness; scans actual generated prompt orientation for false hard-coded host/runtime claims and missing version truth. | D-007, D-008 |
| `tests/unit/validate-governance.interaction-model.tests.ps1` | Feature 016 interaction-model regression suite strengthened for packet-wide navigation enforcement. | D-003, D-004, D-006 |
| `tests/unit/fixtures/016-substantive-interaction-model/navigation/violating-boundary-handoff.md` | Navigation regression fixture using bare repository artifact paths. | D-006 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/missing-why-stopped.md` | Negative handoff fixture missing `Why I Stopped`. | T022 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/approve-only-without-discussion.md` | Negative handoff fixture asking only for approval. | T023 |
| `tests/unit/fixtures/139-boundary-authorization-prompt-truth/handoffs/context-free-discussion-prompt.md` | Negative handoff fixture with context-free targeted prompt. | T024 |

## Evidence and Documentation Surface

| Path | Role | Owning Tasks |
| ---- | ---- | ------------ |
| `specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md` | Automated pre-publish beta3 smoke evidence. | T027 |
| `specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md` | Implementation test and gap evidence. | T028-T029 |
| `specs/139-boundary-authorization-prompt-truth/iterations/001/quality/mechanical-findings.json` | Regenerated mechanical checks for current HEAD. | T028, D-006 |
| `specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md` | Drift classification, including D-003 through D-009 send-backs and release-closeout smoke failures. | T001-T002, T029, D-004, D-005, D-006, D-007, D-008, D-009 |
| `specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md` | Feature closeout acceptance and D-004/D-005/D-006 enforcement-gap record. | feature-closeout |
| `README.md` | Adjacent Feature 016 Post-Commit Verification Protocol repair. | D-003 |

## Public API Delta

### Added

- `Get-SpecrewBoundaryPolicyClassMap`
- `Test-ApprovedFeatureStatusVerdictEvidence`
- `Test-UsesHumanReentryPacketCandidate`
- `Get-MissingHumanReentryPacketSections`
- `Test-DiscussionPromptsCompliant`
- `Get-MarkdownFileLinkMatches`

### Removed

- None.

## Review Notes

- No package manifests changed.
- No broad lifecycle redesign, hook enforcement, full Proposal 150 implementation, or broad historical Proposal 151 migration was introduced.
- Mirrors remain identical according to Feature 139 unit tests.
- Branch publication completed during release closeout through PR `#1562`; D-009 release repair publication completed through PR `#1625`.
