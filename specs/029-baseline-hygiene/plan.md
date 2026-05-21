# Feature Plan: Baseline Hygiene for Session-Loaded File Change Detection

**Spec**: [./spec.md](./spec.md)  
**Status**: planning  
**Approved**: ✓ (Expanded Pillar E scope, 2026-05-21)  
**Created**: 2026-05-21

---

## Summary

Feature 029 fixes false-positive session-loaded file change detection (F-011) caused by `baseline_commit_hash` remaining frozen at feature-start instead of being refreshed at each lifecycle boundary. As Squad commits internal governance work at boundaries (specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout), those changes accumulate in `git diff baseline..HEAD` indefinitely, triggering repeated pause-and-confirm prompts even though no user changes were made.

**Solution**: Two focused pillars:

- **E1 (Feature-Closeout Invalidation, P2)**: Mark `.specrew/last-start-prompt.md` as inactive at feature-closeout so closed features do not resume
- **E2 (Boundary-Based Baseline Updates, P1)**: Update `baseline_commit_hash` to current HEAD at each of the 7 lifecycle boundaries so Squad's governance work is "behind" the baseline

**Impact**: Zero false positives across full feature lifecycle while preserving correct detection of genuine user changes.

---

## Requirements Traceability

| Requirement | Scope | Owner |
|-------------|-------|-------|
| **FR-001**: Boundary-based Baseline Updates | E2: update baseline at all 7 lifecycle boundaries | Implementer |
| **FR-002**: Baseline Update Mechanism | E2: `Update-BaselineCommitHashInFrontmatter` function in `sync-boundary-state.ps1` | Implementer |
| **FR-003**: Feature-Closeout Invalidation | E1: set `session_state_active: false` at feature-closeout | Implementer |
| **FR-004**: F-011 Integration | E2: `Get-BaselineCommitHash` reads updated baseline correctly | Spec Steward (validation) |
| **FR-005**: Idempotency | E2: re-running boundary sync at same boundary does not corrupt state | Implementer + Reviewer (test) |
| **FR-006**: Error Handling | E2: graceful handling of git/file-I/O failures | Implementer |

---

## Design

### Architecture

- **Primary change site**: `scripts/internal/sync-boundary-state.ps1`
- **New helper function**: `Update-BaselineCommitHashInFrontmatter`
- **No changes to F-011**: Detection logic untouched; only baseline input is refreshed
- **No user education needed**: Fix is transparent; boundary-sync already called by framework

### Data Model

```yaml
# .specrew/last-start-prompt.md frontmatter
baseline_commit_hash: <40-char SHA-1 hash>  # Updated at each boundary (currently frozen)
session_state_active: true|false             # Set to false at feature-closeout
session_state_boundary: specify|clarify|...  # Current lifecycle boundary
session_state_feature: <feature-name>        # Feature being worked on
session_state_recorded_at: <ISO8601>         # Timestamp of last boundary record
```

### Lifecycle Flow

1. **feature-start (specify boundary)**: baseline = current HEAD (set by `specrew start`)
2. **clarify/plan/tasks boundaries**: baseline updated to current HEAD after Squad commits
3. **review-signoff, iteration-closeout**: baseline updated (same pattern)
4. **feature-closeout**: baseline updated AND `session_state_active: false`

---

## Iterations

### Iteration 001 (E1 Validation + E2 Core)

- **Effort**: 3-4 story points (reduced scope: E1 already implemented; focus on E2 and validation)
- **Status**: planning
- **Scope**:
  - E2 implementation in `sync-boundary-state.ps1` (baseline update helper)
  - E1 verification only (feature-closeout invalidation already implemented; confirm + test)
  - Integration with `Invoke-SpecrewBoundaryStateSync`
  - Error handling (git failure, file I/O failure)
  - Idempotency validation
  - Core integration + manual tests

**Tasks** (11 total, collapsed scope, ~3.6 SP):

| Task | Title | Requirement | Effort | Owner |
|------|-------|-------------|--------|-------|
| `context-verify` | Verify implementation context: review sync-boundary-state.ps1, specrew-start.ps1, frontmatter schema, E1 existing impl | FR-001–FR-006 | 0.5 SP | Implementer |
| `baseline-update-impl` | Implement baseline update helper function: `Update-BaselineCommitHashInFrontmatter` in sync-boundary-state.ps1 | FR-001, FR-002 | 1 SP | Implementer |
| `unit-tests` | Unit tests for baseline update and session state validity | FR-002, FR-003 | 0.3 SP | Reviewer |
| `it-baseline-sequence` | Integration tests: baseline update across all 7 boundaries + false-positive elimination + genuine-change detection | FR-001, FR-002, FR-004 | 0.3 SP | Reviewer |
| `it-feature-closeout` | Integration tests: feature-closeout invalidation + error handling + idempotency | FR-003, FR-005, FR-006 | 0.3 SP | Reviewer |
| `manual-tests` | Manual test: execute end-to-end lifecycle scenarios (specify → feature-closeout) covering all boundary changes | SC-001, SC-002, SC-003 | 0.5 SP | Reviewer |
| `regression-test` | Run full Specrew test suite; confirm no regressions | SC-004 | 0.2 SP | Reviewer |
| `code-review` | Code review: Spec Steward validates implementation meets quality and correctness standards | FR-001–FR-006 | 0.2 SP | Spec Steward |
| `push-before-review` | Commit semantic groups locally and push branch before review-boundary evidence generation | review-boundary discipline | 0.2 SP | Implementer |
| `review-boundary-pr` | Open PR at review-boundary, self-review, request Spec Steward review, merge with merge-commit after sign-off | PR-lifecycle | 0.2 SP | Implementer |

---

## Success Criteria

- **SC-001**: Developer progresses through 5+ lifecycle boundaries with Squad commits at each; F-011 pause-and-confirm fires **zero times** (baseline hygiene verified)
- **SC-002**: When developer makes genuine out-of-band change to watched file (e.g., `.github/agents/squad.agent.md`), F-011 pause-and-confirm fires **immediately** (detection preserved)
- **SC-003**: At feature-closeout, `.specrew/last-start-prompt.md` has `session_state_active: false` so subsequent `specrew start` does not resume closed feature
- **SC-004**: All test cases (unit, integration, manual, regression) pass; no regressions to existing F-011 behavior

---

## Quality Gates

| Gate | Evidence | Status |
|------|----------|--------|
| **Baseline update mechanism** | `scripts/internal/sync-boundary-state.ps1` with new function signature | pending |
| **F-011 false-positive elimination** | Full lifecycle test results (IT-001, IT-002, MT-001) | pending |
| **Session-state integrity** | State validation in unit tests (UT-001–UT-003) + integration tests (IT-004–IT-006) | pending |
| **Error handling** | Failure scenario tests (IT-006) + code review | pending |

---

## Deferred Out of Scope

- Backfilling closed features' session state (applies prospectively only)
- Changing F-011's detection logic (only baseline management in scope)
- Changes to watched glob patterns (correctly defined in F-011)
- User-facing documentation/education (fix is transparent)
- Future improvements to baseline versioning or rollback (Phase 2 work)

---

## Files Modified

| File | Change | Scope |
|------|--------|-------|
| `scripts/internal/sync-boundary-state.ps1` | Add `Update-BaselineCommitHashInFrontmatter` function; integrate at line ~685 | Primary |
| `scripts/specrew-start.ps1` | No changes; existing `Get-BaselineCommitHash` and `Test-SessionLoadedFilesChanged` already work | N/A |
| `.specrew/last-start-prompt.md` | Baseline and session state updated at each boundary | State |
| `CHANGELOG.md` | Add entry documenting baseline hygiene fix | Documentation |

---

## Team & Ownership

| Role | Owner | Responsibilities |
|------|-------|------------------|
| Spec Steward | Alon Fliess | Approve spec, validate F-011 integration, authorize feature-closeout |
| Implementer | TBD | Code E2 helper function, integrate into boundary-sync, implement error handling |
| Reviewer | TBD | Write and execute tests (unit, integration, manual), code review, sign-off |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Update baseline **in** `Invoke-SpecrewBoundaryStateSync` | Single point of change; atomic with boundary recording; no separate sync step |
| Use `git rev-parse HEAD` | Standard, reliable; always available; returns full 40-char SHA-1 |
| Preserve other frontmatter fields | Maintain audit trail; no data loss; guarantee idempotency |
| Set `session_state_active: false` (not delete) at feature-closeout | Audit trail preserved; simpler error recovery; E1 already implemented this way |
| Apply to all 7 boundaries uniformly | Consistent invariant; minimal special cases; clear semantics |

---

## Related Features

- **F-011** (Conditional Pause on specrew-start When Session-Loaded Files Changed): Introduces baseline detection logic; Feature 029 fixes its false-positive root cause
- **Proposal 067** (Small-Fix Slice Methodology): Feature 029 is a small-fix slice exemplar (~6 SP, focused scope, clear boundary, measurable success)

---

## Maintained By

**Alon Fliess** | Last Updated: 2026-05-21
