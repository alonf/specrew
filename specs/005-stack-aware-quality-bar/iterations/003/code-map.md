# Code Map: Iteration 003

**Schema**: v1
**Reviewed**: 2026-05-08
**Baseline Ref**: 64a521fc335a0d013e29d0167dfc5c553230d32a
**Test-to-Code Ratio**: 37:7

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .claude/settings.local.json | 10 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| .specify/templates/plan-template.md | 37 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .specrew/config.yml | 11 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| .specrew/iteration-config.yml | 3 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/agents/implementer/history.md | 8 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/agents/planner/history.md | 2 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/agents/reviewer/history.md | 7 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/agents/spec-steward/history.md | 13 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/decisions/inbox/implementer-t001-start.md | 15 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/downstream-default-sync/SKILL.md | 32 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/hardening-gate-fixtures/SKILL.md | 26 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/iteration-governance-readiness-review/SKILL.md | 2 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/iteration-readiness-repair/SKILL.md | 2 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/phase-bounded-plan-surface/SKILL.md | 25 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/phase-gate-boundary-sync/SKILL.md | 27 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/phase2-approval-helper-validation/SKILL.md | 19 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| .squad/skills/quality-scaffold-sync/SKILL.md | 19 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-implement.md | 11 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/commands/speckit.specrew-speckit.before-plan.md | 9 | 5 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 | 288 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/run-hardening-gate.ps1 | 597 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-governance.ps1 | 3 | 1 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1 | 125 | 15 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 | 159 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/shared-governance.ps1 | 341 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/scripts/validate-governance.ps1 | 258 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md | 6 | 3 | T001, T002, T005, T008, T012, T013 | Implementer |
| extensions/specrew-speckit/templates/iteration-config.yml | 20 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/current-architecture.md | 6 | 6 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/code-map.md | 159 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/coverage-evidence.md | 42 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/dependency-report.md | 24 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/drift-log.md | 33 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/plan.md | 179 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/quality/hardening-gate.md | 27 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/quality/mechanical-findings.json | 11 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/quality/quality-evidence.md | 17 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/quality/trap-reapplication.md | 15 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/review-diagrams.md | 21 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/review.md | 33 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/reviewer-index.md | 56 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/iterations/003/state.md | 50 | 0 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/plan.md | 15 | 4 | T001, T002, T005, T008, T012, T013 | Implementer |
| specs/005-stack-aware-quality-bar/tasks.md | 22 | 11 | T001, T002, T005, T008, T012, T013 | Implementer |
| tests/integration/bootstrap-to-iteration.ps1 | 32 | 1 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/bug-hunter-lens-execution/.gitkeep | 1 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/hardening-gate-contract/.gitkeep | 1 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/hardening-gate-contract/approved-deferral/.squad/decisions.md | 14 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/hardening-gate-contract/approved-deferral/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md | 22 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/hardening-gate-contract/blocked/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md | 22 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/hardening-gate-contract/ready/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md | 22 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/known-traps-corpus/.gitkeep | 1 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/complete-evidence/project/.specrew/config.yml | 5 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/complete-evidence/project/.specrew/iteration-config.yml | 16 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.specrew/config.yml | 10 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.specrew/iteration-config.yml | 23 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.squad/decisions.md | 14 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/.squad/team.md | 11 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/plan.md | 118 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md | 27 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/mechanical-findings.json | 4 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md | 17 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/iterations/001/state.md | 13 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-approved/project/specs/005-quality-evidence/spec.md | 11 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/.specrew/config.yml | 10 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/.specrew/iteration-config.yml | 23 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/.squad/team.md | 11 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/plan.md | 118 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/hardening-gate.md | 27 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/mechanical-findings.json | 4 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/quality/quality-evidence.md | 17 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/iterations/001/state.md | 13 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/hardening-gate-blocked/project/specs/005-quality-evidence/spec.md | 11 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/missing-evidence/project/.specrew/config.yml | 5 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/quality-evidence-governance/missing-evidence/project/.specrew/iteration-config.yml | 16 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/fixtures/strongest-class-routing/.gitkeep | 1 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/gap-governance.ps1 | 51 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/hardening-gate-contract.ps1 | 327 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/quality-evidence-governance.ps1 | 34 | 0 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/quality-profile-foundation.ps1 | 69 | 1 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |
| tests/integration/reviewer-artifacts.ps1 | 25 | 1 | T003, T004, T005, T006, T009, T010, T011, T014 | Reviewer |

## Public-API Delta

### Added

- New-HardeningFocusArea (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- New-LensActivationPlanEntry (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- New-RoutingPolicyEntry (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Convert-ToRepoMarkdownPath (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-QualityPlanningDefaults (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-PhaseTwoArtifactRefs (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-PhaseTwoHardeningFocusAreas (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-LensIdFromRef (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-PhaseTwoLensActivationPlan (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-PhaseTwoRoutingPolicy (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Get-PhaseTwoLaterDeferrals (extensions/specrew-speckit/scripts/resolve-quality-profile.ps1)
- Convert-ToRepoRelativePath (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Resolve-HardeningContext (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-HardeningConcernDefinitions (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-MarkdownSectionLines (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Escape-MarkdownTableCell (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-CanonicalMarkdownToken (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Merge-HardeningConcernRows (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-HardeningVerdict (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-GateApprovalReference (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-HardeningNotes (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Get-HardeningGateContent (extensions/specrew-speckit/scripts/run-hardening-gate.ps1)
- Test-PhaseTwoQualityArtifactScaffold (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-HardeningGateContent (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Get-TrapReapplicationContent (extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1)
- Write-MissingScaffoldFile (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Ensure-Directory (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Test-PhaseTwoQualityArtifactScaffold (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-HardeningGateContent (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-TrapReapplicationContent (extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1)
- Get-MarkdownContent (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-MarkdownMetadataValue (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-MarkdownSectionTable (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Normalize-MarkdownCell (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-IsNullish (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Convert-ToDecisionReferenceId (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-ApprovalReferenceRecord (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-ApprovalReferenceHasHumanApproval (extensions/specrew-speckit/scripts/shared-governance.ps1)
- ConvertTo-BooleanMarkdownValue (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Test-HardeningConcernBlocksImplementation (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-HardeningGateState (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Get-RoutingEvidenceRecords (extensions/specrew-speckit/scripts/shared-governance.ps1)
- Convert-ToRepoMarkdownPath (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Resolve-RepoMarkdownArtifactPath (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-ObjectPropertyString (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-Phase2HardeningPlanContext (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Get-HardeningExpectedVerdict (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Test-Phase2HardeningGate (extensions/specrew-speckit/scripts/validate-governance.ps1)
- Write-Pass (tests/integration/hardening-gate-contract.ps1)
- Write-Fail (tests/integration/hardening-gate-contract.ps1)
- Assert-True (tests/integration/hardening-gate-contract.ps1)
- Assert-Equal (tests/integration/hardening-gate-contract.ps1)
- Assert-Contains (tests/integration/hardening-gate-contract.ps1)
- Assert-StringNotNullish (tests/integration/hardening-gate-contract.ps1)
- Assert-ConcernStatus (tests/integration/hardening-gate-contract.ps1)
- Assert-Condition (tests/integration/quality-profile-foundation.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- extensions/specrew-speckit/scripts/resolve-quality-profile.ps1 (288 changed lines)
- extensions/specrew-speckit/scripts/run-hardening-gate.ps1 (597 changed lines)
- extensions/specrew-speckit/scripts/shared-governance.ps1 (341 changed lines)
- extensions/specrew-speckit/scripts/validate-governance.ps1 (258 changed lines)
- tests/integration/hardening-gate-contract.ps1 (327 changed lines)
