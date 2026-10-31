# Lens: observability-resilience (medium)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-31,
receipt `c69d30bf8669efb511928aa4ae1553a573a52a0fe72deaaf360fbb80ea462571`.
**Question**: journal integrity for B4F-142, capture that survives a compaction (B4F-112), refusals that
say what was looked for and where (B4F-151), and how reviewer token usage is shown in the round result.

## Failure traces (as recorded in the findings)

```text
 B4F-112 - verdict after a compaction            B4F-142 - flush journals a claimed file twice
 ------------------------------------            ----------------------------------------------
 packet with plan->tasks marker                  writer A: lock wait > 1 s -> hash to buffer/x.jsonl
 [compaction summary: user-role entry,           flusher 1: rename x -> .flushing-<g>.jsonl (claim)
  no parent link]                                flusher 2: lists folder, sees the claimed file,
 human: "approved for tasks - ..."                          reads and journals it too
 capture walks back from the reply,              flusher 1: journals it, removes it
  misses the marker, returns the older           => 4001..4005 lines for 4000 appends (Linux only)
  clarify->plan pair as "captured"               nothing on this path records an approval
 => verdict silently not recorded                (it is the hook-output hash journal)
```

## Decisions

1. **B4F-142: exactly-once except crash recovery.** A flusher skips a claim another flusher made moments
   ago and re-flushes only a stale claim (its flusher gone, or past an age bound). The rule is
   exactly-once on the no-crash path. A stale claim re-flushed after a flusher crash may duplicate lines
   the crashed flusher had already written; those duplicates are accepted, because nothing decides on
   this journal. The exact-count stress case (e) covers the no-crash path. Separately, the Linux one-second
   lock wait is measured on CI (how long the lock is held, and by what) before anything about the budget
   changes.
2. **B4F-112: pair against the pending crossing, not the transcript chain.** Capture pairs a
   verdict-shaped reply with the durable pending-crossing record written by the boundary sync. A
   compaction summary is never a human turn (security-compliance). An unpaired verdict-shaped reply is
   reported in the same turn; the fallback to an older pair is removed. A verdict-shaped reply that names
   a different boundary than the one waiting (for example `approved for tasks` while plan waits) is
   reported and records nothing; it is never recorded against the waiting boundary.
3. **No silent "nothing recorded" (B4F-151 and its class).** Every branch that sees an approval-shaped turn
   and records nothing reports it in the same turn with its own reason: form unreadable, writer failed,
   origin unconfirmed, no pending crossing, boundary mismatch. The report says what was looked for and
   where in plain words; the technical diagnosis goes to the drift record. A test drives each branch and
   asserts the report. This keeps measure (c): the report checks the store when it speaks.
   **Channel.** "Told in the same turn" uses ui-ux's visible-line channel. On a host without one, the report
   is a stop that is justified under the 202 rule, because the human must act (re-type). The B5F-004
   audit records it as a **keep**, so the audit does not remove it.
4. **Token usage, display only.** The usage slot is filled from hosts that report it (Claude, Codex;
   Copilot to be checked; Codex's file delivery carries it apart from stdout). The round result shows
   host-reported tokens or "usage: not reported by <host>"; the review sign-off shows the total. Nothing
   is estimated; nothing enforces in 203.
5. **Correlation and what is not logged.** Every authority record, refusal and drift entry carries the turn
   identity; review ones also carry the campaign id, so the walk's records and the measure (b) audit join
   on one key. Raw prompts are not logged. The health line on `specrew status` and `specrew where` shows
   a degraded journal while it lasts, unchanged.

## Rejected alternatives

- Case (e) counting distinct hashes: the test would accept duplicates instead of preventing them.
- Tuning the lock budget before measuring why the Linux lock is held a full second.
- Recording a mismatched verdict against the waiting boundary: it would record an approval for a boundary
  the human did not name.

## Bindings

- `journal-flush-rule`: `exactly-once-except-crash-recovery-duplicates-accepted`
- `journal-stress-count`: `exact-line-count-no-crash-path`
- `linux-lock-wait`: `measure-cause-before-budget-change`
- `verdict-pairing`: `pending-crossing-record-not-transcript-chain`
- `verdict-boundary-mismatch`: `report-and-record-nothing`
- `not-recorded-report`: `every-branch-own-reason-same-turn`
- `not-recorded-channel`: `visible-line-else-justified-stop-kept-in-b5f-004-audit`
- `token-usage`: `display-only-host-reported-per-round-and-total`
- `correlation-key`: `turn-identity-plus-campaign-id`
