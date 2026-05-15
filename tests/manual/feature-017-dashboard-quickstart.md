# Feature 017 Dashboard Quickstart Checks

Run these commands from the repository root after the dashboard implementation is present:

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color
pwsh -NoProfile -File .\scripts\specrew.ps1 status --compact --no-color
pwsh -NoProfile -File .\scripts\specrew-where.ps1 --team --no-color
pwsh -NoProfile -File .\tests\integration\feature-017-dashboard-core.ps1
pwsh -NoProfile -File .\tests\unit\feature-017-dashboard.tests.ps1
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Manual spot-check expectations:

- `where`, `status`, and `specrew-where.ps1` render the same dashboard sections in the same order.
- Compact mode stays within 24 lines.
- `--team` explains the reserved fallback before rendering the personal dashboard.
- Missing or malformed roadmap inputs emit bounded warnings instead of crashing.
- Validator output may emit `WARN [dashboard]` lines for roadmap drift or missing closeout snapshots.
