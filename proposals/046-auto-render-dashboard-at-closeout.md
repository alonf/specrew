---
proposal: 046
title: Auto-Render Dashboard at Iteration & Feature Closeout
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Auto-Render Dashboard at Iteration & Feature Closeout

## Why

F-020 (Session-State Durability) makes session state durable and synchronized at every boundary, but the dashboard *view* of that state — what `specrew where` renders — remains a user-invoked command. The expected user behavior is:

> "I just shipped an iteration. What state am I in now?"

Today the user has to type `specrew where` to get the answer. They likely won't think to do it. Methodology adoption depends on the right information surfacing at the right moment without requiring the user to know which command to run.

This proposal closes that UX gap: the dashboard renders **automatically** at iteration-closeout and feature-closeout boundaries, so the user sees their state at the natural "you just shipped something" moment.

## What

### Trigger boundaries

Two boundaries auto-render `specrew where`:

1. **Iteration-closeout** — as the final step of the iteration-closeout script, after state files are updated, call the dashboard renderer and print to stdout/console.
2. **Feature-closeout** — as the final step of the feature-closeout script, same pattern. Shows "No active feature. Last completed: Feature NNN. Next roadmap item: ..." per the Phase 0 closeout pattern (commit `9f63790`).

### Out of scope

- Intermediate boundaries (specify, clarify, plan, tasks, review-signoff) do NOT auto-render — that would be too noisy. State sync happens silently; only completion events render the dashboard.
- The dashboard renderer itself is unchanged — same output as `specrew where`. This proposal is purely the trigger.
- CI suppression — see open question 2.

### Implementation sketch

- Modify `extensions/specrew-speckit/scripts/scaffold-iteration-closeout.ps1` (and the feature-closeout equivalent) to call the dashboard renderer at the end of the script.
- The dashboard renderer is already a stand-alone PowerShell module from F-017 (`scripts/internal/dashboard-renderer.ps1` per memory notes). No re-implementation needed.
- Add an `-SuppressAutoRender` flag to the closeout scripts for CI/automation contexts that capture the closeout output separately.

## Effort

~5 SP, single iteration. Composes tightly with F-020 (state durability provides the fresh data the dashboard reads).

## Phase placement

**Phase 2, fast follow-up to F-020.** Should ship in the next 1-2 features after F-020 closes. Doesn't depend on Iteration 2 of F-020 specifically; works with whatever state surface exists at the time.

## Open questions

1. Should the auto-render also fire at iteration-start (showing "just authorized Iteration N of Feature MMM")? Symmetry argument for yes; noise argument for no.
2. CI/automation suppression: env var (`SPECREW_SUPPRESS_DASHBOARD=1`) vs flag (`--no-dashboard`) vs both?
3. Verbosity: same as interactive `specrew where`, or condensed "you just shipped X / next is Y" mini-view?
4. What happens if the dashboard renderer fails (file missing, parse error)? Closeout boundary must still succeed — render failure should warn but not block.

## Risks

- **Noise** — if too many boundaries auto-render, users tune out. Mitigation: only completion boundaries (iteration-closeout + feature-closeout); not intermediate boundaries.
- **CI breakage** — automation pipelines may not expect dashboard output at closeout. Mitigation: suppression flag (open question 2).
- **Render-failure cascade** — if the dashboard renderer crashes, it shouldn't take down the closeout. Mitigation: wrap in try/catch and log as WARN.

## Cross-references

- Composes with [009](009-velocity-dashboard.md) — uses the dashboard renderer F-017 introduced
- Composes with [035](035-session-state-durability.md) — relies on the fresh state that F-020 makes durable
- Composes with [031](031-specrew-distribution-module.md) — the auto-render makes the post-install experience richer

## Status history

- 2026-05-18: candidate captured during F-020 Iteration 1 review-boundary discussion; user identified that downstream Specrew users won't know to invoke `specrew where` manually, so the dashboard must surface automatically at completion events
