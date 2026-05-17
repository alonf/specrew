---
proposal: 040
title: Token Economy as Governance Driver
status: draft
phase: phase-4
estimated-sp: 38
discussion: tbd
---

# Token Economy as Governance Driver

## Why

Empirical 2026-05-16 cost data showed Specrew development consumed ~600/1500 Copilot Premium requests in 16 days. Projected monthly cost: $1,500-2,000. Cost-per-SP currently sits at ~$5.47 (F-019 at 22 SP = ~$120 marginal Copilot cost). Without explicit guardrails, cost grows linearly with feature complexity. With guardrails, Specrew can route work to lower-cost tiers when capability allows.

User signal 2026-05-16: cost-per-SP and remaining quota are FIRST-CLASS user-facing metrics that should drive routing decisions, not just post-hoc reporting. Two billing modes need governance: metered (Copilot AIC, API direct) and quota (Claude Max, Codex Pro). Cross-program arbitrage is real: route to whatever has remaining quota + remaining $.

Critical design constraint from user 2026-05-16: **model names cannot be in the design**. Need an abstraction layer that lets the design refer to capability tiers without hardcoding specific models. Model names live ONLY in the catalog layer (L3-L4), nowhere in design / role mappings / cost predictor logic.

## What

### Seven-layer architecture

| Layer | Name | Content |
|---|---|---|
| **L1** | Capability tiers | `Frontier`, `Versatile`, `Lightweight`, `Economy`, `Free` (5 tiers based on capability profile, not vendor) |
| **L2** | Role → tier mapping | Each Squad role (Spec Steward, Planner, Implementer, etc.) maps to one or more acceptable tiers per task type |
| **L3** | Model catalog per provider + program | Concrete model IDs (Opus 4.7, GPT-5.4, Sonnet 4.6, etc.) classified into L1 tiers per provider. ONLY layer where model names live. |
| **L4** | Cost database with billing-mode awareness | Per-model cost ($/1M tokens or $/request) + billing mode (metered vs quota) + remaining quota tracking |
| **L5** | Empirical capability (incl. repair iterations) | Measured pass-rate per tier per task type, incl. repair-cycle overhead. Feedback loop from actual usage. |
| **L6** | Cost predictor | Given a task + role + tier, predict cost. Aggregates across L4 + L5. |
| **L7** | Dashboard | User-facing surface: cost-per-SP, remaining quota per program, projected cost-to-feature-completion. Integrates with [009](009-velocity-dashboard.md). |

### Two billing modes governed

1. **Metered** (Copilot AI Credits, API direct, OpenAI/Anthropic pay-as-you-go) — cost-per-request or cost-per-token; tracked as $ spent.
2. **Quota** (Claude Max $20/mo, Codex Pro, Copilot subscription) — fixed budget per period; tracked as % of quota used.

Cross-program arbitrage: where to route based on remaining quota across all available programs + remaining $ budget for metered.

### Cost-per-SP headline metric

- Single number: dollar cost / story point shipped.
- Surfaced on dashboard alongside velocity.
- Composable across mixed-billing (metered + quota normalized to dollar-equivalent).

### Out of scope

- Auto-routing without explicit role-tier-task-type binding (validated by L5 capability data first)
- Replacing the L1 5-tier taxonomy with a dynamic / learned alternative (start static)
- Tracking individual model usage at sub-Squad granularity (start at role level)

## Effort

- **Iteration 1** (~12-15 SP): L1-L4 layers (capability tiers, role mapping, model catalog, cost DB). Static MVP.
- **Iteration 2** (~10-13 SP): L5-L6 (empirical capability tracking + cost predictor)
- **Iteration 3** (~10 SP): L7 dashboard integration with [009](009-velocity-dashboard.md)

**Total**: ~30-40 SP across 2-3 iterations

## Phase placement

**Phase 4**, alongside [016](016-outcome-scoring.md) (outcome scoring). The two compose: outcome quality + cost-per-SP = unit economics dashboard.

## Open questions

1. L1 tier definitions: hard cutoffs by parameter count + context window + capability eval scores, or descriptive ("frontier" / "versatile" / etc. with examples)?
2. L4 quota tracking: pulled from provider APIs (where available) vs manually entered ceilings?
3. L5 empirical capability: how is "pass rate" defined for non-binary outcomes (e.g., spec-quality scoring from [016](016-outcome-scoring.md))?
4. L7 dashboard: separate `specrew cost` command, or integrated into existing `specrew where`?
5. Should cost-per-SP be a HEADLINE metric or a drill-down? (Headline competes for screen space with velocity.)
6. Mixed-billing normalization: at what conversion rate? (Recommended: notional dollar-equivalent for quota programs based on plan price / typical usage)
7. Cross-program arbitrage: explicit routing rules vs operator-driven (dashboard surfaces tradeoffs, human decides)?
8. Repair-cycle cost attribution: charged to the feature being repaired or amortized across the iteration?

## Risks

- L1 taxonomy is opinionated; some users will disagree. Mitigation: tiers are configurable per project via `.specrew/quality/tier-classification.yml` (similar pattern to stack-aware tool selection).
- L4 quota tracking via provider APIs is fragile (each provider differs). Mitigation: manual ceilings are an acceptable fallback.
- Cost-per-SP can be perceived as financial pressure on contributors. Mitigation: framing is governance/transparency, not blame.

## Cross-references

- Composes with [016](016-outcome-scoring.md) (cost + outcome-quality = unit economics)
- Composes with [009](009-velocity-dashboard.md) (L7 dashboard layer)
- Composes with [024](024-multi-host-runtime-abstraction.md) (host-neutral tier routing requires CORE)
- Composes with [041](041-specrew-autopilot.md) (autopilot decisions are cost-sensitive)
- Empirical source: file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_copilot_cost_baseline_and_strategy_2026_05_16.md (kept in memory as ongoing strategic context)

## Status history

- 2026-05-13: initial research-stage capture
- 2026-05-16: promoted with two-architectural-iteration scope + cost-baseline empirical data
- 2026-05-18: promoted to draft proposal during memory→proposals consolidation
