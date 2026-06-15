# Drift Log: Iteration 005

**Schema**: v1

<!--
  Markdown authoring note: when adding drift events, keep a BLANK LINE between a colon-terminated
  sentence and the bullet list that follows (MD032). The F-033 pre-boundary markdownlint gate --fixes
  most violations, but writing the blank line avoids the churn.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 50% (1/2 resolved in-iteration; D-009's live wiring is deferred to iteration 006)
**Specification drift**: 1 human-instruction-vs-architecture reconciliation (D-008, the Stop-time detector mechanism) + 1 build != live honesty correction (D-009, the dev-tree-only floor)

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

### D-009 - the failure-mode-A "floor" asserted dev-tree round-trip, not deployed-tree resolution (build != live)

**Requirement**: FR-022 (the agent-authored handover) + the standing build != live lesson (F-054; iter-3 D-002).

**Finding (surfaced at the honest review-signoff close, confirmed by the greenfield dogfood)**: the
originally-presented iteration-005 review claimed the surfacing/handover round-trip as delivered, but
EVERY smoke ran in the DEV tree, where the provider resolves its components via `$PSScriptRoot/bootstrap`
(co-located). In a DEPLOYED downstream project the Stop provider cannot resolve HandoverStore (the
bootstrap components are not deployed there, and SPECREW_MODULE_PATH does not reach the Stop-hook child),
so the agent-authored handover silently never fires (PROVIDER_FAILED, no file). The failure-mode-A floor
asserted persisted-bytes == surfaced-bytes but NEVER that the provider can RESOLVE the persisting code in
a deployed tree - a pledge dressed as the mechanism, the SAME build != live class as F-054 and the iter-3
D-002 send-back. (Diagnostic asymmetry confirmed live: the SessionStart bootstrap DID resolve on `claude`
and rendered orientation on a direct `claude` launch, but the Stop hook did NOT; that split is the iter-6
key.)

**Resolution (deferred, human-approved)**: close iteration 5 honestly-qualified - the dev-tree machinery
is built + unit-tested and reviewable; FR-022's LIVE (deployed-tree) behavior is DEFERRED to iteration 6
(`f174-i005-defer-live-wiring`), which must include a LIVE-WIRING FLOOR asserting a real deployed session
writes the contract + handover to disk (not dev-tree-green). Recorded at the review-signoff close; the
originally-presented review.md + review-report.yml are corrected by their Live-Wiring Qualification
section (review.md) and read dev-tree-verified, not deployed-verified.

### Resolution Strategies (Unused)

- **spec-updated**, **implementation-reverted**, **human-decision** remain available (**deferred** is now
  used by D-009).

### Notes

- Scaffolded during implementation; drift logged immediately on detection (T030).
