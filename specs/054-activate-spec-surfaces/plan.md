# Implementation Plan: Discoverable Spec Kit Surfaces

**Branch**: `054-activate-spec-surfaces` | **Date**: 2026-05-31 | **Spec**: `specs/054-activate-spec-surfaces/spec.md`  
**Input**: Feature specification from `specs/054-activate-spec-surfaces/spec.md`

## Summary

Promote `/speckit.checklist` and `/speckit.analyze` into first-class Specrew discovery surfaces without changing the approved lifecycle: `/speckit.checklist` is surfaced before-plan as a requirements-quality aid recommended for substantive features and optional for lightweight slices, `/speckit.analyze` is surfaced before-implement only after `/speckit.tasks` has produced a complete `tasks.md`, and `/speckit.taskstoissues` stays explicitly deferred. This plan is intentionally bounded to planning/design artifacts for documentation, prompt/agent-discovery, lifecycle contracts, and validation evidence; task generation and implementation changes require a later human approval.

## Technical Context

**Language/Version**: PowerShell 7.x governance scripts plus Markdown/YAML/JSON artifact surfaces  
**Primary Dependencies**: Specrew PowerShell scripts, Spec Kit extension assets under `.specify/extensions/` and `extensions/`, GitHub Copilot agent/prompt markdown under `.github/`, and repository docs under `README.md` and `docs/`  
**Storage**: Git-tracked filesystem artifacts only (`specs/`, `.specify/`, `.specrew/`, `.github/`, `docs/`, `tests/`)  
**Testing**: Markdown linting via `npx --yes markdownlint-cli`, PowerShell integration lanes in `tests/integration/*.ps1`, contract/governance validation lanes, and optional `Invoke-ScriptAnalyzer` only if `.ps1` surfaces enter scope  
**Target Platform**: Specrew repositories run through PowerShell-capable GitHub Copilot / Spec Kit workflows on Windows, macOS, and Linux  
**Project Type**: PowerShell-based governance/extension product with Markdown-driven command-discovery surfaces  
**Performance Goals**: Users should be able to identify the active lifecycle-adjacent Spec Kit commands and their correct timing from standard Specrew discovery surfaces within the spec's 2-minute success criterion window  
**Constraints**: Keep lifecycle placement authoritative (`/speckit.checklist` before-plan, `/speckit.analyze` before-implement after complete `tasks.md`, `/speckit.taskstoissues` deferred); remain additive to existing governance; do not let placeholder `package.json` fixtures redefine repo architecture; stop at the plan boundary with no `tasks.md` or implementation edits  
**Scale/Scope**: One bounded brownfield planning slice covering discovery/docs, agent/prompt metadata, lifecycle contracts, validation evidence design, and canonical iteration-001 planning scaffold only

## Phase 1 Quality Planning

**Phase Scope**: `feature-054-discovery-and-lifecycle-guidance`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Explicit bounded custom composition using `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`, and `test-integrity@v1.0.0`  
**Bounded custom composition**: The active slice is a PowerShell/Markdown/YAML governance product rather than a Node application. Research resolved the planning unknowns by selecting `npx --yes markdownlint-cli` as the active stack-specific lint/analyzer for the current discovery surfaces, keeping `Invoke-ScriptAnalyzer` conditional for any later `.ps1` edits, and requiring repository-standard slash-command/governance integration lanes as stack-tooling evidence beyond baseline mechanical gates and checklist references.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `user-facing-discovery-docs` | `README.md`, `docs/user-guide.md`, `specs/054-activate-spec-surfaces/*.md` | `markdown-user-guidance` | The feature succeeds only if standard Specrew guidance surfaces `/speckit.checklist` and `/speckit.analyze` as first-class capabilities with consistent timing |
| `copilot-agent-and-prompt-surfaces` | `.github/agents/speckit.{plan,tasks,checklist,analyze,taskstoissues}.agent.md`, `.github/prompts/speckit.{checklist,analyze,taskstoissues}.prompt.md` | `copilot-command-discovery` | These are the host-facing discovery surfaces that teach users where commands belong in the lifecycle |
| `spec-kit-extension-and-hook-metadata` | `.specify/extensions.yml`, `.specify/extensions/specrew-speckit/**`, `extensions/specrew-speckit/**` | `spec-kit-extension-governance` | Lifecycle guidance must stay aligned with supported extension/hook surfaces instead of inventing new orchestration rules |
| `validation-and-contract-harness` | `tests/integration/slash-command-discovery.tests.ps1`, `tests/integration/slash-command-routing.tests.ps1`, `tests/integration/slash-command-coexistence.tests.ps1`, `tests/integration/lifecycle-boundary-sync.tests.ps1`, `tests/integration/validation-contract-lane.ps1`, `tests/README.md` | `powershell-governance-validation` | Discovery and lifecycle claims need executable evidence, not doc-only assertions |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| code-quality | required | Discovery-surface edits can still introduce stale references, contradictory command naming, or broken cross-links |
| design-quality-and-separation-of-concerns | required | Lifecycle positioning must remain in supported docs/prompt/extension surfaces without leaking into unrelated runtime behavior |
| verification-confidence | required | User-facing guidance needs executable proof across discovery, routing, and lifecycle-sync lanes |
| maintainability | required | First-class surfacing must be centralized enough that future lifecycle changes do not drift across docs and prompts |
| security | required | Boundary guidance must not imply hidden auto-advances or unsupported hook behavior that weakens human approval semantics |
| robustness | required | Users must receive proportional guidance for lightweight slices and clear deferral messaging when artifacts are not yet ready |
| concurrency-correctness | not-applicable | This slice changes discovery guidance and contracts, not concurrent state management |
| resiliency | not-applicable | No distributed service, retrying workflow, or failure-recovery subsystem is introduced in this planning slice |
| retry-idempotency-and-recovery | not-applicable | The feature does not add retry loops, replay semantics, or recovery automation beyond existing boundary guidance |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `feature-054-discovery-lifecycle-governance` | Custom bundle aligned to lifecycle-truthfulness, discovery consistency, and command-surface evidence |
| Mechanical Checks | `dead-field`, `anti-pattern`, `test-integrity` | Planned evidence path: `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` |
| Ecosystem Tools | `npx --yes markdownlint-cli README.md docs/user-guide.md .github/agents/*.md .github/prompts/*.md specs/054-activate-spec-surfaces/*.md`; `pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1`; `pwsh -NoProfile -File tests/integration/slash-command-routing.tests.ps1`; `pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1`; `pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1`; `pwsh -NoProfile -File tests/integration/validation-contract-lane.ps1` | `markdownlint-cli` is the active stack-specific lint/analyzer for this slice; no additional YAML-specific linter is required by current repo standards |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| dead-field | mechanical | `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` | planned |
| anti-pattern | mechanical | `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` | planned |
| test-integrity | mechanical | `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` | planned |
| stack-tooling-evidence | tooling | `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` plus the markdownlint + slash-command/lifecycle validation lanes listed above | planned |
| quality-lens-review | manual-evidence | `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` and `specs/054-activate-spec-surfaces/contracts/quality-governance-artifacts.md` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| concurrency-correctness | No concurrent workflow, shared mutable runtime, or scheduler behavior changes are planned | none |
| resiliency | Discovery/docs work does not introduce a service or recovery topology that needs resiliency modeling | none |
| retry-idempotency-and-recovery | The slice communicates lifecycle timing; it does not add retried side effects or recovery automation | none |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening execution and sign-off remain deferred until implementation is authorized.
- Dedicated bug-hunter execution remains deferred.
- Hardening-only work stays deferred unless a later approved slice explicitly brings it into scope.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation comparison remain deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `iteration-001 pre-implementation hardening for discovery truthfulness, lifecycle integrity, and deferred-command messaging`  
**Hardening Gate Artifact**: `specs/054-activate-spec-surfaces/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/054-activate-spec-surfaces/iterations/001/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | Discovery guidance must not imply hidden authority, unsupported hook execution, or bypass of human approval gates | `iterations/001/quality/hardening-gate.md` security and trust-boundary sections | required |
| Error handling and failure semantics | Users need truthful messaging when `/speckit.checklist` is optional, `/speckit.analyze` is not yet relevant, or `/speckit.taskstoissues` is deferred | `iterations/001/quality/hardening-gate.md`, `contracts/lifecycle-placement.md`, and `quickstart.md` | required |
| Retry and idempotency expectations | No retry/replay semantics are introduced by this slice; the hardening record should state that explicitly rather than invent work | `iterations/001/quality/hardening-gate.md` rationale section | not-applicable |
| Test-integrity targets | First-class surfacing claims must be backed by discovery/routing/lifecycle/contract evidence rather than prose alone | `iterations/001/quality/quality-evidence.md` and the planned integration command set | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required | Boundary messaging and hook/discovery surfaces influence trusted human-approval semantics | `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` |
| `robustness-baseline@v1.0.0` | required | The feature must stay truthful for lightweight slices, missing artifacts, and deferred-command scenarios | `specs/054-activate-spec-surfaces/iterations/001/quality/quality-evidence.md` |
| `test-integrity@v1.0.0` | required | Discovery claims are only credible if the existing slash-command and contract lanes remain authoritative | `specs/054-activate-spec-surfaces/iterations/001/quality/mechanical-findings.json` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest available | record at execution | none | No downgrade without explicit human approval at the later hardening boundary |

### Explicit Later Deferrals

- Full hardening execution evidence remains deferred until implementation/review boundaries are approved.
- Known-traps corpus additions and trap reapplication proof remain deferred until a dedicated hardening slice exists.
- Requested-versus-effective strongest-class execution evidence remains deferred until routed lens execution occurs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — pre-research scope is anchored to `spec.md` FR-001..FR-011, TG-001..TG-004, and SC-001..SC-005; post-design artifacts preserve the same authoritative placements with no new boundary claims.
- **Layering Gate**: PASS — planned work stays in supported Spec Kit/Specrew layers (`README.md`, `docs/`, `.github/`, `.specify/`, `extensions/`, `tests/`, and feature artifacts) and does not depend on unsupported host hacks.
- **Traceability Gate**: PASS — `research.md`, `data-model.md`, `contracts/discovery-surfaces.md`, `contracts/lifecycle-placement.md`, `contracts/quality-governance-artifacts.md`, and `quickstart.md` map directly to US1/US2/US3 and FR-001..FR-011.
- **Ownership Gate**: PASS — Spec Steward owns lifecycle truth, Planner owns before-plan/before-implement placement coherence, Reviewer owns additive-governance framing and validation confidence, and human approval remains mandatory before any later boundary.
- **Capacity Gate**: PASS — the plan stays within the spec's small brownfield slice (5-8 effort points) and uses the repository's standard iteration scaffold without authorizing implementation.
- **Drift/Reconciliation Gate**: PASS — lifecycle drift will be detected through contract parity, slash-command discovery/routing/coexistence lanes, and `lifecycle-boundary-sync.tests.ps1`; any conflict requires spec/plan reconciliation rather than silent prompt drift.
- **Verification Gate**: PASS — the planning package defines concrete markdownlint and PowerShell validation evidence, explicit quality gates, and post-design artifact consistency checks.

## Project Structure

### Documentation (this feature)

```text
specs/054-activate-spec-surfaces/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── discovery-surfaces.md
│   ├── lifecycle-placement.md
│   └── quality-governance-artifacts.md
├── iterations/
│   └── 001/
│       └── plan.md          # canonical planning scaffold
└── tasks.md                 # created later by /speckit.tasks (not part of this boundary)
```

### Source Code (repository root)

```text
README.md
docs/
└── user-guide.md

.github/
├── agents/
│   ├── speckit.checklist.agent.md
│   ├── speckit.analyze.agent.md
│   ├── speckit.plan.agent.md
│   ├── speckit.tasks.agent.md
│   └── speckit.taskstoissues.agent.md
└── prompts/
    ├── speckit.checklist.prompt.md
    ├── speckit.analyze.prompt.md
    └── speckit.taskstoissues.prompt.md

.specify/
├── extensions.yml
├── memory/constitution.md
└── extensions/specrew-speckit/

extensions/
└── specrew-speckit/

tests/
├── README.md
└── integration/
    ├── lifecycle-boundary-sync.tests.ps1
    ├── slash-command-coexistence.tests.ps1
    ├── slash-command-discovery.tests.ps1
    ├── slash-command-routing.tests.ps1
    └── validation-contract-lane.ps1
```

**Structure Decision**: Treat the repository as a PowerShell-driven Specrew/Spec Kit extension product with Markdown/YAML discovery surfaces. `package.json` may contain incidental fixtures, but the authoritative architecture for this slice comes from `README.md`, `docs/`, `.specify/`, `extensions/`, `scripts/`, and `tests/`.

## Complexity Tracking

No constitution violations require justification for this planning slice.
