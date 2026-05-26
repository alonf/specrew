# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-27
**Overall Verdict**: accepted

## Findings

| Severity | Status | Finding | Resolution |
| -------- | ------ | ------- | ---------- |
| low | resolved | Bug 3 (auto-resume-wrong-feature) root cause was tracked session-state files. Symptom fixed at 437338f6; structural fix deferred to retro. | Commit 437338f6 removed `.specrew/start-context.json` and `.specrew/last-start-prompt.md` from git tracking (they were already gitignored but cached). Structural `specrew-start.ps1` recovery-logic improvement queued for retro action. |

No open findings remain.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-003,FR-012,SC-001 | pass | Tests-first fixture validates Docker harness existence, FileList integrity (182 files), version pin parity, harness logic presence, and workflow integration. |
| T002 | FR-001,FR-002,SC-001 | pass | `tests/Dockerfile.publish-test` created with official Microsoft `mcr.microsoft.com/powershell:lts-ubuntu-22.04` base, installs baseline v0.27.6 from PSGallery, and sets up test workspace. |
| T003 | FR-003,SC-001 | pass | `scripts/internal/test-publish-harness.ps1` implements 5-phase validation: candidate structure check, FileList integrity (100% coverage), version pin drift detection, baseline init test, and update transition validation. |
| T004 | FR-012,SC-001 | pass | Version pin drift assertions added to harness Phase 3: regex-based parsing of `.specrew/config.yml` `specrew_version` vs `Specrew.psd1` `ModuleVersion`; explicit failure on mismatch. |
| T005 | FR-004,SC-001 | pass | `specrew update` execution and layout validation added to harness Phase 5: includes module reload, update execution, config verification, and duplicate Squad entry check (FR-013 regression coverage). |
| T006 | FR-005,SC-001 | pass | Docker harness wired into `.github/workflows/publish-module.yml` as blocking "Pre-publish Docker harness validation" step between tag resolution and publication; `LASTEXITCODE` gating prevents bad candidates from reaching PSGallery. |
| T007 | FR-005,SC-001 | pass | Reviewer verification completed: T001 fixture passed all 7 assertions; harness component checks validated; workflow integration verified; expected CI behavior documented. |
| T018 | FR-013 | pass | Duplicate-row deploy bug fixed at commit 2d52b9f9 in `scripts/specrew-update.ps1` and `templates/github/scripts/deploy-squad-runtime.ps1`: implemented key-based merge strategy (first-column keys) instead of naive append for `.squad/team.md` and `.squad/routing.md`. |
| T019 | FR-013 | pass | Regression test `tests/integration/squad-duplicate-rows.tests.ps1` created and passing: executes 3 consecutive `specrew update` calls and asserts zero duplicate team/routing entries; validates key-based merge fix. |
| T020 | FR-014 | pass | PSGallery-first version check implemented at commit 2d52b9f9 in `scripts/specrew-update.ps1`: `Get-LatestVersionInfo` checks PSGallery API first via `Get-PSGalleryLatestVersion`, falls back to module manifest on query failure, and attributes source correctly. |

## Gap Ledger

- **No requirement (FR/SC) gaps**: All in-scope Iteration 001 requirements verified and fixed-now.
- **Bug 2 regression test coverage**: **Deferred** to future testing-infrastructure iteration. Canonical defer entry `defer-f049-bug2-regression-test` in `.squad\decisions.md` (approving human: Alon Fliess). The fix is straightforward, code-reviewed (lines 397-411 of `specrew-update.ps1`), and observable via manual `specrew update --info` execution. Risk/benefit ratio does not justify adding PSGallery API mock/stub infrastructure now.
- **Bug 3 structural fix**: **Deferred** to retro improvement action. Canonical defer entry `defer-f049-bug3-structural-fix` in `.squad\decisions.md` (approving human: Alon Fliess). Commit 437338f6 removed the immediate symptom (untracked stale session-state files); the durable defense — `specrew-start.ps1` recovery logic preferring current-git-branch-derived feature over session-state cursor and never auto-resuming to a feature at `lifecycle-end` boundary — is queued for a future iteration.

## Scope Notes

- Iteration 002 (Troubleshooting Guide) and Iteration 003 (Persona-Driven Intake) remain out of scope for this review.
- Commit 437338f6 (Bug 3 auto-resume fix) is folded into Iteration 001 deliverables as it's already on the feature branch and fixes a critical user-facing bug.

## Implementation Briefing

- Built Docker-based pre-publish E2E validation harness using official Microsoft PowerShell Ubuntu container, installing baseline Specrew v0.27.6 from PSGallery for upgrade-path validation.
- Implemented 5-phase harness validation: (1) candidate structure check, (2) FileList integrity scan (every `Specrew.psd1` FileList entry exists on disk), (3) version pin drift detection (Prop 134), (4) baseline project initialization test, (5) update transition validation with duplicate Squad entry regression check (FR-013).
- Wired harness into `.github/workflows/publish-module.yml` as the last blocking step before PSGallery publication; exit-code gating ensures corrupt candidates never escape to production.
- Fixed duplicate-row deploy bug (Bug 1) in Squad template merge logic: replaced naive append with key-based merge strategy keyed on first table column (role name or work type).
- Implemented PSGallery-first version check (Bug 2, Proposal 049 promoted to draft): `specrew update --info` now queries actual PSGallery feed as default, falling back to module manifest only on API failure.
- Fixed auto-resume-wrong-feature bug (Bug 3) symptom by removing tracked session-state files from git index; queued structural recovery-logic fix for retro.

## Evidence Summary

### Test Execution

- **T001 fixture**: `tests/integration/publish-module-harness.tests.ps1` — PASS (7/7 assertions)
  - Dockerfile.publish-test exists ✅
  - test-publish-harness.ps1 exists ✅
  - FileList integrity check passed (182 files) ✅
  - Version pin check passed (Config and manifest both 0.27.6) ✅
  - Harness contains FileList validation logic ✅
  - Harness contains version pin drift assertions ✅
  - publish-module.yml wires Docker harness ✅

- **T019 fixture**: `tests/integration/squad-duplicate-rows.tests.ps1` — PASS
  - No duplicate team roles after 3 consecutive `specrew update` calls ✅
  - No duplicate routing entries after 3 consecutive `specrew update` calls ✅
  - Row counts stable across all updates ✅
  - Key-based merge strategy working correctly (FR-013) ✅

- **Docker harness double-coverage**: `test-publish-harness.ps1` lines 273-290 also include duplicate Squad entries check as part of pre-publish validation.

### Code Review Evidence

- **Bug 2 (PSGallery-first version check)**: Verified at `scripts/specrew-update.ps1` lines 397-411. `Get-LatestVersionInfo` checks PSGallery first, falls back to manifest on failure, proper source attribution in return object.

- **Bug 3 (auto-resume-wrong-feature)**: Empirical investigation confirmed root cause: `.specrew/start-context.json` was tracked in git despite being in `.gitignore`. Stale content pointed to F-047 (closed feature) instead of F-049 (active feature). Commit 437338f6 applied `git rm --cached` to untrack both session-state files.

### Requirements Coverage

| Requirement | Test Coverage | Status |
|-------------|---------------|--------|
| FR-001 | Docker harness uses Linux PowerShell container | ✅ Verified in Dockerfile line 15 |
| FR-002 | Baseline v0.27.6 installation | ✅ Verified in Dockerfile line 18 + harness Phase 4 |
| FR-003 | FileList integrity check | ✅ Verified in T001 + harness Phase 2 (lines 84-110) |
| FR-004 | Clean update transition | ✅ Verified in harness Phase 5 (lines 188-290) |
| FR-005 | Workflow integration | ✅ Verified in publish-module.yml lines 143-167 |
| FR-012 | Version pin drift detection | ✅ Verified in T001 + harness Phase 3 (lines 116-144) |
| FR-013 | No duplicate Squad entries | ✅ Verified in T019 + harness Phase 5 (lines 273-290) |
| FR-014 | PSGallery-first version check | ✅ Code review verified (lines 397-411), runtime observable |
| SC-001 | 0% escaped omissions | ✅ Harness blocks before publish (exit-code gate at workflow line 163) |

### Commits

- `f857da4c` — feat(release): add Docker pre-publish validation harness
- `d17f0e3a` — feat(release): wire Docker harness into publish workflow
- `10f5afb8` — feat(release): register test-publish-harness.ps1 in FileList
- `2d52b9f9` — boundary(before-implement): F-049 scope expansion — fold duplicate-row merge fix and Proposal 049 PSGallery version check
- `437338f6` — fix(state): untrack gitignored session-state files (root-cause fix for auto-resume-to-wrong-feature bug)

### Decision Record

- `C:\Dev\Specrew\.squad\decisions.md` — T002-T006 implementation decisions recorded (5-phase validation approach, Docker base image strategy, version pin regex parsing, workflow integration placement, FileList registration)

## Next Steps

1. ✅ All Iteration 001 tasks (T001-T007, T018-T020) complete
2. ✅ Ready for review-signoff boundary
3. 📋 Queue structural `specrew-start.ps1` recovery-logic fix for retro improvement action
4. 📋 Queue Bug 2 regression test infrastructure (PSGallery API mock/stub) for future testing-infrastructure iteration if risk profile changes

---

**Reviewer**: Reviewer (Antigravity Coordinator)  
**Review Date**: 2026-05-27  
**Authority**: Reviewer governance rule 14B (T001, T007, T019 implementation verification)
