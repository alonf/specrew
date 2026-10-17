# Drift Log: Iteration 002

**Schema**: v2

## Summary

**Total drift events**: 3 (DRIFT-001 to DRIFT-003)

## Events

### DRIFT-001 — the iteration-2 scope replaces Tier 2's review-ordering slice; spec amended at the plan (approved with the plan)

- **Observed**: 2026-10-17, iteration-2 plan. The spec's Tier 2 held US7 (FR-022, the review-ordering slices of
  B4F-054/056/058/061, and FR-023, the B4F-103 package comparison). The maintainer's scope ruling ("scope as
  recommended") gave iteration 2 to "one human act, one record" instead: B4F-127 and B4F-129 (the release gate), B4F-125
  with B4F-128, B4F-130, B4F-131, and retro candidates 3 and 7.
- **Requirement citation**: spec.md Scope (Tier 2), US7, FR-022, FR-023; the out-of-scope line "any redesign of the hook
  dispatcher or stores".
- **Resolution**: spec-updated. The Scope line is amended, US7, FR-022 and FR-023 are marked as moved to beta5 and kept as
  the record, and US8 with FR-027 to FR-034, SC-010 and SC-011 is added. Iteration 2 touches the dispatcher and the stores
  only as far as FR-028 and FR-033 require, which the amended Scope line states. The amendment takes effect with the
  maintainer's plan approval. **Approved** with the plan (`09fcbe07`).
- **Class closure**: NONE - a scope change by ruling, not a defect; the amendment and this entry are the record.

### DRIFT-002 — the pre-review governance command still named iteration 001 (resolved)

- **Observed**: 2026-10-17, iteration-2 before-implement preparation. `.specrew/verification-plan.json` ran the
  governance validation against `iterations/001`, which is sealed. The fourth instance of the recurrence 202 DRIFT-011
  (iteration 001) recorded: the command names an iteration number instead of the active iteration.
- **Requirement citation**: the review's verification plan must validate the active iteration (iteration 001 DRIFT-011).
- **Resolution**: re-pointed to `iterations/002` (command `iteration-002-governance-202`). Run locally: PASS, exit 0, with
  six `handoff-block-missing` warnings for boundary commits whose packets were not saved as handoff evidence (B4F-136's
  Codex observation, seen here on Claude too; non-blocking).
- **Class closure**: NONE - making the command name the active iteration is beta5 work (the review engine), per the
  iteration-2 scope ruling.

### DRIFT-003 — co-review round 1 found six defects in T017; five were demoted, and all six are real (resolved)

- **Observed**: 2026-10-17, co-review round 1 (`run-20261017-093636207-bf1e4cc7`, codex, 25 minutes), on the
  maintainer's typed `approved for review round`. The message hook recorded it once (09:35:47 UTC), and no turn end
  recorded it again: T017 working live. Scope `fe509311..46639843` (T017 and T016). 6 findings, all against T017: 5
  reported blocking or major and demoted to minor for "no concrete failure scenario" (each states one), 1 reported
  minor. The summary read "Nothing found that needs your attention." Each was checked against the code, and each is real:
  1. **An update re-recorded a spent approval.** A message recorded before the message-ID key is in the ledger under the
     old key. The first turn end after an update computed the new key, found nothing, and recorded the approval again
     (B4F-127 for every upgrading project).
  2. **On Copilot, a withdrawal the message hook missed was dropped.** The `none` branch reported only approval shapes,
     so a revoked approval stayed spendable. Partial sign-off and workshop repair were not shaped either.
  3. **A recent identical phrase vouched for a missed message.** Any same-text reservation in the last minute counted,
     including an earlier message's or another session's.
  4. **A miss was reported in whichever session spoke next,** and marked as said there.
  5. **A missed abandon was told to retype `stop the review here`,** a different decision.
  6. **A trailing space read as a miss.** The prompt path hashed untrimmed text; the turn end hashes the transcript's
     trimmed text.
- **Requirement citation**: FR-027 and DA-2 (one message, one record; a miss is reported, never silent).
- **Resolution** (`7a75987b`), each behind a failing test:
  1. The turn end also checks the old record of the message (`Test-SpecrewLegacyTurnRecorded`: the old position key,
     or the same text on the same host from just before the message arrived; with no arrival time it fails closed).
     Reservations under the new key carry `identity = message-id` and are never read as history.
  2. A missed withdrawal is recorded by the turn end, once, under its position key. The shape table covers every writer.
  3. The check counts: every same-text human message in the transcript window needs its own reservation in the same
     session, from the earliest of them on.
  4. Reports and disclosures carry the session, and a session hears only its own.
  5. The retype follows the recognized choice.
  6. Both paths hash the trimmed text.
  Also: the cross-channel double-mint observation is skipped under a message-ID key, where it misfired on the
  maintainer's round-1 approval against a phrase typed days earlier.
- **Tests**: `message-identity` 11 new cases, all RED on `46639843`, and 29 of 29 green. All eight lanes pass;
  `f202-i002-suites` takes 193 s alone, and its timeout goes from 450 s to 480 s (2.49x).
- **Class closure**: findings 3 and 4 are the class round 5 of iteration 001 found in the recording disclosure
  (DRIFT-032 finding 5): state read across sessions by time alone. Every T017 read is now tied to the session and the
  message. Finding 1 is the upgrade case of a key change: history under the old key is read once more.
- **Not new**: the prompt hook answered the round approval with "reads as a verdict for 'review' ... nothing was
  recorded" (B4F-116, fifth recurrence; a beta5 candidate).
