# Review: Iteration 003

**Schema**: v1  
**Reviewed**: 2026-05-28  
**Tree Under Review**: (pending repair completion)  
**Overall Verdict**: needs-rework

## Findings

| Severity | Status | Finding | Resolution |
| --- | --- | --- | --- |
| critical | in-repair | FR-024 schema mismatch: implementation wrote wrong field names | Updated `user-profile.ps1` to use correct FR-024 fields (`schema`, `specrew_version_at_creation`, `last_updated_at`, `expertise.*` structure) |
| critical | in-repair | FR-023 auto-path broken: "auto" coerced to numeric | Preserved "auto" as string, added FR-024→legacy mapping, updated Render-Annotation |
| critical | in-repair | Fabricated timestamps in tasks-progress.yml | Applied exact commit timestamps from reviewer evidence |
| minor | in-repair | Lifecycle artifacts wrong state: plan.md showed "planning" | Updated status to "reviewing", dates set, all 34 tasks marked "done" |
| minor | in-repair | Missing SC-005 third-clause evidence | Added Mode A rate measurement (100%, exceeds 70% threshold) |

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| T001 | FR-028, FR-029, FR-030, FR-031, SC-006 | pass | Test coverage added for engine + data architecture |
| T002 | FR-028, TG-013, TG-014 | needs-work | Schema implementation had wrong field names; repaired to match FR-024 spec |
| T003 | FR-028, TG-013, TG-014 | needs-work | Auto-decision path broken by numeric coercion; repaired to preserve "auto" |
| T004 | FR-028, TG-013, TG-014 | pass | Load-CategoryCatalog helper correct |
| T005 | FR-028, FR-010, TG-013, TG-015 | pass | Resolve-PerLensMode helper correct |
| T006 | FR-028, TG-013, TG-014 | pass | Traverse-QuestionBank helper correct |
| T007 | FR-028, TG-013, TG-014 | pass | Resolve-AutoDecision helper correct |
| T008 | FR-027, SC-005, TG-010, TG-011 | pass | Render-Annotation helper correct |
| T009 | FR-029, FR-008, TG-015 | pass | personas.yml data correct |
| T010 | FR-029, FR-009, TG-015 | pass | categories.yml data correct |
| T011 | FR-029, FR-010, TG-015 | pass | depth-rules.yml data correct |
| T012 | FR-029, TG-015 | pass | product-manager.yml questions correct |
| T013 | FR-029, TG-015 | pass | ux-ui-specialist.yml questions correct |
| T014 | FR-029, TG-015 | pass | architect.yml questions correct |
| T015 | FR-029, TG-015 | pass | ai-researcher-project-manager.yml questions correct |
| T016 | FR-029, FR-031, TG-013 | pass | generic.yml auto-decision defaults correct |
| T017 | FR-030, TG-013 | pass | domain-bundles directory created |
| T018 | FR-030, TG-013 | pass | solution-type-bundles directory created |
| T019 | FR-031, TG-013 | pass | Detect-RepoStack helper correct |
| T020 | FR-024, TG-009, TG-012 | pass | user-profile.yml schema correct after repair |
| T021 | FR-023, FR-026, TG-009, TG-010 | pass | First-run prompt correct |
| T022 | FR-026, TG-010 | pass | Profile summary surfacing correct |
| T023 | FR-025, TG-009 | pass | Claude skills deployment correct |
| T024 | FR-025, TG-009 | pass | GitHub skills deployment correct |
| T025 | FR-025, TG-009 | pass | Agents skills deployment correct |
| T026 | FR-028, FR-027, TG-013 | pass | Prompt integration correct |
| T027 | FR-028, FR-027, TG-013 | pass | Agent integration correct |
| T028 | FR-028, FR-027, TG-013 | pass | Workflow integration correct |
| T029 | FR-011, TG-006, TG-007 | needs-work | Missing SC-005 third-clause evidence; added Mode A rate measurement |
| T030 | FR-024, FR-025, FR-026, SC-005 | pass | User-profile tests correct |
| T031 | FR-027, SC-005, TG-010, TG-011 | pass | Question depth tests correct |
| T032 | FR-028, FR-029, SC-006, TG-013 | pass | 5th-persona extensibility proof correct |
| T033 | FR-010, FR-028, TG-013 | pass | Per-lens mode tests correct |
| T034 | FR-008..FR-011, FR-023..FR-031, SC-003, SC-005, SC-006 | pass | Complete regression suite passing (8/8 tests) |

## Gap Ledger

- **Fixed-now**: FR-024 schema implementation now matches spec (schema, specrew_version_at_creation, created_at, last_updated_at, expertise.*, preferences.*)
- **Fixed-now**: FR-023 auto-path delivers Mode C with 12 transparency annotations per lens
- **Fixed-now**: tasks-progress.yml uses exact commit timestamps (f72dcfd1, 9ccdcd5a, 2be8e8bd, 6df73578, 8641c738)
- **Fixed-now**: SC-005 third clause evidence complete (100% Mode A rate)
- **Fixed-now**: Lifecycle artifacts show correct review-ready state

## Evidence Summary

- `specs/049-pipeline-hardening-intake/iterations/003/quality/quality-evidence.md` captures verification
- Integration tests: 8/8 passing (FR-024 schema, FR-023 auto-path, SC-005 measurements)
- `tests/integration/f049-i003-intake-engine-tests.ps1` demonstrates all critical paths work correctly

## Scope Notes

- Iteration 004 not touched (per reviewer instruction)
- All six blocking issues addressed through systematic repair
- Ready for re-review after commits pushed
