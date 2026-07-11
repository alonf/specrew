# Authorization Ledger Audit (DEC-198-GOV-001 follow-up)

**Schema**: v1
**Audited**: 2026-07-11
**Scope**: all 12 verdict_history entries remaining after the DEC-198-GOV-001
surgery, each matched against the session transcript (read-only; no entry
altered, per maintainer instruction with the retro approval)
**Method**: scripted extraction of every assistant boundary-packet marker and
every genuinely human-typed turn (hook feedback, tool results, and injected
system text excluded) from the host transcript; each ledger entry paired with
the packet it references and the keystroke that answered that packet.

## Determinations

Legend — **valid**: the human's keystroke answered exactly that boundary's
rendered packet; capture was merely late. **valid-decision / premature-record**:
the entry was written by the pending-artifact fallback BEFORE the human had
seen that boundary's packet (riding a stale earlier keystroke — the same
defect mechanism as the removed fabricated entry), but the human's next
keystroke afterwards genuinely approved that exact boundary; the ratifying
keystroke was then swallowed as a duplicate by the idempotence guard. The
DECISION is the human's in every such row; the RECORD's timestamp and
evidence pairing are defective.

| # | Boundary | Recorded (UTC) | Evidence source | Matching human turn (UTC, text) | Verdict recorded | Determination |
| - | -------- | -------------- | --------------- | ------------------------------- | ---------------- | ------------- |
| 0 | intake -> specify | 07-09 19:43:59 | marker-bound | 19:37:00 "1" (answered the 19:29 specify packet) | approved for specify | valid |
| 1 | specify -> clarify | 07-09 19:44:40 | fallback | packet rendered 19:44:38 — recorded 2s later riding the stale 19:37 "1"; ratified 20:34:21 "1" | approved for clarify | valid-decision / premature-record |
| 2 | clarify -> plan | 07-09 22:34:49 | marker-bound | 22:23:38 "1" (answered the 20:39 clarify->plan packet) | approved for plan | valid |
| 3 | plan -> tasks | 07-09 22:40:15 | fallback | packet rendered 22:40:13 — recorded 2s later riding the stale 22:35 "1"; ratified 22:44:43 "1" | approved for tasks | valid-decision / premature-record |
| 4 | tasks -> before-implement | 07-09 22:48:48 | fallback | packet rendered 22:48:46 — recorded 2s later; ratified 22:49:47 "1" | approved for before-implement | valid-decision / premature-record |
| 5 | before-implement -> review-signoff | 07-10 18:37:09 | marker-bound | 18:32:46 "1" (answered the 18:21/18:22 signoff packet) | approved for review-signoff | valid |
| 6 | review-signoff -> retro | 07-10 18:37:39 | fallback | packet rendered 18:37:37 — recorded 2s later; ratified 19:57:59 "1" | approved for retro | valid-decision / premature-record |
| 7 | retro -> iteration-closeout | 07-10 20:02:08 | fallback | packet rendered 20:02:06 — recorded 2s later; ratified 21:22:42 "1" | approved for iteration-closeout | valid-decision / premature-record |
| 8 | iteration-closeout -> plan (cycle reset) | 07-10 22:01:56 | marker-bound | 21:28:38 "1" (answered the 21:27 cycle-reset packet) | approved for plan | valid |
| 9 | plan -> tasks | 07-10 22:03:29 | fallback | packet rendered 22:03:27 — recorded 2s later riding the 21:35 "1" that had answered a DIFFERENT packet; ratified 23:38:17 "1" after the human's "before approving the tasks, will we fix these findings?" exchange | approved for tasks | valid-decision / premature-record |
| 10 | tasks -> before-implement | 07-10 23:33:51 | marker-bound | 21:35:24 "1" (answered the 21:33 tasks->before-implement packet); re-confirmed 2026-07-11 00:00:40 "1" against the 23:42 re-render | approved for before-implement | valid (decision given twice) |
| 11 | before-implement -> review-signoff | 07-11 10:45:08 | marker-bound | 10:37:26 "1" (answered the 10:28 signoff packet) | approved for review-signoff | valid |

Removed before this audit (DEC-198-GOV-001): review-signoff -> retro,
recorded 07-11 10:45:40 via fallback, riding the Stop hook's own blocking
feedback while the human's actual reply was a send-back — **invalid,
fabricated**; excised by maintainer-approved surgery with a full-identity
precondition.

## Mechanism finding (sharpens FR-041..FR-043)

The correlation is total: **6 of 6 marker-bound entries are sound; 7 of 7
fallback records (6 surviving + the removed fabrication) were written before
the human had answered the packet in question.** The fallback fires during
the stop cycle that RENDERS a new boundary packet (~2 seconds after render)
and pairs the freshly computed pending crossing with the newest prior human
turn — with **no check that the human turn postdates the packet render**. A
stale keystroke (six cases) or a machinery turn misread as human (the
fabricated case) satisfies it every time.

Consequences carried into iteration 003 (T030-T033):

- FR-041/FR-042 fixtures must include the **temporal-ordering guard**: a
  candidate verdict turn must POSTDATE the packet whose boundary it
  authorizes, in addition to machinery-turn exclusion and tokenizer
  tightening.
- FR-043's regression set gains the six premature-record sequences above as
  fixture shapes (stale-keystroke variant), not only the machinery-turn
  variant.
- A secondary defect: each later genuine ratifying keystroke was swallowed
  by the same-cursor idempotence no-op, leaving the defective early record
  as the ONLY evidence. The FR-044 correction door should support annotating
  such records (first natural use of append-style invalidation/correction).

## Conclusion

No unresolved authorization uncertainty remains: every boundary decision in
the surviving 12 entries was genuinely made by the human (11 with a direct
packet-answering keystroke; 6 of those recorded prematurely but ratified by
the human's next keystroke for that exact boundary; entry 10 confirmed
twice). No entry requires alteration; the six premature records are
candidates for FR-044 correction annotations once the designed door exists —
each would need its own explicit human decision, none taken here.
