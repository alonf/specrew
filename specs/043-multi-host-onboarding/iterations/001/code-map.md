# Iteration 001 Code Map

**Feature**: F-043 Multi-Host Onboarding + Selection Flow
**Iteration**: 001

## Surface inventory

| Concern | File(s) | FR(s) | Status |
|---|---|---|---|
| `host-history.json` schema + read/write/migrate helpers | `scripts/internal/host-history.ps1` | FR-001, FR-004 | Shipped |
| Host-selection priority chain | `scripts/specrew-start.ps1` lines 3668-3745 (`# F-040 + F-043: Host selection chain (per F-043 spec FR-002)` block) | FR-002, FR-012, FR-013 | Shipped |
| First-run probe | `Invoke-SpecrewFirstRunHostProbe` in `scripts/internal/host-runtime-inventory.ps1` | FR-003 | Shipped |
| `specrew host` CLI surface | `scripts/specrew-host.ps1` | FR-005, FR-006, FR-007 | Shipped |
| `host_resolution` field in start-context.json | `Save-StartArtifacts` in `scripts/specrew-start.ps1` (param `-HostResolution`) | FR-012 | Shipped |
| Non-TTY guidance | `non-interactive-no-default` branch in host-gate | FR-013 | Shipped |
| Deferred Category A migration | (no files) | FR-008, FR-009, FR-011 | Deferred |
| Category B preservation (design constraint) | n/a (no-op) | FR-010 | Honored |

## Test coverage

- `tests/integration/multi-host-launch-path.tests.ps1` — F-040 suite, regression-covers F-043 host-selection invariants
- `tests/integration/specrew-start-{baseline-tracking,auto-continue-preservation,change-detector}.ps1` — exercises the `-NoLaunch` path through the host-gate (F-043 wiring)
- `tests/integration/multi-host-onboarding.tests.ps1` (planned T010) — F-043-specific assertions; **not yet implemented** (queued for follow-up)

## Dependencies on F-044

F-043's runtime code dot-sources:

- `hosts/_registry.ps1` (F-044 Phase A) — for `Invoke-HostHandler`
- `scripts/internal/host-runtime-inventory.ps1` (refactored in F-044 Phase C) — for `Get-SpecrewHostRuntimeInventory`

Without F-044's registry-driven substrate, `specrew host list` could not enumerate hosts manifest-driven, and `Resolve-SpecrewHostFromHistory` could not validate kinds against the supported-host enum.
