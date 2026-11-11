# Iteration State: 001

**Schema**: v2
**Current Phase**: before-implement
**Iteration Status**: executing
**Last Completed Task**: T006
**Tasks Remaining**: T007-T015, T018 (10 planned)
**In Progress**: T002 (Windows green; Unix evidence owed), T003 (unit green; integration assertion 3 not run)
**Baseline Ref**: 52c9651cab6e84c6bcb362c11ebd20c882863255
**Updated**: 2026-11-11T16:30:00Z

## Execution Summary

- T001 (FR-001, recovery choice without console input): RED 5/7 in `56f452f3`, GREEN 7/7 in `837b4f09`.
- T002 (FR-002, over-claim dirty check separator): RED 1/3 in `abe6ef14`, GREEN 3/3 on Windows in the following fix commit. Acceptance also needs Unix: no CI step runs the suite yet (bug 5), so T002 stays in progress until a lane runs it on Linux (T015) or the maintainer rules otherwise.
  The T002 suite runs the validator only; `validator-hardening-iteration2.ps1` (assertion 2 updated) also runs
  `specrew start -NoLaunch` and is not run here until that path is read (T003/T014).
- T003 (FR-003, classifier ignores matched managed blocks): RED 8/8 in `d008e382`, GREEN 8/8 in the following fix
  commit. Assertion 3 of `validator-hardening-iteration2.ps1` runs `specrew start -NoLaunch` three times; it is not
  run here until that path is read for home writes (T014's read). Lines 2995-3001 can write the user profile.
- T004 (FR-004, FR-005): hand-over record `handover-to-203.md` opened with five sections (HO-206-1 to HO-206-5);
  open until T018.
- T005 (FR-008a, condition 1): `closed-open-table.md`, 161 iterations, 36 changes in five groups with reasons;
  198/010 awaited the maintainer's ruling; ruled 2026-11-11 (198/010 abandoned and superseded in T007, with
  conditions; group C accepted; group E unchanged).
- T006 (FR-008a, one definition of closed): RED 8/13 in `719f1cef`; option 1 ruled 2026-11-11 with conditions,
  RED 9/16 in `139734f0` (closure-claim words count; "not closed", "not yet closed", "to be closed after review"
  and "blocked" do not); GREEN 16/16 in the following fix commit. Condition 2: the generator rerun after the fix
  keeps the "New" column and totals in every row (`closed-open-table-post-t006.md`); rerun again after T007.
  W51's fixture gains `Iteration Status: complete` (DRIFT-206-I001-003). The deployed hash file is refreshed:
  T002's entry in `52662ebc`, T006's two in its fix commit (DRIFT-206-I001-004, bug 10).

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->