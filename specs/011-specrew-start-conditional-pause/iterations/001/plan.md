# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: executing  
**Capacity**: 10/20 story_points  
**Planned Start**: 2026-05-11  
**Started**: 2026-05-11  
**Hardening-Gate Sign-Off**: 2026-05-11 by Alon Fliess  
**Implementation Authorization**: 2026-05-11

## Summary

Iteration 001 is the foundational slice for feature `011-specrew-start-conditional-pause`. It carries **Phase 1 (Setup & Core Infrastructure) + Phase 2 (Detector Logic, Baseline Tracking, Preservation & Error Fidelity)** only—the change detection infrastructure, baseline commit tracking mechanism, auto-continue preservation for routine resumes, signature stability, and error message fidelity that all pause-and-confirm and parameter features depend on—so before-implement can review the detector mechanism and baseline tracking semantics before pause injection and parameter handling land in Iteration 002.

This is a truthful 10-point slice deliberately stopped before pause-and-confirm directive injection and the optional `-PostRestartDirective` parameter. User-facing pause messages, parameter handling, visibility output testing, known-traps corpus seeding, and comprehensive documentation updates are explicitly deferred to Iteration 002, giving reviewers a clean checkpoint to validate the core change detection mechanism before user-facing behavior adds complexity.

**Primary Focus**: Change detector implementation via `git diff --name-only`, baseline commit hash tracking in `.specrew/last-start-prompt.md` YAML frontmatter, auto-continue preservation for routine resumes, signature stability verification, and error-message preservation  
**Target Slice**: Phase 1 + Phase 2 (`T029`-`T042`)  
**Execution Status**: implementation authorized; execution pending start  
**Deferred Follow-On**: Pause-and-confirm injection, optional parameter support, visibility output, comprehensive tests, and corpus seeding (`T043`-`T057`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001 | Change Detector Implementation | ✅ `T032` | Script maintainer | Implement `git diff --name-only` detector scanning session-loaded paths |
| FR-002 | Baseline Commit Tracking | ✅ `T033` | Script maintainer | Track baseline_commit_hash in .specrew/last-start-prompt.md YAML frontmatter |
| FR-004 | Auto-continue Preservation for Routine Resumes | ✅ `T034` | Script maintainer | Preserve auto-continue directive when detector reports zero changes |
| FR-006 | Signature Stability | ✅ `T035` | Script maintainer | Verify specrew-start.ps1 signature and documented arguments remain unchanged |
| FR-007 | Error Message Preservation | ✅ `T036` | Script maintainer | Preserve all existing error messages; add new pause messages additively |
| FR-010 | Deterministic Test Coverage | ✅ `T037`-`T040` | Test infrastructure maintainer | Write test fixtures and assertions for detector, baseline tracking, auto-continue preservation |
| TG-001, TG-002, TG-005 | Detector Accuracy, Baseline Tracking Durability, Auto-continue Preservation | ✅ `T032`-`T042` | Script maintainer, Test infrastructure maintainer | All requirements map to foundational infrastructure |
| SC-001, SC-002 | Routine Resume Scenarios, Auto-continue Preservation Acceptance | ✅ `T037`-`T039` | Test infrastructure maintainer | Test fixtures and assertions for no-change detection |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Phase 1 + Phase 2 detector and baseline tracking from approved spec.md; pause-and-confirm, parameter, and visibility features explicitly deferred to Iteration 002 |
| **Traceability** | ✅ PASS | Every task maps to foundational FRs (FR-001 through FR-007, FR-010) and canonical test goals (TG-001, TG-002, TG-005) |
| **Ownership** | ✅ PASS | Task owners align to Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 10/20 story_points; truthful slice with explicit deferrals of pause-and-confirm, parameter, visibility, and corpus work |
| **Execution Support** | ✅ PASS | Planning artifacts, baseline documentation, test fixtures, and hardening-gate artifact ready for before-implement review |

---

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-foundation` — change detector infrastructure, baseline tracking mechanism, auto-continue preservation  
**Inferred Quality Profile**: `quality-profile.cli-script-integration-focused.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell CLI modification with git integration, YAML frontmatter handling, deterministic test coverage for core paths, and error message preservation.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Detector accuracy | `required` | Change detection must precisely identify session-loaded file commits; false negatives bypass the pause (regression), false positives over-pause |
| Baseline tracking durability | `required` | Baseline commit hash must survive YAML serialization/deserialization and be precisely comparable between sessions; drift breaks the detector |
| Auto-continue preservation | `required` | Auto-continue behavior for routine resumes (no changes) must not regress; this is the baseline spec 001 Session 2026-05-04 behavior |
| Signature stability | `required` | `specrew-start.ps1` signature, documented arguments, and defaults must remain unchanged (except new optional `-PostRestartDirective` in Iteration 002) |
| Error message preservation | `required` | All existing error messages must remain in their current locations and unchanged; new pause messages added additively only |
| Performance | `required` | Change detector must complete in <100ms baseline assumption to avoid noticeable delay in handoff rendering |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Planned | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ------- | ------- |
| T029 | Create baseline tracking structure documentation and examples showing `.specrew/last-start-prompt.md` YAML frontmatter with `baseline_commit_hash` field format | FR-002 | Foundation | S | Infrastructure maintainer | `specs/011-specrew-start-conditional-pause/quickstart.md` | planned | 1 day | — |
| T030 | Create test fixture directory structure and template scaffolds for change-detection test scenarios (no changes, with changes, bootstrap case) | FR-001, FR-002 | Foundation | S | Test-infrastructure maintainer | `tests/integration/fixtures/specrew-start-detector/` | planned | 1 day | — |
| T031 | Create planning-time hardening-gate.md artifact documenting Phase 1 quality concerns with evidence expectations and pending sign-off structure using richer pre-sign-off schema | FR-010 | Foundation | S | Quality governance maintainer | `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md` | planned | 1 day | — |
| T032 | Implement `git diff --name-only` change detector against baseline commit in `scripts/specrew-start.ps1`, scanning session-loaded paths and returning list of changed files or empty list | FR-001 | Foundation | M | Script maintainer | `scripts/specrew-start.ps1` | planned | 2 days | — |
| T033 | Implement baseline commit tracking in `.specrew/last-start-prompt.md` YAML frontmatter: read existing `baseline_commit_hash` field, validate format, update to current HEAD after detector runs | FR-002 | Foundation | M | Script maintainer | `scripts/specrew-start.ps1` | planned | 2 days | — |
| T034 | Preserve auto-continue directive when detector reports zero changes (routine resumes, spec 001 Session 2026-05-04 behavior) | FR-004 | Foundation | S | Script maintainer | `scripts/specrew-start.ps1` | planned | 1 day | — |
| T035 | Verify `specrew-start.ps1` signature, documented arguments, and defaults remain unchanged (no breaking changes except optional `-PostRestartDirective` in Iteration 002) | FR-006 | Foundation | S | Script maintainer | `scripts/specrew-start.ps1` | planned | 1 day | — |
| T036 | Preserve all existing error messages in their current locations; add new pause-and-confirm messages additively (no modification to existing error paths) | FR-007 | Foundation | S | Script maintainer | `scripts/specrew-start.ps1` | planned | 1 day | — |
| T037 | Write test fixtures and scaffolds for routine resume scenarios (no commits to session-loaded paths, multiple runs in same session state) | SC-001, SC-002 | US1 | M | Test infrastructure maintainer | `tests/integration/fixtures/specrew-start-detector/routine-resume/` | planned | 2 days | — |
| T038 | Write deterministic tests asserting detector returns empty list when no session-loaded files have changed | FR-001, SC-001, SC-002 | US1 | M | Test infrastructure maintainer | `tests/integration/specrew-start-change-detector.ps1` | planned | 2 days | — |
| T039 | Write deterministic tests asserting regenerated `.specrew/last-start-prompt.md` includes auto-continue directive when no changes detected | FR-004, SC-001 | US1 | M | Test infrastructure maintainer | `tests/integration/specrew-start-auto-continue-preservation.ps1` | planned | 2 days | — |
| T040 | Write baseline tracking tests asserting YAML frontmatter serialization/deserialization of `baseline_commit_hash` survives round-trip | FR-002, SC-002 | US1 | M | Test infrastructure maintainer | `tests/integration/specrew-start-baseline-tracking.ps1` | planned | 2 days | — |
| T041 | Integrate change detector logic (T032), baseline tracking (T033), auto-continue preservation (T034) into single cohesive flow ensuring detector runs after bootstrap check but before handoff directive generation | FR-001, FR-002, FR-004 | US1 | L | Script maintainer | `scripts/specrew-start.ps1` | planned | 3 days | — |
| T042 | Run test suite for T037-T040 against T041 implementation and verify all tests pass (zero changes detected = auto-continue preserved) | SC-001, SC-002 | US1 | M | Review-operations maintainer | `tests/integration/specrew-start-*.ps1` | planned | 2 days | — |

**Total Effort**: 10 story_points

---

## Planned Execution Order

1. **Phase 1 (Setup)**: `T029`, `T030`, `T031` in parallel—baseline documentation, fixture scaffolding, and hardening-gate artifact creation
2. **Phase 2 (Detector Implementation)**: `T032`, `T033`, `T034`, `T035`, `T036` can be coded in parallel but integrated sequentially
3. **User Story 1 (Tests & Validation)**: `T037`, `T038`, `T039`, `T040` in parallel—test fixtures and assertions for different concerns
4. **User Story 1 (Integration)**: `T041` integrates all Phase 2 logic; `T042` validates all tests pass
5. Stop at `T042`; do not start any pause-and-confirm injection, parameter support, or visibility testing in this iteration

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T043`-`T054` | 002 | Pause-and-confirm injection, optional `-PostRestartDirective` parameter, and parameter tests depend on detector infrastructure from Iteration 001 |
| `T055`-`T057` | 002 | Polish phase: comprehensive integration tests, known-traps corpus seeding, and documentation updates happen after User Story 2 and 3 land |

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Concurrency Rationale

- Current roster snapshot: Script maintainer, Test infrastructure maintainer, Review-operations maintainer
- Technology and scope signals: PowerShell CLI modification with git integration, deterministic test coverage
- Task dependency graph: `T029`, `T030`, `T031` are independent setup; `T032`, `T033`, `T034`, `T035`, `T036` are sequential logic integration; `T037`-`T040` are independent test fixtures/assertions; `T041` integrates all; `T042` validates all
- Workstream separability: Moderate. Setup tasks can run in parallel. Implementation tasks can be coded in parallel but must be tested sequentially. Test fixtures can be written in parallel before implementation.
- Shared-surface conflict risk: Low. All changes scoped to single entry point (`scripts/specrew-start.ps1`) and test files; YAML frontmatter manipulation is serialized.
- Recommendation: Run setup in parallel (T029-T031), then detector implementation (T032-T036) with parallel test fixture writing (T037-T040), then integration (T041), then validation (T042).

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Iteration slicing, this plan document, traceability packaging, hardening-gate artifact creation |
| Discovery/Spikes | 0 | Feature design already complete; no separate spike authorized |
| Implementation | 7 | Detector logic (T032-T033), preservation (T034-T036), integration (T041) |
| Testing | 3 | Test fixture setup (T037-T040), validation run (T042) |
| Review | 1 | Review validation results and detector logic; hardening-gate sign-off before implementation |
| Rework | 0 | Small buffer reserved if tests fail or edge cases emerge |

## Implementation Approval

- **Approval Verdict**: ✅ **HARDENING-GATE SIGNED OFF AND IMPLEMENTATION AUTHORIZED**
- **Signed Off By**: Alon Fliess
- **Signed Off At**: 2026-05-11
- **Authorized Scope**: Feature 011 iteration 001 (Phase 1 + Phase 2 foundational slice — change detector implementation, baseline commit hash tracking via YAML frontmatter, auto-continue preservation, signature stability verification, error-message preservation, tasks T029 through T042, 10 story points)
- **Authorized Activities**: Implementation, review, retrospective, and closeout
- **Boundary Note**: Implementation approval is explicitly distinct from planning-level approval. Hardening-gate sign-off by Alon Fliess on 2026-05-11 authorizes the bounded scope (Phase 1 + Phase 2 detector and baseline tracking infrastructure) for implementation start. Pause-and-confirm injection, parameter support, visibility output testing, and corpus seeding are explicitly deferred to Iteration 002.

## Notes

- This plan carries Phase 1 + Phase 2 work only—detector infrastructure and baseline tracking—before pause-and-confirm and parameter features land in Iteration 002.
- `T029`-`T031` set up baseline documentation, test fixtures, and planning-time hardening-gate artifact.
- `T032`-`T036` implement the core change detector and tracking mechanism.
- `T037`-`T040` write test fixtures and assertions for detector accuracy, baseline durability, and auto-continue preservation.
- `T041` integrates all detector logic into a single flow in `specrew-start.ps1`.
- `T042` runs the full test suite to confirm all core paths pass without regression.
- User Story 2 (pause-and-confirm) and User Story 3 (parameter support) are explicitly deferred to Iteration 002.
- Pause-and-confirm visibility output testing and known-traps corpus seeding are deferred to Iteration 002 Polish phase.
