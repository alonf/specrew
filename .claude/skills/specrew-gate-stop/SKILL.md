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

## What to render — one Markdown message, then STOP

Render the **full Rule 46 six-section re-entry packet** as Markdown — all six headers, each with real
content built from the lifecycle state (the current phase, `tasks-progress.yml`, the decisions ledger,
and what the lifecycle does next), never a placeholder and never a terse one-liner:

1. `## What I Just Did`
2. `## Why I Stopped`
3. `## What Needs Your Review`
4. `## What Happens Next`
5. `## Discussion Prompts`
6. `## What I Need From You`

Every artifact / file / directory reference in every section MUST be a **visible bare `file:///` URL**
(Rule 52) — not a repo-relative path (`specs/...`, `.specrew/...`), and not a markdown link, because
terminal hosts hide the clickable target otherwise.

Then render the verdict options as a **numbered Markdown list**, exactly:

```text
What's your verdict?
  1. Approve as-is — proceed with the defaults
  2. Approve with instructions — proceed and carry the added instructions
  3. Send back — describe what to change before this boundary can advance
  4. Discuss prompt #N — discuss that prompt only, then return for explicit approval
```

Then, as the **VERY LAST line of your message**, emit the machine marker — an HTML comment, invisible when
the message is rendered, but read by the Stop hook to capture the human's verdict and tie it to THIS exact
boundary:

```text
<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> -->
```

If `.specrew/runtime/pending-verdict-stop.md` exists, copy its `Marker last line exactly` value; that artifact
wins over phase inference, especially after a multi-boundary over-advance. If the artifact does NOT exist,
there is NO controller truth for this stop: state that plainly — "no pending-verdict artifact exists, so no
boundary crossing has been recorded for this stop" — and STOP WITHOUT a marker. Do NOT infer or invent a
`<from> -> <to>` from the phase you are in: an invented marker captures the human's verdict against a
crossing the controller never recorded (DRIFT-198-I011-012 — the July F1 `specify -> specify` signature was
exactly this instruction firing at a first boundary). The recovery is to run the boundary's own sync skill so
the arrival is recorded and the artifact exists, then render this stop again FROM the artifact. The marker is
how the hook records the human's ACTUAL typed verdict as the authorization (evidence-source
`hook-captured-from-transcript`); with no recorded crossing there is nothing a verdict could legitimately
authorize. (The marker does not change what the human sees; it is a comment.)

Then **STOP** — end your turn and wait for the human to type their choice (a number, or free text).

- Do **NOT** call `AskUserQuestion` or any structured-question/menu tool for the verdict. It is disabled
  here, and it drops the packet on this host. The Markdown message above is the entire stop.
- Discussion is not approval unless the human clearly authorizes the boundary after the discussion.
- One approval advances at most one lifecycle boundary.

### ONE-MESSAGE DECISION STOPS (FR-017)

**The packet and the ask are ONE message.** Never end a turn with the decision and then render the
packet in a follow-up. A human who is asked to decide before they can read what they are deciding is
being asked to guess, and the second message arrives after they have already started answering.

This is a MEASURED failure, not a theoretical one: DRIFT-199-I001-001 records a co-design presentation
that ended the turn without its context packet, the Stop hook bouncing, and the packet arriving in a
follow-up message. The same shape applies to any decision-yield stop, boundary or not.

**The check before you end a turn that asks for anything**: is everything the human needs in order to
answer already in THIS message? If the answer is no, you are not ready to stop.

### NEVER SYNC IN THE VERDICT TURN (FR-017 defense)

**Do not run a boundary sync, a state write, or any lifecycle-advancing script in the same turn that
carries the human's verdict.** The verdict turn's job is to record what the human said; a sync in that
turn rebinds the crossing the verdict is being recorded against, so the authorization and the thing it
authorizes can no longer be told apart in the ledger.

If the stop reveals that a sync is missing — for example the pending-verdict artifact does not exist —
say so plainly, run the sync in its OWN turn, and render the stop again from the artifact. That
sequence is slower by one turn and keeps the record honest, which is the trade this rule exists to make.

## When to Use

- At **every** human-judgment boundary stop on the Claude host — invoke this skill to perform the stop
  instead of calling `AskUserQuestion` for the verdict. Re-invoke it at each new boundary.
