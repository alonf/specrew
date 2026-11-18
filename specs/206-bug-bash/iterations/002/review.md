# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-11-17
**Overall Verdict**: accepted: four rounds (rounds 2 and 3 partial). Round 1's nine fixes, round 2's six and round 3's four were fixed failing-test first. Round 4 read the whole iteration and returned four findings (one major); the maintainer typed `stop the review here`, and they are carried as bug list items 86 to 89. The final check ran on `33cffa14`.

## Independent review

Campaign `cmp-206-bug-bash-i002`, code writer Claude. Rounds 1 to 3 ran on the Claude reviewer host, round 4 on Codex.
Each round was started by the maintainer's own typed round approval. Every round read a scope file passed with
`--design-context-ref` (`review-scope-round-1.md` to `review-scope-round-4.md`).

| Round | Run | Reviewer | Head | Findings | Outcome |
| --- | --- | --- | --- | --- | --- |
| 1 | `run-20261115-233001030-c21b0c2f` | Claude | `7c006d67` | 10 (7 minor, 3 notes) | Nine fixed, F8 noted (DRIFT-206-I002-010) |
| 2 | `run-20261116-173258054-8f47fc5f` | Claude | `3ee41574` | 9, partial | Six fixed (F1 to F6); F7 to F9 to the bug list, items 63 to 65 (DRIFT-206-I002-017) |
| 3 | `run-20261117-082153391-a5841b35` | Claude | `ff6fe55e` | 12 (1 major), partial | Four fixed, the major first; the other eight to the bug list, items 75 to 82, with item 74 (DRIFT-206-I002-019) |
| 4 | `run-20261117-175417271-a471ffb6` | Codex | `33cffa14` | 4 (1 major), complete | Carried to the bug list, items 86 to 89, when the maintainer stopped the review (DRIFT-206-I002-021) |

- **Round 1's nine fixes**, each RED first: F1 `409df238`, F2 `541708af`, F3 `1553dbdc`, F4 `79c3c224`, F5 `0245115a`,
  F6 `5bbaec3b`, F7 `55d42b72`, F9 `f87330bd`, F10 `32244053`.
- **Round 2's six fixes**, RED then GREEN: F1 `6cc4da16`/`c1ed64c7`, F2 `e66e3191`/`b2e0b890`, F3
  `982ffe9f`/`e22084ca`, F4 `f37ba01d`/`a56476d6`, F5 `e31a5fd3`/`d1e428b9`, F6 `50f97212`/`cca9cb65`. F2's first CI
  run added `f41ae713`/`e3a26586` (Node 24 for the shim job) and the cherry-pick `00cef4d5` of feature 203's Ubuntu
  PowerShell fix (DRIFT-206-I002-018).
- **Round 3's four fixes**, RED then GREEN: `finding-f194651984ecf15e` (major) `2eeba428`/`54c70599`,
  `finding-877eda7300798107` `16fcff2c`/`46b74cb7`, `finding-a9d93413b59ece33` `70cb1571`/`6cefbbe4`,
  `finding-c79fd0045cfa0bb1` `6860bfef`/`1b793a5c`.
- **Rounds 2 and 3 were partial.** Neither reached the nine round 1 fixes: the Claude reviewer host has no shell and no
  clock, and both stopped after about five minutes of a 2400 s window (bug list items 62 and 59). Round 4's scope file
  gave each fix by file and function and the commit list; Codex read all of it and checked the list against git.

## How the Review Stopped

- Round 4 used the last of the four rounds. Before it, all six lanes passed in the review layout on `266bb3af` (1025 s),
  all three workflows were green on `266bb3af` and on the records push `33cffa14`, and the home hook files hashed the
  same before and after.
- Round 3's unspent approval had to be withdrawn first: the maintainer typed the withdrawal (17:46:15Z), then the round
  approval (17:53:35Z), each captured by field before the next step.
- Round 4 returned four findings (one major), none blocking, with every section of the scope covered.
- The maintainer typed `stop the review here`. The final check ran on the tree exactly as round 4 read it and sign-off
  completed: the gate record `.specrew/review/signoff-gate/latest.json` (reason
  `complete-current-findings-human-accepted`, run `run-20261117-175417271-a471ffb6`, recorded 19:02:30Z).
- The home hook files hashed the same before and after round 4 and after the stop. Codex wrote only in its own folder
  in the home (147 entries, all inside the round's window).

## What This Sign-off Claims, and What It Does Not

- **It claims** every fix from rounds 1 to 3 that the maintainer chose to make is behind a test that failed first, and
  round 4 read every one of them.
- **It claims** the six review lanes pass on `266bb3af` in the review layout, and all three workflows passed on
  `266bb3af` and `33cffa14`; `windows-shim-suites` ran both shim suites green.
- **It does not claim** round 4's four findings, round 3's other eight, or round 2's F7 to F9 are fixed. They are bug
  list items, candidates for the next bug bash; round 4's major (item 86) is marked first.
- **It does not claim** items 15, 16, 19, 20, 28 and 35, cut from this iteration by the maintainer, or items 36, 38,
  40, 42 and 43.
- **It does not claim** the text rules are complete. Round 3's word-list findings and round 4's ledger finding are one
  class; item 74 asks whether a structured line should replace the word lists.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T016 | FR-013 | pass | The empty `_ctl-spec.ps1` deleted with its census exclusion. |
| T017 | FR-014, SC-006 | pass | The stray root `package.json` removed; the f049 assertion reads a fixture; the resolver selects no Node or React preset. |
| T020 | FR-003, SC-002 | pass | The start-written record; round 1's F1 and F5 fixes. |
| T021 | SC-002, FR-012 | pass | SC-002's script green in the preflight layout and registered. |
| T022 | FR-001, SC-001 | pass | A project with no session files starts; an unreadable one still refuses. |
| T023 | FR-001, SC-001 | pass | An outside resume path refused; the identity path relative; round 1's F3, F4 and round 2's F4 fixes. |
| T024 | SC-001, FR-012 | pass | SC-001's script green and registered per push; round 1's F2, F6 and F9 fixes. |
| T025 | SC-001, SC-007 | pass | `specrew init`'s Squad probe in a temp folder; a failed cleanup reported. |
| T026 | FR-008, FR-008a | pass | Abandoned is closed only with a recorded ruling; round 2's F1 and F3 and round 3's `a9d93413` fixes. |
| T027 | FR-012 | pass | `workflow_dispatch:` on Specrew CI. |
| T028 | FR-012, SC-007 | pass | The publish suite clears its key and runs in its own Windows job with no secret mapped. |
| T029 | FR-012 | pass | `multi-host-smoke.ps1` no longer assigns to `$Host` (read and parsed, not run). |
| T030 | FR-009 | pass | Every repository-level stop and the outer catch pass their messages; round 3's note on the shared list is item 82. |
| T031 | FR-011, SC-004 | pass | The census guard reads YAML by structure; round 2's F2 and round 3's `c79fd004` fixes; round 4's finding is item 89. |
| T032 | FR-003 | pass | A mismatched managed-block opener is unbalanced. |
| T033 | FR-015, SC-008 | pass | A `deferred` task verdict names its decision; round 2's F6 and round 3's `f194` and `877e` fixes; round 4's major is item 86. |
| T034 | FR-016, SC-009 | pass | A record before its verdict is a normal state; RED 4/7 `4128585a`, GREEN 7/7 `3a3ba803`; round 2's F5 fix. |
| T035 | FR-017, SC-010 | pass | The closeout dashboard is redrawn after the verdict, before the seal. |
| T036 | FR-018, SC-011 | pass | The Completed date written at capture; open hardening rows named at the arrival. |
| T037 | FR-003, FR-011 | pass | Iteration 001's two reviewer-brief instructions are in every round's scope file. |
| T038 | SC-009 | pass | This record, pushed before its verdict. |

## Gap Ledger

Every entry below is deferred to the next bug bash as a bug list item (`specs/206-bug-bash/bug-list.md`); the deferrals are registered with their approving human in `.squad\decisions.md` after the review-signoff verdict, as iteration 001's were.

- Round 4, `finding-ac98d5cbfc5b6a9c` (major, T033): deferred - bug list item 86, marked first; a decision id inside an indented code example or an unclosed fence counts as a ledger entry.
- Round 4, `finding-cb6118e2f0d33477` (T026): deferred - bug list item 87; the ruling reader removes HTML comments before it reads fences.
- Round 4, `finding-f61aaa3347213843` (T033): deferred - bug list item 88; two plan rows whose ids differ only in case make the deferral check depend on row order.
- Round 4, `finding-3bf4f809c27571cd` (T031): deferred - bug list item 89; a folded `run: >` block is read line by line.
- Round 3, the eight findings not fixed: deferred - bug list items 75 to 82, with the design question item 74 (the maintainer's "206 round 3: fix four", 2026-11-17).
- Round 2, F7 to F9: deferred - bug list items 63 to 65 (the maintainer's "OK for both", 2026-11-16).
- Round 1, F8 (`finding-f3ff23769aa554b0`, a note): deferred - SC-001's and SC-002's scripts run in CI and the release sweep, not among the review preflight's six commands.
- Items 15, 16, 19, 20, 28 and 35: deferred - cut from this iteration by the maintainer with Option B (2026-11-15).
- Items 36 and 38: deferred - later, by the plan; items 40, 42 and 43 deferred - feature 203's code, a hand-over or after its merge.

## Independence

This record carries no derived independence block. The block is computed from the review store, which exists only on
the machine that ran the review, so the local check and CI derive different text (feature 205's DRIFT-012). The
maintainer approved leaving it out. In plain words, this record's independence rests on:

- **The reviewer rounds, for the heads they read.** Round 1 read `7c006d67`, round 2 `3ee41574` (partial), round 3
  `ff6fe55e` (partial), round 4 `33cffa14` on Codex, a different vendor from the code writer.
- **The maintainer's stop on the round 4 result.** The final check confirmed the tree was the one round 4 read.
- **Not on the record itself.** The implementing session (Claude, the code writer) wrote this record, so it adds no
  independence of its own.
