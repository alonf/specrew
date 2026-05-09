# Tasks: Project Path Resolution in Specrew Entry-Point Scripts

**Input**: Design documents from `C:\Dev\Specrew\specs\009-project-path-resolution\`  
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts\cli-path-resolution.md`  
**Tests**: Use the repository's existing PowerShell integration and governance lanes plus the new deterministic regression lane required by this feature.  
**Scope Boundary**: Keep the slice bounded to helper adoption, the audited internal scripts, deterministic regression coverage, the static anti-pattern scan, known-traps seeding/reapplication, and preserving the existing CLI/error-message contract.

## Format: `[ID] [P?] [Story?] [Owner] [Effort] Description`

- **[P]**: Can run in parallel once dependencies are satisfied
- **[Story?]**: Present only for user-story work as `[US1]`, `[US2]`, or `[US3]`
- **[Owner]**: Primary execution owner aligned to the Specrew baseline roles
- **[Effort]**: Relative effort estimate (`S`, `M`, `L`)
- Every task names concrete files and records requirement traceability; no orphan work is allowed in scope

## Phase 1: Setup and Audit Baseline

**Purpose**: Confirm the bounded audit scope, preserve the approved helper direction, and verify the pre-change validation baseline.

- [X] T001 [Owner: Planner] [Effort: S] Review `extensions\specrew-speckit\scripts\shared-governance.ps1` and `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` to confirm the interim `Resolve-ProjectPath` helper remains the canonical FR-001 implementation with rooted-path pass-through preserved. (Trace: FR-001, FR-004, TG-001)
- [X] T002 [P] [Owner: Planner] [Effort: S] Audit `scripts\specrew-start.ps1`, `scripts\specrew-update.ps1`, `scripts\specrew-init.ps1`, `scripts\specrew-team.ps1`, and `scripts\specrew-review.ps1` for user-supplied path resolution call sites and record the entry-point findings in `specs\009-project-path-resolution\research.md`. (Trace: FR-002, TG-001, TG-002)
- [X] T003 [P] [Owner: Planner] [Effort: M] Audit `extensions\specrew-speckit\scripts\resolve-quality-profile.ps1`, `run-hardening-gate.ps1`, `run-mechanical-checks.ps1`, and `validate-governance.ps1` for user-supplied relative-path handling and append the source-tree findings to `specs\009-project-path-resolution\research.md`. (Trace: FR-003, TG-002)
- [X] T004 [P] [Owner: Planner] [Effort: S] Verify the mirrored `.specify\extensions\specrew-speckit\scripts\` copies for the same audited scripts and record parity expectations in `specs\009-project-path-resolution\research.md` so source and deployed trees stay aligned. (Trace: FR-003, TG-002)
- [X] T005 [Owner: Reviewer] [Effort: M] Run the existing baseline validation commands from `specs\009-project-path-resolution\quickstart.md` step 6, excluding the not-yet-created regression lane, to confirm the current governance baseline is green before implementation starts. (Trace: FR-006, TG-005)

**Checkpoint**: Audit scope and baseline are explicit, helper preservation is confirmed, and the feature stays bounded to the approved defect model.

---

## Phase 2: User Story 1 - Entry-Point Scripts Respect PowerShell Working Directory (Priority: P1) 🎯 MVP

**Goal**: Every user-invoked entry point under `scripts\` resolves `-ProjectPath` against `(Get-Location).Path` while preserving the current CLI surface and user-visible error messages.

**Independent Test**: From PowerShell, `Set-Location` into a Specrew-managed project and run `.\scripts\specrew-start.ps1` or `.\scripts\specrew-update.ps1 --info` without an explicit rooted `-ProjectPath`; each command must resolve to the PowerShell location and proceed past the incorrect bootstrap/managed-project failure path.

- [X] T006 [US1] [Owner: Implementer] [Effort: M] Update `scripts\specrew-init.ps1` to replace raw `GetFullPath($ProjectPath)` resolution with `Resolve-ProjectPath` while preserving bootstrap behavior and existing error strings. (Trace: FR-002, FR-004, FR-005, TG-001, TG-005)
- [X] T007 [US1] [Owner: Implementer] [Effort: M] Update all five in-scope `ProjectPath` call sites in `scripts\specrew-team.ps1` to use the shared helper or an explicitly justified equivalent inline pattern that resolves relative paths against `(Get-Location).Path`. (Trace: FR-002, FR-004, FR-005, TG-001, TG-005)
- [X] T008 [US1] [Owner: Implementer] [Effort: M] Update `scripts\specrew-review.ps1` to adopt the shared helper for project-path resolution without changing its existing failure semantics. (Trace: FR-002, FR-004, FR-005, TG-001, TG-005)
- [X] T009 [P] [US1] [Owner: Reviewer] [Effort: S] Verify `scripts\specrew-start.ps1` and `scripts\specrew-update.ps1` already satisfy the shared-helper contract and record any "no change required" evidence in `specs\009-project-path-resolution\research.md` so the full five-entry-point audit is complete. (Trace: FR-001, FR-002, TG-001, TG-005)

**Checkpoint**: All five entry-point scripts are covered by the helper contract, and the canonical "cd into project, run Specrew command" workflow is preserved.

---

## Phase 3: User Story 2 - Internal Script Path Resolution Stays Consistent (Priority: P1)

**Goal**: Every audited internal script in both the source extension tree and the mirrored `.specify` tree resolves user-supplied relative paths consistently, eliminating recurrence traps outside the entry points.

**Independent Test**: Run each in-scope script family with representative relative path inputs from a non-startup PowerShell directory and verify the effective resolution matches `(Get-Location).Path`, not `.NET CurrentDirectory`.

- [X] T010 [US2] [Owner: Implementer] [Effort: M] Update `extensions\specrew-speckit\scripts\resolve-quality-profile.ps1` so `ProjectPath`, `FeaturePath`, and `SpecPath` resolution follows the shared helper contract. (Trace: FR-003, FR-004, TG-002)
- [X] T011 [US2] [Owner: Implementer] [Effort: M] Update `extensions\specrew-speckit\scripts\run-hardening-gate.ps1` so `ProjectPath`, `FeaturePath`, `IterationPath`, and `SpecPath` resolve relative inputs against `(Get-Location).Path`. (Trace: FR-003, FR-004, TG-002)
- [X] T012 [US2] [Owner: Implementer] [Effort: M] Update `extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` so `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath`, and `DispositionPath` use the shared helper or an equivalent inline pattern. (Trace: FR-003, FR-004, TG-002)
- [X] T013 [US2] [Owner: Implementer] [Effort: M] Update `extensions\specrew-speckit\scripts\validate-governance.ps1` anywhere user-supplied project/spec/iteration paths are normalized so relative inputs resolve consistently with the rest of the audited governance scripts. (Trace: FR-003, FR-004, TG-002, TG-005)
- [X] T014 [P] [US2] [Owner: Implementer] [Effort: M] Mirror the Phase 3 path-resolution changes into `.specify\extensions\specrew-speckit\scripts\resolve-quality-profile.ps1`, `run-hardening-gate.ps1`, `run-mechanical-checks.ps1`, and `validate-governance.ps1` to preserve deployment parity. (Trace: FR-003, TG-002, TG-005)
- [X] T026 [P] [US2] [Owner: Implementer] [Effort: M] Extend the internal audit fix to `brownfield-merge.ps1`, `deploy-speckit-extension.ps1`, `deploy-squad-runtime.ps1`, `drift-diff.ps1`, `scaffold-governance.ps1`, and `scaffold-iteration-plan.ps1`, plus mirrored `.specify` copies, so all user-supplied path parameters resolve via `Resolve-ProjectPath`. (Trace: FR-003, FR-004, TG-002, TG-005)
- [X] T015 [P] [US2] [Owner: Planner] [Effort: S] Update `specs\009-project-path-resolution\research.md` with the final migration matrix listing every audited call site, the adopted resolution method, and any residual exemption candidates that must also be recorded in `.specrew\quality\known-traps.md` before closure. (Trace: FR-003, FR-008, TG-002, TG-004)

**Checkpoint**: Both extension trees are aligned, the audit matrix is explicit, and no in-scope internal path-handling flow is left on the historical broken idiom without documented justification.

---

## Phase 4: User Story 3 - Deterministic Regression and Static Audit Coverage (Priority: P2)

**Goal**: Add a deterministic regression lane that reproduces the PowerShell-vs-.NET working-directory split and a static scan that fails on future reintroduction of the broken pattern.

**Independent Test**: Run `pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1` with `.NET CurrentDirectory` forced away from the project and confirm the lane exits zero only when the audited entry points and static scan both pass.

- [X] T016 [US3] [Owner: Reviewer] [Effort: M] Create `tests\integration\project-path-resolution-regression.ps1` to set `[Environment]::CurrentDirectory` away from the project, `Set-Location` into a Specrew-managed fixture or repo root, invoke representative entry points with `-ProjectPath '.'` and default-path behavior, and assert they resolve to the PowerShell working directory. (Trace: FR-006, TG-003)
- [X] T017 [US3] [Owner: Reviewer] [Effort: S] Add the static anti-pattern scan to `tests\integration\project-path-resolution-regression.ps1` so raw `GetFullPath($ProjectPath/$FeaturePath/$SpecPath/$IterationPath/$DispositionPath)` findings outside approved helper/equivalent locations fail with remediation guidance pointing to `Resolve-ProjectPath`. (Trace: FR-007, TG-003)
- [X] T018 [P] [US3] [Owner: Reviewer] [Effort: S] Run `tests\integration\project-path-resolution-regression.ps1` after the US1/US2 migrations land and capture the zero-exit expectation in `specs\009-project-path-resolution\quickstart.md` as the required regression proof for this feature. (Trace: FR-006, FR-007, TG-003)

**Checkpoint**: The bug is reproducibly guarded both behaviorally and mechanically, and the feature has a deterministic regression signal.

---

## Phase 5: Known-Traps Corpus Seeding and Reapplication

**Purpose**: Convert the discovered defect into reusable governance memory before feature closure.

- [X] T019 [Owner: Reviewer] [Effort: S] Create `.specrew\quality\known-traps.md` if absent and seed the feature-009 `path-resolution` trap entry scaffold in the repository corpus. (Trace: FR-008, TG-004)
- [X] T020 [Owner: Reviewer] [Effort: S] Populate the `path-resolution` trap entry in `.specrew\quality\known-traps.md` with the broken pattern example, detection method, remediation guidance, discovery date `2026-05-09`, and any surviving exemption rationale required by SC-002. (Trace: FR-008, TG-004)
- [X] T021 [Owner: Reviewer] [Effort: S] Create `specs\009-project-path-resolution\quality\trap-reapplication.md` documenting the reapplication scan command, the current findings, and confirmation that the trap was re-run before closure. (Trace: FR-008, TG-004)

**Checkpoint**: The path-resolution bug is recorded in the shared trap corpus and reapplication evidence exists for this feature.

---

## Phase 6: Validation and Closure Readiness

**Purpose**: Re-run the required validation path and confirm the bounded fix remains additive to the existing CLI/governance contract.

- [X] T022 [Owner: Reviewer] [Effort: M] Run the full validation suite from `specs\009-project-path-resolution\quickstart.md` step 6, including `tests\integration\project-path-resolution-regression.ps1`, and confirm the existing governance lanes remain green. (Trace: FR-006, FR-007, TG-005)
- [X] T023 [P] [Owner: Reviewer] [Effort: S] Verify against `specs\009-project-path-resolution\contracts\cli-path-resolution.md` that the migrated entry points still emit the existing `Project path does not exist`, `Project is not Specrew-managed`, and `Project is not fully bootstrapped` messages verbatim, with only corrected absolute paths changing. (Trace: FR-005, TG-005)
- [X] T024 [P] [Owner: Reviewer] [Effort: S] Exercise the required edge cases across the migrated scripts and `tests\integration\project-path-resolution-regression.ps1`: explicit absolute paths, UNC paths, missing relative paths, and wrapper-driven `pwsh -File` invocation without a prior `Set-Location`. (Trace: FR-004, FR-005, TG-005)
- [X] T025 [P] [Owner: Reviewer] [Effort: S] Verify the parameter blocks and documented usage in `scripts\specrew-start.ps1`, `scripts\specrew-update.ps1`, `scripts\specrew-init.ps1`, `scripts\specrew-team.ps1`, and `scripts\specrew-review.ps1` remain unchanged apart from corrected path resolution. (Trace: FR-002, FR-005, TG-005)

**Checkpoint**: Validation is green, compatibility is preserved, and closure evidence is explicit and reviewable through the regression, trap-reapplication, quickstart, and research artifacts.

---

## Dependencies & Execution Order

### Phase Dependencies

1. **Phase 1** establishes the helper/audit baseline and must complete first.
2. **Phase 2** fixes the user-visible entry points and is the MVP path.
3. **Phase 3** extends the same resolution contract through the internal governance surfaces and mirrored `.specify` copies.
4. **Phase 4** adds deterministic regression/static-scan protection after the audited migrations exist.
5. **Phase 5** seeds and reapplies the known-traps corpus after the defect pattern is fully characterized.
6. **Phase 6** closes the feature by re-running the required validation path and confirming the existing feature artifacts capture closure evidence.

### User Story Dependencies

- **US1** depends on Phase 1 only.
- **US2** depends on Phase 1 and should land after the entry-point contract is stable.
- **US3** depends on completed US1 and US2 migrations so the regression lane validates the final audited behavior.

### Parallel Opportunities

- T002-T004 can run in parallel after T001 starts.
- T006-T009 are parallel-safe once the Phase 1 audit baseline exists.
- T010-T014 are parallel-safe by file family; T015 follows them to finalize the migration matrix.
- T019-T021 can run after T016-T018 establish the regression/static-scan evidence.
- T023-T025 can run in parallel after T022 starts.

## Implementation Strategy

### MVP First

1. Complete Phase 1 to lock the bounded audit scope and baseline.
2. Complete Phase 2 so the canonical user workflow is repaired.
3. Complete Phase 3 so internal governance scripts and the mirrored `.specify` tree cannot silently diverge.
4. Add Phase 4 regression/static-scan protection.
5. Finish with Phase 5 trap seeding and Phase 6 validation/closure evidence.

### Planning Notes

- Do **not** widen this slice into repo-wide `GetFullPath` cleanup outside the audited defect model.
- Treat `specs\009-project-path-resolution\research.md` as the auditable migration matrix for the internal-script scope.
- Keep feature 009 ahead of feature 008 until the regression lane, trap entry, and validation suite are all green.

## Traceability Matrix

| Task ID | Primary Requirement(s) | Key Artifact(s) |
| --- | --- | --- |
| T001-T005 | FR-001, FR-002, FR-003, FR-004, FR-006, TG-001, TG-002, TG-005 | `shared-governance.ps1`, `research.md`, baseline validation commands |
| T006-T009 | FR-001, FR-002, FR-004, FR-005, TG-001, TG-005 | `scripts\specrew-*.ps1`, `research.md` |
| T010-T015 | FR-003, FR-004, TG-002, TG-005 | `extensions\specrew-speckit\scripts\*.ps1`, `.specify\extensions\specrew-speckit\scripts\*.ps1`, `research.md` |
| T016-T018 | FR-006, FR-007, TG-003 | `tests\integration\project-path-resolution-regression.ps1`, `quickstart.md` |
| T019-T021 | FR-008, TG-004 | `.specrew\quality\known-traps.md`, `specs\009-project-path-resolution\quality\trap-reapplication.md` |
| T022-T025 | FR-002, FR-004, FR-005, FR-006, FR-007, TG-005 | validation commands, `contracts\cli-path-resolution.md`, `scripts\specrew-*.ps1` |

## Success Criteria Coverage

| Success Criterion | Planned Proof |
| --- | --- |
| SC-001 | T006-T009 plus T024 validate entry-point resolution from the PowerShell working directory |
| SC-002 | T002-T004, T010-T015, and T019-T020 maintain the audited call-site matrix and record any explicit exemptions in the trap corpus |
| SC-003 | T016-T018 and T022 provide the deterministic regression and zero-finding static scan proof |
| SC-004 | T019-T021 seed the trap corpus and record reapplication evidence |
| SC-005 | T016, T022, and T023 confirm no entry point reports a false unrelated-path bootstrap/managed-project failure |
