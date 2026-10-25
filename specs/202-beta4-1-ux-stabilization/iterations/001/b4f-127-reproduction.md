# B4F-127 reproduction: one typed approval recorded more than once

Scratch reproduction, 2026-10-16, run outside the worktree against this branch's deployed hooks. It drives the real
dispatcher with Claude-format hook payloads and a synthetic transcript. It is input for iteration 002's first item;
nothing here is fixed in 202 (DRIFT-034).

Citation abbreviations, relative to the repository root:

- HAS = `scripts/internal/bootstrap/HumanAuthorityStore.ps1`
- HS = `scripts/internal/bootstrap/HandoverStore.ps1`
- CCA = `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`
- REV = `scripts/specrew-review.ps1`
- WAS = `extensions/specrew-speckit/scripts/workshop-authority-store.ps1`
- SG = `extensions/specrew-speckit/scripts/shared-governance.ps1`

Line numbers are at `7f6d2e39`.

## Summary

1. **Confirmed, and worse than suspected.** One typed `approved for review round` is recorded once when the message
   arrives (UserPromptSubmit) and again at the turn end (Stop) of the same turn. When the transcript is longer than
   500 lines, it is recorded again at every turn end with no human message: 2 records with a small transcript, 6 with
   a large one. The correct count is 1.
2. **Root cause.** The turn-end path's `turn_id` hashes in its own source event, a sliding tail-window index and an
   always-empty arrival time. So it never matches the message-received identity and changes at every turn end. The
   writers also rewrite a spent record as a fresh unspent one (HAS:733-740, HS:1758-1763, CCA:159/920/952,
   HAS:630-636).
3. **Spendable.** Once the approval is spent, the next turn end writes a fresh unspent
   `pending-round-approval.json` (`source_event=Stop`). An agent's `--approve-round` or `--pause-choice 1` accepts it
   (REV:1109, 1166-1169), so a second review can start with no new human message.
4. **Also affected.** The allowance reset (HAS:1832) behaves the same, and the guard for a reset that already landed
   misses it. The stop-here pause decision (HAS:1233) re-binds to a newer pause the human never saw, and stopping
   here can complete sign-off. Coverage deferral (SG:7938) is affected too, by reading the source.
5. **Not affected.** The partial sign-off override, workshop receipts and workshop repair accept only the
   message-received path. Stage approvals are bound to one pending stage, so a second copy finds nothing pending
   (HS:1045-1051, 1159).
6. **The double-record check cannot decide.** It runs after the writers (HS:1292-1308), and it matches identical text
   across the whole ledger (HAS:827-861), so its `prior_turn_id` points to August (2026-08-26 and 2026-08-30 in this
   worktree's ledger).

## The two paths, `turn_id`, and the ledger

**Message-received path (UserPromptSubmit).** HS:1417-1426 calls `Invoke-SpecrewTypedAuthorityCapture` with
`-SourceEvent UserPromptSubmit -TurnPosition 'prompt-entry' -TurnArrival $NowUtc`, the hook's own clock. No session
id is passed, although `Update-SpecrewRollingHandover` has `-SessionId` (HS:1341).

**Turn-end transcript path (Stop; HS:1701-1768).**

- It parses the transcript tail (HS:1745) and walks back to the newest turn that
  `Test-SpecrewTurnIsHumanVerdictEvidence` accepts (HS:1749-1750). That check rejects isMeta entries and envelopes
  (CCA:92-126, 918-920).
- It calls the same router with `-SourceEvent 'stop-transcript' -TurnPosition $rat -TurnArrival $ratArrival`
  (HS:1758-1763).
- `$rat` is the turn's index within a tail of at most 500 lines or 2 MB (CCA:136-137, 159, 970, 984).
- `$ratArrival` reads a `timestamp` property that parsed turns never carry (CCA:920 and 952 return only role, parts
  or text, and verdict evidence), so it is always empty.
- The comment at HS:1753-1757 says the index is stable because the transcript is append-only. For a tail window,
  that is false.

**Identity.** `Get-SpecrewTypedTurnIdentity` (HAS:710-741) is sha256(Host | SourceEvent | TurnPosition |
TurnArrival | h(text)). Because SourceEvent is in the hash, the two paths can never produce the same id. In the
scratch runs, the turn-end ids map to positions 497, 495, 493, 492 and 490, with an empty arrival each time.

**How `exhausted-turns.jsonl` is consulted.**

- `Test-SpecrewTypedTurnExhausted` (HAS:748-825) matches on `turn_id` only (HAS:820). The W71 ruling makes this
  same-channel only (HAS:761-780).
- The router writes a reservation row first (HS:1244-1253), offers the text to every writer (HS:1255-1277), then
  writes a row naming the writers that recorded something (HS:1310-1317).
- Every turn end with a new id appends a reservation row. This worktree's ledger has 2442 rows, of which 71 record an
  approval.

**Why the double-record check records but cannot block.**

- It runs after the writer loop (HS:1292-1308), when the approval already exists.
- `Get-SpecrewCrossChannelMint` (HAS:827-861) returns the first row in the whole ledger with the same content hash,
  the same host, a non-empty writer list and the other channel (HAS:849-855). There is no session, time window or
  message identity.
- Its own comment says it "does not gate anything" (HAS:828-830).
- The writer comment at HAS:626-629 says a re-offer never reaches the fresh-write branch. That holds only within one
  channel and one window position.

## Harness and results

The harness is a git-initialised scratch project with this branch's runtime copied in. A driver invokes the deployed
dispatcher with the worktree's Claude host binding and a Claude JSON payload on stdin, with `CLAUDE_PROJECT_DIR` and
the working directory set to the scratch project. The steps are:

- (a) the human phrase appended, then UserPromptSubmit;
- (b) assistant text, then Stop;
- (c) an isMeta Stop-hook feedback entry and assistant text, then Stop;
- (d) a queue-operation task notification and assistant text, then Stop;
- (e) the engine spends the approval, then Stop;
- (f) another isMeta entry, then Stop. For the pause case, a new pause `run-0002` is made pending first.

"Small" means 2 earlier transcript lines, and "large" means 620, past the 500-line window.

| Scenario | Approvals per step (a to f) | Total (correct: 1) | Spendable at the end with no new human message? |
| --- | --- | --- | --- |
| Round, small | 1, 1, 0, 0, 0, 0 | 2 | No: at (b) the first record was unspent, so no new file |
| Round, small, spent inside the turn (the 10-15 shape) | 1, 1 (fresh unspent, Stop-sourced), 0, 0, 0, 0 | 2 | **Yes** |
| Round, large | 1, 1, 1, 1, 1 (fresh after the spend), 1 | 6 | **Yes** |
| Allowance reset, small | 1, 1, 0, 0, 0, 0 | 2 | No |
| Allowance reset, large | 1, 1, 1, 1, 1 (fresh), 1 | 6 | **Yes**; the landed-reset guard returned nothing |
| Pause decision, small | 1, 1, 0, 0, 0, 0 | 2 | No |
| Pause decision, large | 1, 1, 1, 1, 1 (fresh, empty run), 1 (re-bound to `run-0002`) | 6 | **Yes, for `run-0002`** |
| Partial sign-off override, large | 1, 0, 0, 0, 0, 0 | 1 | Turn ends wrote reservation rows only |

Every turn end that recorded an approval also wrote a double-record row, which prevented nothing.

**Field corroboration (this worktree's ledger, UTC).**

- Round approval: 10-14 typed 17:30:41, turn ends 17:33:49 and 17:34:32; 10-15 typed 10:28:30, turn end 10:29:18.
- Allowance reset: 10-16 typed 00:19:36, turn end 00:20:17.
- Pause decision: 10-16 typed 02:51:58, turn end 03:12:34; 10-16 typed 14:26:00, turn ends 14:26:34 and 14:27:04.

**The paste case.** The turn-end path offers only the newest human turn and stops after it (HS:1749-1764). A later
paste becomes that turn, matches no phrase, and gets only a reservation row.

**Root cause, in order of weight.**

1. The turn-end identity is not shared with the message-received one (HAS:733-740, 820), so the turn end of the same
   turn always records again. W71 accepted this as "at most two".
2. The turn-end identity is not stable: a sliding index and an empty arrival (CCA:136-137, 159, 920, 952;
   HS:1745-1763). So "at most two" is false in any session longer than 500 lines.
3. The writers short-circuit only while the existing record is unspent (round HAS:630-636, allowance HAS:1863-1868,
   pause HAS:1278-1281), so a re-offer after the spend creates a new spendable approval.

## What uses up `pending-round-approval.json`

- REV:1109-1110: a round approval is requested by `--approve-round`, or by `--pause-choice 1` / fix-and-continue.
- REV:1166-1169 reads `Get-SpecrewReviewRoundApprovalAuthorization` (HAS:966-1005). That reader checks shape, hash,
  recognizer, `spent_at` and withdrawal. It does not check the source event, the evidence source or the message
  identity, so the record written at turn end passes.
- The "already delivered" guard (REV:1369-1399) joins on `minted_ref`, which is empty on a fresh record (HAS:609), so
  it does not fire.
- Delivery spends the record (REV:1746-1762, `Complete-SpecrewReviewRoundApprovalAuthorization` at HAS:1647).

So an unspent turn-end approval lets an agent start a second review with no new human message, and the harness
confirms the reader returns it.

## Per approval kind

**Review round** (HAS:559-648). Both paths record it (Stop accepted at HAS:573-582), and a new spendable approval is
written after a spend (HAS:630-642). The partial-override writer also spends it (HAS:205-216).

**Allowance reset** (HAS:1832-1876). Both paths record it (HAS:1844-1847), and a new spendable approval is written
(HAS:1863-1872). It is used at REV:930 through `Get-SpecrewAllowanceResetAuthorization` (HAS:1878), which has no
source or identity check. `Get-SpecrewLandedResetForAllowanceCapture` (HAS:1938-1975, used at REV:940-956) retires a
record only when a reset landed at or after its time (HAS:1969). The turn-end copy is later than the reset, so it is
skipped. Spending it replenishes the allowance again and answers the pending pause as fix-and-continue
(REV:982-1011).

**Partial review sign-off override** (HAS:91-218). Only the message-received path and PreInvocation are accepted
(HAS:21-30, 102-103). It is bound to a request id derived from the tree and the campaign, written with CreateNew,
and an existing fact is returned (HAS:43, 172-202). The reader requires the message-received source (HAS:242-243).
Measured: one record only.

**Stop-here pause decision** (HAS:1233-1288). Both paths record it (HAS:1245-1248). The run it binds to is taken from
whichever pause is pending at turn end (HAS:1112-1189, 1257), not when the human typed. Once the human's own pause is
answered it is excluded (HAS:1168), and the re-offer is unbound. If a later round pauses while that phrase is still
the human's last message, the next turn end binds it to the new pause. Measured: `stop-here.json` with
`source_event=Stop` and `run_id=run-0002`, and `Get-SpecrewPauseDecisionAuthorization -RunId run-0002` returned it.
It is used at REV:1607 and spent at REV:1689 and 1715. Stopping here can complete sign-off (HAS:1194-1199), so this
is the highest-consequence case.

**Workshop receipts** (WAS:838-990). The writer is called only on the message-received path (HS:1427-1428,
1441-1444), and it refuses other events (WAS:855-856) and origins other than typed-user (WAS:880-889). Receipts are
bound to the open question by receipt id. Workshop repair (WAS:204-260) is also message-received only (WAS:216-218)
and bound to a proposal id (WAS:229-230).

**Stage approvals** (HS:993-1167) are bound. An authorization is written only while a stage approval is pending and
the captured from/to equal the pending from/to (HS:1045-1051). A stale identity is refused (HS:1104-1124).
Authorizing advances the cursor (HS:1135-1139), and a second copy finds nothing pending (HS:1159) or a cursor
mismatch (HS:1146-1156).

**Coverage deferral, from the source only** (SG:7938-7984). It accepts Stop (SG:7951-7954) and writes
unconditionally (SG:7976-7978). Each write takes the tree at deferral from the current state (SG:7961, 7972), so a
turn-end re-offer re-binds the human's deferral to source that moved after they typed, which defeats SG:7969-7971.
Withdrawal is offered on both paths too, but a repeat only revokes, so it is harmless.

## Fix shape

**Where the message identity is available.**

- Turn-end path: each Claude transcript entry has `uuid`, `sessionId` and `timestamp`, and the parser drops them
  today (CCA:920, 952). Carry them through, and pass the uuid and timestamp at HS:1758-1763 instead of the tail index.
  That removes the window drift.
- Message-received path: the Claude payload has `session_id`, `transcript_path`, `cwd`, `hook_event_name` and
  `prompt`, but no message uuid (dispatcher field map, `specrew-hook-dispatcher.ps1`:647-650). `session_id` reaches
  `Update-SpecrewRollingHandover` (HS:1341) but is not passed to the capture (HS:1424-1426).
- Open question, not probed: is the human entry already in the transcript when UserPromptSubmit fires? If yes, bind
  that path to the entry's uuid directly. If not, it writes a claim {session_id, content hash, arrival}, and the first
  turn end binds the claim to the uuid of the latest human entry with the same session and text, within a small
  timestamp skew.

**Changes.**

1. Key the ledger on (host, session_id, entry uuid). Drop the source event from the identity hash (HAS:733-740), and
   add `session_id` and `entry_uuid` fields (HAS:926-964).
2. Before any writer runs, the turn-end path does nothing if the entry uuid is already recorded, or binds the
   matching message-received claim instead.
3. Replace the after-the-fact observation (HS:1292-1308) with that check before the writers. Keep a diagnostic row
   scoped to session and uuid, not to all-time text.
4. Defence in depth: approvals carry `entry_uuid`, and the writers treat a spent record with the same uuid as final
   (HAS:630, 1863, 1278).
5. The pause decision binds the pause pending at the entry's timestamp, not at turn end. Coverage deferral writes
   once per uuid and freezes its tree.
6. Optional: turn off the turn-end path's approval writers on hosts whose message-received hook delivers the prompt
   text, which Claude does (HS:1704-1707).

## Failing-test outline

To go in `tests/unit/round-approval-typed-authority.tests.ps1`, which already drives
`Update-SpecrewRollingHandover -Source Stop`:

```text
Describe 'One typed approval message, then N turn ends with no human message, records exactly one approval'
  BeforeEach: temp git project; temp Claude transcript; an entry helper (uuid, parentUuid, timestamp, sessionId)
  It '<Kind> <Size>: message received + 4 turn ends -> exactly 1 recorded approval'
     cases: round small; round large (620 filler lines); allowance large; pause large (pending run-0001)
     prefill; add the human entry; Update-SpecrewRollingHandover -Source UserPromptSubmit -LastUserMessage <phrase> -SessionId s1
     for each of (assistant) (isMeta feedback + assistant) (queue-operation + assistant) (assistant):
        append; Update-SpecrewRollingHandover -Source Stop -TranscriptPath <tp>
     recorded approvals | Should -Be 1
  It '<Kind>: spent before the first turn end -> nothing spendable after 3 more turn ends'
  It 'pause: a decision for run-0001 is never bound to a later run-0002'
  It 'a genuine retype (a new entry uuid) -> exactly 2 approvals'   (guards against wedging)
  It 'a host with no prompt text at message-received: the turn end records once, later turn ends nothing'
```

Against the current code, the first two cases fail, with totals of 2 and 6 and approvals that stay spendable. The last
two should pass today, and they guard the fix.
