# Data Contracts

## Schema evolution

- `v0` is implicit legacy state: the file omits a top-level `schema` marker.
- `v1` is the current explicit contract: new state writers must emit `schema: v1` (YAML/frontmatter) or `"schema": "v1"` (JSON).
- Future schema upgrades must preserve reader tolerance for older fixtures and add a new current-version fixture under `tests/fixtures/legacy-versions/`.

## Writer contract

Writers must emit explicit `v1` schema markers for Specrew state artifacts:

- `.specrew/config.yml`
- `.specrew/start-context.json`
- `.specrew/last-validator-summary.json`
- `.specify/feature.json`
- `.specify/extensions/specrew-speckit/extension.yml` (`schema` is distinct from `extension.version`)
- `.squad/identity/now.md`

Writers should preserve unrelated existing fields when refreshing an artifact, but they must normalize the schema marker back to `v1`.

## Reader contract

- JSON state readers must use `ConvertFrom-Json -AsHashtable`.
- Access optional fields through hashtable indexers (`$state['field']`) or `.Contains(...)` checks.
- Missing top-level `schema` means `v0`; emit `schema-implied-v0` on the debug stream when that fallback is taken.
- Unsupported explicit schemas must fail fast instead of silently rewriting unknown formats.
- Missing files and malformed optional state should return `$null` where the caller expects an optional artifact, not a `PropertyNotFoundException`.
- The canonical schema-version extraction helper is `Get-SpecrewStateSchemaVersion` in `extensions/specrew-speckit/scripts/shared-governance.ps1`. New readers must call it rather than re-implementing the v0/v1 detection.

## Fixture maintenance

When a feature changes any state-file schema or reader behavior:

1. Preserve older fixture directories as historical evidence.
2. Add or refresh the current Specrew version fixture in `tests/fixtures/legacy-versions/<current-version>/`.
3. Include only representative state artifacts: hand-curated when drift matters, generated when the format is deterministic, snapshot-based when the real lifecycle output is the contract.
4. Extend both Windows and Linux validation to exercise the new fixture.

- The regression contract that exercises the corpus is `tests/integration/Test-LegacyStateReaders.Tests.ps1`. Any new fixture file or reader migration must be reflected there.
- See the fixture coverage matrix in `specs/023-legacy-state-read-tolerance/checklists/state-reader-audit.md` for the current per-version presence/absence rationale.

## Cross-platform rules

- Run regression scripts with `pwsh -NoProfile -File`.
- Do not assume Windows path separators; normalize with `Join-Path` and repo-relative paths.
- Write UTF-8 artifacts without relying on platform-specific defaults.
- Keep fixture assertions insensitive to line-ending differences unless line endings are the contract under test.
