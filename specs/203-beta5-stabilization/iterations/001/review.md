# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-11-14
**Overall Verdict**: blocked: T001 to T013 pass; T014 (pin advance) is scheduled after sign-off by plan and is blocked on it; the verdict is corrected when T014 is done

This record covers review rounds A to D and their fixes. It was committed before round E, because on this engine a
records commit made after the stop cannot be signed off (DRIFT-078). Round E runs on this exact tree. Its result is
recorded after the review sign-off, in the drift log and in the round E section below, before any other commit.

"Blocked" here is not a failed review: every task the review covers passes. T014 is the pin advance, which the plan
puts after the review sign-off, so it cannot pass before it.

## Independent review

Campaign `cmp-203-beta5-stabilization-i001`, reviewer Codex, code writer Claude. The maintainer ruled four unnarrowed
rounds, one focus file each through `--design-context-ref` (DRIFT-070), each started by their own typed
`approved for review round` and launched from the pinned engine (`a56ac787`). Home hook files were hashed before and
after every round: 0 changed.

| Round | Run | Focus | Findings | Outcome |
| --- | --- | --- | --- | --- |
| A | `run-20261113-102531165-8671e9be` | Authority and capture code | 3 major (4 defects) | All fixed, each test first (DRIFT-070) |
| B | `run-20261113-172304585-393b6102` | The review engine | 4 major | All fixed, each test first (DRIFT-071) |
| C | `run-20261113-230313149-5c350d9c` | Extension scripts, dispatcher and hosts | 3 major | All fixed, each test first (DRIFT-072) |
| D | `run-20261114-172156973-8e5f3fa1` | The whole tree with the tests | 3 major | All fixed, each test first (DRIFT-076) |

That is 13 major findings, 14 defects, each checked against the code and fixed behind a test committed red first. The
maintainer's batch after round D also fixed `hook-command-length.tests.ps1`, which could start the dispatcher of the
checkout it ran in (DRIFT-072, DRIFT-076). The full sweep of that batch (`671b2dfc`) then found two defects in the
batch's own test code, both fixed behind a guard case committed red first: `hook-command-length`'s checkout check failed
on a clean checkout, and case 12's fixture made run-suites read the sweep-driver self-test as an empty Pester suite
(DRIFT-080). Round E's first launch then failed in its preflight on two more defects in the same test file, which
only the review target's layout shows: its checkout check threw on a tracked dangling link, and it put an absent `HOME`
back as an empty one. Both are fixed behind a guard committed red first (DRIFT-081). The four-round allowance is spent;
round E is the fifth and last round (DRIFT-076), and whatever it finds that does not block sign-off goes to iteration
002.

## Round E

Not yet run. Its run, findings and outcome are added here after the review sign-off.

## What This Sign-off Claims, and What It Does Not

- **It claims** every finding of rounds A to D is fixed, each behind a test that failed first; that the full sweep of
  `064a2ff4` (1,500 s suite limit, DRIFT-077) is green, with DRIFT-077's start-command allowance recorded in the drift
  log; and that the commits after it, which change only `hook-command-length.tests.ps1` and records, pass the checks
  the maintainer set in place of a second sweep: that suite in both layouts, all ten lanes in the review target's
  layout, and CI (DRIFT-081).
- **It does not claim** the live hooks run the reviewed code. They still run the pinned engine `a56ac787`, which has
  no sender check (DRIFT-072) and whose stop cites a standing grant instead of the typed answer (DRIFT-075). Both
  change at T014.
- **It does not claim** the hook cost is fixed: about 19 s per turn (DRIFT-073), placed by the maintainer.
- **It does not claim** a records commit after a human-accepted stop can be signed off (DRIFT-078, placement pending).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-016, FR-017, FR-027 | pass | Host facts recorded as fixtures; their suites in the sign-off lanes pass. |
| T002 | FR-014 | pass | The live engine pin; reviewed and signed off on its own before the iteration review (state.md). |
| T003 | FR-014, FR-015, FR-018, FR-020, FR-023 | pass | `typed-act-classifier`, `typed-turn-identity`. |
| T004 | FR-021, FR-022, FR-025 | pass | `typed-act-writer`. |
| T005 | FR-019, FR-020 | pass | `verdict-pairing`. |
| T006 | FR-026, FR-027 | pass | `not-recorded-report`; round D finding 2 fixed. |
| T007 | FR-001, FR-002, FR-003, FR-008 | pass | `review-budget-snapshot`. |
| T008 | FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011 | pass | `review-budget-loop`, `review-loop-stops`, `review-stop-answers`; round B's four findings fixed. |
| T011 | FR-046 | pass | `turn-end-after-stop-block`, `crossing-presentation`. |
| T012 | FR-024, FR-041 | pass | `authority-audit`; FR-041's turn identity in drift entries is iteration 002's. |
| T013 | FR-042, FR-043 | pass | `mint-path-fixtures` (435), `authorization-sender`, `authorization-consumers`; round D finding 1 fixed. |
| T014 | FR-045 | blocked | Scheduled after the review sign-off by plan and blocked on it; corrected when the pin advance and the Claude-only capture check are done. The same gap as feature 206's bug list item 37 (a task the plan defers has no verdict value), here for a task scheduled after sign-off; hand-over to whoever fixes item 37. |

## Gap Ledger

No entries. The open items are follow-ups in the drift log: the hook cost (DRIFT-073), DRIFT-078, and the iteration
002 scope the plan names.

## Notes

- The review needed a fifth round because the review-end records could not follow the stop (DRIFT-078); the path was
  proved on scratch copies before any record was written (DRIFT-076).
