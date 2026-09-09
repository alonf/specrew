# Brief for the router-skill crew - read BEFORE beta4 is installed on that machine

**One page. It is operational, not background.** Hand this over with the build.

## What changes for you

Beta4 fixes the defect that stopped the router-skill workshop advancing past its first technical lens. The
workshop resolve now finds the feature whose intake controller is actually open, so **question registration
works and receipts mint.**

That is the fix. **The consequence below is the part that needs a change in how you work.**

## The rule that matters: eight lenses, eight replies, no chatter between presentation and reply

**Once beta4 is installed, every typed message binds to the pending question.**

When a lens is presented for closing, the maintainer's **immediate next message must be `move on` and
nothing else.**

A clarifying question typed in between **mints a receipt the checkpoint would cite as confirmation.** The
receipt is not wrong about anything it records - a typed turn did occur while that question was projected -
but it cannot tell that the turn was a question rather than an answer, and nothing downstream can either.

**So: eight lenses, eight replies, no chatter between presentation and reply.** Ask anything you need
*before* the lens is presented, or *after* it is closed.

## Why - and what a receipt actually proves

**A receipt proves that a typed turn occurred against a projected question. It does not prove the reply
answered it.** `human-confirmed` on a lens is evidence of a *turn*, not of *assent*, and the record cannot
distinguish them.

This was measured, not theorised: during beta4's development, **five `human-confirmed` / `lens-question`
receipts were minted for a `product-domain` lens whose question was never asked.** All five came from
code-review messages. They validate identically to five minted from real answers.

Full record: `docs/beta4-findings.md`, B4F-011.

## Expect more of this kind during your eight-lens re-close

**A block upstream hides every defect downstream of it, and they surface together when the block is lifted.**
Beta3 could not project a question at all, so nothing downstream of registration has ever run on real work -
only on this development tree's review traffic.

**Your re-close is the first time the downstream path runs on a genuine workshop.** Treat anything surprising
in receipts, lens checkpoints or confirmations as expected new visibility rather than a new regression, and
record it before working around it. Full statement: `docs/beta4-findings.md`, B4F-013.

## If a lens refuses to close

Do **not** re-run the lens writer to repair controller state, and do **not** hand-edit
`lens-applicability.json`. The sanctioned repair (`repair-workshop-controller-state.ps1`) covers pre-agenda
state only and will decline past that point - it is inapplicable, not destructive. Stop and report the
refusal text rather than retrying; each retry is another turn, and turns are what mint receipts.
