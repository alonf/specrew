# Hand-back from Feature 203 to the Next Bug Bash

**Written**: 2026-11-18, feature 203 iteration 002, on the reviewer session's routine ruling. **Source of the items**:
feature 206 handed 13 bug-list items to 203 by name (206's `specs/206-bug-bash/follow-up-seed.md`, "With feature 203
(13)", and `specs/206-bug-bash/iterations/001/handover-to-203.md`, HO-206-1 to HO-206-10). 206's seed is at its
closeout gate and stays as written, so this note is where the next bug bash finds what 203 gives back.

**State checked**: on 203's local tip `597c653c1` (2026-11-18). "Fixed" means fixed on the 203 branch: it reaches main
only with 203's merge.

## Handed Back (5)

None of these is fixed or planned in 203. Each line gives 206's item number and hand-over id, the reason, and its 203
finding where one exists.

- **Item 9 (HO-206-6), the macOS review-runtime fault-matrix case: the process-group membership probe failed.**
  B5F-052 (`docs/beta5-findings.md`) proposes a task for it, but no iteration 002 task covers it.
- **Item 14 (HO-206-9), `review-posix-runtime.Tests.ps1:126`: two stream drains took 360 ms against a 250 ms budget
  on macOS.** B5F-051 site 2, recorded by B5F-061. Iteration 002 puts the rest of B5F-051's timing census out of scope.
  Commit `eee6946a6` loosened another case of the same suite (lines 103 and 113), not line 126.
- **Item 27 (HO-206-10), `journal-fault-injection.tests.ps1` on macOS: concurrent Stop dispatchers exited non-zero and
  journaled nothing.** 203 records only the suite's timing sites (B5F-051 site 1, and a 1,500 ms sleep used as a
  barrier); the dispatcher failure itself has no 203 record. Its home in 203's spec (US7, SC-007) moved to the follow-up
  feature (203 T029).
- **Item 42, a one-line approval with instructions (`approved for <to> - <instructions>`) is not captured, while the
  bare phrase is.** B5F-044 fixed approvals whose instructions run onto a second line or sit inside a paste; 206's
  one-line case, journaled with an empty `leading_text`, has no 203 record and no 203 test.
- **Item 62, the campaign reviewer is told an absolute deadline but has no way to read the time.** B5F-090 says
  "candidate, not planned"; no task covers it.

## Fixed in 203 but Thinly Guarded (Test Candidates)

These are fixed on the 203 branch, but the guard is weaker than the finding. Each is a candidate for a test in the
next bug bash.

- **Item 59, the retry message says the approval is "NOT spent" while the spend record says spent.** Fixed by 203
  T008's redesign (iteration 001 DRIFT-052, item 3: per-round approvals removed, FR-010), so the two records cannot
  disagree. No test names this case.
- **Item 60, the automatic retry after a partial result is blocked by the first attempt's own pause.** Fixed by the same
  redesign: one launch per invocation and no automatic retry (`scripts/specrew-review.ps1:1375-1377`). No test names
  this case.
- **Item 58, a partial review's findings are dropped from the pause record and the packet says it "found nothing".**
  Fixed by T008 step (iii) (RED `047cd6a0e`, fix `8b98e2ef7`; iteration 001 DRIFT-052, "Partial findings"): they stay
  open until a later complete round or the human's typed defer or drop. Guarded only by the partial case of
  `tests/unit/review-loop-stops.Tests.ps1`, not by 206's sequence.
- **Item 3 (HO-206-1), `empty-result-retry.Tests.ps1` fails intermittently.** Fixed by 203 T017 (RED `7ddafa6d6`, fix
  `56ec80966`: the agent invoker waits for the child's output after it exits), guarded by
  `agent-invoker-output-drain.Tests.ps1` and 50 green runs. The cause is "likely", not proven, and no CI recurrence
  check is recorded since the fix.
- **Item 7 (HO-206-2), the Windows review-runtime job hung past its timeout and left no log.** 203 T015 made it
  diagnosable (each suite has a named 300 s limit, and the CI step its own timeout below the job's; guard
  `bounded-suite-runner.Tests.ps1`). Why the job hung is still unexplained.

## Found in 203, Candidate (Not Planned)

- **B5F-091, the task writer re-stamps a done task.** `Set-TaskStatus -Status done` on a task already done rewrites
  its `completed_at` to the time of the call and moves state.md's "Last Completed Task" back to it (iteration 002
  DRIFT-036). A done-to-done call should be a no-op, or keep the time and say so. Not a 206 item; found by 203 on
  2026-11-18.
- **Hook commands of other hosts whose missing-launcher refusal is not plain Specrew text (not covered).** 203 fixed
  Claude's generated command (guarded-project-encoded; iteration 002 DRIFT-038, `4d750cfc2`). Not covered, by host:
  - **Codex, Copilot and Cursor** (`launcher-file`) run the per-machine launcher with `pwsh -File`, so a missing
    launcher gets pwsh's own `-File` error.
  - **Antigravity's** `launcher-encoded` command (`& '<launcher>' ...` through `-EncodedCommand`) has no
    missing-launcher guard, so pwsh's error reaches the host the way Claude's throw did. Same class, separate line
    (`deploy-refocus-hooks.ps1`, the `launcher-encoded` case).

  Placement is the maintainer's, through the reviewer session; not built in 203.
- **One "new test file" lane.** Twice on 2026-11-18 a new test file passed its own batch and was then caught by a
  repository-wide guard the batch did not run: the lane-naming guard (DRIFT-035), then the home-isolation guard
  (DRIFT-040). The guards that judge test files are listed in iteration 002's DRIFT-040: lane naming, home isolation,
  the host-coupling firewall, and CI's PSScriptAnalyzer errors. A single lane that runs all four makes the miss
  impossible. Not built in 203.
- **Tests added on main before 203 merges.** Any test that calls `Add-SpecrewBoundaryAuthorization` directly with a
  captured evidence source needs a cited typed turn (`tests/support/cited-typed-turn.ps1`), because 203's FR-022
  refuses a captured verdict without one. Any test that names a hook-writing entry point (the updater, init, start, the
  hooks command or the deployer) needs a private home or a `# specrew-test-home: not-a-writer - <why>` line, because
  203's `test-home-isolation` guard requires it. Both were added to main's tests at 203's merge of main (T030, DRIFT-044).
- **For proposal 166: two home-safety rules for start-running tests.** 206's lane guard
  (`every-suite-is-named-by-a-lane.tests.ps1`: each start-running script points `SPECREW_USER_PROFILE_PATH` at a temp
  file) and 203's `test-home-isolation` (a private home or the not-a-writer line) both guard tests that run Specrew's
  entry points. They should become one rule.
- **A reviewer's authorization reference is never checked against a record (bug-bash candidate).**
  `Test-ContinuousCoReviewReviewerAuthorization` (`reviewer-authorization-gate.ps1`) treats any non-empty
  `authorization_ref` in `.specrew/reviewer-hosts.json` as an explicit authorization and never resolves it. At 203's
  second merge of main, 203's workshop hash and 205's `workshop-205-workshop-lens-order` both satisfied it (iteration
  002 DRIFT-045). Not fixed in 203. For proposal 166, the same catalog is per project and each feature's workshop
  rewrites it, so the last merge wins.

## Fixed in 203, for Completeness

- **Item 8 (HO-206-5), suites that rewrite the real home's hook files**: B5F-039, test first (`77bd4a2e2`, `b69cc5caf`),
  guard `tests/unit/test-home-isolation.Tests.ps1`.
- **Item 13 (HO-206-8), a supervisor still running after a failed lease handoff**: 203 T015 part 1 (RED `5388a5f13`,
  fix `fcafd224f`), guard `co-review-service.Tests.ps1`.
- **Item 61, campaign findings demoted for a missing "Failure scenario:" clause**: B5F-017, `d3ab3f21c`, guard
  `reviewer-prompt-contract.Tests.ps1` (its context at line 119 renders the campaign prompt).
