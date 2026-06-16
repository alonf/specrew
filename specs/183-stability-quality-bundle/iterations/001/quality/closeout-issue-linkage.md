# T010 Closeout Issue Linkage and Traceability Evidence

**Schema**: v1
**Task**: T010 - Closeout issue linkage and traceability evidence
**Trace**: TG-001, TG-002, TG-005
**Recorded At**: 2026-06-16T11:05:00Z
**Updated At**: 2026-06-16T15:09:14Z
**Overall Verdict**: pass-for-readiness

## Issue Linkage Ledger

TG-005 requires feature closeout to link fixing commits to issues #2446, #1627,
and #1761. The linkage state is:

| Issue | In-scope fix surface | Tasks | Fixing commit state | Closeout binding |
| ----- | -------------------- | ----- | ------------------- | ---------------- |
| #2446 | Session identity and journal state no longer collapse missing/blank/malformed host IDs into global `unknown`; per-launch fallback tokens drive dedupe/status/breaker state. | T003 | `4dc710ec` (`boundary(implement): T003 stabilize session id fallback`) | Use `4dc710ec` as the #2446 fixing commit unless later squash/rebase changes the hash. |
| #1627 | Feature-closeout dirty `.specify` classification, no-upstream wording, and auto-detect dashboard refresh. | T004 | Pending final implementation commit; current fix surface is in the working tree. | Feature closeout must link the final T004-containing commit to #1627 before the issue is closed. |
| #1761 | The two in-scope mechanical reds (#2/#3) use scratch git isolation and assert the module-internal lifecycle sync script copy. Red #1 remains out of scope. | T005 | Pending final implementation commit; current fix surface is in the working tree. | Feature closeout must link the final T005-containing commit to #1761 before the issue is closed, explicitly excluding red #1. |

## Proposal Handling

- No files under `file:///C:/Dev/183-stability-quality-bundle/proposals/` were edited for this iteration.
- Proposals remain referenced as product/history context only.
- The out-of-scope set remains unchanged: Proposal 191, Proposal 165 / Issue #2081, Proposal 168, Issue #78, Proposal 159 Tier 2, Proposal 123, and Issue #1761 red #1.
- Closeout must not silently edit proposal files or imply proposal closure from this feature.

## Traceability Check

Traceability check command shape:

```powershell
# Parsed specs/183-stability-quality-bundle/iterations/001/plan.md
# against specs/183-stability-quality-bundle/spec.md.
```

Result:

- Verdict: `PASS`
- Tasks checked: `11`
- In-scope FR/SC/TG requirements checked: `24`
- Covered requirements: `24`
- Orphan tasks: none
- Stale requirement references: none
- Uncovered in-scope requirements: none

Task-to-authority summary:

| Task | Authority refs |
| ---- | -------------- |
| T001 | FR-001, FR-002, SC-001, SC-002 |
| T002 | FR-004, SC-004 |
| T003 | FR-003, SC-003 |
| T004 | FR-005, SC-005 |
| T005 | FR-006, SC-006 |
| T006 | FR-007, SC-009, TG-004 |
| T011 | FR-008, SC-010, TG-006 |
| T007 | SC-007, TG-003 |
| T008 | SC-007 |
| T009 | SC-008, SC-009, TG-004 |
| T010 | TG-001, TG-002, TG-005 |

Requirement-to-task summary:

| Requirement set | Coverage |
| --------------- | -------- |
| FR-001 through FR-008 | Covered by T001, T002, T003, T004, T005, T006, T011 |
| SC-001 through SC-010 | Covered by T001, T002, T003, T004, T005, T006, T007, T008, T009, T011 |
| TG-001 through TG-006 | Covered by T006, T007, T009, T010, T011 and this evidence |

## Closeout Gate Notes

- This artifact is sufficient for T010 readiness evidence because it records the
  issue mapping, proposal non-edit rule, and bidirectional traceability result.
- DR-004 Option A added T011/FR-008/SC-010/TG-006 after the first readiness
  evidence pass; this artifact was updated to include the expanded scope.
- It does not close #1627 or #1761 by itself. Those issues require the final
  implementation commit hashes after the working tree is committed or squashed.
- If the branch is squashed or rebased, update the #2446 row from `4dc710ec` to
  the final commit hash before feature closeout.
