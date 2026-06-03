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

**Total drift events**: 3
**Resolution rate**: 100% (3/3 resolved)
**Specification drift**: None — events are scope-boundary discoveries and an evidence refinement, not spec/impl divergence

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

### D-003 — Real-host evidence refined Finding 1's runtime disposition (post-closeout CI)

- **Type**: evidence refinement at the feature-closeout CI gate (FR-009/TG-005 follow-through).
- **Observed**: The first real-Linux execution of the resolver probe (Ubuntu run
  `26907556536`, PR #1694) showed PowerShell provider cmdlets normalize `\` to
  `/` on POSIX — the wrapper's old construction RESOLVES at runtime, refuting the
  "Path 0/1/2 can never match on Unix" hypothesis. The string-level semantics and
  the raw-.NET-layer hazard remain proven.
- **Decision**: `human-decision` — keep-the-hardening vs revert presented to the
  maintainer before merge; evidence note, probe, CHANGELOG, and feature review
  corrected to the refined truth. Sweep-proposal scope re-aimed at the
  non-provider hazard class.
- **Resolution**: recorded honestly the same day; the deterministic-fixture
  fallback's limit (string semantics ≠ provider behavior) is itself a lesson
  feeding the clarify policy for future investigations.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
