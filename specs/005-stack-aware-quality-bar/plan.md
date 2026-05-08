# Implementation Plan: Stack-Aware Quality Bar (Phase 2 / Deferred Quality Gates)

**Branch**: `008-quality-profile-foundation` | **Date**: 2026-05-08 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/005-stack-aware-quality-bar/spec.md`

## Summary

This plan defines the next implementation slice after Phase 1 / Iteration 002 closed green. Phase 2 is limited to the deferred quality-governance requirements that build directly on the now-stable Phase 1 baseline: the pre-implementation hardening gate, materially relevant bug-hunter review lenses, strongest-class routing, and the project-wide known-traps corpus. This plan is intentionally planning-only: it defines boundaries, architecture, evidence contracts, verification, and dependency-aware slices for the next task-generation pass, but it does **not** claim that Phase 2 execution has started. The feature-level design remains one coherent Phase 2 planning package, but the generated implementation work is **not** a single 20-point iteration: it is intentionally decomposed into Iteration 003 (MVP hardening-gate slice), Iteration 004 (specialist lens execution plus known-traps follow-through), and Iteration 005 (routing enforcement and polish), each bounded by the repo-standard 20 story-point capacity.

## Phase Boundary

### In Scope

- FR-031 through FR-033 — pre-implementation hardening gate
- FR-016 through FR-019a — dedicated bug-hunter review lenses and mechanical-first ordering
- FR-034 through FR-037 — project-wide known-traps corpus and trap reapplication
- FR-038 through FR-040 — strongest-available routing policy, override recording, and routing evidence

### Explicitly Deferred

- FR-041 through FR-043 — quality-drift detection and ledger maintenance
- FR-044 through FR-046 — optional reference-implementation companion mode
- FR-013 through FR-015 — broader override/flexibility workflows beyond the Phase 2 routing-override requirement in FR-039
- Mixed-stack expansion, reference-baseline comparison, and any other out-of-scope work not listed above

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts; downstream Specrew config remains rooted in `.specrew/*.yml`  
**Primary Dependencies**: `extensions/specrew-speckit` scripts/templates, `.specify` planning workflow, existing Phase 1 quality-profile/evidence contracts, iteration governance scripts, and deterministic integration coverage in `tests/integration/`  
**Storage**: Git-tracked Markdown/YAML/JSON under `.specrew/`, `extensions/specrew-speckit/templates/quality/`, and `specs/<feature>/iterations/<NNN>/quality/`; Phase 2 adds a versioned known-traps corpus plus hardening/lens evidence artifacts  
**Testing**: PowerShell integration scripts, governance validation through `extensions/specrew-speckit/scripts/validate-governance.ps1`, and existing process-quality reporting regressions extended for Phase 2 artifacts  
**Target Platform**: Copilot-hosted Specrew repositories on PowerShell-capable environments with downstream `.specrew/`, `.squad/`, `.copilot/`, and `specs/` artifact trees  
**Project Type**: Spec Kit extension plus Squad-native governance/runtime template monorepo  
**Performance Goals**: Keep Phase 2 review flows deterministic, inspectable, and CI-friendly: mechanical checks remain first, hardening/lens artifacts remain reviewable without hidden state, and routing decisions remain reproducible from explicit config and recorded evidence  
**Constraints**: Preserve the green Phase 1 governance baseline, stay additive to the current Specrew lifecycle, use supported extension surfaces only, require human approval where FR-033 and FR-039 demand it, and avoid implying any Phase 3/4 capability as implemented  
**Scale/Scope**: One bounded Phase 2 planning slice covering planner/reviewer artifact contracts, routing/config metadata, new lens checklist sources, known-traps storage, and governance/test extensions for a single repo-wide feature, intentionally decomposed into three dependency-ordered implementation iterations (003-005) under the 20 story-point capacity ceiling

## Phase 2 Quality Planning

**Baseline inherited from Phase 1**: `quality-profile.custom-composition.v1` with Phase 1 governance green in `iterations/002`  
**Phase Scope**: `phase-2-hardening-bug-hunter-known-traps`  
**Planning Status**: `ready-for-task-generation`  
**Execution Status**: `not-started`

### Baseline Quality Profile Carry-Forward

| Item | Current Baseline | Phase 2 Implication |
| --- | --- | --- |
| Inferred profile | `quality-profile.custom-composition.v1` | Continue with bounded custom composition; Phase 2 adds specialist review behavior without pretending a recognized preset now exists |
| Phase 1 evidence status | Green (`iterations/002` accepted, governance passed) | Phase 2 may depend on Phase 1 `quality-evidence.md` and `mechanical-findings.json` as prerequisites |
| Mechanical checks | `dead-field`, `anti-pattern`, `test-integrity` | Must execute first and surface findings before any required model-based lens execution (FR-019a) |
| Quality asset catalog | Versioned presets/lenses under `templates/quality/` | Phase 2 extends the lens catalog with specialist bug-hunter checklists and corpus support |

### Hardening Gate Focus Areas

| Concern Area | Status | Planned Evidence Surface | Notes |
| --- | --- | --- | --- |
| Security surface analysis | required | `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md` | Must be explicit before implementation starts |
| Error-handling expectations | required | `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md` | Must capture expected failure behavior, not just happy paths |
| Retry and idempotency requirements | required review, may conclude not-applicable | `hardening-gate.md` plus rationale row | Required as a review topic even when the answer is “not materially applicable” |
| Test-integrity targets | required | `hardening-gate.md` and linked lens evidence | Must tie to observable negative-path expectations |
| Operational / resilience concerns | required | `hardening-gate.md` | “TBD” is blocking unless a human-approved deferral is recorded |

### Planned Bug-Hunter Lens Activation Matrix

| Lens / Defect Class | Planned Status | Why | Planned Evidence Surface |
| --- | --- | --- | --- |
| `security-issues` | required | The feature changes governance, review, and artifact flows that can silently weaken security expectations if omitted | `specs/<feature>/iterations/<NNN>/quality/lenses/security-issues.md` |
| `error-handling-failure-semantics` | required | Phase 2 introduces blocking/review-gate behavior, so failure handling and incomplete-state behavior are material | `.../quality/lenses/error-handling-failure-semantics.md` |
| `configuration-secret-handling` | required | Routing/config metadata and agent-selection policy must avoid unsafe or ambiguous configuration behavior | `.../quality/lenses/configuration-secret-handling.md` |
| `state-transition-correctness` | required | The slice governs plan → hardening gate → implementation readiness transitions and must keep blocking semantics correct | `.../quality/lenses/state-transition-correctness.md` |
| `dependency-package-health` | optional | Material for extension/runtime dependencies, but secondary to the hardening/lifecycle changes in this slice | `.../quality/lenses/dependency-package-health.md` if activated |
| `algorithmic-complexity-performance-path-traps` | optional | Useful for repo tooling drift, but not a primary Phase 2 blocking concern for this slice | `.../quality/lenses/algorithmic-complexity-performance-path-traps.md` if activated |
| `idempotency-retry-safety` | not-applicable by default | The current slice is artifact/governance orchestration, not an external side-effect workflow; hardening gate still records the explicit rationale | Hardening gate rationale only unless implementation scope changes |
| `concurrency-race-risk` | not-applicable by default | No current Phase 2 scope introduces material shared-state or realtime concurrency behavior | Hardening gate rationale only unless implementation scope changes |

### Routing Policy Baseline

| Policy Element | Planned Decision |
| --- | --- |
| Default route for required hardening/lens review | `strongest-available` |
| Configuration source | Extend `.specrew/iteration-config.yml` agent metadata with explicit strength ranking and allow `.specrew/config.yml` quality-routing defaults |
| Override rule | Only per-lens lower-tier overrides required by FR-039 are in scope; each override must include justification, approval, and the affected lens |
| Recorded evidence | Each lens execution records requested class, effective class, override reference (if any), and reviewer-visible outcome |
| Human approval points | FR-033 hardening deferrals and FR-039 lower-tier overrides require human approval |

### Explicit Phase 3/4 Deferrals

- Do **not** add quality-drift ledgers, baseline-diff automation, or remediation-tracking workflows in this plan.
- Do **not** add reference-implementation storage or comparison workflows in this plan.
- Do **not** broaden this slice into general tool/gate override workflows outside the routing-override obligation in FR-039.

## Constitution Check (Pre-Design)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Scope is limited to the user-requested deferred Phase 2 requirements only, and every excluded requirement family is called out explicitly.
- **Layering Gate**: PASS — Planned changes stay in the Specrew extension layer, downstream governance config/artifacts, reviewer/planner templates, and deterministic test lanes. No unsupported Copilot/VS Code coupling is introduced.
- **Traceability Gate**: PASS — Each planned workstream below maps to explicit FRs, concrete artifact surfaces, and a future task-generation boundary.
- **Ownership Gate**: PASS — Workstreams remain attributable to baseline Specrew roles: Spec Steward (artifact contracts/checklists), Planner (phase planning and routing metadata), Implementer (scripts/orchestration), Reviewer (evidence and validation), with human developer approval reserved where the spec requires it.
- **Capacity Gate**: PASS — The next slice is planned as one bounded Phase 2 planning pass feeding three dependency-ordered implementation iterations (`003`-`005`), each bounded to the repo-standard 20 story-point capacity instead of forcing the full 32-task package into one slice.
- **Drift/Reconciliation Gate**: PASS — The plan starts from the now-green Phase 1 baseline and requires additive artifact evolution instead of silent replacement. Phase 3 drift automation remains deferred and is not implied.
- **Verification Gate**: PASS — The slice is designed around deterministic tests, artifact contracts, and fail-closed governance, with explicit human approval checkpoints for the non-delegable decisions.

## Project Structure

### Documentation (this feature)

```text
specs/005-stack-aware-quality-bar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── mechanical-findings.schema.json
│   └── quality-governance-artifacts.md
└── iterations/
    └── <NNN>/quality/
        ├── hardening-gate.md           # planned Phase 2 artifact
        ├── quality-evidence.md
        ├── mechanical-findings.json
        ├── lenses/
        │   └── *.md                    # planned Phase 2 artifact
        └── trap-reapplication.md       # planned Phase 2 artifact
```

### Source Code (repository root)

```text
extensions/specrew-speckit/
├── commands/
│   ├── speckit.specrew-speckit.before-plan.md
│   └── speckit.specrew-speckit.before-implement.md
├── scripts/
│   ├── resolve-quality-profile.ps1
│   ├── run-mechanical-checks.ps1
│   ├── validate-governance.ps1
│   ├── scaffold-governance.ps1
│   ├── scaffold-iteration-artifacts.ps1
│   ├── scaffold-reviewer-artifacts.ps1
│   ├── run-hardening-gate.ps1         # planned
│   ├── run-bug-hunter-lenses.ps1      # planned
│   └── apply-known-traps.ps1          # planned
├── templates/
│   └── quality/
│       ├── lenses/
│       ├── presets/
│       └── README.md
└── squad-templates/
    └── coordinator/

tests/
└── integration/
```

**Structure Decision**: Extend the existing Phase 1 quality-governance surfaces rather than creating a parallel subsystem. Phase 2 reuses the existing `quality/` artifact directory, adds hardening/lens/trap artifacts there, and keeps repo-wide quality knowledge in downstream `.specrew/quality/`.

## Architecture Overview

| Component | Primary Paths | Responsibilities | Requirements |
| --- | --- | --- | --- |
| Hardening Gate Orchestrator | planned `run-hardening-gate.ps1`, planner/reviewer templates, `before-implement` guidance | Render the pre-implementation hardening checklist, enforce explicit sign-off/rationale, and block readiness on unresolved critical concerns | FR-031, FR-032, FR-033 |
| Lens Catalog and Activation Resolver | `templates/quality/lenses/*.md`, `resolve-quality-profile.ps1`, plan template | Define versioned specialist checklists and decide which lenses are required/optional/not-applicable from feature scope, stack signals, architecture, and risk | FR-016, FR-017, FR-018 |
| Lens Execution and Evidence Publisher | planned `run-bug-hunter-lenses.ps1`, iteration `quality/lenses/*.md`, `quality-evidence.md` | Execute required lenses after mechanical checks, record row-level status/finding/exception evidence, and expose reviewable outcomes | FR-019, FR-019a, FR-040 |
| Routing Policy Resolver | `.specrew/iteration-config.yml`, `.specrew/config.yml`, lens execution artifacts | Resolve strongest-available default routing, allow approved lower-tier overrides, and record requested/effective class per lens run | FR-038, FR-039, FR-040 |
| Known-Traps Corpus Manager | `.specrew/quality/known-traps.md`, planned `apply-known-traps.ps1`, review artifacts | Seed, version, grow, and reapply the corpus of confirmed defect patterns across iterations | FR-034, FR-035, FR-036, FR-037 |
| Governance Validator | `validate-governance.ps1`, iteration plan/review artifacts, new integration fixtures | Fail closed when hardening approval, required lens evidence, routing evidence, or corpus obligations are missing | FR-019, FR-033, FR-039, FR-040 |

## Phase 0: Research Decisions

Research outputs are captured in [research.md](research.md). The decisions that drive this plan are:

1. Keep hardening sign-off in lifecycle-visible feature/iteration artifacts instead of burying it inside transient chat or reviewer prose.
2. Record bug-hunter lens execution as per-lens Markdown evidence under `iterations/<NNN>/quality/lenses/` so row-level checklist execution stays human-reviewable.
3. Keep the known-traps corpus in downstream `.specrew/quality/known-traps.md`, seeded from existing dogfooding and iteration evidence rather than starting empty.
4. Resolve strongest-available routing from explicit config metadata and store both requested and effective review class in each lens execution record.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) extends the Phase 1 model with hardening reviews, lens activation plans, lens execution records, routing overrides, known-trap entries, and trap reapplication scans.
- [contracts/quality-governance-artifacts.md](contracts/quality-governance-artifacts.md) now defines the Phase 2 artifact layout and the reviewable contract for hardening, lens, routing, and known-trap evidence.
- `mechanical-findings.schema.json` remains the Phase 1 schema; Phase 2 consumes it as a prerequisite input rather than redefining it.

### Planned Artifact Layout

```text
.specrew/
├── config.yml
└── quality/
    └── known-traps.md                  # planned

specs/<feature>/iterations/<NNN>/quality/
├── hardening-gate.md                  # planned
├── quality-evidence.md
├── mechanical-findings.json
├── lenses/
│   ├── security-issues.md             # planned
│   ├── error-handling-failure-semantics.md
│   ├── configuration-secret-handling.md
│   └── state-transition-correctness.md
└── trap-reapplication.md              # planned
```

- `known-traps.md` is the cross-iteration memory surface.
- `hardening-gate.md` is the explicit implementation-readiness gate.
- Per-lens Markdown files capture checklist rows, findings, requested/effective routing, and approved exceptions.
- `trap-reapplication.md` records whether newly confirmed traps were offered back into the codebase scan flow and what was found.

## Delivery Slices (Dependency-Aware)

### Slice E — Hardening gate and planning-surface upgrade

**Goal**: Make implementation readiness explicit and blocking before any Phase 2 execution starts.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| E1 | Extend the feature plan/template and coordinator/before-implement guidance with Phase 2 hardening-gate scope, sign-off rows, and blocking semantics | Planner + Spec Steward | Phase 1 green baseline | Plan rendering and contract assertions | FR-031, FR-032, FR-033 |
| E2 | Scaffold `hardening-gate.md` into iteration quality artifacts and wire it into reviewer/implementation readiness flows | Implementer | E1 | Iteration artifact scaffold test | FR-031, FR-032 |
| E3 | Define fail-closed validation for unresolved `TBD` concerns and human-approved deferral records | Reviewer | E2 | Governance fixture proves blocked vs approved-deferral behavior | FR-033 |

### Slice F — Lens catalog expansion and activation resolver

**Goal**: Make specialist review capability explicit, versioned, and materially scoped.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| F1 | Author the minimum Phase 2 specialist lens checklist set required by FR-017 in `templates/quality/lenses/` | Spec Steward | Phase 1 lens asset baseline | Lens contract tests and file-shape assertions | FR-016, FR-017 |
| F2 | Extend profile resolution/planning logic to classify lenses as `required`, `optional`, or `not-applicable` from clarified scope and risk | Planner | F1 | Fixture-based activation tests | FR-018 |
| F3 | Keep Phase 2 lens activation bounded to the approved scope and do not imply Phase 3 drift or Phase 4 reference workflows | Spec Steward | F2 | Rendered-plan inspection and governance assertions | Boundary rule |

### Slice G — Lens execution, routing evidence, and mechanical-first ordering

**Goal**: Execute required specialist review only after deterministic checks and make the routing/evidence reviewable.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| G1 | Implement lens-execution orchestration that requires Phase 1 mechanical findings before opening any required bug-hunter lens | Implementer | E2, F2 | Integration test proves mechanical-first ordering | FR-019a |
| G2 | Publish per-lens execution artifacts with row-level checklist status, focused findings, justified exceptions, and requested/effective reasoning class | Reviewer + Implementer | G1 | Lens evidence contract tests | FR-019, FR-040 |
| G3 | Add explicit strongest-available routing resolution plus approved lower-tier override handling from config | Planner + Implementer | F2 | Routing-policy integration tests | FR-038, FR-039, FR-040 |

### Slice H — Known-traps corpus and trap reapplication

**Goal**: Turn confirmed review findings into persistent project memory and reusable scans.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| H1 | Create/scaffold `.specrew/quality/known-traps.md` and seed it from existing Specrew dogfooding findings, prior iteration defects, and cross-implementation learnings | Spec Steward | Phase 1 accepted baseline | Seed-content contract test and reviewer inspection | FR-034, FR-035 |
| H2 | Define the reviewed “add new trap” workflow from confirmed lens/review findings into the corpus | Reviewer | H1, G2 | Workflow/governance test for approved additions | FR-036 |
| H3 | Add trap reapplication support that can scan for similar instances and record results in `trap-reapplication.md` | Implementer | H2 | Reapplication fixture test | FR-037 |

## Dependencies and Execution Order

1. **E before G** — Hardening artifacts and blocking semantics must exist before implementation-readiness enforcement or lens execution can be validated.
2. **F before G** — Lens execution cannot run until the specialist checklist catalog and activation resolver are stable.
3. **G before H2/H3** — Known traps should be promoted from real confirmed review findings, not from hypothetical planning-only examples.
4. **Phase 1 evidence remains a prerequisite throughout** — Any Phase 2 execution flow must consume the existing mechanical findings/evidence surfaces rather than replacing them.

## Planned Implementation Iterations

| Iteration | Scope | Delivery slices / task package | Estimated effort | Status |
| --- | --- | --- | --- | --- |
| 003 | MVP hardening-gate slice | `T001`-`T014`; Setup + Foundational work plus User Story 2 (`E1`-`E3`) and the minimum planning-surface prerequisites needed to keep later lens/routing deferrals explicit | 20 story_points | Ready for execution approval once iteration artifacts are accepted |
| 004 | Specialist lens execution + known-traps follow-through | `T015`-`T024`; complete the Phase 2 specialist lens catalog/execution package plus known-traps corpus seeding, approval workflow, and trap reapplication (`F`, `G1`-`G2`, `H1`-`H3`) | 18 story_points | Deferred until Iteration 003 is accepted |
| 005 | Routing enforcement + polish | `T025`-`T032`; strongest-available routing enforcement, lower-tier override evidence, reporting alignment, documentation updates, and shipped-extension sync (`G3` + Polish) | 16 story_points | Deferred until Iteration 004 is accepted |

This sequencing preserves the Phase 2 dependency graph: Iteration 003 establishes the blocking hardening/artifact contract, Iteration 004 consumes that contract to deliver required bug-hunter execution and known-traps evidence, and Iteration 005 layers routing enforcement plus cross-cutting cleanup after the underlying execution surfaces are stable.

## Verification Strategy

### Deterministic Checks

- Add dedicated integration coverage for:
  - hardening-gate artifact generation and blocking semantics
  - specialist lens activation classification (`required` / `optional` / `not-applicable`)
  - mechanical-first ordering before lens execution
  - strongest-available routing and approved lower-tier override recording
  - known-traps corpus seeding, approved additions, and trap reapplication
- Keep `quality-profile-foundation.ps1`, `mechanical-findings-contract.ps1`, `quality-evidence-governance.ps1`, `process-quality-scorer.ps1`, and `process-quality-report.ps1` green so Phase 2 does not regress the accepted baseline.
- Extend `validate-governance.ps1 -ProjectPath .` so implementation readiness fails when:
  - `hardening-gate.md` is missing or contains unresolved critical `TBD` rows
  - a required lens has no row-level evidence or approved exception
  - mechanical findings were skipped before required lens execution
  - a lower-tier routing override lacks approval or justification

### Human Review Focus

- Review the initial specialist lens set for checklist quality before use in task generation.
- Review the seed known-traps corpus for signal quality and deduplication.
- Confirm the routing-policy contract keeps “strongest available” explicit and inspectable instead of relying on hidden agent preference.
- Confirm the plan and quickstart never claim that Phase 2 execution is already underway.

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion.*

- **Spec Authority Gate**: PASS — The design remains limited to FR-016 through FR-019a and FR-031 through FR-040 only.
- **Layering Gate**: PASS — The solution stays within extension scripts/templates, downstream governance config, and lifecycle artifacts.
- **Traceability Gate**: PASS — Every slice maps to concrete FRs, artifact paths, and future test lanes.
- **Ownership Gate**: PASS — Human approvals remain preserved where required, with agent roles limited to recommendation, orchestration, and evidence publishing.
- **Capacity Gate**: PASS — The slice sequencing now names the concrete multi-iteration execution plan: Iteration 003 (20 points), Iteration 004 (18 points), and Iteration 005 (16 points), each staying within the configured 20-point baseline.
- **Drift/Reconciliation Gate**: PASS — Phase 2 grows from the accepted Phase 1 baseline and leaves Phase 3 drift automation explicitly deferred rather than implied.
- **Verification Gate**: PASS — Planned verification combines deterministic tests, lifecycle-visible evidence, and fail-closed governance suitable for implementation gating.

## Task Generation Readiness

Phase 2 task generation should preserve the slice order above and keep these rules:

1. Do not start hardening-gate enforcement without first defining the artifact contract and human-approval fields.
2. Do not start lens execution tasks before the specialist checklist set and activation matrix are finalized.
3. Keep routing-policy work separate from lens-checklist authoring so approval and evidence semantics remain explicit.
4. Treat known-traps seeding and trap reapplication as bounded Phase 2 follow-through, not as a back door into Phase 3 drift automation.
5. Keep every task planning-only until an iteration plan and explicit human execution approval exist; this feature plan itself is **not** an execution artifact.
6. Preserve the concrete execution split from this repair: Iteration 003 carries `T001`-`T014` as the MVP slice, Iteration 004 carries `T015`-`T024`, and Iteration 005 carries `T025`-`T032` unless a later tracked decision changes the package.

## Complexity Tracking

No constitution violations require justification for this Phase 2 planning slice.
