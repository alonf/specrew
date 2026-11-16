# Tasks: 206-bug-bash (iterations 001 and 002)

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

## Iteration 002: the carried work and items 37, 39, 41 and 44

**Planned:** 2026-11-15; plan approved by the maintainer (`8a8ed810`), which also approves spec Amendment A1 (FR-015
to FR-018, SC-008 to SC-011). Iteration plan:
file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/iterations/002/plan.md. Design: Option B, D1-a to D6-a
(file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/iterations/002/design-analysis.md). **20 of 20 SP, no
slack:** a task that grows so the total would pass 20 stops the work for the maintainer. Moved to iteration 003 by the
maintainer's cut: items 15, 16, 19, 20, 28 and 35 (5.25 SP). Out: items 36, 38, 40, 42, 43; item 7's candidate T019.

The iteration-001 rules above carry over: **a failing test first, then the fix, two commits, one bug per commit**;
mirror parity; the CI markdownlint command and `validate-governance -ChangedOnly` before every push; the home hook
files hashed before and after every test run, any change stops the work; `scripts/specrew-update.ps1` is never run;
a commit touching `.specify/extensions/specrew-speckit/` refreshes `.specrew-extension-runtime.json` in the same
commit; `.squad/active-features.yml` is in no commit. **Not touched:** `scripts/internal/continuous-co-review/**`,
the capture stores under `scripts/internal/bootstrap/` and `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1`;
a fix that needs one of them stops and goes to the maintainer.

### Execution order (iteration 002)

T020, T021 (SC-002 first); T022, T023, T024, T025 (SC-001); T016, T017; T026; T032, T031; T030; T027, T028, T029;
T034, T033; T035, T036; T037 before the first review round; T038 last.

- Serial: `validate-governance.ps1` (T026, T030, T033, T034), `shared-governance.ps1` (T026, T035, T036) and
  `specrew-start.ps1` / `session-recovery.ps1` (T020, T022, T023) are each changed by several tasks.
- T022's combination test needs T020's record, so T020 lands first.
- T034 lands before T033 and before sign-off, so the sign-off push (T038) is one green push.
- T028 ends in a stop if the release script cannot be shown unable to publish: the suite stays excluded until the
  maintainer rules.
- Test runs follow the reviewer's word on feature 203's sweeps; when the reviewer asks for quiet, the command in hand
  finishes and the work holds.

### Phase 5: Start and checks (US1, SC-001 and SC-002)

- [x] T020 [owner: Implementer] [sp: 3.0] [US1] **Start records the whole files it wrote (D5-a, item 21).**
  - **Done (2026-11-15):** RED 8/10 in `d87f27c5` (end to end, the second start paused on the healed
    `squad.agent.md` and the created charters), GREEN 10/10 in `9930b869`; in the review layout the suite and the five
    lanes are green after two test-side fixes (USERNAME unset, `9acf6cec`; registration, `c9db9184`). Assertion 3 of
    `validator-hardening-iteration2.ps1` runs at T021.
  - **RED:** `validator-hardening-iteration2.ps1` assertion 3, plus a start unit suite: a healed `squad.agent.md` and
    a created charter are bookkeeping at the next start.
  - **Work:** `specrew start` writes the hash of each whole file it creates or repairs to a git-ignored record; at
    the next start, a file whose content matches its recorded hash is Specrew's, and an edited one is the user's.
  - **Acceptance:** an edited healed file pauses; a file with no record pauses once an earlier snapshot exists; the
    marker-block behaviour of T003 is unchanged.
  - **Trace:** FR-003; SC-002.
  - **Owns:** `scripts/specrew-start.ps1`, `scripts/internal/instruction-file-merge.ps1`, `.gitignore`,
    `tests/unit/**`.
- [x] T021 [owner: Implementer] [sp: 0.5] [US1] **`validator-hardening-iteration2.ps1` green and registered (item 29's
  remainder).**
  - **Done (2026-11-15), SC-002 met:** `5bfb685f`; in the review preflight's layout, all 17 checks pass, assertion 3
    included (668 s; home hook files and the repository unchanged). Registered in the release manifest; its census
    exclusion removed. Closes T003's remainder.
  - **Work:** its fixture copies every file git does not ignore, and nothing git ignores; tested in the preflight
    layout; run green; registered in the release manifest. Closes T003 and SC-002.
  - **Acceptance:** green on Windows with home unchanged; the census guard green.
  - **Trace:** SC-002; FR-012.
  - **Depends:** T020.
  - **Owns:** `tests/integration/validator-hardening-iteration2.ps1`, `.specrew/release-gate-suites.txt`,
    `tests/support/test-census.ps1`.
- [x] T022 [owner: Implementer] [sp: 1.25] [US1] **No session files means a first start (D6-a, item 22).**
  - **Done (2026-11-15):** RED 5/8 in `74b2034c`, GREEN 8/8 in `151ba706`, registered in `bf2b6e77`; the suite and the
    five lanes green in the review layout. The combination case passes: a fresh clone with the committed healed
    `squad.agent.md` and charters neither refuses nor pauses at its first no-console start and writes nothing into the
    origin; a later charter edit pauses, naming it. The fixture's identity file names no feature path; the absolute
    path a real identity file carries is T023's.
  - **RED:** start with neither session file and no console exits non-zero today. The combination test: a fresh
    clone whose committed files include a healed `squad.agent.md` and the five charters neither refuses nor pauses at
    its first start.
  - **Work:** a governed project with no session files starts as a first start; a session file that exists and
    cannot be read still refuses.
  - **Acceptance:** first start, exit 0; an unreadable `last-start-prompt.md` still refuses; a user edit to one of
    the committed files after that start pauses (the reviewer's condition, 2026-11-15).
  - **Trace:** FR-001; SC-001.
  - **Depends:** T020.
  - **Owns:** `scripts/internal/session-recovery.ps1`, `scripts/specrew-start.ps1`, `tests/unit/**`.
- [x] T023 [owner: Implementer] [sp: 1.0] [US1] **A resume path outside `-ProjectPath` is refused (item 23).**
  - **Done (2026-11-15):** RED 6/8 in `ed2a27e8`, GREEN 8/8 in `824e9604`, registered in `7f265f9b`; the suite and the
    five lanes green in the review layout. The release-cadence `closeout-identity-schema-parity.tests.ps1` now pins
    the relative path (DRIFT-206-I002-007). This repository's own identity file is rewritten relative at its next sync.
  - **RED:** a rooted resume path outside the fixture is followed today, and start writes into it.
  - **Work:** refuse a resume path outside `-ProjectPath`; the identity file stops carrying an absolute feature path.
  - **Acceptance:** a path inside the project resumes; no write lands outside the fixture.
  - **Trace:** FR-001; SC-001.
  - **Owns:** `scripts/internal/session-recovery.ps1`, `scripts/specrew-start.ps1`,
    `scripts/internal/sync-boundary-state.ps1`, `.squad/identity/now.md`, `tests/unit/**`.
- [x] T024 [owner: Implementer] [sp: 0.5] [US1] **`project-path-resolution-regression.ps1` green and registered (item
  24).**
  - **Done (2026-11-16):** registered per push by the maintainer's answer of 2026-11-16 11:34 ("OK for all", relayed by
    specrewreviewer-98): CI job `deterministic-gate`, step "Integration - script suites no lane ran before the test census
    (F-206 T015)", and lane `f206-changed-integration`; census exclusion removed (`e5c4bbf0`). Supervised run 6: six of
    six in 87 s; home hook files and the repository unchanged.
  - **Green (2026-11-15), SC-001 met; registration then awaited the maintainer:** the refusal removed and the fixture
    copies what git does not ignore, on the feature's branch (`300ec6de`); a dry run's summary names its folder (RED
    1/2 `9c2195d3`, GREEN 2/2 `acb20fac`). Supervised run 5: all six checks pass in 82 s, start with no recovery
    choice; home hook files and the repository unchanged; no probe folder. Registered once the maintainer has seen it
    (iteration 001 ruling).
  - **Work:** its fixture is built in a temp folder and copies every file git does not ignore; the refusal added at
    DRIFT-206-I001-019 is removed once T022, T023 and T025 are in; a supervised run with home hashed; registered.
  - **Acceptance:** green, nothing written into this repository, home unchanged; the census guard green.
  - **Trace:** SC-001; FR-012.
  - **Depends:** T022, T023, T025.
  - **Owns:** `tests/integration/project-path-resolution-regression.ps1`, `.github/workflows/specrew-ci.yml`,
    `.specrew/release-gate-suites.txt`, `tests/support/test-census.ps1`.
- [x] T025 [owner: Implementer] [sp: 1.0] [US1] **`specrew init`'s Squad probe runs in a temp folder (item 25).**
  - **Done (2026-11-15):** RED 3/4 in `091a0b06`, GREEN 4/4 in `4bca00ae`, registered in `bc501e7b`. The init case's
    cause (read): in a dry run on an existing folder no action names the project path, and the summary prints the path
    only after a real run ("Bootstrap completed for ..."), so the output never holds the path SC-001's case looks for.
    A gap in what the case can observe, not wrong path resolution; T024 settles it (bug list item 25).
  - **RED:** `specrew init -DryRun` leaves a probe folder in the install root today.
  - **Work:** the probe runs in a temp folder; a failed cleanup is reported; the cause of the init case found and
    recorded (discovery, within the 1.0).
  - **Acceptance:** no probe folder in the install root; a probe cleanup that fails is reported.
  - **Trace:** SC-001; SC-007.
  - **Owns:** `scripts/specrew-init.ps1`, `scripts/init/squad-deploy.ps1`, `tests/unit/**`.

### Phase 6: Deferred from iteration 001 (US3, US4)

- [x] T016 [owner: Implementer] [sp: 0.25] [US3] **Delete the empty `tests/integration/_ctl-spec.ps1`.**
  - **Done (2026-11-16):** deleted with its census exclusion (`773c1a36`); the census guard passes.
  - **Acceptance:** the census guard green without it.
  - **Trace:** FR-013.
  - **Owns:** `tests/integration/_ctl-spec.ps1`, `tests/support/test-census.ps1`.
- [x] T017 [owner: Implementer] [sp: 1.5] [US4] **No Node or React preset for this repository (item 6a).**
  - **Done (2026-11-16):** RED 2/3 `aa850089`, GREEN 3/3 `b5e6babf` (the root `package.json` removed; f049's
    assertion reads a fixture), registered `be0fe3eb`. Also fixes feature 203's B5F-085 once 206 merges (item 51).
  - **RED:** the resolver, run on this repository with feature 201's spec, selects a Node or React preset.
  - **Work:** remove the stray root `package.json`; move the f049 stack-detection assertion onto a fixture with its
    own `package.json`.
  - **Acceptance:** no Node or React preset here; the fixture still detects `nodejs`.
  - **Trace:** FR-014; SC-006.
  - **Owns:** `package.json`, `tests/integration/f049-i003-intake-engine-tests.ps1`, `tests/integration/fixtures/**`.

### Phase 7: Validator and nightly (US2, US3)

- [x] T026 [owner: Implementer] [sp: 1.0] [US2] **Abandoned is closed only with a recorded ruling
  (DRIFT-206-I001-010).**
  - **Done (2026-11-16):** RED 2/21 `6b057c76`, GREEN 21/21 `4fd14fb9` with group B's rulings recorded in the same
    commit (the maintainer's "OK for all", 2026-11-16 11:34, relayed by specrewreviewer-98, to "206: all four abandoned,
    publish suite per push, per push"). CI-mode full-repository run in clean worktrees at `4fd14fb9` and `eac9e210`:
    exit 0, no finding, the same 129 closed and 13 validated; the T005 table does not change.
  - **RED:** the closed-definition suite: `abandoned` with no recorded ruling is closed today.
  - **Work:** `Test-SpecrewIterationClosed` counts `abandoned` as closed only with a recorded ruling; lands with the
    maintainer's rulings on group B (197/002, 197/007, 197/008, 198/005), so the T005 table does not change. If any
    of the four has no ruling, the work stops for the maintainer.
  - **Acceptance:** `abandoned` with a ruling is closed; a CI-mode full-repository run gives no new finding. Feature
    206 does not close without this task.
  - **Trace:** FR-008; FR-008a.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`,
    `extensions/specrew-speckit/scripts/validate-governance.ps1`, their `.specify` mirrors, the deployed hash file,
    `tests/unit/**`.
- [x] T032 [owner: Implementer] [sp: 0.75] [US1] **A malformed managed-block opener is unbalanced (item 33).**
  - **Done (2026-11-16):** RED 2/15 `e496b099`, GREEN 15/15 `f329c895`.
  - **RED:** an opener with `<<<` where `>>>` belongs is treated as a matched pair today.
  - **Acceptance:** a matched pair still strips; a mismatched pair compares the whole file.
  - **Trace:** FR-003.
  - **Owns:** `scripts/internal/instruction-file-merge.ps1`, `tests/unit/**`.
- [x] T031 [owner: Implementer] [sp: 1.5] [US3] **The census guard reads YAML and shell by structure (items 31, 32).**
  - **Done (2026-11-16):** RED 33/83 `7e7998b1`; item 32 `25f191f2`, item 31 `359b1c95`; 83/83, the repository's own
    workflows included.
  - **RED:** one fixture per construct: `steps:` inside a block scalar, a key of the same name at another level, a
    comment after `;`.
  - **Work:** the guard tracks block scalars and job and step structure, and treats `;` as a comment boundary.
  - **Acceptance:** each fixture is read correctly; a real step still registers.
  - **Trace:** FR-011; SC-004.
  - **Owns:** `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, `tests/support/test-census.ps1`,
    `tests/unit/fixtures/**`.
- [x] T030 [owner: Implementer] [sp: 1.25] [US2] **Every repository-level stop writes its message hash (items 30,
  34).**
  - **Done (2026-11-16):** RED 3 `eda9fff9`; item 30 `57e0cdbd`, item 34 `899f76f8`; nightly-tracking-issue 24/24.
  - **RED:** two different messages in one stop category give one fingerprint today.
  - **Work:** the four repository-level stops and the outer catch pass their messages with `-FailureMessages`.
  - **Acceptance:** two messages give two fingerprints; the same message gives one.
  - **Trace:** FR-009.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`, its `.specify` mirror, the deployed hash
    file, `tests/unit/**`.

### Phase 8: Scripts and CI (US3)

- [x] T027 [owner: Implementer] [sp: 0.25] [US3] **Specrew CI gets a manual trigger (item 12).**
  - **Done (2026-11-16):** `5a0f65a8`; the workflow parses; its first run is the next push's.
  - **Work:** `workflow_dispatch:` on Specrew CI, as the other two workflows have.
  - **Acceptance:** the workflow file parses and the next push's run is green.
  - **Trace:** FR-012.
  - **Owns:** `.github/workflows/specrew-ci.yml`.
- [x] T028 [owner: Implementer] [sp: 0.75] [US3] **`distribution-module-publish.ps1` cannot publish (item 17, high).**
  - **Done (2026-11-16):** RED 5/5 `ae620f15`, GREEN 5/5 `619b1a85`, unit suite registered `3996f9a9`; the suite
    restores `SPECREW_BUILD_COMMIT` too (reviewer's reading; RED 1/6 `c7a9453e`, GREEN 6/6 `ad64464a`). Run per push by
    the maintainer's answer of 2026-11-16 11:34 ("OK for all" to "publish suite per push"; the reviewer's first gloss
    named the unit suite and was corrected): CI job `deterministic-gate`, step "Integration - script suites no lane ran
    before the test census (F-206 T015)", and lane `f206-changed-integration`; the unit suite in `f206-unit-suites`
    (`6c4b2b44`). Local runs: exit 0 in 77 s; home hook files and PowerShellGet's folder unchanged.
  - **Read first:** the suite and the release script it calls, for any path that publishes or writes home.
  - **RED:** with `PSGALLERY_API_KEY` set, the publish case reaches a publish call today.
  - **Work:** the suite clears and restores `PSGALLERY_API_KEY` itself; the release script refuses a publish nobody
    asked for.
  - **Acceptance:** no publish call with the key set; the case still fails with no key. Run, or kept excluded, by the
    maintainer's ruling (**stop**).
  - **Trace:** FR-012; SC-007.
  - **Owns:** `tests/integration/distribution-module-publish.ps1`, `scripts/release/**`.
- [x] T029 [owner: Implementer] [sp: 0.25] [US3] **`multi-host-smoke.ps1` stops assigning to `$Host` (item 18).**
  - **Done (2026-11-16):** `61e46c46` (17 uses renamed); read and parsed, not run.
  - **Work:** rename the loop variable. Read, not run: the script deploys hooks.
  - **Acceptance:** the diff renames only that variable; the script parses.
  - **Trace:** FR-012.
  - **Owns:** `tests/manual/multi-host-smoke.ps1`.

### Phase 9: Review and closeout records (US2, items 37, 39, 41, 44)

- [x] T034 [owner: Implementer] [sp: 1.0] [US2] **A record written before its approval is not stale (D2-a, item 39).**
  - **Done (2026-11-16):** RED 4/7 `4128585a`, GREEN 7/7 `3a3ba803`, registered `8b23047a`.
  - **RED:** review.md beside `executing`, with the review-signoff crossing pending, fails Lint today.
  - **Work:** the staleness checks accept a record whose boundary approval is still pending (review.md beside
    `executing`, retro.md beside `reviewing`), read through the existing start-context reader; where
    `start-context.json` is absent (CI, a fresh clone), the record is accepted with a warning naming the file.
  - **Acceptance (five cases):** record before the verdict passes; at the verdict passes; after the line moves
    passes; the verdict recorded with the line behind fails as today; no `start-context.json` gives the warning and no
    error.
  - **Trace:** FR-016; SC-009.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`, its `.specify` mirror, the deployed hash
    file, `tests/unit/**`.
- [x] T033 [owner: Implementer] [sp: 1.0] [US2] **A `deferred` task verdict with its decision id (D1-a, item 37).**
  - **Done (2026-11-16):** RED 3/4 `53c78d13`, GREEN 4/4 `078578ae`, registered `7ef85fb9`.
  - **RED:** `accepted` with a `deferred` row naming an existing decision fails today.
  - **Work:** review.md accepts `deferred` beside `accepted` when the row names a decision id present in
    `.squad/decisions.md`.
  - **Acceptance:** no decision id fails; a decision id that does not exist fails; `needs-work` beside `accepted`
    still fails. Feature 203's T014 is not covered here; it goes to proposal 206.
  - **Trace:** FR-015; SC-008.
  - **Depends:** T034.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`, its `.specify` mirror, the deployed hash
    file, `tests/unit/**`.
- [x] T035 [owner: Implementer] [sp: 1.25] [US2] **The closeout dashboard is drawn after the verdict (D3-a, item 41).**
  - **Done (2026-11-16):** RED 2/2 `4d391ecd`, GREEN 2/2 `7921e149` (the redraw runs after the mirrors and before
    the seal; a failed redraw warns `CLOSEOUT_DASHBOARD_NOT_REDRAWN` and the seal is still written), registered `3d79d258`.
  - **RED:** a fixture closeout seals a dashboard drawn before the verdict.
  - **Work:** the capture's closeout tail redraws the dashboard after `Sync-SpecrewCrossingMirrors` and before
    `Invoke-SpecrewCloseoutSeal`.
  - **Acceptance:** the sealed dashboard shows the delivered points, `iteration-closeout` and the iteration under
    Recent Shipped; a redraw that throws still seals, with a warning.
  - **Trace:** FR-017; SC-010.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`, its `.specify` mirror, the deployed hash
    file, `tests/unit/**`.
- [x] T036 [owner: Implementer] [sp: 1.5] [US2] **The Completed date and the open hardening rows (D4-a, item 44).**
  - **Done (2026-11-16):** RED 3/6 `1f8ab2fa`, GREEN 6/6 `217ad08f`, registered `bb4e8cb5`.
  - **RED:** a fixture closeout leaves plan.md `complete` with no Completed date, and the arrival names no open
    hardening row.
  - **Work:** the mirror write that moves plan.md to `complete` writes the Completed date; the closeout arrival lists
    open hardening rows in the pending-verdict artifact.
  - **Acceptance:** a second capture leaves the date unchanged; all rows recorded gives no owed line.
  - **Trace:** FR-018; SC-011.
  - **Depends:** T035.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`, its `.specify` mirror,
    `scripts/internal/sync-boundary-state.ps1`, the deployed hash file, `tests/unit/**`.
- [x] T037 [owner: Implementer] [sp: 0.25] [US3] **The two reviewer-brief promotions from iteration 001's retro.**
  - **Done (2026-11-15):** both are in `iterations/002/review-scope-round-1.md` ("Two standing instructions"), the
    scope file the first review round is given with `--design-context-ref`.
  - **Work:** this iteration's review brief asks the reviewer, for any text-matching rule, to try a phrasing that
    matches the pattern but denies or conditions it; and, for any test that reads workflow or script files, to try
    each YAML and shell construct that can hide or fake a line.
  - **Acceptance:** both in the brief before the first review round.
  - **Trace:** FR-003; FR-011.
  - **Owns:** `specs/206-bug-bash/iterations/002/**`.
- [ ] T038 [owner: Implementer] [sp: 0.25] [US2] **Review sign-off records.**
  - **Work:** the review records, pushed before their verdict.
  - **Acceptance:** Lint stays green on that push (SC-009 in use).
  - **Trace:** SC-009.
  - **Depends:** T034.
  - **Owns:** `specs/206-bug-bash/iterations/002/**`.

Sum of iteration-002 effort: 20.0 SP.

## Traceability

| Requirement | Tasks | | Success criterion | Tasks |
| --- | --- | --- | --- | --- |
| FR-001 | T001; T022, T023 | | SC-001 | T001, T014, T015; T022 to T025 |
| FR-002 | T002 | | SC-002 | T002, T003, T015; T020, T021 |
| FR-003 | T003; T020, T032, T037 | | SC-003 | T010 |
| FR-004 | T004 | | SC-004 | T013; T031 |
| FR-005 | T004, T007 | | SC-005 | T008 |
| FR-006 | T007, T010 | | SC-006 | T017 |
| FR-007 | T008 | | SC-007 | T014, T018; T025, T028 |
| FR-008 | T009; T026 | | SC-008 | T033 |
| FR-008a | T005, T006, T010; T026 | | SC-009 | T034, T038 |
| FR-009 | T012; T030 | | SC-010 | T035 |
| FR-010 | T011 | | SC-011 | T036 |
| FR-011 | T013; T031, T037 | | | |
| FR-012 | T014, T015; T021, T024, T027, T028, T029 | | | |
| FR-013 | T016 | | | |
| FR-014 | T017 | | | |
| FR-015 | T033 | | | |
| FR-016 | T034 | | | |
| FR-017 | T035 | | | |
| FR-018 | T036 | | | |

Iteration-002 tasks follow the semicolon. Every task traces to an FR or SC, and every FR and SC has a task.
Sum of iteration-001 effort: 20.0 SP; of iteration-002 effort: 20.0 SP.
