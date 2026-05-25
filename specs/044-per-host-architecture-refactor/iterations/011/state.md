# Iteration State: 011

**Schema**: v1
**Last Completed Task**: T005 (artifacts + lint + commit + push)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: (pending — captured at commit time)
**Updated**: 2026-05-25T00:00:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 011 — Host Menu Priority Ordering (Smoke-Test Bug Fix) (LIVE-TRACKED)
**Started**: 2026-05-25
**Closed**: 2026-05-25

## Summary

User-flagged smoke-test bug: interactive `specrew start` host-selection menu shows `1. antigravity` as default — contradicts docs claiming `copilot` is the default. Root cause: `hosts/_registry.ps1:46-48` used `Sort-Object Name` (alphabetical = antigravity first). Fix: introduce `MenuPriority` field per manifest; sort registry by priority; keep `--host` non-interactive default as `copilot` for CI predictability (user-chosen Option 1).

Priority order (Claude → Codex → Copilot → Antigravity) maps directly to the cross-host smoke-test audit's empirical methodology-rigor ranking — the host that demonstrated strongest discipline first.

## What Shipped (post-implement)

- `hosts/{claude,codex,copilot,antigravity}/host.psd1` — added `MenuPriority` field with values 1, 2, 3, 4 respectively. Copilot manifest comment notes that `--host` flag non-interactive default remains `copilot` for CI predictability
- `hosts/_registry.ps1` — replaced `Sort-Object Name` (alphabetical) with `Sort-Object Priority, Kind` (priority-first, kind as stable tie-break). Hosts missing MenuPriority default to 999 (last in menu)
- `tests/integration/host-registry.tests.ps1` — Test 1 expected order updated to priority-sorted; new Test 1b asserts MenuPriority field exists on all 4 hosts with correct values
- `README.md` — clarified two-defaults model (preserved at flag default; interactive menu uses priority)
- `docs/getting-started.md` — added "Two defaults to keep in mind" section explaining the distinction; updated host table notes
- `docs/user-guide.md` — clarified Multi-Host Launch wording for priority ordering

## Verification

```text
=== iter-011 verification ===
PASS host-registry.tests.ps1: 15 assertions including new Test 1b (MenuPriority field validation)
PASS direct invocation: Get-RegisteredHostKinds returns [claude, codex, copilot, antigravity] in priority order
PASS markdownlint: 0 violations across 3 touched docs
```

## Empirical motivation

User exact phrasing (2026-05-25, smoke-test prep for higher-tier Antigravity test): "the document says that copilot is the default when we see the selection model menu... But the menu show the default as 1, Antigravity. I think that this should be the order if all installed: Claude, Codex, Copilot, Antigravity. And the default should be Claude if installed, then Codex and so on."

The priority order aligns with cross-host smoke-test methodology-rigor results: Claude (gold standard methodology), Codex (gold standard + --smoke-test innovation), Copilot (most-tested historically), Antigravity (weakest cooperative-gate discipline at Flash tier).

## Outstanding (none)

iter-011 is a complete, narrow scope. No follow-ups deferred.
