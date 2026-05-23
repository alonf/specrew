# Implementation Plan: Cost-Aware Model Routing

**Branch**: `041-cost-aware-model-routing` | **Date**: 2026-05-23 | **Spec**: [specs/041-cost-aware-model-routing/spec.md](./spec.md)
**Input**: Approved feature spec + Proposal 068 enrichment (commit `e3c47ddd` on main) with per-host `selector_strategy` enum, `built_in_routing_primitives` (Claude `opusplan`), and 2026-06-18 Gemini deadline awareness.

## Summary

Ship the three pillars of Proposal 068:

1. **Discovery skill `/specrew-research-models`** deployed to all host-skill directories (per F-021 multi-host deploy). Body instructs the agent to enumerate per-host model catalogs via web-search + official-doc fetch and persist findings to `.specrew/model-catalog.yml` (schema v2).
2. **Coordinator-governance update** adding a rule that requires consulting the catalog before routing tasks to roles. Active `cost_profile` from `.specrew/config.yml` determines tier preferences per role. Decisions logged in `.squad/decisions.md`.
3. **`cost_profile: lean` field** in `.specrew/config.yml` (default for fresh projects; `specrew update` adds to brownfield).

The per-host injection layer (FR-008) writes through each host's native primitive: `.squad/config.json` `agentModelOverrides` for Copilot (reuses existing F-019 `Set-SquadModelOverrides`); `.claude/agents/*.md` YAML frontmatter `model:` field for Claude; `.codex/agents/*.toml` `model = "..."` field for Codex.

F-040's `crew_runtime_status: bootstrap_only` (when non-Copilot host has no per-host Crew runtime deployed yet) → F-041 logs the decision in `.squad/decisions.md` but skips the per-host file update with a `crew_runtime_install_required` note pointing at Proposal 024 Slice 3.

## Technical Context

**Language/Version**: PowerShell 7+ runtime scripts, Markdown skill body, YAML catalog, JSON decisions ledger
**Primary Dependencies**: F-040's host enum (`Get-SpecrewHostKind`, `Get-SpecrewSupportedHostKinds`); F-019's `Set-SquadModelOverrides` for Copilot host; new `scripts/internal/cost-routing.ps1` for cross-host orchestration
**Storage**: `.specrew/config.yml` (new `cost_profile` field), `.specrew/model-catalog.yml` (new — schema v2 per Proposal 068 enrichment), `.squad/decisions.md` (existing — routing entries added), `.squad/config.json` (Copilot host override write); `.claude/agents/*.md` (Claude frontmatter write); `.codex/agents/*.toml` (Codex toml write)
**Testing**: New `tests/integration/cost-aware-routing.tests.ps1` covering FR-001 through FR-013 — catalog schema, lean-profile routing, per-host injection, override precedence, friction-dial integration (when 100 ships)
**Target Platform**: PowerShell 7+ on Windows / Linux / macOS (cross-platform per F-019)
**Performance Goals**: Catalog read + routing decision under 50ms (cached after first read per iteration); `/specrew-research-models` discovery may take 10-30s (web-search + doc-fetch) — explicit user invocation only or stale-trigger auto-refresh
**Constraints**: No hardcoded model names anywhere in Specrew code; catalog is the source of truth; backwards-compatible with F-040 `.squad/config.json` `agentModelOverrides`; explicit human overrides win over profile defaults

---

## Phase 0 Decisions

| Topic | Decision | Source |
|---|---|---|
| Catalog schema | v2 per Proposal 068 enrichment: per-host blocks with `selector_strategy`, `built_in_routing_primitives`, `models[]`, `pricing_change_alerts[]` | spec FR-004 + research.md Task 1 |
| Default cost_profile | `lean` for fresh projects; `specrew update` adds field to brownfield with deprecation breadcrumb | spec FR-001/FR-002 + clarify Q1 |
| Discovery trigger | Manual via `/specrew-research-models`; auto-refresh on stale (90+ days); warn on stale (30+ days) | spec FR-006 |
| Per-host injection | Copilot: existing `Set-SquadModelOverrides` writes to `.squad/config.json`. Claude: write `model:` to `.claude/agents/*.md` YAML frontmatter. Codex: write `model = "..."` to `.codex/agents/*.toml` | research.md Task 2 |
| Bootstrap-only host fallback | Log decision in `.squad/decisions.md` with `crew_runtime_install_required` note; skip per-host file update | spec FR-009 |
| Override precedence | Explicit `.squad/config.json` overrides > host-builtin-primitives > lean-profile-defaults | spec FR-010 |
| Friction-dial integration | Spec FR-012 ships with default-mode hardcoded behavior; Proposal 100 integration as small-fix follow-up | spec FR-012 + clarify Q1 (Proposal 100) |
| Routing-decision logging | `.squad/decisions.md` (canonical ledger); host-specific decisions write the same ledger location for now (Proposal 024 Slice 3 introduces per-host decisions if needed) | spec FR-007 + FR-013 |

## Phase 1 Design Artifacts

- [research.md](./research.md) — verified per-host selector_strategy mechanisms; catalog v2 schema; Claude `opusplan` primitive integration; 2026-06-18 Gemini deadline handling
- [data-model.md](./data-model.md) — `.specrew/model-catalog.yml` schema v2 + `cost_profile` field in `.specrew/config.yml` + routing-entry shape in `.squad/decisions.md`
- [contracts/cost-routing-interface.md](./contracts/cost-routing-interface.md) — PowerShell helper signatures: `Get-SpecrewCostProfile`, `Get-SpecrewModelCatalog`, `Resolve-RoleToModelTier`, `Set-PerHostModelOverride`, `Test-CatalogStaleness`, `Invoke-RoutingDecisionLedgerEntry`
- [quickstart.md](./quickstart.md) — rehearsal commands: `/specrew-research-models` invocation + iteration with lean profile + override precedence demo

## Design Scope

### Files and components expected to change during implementation

| Surface | Planned change | Why it exists |
|---|---|---|
| `extensions/specrew-speckit/squad-templates/skills/specrew-research-models/SKILL.md` (new) | Discovery skill body with per-host research workflow + catalog output schema | FR-003 + FR-004 |
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | New numbered rule citing `.specrew/model-catalog.yml` and `cost_profile` for routing decisions | FR-005 |
| `scripts/specrew-init.ps1` | Add `cost_profile: lean` to default `.specrew/config.yml` template | FR-002 |
| `scripts/specrew-update.ps1` | Brownfield migration: add `cost_profile: lean` to existing config.yml with deprecation breadcrumb | FR-002 |
| `scripts/internal/cost-routing.ps1` (new) | Cross-host orchestration: `Get-SpecrewCostProfile`, `Resolve-RoleToModelTier`, `Get-SpecrewModelCatalog`, `Test-CatalogStaleness`, `Invoke-RoutingDecisionLedgerEntry` | New module for the cost-routing primitive surface |
| `scripts/internal/per-host-model-injection.ps1` (new) | Per-host selector_strategy dispatchers: `Set-CopilotModelOverride` (delegates to existing F-019 logic), `Set-ClaudeSubagentModel`, `Set-CodexAgentModel` | FR-008 |
| `extensions/specrew-speckit/scripts/shared-governance.ps1` | New helpers: `Get-SpecrewModelCatalog`, `Test-SpecrewCatalogStaleness`, `Add-SpecrewRoutingDecisionEntry`. Mirror to `.specify/` per Rule 14B | FR-005 + FR-007 |
| `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1` | Mirror of above | Mirror parity |
| `.specrew/config.yml` (in-repo template, not user data) | Add `cost_profile: lean` to the canonical template (consumed by init) | FR-002 |
| `extensions/specrew-speckit/templates/iteration-config.yml` | Document the new `cost_profile` field in the iteration template | Discoverability |
| `tests/integration/cost-aware-routing.tests.ps1` (new) | Schema validation + lean-profile routing + per-host injection + override precedence + stale-catalog warning + bootstrap-only fallback | FR-001 through FR-013 |
| `docs/user-guide.md` | New "Cost-Aware Model Routing" section explaining cost_profile + catalog refresh + per-host injection mechanism | Discoverability |
| `CHANGELOG.md` | v0.27.0 entry | Rule 15 |
| Version manifests (Specrew.psd1, .specrew/config.yml, extensions/specrew-speckit/extension.yml, .specify/extensions/specrew-speckit/extension.yml) | Bump to 0.27.0 | Rule 15 version-consistency |
| `proposals/068-cost-aware-model-routing.md` | Flip `status: draft` → `status: shipped`; add `shipped-as: feature-041`, `shipped-version: 0.27.0` | Proposal lifecycle |
| `proposals/INDEX.md` | Move 068 from Draft to Shipped (24); decrement Draft count to 14 | Proposal 028 conventions |

### Files that will NOT change

- `scripts/specrew-start.ps1` — host enum is F-040's; F-041 reads it via `Get-SpecrewHostKind` from F-040's helper, no direct edits to specrew-start.ps1
- `scripts/internal/host-flag-translation.ps1` — F-040's flag-translation surface untouched by F-041
- `tests/integration/multi-host-launch-path.tests.ps1` — F-040 contract preserved; new F-041 tests in a separate file

## Quality Planning

### Risk dimensions

| Risk | Why it matters | Planned control |
|---|---|---|
| Catalog discovery doesn't return all hosts | Routing falls back to defaults silently — cost reduction doesn't materialize | Integration test seeds a fixture catalog with all 3 hosts; routing decisions validate against the fixture; runtime discovery is a separate concern |
| Model id drift between catalog refreshes | Provider renames or deprecates model; routing holds stale id; iteration fails | Routing layer probes model availability before committing; falls back to next-tier with `fallback_reason: model-unavailable` in decision entry |
| Per-host injection writes corrupt host files | Specrew breaks `.claude/agents/*.md` frontmatter or `.codex/agents/*.toml` syntax → downstream host can't load Crew runtime | Round-trip test: write, then read+parse, then assert structure unchanged except for `model:` field; fail loud on parse error |
| `cost_profile` field collision with future proposals | If Proposal 040 / 100 / 047 introduce conflicting config fields, breaks downstream | `.specrew/config.yml` schema documented in [data-contracts.md](../../docs/data-contracts.md); F-041 reserves only the `cost_profile` top-level key |
| Catalog refresh blocks the lifecycle | Discovery takes 10-30s; if it fires synchronously mid-iteration, user feels stalled | Refresh is async-tolerant: stale-warn at 30 days (non-blocking), auto-refresh at 90 days (blocking before next routing decision but only fires when needed); manual `/specrew-research-models` is the primary path |
| Friction-dial dependency on Proposal 100 | F-041 ships before 100; FR-012 has nothing to gate on | FR-012 hardcoded default-mode behavior in v1; Proposal 100 integration is a small-fix follow-up when 100 lands |

### Required verification evidence

- Catalog v2 schema round-trips (write → read → assert equality)
- Lean-profile routing decisions: Implementer → cheap-tier model; Reviewer/Spec-Steward → strong-tier; intake → strong regardless of profile
- Per-host injection: Copilot writes `.squad/config.json`; Claude writes `.claude/agents/*.md` `model:`; Codex writes `.codex/agents/*.toml` `model = "..."`
- Override precedence: explicit `.squad/config.json` `agentModelOverrides.implementer = "gpt-5.4"` wins over `cost_profile: lean` cheap-tier default
- Stale catalog warning at 30 days; auto-refresh at 90 days
- Bootstrap-only host fallback: routing decisions persist in `.squad/decisions.md` with `crew_runtime_install_required` note; per-host file update skipped
- Built-in routing primitive honor: Claude `opusplan` alias respected when `cost_profile: lean` AND task class is plan→use-Opus, execution→use-Sonnet (matches lean intent natively)
- Discovery skill deployment to all three host-skill directories (`.github/skills/`, `.claude/skills/`, `.agents/skills/`)

---

## Constitution Check

*Gate: must pass before and after design.*

- **Spec Authority Gate**: ✅ Pass — Plan stays inside the approved F-041 spec and the 4 clarify defaults documented inline
- **Layering Gate**: ✅ Pass — Cost-routing logic in new `scripts/internal/cost-routing.ps1`; per-host injection in new `scripts/internal/per-host-model-injection.ps1`; coordinator-governance update writes through extension's existing mirror discipline
- **Traceability Gate**: ✅ Pass — Each FR maps to design artifact + verification test
- **Ownership Gate**: ✅ Pass — Implementer owns helpers + skill body; Reviewer owns per-host injection correctness; Spec Steward owns coordinator-governance rule wording
- **Capacity Gate**: ✅ Pass — 7-9 SP single iteration; consistent with Proposal 068's estimate
- **Drift/Reconciliation Gate**: ✅ Pass — Defaults documented for all four clarify questions; user can override at clarify boundary before plan approval
- **Verification Gate**: ✅ Pass — quickstart.md will document rehearsal commands for each FR

### Constitution Check Re-Evaluation (Post-Design)

To be completed after research.md, data-model.md, contracts/cost-routing-interface.md, quickstart.md are written.

---

## Implementation Sequence (preview — full breakdown in tasks.md)

Iteration 001 (target: cover full FR scope in single iteration):

1. **Catalog schema + helpers** (~1.5 SP) — schema v2 docs + `Get-SpecrewModelCatalog`, `Test-CatalogStaleness`, `Test-CatalogSchema` helpers in `cost-routing.ps1`
2. **`cost_profile` config field** (~1 SP) — add to .specrew/config.yml template + specrew-init writes default + specrew-update brownfield migration
3. **`/specrew-research-models` discovery skill** (~2 SP) — SKILL.md body + frontmatter + deploy to all 3 host-skill directories
4. **Coordinator-governance routing rule** (~1.5 SP) — new numbered rule in specrew-governance.md (and mirror); the rule cites catalog + cost_profile + role-tier mapping
5. **Per-host injection layer** (~2 SP) — Copilot delegates to existing `Set-SquadModelOverrides`; Claude writes subagent frontmatter; Codex writes .toml; bootstrap-only fallback skips file update
6. **Integration tests** (~1.5 SP) — `tests/integration/cost-aware-routing.tests.ps1` covering all 13 FRs
7. **Docs + version bump + CHANGELOG + Proposal 068 status flip** (~0.5 SP)

Total: ~10 SP (slightly over Proposal 068's 7-9 estimate; accommodates per-host injection complexity discovered in spec drafting)

## Out-of-iteration follow-ups

- `balanced`, `premium`, `custom` cost-profile semantics (separate slices)
- Friction-dial integration once Proposal 100 ships (small-fix follow-up)
- F-042 cost.yml measurement layer (next feature)
- Antigravity host catalog entry (post-Antigravity small-fix slice)
- Pricing-change webhook / push notifications (future)
- Per-host model identity drift detection (future)
