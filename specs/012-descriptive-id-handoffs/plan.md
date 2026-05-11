# Implementation Plan: Descriptive References in Handoffs

**Branch**: `012-keep-descriptive-refs` | **Date**: 2026-05-11 | **Spec**: [./spec.md](./spec.md)  
**Input**: Feature specification from `/specs/012-descriptive-id-handoffs/spec.md`

## Summary

Add descriptive-reference behavior to the existing feature 007 handoff surfaces so Squad-authored narration and stop messages keep numeric identifiers readable without weakening current handoff governance. Preserve the preferred two-iteration split: Iteration 001 extends the existing handoff-governance validator rule, coordinator prompt/template/checklist guidance, Squad startup guidance, and worked examples; Iteration 002 adds scaffold-replay-path integration coverage, corpus seeding, and documentation polish while keeping FR-008 and FR-009 strictly non-blocking. Spec status remains Draft as a process note only and does not block this planning workflow.

## Iteration Breakdown

| Iteration | Goal | Included Scope | Explicit Boundaries |
| --- | --- | --- | --- |
| `001` | Roll out the readable-reference rule across the live handoff surfaces | Add the new validator detection rule for opaque numeric references in authored prose; update `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and worked examples | No blocking enforcement, no iteration artifact scaffolding, no task generation, and no weakening of existing feature 007 progress/next-step/file-URI/jargon checks |
| `002` | Prove the rule through bounded integration evidence | Add scaffold-replay-path integration tests, seed corpus examples, update validation-lane documentation, and do documentation polish that stays inside the same descriptive-reference scope | Keep enforcement non-blocking per FR-008/FR-009; do not reopen unrelated governance checks or widen to tool-rendered output |

## Technical Context

**Language/Version**: PowerShell 7.x automation plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: Existing Specrew Spec Kit extension surfaces, Squad/Copilot startup guidance, PowerShell validator/test scripts, Markdown contracts and checklists  
**Storage**: Git-tracked repository files only (`.md`, `.ps1`, `.yml`, `.json`); no database changes  
**Testing**: PowerShell integration tests under `tests/integration`, validator spot checks from `extensions/specrew-speckit/governance/validation-lane.md`, and `validate-governance.ps1`  
**Target Platform**: Windows_NT development workflow with PowerShell-first repository automation  
**Project Type**: Spec Kit extension and governance automation repository  
**Performance Goals**: Low-noise soft-warning detection on final coordinator text with zero new hard-blocking behavior and no regressions to feature 007 handoff quality  
**Constraints**: Limit scope to Squad-authored narration and stop messages, exclude verbatim/tool-rendered surfaces, preserve feature 007 compatibility, avoid iteration scaffolding during planning, and keep the split to two iterations unless a cleaner dependency boundary appears  
**Scale/Scope**: Cross-cutting governance update across existing prompt, checklist, contract, agent-guidance, validator, validation-lane, and integration-test surfaces

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `iteration-001-descriptive-reference-guidance-and-rule`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance logic plus Markdown prompt, checklist, contract, and agent-guidance surfaces  
**Bounded custom composition**: Iteration 001 is a cross-cutting governance slice over the existing handoff surfaces. `research.md` resolves the planning unknowns; runtime replay coverage, corpus seeding, and hardening artifacts remain explicitly deferred to Iteration 002.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `handoff-validator` | `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | PowerShell governance script | The new descriptive-reference rule must extend the existing soft-warning path instead of creating a parallel validator |
| `coordinator-guidance` | `extensions/specrew-speckit/prompts/*.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | Markdown prompt/checklist/template surfaces | These files make the descriptive-reference behavior durable in authored narration and stop messages |
| `agent-startup-guidance` | `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md` | Agent governance docs | Runtime and source Squad guidance must stay aligned to avoid drift in session-loaded instructions |
| `integration-validation` | `tests/integration/**`, `extensions/specrew-speckit/governance/validation-lane.md`, `.specrew/quality/known-traps.md` | PowerShell tests plus governance registry | These are the planned Iteration 002 proof surfaces for replay assertions, corpus seeding, and low-noise regression evidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `governance-correctness` | `required` | The new rule must examine authored narration and stop-message prose only, while leaving excluded verbatim surfaces alone |
| `feature-007-compatibility` | `required` | Existing progress-status, next-step, jargon-first, blocker, and review-file guidance must remain intact |
| `prompt-durability` | `required` | Prompt, checklist, template, and Squad startup guidance must all describe the same descriptive-reference behavior |
| `worked-example-coverage` | `required` | FR-007 and SC-004 require acceptable and unacceptable examples that line up with the validator rule |
| `stateful-data-migration` | `not-applicable` | The feature changes repository guidance and validator heuristics only; no persisted schema or migration path exists |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `tool-bundle.custom.powershell-governance-docs.v1` | Existing governance scripts plus manual artifact review fit this feature better than a runtime-app preset |
| Mechanical Checks | `validate-governance`, plan/spec traceability review, contract-to-data-model review | Planning-time evidence stays in `plan.md`, `research.md`, `data-model.md`, and the contract artifact |
| Ecosystem Tools | Existing PowerShell handoff-governance tests, direct validator invocation, manual Markdown review | Iteration 001 uses current tests as regression baseline; Iteration 002 adds replay-path and corpus coverage |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `constitution-pass` | `manual-evidence` | Constitution Check section in this plan plus `research.md` | `planned` |
| `handoff-compatibility-review` | `manual-evidence` | `research.md` decisions and `contracts/descriptive-reference-handoff.md` preservation clauses | `planned` |
| `governance-schema-validation` | `tooling` | `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` | `planned` |
| `handoff-governance-regression-baseline` | `tooling` | Existing commands documented in `extensions/specrew-speckit/governance/validation-lane.md` | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `database-consistency-review` | No database or persisted domain schema exists; all work stays in repository artifacts and PowerShell heuristics | none |
| `concurrency-correctness-review` | The validator is a stateless text scan with no concurrent runtime coordination | none |
| `performance-load-testing` | The feature operates on a single assembled coordinator response and is governed by false-positive control rather than throughput targets | Revisit only if a future slice adds large-batch transcript processing |

### Explicit Phase 2+ Deferrals

- Scaffold-replay-path integration tests and fixture scaffolding remain deferred to Iteration 002.
- Corpus seeding in `.specrew/quality/known-traps.md` and trap reapplication evidence remain deferred to Iteration 002.
- Validation-lane expansion for the descriptive-reference scenarios remains deferred to Iteration 002.
- Any blocking enforcement, failure semantics change, or expansion beyond the non-blocking governance review described in FR-008 and FR-009 is out of scope.

## Phase 2 Hardening and Specialist Review Planning

> Fill this section when pre-implementation hardening and specialist bug-hunter review planning apply to the active feature. Mirror the bounded Phase 2 planning metadata from quality-profile resolution when available: slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals, plus the planning-time-vs-runtime evidence boundary. Keep it bounded to the currently approved hardening slice; record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments instead of implying later execution or runtime proof already happened.

**Phase 2 Slice Scope**: `iteration-002-integration-coverage-and-corpus-seeding`  
**Hardening Gate Artifact**: `specs/012-descriptive-id-handoffs/quality/hardening-gate.md` (planned only; do not scaffold during planning)  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md` (planned only; do not scaffold during planning)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Authored-prose vs excluded-surface discrimination | FR-006 and FR-009 require the rule to ignore verbatim tool output, Copilot-rendered tool-call result blocks, code blocks, and quoted content | Contract clauses plus planned replay fixtures and a hardening-gate concern section | `required` |
| Existing handoff-governance compatibility | FR-010 and TG-005 require additive behavior only; existing feature 007 warnings must continue to behave the same way | Manual comparison against feature 007 surfaces and future regression evidence in the validation lane | `required` |
| Test-integrity / scaffold-replay-path coverage | User guidance explicitly wants scaffold-replay-path assertions, and known-trap history requires user-visible proof instead of state-file-only checks | Planned `tests/integration/descriptive-reference-*.ps1` plus fixture paths that exercise the real replay/runtime path | `required` |
| Corpus seeding and low-noise review | SC-004 depends on seeded warn/pass examples, and the validator must stay low-noise | Planned known-trap updates plus `trap-reapplication.md` once the iteration is approved | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `coordinator-handoff-governance` checklist | `required` | It is the primary human-review surface for the descriptive-reference rule and must stay aligned with the validator | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` |
| `known-traps reapplication` | `required` | Iteration 002 introduces replay coverage and corpus seeding, so prior trap history must be rechecked before closeout | `specs/012-descriptive-id-handoffs/quality/trap-reapplication.md` (future) |
| `blocking-enforcement escalation` | `not-applicable` | FR-008 and FR-009 explicitly bound the feature to non-blocking governance review | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest-available planning review | to be recorded when execution happens | `none` | Routing may deepen review quality, but it must not convert the descriptive-reference rule into a blocking gate without new spec approval |

### Explicit Later Deferrals

- Hardening-gate and trap-reapplication files are planned only; they are not created in this planning phase.
- Runtime replay evidence, corpus approvals, and closeout validation-lane results remain deferred until implementation is authorized.
- Any broader governance refactor outside descriptive numeric references is out of scope.
- Task generation and iteration artifact scaffolding remain deferred to later commands.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — scope maps directly to `spec.md`; Draft status is noted as a process concern only and does not block planning. The plan stays inside FR-001 through FR-010 and TG-001 through TG-006.
- **Layering Gate**: PASS — the feature lives in Specrew's supported extension surfaces: prompts, checklist, contract, validator, governance docs, and Squad guidance files. No unsupported platform hacks or unrelated runtime layers are introduced.
- **Traceability Gate**: PASS — Iteration 001 covers the readable-reference rule, worked examples, and durable guidance surfaces; Iteration 002 covers scaffold-replay-path evidence, corpus seeding, and polish. Tasks are intentionally not generated in this phase, but every planned workstream maps to named requirements and stories.
- **Ownership Gate**: PASS — coordinator/prompt maintainers own authored-message guidance, handoff-governance maintainers own validator and checklist behavior, agent-guidance maintainers own Squad startup files, and the Spec Steward remains accountable for scope control.
- **Capacity Gate**: PASS — use story points with a two-iteration budget: Iteration 001 = 8 points, Iteration 002 = 5 points. This keeps the user-preferred split while cleanly separating rule rollout from replay/corpus evidence.
- **Drift/Reconciliation Gate**: PASS — `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` must be updated together, feature 007 soft-warning behavior must remain intact, and any validator-rule change must be reconciled across prompt/checklist/template/worked examples in the same iteration.
- **Verification Gate**: PASS — `research.md`, `data-model.md`, the contract, and `quickstart.md` define planning-time verification, existing handoff-governance tests remain the regression baseline, and Iteration 002 adds scaffold-replay-path assertions plus corpus seeding before closeout.

**Post-Phase 1 Re-check**: PASS — the design artifacts keep scope bounded, preserve supported extension layering, and introduce no constitutional violations that require complexity justification.

## Project Structure

### Documentation (this feature)

```text
specs/012-descriptive-id-handoffs/
├── plan.md                               # This file
├── research.md                           # Phase 0 output
├── data-model.md                         # Phase 1 output
├── quickstart.md                         # Phase 1 output
├── contracts/
│   └── descriptive-reference-handoff.md  # Phase 1 output
└── tasks.md                              # Deferred; not created by this planning workflow
```

### Source Code (repository root)

```text
extensions/specrew-speckit/
├── checklists/
├── governance/
├── prompts/
└── validators/

.github/
└── agents/

.squad/
└── templates/

tests/
└── integration/

.specrew/
└── quality/

specs/
├── 001-specrew-product/
│   └── contracts/
└── 012-descriptive-id-handoffs/
```

**Structure Decision**: Keep the feature as a cross-cutting governance update inside existing prompt, checklist, validator, contract, agent-guidance, and integration-test surfaces. Planned `quality/` artifacts for feature 012 are future iteration outputs only and are intentionally not scaffolded during planning.

## Complexity Tracking

No constitutional violations require justification for this plan.
