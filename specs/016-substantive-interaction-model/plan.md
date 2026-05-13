# Implementation Plan: Substantive Interaction Model

**Branch**: `016-substantive-interaction-model` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/016-substantive-interaction-model/spec.md`

## Summary

Feature 016 hardens Specrew's console-first interaction model across three coupled pillars:
per-boundary human authorization, substantive boundary handoffs, and clickable `file:///`
artifact references. The implementation stays inside existing Specrew governance surfaces:
coordinator prompt guidance, `.github/agents/squad.agent.md`, `.squad/decisions.md`
recording rules, `validate-governance.ps1`, the handoff validator/checklist ecosystem,
known-trap corpus rows, README lifecycle guidance, and replayable PowerShell test fixtures.

The delivery plan preserves the clarified scope boundaries exactly:

- **Iteration 1 (~13 SP)**: coordinator prompt updates; hard-validator rules
  `validation-fail.bundled-boundary-advance` and parameterized
  bare-path-in-boundary-handoff in its initial **soft-warning rollout shape**; soft-validator
  rules for substantive handoffs; canonical authorization-recording shape; paired authorization
  recording; validator scope limited to Squad-authored artifacts and handoffs only.
- **Iteration 2 (~9 SP)**: violating/compliant integration fixtures, three new active corpus rows
  plus the passive `thin-artifact-content` future-candidate row and historical cross-references,
  README lifecycle update, per-feature handoff template update, and promotion of
  `bare-path-in-boundary-handoff` from Iteration 1 soft warning to Iteration 2 hard fail by
  configuration flip rather than rewrite.

Feature 017 remains explicitly out of scope; no visual-artifact work is planned here.

## Technical Context

**Language/Version**: PowerShell 7 for validator/test automation, Markdown for prompt/contracts/docs, Git commit metadata for boundary-signature inspection  
**Primary Dependencies**: `extensions/specrew-speckit/scripts/validate-governance.ps1`; `extensions/specrew-speckit/scripts/shared-governance.ps1`; `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`; coordinator prompt surfaces under `extensions/specrew-speckit/prompts/` and `.github/agents/`  
**Storage**: Filesystem + Git history + `.squad/decisions.md` authorization ledger + `.specrew/quality/known-traps.md` corpus  
**Testing**: PowerShell integration replay scripts under `tests/integration/`; Pester-style unit tests under `tests/unit/`; synthetic violating/compliant fixtures under `tests/unit/fixtures/`  
**Target Platform**: Windows-first Copilot/Squad workflow with `pwsh` portability for validator and test scripts  
**Project Type**: Governance/prompt/validator feature for a console-first orchestration product  
**Performance Goals**: New hard-validator rules complete in <200 ms; each soft-warning rule completes in <50 ms; no noticeable regression to normal `validate-governance.ps1` runs  
**Constraints**: Preserve Iteration 1 soft-warning → Iteration 2 hard-fail promotion for bare-path handling; Pillar 2 stays soft-warning-only throughout Feature 016; inspect Squad-authored artifacts/handoffs only; maintain regex/mechanical validation; keep Feature 017 out of scope  
**Scale/Scope**: 24 FRs across 3 user stories, 2 iterations, ~22 total story points, touching existing Specrew prompt, validator, corpus, documentation, and replay-fixture surfaces only

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — Interaction-model governance surfaces for Feature 016 planning  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for prompt + validator + documentation + fixture governance  
**Bounded custom composition**: No stock preset cleanly fits a feature that spans coordinator prompts, Markdown contracts, PowerShell validators, corpus rows, and replay fixtures. Phase 1 quality planning therefore combines: (1) Markdown/contract review, (2) PowerShell validator correctness review, (3) replay-fixture integrity, and (4) manual handoff readability review.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `coordinator-guidance` | `.github/agents/squad.agent.md`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | `custom` | FR-001–FR-005, FR-010, FR-014, FR-015 define coordinator stop-and-ask behaviour and handoff content |
| `governance-validator` | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | `custom` PowerShell tooling | FR-006–FR-013, FR-016–FR-019 depend on additive validator rules |
| `authorization-ledger` | `.squad/decisions.md`, contracts in this feature, prior handoff contracts | `custom` Markdown schema | FR-008 and FR-009 require canonical paired authorization recording |
| `corpus-and-docs` | `.specrew/quality/known-traps.md`, `README.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | `custom` docs/corpus | FR-020–FR-024 extend durable guidance and historical traceability |
| `proof-fixtures` | `tests/integration/*.ps1`, `tests/unit/*.ps1`, `tests/unit/fixtures/**` | `custom` replay/fixture suite | FR-021 and SC-002/SC-005/SC-007/SC-008 rely on violating + compliant fixture proof |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `security` | not-applicable | No new auth/data/network surfaces are introduced; feature governs process and console output |
| `false-positive-governance` | required | Bare-path and substantive-content rules can create workflow noise if exemption and threshold rules drift |
| `backward-compatibility` | required | Pre-Feature-016 history must remain grandfathered and valid |
| `performance` | required | Validator changes must remain fast and mechanical |
| `documentation-accuracy` | required | README/template/corpus updates must preserve clarified scope and rollout semantics |
| `test-integrity` | required | Replay fixtures must exercise real validator paths, not only helper functions |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `interaction-model-governance-v1` | Custom bundle for prompt + PowerShell validator + fixture governance |
| Mechanical Checks | Regex/subject-line classifier review, warning/FAIL shape review, grandfathering review | Evidence in contracts + replay fixtures |
| Ecosystem Tools | `pwsh` integration scripts, Pester-style unit tests, existing validator runtime | Existing repository-native proof surfaces |
| Human Review | Manual handoff readability + lifecycle stop review | Confirms console substance and approval-path fidelity |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `validator-replay-clean` | tooling | `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/...` for Feature 016 fixtures | planned |
| `unit-warning-contract-clean` | tooling | Pester/unit coverage for new warning and FAIL surfaces | planned |
| `manual-handoff-readability-check` | manual-evidence | Fresh-context review of planning/review/retro style handoffs | planned |
| `grandfathering-check` | mechanical | Replay of legacy/pre-016 history remains non-breaking | planned |
| `mirror-sync-check` | mechanical | `extensions/` and `.specify/extensions/` governance script copies remain aligned where required | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | No concurrent runtime behaviour or shared mutable runtime state is introduced | None |
| `database-integrity` | No database schema or storage engine work is planned | None |
| `load/perf-benchmarking` | Feature adds regex/string scans only; budget enforced by NFR-001 rather than load tooling | Revisit only if validator latency regresses in implementation |

### Explicit Phase 2+ Deferrals

- Runtime implementation and execution proof remain out of scope for this plan; this workflow stops after Phase 2 planning.
- Feature 017 visual-artifact work remains deferred and explicitly out of scope.
- Promotion of `bare-path-in-boundary-handoff` to hard fail is planned for Iteration 2 only after exemption-list fixtures demonstrate bounded false positives.
- Pillar 2 soft-warning rules do **not** graduate within Feature 016.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `feature-016-planning-slice` — planning-time hardening for console governance, validator false-positive control, and regression-proof replay design  
**Hardening Gate Artifact**: `specs/016-substantive-interaction-model/quality/hardening-gate.md` (future implementation-phase artifact; not created by this workflow)  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/016-substantive-interaction-model/quality/trap-reapplication.md` (future implementation-phase artifact; not created by this workflow)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Boundary-gap detection | Hard-fail rule must detect missing intervening authorization without misclassifying grandfathered history | `contracts/interaction-model-validator-contract.md`, replay fixtures | required |
| Bare-path exemption control | False positives are the main graduation risk for Pillar 3 | `research.md`, `data-model.md`, violating/compliant fixtures | required |
| Authorization-shape fidelity | Paired authorizations must remain two distinct entries even when sourced from one paste | `contracts/boundary-authorization-and-handoff.md`, `data-model.md` | required |
| Test-integrity targets | Fixture proof must exercise validator runtime and handoff surfaces, not only helper internals | `quickstart.md`, future test fixtures | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `governance-validator-regression` | required | Core risk is incorrect warning/FAIL semantics and grandfathering drift | `contracts/interaction-model-validator-contract.md` |
| `handoff-readability` | required | Pillar 2 depends on human-readable substantive console stops | `contracts/boundary-authorization-and-handoff.md` |
| `security-baseline-v1` | not-applicable | No new trust boundary or secret-handling path | N/A |
| `performance-baseline-lightweight` | optional | Needed only if implementation changes make validator noticeably slower | Future hardening artifact if required |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Validator and governance hardening | strongest available review class | record at execution time | none yet | Hard-fail semantics and grandfathering demand the strongest governance review available |
| Handoff readability/manual review | strong reviewer or human reviewer | record at execution time | none yet | Fresh-context console review is the acceptance target for Pillar 2 |

### Explicit Later Deferrals

- Final hardening-gate sign-off, runtime evidence capture, and routed lens execution remain for later authorized implementation/review slices.
- Trap reapplication write-up and final replay evidence remain deferred until implementation produces the new rules and fixtures.
- Any extension of substantive-content rules to artifact bodies remains future work; Feature 016 governs console handoffs only.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ PASS. The plan scope maps directly to the approved Feature 016 spec and preserves the clarified answers on single-boundary authorization, paired authorization recording, validator scope, Pillar 2 soft-warning-only behaviour, and Iteration 1/2 bare-path severity progression. Feature 017 remains explicitly excluded.

- **Layering Gate**: ✅ PASS. Changes are correctly classified:
  - Spec Kit planning layer: `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, and `contracts/`
  - Specrew governance layer: coordinator prompt surfaces, validator scripts, corpus rows, README lifecycle guidance, and handoff template updates
  - Squad runtime evidence layer: `.squad/decisions.md` authorization-entry shape (governed contract only in this phase; no implementation edits yet)

- **Traceability Gate**: ✅ PASS. Planned deliverables map cleanly:
  - Boundary authorization + handoff contract → US-1/US-2, FR-001–FR-015
  - Validator contract → US-1/US-3, FR-006–FR-021
  - Research decisions → FR-008, FR-009, FR-016, FR-018, FR-021, NFR-001–NFR-005
  - Quickstart workflow → TG-001–TG-006 and SC-001–SC-010

- **Ownership Gate**: ✅ PASS. Roles remain explicit per spec:
  - Spec Steward: Alon Fliess
  - Governance steward: coordinator prompt and handoff contracts
  - Validator steward: `validate-governance.ps1` and warning/FAIL semantics
  - Quality steward: corpus rows, historical cross-references, replay fixtures
  - Documentation steward: README lifecycle and handoff template updates

- **Capacity Gate**: ✅ PASS. Effort unit is story points and the bounded split matches the approved spec:
  - Iteration 1: ~13 SP
  - Iteration 2: ~9 SP
  - Total: ~22 SP

- **Drift/Reconciliation Gate**: ✅ PASS. Drift signals are explicit: any plan or later implementation that weakens single-boundary authorization, collapses paired authorizations into one entry, expands validator scope into user-authored text, changes bare-path graduation semantics, or pulls Feature 017 visuals into scope must be reconciled against the approved spec before proceeding.

- **Verification Gate**: ✅ PASS. Planned verification includes violating/compliant replay fixtures, unit warning-schema checks, grandfathering checks, manual fresh-context handoff review, and validator runtime confirmation. Soft-warning-only behaviour for Pillar 2 remains preserved throughout Feature 016.

**Post-Phase-1-Design Re-check**: ✅ PASS. `research.md`, `data-model.md`, `contracts/`, and `quickstart.md` preserve the approved clarifications, introduce no constitutional conflicts, keep ownership and traceability explicit, and remain bounded to planning/design artifacts only.

## Project Structure

### Documentation (this feature)

```text
specs/016-substantive-interaction-model/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── boundary-authorization-and-handoff.md
│   └── interaction-model-validator-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Coordinator guidance and runtime contract surfaces
.github/
└── agents/
    └── squad.agent.md

extensions/
└── specrew-speckit/
    ├── prompts/
    │   └── coordinator-response.md
    ├── squad-templates/coordinator/
    │   └── specrew-governance.md
    ├── validators/
    │   └── handoff-governance-validator.ps1
    └── scripts/
        ├── shared-governance.ps1
        └── validate-governance.ps1

.specify/
└── extensions/
    └── specrew-speckit/
        ├── squad-templates/coordinator/
        └── scripts/

# Durable governance memory and examples
.squad/
└── decisions.md

.specrew/
└── quality/
    └── known-traps.md

specs/001-specrew-product/contracts/
└── coordinator-handoff-template.md

# Test proof surfaces
tests/
├── integration/
│   └── *.ps1
├── unit/
│   ├── *.ps1
│   └── fixtures/**
└── manual/
```

**Structure Decision**: Single-repository governance feature. No new runtime application modules are introduced. Feature 016 works by extending existing PowerShell validator scripts, Markdown prompt/template surfaces, the decisions ledger contract, the known-traps corpus, README/template documentation, and replay fixtures already present in the repository.

## Complexity Tracking

> No constitution violations requiring justification. All planned work is additive within the existing Specrew governance architecture.
