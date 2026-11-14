# Review Scope: Feature 206, Iteration 001, Round 3

This file is for the reviewer: what changed since round 2, and what to attack first. It is passed with
`--design-context-ref`, so it comes first in the review frame. It adds to the spec and plan and does not replace
them. The round 1 scope (`review-scope-round-1.md`, beside this file) still describes the whole iteration.

- **Feature:** 206 (bug bash). **Iteration:** 001.
- **Iteration baseline:** `52c9651cab6e84c6bcb362c11ebd20c882863255`. The branch base is `d3e33550` on main.
- **Round 2:** Codex, head `7f346037`, six findings. **Reviewed head for round 3:** `c91766df`.
- `.specify/**` is excluded from the frozen tree. The `.specify` mirror copies are checked against their hash
  record by the `f206-deployed-hash-record` lane. Review the sources under `extensions/`.

## What Changed Since Round 2

Each finding was reproduced by a failing test first, then fixed. The fixes are in `7f346037..c91766df`.

| # | Requirement | Round 2 finding | Fix | Test |
| --- | --- | --- | --- | --- |
| 1 | FR-003 | A copilot-instructions.md holding only the managed block strips to empty; the classifier refused an empty side | `Test-CopilotInstructionsChangeType`'s content parameters allow an empty string; `Get-RestartTriggerFiles` (`scripts/specrew-start.ps1`) always classifies the stripped pair | `tests/unit/instruction-classifier-managed-blocks.tests.ps1` |
| 2 | FR-008a | "cannot be closed" and "isn't closed" read as closure claims | `Test-SpecrewClosureClaimStatus` (`shared-governance.ps1`) also treats "cannot", any n't contraction, "unable" and "no longer" before the closure word as negation | `tests/unit/iteration-closed-definition.tests.ps1` |
| 3 | FR-008 | A dated mention of a pending or unrelated ruling counted as a recorded abandonment | `Test-SpecrewIterationRulingRecorded` needs one affirmative Disposition sentence naming the abandonment, the maintainer's ruling or decision, and its date; the heading is not read | `tests/unit/closed-check-since-and-ruling.tests.ps1` |
| 4 | FR-009 | Distinct categorized failures shared one nightly fingerprint | `Add-ValidatorFindingRecord` (`validate-governance.ps1`) writes a hash of every normalized message (never the text); the notifier's fingerprint and table include it | `tests/unit/nightly-tracking-issue.tests.ps1` |
| 5 | FR-008 | `-RebuildClosedIndex` dropped closeout stamps and closure times | The rebuild reads the index under its lock and keeps every `closed_at_source: closeout` entry with its `closed_at`, also when the state.md walk misses it | `tests/unit/closed-check-since-and-ruling.tests.ps1` |
| 6 | FR-011 | The lane guard counted a test path in a workflow comment or step name | `Get-WorkflowRunText` (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) reads only `run:` text, shell comments removed | the same file's fixture |

Also:

- The fixes' comments in the deployed surface state the rule without Specrew's history (self-leak lint).
- T002's suite (`tests/unit/overclaim-dirty-check-separator.tests.ps1`) copied the whole `.specrew`, `.squad` and
  `.github` folders into its fixture, so the git-ignored local review store reached it and its result depended on
  the machine (bug list item 29). It now copies every file git does not ignore, tracked or untracked: a tracked-only
  copy found nothing in a review preflight's verification copy, where `.specrew` and `.squad` are untracked (round 3's
  first launch stopped there; DRIFT-023). The suite's own test builds that layout.

## What to Attack First

1. **The six fixes themselves.** Try to defeat each one with the next case along:
   - an empty side reaching the classifier by another route;
   - a negation the list still misses, or a real closure claim now read as open;
   - an affirmative-looking Disposition sentence that does not record the abandonment, or a real ruling the
     sentence rule now rejects (174/007, 197/006, 198/010 and 198/011 must still read as recorded);
   - a message hash that varies with the machine or the checkout folder, or any message text reaching the issue;
   - a rebuild that loses or invents a stamp, or writes a duplicate entry;
   - a workflow form the run-text reader mis-scopes (`run:` inside a `with:` map, folded blocks, a quoted
     `#`, `<# #>` blocks).
2. **The closure rule and the abandoned-by-ruling exemption**, as in round 1's scope.
3. **A finding emitted for a frozen legacy iteration**, in any validator mode.
4. **The nightly notifier acting where it must not**: a non-default branch, a private value in an issue body, a job
   other than notify with `issues: write`.
5. **A test that exists and is named by no lane**: the census, its exclusions and the guard's readers.
