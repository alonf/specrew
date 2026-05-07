# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: [e.g., `quality-profile.node-public-ws-service.v1` or `quality-profile.custom-composition.v1`]  
**Selected preset ref or explicit custom composition**: [List the selected preset ref or explicit custom composition for this feature.]  
**Bounded custom composition**: [If no recognized Phase 1 preset matches cleanly, describe the bounded custom composition path and the manual unknowns it leaves explicit.]

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| [e.g., `api-runtime`] | [e.g., `src/api/**`, `package.json`] | [preset ID or `custom`] | [material feature surface] |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| [e.g., `security`] | [required] | [why this dimension is active] |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | [tool bundle identifier] | [how it maps to the feature] |
| Mechanical Checks | [dead-field, anti-pattern, test-integrity] | [where evidence will be recorded] |
| Ecosystem Tools | [stack-aware lint/test/analyzer commands] | [free/community baseline when practical] |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| [gate ID] | [mechanical/tooling/manual-evidence] | [command or artifact path] | [planned] |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| [e.g., `concurrency-correctness-review`] | [explicit rationale] | [recorded defer or none] |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics remain deferred in this template.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred in this template.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred in this template.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: Confirm plan scope maps to approved spec artifacts.
- **Layering Gate**: Classify changes as Spec Kit layer, Squad layer, or team
  configuration, with explicit rationale.
- **Traceability Gate**: Confirm each planned deliverable links to user stories,
  requirements, and planned tasks.
- **Ownership Gate**: Confirm explicit role ownership for each major workstream,
  including Spec Steward accountability.
- **Capacity Gate**: Define effort unit and iteration capacity budget used for
  planning and assignment.
- **Drift/Reconciliation Gate**: Define how drift detection and conflict
  escalation will be executed during implementation.
- **Verification Gate**: Define process and outcome verification activities,
  including acceptance-criteria validation.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ----------------------------------- |
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
