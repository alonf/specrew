# Review: Iteration 003

**Schema**: v1
**Reviewed**: 2026-10-24
**Overall Verdict**: accepted: four rounds, every finding fixed except round 4's note (B4F-151), stopped by the
maintainer's typed `stop the review here`; the maintainer's Copilot re-walk then passed SC-011

## Independent review

Campaign `cmp-202-beta4-1-ux-stabilization-i003`, reviewer codex, code writer Claude. Four rounds, each started by the
maintainer's own typed `approved for review round`. The reviewer could not run `git diff`, so rounds 2 to 4 read a file
list (`review-round-2-files.md` to `review-round-4-files.md`).

| Round | Run | Covered | Findings | Outcome |
| --- | --- | --- | --- | --- |
| 1 | `run-20261021-160210288-728ad1a0` | T025 to T032; partial, it could not run `git diff` | 1 minor | Fixed in `0f04b5cd` (T032: a consumer's closeout capture loads the module its extension came from) |
| 2 | `run-20261021-195823967-0de4a137` | T025 to T029 and round 1's fix | 2 minor, 2 notes | All fixed in `c503d405` on `fix the findings now` |
| 3 | `run-20261022-085836670-1423f459` | Round 8's fixes from iteration 002 (`ac87d96c`) and round 2's | 1 minor | Fixed in `8aa15c19` on `fix the finding now` |
| 4 | `run-20261022-211453497-9ebe9c9c` | Round 3's fix | 1 note | Carried as B4F-151 |

That is 6 findings and notes, each checked against the code; 5 are fixed behind a test that failed first, and round 4's
note is a follow-up. The review allowance (4 of 4) is spent. On 2026-10-22 the maintainer typed `stop the review here`,
and sign-off completed with the final check on `f00da0f2`.

## Changes After the Review Sign-off

- `2ea34f92`: the runtime refresh, which deploys T031, T032 and the round fixes into this project. The deployed copies
  match the reviewed sources; the three deployed-copy parity suites pass since.
- `1509b896`: eight payload shapes from the maintainer's re-walk added to the probe fixtures, redacted. Test data
  only; `host-binding-match` and `subagent-prompt-authority` pass with them. No round has read them.
- Records and findings: the round 4 file list, T030's acceptance evidence, B4F-151 to B4F-157 and B5F-006 to B5F-011.
- `4783a721` wrote the re-walk row into closed iteration 002 and `995bf705` reverted it (DRIFT-002). Specrew CI's
  governance check failed on the three pushes that carried those commits, because it validates any iteration a push
  touches, and closed iteration 002's hardening gate still lists open concerns.

## What This Sign-off Claims, and What It Does Not

- **It claims** the maintainer's Copilot re-walk passed SC-011 (Copilot 1.0.101, `2ea34f92`): 0 receipts, stop-block
  rows or hook rows under `claude`, and no receipt written twice, with Copilot still running Claude's hooks. One specify
  approval was recorded, from the maintainer's own typed message. B4F-127 and B4F-129, the beta4.1 gate, held live.
- **It claims** every task's tests pass: all ten verification lanes on round 3's fix (`8aa15c19`), and the two suites
  that read the probe fixtures on `1509b896`.
- **It does not claim** T029 held live. Its shipped text passes FR-032, but Copilot asked the product-domain question
  through `ask_user` anyway (B4F-131 seen again, B4F-153). The maintainer ruled both outside the gate on 2026-10-24.
- **It does not claim** B4F-146 holds live. T031's live test is iteration 003's own closeout, and T032's is 202's
  feature closeout.
- **It does not claim** round 4's note is fixed (B4F-151), or that a round read the fixtures added after sign-off.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T025 | FR-028, SC-011 | pass | The probe passes 108 of 108; live, 0 unrecognized-payload records. |
| T026 | FR-028, SC-011 | pass | `host-binding-match` part 1b; live, 0 hook rows under `claude`. |
| T027 | FR-028 | pass | `host-binding-match` parts 1 and 1b; the walk's record count was 0. |
| T028 | FR-028 | pass | `subagent-prompt-authority`; live, the sub-agent's instructions were refused and nothing was stored (B4F-155 for the row and session it left). |
| T029 | FR-032 | pass | `workshop-question-tool` (122 shipped files); not held live on Copilot (B4F-131, B4F-153), outside the gate. |
| T031 | FR-027 | pass | `closeout-records-on-approval` cases 1 to 4; live at iteration 003's closeout. |
| T032 | FR-027 | pass | `closeout-records-on-approval` cases 5 to 8; live at 202's feature closeout. |
| T030 | SC-011 | pass | `acceptance-evidence.md`; the re-walk passed SC-011. |

## Gap Ledger

These items are open. None is deferred by this record. Their dispositions so far are the maintainer's rulings named
on each.

- **B4F-151**: open - round 4's note: an approval form that cannot be read records nothing and tells the human nothing.
  Carried as a follow-up by the maintainer's `stop the review here`.
- **Fixtures added after sign-off**: open - `1509b896`, test data only, not read by a round. The allowance is spent.
- **T029 live**: open - B4F-131 and B4F-153, outside the beta4.1 gate (`keep the gate as ruled`, 2026-10-24).
- **B4F-146 live**: open - T031 at iteration 003's closeout, T032 at 202's feature closeout.
- **Re-walk misses 3 to 7**: open - B4F-154 to B4F-157 and B5F-011, logged, not scheduled.
- **B4F-152**: open - the pause prompt's command refuses without `--feature`; logged, not scheduled.
- **CI step for the stored-time suite**: open - committed locally on `ci-stored-time-step`; its push needs a login with
  workflow permission and is the maintainer's.

## Notes

- Retro inputs: a review record and the review-signoff stop both skipped. The crew committed the review engine's sign-off
  as `boundary(review-signoff)` (`9881b2d9`) with no review record and no stage approval, and went on toward the retro
  until the maintainer stopped it (DRIFT-003). The re-walk row was written into a closed iteration (DRIFT-002). T029 was
  fixed in words, and Copilot did not follow them. The re-walk took one corrective exchange and no extra stops, down
  from 9 extra stops and 5 corrective exchanges in iteration 1.
- Drift checks ran throughout; the drift log has DRIFT-001 to DRIFT-003, each with its resolution and class closure.
