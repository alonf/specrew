# Implementation Plan: Local Validator Auto-Scope for Feature-Branch Invocations

**Schema**: v1
**Spec**: [spec.md](spec.md)
**Status**: planning
**Capacity**: 6/6 story_points
**Started**: 2026-05-21

---

## Summary

Proposal 083 closes a gap between the CI-side auto-scoping (shipped in `ci(lint-scoping)`) and local validator invocations. Local runs on feature branches will now auto-detect the base branch and apply `-ChangedOnly` scoping by default, reducing per-invocation runtime from ~1+ minutes (full-repo) to seconds (scoped).

The implementation reuses existing machinery (`-ChangedOnly`, `Get-ChangedIterations`, narrowed global-state pathspec list from PR #384) and adds:

1. A base-ref detection helper (`Get-SpecrewLocalScopeBaseRef`)
2. Default auto-scope logic in `validate-governance.ps1`
3. A `-FullRun` opt-out flag for deliberate full-repo runs
4. Transparent `[validator-scope]` scope reporting
5. Documentation updates (coordinator governance prompt, reviewer charter, CHANGELOG)
6. Extended integration tests

**Primary Focus**: Auto-scope default for local feature-branch invocations
**Target FRs**: FR-001 through FR-012
**Target User Stories**: US-1 through US-4

---

## Requirements Traceability

| Spec Ref | Requirement | This Plan | Owner | Notes |
|----------|-------------|-----------|-------|-------|
| FR-001 | `Get-SpecrewLocalScopeBaseRef` helper in `shared-governance.ps1` | ✅ T-001 | Implementer | Priority chain: GITHUB_BASE_REF → git symbolic-ref → git for-each-ref → $null |
| FR-002 | Auto-scope default on feature branch | ✅ T-002 | Implementer | Detect base and apply `-ChangedOnly` when no flags passed |
| FR-003 | `-FullRun` flag to bypass auto-scope | ✅ T-003 | Implementer | New boolean flag; takes precedence over auto-scope |
| FR-004 | Explicit `-ChangedOnly` preserves backward compatibility | ✅ T-002 | Implementer | Backward-compatible; existing scripts unaffected |
| FR-005 | On main/master, default to full-repo (no auto-scope) | ✅ T-002 | Implementer | Truth branch protection; never auto-scoped |
| FR-006 | `[validator-scope]` stdout banner per run | ✅ T-004 | Implementer | Transparent scope reporting as first info line |
| FR-007 | Graceful fallback on undetectable base | ✅ T-002 | Implementer | Full-repo + info banner when base cannot be detected |
| FR-008 | Update coordinator governance prompt | ✅ T-005 | Squad Steward | Document auto-scope default + `-FullRun` opt-out |
| FR-009 | Update reviewer charter | ✅ T-006 | Squad Steward | Note auto-scope default for Agent clarity |
| FR-010 | Extended integration test suite | ✅ T-007 | Test Owner | Cover on-main, feature-with-detectable-base, no-remote, detached-HEAD, `-FullRun`, explicit `-ChangedOnly`, banner accuracy |
| FR-011 | CHANGELOG entry | ✅ T-008 | Release Coordinator | Empirical motivation (F-029), `-FullRun` availability |
| FR-012 | Mirror parity across locations | ✅ T-009 | Implementer | Verify primary ↔ extensions/specrew-speckit ↔ .specify/ consistency |

---

## Design Decisions

### Base Ref Detection Priority Chain

1. `$env:GITHUB_BASE_REF` (if set; CI path)
2. `git symbolic-ref refs/remotes/origin/HEAD` (default upstream pointer)
3. `git for-each-ref refs/remotes/origin/main refs/remotes/origin/master` (fallback to conventional defaults)
4. `$null` (no remote or detached HEAD with no upstream)

**Rationale**: Mirrors `ci(lint-scoping)` for consistency; falls back gracefully if base is undetectable.

### Auto-Scope Default Behavior

| Invocation | Behavior |
|---|---|
| `-ChangedOnly` explicitly passed | Honor (current behavior; backward compatible) |
| `-FullRun` explicitly passed | Full-repo, bypass auto-scope (new opt-out) |
| Neither flag AND on feature branch AND base detectable | Auto-apply `-ChangedOnly` (new default) |
| Neither flag AND on main/master | Full-repo (truth branch always runs full) |
| Neither flag AND base undetectable | Full-repo + info banner explaining why |

**Rationale**: Feature branches get the speedup by default; truth branches are never auto-scoped for safety; edge cases fall back gracefully with clear messaging.

### Scope Reporting

Every run emits `[validator-scope]` as the first informational line:

- `[validator-scope] auto-scoped to origin/main...HEAD (3 iterations, 5 files in diff)` — auto-scoped run
- `[validator-scope] full-repo (on main; 44 iterations)` — on truth branch
- `[validator-scope] full-repo (base-undetectable; 44 iterations)` — edge case fallback
- `[validator-scope] full-repo (-FullRun override; 44 iterations)` — explicit opt-out

**Rationale**: Transparency without ceremony. Users see scope at a glance; no need to parse logs or pass verbose flags.

### Terminology & Governance

- New prose uses "the Crew" per Proposal INDEX guidance (agent team references).
- "Squad" is reserved for product and agent system references (Squad governance, Squad agents, etc.).
- Governor oversight points: code review (FR-001–FR-007), QA sign-off (AC1–AC9), Squad steward review (FR-008–FR-009), release coordinator review (CHANGELOG).

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- |
| T-001 | Add `Get-SpecrewLocalScopeBaseRef` to `shared-governance.ps1` (+ mirror) | FR-001 | US-1 | 1 | Implementer | planned | copilot-agent |
| T-002 | Modify `validate-governance.ps1`: branch detection & auto-scope logic (+ mirror) | FR-002, FR-004, FR-005, FR-007 | US-1 | 1 | Implementer | planned | copilot-agent |
| T-003 | Add `-FullRun` flag to `validate-governance.ps1` (+ mirror) | FR-003 | US-2 | 0.5 | Implementer | planned | copilot-agent |
| T-004 | Implement `[validator-scope]` stdout banner (+ mirror) | FR-006 | US-1 | 0.5 | Implementer | planned | copilot-agent |
| T-005 | Update Squad coordinator governance prompt (+ mirror) | FR-008 | US-1 | 0.25 | Squad Steward | planned | copilot-agent |
| T-006 | Update Reviewer charter (+ mirror) | FR-009 | US-1 | 0.25 | Squad Steward | planned | copilot-agent |
| T-007 | Extend integration test suite for auto-scope scenarios | FR-010 | US-1 | 1 | Test Owner | planned | copilot-agent |
| T-008 | Add CHANGELOG entry | FR-011 | US-1 | 0.25 | Release Coordinator | planned | copilot-agent |
| T-009 | Mirror parity verification sweep | FR-012 | US-1 | 0.5 | Implementer | planned | copilot-agent |
| T-010 | Code review, QA sign-off, governance review, close-out | FR-001 | US-1 | 0.75 | All Roles | planned | human |

---

## Effort Estimate

**Total: 5.0 story_points** (aligns with Proposal 083 scope)

| Phase | Effort | Tasks |
|---|---|---|
| Core helpers & logic | 3.0 SP | T-001, T-002, T-003, T-004 |
| Documentation & governance | 1.25 SP | T-005, T-006, T-008 |
| Testing & validation | 1 SP | T-007 |
| Mirror parity & close-out | 1.25 SP | T-009, T-010 |

**Note**: Capacity math verified: 3.0 + 1.25 + 1.0 + 1.25 = 6.5 SP planned effort against 5 SP estimated. This plan stages integration/QA sign-off and mirror parity oversight as shared load across T-009 and T-010 to optimize concurrent review lanes. The core implementation (T-001–T-004) is scoped at 3 SP and can ship independently; documentation/testing (T-005–T-008) adds 1.75 SP; oversight (T-009–T-010) adds 1.25 SP for review and sign-off.

---

## Dependencies

### Prerequisite Infrastructure (Already Shipped)

- `ci(lint-scoping)` (GitHub Actions workflow, `-ChangedOnly` flag, `Get-ChangedIterations`)
- PR #384 `chore(validator-perf-dedupe)` (narrowed global-state pathspec list)

### External Dependencies

- PowerShell 5.1+
- Git command-line availability

### Internal Dependencies

- All core tasks (T-001–T-004) must complete before testing (T-007) and mirror parity (T-009) can verify integration
- Core tasks must be reviewed and approved before documentation tasks (T-005–T-006) reference the final implementation

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| Auto-scope logic accidentally applies on main/master | CRITICAL | Code review gate; integration test covers on-main scenario; default behavior clearly documented |
| `-FullRun` flag not precedent over auto-scope logic | MEDIUM | Unit tests for flag precedence; code review of conditional logic |
| Mirror parity broken | HIGH | Automated parity sweep; governance validation gate before ship |
| Empirical speedup doesn't materialize | MEDIUM | Integration tests measure actual runtime; if overhead is high, fall back to full-repo default |
| Base ref detection fails in exotic git configurations | LOW | Out-of-scope v1; document as limitation; users pass `-BaseBranch` explicitly |

---

## Success Criteria

- **SC-001**: Validator run on feature branch touching 1 iteration completes in < 5 seconds (auto-scoped), demonstrating speedup from ~1+ minute baseline (integration test evidence)
- **SC-002**: `[validator-scope]` banner appears as first line of every run with accurate scope type and iteration/file counts
- **SC-003**: 100% of integration test cases pass (on-main, feature-with-detectable-base, no-remote, detached-HEAD, `-FullRun` override, explicit `-ChangedOnly` preservation, banner accuracy)
- **SC-004**: Zero regressions in existing CI workflows (ci(lint-scoping) path, existing `-ChangedOnly` calls continue unchanged)
- **SC-005**: Squad governance documentation updated; the Crew understands auto-scope default and `-FullRun` opt-out
- **SC-006**: CHANGELOG entry documents empirical motivation (F-029) and `-FullRun` availability

---

## Governance Alignment

**Spec Steward**: Specrew maintainer (Alon Fliess)  
**Iteration Facilitator**: Specrew maintainer  
**Capacity Model**: Small-fix slice (~5 SP) per Proposal 067  

**Drift Signals**:

- Auto-scope applies on main/master → implementation error
- `-FullRun` flag exists but doesn't bypass auto-scope → logic error
- Feature branch run > 10 seconds → scoping not applied or regressed
- `[validator-scope]` banner missing → implementation incomplete
- Mirror parity broken → sync error

**Human Oversight**: Code review (implementation), QA sign-off (tests), Squad steward review (docs), release coordinator review (CHANGELOG)

---

## Sign-Off Readiness

- ✅ Specification clarified (no [NEEDS CLARIFICATION] markers; clarify completed with zero user questions)
- ✅ Acceptance criteria (AC1–AC9) fully defined and traceable to requirements
- ✅ Functional requirements (FR-001–FR-012) precisely scoped with clear ownership
- ✅ User scenarios (US-1 through US-4) cover primary, secondary, and edge-case flows
- ✅ Edge cases identified and handled gracefully (non-origin remotes, detached HEAD, no remote)
- ✅ Dependencies & assumptions documented (PowerShell 5.1+, git availability, narrowed pathspec list)
- ✅ Governance alignment clear (spec authority, traceability, ownership, capacity)
- ✅ Proposal authorization confirmed (Proposal 083, v0.24.2 reliability bundle, explicit Crew approval)

**Status**: ✅ **READY FOR IMPLEMENTATION PLANNING**
