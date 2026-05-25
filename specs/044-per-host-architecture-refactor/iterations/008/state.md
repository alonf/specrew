# Iteration State: 008

**Schema**: v1
**Last Completed Task**: T008 (user-guide "What you'll see at every boundary" section)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: b1147b29
**Updated**: 2026-05-25T00:00:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 008 — Closeout Documentation + 2-Iteration Calculator Walkthrough + Three-Section Handoff Format Regression Fix (LIVE-TRACKED)
**Started**: 2026-05-25
**Closed**: 2026-05-25

## Summary

User-flagged TWO docs gaps at v0.27.0 release-readiness review:

1. **Closeout under-documented**: README + getting-started + user-guide mention iteration-closeout / feature-closeout by name but never explain what artifacts they produce, why they matter, or how they gate the next iteration / feature.
2. **No worked example**: nowhere in the docs is there a concrete walkthrough showing a feature flow end-to-end.

Mid-iteration, user manual-tested the build and flagged a THIRD regression: the three-section handoff format ("What I just did" / "Why I stopped" / "What I need from you") from Feature 016 Pillar 1 was no longer being applied consistently. Investigation showed the format directive existed as a single bullet under coordinator-governance rule 14A, and only the Implementer charter referenced it — the other 4 agent charters (Spec Steward, Planner, Reviewer, Retro Facilitator) made no mention of it at all.

iter-008 closes all three gaps in the v0.27.0 release before manual re-test.

## What Shipped (post-implement)

- `README.md` — extended the lifecycle-bullet in "What's working today" to explain what iteration-closeout + feature-closeout produce and why skipping them is harmful
- `docs/getting-started.md` — new Step 5 "Close the iteration (and the feature)" explaining the two final boundaries + verdict shapes + the "closeout vs. pause" distinction
- `docs/user-guide.md` — three new major sections:
  - "What you'll see at every boundary" — restores prominence to the three-section handoff format (Feature 016 Pillar 1) with full template + re-prompt guidance
  - "Closing iterations + features" — full coverage of artifacts produced (dashboard.md per iter, closeout-dashboard.md per feature), state changes, verdict shapes, when NOT to close, never-closing methodology stance
  - "Walkthrough: a two-iteration calculator" — narrative-only worked example showing iter-1 (basic four ops + memory) and iter-2 (sin, cos, atan, sqrt) end-to-end, including handoff text at each major boundary
- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror in `.specify/`) — replaced 14A's one-line three-section reference with a full canonical template + welcoming-tone mandate
- `extensions/specrew-speckit/squad-templates/agents/{spec-steward,planner,reviewer,retro-facilitator,implementer}/charter.md` (+ mirrors in `.specify/`) — added `### Boundary handoff format (Feature 016 Pillar 1)` subsection to ALL 5 charters. Previously only Implementer's charter mentioned it (and only incidentally via Proposal 082 commit-discipline references)

## Verification

```text
=== iter-008 verification ===
PASS Markdownlint: 0 violations across all 12 touched files (3 docs + 5 canonical charters + 5 .specify mirrors + coordinator-governance + .specify mirror + 6 iter-008 artifacts)
PASS Validator (governance): iter-008 directory passes canonical-schema lens
```

## Empirical motivation

User exact phrasing (2026-05-25): "In previous releases we had a clear information for the user in each gate stops. with specific questions answered. What I did, why I stopped, What I need from you. This is a fundementual part of the methodology and flow. I do not see that anymore."

Root cause: the three-section format was authored for Feature 016 (Substantive Interaction Model, May 2026), but propagation to the canonical-team source-of-truth (F-044 Slice 9, May 2026) only carried it as a one-line bullet under 14A. The format directive existed, but it wasn't prominent enough in either the coordinator prompt or the agent charters to survive into actual agent behavior. The deployed coordinator-handoff-template.md at `specs/001-specrew-product/contracts/` was a Specrew-spec-only artifact, never propagated to downstream projects.

Fix: structural prominence. The three-section template now appears as a code-fenced canonical shape in the Coordinator governance prompt at 14A (every agent reads this), plus a dedicated `### Boundary handoff format` subsection in every agent charter (every agent IS this). Plus a user-facing docs section so users know what good UX looks like and how to re-prompt when they see a regression.

## Outstanding (deferred)

- **Proposal 109 candidate**: open-feature awareness + multi-feature switching discipline + long-running/never-closed feature methodology. User-raised, scoped separately per "proposals always commit to main" rule. Draft on main as separate commit after iter-008 ships.
