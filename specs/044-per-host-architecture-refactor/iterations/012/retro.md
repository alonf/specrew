# Retrospective: Iteration 012

**Schema**: v1
**Date**: 2026-05-25

**Feature**: F-044 Per-Host Architecture Refactor

> Eighth LIVE-TRACKED iteration of F-044. v0.27.0 release-readiness slice driven by Explore agent audit + collision discovery via git inspection.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1 | 1 | 0 |
| T003 | 2 | 2 | 0 |
| T004 | 1 | 1 | 0 |
| T005 | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP. Clean iteration with explicit user-stated scope from the audit.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.25 | 0.25 | 0 | Plan + audit interpretation |
| Discovery/Spikes | 0.25 | 0.25 | 0 | Proposal-110 collision discovery via git inspection |
| Implementation | 4 | 4 | 0 | T001 + T002 + T003 + T004 |
| Review | 0.25 | 0.25 | 0 | Markdownlint + validator |
| Rework | 0.25 | 0 | -0.25 | Buffer unused |

## Drift Summary

- Total drift events: 2 (see [drift-log.md](./drift-log.md))
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0 in iter-012 scope
- Resolved during this iteration: 1 (drift #1 proposal-110 collision; drift #2 was iter-009 pre-iteration cleanup, documented for traceability)

## Improvement Actions

- **Pre-draft concurrent-proposal-check**: before drafting a new proposal, ALWAYS `git fetch origin main && grep -E "^proposal: NNN$" proposals/*.md` to verify the next free number is genuinely free. Two seconds. Catches concurrent-session races. Worth a memory pointer or a future Proposal 109 (open-feature-awareness) extension to "open proposal numbers in flight".
- **Local validator must match CI invocation**: the `-ChangedOnly` mode catches less than CI's unscoped mode. Document the difference in the user-guide validator section; consider exposing `specrew validate --ci-equivalent` as a sanity check before push. Strengthens Proposal 111's pre-push hook value.
- **Release-readiness audit as standard pre-tag step**: this iteration's audit was high-signal — found 4 real gaps + revealed the collision. Pattern: every major-release-tag iteration should include a single-agent release-readiness audit as the first task. Adds ~10 minutes; pays for itself in publish-blocker discovery.

## What Went Well

- **Explore agent audit was decisively useful**: 8-area brief, returned specific file:line citations + FIX/KEEP/ENHANCE recommendations. Made iter-012 scope decisions in minutes instead of hours of manual sweep.
- **Collision resolution was clean**: renumbering my proposal 110→112 took 3 file edits + 1 git mv. Registering other Claude's proposal in INDEX was 1 edit. The methodology layer's "proposals are independent files + INDEX.md catalog" pattern made this easy.
- **Single-PR docs hardening**: all 4 audit gaps + the collision + the merge all close in iter-012 within the existing PR #844. No separate PR needed.
- **Estimation hit perfectly**: 5 SP planned, 5 SP actual. Cleanest variance of any F-044 live iteration alongside iter-007 and iter-009.

## What Didn't Go Well

- **The proposal-110 collision should have been caught EARLIER** when I drafted proposal 110. I checked main but didn't fetch first — the other Claude pushed in the window between my check and my push. Captured in Improvement Actions as a pre-draft fetch discipline.
- **Local `-ChangedOnly` validator never warned about iter-009 missing reviewer artifacts**. CI caught it; local didn't. This is a methodology layer gap that empirically validates Proposal 111's pre-push hook idea. Worth promoting Proposal 111 priority post-merge.

## Methodology Lessons

### Audit-driven release-readiness

This iteration was structured as: dispatch single Explore agent with 8-area brief → audit returns concrete gaps → iter-012 closes them. The agent acted as a structured-checklist reviewer.

This pattern generalizes. Every "we're about to ship X" moment benefits from a focused agent audit with a structured brief — the audit's value is its STRUCTURE (8 named areas, FIX/KEEP/ENHANCE verdict per area), not raw scanning. The human author would have missed at least one of the 4 gaps without the structured agent prompt.

### Concurrent-session collisions are an empirical risk

Two Claude Code sessions can both pick "next free proposal number" within the same minute and push different content to the same number. Git accepts both because the filenames differ. Only catalog-side (INDEX.md) lookup would have caught it — and even then only if one session updated INDEX before the other.

Mitigation: pre-draft fetch + grep for the next free number. Lightweight discipline; catches the race.

Stronger mitigation: methodology-layer "open proposal numbers" surface (could fit naturally in Proposal 109's open-feature-awareness model, extended to draft proposals).

## Carry-Over to Next Iteration / Feature

- After CI green: tag v0.27.0 + publish to PSGallery (held per user direction)
- iter-010 PR-review cleanup (7 Copilot findings) — still deferred; either separate small-fix slice OR v0.27.1
- F-044 ends at iter-012. No iter-013 anticipated unless the v0.27.0 publication surfaces a new bug.

## Velocity Snapshot

- F-044's 11 iterations (iter-001..009 + iter-011 + iter-012) totaled: 18 + 6 + 4 + 3 + 8 + 4 + 7 + 10 + 2.5 + 3 + 5 = 70.5 SP delivered against ~220 SP nominal capacity (20/iter × 11).
- True throughput: 70.5 SP across ~3.5 weeks of dogfood-driven discovery + repair + docs work.
- iter-012 finished in ~45 minutes wall-clock — fastest iteration. Pure docs work + structured audit.
