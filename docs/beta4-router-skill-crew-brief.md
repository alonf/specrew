# Brief for the router-skill crew - read BEFORE beta4 is installed on that machine

**One page. It is operational, not background.** Hand this over with the build.

## PRE-FLIGHT - run this before the crew starts, not after

**ASK THE MACHINERY, not a proxy.** An earlier draft of this brief scanned for features whose specification
still carried the unauthored scaffold marker. **That check is scoped to INTAKE workshops and answers the
wrong question for a crew resuming technical lenses** - it returned zero for a project with a live workshop.
It has been replaced.

```powershell
. '<specrew-repo>\scripts\internal\bootstrap\ProjectMetadataAccessor.ps1'
Get-ChildItem specs -Directory | ForEach-Object {
    $s = Get-SpecrewWorkshopLifecycleState -ProjectRoot (Get-Location).Path -FeatureRef $_.Name
    '{0,-34} status={1,-9} reason={2}' -f $_.Name, $s.status, $s.reason
}
```

**Exactly one feature must report `status=active`.**

- **Exactly one active** - that is your workshop. Its `current_lens` names where it resumes. Proceed.
- **More than one active** - **stop.** The resolve cannot tell which workshop a typed reply belongs to and
  refuses as ambiguous rather than guessing.
- **None active** - **stop, and read the `reason`.** It names the condition. It does not mean the project is
  empty; it usually means a controller is in a state the resolve rejects.

**Why it is a pre-flight and not a troubleshooting step**: none of these fail loudly. They make the resolve
refuse, and **the refusal reaches the journal rather than you** (B4F-012). You would experience it as the
workshop simply not advancing.

### KNOWN BLOCKER IN THIS PROJECT - read before starting

At the time of writing, `001-agentic-architecture-skills` reports:

```
status=invalid   reason=workshop-record-not-selected
```

**Cause, verified at source.** `ProjectMetadataAccessor.ps1:602` invalidates a controller when any workshop
record names a lens that is not in `selected`. This controller has `workshop: { product-domain }` while
`selected` holds the eight technical lenses - and **the technical agenda deliberately excludes
`product-domain`** (DRIFT-199-I003-079). So the record and the selection cannot both be right, and the
accessor rejects the whole controller.

**Where it came from**: the `product-domain` entry was restored by re-running the lens writer, the repair
DRIFT-199-I003-092 examined and concluded was unnecessary - the Casio walk left the same clearing alone and
closed five lenses. **That entry's conclusion was right and the repair had already happened.**

**This is NOT beta4's defect and beta4's fix does not clear it.** The workshop will not resume until the
controller is valid. **Hand-editing `lens-applicability.json` is forbidden**, and the sanctioned repair
(`repair-workshop-controller-state.ps1`) covers pre-agenda state only and declines past it
(DRIFT-199-I003-093). **Raise it rather than working around it.**

## What changes for you

Beta4 fixes the defect that stopped the router-skill workshop advancing past its first technical lens. The
workshop resolve now finds the feature whose intake controller is actually open, so **question registration
works and receipts mint.**

That is the fix. **The consequence below is the part that needs a change in how you work.**

## The rule that matters, and it has TWO halves

**Once beta4 is installed, EVERY typed message binds to the pending question.** Verified at source:
`scripts/internal/bootstrap/HandoverStore.ps1:1101` writes the workshop receipt on **any non-whitespace user
message**, with no inspection of its content. **There is no redirect-shaped reply that escapes it.**

### Half one - to CONFIRM a lens

**The immediate next message must be `move on` and nothing else.** Eight lenses, eight replies, no chatter
between presentation and reply.

### Half two - to CHANGE or QUESTION a lens, and this is the dangerous half

**Do not type the correction into the lens-closing turn.** If you disagree with a presented lens and type
the disagreement there, **that correction mints a receipt exactly as an agreement would**, and a checkpoint
that reads a present receipt as the close will record the lens as closed **against your objection**.

**The safe path for a disagreement:**

1. **Raise it before the lens is presented for closing** - during the discussion, while the lens is being
   worked. That is the cheap moment and it costs nothing.
2. **If it is already presented, stop the lens-closing exchange rather than answering into it.** Say plainly
   that this is a redirect and not a confirmation, and that the lens stays open.
3. **Settle it outside the exchange, then have the lens re-presented** and confirm it with `move on`.

**And the crew's half of the same rule**: a receipt's existence is **not** permission to close a lens. If
the human's reply was a question, a correction, or an aside, **do not cite that receipt** - re-present the
lens instead. The receipt id is the evidence trail for a confirmation that actually happened; it is never
the confirmation itself.

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
