# Tasks: 206-bug-bash (iteration 001; iteration 002 listed)

**Feature**: 206-bug-bash
**Plan**: file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/plan.md
**Iteration plan**: file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/iterations/001/plan.md
**Date**: 2026-11-11
**Effort unit**: story points. Iteration 001 is 20/20 with no slack (maintainer, plan verdict 2026-11-11): any
task that grows so the total would pass 20 stops the work for the maintainer. Review is not priced in SP.

Conduct is bug-bash. **Every fix lands with a failing test first, one bug per commit.** On every commit:
mirror parity (`extensions/` ↔ `.specify/`), the CI markdownlint command, and `validate-governance -ChangedOnly`
against the push base CI will use (DRIFT-206-I001-001). Before and after every test run, the home hook files are
hashed: `~/.specrew/specrew-hook-launch.ps1`, every file in `~/.specrew/hook-bindings/`, `~/.codex/hooks.json`,
`~/.copilot/hooks/*.json`, `~/.cursor/hooks.json`. Any change stops the work.

**Never run on this machine:** the 16 test files feature 203's census found able to write the home hook files (listed
in the iteration plan's notes and bug list item 8), and no lane from `.specrew/verification-plan.json`. Anything else
that reaches `specrew init`, `start`, `update` or the hook deployer is not run unless it has been read and the path it
takes confirmed unable to write hook files (maintainer, 2026-11-11). No review round starts until a verification plan naming only 206's own checks,
each read for home writes first, has been brought to the maintainer.

## Execution order

T001, T002, T003, T004, T005 (stop), T006, T007, T008, T009, T011, T010, T012, T013, T014 (stop), T015, T018.

- T005 (the closed/open table) comes before T006 changes the definition (design condition 1), and **ends in a
  stop**: the table goes to the maintainer, who rules on 198/010, before T006 and T007 start (tasks verdict,
  2026-11-11).
- T010 runs after T011, out of number order, so the replay sees the corrected message too (tasks verdict).
- T007, T008, T009 and T011 land before T010's replay, which checks that none of them produced a new finding.
- T013 (the census) comes before T014, so T014 reads the scripts the census will count.
- T014 ends in a stop for the maintainer; T015 registers nothing before that ruling.
- T018 is the last acceptance check.
- No task touches a full-validation trigger path (`.specrew/config.yml`, `constitution.md`, `iteration-config.yml`,
  `role-assignments.yml`, `presets/**`, `lenses/**`, `roadmap.yml`, `.squad/identity/wisdom.md`).

## Phase 1: Start and checks (US1, items 1 and 2)

- [x] T001 [owner: Implementer] [sp: 1.5] **No-console recovery refusal and a three-try cap.**
  - **RED:** a unit test calls `Read-SpecrewRecoveryChoice` with console input unavailable and stale session state;
    today it loops on `Read-Host`. A second case gives an interactive console three invalid answers.
  - **Work:** refuse in plain words when console input is not available (what could not be completed, that the
    human's work is safe, the one recovering command `--recovery-choice A|B|C`); `specrew start` exits non-zero.
    Interactive: at most three invalid answers, then the same refusal. No stdin read (the B5F-034 hang class).
  - **Acceptance:** both cases green; with console input and a valid answer, behaviour unchanged; no fourth prompt.
  - **Trace:** FR-001; SC-001 (refusal half).
  - **Owns:** `scripts/internal/session-recovery.ps1`, `scripts/specrew-start.ps1`, `tests/unit/**`.
- [x] T002 [owner: Implementer] [sp: 0.5] **Over-claim dirty check: one path separator.**
  - **Done (2026-11-13):** Unix evidence from the runner: Specrew CI run 43411715314 (attempt 2) on `75ddb2b9`, job
    131847705487, the per-push step: "RESULT tests/unit/overclaim-dirty-check-separator.tests.ps1: 3 passed, 0 failed"
    (maintainer's option (a), `6b2fa5e1`).
  - **Before (2026-11-13):** on Windows the unit suite is 3/3 and
    `validator-hardening-iteration2.ps1`'s assertions 1 and 2 passed in its T015 run. No CI run has executed either on
    Ubuntu or macOS: the unit suite is release-cadence only, and the script is excluded (red at assertion 3).
  - **RED:** `tests/integration/validator-hardening-iteration2.ps1` assertions 1 and 2 (failing today).
  - **Work:** the git-path normalization and the canonical artifact list use one separator; the finding names
    paths with it, and the test asserts it.
  - **Acceptance:** assertions 1 and 2 green on Windows and Unix; a clean artifact gives no finding.
  - **Trace:** FR-002; SC-002.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1` and its `.specify` mirror,
    `tests/integration/validator-hardening-iteration2.ps1`.
- [ ] T003 [owner: Implementer] [sp: 1.5] **Change classifier ignores Specrew's matched marker blocks only.**
  - **Carried into iteration 002 (2026-11-13):** the unit suite is green (10/10, including the regression fixed at T015,
    DRIFT-206-I001-014); the remainder is assertion 3 of `validator-hardening-iteration2.ps1`, which is SC-002, moved to
    iteration 002 by the maintainer (bug list item 21).
  - **RED:** assertion 3 of `validator-hardening-iteration2.ps1`, plus a classifier unit suite.
  - **Work:** before comparing, strip every `specrew-managed` block from both sides **only when its opening and
    closing markers form a matched pair**; any missing or unbalanced marker compares the whole file as today.
  - **Acceptance (design condition 3):** a matched block is stripped and the heal does not pause; a missing or
    unbalanced marker pauses; a user change outside the markers is still classified as the user's.
  - **Trace:** FR-003; SC-002.
  - **Owns:** `scripts/specrew-start.ps1`, `scripts/internal/instruction-file-merge.ps1` (marker constants, read if
    shared), `tests/unit/**`, `tests/integration/validator-hardening-iteration2.ps1`.

## Phase 2: Nightly and history (US2, items 3 and 4)

- [x] T004 [owner: Implementer] [sp: 0.5] **Open the hand-over record for feature 203.**
  - **Work (tasks verdict, 2026-11-11):** one record, with a separate section per item, each with its own
    evidence and proposed owner:
    1. bug list item 3: the flaky retry test, cause not found, one candidate, its recurrence log;
    2. bug list item 7: the Windows review-runtime hang, run 42913380735, no log kept;
    3. the FR-066 mint guard with T091 and T093, one finding, with
       `tools/pending/fr066-first-boundary-arrival.pending.ps1` as its test (not run);
    4. DRIFT-198-I010-004, whatever the maintainer rules for 198/010;
    5. bug list item 8: the two update-calling suites, cross-referenced to feature 205's H-001 and feature 203's
       B5F-039.
  - **Closed by T018**, after adding anything T014 or the other tasks find that belongs to 203.
  - **Acceptance:** each section names its evidence, run ids and proposed owner; no code changes.
  - **Trace:** FR-004, FR-005.
  - **Owns:** `specs/206-bug-bash/bug-list.md`, `specs/206-bug-bash/iterations/001/**`.
- [x] T005 [owner: Implementer] [sp: 1.0] **Closed/open table before the definition changes (design condition 1).**
  - **Work:** every iteration with its answer under the closed index, the state.md heuristic, the renderer rule and
    the new function; every iteration whose answer changes, listed with the reason. **198/010 is included as
    awaiting the maintainer's ruling**, with its status, T082 and DRIFT-198-I010-004; it is marked nothing.
  - **Acceptance:** the table is committed and brought to the maintainer; **STOP** for the ruling on 198/010.
    T006 and T007 do not start before it.
  - **Trace:** FR-008a.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [x] T006 [owner: Implementer] [sp: 2.0] **One definition of "closed".**
  - **RED:** a unit suite for `Test-SpecrewIterationClosed` over index, status and frozen cases; a review verdict
    alone never makes an iteration closed.
  - **Work:** closed = in the closed index, or `Iteration Status` `complete` / `abandoned` (abandoned only with a
    recorded ruling, T009); frozen entries are not closed. Used by the validator's closed filter, the dashboard
    check and the renderer; the state.md heuristic and the review-verdict rule are removed. Maintainer ruling
    2026-11-11, option 1 with conditions: a status that claims closure in the validator's own words ("closed",
    "closeout complete", "closure complete") with no negation or future wording before it also counts; "not
    closed", "not yet closed", "to be closed after review" and "blocked" do not; `Test-ClosedIterationStatus` is
    unchanged for its other caller.
  - **Trace:** FR-008a.
  - **Depends:** T005.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`,
    `extensions/specrew-speckit/scripts/validate-governance.ps1`, their `.specify` mirrors,
    `scripts/internal/dashboard-renderer.ps1`, `tests/unit/**`; the deployed hash file
    `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` (maintainer, 2026-11-11: a commit that
    touches `.specify/extensions/specrew-speckit/` refreshes it in the same commit). Outside owned files, approved:
    the W51 fixture in `tests/integration/closed-iterations-are-history.tests.ps1` (DRIFT-206-I001-003).
- [x] T007 [owner: Implementer] [sp: 1.0] **The triage applied: abandoned and frozen.**
  - **Held, then closed (maintainer, 2026-11-11, option 1):** 197/006, 198/010 and the frozen list were pushed
    first; 198/011's abandonment was held back, because with a `retro.md` its `state.md` could not pass the
    validator (plan `Status: abandoned` refused as stale; plan `Status: retro` brings back the review-verdict
    finding). T009's exemption lets it pass; 198/011 lands in `7e3ddd78`, in T009's push.
  - **Acceptance met (2026-11-12):** a CI-mode full-repository run (`-FullRun`, `CI=true`) on `3b5dcadf` exits 0
    with no failure: 198/011 is closed (abandoned by ruling), the 18 frozen entries are skipped.
  - **Work:** 198/011 and 197/006 marked `abandoned`, each recording the maintainer's ruling of 2026-11-10;
    198/011's `review.md` unchanged. **198/010 marked `abandoned`, superseded** (maintainer's T005 ruling,
    2026-11-11): its `state.md` says in plain words that DRIFT-198-I010-004 stays open and was handed to feature
    203 as HO-206-4, with the hand-over record's path; T082 stays `needs-rework`.
    `.specrew/legacy-frozen.yml` with exactly 18 entries and one true reason each:
    048/001, 197/001, 198/008, and the 15 dashboards ("closed before dashboards were rendered automatically").
  - **Acceptance:** the nightly's 198/011 failure is gone in a CI-mode full-repository run.
  - **Trace:** FR-005, FR-006.
  - **Owns:** `specs/198-beta2-hardening/iterations/011/{state,plan}.md`,
    `specs/198-beta2-hardening/iterations/010/{state,plan}.md`,
    `specs/197-continuous-co-review/iterations/006/{state,plan}.md`, `.specrew/legacy-frozen.yml`.
- [x] T008 [owner: Implementer] [sp: 1.5] **Frozen means judged by nothing (design condition 2).**
  - **RED:** a guard test pinning the 18 keys fails on an added key; a test runs the validator over each frozen
    entry and asserts zero findings.
  - **Work:** the validator skips frozen entries in both open-iteration and closed-iteration checks. 197/006 is
    abandoned, not frozen; the dashboard check applies to `complete` iterations only (maintainer, plan verdict).
  - **Trace:** FR-007; SC-005.
  - **Depends:** T007.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`,
    `extensions/specrew-speckit/scripts/shared-governance.ps1`, their `.specify` mirrors, `tests/unit/**`; the
    deployed hash file's `validate-governance.ps1` entry (standing ruling 2026-11-11); the suite's line in
    `.specrew/release-gate-suites.txt`, as T006's.
- [x] T009 [owner: Implementer] [sp: 1.5] **`since`, the closure stamp, and abandonment by ruling.**
  - **Ruled (maintainer, 2026-11-12, option 1, with conditions):** the real size is 2.0 points (1.0 + 0.75 +
    0.25); the extra 0.5 is the exemption added by the 2026-11-11 ruling, recorded as scope added by ruling
    (DRIFT-206-I001-008); the 1.5 here and the capacity file stay unchanged. "An `abandoned` status with no
    recorded ruling is not closed" moves to iteration 002 as a required item (DRIFT-206-I001-010). The
    `non-specrew-session-bypass` fixture gets stamped index entries (DRIFT-206-I001-009).
  - **RED:** the dashboard check with and without a `closed_at_source: closeout` stamp, before and after
    `since: 2026-05-26`. (The "abandoned with no recorded ruling is not closed" case moved to iteration 002.)
  - **Work:** the dashboard check declares `since` and `applies_to_status: complete`, replacing the feature-number
    cut-off; iteration closeout writes `closed_at_source: closeout`; an unstamped entry is not judged by a `since`
    check. The tests pin the rulings for 198/011 and 197/006 (2026-11-10) and 174/007 (2026-06-14).
  - **Added (maintainer, 2026-11-11, T007 option 1; within the 1.5 points, capacity file unchanged):** an iteration
    whose `state.md` says `abandoned` with a recorded ruling is not held to the plan-status rule or the
    review-verdict rule; `abandoned` with no recorded ruling still gets both. Test first. 198/011's abandonment
    (T007) lands in the same push, and T007 closes then. If this does not fit in 1.5 points: stop with the estimate.
  - **Done (2026-11-12):** RED 17/20 in `9815d2f7`, GREEN 20/20 in `54cb8e18`
    (`tests/unit/closed-check-since-and-ruling.tests.ps1`). Before the push, `validate-governance-changed-only`
    found a strict-mode failure when the renderer comes from an older installed module: RED 3/23 in `36dfd605`,
    GREEN 23/23 in `3b5dcadf`.
  - **Trace:** FR-008.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`,
    `extensions/specrew-speckit/scripts/shared-governance.ps1`, their `.specify` mirrors, `tests/unit/**`; the
    deployed hash file's two entries (standing ruling 2026-11-11); the suite's line in
    `.specrew/release-gate-suites.txt`. Outside owned files, approved: the fixture in
    `tests/integration/non-specrew-session-bypass.tests.ps1` (DRIFT-206-I001-009).
- [x] T011 [owner: Implementer] [sp: 0.5] **The review-verdict finding names the real status.**
  - **RED:** the validator's message for a `retro` iteration says "Complete iterations require …".
  - **Acceptance:** a `retro` iteration is named as such; a `complete` iteration keeps its message.
  - **Done (2026-11-12):** RED 1/2 in `5b1695a3`, GREEN 2/2 in `85f62dc4`
    (`tests/unit/review-verdict-names-status.tests.ps1`).
  - **Trace:** FR-010.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1` and its `.specify` mirror,
    `tests/unit/**`.
- [x] T010 [owner: Implementer] [sp: 0.5] **Local nightly replay (design condition 1, acceptance).**
  - **Done (2026-11-12), on `9de20285`:** exit 0, no failure; 159 iterations, 18 frozen and 128 closed skipped, 13
    validated, all PASS. Of the 36 rows T005 changed: the 12 that became open all PASS; 18 frozen and 5 closed (group
    B, 198/009) are skipped, and 197/006 is closed since T007. The 6 warnings are all `handoff-block-missing` on
    206's own boundary commits (specify to before-implement); none names a closed iteration. No new finding.
  - **Work:** `$env:CI='true'`, `validate-governance.ps1 -FullRun` on the branch head.
  - **Acceptance:** no failure; no iteration whose answer changed in T005 produces a new finding; every warning for
    a closed iteration names a frozen entry or is gone. **If a changed iteration produces a new finding, the work
    stops and that iteration goes to the maintainer; it is not added to the frozen list.**
  - **Trace:** FR-006, FR-008a; SC-003.
  - **Depends:** T006, T007, T008, T009, T011.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [x] T012 [owner: Implementer] [sp: 2.5] **Nightly tracking issue (design condition 4).**
  - **Done (2026-11-12):** RED 13/14 in `ae9a3c9d`, GREEN 14/14 in `ff0e78b9`; the notify job runs only for the
    default branch (maintainer ruling): RED 1/15 in `85d275bb`, GREEN 15/15 in `867d4752`
    (`tests/unit/nightly-tracking-issue.tests.ps1`). The notifier is at `.github/scripts/nightly-tracking-issue.ps1`,
    not the path below, by the maintainer's ruling (DRIFT-206-I001-011).
  - **RED:** a Pester suite with recorded `gh` calls: the first red opens, the same failures stay quiet, changed
    failures comment, green closes; the rendered title, body and comments contain no path, user or machine name.
  - **Work:** `scripts/internal/nightly-tracking-issue.ps1` with injectable `gh`; the validator writes a findings
    file (`-FindingsJsonPath`); a separate notifier job alone holds `issues: write`, the workflow default stays
    `contents: read`.
  - **Trace:** FR-009.
  - **Owns:** `scripts/internal/nightly-tracking-issue.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`
    and its `.specify` mirror, `.github/workflows/specrew-nightly-truth-check.yml`, `tests/unit/**`.

## Phase 3: Test census (US3, item 5)

- [x] T013 [owner: Implementer] [sp: 2.0] **One shared test census.**
  - **Done (2026-11-12):** RED 10/26 in `dd57e075`, GREEN 25/26 in `798ded31`; the one failure is this repository's
    36 unregistered tests, which T015 registers or excludes (planned). The sweep was not run for real: `-ListOnly`
    and a temp-repository fixture test it. By the maintainer's ruling the 36 are held (listed, not run) until T014
    reads them; at T015 the held list is emptied and a test requires it empty (DRIFT-206-I001-012).
  - **RED:** the lane guard passes today with an unregistered `tests/integration/zz-probe.ps1`.
  - **Work:** `tests/support/test-census.ps1`, used by the lane guard and the release full sweep: every `.ps1`
    under `tests/`, classified by content (`Describe` makes a Pester suite), fixtures and support helpers excluded
    by one listed rule, and one exclusion list with a reason per entry.
  - **Acceptance:** SC-004 both ways.
  - **Trace:** FR-011; SC-004.
  - **Owns:** `tests/support/test-census.ps1`, `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`,
    `tests/full-powershell-test-sweep.ps1`.
- [x] T014 [owner: Implementer] [sp: 2.0] **The 35 scripts: read, run the safe ones, then stop for the maintainer.**
  - **Done (2026-11-12):** the 36 held scripts read; 19 run alone with home unchanged (18 green, 1 red); report
    `iterations/001/t014-held-scripts.md` (`fd8c6d28`); ruled by the maintainer on 2026-11-12, built in T015.
  - **Read first:** each script for writes outside its project or hook deployment. **Any script that calls
    `specrew-update.ps1` or the hook deployment is not run and is listed for the maintainer.**
  - **`project-path-resolution-regression.ps1`** (maintainer, plan verdict): it calls `specrew-update.ps1` only
    with `-InfoMode`, plus `specrew start -NoLaunch` and `specrew init -DryRun` on fixtures. Before it runs, those
    three code paths are read and the answer is stated: does any write the home folder or deploy hooks? If all
    three are read-only, it runs with the home hook files hashed before and after. If not, it goes to the
    maintainer before SC-001.
  - **Run:** each safe script, with the home hashes before and after, recording its duration and result.
  - **STOP:** the exclusion list with reasons, every red script with its failure (fixed here only if its cause is
    one of this feature's items), every not-run script, each duration, and the per-push time registration would
    add. Nothing is registered before the maintainer rules.
  - **Trace:** FR-012; SC-001, SC-007.
  - **Depends:** T013.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [x] T015 [owner: Implementer] [sp: 1.0] **Register the 35 per the maintainer's ruling.**
  - **Done (2026-11-13; CI green on `66d70fa3`), SC-001 and SC-002 moved to iteration 002 by ruling:** 23 scripts per push (a Specrew
    CI step), `validator-hardening-iteration1.ps1` to the release manifest, 12 excluded with reasons, the held list
    empty and required empty (RED 16/49 `ec541bae`, GREEN 49/49 `95c28953`). The start-path scripts point the user
    profile at a temp file (RED 9/34 `963fc149`, GREEN `8f1e5f0c`; DRIFT-206-I001-013). A T003 regression found here
    and fixed (RED 2/10 `968022f3`, GREEN 10/10 `30fa853a`; DRIFT-206-I001-014). SC-002 is not met in iteration 001
    (maintainer, option 1): `validator-hardening-iteration2.ps1` is red at assertion 3 (bug list item 21) and is
    required in iteration 002. `project-path-resolution-regression.ps1` is not registered until the maintainer has
    seen its supervised run. **SC-001 is not met in iteration 001** (maintainer, option 1, 2026-11-12): four
    supervised runs, home hook files unchanged in each; runs 1 and 2 red (stale, then missing, session state; fixed
    in the test: DRIFT-206-I001-015 and -016); runs 3 and 4 wrote into this repository (`state.md` both times; run 4
    also an init probe folder; bug list items 23, 24 and 25; DRIFT-206-I001-018). The script now refuses to run until
    those items are fixed (DRIFT-206-I001-019). SC-001 is required in iteration 002. Report:
    `iterations/001/t015-registration.md`; for iteration 002 planning, `iterations/001/specrew-start-facts.md`.
  - **Work:** a per-push lane or the release manifest per the ruling; slow scripts to the release manifest; a
    suite added to a verification lane is read under T014's rule first.
  - **Acceptance:** `project-path-resolution-regression.ps1` and `validator-hardening-iteration2.ps1` green and
    registered (unless the maintainer ruled otherwise at T014); the census guard green.
  - **Trace:** FR-012; SC-001, SC-002.
  - **Depends:** T014 and the maintainer's ruling.
  - **Owns:** `.github/workflows/specrew-ci.yml`, `.specrew/release-gate-suites.txt`,
    `.specrew/verification-plan.json`, `tests/support/test-census.ps1`.

## Phase 4: Acceptance

- [x] T018 [owner: Implementer] [sp: 0.5] **Acceptance checks.**
  - **Done (2026-11-13; trigger-path check accepted on the plan's own reading, reviewer ruling under the maintainer's
    delegation):** four checks pass, and the 203 hand-over is closed (ten items).
    "No commit touches a trigger path" fails as worded: two plan-stage commits (OVERRIDE 5 and its revert,
    DRIFT-206-I001-001), net zero. Record: `iterations/001/t018-acceptance.md`.
  - The branch diff against `main` touches nothing under `scripts/internal/continuous-co-review/**` or
    `scripts/internal/bootstrap/**`.
  - `.squad/active-features.yml` is in no commit.
  - No commit touches a full-validation trigger path.
  - The home hook-file hashes match before and after every run (SC-007).
  - **Close the 203 hand-over record** opened by T004, after adding anything T014 or the other tasks found that
    belongs to 203.
  - **Trace:** SC-007.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.

## Iteration 002 (listed, not planned)

Deferred from iteration 001 by the maintainer (2026-11-11), not cut: T016 (FR-013, delete the empty
`tests/integration/_ctl-spec.ps1`, 0.25 SP), T017 (FR-014 and SC-006, the resolver suggests no Node or React
preset; the f049 assertion onto a fixture; the root `package.json` removed, 1.5 SP). Candidate: T019 (the
Cross-Platform review-runtime step gets its own `timeout-minutes`; bug list item 7, 0.25 SP; a requirement is added
when iteration 002 is planned).

**Required in iteration 002 (maintainer, 2026-11-12; feature 206 does not close without it):** an `abandoned`
status is closed only with a recorded ruling (moved from T009, FR-008a). It lands together with the maintainer's
rulings on the four group B iterations (197/002, 197/007, 197/008, 198/005), so the T005 table does not change.
Until it lands, an `abandoned` status with no recorded ruling counts as closed; this must not ship
(DRIFT-206-I001-010).

## Traceability

| Requirement | Tasks | | Success criterion | Tasks |
| --- | --- | --- | --- | --- |
| FR-001 | T001 | | SC-001 | T001, T014, T015 |
| FR-002 | T002 | | SC-002 | T002, T003, T015 |
| FR-003 | T003 | | SC-003 | T010 |
| FR-004 | T004 | | SC-004 | T013 |
| FR-005 | T004, T007 | | SC-005 | T008 |
| FR-006 | T007, T010 | | SC-006 | T017 (iteration 002) |
| FR-007 | T008 | | SC-007 | T014, T018 |
| FR-008 | T009 | | | |
| FR-008a | T005, T006, T010 | | | |
| FR-009 | T012 | | | |
| FR-010 | T011 | | | |
| FR-011 | T013 | | | |
| FR-012 | T014, T015 | | | |
| FR-013 | T016 (iteration 002) | | | |
| FR-014 | T017 (iteration 002) | | | |

Every iteration-001 task traces to an FR or SC; every FR and SC has a task, in iteration 001 or listed for 002.
Sum of iteration-001 effort: 20.0 SP.
