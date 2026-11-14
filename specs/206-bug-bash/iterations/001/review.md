# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-11-14
**Overall Verdict**: accepted: four rounds (round 1 partial). Rounds 2 and 3 found twelve, all fixed failing-test first.
Round 4's five minor findings were carried to iteration 002 when the maintainer typed `stop the review here`. The final
check ran on `bb0cc72e`.

## Independent review

Campaign `cmp-206-bug-bash-i001`, reviewer Codex, code writer Claude. Each round was started by the maintainer's own
typed `approved for review round`. Rounds 3 and 4 read a scope file passed with `--design-context-ref`
(`review-scope-round-3.md`, `review-scope-round-4.md`). The round 1 scope (`review-scope-round-1.md`) describes the
whole iteration.

| Round | Run | Head | Findings | Outcome |
| --- | --- | --- | --- | --- |
| 1 | `run-20261113-125749559-798d2302` | `7f346037` | 6 minor, partial | Cut by the 600 s deadline: the preflight used 515 s. The engine counted the round as used. Round 2 re-read the same head with 1800 s |
| 2 | `run-20261113-133711531-d5ed060a` | `7f346037` | 6 (5 demoted from major by the engine) | All six fixed (DRIFT-206-I001-021) |
| (none) | `run-20261113-192634642-269e543e` | `6fedc44c` (tree) | none published | Preflight failed on `f206-unit-suites` (DRIFT-206-I001-023). Not a round |
| 3 | `run-20261113-210415408-06f009c3` | `c91766df` | 6 (4 demoted from major) | All six fixed (DRIFT-206-I001-024) |
| 4 | `run-20261114-132511846-d1b4bd05` | `bb0cc72e` | 5 minor | Carried to iteration 002 (DRIFT-206-I001-025) |

Round 2's six fixes, each a test commit with its red count and then a fix commit:

- FR-003: a copilot-instructions.md holding only the managed block stripped to empty, and the classifier refused it.
  RED `f1cdd95e` 3/13, GREEN `0c3968ee`.
- FR-008a: "cannot be closed" and "isn't closed" read as closure claims. RED `e2e89489` 2/18, GREEN `e1f5fbbe`.
- FR-008: a dated mention of a pending, refused or unrelated ruling counted as a recorded abandonment. RED `3230963e`
  5/28, GREEN `ce4f723a`.
- FR-009: a changed failure in the same category left the nightly fingerprint unchanged. RED `d5738276` 4/19, GREEN
  `d3839db1`.
- FR-008: `-RebuildClosedIndex` overwrote closeout times and dropped stamps. RED `cd19f6e3` 3/33, GREEN `95dca9e5`.
- FR-011: the lane guard counted a path in a comment, step name, `paths:` filter or `env:` value. RED `a0a9b938` 4/69,
  GREEN `9cf0c4f6`.

Round 3's six fixes:

- FR-008: "Abandonment was rejected by the maintainer's decision of ..." counted as a ruling. RED `760b7f02` 5/42,
  GREEN `dba4ea9c`.
- FR-008a: "may be closed" and "can be closed" read as closure claims. RED `d82299be` 2/20, GREEN `e50a2650`.
- FR-008a: the rebuild selected new entries by the old text heuristic. RED `c23d858c` 2/44, GREEN `90b0543a`.
- FR-009: a repository-level stop wrote one category record with no message hash. RED `d99f6065` 2/21, GREEN
  `7fc81397`.
- FR-011: a `run:` key under `with:` or `env:` counted as a registration. RED `9bd570a1` 2/74, GREEN `a50d127a`.
- FR-011: a multi-line block comment left its suite counted. RED `924d14bb` 1/76, GREEN `45a8070c`.

By the maintainer's ruling of 2026-11-14, findings 1 and 2 of round 3 replaced the negative-word lists with
affirmative forms. Before building, the forms ran against all 161 iterations: no closed, open or ruled result changed.

## How the Review Stopped

- Round 4 used the last of the four rounds. Before it, all five lanes passed in the preflight layout (571 s of the
  round's 1800 s), and all three workflows were green on `bb0cc72e`.
- Round 4 returned five minor findings, none blocking. The maintainer had ruled beforehand that whatever round 4
  found that was not a blocker goes to iteration 002.
- The maintainer typed `stop the review here`. The final check ran on the tree exactly as it was, and sign-off
  completed: disposition `disposition-d51b40f30aa70338571e` (`accept-current`, target `592d8cb5`). The gate record is
  `.specrew/review/signoff-gate/latest.json` (reason `complete-current-findings-human-accepted`).
- The home hook files hashed the same before and after round 4 and after the stop.

## What This Sign-off Claims, and What It Does Not

- **It claims** every finding from rounds 2 and 3 is fixed behind a test that failed first, and round 4 read those
  fixes.
- **It claims** the five review lanes pass on `bb0cc72e` in the preflight layout, and all three workflows passed on it.
- **It does not claim** round 4's five findings are fixed. They are iteration 002's.
- **It does not claim** SC-001 or SC-002 is met, or T003's remainder, T016 (FR-013) or T017 (FR-014). They are
  iteration 002's, as the task table records.
- **It does not claim** round 1's partial findings were each answered. Three came back in round 2 and are fixed. The
  other three are in the gap ledger.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | No-console refusal and three-try cap; RED 5/7 `56f452f3`, GREEN 7/7 `837b4f09`. |
| T002 | FR-002 | pass | One path separator; green on Windows and in the per-push Ubuntu step. |
| T003 | FR-003 | deferred | The classifier fix and round 2's finding 1 are in; the remainder is SC-002, iteration 002. |
| T004 | FR-004 | pass | `handover-to-203.md`, closed at T018. |
| T005 | FR-008a | pass | `closed-open-table.md`, 161 iterations, rulings recorded. |
| T006 | FR-008a | pass | One definition of closed; affirmative forms since round 3. |
| T007 | FR-005, FR-006 | pass | 197/006, 198/010, 198/011 abandoned by ruling; 18 frozen entries. |
| T008 | FR-007 | pass | Frozen judged by no check in any mode. |
| T009 | FR-008 | pass | `since` and the closure stamp; abandoned-by-ruling exemption. |
| T010 | FR-008a, FR-006 | pass | CI-mode full run on `9de20285`: no new finding. |
| T011 | FR-010 | pass | The review-verdict finding names the actual status. |
| T012 | FR-009 | pass | Notifier and findings file; round 4's findings 4 and 5 are for iteration 002. |
| T013 | FR-011 | pass | Shared test census and lane guard; round 4's findings 1 and 2 are for iteration 002. |
| T014 | FR-012 | pass | 36 held scripts read; report `t014-held-scripts.md`. |
| T015 | FR-012 | pass | Registered per the rulings; SC-001 and SC-002 not met here (iteration 002). |
| T018 | SC-007 | pass | Acceptance checks; `t018-acceptance.md`. |

## Gap Ledger

Every entry is deferred to iteration 002, by the maintainer's ruling for round 4 (2026-11-14) and by the task table for
the rest. Its classification is the maintainer's at the closeout.

- **Round 4, finding 1** (`finding-175c2ab8a756a10e`, FR-011): `steps:` inside a YAML block scalar is read as steps.
- **Round 4, finding 2** (`finding-2f7f4713967f972f`, FR-011): a comment right after `;` still counts as a registration.
- **Round 4, finding 3** (`finding-5cfaa2b2f67ea55b`, FR-003): a malformed `>>> ... <<<` opener is treated as a
  balanced managed block.
- **Round 4, finding 4** (`finding-42d18d3781d59c95`, FR-009): an unexpected validator exception writes no message
  hash; beside bug list item 30's four stops.
- **Round 4, finding 5** (`finding-d249cc05e6ee6910`, FR-009): overlapping notifier runs can open two tracking issues;
  the workflow has no `concurrency:` group.
- **Round 1, three partial findings not raised again**: plan.md's note that unruled `abandoned` is not closed
  contradicts the code (`finding-075e938b2db1e279`); the T003 and T015 rows claim more than the census shows
  (`finding-ac49cb6709990d38`); the notifier adopts any open issue with its label.
- **SC-001, SC-002, T003's remainder, T016, T017**, bug list items 12 and 15 to 30, and DRIFT-206-I001-010
  (required before feature 206 closes).

## Independence

This record carries no derived independence block. The block is computed from the review store, which exists only on
the machine that ran the review, so the local check and CI derive different text (feature 205's DRIFT-012). The
maintainer approved leaving it out. In plain words, this record's independence rests on:

- **The Codex rounds, for the heads they read.** Round 2 read `7f346037`, round 3 `c91766df`, round 4 `bb0cc72e`.
  Round 1 was partial.
- **The maintainer's stop on the round 4 result.** The final check confirmed the tree was the one round 4 read.
- **Not on the record itself.** The implementing session (Claude, the code writer) wrote this record, so it adds no
  independence of its own.
