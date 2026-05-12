# Implementation Plan: Handoff Format Scoping

**Branch**: `014-handoff-format-scoping` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)  
**Status**: Closed  
**Closed**: 2026-05-12  
**Input**: Feature specification from `specs/014-handoff-format-scoping/spec.md`

## Summary

This plan narrowed feature 007's three-section handoff rule so only genuine human-blocked stops use the existing stop-message format, while ordinary in-flight coordination stays a concise single-line progress update. The change remained additive inside the existing PowerShell handoff-governance validator and preserved feature 012's readable-reference rule across both governed response types.

The approved two-iteration split remained the cleanest dependency boundary:

- **Iteration 001 (CLOSED)**: rolled out response-type selection guidance, updated the coordinator prompt/template/checklist/agent surfaces, extended the `human-handoff-id-context` rule to both response types, and added the two new additive warning rules with a fixed repository-maintained placeholder list.
- **Iteration 002 (Deferred)**: will add deterministic violating/compliant fixtures, historical-sample calibration, validation-lane follow-through, and known-traps graduation for the new misapplied-stop pattern.

This planning and execution stayed inside the user-authorized boundary: feature opening through Iteration 001 planning scaffold and execution completed. All tasks were generated and executed, Iteration 001 implementation and review completed, and feature closeout is now in progress.

## Technical Context

**Language/Version**: PowerShell 7.x automation plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, coordinator prompt/checklist surfaces under `extensions/specrew-speckit/`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `.specrew/quality/known-traps.md`, existing integration tests under `tests/integration/`  
**Storage**: Git-tracked repository artifacts only (`.md`, `.ps1`, `.json`, `.yml`); no database or external state changes  
**Testing**: PowerShell integration tests under `tests/integration/`, direct validator invocation via `handoff-governance-validator.ps1`, and repository governance validation via `validate-governance.ps1`  
**Target Platform**: Windows_NT workflow with PowerShell-first repository automation and Copilot/Squad session guidance files  
**Project Type**: Spec Kit extension and governance automation repository  
**Performance Goals**: Keep warnings low-noise and additive, preserve concise in-flight updates, and avoid regressions to existing feature 007 / 012 handoff guidance and validator behavior  
**Constraints**: Coordinator top-level response surface only; preserve the existing three-section stop-message format unchanged; fixed repository-maintained placeholder phrase list in code/tests; no positive `soft-info.well-scoped-handoff`; no symmetric reverse warning for silent real stops; no expansion to sub-agent output, tool-rendered result blocks, or unrelated handoff formats; preserve the approved two-iteration split unless a stricter dependency forces change  
**Scale/Scope**: Cross-cutting governance update across validator logic, prompt/template/checklist guidance, Squad session guidance, corpus wording, validation-lane documentation, and planned replay/calibration fixtures; approximately 12 total story points across two bounded iterations

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `iteration-001-stop-vs-progress-scope-rollout`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance heuristics plus Markdown prompt/template/checklist/agent-guidance surfaces  
**Bounded custom composition**: Iteration 001 is a cross-cutting governance slice over existing handoff artifacts. The planning artifacts in this feature resolve the selector, warning-shape, placeholder-list, and iteration-split decisions now; deterministic replay/calibration proof and known-traps graduation remain explicitly deferred to Iteration 002.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `handoff-validator` | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | PowerShell governance script | The two new warnings must extend the existing additive soft-warning path rather than create a parallel validator |
| `coordinator-guidance` | `extensions/specrew-speckit/prompts/*.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | Markdown governance guidance | These surfaces define when a final stop message vs an in-flight progress update is correct |
| `agent-session-guidance` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | Session-loaded agent guidance | The coordinator-facing runtime contract must stay aligned with the prompt/template wording |
| `corpus-and-lane` | `.specrew/quality/known-traps.md`, `extensions/specrew-speckit/governance/validation-lane.md` | Governance corpus + validation registry | Iteration 002 must graduate the new misuse pattern and keep the validation lane aligned |
| `integration-replay` | `tests/integration/**`, `tests/integration/fixtures/**` | PowerShell integration tests + fixtures | Iteration 002 needs deterministic violating/compliant fixtures and historical-sample calibration evidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `governance-correctness` | `required` | The feature's core value is choosing the right response type and warning only on real misuse |
| `feature-007-compatibility` | `required` | Existing progress-status / next-step / review-URI / blocker-risk behavior must remain intact |
| `prompt-template-corpus-drift` | `required` | Prompt, checklist, template, agent guidance, `human-handoff-id-context`, and known-traps wording must agree |
| `low-noise-warning-calibration` | `required` | The new warnings are intentionally advisory and must stay below the false-positive target in the spec |
| `scope-boundary-discipline` | `required` | The rule must stay limited to the coordinator's top-level response surface and exclude sub-agent/tool-rendered content |
| `stateful-data-migration` | `not-applicable` | The feature changes repository guidance, validator heuristics, and fixtures only; no persisted runtime schema exists |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `tool-bundle.custom.powershell-handoff-governance.v1` | Existing PowerShell validator/test tooling plus manual artifact-consistency review fit the feature |
| Mechanical Checks | `handoff-scope-contract-review`, `warning-identifier-consistency`, `placeholder-phrase-list-audit`, `plan/spec traceability review` | Planning-time evidence lives in `plan.md`, `research.md`, `data-model.md`, and the contract artifact |
| Ecosystem Tools | Existing `handoff-governance-*.ps1` tests, future Iteration 002 warning tests, direct `handoff-governance-validator.ps1` invocation, and `validate-governance.ps1 -ProjectPath .` | Keep current regression lanes green while adding bounded warning coverage later |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `constitution-pass` | `manual-evidence` | Constitution Check section in this plan | `recorded-2026-05-12` |
| `handoff-scope-contract-present` | `manual-evidence` | `specs/014-handoff-format-scoping/contracts/coordinator-handoff-scoping.md` | `recorded-2026-05-12` |
| `iteration-001-scope-boundary-reviewed` | `manual-evidence` | `research.md` decisions on response-type selection and iteration split | `recorded-2026-05-12` |
| `feature-007-and-012-regression-lane` | `tooling` | Existing handoff-governance tests plus `validate-governance.ps1 -ProjectPath .` | `planned` |
| `warning-calibration-replay-lane` | `tooling` | Iteration 002 warning fixtures + historical sample calibration commands | `deferred-to-iteration-002` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `database-consistency-review` | No database or persisted domain store exists; all work stays in repository artifacts and PowerShell heuristics | none |
| `concurrency-correctness-review` | The validator is a stateless text scan over assembled response text | none |
| `runtime-throughput-load-testing` | The feature is governed by false-positive control and clarity, not by high-volume request throughput | Revisit only if a later slice adds batch transcript processing |

### Explicit Phase 2+ Deferrals

- Deterministic violating/compliant fixtures for the two new warnings remain deferred to Iteration 002.
- Historical-sample calibration against at least 20 prior responses remains deferred to Iteration 002.
- Known-traps graduation for the misapplied-format pattern remains deferred to Iteration 002.
- Validation-lane expansion and replay-path documentation for the new warnings remain deferred to Iteration 002.
- Positive-emission behavior, reverse symmetric warning logic, and any expansion beyond the coordinator top-level response surface remain out of scope.

## Phase 2 Hardening and Specialist Review Planning

> Fill this section when pre-implementation hardening and specialist bug-hunter review planning apply to the active feature. Mirror the bounded Phase 2 planning metadata from quality-profile resolution when available: slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals, plus the planning-time-vs-runtime evidence boundary. Keep it bounded to the currently approved hardening slice; record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments instead of implying later execution or runtime proof already happened.

**Phase 2 Slice Scope**: `iteration-002-warning-calibration-and-corpus-follow-through`  
**Hardening Gate Artifact**: `specs/014-handoff-format-scoping/quality/hardening-gate.md` (planned only; do not scaffold during planning)  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/014-handoff-format-scoping/quality/trap-reapplication.md` (planned only; do not scaffold during planning)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Genuine-stop vs in-flight discrimination | The feature fails if the validator warns on normal progress updates or misses faux stop messages | Iteration 002 fixture lanes plus hardening-gate concern sections | `required` |
| Placeholder-phrase transparency | Humans must understand why `soft-warning.empty-user-action-section` fired and which phrase matched | Fixed phrase list documented in the contract, data model, and replay fixtures | `required` |
| Existing handoff-governance compatibility | New warnings must remain additive and preserve feature 007 / 012 behavior | Preserved regression commands plus direct validator runs in Iteration 002 | `required` |
| Test-integrity / calibration coverage | FR-009 requires at least one violating and one compliant fixture per rule plus low-noise calibration on historical samples | Planned warning-specific tests, fixture corpus, and calibration manifest | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `coordinator-handoff-governance` checklist | `required` | It is the primary human-review and validator-alignment surface for stop-vs-progress scoping | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` |
| `known-traps reapplication` | `required` | Iteration 002 must graduate and recheck the misapplied stop-message pattern before closeout | `.specrew/quality/known-traps.md` and planned `quality/trap-reapplication.md` |
| `blocking-enforcement escalation` | `not-applicable` | The spec explicitly keeps both warnings soft and additive | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` planning review | to be recorded when execution happens | `none` | Routing may deepen review quality, but it must not convert advisory warnings into blocking enforcement without new spec approval |

### Explicit Later Deferrals

- Hardening-gate and trap-reapplication files are planned only; they are not created in this planning phase.
- Runtime replay evidence, historical-sample calibration results, and closeout validation-lane proof remain deferred until implementation is authorized.
- No Iteration 002 directory scaffolding is performed here because the repository known-traps corpus forbids pre-emptive iteration scaffolding without fresh authorization.
- Any broader governance refactor outside stop-vs-progress scoping remains out of scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — scope maps directly to the approved `specs/014-handoff-format-scoping/spec.md`. The plan stays inside FR-001 through FR-009 and preserves the user-authorized boundary: planning only, no tasks, no implementation, no unauthorized Iteration 002 scaffolding.
- **Layering Gate**: PASS — all planned changes stay inside supported Specrew surfaces: PowerShell validator logic, Markdown prompt/template/checklist guidance, session-loaded agent guidance, governance corpus, validation-lane documentation, and test fixtures. No unsupported Copilot/VS Code hacks or unrelated runtime-layer changes are introduced.
- **Traceability Gate**: PASS — planned workstreams map cleanly to TG-001 through TG-004. Iteration 001 covers FR-001 through FR-007; Iteration 002 covers FR-008 and FR-009 plus the proving/calibration surfaces they require.
- **Ownership Gate**: PASS — Governance prompt stewards own coordinator prompt and decision guidance updates; handoff-template stewards own `coordinator-handoff-template.md`; validator maintainers own the new warnings and fixed placeholder list; governance corpus stewards own `human-handoff-id-context` wording and known-traps graduation; Alon Fliess remains Spec Steward per the approved spec.
- **Capacity Gate**: PASS — capacity unit is story points, following the spec's two-iteration / ~12-point model. Planned split: Iteration 001 = 7 points for selector/guidance/warning rollout and `human-handoff-id-context` applicability wording; Iteration 002 = 5 points for deterministic fixtures, calibration, validation-lane updates, and known-traps graduation. This preserves the source draft's intended split because later proof work depends on the Iteration 001 contract and warning shape but does not block defining them now.
- **Drift/Reconciliation Gate**: PASS — prompt, checklist, template, agent guidance, validator warning identifiers, `human-handoff-id-context`, and known-traps wording must be updated together in the same implementation slice whenever the selector or warning semantics change. Any discovered mismatch is a reconciliation event and must be corrected in the same PR rather than normalized.
- **Verification Gate**: PASS — `research.md`, `data-model.md`, `contracts/coordinator-handoff-scoping.md`, and `quickstart.md` define the bounded design now. Verification later consists of preserved regression tests, direct validator invocation, new warning-specific violating/compliant fixtures, historical-sample calibration, and `validate-governance.ps1 -ProjectPath .` before closeout.

**Post-Phase 1 Re-check**: PASS — the design artifacts keep the feature bounded to supported extension surfaces, preserve the two-iteration split, and introduce no constitutional violations or hidden expansion beyond the coordinator top-level response contract.

## Project Structure

### Documentation (this feature)

```text
specs/014-handoff-format-scoping/
├── plan.md                                 # This file
├── research.md                             # Phase 0 output
├── data-model.md                           # Phase 1 output
├── quickstart.md                           # Phase 1 output
├── contracts/
│   └── coordinator-handoff-scoping.md      # Phase 1 governance contract
└── tasks.md                                # Deferred; not created by this planning workflow
```

### Source Code (repository root)

```text
extensions/specrew-speckit/
├── validators/
│   └── handoff-governance-validator.ps1
├── prompts/
│   ├── coordinator-response.md
│   └── coordinator-decision-guidance.md
├── checklists/
│   └── coordinator-handoff-governance.md
└── governance/
    └── validation-lane.md

specs/001-specrew-product/contracts/
└── coordinator-handoff-template.md

.github/agents/
└── squad.agent.md

.squad/templates/
└── squad.agent.md

.specrew/quality/
└── known-traps.md

tests/integration/
├── handoff-governance-jargon-response-test.ps1
├── handoff-governance-plain-language-response-test.ps1
├── handoff-governance-review-file-reference-test.ps1
├── handoff-governance-descriptive-narration-test.ps1
├── handoff-governance-descriptive-stop-message-test.ps1
├── handoff-governance-empty-user-action-test.ps1          # planned Iteration 002
├── handoff-governance-transitional-stop-claim-test.ps1    # planned Iteration 002
└── fixtures/
    └── handoff-format-scoping/                            # planned Iteration 002 warning + calibration fixtures
```

**Structure Decision**: Keep the feature as a cross-cutting governance update inside the existing validator, prompt, checklist, template, agent-guidance, corpus, and integration-test surfaces. Planned Iteration 002 `quality/` artifacts and warning fixtures are documented here only; they are intentionally not scaffolded during this planning run.

## Complexity Tracking

No constitutional violations require justification for this plan.
