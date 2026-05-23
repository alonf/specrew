---
proposal: 106
title: Provider Billing Reconciliation + Estimator Calibration (Closed-Loop Cost Accuracy)
status: candidate
phase: phase-2
estimated-sp: 12-18
discussion: ad-hoc 2026-05-23 — surfaced by user question "can the user feed the actual usage from the provider site and get the actual numbers for comparison and fine tuning?"
---

# Provider Billing Reconciliation + Estimator Calibration

## Why

F-042 (Token Economy MVP) ships per-iteration cost estimation via a catalog-driven calculator. Estimates have ~70-95% accuracy depending on tokenizer availability (naive byte/4 is ~70-80%; per-model tokenizers reach ~95%). For organizations spending hundreds-to-thousands of USD per month on AI infrastructure, that gap matters — a 15% estimator error on a $2K/month spend is a $300/month visibility hole.

F-042 includes an MVP reconciliation surface (FR-013 catalog display + FR-014 Anthropic CSV import + FR-015 reconcile report) but explicitly stops at REPORTING. The next-level value is **closed-loop calibration**: feed reconciliation deltas back into the estimator so subsequent iterations use empirically-tuned multipliers.

This proposal closes that loop. It also extends F-042's MVP one-provider import to a multi-provider matrix (Anthropic + Copilot + Codex + Google AI) and adds the calibration write-back pattern.

User direction (2026-05-23 ad-hoc):

> "Do we have a way to show the cost (both the table and the consumption) and if the user sees the actual usage from the provider site, can it provide the actually numbers for comparison and fine tuning?"

## What

Three pillars composing on top of F-042's measurement layer:

### Pillar 1: Multi-provider billing import (~5-7 SP)

Extend F-042's MVP single-provider (Anthropic) import to all four:

- **Anthropic** — billing CSV from console.anthropic.com (shipped in F-042 MVP; this proposal hardens the parser for column-name variations)
- **GitHub Copilot** — premium-request usage export from github.com/settings/billing; transitioning June 1 2026 to AI Credits which changes the format
- **OpenAI / Codex** — billing CSV from platform.openai.com; credit-to-USD normalization
- **Google AI / Antigravity** — billing JSON from cloud.google.com/billing (when Antigravity host ships)

Each provider gets a parser at `scripts/internal/cost-actuals-{provider}.ps1`. All parsers normalize to the canonical `.specrew/actuals/<provider>-<YYYY-MM>.yml` schema.

### Pillar 2: Calibration factor computation + write-back (~5-7 SP)

After reconciliation, the user can apply suggested calibration factors:

```text
$ specrew cost reconcile --month 2026-05
... (report from F-042) ...

Apply calibration factors? [y/n/r=review-first]
> r

Suggested .specrew/calibration.yml entries:
  claude-haiku-4-5      naive_byte_4_multiplier: 1.087     (95% confidence; 47 data points)
  claude-sonnet-4-6     naive_byte_4_multiplier: 0.952     (98% confidence; 28 data points)
  gpt-5-mini            naive_byte_4_multiplier: 1.000     (no change; estimator was correct)
  gpt-5.4               naive_byte_4_multiplier: 0.998     (no change; <1% drift)

Confidence interpretation:
  >90% = strong signal; safe to apply
  50-90% = moderate; review the underlying records
  <50% = weak; gather more data before applying

Apply? [y/n/per-model]
> y
Wrote .specrew/calibration.yml; effective from 2026-06-01.
Next estimate per model multiplies the naive byte/4 estimate by the calibration factor.
```

`.specrew/calibration.yml` is gitignored by default (similar to pricing-overrides) so per-project calibration doesn't leak between developers.

### Pillar 3: Dashboard surfaces showing the closed loop (~2-4 SP)

`specrew where` dashboard COST section gets two new lines when calibration is active:

```text
COST
Recent iterations:
  F-042 / 001 — $0.94 ($0.13/SP, 7 SP, claude-code 100%)
  F-041 / 001 — $1.18 ($0.07/SP, 18 SP, copilot 60% / claude-code 40%)
  F-040 / 001 — $1.31 ($0.19/SP, 7 SP, copilot 100%)
Last 10 closed: $11.42 total / $0.21/SP average
By host: copilot $7.14 (63%) / claude-code $4.28 (37%)
Trend: improving (cost-per-SP down 22% over last 5 iterations)

Calibration: ACTIVE since 2026-06-01 (4 models calibrated; haiku +8.7%, sonnet -4.8%)
Reconciliation: last reconcile 2026-05-31 against May 2026 actuals; 94.7% confidence
```

## How

| Step | Surface | Effort |
|---|---|---|
| Multi-provider parsers (Copilot premium-request export, Codex CSV, Google AI JSON) | `scripts/internal/cost-actuals-copilot.ps1`, `scripts/internal/cost-actuals-codex.ps1`, `scripts/internal/cost-actuals-google.ps1` | 3-4 SP |
| Calibration computation | `scripts/internal/cost-calibration.ps1` — `Compute-SpecrewCalibrationFactors`, `Apply-SpecrewCalibration`, `Get-SpecrewCalibration`, `Test-SpecrewCalibrationSchema` | 2-3 SP |
| Calibration-aware estimator | Extend `Get-SpecrewTokenEstimate` in cost-tracking.ps1 to multiply by calibration factor when present (with confidence threshold gating) | 1 SP |
| CLI extension: `specrew cost calibrate [--apply / --review / --status]` | `scripts/specrew-cost.ps1` | 1-2 SP |
| Dashboard COST section calibration + reconciliation lines | `scripts/internal/dashboard-renderer.ps1` | 1 SP |
| Integration tests covering: multi-provider import, calibration write-back, calibration-aware estimation, dashboard surfacing | `tests/integration/cost-reconciliation-calibration.tests.ps1` (new) | 2-3 SP |
| Docs: provider-specific import instructions (CSV format per provider, where to download from) | `docs/user-guide.md` extension | 1 SP |

Total: ~12-18 SP

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | `specrew cost actuals import --provider copilot --file <csv>` parses the GitHub premium-request export format (handles both pre-2026-06-01 and post-AI-Credits formats); stores at `.specrew/actuals/copilot-<YYYY-MM>.yml` |
| AC2 | `specrew cost actuals import --provider codex --file <csv>` parses the OpenAI Codex billing export; credit-to-USD normalization via the catalog's credit_value_usd field |
| AC3 | `specrew cost actuals import --provider google --file <json>` parses the Google Cloud Billing JSON export (Antigravity / Gemini Agent Platform charges) |
| AC4 | `specrew cost calibrate --review` computes per-model calibration factors from reconciliation deltas; shows confidence percentages + data-point counts; does NOT write yet |
| AC5 | `specrew cost calibrate --apply` writes `.specrew/calibration.yml`; factors take effect at the configured `effective_from` date (default: next iteration boundary) |
| AC6 | Calibration-aware estimator: when `.specrew/calibration.yml` has a factor for the model being estimated AND confidence ≥ configured threshold (default 80%), the naive byte/4 estimate gets multiplied by the factor; estimator returns `tokenizer_method: 'naive_byte_4_calibrated'` and `confidence: 'medium'` |
| AC7 | Confidence threshold for auto-application is configurable in `.specrew/config.yml` (`calibration.minimum_confidence_pct: 80` default); user can opt into riskier auto-apply (e.g., 50%) or require manual approval (100%, never auto-apply) |
| AC8 | `specrew where` dashboard COST section shows "Calibration: ACTIVE" line when `.specrew/calibration.yml` exists, with summary of which models are calibrated + direction (+/-%) |
| AC9 | `specrew where` dashboard COST section shows "Reconciliation: last reconcile YYYY-MM-DD against <month> actuals; confidence %" when reconcile has run |
| AC10 | `.specrew/calibration.yml` is added to `.gitignore` on greenfield bootstrap (per-project calibration doesn't leak between developers) |
| AC11 | `specrew cost recompute --all` recomputes WITH calibration factors applied (if `.specrew/calibration.yml` exists); user sees the empirical-adjusted cost figures retroactively |
| AC12 | When a catalog refresh (via `/specrew-research-models`) writes new public rates, calibration factors are preserved (they apply over whatever the underlying rate is); user gets a notice "Catalog refreshed; calibration factors retained — re-reconcile when fresh actuals are available" |

## Out of Scope

- **Automatic monthly reconciliation** — F-042 + this proposal both require explicit user invocation. A future Proposal could add a `specrew schedule` for monthly auto-reconcile, but that's separate.
- **Cross-month calibration drift** — calibration factors are point-in-time. Tracking how they drift month-over-month is observability data; doesn't change the cost layer.
- **Per-feature calibration** — calibration factors are per-model, not per-(model, feature). If a feature has unusual prompt patterns that move the calibration, that's an edge case the user investigates manually.
- **Provider API integration** — Specrew does NOT directly call billing APIs (which would require OAuth + sensitive credential storage). User exports CSVs/JSON manually and feeds them to `cost actuals import`. API integration is a Proposal 040 (Token Economy Governance) future surface, not 106.
- **Multi-project calibration sharing** — each project keeps its own `.specrew/calibration.yml`. Sharing across projects belongs to Proposal 010 (Multi-Developer Reconciliation) territory.

## Composition

| Proposal | Relationship |
|---|---|
| **070 / F-042 Token Economy MVP** | Direct dependency. F-042 ships estimator + cost.yml records + the MVP catalog display / Anthropic import / reconcile report. Proposal 106 extends those primitives with multi-provider import + calibration write-back. |
| **068 / F-041 Cost-Aware Model Routing** | F-041's catalog + pricing-overrides feed Proposal 106's reconciliation math. Calibration factors persist alongside (not inside) catalog. |
| **069 / F-040 Multi-Host Launch Path (shipped v0.26.0)** | F-040's `selected_host` records the host attribution that reconciliation needs to match estimates against the right provider's actuals. |
| **040 Token Economy as Governance Driver** | Architectural parent. F-042 + Proposal 106 together ship L1-L3 of 040's 7-layer architecture (measurement + reconciliation + calibration). 040's L4-L7 (governance, budget gates, decision UI) remain future. |
| **048 Dashboard Velocity Metric Refinement** | When 048 ships, the calibration/reconciliation lines in COST section get the same Peak/Recent/Trailing trend treatment that 048 gives velocity. |
| **010 Multi-Developer Reconciliation (Phase 5)** | Future intersection: per-developer calibration data could feed multi-dev cost-attribution reports. |
| **092 Specrew Dashboard Web App** | A web dashboard could plot calibration drift over time; this proposal's per-month YAML output is the data source. |
| **059 Legacy-State Read-Tolerance** | Calibration schema versioning follows 059's pattern; brownfield migration covered. |

## Risks

- **User imports the wrong provider's CSV** — Anthropic import command receives a Copilot CSV; parser writes nonsense. Mitigation: each parser validates expected columns; emits clear error "this file doesn't look like an Anthropic billing export" before writing.
- **Calibration drift unnoticed** — applied calibration is wrong for a new month's usage patterns; cost estimates stay off. Mitigation: reconciliation report shows accuracy each month; user gets a warning when reconciliation confidence drops >10% between months (suggests re-calibration needed).
- **Privacy / billing-data leak** — `.specrew/actuals/*.yml` contains the user's billing data. Mitigation: `.specrew/actuals/` is gitignored on greenfield bootstrap; documentation warns about exposing this data publicly.
- **Tokenizer adoption obviates calibration** — if user opts into the per-model tokenizer (F-042 v2 follow-up), naive byte/4 estimates become irrelevant. Mitigation: calibration factors are SCOPED to estimation method (`naive_byte_4_multiplier` is a separate field from `tiktoken_cl100k_multiplier`); when user upgrades the estimator, the new method has its own calibration row.
- **Provider CSV format drift** — Anthropic / OpenAI / GitHub change billing export columns; parsers break. Mitigation: parsers tolerate column-name variations (the F-042 MVP Anthropic parser already does this); test fixtures captured per provider; bug-fix slice when a provider changes format.

## Why this is a separate proposal (not in F-042)

F-042 ships the *measurement* layer. Proposal 106 ships the *learning* layer. These have different value-per-SP curves:

- F-042 measurement: every iteration writes cost.yml, dashboard shows cost-per-SP, manual reconciliation possible via `cost add`. **Useful in isolation; pays for itself on day one.**
- Proposal 106 calibration: requires the user to actually import billing data (monthly cycle), run reconciliation, review suggested factors, apply them. **Higher friction; pays off over months.**

Shipping F-042 first lets users build the cost.yml record corpus; Proposal 106 then has data to calibrate against. Reverse order doesn't work — calibration without measurement records has nothing to compute.

## Cross-references

- file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md (F-042 — direct dependency)
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md (F-041 — catalog + overrides feed reconciliation math)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (F-040 — host attribution for matching actuals to estimates)
- file:///C:/Dev/Specrew/proposals/040-token-economy-governance.md (architectural parent; 106 ships L1-L3 layers)
- file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md (calibration schema versioning pattern)
- file:///C:/Dev/Specrew/specs/042-token-economy-mvp/spec.md (FR-013/14/15/16 — the MVP layer 106 builds on)
