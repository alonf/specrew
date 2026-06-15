# Drift Log: Iteration 004

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved in-iteration)
**Specification drift**: 2 post-review-signoff amendments (provider dev-tree resolution; bootstrap UX from manual validation)

## Events

### D-006 — providers now honor SPECREW_MODULE_PATH (post-review-signoff testability amendment)

**Requirement**: FR-001 / FR-009 (deployed provider component resolution).

**Finding**: Surfaced by the maintainer's greenfield-test request. The deployed bootstrap/handover
providers resolved their components only from a co-located dir or the installed module
(`Get-Module -ListAvailable`) - so an UNPUBLISHED dev/branch module could not be tested in a fresh
project (the published 0.33.0 lacks the iter-4 components, and the dev tree is not a discoverable
"Specrew" module). The `SPECREW_MODULE_PATH` dev-tree override (already honored by
`specrew.ps1`/`specrew-update.ps1`) was not honored by the providers.

**Resolution (in-iteration, after the review-signoff was approved)**: both providers now check
`SPECREW_MODULE_PATH/scripts/internal/bootstrap` before the installed-module fallback (gated behind
the deployed case - self-host co-located resolution is unchanged). Verified: a deployed provider with
no co-located components resolves via SPECREW_MODULE_PATH; 18 suites + PSSA green. Additive + low-risk;
the approved review's core findings are unaffected. Production (published module) path unchanged.

### D-007 — bootstrap UX polish from greenfield manual validation (post-review-signoff)

**Requirement**: FR-004 / FR-020 (render-first orientation) + FR-008 (docs).

**Finding**: The maintainer's greenfield manual test confirmed F-174 works live (the agent rendered the
full orientation - incl. the concurrency advisory - on its first reply). It also surfaced two honest
UX truths: (1) a Claude SessionStart hook injects context SILENTLY and the agent does not auto-respond,
so there is NO zero-interaction splash via the hook - the orientation lands on the agent's FIRST reply,
and a true pre-session banner is the `specrew start` launcher's job; (2) the orientation only landed
because the first message was an open question - a task-first message ("create a feature ...") could
skip it.

**Resolution (in-iteration)**: (a) the bootstrap directive now instructs the agent to LEAD its FIRST
response with the orientation REGARDLESS of the user's first message (even a task), then act - plus a
branch + recommended-next-step in the render order; (b) getting-started + README document the two start
paths honestly (`specrew start` = guided splash; direct launch = ask/state-intent, orientation on turn
one). 18 suites + PSSA green; bootstrap provider re-mirrored. The zero-interaction-splash limit is a
documented host constraint, not a defect.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
