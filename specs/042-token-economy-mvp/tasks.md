# Tasks: Token Economy MVP (Iteration 001)

**Feature**: F-042 / Proposal 070 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Research**: [research.md](./research.md)
**Iteration**: 001 (target: cover full FR scope in single iteration)
**Total SP**: ~5.75 SP
**Dependencies**: F-041 merged to main (provides catalog with cost-per-token + tokenizer hints). Implementation work begins AFTER F-040 → F-041 sequence merges.

## Task list

| ID | Task | Owner | SP | Deps | Test evidence |
|---|---|---|---|---|---|
| T001 | Create `scripts/internal/cost-tracking.ps1` with helpers: `Get-SpecrewCostYml`, `Add-SpecrewCostRecord`, `Update-SpecrewCostAggregates`, `Get-SpecrewCostAggregatesForFeature` | Implementer | 1 | F-041 merged | unit tests for each helper |
| T002 | Define cost.yml schema at `scripts/internal/cost-yml-schema.yml` + validator function `Test-SpecrewCostYmlSchema` | Implementer | 0.5 | T001 | schema-conformance test on fixture cost.yml |
| T003 | Implement `Get-SpecrewTokenEstimate` with naive byte/4 fallback + per-model tokenizer dispatch from F-041 catalog hint. Tokenizer invocation stubbed (returns naive estimate) in v1; actual tokenizer wiring follow-up | Implementer | 0.5 | T001 | tokenizer dispatch test; naive fallback test |
| T004 | Extend `scripts/internal/sync-boundary-state.ps1` `Invoke-SpecrewBoundaryStateSync` to call `Add-SpecrewCostRecord` AFTER F-039 authorization passes; records boundary + role + tokens + cost + host (from F-040 selected_host) | Implementer | 1 | T001, T003 | end-to-end test: boundary advance writes cost record; F-039 gate fires before record write |
| T005 | Extend `scripts/internal/dashboard-renderer.ps1` with COST block reader; aggregates cost.yml across recent N iterations; renders between VELOCITY and RECENT SHIPPED with trend classification | Implementer | 1 | T001, T002 | dashboard render test with fixture iterations across hosts |
| T006 | Create `scripts/specrew-cost.ps1` with three subcommand dispatchers: `summary`, `add`, `recompute`. Wire entry alias via scripts/specrew.ps1 | Implementer | 0.75 | T001 | CLI invocation tests for each subcommand |
| T007 | Create `tests/integration/token-economy-mvp.tests.ps1` covering all 12 FRs (FR-001 through FR-012) | Implementer | 1 | T001-T006 | 18+ assertions; cross-platform |
| T008 | Update `docs/user-guide.md` with "Cost Tracking" section (cost.yml schema + `specrew cost` CLI examples + dashboard COST screenshot reference) | Implementer | 0.25 | T001-T006 | docs render |
| T009 | Update `docs/dashboard-guide.md` with COST section + per-host attribution explanation | Implementer | 0.25 | T005 | docs render |
| T010 | Bump version to 0.28.0 across 4 manifests (Specrew.psd1, .specrew/config.yml, extensions/specrew-speckit/extension.yml, .specify/extensions/specrew-speckit/extension.yml) | Implementer | 0.25 | - | version-consistency validator passes |
| T011 | Update `CHANGELOG.md` with F-042 entry under v0.28.0 | Implementer | 0.25 | T010 | CHANGELOG renders |
| T012 | Flip `proposals/070-token-economy-mvp.md` `status: draft` → `status: shipped`; add shipped-as/version metadata | Implementer | 0.25 | T010 | proposal frontmatter validates |
| T013 | Update `proposals/INDEX.md` — move 070 from Draft to Shipped; decrement Draft count | Implementer | 0.25 | T012 | INDEX renders |

## Dependency graph

```
F-041 merged ──► T001 ─┬─► T002 ─┬─► T005 ─┐
                       │         │         │
                       ├─► T003 ─┤         ├─► T007 ──► T008, T009
                       │         │         │
                       ├─► T004 ─┘         │
                       │                   │
                       └─► T006 ───────────┘
                                           │
T010 ──► T011, T012 ──► T013 ──────────────► (closeout-ready)
```

T001-T006 form the core feature path; T007-T013 are testing + housekeeping.

## Iteration-001 acceptance criteria

| AC | Validates FR(s) | Task evidence |
|---|---|---|
| AC1 | FR-001 (cost.yml artifact created on boundary advance) | T004 |
| AC2 | FR-002 (record schema: timestamp/boundary/role/host/model/tokens/cost/source) | T001, T002 |
| AC3 | FR-003 (per-model tokenizer with naive fallback) | T003 |
| AC4 | FR-004 (cost computation from F-041 catalog cost-per-token) | T001, T003 |
| AC5 | FR-005 (aggregates block with by_host + by_role) | T001 |
| AC6 | FR-006 (cost_estimate_confidence: low when catalog incomplete) | T001, T003 |
| AC7 | FR-007 (dashboard COST section between VELOCITY and RECENT SHIPPED) | T005 |
| AC8 | FR-008 (`specrew cost summary` CLI) | T006 |
| AC9 | FR-009 (`specrew cost add` manual entry) | T006 |
| AC10 | FR-010 (`specrew cost recompute` re-estimates source: estimated only) | T006 |
| AC11 | FR-011 (Antigravity enum entry but only-active-hosts write records) | T001 |
| AC12 | FR-012 (cost.yml writes inside F-039 boundary-sync flow) | T004 |

## Out of iteration

- `source: reported` host-CLI parsers (Claude first, then Codex, then Copilot via API)
- Cache for dashboard COST section (small-fix when iteration count grows past ~500)
- Per-developer cost-per-SP dashboards (Proposal 092 Web App)
- Cost-priority feature ordering (Proposal 028 / 033 governance CLI)
- Cost forecasting per feature scope (Proposal 040 architectural parent)

## Boundary checklist (per F-039 boundary discipline)

- [x] specify-boundary: completed 2026-05-23 with spec.md + 4 clarify defaults
- [ ] clarify-boundary: AWAITING user review of clarify defaults (Q1-Q4)
- [ ] plan-boundary: AWAITING user verdict — full artifact suite ready for review
- [ ] tasks-boundary: requires plan-boundary verdict to authorize
- [ ] before-implement: requires tasks-boundary verdict AND F-041 merged to main
- [ ] review-signoff: post-implementation
- [ ] retro: after review-signoff
- [ ] iteration-closeout: after retro
- [ ] feature-closeout: after iteration-closeout

## Open questions for user (clarify-boundary review)

The 4 clarify defaults are documented inline in spec.md. Quick summary for review:

1. **Q1 — Tokenizer dispatch**: Per-model tokenizer where available + naive fallback. Catalog v2 (F-041) records tokenizer hint per model.
2. **Q2 — `source: reported` in v1?**: Estimated-only in v1; reported-mode parsers ship as follow-up small-fix per host (Claude first per richest surface).
3. **Q3 — Record granularity**: Per-boundary AND per-role. Aggregation computed at read-time.
4. **Q4 — Dashboard COST refresh**: Auto-render every `specrew where` invocation; no cache.
