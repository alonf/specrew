# Iteration State: 012

**Schema**: v1
**Last Completed Task**: T004 (the cross-host dogfood — ACCEPTED on both hosts: "the best workshop")
**Tasks Remaining**: none — T001–T004 done
**In Progress**: none — iteration complete (review-signoff ACCEPTED; SC-028 + SC-027 met cross-host; retro done)
**Baseline Ref**: 26ef631e
**Updated**: 2026-06-06T02:10:00Z
**Current Phase**: complete (A8/FR-041 — open-question-first + cross-host pacing CONFIRMED; catalog-at-open reverted; the Claude agenda skim is the maintainer-accepted minor)
**Iteration Status**: complete

## Execution Summary

- Iteration 12 scope: **Amendment A8 / FR-041** — the corrected implementation of FR-037/FR-040 after i11's
  dogfood proved render-before-the-menu CONDUCT insufficient on Claude (the `AskUserQuestion` tool-gravity).
- Build plan: T001 catalog-at-open (present all 9 lenses + decisions at workshop open, from `index.yml` + the
  lens md — structural front-loading); T002 open-question-first (each lens opens with a presentation + an open
  question, never a menu first — the binary conduct lever); T003 presence-lock tests. T004 is the consolidated
  cross-host re-dogfood (SC-028 + carried SC-027), the behavioral acceptance, maintainer-run.
- **Honest split (advisor pre-build):** the agenda is fixed *structurally* (front-loading holds by
  construction); the per-lens component-map render is *conduct* (open-question-first), the case the dogfood
  actually tests. Pre-committed: if the map still stuffs into the menu on a host, the answer is a `PreToolUse`
  hook or documented host-variance decided with the maintainer — NOT another instruction edit.
- Carried constraints: the catalog reuses `index.yml` + the lens md (no parallel catalog); no `workshop show`
  command; `index.yml` stays pure; deploy unchanged; no release/push while 141 in progress.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->
