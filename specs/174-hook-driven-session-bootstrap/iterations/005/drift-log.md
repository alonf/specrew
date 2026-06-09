# Drift Log: Iteration 005

**Schema**: v1

<!--
  Markdown authoring note: when adding drift events, keep a BLANK LINE between a colon-terminated
  sentence and the bullet list that follows (MD032). The F-033 pre-boundary markdownlint gate --fixes
  most violations, but writing the blank line avoids the churn.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved in-iteration)
**Specification drift**: 1 human-instruction-vs-architecture reconciliation (the Stop-time detector mechanism)

## Events

### D-008 - instruction #2 "Stop-time warns the agent" is unrealizable under P1; delivered as option-1 detection

**Requirement**: FR-022 (the iter-5 mechanical detector) + the F-171 P1 fail-open doctrine.

**Finding (surfaced during T030, confirmed against primary source)**: the maintainer's approved
instruction #2 - "Stop-time warns the agent while it can still author" - cannot be implemented as a
literal Stop-hook-to-agent warn. A Stop-event hook CANNOT reach the agent same-session:

- the dispatcher's `Write-InjectionOutput` shapes agent-facing output only for SessionStart /
  PostToolUse / UserPromptSubmit / PreToolUse - **Stop is not an injection event**;
- the handover provider is write-only (emits no stdout), so the injection path never fires for it;
- P1 is hard-coded "exit 0 - never block a session", so the only alternative (a Stop `decision: block`
  that forces continuation) is forbidden by doctrine.

**Resolution (in-iteration, maintainer-informed BEFORE building T030)**: deliver the FUNCTION of #2
within P1, as option 1 (recommended; the maintainer was given an off-ramp to option 3, a P1-exception
block):

- the **failure-reducing "author while you can"** moves to the **directive** (T032), which fires on
  SessionStart - a real inject event - instructing the agent to author the body via
  `Write-SpecrewHandoverContext` when it renders a boundary packet, before it stops;
- the **Stop-time detector** (T030) is a **non-blocking same-session detection**: a self-documenting
  placeholder body + a `.specrew/runtime/handover-journal.jsonl` `hollow-handover-at-stop` record;
- the **resume warn** (T032) is the prominent agent-facing backstop at the next SessionStart.

SC-010 encodes this as detect-not-prevent honesty (the iter-5 mechanism-not-pledge lesson applied to
its own deliverable). The two failure-mode-A plumbing smokes + the T030 provider smoke are green.

### Resolution Strategies (Unused)

- **spec-updated**, **implementation-reverted**, **deferred**, **human-decision** remain available.

### Notes

- Scaffolded during implementation; drift logged immediately on detection (T030).
