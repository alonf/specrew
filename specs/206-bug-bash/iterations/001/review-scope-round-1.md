# Review Scope: Feature 206, Iteration 001, Round 1

This file is for the reviewer: what changed, and what to attack first. It is passed with `--design-context-ref`, so
it comes first in the review frame. It adds to the spec and plan and does not replace them.

- **Feature:** 206 (bug bash). **Iteration:** 001.
- **Iteration baseline:** `52c9651cab6e84c6bcb362c11ebd20c882863255`. The branch base is `d3e33550` on main.
- **Reviewed head:** `aa13c5b5` or later (records only after that).
- `.specify/**` is excluded from the frozen tree. The `.specify` mirror copies of the validator are checked against
  their hash record by the `f206-deployed-hash-record` lane. Review the sources under `extensions/`.

## What Changed, by Task

| Task | Requirement | Code and tests (records under `specs/` left out) |
| --- | --- | --- |
| T001 | FR-001: with no console input, `specrew start` refuses in plain words and never loops | `scripts/internal/session-recovery.ps1` (`Get-SpecrewRecoveryRefusalMessage` :447, `Read-SpecrewRecoveryChoice` :456), `scripts/specrew-start.ps1`, `tests/unit/recovery-choice-no-console.tests.ps1` |
| T002 | FR-002: the over-claim dirty check uses one path separator | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/unit/overclaim-dirty-check-separator.tests.ps1`, `tests/integration/validator-hardening-iteration2.ps1` |
| T003 | FR-003: the change classifier strips matched `specrew-managed` blocks only (plus the T015 regression fix: a side missing at the baseline) | `scripts/internal/instruction-file-merge.ps1`, `scripts/specrew-start.ps1` (`Get-RestartTriggerFiles`), `tests/unit/instruction-classifier-managed-blocks.tests.ps1` |
| T006 | FR-008a: one definition of closed for the validator filter, the dashboard check and the renderer; closure-claim words, with negations ("not closed", "not yet closed", "to be closed after review", "blocked") not counting | `extensions/specrew-speckit/scripts/shared-governance.ps1` (`Test-SpecrewIterationClosed` :884, `Test-SpecrewClosureClaimStatus` :929), `validate-governance.ps1`, `scripts/internal/dashboard-renderer.ps1`, `tests/unit/iteration-closed-definition.tests.ps1`, `tests/integration/closed-iterations-are-history.tests.ps1` |
| T007 | FR-005, FR-006: the frozen legacy list | `.specrew/legacy-frozen.yml` (18 entries) |
| T008 | FR-007: a frozen legacy iteration is judged by no check, in every mode; an abandoned iteration owes no dashboard | `shared-governance.ps1` (`Get-SpecrewLegacyFrozenIterationKeys` :766), `validate-governance.ps1`, `tests/unit/legacy-frozen-judged-by-nothing.tests.ps1` |
| T009 | FR-008: the closed-iteration dashboard check applies since 2026-05-26 to iterations closeout stamped; abandoned by recorded ruling is exempt from the plan-status and review-verdict rules | `shared-governance.ps1` (`Test-SpecrewIterationRulingRecorded` :807, `Test-SpecrewIterationAbandonedByRuling` :838, `Test-SpecrewClosedCheckApplies` :848), `validate-governance.ps1`, `tests/unit/closed-check-since-and-ruling.tests.ps1`, `tests/integration/non-specrew-session-bypass.tests.ps1` |
| T011 | FR-010: the review-verdict finding names the iteration's actual status | `validate-governance.ps1`, `tests/unit/review-verdict-names-status.tests.ps1` |
| T012 | FR-009: the nightly keeps one tracking issue from the validator's findings file; only the notify job can write issues, on the default branch only | `.github/scripts/nightly-tracking-issue.ps1` (`Format-IssueBody` :121), `.github/workflows/specrew-nightly-truth-check.yml`, `validate-governance.ps1` (`-FindingsJsonPath`), `tests/unit/nightly-tracking-issue.tests.ps1` |
| T013 | FR-011: one shared test census for the lane guard and the release full sweep | `tests/support/test-census.ps1`, `tests/full-powershell-test-sweep.ps1` (`-ListOnly`), `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, `tests/unit/full-sweep-direct-exit.tests.ps1` |
| T015 | FR-012: every held script registered or excluded with a reason; the held list empty | `.github/workflows/specrew-ci.yml` (per-push step), `.specrew/release-gate-suites.txt`, `tests/support/test-census.ps1`, the profile override in eight start-path scripts, `mechanical-findings-contract.ps1`'s `Test-Json` helper, `project-path-resolution-regression.ps1`'s refusal |

## What to Attack First

1. **The closure rule judging an iteration closed or open wrongly.** Look at `Test-SpecrewIterationClosed` and
   `Test-SpecrewClosureClaimStatus`, and try to defeat the negation handling: a closure word inside a negated or
   conditional sentence, odd casing or punctuation, a status line that both claims and denies. Then the
   abandoned-by-ruling exemption (`Test-SpecrewIterationAbandonedByRuling`): an "abandoned" status with no recorded
   ruling, a Disposition section that names no maintainer or no date, or a ruling in the wrong section.
2. **A finding emitted for a frozen legacy iteration.** Any check, in any mode (full repository, `-IncludeClosed`,
   changed-only, explicit targets), that still judges an entry of `.specrew/legacy-frozen.yml`. Include the dashboard
   check's `since` and closure-stamp path (`Test-SpecrewClosedCheckApplies`).
3. **The nightly notifier acting where it must not.** Look at `.github/scripts/nightly-tracking-issue.ps1` and the
   notify job's `if:`. A run on a non-default branch that opens, comments on or closes the issue; a path, user name or
   machine name leaking into an issue body; any job other than notify holding `issues: write`.
4. **`specrew start` with no console doing anything other than the plain refusal.** In `Read-SpecrewRecoveryChoice`,
   look for a loop, a wait, a silent default choice, or a refusal that does not exit non-zero, when stdin is redirected
   or empty.
5. **A test that exists and is named by no lane.** Look at `tests/support/test-census.ps1` and the lane guard: a file
   pattern the census misses, an exclusion that hides a real test, a held entry that should not be, or a lane-naming
   source the guard reads wrongly (a comment, a `\` path, a registry no CI step runs).
