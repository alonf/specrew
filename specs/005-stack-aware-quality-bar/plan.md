# Implementation Plan: Stack-Aware Quality Bar (Hardening Evidence Boundary Repair)

**Branch**: `008-quality-profile-foundation` | **Date**: 2026-05-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/005-stack-aware-quality-bar/spec.md`

## Summary

This plan repairs one bounded governance bug inside the active quality-bar feature: the pre-implementation hardening gate must keep using a single lifecycle artifact, but it must accept planning-time evidence before implementation and require runtime evidence only later before closure. The repair is limited to FR-031 through FR-033a and their traceability/governance fallout. It does **not** reopen broader bug-hunter lens execution, known-traps follow-through, routing expansion, quality-drift, or reference-implementation work.

Iteration `003` remains closed and authoritative. This repair is planned as a new bounded follow-on in Iteration `004`.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts
**Primary Dependencies**: `extensions/specrew-speckit` governance scripts/templates, `.specify` planning workflow, feature-local planning artifacts, and deterministic integration tests under `tests/integration/`
**Storage**: Git-tracked Markdown/YAML/JSON in `specs/005-stack-aware-quality-bar/`, `.specify/`, `.specrew/`, and `extensions/specrew-speckit/`
**Testing**: PowerShell integration coverage via `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, and `tests/integration/quality-evidence-governance.ps1`
**Target Platform**: PowerShell-capable Specrew repositories on Windows or equivalent supported environments
**Project Type**: Spec Kit extension + Specrew governance monorepo
**Performance Goals**: Deterministic, fail-closed planning/review behavior with no hidden state and no requirement for runtime-only proof before implementation exists
**Constraints**: Keep one hardening-gate artifact, require planning-time analysis before implementation, reserve `deferred-with-approval` for runtime-only final proof, preserve completed Iteration `003`, and avoid reopening unrelated Phase 2/3/4 scope
**Scale/Scope**: One bounded requirements-and-governance repair across feature planning artifacts plus a proposed Iteration `004` implementation slice for the affected governance logic, fixtures, and review artifacts

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-baseline-carry-forward`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`
**Selected preset ref or explicit custom composition**: Carry forward the existing PowerShell governance custom composition from the accepted Phase 1 baseline
**Bounded custom composition**: This repair keeps the accepted Phase 1 mechanical-check baseline and narrows new work to hardening-gate evidence semantics, governance validation, and the review artifact contract

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Planning artifacts | `specs/005-stack-aware-quality-bar/plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/**` | `custom` | This slice is primarily a planning/governance repair and must stay truthful in the authoritative feature artifact chain |
| Hardening governance implementation surface | `.specify/templates/plan-template.md`, `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`, `run-hardening-gate.ps1`, `shared-governance.ps1`, `validate-governance.ps1` | `powershell-governance` | These surfaces eventually enforce the repaired planning-time vs runtime-evidence boundary |
| Regression and review artifacts | `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/fixtures/**`, `specs/005-stack-aware-quality-bar/iterations/004/**` | `powershell-test-fixtures` | The bugfix must be provable with deterministic fixtures and reviewable iteration-local evidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Governance drift | `required` | The bug is a requirements/governance overreach; the plan must stop implementation readiness from depending on impossible early runtime proof |
| State-transition correctness | `required` | The repair changes when a concern is considered planning-ready versus fully closed |
| Test integrity | `required` | Fixture and regression coverage must prove the repaired boundary fails closed in the right places |
| Specialist lens expansion | `not-applicable` | This slice does not reopen broader bug-hunter execution behavior |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `quality-bundle.powershell-governance-hardening-repair.v1` | Bounded to planning artifacts, governance scripts, and deterministic integration fixtures |
| Mechanical Checks | `contract-diff`, `hardening-gate-fixtures`, `governance-regression` | Proof lives in the repaired contract docs, iteration plan, and the named PowerShell regression lanes |
| Ecosystem Tools | `pwsh` integration tests + governance scripts | No new toolchain is introduced for this repair slice |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `hardening-evidence-boundary-plan` | manual-evidence | `specs/005-stack-aware-quality-bar/plan.md` | `planned` |
| `hardening-evidence-boundary-contract` | manual-evidence | `specs/005-stack-aware-quality-bar/contracts/quality-governance-artifacts.md` + `data-model.md` | `planned` |
| `hardening-boundary-validation-lane` | tooling | `specs/005-stack-aware-quality-bar/quickstart.md` + `iterations/004/plan.md` | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| Specialist lens execution changes | This bugfix does not change row-level bug-hunter execution behavior or lens catalogs | Keep deferred until a later explicit planning slice |
| Known-traps corpus workflow | The bugfix does not change corpus seeding, additions, or trap reapplication logic | Leave unchanged and out of scope |

### Explicit Phase 2+ Deferrals

- Specialist bug-hunter lens execution remains deferred in this repair slice.
- Known-traps corpus seeding and trap reapplication remain deferred in this repair slice.
- Strongest-class routing expansion beyond the hardening-gate default remains deferred in this repair slice.
- Quality-drift and reference-implementation work remain explicitly deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `hardening-evidence-boundary-repair`
**Hardening Gate Artifact**: `specs/005-stack-aware-quality-bar/iterations/004/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md` *(unchanged; out of scope for this repair)*
**Trap Reapplication Artifact**: `unchanged; not part of this repair slice`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | The gate must accept trust-boundary analysis and expected controls before implementation instead of demanding runtime proof too early | `plan.md`, `contracts/quality-governance-artifacts.md`, future `iterations/004/quality/hardening-gate.md` | `required` |
| Error handling and failure semantics | Missing planning-time analysis must still block implementation, while runtime verification is carried to later closure | `plan.md`, `data-model.md`, future hardening-gate rows, `quality-evidence-governance` fixtures | `required` |
| Retry and idempotency expectations | The row must still be reviewed and may conclude `not-applicable`, but deferral cannot stand in for missing analysis | future hardening-gate rows and `hardening-gate-contract` fixtures | `required` |
| Test-integrity targets | The pre-implementation gate must require planned validation expectations now and actual runtime/test proof later | `quickstart.md`, `iterations/004/plan.md`, future hardening-gate rows | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `error-handling-failure-semantics` | `not-applicable` | This repair does not change specialist lens execution; deterministic hardening-gate and governance regressions are the intended proof surface | `none in this slice` |
| `state-transition-correctness` | `not-applicable` | The lifecycle-state bug is repaired through the hardening-gate contract plus deterministic fixture validation, not by reopening lens infrastructure | `none in this slice` |
| `security-issues` | `not-applicable` | The slice changes evidence standards, not runtime security review execution | `none in this slice` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Hardening gate review for this repair | `strongest-available` | Record when the repaired hardening gate actually runs | Lower-tier use still requires explicit human approval | The planning repair preserves the existing default while clarifying that evidence standards differ by lifecycle phase |

### Explicit Later Deferrals

- Required bug-hunter lens execution evidence remains deferred.
- Known-traps corpus and trap-reapplication evidence remain deferred.
- Requested-versus-effective routing evidence for specialist lens execution remains deferred.
- Quality-drift and reference-implementation behavior remain deferred.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Scope maps directly to the approved 2026-05-09 clarifications plus FR-031 through FR-033a, TG-013, SC-009, and SC-009a.
- **Layering Gate**: PASS — The repair stays in the Spec Kit/Specrew governance layer: planning artifacts, governance scripts, fixtures, and review artifacts.
- **Traceability Gate**: PASS — Each planned deliverable points to the hardening-gate contract, the future Iteration `004` artifact chain, and the required validation lanes.
- **Ownership Gate**: PASS — Spec Steward owns contract truth, Planner owns bounded plan/iteration slicing, Implementer owns later governance-script changes, Reviewer owns deterministic fixtures and validation.
- **Capacity Gate**: PASS — The repair is planned as one new bounded follow-on slice instead of reopening completed Iteration `003`.
- **Drift/Reconciliation Gate**: PASS — Completed history stays intact; the repair is additive and explicit.
- **Verification Gate**: PASS — The validation path is explicitly defined through hardening-gate and governance regression lanes.

## Project Structure

### Documentation (this feature)

```text
specs/005-stack-aware-quality-bar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── quality-governance-artifacts.md
└── iterations/
    ├── 003/                         # completed MVP slice; do not reopen
    └── 004/
        ├── plan.md                  # bounded repair iteration plan
        └── state.md                 # bounded repair iteration state
```

### Source Code (repository root)

```text
.specify/
└── templates/
    └── plan-template.md

extensions/specrew-speckit/
├── commands/
│   ├── speckit.specrew-speckit.before-plan.md
│   └── speckit.specrew-speckit.before-implement.md
├── scripts/
│   ├── resolve-quality-profile.ps1
│   ├── run-hardening-gate.ps1
│   ├── shared-governance.ps1
│   └── validate-governance.ps1
└── squad-templates/
    └── coordinator/
        └── specrew-governance.md

tests/
└── integration/
    ├── hardening-gate-contract.ps1
    ├── quality-evidence-governance.ps1
    └── fixtures/
        ├── hardening-gate-contract/
        └── quality-evidence-governance/
```

**Structure Decision**: Keep the repair anchored in feature planning artifacts while pointing at the exact governance scripts, fixtures, and reviewer surfaces that must change later. No new subsystem or artifact family is introduced.

## Phase 0: Research Decisions

Research outputs are captured in [research.md](research.md). The decisions that drive this plan are:

1. Keep one hardening-gate artifact across lifecycle phases instead of splitting planning and post-implementation proof into separate artifacts.
2. Record planning-time analysis explicitly and carry runtime-only proof forward as pending follow-through rather than treating it as a pre-implementation blocker.
3. Reserve `deferred-with-approval` for runtime-only final proof after planning analysis already exists.
4. Create a new Iteration `004` repair artifact instead of reopening completed Iteration `003`.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) narrows the data model to the hardening-gate review packet, concern rows, evidence basis, and runtime follow-through state.
- [contracts/quality-governance-artifacts.md](contracts/quality-governance-artifacts.md) defines the repaired hardening-gate contract and the validation lane for this bounded slice.
- [quickstart.md](quickstart.md) captures the required validation path for the repair without claiming implementation has happened.

### Proposed Implementation Slices

| Slice | Scope | Affected Surfaces | Outcome |
| --- | --- | --- | --- |
| Slice A | Planning and contract repair | `specs/005-stack-aware-quality-bar/plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/quality-governance-artifacts.md`, `iterations/004/*` | The authoritative artifact chain reflects the bounded bugfix truthfully |
| Slice B | Hardening-gate and governance enforcement repair *(future implementation)* | `.specify/templates/plan-template.md`, `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`, `run-hardening-gate.ps1`, `shared-governance.ps1`, `validate-governance.ps1`, lifecycle guidance docs | Planning-time evidence is required before implementation; runtime-only proof is required later before closure |
| Slice C | Deterministic proof and review artifact repair *(future implementation)* | `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, related fixtures, future `iterations/004/quality/hardening-gate.md` | The repair is enforced by fixtures, reviewable artifacts, and fail-closed validation |

### Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\004 -OutputFormat Json
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Post-Design Constitution Re-check

- **Spec Authority Gate**: PASS — The design stays bounded to the approved hardening-evidence clarification.
- **Layering Gate**: PASS — No runtime-layer or unrelated Phase 2/3/4 capability is implied.
- **Traceability Gate**: PASS — Proposed implementation slices map directly to FR-031 through FR-033a and TG-013.
- **Ownership Gate**: PASS — Role boundaries remain explicit for later task generation/execution.
- **Capacity Gate**: PASS — Iteration `004` is a clean bounded follow-on instead of a history rewrite.
- **Drift/Reconciliation Gate**: PASS — Iteration `003` remains closed; this repair is additive.
- **Verification Gate**: PASS — Required fixture, artifact, and governance validation commands are explicit.

## Complexity Tracking

No constitution exceptions are required for this repair slice.
