# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-10-19
**Overall Verdict**: accepted, by partial sign-off: the round-8 fixes reached sign-off without a further review round,
by the maintainer's typed acceptance, and one defect fix made after sign-off (DRIFT-004, B4F-138) is unreviewed and
listed here for the maintainer's decision

## Independent review

Campaign `cmp-202-beta4-1-ux-stabilization-i002`, reviewer codex, code writer Claude. Eight rounds, each started by the
maintainer's own typed `approved for review round`, rounds 5 to 8 after the allowance reset of 2026-10-17:

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

That is 32 findings, all real; 28 were demoted for "no concrete failure scenario", and each one states one. Across
feature 202, 64 of 64 findings are real (B4F-055). Each was checked against the code and fixed behind a test that failed
first (`drift-log.md`, DRIFT-003).

**How sign-off closed (DRIFT-003, review close).** The round-8 fixes were committed after round 8, with the allowance
spent. The crew recommended `stop the review here` and said the final check would cover those fixes. That was wrong,
and it repeated iteration 001's DRIFT-033. The stop was refused with `latest-result-not-current`, and the decision was
not spent. The maintainer then typed `approved for partial review signoff - the round-8 fixes have failing-first tests,
all eight lanes pass, and the Copilot re-walk exercises the conditional partial sign-off on a non-Claude host` as the
whole message. The stop, run again with no write in between, completed. The engine reported: "Your files were checked
exactly as they are now, the remaining findings were saved as follow-ups, and review sign-off is complete."

## Changes After Sign-off

CI had been red on every push since T016 (`46639843`), unwatched through all eight rounds, because the local lanes do
not run those suites (DRIFT-004). After sign-off:

- `cc6126ae`: two regressions fixed. The workshop guard sentence T020 had dropped was restored, and a hook-health suite
  had counted T016's unrecognized-payload record as a receipt. The product was unaffected by the second.
- `fcc62934`, on the maintainer's `fix it now`: stored times are compared as exact moments, not re-read from text.
  This fixed the third failure (a line marked in the same second the hook started was never put back) and three of
  T017's approval checks. Behind UTC, a `+00:00` record made the legacy check miss a message's own record: B4F-127's
  double record. The real ledger stores `Z` times, so no live double record follows from it. The sweep also fixed the
  review engine's "latest result" orderings within one second (B4F-138).
- One commit is local only: the CI step that runs the stored-time suite on all three platforms. GitHub refused the push
  because this session's login has no permission for workflow files.

None of these changes was reviewed.

## What This Sign-off Claims, and What It Does Not

- **It claims** every task's tests pass at `19151871`: all eight verification lanes, and CI green on all three
  workflows (Specrew CI 39221434586, Test 39221434573, Cross-Platform Validation 39221434596). That is the first green
  CI since T016.
- **It claims** B4F-127 and B4F-129, the beta4.1 release gate, are fixed in code: one message, one key (T017, FR-027,
  SC-010), and a hook that acts only for its own host (T016, FR-028).
- **It does not claim** the round-8 fixes or the post-sign-off changes were reviewed. The maintainer accepted the
  round-8 fixes by the typed partial sign-off; the post-sign-off changes are listed above for the maintainer's decision.
- **It does not claim** SC-011 holds live. That is measured by the maintainer's Copilot re-walk (`copilot-rewalk.md`).
  Until then, its after-value is null.
- **It does not claim** CI was green during review. It was red from T016 to sign-off.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T017 | FR-027, SC-010 | pass | `message-identity` (43 cases); `timestamp-read` cases 6 and 7 after sign-off (unreviewed). |
| T016 | FR-028, SC-011 | pass | `host-binding-match` (255 assertions); SC-011 live after-value waits on the Copilot re-walk. |
| T022 | FR-033 | pass | `receipt-disclosure` case 20; `receipt-outcomes-retired`. |
| T020 | FR-031 | pass | `workshop-delegation` cases 1 to 10; guard sentence restored after sign-off (`cc6126ae`). |
| T021 | FR-032 | pass | `workshop-question-tool` (47 shipped files). |
| T018 | FR-029 | pass | `approval-form` (51 cases, round-8 condition case on all three hosts); `verdict-capture-blocks` W45. |
| T019 | FR-030 | pass | `presented-check` cases 9 to 11. |
| T023 | FR-034 | pass | `turn-draft-intake` cases 1 to 6 and 9; reviewed in round 6 with no finding on it. |
| T024 | FR-027 to FR-034 | pass | `acceptance-evidence.md`; `copilot-rewalk.md` written; the walk itself is the maintainer's. |

## Gap Ledger

- **Unreviewed code**: the round-8 fixes (accepted by the maintainer's partial sign-off) and the post-sign-off changes
  (`cc6126ae`, `fcc62934`). The maintainer decides at this boundary whether the latter get a review round.
- **SC-011 live value**: waits on the maintainer's Copilot re-walk.
- **CI step for the stored-time suite**: committed locally, not pushed; it needs a login with workflow permission.
- **B4F-138 class**: the fourth time stored times were compared through text. A tree-wide lint is a beta5 candidate.
- **Beta5 findings raised in iteration 002**: B4F-126 (second recurrence: a stop recommended after fixes outside the
  last round), B4F-055 (the engine's demotions), and the rest in `docs/beta4-findings.md`.

## Notes

- Retro inputs: a fix-and-review loop that took eight rounds to converge (32 findings; rounds 1 to 4 were all on T017 and its
  fixes); CI red and unwatched from T016 to sign-off; and the stop recommended in place of the partial sign-off, for
  the second iteration running.
- Drift checks ran throughout; the drift log has DRIFT-001 to DRIFT-004, each with its resolution and class closure.
