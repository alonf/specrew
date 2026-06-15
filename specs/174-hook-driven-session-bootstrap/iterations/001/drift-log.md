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
**Resolution rate**: resolved on self-host (1/1; downstream deploy carried to iteration 003)
**Specification drift**: 1 resolved (D-001 live wiring — provider registered + dispatcher-proven)

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

**Resolution**: resolved on self-host (2026-06-08). The B2 bootstrap is now LIVE: a `bootstrap`
provider row was added to `refocus-scopes.json` (source + deployed mirror), the entry script
`scripts/internal/specrew-bootstrap-provider.ps1` was added, and a dispatcher smoke proved the
F-171 SpecrewHookDispatcher fires the provider on SessionStart B2 (silent on `compact`, so B1 is
unchanged — FR-011). The 8 new files are in the `Specrew.psd1` FileList (install guard); the
provider self-dot-sources the components, so module-level loading is unnecessary for the hook
path. REMAINING: the downstream extension-tree deploy (placing the provider + components under
`extensions/specrew-speckit/scripts/` so downstream dispatchers resolve them) — folded into the
iteration-003 per-host/deploy work (T016/T017). The reviewer assesses at review-signoff.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
