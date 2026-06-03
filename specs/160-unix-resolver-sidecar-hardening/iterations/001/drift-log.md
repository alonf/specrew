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

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: None — both events are scope-boundary discoveries handled within plan, not spec/impl divergence

## Events

### D-001 — Resolver backslash pattern is codebase-wide (scope boundary, not drift)

- **Type**: scope-discovery (no spec/impl divergence).
- **Observed**: While fixing the boundary-sync resolver (Finding 1), a grep found the
  same embedded-backslash `Join-Path`/`Test-Path` ChildPath pattern in ~105
  occurrences across 18 production scripts, including a sibling resolver in
  `validate-governance.ps1` (L1491/L1500, dashboard-renderer dev-tree-vs-installed
  resolution) with the identical latent Unix bug.
- **Decision**: Out of scope for Feature 160. Proposal 160 explicitly scoped only
  the boundary-sync resolver, and a blind 105-site sweep would violate the
  no-blind-fix discipline and iteration capacity.
- **Resolution**: `deferred` to a follow-up proposal (codebase-wide Unix
  path-separator portability sweep + a CI lint rejecting new embedded-backslash
  ChildPaths). Recorded in `review.md` "Scope Boundary" section. No spec change
  required; Feature 160's spec already scoped exactly two suspicions.

### D-002 — Self-host scaffolder template defects (tooling note, not feature drift)

- **Type**: tooling observation in the self-host tree (not a spec/impl gap for F-160).
- **Observed**: (a) `scaffold-iteration-artifacts.ps1` emitted `drift-log.md` without
  a trailing newline, tripping the pre-boundary markdownlint gate (MD047) on the
  first boundary-sync; (b) the same scaffold emitted `state.md` without the
  canonical `Current Phase` / `Iteration Status` fields the validator requires.
- **Resolution**: `fixed-now` locally (newline added; canonical state.md fields
  populated). Flagged for retro as real defects in this repo's scaffolder, since
  this is the Specrew self-host tree. No Feature-160 spec impact.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
