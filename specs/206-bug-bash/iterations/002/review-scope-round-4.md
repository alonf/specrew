# Review Scope: Feature 206, Iteration 002, Round 4

This file is for the reviewer: what this round covers, and in what order. It is passed with `--design-context-ref`, so
it comes first in the review frame. It adds to the spec, the plan, the design analysis and the scope files of rounds 1
to 3 (`review-scope-round-1.md` to `review-scope-round-3.md`) and does not replace them.

- **Feature:** 206 (bug bash). **Iteration:** 002.
- **This is round 4 of 4, the last round in the budget.** No round follows it. If you stop before Section 1 is read,
  the nine round 1 fixes stay unread for a third time and the iteration is signed off without them.
- **Round 1** reviewed Phase 5 at head `7c006d67` (run `run-20261115-233001030-c21b0c2f`, 10 findings, none
  blocking).
- **Round 2** (run `run-20261116-173258054-8f47fc5f`, head `3ee41574`) ended partial with nine findings and did not
  reach Section 1 (DRIFT-206-I002-017).
- **Round 3** (run `run-20261117-082153391-a5841b35`, head `ff6fe55e`) ended partial with 12 findings (1 major, 9
  minor, 2 notes) and did not reach Section 1 either. Its host gives the reviewer Read, Glob, Grep and Write only, so
  it could not show a commit (DRIFT-206-I002-019).
- **This round:** Section 1 first, then Section 2, then Section 3. Everything since `7c006d67`.
- **Mirrors:** `extensions/specrew-speckit/**` is the source. Each `.specify/extensions/specrew-speckit/**` change is a
  byte copy with its hash refreshed in `.specrew-extension-runtime.json`, which lane `f206-deployed-hash-record` checks.
- **Not in scope:** `scripts/internal/continuous-co-review/**`, the capture stores under `scripts/internal/bootstrap/`
  and `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` are feature 203's and were not changed.

## How to Spend the Time

This file gives a reviewer with no shell what a shell would: the commit list, the changed files, and each fix located by
file and function, so every one can be read with Read and Grep. If your host gives you a shell, read the git history
yourself (`git log`, `git show <commit>`) and check the commit list below against it rather than trusting it.

The deadline you are given is counted from your start; the verification that ran before you does not use it. You
cannot read a clock, so do not stop for time on a guess. Cover Section 1 and Section 2 before you publish a partial
candidate. If you must stop early, say which items you covered.

**State a concrete failure scenario for every blocking or major finding, and include the literal clause 'Failure
scenario:' in its description.** Without it, the engine on this branch stores the finding as minor (bug list item
61).

**The current date and time** when this file was written: 2026-11-17 16:30Z (18:30 the maintainer's local time).

## Maintainer Answers This Round Rests On

1. 2026-11-16 11:34 local, "OK for all" (relayed): 197/002, 197/007, 197/008 and 198/005 are abandoned by ruling
   (T026); the publish suite runs per push (T028); SC-001's script runs per push (T024).
2. 2026-11-16 14:38 local, "206 publish: A" (relayed): the publish suite runs in its own Windows job.
3. 2026-11-16 20:56 local, "OK for both" (relayed): fix round 2's six findings (F1 to F6) before round 3.
4. 2026-11-17 about 01:52 local, "You can apply both" (typed): the `windows-shim-suites` job's Node 24 fix, and feature
   203's Cross-Platform Validation fix taken onto this branch.
5. 2026-11-17 18:13 local, "206 round 3: fix four" (relayed): fix round 3's major finding and three minor ones; the
   rest go to the bug list (items 74 to 82).

## Section 1: The Nine Round 1 Fixes (read these first)

Each has a failing test first and one finding per commit (DRIFT-206-I002-010). Read each where it is now. The line
numbers are as of this file.

| Round 1 finding | Commit | What it fixed | Where to read it now |
| --- | --- | --- | --- |
| F1 | `409df238` | `.github/copilot-instructions.md` (shared by Specrew and the user) is never stored in or read from the start-written record; T003's block-aware classifier decides its changes | `scripts/internal/instruction-file-merge.ps1`: `$script:SpecrewSharedInstructionFiles` and `Test-SpecrewSharedInstructionFile` (:226 to :237), `Read-SpecrewStartWrittenFilesRecord` (:283), `Save-SpecrewStartWrittenFilesRecord` (:308). `scripts/specrew-start.ps1`: `Get-RestartTriggerFiles` (:2232; the change at :2250) |
| F2 | `541708af` | SC-001's fixture writes the copied identity file's feature path relative, not the writing machine's absolute path | `tests/integration/project-path-resolution-regression.ps1`: `Set-Sc001FixtureIdentityRelative` (:26), called at :165 |
| F3 | `1553dbdc` | a path through a junction or symlink below the project is outside; unknown is outside | `scripts/internal/sync-boundary-state.ps1`: `Test-SpecrewPathInsideProject` (:174; the change at :214). Tests: `tests/unit/resume-path-inside-project.tests.ps1`, Describe at :97 |
| F4 | `79c3c224` | an outside session feature path that start did not adopt is cleared before it is written back | `scripts/specrew-start.ps1`: the `$validatedSessionState` assignment in the script body (the `elseif` at :3391). Tests: `resume-path-inside-project.tests.ps1`, Describe at :180 |
| F5 | `0245115a` | start records each writing step in a region of its own, so none spans a prompt | `scripts/internal/instruction-file-merge.ps1`: `Start-SpecrewStartWrittenRegion` (:370), `Complete-SpecrewStartWrittenRegion` (:382). `scripts/specrew-start.ps1`: the three regions (heal :3054 to :3062; skill repair :3213 to :3232; crew :3528 to :3542) |
| F6 | `5bbaec3b` | SC-001's script gives each run its own temp folder | `tests/integration/project-path-resolution-regression.ps1` :104 |
| F7 | `55d42b72` | the identity-writer case runs a real boundary sync on a temp project instead of reading source text | `tests/unit/resume-path-inside-project.tests.ps1` :230 |
| F9 | `f87330bd` | SC-001's update `--info`, team list and review cases run in the fixture | `tests/integration/project-path-resolution-regression.ps1` :209, :217, :226 |
| F10 | `32244053` | the Squad probe's comment names the probe root | `scripts/init/squad-deploy.ps1`: `Test-SquadInitSupportsNonInteractive` (:23) |

F8 was noted and not changed. Round 1's findings are in its result (run `run-20261115-233001030-c21b0c2f`).

Round 1 also listed three source-text cases that remain, each beside a behavioural case: start's regions (F5's region
case and T020's end-to-end), init's probe call, and SC-001's identity call (DRIFT-206-I002-010). Say if any of them can
pass while the behaviour is wrong.

## Section 2: The Round 2 and Round 3 Fixes

### 2a. Round 2's six fixes

Each has its RED commit, then one fix commit (DRIFT-206-I002-017). Round 3 read these and raised findings on F2, F3 and
F6; read them again only where a round 3 fix below touches them.

| Round 2 finding | RED | Fix | Where |
| --- | --- | --- | --- |
| F1 `finding-30faa1624cf6d7a1` | `6cc4da16` | `c1ed64c7` | `validate-governance.ps1`, the closed-index rebuild (`-RebuildClosedIndex`) |
| F2 `finding-124f7de3f876daab` | `e66e3191` | `b2e0b890` | `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`: `Test-WorkflowConditionRuns`, `Get-WorkflowRunnerOs`, `Test-WorkflowRunsPerPush`, `Get-WorkflowRunText`; `.github/workflows/specrew-ci.yml`, job `windows-shim-suites` |
| F3 `finding-8440e050721c87ad` | `982ffe9f` | `e22084ca` | `shared-governance.ps1`: `Test-SpecrewIterationRulingRecorded` |
| F4 `finding-4b72620596668b79` | `f37ba01d` | `a56476d6` | `scripts/internal/session-recovery.ps1`, the identity reader's relative path |
| F5 `finding-e2ef0515b3bc7a8f` | `e31a5fd3` | `d1e428b9` | `validate-governance.ps1`: `Get-SpecrewRecordApprovalState` (T034) |
| F6 `finding-6b34e25ddeb81569` | `50f97212` | `cca9cb65` | `validate-governance.ps1`, the deferred-row check in the Task Verdicts loop (T033) |

Also since round 2: `f41ae713` (RED) and `e3a26586` (fix), the `windows-shim-suites` job's Node 24 step and `if:
always()` on its second suite; `00cef4d5`, feature 203's `f2493ccc` cherry-picked (DRIFT-206-I002-018). The patch-id
of `00cef4d5` and of 203's `f2493ccc` is the same (`git patch-id --stable`: `8dd1c2c0f146d4be387cb516f010521377de0edb`
for both), so the text is identical; review it in feature 203.

**CI on `ff6fe55e`** (round 3's head): all three workflows green. Specrew CI run `43985711026`: `windows-shim-suites`
passed, so both shim suites ran and passed (round 3's note `finding-46dd269bed6f96cd`). Cross-Platform Validation run
`43985710873` and Test run `43985710819` green, Ubuntu Validation included.

### 2b. Round 3's four fixes

Each has its RED commit, then one fix commit (DRIFT-206-I002-019):

| Round 3 finding | RED | Fix | What changed, and where |
| --- | --- | --- | --- |
| `finding-f194651984ecf15e` (major) | `2eeba428` 2/12 | `54c70599` | the deferred row finds its plan task case-insensitively, as `$reviewedTaskIds` does, and fails when no plan task has its id. `validate-governance.ps1`, the deferred-row check (search "finding-f194651984ecf15e") |
| `finding-877eda7300798107` | `16fcff2c` 1/14 | `46b74cb7` | decisions.md's line endings are made LF before comments and fences are removed. Same check (search "finding-877eda7300798107") |
| `finding-a9d93413b59ece33` | `70cb1571` 1/54 | `6cefbbe4` | HTML comments are removed from the whole state.md before headings are read. `shared-governance.ps1`: `Test-SpecrewIterationRulingRecorded` |
| `finding-c79fd0045cfa0bb1` | `6860bfef` 1/92 | `1b793a5c` | each step's run text is held with its condition and judged when the job ends, with the job's runner as finally read. `every-suite-is-named-by-a-lane.tests.ps1`: `Get-WorkflowRunText` (`$jobSteps`, `$flushStep`, `$flushJob`) |

What to attack:

- **f194:** a deferred row whose id differs in case from a plan task that is deferred (must pass); from one that is
  done (must fail); a plan with two rows of the same id in different case.
- **877e:** a ledger with mixed line endings; a lone `\r`; a fence opened and never closed.
- **a9d9:** a `<!--` inside a code fence above the Disposition heading, with a `-->` further down: the whole-page
  removal now runs before fences are read. Is a real ruling lost?
- **c79f:** a job whose `runs-on` comes after steps and whose job-level `if:` comes after `runs-on`.

## Section 3: The Rest of the Iteration

Round 2's scope file lists the Phase 6 to 9 changes (T026, T032, T031, T027, T028, T034, T033, T035, T036, T037) and
round 3's lists T030, T029, T017 and T016. Round 3 read T030's stop call sites, T029, and T016 and T017's deletions.
Not yet read in depth: T017's and T030's tests (`tests/unit/no-node-preset-for-this-repo.tests.ps1`,
`tests/unit/nightly-tracking-issue.tests.ps1`).

## Known and Deferred

- Bug list items 52 and 53; items 58 to 62 and 66 to 72 (the review engine and the downstream project's reports).
- Round 2's F7, F8 and F9 (items 63 to 65).
- Round 3's other eight findings (items 75 to 82). Items 75 to 77 are word-list rules; item 74 is the design question
  they share (a structured line instead of more words). Do not report another phrasing those lists miss unless it is
  of a new kind.

**Two standing instructions from iteration 001's retro (T037):**

- **For any text-matching rule, try a phrasing that matches the pattern but denies or conditions it.**
- **For any test that reads workflow or script files, try each YAML and shell construct that can hide or fake a
  line:** comments, block scalars, keys of the same name at other levels, and statement delimiters.

## The Range: Commits and Changed Files

Commits from `7c006d67` (exclusive), oldest first. The records commit that adds this file comes after the last one
listed.

```text
00defd64b records(206/002): DRIFT-206-I002-010, round 1's findings and the maintainer's decision to fix nine before round 2
846855340 test(206/002 round 1 F1): RED 2 - a user's uncommitted copilot-instructions.md edit is recorded as Specrew's
409df238f fix(206/002 round 1 F1): copilot-instructions.md is never in the start-written record; GREEN
8ddb2c4d2 test(206/002 round 1 F2): RED 5/5 - SC-001's fixture keeps this machine's absolute identity path
541708afa fix(206/002 round 1 F2): SC-001's fixture writes the copied identity path relative; GREEN 5/5
5cfbd8c73 chore(206/002 round 1 F2): register the SC-001 fixture-identity suite in the release manifest
c6999b01d records(206): bug list items 46 and 47; items 45 to 47 placed at the top of iteration 003's candidates
749fa9a42 test(206/002 round 1 F6, F9): RED 2/77 - SC-001's temp folder is fixed-name; three cases run in this repository
5bbaec3b4 fix(206/002 round 1 F6): SC-001's script gives each run its own temp folder
f87330bd5 fix(206/002 round 1 F9): SC-001's update --info, team list and review cases run in the fixture
a069b2e7f records(206): bug item 46's cause, established and reproduced by the reviewer (a command line past 32,767 characters)
322440533 docs(206/002 round 1 F10): the Squad probe's comment names the probe root, not the install root
0f3dbcbb4 test(206/002 round 1 F4): RED 1 - an outside session path start does not adopt is still written to the prompt
79c3c2247 fix(206/002 round 1 F4): an outside session path start does not adopt is cleared before it is written back; GREEN
fe91ee00f test(206/002 round 1 F3): RED 2 - a junction or symlink inside the project passes the inside-project check
1553dbdcb fix(206/002 round 1 F3): a path through a junction or symlink below the project is outside; GREEN
90a55bf48 test(206/002 round 1 F5): RED 2 - start's record window spans its prompts
0245115a3 fix(206/002 round 1 F5): start records each writing step in a region of its own; GREEN
55d42b728 test(206/002 round 1 F7): the identity-writer case runs a real boundary sync instead of reading source text
00a9516ad records(206/002): DRIFT-206-I002-010 resolved - round 1's nine fixes, the phase's source-text inventory
23c608d73 records(206): bug item 46 confirmed on the other machine; the fix's third part (lint scope), about 2.5 SP
773c1a363 chore(206/002 T016): delete the empty tests/integration/_ctl-spec.ps1 (FR-013)
aa850089a test(206/002 T017): RED 2/3 - the quality resolver gives this repository a Node preset (item 6a)
b5e6babf0 fix(206/002 T017): remove the stray root package.json; f049's stack assertion reads a fixture; GREEN 3/3
be0fe3eb6 chore(206/002 T017): register the no-node-preset suite in the release manifest
e496b099a test(206/002 T032): RED 2/15 - a managed-block marker whose trailing arrows point the wrong way is stripped (item 33)
f329c8959 fix(206/002 T032): a managed-block marker must point one way at both ends; GREEN 15/15 (item 33)
7e7998b15 test(206/002 T031): RED 33/83 - the census guard reads steps: in a block scalar and at another level, and a comment after ; (items 31, 32)
25f191f22 fix(206/002 T031): the census guard's shell reader starts a comment after a statement delimiter (item 32)
359b1c95b fix(206/002 T031): the census guard reads a workflow's real job and step structure (item 31); GREEN 83/83
eda9fff9d test(206/002 T030): RED 3 - four repository-level stops and the outer catch write their category alone (items 30, 34)
57e0cdbd1 fix(206/002 T030): the four count-only repository stops write their messages as hashes (item 30)
899f76f81 fix(206/002 T030): the validator's outer catch passes the exception's text, so only its hash is written (item 34); GREEN 24/24
5a0f65a81 ci(206/002 T027): Specrew CI can be started by hand (workflow_dispatch; item 12)
61e46c463 fix(206/002 T029): multi-host-smoke.ps1's loop variable no longer assigns to the read-only $Host (item 18)
4128585a7 test(206/002 T034): RED 4/7 - a record written before its boundary approval is called stale (item 39, D2-a)
3a3ba8031 fix(206/002 T034): a record written while its boundary approval is pending is not stale; GREEN 7/7 (item 39, D2-a)
8b23047ae chore(206/002 T034): register the record-before-approval suite in the release manifest
377785929 records(206/002): T016, T017, T027, T029, T030, T031, T032, T034 done; bug items 48 to 51 (203's dry run); item 39's link
53c78d13d test(206/002 T033): RED 3/4 - a task deferred by a recorded decision has no honest review verdict (item 37, D1-a)
078578aea fix(206/002 T033): review.md accepts a deferred task verdict that names its decision; GREEN 4/4 (item 37, D1-a)
7ef85fb9f chore(206/002 T033): register the deferred-task-verdict suite in the release manifest
4d391ecd7 test(206/002 T035): RED 2/2 - the closeout capture seals the dashboard drawn before the verdict (item 41, D3-a)
7921e149d fix(206/002 T035): the closeout capture redraws the iteration dashboard before it seals; GREEN 2/2 (item 41, D3-a)
3d79d2580 chore(206/002 T035): register the closeout-dashboard-redraw suite in the release manifest
1f8ab2fa1 test(206/002 T036): RED 3/6 - closeout leaves plan.md with no Completed date and the arrival names no open hardening row (item 44, D4-a)
217ad08f3 fix(206/002 T036): closeout writes the Completed date and the arrival names the open hardening items; GREEN 6/6 (item 44, D4-a)
bb4e8cb52 chore(206/002 T036): register the closeout-completed-and-open-rows suite in the release manifest
eac162b42 records(206/002): T033, T035 and T036 done
53bc65749 chore(206/002): the unit lane names the six suites added since Phase 5
ae620f15e test(206/002 T028): RED 5/5 - the release script reaches Publish-Module with the key set and nobody asking (item 17, high)
619b1a855 fix(206/002 T028): the release script refuses a live publish nobody asked for, and the publish suite clears the key; GREEN 5/5 (item 17, high)
3996f9a9e chore(206/002 T028): register the release-script-refuses-unasked-publish suite in the release manifest
9c4497ee9 records(206/002): DRIFT-206-I002-011 - T028's fix lies partly outside the files the task names
fdb42f2dc records(206/002): DRIFT-206-I002-011's class closure states its reason in the checked form
eac9e210c records(206/002): DRIFT-206-I002-012 - a Windows co-review CI step hung on fdb42f2d and passed on its one rerun
6b057c766 test(206/002 T026): RED 2/21 - an abandoned iteration with no recorded ruling is counted closed (DRIFT-206-I001-010)
4fd14fb99 fix(206/002 T026): abandoned is closed only with the maintainer's ruling recorded; group B's rulings recorded; GREEN 21/21 (DRIFT-206-I001-010)
c7a9453e7 test(206/002 T028): RED 1/6 - the publish suite sets SPECREW_BUILD_COMMIT and never restores it
ad64464a4 fix(206/002 T028): the publish suite restores SPECREW_BUILD_COMMIT on exit; GREEN 6/6
6c4b2b44d chore(206/002 T028): the publish suite runs per push - CI's deterministic gate and the f206-changed-integration lane
e5c4bbf03 chore(206/002 T024): SC-001's script runs per push - CI's deterministic gate and the f206-changed-integration lane
02c3e6ff3 records(206/002): T024, T026, T028 done; items 48 to 51 placed as iteration 003 candidates; DRIFT-206-I002-013 and item 52
1edab5305 records(206/002): the round 2 scope file
0b9664451 records(206/002): round 2 scope - the publish secret's facts, T034's two observations; bug list item 53
792e432d3 fix(206/002 T026): the closed check's comment cites no drift id in the deployed script
db3fa1715 test(206/002 T028): RED 1/7 - the publish suite cannot copy a hidden release file (Specrew CI, Linux)
e97fdb18e fix(206/002 T028): the publish suite copies hidden release files; GREEN 7/7
b616ce233 test(206/002 T023): RED 14/27 - a path one OS calls absolute and another does not (Specrew CI, Linux)
1cb31e600 test(206/002 T023): restore the UNC cases and the slash replace that b616ce23 lost
7f85bdede fix(206/002 T023): a path one OS calls absolute is absolute on every OS; a foreign identity path is not used; GREEN 27/27
52cd449d2 records(206/002): DRIFT-206-I002-014 (Linux CI, the registration order); scope and plan rework; bug items 54, 55
9f8c270fe records(206/002): the RED of record for the path-kind fix (14/27 at 1cb31e60); two scope notes
936f8463c test(206/002 T028): RED 2/10 - the publish suite runs on Linux, where PowerShellGet rejects the module
347de313b fix(206/002 T028): the publish suite runs per push in its own windows-latest Specrew CI job; GREEN 10/10
9d314cfde records(206/002): DRIFT-206-I002-015 (the publish suite moves to a Windows job); bug item 56; scope and rework
3ee41574a records(206/002): DRIFT-206-I002-016 - Lint's gallery install failed on 9d314cfd; one rerun, green; bug item 57
6cc4da16a test(206/002 round 2 F1): RED 1/46 - -RebuildClosedIndex indexes an abandoned iteration with no recorded ruling
c1ed64c73 fix(206/002 round 2 F1): -RebuildClosedIndex leaves an abandoned iteration without a recorded ruling out of the index; GREEN 46/46
e66e31915 test(206/002 round 2 F2): RED 2/87 - the census guard counts a CI step or job that has an if: as running its suite
b2e0b8902 fix(206/002 round 2 F2): the census guard counts a conditioned CI step only when its condition runs; the two never-run suites move to a Windows job; GREEN 90/90
982ffe9f6 test(206/002 round 2 F3): RED 6/53 - the ruling matcher accepts a denied, conditioned, commented, sub-headed or future ruling
e22084ca4 fix(206/002 round 2 F3): the ruling matcher reads the Disposition as Markdown and refuses a denied, conditioned or future ruling; GREEN 53/53
f37ba01da test(206/002 round 2 F4): RED 1/28 - the identity reader adopts a relative feature path that climbs out of the project
a56476d61 fix(206/002 round 2 F4): the identity reader holds a relative feature path to the inside check; GREEN 28/28
e31a5fd3c test(206/002 round 2 F5): RED 4/12 - T034 reads a record as pending under any earlier approval, and under any iteration when the session names none
d1e428b98 fix(206/002 round 2 F5): T034 reads a record as pending only under the approval right before it, and only in the newest iteration when the session names none; GREEN 12/12
50f972124 test(206/002 round 2 F6): RED 6/10 - a deferred review row passes with a commented-out, denied, conditional or absent decision, or a task the plan does not defer
cca9cb65b fix(206/002 round 2 F6): a deferred review row must match a deferred plan task and name an undenied, unconditioned decision the ledger holds outside comments; GREEN 10/10
7b54d49d5 records(206/002): DRIFT-206-I002-017 - round 2 partial, the maintainer's "fix six" (20:56, relayed); bug items 58 to 65; round 3 scope; rework row
f41ae7133 test(206/002 round 2 F2): RED 2/12 - the windows-shim-suites job sets up no Node 24 and skips its second suite when the first fails
e3a265868 fix(206/002 round 2 F2): windows-shim-suites sets up Node 24 and runs its second suite even when the first fails; GREEN 12/12
00cef4d5f fix(203/002 T015): Cross-Platform Validation's three Ubuntu "Setup PowerShell" steps use the runner's pwsh when it has one and otherwise install it from Microsoft's package feed - the pinned 7.4.1 .deb cannot install on ubuntu-26.04, where ubuntu-latest is moving (205's run 43954284857, job 133604592995; 206's run 43956458711, job 133612182895: "powershell depends on libicu72 | ... | libicu52", every later step skipped)
ff6fe55ed records(206/002): DRIFT-206-I002-018 - CI's first run of windows-shim-suites (Node 22) and Ubuntu Validation's PowerShell install; the maintainer's "You can apply both"; bug items 66 to 72; one more item 52 sighting
2eeba428e test(206/002 round 3 f194651984ecf15e): RED 2/12 - a deferred review row whose task id differs from the plan's only in case skips the plan-status check, and a deferred row for a task no plan has passes
54c70599a fix(206/002 round 3 f194651984ecf15e): a deferred review row finds its plan task with the same case-insensitive comparison as the verdict-row check, and fails when no plan task has its id; GREEN 12/12
16fcff2cd test(206/002 round 3 877eda7300798107): RED 1/14 - in a decisions.md with CRLF line endings no code fence is removed, so a decision id written only inside a fenced example counts as a ledger entry
46b74cb7e fix(206/002 round 3 877eda7300798107): the deferred-row check makes decisions.md's line endings LF before removing comments and code fences, so a fenced example is not an entry in a CRLF ledger; GREEN 14/14
70cb1571a test(206/002 round 3 a9d93413b59ece33): RED 1/54 - a Disposition section inside an HTML comment that opens before its heading still reads as the maintainer's ruling
6cefbbe4a fix(206/002 round 3 a9d93413b59ece33): the ruling reader removes HTML comments from the whole state.md before it reads headings, so a Disposition section commented out with its heading is no ruling; GREEN 54/54; the four recorded rulings (174/007, 197/006, 198/010, 198/011) still read
6860bfef8 test(206/002 round 3 c79fd0045cfa0bb1): RED 1/92 - a job whose runs-on comes after its steps is judged with no runner, so a step under "if: runner.os != 'Linux'" on an Ubuntu job counts as running
1b793a5c9 fix(206/002 round 3 c79fd0045cfa0bb1): the lane census holds each step's run text with its condition and judges both when the job ends, so a runs-on written after steps: still decides a step's runner.os condition; GREEN 92/92
```

Changed files from `7c006d67` (the `.specify/extensions/specrew-speckit/` mirrors are byte copies of `extensions/`):

```text
.github/workflows/cross-platform-validation.yml
.github/workflows/publish-module.yml
.github/workflows/specrew-ci.yml
.specify/extensions/specrew-speckit/.specrew-extension-runtime.json
.specify/extensions/specrew-speckit/scripts/shared-governance.ps1
.specify/extensions/specrew-speckit/scripts/validate-governance.ps1
.specrew/release-gate-suites.txt
.specrew/verification-plan.json
extensions/specrew-speckit/scripts/shared-governance.ps1
extensions/specrew-speckit/scripts/validate-governance.ps1
package.json
scripts/init/squad-deploy.ps1
scripts/internal/instruction-file-merge.ps1
scripts/internal/invoke-module-release.ps1
scripts/internal/session-recovery.ps1
scripts/internal/sync-boundary-state.ps1
scripts/specrew-start.ps1
specs/197-continuous-co-review/iterations/002/state.md
specs/197-continuous-co-review/iterations/007/state.md
specs/197-continuous-co-review/iterations/008/state.md
specs/198-beta2-hardening/iterations/005/state.md
specs/206-bug-bash/bug-list.md
specs/206-bug-bash/iterations/002/drift-log.md
specs/206-bug-bash/iterations/002/plan.md
specs/206-bug-bash/iterations/002/review-scope-round-2.md
specs/206-bug-bash/iterations/002/review-scope-round-3.md
specs/206-bug-bash/iterations/002/state.md
specs/206-bug-bash/iterations/002/tasks-progress.yml
specs/206-bug-bash/tasks.md
tests/integration/Test-LegacyStateReaders.Tests.ps1
tests/integration/_ctl-spec.ps1
tests/integration/distribution-module-publish.ps1
tests/integration/f049-i003-intake-engine-tests.ps1
tests/integration/project-path-resolution-regression.ps1
tests/manual/multi-host-smoke.ps1
tests/support/test-census.ps1
tests/unit/closed-check-since-and-ruling.tests.ps1
tests/unit/closeout-completed-and-open-rows.tests.ps1
tests/unit/closeout-dashboard-redraw.tests.ps1
tests/unit/deferred-task-verdict.tests.ps1
tests/unit/every-suite-is-named-by-a-lane.tests.ps1
tests/unit/instruction-classifier-managed-blocks.tests.ps1
tests/unit/iteration-closed-definition.tests.ps1
tests/unit/nightly-tracking-issue.tests.ps1
tests/unit/no-node-preset-for-this-repo.tests.ps1
tests/unit/record-before-approval.tests.ps1
tests/unit/release-script-refuses-unasked-publish.tests.ps1
tests/unit/resume-path-inside-project.tests.ps1
tests/unit/sc001-fixture-identity.tests.ps1
tests/unit/start-written-files-record.tests.ps1
```
