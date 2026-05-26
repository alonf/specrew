# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-26
**Baseline Ref**: 386c865e75ad136b72708e5c76d16574dc9a7f93
**Test-to-Code Ratio**: 3:9

## Review Evidence Check

- Implementation and boundary-state commits are present in git history.
- The 41-file diff is expected for this iteration because it includes mirrored extension scripts, host/runtime templates, Specrew lifecycle artifacts, review packet artifacts, and focused integration tests.
- No uncommitted implementation work was required to interpret this code map.

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/extension.yml | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 29 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 | 33 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | 262 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specrew/config.yml | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specrew/last-start-prompt.md | 324 | 14 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specrew/last-validator-summary.json | 2 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .specrew/start-context.json | 37 | 30 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .squad/agents/reviewer/charter.md | 1 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .squad/config.json | 19 | 6 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .squad/decisions.md | 280 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| .squad/identity/now.md | 7 | 7 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| CHANGELOG.md | 6 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| README.md | 3 | 3 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| Specrew.psd1 | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/extension.yml | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | 5 | 3 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/prompts/coordinator-response.md | 6 | 5 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 29 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 33 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 262 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md | 1 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| scripts/internal/skill-catalog-state.ps1 | 13 | 4 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| scripts/internal/task-progress.ps1 | 110 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| scripts/specrew-start.ps1 | 3 | 2 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/contracts/mechanical-findings.schema.json | 77 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/contracts/trust-hardening.md | 9 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/data-model.md | 14 | 4 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/findings.md | 24 | 17 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/drift-log.md | 45 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/plan.md | 111 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/quality/hardening-gate.md | 40 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/quality/mechanical-findings.json | 11 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/state.md | 36 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/iterations/001/tasks-progress.yml | 119 | 0 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/plan.md | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/quickstart.md | 1 | 1 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| specs/047-bug-bash-trust-hardening/spec.md | 3 | 3 | T002, T004, T005, T006, T007, T013, T018, T019 | Implementer |
| specs/047-bug-bash-trust-hardening/tasks.md | 19 | 19 | T001, T002, T003, T004, T008, T010, T011, T012, T015, T016, T017 | Implementer |
| tests/integration/non-specrew-session-bypass.tests.ps1 | 319 | 0 | T002, T004, T005, T006, T007, T013, T018, T019 | Implementer |
| tests/integration/reviewer-artifacts.ps1 | 2 | 0 | T002, T004, T005, T006, T007, T013, T018, T019 | Implementer |

## Public-API Delta

### Added

- Test-SpecrewHandoffBlockPresent (.specify/extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-TrustHardeningWarning (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ObjectPropertyBool (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-SpecrewHandoffBlocks (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-HandoffEvidenceGovernance (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-WrongLocationCanonicalArtifacts (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-HandoffInternalReferenceSurfaces (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewDiagramsMermaidBlock (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-MissingDashboardDiagnosis (.specify/extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-SpecrewHandoffBlockPresent (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Write-TrustHardeningWarning (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ObjectPropertyBool (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-SpecrewHandoffBlocks (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-HandoffEvidenceGovernance (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-WrongLocationCanonicalArtifacts (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-HandoffInternalReferenceSurfaces (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-ReviewDiagramsMermaidBlock (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-MissingDashboardDiagnosis (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-FeatureTasksPath (scripts/internal/task-progress.ps1)
- Get-IterationStatePath (scripts/internal/task-progress.ps1)
- Get-TaskProgressDerivedStatusHints (scripts/internal/task-progress.ps1)
- Write-Pass (tests/integration/non-specrew-session-bypass.tests.ps1)
- Write-Fail (tests/integration/non-specrew-session-bypass.tests.ps1)
- Assert-Match (tests/integration/non-specrew-session-bypass.tests.ps1)
- Assert-NotMatch (tests/integration/non-specrew-session-bypass.tests.ps1)
- Get-SpecrewFeatureRecords (tests/integration/non-specrew-session-bypass.tests.ps1)
- Read-SpecrewRoadmapDefinition (tests/integration/non-specrew-session-bypass.tests.ps1)
- Get-SpecrewRoadmapProgress (tests/integration/non-specrew-session-bypass.tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 (264 changed lines)
- .specrew/last-start-prompt.md (338 changed lines)
- .squad/decisions.md (280 changed lines)
- extensions/specrew-speckit/scripts/validate-governance.ps1 (264 changed lines)
- tests/integration/non-specrew-session-bypass.tests.ps1 (319 changed lines)
