---
proposal: 068
title: Cost-Aware Model Routing with Agent-Discovered Model Catalog
status: draft
phase: phase-2
estimated-sp: 7-9
discussion: ad-hoc 2026-05-20 session; enriched 2026-05-23 with per-host model-selection mechanisms + Antigravity additions
release-urgency: immediate
---

# Cost-Aware Model Routing with Agent-Discovered Model Catalog

## Why

Copilot's pricing model changes in ~10 days (effective end of May 2026). Projected monthly cost for Specrew's current single-developer usage is **$1,500-2,000/month** if no action is taken (per memory entry `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]`). Premium models (GPT-5.4) account for ~67% of token cost. The same workload was previously near-zero under the old pricing model.

User direction (2026-05-20 ad-hoc session):

> "We have 10 days until Copilot changes the pricing model. I do not want to pay 1500usd for what was free before. We need to: fix fast and small problems; promote features that reduce cost: use of Claude Code and Codex; use free models in Copilot — the strong model creates a much detailed spec so free model can carry it, can run tests. Validation is still done by a strong model (Senior/Junior proposal); ... token economy — how much each SP cost. Allow priority by cost."

Refinement (same session):

> "There are free models and since we do not know which is which and which model is best for what, but our agents knows to search the web and official document, we can instruct them when creating the team or in general to find out each model, its abilities (match the task to a model) and its cost."

### Refinement (2026-05-21 session): multiply budget, don't replace hosts

The cost-reduction strategy is NOT "abandon Copilot for cheaper hosts." It is **multiply usable budget by alternating across hosts.** The user holds a $200/mo Claude Max subscription in addition to Copilot quota. After Proposal 069 (Multi-Host Launch Path) ships, Squad can alternate between Copilot CLI and Claude Code (and eventually Codex CLI + Antigravity) within a project's lifecycle, drawing on multiple budgets in turn. The eventual concurrent-execution future — different agents in the same Crew team running on different hosts simultaneously — is its own architectural lift (likely a separate Phase 3+ proposal), but **alternation is sufficient to multiply effective runway in the near term**.

This refinement does not change the design surface — Pillar 1's catalog already enumerates multiple hosts as peers; Pillar 2's routing already references per-host model preferences via the `cost_profile` mechanism. It does sharpen the **WHY** framing: this proposal is **not a Copilot-replacement plan**; it is a **multi-host budget-optimization plan** that happens to address the May 2026 Copilot pricing pivot as one specific cost vector. The savings come from "$200/mo Claude + remaining Copilot quota" being a larger combined pool than "$2,000/mo Copilot alone."

### Enrichment (2026-05-23 research): per-host model-selection mechanisms

The 2026-05-23 multi-host research wave verified that **each host has its own per-role model-selection primitive**. The cost-routing logic (Pillar 2) writes through these primitives rather than a single Specrew-only abstraction:

| Host | Per-role model selection mechanism | Built-in cost-routing primitives |
|---|---|---|
| **Copilot CLI** | `.squad/config.json` `agentModelOverrides` + `baselineAgentModelOverrides` (already implemented in Specrew) | None native — pure manual routing |
| **Claude Code** | `model:` field in per-subagent `.claude/agents/*.md` YAML frontmatter | **`opusplan` alias** (Opus for `/speckit.plan`, Sonnet for execution) is a built-in cost-routing primitive Specrew should record in the catalog |
| **Codex CLI** | Per-agent `model = "<name>"` in `.codex/agents/*.toml` | None native |
| **Antigravity CLI** | `-m <model-name>` CLI flag (e.g., `agy -m gemini-3.5-flash`); also dropdown in desktop app | Defaults shifting — research found Wikipedia listed Gemini 3.1 Pro; MarkTechPost says 3.5 Flash is the new default. Catalog must capture both default + override surface. |

The Pillar 2 routing logic gains a per-host **selector strategy**: when assigning a model to a role, Specrew uses the catalog's per-host selector field (`squad_config_field` for Copilot, `subagent_frontmatter` for Claude, `agent_toml_field` for Codex, `cli_flag` for Antigravity) to know HOW to inject the choice. The routing decision stays single-sourced in `.squad/decisions.md` (or its per-host equivalent per Proposal 024); the injection mechanism is per-host.

### Critical date (2026-05-23 research finding)

**Gemini CLI free tier stops serving requests on 2026-06-18** (~4 weeks from this enrichment date). After that, Antigravity-host users need Google AI Pro / Ultra ($100/mo) or enterprise Gemini Agent Platform API keys. Catalog refresh must surface this deadline as a `pricing_change_alerts` entry on the `antigravity` host so users opting into `--host antigravity` see the warning before the deadline lapses.

### Core routing lever (unchanged)

The biggest single cost-reduction lever is **routing Junior/Implementer-class work to cheaper models** while keeping Senior/Reviewer/Spec-Steward-class work on strong models. The infrastructure for per-role routing already exists in `.squad/config.json` (`roleAgentFamilies` and `baselineAgentModelOverrides`); it just isn't populated with cost-conscious defaults. Crucially, "cheap" and "strong" tiers can come from **either** host's catalog: a "cheap" tier might be Claude Haiku on one project and Copilot's free tier on another, depending on availability and current pricing — the routing logic stays the same.

Hardcoding specific model names is the wrong approach — pricing and lineups shift constantly (the upcoming Copilot pivot is a perfect example). Specrew agents already have web-search and document-fetch capabilities. **Let them discover available models, classify by cost + capability, and route accordingly.**

## What

Three lightweight pillars composed into a single small-fix-shaped slice:

### Pillar 1: Discovery skill `/specrew-research-models`

A new skill that any Squad agent can invoke. When invoked:

1. Identifies the currently active host runtime(s): Copilot CLI, Claude Code, Codex CLI, Antigravity CLI (whichever are available/configured per Proposal 104's `host-history.yml`)
2. For each host, web-searches and reads official documentation to enumerate:
   - Available model identifiers (current names — these change)
   - Cost per million input/output tokens (or per-request pricing where applicable)
   - Capability tags (e.g., `reasoning-deep`, `code`, `fast`, `cheap`, `vision`, `long-context`)
   - Best-for hints (matched to Crew roles: Junior/Implementer, Senior/Reviewer, Architect/Spec Steward)
   - **Per-host selector strategy** (how to inject the choice — `squad_config_field` / `subagent_frontmatter` / `agent_toml_field` / `cli_flag`)
   - **Built-in routing primitives** the host provides (e.g., Claude's `opusplan` alias)
   - Any active pricing-change announcements (with effective date — including the **2026-06-18 Gemini CLI free-tier deadline** for Antigravity)
3. Writes findings to `.specrew/model-catalog.yml` with a `last_refreshed_at` timestamp and a `confidence` field reflecting how authoritative the discovered information was
4. Outputs a short briefing the user can review

Skill file: `extensions/specrew-speckit/squad-templates/skills/specrew-research-models/SKILL.md` with proper YAML frontmatter (per F-024's skill-discovery contract).

Trigger surface (option A + C per 2026-05-20 design discussion):

- The skill itself can be invoked at any time by any agent (Squad coordinator, Spec Steward, or human via `/specrew-research-models`)
- The coordinator-governance prompt is updated to: "before routing a task, consult `.specrew/model-catalog.yml`. If the catalog is missing, older than 30 days (warn), or older than 90 days (auto-refresh), invoke the discovery skill before proceeding."

### Pillar 2: Catalog → routing in coordinator-governance

The Squad coordinator-governance prompt (`extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`) gains a new rule that requires Squad to:

- Consult `.specrew/model-catalog.yml` when assigning tasks to roles
- Match task class to the appropriate model tier per the active `cost_profile`:
  - Junior/Implementer tasks → cheapest model that meets the capability bar for the task
  - Senior/Reviewer/Spec Steward tasks → strong/premium model
  - Intake/scope-grounding tasks → strong model (never auto-resolved on cheap models; intake quality matters)
- Honor explicit human overrides in `.squad/config.json` `baselineAgentModelOverrides` and `roleAgentFamilies`
- Surface routing decisions in `.squad/decisions.md` (composes with Proposal 053 Autopilot Decision Transparency)

### Pillar 3: `lean` cost profile in `.specrew/config.yml`

A new top-level field in `.specrew/config.yml`:

```yaml
cost_profile: lean   # default for v1; future profiles (balanced, premium, custom) deferred
```

`lean` profile semantics (v1):

| Squad role | Tier preference | Why |
|---|---|---|
| Spec Steward | strong | spec authoring needs depth + comprehension |
| Planner | balanced (strong if reasoning-heavy, cheap if mechanical) | task generation is mostly mechanical |
| Implementer (Junior) | cheap | most token-volume role; cheapest model that can code in the project's stack |
| Reviewer | strong | review quality is the safety net; must catch Junior-class mistakes |
| Retro Facilitator | cheap | mostly templated output |
| AI Researcher (per Proposal 063) | balanced | research needs comprehension but not deep reasoning |

The exact model mapping comes from the catalog (Pillar 1), not hardcoded names. The profile defines TIER preferences; the catalog tells Squad which actual model fits each tier.

## How

### Phase 1 — Discovery skill (~3-4 SP)

- Create `extensions/specrew-speckit/squad-templates/skills/specrew-research-models/SKILL.md` with frontmatter:
  - `name: specrew-research-models`
  - `description: Discover available models for each active host runtime; classify by cost and capability; write findings to .specrew/model-catalog.yml. Use when the catalog is missing or stale, or after a pricing announcement.`
  - `allowed-tools: Bash Read Grep WebSearch WebFetch` (or equivalent for the host)
- Body prose instructs the agent to:
  - Identify active hosts (check for `gh copilot`, `claude`, `codex` binaries)
  - Per-host research workflow (sources, search terms, fields to extract)
  - Output schema for `.specrew/model-catalog.yml`
  - Pricing-change-alert capture format
- Source-of-truth references: `gh copilot --help` output, github.com/features/copilot/plans, docs.anthropic.com/en/docs/about-claude/models, developers.openai.com/codex/cli (and any model-listing endpoints these provide)

Output catalog format (illustrative, schema enriched 2026-05-23):

```yaml
catalog:
  version: 2
  last_refreshed_at: 2026-05-23T15:00:00Z
  confidence: high   # high | medium | low
  hosts:
    copilot-cli:
      available: true
      selector_strategy: squad_config_field   # writes .squad/config.json agentModelOverrides
      built_in_routing_primitives: []
      pricing_change_alerts:
        - effective_date: 2026-05-30
          summary: "Premium tier becomes metered; previously-free models remain"
          source_url: https://github.com/features/copilot/plans
      models:
        - id: "<discovered-name-1>"
          tier: free
          cost_per_million_input: 0
          cost_per_million_output: 0
          capability_tags: [code, fast]
          best_for: [Implementer, Retro Facilitator]
        - id: "<discovered-name-2>"
          tier: premium
          cost_per_million_input: <value>
          cost_per_million_output: <value>
          capability_tags: [reasoning-deep, code, long-context]
          best_for: [Spec Steward, Reviewer, Planner]
    claude-code:
      available: true
      selector_strategy: subagent_frontmatter   # writes model: field in .claude/agents/*.md
      built_in_routing_primitives:
        - name: opusplan
          description: "Opus for /speckit.plan, Sonnet for execution — built-in cost-routing alias"
          enabled_by_default: false
      models:
        - id: "claude-opus-4-7"
          tier: premium
          best_for: [Spec Steward, Reviewer]
        - id: "claude-sonnet-4-6"
          tier: balanced
          best_for: [Planner, Implementer]
        - id: "claude-haiku-4-5"
          tier: cheap
          best_for: [Implementer, Retro Facilitator]
    codex-cli:
      available: <true/false>
      selector_strategy: agent_toml_field   # writes model = "<name>" in .codex/agents/*.toml
      built_in_routing_primitives: []
      models: [...]
    antigravity:
      available: <true/false>
      selector_strategy: cli_flag   # uses -m <model-name> per invocation
      built_in_routing_primitives: []
      pricing_change_alerts:
        - effective_date: 2026-06-18
          summary: "Gemini CLI free tier stops; requires Google AI Pro / Ultra ($100/mo) or enterprise API key"
          source_url: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
      models: [...]
```

### Phase 2 — Coordinator-governance update + lean profile (~3-4 SP)

- Add Rule N to `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`:
  > "Cost-aware routing: when assigning tasks to roles, consult `.specrew/model-catalog.yml` and apply the active `cost_profile` from `.specrew/config.yml`. If the catalog is missing or older than 30 days, warn; if older than 90 days, invoke `/specrew-research-models` to refresh before routing. Junior/Implementer tasks route to cheap-tier models; Senior/Reviewer/Spec-Steward tasks route to strong-tier models; intake tasks stay on strong-tier. Honor explicit `.squad/config.json` overrides. Log routing decisions in `.squad/decisions.md`."
- Add `cost_profile` field to `.specrew/config.yml` (default `lean`)
- Update `scripts/specrew-init.ps1` to write the `cost_profile: lean` default during bootstrap
- Update user-guide and getting-started with a section on cost profiles + how to refresh the catalog manually

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | `/specrew-research-models` skill exists with proper YAML frontmatter discoverable per F-024's deployment contract (`.claude/skills/`, `.github/skills/`, `.agents/skills/`) |
| AC2 | Invoking the skill on a fresh project produces a `.specrew/model-catalog.yml` with at least one host populated and a non-empty `last_refreshed_at` timestamp |
| AC3 | The catalog distinguishes at least three tiers (free/cheap, balanced, premium) for at least one host |
| AC4 | Coordinator-governance prompt contains the cost-aware routing rule, citing `.specrew/model-catalog.yml` and `cost_profile` |
| AC5 | `specrew init` writes `cost_profile: lean` into `.specrew/config.yml` on greenfield bootstrap |
| AC6 | A new feature iteration after this proposal ships routes Implementer tasks to a cheaper model than Spec Steward / Reviewer tasks (validated by inspecting `.squad/decisions.md` routing entries) |
| AC7 | Empirical cost reduction measured against the May 2026 baseline ($5.47/SP per memory) — target ≥ 30% reduction on the first iteration after this ships |

## Out of scope (deferred)

- **Multi-host abstraction**: Proposal 024 (Multi-Host Runtime CORE) is the architectural follow-up. This proposal is the cost-reduction MVP; it doesn't yet abstract the host runtime.
- **`balanced` and `premium` cost profiles**: only `lean` is defined in v1. Other profiles can be added when needed.
- **Per-task cost forecasting**: full Proposal 040 (Token Economy as Governance Driver) covers cost-priority decision UI, billing modes, model-name catalogs at L3-L4. This proposal ships the routing + catalog; the governance layer over them is Proposal 040.
- **Catalog auto-refresh based on pricing-change announcements**: discovery is pull-based (manual or stale-trigger), not push-based. Watching for pricing-change blog posts is a follow-up.
- **Multi-user cost attribution**: Proposal 010 (Multi-Developer Reconciliation). Each user runs their own routing; aggregated cost reporting deferred.
- **Token Economy MVP (cost-per-SP measurement)**: separate Proposal 070 sliced from Proposal 040. Composes with this proposal but ships separately.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **069 (Multi-Host Launch Path)** | **Hard prerequisite for the 2026-05-21 multi-host budget-optimization framing.** Without 069, the catalog still works for a single host but the budget-multiplication thesis is unrealized. 069 should ship before or alongside this proposal. |
| **024 (Multi-Host Runtime CORE)** | The deeper architectural follow-up to 069. This proposal lays the cost-routing groundwork inside whatever host topology exists; when 024 ships, the catalog naturally extends to richer per-host abstraction. |
| **010 (Multi-Developer Reconciliation)** | Phase 5 work for true multi-user. This proposal does not solve multi-user cost attribution; it ships the per-developer routing first. |
| **040 (Token Economy as Governance Driver)** | This proposal is a slice of 040's larger architecture. Specifically: the catalog (Pillar 1) maps to 040's L3-L4 model catalog. Profile-driven routing (Pillar 3) is the seed of 040's billing-mode separation. When 040 ships, this proposal's outputs feed it. |
| **014 (Red Team Agent)** | Holistic adversarial review at feature-closeout; ensures cost-savings don't compromise spec fidelity. Composes naturally. |
| **053 (Autopilot Decision Transparency)** | Cost-driven routing decisions get logged via 053's machinery. |
| **063 (Substantive Intake Questioning)** | Intake tasks stay on strong-tier models regardless of `cost_profile`; quality at the intake boundary determines spec quality downstream. |
| **067 (Small-Fix Slice Type)** | This proposal itself is being shipped under 067's contract (proposal entry + CHANGELOG + INDEX update at ship time, no full feature lifecycle). |

## Methodology learning

The agent-driven discovery pattern formalized here generalizes beyond cost: any time Specrew needs current information about an external system (host versions, dependency lineups, API capabilities), the right move is "ask the agent to discover and persist, then read the persisted catalog" — not "hardcode a current snapshot that goes stale." This pattern should propagate to:

- Host runtime version detection (`/specrew-research-hosts`)
- Dependency tooling discovery (`/specrew-research-tooling`) — composes with Proposal 044 (Downstream Quality Baseline Bootstrap)
- Methodology drift detection — when the broader AI-SDLC landscape shifts, agents can update their own playbooks

This is the "delegate discovery to agent" pillar of Specrew's positioning.

## Cross-references

- Memory: `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]` — empirical cost baseline ($5.47/SP; GPT-5.4 = 67% of cost)
- Memory: `[[project-post-f024-sequencing-locked-2026-05-20]]` — prior sequencing now revised; F-068 jumps ahead of F-025/F-035 due to 10-day Copilot pricing deadline
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/proposals/040-token-economy-governance.md
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
