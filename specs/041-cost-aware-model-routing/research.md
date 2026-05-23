# Research: Cost-Aware Model Routing

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Date**: 2026-05-23
**Inputs**: Proposal 068 enrichment (commit `e3c47ddd` on main, 2026-05-23) with verified per-host `selector_strategy` enum + Claude `opusplan` primitive + 2026-06-18 Gemini deadline; F-040 ship artifacts (host enum, available_hosts probe, selected_host persistence); 2026-05-16 cost-baseline memory ($5.47/SP empirical baseline).

This file answers three research tasks that govern F-041's design.

---

## Task 1: Catalog v2 schema (per-host selector_strategy + built-in primitives)

**Decision**: Adopt Proposal 068's enrichment schema verbatim. Per-host blocks include the explicit `selector_strategy` enum so routing logic knows HOW to inject each host's choice. Schema versioned as `version: 2` per clarify Q2.

### Schema example

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
        - id: "<discovered-name>"
          tier: free | cheap | balanced | premium
          cost_per_million_input: <value>
          cost_per_million_output: <value>
          capability_tags: [code, reasoning-deep, fast, long-context, vision]
          best_for: [Implementer, Reviewer, Spec Steward, Planner, Retro Facilitator]

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
      available: <bool>
      selector_strategy: agent_toml_field   # writes model = "<name>" in .codex/agents/*.toml
      built_in_routing_primitives: []
      models: [...]

    antigravity:
      available: <bool>
      selector_strategy: cli_flag   # uses -m <model-name> per invocation
      built_in_routing_primitives: []
      pricing_change_alerts:
        - effective_date: 2026-06-18
          summary: "Gemini CLI free tier stops; requires Google AI Pro / Ultra ($100/mo) or enterprise key"
          source_url: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
      models: [...]
```

### Why selector_strategy is the load-bearing field

Routing logic dispatches on this enum to know WHICH file to write and WHAT format. Without it, F-041 would have to maintain per-host case statements in cost-routing.ps1 — fragile and host-coupled. The enum + `built_in_routing_primitives` together capture the host's native cost-routing surface, so Specrew can either USE a built-in primitive (e.g., Claude opusplan when lean profile matches its intent) or WRITE through the per-host config when no built-in fits.

### Sources

- Proposal 068 enrichment (commit `e3c47ddd`, 2026-05-23): full schema example with all 4 selector_strategy values
- 2026-05-23 multi-host research wave (Claude Code agent): `model:` frontmatter field in `.claude/agents/*.md`; opusplan built-in primitive
- 2026-05-23 multi-host research wave (Codex agent): per-agent `model = "..."` in `.codex/agents/*.toml`
- F-019 Specrew Distribution Module: existing `Set-SquadModelOverrides` writes `.squad/config.json` `agentModelOverrides` for Copilot

---

## Task 2: Per-host injection mechanics — the four selector_strategy dispatchers

**Decision**: F-041 ships four dispatch functions in new `scripts/internal/per-host-model-injection.ps1`. Each function honors the host's native config conventions; tests verify round-trip integrity.

### `selector_strategy: squad_config_field` (Copilot)

```powershell
function Set-CopilotModelOverride {
    param([string]$Role, [string]$ModelId, [string]$ProjectPath)
    # Delegate to F-019's existing Set-SquadModelOverrides (already battle-tested)
    Set-SquadModelOverrides -ProjectPath $ProjectPath -Overrides @{ $Role = $ModelId }
}
```

Writes to `.squad/config.json` `agentModelOverrides.<role>`. No new file format; reuses F-019 code path.

### `selector_strategy: subagent_frontmatter` (Claude)

```powershell
function Set-ClaudeSubagentModel {
    param([string]$Role, [string]$ModelId, [string]$ProjectPath)
    $subagentPath = Join-Path $ProjectPath ".claude\agents\$Role.md"
    if (-not (Test-Path -LiteralPath $subagentPath)) {
        return [pscustomobject]@{ Status = 'crew_runtime_install_required'; Reason = 'Claude subagent file not deployed; awaits Proposal 024 Slice 3' }
    }
    # Parse YAML frontmatter, set/update model: field, write back
    ...
}
```

Writes the `model:` field inside the YAML frontmatter block of `.claude/agents/<role>.md`. If the subagent file doesn't exist (F-040 left non-Copilot hosts at `crew_runtime_status: bootstrap_only`), the function returns the bootstrap-only fallback rather than creating files Proposal 024 Slice 3 will deploy.

### `selector_strategy: agent_toml_field` (Codex)

```powershell
function Set-CodexAgentModel {
    param([string]$Role, [string]$ModelId, [string]$ProjectPath)
    $tomlPath = Join-Path $ProjectPath ".codex\agents\$Role.toml"
    if (-not (Test-Path -LiteralPath $tomlPath)) {
        return [pscustomobject]@{ Status = 'crew_runtime_install_required'; Reason = 'Codex agent .toml not deployed; awaits Proposal 024 Slice 3' }
    }
    # Read .toml, set model = "<id>" in [agent] section, write back
    ...
}
```

Writes the `model = "..."` field in `.codex/agents/<role>.toml`. Same bootstrap-only fallback as Claude.

### `selector_strategy: cli_flag` (Antigravity — placeholder for future)

```powershell
function Set-AntigravityModelOverride {
    param([string]$Role, [string]$ModelId, [string]$ProjectPath)
    # F-041 catalog records this strategy, but no .agents/agents/*.toml convention
    # exists in Antigravity v1. Persistence model TBD when Antigravity small-fix
    # slice ships.
    return [pscustomobject]@{ Status = 'deferred'; Reason = 'Antigravity host deferred per F-040 clarify Q1' }
}
```

Codified but no-ops in F-041; activates when the Antigravity small-fix slice ships post-F-040.

### Round-trip integrity

Each dispatcher MUST round-trip cleanly:

1. Read existing file (preserves all non-model fields)
2. Modify only the `model:` / `model = "..."` field
3. Write back (preserves file structure: YAML frontmatter, TOML sections, comments)

Tests verify round-trip: read → write → re-read → assert structural equality except for the targeted field.

---

## Task 3: Catalog staleness + auto-refresh trigger

**Decision**: Two-threshold model — warning at 30 days, auto-refresh at 90 days. Manual `/specrew-research-models` invocation always refreshes regardless of catalog age.

### Threshold rationale

| Age | Behavior | Rationale |
|---|---|---|
| 0-30 days | No warning; use catalog as-is | Pricing/model changes are usually slow; weekly Specrew use shouldn't be hassled |
| 30-90 days | Warning logged on each routing decision: "Catalog is N days old. Refresh via `/specrew-research-models`." | Periodic nudge without forcing action; user can run discovery when convenient |
| 90+ days | Auto-refresh fires before next routing decision; routing blocks ~10-30s while skill runs | Three months is a long time in AI lineup churn; force re-discovery to keep cost-tier accuracy |

### Refresh failure handling

When auto-refresh fires but fails (network/auth/etc.):

1. Prominent warning logged: "Catalog refresh failed; using stale catalog from <timestamp>"
2. Routing proceeds with stale catalog (don't block work on discovery failure)
3. Failure recorded in `.specrew/model-catalog.yml` as a `last_refresh_attempt` block with `status: failed`, `error_summary`, `attempted_at`
4. Next routing decision retries the refresh; if it succeeds, the failure record is cleared

### Pricing-change-alert effective-date passed

When the catalog's `pricing_change_alerts[].effective_date < today`:

1. `specrew where` dashboard shows the alert prominently in the COST section (F-042 surface)
2. Routing layer still uses the current catalog (don't second-guess provider transitions)
3. User is nudged to manually refresh via `/specrew-research-models` to capture post-pivot pricing

For F-041 specifically, the **2026-05-30 Copilot pricing pivot** is the immediate test case: catalog refresh between F-041 ship and 2026-05-30 must surface the pivot as a `pricing_change_alerts` entry; routing logic doesn't need to know HOW the pricing changed, just that the catalog will be re-refreshed after the pivot.

### Cost of repeated refresh

Discovery uses web-search + doc-fetch tokens. Estimated cost per refresh: ~$0.10-0.50 depending on host count and depth (single-host refresh < multi-host). Mitigated by:

- 30/90-day threshold (avoid daily-refresh paranoia)
- Catalog is durable on disk (one refresh serves many routing decisions across many iterations)
- Manual invocation is explicit (user opt-in to spend the discovery tokens)

---

## Cross-references

- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md (source proposal, enriched 2026-05-23)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (F-040, shipped — provides host enum + selector_strategy)
- file:///C:/Dev/Specrew/proposals/040-token-economy-governance.md (architectural parent; F-041 ships L3-L4 layer)
- file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md (F-042 follow-up — measurement layer)
- file:///C:/Dev/Specrew/proposals/100-friction-dial.md (FR-012 integration; small-fix follow-up when 100 ships)
- file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md (routing-entry logging composition)
- file:///C:/Dev/Specrew/specs/040-multi-host-launch-path/research.md (per-host CLI surfaces evidence)
- Memory: `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]` — $5.47/SP empirical baseline; GPT-5.4 = 67% of cost; multi-host budget-multiplication strategy
