# Lens: ui-ux (medium)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `e1b1537267b85fced970a2ca4d45ab833e9690b951397a6c005614eefb6d0e0d`.
**Question**: what the human sees when state repeats, when owed content is missing, and when capture degrades.

## Governing UX principle for 202 (maintainer, verbatim; ranks above every decision below)

> The human provides intent (problem domain, constraints, limits), reasons with the agents about the solution, and directs and decides. The system analyzes, suggests, recommends, implements, validates, and diagnoses its own failures. The human is in the loop for approvals and on the loop for understanding, but does not run the process. A stop message is justified only when the system needs a human decision to proceed AND the human lacks the context for it. A question gets an answer, not a stop. Unchanged context needs no packet. Needing nothing from the human means no message. The packet's size follows the size of the context gap (new session, resume, compaction, external state change, long gap). Verdicts stay explicit typed replies: the system decides when to ask, only the human decides what is approved.

## Session text surfaces (the diagram shown in the lens)

```
 session timeline (one host, one session)
 ------------------------------------------------------------------------------------------
 SessionStart  ->  first reply                 ->  later turns                -> refusal
               |                               |                              |
               | orientation + dials line      | unchanged pending crossing   | gate / capture
               | MUST precede any question     | B4F-104: packet only after   | cannot proceed
               | B4F-096: today arrives after  |   a context gap; otherwise   | B4F-102: name the
               |   the first lens (backfill)   |   at most a brief mention    |   producing step
               | B4F-106: missing dials line   | degraded capture (latched    | B4F-108: actual
               |   is system-filled, no block  |   marker)                    |   cause, turn-consumed
               | B4F-107: one shared sentence  | B4F-108: disclosed SAME turn |   status, one decision
               |                               |   0 silently consumed turns  | B4F-100: substance
               |                               |                              |   check, no format block
 ------------------------------------------------------------------------------------------
```

## Decisions

1. **Source of UX truth.** The project's refusal standard and the orientation contract, with no new surfaces or message types. A refusal names the actual cause in plain project terms, and the technical detail goes to the drift record. **Amended for degraded states:** the system diagnoses, recovers what it can on its own, and comes to the human only with a decision (for example, "may I move this marker aside?"). The refusal also says whether the human's turn was consumed.
2. **Unchanged pending crossing (B4F-104): decided by context, not frequency.** Neither "nothing" nor "one line every turn":
   - A question from the human gets an answer, not a stop.
   - While context is unchanged, the pending decision is at most a brief mention inside a reply that answers the human.
   - The full packet returns only after a context gap: a new session, a resume, a compaction, an external state change, or a long gap.
3. **The hook never blocks a reply over formatting (B4F-106, B4F-096; strengthened).** The hook checks substance only:
   - When a decision is needed, the reply makes that decision clear.
   - Authority is intact.

   Deterministic text the system fills in, such as the dials line or the orientation facts, is supplied without a human-visible cycle. It is marked as system output and recorded in the hook-output journal. For orientation, acceptance is about order: the human never answers a question before having seen the orientation. The mechanism is chosen at design-analysis.
4. **Dials wording (B4F-107).** One shared prose sentence, identical on every host, for example: "I'll treat you as mid-level on Product Strategy, expert on UX/UI Design, expert on Software Architecture, expert on AI Delivery Planning." Only the reference to the correction command comes from the adapter. Numbers and keys are never shown. B4F-091's band semantics stay in beta5.
5. **The "presented" check (B4F-100).** It compares a set of meaning-bearing lines, declared once in the shared path: headings, review-target links, the question line, the approval line, the **verdict options**, and the marker. It never compares the whole draft, so tightening a sentence never costs a turn.

## The principle applied to Tier 1

| Finding | Under the principle |
|---|---|
| B4F-104 | The packet appears only after a context gap. With unchanged context, the pending decision is at most a brief mention inside an answering reply. No `Stop hook error`. |
| B4F-106 | A missing dials line is filled by the system, marked as system output and journaled. It never blocks the reply, and costs 0 human-visible cycles. |
| B4F-096 | Orientation is the new-session packet and precedes the first question. The system supplies its deterministic facts; it does not demand them after the fact. |
| B4F-107 | One shared sentence on every host. Only the correction command reference comes from the adapter. |
| B4F-100 | A substance-only check over the declared meaning-bearing line set, including the verdict options. A wording change is never a block. |
| B4F-102 | The system names, and where it can performs, the step that produces the missing artifact. It does not stop to ask the human how to find it. |
| B4F-108 | The system diagnoses the latch and recovers a transient failure on its own. It discloses degraded capture in the same turn, says whether the turn was consumed, and asks only for a decision it cannot make (for example, moving the marker aside). It never attributes a reply to a channel the human did not use. |
| B4F-105 | Status resolves the current feature from the evidence and says which one it chose. It asks only when the choice is a genuine human decision. |
| B4F-089 | A resume is a context gap. The resume packet describes the current state from disk, sized to that gap, never a stale narrative. |
| B4F-101 | Drafts go to a fixed, ignored location. This is internal mechanics with no message to the human. |

## Exposed beyond Tier 1: recorded as beta5, not added to 202

- **B5F-004** (docs/beta5-findings.md): Stop-block and force-continue reasons outside the Tier 1 findings have not been audited against the substance-only rule. One example is the material-work turn-end declaration, which force-continues a stop that carries no human decision.
- B4F-039 (mid-clarify packets with no pending crossing) was already beta5. The principle sharpens its target: no packet when the context is unchanged. This is a cross-reference only.

## Bindings

- `ux-governing-principle`: `human-intent-system-runs-process`
- `crossing-repeat`: `context-gap-sized`
- `hook-block-scope`: `substance-only`
- `system-filled-text`: `marked-and-journaled`
- `dials-text`: `shared-sentence-adapter-command-ref`
- `presented-check`: `declared-meaning-lines-incl-verdict-options`
- `degraded-recovery`: `self-recover-ask-decision-only`
- `refusal-turn-consumed`: `disclosed`
