# Code Map: Iteration 003 — Iteration 2b: Conflict Reduction & Multi-Developer Auto-Detection

**Schema**: v1
**Reviewed**: 2026-06-01
**Baseline Ref**: d1cae7d26a01f866299a7f42370f9b7ba25735e0
**Implementation Commit**: `3523cc80`
**Test-to-Code Ratio**: focused helper coverage plus existing F-051 regression lanes

## Files Touched

| Path | Owning Task ID(s) | Owning Role | Purpose |
| ---- | ----------------- | ----------- | ------- |
| `scripts/decisions-split.ps1` | T034, T040 | Implementer | Mirrors `.squad/decisions.md` entries into per-iteration markdown files. |
| `scripts/append-only-logs.ps1` | T036, T037 | Implementer | JSON Lines append/read primitives and lifecycle event writer. |
| `scripts/psd1-sort.ps1` | T038, T039, T041 | Implementer | Sorts `Specrew.psd1` FileList and preserves parseability. |
| `scripts/auto-detection.ps1` | T042-T046, T050-T052 | Implementer | Aggregates multi-developer signals and recommendation text. |
| `scripts/internal/sync-boundary-state.ps1` | T035, T037, T039, T049 | Implementer | Boundary-sync integration for decisions split, JSONL events, FileList sorting, and activity notes. |
| `scripts/specrew-start.ps1` | T047, T050 | Implementer | Welcome Orientation recommendation path after session registration. |
| `scripts/internal/dashboard-renderer.ps1` | T048, T050 | Implementer | `specrew where` multi-developer signal warning and compact/full indicator. |
| `Specrew.psd1` | T038, T041 | Implementer | FileList sorted and new helper scripts declared. |
| `tests/unit/feature-051-iteration2b.tests.ps1` | T040, T041, T051, T052, T054 | Implementer/Reviewer | Focused acceptance coverage for FR-017 through FR-024. |
| `specs/051-multi-session-foundation/data-model.md` | T053 | Reviewer | Reconciled aggregate `MultiDevSignal`, decision mirror, and lifecycle event schemas. |
| `specs/051-multi-session-foundation/contracts/multi-session-foundation.md` | T053 | Reviewer | Reconciled shipped helper names and on-disk public surfaces. |
| `specs/051-multi-session-foundation/quickstart.md` | T053, T054 | Reviewer | Added Iteration 2b replay commands and edge cases. |
| `specs/051-multi-session-foundation/tasks.md` | T034-T055 | Reviewer | Marked Iteration 2b tasks complete. |
| `specs/051-multi-session-foundation/iterations/003/plan.md` | T034-T055 | Reviewer | Marked task verdicts and effort actuals. |
| `specs/051-multi-session-foundation/iterations/003/state.md` | T034-T055 | Reviewer | Advanced iteration state to review with evidence summary. |
| `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml` | T034-T055 | Reviewer | Recorded task progress as done. |
| `specs/051-multi-session-foundation/iterations/003/quality/hardening-gate.md` | T034-T055 | Reviewer | Recorded runtime evidence for all hardening concerns. |
| `specs/051-multi-session-foundation/iterations/003/quality/mechanical-findings.json` | T055 | Reviewer | Mechanical checks found no findings. |
| `.specrew/last-validator-summary.json` | T055 | Reviewer | Latest validator summary for this run. |

## Public-API Delta

### Added

- `Split-SpecrewDecisionsByIteration`
- `Add-SpecrewJsonLine`
- `Read-SpecrewJsonLines`
- `Add-SpecrewLifecycleEvent`
- `Sort-SpecrewManifestFileList`
- `Get-SpecrewMultiDeveloperSignals`
- `Get-SpecrewMultiDeveloperRecommendation`

### Removed

- none

## Module Hotspots

- No changed source file exceeds the 250-line hotspot threshold.
- No package manifest changed; no new dependency surface was introduced.
