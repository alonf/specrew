# Tasks: Local Validator Auto-Scope for Feature-Branch Invocations (Proposal 083)

**Feature**: Local Validator Auto-Scope for Feature-Branch Invocations  
**Proposal**: 083  
**Version**: v0.24.2  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)  
**Branch**: `chore-083-local-validator-speedup`  
**Capacity**: 6 story_points

---

## Executive Summary

**Goal**: Close the gap between CI-side auto-scoping (already shipped in `ci(lint-scoping)`) and local validator invocations. Local runs on feature branches will now auto-detect the base branch and apply `-ChangedOnly` scoping by default, reducing per-invocation runtime from ~1+ minutes (full-repo) to seconds (scoped).

**Scope**: Tightly bound to Proposal 083 and its accepted mirror parity, banner, documentation, testing, and changelog work. Implementation reuses existing machinery (`-ChangedOnly`, `Get-ChangedIterations`, narrowed pathspec list from PR #384) and adds new helpers, default logic, and opt-out flags.

**User Stories**: US-1 through US-4  
**Functional Requirements**: FR-001 through FR-012  
**Acceptance Criteria**: AC1 through AC9

---

## Phase 1: Setup & Prerequisite Validation

**Purpose**: Validate environment and establish readiness for implementation

- [X] T001 [assigned_to: Implementer] [effort: S] Verify PowerShell 5.1+, git availability, and validate prerequisite infrastructure (ci(lint-scoping), PR #384 narrowed pathspec list) per plan.md (Trace: FR-001, FR-002)
- [X] T002 [P] [assigned_to: Implementer] [effort: S] Review existing `-ChangedIterations` helper and narrowed global-state pathspec list in `scripts/internal/shared-governance.ps1` (Trace: plan.md prerequisites section)
- [X] T003 [P] [assigned_to: Test Owner] [effort: S] Locate and review existing test suite at `tests/integration/validate-governance-changed-only.tests.ps1` for extension points (Trace: FR-010)

**Independent Test**: Verify environment can execute PowerShell scripts and run git commands; confirm existing test infrastructure is accessible.

**Checkpoint**: Prerequisites validated; team understands existing machinery and extension points.

---

## Phase 2: Core Implementation (User Story US-1 & US-4)

**Goal**: Implement base-ref detection and auto-scope default logic with backward compatibility

**Priority**: P1 (unblocks other stories and provides primary speedup benefit)

**Independent Test**: Running validator on feature branch with no flags auto-applies `-ChangedOnly` against detected base and emits `[validator-scope]` banner; explicit flags are honored; on main, defaults to full-repo.

### User Story 1: Maintainer Invokes Validator Locally on Feature Branch (Auto-Scope Default)

- [X] T004 [US1] [assigned_to: Implementer] [effort: M] Implement `Get-SpecrewLocalScopeBaseRef` helper function in `scripts/internal/shared-governance.ps1` with priority chain: (1) `$env:GITHUB_BASE_REF` if set, (2) `git symbolic-ref refs/remotes/origin/HEAD`, (3) `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master`, (4) return `$null` on failure (Trace: FR-001, AC1)

- [X] T005 [US1] [assigned_to: Implementer] [effort: M] Modify `validate-governance.ps1` to detect current branch and implement auto-scope default logic: on feature branch with detectable base + no explicit flags → auto-apply `-ChangedOnly` against detected base; on main/master → full-repo; edge cases → full-repo with info banner (Trace: FR-002, FR-005, FR-007, AC2, AC5)

- [X] T006 [P] [US1] [assigned_to: Implementer] [effort: S] Implement `[validator-scope]` stdout banner output for all execution paths: auto-scoped runs, full-repo on main, base-undetectable fallback, `-FullRun` override; emit as first informational line with scope type, iteration count, and file count (if scoped) (Trace: FR-006, AC6)

### User Story 4: Explicit Flags Preserve Existing Behavior (Backward Compatibility)

- [X] T007 [P] [US4] [assigned_to: Implementer] [effort: S] Verify and document that explicit `-ChangedOnly` flag (with or without `-BaseBranch`) preserves current behavior and takes precedence over auto-scope logic (Trace: FR-004, AC4)

**Checkpoint**: Core implementation complete; `-ChangedOnly` auto-applied on feature branches; explicit flags honored; scope banner emitted. Backward compatibility verified.

---

## Phase 3: Opt-Out Override Flag (User Story US-2)

**Goal**: Provide explicit `-FullRun` flag for deliberate full-repo validation on feature branches

**Priority**: P2 (secondary use case; supports Squad governance workflows)

**Independent Test**: Passing `-FullRun` on feature branch forces full-repo validation and emits appropriate `[validator-scope]` banner.

- [X] T008 [US2] [assigned_to: Implementer] [effort: S] Add `-FullRun` boolean flag to `validate-governance.ps1` parameter set; verify flag takes precedence over auto-scope logic when passed (Trace: FR-003, AC3)

**Checkpoint**: `-FullRun` flag works correctly; auto-scope can be explicitly overridden.

---

## Phase 4: Edge-Case Resilience (User Story US-3)

**Goal**: Validator gracefully handles undetectable base branch scenarios

**Priority**: P2 (edge case resilience; supports production robustness)

**Independent Test**: Running validator with no detectable base ref (detached HEAD, no remote) falls back to full-repo cleanly and emits informational banner.

- [X] T009 [US3] [assigned_to: Implementer] [effort: S] Implement graceful fallback logic: when base ref is undetectable, validator runs full-repo and emits `[validator-scope] full-repo (base-undetectable; <iteration-count> iterations)` info banner (Trace: FR-007, AC7)

**Checkpoint**: Edge cases handled gracefully; no failures in detached HEAD or no-remote scenarios.

---

## Phase 5: Documentation & Governance Alignment (Cross-Cutting)

**Goal**: Update Squad governance documentation to reflect new auto-scope default and `-FullRun` opt-out

**Priority**: P1 (mandatory for Squad awareness and Agent clarity)

**Independent Test**: Coordinator governance prompt and Reviewer charter clearly document auto-scope default, `-FullRun` opt-out, and encourage use of auto-scoped default without explicit flags.

- [X] T010 [assigned_to: Squad Steward] [effort: S] Update Squad coordinator governance prompt in `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` to document that local validator runs now auto-scope by default on feature branches and that `-FullRun` is the explicit opt-out for deliberate full-repo runs (Trace: FR-008, AC8)

- [X] T011 [P] [assigned_to: Squad Steward] [effort: S] Update Reviewer charter in `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` to note the auto-scope default and `-FullRun` opt-out for clarity when the Crew validates locally (Trace: FR-009, AC8)

- [X] T012 [assigned_to: Release Coordinator] [effort: S] Add CHANGELOG.md entry under `Changed` section documenting Proposal 083, empirical motivation from F-029 (validator speedup during boundary lifecycle), and `-FullRun` availability as explicit opt-out (Trace: FR-011, AC9)

**Checkpoint**: Documentation updated; the Crew understands auto-scope default and `-FullRun` opt-out.

---

## Phase 6: Mirror Parity & Cross-Location Sync

**Goal**: Verify and maintain mirror parity across three locations (primary, extensions/specrew-speckit, .specify/extensions)

**Priority**: P1 (governance integrity; required for dual-toolchain consistency)

**Independent Test**: Compare all modified files across three locations; verify byte-for-byte parity (or documented intentional variations); audit trail captures verification.

- [X] T013 [assigned_to: Implementer] [effort: M] Mirror parity verification sweep across all modified locations:
  - `scripts/internal/shared-governance.ps1` ↔ `extensions/specrew-speckit/scripts/shared-governance.ps1` ↔ `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`
  - `scripts/internal/validate-governance.ps1` ↔ `extensions/specrew-speckit/scripts/validate-governance.ps1` ↔ `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`
  - `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` ↔ `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
  - `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` ↔ `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`
  - Verify parity; document any intentional variations; create audit trail (Trace: FR-012, AC8)

**Checkpoint**: All mirrors in sync; parity sweep complete.

---

## Phase 7: Integration Testing & Validation

**Goal**: Extend integration test suite to cover all auto-scope scenarios and acceptance criteria

**Priority**: P1 (mandatory QA sign-off; validates all acceptance criteria)

**Independent Test**: All test cases pass; empirical speedup measured and logged; edge cases handled gracefully; banners accurate.

- [X] T014 [assigned_to: Test Owner] [effort: L] Extend integration test suite in `tests/integration/validate-governance-changed-only.tests.ps1` to cover:
  - **On main branch, no flags**: Verify full-repo validation (`[validator-scope] full-repo (on main; <count> iterations)`)
  - **On feature branch, detectable base, no flags**: Verify auto-scope (`[validator-scope] auto-scoped to origin/main...HEAD (<count> iterations, <files> files in diff)`)
  - **No remote configured, no flags**: Verify graceful fallback (`[validator-scope] full-repo (base-undetectable; <count> iterations)`)
  - **Detached HEAD, no flags**: Verify graceful fallback
  - **`-FullRun` on feature branch**: Verify bypass of auto-scope (`[validator-scope] full-repo (-FullRun override; <count> iterations)`)
  - **Explicit `-ChangedOnly -BaseBranch origin/main`**: Verify honored as-is (backward compatibility)
  - **Banner accuracy**: Verify iteration count and file count (if scoped) match actual diff
  - **Empirical speedup measurement**: Verify feature-branch run (1–2 iterations) completes in < 5 seconds; capture runtime in test output
  - **Edge cases**: Multiple remotes, conventional vs. non-conventional default branches, missing `origin/HEAD` pointer
  (Trace: FR-010, AC2, AC3, AC4, AC5, AC6, AC7, AC1–AC9)

**Checkpoint**: All test cases passing; empirical speedup confirmed; edge cases verified; QA sign-off ready.

---

## Phase 8: Polish & Closeout

**Goal**: Final verification, code review, and sign-off

**Priority**: P1 (mandatory governance gates before ship)

**Independent Test**: Code review approved; QA sign-off complete; drift signals clear; deployment checklist verified.

- [ ] T015 [assigned_to: All Roles] [effort: M] Code review, QA sign-off, and governance closeout:
  - **Code review gate** (Implementer + Spec Steward): Verify implementation matches spec; FR-001–FR-007 correctly implemented; mirror parity verified
  - **QA sign-off** (Test Owner): Verify all integration tests pass; empirical speedup confirmed (SC-001); acceptance criteria AC1–AC9 all signed off
  - **Squad steward review** (Squad Steward): Verify governance documentation (coordinator prompt, reviewer charter) updated and aligned; the Crew understands auto-scope default
  - **Release coordinator review** (Release Coordinator): Verify CHANGELOG entry present and captures empirical motivation (F-029) and `-FullRun` availability
  - **Drift signal audit**: Verify no drift signals triggered (auto-scope never applies on main, `-FullRun` precedence correct, feature-branch runs < 10 seconds, banner always present, mirror parity verified)
  - Document approvals; resolve any open items before merge
  (Trace: plan.md governance alignment section, all FRs, all ACs)

**Checkpoint**: All governance gates passed; deployment checklist complete; ready for merge to main and v0.24.2 bundle.

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Dependencies | Blocking |
|-------|-------------|----------|
| Phase 1: Setup | None | All others |
| Phase 2: Core Implementation | Phase 1 complete | Phase 3, 5, 6, 7, 8 |
| Phase 3: Opt-Out Flag | Phase 2 complete | Phase 7, 8 |
| Phase 4: Edge-Case Resilience | Phase 2 complete | Phase 7, 8 |
| Phase 5: Documentation | Phase 2, 3, 4 complete | Phase 7, 8 |
| Phase 6: Mirror Parity | Phase 2, 3, 4, 5 complete | Phase 8 |
| Phase 7: Integration Testing | Phases 2, 3, 4, 6 complete | Phase 8 |
| Phase 8: Closeout | All other phases complete | Ship |

### Parallelization Opportunities

**After Phase 1 (Setup)**:
- Phase 2 (T004–T007): Implementer works on core helpers and logic
- Parallel with Phase 2: Phase 5 can draft documentation changes (T010–T012) but final updates require Phase 2 completion

**After Phase 2 complete**:
- Phase 3 (T008) and Phase 4 (T009) can run in parallel: both extend Phase 2 logic independently
- Phase 5 (T010–T012) and Phase 6 (T013) can run in parallel: both are post-implementation activities
- Phase 7 (T014) depends on Phase 2, 3, 4, 6 complete; then can run independently

**Recommended Parallel Execution**:
1. Phase 1 (setup) — sequential baseline
2. Phase 2 (core) — single implementer, sequential tasks within phase
3. *After Phase 2*: Phase 3, 4, 5, 6 can overlap:
   - Implementer: Phase 3 (T008) → Phase 4 (T009) → Phase 6 parity verification (T013)
   - Squad Steward: Phase 5 docs (T010–T012) while implementer does T008–T009
4. Phase 7 (T014) — once Phase 6 complete
5. Phase 8 (T015) — all other phases complete

---

## User Story Mapping

### User Story 1: Maintainer Invokes Validator Locally on Feature Branch (P1 🎯 MVP)

**Tasks**: T004, T005, T006, T007 (Phase 2), plus T014 (integration tests)  
**Acceptance Criteria**: AC2, AC4, AC5, AC6  
**Effort**: 3.5 SP  

**What delivers**: Maintainer runs `validate-governance.ps1` on feature branch with no flags → validator auto-applies `-ChangedOnly` against detected base → runs in seconds instead of minutes → `[validator-scope]` banner confirms scope.

**Independent test**: Feature branch (touching 1–2 iterations) validates in < 5 seconds with accurate `[validator-scope]` banner.

### User Story 2: Squad Agent Needs Full-Repo Validation (P2)

**Tasks**: T008 (Phase 3), plus T014 (integration tests)  
**Acceptance Criteria**: AC3, AC6  
**Effort**: 1 SP  

**What delivers**: Squad agent passes `-FullRun` on feature branch → validator bypasses auto-scope → runs full-repo regardless of branch state → `[validator-scope]` banner indicates override.

**Independent test**: `-FullRun` on feature branch forces full-repo validation with `[validator-scope] full-repo (-FullRun override; <count> iterations)` banner.

### User Story 3: Validator Gracefully Handles Undetectable Base (P2)

**Tasks**: T009 (Phase 4), plus T014 (integration tests)  
**Acceptance Criteria**: AC7  
**Effort**: 1 SP  

**What delivers**: Validator in detached HEAD or no-remote scenario → gracefully falls back to full-repo → emits `[validator-scope] full-repo (base-undetectable; <count> iterations)` info banner.

**Independent test**: Detached HEAD or no-remote environment validates full-repo cleanly with explanatory banner.

### User Story 4: Explicit Flags Preserve Existing Behavior (P1)

**Tasks**: T007 (Phase 2), plus T014 (integration tests)  
**Acceptance Criteria**: AC4  
**Effort**: 0.5 SP  

**What delivers**: Existing scripts with `-ChangedOnly -BaseBranch origin/main` continue to work unchanged; no breaking changes.

**Independent test**: Explicit `-ChangedOnly -BaseBranch` behaves identically to pre-083 behavior.

---

## Success Criteria

### Measurable Outcomes (from spec.md)

- **SC-001**: Validator run on feature branch touching 1 iteration completes in < 5 seconds (auto-scoped), demonstrating speedup from ~1+ minute baseline (integration test evidence in T014)
- **SC-002**: `[validator-scope]` banner appears as first line of every run with accurate scope details (verified in T006, T014)
- **SC-003**: 100% of integration test cases pass: on-main, feature-with-detectable-base, no-remote, detached-HEAD, `-FullRun`, explicit `-ChangedOnly`, banner accuracy (T014)
- **SC-004**: Zero regressions in existing CI workflows (ci(lint-scoping) path, existing `-ChangedOnly` calls continue unchanged) (verified in T014)
- **SC-005**: Squad governance documentation updated; the Crew understands auto-scope default and `-FullRun` opt-out (T010–T012)
- **SC-006**: CHANGELOG entry documents empirical motivation (F-029) and `-FullRun` availability (T012)

---

## Effort Breakdown

| Phase | Tasks | Effort | Notes |
|-------|-------|--------|-------|
| Phase 1: Setup | T001–T003 | 1 SP | Prerequisite validation |
| Phase 2: Core Implementation | T004–T007 | 3.5 SP | Base-ref helper, auto-scope logic, banner, backward compat |
| Phase 3: Opt-Out Override | T008 | 1 SP | `-FullRun` flag |
| Phase 4: Edge-Case Resilience | T009 | 1 SP | Graceful fallback |
| Phase 5: Documentation | T010–T012 | 0.75 SP | Coordinator prompt, reviewer charter, CHANGELOG |
| Phase 6: Mirror Parity | T013 | 1 SP | Sync verification across locations |
| Phase 7: Integration Testing | T014 | 1 SP | Extend test suite, empirical speedup validation |
| Phase 8: Closeout | T015 | 0.75 SP | Code review, QA sign-off, governance gates |
| **TOTAL** | **15 tasks** | **~9 SP** | Includes setup, core, testing, documentation, oversight |

**Note**: Planning capacity (T001–T003, T015) totals 1.75 SP. Core implementation (T004–T009) totals 6.5 SP. Documentation/governance (T010–T013) totals 1.75 SP. All tasks fit within v0.24.2 small-fix-slice capacity model.

---

## Traceability Matrix

| Task | Requirement(s) | Story | Phase | Owner | Effort |
|------|----------------|-------|-------|-------|--------|
| T001 | FR-001, FR-002 | — | 1 | Implementer | S |
| T002 | FR-001, FR-002 | — | 1 | Implementer | S |
| T003 | FR-010 | — | 1 | Test Owner | S |
| T004 | FR-001 | US-1 | 2 | Implementer | M |
| T005 | FR-002, FR-005, FR-007 | US-1 | 2 | Implementer | M |
| T006 | FR-006 | US-1 | 2 | Implementer | S |
| T007 | FR-004 | US-4 | 2 | Implementer | S |
| T008 | FR-003 | US-2 | 3 | Implementer | S |
| T009 | FR-007 | US-3 | 4 | Implementer | S |
| T010 | FR-008 | — | 5 | Squad Steward | S |
| T011 | FR-009 | — | 5 | Squad Steward | S |
| T012 | FR-011 | — | 5 | Release Coordinator | S |
| T013 | FR-012 | — | 6 | Implementer | M |
| T014 | FR-010 | All | 7 | Test Owner | L |
| T015 | All FRs | All | 8 | All Roles | M |

---

## Risk Mitigation

| Risk | Impact | Mitigation | Owner |
|------|--------|-----------|-------|
| Auto-scope logic accidentally applies on main/master | CRITICAL | Code review gate (T015); integration test on-main scenario (T014); default behavior documented in spec and code comments | Implementer + Code Reviewer |
| `-FullRun` flag does not take precedence over auto-scope | MEDIUM | Unit tests for flag precedence (T014); code review of conditional logic (T015) | Test Owner + Implementer |
| Mirror parity broken across locations | HIGH | Automated parity sweep (T013); governance validation gate (T015) before ship | Implementer |
| Empirical speedup doesn't materialize | MEDIUM | Integration tests measure actual runtime (T014); if overhead is high, documented in retrospective for future strategy | Test Owner |
| Base ref detection fails in exotic git configurations | LOW | Out-of-scope v1; documented as limitation; users can pass `-BaseBranch` explicitly | Spec Steward |

---

## Governance Checkpoints

### Before Starting Implementation (Phase 1)

- [ ] ✅ Specification clarified (no [NEEDS CLARIFICATION] markers)
- [ ] ✅ Acceptance criteria fully defined and traceable
- [ ] ✅ User scenarios cover primary, secondary, and edge cases
- [ ] ✅ Dependencies & assumptions documented
- [ ] ✅ Proposal authorization confirmed (Proposal 083, v0.24.2 bundle)

### After Phase 2 (Core Implementation Complete)

- [ ] ✅ Code review approved: FR-001–FR-007 correctly implemented
- [ ] ✅ Helper function (`Get-SpecrewLocalScopeBaseRef`) in `shared-governance.ps1` with documented priority chain
- [ ] ✅ Validator detects branch state and applies auto-scope on feature branches
- [ ] ✅ `-FullRun` flag takes precedence; explicit flags honored
- [ ] ✅ `[validator-scope]` banner emitted on all paths with accurate scope info
- [ ] ✅ Backward compatibility verified: existing scripts continue unchanged

### After Phase 6 (Mirror Parity Complete)

- [ ] ✅ Primary ↔ extensions/specrew-speckit ↔ .specify/extensions all in sync
- [ ] ✅ Parity sweep audit trail documented
- [ ] ✅ No intentional variations; any differences documented

### After Phase 7 (Testing Complete)

- [ ] ✅ All integration tests pass (T014)
- [ ] ✅ Empirical speedup measured: feature-branch run < 5 seconds (AC1–AC9 verified)
- [ ] ✅ Edge cases validated: on-main, detached-HEAD, no-remote, `-FullRun`, explicit flags
- [ ] ✅ QA sign-off: no regressions, all acceptance criteria met

### Before Ship (Phase 8 Complete)

- [ ] ✅ Code review approved by Spec Steward and primary implementer
- [ ] ✅ QA sign-off: tests pass, empirical speedup confirmed
- [ ] ✅ Squad steward review: governance docs updated; the Crew understands auto-scope
- [ ] ✅ Release coordinator review: CHANGELOG entry present and captures F-029 motivation
- [ ] ✅ Drift signal audit: zero critical drift signals triggered
- [ ] ✅ All governance gates cleared; ready for merge and v0.24.2 release

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. **Phase 1** (T001–T003): Setup & validation
2. **Phase 2** (T004–T007): Core implementation (base-ref helper, auto-scope logic, banner, backward compat)
3. **Phase 7** (T014): Integration tests with empirical speedup validation
4. **Phase 8** (T015): Code review, QA sign-off, governance gates
5. **STOP and VALIDATE**: User Story 1 fully functional and tested independently

**Outcome**: Auto-scoped feature-branch validation working; maintainers see speedup; backward compatibility verified. Ship as MVP.

### Incremental Delivery (Full Proposal 083)

1. **MVP (above)**: User Story 1 complete, tested, shipped
2. **Add Phase 3** (T008): `-FullRun` override flag + integration tests
3. **Add Phase 4** (T009): Edge-case resilience + integration tests
4. **Add Phase 5–6** (T010–T013): Documentation, governance, mirror parity
5. **Final Phase 8** (T015): Comprehensive code review, QA sign-off
6. **Deploy**: v0.24.2 bundle with Proposals 082, 081, and other small-fix slices

**Outcome**: Complete Proposal 083 delivered with all user stories, documentation, tests, and governance checkpoints.

### Parallel Team Strategy (If Multiple Developers Available)

1. **Phase 1** (all): Setup & validation (sequential baseline)
2. **Phase 2** (Implementer 1): Core implementation (T004–T007)
3. *During Phase 2*:
   - **Squad Steward** (parallel): Draft governance docs (T010–T012) — finalize after Phase 2
   - **Test Owner** (parallel): Design test cases and set up test harness — ready to run after Phase 2
4. **Phase 3–4** (Implementer 1): T008–T009 (opt-out flag, edge-case resilience)
5. **Phase 6** (Implementer 1): T013 (mirror parity sweep)
6. **Phase 7** (Test Owner): T014 (run integration tests; measure empirical speedup)
7. **Phase 8** (all roles): T015 (code review, QA sign-off, governance gates)

**Outcome**: All phases completed efficiently; core implementation, documentation, testing, and governance in parallel.

---

## Notes for Implementers

- **Preserve Terminology**: Use "the Crew" for references to agent teams; "Squad" is reserved for product and agent system references (per Proposal INDEX guidance).
- **Scope Reporting**: The `[validator-scope]` banner is primary observational output; no runtime timeouts or timeout fallback behavior added (performance thresholds are acceptance signals only).
- **Mirror Parity**: All changes must be applied to three locations: primary (`scripts/internal/`), extensions (`extensions/specrew-speckit/`), and `.specify/` mirror. Task T013 verifies parity.
- **Backward Compatibility**: Existing `-ChangedOnly` and `-BaseBranch` flags must continue to work unchanged. Any script passing explicit flags should see no behavior change.
- **Edge Cases**: Graceful fallback (full-repo + info banner) is the strategy for undetectable base ref; never fail due to missing remote or detached HEAD.
- **Empirical Speedup**: Performance thresholds (< 5 seconds for 1-iteration branch) are acceptance signals for QA, not enforced runtime limits. Integration tests measure actual runtime and log evidence.

---

## Next Steps

1. **Immediate**: Team reviews this tasks.md and confirms ownership assignments (T001–T015).
2. **Phase 1**: Implementer runs T001–T003; confirms PowerShell 5.1+, git available; reviews existing helpers and test infrastructure.
3. **Phase 2**: Implementer implements T004–T007 (core logic, banner, flags).
4. **Parallel** (after Phase 2 starts): Squad Steward drafts T010–T012; Test Owner designs T014 test cases.
5. **Phase 3–4**: Implementer completes T008–T009 (opt-out, edge cases).
6. **Phase 6**: Implementer runs T013 (mirror parity verification).
7. **Phase 7**: Test Owner runs T014; validates all acceptance criteria.
8. **Phase 8**: All roles execute T015 (code review, QA sign-off, governance gates).
9. **Ship**: Merge to `main` branch; include in v0.24.2 bundle with Proposals 082, 081, others.

---

## Summary

**Proposal 083 Tasks**: 15 tasks across 8 phases  
**Total Capacity**: ~9 SP (planning 1.75 SP, core 6.5 SP, documentation/governance 1.75 SP)  
**User Stories**: 4 (US-1 P1, US-2 P2, US-3 P2, US-4 P1)  
**Functional Requirements**: 12 (FR-001 through FR-012)  
**Acceptance Criteria**: 9 (AC1 through AC9)  

**MVP Scope**: User Story 1 (auto-scope on feature branches) + Phase 1, 2, 7, 8  
**Full Scope**: All 4 user stories + all 8 phases + governance checkpoints  
**Governance Gates**: Code review, QA sign-off, Squad steward review, release coordinator review, drift signal audit  

**Ready for implementation**: ✅ All design documents complete; spec clarified; plan finalized; tasks defined; ownership assigned; acceptance criteria traceable; governance checkpoints explicit.

---

**Proposal 083: Local Validator Speedup — Auto-Scoped Default for Feature-Branch Invocations**  
*v0.24.2 reliability bundle | Feature specification dated 2026-05-21 | Tasks generated for implementation*
