# F-044 Feature Closeout Dashboard

**Feature**: F-044 Per-Host Architecture Refactor
**Source proposal**: Proposal 108 (specrew-init refactor + per-host Crew-runtime abstraction)
**Shipped on branch**: `multi-host-integration-refactor` (bundled with F-043 per architectural co-evolution; merges to main as one PR)
**Closeout date**: 2026-05-24 (pending iter-004 manual-test verification round before final feature-closeout)

## Delivery summary

| Metric | Planned (Proposal 108) | Actual | Variance |
|---|---|---|---|
| Story points | 22-25 SP | ~32 SP (iter-001 ~22 + iter-002 ~6 + iter-003 ~4) | +7 SP via review-driven + manual-test-driven cleanup |
| Iterations | 1 (Proposal 108 implicit) | 3 (architectural payoff + deep-review fix + manual-test fix) | +2 (methodology shape — see retros) |
| FRs delivered | 13 | 13 | 0 |
| ACs verified | 12 | 12 PASS (5 PASS in iter-001; 7 closed in iter-002) | 0 |
| Implementation commits | ~10 | ~24 in iter-001 (Phase A-D + Slices 1-9) + 1 in iter-002 + 1 in iter-003 | n/a |

## FR scoreboard

| FR | Scope | Status | Iteration |
|---|---|---|---|
| FR-001 | Canonical team source-of-truth at `.specrew/team/agents/<role>.md` | ✅ Shipped | iter-001 (Slice 9) |
| FR-002 | `Status='supported'` hosts declare `AgentDir` | ✅ Shipped | iter-002 (Copilot AgentDir added + validator update) |
| FR-003 | 5 contract functions per host | ✅ Shipped | iter-001 (Slice 9) |
| FR-004 | Registry exposes `InstallCrewRuntime` slot | ✅ Shipped | iter-001 (Slice 9) |
| FR-005 | `Invoke-CrewBootstrap` dispatcher | ✅ Shipped | iter-001 (Slice 9) |
| FR-006 | Auto-seed canonical on first `specrew start` | ✅ Shipped | iter-002 (W-3 fix) |
| FR-007 | Specrew-managed marker (inline or sidecar) | ✅ Shipped | iter-002 (sidecar pattern for Copilot per advisor catch) |
| FR-008 | User-edit preservation | ✅ Shipped | iter-002 (W-4 fix) |
| FR-009 | `scripts/specrew-init.ps1` split | ✅ Shipped | iter-001 (Slices 1-8) |
| FR-010 | Marker-file walk for path resolution | ✅ Shipped | iter-002 (W-2 fix) |
| FR-011 | Adding a new host requires zero edits to existing files | ✅ Shipped | iter-001 (Phase A-C registry) |
| FR-012 | Documentation updated for 5-function contract + canonical team | ✅ Shipped | iter-002 (W-1 + W-9 + W-10 + W-11 fixes) |
| FR-013 | `tests/integration/crew-bootstrap-contract.tests.ps1` | ✅ Shipped | iter-002 (W-6 fix — promoted from `.scratch/`) |

## Pillars delivered

| Pillar | Source | Status |
|---|---|---|
| Pillar 1: Per-host registry + manifest discovery | Proposal 108 Phase A | ✅ Shipped |
| Pillar 2: Per-host handler dispatch (5 contract functions) | Proposal 108 Phase B + Slice 9 | ✅ Shipped |
| Pillar 3: Registry-driven shims replacing host-coupled scripts | Proposal 108 Phase C | ✅ Shipped |
| Pillar 4: Declarative coordinator-prompt surgery rules engine | Proposal 108 Phase C.3 | ✅ Shipped |
| Pillar 5: `scripts/specrew-init.ps1` split into focused init files | Proposal 108 Slices 1-8 | ✅ Shipped |
| Pillar 6: Canonical team source-of-truth + per-host translation | Proposal 108 Slice 9 (mid-flight redesign) | ✅ Shipped |
| Pillar 7: Per-host coordinator-overlay translation | Proposal 024 Category D | ⏳ Deferred |
| Pillar 8: `specrew team` CLI rewire to canonical | Follow-up small-fix slice | ⏳ Deferred |

## Cross-feature bundle disclosure

This feature shipped on the same PR as **F-043 Multi-Host Onboarding** because the work co-evolved on the same branch — F-043's runtime depends on F-044's registry. The reader can navigate to each feature's iteration artifacts independently for a clean per-feature narrative.

| Bundle component | Spec | Iteration artifacts |
|---|---|---|
| F-043 (sibling) | [`../043-multi-host-onboarding/spec.md`](../043-multi-host-onboarding/spec.md) | [`../043-multi-host-onboarding/iterations/001/`](../043-multi-host-onboarding/iterations/001/) |
| F-044 (this) | [`spec.md`](./spec.md) | [`iterations/001/`](./iterations/001/) + [`iterations/002/`](./iterations/002/) + [`iterations/003/`](./iterations/003/) |

## Architecture + design references

- **Source proposal**: file:///C:/Dev/Specrew/proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md (on main as commit `1698b08e`; arrives on this branch via merge)
- **Host-package architecture overview** (Mermaid `flowchart TB`): file:///C:/Dev/Specrew/docs/architecture/host-package-architecture.md
- **Original design proposal**: file:///C:/Dev/Specrew/docs/design/host-package-architecture.md
- **Slice 9 implementation review**: file:///C:/Dev/Specrew/docs/design/proposal-108-slice-9-review.md
- **How-to add a new host**: file:///C:/Dev/Specrew/docs/how-to/add-a-new-host.md
- **Contract**: file:///C:/Dev/Specrew/hosts/_contract.md (rewritten in iter-002)

## Follow-up work queued

| Item | Vehicle | When |
|---|---|---|
| `proposals/INDEX.md` update — Proposal 108 → shipped as F-044 | On-main chore commit | Post-merge to main |
| Antigravity empirical smoke test (`agy` binary) | Small-fix slice | Post-Gemini-deadline 2026-06-18 |
| Per-host coordinator-overlay translation (Claude / Codex / Antigravity) | Proposal 024 Category D | Phase 2 (after F-044 lands on main) |
| `specrew team` CLI rewire to canonical `.specrew/team/agents/<role>.md` | Small-fix slice | Post-F-044 close |
| Factor `Get-SpecrewDistRoot` marker-walk helper to prevent re-duplication | Small chore | Opportunistic |
| Proposal 063 / F-025 / F-029 Substantive Intake Questioning structural fix | Standing work | Phase 2b |

## Methodology disclosure

This feature was implemented BEFORE the spec was written. The user explicitly flagged the gap at closeout: "we work really hard and not so by Specrew methodology since I want available and I let you run. It is time to fix that." The spec, plan, and all iteration artifacts in this directory are retroactive backfill. The two-iteration close (iter-001 with 22 known issues + iter-002 fix slice) is the methodology pattern Specrew enforces; this feature happens to demonstrate the pattern via retroactive artifacts rather than live ones. Future readers can navigate the full lifecycle even though it wasn't applied in real-time. The structural fix to prevent recurrence is Proposal 063 (Substantive Intake Questioning).
