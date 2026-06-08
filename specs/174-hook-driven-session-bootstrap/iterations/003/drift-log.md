# Drift Log: Iteration 003

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
**Specification drift**: 2 implementation gaps caught by the live-wiring completeness checks, both fixed in-iteration

## Events

### D-003 — launcher dedupe false-triggered on sync-rewritten last-start-prompt.md

**Requirement**: FR-007 (launcher<->hook idempotency).

**Finding**: The iteration-002 launcher dedupe keyed on `last-start-prompt.md` recency, but boundary
syncs ALSO rewrite that file - so after any recent sync the hook falsely deduped and the bootstrap
never rendered. Surfaced by the T021 live cross-host smoke (all 4 hosts initially FAILed).

**Resolution (in-iteration)**: moved the dedupe to a dedicated launcher marker
(`.specrew/runtime/launcher-bootstrap.json`) that only the launcher writes; syncs never trip it.
Fixed in commit `f51baaf3`.

### D-004 — D-002 SessionEnd handover was not actually live (no host hook + latent overlay gap)

**Requirement**: FR-009 (SessionEnd handover wired through the shipped hook path).

**Finding**: The handover provider + dispatcher dispatch were ready, but `deploy-refocus-hooks.ps1`
registered no SessionEnd host hook, so on a real session-end nothing invoked the dispatcher.
Additionally a latent iteration-001 gap: the catalog-overlay canonical-id set excluded only
`refocus`, mis-capturing `bootstrap`/`handover` as user rows. Surfaced by the pre-review
"build+test != live" completeness check (the iteration-002 retro action).

**Resolution (in-iteration)**: registered the Claude SessionEnd host hook; fixed the overlay
canonical-id set to all three Specrew providers. Fixed in commit `1de2a45a`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
