# Lens: architecture-core (full)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-30.
**Question**: where review-budget authority lives, how typed acts are captured, what the stop check
decides, the default for a plan without a budget, and when a merged feature's claim is released.

## Shape (drawn from function names; the maintainer answered against it without correction)

```text
 typed human message
        |
        v
 +------------------------------+
 | host adapters (Claude,       |
 | Codex, Copilot hooks)        |
 +------------------------------+
        |
        v
 +------------------------------+   one classifier: each typed turn
 | typed-act capture            |   read once, routed to one act
 | (HumanAuthorityStore +       |   (verdict | top-up | stop answer |
 |  verdict classifier)         |    workshop reply)
 +------------------------------+
    |                |                 |
    v                v                 v
 boundary         allowance reset   workshop
 verdict ledger   (top-up) ->       receipts
    |             budget-reset fact
    | before-implement verdict
    v
 +------------------------------+
 | review campaign facts        |   single grant snapshots
 | grant / reserve / spend /    |   budget_total = plan rounds
 | pause / disposition          |   + reviewer host order
 +------------------------------+
        |
        v
 +------------------------------+   reservation checks
 | campaign orchestrator loop   |   rounds_used < budget_total
 |                              |   BEFORE the reviewer is invoked;
 +------------------------------+   clean -> end; fix needed -> fix, next round
        |
        v  a pause fact only for:
   (a) budget spent   (b) dispute or defer
   (c) judgment call  (d) host outside the approved order
        |
        v
 +------------------------------+
 | Stop check reads pause facts,|   no pause -> no human stop;
 | not tree coverage            |   never outside implement
 +------------------------------+
```

## Decisions

1. **Design method.** Inherit 202's binding: the existing layered hooks (adapters, dispatcher, shared
   engines, stores) plus the review campaign fact store. No new subsystem.
2. **Budget becomes authority by snapshot.** When the before-implement verdict is recorded, the
   boundary sync snapshots the plan's review budget (rounds, reviewer host order) into the campaign
   grant, citing that verdict. The engine never reads the plan live.
   - **2a (B).** The plan's rounds become the campaign's `budget_total`; the verdict is the single
     grant. The one-slot-per-authorization grant (review-campaign-orchestrator.ps1:1731, guard at 1743)
     and the per-round approval that fed it go. The top-up `approved for allowance reset` is the
     existing budget-reset fact, unchanged; it moves the counting origin and grants another
     `budget_total` rounds.
   - **Config fuse.** Kept, but only as a validation bound on the plan's budget, not as a runtime
     counter. A plan budget above the configured ceiling is refused when the plan states it and when
     the before-implement verdict snapshots it; the refusal names the ceiling and where it is set. At
     runtime there is one counter: `rounds_used` against the snapshotted `budget_total`.
3. **One typed-act classifier.** Each typed turn is read exactly once and routed to exactly one act:
   boundary verdict, top-up, stop answer, or workshop reply. The existing stores stay the sinks. This
   removes by construction the `approved for review...` prefix residue (B4F-116/150), the
   latest-turn-only reading (B4F-117), and folding into an older unspent record (B4F-137/140).
4. **The stop check.** It stops for a human only when one of the four pause facts exists, never
   outside implement, and never asks for a round. There is no crew-facing block to make the crew run
   the next round: the review boundary checks coverage, and a stop with no human decision is what
   B5F-004 removes. The round cap is enforced by a reservation taken before the reviewer is invoked
   (the July auto-loop recorded "ceiling reached" for rounds 3-7 past a max of 2 because the check ran
   after the round started).
5. **Plan without a budget (planned before 203).** `budget_total = 0`. The first review meets stop
   (a) at once, and `approved for allowance reset` grants the rounds. One model; no silent default.
6. **Merged feature's claim (B5F-014).** Released when the merge is observed, checked at session start
   and at every boundary sync, with a release record. Not at the closeout approval, which precedes the
   merge.

## Rejected alternatives

- Reading the plan's budget live from the engine: a plan edited after approval would change the budget.
- (A) N-slot grant: two counters (slots and fuse) that can disagree; the top-up needs two writes.
- Config fuse as a runtime ceiling: brings back the two-counter problem.
- Per-round approvals kept for legacy plans: two models side by side.
- A crew-facing block to force the next round: a stop with no human decision.
- Claim release at the closeout approval: frees the claim of a feature whose PR is never merged.

## Bindings

- `decomposition-style`: `existing-layered-hooks-plus-campaign-facts`
- `review-budget-source`: `plan-snapshot-at-before-implement`
- `review-grant-model`: `single-grant-budget-total`
- `review-config-fuse`: `plan-validation-bound-only`
- `review-runtime-counter`: `rounds-used-vs-snapshot-budget-total`
- `round-cap-enforcement`: `reservation-before-invocation`
- `typed-act-capture`: `single-classifier-one-act-per-turn`
- `top-up-phrase`: `approved-for-allowance-reset`
- `review-human-stops`: `budget-spent-dispute-defer-judgment-host-outside-order`
- `crew-next-round-block`: `none`
- `no-budget-plan-default`: `zero-rounds`
- `reviewer-host-order`: `codex-copilot-claude`
- `claim-release`: `on-observed-merge-session-start-and-sync`
