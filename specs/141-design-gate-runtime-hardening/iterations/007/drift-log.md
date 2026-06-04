# Drift Log: Iteration 007

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: None (implementation/wiring drift only, caught by the runtime dogfood)

## Events

### DRIFT-001: SC-021 floor wired to the wrong artifact (2026-06-04)

**Type**: implementation/wiring drift (not specification drift)
**Detected during**: the T006 runtime dogfood (testLenses3, feature 001-photo-foundation)
**Description**: The SC-021 per-lens-record floor (`Test-SpecrewLensWorkshopRecords`) was wired into the
design-analysis (plan) gate with iteration-first resolution. But the workshop records live in the
FEATURE-level `lens-applicability.json` (the iteration-level one is the design-analysis questionnaire,
no `workshop_intake`), so the floor resolved the wrong artifact and **no-opped** — the SC-021 contract
was silently not enforced. The unit test missed it because it modeled `workshop_intake` at the iteration
directory, not the real feature-vs-iteration split (Shape-8 gate-completeness pattern).
**Resolution**: implementation-corrected (`a0b78cbc`) — `Test-SpecrewLensWorkshopRecords` now takes the
exact `-ArtifactPath`; the SC-021 check was re-homed to `Invoke-SpecrewSpecifyBoundaryLensGate` against
the feature-level artifact and removed from the design-analysis gate; a new specify-gate test models the
real layout with a failing negative case. All suites green.
**Status**: resolved this iteration.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- The dogfood — not the unit suite — was the gate-completeness check (the Proposal 145 / Shape-8 thesis,
  live). Captured as Iteration 7's retro lesson.
