# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-10-20
**Overall Verdict**: accepted: ten rounds; the round-8 fixes reached sign-off by the maintainer's typed partial
sign-off, and the changes made after it were reviewed in rounds 9 and 10, with round 10 clean and current

## Independent review

Campaign `cmp-202-beta4-1-ux-stabilization-i002`, reviewer codex, code writer Claude. Ten rounds, each started by the
maintainer's own typed `approved for review round`. Rounds 5 to 8 followed the allowance reset of 2026-10-17, rounds 9
and 10 the reset of 2026-10-19:

| Round | Run | Covered | Findings | Demoted | Real |
| --- | --- | --- | --- | --- | --- |
| 1 | `run-20261017-093636207-bf1e4cc7` | T016, T017 | 6 | 5 | 6 |
| 2 | `run-20261017-134352532-0fb503db` | round-1 fixes | 4 | 4 | 4 |
| 3 | `run-20261017-152855473-5b668458` | round-2 fixes | 3 | 3 | 3 |
| 4 | `run-20261017-181522696-4d1fe121` | round-3 fixes | 3 | 3 | 3 |
| 5 | `run-20261018-075433218-7cbe648b` | round-4 fixes, B4F-137, T018 to T022 | 5 | 4 | 5 |
| 6 | `run-20261018-114927550-9d62a483` | round-5 fixes, T023, T024 | 6 | 4 | 6 |
| 7 | `run-20261018-125258950-98a6a63d` | round-6 fixes | 3 | 3 | 3 |
| 8 | `run-20261018-163747348-5da84de1` | round-7 fixes | 2 | 2 | 2 |
| 9 | `run-20261020-091334714-2512bac6` | the changes made after sign-off | 3 | 2 | 3 |
| 10 | `run-20261020-104236165-bf217f2e` | round-9 fixes | 0 | 0 | 0 |

That is 35 findings, all real; 30 were demoted for "no concrete failure scenario", and each one states one. Across
feature 202, 67 of 67 findings are real (B4F-055). Each was checked against the code and fixed behind a test that failed
first (`drift-log.md`, DRIFT-003 to DRIFT-005).

**How sign-off closed after round 8 (DRIFT-003).** The round-8 fixes were committed after round 8, with the allowance
spent. The crew recommended `stop the review here` and said the final check would cover those fixes. That was wrong,
and it repeated iteration 001's DRIFT-033. The stop was refused with `latest-result-not-current`, and the decision was
not spent. The maintainer then typed `approved for partial review signoff - the round-8 fixes have failing-first tests,
all eight lanes pass, and the Copilot re-walk exercises the conditional partial sign-off on a non-Claude host` as the
whole message. The stop, run again with no write in between, completed.

**Rounds 9 and 10, on the changes made after sign-off.** The maintainer sent those changes to review: an allowance
reset (`reset-8170f3b4511c93dcc47c`), then a round.

- The first launch of round 9 was refused before the reviewer started: this record had been committed before the round,
  with the plan still at "executing" (DRIFT-005). On the maintainer's `move it aside`, the record came out of the
  iteration folder (`537352e3`) until the rounds were done.
- The maintainer typed the round approval again after that commit. It was not stored, because the earlier typed
  approval (01:06Z) was still unspent (B4F-140). On the maintainer's `use it`, round 9 ran on the 01:06Z approval.
- Round 9 found two sites the stored-time fix had missed, and one unused variable. All three are fixed in `cb5be72f`
  behind a failing test (`timestamp-read` case 10, 6 failures on the old code). The reviewer marked its own coverage
  partial, and the engine reported the round as having found nothing (B4F-139).
- Round 10 ran on a fresh typed approval (10:42:10Z). The engine reported: "Nothing was found, and this review covers
  your files exactly as they are now."

## Changes After the Round-8 Sign-off

CI had been red on every push since T016 (`46639843`), unwatched through rounds 1 to 8, because the local lanes do not
run those suites (DRIFT-004). After sign-off:

- `cc6126ae`: two regressions fixed. The workshop guard sentence T020 had dropped was restored, and a hook-health suite
  had counted T016's unrecognized-payload record as a receipt. The product was unaffected by the second.
- `fcc62934`, on the maintainer's `fix it now`: stored times are compared as exact moments, not re-read from text.
  This fixed the third failure (a line marked in the same second the hook started was never put back) and three of
  T017's approval checks. Behind UTC, a `+00:00` record made the legacy check miss a message's own record: B4F-127's
  double record. The real ledger stores `Z` times, so no live double record follows from it. The sweep also fixed the
  review engine's "latest result" orderings within one second (B4F-138).
- `cb5be72f`: the round-9 fixes. The round approval an allowance reset creates, and the check that stops one reset
  approval from topping up the rounds twice, now read the capture time as an instant.
- One commit is local only: the CI step that runs the stored-time suite on all three platforms. GitHub refused the push
  because this session's login has no permission for workflow files.

All of these were reviewed in rounds 9 and 10.

## What This Sign-off Claims, and What It Does Not

- **It claims** every task's tests pass at `cb5be72f`: all eight verification lanes, and CI green on all three
  workflows (Specrew CI 39404397222, Test 39404397299, Cross-Platform Validation 39404397149).
- **It claims** round 10's clean result covers the files as they are now. Round 10's scope was the changes made after
  the round-8 sign-off; the round-8 fixes themselves were accepted by the maintainer's partial sign-off.
- **It claims** B4F-127 and B4F-129, the beta4.1 release gate, are fixed in code: one message, one key (T017, FR-027,
  SC-010), and a hook that acts only for its own host (T016, FR-028).
- **It does not claim** SC-011 holds live. That is measured by the maintainer's Copilot re-walk (`copilot-rewalk.md`).
  Until then, its after-value is null.
- **It does not claim** CI was green during rounds 1 to 8. It was red from T016 to the round-8 sign-off.
- **It does not claim** the stored-time class is closed: a fifth site, found after round 10, is logged for beta5
  (B4F-141).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T017 | FR-027, SC-010 | pass | `message-identity` (43 cases); `timestamp-read` cases 6, 7 and 10, reviewed in rounds 9 and 10. |
| T016 | FR-028, SC-011 | pass | `host-binding-match` (255 assertions); SC-011 live after-value waits on the Copilot re-walk. |
| T022 | FR-033 | pass | `receipt-disclosure` case 20; `receipt-outcomes-retired`. |
| T020 | FR-031 | pass | `workshop-delegation` cases 1 to 10; guard sentence restored after sign-off (`cc6126ae`). |
| T021 | FR-032 | pass | `workshop-question-tool` (47 shipped files). |
| T018 | FR-029 | pass | `approval-form` (51 cases; the reset's round approval now compared as an instant); `verdict-capture-blocks` W45. |
| T019 | FR-030 | pass | `presented-check` cases 9 to 11. |
| T023 | FR-034 | pass | `turn-draft-intake` cases 1 to 6 and 9; reviewed in round 6 with no finding on it. |
| T024 | FR-027 to FR-034 | pass | `acceptance-evidence.md`; `copilot-rewalk.md` written; the walk itself is the maintainer's. |

## Gap Ledger

- **Round-8 fixes**: accepted by the maintainer's partial sign-off, not reviewed line by line.
- **SC-011 live value**: waits on the maintainer's Copilot re-walk.
- **CI step for the stored-time suite**: committed locally, not pushed; it needs a login with workflow permission.
- **B4F-141**: the hook-health record carries an episode's start time as text; logged for beta5 by the maintainer's
  `log it`, with the tree-wide check for the class.
- **B4F-142**: one Linux CI run counted 4001 journal lines for 4000 appends; passed on the next push; not investigated.
- **Beta5 findings raised in iteration 002**: B4F-126 (second recurrence: a stop recommended after fixes outside the
  last round), B4F-055 (the engine's demotions), B4F-139 and B4F-140 (round 9's report and approval), and the rest in
  `docs/beta4-findings.md`.

## Notes

- Retro inputs: a fix-and-review loop that took ten rounds (35 findings; rounds 1 to 4 were all on T017 and its fixes);
  CI red and unwatched from T016 to the round-8 sign-off; the stop recommended in place of the partial sign-off, for the
  second iteration running; the review record written before a round that could still run (DRIFT-005); and the
  stored-time class found one site at a time, five times.
- Drift checks ran throughout; the drift log has DRIFT-001 to DRIFT-005, each with its resolution and class closure.
