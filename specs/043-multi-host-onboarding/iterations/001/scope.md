# Iteration 001 Scope

**Feature**: F-043 Multi-Host Onboarding + Selection Flow
**Iteration**: 001 — partial-shipped slice

## FR allocation

| FR | Description (abbreviated) | This iteration | Vehicle |
|---|---|---|---|
| FR-001 | `.specrew/host-history.{yml,json}` schema | ✅ Shipped (as `.json`) | `scripts/internal/host-history.ps1` |
| FR-002 | Host-selection priority chain (`--host` → history → first-run probe → non-TTY exit) | ✅ Shipped | `scripts/specrew-start.ps1` lines 3668-3745 |
| FR-003 | First-run probe enumerates available hosts | ✅ Shipped | `Invoke-SpecrewFirstRunHostProbe` in `host-runtime-inventory.ps1` |
| FR-004 | `host-history` updated on every selection | ✅ Shipped | `Update-SpecrewHostHistory` in `host-history.ps1` |
| FR-005 | `specrew host list` with available-on-PATH + selected status | ✅ Shipped | `scripts/specrew-host.ps1` |
| FR-006 | `specrew host use <kind>` validates + persists | ✅ Shipped | `scripts/specrew-host.ps1` |
| FR-007 | `specrew host status` reports per-host Crew-runtime install state | ✅ Shipped | `scripts/specrew-host.ps1` + `Get-SpecrewHostRuntimeInventory` |
| FR-008 | `specrew init` writes Category A files to `.specrew/coordinator/` | ⏳ Deferred | Tracked as follow-up small-fix slice |
| FR-009 | `specrew update` migrates brownfield `.squad/coordinator/` → `.specrew/coordinator/` | ⏳ Deferred | Same follow-up slice |
| FR-010 | Category B files stay at host-native paths (no migration) | ✅ Honored (no-op for this iteration; design constraint) | n/a |
| FR-011 | Validators read from `.specrew/coordinator/` with breadcrumb fallback | ⏳ Deferred | Same follow-up slice |
| FR-012 | `start-context.json` gains `host_resolution` field | ✅ Shipped | `Save-StartArtifacts` in `specrew-start.ps1` |
| FR-013 | Non-TTY runs without `--host`/history exit non-zero with guidance | ✅ Shipped | `non-interactive-no-default` branch in `specrew-start.ps1` host-gate |

## Commits attributing to F-043

| Commit | Title | FRs touched |
|---|---|---|
| `487c653f` | spec(F-043): specify + plan boundary artifacts | (specify + plan) |
| `d9868035` | draft(F-043): pre-stage host-history persistence + runtime-inventory helpers | (FR-001, FR-003 scaffolding) |
| `39b4e48d` | feat(F-043 MVP): specrew host command + host-history persistence (registry-driven) | FR-001, FR-003, FR-004, FR-005, FR-006, FR-007 |
| `755c87f1` | fix(F-043): wire host-selection chain into specrew-start (closes Gap 1 from F-040 review) | FR-002, FR-012, FR-013 |

## Out-of-scope (deferred)

**FR-008 / FR-009 / FR-011 — Category A coordinator-content migration.**

The spec called for moving Specrew-owned templates (coordinator-governance.md, charters, ceremonies, directives, skill templates per Proposal 024 audit) from `.squad/coordinator/` to `.specrew/coordinator/`, with a breadcrumb-file deprecation pattern for brownfield projects. Implementation was deferred because:

1. F-044 (Per-Host Architecture Refactor) was running in parallel and consumed sprint capacity.
2. Category A migration is a brownfield-impacting change requiring a tested migration path; sequencing it behind F-044's stable per-host substrate reduces risk.
3. The user-facing surface of F-043 (the host-selection chain + `specrew host` command) is independently valuable without Category A migration — Category A is plumbing, not user-facing UX.

Follow-up vehicle: a small-fix slice off F-043 once F-044 closes, or absorbed into a future Proposal 024 Slice work.

## Cross-feature entanglement

F-043's runtime implementation requires F-044's registry (`hosts/_registry.ps1`, Phase A) and per-host handlers (Phase B). The commits are interleaved on the `multi-host-integration-refactor` branch:

```
F-044 commits: c61daf5b (Phase A) → b656da6c (Phase B) → 0bf59876 + d3581bab + 4170c305 (Phase C) →
F-043 commit:  39b4e48d (F-043 MVP — uses registry)
F-044 commit:  af88192f (architecture docs)
F-043 commit:  755c87f1 (F-043 wiring — uses registry for first-run probe)
F-044 commits: e281aa17 (Phase D) → cdd8901e (truthful metrics) → 6b3b010c..70b1da06 (Slice 1-9)
```

This is genuine architectural co-evolution — F-043 builds on F-044's substrate. The PR bundling these two features explicitly acknowledges this in its description.
