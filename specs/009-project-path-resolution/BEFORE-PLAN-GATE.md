# Before-Plan Gate Report: Feature 009

**Feature**: Project Path Resolution in Specrew Entry-Point Scripts  
**Feature Directory**: `specs/009-project-path-resolution`  
**Gate Execution Date**: 2026-05-09  
**Gate Status**: ✅ **APPROVED FOR PLANNING**

---

## Executive Summary

Feature 009 has passed the before-plan governance gate. The specification is complete, requirements are clear and testable, all clarifications are resolved, and critical governance requirements (regression coverage, known-traps corpus integration) are explicitly specified. **Planning phase may proceed.**

---

## Gate Validation Results

### ✅ Specification Completeness

All mandatory sections are present and complete:

- **Problem Statement**: Root cause identified (PowerShell $PWD vs .NET CurrentDirectory divergence), user impact clearly described (canonical workflow broken on Windows), spec 001 dogfooding impact articulated
- **Relationship to Existing Features**: Links established to spec 001 (FR-024, FR-035) and spec 005 (FR-034/037)
- **User Scenarios & Testing**: Three prioritized user stories (2×P1, 1×P2) with concrete acceptance scenarios
- **Requirements**: Nine functional requirements (FR-001 through FR-009) with clear acceptance criteria
- **Traceability & Governance Requirements**: Five traceability mappings (TG-001 through TG-005), four key entity definitions
- **Success Criteria**: Five measurable outcomes (SC-001 through SC-005)
- **Assumptions**: PowerShell 7+ on Windows, spec 005 corpus availability, interim fix as baseline
- **Non-Goals**: Clear scope boundaries (no universal GetFullPath replacement, no new abstraction layers)
- **Clarifications**: Session 2026-05-09 clarifications incorporated; no unresolved `[NEEDS CLARIFICATION]` markers remain
- **Governance Alignment**: Spec Steward (Alon Fliess), Iteration Facilitator, Capacity Model, Drift Signals, Human Oversight Points

### ✅ Requirement Actionability

**Functional Requirements (9 total)**:

- FR-001: Shared Resolve-ProjectPath helper (relative path → PowerShell $PWD; rooted path → GetFullPath)
- FR-002: Entry-point script adoption (5 scripts: specrew-start.ps1, specrew-update.ps1, specrew-init.ps1, specrew-team.ps1, specrew-review.ps1)
- FR-003: Internal script audit (extensions/specrew-speckit/scripts/ + .specify/extensions/specrew-speckit/scripts/)
- FR-004: Absolute path pass-through (no breaking change for rooted paths)
- FR-005: Error message fidelity (preserve text, correct absolute paths in output)
- FR-006: Deterministic regression coverage (integration test with Set-Location and CurrentDirectory mismatch)
- FR-007: Static audit check (scan for reintroduction of broken pattern)
- FR-008: Known-traps corpus seeding (5 fields: category, pattern, detection, remediation, date)
- FR-009: Mechanical-check mapping (OPTIONAL, Phase 2 dependent)

**Traceability Mappings (5 total)**:

- TG-001: User Story 1 (canonical entry-point) → FR-001, 002, 004, 005
- TG-002: User Story 2 (consistency) → FR-002, 003
- TG-003: User Story 3 (regression prevention) → FR-006, 007
- TG-004: Trap corpus integration → FR-008, FR-009 (Phase 2)
- TG-005: Additive to spec 001 (no breaking changes)

**Success Criteria (5 total)**:

- SC-001: 100% of representative user sessions with entry-point scripts resolve to PowerShell PWD
- SC-002: 100% of audited call sites migrated or exempted with documented rationale
- SC-003: Static audit produces zero findings; deterministic regression test exits zero
- SC-004: Known-traps corpus contains path-resolution trap with all five required fields populated
- SC-005: No entry-point script reports false "not bootstrapped" errors against wrong paths

### ✅ Quality Checklist: PASS

**Content Quality**:

- No implementation details (languages, frameworks, specific APIs)
- Focused on user value (broken workflow, dogfooding loop impact)
- Written for non-technical stakeholders (concrete error examples with actual error messages)

**Requirement Quality**:

- No clarification markers remain
- Testable and unambiguous (MUST/SHOULD with quantifiable acceptance criteria)
- Measurable success criteria (100%, zero, specific corpus fields)
- Technology-agnostic (describes behavior, not implementation details)

**Completeness**:

- All acceptance scenarios defined for all three user stories
- Edge cases identified (absolute paths, UNC paths, non-existent paths, wrapper/scheduler scenarios)
- Scope clearly bounded with explicit non-goals

### ✅ Critical Governance Requirements

**Regression Coverage (User Story 3, FR-006/FR-007)**:

- ✓ Deterministic integration test required (FR-006)
- ✓ Static audit check required (FR-007)
- ✓ Traceability: TG-003 maps User Story 3 (P2) to FR-006, FR-007
- ✓ Success validation: SC-003 confirms zero findings and zero regression exit

**Known-Traps Corpus Integration (FR-008)**:

- ✓ Mandatory corpus entry seeding in scope (not optional or deferred)
- ✓ Five required fields specified: category (path-resolution), concrete pattern, detection method, remediation guidance, discovery date (2026-05-09)
- ✓ Traceability: TG-004 maps corpus integration to FR-008
- ✓ Success validation: SC-004 confirms presence of trap entry with all five fields
- ✓ Optional Phase 2 mechanical-check mapping (FR-009) does not block feature closure

### ✅ Validation Lane Preservation

**Full validation lane for Feature 009 is explicit and preserved**:

1. **User Story 1** (P1 - Canonical entry-point behavior)
   - Entry-point scripts with `-ProjectPath '.'` resolve correctly from project root
   - Covers: FR-001, FR-002, FR-004, FR-005
   - Validates: SC-001, SC-005

2. **User Story 2** (P1 - Consistency across all scripts)
   - Path resolution consistent across all entry-point and internal scripts
   - Covers: FR-002, FR-003
   - Validates: SC-002

3. **User Story 3** (P2 - Regression prevention)
   - Deterministic regression test and static audit in place
   - Covers: FR-006, FR-007
   - Validates: SC-003

**Edge cases explicitly covered**:

- Absolute Windows paths (no behavior change)
- UNC paths (same handling as absolute paths)
- Non-existent paths (resolve against PWD before checking existence)
- Wrapper/scheduler scenarios (PWD explicitly set by wrapper)
- Script-to-script invocation (no double-resolution)

**Governance assignments**:

- Spec Steward: Alon Fliess (owns policy boundary that "downstream users SHOULD start work with `specrew start`")
- Iteration Facilitator: Specrew lifecycle and routing maintainers

---

## Blocker Assessment: NONE

All potential blockers have been resolved:

✅ **Clarification Phase**: Complete (Session 2026-05-09)  
✅ **Interim Fix Baseline**: Validated as reference implementation for FR-001  
✅ **Spec 005 Dependency**: Clarified (FR-008 can seed first corpus entry if needed)  
✅ **Requirement Ambiguity**: None (all FR/SC/TG are explicit and unambiguous)  
✅ **Governance Record**: Complete (steward, facilitator, capacity, drift signals documented)  

---

## Approved Governance Artifacts

### Present and Validated

- ✅ `spec.md`: Complete specification with all mandatory sections
- ✅ `checklists/requirements.md`: Quality checklist with PASS validation
- ✅ `.specify/feature.json`: Feature pointer updated

### Governance Record Items

- ✅ Spec Steward identified: Alon Fliess
- ✅ Iteration Facilitator identified: Specrew lifecycle maintainers
- ✅ Capacity model confirmed: One bounded fix slice
- ✅ Drift signals documented: Future GetFullPath reintroduction, user reports of false bootstrap errors, inconsistent path resolution
- ✅ Human oversight points identified: Audit list approval, trap entry text approval, regression script review

---

## Planning Readiness Criteria

### Mandatory Criteria: ALL MET ✅

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Specification is complete | ✅ PASS | All 10 mandatory sections present and detailed |
| No clarification blockers remain | ✅ PASS | No `[NEEDS CLARIFICATION]` markers in spec |
| Requirements are testable | ✅ PASS | All FR/SC are measurable and unambiguous |
| Success criteria are measurable | ✅ PASS | SC-001 through SC-005 define quantifiable outcomes |
| Governance assignments made | ✅ PASS | Steward, Facilitator, Capacity, Drift signals documented |
| Critical governance requirements explicit | ✅ PASS | Regression coverage (FR-006/007) and corpus seeding (FR-008) specified |
| Validation lane preserved | ✅ PASS | 3-story lane (P1, P1, P2) and edge cases documented |
| No implementation details leak into spec | ✅ PASS | Spec describes behavior, not PowerShell/code mechanisms |

---

## Next Phase: Planning

**Planning phase may now proceed with the following preservation requirements**:

1. **Preserve the 3-story validation lane**:
   - User Story 1 (P1): Canonical entry-point behavior
   - User Story 2 (P1): Consistency across all scripts
   - User Story 3 (P2): Regression prevention and static audit

2. **Ensure plan includes tasks for critical governance requirements**:
   - FR-006: Deterministic regression test with Set-Location/CurrentDirectory mismatch
   - FR-007: Static audit check for broken pattern reintroduction
   - FR-008: Known-traps corpus seeding (5-field entry for path-resolution trap)

3. **Plan MUST map all user stories to FR/SC**:
   - TG-001 through TG-005 traceability must remain visible in plan and tasks
   - SC-001 through SC-005 must be testable from planned tasks

4. **Preserve interim fix**:
   - Existing Resolve-ProjectPath helper in `extensions/specrew-speckit/scripts/shared-governance.ps1` is reference implementation for FR-001
   - Existing adoption in specrew-start.ps1 and specrew-update.ps1 is baseline for FR-002 extension

---

## Gate Sign-Off

**Gate Executed By**: Specrew Governance Automation  
**Gate Result**: ✅ **APPROVED**  
**Recommendation**: Proceed to planning phase without delay  
**Validation Timestamp**: 2026-05-09

---

**Feature 009 is ready for implementation planning.**
