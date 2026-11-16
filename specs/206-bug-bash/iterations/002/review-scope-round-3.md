# Review Scope: Feature 206, Iteration 002, Round 3

This file is for the reviewer: what this round covers, and in what order. It is passed with `--design-context-ref`, so
it comes first in the review frame. It adds to the spec, the plan, the design analysis and the round 1 and round 2
scope files (`review-scope-round-1.md`, `review-scope-round-2.md`) and does not replace them.

- **Feature:** 206 (bug bash). **Iteration:** 002.
- **Round 1** reviewed Phase 5 at head `7c006d67` (run `run-20261115-233001030-c21b0c2f`, 10 findings, none blocking).
- **Round 2** (run `run-20261116-173258054-8f47fc5f`, head `3ee41574`) ended partial with nine findings, none blocking.
  It covered round 2's attack items 0 to 5 and did not reach the nine round 1 fixes, T030, T029, T017 or T016
  (DRIFT-206-I002-017).
- **This round:** everything since `7c006d67`, in the order below.
- **Mirrors:** `extensions/specrew-speckit/**` is the source. Each `.specify/extensions/specrew-speckit/**` change is a
  byte copy with its hash refreshed in `.specrew-extension-runtime.json`, which lane `f206-deployed-hash-record` checks.
- **Not in scope:** `scripts/internal/continuous-co-review/**`, the capture stores under `scripts/internal/bootstrap/`
  and `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` are feature 203's and were not changed.

## How to Spend the Time

You have the full window: the deadline you are given is counted from your start, not from the round's request, and
the verification that ran before you does not use it. You cannot read a clock, so do not stop for time on a guess.
Cover every section below, in order, before you publish a partial candidate. If you must stop early, say which
sections you covered.

**State a concrete failure scenario for every blocking or major finding, and include the literal clause 'Failure
scenario:' in its description.** Without it, the engine on this branch stores the finding as minor (bug list item
61).

## Maintainer Answers This Round Rests On

1. 2026-11-16 11:34 local, "OK for all" (relayed): 197/002, 197/007, 197/008 and 198/005 are abandoned by ruling
   (T026); the publish suite runs per push (T028); SC-001's script runs per push (T024).
2. 2026-11-16 14:38 local, "206 publish: A" (relayed): the publish suite runs in its own Windows job.
3. 2026-11-16 20:56 local, "OK for both" (relayed): fix round 2's six findings (F1 to F6) before round 3. F7, F8, F9
   and the engine items go to the bug list.

## Section 1: What Round 2 Did Not Reach

Review these first.

### 1a. The nine round 1 fixes, commit by commit

Each fix has a failing test first and one finding per commit (DRIFT-206-I002-010). Read each against its round 1
finding:

- F1 `409df238`
- F2 `541708af`
- F3 `1553dbdc`
- F4 `79c3c224`
- F5 `0245115a`
- F6 `5bbaec3b`
- F7 `55d42b72`
- F9 `f87330bd`
- F10 `32244053`

F8 was noted and not changed.

### 1b. T030, T029, T017, T016

| Task | Item | Change | Test |
| --- | --- | --- | --- |
| T030 | 30, 34 | every repository-level stop of the nightly check passes its message, so two messages give two fingerprints | `tests/unit/nightly-tracking-issue.tests.ps1` |
| T029 | 18 | `multi-host-smoke.ps1`'s loop variable no longer assigns to `$Host` (read and parsed, not run: it deploys hooks) | parse only |
| T017 | 6a | the stray root `package.json` removed; f049's stack assertion reads a fixture with its own | `tests/unit/no-node-preset-for-this-repo.tests.ps1` |
| T016 | — | the empty `tests/integration/_ctl-spec.ps1` deleted with its census exclusion | the census guard |

## Section 2: Round 2's Six Fixes

Each has its RED commit, then one fix commit, in round 2's result order (DRIFT-206-I002-017):

| Round 2 finding | RED | Fix | What changed |
| --- | --- | --- | --- |
| F1 `finding-30faa1624cf6d7a1` | `6cc4da16` 1/46 | `c1ed64c7` | `-RebuildClosedIndex` leaves an abandoned iteration without a recorded ruling out of the index |
| F2 `finding-124f7de3f876daab` | `e66e3191` 2/87 | `b2e0b890` | the census guard counts a conditioned step or job only when its condition runs; the two suites that never ran move to the `windows-shim-suites` job; per push means a workflow a push runs |
| F3 `finding-8440e050721c87ad` | `982ffe9f` 6/53 | `e22084ca` | the ruling matcher reads the Disposition as Markdown (fences, comments, any heading ends it), takes only an "(at ...)" note with no denying word, and refuses a date later than tomorrow |
| F4 `finding-4b72620596668b79` | `f37ba01d` 1/28 | `a56476d6` | the identity reader holds a relative path to the inside check |
| F5 `finding-e2ef0515b3bc7a8f` | `e31a5fd3` 4/12 | `d1e428b9` | T034: pending only under the approval right before the record's boundary; with no session iteration, only the newest iteration |
| F6 `finding-6b34e25ddeb81569` | `50f97212` 6/10 | `cca9cb65` | a deferred row must match a deferred plan task, name a decision the clause before it does not deny or condition, and find it in the ledger outside comments and fences |

What to attack:

- **F3 and F6 are text-matching rules.** Try a phrasing that matches the pattern but denies or conditions it, beyond
  the ones the tests list. F3's denying-word list applies only to an "(at ...)" note; F6's applies to the clause
  before the decision id. Is either list too narrow, or too wide (a legitimate record refused)?
- **F2 reads workflow structure.** Try each YAML construct that can hide or fake a condition: an `if:` written as a
  block scalar or with `${{ }}`, a condition on the step's list item line, a job `if:` after its `steps:`, a matrix
  `runs-on` whose legs all exclude the condition, and `||`. Is the declared list of conditions that run right?
- **F2's two suites** (`tests/integration/bootstrap-asset-blocker-recovery.ps1`,
  `tests/integration/validate-versions-cli-behavior.ps1`) now run only in the `windows-shim-suites` job. They are not
  run on the developer machine: the first runs `specrew-init`, which writes the real home's hook files. Can the job
  pass without running them?
- **The job's first CI run was red** (DRIFT-206-I002-018): `specrew-init`'s dependency check refused the runner's
  Node 22, and the second suite was skipped behind it. Nothing was excluded. By the maintainer's "You can apply both"
  (2026-11-17), `f41ae713` (RED 2/12) and `e3a26586` (GREEN 12/12) add the Node 24 setup step and run the second suite
  with `if: always()`. Check that a failed first step still fails the job, and whether either suite needs anything
  else the runner lacks.
- **`00cef4d5`** is feature 203's `f2493ccc` (T015), cherry-picked with identical hunks: the Ubuntu "Setup
  PowerShell" steps in `cross-platform-validation.yml`. It is 203's change, reviewed there; here, check only that it
  is the same text.
- **F5** is the one feature 203 builds on. Check the boundary order it uses, a boundary at the start of the order, and
  an iteration folder whose name is not a number.
- **F1** keeps every existing index entry (append-only). An abandoned iteration indexed by an earlier rebuild stays
  closed regardless of its ruling. That is by design; say if it should not be.

## Section 3: The Rest of the Iteration, as in Round 2

Round 2's scope file lists the Phase 6 to 9 changes (T026, T032, T031, T027, T028, T034, T033, T035, T036, T037), the
registrations, and its attack items 0 to 5. Round 2 covered those; read them again only where a Section 2 fix touches
the same code: T026 (F1, F3), T031 (F2), T034 (F5), T033 (F6), and the path-kind helper (F4).

## Known and Deferred

- Bug list items 52 and 53 (round 2's scope file).
- Round 2's F7 (item 63, not reachable by reading), F8 (item 64, the validator's unparenthesised `-or`; fixing it would
  newly refuse eight hardening gates) and F9 (item 65).
- Items 58 to 62: the review engine's own misreports in round 2 (feature 203's engine).
- `specrew-start.ps1`'s `.specify/feature.json` auto path (about line 709) and the FR-024 stale check's `-like`, as
  in round 2.

**Two standing instructions from iteration 001's retro (T037):**

- **For any text-matching rule, try a phrasing that matches the pattern but denies or conditions it.**
- **For any test that reads workflow or script files, try each YAML and shell construct that can hide or fake a
  line:** comments, block scalars, keys of the same name at other levels, and statement delimiters.
