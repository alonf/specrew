# Tasks: Cost-Aware Model Routing (Iteration 001)

**Feature**: F-041 / Proposal 068 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Research**: [research.md](./research.md)
**Iteration**: 001 (target: cover full FR scope in single iteration)
**Total SP**: ~10 SP (slightly over Proposal 068's 7-9 estimate; accommodates per-host injection complexity discovered in spec drafting)
**Dependencies**: F-040 merged to main (provides host enum + `selected_host` field + `available_hosts` probe). Implementation work begins AFTER F-040 PR #805 merges.

## Task list

| ID | Task | Owner | SP | Deps | Test evidence |
|---|---|---|---|---|---|
| T001 | Add `cost_profile` field to `.specrew/config.yml` template + specrew-init writes `cost_profile: lean` on greenfield + specrew-update brownfield migration with deprecation breadcrumb | Implementer | 1 | F-040 merged | config.yml schema test; round-trip read/write |
| T002 | Create `scripts/internal/cost-routing.ps1` with helpers: `Get-SpecrewCostProfile`, `Get-SpecrewModelCatalog`, `Test-SpecrewCatalogStaleness`, `Resolve-RoleToModelTier`, `Add-SpecrewRoutingDecisionEntry` | Implementer | 1.5 | T001 | unit tests for each helper |
| T003 | Define catalog v2 schema (YAML) at `scripts/internal/model-catalog-schema.yml` + corresponding validator function `Test-SpecrewModelCatalogSchema` (matches Proposal 068 enrichment) | Implementer | 1 | T002 | schema-conformance test on fixture catalog |
| T004 | Create `extensions/specrew-speckit/squad-templates/skills/specrew-research-models/SKILL.md` with YAML frontmatter (per F-021 contract) + body instructing the agent on the per-host research workflow + output schema | Implementer | 2 | T003 | skill-frontmatter validation; deploy to all 3 host-skill dirs via existing F-021 multi-host deploy |
| T005 | Add new numbered rule to `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (and mirror to `.specify/`) citing `.specrew/model-catalog.yml` + active `cost_profile` + role-tier mapping per FR-005 | Implementer | 1 | T004 | mirror parity validator; rule presence test |
| T006 | Create `scripts/internal/per-host-model-injection.ps1` with four dispatchers: `Set-CopilotModelOverride` (delegates to F-019 `Set-SquadModelOverrides`), `Set-ClaudeSubagentModel`, `Set-CodexAgentModel`, `Set-AntigravityModelOverride` (no-op placeholder) | Implementer | 2 | T002 | round-trip integrity test per dispatcher; bootstrap-only fallback test |
| T007 | Wire cost-routing into the boundary sync flow: when a routing decision is made (typically at plan/tasks boundary), `Add-SpecrewRoutingDecisionEntry` records the decision in `.squad/decisions.md` AND the matching per-host injection dispatcher is invoked | Implementer | 1.5 | T002, T006 | end-to-end routing test: lean profile + Claude host → cheap-tier model id appears in `.claude/agents/implementer.md` frontmatter |
| T008 | Create `tests/integration/cost-aware-routing.tests.ps1` covering all 13 FRs (FR-001 through FR-013) | Implementer | 1.5 | T001-T007 | 20+ assertions; CI passes on Windows + Linux |
| T009 | Update `docs/user-guide.md` with "Cost-Aware Model Routing" section: `cost_profile` field + `/specrew-research-models` skill + per-host injection mechanism + override precedence + stale-catalog behavior | Implementer | 0.5 | T001-T007 | docs render; example commands runnable |
| T010 | Bump version to 0.27.0 across the four manifests (Specrew.psd1, .specrew/config.yml, extensions/specrew-speckit/extension.yml, .specify/extensions/specrew-speckit/extension.yml) | Implementer | 0.25 | - | version-consistency validator passes |
| T011 | Update `CHANGELOG.md` with F-041 entry under v0.27.0 | Implementer | 0.25 | T010 | CHANGELOG renders; entry references Proposal 068 + Proposal 040 architectural parent |
| T012 | Flip `proposals/068-cost-aware-model-routing.md` `status: draft` → `status: shipped`; add `shipped-as: feature-041`, `shipped-version: 0.27.0` | Implementer | 0.25 | T010 | proposal frontmatter validates |
| T013 | Update `proposals/INDEX.md` — move 068 from Draft (15) to Shipped (24); decrement Draft count; update phase-breakdown if needed | Implementer | 0.25 | T012 | INDEX renders; counts match |

## Dependency graph

```
F-040 merged ──► T001 ──► T002 ─┬─► T003 ─► T004 ─► T005 ─┐
                                │                          │
                                └─► T006 ──► T007 ─────────┼─► T008 ──► T009
                                                           │
T010 ──► T011, T012 ──► T013 ──────────────────────────────► (closeout-ready)
```

T001-T007 form the core feature path. T008-T013 are testing + housekeeping.

## Iteration-001 acceptance criteria

Tied to FRs in spec.md:

| AC | Validates FR(s) | Task evidence |
|---|---|---|
| AC1 | FR-001 (cost_profile field) | T001 |
| AC2 | FR-002 (init + update writes cost_profile) | T001 |
| AC3 | FR-003 (discovery skill deployed to all 3 host-skill dirs) | T004 |
| AC4 | FR-004 (catalog v2 schema validates) | T003, T004 |
| AC5 | FR-005 (coordinator-governance rule cites catalog + cost_profile + role-tier mapping) | T005 |
| AC6 | FR-006 (staleness thresholds — warn at 30, auto-refresh at 90) | T002 |
| AC7 | FR-007 (routing decisions persist in .squad/decisions.md with full metadata) | T007 |
| AC8 | FR-008 (per-host selector_strategy dispatchers work for all 3 hosts) | T006, T007 |
| AC9 | FR-009 (bootstrap-only host fallback logs decision but skips per-host file update) | T006 |
| AC10 | FR-010 (explicit overrides win over profile defaults) | T002, T007 |
| AC11 | FR-011 (host-native built-in primitives honored — Claude opusplan when lean intent matches) | T002, T007 |
| AC12 | FR-012 (friction-dial integration placeholder; default-mode hardcoded) | T002 |
| AC13 | FR-013 (decisions logged in .squad/decisions.md canonical ledger regardless of host) | T007 |

## Out of iteration

- `balanced`, `premium`, `custom` cost-profile semantics (separate slices)
- Friction-dial integration once Proposal 100 ships (small-fix follow-up)
- F-042 cost.yml measurement layer (next feature)
- Antigravity host catalog entry (post-Antigravity small-fix slice)
- Pricing-change webhook / push notifications (future)
- Per-host model identity drift detection (future)
- Per-host decisions-ledger relocation (Proposal 024 Slice 3 / Proposal 104 Category A)

## Boundary checklist (per F-039 boundary discipline)

- [x] specify-boundary: completed 2026-05-23 with spec.md + 4 clarify defaults
- [ ] clarify-boundary: AWAITING USER review of the 4 clarify defaults (Q1-Q4) before plan approval
- [ ] plan-boundary: AWAITING user verdict — spec.md + plan.md + research.md + tasks.md ready for review
- [ ] tasks-boundary: requires plan-boundary verdict to authorize
- [ ] before-implement: requires tasks-boundary verdict AND F-040 merged to main
- [ ] review-signoff: post-implementation
- [ ] retro: after review-signoff
- [ ] iteration-closeout: after retro
- [ ] feature-closeout: after iteration-closeout (single-iteration feature)

## Open questions for user (clarify-boundary review)

The 4 clarify defaults are documented inline in spec.md "Clarifications" section. Quick summary for morning review:

1. **Q1 — Ship `balanced` profile alongside `lean` in F-041?** Default: defer. (Most-conservative; lean validates the routing primitive against the 2026-05-30 pivot.)
2. **Q2 — Catalog schema_version field?** Default: yes, `schema_version: 2`. (Future-proofing; ~5 lines.)
3. **Q3 — `/specrew-research-models` always refreshes when explicitly invoked?** Default: yes. (Stale thresholds apply to auto-refresh only.)
4. **Q4 — F-041 cost-reduction success criterion measurable without F-042?** Default: no — F-041 routes, F-042 measures. (Document the F-042 dependency; rely on manual reconciliation pre-F-042.)
