# Contract: Hardening Evidence Boundary Repair Artifacts

**Date**: 2026-05-09
**Spec**: [../spec.md](../spec.md)  
**Plan**: [../plan.md](../plan.md)

## Purpose

This contract defines the artifact surfaces for the bounded hardening-gate evidence-boundary repair. It is intentionally limited to the pre-implementation vs post-implementation evidence rules for one lifecycle-visible hardening artifact and the related repair iteration package.

## Artifact Layout

```text
specs/005-stack-aware-quality-bar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── quality-governance-artifacts.md
└── iterations/004/
    ├── plan.md
    └── state.md

specs/<feature>/iterations/<NNN>/quality/
└── hardening-gate.md
```

## Planning Artifact Contract

The repaired feature `plan.md` MUST expose:

- a bounded bugfix scope tied to FR-031 through FR-033a
- one hardening-gate artifact path
- planning-time evidence requirements before implementation
- runtime-evidence follow-through requirements before closure
- the narrow meaning of `deferred-with-approval`
- explicit affected governance/code/test surfaces
- explicit validation commands

## Iteration Repair Contract

`iterations/004/plan.md` MUST include:

- the reason Iteration `003` stays untouched
- bounded proposed implementation slices for the repair
- affected governance surfaces, fixtures, and review artifacts
- deterministic validation commands

`iterations/004/state.md` MUST include:

- status `planned`
- no execution-in-progress claims
- the baseline ref used for the repair plan

## Hardening Gate Contract

`hardening-gate.md` MUST include:

| Column / Field | Meaning |
| --- | --- |
| Concern | Reviewed hardening topic |
| Status | `addressed`, `not-applicable`, `tbd`, or `deferred-with-approval` |
| Evidence Basis | `planning-time-analysis`, `runtime-evidence`, or `not-applicable` |
| Runtime Evidence Status | `not-needed`, `pending-post-implementation`, or `recorded` |
| Expected Controls | Controls expected once implementation exists |
| Blocking | Whether unresolved state blocks implementation |
| Rationale | Why the conclusion is valid |
| Approval | Human approval reference when required |

Rules:

- Any blocking concern with missing planning-time analysis remains blocking.
- `deferred-with-approval` is valid only when the row already records planning-time analysis, expected controls, and rationale, but final runtime proof cannot exist yet.
- `deferred-with-approval` MUST NOT be used to bypass missing pre-implementation analysis.
- Runtime-only concerns carried forward from the pre-implementation gate MUST remain visibly open or deferred until later review records the actual runtime evidence needed for closure.
- Requested and effective review class MUST be recorded at the artifact level.

## Validation Lane Contract

The required validation path for this repair is:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-hardening-gate.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\004 -OutputFormat Json
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Non-Goals for This Contract

This contract does **not** reopen:

- specialist bug-hunter lens execution
- known-traps corpus seeding or trap reapplication
- routing expansion beyond the existing hardening-gate default
- quality-drift ledgers
- reference-implementation comparison
