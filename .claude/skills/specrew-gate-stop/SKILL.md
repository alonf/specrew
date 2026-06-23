---
name: "specrew-gate-stop"
description: "Perform a Specrew human-verdict boundary stop on the Claude host. Renders the FULL Rule 46 six-section human re-entry packet AND the verdict options as one Markdown message, with the AskUserQuestion picker disabled so the packet cannot collapse into the picker's short header/option fields. Invoke at EVERY human-judgment boundary stop (specify, clarify, plan, tasks, before-implement, implement, review, retro, feature-closeout, lifecycle-end). Triggers: boundary stop, verdict, approve / redirect / send back, why I stopped, human re-entry packet, gate stop."
domain: "lifecycle-governance"
confidence: "high"
source: "Specrew Feature 165 — on the Claude host the AskUserQuestion picker collapses the Rule 46 six-section packet into its short fields (the human is asked to approve what they cannot read; proven gameable even under a runtime hook-deny that the model satisfied by rewording the menu). disallowed-tools removes the picker for the stop, so the packet has nothing to collapse into and renders as prose. The design workshop is unaffected — its lens questions keep the picker because the workshop skill does NOT disable it."
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
stop as a Markdown message. (The design workshop is unaffected: its per-lens questions keep the
picker, because the workshop skill does not disable it. Clarify questions are not boundary stops and
keep the picker too. Only boundary **verdict** stops route through this skill.)

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
wins over phase inference, especially after a multi-boundary over-advance. Otherwise replace `<from> -> <to>`
with the **canonical** boundary you are gating (the from→to for this stop — e.g.
`tasks -> before-implement`, `plan -> tasks`, `review-signoff -> retro`). This marker is how the hook records
the human's ACTUAL typed verdict as the authorization (evidence-source `hook-captured-from-transcript`),
instead of anything inventing one. Without it the gate stays un-authorized and the next session surfaces the
boundary as "awaiting your verdict" so the human must re-confirm — so always include it, with the correct
canonical boundary names. (It does not change what the human sees; it is a comment.)

Then **STOP** — end your turn and wait for the human to type their choice (a number, or free text).

- Do **NOT** call `AskUserQuestion` or any structured-question/menu tool for the verdict. It is disabled
  here, and it drops the packet on this host. The Markdown message above is the entire stop.
- Discussion is not approval unless the human clearly authorizes the boundary after the discussion.
- One approval advances at most one lifecycle boundary.

## When to Use

- At **every** human-judgment boundary stop on the Claude host — invoke this skill to perform the stop
  instead of calling `AskUserQuestion` for the verdict. Re-invoke it at each new boundary.
