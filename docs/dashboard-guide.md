# Velocity Dashboard Guide

Feature 018 keeps the console-first dashboard from Feature 017 and adds richer
default rendering when the terminal can truthfully support it.

## Commands

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where
pwsh -NoProfile -File .\scripts\specrew.ps1 status
pwsh -NoProfile -File .\scripts\specrew-where.ps1
```

Useful flags:

- `--compact` keeps the dashboard within the fixed 24-line budget.
- `--ASCII` forces the ASCII-safe fallback.
- `--no-color` forces the monochrome-safe fallback.
- `--RecentCount <N>` changes how many Recent Shipped rows are shown (default 6).
- `--BarWidth <N>` changes the rich-mode shipped-bar width (default 28).
- `--team` explains the reserved multi-developer path, then falls back to the
  personal dashboard.
- `--output-path` writes a closeout snapshot when invoked from lifecycle tooling.
- `--capture-kind` labels snapshots as `iteration-closeout` or `feature-closeout`.

## Section Order

1. Header + summary
2. Active work
3. Velocity
4. Recent shipped work
5. Recent iterations (plan vs reality)
6. Full history
7. Roadmap
8. Projection (multi-scope ETA)
9. Warnings
10. Footer guidance

## Automatic closeout snapshots

- Iteration closeout scaffolds `specs/<feature>/iterations/<NNN>/dashboard.md`.
- Feature closeout scaffolds `specs/<feature>/closeout-dashboard.md`.

Both files are historical snapshots captured during closeout. Re-running the
dashboard later produces a fresh live view and must not overwrite these files.
Stored snapshots strip ANSI escape sequences but preserve readable Unicode
glyphs.

## Rich-mode highlights

```text
SPECREW VELOCITY DASHBOARD
Today: 2026-05-15 | Captured: 2026-05-15T11:30:28Z
Repo: specrew | Branch: 018-velocity-dashboard-visual-richness
Rendering: rich default
Summary: → F-018 Velocity Dashboard Visual Richness (In Progress · phase executing) | Velocity 11.33 SP/day (6 closed iterations, moderate)

ACTIVE WORK
Feature: → F-018 | Velocity Dashboard Visual Richness | status In Progress

VELOCITY
Headline: 11.33 SP/day | confidence moderate
Sample basis: Based on 6 closed iteration(s), 73 SP across 7 calendar day(s) (avg 1.2 day(s)).
Sparkline: ▁▂▄▅▃█ | values 8 / 11 / 13 / 15 / 12 / 18

RECENT SHIPPED
✓ F-017 Velocity Dashboard | 18 SP | 1 iter | closed 2026-05-12 | ████████████████████████████

ROADMAP
◐ Richness (current) | [███████░░░░░░░░░]  47% | 14/30 SP | in-progress
  Restore rich dashboard density while preserving truthful fallback semantics a...
```

## Fallback rules

- `--ASCII` always wins and forces the ASCII-safe fallback.
- `--no-color`, `NO_COLOR`, `NO_UNICODE`, redirected output, `TERM=dumb`, and
  missing Windows VT support all force the monochrome-safe fallback.
- Rich mode requires UTF-8-capable output plus ANSI-capable live rendering.
- The sparkline appears only in the Velocity section.

## Reading pace responsibly

- Low sample sizes intentionally yield low confidence. Use the warning line to
  understand when the data is thin.
- The dashboard favors calm uncertainty over false precision, so expect `TBD`
  or low-confidence ETAs when history is sparse.

## Production upgrade vs proof of concept

The shipped dashboard improves on the original proof-of-concept script by
adding structured roadmap input, lifecycle closeout integration, documented
interpretation guidance, command-surface parity, validator drift warnings, and
fixture-backed tests.

## FAQ

- **Why does velocity look low or uncertain?** Sparse history reduces confidence
  on purpose; the dashboard prefers calm uncertainty over fake precision.
- **What if roadmap status looks wrong?** Check `.specrew/roadmap.yml` and
  `docs/roadmap-maintenance.md`, then rerun the dashboard and
  `validate-governance.ps1` to surface drift warnings.
- **What if there are no closed features yet?** The dashboard stays in empty-state
  mode and explains that the first closeout will seed velocity history.
- **Why is the dashboard plain even though Feature 018 shipped?** A fallback
  signal won: `--ASCII`, `--no-color`, `NO_COLOR`, `NO_UNICODE`, redirected
  output, `TERM=dumb`, missing UTF-8 support, or missing Windows VT support.
- **Why does `--team` fall back?** Multi-developer aggregation is still deferred in
  v1, so the command explains the limitation and renders the personal dashboard.
