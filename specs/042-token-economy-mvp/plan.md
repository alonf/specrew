# Implementation Plan: Token Economy MVP

**Branch**: `042-token-economy-mvp` | **Date**: 2026-05-23 | **Spec**: [specs/042-token-economy-mvp/spec.md](./spec.md)
**Input**: Approved spec + Proposal 070 enrichment (commit `e3c47ddd` on main) with per-host reported-token surface inventory (Claude `--output-format json` richest; Codex `--json`; Copilot post-hoc only; Antigravity envelope pending).

## Summary

Three lightweight pillars from Proposal 070:

1. **Per-iteration `cost.yml` artifact** at `specs/<feature>/iterations/<NNN>/cost.yml`. Records accumulate at each boundary advance during iteration execution; aggregates block computed at write time.
2. **COST section in `specrew where` dashboard** between VELOCITY and RECENT SHIPPED. Shows recent iterations with cost-per-SP, by-host distribution, trend classification.
3. **`specrew cost` CLI surface** with three subcommands: `summary` (rollup view), `add` (manual entry from billing reconciliation), `recompute` (re-estimate after catalog refresh).

Cost.yml writes happen INSIDE the canonical boundary-sync flow (`sync-boundary-state.ps1`), so F-039 authorization gates apply automatically. F-041 catalog provides cost-per-token authority; F-040 `selected_host` provides the per-host attribution.

Estimator uses per-model tokenizer where the catalog provides a hint; falls back to naive byte/4 estimate. The `cost_estimate_confidence: low` marker surfaces when the catalog is incomplete.

## Technical Context

**Language/Version**: PowerShell 7+ runtime scripts, YAML cost.yml, JSON `specrew cost summary --json` output
**Primary Dependencies**: F-041 catalog at `.specrew/model-catalog.yml`; F-040 `selected_host` in start-context.json; F-039 boundary-sync flow (writes happen inside the canonical sync function); existing `Get-DashboardRenderer` / `scripts/internal/dashboard-renderer.ps1` for COST section integration
**Storage**: New `specs/<feature>/iterations/<NNN>/cost.yml` artifact per iteration; existing tasks.md / state.md unchanged
**Testing**: New `tests/integration/token-economy-mvp.tests.ps1` covering FR-001 through FR-012 — cost.yml schema, per-host attribution, dashboard COST section, three CLI commands, recompute behavior, manual override
**Target Platform**: PowerShell 7+ on Windows / Linux / macOS (cross-platform per F-019)
**Performance Goals**: cost.yml read + dashboard render under 100ms for last 10 iterations; recompute --all under 5s for 100 iterations
**Constraints**: Backwards-compatible with existing iteration artifacts (no migration of pre-F-042 iterations); manual records always win for matching boundary+role key

---

## Phase 0 Decisions

| Topic | Decision | Source |
|---|---|---|
| Cost.yml location | `specs/<feature>/iterations/<NNN>/cost.yml` (alongside state/plan/tasks) | spec FR-001 |
| Record granularity | Per-boundary AND per-role (one record per boundary advance per role) | clarify Q3 |
| Token-counting | Per-model tokenizer where catalog provides hint; naive byte/4 fallback | clarify Q1 + spec FR-003 |
| Reported-token mode in v1 | Schema includes `source: reported` value but parsers ship as follow-up small-fix slice | clarify Q2 |
| Dashboard COST section position | Between VELOCITY and RECENT SHIPPED | spec FR-007 |
| Dashboard refresh strategy | Auto-render every invocation (no cache) | clarify Q4 |
| Manual record precedence | Manual records always win for matching boundary+role key | spec FR-009 |
| Empty catalog handling | `cost_estimate_confidence: low` per-iteration; `estimated_cost_usd: null` per-record | spec FR-006 |
| Antigravity entry | Schema accommodates; v1 only writes records for actually-active hosts | spec FR-011 |
| Boundary discipline | Cost.yml writes happen inside `sync-boundary-state.ps1`; F-039 gates apply | spec FR-012 |
| Tokenizer dependency | Optional; naive fallback ships in v1; tokenizer opt-in via cost_profile extension | risks |

## Phase 1 Design Artifacts

- [research.md](./research.md) — per-host reported-token surface evidence + tokenizer recommendation per host + dashboard renderer integration mechanics
- [data-model.md](./data-model.md) — cost.yml schema (records[] + aggregates block) + by_host/by_role aggregation algorithm
- [contracts/cost-yml-interface.md](./contracts/cost-yml-interface.md) — PowerShell helper signatures for read/write/recompute
- [quickstart.md](./quickstart.md) — rehearsal commands for `specrew cost summary/add/recompute` + dashboard COST inspection

## Design Scope

### Files and components expected to change during implementation

| Surface | Planned change | Why it exists |
|---|---|---|
| `scripts/internal/cost-tracking.ps1` (new) | `Get-SpecrewCostYml`, `Add-SpecrewCostRecord`, `Update-SpecrewCostAggregates`, `Get-SpecrewCostAggregatesForFeature`, `Get-SpecrewTokenEstimate` | Core cost-tracking primitive |
| `scripts/internal/cost-yml-schema.yml` (new) | YAML schema spec + validator function | Schema-conformance test fixture |
| `scripts/internal/sync-boundary-state.ps1` | Extend `Invoke-SpecrewBoundaryStateSync` to call `Add-SpecrewCostRecord` after F-039 authorization passes | spec FR-001 + FR-012 |
| `scripts/internal/dashboard-renderer.ps1` | New COST block reader that aggregates cost.yml files across recent iterations; rendered between VELOCITY and RECENT SHIPPED | spec FR-007 |
| `scripts/specrew-cost.ps1` (new) | Command dispatcher for `summary` / `add` / `recompute` subcommands | spec FR-008/9/10 |
| `scripts/specrew.ps1` (entry wrapper) | Route `cost` subcommand to specrew-cost.ps1 | CLI surface |
| `extensions/specrew-speckit/scripts/shared-governance.ps1` | New cost-aggregation helpers callable from boundary commands. Mirror to `.specify/` per Rule 14B | spec FR-005 + FR-012 |
| `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | Mirror of above | Mirror parity |
| `tests/integration/token-economy-mvp.tests.ps1` (new) | All 12 FR coverage + 15+ assertions | Verification |
| `docs/user-guide.md` | New "Cost Tracking" section with cost.yml schema + `specrew cost` CLI examples + dashboard COST screenshot | Discoverability |
| `docs/dashboard-guide.md` | Document the COST section + per-host attribution explanation | Discoverability |
| `CHANGELOG.md` | v0.28.0 entry | Rule 15 |
| Version manifests (4 files) | Bump to 0.28.0 | Rule 15 version-consistency |
| `proposals/070-token-economy-mvp.md` | Flip `status: draft` → `status: shipped`; add shipped-as/version metadata | Proposal lifecycle |
| `proposals/INDEX.md` | Move 070 from Draft to Shipped; decrement Draft count | Proposal 028 conventions |

### Files that will NOT change

- `scripts/specrew-start.ps1` — host enum and selected_host are F-040's; F-042 reads them but doesn't modify
- `scripts/internal/cost-routing.ps1` — F-041's routing logic; F-042 reads catalog through F-041 helpers but doesn't modify routing decisions
- `tests/integration/cost-aware-routing.tests.ps1` — F-041 contract preserved; new F-042 tests in separate file

## Quality Planning

### Risk dimensions

| Risk | Why it matters | Planned control |
|---|---|---|
| Tokenizer dependency varies by host | Adds Python/Node packages to footprint | Optional; naive byte/4 fallback ships in v1; tokenizer opt-in via cost_profile extension |
| Catalog absence breaks cost silently | If F-041 catalog missing, estimates null | FR-006 marks `cost_estimate_confidence: low`; dashboard surfaces warning prominently; doesn't block lifecycle |
| Multi-host alternation aggregation | Sum-of-iteration with per-host attribution is non-trivial | Per-iteration rollup, then feature-level sum; tests cover alternation case (iteration 001 on Copilot, iteration 002 on Claude) |
| `specrew cost` CLI surface conflict | Future Proposal 040 will add richer cost commands | F-042 reserves only `cost summary/add/recompute`; future commands extend |
| Cost.yml proliferation | 100 iterations = 100 small YAML files | Dashboard reads only recent N; files <5KB; lazy load |
| F-041 dependency | F-042 reads catalog; without F-041, no costs | F-042 ships with fixture catalog for the 3 supported hosts; replaced by live catalog when discovery runs |
| Manual records lost on recompute | If recompute logic naively overwrites all records | FR-010 explicit: only `source: estimated` records re-estimate; manual records untouched |

### Required verification evidence

- cost.yml schema round-trip (write → read → assert structural equality)
- Per-boundary record creation: each boundary advance writes exactly one record per active role
- Aggregates block: by_host shares sum to 1.0; by_role shares sum to 1.0; total_cost_usd matches sum of records
- Per-host attribution: alternating-host iteration test (1=Copilot, 2=Claude) → by_host distribution matches
- Dashboard COST section renders with by_host line when multiple hosts used; reads cleanly with single host
- `specrew cost summary --json` parseable JSON
- `specrew cost add` appends record with `source: manual`
- `specrew cost recompute` re-estimates only `source: estimated` records; manual untouched
- Tokenizer fallback: when no tokenizer hint in catalog, naive byte/4 estimate runs and is recorded with `tokenizer_method: naive_byte_4`
- Cost-per-SP within 30% of baseline ($5.47/SP per memory) on first iteration after F-042

---

## Constitution Check

*Gate: must pass before and after design.*

- **Spec Authority Gate**: ✅ Pass — Plan stays inside the approved F-042 spec and 4 clarify defaults
- **Layering Gate**: ✅ Pass — cost-tracking logic in new `scripts/internal/cost-tracking.ps1`; CLI dispatcher in new `scripts/specrew-cost.ps1`; sync-boundary integration is minimal (one helper call)
- **Traceability Gate**: ✅ Pass — Each FR maps to design artifact + test
- **Ownership Gate**: ✅ Pass — Implementer owns cost-tracking + CLI; Reviewer owns aggregation correctness; Spec Steward owns no-routing-coupling discipline (FR-001 measurement-only contract)
- **Capacity Gate**: ✅ Pass — 5-6 SP single iteration; consistent with Proposal 070's estimate
- **Drift/Reconciliation Gate**: ✅ Pass — Defaults documented for all 4 clarify questions; user can override at clarify boundary
- **Verification Gate**: ✅ Pass — quickstart.md will document rehearsal commands

### Constitution Check Re-Evaluation (Post-Design)

To be completed after research.md, data-model.md, contracts/cost-yml-interface.md, quickstart.md are written.

---

## Implementation Sequence (preview — full breakdown in tasks.md)

Iteration 001 (target: cover full FR scope in single iteration):

1. **cost.yml schema + helpers** (~1 SP) — `scripts/internal/cost-tracking.ps1` core; schema validator
2. **Token estimator** (~0.5 SP) — naive byte/4 fallback; tokenizer-hint dispatch (no actual tokenizer wired in v1)
3. **Capture hook in sync-boundary-state** (~1 SP) — extend `Invoke-SpecrewBoundaryStateSync` to write cost record after F-039 authorization passes
4. **Dashboard COST block** (~1 SP) — extend `scripts/internal/dashboard-renderer.ps1`; aggregate cost.yml across recent iterations
5. **`specrew cost` CLI** (~0.75 SP) — `scripts/specrew-cost.ps1` + entry wrapper route
6. **Integration tests** (~1 SP) — all FR coverage in `tests/integration/token-economy-mvp.tests.ps1`
7. **Docs + version bump + CHANGELOG + Proposal 070 status flip** (~0.5 SP)

Total: ~5.75 SP (in line with Proposal 070's 5 SP estimate, slight buffer for per-host aggregation complexity)

## Out-of-iteration follow-ups

- `source: reported` host-CLI-output parsers (Claude first, then Codex, then Copilot via API)
- Per-developer cost-per-SP dashboards (Proposal 092 Web App)
- Cost-priority feature ordering (Proposal 028 / 033 governance CLI)
- Cost forecasting per feature scope (Proposal 040 architectural parent)
- Per-iteration budget gates (Proposal 040)
