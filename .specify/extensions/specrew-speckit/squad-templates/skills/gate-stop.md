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

Then render the four responses as **lines the human can literally send**, exactly — substituting the real
boundary name for `<to>` and a real prompt number:

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
crossing the controller never recorded. The recovery is to run the boundary's own sync skill so
the arrival is recorded and the artifact exists, then render this stop again FROM the artifact. The marker is
how the hook records the human's ACTUAL typed verdict as the authorization (evidence-source
`hook-captured-from-transcript`); with no recorded crossing there is nothing a verdict could legitimately
authorize. (The marker does not change what the human sees; it is a comment.)

Then **STOP** — end your turn and wait for the human to type their choice (a number, or free text).

- Do **NOT** call `AskUserQuestion` or any structured-question/menu tool for the verdict. It is disabled
  here, and it drops the packet on this host. The Markdown message above is the entire stop.
- Discussion is not approval unless the human clearly authorizes the boundary after the discussion.
- One approval advances at most one lifecycle boundary.

## When to Use

- At **every** human-judgment boundary stop on the Claude host — invoke this skill to perform the stop
  instead of calling `AskUserQuestion` for the verdict. Re-invoke it at each new boundary.
