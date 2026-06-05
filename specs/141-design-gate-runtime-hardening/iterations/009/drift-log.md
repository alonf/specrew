# Drift Log: Iteration 009

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% dispositioned (1/1 — deferred to iteration 010 / the delivery relocation, maintainer-approved)
**Specification drift**: None (the A6 conduct matches the spec; the conduct's DELIVERY — a one-shot mega-prompt — dilutes it, so it under-surfaces at runtime)

## Events

### DRIFT-001: SC-024 in-band surfacing unreliable — correct conduct, diluting delivery (2026-06-05)

**Type**: delivery/conduct drift (not specification drift; not a defect in the deterministic floor)
**Detected during**: the T006 runtime SC-024 dogfood (testLenses5, feature 001-training-admin, on Claude — with a parallel Codex run as the contrast)
**Description**: The A6 co-design conduct is correct and DID run — the human co-designed the IDesign component/responsibility
map (4 Managers / 3 Engines / 5 ResourceAccess) and walked two flows, recorded in the Co-Design Record. But the Claude agent
**under-surfaced in-conversation**: it wrote the component diagram to an HTML file and never showed it or its link, presented a
terse "4 Managers, 3 Engines" count instead of named components + responsibilities, and the agreed UI/screen layout was captured
nowhere. Root cause: the conduct (Rules 9a/9b/9c) lives in a ~50-rule one-shot launch prompt the agent skims by the time it
reaches each lens. The content sub-bugs were fixed in-iteration — A: on a terminal a fenced mermaid block is source text, not a
picture, so Rule 9b now makes ASCII the inline default and mermaid/file requires the clickable link in-chat; C: name components +
responsibilities, never a count; D: the SC-025 floor now requires the ui-ux layout capture. The deeper delivery/dilution cause
remains.
**Resolution**: **deferred to iteration 010 (the delivery relocation)** — maintainer-dispositioned INSIDE Feature 141 as a delivery
REDO (same A4/A5/A6 intent, changed implementation): a single re-invokable design-workshop skill (uniform across the 5 host skill
dirs) that loads the correct per-lens `design-lenses\<id>.md` at each stage, the per-lens conduct co-located into those md files,
a trimmed launch prompt, and workshop-folder artifact organization. Web-confirmed mechanism: agents re-invoke skills on-demand
(name + description always in the system prompt; body loaded when relevant, multiple times per session). SC-024's full behavioral
pass re-confirms in a clean i10 dogfood. Canonical defer entry recorded in `.squad\decisions.md` (FR-036).
**Status**: deferred to iteration 010 (approved, with a named next action — not a silent skip).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **human-decision**: Escalate to Alon for resolution

### Notes

- The dogfood — not the unit suite — was the gate-completeness check for the third consecutive iteration (i7: a gate wired to the
  wrong artifact; i8: conduct that permits instead of compels; i9: correct conduct diluted by one-shot delivery). The recurring
  shape is form-present / runtime-value-absent, each caught only by the real run. The maintainer's retro action: a 1-run PoC up
  front catches rule-skimming-at-scale before the full build.
