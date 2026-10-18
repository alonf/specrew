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

### DRIFT-003 — co-review rounds 1 to 4 found sixteen defects in T017 and its fixes; fifteen were demoted, and all sixteen are real (resolved)

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
- **Round 2 (2026-10-17, the maintainer's typed `approved for review round`, recorded once by the message hook with
  the new session and identity fields)**: run `run-20261017-134352532-0fb503db` (codex, 26 minutes) reviewed the round-1
  fixes, answering round 1's pause with "run another round". The crew had recommended carrying the fixes into the planned
  round after T019; the maintainer chose to review them now. 4 findings, all reported blocking or major and demoted for
  "no concrete failure scenario" (each states one). Each was checked against the code, and each is real:
  1. **The history check missed an untrimmed record.** The old message hook hashed the untrimmed text, so a spent
     pre-update approval typed with a trailing space still came back after an update.
  2. **Received was read as saved.** A reservation is written before the writers run, so an approval whose writer failed
     (a locked file) read as recorded, and nothing was reported.
  3. **A message outside the transcript window could still vouch.** The count started 60 seconds before the earliest
     counted message, so an identical approval just outside the window satisfied it.
  4. **The not-recorded line was marked said before delivery.** When the dispatcher withheld that output, the line was
     lost for good.
- **Resolution** (`f98c0a96`, runtime `30a65e86`), each behind a failing test:
  1. An old message-hook record within 15 seconds of the message's arrival matches on time alone. Measured on the live
     ledgers: Copilot's hook records 4 to 6 s before the transcript entry, and Claude's about 4 s after.
  2. The router reports a recognized act whose writer threw and stored nothing (`reason = not-saved`), and says it in the
     same turn: "was received but could not be saved".
  3. Each counted message is paired with a reservation within 15 s of its own arrival, and the answer is the latest
     message's. **Residual, stated**: on Copilot, which sends no message ID, two identical approvals typed less than 15 s
     apart, with the first pushed out of the 500-line window in between and the second missed, still cannot be told apart.
  4. The dispatcher (both twins) appends an `undelivered` row for each line marked said during a withheld fire, as it
     already takes back an undelivered recovery question, and the store says the line again at the next message.
- **Tests (round 2)**: `message-identity` 5 new cases and `hook-output-journal` 1 new check, all RED on `48540631`;
  `message-identity` 34 of 34 green. All eight lanes pass. `f199-class-guards-b` failed once in the 8-way parallel run
  (`mechanical-checks-applicability`, untouched by these changes) and passed alone and on its lane rerun. The
  `f202-i002-suites` lane takes 248 s alone, and its timeout goes from 480 s to 600 s (2.42x).
- **Class closure (round 2)**: findings 2 and 4 are the same class: a record of success written before the success. The
  reservation now stands only for "the hook saw it", with a failed save reported separately. The not-recorded line joins
  the orientation stamp and the recovery question in the dispatcher's undelivered rollback.
- **Plan effect**: round 2 is spent on the fixes, so the round planned after T019 becomes round 3 (3 of 4). Superseded
  by round 3 below.
- **Not new**: the round-2 approval drew B4F-116's notice again (sixth recurrence).
- **Round 3 (2026-10-17, the maintainer's typed `approved for review round`, recorded once by the message hook)**: run
  `run-20261017-152855473-5b668458` (codex, 26 minutes) reviewed the round-2 fixes. The crew had again recommended
  carrying them into the round after T019, and the maintainer again chose to review them now. 3 findings, all reported
  major and demoted for "no concrete failure scenario" (each states one). Each was checked against the code, and each is
  real:
  1. **A recovered withdrawal re-ran as the window slid.** The Copilot turn end keyed it by its index in the 500-line
     transcript window. Each new index was a new key, so a later turn end ran the withdrawal again, against an approval
     another session had recorded since (round 1's fix, finding 2).
  2. **The workshop repair writer hid a failed save.** It caught its own lock and append failures and returned null, so
     round 2's not-saved report never fired for it.
  3. **A provider timeout lost the not-recorded line.** Round 2's restore ran only for withheld output, and a provider
     killed after marking the line said never set that flag.
- **Resolution (round 3)** (`8222019a`, runtime `db4ed7a1`), each behind a failing test:
  1. A recovered withdrawal is keyed by its transcript entry (`entry:<id>`), which never moves.
  2. Once the phrase has matched, the repair writer rethrows a failed save. The withdrawal writer throws when none of its
     four stores landed. The router reports both as received but not saved. The other five writers already throw on a
     failed save (checked).
  3. The dispatcher restores, once per prompt, every line marked said during the fire that the delivered output does not
     carry: withheld, timed out and failed alike.
- **Tests (round 3)**: `message-identity` 3 new cases and `hook-output-journal` 1 new check, all RED on `28a499fe`.
  `message-identity` 37 of 37, `round-approval-typed-authority` 130 of 130 and `lens-acknowledgment` are green. All eight
  lanes pass, and `f202-i002-suites` takes 224 s alone against 600 s. The repair case needed the project's deployed
  workshop store, which the message hook loads from `.specify` as in a real project.
- **Class closure (round 3)**: finding 3 completes round 2's class: whether a line was shown is decided by what was
  delivered, not by one cause of loss. Finding 2 closes "a writer that swallows its own save failure" across all seven
  writers. Finding 1 removes the last window-relative key from the T017 code.
- **Plan effect**: rounds 1 to 3 are spent on T017 and its fixes. The round after T019 is round 4, the last in the
  allowance; a further round needs the maintainer's allowance reset. Superseded by round 4 below.
- **Round 4 (2026-10-17, the maintainer's typed `approved for review round`, recorded once by the message hook)**: run
  `run-20261017-181522696-4d1fe121` (codex, 23 minutes) reviewed the round-3 fixes. The crew had recommended carrying
  them into the round after T019; the maintainer chose to review them now. 3 findings, all reported major and demoted
  for "no concrete failure scenario" (each states one). Each was checked against the code, and each is real:
  1. **A time-only legacy match suppressed a different act.** Round 2's trailing-space fix matched an old message hook
     record on time alone. The old hook reserved every message, so an ordinary reply, or an approval, typed within 15
     seconds before a withdrawal the message hook then missed, matched it, and the withdrawal was never recorded.
  2. **A dispatcher failure lost the not-recorded line.** Round 3's restore ran at the dispatcher's normal end only. A
     failure after a provider marked the line said (a session state it can read but not save) took the fail-open exit
     without putting it back.
  3. **The repair writer still dropped a failure before the save.** Round 3 rethrew failures from the save onward, but an
     existing repair record it could not read (torn line, lock) failed earlier and was read as a non-match.
- **Resolution (round 4)** (`c43b3cec`, runtime `3f8e94fb`), each behind a failing test:
  1. An old record matched on time alone vouches for this message only when that old turn recorded the same kind of act
     (its minted writer, read from the ledger's second line for that turn).
  2. The fail-open exit reconciles the line against what was delivered before the failure, as the normal end does, and
     so does the stop-block exit. Reconciliation runs once per fire.
  3. In the repair writer, a non-match is an explicit `return $null`; anything that throws after the phrase matched (an
     unreadable proposal, an unreadable existing record, a failed save) propagates and is reported as not saved.
- **Tests (round 4)**: `message-identity` 4 new cases and `hook-output-journal` 1 new check, all RED on `0221f4a8`.
  `message-identity` 41 of 41 and all eight lanes pass; `f202-i002-suites` takes 236 s alone against 600 s.
- **Class closure (round 4)**: finding 1 removes the last approximate match that ignored what the old turn did. Finding 2
  completes the delivered-text rule for every exit of the dispatcher. Finding 3 states the writer contract as code: only
  an explicit non-match returns nothing.
- **Plan effect**: the allowance is spent (4 of 4), and the round-4 fixes are unreviewed. T022, T020, T021, T018 and T019
  reach review only through the maintainer's allowance reset; the review is left paused, not stopped, because stopping
  would sign off an iteration with seven tasks still open.
- **Allowance reset (2026-10-17)**: the maintainer typed `approved for allowance reset` and, after the B4F-127 interim
  check found the stored approval was an older turn-end record (B4F-137), confirmed the go-ahead. Reset
  `reset-7b13db76ba620c12794b` restored the rounds; the next round comes after T019 and covers the round-4 fixes and
  T022, T020, T021, T018 and T019.
- **Round 5 (2026-10-18, the maintainer's typed `approved for review round`, checked typed, fresh and unspent before
  launch)**: run `run-20261018-075433218-7cbe648b` (codex, 29 minutes) reviewed the round-4 fixes, B4F-137 and T018 to
  T022. The engine counts it as round 1 of the restored allowance (1 of 4). 5 findings: 4 reported blocking or major and
  demoted for "no concrete failure scenario" (each states one), 1 reported minor. Each was checked against the code, and
  each is real:
  1. **A quoted menu reached the partial sign-off writer.** T018 left the one-line rule to each recognizer, and the
     partial sign-off's reason runs to the end of the message, so a menu that began with that phrase was saved as an
     override while the disclosure said nothing was approved.
  2. **Reducing a Claude message to its authority line removed a machinery envelope first.** Every writer refuses a
     message that starts with one, but the reduction ran before them: `<hook_prompt>` around `approved for review round`
     recorded a human approval.
  3. **A delegation that named the remaining lenses to exclude them covered them.** "you decide this lens, not all
     remaining lenses" was recorded for every open lens, because the wide form was matched anywhere in the reply.
  4. **Receipts were suppressed by their answer text.** 'skip', 'you decide', 'skip' to one question kept only the first
     skip, so the delegation between them stayed newest and could close the lens after the human's latest skip.
  5. **A period inside a version or a file name ended a reply question.** A reworded question carrying `1.2` lost its
     identifier and was counted missing, and the packet would be rendered again.
- **Resolution (round 5)**, each behind a failing test:
  1. A quoted menu reaches no minting writer; only the withdrawal still runs, since refusing it fails open.
  2. A message with a machinery envelope at the start of any line is not reduced; the writers see it whole and refuse it.
  3. The wide form is the whole reply: the delegation and the remaining lenses, and nothing else.
  4. A held receipt is the same reply only when it carries the same message ID or, where the host gives none, when it is
     still its lens's newest record with the same answer to the same question. A new act gets its own receipt ID.
  5. A period followed by a non-space does not end a question.
- **Tests (round 5)**: `approval-form` 9 new cases (6 RED on `29ac6303`; 3 are controls that prove the fixture holds a
  real sign-off request), `workshop-delegation` cases 8 and 9 (12 checks RED), `presented-check` case 10 (2 RED). The
  first version of fix 4 suppressed too little, and a replayed message became a fourth receipt; case 9's replay check
  caught it before the lanes. The first lane run then caught a replay check that matched on the message ID alone, which the cross-host walk (one recorded host message for every reply) exposed; a replay now matches both the message ID and the answer. All eight lanes pass; `f202-i002-suites` takes 390 s in the parallel run against 660 s.
- **Class closure (round 5)**: findings 1 and 2 are one class, T018's own premise: the form the writers decide on must
  keep every reason to refuse that the message had. Finding 4 closes identity by content for workshop receipts, the
  class T017 closed for authority facts.
- **Round 6 (2026-10-18, the maintainer's typed `approved for review round`, checked typed, fresh and unspent before
  launch)**: run `run-20261018-114927550-9d62a483` (codex, 30 minutes) reviewed the round-5 fixes, T023 and T024. The
  engine counts it as round 2 of the restored allowance (2 of 4). 6 findings: 4 reported blocking or major and demoted for
  "no concrete failure scenario" (each states one), 2 reported minor. Each was checked against the code, and each is real:
  1. **Bulleted alternatives were not counted as options.** An option counted only when its line began with one, so on
     Claude `approved for review round` above `- changes needed: ...` and `- discuss prompt 1` was reduced to its line and
     recorded, and the same bullets let a partial sign-off menu reach the override writer on every host.
  2. **Reducing a Claude message to its approval line dropped a condition typed on the next line.** `approved for review
     round` above `provided the security checks pass` reached the writer with nothing after the phrase, so the condition
     the writer refuses on the same line was never seen and the round was spendable at once.
  3. **A message the host added still reached the approval writers.** The dispatcher labels a replay of the hook's own
     output `host-injected` and an unreadable records check `unknown`; the workshop receipt refused both, while every
     approval writer ran. The prompt-entry boundary approval had the same gap (closed with it).
  4. **After a wide delegation, every confirmed reply was passed over.** A craft answer such as "Do not decide this lens
     for me; I choose a local queue" still let the lens close as delegated, on the older receipt.
  5. **The envelope check ran before pastes were removed.** A pasted log quoting a `<system-reminder>` line hid the reset
     typed below it, and no refusal said so.
  6. **'before' and 'after' were both dropped from a question's meaning.** "Should the migration run before
     deployment?" and "... after deployment?" read as the same question.
- **Resolution (round 6)**, each behind a failing test:
  1. A line's list, quote and number markers and inline marks are removed before it is read as an option.
  2. When the typed text beside the one approval line carries a condition or a reversal, the message is not reduced; the
     writers refuse it as more than one line, and the refusal says so, for a condition above the phrase too.
  3. A message whose origin is not `typed-user` reaches only the withdrawal, which removes authority. An `unknown`
     origin, which may be the human's own typing, is reported in the same turn with the phrase to type again. The
     prompt-entry boundary approval refuses both origins.
  4. The receipt marks a reply that only names the reviewer (a reviewer host or the default) as a reviewer pick, and only
     that reply may stand after a wide delegation.
  5. The envelope check reads the human's own text, outside every paste.
  6. A question that has 'before' (or 'earlier', 'first') where the other has its opposite is a changed question; a
     rewording may still add or drop one, as B4F-128's reply did.
- **Tests (round 6)**: `approval-form` 19 new cases (15 RED on `d8b0a092`; 4 controls, among them the withdrawal that
  still runs whatever the origin), `workshop-delegation` case 10 (4 checks RED; 4 reviewer picks are controls),
  `presented-check` case 11 (2 RED), `verdict-capture-blocks` W45 (8) (RED: the old capture takes no origin at all).
- **Class closure (round 6)**: findings 1, 2 and 5 are T018's premise again, in three more places: the form the writers
  decide on must keep every reason to refuse that the message had - an option in any wrapping, a condition on any line, an
  envelope only where the human typed it. Finding 3 closes provenance for every writer that records authority from a
  prompt, the class FR-006 closed for the workshop receipt.
- **Round 7 (2026-10-18, the maintainer's typed `approved for review round`, checked typed, fresh and unspent before
  launch)**: run `run-20261018-125258950-98a6a63d` (codex, 27 minutes) reviewed the round-6 fixes. The engine counts it as
  round 3 of the restored allowance (3 of 4). 3 findings, all reported major and demoted for "no concrete failure
  scenario" (each states one). Each was checked against the code, and each is real:
  1. **A qualified message still reached the partial sign-off writer.** Round 6 left a qualified message multi-line for
     the writers' one-line rule, but that writer reads everything after its dash as the reason and has no such rule, so
     the condition typed on the next line was saved with the override.
  2. **The coverage deferral kept its own six condition words.** 'continue without coverage until the review phase,
     provided the security checks pass' was saved at once; the shared guard also names provided, assuming, contingent,
     subject to, as long as and pending.
  3. **'Use the default.' was a reviewer pick whatever it answered.** After a wide delegation, that reply to a craft
     question ("Use SQLite or the default in-memory store?") was passed over, and the lens could close as delegated.
- **Resolution (round 7)**, each behind a failing test:
  1. Every reason the approval form gives to refuse (a quoted menu, a qualified message, a host envelope) keeps the
     message from every writer but the withdrawal, in the router, not in each writer.
  2. The coverage deferral uses the shared condition guard, with the same words as its fallback when loaded alone.
  3. A reply that does not itself say "reviewer" or "review" is a reviewer pick only when the open question asks about
     the reviewer.
- **Tests (round 7)**: `approval-form` 4 new cases (all RED on `96b2fc32`: the qualified partial sign-off, and the
  conditional deferral through the message hook on three hosts, each with the bare phrase as its control);
  `round-approval-typed-authority` one matrix case, every shared condition against every recognizer (RED);
  `workshop-delegation` case 11 (2 RED; 2 reviewer-question controls).
- **Class closure (round 7)**: finding 1 is round 6's own fix one step short: a reason to refuse that the form found must
  bind at the one place every writer passes through, which round 5 established for the quoted menu. Finding 2 is the
  fourth copy of the condition rule to drift from the shared one (DRIFT-199-I001-123); the matrix now runs the shared
  list against every recognizer, so a copy cannot drift silently again.
- **Round 8 (2026-10-18, the maintainer's typed `approved for review round`, checked typed, fresh and unspent before
  launch)**: run `run-20261018-163747348-5da84de1` (codex, 29 minutes) reviewed the round-7 fixes. The engine counts it as
  round 4 of the restored allowance (4 of 4; none left). 2 findings, both reported blocking or major and demoted for "no
  concrete failure scenario" (each states one). Each was checked against the code, and each is real:
  1. **The qualified check ran only where the host marks pastes.** On Codex and Copilot, 'approved for partial review
     signoff - the remaining files are documentation' above 'provided the security checks pass' had no reason to refuse,
     so the router let it reach the partial sign-off writer, which reads every line after its dash as the reason, and
     the override was saved with the condition inside it.
  2. **A boundary approval did not take the approval form.** On Claude, 'approved for before-implement' on its own line
     above a paste was refused as a multi-line message, and below a paste was not read as an approval at all, while
     the same act is an approval for a review round (FR-029). Both verdict readers classified the raw message. This
     fails closed (nothing is approved that was not typed), and it costs the human a second, bare reply.
- **Resolution (round 8)**, each behind a failing test:
  1. A condition or a reversal in the typed text beside the one authority line qualifies the message on every host, so
     the router refuses it for every writer but the withdrawal, wherever the host stands on pastes.
  2. Both boundary verdict readers (the prompt with no transcript, and the transcript at the turn end) read the message
     through the approval form for the host. A reason to refuse leaves the message as it came, so every earlier refusal
     still holds; hosts that mark no pastes are unchanged.
- **Tests (round 8)**: `approval-form` the round-7 partial sign-off case now runs on all three hosts (codex and copilot
  RED on `1ef797ba`); `verdict-capture-blocks` W45 (9), seven cases through both readers: the approval above and below a
  paste on Claude authorize, and the same text on Codex and Copilot, an approval only inside a paste, a quoted menu and a
  condition outside the paste do not. Its RED on the old code is a missing-parameter error; a direct probe of the old
  reader shows the behaviour (above a paste: `refused-multi-line`; below: `none`).
- **Class closure (round 8)**: both are the approval form applied in fewer places than its rule covers. Finding 1 is a
  host-independent rule (a condition beside an approval qualifies it) placed inside the host-dependent branch. Finding
  2 is a reader of typed approvals that never passed through the router, which is where T018 put the form; the boundary
  readers now call the same form rather than carrying a copy.
- **Review close (2026-10-18)**: with the allowance spent, the crew recommended `stop the review here` and told the
  maintainer the final check would cover the round-8 fixes. That was wrong, and it is iteration 001's DRIFT-033 again:
  the maintainer typed the stop (checked typed, fresh and unspent), the stop refused at sign-off with
  `latest-result-not-current` because the round-8 fixes were committed after round 8, and the decision was not spent.
  The refusal refreshed the partial sign-off request against the current files; the maintainer typed
  `approved for partial review signoff - <reason>` as the whole message, and the stop, run again with no write between,
  completed: the remaining findings were saved as follow-ups and review sign-off is complete. The round-8 fixes are
  signed off unreviewed by the maintainer's recorded acceptance. Cost: one extra human decision and two long waits,
  for an outcome known when the round-8 fixes were committed (B4F-126, second recurrence). Crew rule from here: when
  fixes land after the last round, the decision brought to the maintainer is the partial sign-off reply, not a stop.
