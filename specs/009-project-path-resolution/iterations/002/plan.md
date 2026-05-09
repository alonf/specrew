# Iteration Plan: 002

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: complete  
**Capacity**: 4/20 story_points  
**Started**: 2026-05-10  
**Completed**: 2026-05-10  

## Summary

Iteration 002 closes the FR-003 audit gap by migrating the two manual test harnesses to `Resolve-ProjectPath`, documenting the process-scorer exemption, and extending static scan coverage to the three audit targets.

**Approval**: Explicit human execution approval recorded: `I am explicitly authorizing the work below; do all of it in this same session without asking for additional approvals beyond the explicit human checkpoints named below.`

---

## User Story Mapping

This iteration closes the remaining FR-003 audit gaps identified during Phase 1 feature research. The research matrix in `specs/009-project-path-resolution/research.md` documented two mandatory migrations and one exemption candidate.

### US-1: Migrate Test Entry Points to `Resolve-ProjectPath` (FR-003)

**Goal**: Two test/evaluation scripts that accept `-ProjectPath` relative paths and use raw `GetFullPath` must adopt the shared helper to match entry-point parity.

**Success Criteria**:
- `tests/manual/copilot-squad-smoke.ps1` resolves `-ProjectPath` via `Resolve-ProjectPath` imported from shared helper
- `tests/manual/copilot-squad-confidence-lane.ps1` resolves `-ProjectPath` via `Resolve-ProjectPath` imported from shared helper
- Both scripts retain existing parameter names, CLI surface, and error-message contract
- Static-scan finds no residual raw `GetFullPath` usage on the audited path parameters in these files

**Tasks**:
- [T001] Audit `tests/manual/copilot-squad-smoke.ps1` for GetFullPath usage and import/adopt `Resolve-ProjectPath` helper
- [T002] Audit `tests/manual/copilot-squad-confidence-lane.ps1` for GetFullPath usage and import/adopt `Resolve-ProjectPath` helper
- [T003] Verify both scripts preserve CLI parameter contract and error semantics

### US-2: Document Exemption for `evaluation/scorers/process-scorer.ps1` (FR-003, TG-002)

**Goal**: Audit the third candidate file and record whether it meets migration criteria or should remain as an exemption.

**Rationale**: The scope constraint specifies "migrate only if the parameter is truly a user-supplied relative path." The process-scorer has `$ProjectPath = (Get-Location).Path` (already resolved default) and uses `Resolve-Path` (not `GetFullPath`) for the main path parameter, so it does not meet the defect criteria. An exemption entry should explain why.

**Success Criteria**:
- Audit confirms `$ProjectPath` uses `Resolve-Path` (safe semantics) not raw `GetFullPath`
- `$ReportPath` and other GetFullPath calls are on computed paths, not raw user input
- Exemption entry recorded in `.specrew/quality/known-traps.md` and `specs/009-project-path-resolution/research.md` research update
- Static-scan target list extended to include all three files (smoke, confidence-lane, process-scorer) to detect any future reintroduction

**Tasks**:
- [T004] Analyze `evaluation/scorers/process-scorer.ps1` parameter handling and usage of GetFullPath
- [T005] Record exemption justification in `.specrew/quality/known-traps.md`
- [T006] Update research.md audit matrix with migration decision

### US-3: Extend Static-Scan Coverage (FR-007, TG-003)

**Goal**: Add the three test/evaluation files to the deterministic anti-pattern scan in `tests/integration/project-path-resolution-regression.ps1` so future reintroduction of raw `GetFullPath(${ProjectPath})` is caught mechanically.

**Success Criteria**:
- `$scanTargets` array includes all three files
- Regression test runs zero-exit after migrations and scan additions
- Static-scan proves no remaining raw `GetFullPath($ProjectPath/...)` patterns exist in any in-scope file

**Tasks**:
- [T007] Extend `$scanTargets` list in project-path-resolution-regression.ps1 to include:
  - `tests/manual/copilot-squad-smoke.ps1`
  - `tests/manual/copilot-squad-confidence-lane.ps1`
  - `evaluation/scorers/process-scorer.ps1` (for exemption verification)
- [T008] Run regression test after migrations and verify zero findings and zero-exit status

---

## Dependency and Sequencing

**Pre-requisites**:
- Feature 009 Phase 1 research and audit baseline are green
- `extensions/specrew-speckit/scripts/shared-governance.ps1` contains the canonical `Resolve-ProjectPath` helper
- `.specrew/quality/known-traps.md` exists (created during feature 009 Phase 5)

**Execution Order**:
1. T001-T002: Migrate the two scripts in parallel (US-1)
2. T003: Verify CLI contract preservation (US-1)
3. T004-T006: Audit and document exemption (US-2)
4. T007: Extend static-scan targets (US-3)
5. T008: Run regression test to close the gap (US-3)

**Parallel Opportunities**:
- T001 and T002 are independent and can run in parallel
- T004 can run in parallel with T001-T002 (independent audit)
- T007 can proceed as soon as T001-T002 are ready for validation

**Blocking Gates**:
- T008 (regression test) must run after T001-T002 complete so the test can verify zero findings

---

## Success Metrics

| Metric | Evidence | Target |
| --- | --- | --- |
| Migration coverage | T001-T002: `Resolve-ProjectPath` adopted in both scripts | 100% adoption |
| Exemption clarity | T005-T006: Documented in known-traps and research.md | Explicit decision recorded |
| Static-scan coverage | T007-T008: Three files added to `$scanTargets` | All three files in scope list |
| Regression validation | T008: Zero-exit regression test | Clean exit code 0 |
| CLI stability | T003: Parameter names and errors unchanged | No breaking changes |

---

## Known Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Scripts have additional path parameters not yet identified | Low | Incomplete migration | T001-T002 include full script audit for all GetFullPath usage on user-supplied paths |
| Static-scan over-matches on benign GetFullPath usage outside user-supplied paths | Low | False positives in regression test | Scan rule limited to exact pattern: `[System.IO.Path]::GetFullPath($ProjectPath\|FeaturePath\|SpecPath\|IterationPath\|DispositionPath)` |
| Exemption rationale challenged in review | Low | Review block | T005-T006 document clear criteria: user-supplied + relative + broken idiom required for migration |

---

## Deferred to Later Work

- **Feature 005 Mechanical-Lens Catalog**: Optional mapping of anti-pattern to broader lens catalog remains deferred per feature 009 plan; Iteration 002 scope does not reopen this decision.
- **Cross-platform Ergonomics**: Beyond shared helper existing rooted-path handling remain deferred.
- **Repository-Wide GetFullPath Cleanup**: Out of scope; this slice stays within the audited path-parameter defect model.

---

## Files Affected

| File | Change Type | Rationale |
| --- | --- | --- |
| `tests/manual/copilot-squad-smoke.ps1` | Migrate `$ProjectPath` to use `Resolve-ProjectPath` | T001: Closure of FR-003 audit gap |
| `tests/manual/copilot-squad-confidence-lane.ps1` | Migrate `$ProjectPath` to use `Resolve-ProjectPath` | T002: Closure of FR-003 audit gap |
| `evaluation/scorers/process-scorer.ps1` | Audit only; document exemption | T004-T006: Verify no defect present; record rationale |
| `tests/integration/project-path-resolution-regression.ps1` | Extend `$scanTargets` array | T007-T008: Add three files to deterministic anti-pattern scan |
| `.specrew/quality/known-traps.md` | Document exemption entry | T005: Record why process-scorer does not require migration |
| `specs/009-project-path-resolution/research.md` | Update audit matrix | T006: Post-migration decision artifact |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-0201 | Migrate smoke harness `ProjectPath` resolution | FR-003 | US-1 | 1 | Implementer | done | copilot-cli | 1 | pass |
| T-0202 | Migrate confidence lane `ProjectPath` resolution | FR-003 | US-1 | 1 | Implementer | done | copilot-cli | 1 | pass |
| T-0203 | Verify manual harness CLI contract and error behavior | FR-003 | US-1 | 0.5 | Implementer | done | copilot-cli | 0.5 | pass |
| T-0204 | Audit process-scorer path handling for exemption criteria | FR-003 | US-2 | 0.5 | Implementer | done | copilot-cli | 0.5 | pass |
| T-0205 | Record process-scorer exemption in known-traps | FR-003 | US-2 | 0.25 | Implementer | done | copilot-cli | 0.25 | pass |
| T-0206 | Update research audit matrix with exemption decision | FR-003 | US-2 | 0.25 | Implementer | done | copilot-cli | 0.25 | pass |
| T-0207 | Extend regression static-scan targets | FR-007 | US-3 | 0.25 | Implementer | done | copilot-cli | 0.25 | pass |
| T-0208 | Run regression + validation lanes | FR-007 | US-3 | 0.25 | Implementer | done | copilot-cli | 0.25 | pass |

**Planned Total**: 4 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Keep the slice fixed to the three-file audit-gap scope. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 4/20. |
| Defer Strategy | manual | If additional audit gaps emerge, plan a new iteration instead of widening this slice. |
| Calibration Enabled | true | Retro should confirm audit-gap work stayed within estimate. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.5 | Confirm scope, exemption criteria, and static-scan extension plan |
| Implementation | 2.5 | Migrate two scripts, document exemption, and update regression targets |
| Review | 0.5 | Validate regression output and document review evidence |
| Rework | 0.5 | Reserve time for any remediation identified during review |

---

## Validation Commands

```powershell
# After T001-T002 migrations, verify no CLI breakage
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\manual\copilot-squad-smoke.ps1 -ProjectPath '.' -KeepProject
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\manual\copilot-squad-confidence-lane.ps1 -ProjectPath '.'

# After T007-T008 completion, run regression test
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1

# Verify static scan finds no findings
Select-String -Path .\tests\integration\project-path-resolution-regression.ps1 -Pattern '\[System\.IO\.Path\]::GetFullPath\(\s*\$(ProjectPath|FeaturePath|SpecPath|IterationPath|DispositionPath)\s*\)' | ? { $_.Path -in @('tests/manual/copilot-squad-smoke.ps1','tests/manual/copilot-squad-confidence-lane.ps1','evaluation/scorers/process-scorer.ps1') }
```

---

## Governance Checkpoints

- **Planner**: Scope bounded to FR-003 audit gap items named by user; execution readiness confirmed
- **Reviewer**: Will validate that migrations preserve CLI contract and exemption is justified
- **Implementer**: Will execute migrations, run regression test, and update artifacts
- **Feature owner** (`Spec Steward`): Closure gates on zero-finding regression test + exemption recorded

---

**Created**: 2026-05-09 | **Planner**: Planner | **Next Review**: Post-implementation evidence review after the recorded execution approval is exercised
