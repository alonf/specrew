# Velocity Dashboard Guide

Feature 017 adds a console-first dashboard for answering "where are we right now?"
from canonical repository artifacts.

## Commands

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where
pwsh -NoProfile -File .\scripts\specrew.ps1 status
pwsh -NoProfile -File .\scripts\specrew-where.ps1
```

Useful flags:

- `--compact` keeps the dashboard within the fixed 24-line budget.
- `--no-color` forces monochrome output.
- `--team` explains the reserved multi-developer path, then falls back to the
  personal dashboard.
- `--output-path` writes a closeout snapshot when invoked from lifecycle tooling.
- `--capture-kind` labels snapshots as `iteration-closeout` or `feature-closeout`.

## Section Order

1. Summary line (active feature, phase, velocity, ETA cues)
2. Active work
3. Velocity
4. Recent shipped work
5. Recent iterations (plan vs reality)
6. Full history
7. Roadmap
8. Projection (multi-scope ETA)
9. Warnings

## Automatic closeout snapshots

- Iteration closeout scaffolds `specs/<feature>/iterations/<NNN>/dashboard.md`.
- Feature closeout scaffolds `specs/<feature>/closeout-dashboard.md`.

Both files are historical snapshots captured during closeout. Re-running the
dashboard later produces a fresh live view and must not overwrite these files.

## Sample output

```text
SPECREW VELOCITY DASHBOARD
Summary: feature-017 (In Progress · phase executing) | Velocity 17 SP/day (2 closed iterations, low) | ETA: feature 1 calendar day(s) · phase 2 calendar day(s) · roadmap 2 calendar day(s)
Repo: healthy-repository | Branch: 017-velocity-dashboard | Captured: 2026-05-15T11:30:28Z

ACTIVE WORK
Feature: 017-velocity-dashboard (Feature Specification: Velocity Dashboard) | status In Progress
Iteration: feature-017.iter-001 | planned 11 SP | phase EXECUTING | started 2026-05-05
In-flight: 11 SP planned · 0 SP delivered · 11 SP remaining

VELOCITY
Headline: 17 SP/day from 2 closed iteration(s) (34 SP / 2 total days, avg 1 days) | confidence low
Recent sample: 15 / 19

RECENT SHIPPED
feature-016.iter-001    15 SP ########### (2026-05-04)
feature-015.iter-001    19 SP ############## (2026-05-02)

RECENT ITERATIONS (PLAN VS REALITY)
Iter                  Planned Actual Delta Days
feature-016.iter-001      15     15     0    1
feature-015.iter-001      19     19     0    1

FULL HISTORY
feature-016.iter-001    15 SP ###########
feature-015.iter-001    19 SP ##############

ROADMAP
Foundations: [################] 100% | declared shipped | effective shipped | derived 19/19 SP
Visibility (current): [#######.........]  44% | declared in-progress | effective in-progress | derived 15/34 SP

PROJECTION
Active feature remaining: 11 SP | ETA: 1 calendar day(s) | confidence low
Current phase remaining: 19 SP | ETA: 2 calendar day(s) | confidence low
Roadmap remaining: 19 SP | ETA: 2 calendar day(s) | confidence low

WARNINGS
WARN: Velocity uses only 2 closed iteration(s); confidence remains low until 4+ iterations are available.
```

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
- **Why does `--team` fall back?** Multi-developer aggregation is still deferred in
  v1, so the command explains the limitation and renders the personal dashboard.
