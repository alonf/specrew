# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-11-15
**Overall Verdict**: accepted: T001 to T014 pass; the sign-off was a partial one (DRIFT-085), and round E's two major findings, which fail closed, are carried to iteration 002 with the items in the Gap Ledger

This record covers review rounds A to D and their fixes. It was committed before round E, because on this engine a
records commit made after the stop cannot be signed off (DRIFT-078). Round E ran on this exact tree. Its result was
added after the review sign-off, in the drift log and in the round E section below, before any other commit.

"Blocked" here is not a failed review: every task the review covers passes. T014 has two parts. The pin advance was
done before the sign-off, on the maintainer's decision (DRIFT-082), and the sign-off waited on it. The Claude-only
capture check runs on the advanced pin after the sign-off, so T014 cannot pass before it.

The sign-off is a partial one: the maintainer typed `approved for partial review signoff` for the records-only change
after round E (DRIFT-085), then `approved for review-signoff`.

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
| E | `run-20261115-042146354-0a33bd36` | The four fixes since round D, and the records | 2 major | Open, fail closed, to iteration 002 (DRIFT-083, DRIFT-084) |

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

Run `run-20261115-042146354-0a33bd36`, relaunched at 06:21 local on 2026-11-15 from the pin `a56ac787`, on the tree
`59abeef8`, using the maintainer's round-5 approval. Its first launch had failed in its preflight without using a round
(DRIFT-081). The preflight passed in 2,812 s and the run ended at 3,185 s: completion complete, currentness current,
verdict findings, 2 major, 0 blocking. Home hook files: 0 changed.

| ID | Location | Finding | Fail mode | Placement |
| --- | --- | --- | --- | --- |
| `finding-cf1fe81e0398f883` | `HumanAuthorityStore.ps1:2526` | Round D finding 1's fix is incomplete: inside the tail window the message-ID fallback can return a later message that reuses the same running prompt ID, and the loop stops before the whole-transcript read (DRIFT-083) | Closed: a valid approval is refused | Iteration 002, first batch |
| `finding-a537d3f72672e5f5` | `HumanAuthorityStore.ps1:2052` | Round D finding 2's fix is incomplete: the recovery path reports an unsaved turn only for approval shapes, so a review-stop answer gets no report (DRIFT-084) | Closed: nothing is saved and nothing is said | Iteration 002, first batch |

Both were confirmed in the code. Neither shows a fix is wrong, and neither blocks: each refuses an act rather than
allowing one. The maintainer typed `stop the review here` at 11:17 local. The stop ended at 12:09 with the gate's
allow (`complete-current-findings-human-accepted`). The sign-off then took the path in DRIFT-082 and DRIFT-085.

## What This Sign-off Claims, and What It Does Not

- **It claims** every finding of rounds A to D is fixed, each behind a test that failed first; that the full sweep of
  `064a2ff4` (1,500 s suite limit, DRIFT-077) is green, with DRIFT-077's start-command allowance recorded in the drift
  log; and that the commits after it, which change only `hook-command-length.tests.ps1` and records, pass the checks
  the maintainer set in place of a second sweep: that suite in both layouts, all ten lanes in the review target's
  layout, and CI (DRIFT-081).
- **It claims** the live hooks run the code round E reviewed. The pin moved from `a56ac787` to `da78b600` at 17:11
  local on 2026-11-15, on the maintainer's typed `advance the pin`, after a full sweep of `da78b600` (DRIFT-082,
  DRIFT-087). The project's hook launcher was not redeployed (DRIFT-085).
- **It does not claim** round E's two findings are fixed. Both fail closed and go to iteration 002's first batch.
- **It does not claim** the hook cost is fixed: about 19 s per turn (DRIFT-073), placed in iteration 002's first batch.
- **It does not claim** a records commit after a human-accepted stop can be signed off. DRIFT-078 is placed in
  iteration 002's first batch; this sign-off needed a partial sign-off instead.

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
| T014 | FR-045 | pass | done live: the pin advance to da78b600 (2026-11-15 17:11 local, on the maintainer's typed "advance the pin"), the verdict after a compaction ("approved for review-signoff", 18:44 local, captured once, marker path) and the drop-finding line (20:58 local, not recorded, its text shown); rehearsed on scratch copies and not typed live: the quoted phrase, the pasted phrase and the verdict typed more than 500 transcript lines after its packet (DRIFT-092); owed in iteration 002: the live `stop the review here` on the advanced engine at iteration 002's first review stop (the maintainer's "Yes to all three", 20:57 local, DRIFT-092); passed on the rehearsal by the maintainer's "accept the rehearsal" (2026-11-16 02:13, DRIFT-094). |

## Gap Ledger

- Deferred to iteration 002, first batch: round E's `finding-cf1fe81e0398f883`, an approval with more than 2 MiB after it can be refused when a later record shares its prompt ID (DRIFT-083); the maintainer's partial review signoff, 2026-11-15 17:30 (.squad\decisions.md, f203-i001-gap-ledger-deferrals).
- Deferred to iteration 002, first batch: round E's `finding-a537d3f72672e5f5`, a review-stop answer lost on the recovery path gets no report (DRIFT-084); the maintainer's partial review signoff, 2026-11-15 17:30 (.squad\decisions.md, f203-i001-gap-ledger-deferrals).
- Deferred to iteration 002, first batch: the hook cost, about 19 s per turn (DRIFT-073); placed by a condition the maintainer accepted, not by words of theirs about the hook cost: their "Yes fix all (203)" (2026-11-14 20:30) answered a recommendation whose third condition kept the hook cost for iteration 002, and their "203: yes" (2026-11-15 01:19) placed DRIFT-078 in iteration 002's first batch alongside it (.squad\decisions.md, f203-i001-gap-ledger-deferrals).
- Deferred to iteration 002, first batch: DRIFT-078 with DRIFT-091 and B5F-071, one design input for the sign-off gate; the maintainer's decisions of 2026-11-15 01:19 and 19:02 (.squad\decisions.md, f203-i001-gap-ledger-deferrals).
- Deferred to iteration 002's first review stop: T014's live `stop the review here` on the advanced engine (DRIFT-092); the maintainer's decision of 2026-11-15 20:57 (.squad\decisions.md, f203-i001-gap-ledger-deferrals).
- Deferred to iteration 002, first batch: the missing test for the retry-idempotency hardening row, a second top-up with no round between grants no extra window; the maintainer's decision of 2026-11-16 02:13 (.squad\decisions.md, f203-i001-gap-ledger-deferrals).

## Notes

- The review needed a fifth round because the review-end records could not follow the stop (DRIFT-078); the path was
  proved on scratch copies before any record was written (DRIFT-076).
- The sign-off sync then refused once at its state-truth gate. Its way through was proved on scratch copies before
  anything changed in the real tree (DRIFT-082, DRIFT-086).
