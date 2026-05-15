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

## Closeout snapshots

- Iteration closeout writes `specs/<feature>/iterations/<NNN>/dashboard.md`
- Feature closeout writes `specs/<feature>/closeout-dashboard.md`

Both files are historical snapshots and should be preserved once captured.

## FAQ

- **Why does velocity look low or uncertain?** Sparse history reduces confidence
  on purpose; the dashboard prefers calm uncertainty over fake precision.
- **What if roadmap status looks wrong?** Check `.specrew/roadmap.yml`, then rerun
  the dashboard and `validate-governance.ps1` to surface drift warnings.
- **What if there are no closed features yet?** The dashboard stays in empty-state
  mode and explains that the first closeout will seed velocity history.
- **Why does `--team` fall back?** Multi-developer aggregation is still deferred in
  v1, so the command explains the limitation and renders the personal dashboard.
