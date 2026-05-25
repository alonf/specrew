# Code Map: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-25
**Baseline Ref**: d5b2c431455dd13146ea4e3393c78f04ceede4dd
**Implementation Commits**: 0c871d59, 99eb985b
**Boundary Sync Commit**: 00d3c67a
**Test-to-Code Ratio**: focused integration regression

## Runtime Surface

| Path | Purpose | Owning Task ID(s) |
| ---- | ------- | ----------------- |
| `scripts/internal/skill-catalog-state.ps1` | Shared required-root detection, formatting, and repair invocation for skill catalogs. | T003 |
| `scripts/specrew-start.ps1` | Imports shared helper and repairs missing skill catalogs before normal start continuation. | T004, T011 |
| `scripts/specrew-init.ps1` | Imports shared helper and treats missing skill catalogs as deployable gaps on force and non-force paths. | T005, T012, T013 |
| `scripts/specrew.ps1` | Adds top-level version aliases through canonical version routing. | T009 |
| `scripts/specrew-version.ps1` | Gates undetermined-version warning to true installed-version unknown states. | T010 |

## Test Surface

| Path | Purpose | Owning Task ID(s) |
| ---- | ------- | ----------------- |
| `tests/integration/validate-versions-cli-behavior.ps1` | Covers Spec Kit version probe behavior plus `specrew version`, `--version`, `-v`, `--project-path`, and false-warning checks. | T007, T015 |
| `tests/integration/start-recovery-flow.tests.ps1` | Covers existing stale-state recovery plus start auto-repair and init force/non-force repair paths with local CLI shims. | T008, T015 |

## Governance And Evidence Surface

| Path | Purpose | Owning Task ID(s) |
| ---- | ------- | ----------------- |
| `specs/045-v0271-bugfix-bundle/iterations/001/finding-disposition.md` | F1-F7 actionable/deferred ledger. | T001 |
| `specs/045-v0271-bugfix-bundle/contracts/cli-behavior-contract.md` | Public CLI behavior contract for iteration 001 and deferred iteration 002 items. | T014 |
| `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | Runtime, mechanical, and governance evidence. | T015 |
| `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` | Mechanical check output with zero findings. | T015 |
| `specs/045-v0271-bugfix-bundle/iterations/001/plan.md` | Iteration task status and approved scope. | T007-T015 |
| `specs/045-v0271-bugfix-bundle/iterations/001/state.md` | Current lifecycle state snapshot. | T007-T015 |
| `specs/045-v0271-bugfix-bundle/iterations/001/tasks-progress.yml` | Per-task execution timestamps and statuses. | T007-T015 |

## Public API Delta

### Added

- `specrew --version`
- `specrew -v`

### Changed

- `specrew version` no longer emits `WARNING: Specrew version could not be determined.` when installed module metadata resolves successfully but project baseline metadata is absent.
- `specrew start` attempts skill-catalog repair through bundled runtime deployment when required roots are missing.
- `specrew init` validates skill catalog roots after repair/deployment and fails rather than returning false success when required roots remain missing.

### Dependencies

- No package or manifest dependency changes.

## Review Focus

- Scope discipline: no T002 or T016-T030 implementation was added.
- Runtime locality: repair targets are derived from host manifests and project-local root paths.
- Evidence integrity: tests were authored before implementation and rerun after implementation.
