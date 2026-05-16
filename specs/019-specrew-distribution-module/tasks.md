# Tasks: Specrew Distribution Module

**Feature**: 019-specrew-distribution-module  
**Input**: Design documents from `/specs/019-specrew-distribution-module/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/Specrew.psd1.contract.md, quickstart.md

**Organization**: Tasks are grouped by implementation pillar (from plan.md). The first phase resolves six design questions that surfaced during planning but do not block the plan structure. Each task includes explicit traceability metadata and file paths.

**Estimated Total Effort**: 14 Story Points (SP) across all pillars

---

## Phase 0: Design-Question Resolution (Pre-Implementation)

**Purpose**: Resolve six plan-time design questions that surfaced during planning. T001-T004 must complete before Pillar 1/2 implementation begins, T006 must complete before the Pillar 5 signing work, and T005 remains a documentation-only non-blocking task.

**⚠️ CRITICAL**: T001-T004 and T006 carry implementation impact. T005 should still be recorded truthfully, but it does not block implementation work.

### Design Question Tasks

- [ ] T001 [assigned_to: Implementation Team] [effort: S] **Resolve Module Manifest File-List Strategy** — Decide explicit FileList enumeration vs. automatic detection for Specrew.psd1; update contracts/Specrew.psd1.contract.md with decision and rationale (Trace: plan.md Plan-Time Design Question 1, FR-010)  
  **Blocks**: T007, T010, T011, T012, T013, T014  
  **Downstream Impact**: Pillar 1 Module Packaging implementation depends on FileList structure decision

- [ ] T002 [assigned_to: Implementation Team] [effort: S] **Resolve Conflict-Marker Format** — Choose conflict marker format (Git-style vs custom vs structured) for specrew update; document in data-model.md Template Conflict entity. **Options**: (A) Git-style (`<<<<<<<`, `=======`, `>>>>>>>`): familiar to developers but may break non-text files; (B) Custom (`<<<< USER`, `==== MODULE-v0.22`, `>>>> END`): clearer labels but requires parser updates; (C) Structured comments: language-aware but complex. **Implications**: Squad coordinator must be able to parse markers for crew-mediated resolution; choice affects T031 conflict-handling implementation. (Trace: plan.md Plan-Time Design Question 2, FR-021)  
  **Blocks**: T030, T031, T032, T033  
  **Downstream Impact**: Pillar 4 Update Story conflict-resolution implementation depends on marker format decision

- [ ] T003 [assigned_to: Implementation Team] [effort: M] **Resolve Cross-Platform Test Automation Depth** — Decide manual checklist vs GitHub Actions matrix for cross-platform verification; update plan.md Pillar 5 with automation strategy. **Approved 2026-05-16**: Option A — use `specs/019-specrew-distribution-module/iterations/001/quality/cross-platform-manual-checklist.md` for Iteration 001 manual evidence and defer GitHub Actions matrix / Ubuntu / macOS / WSL hardening work to Iteration 002. (Trace: plan.md Plan-Time Design Question 3, FR-031)  
  **Blocks**: T040, T041  
  **Downstream Impact**: Pillar 5 Publishing Workflow cross-platform verification task scope depends on automation depth decision

- [ ] T004 [assigned_to: Implementation Team] [effort: S] **Resolve Module Loader Structure** — Choose explicit dot-sourcing vs dynamic discovery for Specrew.psm1; update contracts/Specrew.psd1.contract.md with loader pattern. **Approved 2026-05-16**: Option A — explicit dot-sourcing using `$ScriptRoot = $PSScriptRoot`, `Join-Path` for every path segment, `scripts/internal/dashboard-renderer.ps1` first, then the reviewed entry-point order (`specrew`, `specrew-init`, `specrew-review`, `specrew-start`, `specrew-team`, `specrew-update`, `specrew-where`); broader embedded `\` cleanup stays deferred to Iteration 002. (Trace: plan.md Plan-Time Design Question 4, research.md R2)  
  **Blocks**: T008  
  **Downstream Impact**: Pillar 1 Module Packaging Specrew.psm1 implementation depends on loader structure decision

- [x] T005 [assigned_to: Alon Fliess] [effort: S] **Document API-Key Rotation Guidance** — Document PSGallery API key rotation procedure in `docs/operations/psgallery-release-credentials.md`, including the approved cadence (annual review/rotation at the key-creation anniversary plus triggered rotation for maintainer transition, suspected leak, unexplained publish-auth failure, or annual-review age >12 months) and the four-step secret-update + dry-run verification protocol. **Approved 2026-05-16**: Option A — document lightweight cadence now and pair the annual review with T006 certificate review later. **Non-blocking**: documentation-only; does not block implementation work. (Trace: plan.md Plan-Time Design Question 5, data-model.md PSGallery API Key entity)  
  **Blocks**: None (documentation task; does not block implementation)  
  **Downstream Impact**: Maintainer reference for future key rotation; not blocking for v1

- [x] T006 [assigned_to: Implementation Team] [effort: S] **Resolve Self-Signed Certificate Validity Period** — Choose validity period (1 year vs 5 years vs 10 years) for self-signed certificate; document in data-model.md Signing Certificate entity and update Pillar 5 certificate generation task parameters. **Approved 2026-05-16**: Option A — 1-year validity, renewed during the same annual operations event as the PSGallery API-key review; renewal procedure covers `AddYears(1)`, GitHub Actions secret refresh, publish dry-run signing verification, archival of the old certificate, and reminder capture. (Trace: plan.md Plan-Time Design Question 6, research.md R6)  
  **Blocks**: T038  
  **Downstream Impact**: Pillar 5 Publishing Workflow certificate generation task depends on validity period decision

**Phase 0 Verification**:
```powershell
# Verify all six design-question decisions documented
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\contracts\Specrew.psd1.contract.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\data-model.md
Test-Path C:\Dev\Specrew\docs\operations\psgallery-release-credentials.md
```

**Checkpoint**: Design questions resolved — Pillar 1/2 implementation can now begin

---

## Phase 1: Pillar 1 — Module Packaging (US1, US2, US4)

**Goal**: Create valid PowerShell module manifest and loader that exports all Specrew CLI commands

**User Stories Served**: US1 (First-Time Install), US2 (Project Bootstrap from Installed Module), US4 (Module Publishing on Feature Closeout)

**Dependencies**: T001 (FileList strategy), T004 (loader structure) must complete first

### Implementation Tasks

- [x] T007 [P] [assigned_to: Implementation Team] [effort: M] **Create Module Manifest Specrew.psd1** — Generate Specrew.psd1 in repository root with: ModuleVersion placeholder (to be stamped from config.yml at build time), PowerShellVersion = '7.0', GUID (generate once), Author = 'Alon Fliess', Description from spec, FunctionsToExport list (specrew, specrew-init, specrew-start, specrew-update, specrew-review, specrew-team, specrew-where), FileList per T001 decision, PrivateData.PSData (tags, ProjectUri, LicenseUri, ReleaseNotes), PSEdition = 'Core' (Trace: FR-001, FR-002, FR-003, FR-004, FR-032, contracts/Specrew.psd1.contract.md)

- [x] T008 [P] [assigned_to: Implementation Team] [effort: M] **Create Module Loader Specrew.psm1** — Implement Specrew.psm1 in repository root following T004 loader structure decision; dot-source all scripts from scripts/ directory using Join-Path for cross-platform path handling; Export-ModuleMember for all CLI functions (Trace: FR-002, FR-030, research.md R2)

- [x] T009 [assigned_to: Implementation Team] [effort: S] **Validate Module Manifest** — Run Test-ModuleManifest against Specrew.psd1; verify no errors; confirm all FunctionsToExport match actual script files; validate PrivateData structure (Trace: FR-001, Quality Gate: Module manifest validity)

**Pillar 1 Verification**:
```powershell
# Validate manifest structure
Test-ModuleManifest C:\Dev\Specrew\Specrew.psd1
# Verify exports match scripts
Get-Content C:\Dev\Specrew\Specrew.psd1 | Select-String -Pattern "FunctionsToExport"
```

**Checkpoint**: Module manifest valid — can proceed to Pillar 2 bundling

---

## Phase 2: Pillar 2 — Resource Bundling (US1, US2)

**Goal**: Bundle scripts, extensions, templates, and docs in module package; exclude repo artifacts

**User Stories Served**: US1 (First-Time Install), US2 (Project Bootstrap from Installed Module)

**Dependencies**: T001 (FileList strategy), T007 (manifest created) must complete first

### Implementation Tasks

- [x] T010 [P] [assigned_to: Implementation Team] [effort: M] **Create Templates Directory Structure** — Create templates/ directory in repository root with subdirectories: templates/specify/ (copy from .specify/templates/), templates/squad/ (copy from .squad/agents/ and .squad/identity/), templates/github/ (copy from .github/workflows/specrew-*.yml); preserve directory structure for specrew init bootstrap (Trace: FR-008, data-model.md Template Tree entity)

- [x] T011 [P] [assigned_to: Implementation Team] [effort: S] **Bundle Specrew-Speckit Extension** — Verify extensions/specrew-speckit/ is correctly structured for bundling (validators/, coordinator-prompts/, scripts/); update FileList in Specrew.psd1 to include extensions/specrew-speckit/**/* (Trace: FR-007)

- [x] T012 [P] [assigned_to: Implementation Team] [effort: S] **Bundle Scripts Directory** — Verify scripts/ directory structure (entry points + internal/ utilities); update FileList in Specrew.psd1 to include scripts/*.ps1 and scripts/internal/*.ps1 (Trace: FR-006)

- [x] T013 [P] [assigned_to: Implementation Team] [effort: S] **Bundle Documentation** — Verify docs/ directory contains dashboard-guide.md, roadmap-maintenance.md, and `operations/psgallery-release-credentials.md` (from T005); update FileList in Specrew.psd1 to include docs/*.md and the operations subdirectory as needed (Trace: FR-009)

- [x] T014 [assigned_to: Implementation Team] [effort: M] **Validate Exclusions** — Audit FileList in Specrew.psd1; confirm specs/, proposals/, tests/, CHANGELOG.md, LICENSE, README.md, .git/, .vscode/, *.log are excluded; verify module package size estimate under 5 MB (Trace: FR-005, FR-010)

**Pillar 2 Verification**:
```powershell
# Verify templates directory structure
Test-Path C:\Dev\Specrew\templates\specify
Test-Path C:\Dev\Specrew\templates\squad
Test-Path C:\Dev\Specrew\templates\github
# Verify bundled size estimate
Get-ChildItem -Path C:\Dev\Specrew -Recurse -File | Where-Object { $_.FullName -match "scripts|extensions|templates|docs|Specrew\.ps" } | Measure-Object -Property Length -Sum
```

**Checkpoint**: Resources bundled — templates ready for init refactor

---

## Phase 3: Pillar 3 — Init Refactor (US2, US5)

**Goal**: Refactor specrew-init.ps1 to detect module-vs-clone execution context and resolve templates from module path

**User Stories Served**: US2 (Project Bootstrap from Installed Module), US5 (Cross-Platform Consistency)

**Dependencies**: T007 (manifest), T008 (loader), T010 (templates structure) must complete first

### Implementation Tasks

- [x] T015 [assigned_to: Implementation Team] [effort: M] **Implement Module-vs-Clone Detection Logic** — Update scripts/specrew-init.ps1 to detect execution context: if running from module (Test-Path "$PSScriptRoot/../Specrew.psd1"), resolve templates from "$PSScriptRoot/../templates/"; else fall back to existing clone-and-PATH logic (.specify/templates/ in repo root); use Join-Path for all path construction (Trace: FR-011, FR-012, FR-030, US5 cross-platform requirement)

- [x] T016 [assigned_to: Implementation Team] [effort: L] **Refactor Template-Copy Logic for Module Path** — Update specrew-init.ps1 template-copy loops to: (1) copy templates/specify/* to <user-project>/.specify/, (2) copy templates/squad/* to <user-project>/.squad/, (3) copy templates/github/* to <user-project>/.github/; preserve directory structure; use Join-Path for all destination paths (Trace: FR-013, FR-014, FR-015, FR-030)

- [x] T017 [assigned_to: Implementation Team] [effort: M] **Preserve Per-Project File Generation** — Verify specrew-init.ps1 still generates per-project files after template copy: feature.json baseline, .squad/decisions.md skeleton, .squad/identity/now.md; no changes expected to generation logic (Trace: FR-016)

- [x] T018 [assigned_to: Implementation Team] [effort: M] **Implement Idempotency Check** — Add idempotency logic to specrew-init.ps1: detect if .specify/, .squad/, .github/ directories already exist; prompt user for confirmation before overwriting or skip template copy if already initialized (Trace: FR-018)

- [x] T019 [assigned_to: Implementation Team] [effort: S] **Add Bootstrap Validation** — Implement post-bootstrap validation in specrew-init.ps1: verify .specify/templates/ exists with expected files, .squad/agents/ exists, .github/workflows/ contains at least one workflow; report success/failure to user (Trace: FR-017)

**Pillar 3 Verification**:
```powershell
# Exercise the bundled-module bootstrap path and rerun guard
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-init.ps1
```

**Checkpoint**: Init refactored — bootstrap works from module path

---

## Phase 4: Pillar 4 — Update Story (US3, US5)

**Goal**: Implement specrew update command with Template-Refresh pattern and preserve-and-flag conflict resolution

**User Stories Served**: US3 (Module Update and Template Refresh), US5 (Cross-Platform Consistency)

**Dependencies**: T002 (conflict marker format), T015-T019 (init refactor for module-path detection logic) must complete first

### Implementation Tasks

- [x] T030 [assigned_to: Implementation Team] [effort: L] **Create specrew-update.ps1 Entry Point** — Implement scripts/specrew-update.ps1 with: module-version detection (compare user project's init version from baseline vs current installed module version), template-scan logic (detect user-modified templates via content hash comparison), template-refresh flow (classify changes: no-change/user-only/module-only/both-modified), use Join-Path for all path construction (Trace: FR-019, FR-020, FR-030, US3)

- [x] T031 [assigned_to: Implementation Team] [effort: L] **Implement Preserve-and-Flag Conflict Resolution** — Add conflict-handling logic to specrew-update.ps1: for both-modified templates, inject conflict markers per T002 format decision; preserve user's local template in place with markers; embed module's new template content in markers; write .specrew/template-conflicts/<filename>.conflict artifact with full diff (Trace: FR-021, data-model.md Template Conflict entity, research.md R3)

- [x] T032 [assigned_to: Implementation Team] [effort: M] **Implement New-Template Addition** — Add new-template handling logic to specrew-update.ps1: detect templates added in new module version; copy to user project non-destructively; report added files to user (Trace: FR-022)

- [x] T033 [assigned_to: Implementation Team] [effort: M] **Implement Template-Deletion Flagging** — Add deletion-handling logic to specrew-update.ps1: detect templates deleted in new module version; flag for manual review via .specrew/template-conflicts/<filename>.deletion artifact or preserve with deletion marker (Trace: FR-023)

- [x] T034 [assigned_to: Implementation Team] [effort: S] **Add Conflict Artifact Generation** — Implement .specrew/template-conflicts/ artifact generation in specrew-update.ps1: create directory if not exists, write <filename>.conflict files with structure from research.md R3 (User Version, Module Version, Resolution Instructions) (Trace: FR-021, data-model.md Conflict Artifact entity)

- [x] T035 [assigned_to: Implementation Team] [effort: M] **Integrate Conflict Detection into specrew-start** — Update scripts/specrew-start.ps1 to check for .specrew/template-conflicts/*.conflict artifacts at session start; prompt user to review conflicts if unresolved artifacts exist; surface conflict count and file list (Trace: research.md R3 crew-mediated resolution flow)

**Pillar 4 Verification**:
```powershell
# Test update workflow (requires two module versions installed for testing)
# 1. Init project with v0.21
# 2. Modify a template file locally
# 3. Update module to v0.22
# 4. Run specrew update
specrew-update -ProjectPath C:\TestProjects\UpdateTest
Test-Path C:\TestProjects\UpdateTest\.specrew\template-conflicts\*.conflict
Get-Content C:\TestProjects\UpdateTest\.specify\templates\spec-template.md | Select-String -Pattern "<<<<<<<|=======|>>>>>>>"
```

**Checkpoint**: Update story complete — template refresh works with conflict resolution

---

## Phase 5: Pillar 5 — Publishing Workflow (US4, US5)

**Goal**: Implement GitHub Actions workflow for automated module publishing to PSGallery with version stamping and signing

**User Stories Served**: US4 (Module Publishing on Feature Closeout), US5 (Cross-Platform Consistency)

**Dependencies**: T003 (cross-platform automation depth), T006 (certificate validity period), T007 (manifest), T008 (loader), all Pillar 1-4 tasks complete

**Iteration 001 scope note**: T003 fixed this slice to a Windows-first manual evidence path. Do not widen Pillar 5 or Phase 6 work to Ubuntu/macOS matrix validation, WSL end-to-end verification, Join-Path audit hardening, or a real PSGallery publish inside Iteration 001; those items are tracked for Iteration 002.

### Implementation Tasks

- [x] T036 [assigned_to: Implementation Team] [effort: L] **Create GitHub Actions Publish Workflow** — Implemented `.github/workflows/publish-module.yml` with a Windows runner, `v*.*` tag trigger, `workflow_dispatch` manual gate, and release-mode resolution that keeps tag pushes on the dry-run lane in Iteration 001. (Trace: FR-024, FR-026, FR-027, FR-032)

- [x] T037 [assigned_to: Implementation Team] [effort: M] **Implement Version Stamping Step** — Added `scripts/internal/invoke-module-release.ps1` and wired the workflow to read `.specrew/config.yml`, stamp `Specrew.psd1`, and re-run `Test-ModuleManifest` before publish logic proceeds. (Trace: FR-024, data-model.md Module Manifest entity)

- [x] T038 [assigned_to: Implementation Team] [effort: M] **Implement Module Signing Step** — Implemented secret-backed signing for live publish plus an Iteration 001 dry-run fallback that generates a 1-year self-signed certificate, signs `Specrew.psd1`/`Specrew.psm1`, and verifies the signer thumbprint before continuing. (Trace: FR-025, research.md R6, data-model.md Signing Certificate entity)

- [x] T039 [assigned_to: Implementation Team] [effort: M] **Implement Publish-Module Step** — Implemented `Publish-Module` in a dry-run/manual-gated shape: tag pushes use `-WhatIf`, live publish is only allowed through manual dispatch against a tag ref, and failure paths now report missing tag/secret requirements clearly. (Trace: FR-026, FR-028, FR-029, data-model.md PSGallery API Key entity)

- [x] T040 [assigned_to: Implementation Team] [effort: M] **Implement Cross-Platform Verification Task** — Executed the Windows-first checklist at `iterations/001/quality/cross-platform-manual-checklist.md`, including installed-module init/start/where evidence, update artifact evidence, and publish dry-run/manual-gate evidence. Ubuntu/macOS/WSL expansion remains deferred to Iteration 002. (Trace: FR-030, FR-031, research.md R4, US5)

- [ ] T041 [P] [assigned_to: Implementation Team] [effort: S] **Create Join-Path Audit Script** — **Deferred 2026-05-16 to Iteration 002** per the approved Windows-first boundary. The broad audit/hardening sweep was not implemented in Iteration 001 and remains tracked in `.specrew/cross-platform-backlog.md`. (Trace: FR-030, research.md R4)

- [ ] T042 [P] [assigned_to: Alon Fliess] [effort: S] **Configure GitHub Actions Secrets** — **Prepared 2026-05-16; human follow-up still required.** Secret names are documented in `.github/workflows/publish-module.yml`, `docs/operations/psgallery-release-credentials.md`, and `specs/019-specrew-distribution-module/test-evidence/us4-publish.md`. No secrets were created or committed during Iteration 001. (Trace: FR-025, FR-028, data-model.md PSGallery API Key, Signing Certificate entities)

**Pillar 5 Verification**:
```powershell
# Test workflow on test tag (do not push to origin without verification)
git tag v0.21.0-test
git push origin v0.21.0-test
# Monitor GitHub Actions run: https://github.com/alonf/specrew/actions
# Verify workflow steps: version-stamp → sign → publish
# Check PSGallery: Find-Module Specrew -AllVersions
```

**Checkpoint**: Publishing workflow complete — dry-run/manual-gate ready; first live publish still requires T042 and T053

---

## Phase 6: Final Validation and Evidence Collection

**Goal**: Validate all user stories end-to-end; collect test evidence for acceptance criteria

**Dependencies**: All Pillars 1-5 must complete first

**Iteration 001 validation note**: Do not claim FR-031 / SC-006 cross-platform parity in this slice. Iteration 001 records Windows-first manual evidence only; Ubuntu/macOS/WSL parity evidence is deferred to Iteration 002.

### Validation Tasks

- [x] T050 [assigned_to: Implementation Team] [effort: M] **Execute User Story 1 Acceptance Scenarios** — Recorded Windows-first proxy evidence in `test-evidence/us1-install.md`: manifest/import validation, exported command verification, `specrew help`, and fresh-directory installed-module bootstrap. Live PSGallery install evidence remains pending the first real publish. (Trace: US1 acceptance scenarios, SC-001, SC-002)

- [x] T051 [assigned_to: Implementation Team] [effort: M] **Execute User Story 2 Acceptance Scenarios** — Recorded installed-module bootstrap, rerun idempotency, and installed-module `specrew start` handoff evidence in `test-evidence/us2-bootstrap.md`. Final validation also repaired the missing bundled coordinator prompt so bootstrap now leaves the project start-ready. (Trace: US2 acceptance scenarios, SC-002)

- [x] T052 [assigned_to: Implementation Team] [effort: L] **Execute User Story 3 Acceptance Scenarios** — Recorded update/conflict/new-template evidence in `test-evidence/us3-update.md` using the installed-module update fixture and the existing update-command regression coverage. (Trace: US3 acceptance scenarios, SC-003)

- [ ] T053 [assigned_to: Alon Fliess] [effort: M] **Execute User Story 4 Acceptance Scenarios** — **Prepared 2026-05-16; human follow-up still required.** `test-evidence/us4-publish.md` now captures workflow dry-run evidence, tag/manual-gate enforcement, version stamping, and missing-`PSGALLERY_API_KEY` error reporting. The remaining manual action is the first real tag push + manual dispatch publish. (Trace: US4 acceptance scenarios, SC-005)

- [ ] T054 [assigned_to: Implementation Team] [effort: L] **Execute User Story 5 Acceptance Scenarios** — **Deferred to Iteration 002** by the approved T003 Windows-first boundary. Linux/macOS parity and PS 5.1 rejection evidence remain required for the feature, but they are not part of Iteration 001 execution. Record later evidence in specs/019-specrew-distribution-module/test-evidence/us5-cross-platform.md when the deferred slice is authorized. (Trace: US5 acceptance scenarios, SC-006)

- [x] T055 [assigned_to: Implementation Team] [effort: M] **Validate Success Criteria** — Recorded the truthful Iteration 001 success-criteria review in `test-evidence/success-criteria.md`, keeping SC-004 and SC-005 pending live release feedback and SC-006 deferred to Iteration 002. (Trace: SC-001 through SC-006)

- [x] T056 [assigned_to: Implementation Team] [effort: S] **Update Quickstart Guide** — Updated `quickstart.md` to reflect the actual `specrew help` command surface, generated bootstrap artifacts, live-publish pending state, and the current clone-and-PATH fallback. (Trace: quickstart.md, US1 through US5)

**Final Validation Verification**:
```powershell
# Verify test evidence collected
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us1-install.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us2-bootstrap.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us3-update.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us4-publish.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us5-cross-platform.md
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\success-criteria.md
```

**Checkpoint**: All validation complete — ready for feature closeout

---

## Implementation Summary

### Task Count by Phase

- **Phase 0 (Design Questions)**: 6 tasks
- **Phase 1 (Pillar 1 — Module Packaging)**: 3 tasks
- **Phase 2 (Pillar 2 — Resource Bundling)**: 5 tasks
- **Phase 3 (Pillar 3 — Init Refactor)**: 5 tasks
- **Phase 4 (Pillar 4 — Update Story)**: 6 tasks
- **Phase 5 (Pillar 5 — Publishing Workflow)**: 7 tasks
- **Phase 6 (Final Validation)**: 7 tasks

**Total**: 39 tasks

### Parallel Execution Opportunities

**Phase 0**: T001, T002, T003, T004, T006 can execute in parallel (T005 is documentation-only, no blocking dependencies)

**Phase 1**: T007, T008 can execute in parallel after T001 and T004 complete

**Phase 2**: T010, T011, T012, T013 can execute in parallel after T001 and T007 complete

**Phase 3**: T017 (per-project file generation) can execute in parallel with T015-T016 (template-copy refactor)

**Phase 4**: T032 (new-template addition) and T033 (deletion flagging) can execute in parallel with T031 (conflict resolution) after T030 (entry point) completes

**Phase 5**: T042 (GitHub Actions secrets) can execute in parallel with other Iteration 001 Pillar 5 tasks; T041 is deferred to Iteration 002

**Phase 6**: T050-T053 can execute in parallel after all Iteration 001 Pillars 1-5 work completes; T054 remains deferred to Iteration 002

### Critical Path

Phase 0 (Design Questions) → Pillar 1 Module Packaging → Pillar 2 Resource Bundling → Pillar 3 Init Refactor → Pillar 4 Update Story → Pillar 5 Publishing Workflow → Final Validation

**Estimated Duration**: 14 SP (single iteration, focused Monday-Tuesday slot per plan.md)

### Dependencies Summary

- **Pillar 1 depends on**: T001 (FileList strategy), T004 (loader structure)
- **Pillar 2 depends on**: T001 (FileList strategy), T007 (manifest created)
- **Pillar 3 depends on**: T007 (manifest), T008 (loader), T010 (templates structure)
- **Pillar 4 depends on**: T002 (conflict marker format), T015-T019 (init refactor)
- **Pillar 5 depends on**: T003 (cross-platform automation depth), T006 (certificate validity), all Pillars 1-4
- **Final Validation depends on**: All Pillars 1-5 complete

### Traceability Map

| Task Range | User Stories | Functional Requirements | Plan Tracks |
|------------|-------------|------------------------|-------------|
| T001-T006 | All | All (design decisions) | Phase 0 Research |
| T007-T009 | US1, US2, US4 | FR-001 through FR-005, FR-032 | Pillar 1 Module Packaging |
| T010-T014 | US1, US2 | FR-006 through FR-010 | Pillar 2 Resource Bundling |
| T015-T019 | US2, US5 | FR-011 through FR-018, FR-030 | Pillar 3 Init Refactor |
| T030-T035 | US3, US5 | FR-019 through FR-023, FR-030 | Pillar 4 Update Story |
| T036-T042 | US4, US5 | FR-024 through FR-032 | Pillar 5 Publishing Workflow |
| T050-T056 | US1-US5 | SC-001 through SC-006 | Final Validation |

---

## Next Steps After Tasks Complete

1. **Feature Closeout**: Follow Rule 15 sequence — version bump in .specrew/config.yml, tag (e.g., v0.21.0), push tag to trigger publish workflow, create PR for feature branch merge
2. **PSGallery Verification**: After first publish, verify module appears on PSGallery via Find-Module Specrew -AllVersions
3. **Documentation Update**: Update main README.md to add Install-Module Specrew as primary install path; preserve clone-and-PATH instructions for existing users
4. **Feedback Collection**: Monitor GitHub issues and feedback channels for onboarding friction reports related to module install/init/update workflows

---

**Generated**: 2026-05-16  
**Next Boundary**: `/speckit.implement` (after explicit authorization)
