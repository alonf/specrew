# Implementation Plan: Stack-Aware Quality Bar (Phase 1 / First Slice)

**Branch**: `008-quality-profile-foundation` | **Date**: 2026-05-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/005-stack-aware-quality-bar/spec.md`

## Summary

This plan delivers only the Phase 1 foundation for stack-aware quality governance: inferred quality profiles in planning artifacts, versioned stack presets and lens checklists, deterministic mechanical-check contracts with structured JSON findings, and explicit quality evidence recording. The implementation stays inside Specrew's existing extension-driven architecture by extending `extensions/specrew-speckit` scripts/templates, downstream `.specrew/` governance assets, and deterministic integration coverage under `tests/integration/`.

## Phase Boundary

### In Scope

- FR-002 through FR-004 and FR-003a
- FR-022 through FR-026
- FR-027 through FR-030 and FR-030a
- FR-010 through FR-012

### Explicitly Deferred

- Phase 2 bug-hunter execution workflows beyond Phase 1 artifact foundations
- FR-031 through FR-033 hardening gate
- FR-034 through FR-037 known-traps corpus workflows
- FR-041 through FR-043 quality-drift detection
- FR-044 through FR-046 reference-implementation companion mode
- Mixed-stack fallback/override workflows outside the minimum Phase 1 profile foundation

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts; downstream Specrew config currently pins Spec Kit `0.8.4` and Squad `0.9.1` in `.specrew/config.yml`  
**Primary Dependencies**: `extensions/specrew-speckit` script/template surfaces, `.specify` plan workflow, Squad-native runtime deployment via `deploy-squad-runtime.ps1`, existing governance/evaluation scripts under `tests/integration/` and `evaluation/scorers/`  
**Storage**: Git-tracked Markdown/YAML assets under `.specrew/` plus feature and iteration artifacts under `specs/<feature>/`; machine-readable mechanical findings stored as JSON sidecars  
**Testing**: PowerShell integration scripts in `tests/integration/`, governance validation via `extensions/specrew-speckit/scripts/validate-governance.ps1`, process-quality scorer/report checks in `evaluation/scorers/` and `tests/integration/process-quality-*.ps1`  
**Target Platform**: Copilot-hosted Specrew repositories on PowerShell-capable environments, with deployed assets under `.specrew/`, `.squad/`, `.copilot/`, and `specs/`  
**Project Type**: Spec Kit extension plus Squad-native governance/runtime template monorepo  
**Performance Goals**: Keep the Phase 1 quality bar deterministic and CI-friendly: preset/lens assets remain Markdown-reviewable, governance validation remains local/offline, and mechanical findings emit structured JSON suitable for downstream tooling without requiring live model execution  
**Constraints**: Must remain additive to the current Specrew lifecycle, use supported extension surfaces only, preserve markdown-first governance conventions, avoid unresolved planning placeholders, and defer later-phase hardening/lens/drift/reference workflows explicitly rather than partially implementing them  
**Scale/Scope**: One repo-wide foundation slice touching extension scaffolding, planner/reviewer governance prompts, deterministic validation/tests, and a minimum preset/lens catalog with one fully worked `node-public-ws-service` example

## Constitution Check (Pre-Design)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Scope is explicitly limited to the Phase 1 guidance in `spec.md` and the user-provided in-scope FR list. Deferred FRs are named above rather than blended into the slice.
- **Layering Gate**: PASS — Changes stay in the Specrew Spec Kit extension layer (`extensions/specrew-speckit`), Squad governance prompts/templates, downstream `.specrew/` generated assets, and deterministic test/evaluation surfaces. No direct Copilot/VS Code hacks are introduced.
- **Traceability Gate**: PASS — The delivery slices below map every planned workstream to requirement IDs, downstream artifacts, verification steps, and later task-generation boundaries.
- **Ownership Gate**: PASS — Major workstreams are owned by existing Specrew baseline roles: Spec Steward (artifact contracts/versioning), Planner (profile/preset selection surfaces), Implementer (mechanical checks + scripts), Reviewer (evidence visibility + validation), with human developer approval required for demotion workflow decisions.
- **Capacity Gate**: PASS — Planning uses the repo-standard `story_points` effort model from `extensions/specrew-speckit/extension.yml` and `.specrew/iteration-config.yml`. This first slice is intentionally capped at a single 20-point iteration budget and organized into four serial work packages for later task generation.
- **Drift/Reconciliation Gate**: PASS — Phase 1 uses existing Specrew drift discipline (`drift-log.md`, review gap handling, change logs) for artifact reconciliation. Dedicated quality-drift ledgers remain deferred to Phase 3; any preset/lens/rule changes in this slice must record version bumps, change logs, and reviewed demotion rationale instead of silent edits.
- **Verification Gate**: PASS — Verification will remain deterministic: governance validation, integration scripts, and scorer/report fixtures prove the slice. Review evidence must tie every required quality gate to either emitted findings/evidence or an explicit approved exception record.

## Project Structure

### Documentation (this feature)

```text
specs/005-stack-aware-quality-bar/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
    ├── quality-governance-artifacts.md
    └── mechanical-findings.schema.json
```

### Source Code (repository root)

```text
extensions/specrew-speckit/
├── extension.yml
├── scripts/
│   ├── scaffold-governance.ps1
│   ├── validate-governance.ps1
│   └── deploy-squad-runtime.ps1
├── templates/
│   ├── iteration-config.yml
│   ├── role-assignments.yml
│   └── quality/
│       ├── presets/
│       └── lenses/
└── squad-templates/
    ├── coordinator/
    ├── agents/
    └── skills/

tests/
└── integration/

evaluation/
└── scorers/

docs/
```

**Structure Decision**: Implement the slice as extension-owned source templates/scripts plus deterministic repo tests, then deploy the resulting assets into downstream `.specrew/` directories through the existing scaffolding path. Quality evidence remains part of the existing feature/iteration artifact tree instead of a parallel subsystem.

## Architecture Overview

### Phase 1 Components

| Component | Primary Paths | Responsibilities | Requirements |
| --- | --- | --- | --- |
| Quality Governance Asset Registry | `extensions/specrew-speckit/templates/quality/**`, `scaffold-governance.ps1`, downstream `.specrew/config.yml` | Define where presets and lens checklists live, scaffold them into downstream repos, and make the paths/versioning discoverable to later scripts | FR-022, FR-023, FR-024, FR-024a, FR-025, FR-026 |
| Quality Profile Resolver | planner/coordinator governance templates plus new profile-resolution script surface | Infer the active feature's quality profile from spec scope + repo signals, select preset references when recognized, and fall back to a bounded Phase 1 custom profile composition path | FR-002, FR-003, FR-003a, FR-004, FR-010, FR-011 |
| Mechanical Check Catalog and Runner | new script surfaces under `extensions/specrew-speckit/scripts/`, contract schema in `contracts/` | Model dead-field, anti-pattern, and test-integrity checks as deterministic rules that emit machine-readable findings with remediation metadata | FR-027, FR-028, FR-029, FR-030 |
| Rule Demotion Workflow Metadata | governance artifacts + change logs + explicit exception records | Record reviewed demotions of noisy rules from blocking mechanical checks to advisory guidance without hiding them | FR-030a |
| Quality Evidence Publisher | plan/review artifact contract, downstream iteration artifacts, governance validation | Make selected profile, tool bundle, gate status, findings references, and approved exceptions visible and reviewable in lifecycle artifacts | FR-010, FR-011, FR-012 |
| Deterministic Verification Lane | `tests/integration/`, `evaluation/scorers/`, `validate-governance.ps1` | Prove scaffolding, contracts, evidence visibility, and JSON finding structure without requiring later-phase live bug-hunter workflows | FR-010, FR-011, FR-012, FR-027, FR-030 |

## Phase 0: Research Decisions

Research outputs are captured in [research.md](research.md). The Phase 0 decisions that drive this plan are:

1. Keep quality governance assets in downstream `.specrew/` space, but source them from extension templates so Specrew remains the system of record.
2. Use semantic-versioned Markdown artifacts for presets and lens checklists, including the worked `node-public-ws-service` preset in the preset artifact itself.
3. Emit mechanical findings as JSON envelopes aligned with existing scorer-style structured output, with one record shape shared across dead-field, anti-pattern, and test-integrity rules.
4. Record planned quality expectations in feature/iteration artifacts rather than inventing a separate quality-only workflow; Phase 1 stays additive to Specrew's current lifecycle.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) defines the authoritative entities for quality profiles, stack presets, lens checklists, quality gates, structured findings, evidence records, and demotion records.
- [contracts/quality-governance-artifacts.md](contracts/quality-governance-artifacts.md) defines the normative artifact layout and lifecycle-visible fields.
- [contracts/mechanical-findings.schema.json](contracts/mechanical-findings.schema.json) defines the machine-readable findings payload required by FR-030.

### Downstream Artifact Shape

Phase 1 will introduce or reserve the following downstream surfaces:

```text
.specrew/
├── config.yml
├── presets/
│   └── node-public-ws-service-v1.md
└── lenses/
    ├── security-baseline-v1.md
    ├── robustness-baseline-v1.md
    └── test-integrity-v1.md

specs/<feature>/
└── iterations/<NNN>/
    └── quality/
        ├── quality-evidence.md
        └── mechanical-findings.json
```

- `config.yml` will gain explicit quality-asset path metadata so scripts can discover preset/lens roots without hard-coded magic beyond `.specrew/`.
- Presets and lens checklists remain Markdown-first and git-reviewable.
- `quality-evidence.md` is the human-review surface; `mechanical-findings.json` is the downstream-tooling surface.

## Delivery Slices (Dependency-Aware)

### Slice A — Quality asset registry and versioned sources

**Goal**: Establish the source-of-truth artifacts and scaffolding path before any profile inference or findings logic is added.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| A1 | Add extension template roots for versioned presets and lens checklists | Spec Steward | — | New integration test proves scaffold copies assets without overwriting local edits | FR-022, FR-023, FR-024, FR-024a, FR-025 |
| A2 | Extend `scaffold-governance.ps1` and downstream `.specrew/config.yml` to expose quality artifact paths | Implementer | A1 | Dry-run scaffold output and config assertions | FR-023, FR-024, FR-025 |
| A3 | Define the minimum v1 preset set and the worked `node-public-ws-service` example with change logs/upgrade guidance | Planner | A1 | Artifact contract test validates required sections and semantic versions | FR-024, FR-024a, FR-025, FR-026 |

### Slice B — Quality profile planning integration

**Goal**: Make the active quality profile explicit in planning artifacts using repo signals and versioned preset references.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| B1 | Add a profile-resolution surface that maps clarified feature scope + repo evidence to stack surfaces, risk dimensions, and preset references | Planner | A1-A3 | Deterministic fixture test for recognized stack selection and bounded custom composition fallback | FR-002, FR-003, FR-003a, FR-004 |
| B2 | Update planner/coordinator governance prompts/templates so plan artifacts expose quality profile, tool bundle, gate list, preset/lens refs, and not-applicable dimensions | Spec Steward | B1 | Contract test against rendered planning artifact sections | FR-010, FR-011 |
| B3 | Keep unsupported/later-phase dimensions explicitly deferred instead of silently implied (e.g., hardening gate, dedicated bug-hunter execution) | Spec Steward | B2 | Review of rendered plan text and governance validation messages | FR-010, FR-011 |

### Slice C — Mechanical checks and structured findings foundation

**Goal**: Define deterministic checks and the shared findings contract without introducing later-phase model-based review.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| C1 | Implement or stub the dead-field/dead-symbol, anti-pattern, and test-integrity rule catalog behind one runner contract | Implementer | A1-A2 | Integration tests over fixture repos/files produce stable findings sets | FR-027, FR-028, FR-029 |
| C2 | Emit findings through a single JSON schema with gate IDs, severity, source location, remediation, and traceability metadata | Implementer | C1 | Schema validation test and scorer-style JSON snapshot | FR-030 |
| C3 | Define reviewed demotion records for noisy rules, including scope, rationale, approval, and change-log linkage | Reviewer + human developer | C2 | Governance test proves demoted rules remain visible as advisory | FR-030a |

### Slice D — Quality evidence publication and governance validation

**Goal**: Make the Phase 1 quality bar reviewable and enforceable in lifecycle artifacts.

| Item | Planned Changes | Owner | Depends On | Verification | Requirements |
| --- | --- | --- | --- | --- | --- |
| D1 | Add `quality-evidence.md` contract and render path for required gate/evidence status | Reviewer | B2, C2 | Integration test checks gate/evidence matrix completeness | FR-010, FR-011, FR-012 |
| D2 | Extend `validate-governance.ps1` to fail when required quality evidence or approved exceptions are missing for declared Phase 1 gates | Reviewer | D1 | Governance validation fixture | FR-012 |
| D3 | Add deterministic tests/reports to the existing integration lane without requiring live lens execution | Implementer + Reviewer | A1-A3, B1-B2, C1-C3, D1-D2 | New `tests/integration/*quality*` scripts plus existing process-quality checks remain green | FR-010, FR-011, FR-012, FR-030 |

## Verification Strategy

### Deterministic Checks

- Extend `tests/integration/` with Phase 1 fixture-based coverage for:
  - preset/lens scaffold contract
  - quality profile rendering in planning artifacts
  - mechanical findings JSON schema compliance
  - quality-evidence completeness and exception handling
- Keep `tests/integration/process-quality-scorer.ps1` and `process-quality-report.ps1` passing so Phase 1 does not regress current evaluation/report behavior.
- Use `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` as the enforcement gate for artifact completeness.

### Human Review Focus

- Review the `node-public-ws-service` preset as the canonical worked example before cloning the pattern to other presets.
- Review at least one demotion record example to ensure noisy-rule fallback remains explicit and auditable.
- Confirm that plan/review artifacts clearly distinguish:
  - selected preset vs. custom composition
  - required vs. not-applicable gates
  - emitted findings vs. approved exception
  - Phase 1 implemented behavior vs. later-phase deferrals

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design completion.*

- **Spec Authority Gate**: PASS — The plan remains constrained to the user-scoped Phase 1 FRs, with every deferred requirement called out explicitly.
- **Layering Gate**: PASS — Design changes remain in extension templates/scripts, downstream generated governance assets, and deterministic tests. No new unsupported platform coupling is introduced.
- **Traceability Gate**: PASS — Delivery slices, contracts, and data model each point back to explicit FRs and later task-generation boundaries.
- **Ownership Gate**: PASS — Workstreams remain assigned to baseline Specrew roles with human approval preserved for demotions and exceptions.
- **Capacity Gate**: PASS — The design stays within a single first-slice iteration budget by sequencing registry → profile → findings → validation rather than parallelizing overlapping artifact changes.
- **Drift/Reconciliation Gate**: PASS — Versioned preset/lens change logs, demotion records, and existing drift/gap governance provide the Phase 1 reconciliation path. Standalone quality-drift automation remains deferred to Phase 3 and is not implied by this slice.
- **Verification Gate**: PASS — Every in-scope requirement maps to a deterministic artifact or validation lane; no Phase 1 deliverable depends on unimplemented later-phase model-based review.

## Task Generation Readiness

Phase 2 task generation should preserve the slice order above and keep these dependency rules:

1. Do not start profile inference work before preset/lens asset scaffolding exists.
2. Do not wire governance enforcement before the findings schema and evidence contract are stable.
3. Keep demotion workflow tasks separate from the initial mechanical-rule implementation so reviewed approval semantics remain explicit.
4. Treat later-phase features as explicit deferred follow-ons, not hidden sub-tasks in this first slice.

## Complexity Tracking

No constitution violations require justification for this Phase 1 slice.
