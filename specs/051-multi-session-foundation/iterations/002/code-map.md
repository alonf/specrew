# Code Map: Iteration 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Reviewed**: 2026-05-31
**Baseline Ref**: 4fe1ff610b7ae7c1dab9807324427e6b3ad31b00
**Test-to-Code Ratio**: focused

## Files Touched

| Path | Owning Task ID(s) | Owning Role | Review Note |
| ---- | ----------------- | ----------- | ----------- |
| `scripts/internal/atomic-write.ps1` | T020, T026b, T027 | Implementer | Shared atomic write helper used by locks and claims. |
| `scripts/internal/yaml-list.ps1` | T020, T027 | Implementer | Minimal YAML-list serializer/parser for lock and claim files. |
| `scripts/internal/specrew-time.ps1` | T020, T027, T029 | Implementer | UTC parsing/formatting helper for monotonic refresh and stale detection. |
| `scripts/internal/session-management.ps1` | T020-T026b | Implementer | Active-session lock read/write, local fingerprint, collision, stale clear, remove. |
| `scripts/internal/feature-claims.ps1` | T027-T033 | Implementer | Feature-claim read/write, add/update/remove, conflict detection. |
| `scripts/internal/file-classification.ps1` | T020c | Implementer | Adds `.specrew/active-sessions.yml` as per-session/gitignored. |
| `scripts/internal/session-config.ps1` | T020 | Implementer | Uses extracted shared atomic-write helper instead of local copy. |
| `scripts/internal/sync-boundary-state.ps1` | T022, T028, T029, T031 | Implementer | Wires feature claim lifecycle and feature-closeout lock cleanup. |
| `scripts/specrew-start.ps1` | T021, T023, T024, T030 | Implementer | Wires stale clear, collision warnings, claim conflict prompt, and session registration. |
| `Specrew.psd1` | T020, T027 | Implementer | Registers new helper modules in FileList. |
| `tests/unit/feature-051-session-management.tests.ps1` | T025, T026, T026b | Implementer | Focused lock module coverage. |
| `tests/unit/feature-051-feature-claims.tests.ps1` | T032, T033 | Implementer | Focused claim module coverage. |
| `tests/unit/feature-051-file-classification.tests.ps1` | T020c | Implementer | Verifies per-session pattern coverage. |
| `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1` | T021-T033 | Implementer | Real temp-repo replay of start and boundary-sync wiring. |
| `specs/051-multi-session-foundation/data-model.md` | T033b | Reviewer | Reconciles shipped lock/claim semantics. |
| `specs/051-multi-session-foundation/iterations/002/*` | T033b | Reviewer | Review, coverage, code map, diagrams, state, and task tracking evidence. |

## Public-API Delta

### Added

- `Write-SpecrewFileAtomic`
- `Get-MachineFingerprint`
- `Read-ActiveSessions`
- `Write-ActiveSessions`
- `Register-SessionLock`
- `Remove-SessionLock`
- `Test-SessionCollision`
- `Clear-StaleSessionLocks`
- `Get-SpecrewCoarseIdentity`
- `Read-FeatureClaims`
- `Write-FeatureClaims`
- `Add-FeatureClaim`
- `Update-FeatureClaim`
- `Remove-FeatureClaim`
- `Test-FeatureClaimConflict`

### Removed

- Local-only `Write-SpecrewFileAtomic` implementation from `session-config.ps1`; replaced by shared helper.

## Module Hotspots

- none

