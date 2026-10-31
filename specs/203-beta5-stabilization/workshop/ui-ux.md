# Lens: ui-ux (medium)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-31.
**Question**: what the human sees at a review stop, a top-up and a refusal; the closing line of every
waiting turn; how the B5F-004 stop-reason audit is run.

## Source of UX truth

No mockups. Three standing rules: the refusal standard (what could not be completed, the answers are
safe, one recovery action, ask for approval; diagnosis to the drift record); 202's principle (a stop
only when the human must decide and lacks the context; never a block over formatting); one decision
per message, in a short packet.

## Agreed layout of a review stop

```text
 Review paused - <the one reason, plain words>                   <- line 1: why
 Round 3 of 3 used; 4 findings fixed; 1 open: F-7 <one line>      <- what happened, counted
 <the one decision you need to make, one sentence>                <- the decision
 Type one of these:                                               <- sendable lines, never numbers,
   <phrase 1>  -> <what happens>                                     each with its consequence
   <phrase 2>  -> <what happens>
```

## Agreed phrases per stop

| Stop | Sendable line | Consequence stated on the line |
| --- | --- | --- |
| (a) budget spent | `approved for allowance reset` | another budget of rounds; the next round starts |
| (a) budget spent | `stop the review here` | the sign-off packet lists what remains uncovered (B4F-058) |
| (b) dispute or defer | `defer finding F-7 to <backlog item or iteration>` | the finding is recorded at the named destination |
| (b) dispute or defer | `drop finding F-7` | the finding is closed as disputed, with the crew's reason |
| (b) dispute or defer | `fix finding F-7` | the crew fixes it; the next round reviews the fix |
| (c) judgment call | free text | the crew acts on the answer |
| (d) host outside order | `allow reviewer <host>` | that host reviews the next round |
| (d) host outside order | `stop the review here` | as in (a) |

`allow reviewer <host>` replaces the proposed `approved for reviewer <host>`, which collides with the
`approved for review...` prefix residue found in architecture-core. A deferral always names where the
finding goes; a deferral without a destination is a silent drop and is not offered.

## Decisions

1. **Layout** as above: why, what happened, the one decision, sendable lines with consequences.
2. **Phrases** as in the table. (b) and (d) are new acts routed by the single classifier; deferral is a
   captured act (no-gap rule).
3. **Hook-block audience (B5F-012).** On Claude Code a Stop-hook block reason IS shown to the human
   (the maintainer read one in full in this session). So crew guidance goes through a non-blocking
   channel (context for the next turn) wherever the host has one, and any text that does block is
   written for a human to read: plain words, no internal codes.
4. **Closing line (B5F-011).** Every turn that waits on the human ends with one line naming what to
   type. The check supplies a missing line and never blocks. Verify per host how a hook can add a
   visible line (Claude: `systemMessage`; Copilot and Codex: to be checked). Where a host can only add
   it by blocking, record a drift entry instead of blocking.
5. **B5F-004 audit.** List every Stop-block and force-continue reason in the hooks; mark each keep
   (protects authority or a needed decision), drop, or convert (to a supplied line or a drift entry).
   The table goes into the spec and the maintainer rules on it at specify.
6. **Refusals.** Every capture and review refusal 203 touches follows the refusal standard, including
   B4F-151 and the budget-ceiling refusal (names the ceiling and where it is set). Diagnosis goes to
   the drift record.

## Bindings

- `review-stop-layout`: `why-what-decision-sendable-lines-with-consequence`
- `reviewer-allow-phrase`: `allow-reviewer-host`
- `deferral-destination`: `required`
- `crew-guidance-channel`: `non-blocking-context-where-available`
- `blocking-text-audience`: `human-plain-words`
- `closing-line`: `supply-never-block-drift-entry-where-host-cannot`
- `stop-reason-audit`: `keep-drop-convert-table-in-spec`
- `refusal-standard`: `applies-to-all-touched-refusals`
