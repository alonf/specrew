# Feature 017 Dashboard Quickstart Checks

Run these commands from the repository root after the dashboard implementation is present:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color
pwsh -NoProfile -File .\scripts\specrew.ps1 where --ASCII
pwsh -NoProfile -File .\scripts\specrew.ps1 where --RecentCount 4 --BarWidth 20
pwsh -NoProfile -File .\scripts\specrew.ps1 status --compact --no-color
pwsh -NoProfile -File .\scripts\specrew-where.ps1 --team --no-color
pwsh -NoProfile -File .\tests\integration\feature-017-dashboard-core.ps1
pwsh -NoProfile -File .\tests\unit\feature-017-dashboard.tests.ps1
pwsh -NoProfile -File .\tests\integration\feature-018-rich-dashboard.ps1
pwsh -NoProfile -File .\tests\unit\feature-018-dashboard.tests.ps1
pwsh -NoProfile -File .\tests\integration\feature-018-render-budget.ps1
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Manual spot-check expectations:

- `where`, `status`, and `specrew-where.ps1` render the same dashboard sections in the same order.
- Rich mode appears by default only when the terminal is truly eligible.
- `--ASCII` and `--no-color` force the monochrome-safe fallback without changing meaning.
- `--RecentCount` and `--BarWidth` change density only; they do not change the underlying data.
- Compact mode stays within 24 lines.
- `--team` explains the reserved fallback before rendering the personal dashboard.
- Missing or malformed roadmap inputs emit bounded warnings instead of crashing.
- Stored dashboard snapshots strip ANSI escape sequences while preserving Unicode glyphs.
- Validator output may emit `WARN [dashboard]` lines for roadmap drift or missing closeout snapshots.
