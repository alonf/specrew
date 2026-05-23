# Research: Token Economy MVP

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Date**: 2026-05-23
**Inputs**: Proposal 070 enrichment (commit `e3c47ddd` on main, 2026-05-23) with per-host reported-token surface inventory; F-040 ship artifacts; F-041 catalog schema v2; 2026-05-16 cost-baseline memory ($5.47/SP empirical baseline).

## Task 1: Per-host reported-token surface inventory

**Decision**: F-042 v1 ships estimated-only. The `source: reported` schema value is defined so reported-mode parsers can be wired in follow-up small-fix slices per host. Wiring sequencing: Claude first (richest surface), then Codex (clean JSON), then Copilot (post-hoc only — likely API integration). Antigravity deferred until host slice ships.

### Per-host evidence (from 2026-05-23 multi-host research wave)

| Host | Reported-token surface | Sequencing recommendation |
|---|---|---|
| **Claude Code** | `claude -p --output-format json` emits `usage.input_tokens` + `usage.output_tokens` per turn. Native, real-time, structured. | **First.** Highest-quality surface; ship reported-mode for Claude in the v0.28.x → v0.29.x window post-F-042. |
| **Codex CLI** | `codex exec --json` emits per-request token usage. | Second. Same shape as Claude, less integration overhead. |
| **Copilot CLI** | Not surfaced in `copilot -i` stdout. Available in github.com/settings/billing premium-request reports (post-hoc, daily granularity). | Third. Likely API integration via `gh api` or scraping the billing page. Materially harder than Claude/Codex. |
| **Antigravity (`agy`)** | `agy -p --output-format json` is the verified bootstrap surface per F-040 research; token-emission shape not yet documented but the `--output-format json` envelope suggests structured fields exist. | Fourth. Empirical verification needed before relying on reported-mode. |

### Why estimated-only ships first

- **Per-host parsers add scope** — each host's JSON shape differs. Wiring all four in F-042 would balloon scope from 5 SP to 15+ SP.
- **Estimated is good enough for the cost-reduction strategy** — naive byte/4 estimates are within 20% of actual tokens for most text. Per-model tokenizer estimates (when hints are available in F-041 catalog) get within 5%.
- **Manual entry covers reconciliation** — `specrew cost add` lets the user paste billing-page numbers when ground truth matters. The schema accommodates the source-of-truth distinction (`estimated` vs `reported` vs `manual`).

---

## Task 2: Tokenizer dispatch (naive vs per-model)

**Decision**: F-042 v1 ships naive byte/4 fallback as the default. Per-model tokenizers are opt-in via catalog hint (F-041 catalog v2 can populate a `tokenizer_method` field per model). When the hint is present and the tokenizer is available on PATH, F-042 uses it. Otherwise falls back to naive.

### Estimator quality comparison

| Method | Accuracy vs actual | When to use |
|---|---|---|
| **Naive byte/4** | ~50-80% accurate for English text; worse for code (over-counts), better for narrative (under-counts) | Default; always works; no deps |
| **tiktoken (OpenAI family)** | ~95% accurate | When catalog model is GPT-family AND tiktoken is installed |
| **claude-tokenizer (Anthropic family)** | ~95% accurate | When catalog model is Claude-family AND claude-tokenizer is installed |
| **Gemini tokenizer** | ~95% accurate | When catalog model is Gemini-family (Antigravity host) |

### Why opt-in rather than mandatory

- **Avoid Python/Node dependency creep** — Specrew is currently PowerShell-only. Pulling tokenizer packages adds runtime deps.
- **Most users don't need 95% accuracy** — the cost-reduction strategy works at 70%+ accuracy (you can tell if costs are dropping). Manual reconciliation closes the ground-truth gap for those who need it.
- **Future feature**: a `cost_profile: tokenizer-enabled` extension or a `--use-tokenizer` flag on `specrew cost recompute` opts into the higher-accuracy path.

### Estimator dispatch logic (PowerShell pseudocode)

```powershell
function Get-SpecrewTokenEstimate {
    param([string]$Content, [string]$ModelId, [hashtable]$Catalog)

    $modelEntry = $Catalog.models | Where-Object { $_.id -eq $ModelId } | Select-Object -First 1
    $tokenizerHint = $modelEntry.tokenizer_method  # e.g., 'tiktoken-cl100k', 'claude-tokenizer', etc.

    if (-not [string]::IsNullOrWhiteSpace($tokenizerHint)) {
        $tokenizerResult = Invoke-PerModelTokenizer -Method $tokenizerHint -Content $Content -ErrorAction SilentlyContinue
        if ($null -ne $tokenizerResult) {
            return [pscustomobject]@{
                Tokens = $tokenizerResult.Count
                Method = $tokenizerHint
                Confidence = 'high'
            }
        }
    }

    # Naive fallback
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($Content)
    return [pscustomobject]@{
        Tokens = [Math]::Ceiling($byteCount / 4.0)
        Method = 'naive_byte_4'
        Confidence = 'low'
    }
}
```

---

## Task 3: Dashboard COST block integration

**Decision**: New COST block in `scripts/internal/dashboard-renderer.ps1` inserted between VELOCITY and RECENT SHIPPED. Reads cost.yml files from recent N iteration directories (default last 10 closed) and aggregates at render time. No caching in v1.

### Block layout (illustrative)

```text
COST
Recent iterations:
  F-042 / 001 — $0.94 ($0.13/SP, 7 SP, claude-code 100%)
  F-041 / 001 — $1.18 ($0.07/SP, 18 SP, copilot 60% / claude-code 40%)
  F-040 / 001 — $1.31 ($0.19/SP, 7 SP, copilot 100%)
Last 10 closed: $11.42 total / $0.21/SP average
By host: copilot $7.14 (63%) / claude-code $4.28 (37%)
Trend: improving (cost-per-SP down 22% over last 5 iterations)
```

### Aggregation algorithm

```text
1. Enumerate all iterations matching the dashboard's "closed" criterion (state.md status: closed or feature-level closeout)
2. For each iteration: read cost.yml; extract aggregates block (total_cost_usd, cost_per_sp_usd, by_host)
3. Compute last-N (default 10): sum total_cost_usd, average cost_per_sp_usd, sum by_host across all
4. Compute trend: last-5 avg cost_per_sp_usd vs prior-5 avg cost_per_sp_usd; classify "improving" (>10% decrease), "regressing" (>10% increase), or "stable"
5. Render with cost values formatted as USD with appropriate precision ($0.07/SP not $0.071234/SP)
```

### Why no cache

- cost.yml files are <5KB each; reading 10 = <50KB total
- YAML parse is sub-millisecond per file
- Total dashboard COST render: <100ms even for 100 iterations (would still be cheap)
- Cache adds complexity (invalidation on new iteration close) without measurable benefit at current scale

If iteration count grows past ~500 and dashboard render becomes noticeable, a cache invalidated on iteration-closeout boundary is a small-fix follow-up.

---

## Task 4: Aggregation across multi-host alternating iterations

**Decision**: Per-iteration aggregation is straightforward (sum records → aggregates block). Feature-level aggregation across alternating-host iterations requires preserving per-host shares at the iteration level, then summing weighted at feature level.

### Example

Feature has 2 iterations:

- Iteration 001 on Copilot: total_cost_usd=$1.20, cost_per_sp_usd=$0.10, by_host={copilot=$1.20}, sp=12
- Iteration 002 on Claude: total_cost_usd=$0.40, cost_per_sp_usd=$0.04, by_host={claude-code=$0.40}, sp=10

Feature-level rollup:

- total_cost_usd: $1.60
- cost_per_sp_usd: $1.60 / 22 = $0.073 (weighted average)
- by_host: { copilot: $1.20 (75%), claude-code: $0.40 (25%) }

The rollup logic must preserve iteration-level shares — averaging shares directly would lose accuracy. Implementation: sum dollar amounts per host across iterations, then compute share = sum_per_host / sum_total.

### Why this matters

- The multi-host budget-multiplication strategy works by alternating hosts to use multiple budgets in turn. Feature-level by_host visibility is the primary signal that the strategy is being tuned.
- Users will read this aggregate to answer "are we drawing on Claude budget enough that Copilot quota lasts the month?"

---

## Cross-references

- file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md (source proposal, enriched 2026-05-23)
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md (F-041 — provides catalog with cost-per-token + tokenizer hints)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (F-040 — provides selected_host for per-host attribution)
- file:///C:/Dev/Specrew/proposals/040-token-economy-governance.md (architectural parent; F-042 ships L1-L2 measurement layer)
- file:///C:/Dev/Specrew/proposals/048-dashboard-velocity-metric-refinement.md (COST block gets Peak/Recent/Trailing treatment when 048 ships)
- file:///C:/Dev/Specrew/proposals/092-specrew-dashboard-web-app.md (per-developer cost-per-SP dashboards — future)
- file:///C:/Dev/Specrew/specs/041-cost-aware-model-routing/research.md (F-041 catalog v2 schema)
- Memory: `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]` — $5.47/SP empirical baseline computed manually
