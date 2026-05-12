# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 8/20 story_points
**Started**: 2026-05-09
**Completed**: 2026-05-09

## Summary

Iteration `004` is the bounded hardening-gate evidence-boundary repair slice for feature `005-stack-aware-quality-bar`. Iteration `003` remains complete and authoritative, while this follow-on slice now closes the hardening-boundary fix, the validator-gap follow-up, and the final whitespace cleanup with accepted review, completed retrospective, and recorded final sign-off.

**Primary Focus**: hardening-gate evidence standards, fail-closed governance semantics, deterministic fixture coverage, and review artifact continuity  
**Target Scope**: FR-031, FR-032, FR-033, FR-033a, TG-013, SC-009, SC-009a  
**Out of Scope**: bug-hunter lens execution, known-traps follow-through, routing expansion beyond the hardening default, quality-drift, reference-implementation work

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-031, FR-032 | Pre-implementation hardening gate must accept planning-time evidence and keep one lifecycle artifact | Delivered Slice A + Slice B | Spec Steward + Planner + Implementer | Hardening gate now keeps one lifecycle-visible artifact with explicit evidence-basis rows |
| FR-033, FR-033a | Missing planning-time analysis must still block; `deferred-with-approval` is narrow and runtime-only | Delivered Slice B + Slice C | Reviewer + Implementer | Shared governance and validation now fail closed on missing planning-time analysis and narrow deferrals |
| TG-013 | Sign-off must record evidence basis and remain auditable | Delivered Slice A + Slice C | Spec Steward + Reviewer | Audit fields, evidence basis, reviewed-by/at, and approval references are now persisted |
| SC-009, SC-009a | Planning gate accepts phase-appropriate evidence and later closure still requires runtime proof | Delivered Slice B + Slice C | Reviewer | Validation path now proves pre-implementation readiness and preserves later runtime follow-through |

---

## Iteration Acceptance Criteria

1. The repair preserves one `hardening-gate.md` artifact across lifecycle phases.
2. Pre-implementation readiness requires planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning rather than runtime-only proof.
3. `deferred-with-approval` is accepted only for runtime-only final proof after planning-time analysis is already present.
4. Runtime-only concerns remain visibly open or pending until later runtime evidence is recorded before closure.
5. Deterministic fixture and governance validation lanes prove the repaired behavior without reopening unrelated Phase 2 work.

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope is limited to the approved hardening evidence-boundary repair only. |
| **Traceability** | ✅ PASS | Every proposed slice maps to the relevant hardening-gate requirements and success criteria. |
| **Ownership** | ✅ PASS | Spec Steward, Planner, Implementer, and Reviewer roles remain explicit. |
| **Capacity** | ✅ PASS | Planned effort is 8/20 story_points; the slice is intentionally small and repair-focused. |
| **Execution Support** | ✅ PASS | Feature plan, research, data model, contract, quickstart, iteration plan, iteration state, and iteration-local hardening artifact now align to the same bounded scope. |

---

## Proposed Implementation Slices

| Slice | Goal | Affected Surfaces | Effort | Owner |
| ---- | ---- | ----------------- | ------ | ----- |
| Slice A | Repair the authoritative planning and contract chain | `specs/005-stack-aware-quality-bar/plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/quality-governance-artifacts.md`, `iterations/004/*` | 2 | Spec Steward + Planner |
| Slice B | Repair hardening-gate enforcement semantics | `.specify/templates/plan-template.md`, `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`, `run-hardening-gate.ps1`, `shared-governance.ps1`, `validate-governance.ps1`, lifecycle guidance docs | 3 | Implementer + Planner |
| Slice C | Repair deterministic fixtures and review evidence | `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, related fixtures, `iterations/004/quality/hardening-gate.md` | 3 | Reviewer |

**Total Effort**: 8 story_points

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| I004-T001 | Publish iteration-local artifact readiness surfaces for the repair slice | FR-031, FR-032, TG-013 | US-2 | 2 | Planner | done |
| I004-T002 | Repair hardening-gate generation and governance enforcement for the planning-time boundary | FR-031, FR-033, FR-033a, SC-009 | US-2 | 3 | Implementer | done |
| I004-T003 | Extend deterministic regression coverage and reviewer evidence for the repaired lifecycle contract | FR-032, TG-013, SC-009a | US-2 | 3 | Reviewer | done |

---

## Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\004 -OutputFormat Json
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

## Notes

- Iteration `003` remains complete and must not be reopened.
- Implementation approval was granted for this bounded slice, the required validation lane is green, the retrospective is complete, and Alon Fliess final closure approval is now recorded.
- The iteration-local hardening gate now closes this bounded governance repair with planning-time analysis plus deterministic validation/test evidence; any future runtime-bearing follow-through must be tracked in a later iteration rather than keeping Iteration `004` open.
- If broader Phase 2 work is resumed later, it must be re-planned explicitly after this repair rather than assumed from pre-repair iteration numbering.
