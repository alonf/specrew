# Tasks: F-049 Release Pipeline Hardening + Substantive Intake Slice

**Input**: Design documents from `specs/049-pipeline-hardening-intake/`  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/pipeline-hardening-intake.md`, `quickstart.md`, `review-diagrams.md`  
**Scope Guardrail**: Three iterations. Iteration 001 ships the pre-publish Docker E2E harness + Prop 134 version pin check. Iteration 002 ships the durable troubleshooting guide. Iteration 003 ships `/speckit.specify` persona intake.

---

## Iteration 001: Docker Pre-Publish Verification

### Phase 1: Docker Harness Tests & Setup

- [ ] T001 [P] [assigned_to: Reviewer] [effort: S] Add failing E2E publish-module test assertions: harness fails if files in `Specrew.psd1` FileList are missing in the candidate package, or if version pin drift is detected (Prop 134). (Trace: FR-003, FR-012, SC-001)
- [ ] T002 [assigned_to: Implementer] [effort: M] Create `tests/Dockerfile.publish-test` using `mcr.microsoft.com/powershell:lts-ubuntu-22.04` that sets up a clean baseline by downloading Specrew `v0.27.6` from PSGallery. (Trace: FR-001, FR-002, SC-001)
- [ ] T003 [assigned_to: Implementer] [effort: M] Create `scripts/internal/test-publish-harness.ps1` E2E test script: installs previous stable baseline, executes `specrew init`, unpacks module candidate, and verifies that every single FileList entry exists on disk. (Trace: FR-003, SC-001)
- [ ] T004 [assigned_to: Implementer] [effort: S] Add manifest version pin drift assertions to `test-publish-harness.ps1` comparing version declarations in `.specrew/config.yml` (`specrew_version`) vs `Specrew.psd1` (`ModuleVersion`). (Trace: FR-012, SC-001)
- [ ] T005 [assigned_to: Implementer] [effort: S] Add `specrew update` execution and layout validation to `test-publish-harness.ps1` ensuring update transitions succeed cleanly. (Trace: FR-004, SC-001)

### Phase 2: Pipeline Integration & Verification

- [ ] T006 [assigned_to: Implementer] [effort: S] Wire the Docker harness execution directly into `.github/workflows/publish-module.yml` as a blocking step before module publication. (Trace: FR-005, SC-001)
- [ ] T007 [assigned_to: Reviewer] [effort: S] Run focused harness tests locally and in CI to verify the pre-publish block works perfectly; record results in iteration quality artifacts. (Trace: FR-005, SC-001)

---

## Iteration 002: Troubleshooting Guide & Cross-References

### Phase 3: Troubleshooting Guide Content

- [ ] T008 [assigned_to: Spec Steward] [effort: S] Create durable `docs/troubleshooting.md` addressing: standard recovery, PSGallery side-by-side cache gotchas, FileList omissions, deployscript exceptions, clean-reinstalls. (Trace: FR-006, SC-002)
- [ ] T009 [assigned_to: Implementer] [effort: S] Add `docs/troubleshooting.md` to `Specrew.psd1`'s `FileList` in the same commit to prevent future omissions. (Trace: FR-007, SC-002)

### Phase 4: Cross-Referencing & Documentation Verification

- [ ] T010 [assigned_to: Spec Steward] [effort: S] Add clear cross-reference links pointing to `docs/troubleshooting.md` inside `README.md`, `docs/getting-started.md`, and `docs/user-guide.md`. (Trace: FR-006, SC-002)
- [ ] T011 [assigned_to: Reviewer] [effort: S] Run governance validation and check that all cross-references render correctly; record results in quality artifacts. (Trace: FR-006, FR-007, SC-002)

---

## Iteration 003: Substantive specify Intake

### Phase 5: Persona Templates & branched specify CLI

- [ ] T012 [P] [assigned_to: Reviewer] [effort: S] Add failing specify integration tests asserting correct template generation and branching behavior for PM, UX, Architect, and AI Researcher personas. (Trace: FR-008, FR-009, SC-003)
- [ ] T013 [assigned_to: Implementer] [effort: M] Implement specify CLI persona-branching logic: prompts user to select a persona, and dynamically displays the corresponding targeted spec generation guidance. (Trace: FR-008, SC-003)
- [ ] T014 [assigned_to: Implementer] [effort: M] Implement the 12-category console intake catalog within `/speckit.specify` with standard numbered PowerShell prompts. (Trace: FR-009, SC-003)

### Phase 6: Branching Modes, Escape Hatches & AI Research

- [ ] T015 [assigned_to: Implementer] [effort: S] Implement dynamic Mode A, Mode B, and Mode C branching based on input completeness. (Trace: FR-010, SC-003)
- [ ] T016 [assigned_to: Implementer] [effort: S] Add `"Other"` and `"I don't know, you decide"` fallback options, integrating the AI domain-research stack parser to compute optimal defaults. (Trace: FR-011, SC-003)
- [ ] T017 [assigned_to: Reviewer] [effort: S] Run E2E specify tests across various personas and modes; perform E2E PR verification and closeout checks. (Trace: FR-008, FR-009, FR-010, FR-011, SC-003)
