# Code Map: Iteration 006

**Schema**: v1
**Reviewed**: 2026-07-16
**Baseline Ref**: `5adc9d8cc9667fa15ea7537108d6be94396dc716`
**Reviewed HEAD**: `2157017f77a225f9497c44ffb013e101bff6f2a7`
**Reviewed-State Digest**: `bedc0172de77fda277f764cd07b90d5af291e2cc`

## Production Surface

| Path | Responsibility | Task(s) |
| --- | --- | --- |
| `scripts/internal/continuous-co-review/review-authority-cutover.ps1` | Singular legacy/campaign authority seam | T041 |
| `scripts/internal/continuous-co-review/review-authority-core.ps1` | Closed contracts, allowance/run/currentness/lineage policy, shared timing bounds | T042–T044 |
| `scripts/internal/continuous-co-review/review-authority-store.ps1` | Immutable CreateNew facts, reservations, claims, reconciliation | T045 |
| `scripts/internal/continuous-co-review/review-target-port.ps1` | External Git worktree target, integrity, currentness, disposal | T046 |
| `scripts/internal/continuous-co-review/review-result-ingestor.ps1` | Strict candidate validation and controller terminal publication | T047 |
| `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1` | Synchronous preflight/spend/runtime/ingress composition | T048 |
| `scripts/internal/continuous-co-review/review-claude-harness-port.ps1` | Scoped file-primary Claude candidate delivery | T050 |
| `scripts/internal/continuous-co-review/review-authority-mode.json` | Explicit legacy/campaign construction mode | T041 |
| `scripts/internal/continuous-co-review/_load.ps1` | Runtime module loading | T041, T048, T050 |
| `scripts/internal/continuous-co-review/co-review-service.ps1` | Legacy service suppression at the cutover seam | T041 |
| `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1` | Legacy-result advisory treatment under campaign authority | T041 |
| `Specrew.psd1` | Packaged-artifact FileList entries for the authority foundation | T049, T050 |

## Test Surface

| Path | Behavior proved |
| --- | --- |
| `tests/continuous-co-review/unit/review-authority-cutover.Tests.ps1` | Fail-closed mode matrix and legacy-spawn suppression |
| `tests/continuous-co-review/unit/review-authority-core.Tests.ps1` | Closed schemas, allowance/run policy, currentness, timing bounds, lineage |
| `tests/continuous-co-review/unit/review-authority-store.Tests.ps1` | Immutable conflict/idempotency, multi-process winners, crash reconciliation |
| `tests/continuous-co-review/unit/review-target-port.Tests.ps1` | External placement, exact dirty-state digest, origin immutability, target neutrality |
| `tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1` | Strict ingress, identity substitution, partial/moved/timeout/duration publication |
| `tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1` | Port composition, no-spend preflight, recovery, file-primary malformed/raw pair |
| `tests/f198-iteration006-foundation.ps1` | Deterministic eight-suite foundation registry |
| `tests/f198-regression-suite.ps1` | Complete 45-suite Feature 198 regression registry |

## Public Surface and Hotspots

- The iteration adds internal PowerShell functions and one packaged JSON configuration; no new external package or service is introduced.
- Primary policy hotspot: `review-authority-core.ps1` (790 added lines), intentionally dependency-free and exhaustively exercised by pure tests.
- Primary storage hotspot: `review-authority-store.ps1` (390 added lines), isolated from policy and proven with barrier-synchronized processes.
- Primary orchestration hotspot: `review-campaign-orchestrator.ps1` (285 added lines), composed through explicit target/harness/runtime/store/clock ports.
