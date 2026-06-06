# Drift Log: Iteration 011

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% dispositioned (1 deferred-with-decision-entry, 1 fixed-now)
**Specification drift**: the render-before-the-menu requirement's CONDUCT implementation was falsified on Claude; resolved by spec amendment (A8 / FR-041) and deferred to iteration 012, not left as silent divergence.

## Events

### DRIFT-001: render-before-the-menu CONDUCT (T007) is presence-locked but behaviorally falsified on Claude (2026-06-05)

**Type**: implementation-vs-spec-intent drift (Form-Without-Runtime-Compliance Shape 7 variant — the conduct is present and unit-presence-locked, but the required behavior does not hold at runtime on one host)
**Detected during**: the T006 consolidated cross-host re-dogfood (testLenses8 + testLenses11, on Claude)
**Description**: T007 implemented FR-037/FR-040 in-band surfacing as CONDUCT — a skill Big-Picture "render before you ask" rule plus fill-in templates (component map, then agenda) — and presence-locked it in `lens-conduct-delivery`. The dogfood falsified it on Claude twice: the agent put the thing-being-confirmed into the `AskUserQuestion` question/option fields ("approve 13 components", "8 lenses shown") instead of rendering it first. Advisor-confirmed root cause: the AskUserQuestion tool-gravity — the call's fields are a content sink, so every conduct rule of the shape "render somewhere other than the call" is defeated. It holds on Copilot + Antigravity (they render in prose first), so the behavior is host-dependent. The presence-lock guarded the text; it could not guarantee the behavior — the gap-completeness (Shape 8) lesson restated.
**Resolution**: **spec-updated + deferred** — recorded as Amendment A8 (FR-041, the non-discretionary presentation mechanism; SC-028 acceptance), the corrected implementation of FR-037/FR-040, and deferred to iteration 012 (the ~6-SP mechanical render does not fit i11's full 20; capacity validator). The A7 behavioral confirmation (SC-027) consolidates into i12's single cross-host re-dogfood. See `.squad/decisions.md` (decision `defer-141-i011-behavioral-to-i012-a8`).
**Status**: deferred to iteration 012 (human-approved; decision-linked).

### DRIFT-002: lifecycle-metadata drift — state.md stale relative to tasks-progress.yml + git log (2026-06-05)

**Type**: lifecycle-metadata drift (Lifecycle Metadata Integrity)
**Detected during**: the closeout state-verification (145 "report is an artifact under test" — verifying against artifacts, not the session summary)
**Description**: `state.md` read "**Last Completed Task**: (none — build starting)" / "**In Progress**: T001" while `tasks-progress.yml` (updated 23:55Z) and `git log` showed T001–T005 + T007 committed and done. The state metadata lagged the actual committed work.
**Resolution**: **fixed-now** — `state.md` rewritten at closeout to reflect the true delivered state (T001–T005 + T007 done, T006 deferred), Iteration Status → complete.
**Status**: fixed-now.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later:

- **implementation-reverted**: Revert implementation to match spec
- **human-decision**: Escalate to Alon for resolution

### Notes

- The dogfood was again the gate-completeness check — and this iteration it falsified the conduct approach to a requirement that unit presence-locks had reported as covered. That is the load-bearing i11 lesson: presence ≠ obedience, and for host-robust in-band rendering the lever is a non-discretionary mechanism (A8), not another instruction. The drift is honestly dispositioned forward (spec-amended + deferred), not silently carried.
