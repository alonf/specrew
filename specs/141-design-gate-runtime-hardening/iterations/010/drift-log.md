# Drift Log: Iteration 010

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% dispositioned (1/1 — presence-locked + carried to a fresh-deploy dogfood; shipped, no defer)
**Specification drift**: None (the relocation matches the A4/A5/A6 intent; SC-024 — the i9 carry — is confirmed at runtime by testLenses6)

## Events

### DRIFT-001: the SC-024 dogfood ran on a deployed skill that predated the three same-session refinements (2026-06-05)

**Type**: deployment-currency drift (the artifact under test lagged the source — NOT specification drift, NOT a conduct defect)
**Detected during**: the T006 runtime SC-024 dogfood (testLenses6, feature 001-skill-mcp-catalog, on Claude)
**Description**: The relocation itself was confirmed — the `specrew-design-workshop` skill auto-loaded, re-invoked
per lens, surfaced console-ASCII diagrams in-band the maintainer saw, named every component with its
responsibility, co-designed the map and walked the flow, and held the trade-off options until the map was
agreed; the SC-025 floor validated `Valid=True`. But the deployed skill the dogfood ran **predated the three
refinements committed this same session**: the agent hit the OLD SC-021 record shape (it failed the
specify-boundary gate and had to reverse-engineer + restructure the records) and wrote PROSE `diagram` fields
rather than persisted file references — the exact behaviors `c80e7d58` (the exact `workshop` → `<lens-id>`
record shape) and `49a9ff39` (workshop-folder diagram persistence) target, with `a38daa33` (question-FORM) on
the same build boundary. So the run confirms the RELOCATION but exercises none of the three refinements.
**Resolution**: **fixed-now + carried** — the three refinements are shipped in the skill source and
**presence-locked** by the review-driven assertions added this iteration (`aef42c89`/`e6d62ee7`), so a later
skill edit cannot silently drop them. Their **behavioral** confirmation is a fresh-deploy dogfood: the next
downstream workshop run on the updated skill should write the gate-conformant SC-021 record on the first try
(no shape dance) and persist keeper diagrams to the workshop folder as file references (no prose `diagram`
fields). This is shipped scope awaiting natural exercise — **no unmet requirement, no defer entry**; carried
into the i10 retro as a next-dogfood watch.
**Status**: fixed-now (shipped + presence-locked); behavioral confirmation carried to the next fresh-deploy run.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **human-decision**: Escalate to Alon for resolution

### Notes

- The dogfood was again the gate-completeness check — but this iteration it **confirmed** rather than falsified:
  the i9 delivery-dilution diagnosis (correct conduct, diluting one-shot delivery) was right, and relocating the
  conduct into a focused, re-invokable skill made the agent surface and co-design where the mega-prompt failed
  five times. The residual drift is mundane (the test ran on a slightly stale deployed skill), and the honest
  carry — three refinements present-but-not-yet-behaviorally-observed — is recorded rather than over-claimed.
