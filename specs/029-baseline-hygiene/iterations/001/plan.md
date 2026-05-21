# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: retro  
**Capacity**: 3.6/20 story_points  
**Started**: 2026-05-21  
**Completed**:  

## Summary

Iteration 001 covers the core implementation of baseline hygiene to fix false-positive session-loaded file change detection in F-011 (Conditional Pause on specrew-start When Session-Loaded Files Changed). This iteration addresses the root cause: `baseline_commit_hash` frozen at feature-start instead of being updated at lifecycle boundaries.

**Primary Focus**: E1 (Feature-Closeout Invalidation, P2, ~1 SP) and E2 (Boundary-Based Baseline Updates, P1, ~2-3 SP)  
**Target User Stories**: US-1 (Lifecycle baseline hygiene), US-2 (Out-of-band user changes still trigger pause), US-3 (Feature-closeout clears session state)  
**Success Criteria**: SC-001, SC-002, SC-003, SC-004 (zero false positives across 5+ boundaries; correct genuine-change detection; clean feature-closeout)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001 | Boundary-based Baseline Updates | ✅ E2 | Implementer | Update baseline at specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout |
| FR-002 | Baseline Update Mechanism | ✅ E2 | Implementer | Read/write `.specrew/last-start-prompt.md` frontmatter with current HEAD hash |
| FR-003 | Feature-Closeout Invalidation | ✅ E1 | Implementer | Delete or mark `session_state_active: false` at closeout |
| FR-004 | F-011 Integration | ✅ E2 | Spec Steward | Verify F-011 uses updated baseline correctly |
| FR-005 | Idempotency | ✅ E2 | Implementer | Re-running baseline update must not corrupt state |
| FR-006 | Error Handling | ✅ E2 | Implementer | Graceful error handling for git/file-I/O failures |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | All tasks trace to approved FR-001 through FR-006 and User Stories US-1, US-2, US-3 from spec.md |
| **Traceability** | ✅ PASS | Each task maps to specific functional requirements and success criteria |
| **Ownership** | ✅ PASS | Tasks assigned to Implementer, Spec Steward, and Reviewer roles |
| **Capacity** | ✅ CONFIRMED | Capacity fixed at 3.6 SP; scope-reduced per 2026-05-21 planning repair; E1 already implemented (validation-only) |
| **Execution Support** | ✅ PASS | Integration tests, error scenarios, and idempotency validation planned |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| baseline-update-boundary | Update baseline at each lifecycle boundary (specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout) | FR-001, FR-002 | US-1 | 1 | Implementer | done |
| closeout-invalidation | Invalidate session state at feature-closeout (delete or mark `session_state_active: false`) | FR-003 | US-3 | 0.5 | Implementer | done |
| git-integration | Integrate `git rev-parse HEAD` calls and ensure correct sequencing post-Squad-work | FR-002 | US-1 | 0.5 | Implementer | done |
| idempotency-test | Verify re-running boundary sync at same boundary does not corrupt state | FR-005 | US-1 | 0.3 | Reviewer | done |
| error-handling | Implement error handling for git failures and file I/O errors | FR-006 | US-1 | 0.3 | Implementer | done |
| f011-integration-test | Validate F-011 uses updated baseline; zero false positives (no genuine changes), correct detection (genuine changes) | FR-004 | US-2 | 0.5 | Spec Steward | done |
| full-lifecycle-test | Execute complete feature lifecycle (specify through feature-closeout) with Squad commits at each boundary | SC-001, SC-002, SC-003 | US-1, US-2, US-3 | 0.5 | Reviewer | done |

**Total Effort (Planned)**: 3.6 story_points (scope-reduced per 2026-05-21 planning repair; E1 validation-only)

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | --- |
| Effort Unit | story_points | Tracked against this iteration's planned/actual effort |
| Capacity per Iteration | 20 | Baseline; this iteration's actual assignment: 7 story_points |
| Iteration Bounding | scope | Keep requirements fixed; defer overages to next iteration if needed |
| Time Limit (hours) | n/a | Uses scope-based bounding, not time-based |
| Overcommit Threshold | 1.0 | Warn when planned effort > capacity |
| Defer Strategy | manual | Explicit deferral of lower-priority work if needed |
| Calibration Enabled | true | Retrospective will suggest capacity adjustments |

---

## Quality Planning

**Phase Scope**: `phase-1-baseline-governance`  
**Inferred Quality Profile**: `quality-profile.powershell-governance.v1`  
**Recognized Stack**: PowerShell + YAML frontmatter + git integration

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
| --- | --- | --- | --- |
| `baseline-update-mechanism` | implementation | `scripts/internal/sync-boundary-state.ps1` | pass |
| `f011-false-positive-elimination` | integration | Full lifecycle test results | pass |
| `session-state-integrity` | integration | State validation in tests | pass |

---

## Deferred Out of Scope

- Backfilling closed features' session state (baseline hygiene applies prospectively only)
- Changing F-011's detection logic (only baseline management is in scope)
- Changes to watched globs for session-loaded paths (correctly defined in F-011)
- User-facing documentation or education (fix is transparent)

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-21
