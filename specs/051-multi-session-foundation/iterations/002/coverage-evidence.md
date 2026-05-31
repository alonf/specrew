# Coverage Evidence: Iteration 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Reviewed**: 2026-05-31
**Overall Verdict**: pass

## Test Strategy

Iteration 2a uses focused PowerShell replay coverage against real temporary
project files. Unit-level tests exercise the lock and claim modules directly;
the call-site integration test exercises `specrew start` and boundary-sync
through a temporary git repository.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-051-session-management.tests.ps1` | pass | 24 | 0 | <1m | 0 | Covers session lock read/write, local-only fingerprint, register/remove, collision detection, stale clear, corrupt YAML safe degradation, and deterministic atomic-write race. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\feature-051-feature-claims.tests.ps1` | pass | 13 | 0 | <1m | 0 | Covers claim add/upsert, monotonic refresh, manual-removal re-add, conflict detection, remove, and corrupt YAML safe degradation. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\feature-051-iteration2a-callsite-wiring.tests.ps1` | pass | 6 | 0 | <1m | 0 | Covers specify claim create, boundary refresh, start-time stale clear + collision warning + session register, closeout claim/lock removal, and claim conflict continue/decline. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\stale-state-detection.tests.ps1` | pass | 5 | 0 | <2m | 0 | Adjacent start-path regression stayed green after start-time guard wiring. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\boundary-sync-atomicity.tests.ps1` | pass | 2 | 0 | <1m | 0 | Adjacent boundary-sync atomicity regression stayed green after claim refresh wiring. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\lifecycle-boundary-sync.tests.ps1` | blocked | 0 | 1 | <2m | 1 | Attempted adjacent regression failed on a pre-existing feature-closeout working-tree gate in its fixture path (`specs/022-hotfix-schema-tests/iterations/`) while resolving installed Specrew 0.29.0, not this dev tree. Not counted as Iteration 2a failure. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: PowerShell script assertions + Specrew validator

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-005 | `tests/unit/feature-051-file-classification.tests.ps1`; verified by focused suite history and data-model reconciliation |
| FR-007 | `tests/unit/feature-051-session-management.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-008 | `tests/unit/feature-051-session-management.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-009 | `tests/unit/feature-051-session-management.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-010 | `tests/unit/feature-051-session-management.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-011 | `tests/unit/feature-051-session-management.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-012 | `tests/unit/feature-051-feature-claims.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-013 | `tests/unit/feature-051-feature-claims.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-014 | `tests/unit/feature-051-feature-claims.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-015 | `tests/unit/feature-051-feature-claims.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-016 | `tests/unit/feature-051-feature-claims.tests.ps1`; `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` |
| FR-043 | `tests/unit/feature-051-session-management.tests.ps1`; local-only fingerprint implementation and data-model reconciliation |
