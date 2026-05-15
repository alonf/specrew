# Quality Evidence: Feature 017 Iteration 001

## Automated Evidence

- `pwsh -NoProfile -File tests/integration/feature-017-dashboard-core.ps1`
- `pwsh -NoProfile -File tests/unit/feature-017-dashboard.tests.ps1`
- `pwsh -NoProfile -File extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`

## Manual Review Notes

- The dashboard keeps one ordered section model across the CLI command, alias, direct script, and persisted artifact surfaces.
- Missing or malformed roadmap inputs degrade with calm `WARN:` guidance rather than crashing the render.
- Closeout snapshots are historical artifacts, not a mutable current-status file.

## Stack Surface Coverage

- CLI dispatch and rendering: `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, `scripts/internal/dashboard-renderer.ps1`
- Dashboard data and roadmap: `.specify/feature.json`, `.specrew/roadmap.yml`, `specs/*/iterations/*`
- Closeout and validator integration: `extensions/specrew-speckit/scripts/*.ps1`, mirrored `.specify` scripts, `.specrew/quality/known-traps.md`
- Documentation and discovery: `README.md`, `docs/dashboard-guide.md`, `docs/roadmap-maintenance.md`, `docs/getting-started.md`, `docs/user-guide.md`, `.github/copilot-instructions.md`
- Test fixtures and replay: `tests/integration/feature-017-dashboard-core.ps1`, `tests/unit/feature-017-dashboard.tests.ps1`, fixture repositories under `tests/integration/fixtures/feature-017-dashboard/`
