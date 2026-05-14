---
proposal: 009
title: Velocity Dashboard ("Where Am I?")
status: draft
phase: phase-2
estimated-sp: 19
discussion: tbd
---

# Velocity Dashboard ("Where Am I?")

## Why

Specrew has substantial state — closed iterations, active feature, queued backlog, roadmap phases — but no consolidated view that answers the developer's question at iteration close: "where am I in the larger project?"

Developers typically have to:
- Open multiple state.md files to track recent closures
- Mentally compute velocity from commit history
- Reference scattered memory entries for roadmap phases
- Guess at remaining effort

A console-rendered dashboard surfacing recent shipped features, rolling velocity, roadmap position, and effort projection — invoked automatically at every iteration-closeout — closes this visibility gap with minimal friction.

## What

A new command (`specrew where` and standalone `scripts/specrew-where.ps1`) that renders a five-section dashboard:

1. **Header**: Specrew version, today's date, bootstrap date
2. **Active work**: active feature, iteration position, in-flight SP
3. **Recent shipped features**: bar chart of last 6 features with SP totals, iteration counts, close dates
4. **Velocity**: rolling SP/day over a windowed sample
5. **Roadmap position**: per-phase progress bars (shipped vs planned SP)
6. **Effort projection**: working-days to MVP and 1.0

Five pillars:
1. Dashboard rendering — Unicode block characters, ANSI semantic color theme, `--NoColor` and `--Compact` flags
2. Structured roadmap source — `.specrew/roadmap.yml` replaces hardcoded phase array; auto-detection of shipped SP per phase
3. Color theme — semantic palette (green = shipped, yellow = active, gray = queued, red = blocked, cyan = identity), single constants block for replacement
4. Auto-invocation at iteration-closeout — coordinator-prompt rule writes `dashboard.md` artifact per iteration
5. User education — `--help`, `docs/dashboard.md`, README section, first-time-without-roadmap.yml friendly setup message

Forward-compatible multi-developer support: `--Team` flag exists as a stub in Iteration 1 (prints "team mode requires multi-developer reconciliation feature"); becomes real when Multi-Developer Reconciliation ships.

## Effort

- **Iteration 1 (~11 SP)**: Core rendering, structured roadmap source, color theme, flag stubs
- **Iteration 2 (~8 SP)**: Auto-invocation, user education, integration tests, corpus row
- **Total**: ~19 SP

## Phase placement

Phase 2 — after the queued graduation candidates and Methodology Site. Foundation already exists as a PoC script.

## Open questions

1. `dashboard.md` snapshot vs regenerable view?
2. `--Compact` line limit — fixed 24 lines or configurable?
3. Time projection visible or only raw remaining SP?
4. Partial-phase contribution vs all-or-nothing for shipped SP auto-detection?
5. `--Team` placeholder strategy — error / hidden / friendly message?
6. Git hooks integration for additional auto-invocations?
7. Top-level `.specrew/where-we-are.md` living document?
8. Calendar-days vs work-days velocity computation?
9. "Next likely feature" hint or descriptive only?
10. `NO_COLOR` environment variable support?

## Risks

- **Misleading velocity signal**: users might optimize for SP/day at the expense of quality. Mitigation: velocity is informational, not target; wide-error-bar disclaimer permanent.
- **Stale roadmap drift**: `.specrew/roadmap.yml` may not stay in sync with reality. Mitigation: corpus row `dashboard-out-of-sync` catches declared-vs-actual drift; auto-detection of shipped SP from real feature data reduces manual maintenance.
- **Color theme rendering**: older terminals may not support ANSI. Mitigation: standard 8-color subset; TTY detection; `--NoColor` and `NO_COLOR` fallbacks.

## Cross-references

- Composes with: Proposal 013 (Methodology Site) — dashboard screenshots as showcase content
- Forward-compatible with: Proposal 016 (Multi-Developer Reconciliation) — `--Team` mode becomes real
- Reference: Architecting Scalable Solutions, observability chapter

## Status history

- 2026-05-14: candidate captured during F-015 closeout discussion
- 2026-05-14: PoC drafted to validate concept (~250 lines PowerShell)
- 2026-05-14: status → draft; source spec written
