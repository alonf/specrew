# Code Map: Iteration 002

**Schema**: v1
**Reviewed**: 
**Baseline Ref**: 47c699db0787f8c925f4972e4800b92d7a2137d4
**Test-to-Code Ratio**: 4:1

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .github/agents/squad.agent.md | 2 | 1 | T007 | Governance-validator maintainer |
| .squad/decisions.md | 10 | 0 | T007 | Governance-validator maintainer |
| extensions/specrew-speckit/checklists/coordinator-handoff-governance.md | 10 | 0 | T007 | Governance-validator maintainer |
| extensions/specrew-speckit/governance/validation-lane.md | 21 | 0 | T007 | Governance-validator maintainer |
| extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | 4 | 3 | T007 | Governance-validator maintainer |
| extensions/specrew-speckit/prompts/coordinator-response.md | 4 | 3 | T007 | Governance-validator maintainer |
| extensions/specrew-speckit/validators/handoff-governance-validator.ps1 | 308 | 0 | T007 | Governance-validator maintainer |
| specs/001-specrew-product/contracts/coordinator-handoff-template.md | 2 | 1 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/iterations/002/drift-log.md | 2 | 0 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/iterations/002/plan.md | 23 | 16 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/iterations/002/quality/hardening-gate.md | 22 | 22 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/iterations/002/state.md | 30 | 23 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/plan.md | 6 | 2 | T007 | Governance-validator maintainer |
| specs/007-user-facing-progress-handoff/spec.md | 12 | 1 | T008 | Test maintainer |
| specs/007-user-facing-progress-handoff/tasks.md | 4 | 1 | T007 | Governance-validator maintainer |
| tests/integration/handoff-governance-jargon-response-test.ps1 | 55 | 0 | T008 | Test maintainer |
| tests/integration/handoff-governance-plain-language-response-test.ps1 | 55 | 0 | T008 | Test maintainer |
| tests/integration/validation-contract-lane.ps1 | 2 | 0 | T008 | Test maintainer |

## Public-API Delta

### Added

- Get-NormalizedText (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Get-HandoffSections (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Get-LeadSentence (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Get-GovernanceHitCount (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasPlainLanguageParaphrase (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasExplicitProgressStatus (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasExplicitNextStep (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-MentionsBlockerOrRisk (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-PlainlyDisclosesBlockerOrRisk (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasFileUri (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasWindowsAbsolutePath (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-HasReviewCue (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Test-MissingReviewFileReference (extensions/specrew-speckit/validators/handoff-governance-validator.ps1)
- Write-Pass (tests/integration/handoff-governance-jargon-response-test.ps1)
- Write-Fail (tests/integration/handoff-governance-jargon-response-test.ps1)
- Write-Pass (tests/integration/handoff-governance-plain-language-response-test.ps1)
- Write-Fail (tests/integration/handoff-governance-plain-language-response-test.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/validators/handoff-governance-validator.ps1 (308 changed lines)