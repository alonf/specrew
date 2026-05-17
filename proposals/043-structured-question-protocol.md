---
proposal: 043
title: Structured Question Protocol
status: candidate
phase: phase-3
estimated-sp: 10
discussion: tbd
---

# Structured Question Protocol

## Why

Specrew's clarify-time interaction surface is currently free-form text. Squad asks questions, user answers in prose. Two problems:

1. **No machine-parseable structure for choices**: when Squad presents a clear menu of options (e.g., "A: option X, B: option Y, C: option Z"), the user's response is also prose ("B", "B — but with caveat..."). Hard to validate completeness, hard to detect mismatches, hard to surface in a richer UI.

2. **Host-CLI-specific UX**: today's interaction is whatever Copilot CLI renders. When Specrew supports multiple host runtimes (per [024](024-multi-host-runtime-abstraction.md)), each host has different UX affordances. A host-neutral question protocol lets each provider render appropriately.

User signal 2026-05-16: "Yes, when we already have options, and recommendations, using a menu is easier for the human user."

## What

### Host-neutral `# specrew:choice` sentinel

A YAML sentinel block embedded in Squad output that hosts can parse and render with menu UX. Text fallback for hosts that don't support rendering.

```yaml
# specrew:choice
question: Which clarify-time option do you prefer?
options:
  - id: a
    label: Option A — keep current scope
    notes: |
      Simpler implementation, faster ship.
  - id: b
    label: Option B — expand scope with X capability
    notes: |
      ~5 extra SP, addresses Y concern.
  - id: c
    label: Option C — defer to next iteration
    notes: |
      Lowest risk, keeps Iter 1 tight.
recommended: a
```

### Per-host adapters

- **Copilot CLI**: render as numbered list with `[A] [B] [C]` keystroke shortcuts; user types letter to select
- **Claude Code**: render as native ask_user menu (Claude has structured choice support)
- **Codex CLI**: render as numbered prompt
- **Plain text fallback**: render as Markdown list; user types option ID or full label

### Three-pillar implementation

1. **Specrew sentinel format** — formalize the `# specrew:choice` YAML schema; document in proposals/043 + the coordinator template
2. **Host-adapter registry** — `extensions/specrew-speckit/host-adapters/` directory with one adapter per supported host runtime
3. **Squad coordinator-prompt update** — instruct Squad to emit the sentinel when presenting ≤3-option decisions

### Decision criteria for using sentinel vs prose

- ≤3 mutually exclusive options → sentinel
- ≥4 options OR options aren't mutually exclusive → prose (sentinel becomes unwieldy)
- Narrative questions (e.g., "describe X") → prose

### Out of scope

- Replacing all clarify-time questions with menus (some questions are inherently narrative)
- Building a graphical UI; this is terminal/text only

## Effort

- **Iteration 1** (~5-7 SP): sentinel format + Copilot CLI adapter + plain-text fallback + coordinator-prompt update
- **Iteration 2** (~3-5 SP): Claude Code adapter + Codex adapter

**Total**: ~8-12 SP

Could be ~8 SP small predecessor feature (only Copilot CLI adapter) OR fold into Multi-Host CORE ([024](024-multi-host-runtime-abstraction.md)) as a fifth pillar (~3-5 SP marginal cost when CORE is being built anyway).

## Phase placement

**Phase 3** alongside [024](024-multi-host-runtime-abstraction.md). If folded into CORE, ships with CORE; if separate, ships immediately after.

## Open questions

1. Fold into [024](024-multi-host-runtime-abstraction.md) as a pillar, or ship as small predecessor?
2. Sentinel format: YAML (proposed) vs JSON vs a custom DSL?
3. Should the sentinel support nested questions (e.g., "if A, then choose A.1/A.2")?
4. Per-host adapter discovery: convention-based file lookup or registered in `extensions/specrew-speckit/extension.yml`?
5. Should the sentinel block be visible in the rendered output (transparency) or hidden by the adapter?

## Risks

- Squad upstream may not consistently emit the sentinel even with coordinator-prompt instruction; need [004](004-validator-hardening.md) integration to catch missing sentinels on ≤3-option decisions
- Adapter brittleness: each host has different rendering quirks (Unicode support, color, line wrapping)

## Cross-references

- Composes tightly with [024](024-multi-host-runtime-abstraction.md) (could be a fifth pillar)
- Composes with [004](004-validator-hardening.md) (detect missing-sentinel inconsistency as a gap)
- Empirical source: F-019 Iter 1 clarify-time questions where menu UX would have been faster

## Status history

- 2026-05-16: captured as memory; user requested menu UX for ≤3-option decisions
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
