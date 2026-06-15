# Implementation Plan: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Date**: 2026-06-08
**Spec**: [spec.md](./spec.md)
**Design source**: [iterations/001/design-analysis.md](./iterations/001/design-analysis.md)
(approved for plan with **Option B — IDesign volatility-based**, verdict `fa33aff8`)

## Summary

Turn the F-171 SessionStart B2 hook into the primary session bootstrap path while
keeping `specrew start` as a compatibility/host-selection launcher; round-trip the
Proposal 130 handover; and clear stale/non-portable session anchors. Implemented as
an IDesign volatility-based decomposition (Option B): volatile host/event/picker
adapters over stable classification/validation/directive engines over resource
accessors, reusing the F-171 dispatcher unchanged.

## Composed sources (TG-005 — referenced, not re-authored)

- **Proposal 130 Pillar 4** — handover `.md` + index format and source discrimination.
- **Proposal 143** — orientation and recovery-menu content.
- **Proposal 077** — Resume / New / Pick-feature semantics.
- **Proposal 078** — handoff prose conventions.
- **F-171 / Proposal 146** — hook dispatcher, kill switch, breaker, journal, dedupe, B2 trigger.

This feature owns only the bootstrap directive contract, the classification/validation
rules, the SessionStart marker, and the stale-anchor clearing — it does not redefine the
above.

## Technical Context

- **Language/runtime**: PowerShell (Specrew module); functions follow `Verb-SpecrewNoun`.
- **Data contracts**: `PSCustomObject` (the bootstrap directive, classification record,
  validation findings) — no classes/interfaces; the contract is the function signature +
  returned object shape, documented in comment-based help.
- **Test harness**: Pester — one `<Component>.Tests.ps1` per component.
- **Deployment**: registered through the existing F-171 hook deploy loop; no new install
  path (devops d1). Every new `.ps1` MUST be added to the module FileList.
- **Out of scope**: B4 pre-compaction capture, Antigravity binding (FR-012); cross-machine
  prevention and adversarial/untrusted-artifact hardening (deferred proposals).

## Quality profile (from `before-plan` resolution)

Phase-1 bounded custom composition. **Required dimensions**: code-quality,
design-quality-and-separation-of-concerns, verification-confidence, maintainability.
**Not applicable (recorded)**: concurrency-correctness, resiliency,
retry-idempotency-and-recovery — this feature's "concurrency" is *advisory detection*
(no shared-state execution, no locks/retries; architecture-core d3). **Required gates**:
dead-field, anti-pattern, test-integrity, stack-tooling-evidence. Custom lenses:
security-baseline, robustness-baseline, test-integrity.

## Architecture (Option B — see design-analysis for the full Co-Design Record)

IDesign roles, one `.ps1` file per component under `scripts/internal/bootstrap/`:

- **Managers** (orchestrate, stable): `SessionBootstrapManager`, `SessionEndHandoverManager`.
- **Engines**: `ClassificationEngine` (pure), `DirectiveEngine` (pure), `ValidationEngine`
  (calls accessors — predictable/large reads).
- **ResourceAccessors**: `HandoverStore`, `SessionStateAccessor`, `ProjectMetadataAccessor`,
  `HookJournalAccessor`.
- **Adapters** (volatile): `HostEventAdapter`, `LauncherIntegration`.
- **Reused**: F-171 `HookDispatcher` (unchanged — B1/B3 regression safety).

**Binding constraints** (from the Co-Design Record): IDesign layering is convention,
enforced by review + tests (no access modifiers); **engine call-rule** — an engine may
call an accessor only when the data is predictable or too large to pass, else the Manager
passes it in; ClassificationEngine/DirectiveEngine stay pure.

## Requirement → component → test mapping

| FR / SC | Owning component(s) | Verification |
| --- | --- | --- |
| FR-001/002 B2 primary + directive | SessionBootstrapManager, DirectiveEngine | unit: directive fields; per-host empirical |
| FR-003 non-interactive hook | SessionBootstrapManager | unit: no input/branch on menu |
| FR-004/020 render-first mechanical | DirectiveEngine + disallowed-tools skill | unit: `render_first`; host empirical (SC-001) |
| FR-005 per-host menu | HostEventAdapter, agent | per-host empirical evidence |
| FR-006/007/008 launcher + dedupe + docs | LauncherIntegration | dedupe test (SC-002); doc check (SC-006) |
| FR-009/021 SessionEnd write-only | SessionEndHandoverManager, HandoverStore | round-trip fixture (SC-003) |
| FR-010/017 handover read + validate | ValidationEngine, HandoverStore | unit: valid/invalid/mismatch |
| FR-011 B1/B3 unchanged | (reuse) HookDispatcher | regression tests (SC-005) |
| FR-013/014/015 anchor clearing/portability | ValidationEngine, ProjectMetadataAccessor, SessionStateAccessor | unit: merged/closed/absolute-path (SC-004) |
| FR-018/019 marker + concurrency | SessionStateAccessor, ClassificationEngine | unit: marker fields; 1h freshness window |
| SC-007 journal distinguishability | HookJournalAccessor, ClassificationEngine | per-path journal-assertion tests (observability d2) |

## Testing strategy

1. **Pure unit tests** for ClassificationEngine + DirectiveEngine — every bootstrap mode
   (full / welcome-back / cleared-anchor) and the unclean-exit path, in-memory.
2. **Mocked-accessor / fixture tests** for ValidationEngine and the accessors (temp dirs,
   git fixtures).
3. **Journal-assertion tests** — each path asserts both the rendered mode and its
   distinguishable journal record (SC-007).
4. **SessionEnd round-trip** fixture using a Proposal 130-compatible handover (SC-003).
5. **Regression** — B1 post-compaction + B3 boundary-cross digest unchanged vs F-171 (SC-005).
6. **Idempotency** — launcher + hook → exactly one bootstrap (SC-002).
7. **Per-host empirical evidence** (Claude, Codex, Copilot, Cursor) — render-before-picker;
   manual smoke recorded with command + output + timestamp where a host can't be automated.

## Risks & mitigations

- **Render-first collapses on Claude** (the FR-004 hazard) → mechanical enforcement via a
  `disallowed-tools: AskUserQuestion` skill, not directive text alone (FR-020).
- **FileList omission breaks installs** (recurring) → explicit tasks-level FileList obligation
  for every new `.ps1`.
- **IDesign layering rot** (no compiler enforcement) → review + a layering note in tasks.
- **Per-host menu variance** → FR-005 empirical gate before locking the menu shape.

## Phasing

Single iteration (001). Build order: accessors + HostEventAdapter (seams) → pure engines
(Classification/Directive) → ValidationEngine → managers → LauncherIntegration + dedupe →
SessionEnd handover writer → per-host empirical verification. Capacity re-estimated at
tasks; workshop-added scope (marker, concurrency detection, mechanical render, write-only
exit) pushes this above the original 8–13 SP — confirmed against the iteration cap at tasks.
