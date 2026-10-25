# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-10-16
**Overall Verdict**: accepted, by partial sign-off: round 6's four fixes reached sign-off without a further review
round, by the maintainer's advance acceptance, and one critical defect older than 202 is open (B4F-127)

## Independent review

Campaign `cmp-202-beta4-1-ux-stabilization-i001`, reviewer codex, code writer Claude. Six rounds, the last two after
the maintainer's allowance reset:

| Round | Run | Findings | Demoted | Real | Fixed in |
| --- | --- | --- | --- | --- | --- |
| 1 | `run-20261013-234651770-ac649a7e` | 8 | 8 | 8 | DRIFT-014 |
| 2 | `run-20261014-102731596-597f9ec9` | 5 | 4 | 5 | DRIFT-015 |
| 3 | `run-20261014-173122349-f5d4f978` | 4 | 4 | 4 | DRIFT-024 |
| 4 | `run-20261015-110313119-da115ef4` | 5 | 0 | 5 | DRIFT-031 |
| 5 | `run-20261016-002823641-f5fc77f3` | 6 | 4 | 6 | DRIFT-032 |
| 6 | `run-20261016-031317319-8c4537dd` | 4 | 3 | 4 | DRIFT-032 (`0e6a8a01`) |

That is 32 findings, all real; 23 were demoted to minor, and every demoted finding was real (B4F-055). Each was
checked against the code with a separate trace and fixed behind a test that failed first.

**How sign-off closed (DRIFT-033).** Round 5's result moved mid-run because of a crew commit, so it could not carry a
sign-off, and round 6 had to run against the maintainer's "no round 6" rule: mechanics overrode it, not a decision.
Round 6's four fixes were committed after the round, so the stop after round 6 was refused as well. Sign-off closed
on the maintainer's typed `approved for partial review signoff - round 6's four fixes each have a failing-first
test, CI is green at bf94e30a, and I accepted them unreviewed in advance`, together with their typed
`stop the review here` for round 6's pause. Both were recorded from the maintainer's own messages (message-received
path; `stop-here.json` names run `run-20261016-031317319-8c4537dd`). The engine reported: "Your files were checked
exactly as they are now, the remaining findings were saved as follow-ups, and review sign-off is complete."

## What This Sign-off Claims, and What It Does Not

- **It claims** every task's tests pass at `bf94e30a`: all seven verification lanes, run cold (lowest headroom 2.89x),
  the 13 touched suites outside the lanes and both copy-parity checks. CI at `bf94e30a` is green: Specrew CI
  38848274478, Test 38848274583, Cross-Platform Validation 38848274457.
- **It claims** a round approval is never a stage approval, with `before-implement -> review-signoff` pending:
  `tests/unit/round-phrase-never-boundary-verdict.tests.ps1` (lane f199-class-guards-b).
- **It does not claim** round 6's four fixes were reviewed. They were not; the maintainer accepted them in advance.
- **It does not claim** Tier 1 worked for people. That is measured by the live walk at closeout (`live-walk.md`),
  against the beta4 baseline of 8 stops in one session, none about the code (`acceptance-evidence.md`). Until then,
  the SC-001 and SC-003 after-values are null.
- **It does not claim** approvals are safe from duplication. B4F-127 is open (below).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-024 | pass | Host payloads captured in scratch folders; measurements in `research.md`. |
| T002 | FR-006, FR-024, SC-001 | pass | `turn-record-contract` through the deployed hook command. |
| T003 | FR-001 to FR-005, FR-008, FR-025, SC-002 | pass | `hook-output-journal`, including round 6's partial health line. This area drew 22 of the 32 findings (retro input). |
| T004 | FR-007, FR-009, FR-010 | pass | `receipt-disclosure` cases 1 to 19, including round 5's conditional yes and decline. |
| T005 | FR-001, FR-024, FR-025, SC-001, SC-002 | pass | Cross-host acceptance suite; closed on run 38587028733. |
| T006 | FR-011, SC-004 | pass | `crossing-presentation`, including round 6's parenthesised and case-differing links. |
| T007 | FR-012, FR-013, FR-015, SC-003 | pass | `presented-check`, including heading meaning-match (DRIFT-030) and round 6's bullet-wrapped options. |
| T008 | FR-014, SC-003 | pass | `orientation-order`. |
| T009 | FR-016, SC-005 | pass | `dials-parity`. |
| T010 | FR-017, FR-018, SC-006 | pass | `feature-resolver`. |
| T011 | FR-026, SC-006, SC-009 | pass | `new-feature-reset`, `crossing-mint-gate` case 6 (feature-scoped identity, round 5). |
| T012 | FR-019 | pass | `resume-from-disk`. |
| T013 | FR-020 | pass | `design-analysis-gate-refusal`. |
| T014 | FR-021 | pass | `turn-draft-intake` on Windows, Ubuntu and macOS (Hebrew, emoji, CRLF). |
| T015 | FR-024, SC-001, SC-003, SC-008 | pass | `acceptance-evidence.md` maps every SC to evidence. The live walk is written for about 35 minutes across three hosts; its after-values are filled at closeout. |

## Gap Ledger

- **B4F-127, critical, open; predates 202 (seen from 2026-08-30).** One typed approval can be recorded again at a
  turn end, leaving an approval the maintainer never gave. A scratch reproduction found 6 records from one message
  in a long conversation, and a stop-here decision re-bound to a pause the human never saw
  (`b4f-127-reproduction.md`, DRIFT-034). Iteration 002, first item, by the maintainer's ruling. Interim crew rule:
  before any round launch, pause choice or allowance reset, check the stored approval came from the human's own
  typed message for that run.
- **B4F-125** (approval refused by position; one decision, two approvals; a script offered as the approval):
  iteration 002, second item.
- **Round 6's four fixes**: unreviewed, accepted in advance by the maintainer.
- **Beta5 findings raised during 202**: B4F-111 to B4F-124 and B4F-126, in `docs/beta4-findings.md`.

## Notes

- Retro inputs, each with its evidence, are in `retro-inputs/`: the findings trend, why the tests missed all 32, the
  runtime-store inventory before and after 202 (12 stores added, none removed), and the live friction events.
- The proposed iteration-002 order (B4F-127, B4F-125, B4F-055, one simplification item; 15 SP or less) is in
  `plan.md`, to be decided at iteration 002's plan stop.
- Drift checks ran throughout; the drift log has DRIFT-001 to DRIFT-034, each with its resolution and class closure.
