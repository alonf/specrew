# Review Scope: Feature 206, Iteration 001, Round 4

This file is for the reviewer: what changed since round 3, and what to attack first. It is passed with
`--design-context-ref`, so it comes first in the review frame. It adds to the spec and plan and does not replace
them. The round 1 scope (`review-scope-round-1.md`, beside this file) still describes the whole iteration.

- **Feature:** 206 (bug bash). **Iteration:** 001.
- **Iteration baseline:** `52c9651cab6e84c6bcb362c11ebd20c882863255`. The branch base is `d3e33550` on main.
- **Round 3:** Codex, head `c91766df`, six findings. **Reviewed head for round 4:** `bb0cc72e` (the fixes end at `995851d2`; `bb0cc72e` adds records only).
- **This is the last round in the budget.** What it finds that is not a blocker goes to iteration 002 (maintainer,
  2026-11-14).
- `.specify/**` is excluded from the frozen tree. The `.specify` mirror copies are checked against their hash
  record by the `f206-deployed-hash-record` lane. Review the sources under `extensions/`.

## What Changed Since Round 3

Each finding was reproduced by a failing test first, then fixed. The fixes are in `c91766df..995851d2`.

| # | Requirement | Round 3 finding | Fix | Test |
| --- | --- | --- | --- | --- |
| 1 | FR-008 | "Abandonment was rejected by the maintainer's decision of 2026-11-12" counted as a recorded ruling | `Test-SpecrewIterationRulingRecorded` (`shared-governance.ps1`) accepts only affirmative forms: a Disposition sentence that starts with the abandonment and ends with the maintainer's dated ruling or decision | `tests/unit/closed-check-since-and-ruling.tests.ps1` |
| 2 | FR-008a | "may be closed" and "can be closed" read as closure claims | `Test-SpecrewClosureClaimStatus` accepts only affirmative forms: a clause that is the claim word, or "iteration [NNN] [is/was/has been] [formally]" and the claim word, followed only by via, by, on, at, after or with | `tests/unit/iteration-closed-definition.tests.ps1` |
| 3 | FR-008a | `-RebuildClosedIndex` selected new entries by the old state.md text heuristic | The rebuild (`validate-governance.ps1`) selects new entries by the canonical definition's state.md criteria, never a frozen entry, and keeps every existing entry as it is | `tests/unit/closed-check-since-and-ruling.tests.ps1`, `tests/integration/closed-iteration-index.tests.ps1` |
| 4 | FR-009 | A repository-level stop wrote one category record with no message hash | `Write-ValidatorSummaryAndExit -FailureMessages`: the seal, Squad team and classifier stops write each error as a hash under their rule | `tests/unit/nightly-tracking-issue.tests.ps1` |
| 5 | FR-011 | A `run:` key under `with:` or `env:` counted as a registration | `Get-WorkflowRunText` (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) reads only a step's own `run:` key | the same file's fixture |
| 6 | FR-011 | A multi-line `<# #>` block comment left its suite counted | `Remove-ShellComment` reads a `run:` value's lines in one pass, block comments before line comments | the same file's fixture |

Also:

- **The affirmative forms replace the negative-word lists** (maintainer ruling 2026-11-14, replacing the earlier
  ruling on T006). Before building, both rules ran against all 161 iterations in the repository: no iteration's
  closed, open or ruled result changed (32 statuses claim closure before and after; the same four iterations record a
  ruling: 174/007, 197/006, 198/010, 198/011).
- **The rebuild never removes an entry.** On a copy of this repository's state files and index it adds the seven
  iterations already closed by status and changes no iteration's closed result.
- **Known and deferred:** four repository-level stops that return only a count (`source-without-implement-authorization`,
  `handoff-evidence`, `approved-status`, `boundary-canonical`) still write their category alone (bug list item 30,
  iteration 002).

## What to Attack First

1. **The six fixes themselves.** Try to defeat each one with the next case along:
   - an affirmative-looking Disposition sentence or status clause that does not record the abandonment or the
     closure, or a real ruling or closure in this repository that the forms now reject;
   - a rebuild that writes a duplicate entry, loses a stamp, or indexes a frozen or open iteration;
   - a message from a repository-level stop that reaches the findings file as text, or a hash that varies with the
     machine or checkout folder;
   - a workflow form the step reader mis-scopes (indentless `steps:` lists, a `-` alone on its line, nested jobs),
     or a comment form the scanner mis-reads.
2. **The closure rule and the abandoned-by-ruling exemption**, as in round 1's scope.
3. **A finding emitted for a frozen legacy iteration**, in any validator mode.
4. **The nightly notifier acting where it must not**: a non-default branch, a private value in an issue body, a job
   other than notify with `issues: write`.
5. **A test that exists and is named by no lane**: the census, its exclusions and the guard's readers.
