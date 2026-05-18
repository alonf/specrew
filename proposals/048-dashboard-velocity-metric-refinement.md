---
proposal: 048
title: Dashboard Velocity Metric Refinement
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Dashboard Velocity Metric Refinement

## Why

The current `specrew where` velocity headline ("11.04 SP/day, high confidence") is a trailing 10-iteration average over the elapsed calendar-day window. It's conservative by design (smooths marathon days), but it systematically understates current acceleration when the maintainer's pace shifts upward.

Empirical example surfaced 2026-05-18: maintainer delivered 31 SP in a single ~7-hour session (F-020 Iter 1 + Iter 2 closed back-to-back, 16 + 15 SP), but the dashboard headline still reported 11.04 SP/day. The trailing-10 average pulled in older F-019 repair-heavy iterations (4-7 SP/day) plus gap calendar days where nothing shipped, masking the recent acceleration.

A dashboard meant to answer "where am I?" should also answer "how fast am I actually moving right now?" — not just "what's my long-run smoothed average?"

## What

Augment the VELOCITY section of `specrew where` (and the dashboard renderer used by Proposal 046 auto-render) with metrics that surface the **current** pace, not just the trailing average.

### Five enhancements

1. **Peak day SP** — maximum single-day SP delivery in the window. Surfaces marathon sessions and shows what's possible at burst.

2. **Recent-weighted velocity headline** — replace the trailing-10 simple mean with an exponentially-weighted moving average over the last N iterations (default N=5, weight decay 0.7). Responsive to acceleration; older iterations contribute less to the headline.

3. **Velocity trio: Peak / Recent / Trailing** — render all three side-by-side in the VELOCITY section, not just one. Current trailing-10 average stays available for long-term planning context; recent-weighted is the new headline.

4. **Iteration cycle-time metric** — average days from iteration-start authorization to iteration-closeout, broken into recent vs trailing windows. Today's value: ~1 day (recent) vs ~2 days (trailing). Surfaces the compression that's actually happening.

5. **Trend direction indicator** — small arrow next to the recent-weighted headline: ↗ accelerating, → steady, ↘ decelerating. Computed from sign + magnitude of (recent-weighted minus trailing-mean).

### Proposed VELOCITY section layout

```
VELOCITY
Recent: 22.4 SP/day ↗ (last 5 iter, exp-weighted)
Trailing: 11.04 SP/day (10 closed iter, 13 calendar days)
Peak: 31 SP (2026-05-18) — F-020 Iter 1 + Iter 2 same day
Iter cycle: 1.0 day recent / 1.3 days trailing
Sparkline: ▆▇▁▅█▆█▇▅▂ | values 15 / 16 / 8 / 14 / 18 / 14.5 / 18 / 17 / 13 / 10
```

### Storage

No new storage. All metrics derivable from existing iteration history that the dashboard already reads. Pure renderer-layer enhancement.

## Effort

**~5 SP, single iteration**. Roughly:

- Helper functions for recent-weighted average + peak day + cycle time (~1 SP)
- Trend indicator logic (~0.5 SP)
- Renderer updates to the VELOCITY section + ASCII/monochrome compatibility (~1 SP)
- Tests against fixture iteration histories with known expected values (~1.5 SP)
- Documentation: update `docs/dashboard-guide.md` with metric definitions (~0.5 SP)
- Compatibility: ensure stored closeout snapshots (with the old headline format) continue to render historically (~0.5 SP)

## Phase placement

**Phase 2, fast follow-up to F-020.** Slots well after Proposal 046 (auto-render dashboard at closeout) since both touch the dashboard renderer. Could combine with 046 as a single ~10-SP feature.

Possible sequencing within the post-F-020 queue:
- **Option A**: 032 (slash commands) → 046 (auto-render) → 048 (velocity refinement) → 047 (governance profile). 048 slots between 046 and 047 since both 046 and 048 touch the dashboard.
- **Option B**: 032 → 046 + 048 combined → 047. Single shared dashboard-renderer feature.

Recommended: **Option B** (combine 046 + 048). Both edit `scripts/internal/dashboard-renderer.ps1` (or whatever Iter-1-of-F-017 produced); single feature minimizes churn.

## Open questions

1. **Default headline metric**: recent-weighted vs trailing? Proposal recommends recent-weighted (more responsive) but trailing has merits for long-term planning. Should the governance-profile (Proposal 047) include a "preferred velocity headline" dial?
2. **Recency window N**: 3, 5, or 10 iterations for the recent-weighted? Different N affects responsiveness vs noise tradeoff.
3. **Exponential decay factor**: 0.5 (very recent-biased) vs 0.7 (moderate) vs 0.9 (close to mean)? Affects how fast old data drops out.
4. **Peak window**: lifetime peak, last 30 days, last 10 iterations? Lifetime gives motivation; recent-only avoids stale peaks from long-past marathon days.
5. **Trend threshold**: how much above/below trailing-mean qualifies as accelerating/decelerating? 10%? 25%? Standard deviation based?
6. **Cycle-time semantics**: "days from iteration-start authorization to iteration-closeout commit" vs "first commit to closeout commit"? The former includes gap days; the latter measures active work span.
7. **Gap-day handling**: should the recent-weighted average exclude calendar days with zero closures, or include them? Excluding makes the metric measure pace-when-active; including measures pace-overall.
8. **Display in monochrome / ASCII modes**: trend arrow becomes `^` `=` `v`? Sparkline is already handled by F-018 visual-richness work.
9. **Closeout snapshot compatibility**: do stored historical dashboards re-render with new metrics if re-read, or stay frozen in their original format?
10. **Notification semantics**: should trend ↘ at iteration-closeout trigger a yellow warning? (Probably no — that's overreach; surface the data and let the human interpret.)

## Risks

- **Metric overfitting to recent volatility**: a single bad week could drag the recent-weighted way down, creating false "decelerating" signals. Mitigation: use a window of at least 5 iterations; document the metric's sensitivity.
- **Misleading peak**: a one-time marathon day (like 2026-05-18) might create unsustainable expectations. Mitigation: pair Peak with a "median day" metric so users see both ceiling and typical.
- **Dashboard noise**: adding 4 new lines to VELOCITY might clutter the dashboard. Mitigation: VELOCITY section is small today (1-2 lines); adding 3-4 lines is still compact. If clutter becomes an issue, gate the extra detail behind a `--verbose` flag.
- **Closeout snapshot format drift**: changing the dashboard format means stored snapshots from F-017+F-018 era look different from new ones. Mitigation: keep stored snapshots immutable; new metrics only render in live views.

## Cross-references

- **Proposal 009 / F-017 (Velocity Dashboard)** — extends the renderer this feature shipped
- **Proposal 018 / F-018 (Visual Richness)** — composes with the rich-rendering work; new metrics use the same render-mode primitives
- **Proposal 046 (Auto-Render Dashboard)** — when 046 fires the dashboard at closeout boundaries, it'll render the new metrics automatically
- **Proposal 047 (Project Governance Profile)** — could add a `velocity_headline_metric` dial letting users pick recent-weighted vs trailing vs peak as their preferred headline

## Status history

- 2026-05-18: candidate captured after maintainer observed that the trailing-10 SP/day average (11.04) significantly understated the actual recent pace (15-16 SP/iter-day for F-020 iterations; 31 SP delivered in a single ~7-hour session). The dashboard's headline is conservative by design but slow to recognize acceleration.
