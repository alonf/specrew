# Drift Log: Iteration 001

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 30
**Resolution rate**: 80% (24/30 resolved; 028 reported for feature 203's triage; 017 deferred to iteration 002 planning; 007 deferred to iteration 002 as bug list item 12; 010 deferred to
iteration 002 as a required item: feature 206 does not close without it; 022 reported for feature 203's triage; 025
deferred to iteration 002 by the maintainer's ruling)
**Specification drift**: None detected (process drift only)

## Events

### DRIFT-206-I001-001 — the OVERRIDE 5 revert, pushed alone, turned Specrew CI red on two iterations

- **Recorded**: 2026-11-11, at the maintainer's instruction.
- **Run**: Specrew CI run 42918626688 on `a3778f1a` (the revert of OVERRIDE 5, pushed alone by the
  maintainer's choice of "two plain pushes, no history rewrite"). Lint failed; the Deterministic gate and
  Contract lane were skipped. Test and Cross-Platform Validation were green.
- **Trigger**: the revert touched `.specrew/iteration-config.yml`, one of the validator's global-state paths,
  relative to the push base `435332da`. So `-ChangedOnly` fell back to the whole repository
  (`global-state-changed`, 159 iterations).
- **Failures, and what fixes each**:
  - `198-beta2-hardening/011`: "Complete iterations require review.md overall verdict 'accepted' (found
    'needs-rework')". The nightly's existing failure; fixed by T007 (marked abandoned by the maintainer's
    ruling).
  - `206-bug-bash/001`: "plan.md Capacity total '22' does not match iteration-config capacity_per_iteration
    '20'" (Capacity line and Effort Model). At `a3778f1a` the plan still read 21.75/22; fixed by `99eb5132`
    (20/20, T016 and T017 deferred to iteration 002), which is in the second push.
- **Process miss**: the revert was not validated on its own before it was pushed. The local runs validated
  the two commits together (and changed-only against `origin/main`, not against the push base CI uses), so
  the 206/001 failure was not seen. The maintainer had expected 198/011 only.
- **Resolution (2026-11-12)**: 198/011's failure is gone: `7e3ddd78` marks it abandoned by the maintainer's
  ruling, and T009's exemption (`54cb8e18`) stops the review-verdict rule for an iteration abandoned by
  recorded ruling. The 206/001 failure was fixed by `99eb5132`.
- **Class closure**: NONE — no executable guard is added in this feature; the working rule from here on is to
  validate each pushed head alone, changed-only against the push base CI will use (`SPECREW_SCOPE_BASE_REF`
  set to the previous pushed commit), before every push.

### DRIFT-206-I001-002 — external change to a real-home hook file during T001

- **Recorded**: 2026-11-11, at the maintainer's instruction.
- **What**: `~/.codex/hooks.json` changed between the T001 baseline hash (03:30:55 local) and the pre-test
  hash (03:32:18 local). File time 03:31:38 local, 43 seconds after the baseline.
- **Hashes (SHA-256)**: baseline `b3a87829a11e8c2e7f2b360dd4ed0e7220749ec52c59f81009fdea622555dc94`;
  changed to `8adb8157fb01749d2931b5a6223228ad1885d6d73240fbd3517ee40b49ff0e16`. The other 9 files in the
  set were unchanged; no file added or removed.
- **Cause**: feature 203's session (the maintainer's finding). No 206 test or script was running; the T001
  test run itself left all 10 files unchanged.
- **Resolution**: 206 stopped and restored nothing. The file was restored outside 206 and a new baseline at
  10:42:51 local matched the first baseline on all 10 files; T001 resumed.
- **Class closure**: NONE — the writer is outside 206. Working rule from here on (maintainer): a hash change
  while none of 206's own tests or scripts ran is reported in one line and work continues on anything that
  runs no Specrew script; a full stop applies only when the change falls inside one of 206's own runs.

### DRIFT-206-I001-003 — T006 changed a test file outside its owned files: the W51 fixture

- **Recorded**: 2026-11-11, at the maintainer's instruction (T006 ruling, condition 3).
- **What**: `tests/integration/closed-iterations-are-history.tests.ps1` is not in T006's owned files. Its shared
  fixture (`New-TwoIterationProject`) closed iteration 001 only through `**Current Phase**: iteration-closeout`
  plus `RETRO COMPLETE`, which is the state.md text heuristic that FR-008a removes from the closed definition.
  After T006, W51 part 2 read that iteration as open and failed ("closed-iteration filter: 1 closed iterations
  skipped" not printed).
- **Change**: the fixture's state.md gains `**Iteration Status**: complete`, plus a comment naming the reason.
  W51's point is kept: the iteration is closed by its own state.md, with no closed-index entry.
- **Approval**: the maintainer, 2026-11-11 ("approved to add Iteration Status: complete to its test iteration").
- **Resolution**: lands in T006's fix commit.
- **Class closure**: NONE — a one-off fixture follow-up to a definition change the maintainer ruled on; no
  mechanism is needed to stop a test from following a ruled definition.

### DRIFT-206-I001-004 — T002 changed a deployed file without refreshing its hash

- **Recorded**: 2026-11-11, at the maintainer's instruction (T006 ruling, hash-file item 4).
- **What**: T002's fix commit `6acb84aa` edited the `.specify` mirror of `validate-governance.ps1` and left its
  entry in `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` at the old value. The
  validator's deployed-machinery integrity check then reports "The deployed Specrew machinery ... does not match
  what was installed" for every iteration with a review.md that it validates. T006's uncommitted change added
  `shared-governance.ps1` to the mismatch.
- **Evidence**: hashes computed the way the check computes them (`Get-SpecrewDeployedExtensionManifest`,
  CR-stripped, SHA-256) match the file at `6acb84aa~1` for both files; from `6acb84aa`, `validate-governance.ps1`
  differs. `tests/integration/validate-governance-changed-only.tests.ps1` failed 3 assertions on it, all with
  this error (run from this worktree, a short path, on the T006 working tree).
- **Why nothing caught it**: 206's own iteration has no review.md, so 206's validator runs stayed green, and no
  CI workflow runs the suite that fails (bug-list item 10).
- **Resolution**: `52662ebc` refreshes T002's entry (old `7cee2741...e3bc`, new `a7076e71...518f`); T006's fix
  commit refreshes both entries for its own change. Values in the bug-list item.
- **Class closure**: a working rule from the maintainer (2026-11-11): any commit that touches a file under
  `.specify/extensions/specrew-speckit/` refreshes the hash file in the same commit. The executable guard (a CI
  step) is proposed in bug-list item 10; no workflow is changed in this feature yet.

### DRIFT-206-I001-005 — T006's comments cited a feature id in the deployed surface; Specrew CI went red

- **Recorded**: 2026-11-11.
- **Run**: Specrew CI run 43068147301 on `b76dd4d8`. "Self-leak firewall (deploy surface)" failed, and the
  Deterministic gate failed on the same check (`tests/unit/self-leak-lint.tests.ps1`, 1 of 131). Test and
  Cross-Platform Validation were green (the macOS fault-matrix case passed).
- **What**: six comments added by T006 in `extensions/specrew-speckit/scripts/shared-governance.ps1` (4) and
  `validate-governance.ps1` (2) began with the feature id `F-206`, which the self-leak lint refuses in files
  deployed to consumer projects.
- **Process miss**: the pre-push checks were markdownlint and validate -ChangedOnly only; the self-leak lint
  (`scripts/internal/lint-self-leak.ps1`) was not run locally. It reproduced the 6 hits before the fix and is
  green after.
- **Resolution**: the comments name the requirement and the rule, not the feature; the `.specify` mirrors and
  their hash entries are refreshed in the same commit.
- **Second miss, same push sequence**: the fix and this entry were pushed as `dc932cda` although validate
  -ChangedOnly had failed on this entry's Class closure format; the push step tested the home-hash script's exit
  code instead of the validator's. Specrew CI run 43071573503 went red at Lint for it (Deterministic gate skipped).
  `f37e639d` fixed the format; its CI runs (Specrew CI 43071834486, Test, Cross-Platform Validation) were all green.
- **Class closure**: NONE — no executable guard is added in this feature; working rule from here on: the self-leak
  lint joins 206's pre-push checks whenever a push touches `extensions/` or `.specify/`.
  The push step now checks the validator's own exit code.

### DRIFT-206-I001-006 — the validator had no way to mark an iteration abandoned once retro.md exists

- **Recorded**: 2026-11-11, at the maintainer's instruction (T007 ruling, condition 5).
- **What**: T007 marks 198/011 and 197/006 abandoned by ruling. Both have a `retro.md`. The validator accepts
  only `retro` or `complete` as plan.md `Status` for an iteration with a `retro.md` ("plan.md status 'abandoned'
  is stale"), and a plan at `retro` is held to the review-verdict rule ("Complete iterations require review.md
  overall verdict 'accepted'"). No plan status says "abandoned" and passes.
- **197/006**: keeps plan.md at `Status: retro` with state.md at `Iteration Status: abandoned`, following
  174/007 (state.md `abandoned`, plan.md `executing`). Its `review.md` records `accepted`, so the review-verdict
  rule does not fire, and it passes. Its Disposition section says why plan.md keeps `retro`. (Corrected
  2026-11-12: this entry first said 197/006 has no `review.md`; it has one.)
- **198/011**: has a `review.md` with verdict `needs-rework`; neither form passes. Its abandonment is held back
  from T007's push (maintainer, 2026-11-11, option 1).
- **Resolution**: T009 adds the rule, test first: an iteration whose state.md says `abandoned` with a recorded
  ruling is not held to the plan-status rule or the review-verdict rule; `abandoned` with no recorded ruling
  still gets both. 198/011's abandonment lands in T009's push. Resolved 2026-11-12: RED 17/20 in `9815d2f7`,
  GREEN 20/20 in `54cb8e18`; 198/011 abandoned in `7e3ddd78`, in the same push.
- **Class closure**: T009's validator rule and its tests: abandonment by recorded ruling becomes a status the
  validator accepts after `retro.md`, and an unrecorded `abandoned` stays refused.

### DRIFT-206-I001-007 — the three push runs on 4f315689 are stuck as queued; 4f315689 has no Specrew CI result

- **Recorded**: 2026-11-12, at the maintainer's instruction.
- **What**: the push of `4f315689` (2026-11-11 20:26Z) created Test 43096082467, Specrew CI 43096082485 and
  Cross-Platform Validation 43096082509. All three stayed `queued` with 0 jobs (API `updated_at` 20:26:38Z). Runs
  of other workflows on `main` with the same runner label (`ubuntu-latest`) kept completing, and GitHub's status
  page showed Actions operational. Feature 205's push runs from 20:30Z are stuck the same way.
- **GitHub refuses to clear them**: cancel answers "Cannot cancel a workflow run that is completed";
  force-cancel answers "Cannot cancel a workflow run that has not been queued yet" (HTTP 409); re-run answers
  "cannot be rerun; its workflow file may be broken". The three runs are still listed as queued.
- **Re-checked on demand**: Test 43112873232 and Cross-Platform Validation 43112877362 were started manually on
  `4f315689` (workflow_dispatch) at 22:34Z; both started at once and both are green.
- **Not re-checked**: Specrew CI has no manual trigger, so **`4f315689` has no Specrew CI result of its own**.
  Its changes are re-checked only as part of the next push, `ad31b2d5` (T008), whose Specrew CI run is
  43113590639.
- **Resolution**: none possible from here for the stuck runs; Specrew CI's missing manual trigger is bug list
  item 12, a candidate for iteration 002 (no workflow changed now).
- **Class closure**: NONE — the stuck runs are a GitHub-side state this feature cannot change; the gap that
  left a commit without a re-check is bug list item 12, deferred to iteration 002 by the maintainer.

### DRIFT-206-I001-008 — T009 is 2.0 points against its 1.5: scope added by ruling

- **Recorded**: 2026-11-12, at the maintainer's instruction (T009 ruling, condition 1).
- **What**: T009 is planned at 1.5 points. Its estimate, with the "abandoned is closed only with a recorded
  ruling" part moved to iteration 002, is 1.0 (`since`, the closure stamp, the dashboard check) + 0.75 (the
  recorded-ruling reader, the exemption, 198/011 landing) + 0.25 (the two fixtures) = **2.0 points**. The option
  put to the maintainer said "about 1.5"; that was an addition error, not a different estimate.
- **Cause**: the extra 0.5 is the exemption added to T009 by the maintainer's T007 ruling of 2026-11-11.
- **Ruling (maintainer, 2026-11-12)**: proceed at 2.0; the capacity file and T009's points stay unchanged
  (1.5 in tasks.md and plan.md; iteration 001 stays at 20/20 on paper).
- **Resolution**: human-decision; T009 done at the real size.
- **Class closure**: NONE — a one-off estimate error corrected by the maintainer's ruling; the sum is now shown
  with its parts so the next estimate can be checked.

### DRIFT-206-I001-009 — T009 changed a test file outside its owned files: the non-specrew-session-bypass fixture

- **Recorded**: 2026-11-12, at the maintainer's instruction (T009 ruling, condition 5), as DRIFT-206-I001-003.
- **What**: `tests/integration/non-specrew-session-bypass.tests.ps1` is not in T009's owned files. Its fixture
  closes `017-sample` iterations 002 and 003 with no closed-index entry, and it expects the two missing-dashboard
  warnings. After T009 the dashboard check judges only an iteration closeout stamped on or after 2026-05-26, so
  an unstamped one draws no warning and the suite would fail.
- **Change**: the fixture writes `.specrew/closed-iterations.yml` with both iterations stamped
  `closed_at_source: closeout`, `closed_at: 2026-11-01T10:00:00Z`, plus a comment naming the reason. The suite's
  point is kept: the managed and non-managed diagnoses still fire. T008's own fixture
  (`tests/unit/legacy-frozen-judged-by-nothing.tests.ps1`, inside T009's `tests/unit/**`) gets the same entries.
- **Approval**: the maintainer, 2026-11-12 ("approved to add a stamped index entry").
- **Resolution**: lands in T009's test commit `9815d2f7`; green before and after the fix.
- **Class closure**: NONE — a one-off fixture follow-up to a rule the maintainer ruled on; no mechanism is needed
  to stop a test from following a ruled rule.

### DRIFT-206-I001-010 — until iteration 002, an abandoned status with no recorded ruling counts as closed

- **Recorded**: 2026-11-12, at the maintainer's instruction (T009 ruling, condition 2).
- **What**: since T006, `Test-SpecrewIterationClosed` counts any `Iteration Status: abandoned` as closed, with or
  without a recorded ruling. T009 as planned would have made "abandoned" closed only with a recorded ruling; the
  maintainer moved that rule to iteration 002. Until it lands, an iteration can be closed, and skipped by the
  validator's closed filter, by writing `abandoned` in its state.md with no ruling. **This must not ship.**
- **Who it affects now**: group B of the T005 table (197/002, 197/007, 197/008, 198/005): abandoned, no recorded
  ruling, closed since T006. The T005 table stays as accepted.
- **Resolution**: deferred to iteration 002 as a **required item**: feature 206 does not close without it. It
  lands together with the maintainer's rulings on the four group B iterations, so the T005 table does not
  change. The T009 exemption is unaffected: it already applies only to iterations with a recorded ruling.
- **Class closure**: deferred — iteration 002's rule and its test (an `abandoned` status with no recorded ruling
  is not closed), with the closed definition's suite covering it.

### DRIFT-206-I001-011 — T012's notifier is at .github/scripts/, not scripts/internal/

- **Recorded**: 2026-11-12, at the maintainer's instruction (T012 ruling, option 2).
- **What**: tasks.md and plan.md name `scripts/internal/nightly-tracking-issue.ps1`. A shippable file beside
  `scripts/internal/lint-self-leak.ps1` must be in `Specrew.psd1`'s FileList (the release-gate
  `package-filelist-completeness` guard failed on it). The maintainer ruled the script workflow-only: a script
  that writes GitHub issues does not belong in the installed module.
- **Change**: the notifier is `.github/scripts/nightly-tracking-issue.ps1`, after
  `.github/scripts/sync-specrew-board.ps1`; the workflow and the test use that path. `Specrew.psd1` is unchanged.
  The approved tasks.md and plan.md text keeps the old path.
- **Same ruling, scope added**: the notify job runs only for the default branch, so a manual run on a feature
  branch cannot close or rewrite main's tracking issue; the validator job still runs on any branch. Test first:
  RED 1/15 in `85d275bb`, GREEN 15/15 in `867d4752`. T012's points are unchanged.
- **Resolution**: human-decision; landed in `ae9a3c9d` (test path), `ff0e78b9` (fix) and `867d4752`.
- **Class closure**: NONE — a one-off placement decision; `package-filelist-completeness` already refuses a
  shippable file missing from the FileList, and the T012 suite pins both the path and the branch condition.

### DRIFT-206-I001-012 — T013 changed a test file outside its owned files: the full-sweep-direct-exit fixture

- **Recorded**: 2026-11-12, at the maintainer's instruction (T013, reply 1), as DRIFT-206-I001-003.
- **What**: `tests/unit/full-sweep-direct-exit.tests.ps1` is not in T013's owned files. It copies only
  `tests/full-powershell-test-sweep.ps1` into a scratch fixture and runs it. After T013 the sweep reads its definition
  of a test from `tests/support/test-census.ps1`, which the fixture did not have, so the suite failed ("The term
  '...\tests\support\test-census.ps1' is not recognized"). It runs at release cadence only.
- **Change**: the fixture also copies `tests/support/test-census.ps1`, plus a comment naming the reason. The suite's
  point is kept: a direct assertion script that exits 1 is still a failed file.
- **Same ruling, scope added**: the census holds the 36 tests that no lane, CI step or registry ran before, with the
  reason "not read yet (T014)". The guard still counts them and fails on this repository until T015; the sweep lists
  them as held and does not run them. At T015 every held test moves to registered or excluded, and a test then
  requires the held list to be empty; a script T014 finds writing the home folder is excluded with the reason
  "writes the real home; not run until feature 203's private test home is merged". T013's points are unchanged.
- **Approval**: the maintainer, 2026-11-12 ("1: approved").
- **Resolution**: lands in T013's fix commit `798ded31`; the suite passes after it.
- **Class closure**: NONE — a one-off fixture follow-up; the lane guard's fixture run of the sweep now copies the
  census the same way, so a sweep that cannot find its census fails there first.

### DRIFT-206-I001-013 — T015 changed test files outside its owned files: the profile override and the lane guard

- **Recorded**: 2026-11-12, at the maintainer's instruction (T014 ruling, item 3: "This is a change to test files
  outside T015's list; drift entry").
- **What**: T015 owns `.github/workflows/specrew-ci.yml`, `.specrew/release-gate-suites.txt`,
  `.specrew/verification-plan.json` and `tests/support/test-census.ps1`. By the ruling it also changes:
  - the eight scripts that run `scripts/specrew-start.ps1` (`project-path-resolution-regression.ps1`, the six
    `specrew-start-*.ps1`, `validator-hardening-iteration2.ps1`): each sets `SPECREW_USER_PROFILE_PATH` to a temp
    file at its top, so `specrew start` writes its user profile there and never to the real home, whatever shell
    runs the script;
  - `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` (T013's file): the test the ruling requires (item 6: the
    held list is empty), the profile override checked in each of the eight scripts, and each held script found where
    the ruling put it.
- **Same ruling, decisions recorded**: `feature-017-dashboard-core.ps1` and `feature-018-rich-dashboard.ps1`, run
  alone at T015, are red, and so is `validator-hardening-iteration2.ps1` (SC-002, ruled 2026-11-12 option 1); excluding a red script needs the maintainer's ruling under FR-012, and the ruling
  (2026-11-12) excludes each with its cause as the reason, a bug-list entry each (items 19, 20 and 21), fix in iteration 002; SC-002 is not met in iteration 001 and is
  required in iteration 002. `project-path-resolution-regression.ps1` (SC-001) is not registered until the maintainer has seen its
  supervised run (item 3c); the held list must still be empty (item 6), so it is excluded with the reason "awaits
  the maintainer" until that ruling.
- **Approval**: the maintainer, 2026-11-12 (T014 ruling, items 3 and 6; the dashboard ruling).
- **Resolution**: RED 9/34 in `963fc149`, GREEN 33/34 in `8f1e5f0c` (the override); RED 16/49 in `ec541bae`, GREEN
  49/49 in `95c28953` (the held list empty, each script where the rulings put it).
- **Class closure**: the lane guard fails if any of the eight scripts loses its override or sets it after its first
  `specrew start` call. Scripts outside the eight that run `specrew start` (those CI already ran before 206) are not
  covered by that check.

### DRIFT-206-I001-014 — T003's fix stopped `specrew start` when copilot-instructions.md is missing on one side

- **Recorded**: 2026-11-12, at the maintainer's instruction (SC-002 ruling, item 4).
- **What**: found at T015, when the six `specrew-start-*` scripts ran for the first time. Four were red: the second
  `specrew start` exited 1 with "Cannot bind argument to parameter 'BeforeContent' because it is an empty string."
  T003's fix (`0621a076`) made `Get-RestartTriggerFiles` read both versions of `.github/copilot-instructions.md`
  and call the classifier with content; the classifier's mandatory `-BeforeContent` and `-AfterContent` allow
  `$null` but not an empty string, which is what a file added or deleted since the baseline commit gives. Before
  T003 the classifier read the files itself and assigned the empty side internally, so binding never saw it. In a
  user's project this hits the second `specrew start` after the first one created the instructions file.
- **How it escaped T003's own tests**: T003's unit suite exercised the pure functions with content on both sides,
  and its one check on `specrew-start.ps1` read the source text (that the call passes `-BeforeContent`) without
  executing `Get-RestartTriggerFiles`. The two runs that would have executed it were not available: assertion 3 of
  `validator-hardening-iteration2.ps1` was not run until the start path was read for home writes (T014), and the six
  `specrew-start-*` scripts ran in no lane (item 5), so nothing ran them after T003 either.
- **Fix**: RED 2/10 in `968022f3` (the function, extracted from `specrew-start.ps1`, is executed on a temp
  repository: a file added since the baseline, a file deleted since it); GREEN 10/10 in `30fa853a`. With either side
  missing or empty, the classifier reads the files itself and compares the absent side as empty, as before T003.
  The six `specrew-start-*` scripts are green after it, each run alone with home unchanged.
- **Approval**: the maintainer, 2026-11-12 (fix here: the cause is this feature's item, FR-003).
- **Class closure**: the six `specrew-start-*` scripts now run per push (T015), so a change to the start path's
  classification is executed on every push; the T003 suite executes the call site instead of reading its text.

### DRIFT-206-I001-015 — T015 changed SC-001's script: its fixture copies tracked files only

- **Recorded**: 2026-11-12, at the reviewer's ruling under the maintainer's delegation (T015 report, SC-001 option 1).
- **What**: `tests/integration/project-path-resolution-regression.ps1` is outside T015's owned files (DRIFT-013
  already covers its profile override). Its first supervised run was red because it copied the developer's
  gitignored session state into its fixture (bug list item 22). Its `.specrew` copy now takes only the files git
  tracks, as a fresh checkout has them; the other four fixture folders are copied as before. The ruling preferred
  tracked-only over dropping the two named files, because the class fix also keeps the authority, review and
  runtime stores out of a temp copy.
- **Approval**: the reviewer session, 2026-11-12, under the maintainer's delegation (a routine ruling inside the plan;
  no approval carried).
- **Resolution**: RED 1/50 in `b9354aff`, GREEN 50/50 in `7c8b5cf7`; supervised run 2 (red, a different cause: missing session files read as stale) reported in
  `t015-registration.md`.
- **Class closure**: the lane guard fails if the script's `.specrew` copy stops going through `git ls-files`. The
  other fixture builders that copy repository folders are not covered.

### DRIFT-206-I001-016 — T015 changed SC-001's start case: it passes a recovery choice

- **Recorded**: 2026-11-12, by the maintainer's choice of option 1 ("Yes for 1 about the Specrew start", relayed by the
  reviewer session).
- **What**: supervised run 2 showed that a fresh copy of a governed project (features under `specs/`, the tracked
  `.specrew` files, no session files) is stale state to `specrew start`: "Session-state file missing on disk:
  last-start-prompt.md ... start-context.json", and with no console it refuses (item 1, as T001 fixed it). The
  start case of `tests/integration/project-path-resolution-regression.ps1` now passes `-RecoveryChoice A`, so start
  re-anchors and the case measures path resolution. Recovery A was read before the run: it sets an in-memory resume
  override and a directive (`scripts/internal/session-recovery.ps1:513-560`), read before run 3; no home path, no hook deployment.
- **Approval**: the maintainer, 2026-11-12 (option 1).
- **Resolution**: RED 1/51 in `0b54a3e6`, GREEN 51/51 in `3e3ae481`. Supervised run 3 was green on every check but
  rewrote this repository's `state.md` (bug list item 23); see DRIFT-206-I001-018 and -019.
- **Class closure**: NONE — a test change only; in the product, the question whether a governed project with no session files (a fresh
  clone) is stale state is left open for the maintainer, with the input in DRIFT-206-I001-017.

### DRIFT-206-I001-017 — input to iteration 002: the maintainer no longer uses `specrew start`

- **Recorded**: 2026-11-12, at the maintainer's instruction (relayed by the reviewer session). Not acted on.
- **What the maintainer said**: "I do not use Specrew start for a long time since we have the startup hook."
- **Context the reviewer found**: `docs/getting-started.md:135` says the SessionStart hook is the primary path and
  `specrew start` is optional; `README.md:150` says that on a hook-capable host you just launch the CLI.
  `scripts/specrew-start.ps1` is 3,562 lines.
- **Bearing on this feature**: SC-001 and SC-002 both run through `specrew start`, and so do the T003 regression
  (DRIFT-206-I001-014), bug list item 21 (SC-002's cause) and the open question whether a fresh clone is stale state
  (item 22), and the outside write and the init probe found later (items 23 and 25). For iteration 002 planning, a one-page fact sheet (`iterations/001/specrew-start-facts.md`) lists what `specrew start`
  still does that the session hooks do not and what each start-only item would cost, so that the maintainer can
  decide whether it is kept, frozen to bug fixes, or retired before any new design work on it.
- **Resolution**: deferred to iteration 002 planning (maintainer's decision).
- **Class closure**: NONE — an input to a decision, not a defect.

### DRIFT-206-I001-018 — T015 isolated SC-001's fixture from this repository

- **Recorded**: 2026-11-12, by the maintainer's option 1 ("1", relayed by the reviewer session at about 23:45 local),
  with the reviewer's conditions.
- **What**: supervised run 3 of `tests/integration/project-path-resolution-regression.ps1` was green on every check
  but rewrote this repository's real `state.md` (bug list item 23). The fixture sat under this repository's `.scratch`
  without a git repository of its own (item 24). `state.md` was restored from git at the maintainer's word; the diff
  was kept as evidence. The script's scratch root is now under the temp folder, the fixture has its own `git init`
  and commit, and the script refuses to run if the fixture's git top level is not the fixture.
- **Approval**: the maintainer, 2026-11-12 (option 1).
- **Resolution**: RED 1/52 in `e29b179f`, GREEN 52/52 in `e416edc6`; supervised run 4 (repository compared as well as
  home) was red and still wrote into this repository: `state.md` again, through the tracked `.squad/identity/now.md`
  (item 23's route), and an init probe folder (item 25). The isolation was necessary, not sufficient.
- **Class closure**: the lane guard fails if the script's fixture moves back inside the repository or loses its own
  git repository, and the script itself checks its fixture's git top level at run time. The product side (start
  writing outside its project) is item 23, open for iteration 002.

### DRIFT-206-I001-019 — SC-001 is not met in iteration 001, and its script refuses to run

- **Recorded**: 2026-11-12, by the maintainer's option 1 ("Option 1 it is", relayed by the reviewer session at about
  23:55 local), with the reviewer's conditions.
- **What**: after run 4, SC-001 moves to iteration 002 as a required item, with bug list items 23, 24 and 25. Because
  exclusion keeps the script out of the automated lists only, and a run by hand would rewrite `state.md` again (and,
  after closeout, break the iteration's seal), `tests/integration/project-path-resolution-regression.ps1` now refuses
  to run: its first statement prints one line naming the three items and exits 1, before any fixture is built, with
  no switch or variable to bypass it. Its census exclusion reason says what runs 3 and 4 wrote. `state.md` was
  restored and the probe folder deleted at the maintainer's word; both diffs and the probe file are kept as evidence.
- **Approval**: the maintainer, 2026-11-12 (option 1).
- **Resolution**: RED 2/54 in `4f8205ff`, GREEN 54/54 in `f0201deb` (the refusal; run with the temp folder pointed at
  an empty directory, it writes nothing in the repository or the temp folder); RED 1/54 in `8f8e34cb`, GREEN 54/54
  in `3977131d` (the exclusion reason).
- **Class closure**: the lane guard fails if the refusal stops being the script's first statement, gains a bypass,
  or the script writes anything when run. Iteration 002 removes the refusal together with the fixes.

### DRIFT-206-I001-020 — T015 fixed a registered script outside its owned files: mechanical-findings-contract.ps1

- **Recorded**: 2026-11-12, at the reviewer's ruling under the maintainer's delegation (CI on `103a5e3b`).
- **What**: `tests/integration/mechanical-findings-contract.ps1`, registered per push by T015, went red on CI on one
  Ubuntu image (`20261101.360`) and green on another (`20261111.370`) with no change to it (bug list item 26). Its
  helper now returns `Test-Json`'s own result. The same CI run had a macOS failure in the hook dispatcher's journal
  test (item 27), not rerun and handed to 203 as HO-206-10.
- **Approval**: the reviewer session, 2026-11-12, under the maintainer's delegation (routine, inside the plan; no
  approval carried).
- **Resolution**: RED 1/55 in `ff8a39a8`, GREEN 55/55 in `6fd9fcd9`.
- **Class closure**: the lane guard runs the lifted helper against a `Test-Json` that returns `$false`, so this script
  cannot again depend on whether `Test-Json` throws. A search of `tests/` found no other helper that discards a result
  with `$null =` and counts only an exception as failure; nothing enforces that for new scripts.

### DRIFT-206-I001-021 — review rework: round 2's six findings fixed in iteration 001

- **Recorded**: 2026-11-13, at the maintainer's instruction (round 2 decision, option 1).
- **What**: review round 2 (Codex, run `run-20261113-133711531-d5ed060a`, head `7f346037`) returned six findings in
  206's own code. The engine demoted five from major to minor as "no concrete failure scenario"; each one reproduced
  with a failing test. All six are fixed in iteration 001, each with a test commit (red count) and then a fix commit:

  | # | Requirement | What was wrong | RED | GREEN |
  | --- | --- | --- | --- | --- |
  | 1 | FR-003 | A copilot-instructions.md holding only the managed block strips to empty, and the classifier refused an empty side: `specrew start` still stopped with the binding error | `f1cdd95e` 3/13 | `0c3968ee` |
  | 2 | FR-008a | "cannot be closed" and "isn't closed" read as closure claims | `e2e89489` 2/18 | `e1f5fbbe` |
  | 3 | FR-008 | A dated mention of a pending, refused or unrelated maintainer ruling counted as a recorded abandonment | `3230963e` 5/28 | `ce4f723a` |
  | 4 | FR-009 | A categorized failure replaced or added in the same category left the nightly fingerprint unchanged; the record now carries a hash of the message, never the text | `d5738276` 4/19 | `d3839db1` |
  | 5 | FR-008 | `-RebuildClosedIndex` overwrote closeout closure times and dropped their stamps | `cd19f6e3` 3/33 | `95dca9e5` |
  | 6 | FR-011 | The lane guard counted a test path in a workflow's inline comment, step name, `paths:` filter or `env:` value as a registration | `a0a9b938` 4/69 | `9cf0c4f6` |

- **Growth**: about 1.5 points of rework (0.25 each) beyond the planned 20. The capacity file and the task points
  stay unchanged (maintainer, 2026-11-13).
- **Side effect**: finding 4 changes every nightly fingerprint once, so the first nightly after the merge comments on
  an open tracking issue even if the failures are the same.
- **Not done**: finding 5 keeps the stamps that exist; it does not recover a stamp for an entry that never had one.
- **Resolution**: FIXED; round 3 reviews the fixes.
- **Class closure**: each fix has its test in a review-plan lane (`f206-unit-suites` holds 1 to 5; `f206-census-guard`
  holds 6), so a regression fails the next round's preflight.

### DRIFT-206-I001-022 — the round 2 launch: three typed approvals did not reach the round, and the demotion wording was wrong

- **Recorded**: 2026-11-13, after review round 2 (recording earlier would have moved its head).
- **What**: launching round 2 took four typed `approved for review round` replies.
  - The approval typed at 12:57 local was captured for round 1. When round 1 ended partial (preflight 514.7 of 600 s),
    the pending approval file still read as not spent, but the campaign charged it to round 1 ("already paid").
  - An approval re-typed while one was still unspent was dropped.
  - An approval typed while a turn was running was not captured.
  - The approval captured at 13:35:20 local launched round 2.
- **Also**: the engine demoted five findings with the note "no concrete failure scenario, so it cannot gate". Each
  finding described its scenario, and each reproduced with a failing test (DRIFT-021).
- **Owner**: the review engine is the installed module (0.40.0) and the capture stores belong to feature 203. 206
  changes neither.
- **Resolution**: reported for feature 203's triage; no change in 206.
- **Class closure**: NONE — the fault is in code 206 must not touch; until 203 fixes it, a round launch checks the
  campaign's spend ledger, not the pending approval file.

### DRIFT-206-I001-023 — round 3's preflight failed on my own fixture fix; lanes now run in the preflight's layout

- **Recorded**: 2026-11-13, at the reviewer's ruling under the maintainer's delegation.
- **What**: round 3 (approval captured 21:25:54 local, minted `cmp-206-bug-bash-i001-round-3`) stopped in its
  preflight: `verification-command-failed:f206-unit-suites` after 554 s (run `run-20261113-192634642-269e543e`; the
  engine says no round was used). The cause was bug list item 29's first fix: T002's fixture copied tracked files
  only, and the preflight's verification copy holds `.specrew` and `.squad` as untracked files. My pre-round check
  ran the lanes in this worktree with the full environment, so it could not see that.
- **Resolution**: the fixture copies every file git does not ignore (item 29). Bug item 24 records the same rule for
  the SC-001 script, for iteration 002.
- **Class closure**: before a round, all five lanes run once in the preflight's layout: a copy of the reviewed tree
  with `.specrew`, `.squad` and `.specify` restored untracked, the local review store present and ignored, an empty
  environment plus each lane's `env_refs` and the preflight marker. That step sits next to the time-budget check, and
  the round report states its result.

### DRIFT-206-I001-024 — review rework: round 3's six findings fixed in iteration 001; closure and ruling read by affirmative forms

- **Recorded**: 2026-11-14, at the maintainer's instruction (round 3 decision, option 1).
- **What**: review round 3 (Codex, run `run-20261113-210415408-06f009c3`, head `c91766df`) returned six findings. The
  engine demoted four from major to minor; each reproduced with a failing test. All six are fixed in iteration 001,
  each with a test commit (red count) and then a fix commit:

  | # | Requirement | What was wrong | RED | GREEN |
  | --- | --- | --- | --- | --- |
  | 1 | FR-008 | "Abandonment was rejected by the maintainer's decision of 2026-11-12" counted as a recorded abandonment ruling | `760b7f02` 5/42 | `dba4ea9c` |
  | 2 | FR-008a | "may be closed" and "can be closed" read as closure claims | `d82299be` 2/20 | `e50a2650` |
  | 3 | FR-008a | `-RebuildClosedIndex` selected new entries with the old state.md text heuristic, and dropped unstamped entries it did not detect | `c23d858c` 2/44 | `90b0543a` |
  | 4 | FR-009 | A repository-level stop (Squad team, sealed iteration edited, classifier) wrote one category record with no message hash | `d99f6065` 2/21 | `7fc81397` |
  | 5 | FR-011 | A `run:` key under a step's `with:` or `env:` counted as a CI registration | `9bd570a1` 2/74 | `a50d127a` |
  | 6 | FR-011 | A PowerShell block comment over several lines of a `run:` block left its suite counted | `924d14bb` 1/76 | `45a8070c` |

- **Ruling**: findings 1 and 2 replace the negative-word lists with affirmative forms (maintainer, 2026-11-14; this
  replaces the earlier ruling on T006). Before building, the forms ran against the Iteration Status of all 161
  iterations and the Disposition of every state.md that has one: no iteration's closed, open or ruled result changed
  (32 statuses claim closure before and after; the same four iterations record a ruling).
- **Rebuild**: finding 3's fix keeps every existing index entry, so a rebuild never turns a closed iteration open. On
  a copy of this repository's state files and index, the rebuild adds the seven iterations already closed by status
  and changes no iteration's closed result.
- **Growth**: about 1.5 more points of rework (0.25 each), 3 in all beyond the planned 20. The capacity file and the
  task points stay unchanged (maintainer, 2026-11-14).
- **Not done**: the four stops that return only a count (`source-without-implement-authorization`,
  `handoff-evidence`, `approved-status`, `boundary-canonical`) still write their category alone; bug list item 30,
  for iteration 002.
- **Resolution**: FIXED; round 4, the last in the budget, reviews the fixes. What it finds that is not a blocker goes
  to iteration 002 (maintainer, 2026-11-14).
- **Class closure**: the closure and ruling checks accept only listed forms, so a new wording is open or unruled until
  someone adds its form and its test, instead of closed until someone notices. Each fix's test is in a review-plan
  lane (`f206-unit-suites` holds 1 to 4; `f206-census-guard` holds 5 and 6).

### DRIFT-206-I001-025 — review round 4: five minor findings carried to iteration 002; the review stopped

- **Recorded**: 2026-11-14, after the review stop (recording earlier would have moved the reviewed tree).
- **What**: round 4 (Codex, run `run-20261114-132511846-d1b4bd05`, head `bb0cc72e`), the last in the budget,
  returned five minor findings, none blocking:

  | # | Requirement | Finding |
  | --- | --- | --- |
  | 1 | FR-011 | `steps:` inside a YAML block scalar is read as real steps by the census guard |
  | 2 | FR-011 | A comment right after `;` (`Write-Host done;# tests/...`) still counts as a registration |
  | 3 | FR-003 | A malformed opener `<!-- >>> ... <<< -->` is treated as balanced and stripped |
  | 4 | FR-009 | An unexpected validator exception writes no message hash (a fifth stop beside bug list item 30) |
  | 5 | FR-009 | Overlapping notifier runs can open two tracking issues; the workflow has no `concurrency:` group |

- **Before the round**: the five lanes passed in the preflight layout (571 s of 1800 s) and all three workflows were
  green on `bb0cc72e`. The home hook files hashed the same before and after the round and after the stop.
- **Approval**: the maintainer, before the round: "Round 4 is the last: whatever it finds that is not a blocker goes
  to iteration 002." Finding 5 waits with the others (maintainer, 2026-11-14). The maintainer typed `stop the review
  here`; sign-off completed with disposition `disposition-d51b40f30aa70338571e`.
- **Also**: the pause prompt's own command (`specrew review --live --pause-choice 2`) refused without `--feature`, as
  feature 202 logged in B4F-152.
- **Resolution**: deferred to iteration 002, with round 1's three partial findings not raised again (review.md's gap
  ledger).
- **Class closure**: NONE — the five are deferred by the maintainer's ruling; iteration 002 fixes each behind a
  failing test, and its tests join the `f206-census-guard` and `f206-unit-suites` lanes.

### DRIFT-206-I001-026 — the maintainer's standing rule for a push that adds only Markdown records

- **Recorded**: 2026-11-14, the maintainer's decision of 15:23 local, relayed by the reviewer session.
- **What**: the maintainer's answer to feature 203's crew, "203: yes", sets a rule for every crew. When the only
  difference between the last commit with full pre-push checks and CI green and the commit to push is Markdown
  records under `specs/` or `docs/`, run markdownlint and the governance check and push; the longer suites and the
  preflight-layout lanes need not be repeated for that difference. Anything else in the difference gets the full
  checks. Before using the rule, the changed files between the two commits are printed and each confirmed a Markdown
  record.
- **Limits for 206**: a review round's head still needs green CI on all three workflows and the five lanes green in
  the preflight layout; the rerun exception still covers only `co-review-service.Tests.ps1:129`.
- **Resolution**: adopted as a standing rule; CI is still followed after every push.
- **Class closure**: NONE — a working rule for the crew, not a defect; the printed file list is its check.

### DRIFT-206-I001-027 — the review record's format at review sign-off; T003 recorded as pass for this iteration's part

- **Recorded**: 2026-11-14, after the review-signoff verdict.
- **What**: once the boundary commit moved plan.md to `reviewing`, the governance check judged review.md and refused
  it: T003's verdict `deferred` is not a verdict value, the Gap Ledger entries were not classified one per line, and
  the deferrals had no canonical entry in `.squad/decisions.md`. With T003 as `needs-work` (the maintainer's
  `fix the record as proposed`), the check refused an `accepted` review holding a non-passing task; with no T003 row,
  it refused the missing row.
- **Approval**: the maintainer's decision at 21:24 local, relayed by the reviewer session (`specrewreviewer-98`):
  "206: understand, so we pass now but fix it in the next iteration?" — the first option, T003 `pass` with the note
  "pass for this iteration's part: the classifier change and round 2's finding 1, suite green; remainder carried to
  iteration 002 as SC-002". The overall verdict stays accepted. Round 1's three notes go to iteration 002 with round
  4's (maintainer, typed, 2026-11-14).
- **Resolution**: review.md fixed; defer entries `f206-i001-gap-ledger-deferrals` and one per requirement (FR-003,
  FR-009, FR-011, FR-013); tasks-progress.yml rewritten to the task table (maintainer, typed); bug list items 31 to 37
  and an Iteration 002 Intake section naming SC-002.
- **Class closure**: bug list item 37 — iteration 002 adds a verdict value for a task the plan defers, so a
  part-finished task is no longer written as `pass`. Until then, the note on the row carries the truth.

### DRIFT-206-I001-028 — the retro scaffold refused review.md's verdict line; retro.md written without it

- **Recorded**: 2026-11-14, at the retro.
- **What**: `scaffold-retro-artifact.ps1 -DryRun` threw "review.md contains an invalid overall verdict: 'accepted:
  four rounds (round 1 partial). ...'". It reads the whole verdict line as the value, while the governance check
  accepts `accepted` followed by its explanation. Feature 205 hit the same refusal (its DRIFT-024).
- **Resolution**: retro.md written by hand in the template's sections, following feature 205's retro; review.md
  unchanged, as approved.
- **Class closure**: NONE — the scaffold is the installed module's; reported for feature 203's triage with 205's
  instance, two features now.

### DRIFT-206-I001-029 — the retro push is red on Lint by the boundary order; one exception, and bug list item 39

- **Recorded**: 2026-11-14, before the retro push.
- **What**: the retro sync refused until the retro commit is on origin (`verdict-commit-durable`), and that commit is
  red on Lint ("plan.md status 'reviewing' is stale: retro.md exists") until the retro boundary moves the line. The
  sync also refused on task-state: state.md's Tasks Remaining said "none planned" beside T003 `deferred`; fixed in
  `7233fc35`.
- **Approval**: the maintainer's decision at 22:39 local, relayed by the reviewer session (`specrewreviewer-98`): "OK,
  so for now allow it as before, and instruct 206 to add it". One red Specrew CI run on Lint only, for this push of
  `c439c012`, `e053b91a` and `7233fc35`: the plan-status item and the standing derived-block item, nothing else. It is
  not a standing exception.
- **Resolution**: the push goes ahead under that exception; bug list item 39 records the ordering for iteration 002.
- **Class closure**: bug list item 39. The validator would accept a record beside its pre-verdict phase while the
  crossing is pending. Until then, every review sign-off and every retro needs this exception.

### DRIFT-206-I001-030 — the retro's two discussion prompts answered; one correction to the approved retro

- **Recorded**: 2026-11-14, after the retro verdict.
- **What**: the reviewer session (`specrewreviewer-98`) answered the retro packet's two prompts under the maintainer's
  delegation. It showed the answers to the maintainer at 22:53 local, and the maintainer typed `approved for retro`
  afterwards without objecting. They are the reviewer's rulings, not the maintainer's words.
  1. The two reviewer-brief promotions come in with iteration 002's plan, as a planned task with its own check, worded
     exactly as retro.md has them. A change to the reviewer's instructions is a methodology change and is planned and
     reviewed like one.
  2. The calibration is accepted as proposed: 0.25 SP per expected review finding on tasks that build a rule over free
     text or a reader of YAML or shell, and a 1 SP line for the review-signoff crossing until the ordering is fixed.
     It is applied when iteration 002 is estimated.
- **Correction**: retro.md's Signals say the review-signoff crossing repeats its red Lint push "until 203 fixes the
  phase-line order". By the maintainer's decision at 22:39 (DRIFT-029), that ordering is bug list item 39, 206's
  candidate for iteration 002, not a hand-over to 203. The approved retro is left as it is.
- **Resolution**: recorded for iteration 002's plan.
- **Class closure**: NONE — rulings and a correction to a record, not a defect.

<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
