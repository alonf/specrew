# Implementation Plan: Substantive Interaction Model

**Branch**: `016-substantive-interaction-model` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `C:\Dev\Specrew\specs\016-substantive-interaction-model\spec.md`

## Summary

Feature 016 resumes at Iteration 002 with the original sustainability slice intact—FR-020 through
FR-024 plus the FR-016 severity graduation proof—but the plan also absorbs the tightly-coupled
carryovers discovered during Iteration 001 review and retro so the follow-through is truthful
instead of pretending the remaining work is still the original ~9 SP stub.

The resumed Iteration 002 plan therefore covers:

- FR-020 through FR-024
- FR-016 Iteration 2 promotion from soft warning to hard fail after bounded-false-positive proof
- FR-008 follow-through for pending -> post-commit Commit Reference synchronization
- Decisions-ledger `Recorded At` canonicalization to UTC seconds precision
- Post-commit verification protocol formalization in README/template/handoff guidance
- A stale-reference scan mandate after boundary commits, with prompt/checklist updates
- Graduation of the feature-local passive-guidance rows that were proven by Iteration 001 evidence

Planned Iteration 002 capacity is **17.0 / 20 story_points**, keeping the slice below the
constitutional cap while making explicit deferrals for work that would otherwise over-expand the
feature: standalone fractional-second parser broadening, standalone stale-reference soft-validator
support, validator performance optimization, and the non-feature-local
`self-referential-feature-sp-surcharge` corpus row.

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML governance artifacts  
**Primary Dependencies**: Git commit history, `extensions/.specify` mirrored PowerShell validator
surfaces, Pester + replay-path integration scripts, `.squad/decisions.md`, `.specrew/quality/known-traps.md`  
**Storage**: File-based repository artifacts (`.squad/`, `.specrew/`, `specs/`, `extensions/`, `tests/`)  
**Testing**: PowerShell integration replay scripts, Pester unit coverage, repo-wide `validate-governance.ps1` runs  
**Target Platform**: Windows PowerShell-driven repository workflow  
**Project Type**: Specrew governance extension / repository automation tooling  
**Performance Goals**: Preserve replay-path proof and validator boundedness; calibrate runtime claims
against a locked pre-change baseline rather than a post-change tree; avoid any transcript-parsing expansion  
**Constraints**: Keep Pillar 2 rules soft-warning-only; keep validator scope bounded to
Squad-authored handoffs/artifacts; plan Iteration 002 only; preserve Iteration 001 closed state; stay
below 20 story_points  
**Scale/Scope**: One feature-level governance slice spanning validator scripts, prompt/template
surfaces, docs, known-traps corpus, decisions-ledger contract, and replay fixtures

## Phase 1 Quality Planning

**Phase Scope**: `iteration-002-resume-planning`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition of governance-validator
correctness, replay-path integrity, corpus truthfulness, and public-doc/template consistency  
**Bounded custom composition**: Planning covers only the explicit Feature 016 follow-through slice.
Dedicated bug-hunter execution, strongest-class routing enforcement, and quality-drift automation stay
deferred until a later authorized slice needs them.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `validator-runtime` | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1`, `extensions/specrew-speckit/validators/*.ps1` | custom-governance-powershell | Rule rollout, commit-reference synchronization, timestamp policy, and scope enforcement live here |
| `replay-and-unit-proof` | `tests/integration/**/*.ps1`, `tests/unit/**/*.ps1` | powershell-test-harness | FR-021 requires violating/compliant/exempt scaffold-replay coverage |
| `docs-and-template-truth` | `README.md`, `extensions/specrew-speckit/governance/*.md`, `specs/001-specrew-product/contracts/*.md` | markdown-governance-docs | FR-022 and FR-023 plus post-commit verification protocol formalization land here |
| `corpus-and-ledger` | `.specrew/quality/known-traps.md`, `.squad/decisions.md` | markdown-governance-memory | Carryover rows, FR-020/024 cross-references, and authorization-record discipline depend on these files |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| governance-integrity | required | Feature 016 governs lifecycle truth surfaces; silent carryover deferral would create planning drift |
| test-integrity | required | FR-021 explicitly requires replay-path violating/compliant/exempt fixtures through real entrypoints |
| documentation-truth | required | README, validation-lane, and handoff template text must describe the actual three-pillar contract and new post-commit rules |
| authorization-surface | required | Commit-reference synchronization and timestamp precision affect `.squad/decisions.md` fidelity |
| concurrency-correctness | not-applicable | The slice is repository-governance tooling, not concurrent runtime state management |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `feature-016-iteration-002-governance-followthrough` | Custom bundle for validator + docs/template + corpus follow-through |
| Mechanical Checks | `dead-field`, `anti-pattern`, `test-integrity`, `mirror-sync-check` | Evidence recorded in Iteration 002 quality artifacts and replay outputs |
| Ecosystem Tools | `pwsh` replay scripts, `Invoke-Pester`, repo-wide `validate-governance.ps1` | Use the existing real-surface PowerShell harnesses rather than mocks |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `test-integrity` | mechanical | `tests/integration/substantive-interaction-model-iteration2.ps1`, `tests/unit/validate-governance.interaction-model.tests.ps1` | planned |
| `mirror-sync-check` | mechanical | mirrored `extensions/` + `.specify/extensions/` paths | planned |
| `known-trap-cross-reference-completeness` | manual-evidence | `.specrew/quality/known-traps.md` | planned |
| `post-commit-verification-truth` | manual-evidence | README, validation docs, handoff template, quickstart | planned |
| `repo-validator-clean` | tooling | `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `distributed-systems-failure-review` | No networked or multi-host runtime semantics are added in this slice | none |
| `frontend-rendering-review` | No UI rendering or browser-facing surfaces are touched | none |

### Explicit Phase 2+ Deferrals

- Dedicated pre-implementation hardening-gate execution remains deferred until implementation is
  explicitly authorized.
- Standalone stale-reference soft-validator support is deferred unless the implementation falls out
  trivially from the mandated replay/doc work.
- Decisions-ledger fractional-second parser broadening is deferred; Iteration 002 uses a simpler and
  reviewable seconds-precision canonical format.
- Validator performance optimization remains deferred; only truthful baseline-locked calibration and
  documentation are in scope now.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `iteration-002 planning only — proof, corpus, docs/template, and post-commit carryover follow-through`  
**Hardening Gate Artifact**: `specs/016-substantive-interaction-model/iterations/002/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/016-substantive-interaction-model/iterations/002/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Authorization / ledger synchronization | FR-008 follow-through now depends on replacing `pending` commit references in the same post-commit cycle and keeping `Recorded At` canonical | contracts, README/template protocol text, replay fixtures, quality evidence | required |
| Click-through evidence hygiene | The new stale-reference scan mandate must keep `file:///` navigation truthful after boundary commits | handoff template, validator documentation, replay commands | required |
| Replay-path proof integrity | FR-021 and SC-007 require violating/compliant/exempt fixtures through scaffold-replay paths before severity graduation | integration + unit tests, quality evidence | required |
| Documentation and template truthfulness | FR-022 and FR-023 must describe the actual three-pillar model, validator scope, and post-commit verification workflow | README, validation-lane.md, coordinator handoff template | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `manual-governance-review` | required | Public docs, corpus rows, and template examples need human truthfulness review, not just script replay | `specs/016-substantive-interaction-model/iterations/002/quality/quality-evidence.md` |
| `security-issues-v1` | required | Authorization text and decision-ledger mutations remain a security/privacy-adjacent surface | `specs/016-substantive-interaction-model/iterations/002/quality/hardening-gate.md` |
| `concurrency-correctness-review` | not-applicable | No concurrent runtime behavior is introduced | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest available planning/review class | not run yet | none | Planning only; execution remains future work |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence remains deferred until implementation and review are
  explicitly authorized.
- Strongest-class routing enforcement details remain deferred until routed execution happens.
- Quality-drift automation, mixed-stack override workflows, and reference-implementation comparisons
  remain deferred unless a later authorized slice pulls them in.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — the resumed scope keeps Feature 016 authority rooted in FR-020
  through FR-024, FR-016 graduation, and tightly-coupled FR-008 / review / retro follow-through.
- **Layering Gate**: PASS — planned changes stay within Spec Kit planning artifacts, Squad
  governance memory, prompt/template surfaces, validator scripts, docs, corpus, and replay fixtures.
- **Traceability Gate**: PASS — every planned deliverable maps to FR/TG/SC coverage or an explicit
  carryover item grounded in Iteration 001 review/retro evidence.
- **Ownership Gate**: PASS — Governance steward, Validator steward, Quality steward, Documentation
  steward, and Iteration facilitator ownership remains explicit in Iteration 002 planning.
- **Capacity Gate**: PASS — Iteration 002 is planned at **17.0 / 20 story_points**, below the
  constitutional ceiling and inside the requested 15-19 SP target band.
- **Drift/Reconciliation Gate**: PASS — the plan explicitly records in-scope carryovers and explicit
  deferrals so the feature does not silently lose lessons from Iteration 001.
- **Verification Gate**: PASS — replay-path proof, repo-validator reruns, docs/template truth review,
  and known-traps cross-reference validation are all planned explicitly.

## Project Structure

### Documentation (this feature)

```text
specs/016-substantive-interaction-model/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── boundary-authorization-and-handoff.md
│   └── interaction-model-validator-contract.md
├── iterations/
│   ├── 001/
│   └── 002/
└── tasks.md
```

### Source Code (repository root)

```text
.squad/
├── decisions.md
└── config.json

.specrew/
└── quality/
    └── known-traps.md

extensions/specrew-speckit/
├── governance/
│   └── validation-lane.md
├── prompts/
├── scripts/
│   ├── shared-governance.ps1
│   └── validate-governance.ps1
├── squad-templates/
└── validators/

.specify/extensions/specrew-speckit/
├── scripts/
│   ├── shared-governance.ps1
│   └── validate-governance.ps1
└── squad-templates/

tests/
├── integration/
└── unit/

README.md
specs/001-specrew-product/contracts/coordinator-handoff-template.md
```

**Structure Decision**: This is a single-repository governance/tooling feature. The canonical
implementation surfaces are mirrored PowerShell validator scripts, Markdown governance docs/templates,
the decisions ledger, the known-traps corpus, and replay-path tests; no new runtime application module
is introduced.

## Complexity Tracking

No constitutional violations require justification in this plan. The main complexity control is
explicit scoping: absorb only the carryovers that are tightly coupled to Feature 016's approved
authority and defer the rest explicitly.
