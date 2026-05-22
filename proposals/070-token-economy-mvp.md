---
proposal: 070
title: Token Economy MVP (Cost-per-Iteration Tracking + Dashboard Surfacing)
status: draft
phase: phase-2
estimated-sp: 5
discussion: ad-hoc 2026-05-20 session; enriched 2026-05-23 with Antigravity host + per-host token-reporting findings
release-urgency: immediate
---

# Token Economy MVP

## Why

User direction (2026-05-20):

> "Token economy — how much each SP cost. Allow priority by cost."

### Refinement (2026-05-21 session): per-host attribution is required

The cost-visibility surface must be **per-host from the start.** Specrew's strategy is to alternate between hosts (Copilot, Claude, Codex) to multiply usable budget — not to replace one host with another. The dashboard COST section and `cost.yml` artifact must therefore distinguish "which host ran each boundary" so that per-host spend, host-share, and per-host cost-per-SP all become visible. Without per-host attribution, the user can't tell whether one host's quota is being exhausted faster than the other, and the alternation strategy can't be tuned.

Specrew today has no per-iteration cost visibility. The 2026-05-16 cost-baseline memory recorded $5.47/SP empirical cost, but that figure came from manual reconciliation of GitHub's premium-request reports against shipped story points. There's no in-repo surface that says "this iteration cost X, this feature cost Y, this host carried Z% of the work."

Without this visibility:

- The user can't validate whether Proposal 068 (Cost-Aware Routing) actually reduces cost — there's no in-repo measurement to compare before/after
- The user can't prioritize features by cost-per-SP — proposals get sized in SP, but SP-to-dollar conversion is folklore not data
- Squad's auto-resolution decisions can't include cost as a factor — there's no cost signal to weight against

Full Proposal 040 (Token Economy as Governance Driver, 38 SP) is the architectural endgame: cost-priority decision UI, billing modes, per-iteration budgets, model-name catalogs at L3-L4. **This proposal ships the MVP slice**: log per-iteration token consumption + cost estimate + surface in `specrew where` dashboard. Just measurement, no governance.

## What

Three pillars:

### Pillar 1: Per-iteration cost artifact (~2 SP)

A new artifact `specs/<feature>/iterations/<NNN>/cost.yml` accumulated during iteration execution:

```yaml
cost:
  schema_version: 1
  iteration: 001
  feature: 024-slash-command-multi-host-correctness
  records:
    - timestamp: 2026-05-20T01:30:00Z
      boundary: plan
      agent: planner
      host: copilot-cli
      model: <discovered-from-catalog>
      tokens_in: 12450
      tokens_out: 3210
      estimated_cost_usd: 0.42
      source: estimated   # estimated | reported | manual
    - timestamp: 2026-05-20T02:15:00Z
      boundary: implement
      agent: implementer
      host: copilot-cli
      model: <discovered>
      tokens_in: 28100
      tokens_out: 8540
      estimated_cost_usd: 0.89
      source: estimated
  aggregates:
    total_tokens_in: 40550
    total_tokens_out: 11750
    total_cost_usd: 1.31
    cost_per_sp_usd: 0.19   # iteration is 7 SP per tasks.md
    by_host:
      copilot-cli:
        cost_usd: 1.31
        share: 1.00
      # other hosts populated when alternation occurs:
      # claude-code: { cost_usd: 0, share: 0 }
      # codex-cli: { cost_usd: 0, share: 0 }
      # antigravity: { cost_usd: 0, share: 0 }
    by_role:
      planner: { cost_usd: 0.42, share: 0.32 }
      implementer: { cost_usd: 0.89, share: 0.68 }
```

Capture mechanism (v1, simplest):

- **Estimated** (default): count tokens in the artifacts produced/consumed at each boundary (spec.md, plan.md, tasks.md, etc.). Apply per-model cost-per-million-token from Proposal 068's catalog. Mark `source: estimated`.
- **Reported** (future): parse host CLI output for actual token counts when the host reports them. Mark `source: reported`.
- **Manual** (escape hatch): user can `specrew cost add --feature ... --iteration ... --tokens-in N --tokens-out N` to enter from a billing-page reconciliation. Mark `source: manual`.

v1 ships estimated-only. Reported + manual are follow-up scope.

#### Per-host reported-token surface (2026-05-23 research findings)

The `source: reported` follow-up needs per-host knowledge of how each host exposes token totals. Findings:

| Host | Reported-token surface | Notes |
|---|---|---|
| **Copilot CLI** | Not surfaced in `copilot -i` stdout; available in github.com/settings/billing premium-request reports (post-hoc, daily granularity). | Reported-mode integration needs API access to GitHub's usage endpoint or screen-scraping from the billing page. |
| **Claude Code** | `claude -p --output-format json` emits `usage.input_tokens` + `usage.output_tokens` per turn. Native, real-time. | Strongest reported-token surface of all four hosts. Specrew can capture per-boundary cost authoritatively when host = claude. |
| **Codex CLI** | `codex exec --json` emits per-request token usage. | Native. |
| **Antigravity CLI** | `agy -p --output-format json` is the verified surface for headless runs (per 2026-05-23 research); token-emission shape not yet documented but the `--output-format json` envelope suggests structured fields. | Empirical verification needed before relying on reported mode. |

Reported-mode v2 should land first for **Claude Code** (richest native surface), then Codex, then Antigravity, then Copilot (likely API-based). This sequencing aligns with the host-priority recommendation in Proposal 069.

### Pillar 2: Cost section in `specrew where` dashboard (~2 SP)

`specrew where` dashboard renderer gains a "COST" section between "VELOCITY" and "RECENT SHIPPED":

```text
COST
Recent iterations:
  F-028 / 001 — $1.18 ($0.07/SP, 18 SP, copilot-cli 60% / claude-code 40%)
  F-026 / 001 — $0.84 ($0.10/SP, 8 SP, claude-code 100%)
  F-024 / 001 — $1.31 ($0.19/SP, 7 SP, copilot-cli 100%)
Last 10 closed: $11.42 total / $0.21/SP average
By host: copilot-cli $7.14 (63%) / claude-code $4.28 (37%)
Trend: improving (cost-per-SP down 22% over last 5 iterations)
```

Trend math: simple comparison of last-5-iterations cost-per-SP vs prior-5-iterations. The per-host split shows budget distribution so the user can tune the alternation strategy (e.g., shift more Implementer work to whichever host has spare quota). No advanced statistics in v1.

Dashboard renderer at `scripts/internal/dashboard-renderer.ps1` gains a Cost block that reads `cost.yml` files from iteration directories.

### Pillar 3: `specrew cost` CLI surface (~1 SP)

Three lightweight commands:

| Command | Purpose |
|---|---|
| `specrew cost summary [--feature <F>] [--last N]` | Show cost rollup across iterations |
| `specrew cost add --feature <F> --iteration <N> --tokens-in N --tokens-out N [--model M]` | Manual entry from billing-page reconciliation |
| `specrew cost recompute --feature <F> --iteration <N>` | Re-estimate from current artifacts (useful after Proposal 068 catalog refresh updates cost-per-token values) |

These are thin wrappers around the cost.yml read/write logic.

## How

| Step | File | Effort |
|---|---|---|
| `cost.yml` schema + helper module | `scripts/internal/cost-tracking.ps1` (new) | 1.5 SP |
| Token estimator (count tokens in markdown artifacts) | same | 0.5 SP |
| Capture hook: write to cost.yml at boundary events | `scripts/internal/sync-boundary-state.ps1` (extend) | 1 SP |
| Dashboard COST block | `scripts/internal/dashboard-renderer.ps1` | 1 SP |
| `specrew cost` command dispatcher | `scripts/specrew-cost.ps1` (new) + `scripts/specrew.ps1` (route) | 0.5 SP |
| Smoke test + doc updates | tests + user-guide | 0.5 SP |

Total: ~5 SP

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | After a complete iteration with at least one boundary advance, `specs/<feature>/iterations/<NNN>/cost.yml` exists with at least one record |
| AC2 | `cost.yml` schema validates: `schema_version`, `iteration`, `feature`, `records` array, `aggregates` block |
| AC3 | `specrew where` dashboard renders a COST section showing recent iterations with cost-per-SP |
| AC4 | `specrew cost summary` returns parseable output (text + `--json` form) |
| AC5 | Cost-per-SP for a known iteration (F-024 iteration 001 once shipped) is within 30% of manually-computed baseline (estimation accuracy bar) |
| AC6 | The `source: estimated` mark is honest — the dashboard explicitly notes "estimated from artifact tokens" when no reported/manual records exist |
| AC7 | Manual entry via `specrew cost add` produces a `source: manual` record that overrides the estimate for that boundary |
| AC8 | When an iteration runs on multiple hosts (alternation), `cost.yml`'s `aggregates.by_host` block reports each host's share; the dashboard's COST section surfaces a per-host split as a single summary line. Single-host iterations show `host 100%` cleanly without noise |

## Out of scope

- **Cost-priority routing** — Squad does NOT use cost as a routing input in v1. Routing decisions (Proposal 068) stay capability-driven; cost tracking is observational only.
- **Per-iteration budgets / cost gates** — no "this iteration exceeds budget; pause for human approval" behavior. That's Proposal 040's governance layer.
- **Host CLI output parsing for actual token counts** — `source: reported` mode is defined in the schema but not implemented in v1.
- **Multi-user cost attribution** — Proposal 010 (Multi-Developer Reconciliation). v1 records cost on whoever's iteration directory it lands in.
- **Currency conversion** — USD only.
- **Cost-priority feature ordering** — Proposal 028 / Proposal 033 governance CLI would surface this. v1 measures, doesn't prioritize.

## Composition

| Proposal | Relationship |
|---|---|
| **040 (Token Economy as Governance Driver)** | Architectural parent. This proposal ships the L1-L2 measurement layer; 040 adds L3-L7 (catalog, billing modes, budget gates, governance decision UI). When 040 ships, this proposal's outputs feed it. |
| **068 (Cost-Aware Model Routing)** | The model catalog produced by 068's discovery skill is the cost-per-token authority this proposal reads. Without 068, the estimator has no per-model pricing to apply. Tight composition — 068 should ship first or alongside. |
| **069 (Multi-Host Launch Path)** | Cost records include `host: ...` field; 069's per-host launch is what populates that. Both proposals share host-awareness. |
| **048 (Dashboard Velocity Metric Refinement)** | Dashboard rendering composes with this proposal's COST block. When 048 ships, the Cost section gets the same Peak/Recent/Trailing trend treatment as Velocity. |
| **055 (Always-In-Flow Discipline)** | When 055's slice-type catalog ships, cost data per slice type becomes a natural cross-cut. |
| **067 (Small-Fix Slice)** | This proposal's ship cycle follows the 067 contract. |

## Empirical baseline (for AC5 calibration)

Per the 2026-05-16 cost-baseline memory: ~$5.47/SP empirical, computed manually. The MVP estimator should land within 30% of that baseline on iterations from the past 7-14 days (where the baseline math is most relevant). If the estimator is wildly off (>50% error), the model catalog (Proposal 068) is the most likely culprit and we recalibrate.

Once Proposal 068's catalog is populated with current Copilot pricing, expect the estimator to track close to actual billing-page numbers.

## Cross-references

- Memory: `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]` — $5.47/SP empirical baseline; ~67% premium model concentration
- file:///C:/Dev/Specrew/proposals/040-token-economy-governance.md
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md
- file:///C:/Dev/Specrew/proposals/048-dashboard-velocity-metric-refinement.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
