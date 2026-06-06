# Drift Log: Iteration 008

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% dispositioned (1/1 — deferred to iteration 009 / Amendment A6, maintainer-approved)
**Specification drift**: None (behavioral/conduct drift — the capability matches the spec; the conduct under-drove its runtime surfacing)

## Events

### DRIFT-001: SC-022 surfacing clause unmet at runtime — conduct permitted instead of compelling (2026-06-05)

**Type**: behavioral/conduct drift (not specification drift; not implementation defect in the deterministic helper)
**Detected during**: the T005 runtime visual dogfood (testLenses4, feature 001-doc-translation)
**Description**: The A5 capability fired — a per-lens architecture component diagram and an ERD were authored from
`diagram-vocabulary.json` — but the agent wrote them only to a persisted `.specrew\workshop-visuals\001-doc-translation-architecture.html`
with no in-band clickable `file:///` link and no inline render, so the maintainer saw no diagram during the workshop,
and the ui-ux lens produced no visual at all. The emit helper itself correctly returns a `file:///` reference (SC-023
tests green); the gap is that Rule 9b phrased surfacing as something the agent "MAY" do, so it did not compel the
in-band surfacing the experience depends on. SC-022's "surfaced per the tier policy" clause was therefore not met.
**Resolution**: **deferred to iteration 009 (Amendment A6)** — maintainer-dispositioned INSIDE Feature 141. Rule 9b will be
strengthened so workshop visuals MUST surface in-band (inline render or a clickable `file:///` link, never written to
disk only) and are expected for structural + UI-bearing lenses; SC-022's surfacing clause is re-confirmed in the i9
downstream dogfood. Canonical defer entry recorded in `.squad\decisions.md` (FR-031).
**Status**: deferred to iteration 009 (approved, with a named next action — not a silent skip).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **human-decision**: Escalate to Alon for resolution

### Notes

- The dogfood — not the SC-023 unit suite — was the gate-completeness check for the second consecutive iteration
  (i7: a gate wired to the wrong artifact; i8: conduct that permits instead of compels). Captured as Iteration 8's
  retro lesson and as the direct mandate for Amendment A6's Rule 9b strengthening.
