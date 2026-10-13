---
name: "specrew-turn-end"
description: "Record turn completion and verify the agent-authored reply. Triggers: turn end, stop, packet, in flight, boundary packet, declare-turn-end, record a design decision."
domain: "lifecycle-governance"
confidence: "high"
source: "Specrew turn declaration and agent-authored presentation contract."
---

# specrew-turn-end

**Namespace**: `/specrew`

The script is the **last tool call**, and its return is **for you, never your reply**. You author the
human-facing question, complete agenda, answer or boundary packet. Save the draft before the last call:

```powershell
pwsh -File .specify/extensions/specrew-speckit/scripts/declare-turn-end.ps1 `
    -Kind <boundary|in-flight|conversational> -Summary '<what this turn did>' `
    -MessagePath <utf8-draft-file> -Token <the token from the latest [specrew-turn] line>
```

Then send the authored content in your own message. Ordinary declarations emit no human-facing text.
At a boundary the script verifies the draft and supplies only a missing machine-derived approval line
and/or marker. Incorporate those into your packet, with the marker last. Stop checks that the prepared
content actually reached your reply; a tool result alone is not presentation.

## The token

At the start of each turn the hook hands you one line beginning **`[specrew-turn]`** carrying this turn's
token. Pass the **most recent** one as `-Token`. It is how the declaration is placed under the session
that is actually making it: the hook that issued the token is the hook that judges the record, and with
two sessions working in one project nothing else can tell them apart. The hook consumes the token when the
turn ends, so an earlier turn's token is no longer live and is refused by name.

Without `-Token` the script accepts exactly one live token and refuses more than one, naming each session
and the parameter. A token left behind by a session that crashed shows up in that refusal with its path and
issue time; if you know that session is gone, its token file can be removed.

## Choosing the kind

| kind | when | extra |
| --- | --- | --- |
| `boundary` | a lifecycle stage is ready for the human's verdict | `-Owed '<artifact>'` when the stage owes something it has not produced |
| `in-flight` | background work is still running | `-Pending '<the work>'` — **required** |
| `conversational` | an answer or a workshop question awaits the human | `-MessagePath` carries the authored reply |

**`-Owed` matters.** When a stage owes artifacts it has not produced there is nothing to approve, so the
packet renders with no options and no verdict marker and names what is owed instead. Offering an approval
phrase for an empty increment is the thing that rule exists to prevent.

**`-Pending` is required for `in-flight` and only for `in-flight`.** A boundary declaration is checked
against the pending crossing and a conversational one claims nothing, but "work is in flight" is a
statement about the world that no artifact confirms. The least it can be asked for is what, by name. Say
the same thing about the same item on too many consecutive turns and the existing Stop gate asks you to
explain what remains pending and what should happen next.

## Authorship and declaration

**Author the packet yourself.** Include the six Rule 46 sections, specific review targets, a
recommendation and the next step. The pending crossing supplies the approval line and marker; you never
infer them from your intended next phase. A missing-artifact packet names what is owed and the step you
will perform, and offers no approval or marker. Opening orientation is yours, once; turn-end never repeats
it. The orientation gate supplies only an absent dials line.

**Declare small turns too.** A declaration with no output still records the turn and its session identity.
Your reply remains your responsibility.

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
