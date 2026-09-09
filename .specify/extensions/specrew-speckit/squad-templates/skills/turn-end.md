# specrew-turn-end

**Namespace**: `/specrew`

End every turn by running the turn-end script. It decides what is rendered; you supply the facts.

```powershell
pwsh -File .specify/extensions/specrew-speckit/scripts/declare-turn-end.ps1 `
    -Kind <boundary|in-flight|conversational> -Summary '<what this turn did>'
```

Output whatever it returns, verbatim. **It may return nothing, and nothing is a complete answer** — a turn
that discussed something and changed nothing owes the human no ceremony.

## Choosing the kind

| kind | when | extra |
| --- | --- | --- |
| `boundary` | the human's judgment decides what happens next | `-Owed '<artifact>'` when the stage owes something it has not produced |
| `in-flight` | background work is still running | `-Pending '<the work>'` — **required** |
| `conversational` | nothing material changed | — |

**`-Owed` matters.** When a stage owes artifacts it has not produced there is nothing to approve, so the
packet renders with no options and no verdict marker and names what is owed instead. Offering an approval
phrase for an empty increment is the thing that rule exists to prevent.

**`-Pending` is required for `in-flight` and only for `in-flight`.** A boundary declaration is checked
against the pending crossing and a conversational one claims nothing, but "work is in flight" is a
statement about the world that no artifact confirms. The least it can be asked for is what, by name. Say
the same thing about the same item on too many consecutive turns and the script stops reporting and starts
asking — waiting is not a report.

## What you do not do

**Do not compose the packet yourself.** The script renders it from the artifacts: the boundary, the
approval phrase and the verdict marker come from `.specrew/runtime/pending-verdict-stop.md`, never from the
phase you intend to enter next.

**Do not skip it because the turn felt small.** The gates decide whether anything is rendered; that is what
they are for. A declaration that earns no output is still recorded, because "the agent declared and nothing
was earned" and "the agent declared nothing at all" look identical from outside and mean opposite things.

## Recording a design decision

A design choice is not a boundary verdict, and they are recorded separately on purpose — one settles what
to build, the other grants permission to proceed:

```powershell
pwsh -File .specify/extensions/specrew-speckit/scripts/record-design-decision.ps1 `
    -FeatureRef <feature> -Key <slug> -Question '<what was decided>' `
    -OptionId '1','2','3' -OptionSummary '<a>','<b>','<c>' `
    -Chosen <id> -Rationale '<why>' -HumanTurn '<the human''s reply, verbatim>'
```

The human's reply opens with **`design decision`** — for example `design decision: option 3 - filters
compose and each is testable alone`. It needs at least two options as they were presented, and the chosen
one must be among them: a choice between one thing is a hand-down wearing a choice's clothes.
