# Feature Specification: Cost-Aware Model Routing

**Feature Branch**: `041-cost-aware-model-routing`
**Created**: 2026-05-23
**Status**: Draft
**Input**: User direction (2026-05-20 ad-hoc session): "We have 10 days until Copilot changes the pricing model. I do not want to pay 1500usd for what was free before. We need to: fix fast and small problems; promote features that reduce cost: use of Claude Code and Codex; use free models in Copilot — the strong model creates a much detailed spec so free model can carry it, can run tests. Validation is still done by a strong model (Senior/Junior proposal); ... token economy — how much each SP cost. Allow priority by cost."
**Source proposal**: file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md (enriched 2026-05-23 with per-host selector_strategy + Gemini deadline + catalog v2)
**Composes with**: F-040 Multi-Host Launch Path (host enum), F-042 Token Economy MVP (cost.yml measurement), Proposal 100 Friction Dial (lean ↔ premium profile selection), Proposal 053 Autopilot Decision Transparency (routing-decision logging)
**Release urgency**: high — Copilot pricing pivot 2026-05-30 (~7 days from spec date)

## Clarifications

### Session 2026-05-23

Spec drafted overnight while user was offline. Spec uses default assumptions documented inline; the four open questions below are queued for user review at the clarify-boundary in the morning. Default assumption is the recommendation; user can override any of them before plan-boundary approval.

- Q1: Should F-041 ship `balanced` cost-profile semantics alongside `lean`, or defer? → **Default A: Defer.** F-041 ships `lean` only; `balanced`/`premium`/`custom` are reserved enum values with semantics shipping in follow-up slices. Lean is the highest-value default and the simplest to validate; other profiles can land once lean is empirically tested against the 2026-05-30 pricing pivot. (User may override to ship balanced if they want a "best of both worlds" mode in v1.)
- Q2: Should `.specrew/model-catalog.yml` carry a schema_version field? → **Default A: Yes, schema_version: 2 (matching Proposal 068 enrichment).** Readers can branch on schema_version when future migrations happen. Adds ~5 lines; pays off the first time we change the catalog shape.
- Q3: `/specrew-research-models` discovery — should the skill require an explicit `--refresh` flag when the catalog is fresh, or always re-discover when invoked? → **Default A: Always re-discover when explicitly invoked.** The freshness threshold (30/90 days) is for AUTO-refresh triggers; explicit invocation always refreshes. Adds friction-budget guidance: re-discovery costs tokens, so manual invocation should be intentional.
- Q4: Without F-042 measurement, can F-041 verify the "30% cost reduction" success criterion? → **Default A: No — F-041 routes; F-042 measures.** F-041's success criterion is empirically measurable only after F-042 ships. Document the dependency; rely on manual reconciliation against the 2026-05-16 baseline ($5.47/SP) for the F-041-only ship period.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Automatic Junior-to-cheap-model routing reduces cost without quality loss (Priority: P1)

A maintainer or external developer running the Specrew lifecycle expects per-role cost optimization out of the box. Junior/Implementer-class tasks (most token-volume) auto-route to the cheapest model that meets the capability bar; Senior/Reviewer/Spec-Steward-class tasks stay on strong models so quality is preserved. The user sees the routing decisions in `.squad/decisions.md` and doesn't need to manually configure model overrides for the common case.

**Why this priority**: Cost reduction is the WHY of the entire F-040 → F-041 → F-042 sequence. Without automatic routing, the multi-host launch (F-040) only enables manual host alternation — the dollar savings come from F-041's per-role tiering. Empirically, GPT-5.4 (premium) accounts for ~67% of Specrew token cost per the 2026-05-16 cost-baseline memory; routing Junior work to cheap-tier models reverses that ratio.

**Independent Test**: Run a fresh feature iteration after F-041 ships. Verify `.squad/decisions.md` contains routing entries that show Implementer using a cheap-tier model AND Reviewer using a strong-tier model. Verify the iteration completes without quality regressions (review-signoff passes; no excess clarify cycles).

**Acceptance Scenarios**:

1. **Given** a project with `cost_profile: lean` in `.specrew/config.yml`, **When** the Crew assigns work to roles during an iteration, **Then** Implementer tasks route to a cheap-tier model from the catalog and Reviewer/Spec-Steward tasks route to a strong-tier model
2. **Given** the catalog at `.specrew/model-catalog.yml` is missing or older than 30 days, **When** any agent attempts a routing decision, **Then** Specrew emits a warning prompting catalog refresh via `/specrew-research-models`
3. **Given** the catalog is older than 90 days, **When** an agent attempts routing, **Then** Specrew auto-invokes `/specrew-research-models` to refresh the catalog before proceeding
4. **Given** `cost_profile: lean` AND `.squad/config.json` has an explicit `agentModelOverrides` entry for a role, **When** the Crew routes that role, **Then** the explicit override wins over the lean-profile default (humans-in-the-loop preserved)
5. **Given** a routing decision is made, **When** the Crew records the decision in `.squad/decisions.md`, **Then** the entry includes: requested model tier, selected model id, host kind (per F-040's `selected_host`), cost_profile, fallback reason if any

---

### User Story 2 — Agent-discovered model catalog stays current without hardcoded model names (Priority: P1)

The user runs `/specrew-research-models` (or it auto-fires on stale catalog). The discovery skill web-searches and reads official documentation for each available host (Copilot, Claude Code, Codex CLI), enumerates current model identifiers, classifies by cost tier + capability, captures pricing-change announcements (including the 2026-06-18 Gemini CLI free-tier deadline if Antigravity is available), and writes findings to `.specrew/model-catalog.yml`. The maintainer never has to update a hardcoded model-name list in Specrew code — the catalog is the source of truth and stays current via agent-driven refresh.

**Why this priority**: Hardcoding model names is the wrong approach — pricing and lineups shift constantly (the upcoming Copilot pivot is the perfect example). Specrew agents already have web-search + document-fetch. Delegating discovery to the agent + persisting the catalog is the methodology pattern that scales.

**Independent Test**: Invoke `/specrew-research-models` on a fresh project. Verify `.specrew/model-catalog.yml` is written with at least one host populated, a `last_refreshed_at` timestamp, and at least three tiers (free/cheap, balanced, premium) for any host available on PATH.

**Acceptance Scenarios**:

1. **Given** `/specrew-research-models` is invoked on a fresh project with `copilot` + `claude` on PATH, **When** the skill completes, **Then** `.specrew/model-catalog.yml` contains entries for both hosts with at least one model per tier
2. **Given** the catalog discovery, **When** the skill records each model entry, **Then** the entry includes id, tier (free/cheap/balanced/premium), cost_per_million_input, cost_per_million_output, capability_tags, best_for, and the host's `selector_strategy` (per Proposal 068 v2 schema)
3. **Given** Antigravity is on PATH at the time of discovery, **When** the skill records the antigravity entry, **Then** a `pricing_change_alerts` array surfaces the 2026-06-18 Gemini free-tier deadline if discovery date < deadline
4. **Given** the catalog records a host's `built_in_routing_primitives` (e.g., Claude's `opusplan` alias), **When** the Crew evaluates routing, **Then** Specrew respects host-native primitives where they align with the active cost_profile
5. **Given** a host is configured but not currently available on PATH, **When** the skill discovers, **Then** the catalog records `available: false` for that host but still enumerates known models from the prior catalog (preserves data through transient PATH issues)

---

### User Story 3 — Per-host model-selection mechanism injection respects host conventions (Priority: P2)

Different hosts inject the chosen model differently — Copilot uses `agentModelOverrides` in `.squad/config.json`; Claude uses the `model:` field in `.claude/agents/*.md` subagent frontmatter; Codex uses `model = "..."` in `.codex/agents/*.toml`. Specrew's routing layer must write through each host's native primitive rather than maintaining its own Specrew-side abstraction.

**Why this priority**: Routing decisions must take effect at the host runtime. If Specrew records "Implementer → Claude Haiku" but doesn't actually update `.claude/agents/implementer.md`'s `model:` field, the host runs whatever its default is and the routing is theoretical. The per-host selector_strategy enum in Proposal 068 v2 codifies this.

**Independent Test**: Run an iteration with `cost_profile: lean` on each of the three supported hosts. After routing decisions are made, inspect the host-native config files (`.squad/config.json`, `.claude/agents/*.md`, `.codex/agents/*.toml`) and verify the chosen models are persisted in the right format per host.

**Acceptance Scenarios**:

1. **Given** `--host copilot` AND a routing decision for Implementer, **When** the routing layer applies, **Then** `.squad/config.json` `agentModelOverrides.implementer` is set to the chosen cheap-tier model id (preserves existing F-019 Set-SquadModelOverrides logic)
2. **Given** `--host claude` AND a routing decision for Implementer, **When** the routing layer applies, **Then** `.claude/agents/implementer.md` YAML frontmatter `model:` field is set to the chosen cheap-tier model id
3. **Given** `--host codex` AND a routing decision for Implementer, **When** the routing layer applies, **Then** `.codex/agents/implementer.toml` `model = "..."` field is set to the chosen cheap-tier model id
4. **Given** a host doesn't have a Crew runtime deployed (per F-040's `crew_runtime_status: bootstrap_only`), **When** routing decisions are made, **Then** Specrew logs the decision in `.squad/decisions.md` but skips the per-host file update with a `crew_runtime_install_required` note (Proposal 024 Slice 3 fills that gap)

---

### Edge Cases

- **Stale catalog (>30 days, <90 days)**: warning logged; routing proceeds with existing catalog. User can manually refresh via `/specrew-research-models`.
- **Stale catalog (≥90 days)**: auto-refresh fires before next routing decision. Refresh failure (network/auth/etc.) falls back to stale catalog with prominent warning; routing still proceeds (don't block work on discovery failure).
- **Pricing-change-alert effective date passed**: prominent warning in `specrew where` dashboard until catalog is re-refreshed. Routing continues but the user sees that quoted costs may be outdated.
- **Explicit `.squad/config.json` override for a role**: lean profile defers to the explicit override per AC4 of User Story 1. Override is recorded in `.squad/decisions.md` routing entry as `override_source: human-config`.
- **Multi-host alternation mid-feature** (user runs iteration 001 on Copilot, iteration 002 on Claude): each iteration's routing decisions reference its own `selected_host` from start-context.json. Aggregate cost per feature must be sum-of-iteration costs, not assume single-host.
- **`cost_profile` field missing from `.specrew/config.yml`**: F-041's init/update writes `cost_profile: lean` as the default on fresh projects. Brownfield projects without it get a warning + default-to-lean on first F-041 routing decision.
- **All discovered models in a tier have `cost_per_million_input: null`** (e.g., catalog refresh hit a doc page without pricing data): tier is still valid for routing on capability_tags alone; cost estimate (Proposal 070 / F-042) marks the iteration `cost_estimate_confidence: low`.

## Functional Requirements

| FR | Statement |
|---|---|
| FR-001 | Specrew MUST add a `cost_profile` field to `.specrew/config.yml` with valid values `lean`, `balanced`, `premium`, `custom`. F-041 ships `lean` as default; other profiles are reserved-not-yet-implemented |
| FR-002 | `specrew init` MUST write `cost_profile: lean` into `.specrew/config.yml` on greenfield bootstrap. `specrew update` adds the field to brownfield projects with a deprecation breadcrumb at the old default (no cost-profile) |
| FR-003 | Specrew MUST deploy a new skill `/specrew-research-models` to all host-skill directories (`.github/skills/`, `.claude/skills/`, `.agents/skills/`) per F-021 multi-host deploy. The skill body instructs the agent to enumerate current models per host via web-search + official-doc fetch |
| FR-004 | The discovery skill MUST write to `.specrew/model-catalog.yml` per the catalog v2 schema (Proposal 068 enrichment): per-host blocks with `selector_strategy`, `built_in_routing_primitives`, `models[]` (id, tier, cost_per_million_input/output, capability_tags, best_for), and optional `pricing_change_alerts[]` |
| FR-005 | The Crew coordinator-governance prompt MUST contain a rule that requires consulting `.specrew/model-catalog.yml` when assigning tasks to roles. The rule cites the active `cost_profile` from `.specrew/config.yml` and matches task class (Junior/Implementer → cheap; Senior/Reviewer/Spec-Steward → strong; intake → strong regardless of profile) |
| FR-006 | When the catalog is missing or older than 30 days, Specrew MUST emit a warning suggesting `/specrew-research-models`. When older than 90 days, the Crew MUST auto-invoke the discovery skill before the next routing decision |
| FR-007 | Routing decisions MUST be persisted in `.squad/decisions.md` (or per-host equivalent — see FR-013). Each entry MUST include: role, task summary, selected model id, model tier, host (`copilot`/`claude`/`codex`), cost_profile, fallback_reason (nullable), override_source (`lean-profile-default` / `human-config` / `host-builtin-primitive`) |
| FR-008 | Per-host selector_strategy: when host is `copilot`, model selection writes through `.squad/config.json` `agentModelOverrides` (reuses existing F-019 `Set-SquadModelOverrides` logic). When host is `claude`, writes through `.claude/agents/*.md` YAML frontmatter `model:` field. When host is `codex`, writes through `.codex/agents/*.toml` `model = "..."` field |
| FR-009 | When the active host has `crew_runtime_status: bootstrap_only` (per F-040 — no per-host Crew runtime deployed yet), Specrew MUST log routing decisions in `.squad/decisions.md` but skip the per-host file update, emitting a `crew_runtime_install_required` note pointing to Proposal 024 Slice 3 |
| FR-010 | Explicit human overrides in `.squad/config.json` `baselineAgentModelOverrides` or `agentModelOverrides` MUST take precedence over any cost_profile default. The override source is recorded as `human-config` in the routing entry |
| FR-011 | Host-native built-in routing primitives (e.g., Claude's `opusplan` alias which routes Opus for plan, Sonnet for execution) MUST be honored when they align with the active cost_profile. The catalog v2 `built_in_routing_primitives` field is the source of truth for what each host provides natively |
| FR-012 | The Specrew Friction Dial (Proposal 100) `friction.mode` MUST influence routing posture: `strict` requires human approval on every model-tier-change decision; `default` requires human approval only when tier changes from strong→cheap on a non-Implementer role; `autonomous` allows automatic tier changes without human approval but logs them prominently |
| FR-013 | When the active host is non-Copilot (i.e., `crew_runtime_status: bootstrap_only` per F-040), routing decisions MUST be persisted in `.squad/decisions.md` (the canonical ledger location) regardless of host, since the per-host equivalent does not yet exist (waits for Proposal 104's Category A migration + Proposal 024 Slice 3) |

## Out of Scope

This feature explicitly does NOT include:

- **Per-iteration token-cost measurement** — Proposal 070 / F-042 (next feature). F-041 produces the catalog + routing; F-042 produces the cost.yml measurement.
- **Cost-priority feature ordering** — Proposal 033 / Proposal 028 governance CLI surfaces. F-041 routes per cost_profile but doesn't reorder the roadmap.
- **`balanced`, `premium`, `custom` cost profiles** — only `lean` is defined in v1. Other profiles are reserved as enum values; their semantics ship in follow-up slices.
- **Multi-user cost attribution** — Proposal 010 Multi-Developer Reconciliation. Each user gets their own routing per their own cost_profile.
- **Pricing-change webhook / push notifications** — discovery is pull-based (manual or stale-trigger). Watching for pricing-change blog posts is a follow-up.
- **Antigravity host catalog entry** — F-041 catalog v2 schema accommodates `antigravity` but the discovery skill defers Antigravity entries until the Antigravity small-fix slice ships (post-F-040, separate from F-041).
- **Per-host model identity drift detection** — catalog refresh writes wholesale; doesn't diff against prior version to surface "Model X was removed by provider" alerts. Future work.
- **Cost forecasting per feature scope** — Proposal 040 (Token Economy Governance) covers cost-aware decision UI. F-041 is the routing primitive; 040 is the decision layer over it.

## Composition

- **068 (this feature's source proposal)** — full design surface; F-041 implements pillars 1-3
- **069 / F-040 Multi-Host Launch Path (shipped v0.26.0)** — F-041 consumes the host enum and per-host selector_strategy from F-040
- **070 / F-042 Token Economy MVP** — F-042's cost.yml reads F-041's catalog to compute per-iteration cost estimates
- **040 Token Economy as Governance Driver** — F-041 ships the L3-L4 catalog layer; 040 ships L5-L7 governance over it (future Phase 4)
- **053 Autopilot Decision Transparency** — F-041 routing entries in .squad/decisions.md compose with 053's auto-resolution visibility surface
- **100 Friction Dial** — FR-012 ties routing approval requirements to friction.mode
- **063 Substantive Intake Questioning** — intake tasks stay on strong-tier regardless of profile (per FR-005); 063 is intake-quality enforcement; F-041 is cost-quality enforcement
- **024 Multi-Host Runtime Abstraction Slice 3** — when per-host Crew runtime install ships, F-041's per-host writes (`.claude/agents/*.md`, `.codex/agents/*.toml`) gain real targets. Until then, FR-009 honors the bootstrap_only constraint
- **F-019 Specrew Distribution Module (shipped)** — F-041 ships skill catalog + Specrew helpers as part of v0.26.x module; published to PSGallery on next tag push
- **067 Small-Fix Slice Type** — F-041's ship cycle follows 067's contract

## Success Criteria (Outcome-Focused)

- **`cost_profile: lean` is the default for new projects**; existing projects get the field added via `specrew update`
- **`/specrew-research-models` discovers per-host model catalogs** without hardcoded model names; catalog refreshes survive provider lineup changes
- **Junior/Implementer tasks route to cheap-tier models, Senior/Reviewer/Spec-Steward stay on strong-tier** — verifiable in `.squad/decisions.md` routing entries
- **Per-host selector_strategy injection works** for each host's native primitive (Copilot agentModelOverrides; Claude subagent frontmatter; Codex .toml)
- **Empirical cost reduction**: target ≥ 30% reduction in cost-per-SP on the first iteration after F-041 ships, measured against the 2026-05-16 baseline of $5.47/SP (measurement layer ships with F-042; until then, manual reconciliation per memory entry)
- **2026-05-30 Copilot pricing-change resilience**: catalog refresh between F-041 ship date and 2026-05-30 surfaces the new pricing as a `pricing_change_alerts` entry; routing logic adapts without code change

## Risks

- **Catalog discovery quality varies by host** — official docs differ in completeness; some hosts may not publish per-million-token pricing. Mitigation: catalog v2 schema accommodates `cost_per_million_input: null` and routes on capability_tags alone in those cases. AC5 (catalog tier distinction independent of exact prices) verifies this.
- **Model identity changes between catalog refreshes** — provider renames or deprecates a model; routing layer holds stale id; iteration fails. Mitigation: routing layer probes model availability before committing the override; falls back to next-tier model with `fallback_reason: model-unavailable` in the routing entry.
- **`cost_profile` adoption friction** — existing projects with explicit `.squad/config.json` overrides expect their config to win. Mitigation: FR-010 makes overrides authoritative; lean-profile default applies only where no override exists.
- **Multi-host cost-attribution complexity** — alternating hosts within a feature makes "iteration cost" ambiguous. Mitigation: each iteration's routing references its own `selected_host`; F-042's cost.yml is per-iteration; aggregation is feature-level sum-of-iteration.
- **Discovery skill abuse / cost** — if every routing decision triggers a fresh discovery, cost EXPLODES instead of reduces. Mitigation: 30-day warning + 90-day auto-refresh + catalog is durable on disk (one discovery serves many routing decisions).
- **Friction-dial integration depends on Proposal 100 shipping** — Mitigation: FR-012 ships with hardcoded `default` mode behavior; when Proposal 100 lands, friction-dial integration becomes a small-fix follow-up.
