# Iteration State: 001

**Schema**: v2
**Current Phase**: before-implement
**Iteration Status**: executing
**Last Completed Task**: T013
**Tasks Remaining**: T014, T015, T018 (3 planned)
**In Progress**: T002 (Windows green; Unix evidence owed), T003 (unit green; integration assertion 3 not run)
**Baseline Ref**: 52c9651cab6e84c6bcb362c11ebd20c882863255
**Updated**: 2026-11-12T11:44:00Z

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
  T002's entry in `52662ebc`, T006's two in its fix commit (DRIFT-206-I001-004, bug 10). The self-leak firewall
  refused six comments citing the feature id; fixed in `ba2d1d8b` (DRIFT-206-I001-005).
- T007 (FR-005, FR-006), **done 2026-11-12**: 198/011 abandoned by the 2026-11-10 ruling in `7e3ddd78`, in T009's
  push; acceptance met: a CI-mode full-repository run (`-FullRun`, `CI=true`) on `3b5dcadf` exits 0 with no
  failure (frozen filter 18, closed filter 128; 198/011 closed). History: 197/006 abandoned (ruling 2026-11-10), 198/010 abandoned and
  superseded (ruling 2026-11-11: DRIFT-198-I010-004 stays open, handed to 203 as HO-206-4; T082 stays
  `needs-rework`), each with a Disposition section; `Current Phase` unchanged. 197/006 keeps plan.md `Status:
  retro` (it has a `retro.md`), following 174/007 (DRIFT-206-I001-006). `.specrew/legacy-frozen.yml` with 18
  entries. Table rerun (with 198/011 applied locally): all 18 frozen rows agree; 0 mismatches in 161 rows.
  **Held back (maintainer, 2026-11-11, option 1):** 198/011's abandonment. With a `retro.md`, its plan.md cannot
  say `abandoned` (stale-status rule) and with `retro` it keeps the review-verdict finding; the exemption for an
  iteration abandoned by recorded ruling is T009's, and 198/011 lands in T009's push. The acceptance (the nightly's
  198/011 failure gone) is not met until then. Local CI-mode full-repository run with 198/011 applied: 198/011
  gone; 7 failures, all frozen entries (141/006, 141/008, 174/006, 174/008-011), judged live until T008; 5
  missing-dashboard warnings on abandoned iterations (197/002, 197/007, 197/008, 198/005, 198/010), which T008's
  "dashboard check applies to complete only" removes. T010 replays after T008-T011.
- T008 (FR-007, SC-005, frozen means judged by nothing): RED 5/6 in `ad11f315` (the guard pinning the 18 keys
  passes; 7 of the 18 frozen entries here FAIL before the fix); GREEN 6/6 in the following fix commit. The
  validator skips a frozen entry in every mode (full-repo, `-IncludeClosed`, changed-only, explicit targets) and
  says so in a "frozen filter" line; the dashboard check skips an iteration whose status is `abandoned` (read as:
  every closed iteration except abandoned ones). Also green: T006's suite 16/16, W51 8/8,
  `non-specrew-session-bypass`, `validate-governance-changed-only`, the self-leak lint. Not run:
  `feature-017-dashboard-core.ps1` (it runs `scripts/specrew.ps1`, not yet read for home writes).
- T009 (FR-008; maintainer 2026-11-12, option 1 with conditions; real size 2.0 points by ruling,
  DRIFT-206-I001-008): RED 17/20 in `9815d2f7`, GREEN 20/20 in `54cb8e18`; then, found before the push by
  `validate-governance-changed-only` (its fixture loads the installed module's older renderer, whose index reader
  drops the stamp, and strict mode threw), RED 3/23 in `36dfd605`, GREEN 23/23 in `3b5dcadf`: the validator reads
  the index before loading the renderer, and a missing stamp key is unstamped. The closed-iteration dashboard check
  declares `since: 2026-05-26` and `applies_to_status: complete` and judges an iteration only when iteration
  closeout stamped its index entry (`closed_at_source: closeout`) on or after that date; this replaces its
  feature-number cut-off (the feature-closeout dashboard check keeps its cut-off). Closeout writes the stamp. An
  iteration abandoned by recorded ruling (a Disposition section naming the maintainer's ruling with its date) is
  not held to the plan-status or review-verdict rule; abandoned with no recorded ruling still gets both. Fixtures:
  T008's suite and `non-specrew-session-bypass` get stamped entries (DRIFT-206-I001-009). "Abandoned is closed only
  with a recorded ruling" is required in iteration 002 (DRIFT-206-I001-010). Also green: T008 6/6, T006 16/16,
  `closed-iteration-index`, `capacity-grandfather-closed-iterations`, `closed-iterations-are-history` 8/8,
  `every-suite-is-named-by-a-lane`, `feature-018-dashboard`, `validate-governance-changed-only` (on `3b5dcadf`), the
  self-leak lint. Not run, read instead:
  `closeout-records-on-approval.tests.ps1` (drives `sync-boundary-state.ps1`, home path unread; it counts
  `- feature:` lines only, so the stamp line does not change it; no lane runs it) and
  `sealed-iteration-writers.tests.ps1` (runs `scripts/specrew.ps1`).
- T011 (FR-010): RED 1/2 in `5b1695a3`, GREEN 2/2 in `85f62dc4`. The review-verdict finding reads the
  iteration's status: a `retro` iteration is told "Retro iterations require ..."; a `complete` one keeps its
  message. Also green: T009 23/23, T008 6/6, T006 16/16, `closed-iterations-are-history` 8/8,
  `non-specrew-session-bypass`, the self-leak lint.
- T010 (FR-006, FR-008a, SC-003; design condition 1): CI-mode `-FullRun` on `9de20285` exits 0, no failure: 159
  iterations, 18 frozen and 128 closed skipped, 13 validated, all PASS. Of T005's 36 changed rows: the 12 now open
  all PASS; 18 frozen and 5 closed (group B, 198/009) skipped; 197/006 closed since T007. Validated explicitly as
  well, all PASS: 197/002, 197/006-008, 198/005, 198/009-011. The 6 warnings are `handoff-block-missing` on 206's
  own boundary commits; none names a closed iteration. No new finding. 017/001 and 040/001 have no `plan.md` and
  are not iterations to the validator (159 against the table's 161; their rows did not change).
- T012 (FR-009; design condition 4): RED 13/14 in `ae9a3c9d`, GREEN 14/14 in `ff0e78b9`. The validator writes a
  findings file (`-FindingsJsonPath`); `.github/scripts/nightly-tracking-issue.ps1` keeps one tracking issue
  (open, quiet, comment, close; no path, user or machine name); the notify job alone holds `issues: write`. By
  the maintainer's ruling the notifier is workflow-only (not in the module FileList), and the notify job runs only
  for the default branch: RED 1/15 in `85d275bb`, GREEN 15/15 in `867d4752` (DRIFT-206-I001-011).
- T013 (FR-011, SC-004): RED 10/26 in `dd57e075`, GREEN 25/26 in `798ded31`. `tests/support/test-census.ps1` is the
  one definition of a test, read by the lane guard and the release full sweep: every `.ps1` under `tests/` except
  `fixtures/` and `tests/support/`, 13 listed exclusions with reasons, 36 held tests ("not read yet (T014)"), two
  CI-run registries. SC-004 is proved both ways on temp fixtures for five file names. The sweep was not run for
  real: `-ListOnly` (475 to run, 36 held) and a temp-repository run of two trivial scripts test it. The one guard
  failure is this repository's 36 unregistered tests, green at T015 (DRIFT-206-I001-012).

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