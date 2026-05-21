---
description: "Actionable tasks for Baseline Hygiene (Feature 029) - Session-Loaded File Change Detection"
---

# Tasks: Baseline Hygiene for Session-Loaded File Change Detection (Feature 029)

**Feature**: 029-baseline-hygiene  
**Iteration**: 001  
**Scope**: Fix false-positive F-011 pause-and-confirm prompts by refreshing `baseline_commit_hash` at each lifecycle boundary  
**Capacity**: 3.6 story points (reduced scope: E1 validation-only)  
**Planned Effort**: ~3.6 story points  

---

## Overview

This iteration delivers two focused enhancements (E1 & E2) to eliminate false-positive misfires in F-011 (Conditional Pause on specrew-start When Session-Loaded Files Changed):

- **E1 (Feature-Closeout Invalidation, P2)**: Validate that `.specrew/last-start-prompt.md` is marked inactive at feature-closeout (already implemented; confirmation and testing added)
- **E2 (Boundary-Based Baseline Updates, P1)**: Implement and validate baseline update mechanism that refreshes `baseline_commit_hash` to current HEAD at each of the seven lifecycle boundaries

**User Stories**:
- **US-1** (P1): Lifecycle baseline hygiene — baseline updated at each boundary, no false positives across full feature lifecycle
- **US-2** (P1): Out-of-band user changes still trigger pause correctly — genuine changes are still detected after baseline updates
- **US-3** (P2): Feature-closeout clears session state — closed features do not resume

**Success Criteria**:
- SC-001: Zero false positives across 5+ lifecycle boundaries with Squad commits at each
- SC-002: Genuine out-of-band user changes to session-loaded files are correctly detected
- SC-003: Feature-closeout invalidates session; next `specrew start` does not resume closed feature
- SC-004: All test cases pass; no regressions to existing F-011 behavior

---

## Tasks (11 Total)

### T001: Verify Implementation Context (0.5 SP)

**Objective**: Establish baseline understanding of current implementation and prepare environment.

**Acceptance Criteria**:
- [ ] Review `scripts/internal/sync-boundary-state.ps1` lines 601–690 to understand boundary-sync flow
- [ ] Review `scripts/specrew-start.ps1` functions `Get-BaselineCommitHash` (line 2466) and `Test-SessionLoadedFilesChanged` (line 2492); confirm no changes needed
- [ ] Review `.specrew/last-start-prompt.md` frontmatter schema; confirm baseline_commit_hash, session_state_active, session_state_boundary, session_state_recorded_at fields match spec
- [ ] Confirm E1 already implemented: verify `New-SpecrewSessionState` returns `active: 'false'` when `$BoundaryType -eq 'feature-closeout'` at line 251 in sync-boundary-state.ps1
- [ ] Verify git environment ready; can run `git rev-parse HEAD` successfully

**Owner**: Implementer  
**Trace**: FR-001–FR-006, spec.md "Key Entities", "Implementation Notes"

---

### T002: Implement `Update-BaselineCommitHashInFrontmatter` Helper (1 SP)

**Objective**: Create the core baseline update mechanism.

**Acceptance Criteria**:
- [ ] Create helper function in `scripts/internal/sync-boundary-state.ps1` that:
  - Accepts parameters: `$ProjectRoot`, `$PromptPath`, `$NewBaselineHash`
  - Reads existing `.specrew/last-start-prompt.md` frontmatter
  - Updates `baseline_commit_hash` field to new value
  - Preserves all other frontmatter fields unchanged
  - Reconstructs markdown using existing helper functions
  - Writes atomically with proper error handling
- [ ] Integrate baseline update into `Invoke-SpecrewBoundaryStateSync` (after `Update-SpecrewMarkdownStateFile` call)
- [ ] Resolve current HEAD: `$newBaseline = git rev-parse HEAD` with error handling
- [ ] Add error handling:
  - Catch `git rev-parse HEAD` failures → log warning, continue boundary-sync (best-effort)
  - Catch file write failures → log error, propagate (fatal)
- [ ] Test idempotency: re-running at same boundary with same HEAD produces same baseline

**Owner**: Implementer  
**Trace**: FR-001, FR-002, FR-006

---

### T003: Implement Unit Tests for Baseline Update (0.3 SP)

**Objective**: Validate baseline update function behavior at the unit level.

**Acceptance Criteria**:
- [ ] **UT-001**: Test `Update-BaselineCommitHashInFrontmatter`:
  - Create `.specrew/last-start-prompt.md` with existing frontmatter
  - Call function with new baseline hash
  - Verify baseline_commit_hash updated; all other fields preserved; body unchanged
  - Verify file is valid YAML + Markdown
- [ ] **UT-002**: Test `Get-BaselineCommitHash` robustness:
  - Valid 40-char hash → returns hash
  - Missing field → returns `$null`
  - Invalid format → returns `$null`
  - Malformed YAML → returns `$null`
- [ ] **UT-003**: Test session state validity at feature-closeout:
  - Call boundary-sync at feature-closeout
  - Verify `session_state_active: false` in .specrew/last-start-prompt.md
  - Verify `.specrew/start-context.json` has `session_state.active: false`

**Owner**: Reviewer  
**Trace**: FR-002, FR-003  
**Test Location**: `tests/integration/baseline-hygiene.tests.ps1`

---

### T004: Implement Integration Tests — Baseline Sequence Across Boundaries (0.3 SP)

**Objective**: Validate baseline updates at each of the 7 lifecycle boundaries.

**Acceptance Criteria**:
- [ ] **IT-001**: Test baseline update sequence:
  - Initialize test git repo with Specrew structure
  - Run `specrew start` at feature-start → capture baseline_V1 = current HEAD
  - For each of 6 remaining boundaries (clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout):
    - Simulate Squad boundary work (modify `.squad/agents/*/charter.md`, commit)
    - Call `Invoke-SpecrewBoundaryStateSync -BoundaryType '<boundary>'`
    - Verify `baseline_commit_hash` updated to post-boundary HEAD
    - Verify `session_state_boundary` reflects current boundary
  - Verify decisions.md contains baseline update entries

**Owner**: Reviewer  
**Trace**: FR-001, FR-002, SC-001  
**Test Location**: `tests/integration/baseline-hygiene-full-lifecycle.tests.ps1`

---

### T005: Implement Integration Tests — False-Positive Elimination (0.3 SP)

**Objective**: Validate that Squad's boundary work no longer triggers F-011's pause prompt.

**Acceptance Criteria**:
- [ ] **IT-002**: Test false-positive elimination:
  - After Squad boundary work and `Invoke-SpecrewBoundaryStateSync -BoundaryType 'clarify'`:
  - User runs `specrew start` (no new user changes)
  - Verify `Get-BaselineCommitHash` returns updated baseline
  - Run `git diff <updated-baseline>..HEAD` against watched globs
  - Verify result is EMPTY (no changes)
  - Verify pause-and-confirm prompt is NOT generated
- [ ] **IT-003**: Test genuine change detection:
  - After IT-002 completes (clarify boundary with updated baseline):
  - User intentionally modifies `.github/agents/squad.agent.md` and commits
  - User runs `specrew start`
  - Verify `Test-SessionLoadedFilesChanged` detects modification
  - Verify `git diff <baseline>..HEAD` includes modified file
  - Verify pause-and-confirm prompt IS generated with correct file list
- [ ] **IT-004**: Test idempotency:
  - Call `Invoke-SpecrewBoundaryStateSync -BoundaryType 'clarify'` twice (same boundary)
  - Verify baseline values match; all other fields preserved

**Owner**: Reviewer  
**Trace**: FR-001, FR-002, FR-004, SC-001, SC-002  
**Test Location**: `tests/integration/baseline-hygiene-full-lifecycle.tests.ps1`

---

### T006: Implement Integration Tests — Feature-Closeout & Error Handling (0.3 SP)

**Objective**: Validate feature-closeout invalidation and error scenarios.

**Acceptance Criteria**:
- [ ] **IT-005**: Test feature-closeout invalidation:
  - After feature-closeout boundary-sync:
  - Verify `.specrew/last-start-prompt.md` has `session_state_active: false`
  - Verify `.specrew/start-context.json` has `session_state.active: false`
  - User runs `specrew start` without feature request
  - Verify session treated as fresh (no feature resumption)
- [ ] **IT-006**: Test error handling:
  - Scenario 1: `git rev-parse HEAD` fails → verify warning logged, boundary-sync continues
  - Scenario 2: File write fails → verify error logged, state not corrupted
  - Scenario 3: Frontmatter parsing fails → verify treated gracefully

**Owner**: Reviewer  
**Trace**: FR-003, FR-006, SC-003  
**Test Location**: `tests/integration/baseline-hygiene-full-lifecycle.tests.ps1`

---

### T007: Manual End-to-End Lifecycle Test (0.5 SP)

**Objective**: Validate all user stories through manual execution of complete feature lifecycle.

**Acceptance Criteria**:
- [ ] Execute complete feature lifecycle (specify → feature-closeout) with test feature
- [ ] At each boundary (clarify, plan, tasks):
  - Simulate Squad boundary work (modify charter)
  - Call `Invoke-SpecrewBoundaryStateSync -BoundaryType '<boundary>'`
  - Run `specrew start` → verify NO pause-and-confirm prompt fires (US-1: baseline hygiene)
- [ ] At clarify boundary:
  - Intentionally modify `.github/agents/squad.agent.md` and commit
  - Run `specrew start` → verify pause-and-confirm prompt FIRES with correct file (US-2: genuine changes detected)
- [ ] At feature-closeout:
  - Call boundary-sync for feature-closeout
  - Read `.specrew/last-start-prompt.md` → verify `session_state_active: false`
  - Run `specrew start` → verify session does not resume (US-3: closeout invalidation)
- [ ] Document console output for all scenarios

**Owner**: Reviewer  
**Trace**: SC-001, SC-002, SC-003

---

### T008: Run Regression Test Suite (0.2 SP)

**Objective**: Ensure no regressions in existing Specrew functionality.

**Acceptance Criteria**:
- [ ] Execute existing Specrew test suite
- [ ] Verify all tests pass (focus on F-011-related tests, boundary-sync tests, session state tests)
- [ ] Verify no new failures introduced

**Owner**: Reviewer  
**Trace**: SC-004

---

### T009: Code Review & Final Validation (0.2 SP)

**Objective**: Verify implementation meets quality and correctness standards.

**Acceptance Criteria**:
- [ ] Verify `Update-BaselineCommitHashInFrontmatter` function follows Specrew conventions
- [ ] Verify idempotency: re-running at same boundary produces stable state
- [ ] Verify error handling: graceful failures, clear logging
- [ ] Verify state preservation: all frontmatter fields intact after baseline update
- [ ] Verify integration point: baseline update called at right point in boundary-sync flow
- [ ] Confirm zero false positives across 5+ boundaries with Squad commits (SC-001)
- [ ] Confirm genuine user changes detected correctly (SC-002)
- [ ] Confirm feature-closeout clears session (SC-003)
- [ ] All test cases pass; no regressions (SC-004)

**Owner**: Spec Steward (Alon Fliess)  
**Trace**: FR-001, FR-002, FR-005, FR-006, SC-001–SC-004

---

### T010a: Push Upstream Before Review Boundary (0.2 SP)

**Objective**: Finish implementation discipline by landing semantic commits locally and pushing the branch before review-boundary evidence is generated.

**Acceptance Criteria**:
- [ ] Verify T001–T009 complete and validation evidence is fresh
- [ ] Commit implementation work in semantic groups (spec artifacts, bug fix, boundary-sync helpers, boundary integration, tests, changelog as needed)
- [ ] Push feature branch `029-baseline-hygiene` to remote before entering review-boundary
- [ ] Confirm the review-boundary tree is committed and pushable with no implementation-only drift left unstaged

**Owner**: Implementer  
**Trace**: review-boundary discipline, spec.md, plan.md, lifecycle completion

---

### T010b: Review Boundary PR + Post-Signoff Merge (0.2 SP)

**Objective**: Open the PR at review-boundary, then merge only after review sign-off.

**Acceptance Criteria**:
- [ ] Open pull request on GitHub at review-boundary with:
  - Title: "Feature 029: Baseline Hygiene for Session-Loaded File Change Detection"
  - Description: Reference spec.md and cite requirements FR-001–FR-006
  - Checklist: T001–T010a complete, all tests passing, no regressions
- [ ] Perform self-review and request Spec Steward (Alon Fliess) review
- [ ] After review sign-off and CI passes (all checks green):
  - Merge with merge-commit to main branch
  - Delete feature branch if policy still allows

**Owner**: Implementer  
**Trace**: review-boundary, post-review sign-off, lifecycle completion

---

## Dependencies & Execution Order

### Linear Execution (Recommended)

1. **T001**: Verify Implementation Context (foundation)
2. **T002**: Implement baseline update helper (blocking prerequisite for all tests)
3. **T003**: Unit tests (validate T002)
4. **T004**: Integration tests — baseline sequence (validates boundaries)
5. **T005**: Integration tests — false-positive elimination & genuine change detection
6. **T006**: Integration tests — feature-closeout & error handling
7. **T007**: Manual end-to-end lifecycle test (comprehensive validation)
8. **T008**: Regression test suite (final quality gate)
9. **T009**: Code review & final validation (sign-off)
10. **T010a**: Push upstream before review-boundary
11. **T010b**: Open PR at review-boundary, merge after sign-off

### Parallelization Opportunities

- **Unit Tests (T003)** and **Integration Tests (T004–T006)** can run in parallel after T002 completes
- **Manual Test (T007)** can run in parallel with T003–T006 (uses separate test feature)
- **Regression Tests (T008)** depends on T002 completion; can run after T004

---

## Effort Summary

| Task | Story | Effort | Owner |
|------|-------|--------|-------|
| T001 | Shared | 0.5 SP | Implementer |
| T002 | E2 | 1 SP | Implementer |
| T003 | US-1/US-3 | 0.3 SP | Reviewer |
| T004 | US-1 | 0.3 SP | Reviewer |
| T005 | US-1/US-2 | 0.3 SP | Reviewer |
| T006 | US-2/US-3 | 0.3 SP | Reviewer |
| T007 | US-1/US-2/US-3 | 0.5 SP | Reviewer |
| T008 | QA | 0.2 SP | Reviewer |
| T009 | Sign-off | 0.2 SP | Spec Steward |
| T010a | Polish | 0.2 SP | Implementer |
| T010b | Review boundary | 0.2 SP | Implementer |
| **TOTAL** | **All** | **~3.6 SP** | — |

**Capacity**: 3.6 story points  
**Planned**: 3.6 story points (scope aligned per 2026-05-21 planning repair)  
**Note**: Effort reduced from prior 5.6 SP estimate; feature-closeout (E1) is already implemented and only requires validation testing.

---

## Quality Gates

- [ ] T003: Unit tests pass
- [ ] T004–T006: Integration tests pass
- [ ] T007: Manual lifecycle test completes successfully
- [ ] T008: Regression suite passes (no new failures)
- [ ] T009: Code review approved by Spec Steward
- [ ] T010a: Review-boundary tree committed and pushed upstream before review
- [ ] T010b: PR merged to main after review sign-off; feature available in next release

---

## Sign-Off

**Generated**: 2026-05-21  
**Repaired**: 2026-05-21 (capacity and effort alignment)  
**Status**: ✅ **READY FOR IMPLEMENTATION KICKOFF**  
**Feature**: 029-baseline-hygiene  
**Iteration**: 001  
**Total Tasks**: 11  

All design artifacts complete. E1 already implemented and verified in current sync-boundary-state.ps1. E2 implementation and validation tasks defined with clear acceptance criteria. Capacity and effort aligned (3.6 SP). No blockers identified.

---

**Maintained by**: Alon Fliess  
**Last Updated**: 2026-05-21
