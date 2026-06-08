# Drift Log: Iteration 001

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

**Total drift events**: 1
**Resolution rate**: deferred (0/1 resolved; 1 deferred to iteration 003)
**Specification drift**: 1 deferred (D-001 live wiring)

## Events

### D-001 — Bootstrap components built + tested but not yet live-wired

**Requirement**: FR-001 (the SessionStart B2 trigger MUST become the primary bootstrap path).

**Drift**: Iteration 001 built and unit-tested all 7 bootstrap components (57 assertions,
green), but the live wiring is not yet in place:

- module dot-sourcing of `scripts/internal/bootstrap/*.ps1` (not yet loaded by `Specrew.psm1`);
- `Specrew.psd1` FileList entries for the new files (the install-break guard);
- the F-171 SessionStart B2 dispatcher registration that makes the provider fire on launch.

So FR-001's "primary bootstrap path" is not yet observable on a live host — the spec intent
exceeds the shipped wiring.

**Resolution**: deferred. The live wiring is paired with the iteration-003 per-host empirical
verification (T017 / SC-001), which is the step that actually proves render-before-picker on
each host. Recorded here so the gap stays visible; the reviewer assesses it at review-signoff.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
