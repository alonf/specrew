# Feature Specification: Token Economy MVP (Cost-per-Iteration Tracking + Dashboard Surfacing)

**Feature Branch**: `042-token-economy-mvp`
**Created**: 2026-05-23
**Status**: Draft
**Input**: User direction (2026-05-20 ad-hoc session): "Token economy — how much each SP cost. Allow priority by cost." Refined 2026-05-21: per-host attribution required from day one to enable multi-host budget-optimization strategy.
**Source proposal**: file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md (enriched 2026-05-23 with per-host reported-token surface inventory + by_host aggregation extended for antigravity)
**Composes with**: F-040 Multi-Host Launch Path (host enum for the `host:` field), F-041 Cost-Aware Model Routing (catalog provides cost-per-token authority), Proposal 048 Dashboard Velocity Metric Refinement (Cost block gets same Peak/Recent/Trailing treatment when 048 ships)
**Release urgency**: high — composes with F-041 to make cost reduction measurable, not folklore

## Clarifications

### Session 2026-05-23

Spec drafted overnight while user was offline. Four clarify defaults documented inline; user reviews + overrides at clarify boundary.

- Q1: Token-counting method for `source: estimated` — naive byte/word approximation, or per-model tokenizer (e.g., tiktoken for OpenAI-family, claude-tokenizer for Anthropic)? → **Default A: Per-model tokenizer where available; naive fallback otherwise.** Tokenizers add a dependency but estimates are 10-15× more accurate than naive byte/4 estimates. Catalog v2 (F-041) records tokenizer hint per model; F-042 reads that hint.
- Q2: Should F-042 ship `source: reported` (parse host CLI output for actual token counts) in v1, or estimated-only? → **Default A: Estimated-only in v1.** Reported-mode requires per-host CLI-output parsers and the host APIs differ. Catalog v2 records `reported_token_surface` per host (Claude richest via `--output-format json`; Codex via `--json`; Copilot post-hoc only); reported-mode ships as F-042 follow-up small-fix slice once at least one host is wired.
- Q3: Granularity of `cost.yml` entries — per-boundary (one record per /speckit.sync-* call), per-role, per-task-id? → **Default A: Per-boundary AND per-role.** Each routing decision logs a record with role + boundary + estimated tokens + cost. Aggregation over the iteration is computed at read-time. Avoids over-recording while preserving the per-host alternation visibility the strategy needs.
- Q4: Dashboard COST section refresh — auto-render on every `specrew where` invocation, or cached with a `--refresh-cost` flag? → **Default A: Auto-render every invocation.** Cost.yml files are small (<5KB per iteration); reading 10 iterations + summing is sub-millisecond. No caching complexity. If performance becomes an issue post-ship, add a cache as a small-fix.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Per-iteration cost visibility closes the loop on F-041 (Priority: P1)

A maintainer who shipped F-041 (cost-aware routing) wants to verify the strategy actually saves money. Today the only signal is folklore — the 2026-05-16 cost-baseline memory says "$5.47/SP empirical baseline" computed by manually reconciling premium-request reports against shipped story points. Without F-042 measurement, the user can't tell whether F-041's lean profile is actually reducing per-iteration spend. After F-042, every iteration writes a `cost.yml` artifact with token counts, cost estimates, and per-host attribution; `specrew where` dashboard surfaces a COST section that compares recent iterations to a trailing baseline.

**Why this priority**: F-041 + F-042 together unlock the cost-reduction story. F-041 routes; F-042 measures. Without measurement, "the lean profile saved 30%" is unverifiable claim. With measurement, it's empirical evidence in `cost.yml`.

**Independent Test**: Run a complete feature iteration after F-042 ships. Verify `specs/<feature>/iterations/<NNN>/cost.yml` exists with at least one record per boundary advanced, aggregates block populated, and `specrew where` dashboard shows a COST section with cost-per-SP for the iteration.

**Acceptance Scenarios**:

1. **Given** an iteration completes with at least one boundary advance, **When** the closeout-sync command runs, **Then** `specs/<feature>/iterations/<NNN>/cost.yml` exists with at least one record (per FR-001) and the aggregates block (per FR-005) populated
2. **Given** an iteration runs across two hosts (Copilot for plan, Claude for implement), **When** `cost.yml` is read, **Then** `aggregates.by_host` has entries for both hosts with non-zero `cost_usd` and `share` values that sum to 1.0
3. **Given** `specrew where` is invoked on a project with at least one closed iteration, **When** the dashboard renders, **Then** a COST section appears between VELOCITY and RECENT SHIPPED (per FR-007) showing recent iterations with cost-per-SP
4. **Given** cost-per-SP for an iteration is within 30% of the manually-computed 2026-05-16 baseline ($5.47/SP), **When** the estimator is calibrated, **Then** the COST section's "Trend" line correctly classifies improvement/regression
5. **Given** the catalog at `.specrew/model-catalog.yml` is missing or has incomplete cost-per-token data, **When** F-042 attempts to compute cost, **Then** the record marks `cost_estimate_confidence: low` and the dashboard surfaces the warning prominently

---

### User Story 2 — Per-host cost attribution surfaces budget alternation strategy (Priority: P1)

The Specrew strategy is to alternate hosts within a project to multiply usable budget (Claude Max $200/mo + remaining Copilot quota, etc.). Without per-host attribution in `cost.yml`, the user can't tell which host is carrying which workload — they can't tune alternation. After F-042, every cost record has a `host:` field (sourced from F-040's `selected_host` at record-write time) and the dashboard surfaces `By host: copilot 60% / claude-code 40%` per iteration.

**Why this priority**: This is the 2026-05-21 refinement that promoted F-042 from "nice-to-have measurement" to "load-bearing for the multi-host strategy". Specrew is NOT replacing Copilot with Claude; it's alternating to multiply runway. Without per-host visibility, the alternation is invisible and untunable.

**Independent Test**: Run two iterations on different hosts (e.g., iteration 001 on Copilot, iteration 002 on Claude). Verify each iteration's `cost.yml` `aggregates.by_host` reports the correct host. Aggregated across both iterations at the feature level, the user sees the host-share distribution.

**Acceptance Scenarios**:

1. **Given** an iteration runs on `--host claude`, **When** `cost.yml` records are written, **Then** each record has `host: claude-code` matching F-040's start-context.json `selected_host` (case-normalized)
2. **Given** mid-feature host switch (iteration 001 on Copilot, iteration 002 on Claude), **When** the feature-level cost rollup is computed (across all closed iterations), **Then** the by_host breakdown reflects each iteration's host independently and sums correctly
3. **Given** `specrew where` dashboard renders the COST section, **When** at least two hosts have been used in recent iterations, **Then** a "By host:" line shows the share distribution (e.g., `copilot 63% / claude-code 37%`)
4. **Given** a single-host iteration, **When** the dashboard renders, **Then** the by_host display reads cleanly as `host 100%` without noise

---

### User Story 3 — `specrew cost` CLI surface lets the user reconcile + recompute (Priority: P2)

The user wants to be able to (a) summarize cost across recent iterations from the command line, (b) enter actual token counts from billing-page reconciliation when they want ground truth, and (c) recompute estimates after a catalog refresh that changes per-token pricing. Three lightweight `specrew cost` subcommands cover these.

**Why this priority**: Without the CLI, the cost.yml files are invisible unless the user opens them manually or runs `specrew where`. The CLI makes cost a first-class lifecycle concern.

**Independent Test**: After at least one iteration ships with F-042, run `specrew cost summary --last 5` and verify parseable output (text + `--json` flag). Run `specrew cost add --feature 040 --iteration 001 --tokens-in 12000 --tokens-out 4500` and verify a new record is appended to that iteration's cost.yml with `source: manual`.

**Acceptance Scenarios**:

1. **Given** at least one iteration has shipped cost.yml records, **When** `specrew cost summary` runs, **Then** the output lists recent iterations with cost/SP/host breakdown
2. **Given** `specrew cost summary --json`, **When** the command runs, **Then** the output is valid JSON suitable for downstream tooling
3. **Given** `specrew cost add --feature <F> --iteration <N> --tokens-in N --tokens-out N`, **When** the command runs, **Then** a new record is appended to the iteration's cost.yml with `source: manual` and the aggregates block recomputes
4. **Given** the catalog refreshes with new per-token pricing, **When** `specrew cost recompute --feature <F> --iteration <N>` runs, **Then** existing `source: estimated` records get new cost figures (estimated records re-estimate from the new catalog; manual records are left unchanged)
5. **Given** `specrew cost recompute --all`, **When** the command runs, **Then** all `source: estimated` records across the project re-estimate from the current catalog (useful after a 2026-05-30 Copilot pricing pivot)

---

### Edge Cases

- **Iteration with zero boundary advances** (rare; iteration that was opened then immediately closed via rollback): cost.yml exists with empty records[] and aggregates block all zeros. Dashboard surfaces `(no recorded cost)` rather than crashing.
- **Catalog missing entirely**: cost.yml records still write with `cost_per_million_input: null` and `estimated_cost_usd: null`; aggregates block reflects null. Dashboard surfaces the missing-catalog warning at the top of the COST section.
- **Catalog has model id but no cost-per-token data**: cost is null for that boundary; aggregates still compute over records with non-null cost. `cost_estimate_confidence: low` on the iteration.
- **Multi-host alternation within an iteration** (rare): each boundary records its `host:` at record-write time. If `selected_host` changed mid-iteration (which requires session restart per F-040), records reflect the actual host that was active at each boundary.
- **Manual entry corrects an estimated record**: `specrew cost add` with same boundary+role+timestamp overwrites the estimated record (source: estimated → source: manual). Manual records always win for that boundary key.
- **Token estimator fails (e.g., tokenizer crash on huge artifact)**: cost record writes with `estimator_error: <message>` and naive byte/4 fallback estimate. Doesn't block iteration progression.

## Functional Requirements

| FR | Statement |
|---|---|
| FR-001 | A new artifact `specs/<feature>/iterations/<NNN>/cost.yml` MUST be created/updated on every boundary advance during iteration execution |
| FR-002 | Each record MUST include: timestamp (ISO8601), boundary (canonical 9-boundary name from F-039), agent/role, host (matching F-040's `selected_host` case-normalized), model id, tokens_in, tokens_out, estimated_cost_usd, source (`estimated`/`reported`/`manual`) |
| FR-003 | Estimated-mode token-counting MUST use per-model tokenizer where catalog v2 (F-041) provides a tokenizer hint; falls back to naive byte/4 estimate when no tokenizer hint is available. Estimator records the method used in `tokenizer_method` field |
| FR-004 | Per-model cost-per-million-input/output rates MUST be read from `.specrew/model-catalog.yml` (F-041). Cost = (tokens_in / 1e6) × cost_per_million_input + (tokens_out / 1e6) × cost_per_million_output |
| FR-005 | The `aggregates` block MUST include: total_tokens_in, total_tokens_out, total_cost_usd, cost_per_sp_usd (computed from iteration tasks.md), `by_host` (per-host cost_usd + share), `by_role` (per-role cost_usd + share) |
| FR-006 | When the catalog is incomplete (model missing or cost-per-token data unavailable), the iteration record MUST set `cost_estimate_confidence: low` and individual records MUST set `estimated_cost_usd: null` for incomplete entries |
| FR-007 | The `specrew where` dashboard MUST render a COST section between VELOCITY and RECENT SHIPPED. The section shows recent N iterations with cost-per-SP, last-10-closed total + average, by-host distribution, and trend (improving/declining classification from last-5 vs prior-5 cost-per-SP) |
| FR-008 | `specrew cost summary [--feature <F>] [--last N] [--json]` MUST emit cost rollup across iterations. Default is last 10 closed iterations across all features. `--feature` filters to one feature; `--json` emits parseable JSON |
| FR-009 | `specrew cost add --feature <F> --iteration <N> --tokens-in N --tokens-out N [--model M] [--role R] [--boundary B]` MUST append a `source: manual` record to that iteration's cost.yml and recompute the aggregates block. Manual records win for the matching boundary+role key |
| FR-010 | `specrew cost recompute [--feature <F> --iteration <N>]` (or `--all` for the whole project) MUST re-estimate `source: estimated` records from the current `.specrew/model-catalog.yml`. `source: manual` records are left unchanged |
| FR-011 | F-042 cost.yml MUST support `host: antigravity` once Proposal 069 Antigravity follow-up slice ships. F-042 v1 hardcodes the 4-host enum from F-040 (copilot/claude-code/codex-cli/antigravity) but only writes records for actually-active hosts |
| FR-012 | F-042 MUST NOT alter F-039's boundary discipline. Cost.yml writes happen INSIDE the canonical boundary-sync flow (extending sync-boundary-state.ps1, not bypassing it), so all writes are gated by F-039 authorization |
| FR-013 | `specrew cost catalog [--effective] [--diff] [--json]` MUST display the rate table from `.specrew/model-catalog.yml`. Default form shows public list rates per (host, model). `--effective` applies any `.specrew/pricing-overrides.yml` overlay (per F-041 FR-017) so the user sees their actual negotiated rates. `--diff` shows only rows where effective ≠ public (audit view of what org contract buys). `--json` emits parseable JSON. Output includes contract expiry warnings per F-041 FR-019 |
| FR-014 | `specrew cost actuals import --provider <kind> --file <path>` MUST accept a CSV or JSON billing export from a supported provider (MVP: Anthropic billing CSV first; Copilot + Codex + others ship as small-fix slices of Proposal 106). Parses provider-specific format; stores as `.specrew/actuals/<provider>-<month>.yml` with per-line-item records (timestamp, model, tokens_in, tokens_out, charged_usd, line_item_id) |
| FR-015 | `specrew cost reconcile [--month YYYY-MM] [--feature <F>]` MUST produce a reconciliation report comparing Specrew's estimated cost (from cost.yml records in scope) against provider actuals (from `.specrew/actuals/`). Report shows: total estimated vs actual, delta with confidence percentage, per-model accuracy breakdown (estimator-vs-actual ratio), and per-host accuracy. Output includes calibration-factor suggestions for models where estimator is consistently off by >5% |
| FR-016 | F-042 v1 reconciliation is REPORTING ONLY — does NOT auto-apply calibration factors. Calibration write-back to a `.specrew/calibration.yml` file is reserved for **Proposal 106 (Provider Billing Reconciliation + Estimator Calibration)** as a follow-up feature. F-042 surfaces the suggested calibration factors so the user can manually copy them into pricing-overrides or wait for Proposal 106 to ship the learning loop |

## Out of Scope

This feature explicitly does NOT include:

- **Cost-priority routing input** — Squad does NOT use F-042 cost data as a routing input. Routing stays capability-driven via F-041's lean profile. F-042 is observational only.
- **Per-iteration budgets / cost gates** — no "this iteration exceeds budget; pause for human approval" behavior. That's Proposal 040 (Token Economy as Governance Driver, Phase 4).
- **Host CLI output parsing for actual token counts** (`source: reported`) — schema defines the source value but parsers ship in a follow-up small-fix slice once Claude `--output-format json` integration is wired (richest surface per F-040 research).
- **Multi-user cost attribution** — Proposal 010 Multi-Developer Reconciliation. v1 records cost on whoever's iteration directory it lands in.
- **Currency conversion** — USD only.
- **Cost-priority feature ordering** — Proposal 028 / Proposal 033 governance CLI surfaces. v1 measures, doesn't prioritize.
- **Cost forecasting per feature scope** — Proposal 040 covers cost-aware decision UI.
- **Per-developer cost-per-SP dashboards** — Proposal 092 Specrew Dashboard Web App (Phase 4).

## Composition

- **070 (this feature's source proposal)** — full design surface; F-042 implements all three pillars
- **068 / F-041 Cost-Aware Model Routing** — F-042's cost estimates read F-041's catalog; tight composition. F-041 should ship first; F-042 can ship in same release if branched correctly
- **069 / F-040 Multi-Host Launch Path (shipped v0.26.0)** — F-042's `host:` field comes from F-040's `selected_host` in start-context.json. Per-host attribution depends on F-040
- **040 Token Economy as Governance Driver** — F-042 ships L1-L2 measurement; 040 adds L3-L7 (catalog at premium tier, billing modes, budget gates, governance decision UI). Phase 4 future work
- **048 Dashboard Velocity Metric Refinement** — when 048 ships, COST section gets Peak/Recent/Trailing trend treatment same as Velocity
- **055 Always-In-Flow Discipline** — when 055's slice-type catalog ships, cost data per slice type becomes a natural cross-cut
- **067 Small-Fix Slice Type** — F-042's ship cycle follows 067's contract
- **F-039 Launch-Mode Boundary Enforcement (shipped)** — F-042 writes cost.yml INSIDE the canonical boundary-sync flow; F-039 authorization gates apply automatically

## Success Criteria (Outcome-Focused)

- **Every iteration after F-042 ships writes a cost.yml** with at least one record and aggregates block
- **Per-host attribution works**: cost.yml records reflect the host that was active at each boundary advance
- **`specrew where` COST section renders** with cost-per-SP and by-host distribution
- **`specrew cost summary/add/recompute` CLI surface works** and emits parseable JSON when requested
- **Cost-per-SP estimator within 30% of manually-computed baseline** ($5.47/SP per 2026-05-16 memory) on the first iteration after F-042 ships
- **2026-05-30 Copilot pricing pivot survivable**: `specrew cost recompute --all` re-estimates all historical iterations from the post-pivot catalog without breaking the schema or losing manual records

## Risks

- **Tokenizer dependency adds package surface** — per-model tokenizers (tiktoken, claude-tokenizer) add Python/Node packages to Specrew's footprint. Mitigation: tokenizer is optional; naive byte/4 fallback ships in v1 if tokenizer install fails. User can opt into tokenizer via `cost_profile` extension.
- **Catalog absence breaks cost computation silently** — if `.specrew/model-catalog.yml` is missing or stale, estimates become null. Mitigation: FR-006 marks `cost_estimate_confidence: low`; dashboard surfaces the warning prominently. Doesn't block lifecycle.
- **Multi-host alternation makes feature-level cost math non-trivial** — sum-of-iteration is straightforward but per-host attribution at feature level requires careful aggregation. Mitigation: rollup logic is per-iteration, then feature-level sum; tests cover the alternation case.
- **`specrew cost` CLI command surface conflicts with future Proposal 040** — 040 will add richer cost commands. Mitigation: F-042 reserves only `cost summary/add/recompute`; future commands extend.
- **Cost.yml file proliferation** — every iteration writes one. After 100 iterations that's 100 small YAML files. Mitigation: dashboard reads only most-recent-N by default; files are <5KB each.
- **F-041 dependency** — F-042 estimates require F-041's catalog. Mitigation: F-042 ships with a fixture catalog (minimal cost data for the 3 supported hosts) that works on greenfield projects before `/specrew-research-models` has been run. The fixture catalog is replaced by the live one when discovery runs.
