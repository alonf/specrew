---
name: specrew-research-models
description: |
  Discover available models for each active host runtime (Copilot CLI, Claude Code, Codex CLI, Antigravity);
  classify by cost tier and capability; persist findings to `.specrew/model-catalog.yml`.
  Invoke when the catalog is missing, stale, after a known pricing announcement, or before a routing decision
  on a host you haven't researched recently. Routes Junior/Implementer tasks to cheap-tier models,
  Senior/Reviewer/Spec-Steward to strong-tier (F-041 Cost-Aware Model Routing / Proposal 068).
allowed-tools: Bash Read Write WebSearch WebFetch
---

# /specrew-research-models — Discover available models per host

## When to invoke this skill

Invoke explicitly via `/specrew-research-models` (or its host-prefix variant `/speckit.specrew-research-models`)
when ANY of the following apply:

1. `.specrew/model-catalog.yml` is missing (fresh project; F-041 hasn't been initialized yet)
2. Catalog is older than 30 days (Specrew warned about staleness on the last routing decision)
3. Catalog is older than 90 days (Specrew triggered auto-refresh; this skill is the auto-refresh target)
4. A host's pricing changed (e.g., 2026-05-30 Copilot pricing pivot, 2026-06-18 Gemini free-tier sunset)
5. A new model was announced that you want included in the cost-routing decisions

Do NOT invoke this skill for every routing decision — the catalog is durable on disk; one discovery
serves many decisions across many iterations. Discovery costs web-search + doc-fetch tokens; manual
invocation should be intentional.

## Discovery workflow

For each host currently active on this project (per `.specrew/host-history.yml` or PATH probe):

### Step 1 — Identify the host's model surface

| Host | Where models are documented |
|---|---|
| Copilot CLI | `gh copilot --help` output + <https://github.com/features/copilot/plans> + GitHub Copilot model docs |
| Claude Code | <https://docs.anthropic.com/en/docs/about-claude/models> |
| Codex CLI | <https://developers.openai.com/codex/cli> + provider model docs |
| Antigravity | <https://antigravity.google/docs/models> + Google AI / Gemini docs |

### Step 2 — Enumerate models per host

For each model the host can dispatch to, capture:

- **id** (canonical model identifier — what the provider's docs call it)
- **tier** — your assessment based on documented pricing + capability:
  - `free` — provider lists as no-cost (e.g., Copilot's free-tier models)
  - `cheap` — under $5/M output tokens (e.g., Claude Haiku, Gemini Flash variants)
  - `balanced` — $5-30/M output tokens (e.g., Claude Sonnet, GPT-4o mid-tier)
  - `premium` — over $30/M output tokens (e.g., Claude Opus, GPT-5 family)
- **cost_per_million_input** — official rate; null if not published
- **cost_per_million_output** — official rate; null if not published
- **capability_tags** — choose from: `code` `reasoning-deep` `reasoning-fast` `fast` `long-context` `vision` `cheap`
- **best_for** — Crew roles this model is best suited for: `Implementer` `Reviewer` `Spec Steward` `Planner` `Retro Facilitator`
- **tokenizer_method** — hint for F-042 cost estimator: `tiktoken-cl100k` (OpenAI family), `tiktoken-o200k` (newer OpenAI), `claude-tokenizer` (Anthropic family), `gemini-tokenizer` (Google family), or null

### Step 3 — Record per-host metadata

- **selector_strategy** — KEEP the value from the schema (already correct per F-041 / Proposal 068):
  - `copilot-cli` → `squad_config_field`
  - `claude-code` → `subagent_frontmatter`
  - `codex-cli` → `agent_toml_field`
  - `antigravity` → `cli_flag`
- **built_in_routing_primitives** — capture host-native cost-routing aliases. Most important:
  - Claude Code's `opusplan` (Opus for `/speckit.plan`, Sonnet for execution) — set `enabled_by_default: false`; user opts in
- **pricing_change_alerts** — search for any provider-published pricing changes with a future or recent effective_date. Capture summary + source_url.

### Step 4 — Write the catalog

Write the populated catalog to `.specrew/model-catalog.yml` following the schema at
`scripts/internal/model-catalog-schema.yml`. Preserve any existing user-edited content
that you can't validate (be conservative — don't blow away custom notes).

Set the top-level metadata:

- `schema_version: 2`
- `last_refreshed_at: <current ISO8601 timestamp>`
- `confidence: high | medium | low` — your honest self-assessment of the discovery quality.
  Use `high` only if you read official documentation; drop to `medium` if you relied on third-party guides;
  drop to `low` if you had to infer pricing or capability tags.

### Step 5 — Output a brief summary

After writing the catalog, output a ~5-line summary the user can review:

```text
Discovery complete. Catalog: .specrew/model-catalog.yml
Hosts populated: <list>
Models discovered: <N>
Pricing alerts: <count> active alerts
Confidence: <high|medium|low>
```

## What this skill does NOT do

- **Does NOT make routing decisions** — that's F-041's coordinator-governance rule. This skill only populates the catalog.
- **Does NOT modify `.squad/config.json` or other per-host overrides** — those are F-041's per-host-model-injection layer.
- **Does NOT bill or estimate cost for past iterations** — that's F-042's measurement layer.

## Safety + hygiene

- The catalog file is sensitive (drives routing decisions). Write atomically; back up the prior file as
  `.specrew/model-catalog.yml.bak` so user can restore if the refresh produced bad data.
- If discovery fails partway (e.g., network error mid-host), write what you have and mark the
  affected host with `available: false` and a `last_refresh_attempt` block recording the failure.
- DO NOT hardcode model names in your reasoning — the entire point of this skill is to AVOID hardcoded
  names. Read everything from the catalog you just wrote.

## Cross-references

- Catalog schema: `scripts/internal/model-catalog-schema.yml`
- Routing logic: F-041 coordinator-governance rule in `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- Per-host injection: `scripts/internal/per-host-model-injection.ps1`
- Cost estimator: F-042 (Proposal 070) reads tokenizer_method hints from the catalog
- Source proposal: file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md
