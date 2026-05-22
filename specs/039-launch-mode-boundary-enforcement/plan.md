# Implementation Plan: Launch-Mode Boundary Enforcement

**Branch**: `039-launch-mode-boundary-enforcement` | **Date**: 2026-05-22 | **Spec**: [specs/039-launch-mode-boundary-enforcement/spec.md](./spec.md)  
**Input**: Approved feature specification plus Proposal 065 reconciliation recorded in `iterations/001/drift-log.md`

## Summary

Implement Proposal 065's launch-mode boundary enforcement as a fail-closed authorization system that survives autopilot chaining. `specrew-start.ps1` handles schema migration, recovery posture, and emergency bypass activation; mirrored shared-governance helpers and boundary-advancing skills perform the actual authorization refusal, verdict persistence, and directive emission.

## Technical Context

**Language/Version**: PowerShell 7+ runtime scripts, Markdown governance artifacts, JSON/YAML state  
**Primary Dependencies**: `scripts\specrew-start.ps1`, `scripts\internal\sync-boundary-state.ps1`, mirrored `shared-governance.ps1`, Proposal 090 validator surfaces  
**Storage**: `.specrew\start-context.json` schema `v2`, `.squad\decisions.md`, `.squad\log\enforcement-errors.log`, `.specrew\config.yml` (future Proposal 038 policy lookup)  
**Testing**: Existing PowerShell integration/validator lane plus targeted boundary-enforcement tests to be added in implementation  
**Target Platform**: Windows PowerShell / PowerShell 7 with mirror-safe behavior across `.specify` and extension copies  
**Performance Goals**: Boundary authorization overhead stays comfortably below the existing session/bootstrap cost envelope  
**Constraints**: Fail-safe on corruption, mandatory audit trail, session-scoped bypass, nine-boundary canonical vocabulary, mirror parity  
**Scale/Scope**: One active Specrew session, nine lifecycle boundaries, future class-aware policy composition via Proposal 038

---

## Phase 0 Decisions

The Phase 0 research artifacts are complete and govern the design below.

| Topic | Decision | Source artifact |
| --- | --- | --- |
| Boundary detection | Structured `current -> requested` authorization is authoritative; prose is evidence-only for bypass attempts | `research.md` Task 1 |
| Intercept placement | `specrew-start.ps1` owns preflight; skills/shared-governance own the real stop | `research.md` Task 2 |
| Fail-safe behavior | Throw before advancement; malformed `boundary_enforcement` never degrades to permissive mode | `research.md` Task 3 |
| Audit log format | Reuse `.squad\decisions.md` append-only markdown entries with FR-004 fields | `research.md` Task 4 |
| Emergency bypass | Session-scoped `--bypass-boundary-enforcement --reason "..."` with per-boundary audit entries | `research.md` Task 5 |
| Proposal 038 | Add a policy adapter seam now; keep MVP behavior hard-stop for every gated boundary | `research.md` Task 6 |

## Phase 1 Design Artifacts

- [research.md](./research.md) — six research tasks answered with evidence, decisions, rationale, and failure-mode analysis
- [data-model.md](./data-model.md) — Proposal 065 Pillar 3 schema, verdict/bypass history, and migration path
- [contracts/enforcement-hook-interface.md](./contracts/enforcement-hook-interface.md) — authorization helper signatures, sentinels, fail-safe semantics, mirror parity rules
- [quickstart.md](./quickstart.md) — exact rehearsal commands for block, approved continuation, and emergency bypass

## Design Scope

### Files and components expected to change during implementation

| Surface | Planned change | Why it exists |
| --- | --- | --- |
| `scripts\specrew-start.ps1` | Add `--bypass-boundary-enforcement` + `--reason`, migration preflight, startup trust-posture messaging | Launcher owns session bootstrap and bypass activation |
| `scripts\internal\sync-boundary-state.ps1` | Extend canonical boundary list to nine entries and preserve `boundary_enforcement` during state sync | Current helper omits `before-implement`; F-039 needs schema-aware sync |
| `extensions\specrew-speckit\scripts\shared-governance.ps1` | Add authorization parser/persistence/directive helpers and event writers | Authoritative skill-side enforcement surface |
| `.specify\extensions\specrew-speckit\scripts\shared-governance.ps1` | Mirror of the same helper changes | Required distribution parity |
| Boundary-advancing command/skill surfaces | Call `Test-SpecrewBoundaryAuthorization` before advancing | Mechanical stop that prevents chained bypass |
| Validator/test surfaces | Extend schema validation and add boundary-enforcement coverage | Protects migration, parity, and audit completeness |

## Quality Planning

### Risk dimensions

| Risk | Why it matters | Planned control |
| --- | --- | --- |
| Governance correctness | One missed boundary bypass invalidates the methodology guarantee | Skill-level fail-closed authorization tests |
| State integrity | Corrupt `start-context.json` must not silently allow | Schema v2 validation + recovery directive path |
| Security / override abuse | Bypass is intentionally powerful | Mandatory `--reason`, session-scoped marking, audit trail |
| Mirror parity | Extension and `.specify` divergence would create host-dependent behavior | Identical helper signatures and parity checks |
| Boundary-name drift | Current helpers still use 8-boundary vocabulary and aliases | Canonical nine-boundary normalization and validator updates |

### Required verification evidence

- Verdict parser coverage for accepted, ambiguous, rejected, parked, and compound verdict forms
- Authorization refusal coverage for every canonical boundary
- Schema migration coverage for pre-065 sessions
- Bypass audit-trail coverage, including session activation and per-boundary usage rows
- Mirror-parity coverage between extension and `.specify` helper copies

---

## Constitution Check

*Gate: must pass before and after design. Re-evaluated below using the completed Phase 0 and Phase 1 artifacts.*

- **Spec Authority Gate**: ✅ Pass — the plan stays inside the approved F-039 spec and the Proposal 065 clarifications already reconciled in `iterations/001/drift-log.md`.
- **Layering Gate**: ✅ Pass — launcher responsibilities stay in `scripts\specrew-start.ps1`; shared reusable authorization logic stays in mirrored governance helpers; future policy remains project config, not feature-local code.
- **Traceability Gate**: ✅ Pass — `research.md`, `data-model.md`, `contracts/enforcement-hook-interface.md`, and `quickstart.md` collectively cover FR-001 through FR-010, AC3, AC6, AC9, and the Proposal 065 Pillar 3 migration requirement.
- **Ownership Gate**: ✅ Pass — Planner owns the plan bundle; Implementer will own helper/runtime changes; Reviewer/Spec Steward own fail-safe and audit verification; Security Specialist review remains focused on bypass misuse and fail-closed behavior.
- **Capacity Gate**: ✅ Pass — the design remains the same bounded single-iteration slice envisioned by Proposal 065 (~7 SP) and does not introduce extra downstream scope.
- **Drift/Reconciliation Gate**: ✅ Pass — the design explicitly reconciles the current 8-boundary helper catalog with the spec/proposal's 9-boundary contract and resolves the earlier counter-only placeholder by adopting Proposal 065's history-based schema.
- **Verification Gate**: ✅ Pass — post-design artifacts specify deterministic sentinels, migration expectations, mirror parity requirements, and exact rehearsal commands for the three critical paths.

### Constitution Check Re-Evaluation (Post-Design)

- **Spec Authority Gate**: ✅ Pass — `data-model.md` adopts Proposal 065 Pillar 3 without contradicting the approved spec; older count-oriented wording is satisfied through derived views rather than conflicting persistence fields.
- **Layering Gate**: ✅ Pass — contracts keep host-specific launch behavior in `specrew-start.ps1` and reusable authorization logic in mirrored shared-governance helpers.
- **Traceability Gate**: ✅ Pass —
  - FR-001/FR-002/FR-003/FR-005/FR-006/FR-007 → `research.md` Tasks 1-3 + `contracts/enforcement-hook-interface.md`
  - FR-004/FR-008/FR-009/FR-010 → `data-model.md` + `quickstart.md` + `research.md` Tasks 4-5
  - TG-006 / Proposal 038 extension point → `research.md` Task 6 + `data-model.md`
- **Ownership Gate**: ✅ Pass — no ownership gaps were introduced by the design; mirror parity and validator work remain implementer/reviewer concerns, not hidden planner work.
- **Capacity Gate**: ✅ Pass — post-design scope is still plan-boundary only; no implementation or task-generation artifacts were created.
- **Drift/Reconciliation Gate**: ✅ Pass — all previously deferred post-design placeholders are now resolved with explicit verdicts, and the design names the remaining future composition (Proposal 038, Proposal 098) as true deferrals rather than unresolved blockers.
- **Verification Gate**: ✅ Pass — `quickstart.md` provides exact commands and expected sentinels for block, approval, and bypass; the contract defines deterministic return shapes suitable for automated tests.

---

## Project Structure

```text
specs/039-launch-mode-boundary-enforcement/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── enforcement-hook-interface.md
└── iterations/
    └── 001/
        └── drift-log.md
```

## Implementation notes carried forward

1. The empirical F-039 `plan -> tasks` breach remains the canonical regression case.
2. `before-implement` must be added to the canonical boundary lists before implementation is considered complete.
3. History arrays (`verdict_history`, `bypass_history`) are the persisted truth; counts are derived views.
4. No plan-beyond-boundary work is authorized here: task generation and implementation remain explicitly unopened.

## Complexity Tracking

No constitution violations require justification.
