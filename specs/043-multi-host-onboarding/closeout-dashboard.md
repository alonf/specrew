# F-043 Feature Closeout Dashboard

**Feature**: F-043 Multi-Host Onboarding + Selection Flow
**Source proposal**: Proposal 104 (Multi-Host Onboarding + Selection Flow)
**Shipped on branch**: `multi-host-integration-refactor` (bundled with F-044 per architectural co-evolution; merges to main as one PR)
**Closeout date**: 2026-05-24

## Delivery summary

| Metric | Planned | Actual | Variance |
|---|---|---|---|
| Story points | ~20 SP | ~12 SP (9 FRs shipped; 4 deferred) | -8 SP via explicit scope cut |
| Iterations | 1 | 1 | 0 |
| FRs delivered | 13 | 9 | -4 (deferred to follow-up slice, see [iter-001 scope.md](./iterations/001/scope.md)) |
| ACs verified | 13 | 9 PASS + 4 DEFERRED | -4 |
| Implementation commits | (planned per tasks.md) | 4 (`487c653f` spec/plan, `d9868035` draft, `39b4e48d` MVP, `755c87f1` wiring) | n/a |

## FR scoreboard

| FR | Scope | Status |
|---|---|---|
| FR-001 | `host-history` schema | ✅ Shipped (as `.json` per [drift-log #1](./iterations/001/drift-log.md)) |
| FR-002 | Host-selection priority chain | ✅ Shipped |
| FR-003 | First-run probe | ✅ Shipped |
| FR-004 | History update on every selection | ✅ Shipped |
| FR-005 | `specrew host list` | ✅ Shipped |
| FR-006 | `specrew host use` | ✅ Shipped |
| FR-007 | `specrew host status` | ✅ Shipped |
| FR-008 | `specrew init` writes Category A to `.specrew/coordinator/` | ⏳ Deferred to follow-up slice |
| FR-009 | `specrew update` migrates brownfield | ⏳ Deferred to follow-up slice |
| FR-010 | Category B stays host-native (design constraint) | ✅ Honored |
| FR-011 | Validators read `.specrew/coordinator/` | ⏳ Deferred to follow-up slice |
| FR-012 | `host_resolution` field in start-context.json | ✅ Shipped |
| FR-013 | Non-TTY guidance | ✅ Shipped |

## Architecture + design references

- Implementation substrate: F-044 Per-Host Architecture Refactor — see [../044-per-host-architecture-refactor/spec.md](../044-per-host-architecture-refactor/spec.md)
- Host registry contract: [hosts/_contract.md](../../hosts/_contract.md)
- Host-package architecture diagram (Mermaid): [docs/architecture/host-package-architecture.md](../../docs/architecture/host-package-architecture.md)

## Follow-up work queued

| Item | Vehicle | When |
|---|---|---|
| FR-008/009/011 Category A coordinator-content migration | Small-fix slice off F-043 | After F-044 merges to main |
| T010 `tests/integration/multi-host-onboarding.tests.ps1` | Small-fix slice (folds into Category A migration PR) | Same |
| Proposal 063 Substantive Intake Questioning structural fix for auto-draft gap | F-025 / F-029 (per current sequencing) | Phase 2b |

## Cross-feature bundle disclosure

This feature shipped on the same PR as **F-044 Per-Host Architecture Refactor** because the work co-evolved on the same branch — F-043's runtime depends on F-044's registry. The reader can navigate to each feature's iteration artifacts independently for a clean per-feature narrative.

| Bundle component | Spec | Iteration artifacts |
|---|---|---|
| F-043 (this) | [`spec.md`](./spec.md) | [`iterations/001/`](./iterations/001/) |
| F-044 (sibling) | [`../044-per-host-architecture-refactor/spec.md`](../044-per-host-architecture-refactor/spec.md) | [`../044-per-host-architecture-refactor/iterations/001/`](../044-per-host-architecture-refactor/iterations/001/) + [`002/`](../044-per-host-architecture-refactor/iterations/002/) |
