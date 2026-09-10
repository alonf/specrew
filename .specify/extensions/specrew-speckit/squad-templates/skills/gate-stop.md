---
name: "specrew-gate-stop"
description: "Perform a Specrew human-verdict boundary stop on the Claude host. Renders the FULL Rule 46 six-section human re-entry packet AND the verdict options as one Markdown message, with the AskUserQuestion picker disabled so the packet cannot collapse into the picker's short header/option fields. Invoke at EVERY human-judgment boundary stop (specify, clarify, plan, tasks, before-implement, implement, review, retro, feature-closeout, lifecycle-end). Triggers: boundary stop, verdict, approve / redirect / send back, why I stopped, human re-entry packet, gate stop."
domain: "lifecycle-governance"
confidence: "high"
source: "Specrew Feature 165 — on the Claude host the AskUserQuestion picker collapses the Rule 46 six-section packet into its short fields (the human is asked to approve what they cannot read; proven gameable even under a runtime hook-deny that the model satisfied by rewording the menu). disallowed-tools removes the picker for the stop, so the packet has nothing to collapse into and renders as prose. The design-workshop skill now applies the same Claude-only capability guard for workshop questions; clarify questions remain unaffected."
host-scope: claude
disallowed-tools: AskUserQuestion
---

# specrew-gate-stop

**Type**: Lifecycle-Governance Skill
**Schema**: v1
**Status**: Active boundary-stop renderer (Claude host)

## Purpose

You have reached a Specrew **human-verdict boundary stop**. On the Claude host the `AskUserQuestion`
picker **collapses** the Rule 46 packet into its short header/option fields, so the human is asked to
approve something they cannot read. This skill removes that failure mode: while it is active the
`AskUserQuestion` tool is **disallowed** — you have no picker to collapse into, so you MUST render the
stop as a Markdown message. The design workshop is governed by its own skill, which independently
removes the same unsafe picker on Claude and uses typed prose choices. Clarify questions are not
boundary stops and keep the picker. Only boundary **verdict** stops route through this skill.

## What to render — one command, its output verbatim, then STOP

**You do not compose the stop. The turn-end script renders it, and you output what it returns:**

```powershell
pwsh -File .specify/extensions/specrew-speckit/scripts/declare-turn-end.ps1 `
    -Kind boundary -Summary '<what this turn did>' `
    -Token <the token from the latest [specrew-turn] line>
```

Add `-Owed '<artifact>'` when the stage owes something it has not produced. The script takes the boundary,
the approval phrase and the marker from `.specrew/runtime/pending-verdict-stop.md` — never from the phase
you intend to enter next — and the Stop hook credits the record it writes. A packet you compose by hand is
not credited, however complete it looks: the hook verifies artifacts the script wrote, never prose.

**What it renders**, so you can recognise a correct stop and so this contract and the script never
disagree: the **full Rule 46 six-section re-entry packet** — all six headers, each with real content built
from the lifecycle state, never a placeholder and never a terse one-liner:

1. `## What I Just Did`
2. `## Why I Stopped`
3. `## What Needs Your Review`
4. `## What Happens Next`
5. `## Discussion Prompts`
6. `## What I Need From You`

Every artifact / file / directory reference in every section MUST be a **visible bare `file:///` URL**
(Rule 52) — not a repo-relative path (`specs/...`, `.specrew/...`), and not a markdown link, because
terminal hosts hide the clickable target otherwise.

**FIRST, whether a verdict may be offered at all** (FR-024) is decided from the pending-verdict artifact
and from `-Owed`: when the artifact is absent, or the stage owes artifacts it has not produced, the script
offers NO verdict options and emits NO marker. It says so plainly instead — naming what the stage owes and
the one step that produces it:

```text
I am not offering a verdict here: '<from>' owes <artifact> and it does not exist yet, so there is
nothing this verdict would approve.
A verdict recorded now would be indistinguishable in the ledger from an approval of real work.
Your earlier approvals stand. Produce the owed artifact through the '<from>' stage's normal step,
and the verdict options will be offered then.
```

That is the whole stop in that case: the six sections, this paragraph, no options, no marker. The
machinery says the same thing on its own surface when it withholds the artifact, so the two never
disagree.

**OTHERWISE — the stage has something to approve — the script renders the four responses** as **lines the
human can literally send**, exactly, with the real boundary name in place of `<to>`:

```text
What would you like to do? Type one of these:

  approved for <to>
  approved for <to> - <your instructions>
  changes needed: <what to change>
  discuss prompt 1
```

**NO SELECTION AFFORDANCE AT A BOUNDARY VERDICT** (maintainer ruling 2026-08-12). Not a numbered list,
not a picker, not a menu. Only a typed phrase is captured, so an interface that offers a selection is
offering a control that cannot do the thing it names — and the user does exactly what they were offered.
Measured on two hosts: a Copilot picker selection was not captured and its agent then invoked the
authorization writer directly; a Claude numbered option was not captured and its agent edited and
committed the spec on the strength of it. Same cause, opposite failure modes.

**This rule is about the BOUNDARY VERDICT, not about pickers.** A picker in a design discussion, a
clarify question, or any exchange where no ledger records the answer and no boundary advances is doing
good work and stays. The rule binds only where a typed phrase is the sole captured channel.

Each line above is literally sendable, which is the whole point: the human reads four lines and every one
of them is text they can type. All four response kinds are kept — **approve with instructions** is how a
human approves without rubber-stamping, and **discuss prompt N** is how they open one item without
withdrawing approval of the rest. Do not add a line warning that clicking or numbering will not
authorize: it defends against an affordance that is no longer offered, plants the idea, and speaks in the
machinery's voice. If someone types `1` anyway, answer them helpfully then.

Then, as the **VERY LAST line of the message**, the machine marker — an HTML comment, invisible when the
message is rendered, but read by the Stop hook to capture the human's verdict and tie it to THIS exact
boundary:

```text
<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> -->
```

The script copies it from `.specrew/runtime/pending-verdict-stop.md`'s `Marker last line exactly` value;
that artifact wins over phase inference, especially after a multi-boundary over-advance. If the artifact
does NOT exist, there is NO controller truth for this stop and the script renders no marker: say plainly
that no pending-verdict artifact exists, so no boundary crossing has been recorded for this stop. Do NOT
type a `<from> -> <to>` marker yourself: an invented marker captures the human's verdict against a
crossing the controller never recorded. The recovery is to run the boundary's own sync skill so the
arrival is recorded and the artifact exists, then run the turn-end script again. The marker is how the
hook records the human's ACTUAL typed verdict as the authorization (evidence-source
`hook-captured-from-transcript`); with no recorded crossing there is nothing a verdict could legitimately
authorize. (The marker does not change what the human sees; it is a comment.)

Then **STOP** — end your turn and wait for the human to type their choice.

- Do **NOT** call `AskUserQuestion` or any structured-question/menu tool for the verdict. It is disabled
  here, and it drops the packet on this host. The Markdown message above is the entire stop.
- Discussion is not approval unless the human clearly authorizes the boundary after the discussion.
- One approval advances at most one lifecycle boundary.

## When to Use

- At **every** human-judgment boundary stop on the Claude host — invoke this skill to perform the stop
  instead of calling `AskUserQuestion` for the verdict. Re-invoke it at each new boundary.
