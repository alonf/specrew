# Implementation Plan: Minimal Design Alternatives / Architecture Intake Gate

**Branch**: `140-design-analysis-gate`  
**Date**: 2026-06-02  
**Spec**: file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/spec.md  
**Input**: Feature specification from file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/spec.md, Proposal 137, and human-approved planning defaults from the clarify-to-plan boundary.

## Summary

This first slice adds a narrow design-analysis gate before plan for new substantive iterations. The implementation will create a per-iteration `design-analysis.md` decision artifact, require at least two meaningful alternatives, require a populated Crew recommendation, and prevent the active feature/iteration from advancing into plan until the human decision is recorded.

The selected implementation approach is deliberately narrow:

- Add a small design-analysis artifact helper for scaffolding and validation.
- Add plan-boundary enforcement that checks the active iteration's design-analysis artifact before `plan` can sync.
- Update generated lifecycle guidance so future coordinators stop at `clarify/before-plan -> design-analysis -> plan`.
- Add focused tests for artifact creation, required sections, recommendation presence, human decision presence, and compatibility behavior.

Broad validator enforcement across all existing or in-flight projects, full multi-host slash-command deployment, full slice-type catalog behavior, Unix install/wrapper changes, and beta/stable publishing remain deferred.

## Context Load

| Source | Loaded Context | Planning Effect |
| --- | --- | --- |
| Proposal 137 | Specrew needs a pre-plan alternatives gate because design decisions currently surface too late. | Add the design-analysis stop and durable decision artifact, but keep this slice smaller than the full six-pillar proposal. |
| Clarified spec | `design-analysis.md` is per-iteration under `specs/<feature>/iterations/<NNN>/design-analysis.md`. | Plan uses iteration-scoped artifact creation and validation. |
| Human planning defaults | Use narrow active-iteration enforcement; defer broad validator enforcement and full multi-host deployment; preserve compatibility; exclude Unix surfaces. | Plan avoids historical hard-fails and limits enforcement to the active new substantive iteration path. |
| Before-plan quality profile | `quality-profile.react-spa-public.v1` with security, robustness, test-integrity, maintainability, and concurrency-correctness planning dimensions. | Plan includes focused tests, explicit compatibility behavior, and clear evidence for enforcement. |
| Existing lifecycle surfaces | Sync commands exist for canonical boundaries; start prompt generation and tests already cover boundary policy and lifecycle guidance. | Extend the smallest existing lifecycle/prompt/sync surfaces needed for the new gate. |

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: Git, `.specrew/start-context.json`, `.squad/decisions.md`, Spec Kit extension command metadata, Specrew boundary sync, existing PowerShell tests  
**Storage**: File-based repository state under `.specrew/`, `.squad/`, `scripts/`, `extensions/`, `.specify/extensions/`, `tests/`, and `specs/`  
**Testing**: Focused PowerShell tests plus existing governance validation  
**Target Platform**: Windows-hosted Specrew runtime and downstream project lifecycle flows  
**Project Type**: Specrew lifecycle governance/tooling  
**Constraints**: Do not touch Unix install/wrapper surfaces; do not publish beta/stable; avoid broad historical enforcement; stop again at plan -> tasks

## Branch and State Hygiene

The worktree contains unrelated edits from prior/runtime activity. They must not be staged for Feature 140 implementation unless a file becomes a required Feature 140 artifact.

| Status Class | Paths / Evidence | Planned Handling |
| --- | --- | --- |
| Existing unrelated runtime/session edits | `.codex/agents/*.toml`, `.github/agents/squad.agent.md`, `.squad/casting/registry.json`, `.squad/config.json`, `.squad/decisions.md`, `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml`, `.cursor/`, `.specrew/version-check-cache.json` | Leave unstaged unless a later task proves a specific change is required for Feature 140. |
| Feature 140 planning artifacts | `specs/140-design-analysis-gate/*` | Stage and commit as the plan boundary evidence. |
| Future implementation edits | Lifecycle helper, prompt generation, sync enforcement, command metadata, tests, docs | Stage only feature-scoped changes with focused boundary commits. |

## Architecture Decision

### Options Considered

| Option | Approach | Upside | Downside | Decision |
| --- | --- | --- | --- | --- |
| A: Prompt-only discipline | Teach coordinators to write `design-analysis.md`, with no runtime enforcement. | Cheapest and low risk. | Does not satisfy the requirement to block plan-boundary advancement when the decision is missing. | Rejected. |
| B: Helper plus plan-sync enforcement | Add a small artifact validator/helper and call it from the active plan-boundary sync path; update prompt/workflow guidance and focused tests. | Meets the first-slice enforcement goal with limited blast radius and clear compatibility behavior. | Requires touching boundary sync internals and prompt guidance. | Selected. |
| C: Full Proposal 137 workflow/slash-command deployment | Add full `/speckit.design-analysis` multi-host command, workflow hooks, broad validator rules, and slice-type catalog integration. | Most complete long-term model. | Exceeds first-slice scope and risks breaking existing/in-flight projects. | Deferred. |

### Selected Pattern

Use a layered governance helper pattern:

1. `DesignAnalysisArtifact` helper owns artifact schema checks and simple substantive/trivial applicability.
2. Boundary sync owns hard blocking for the active `plan` boundary only.
3. Prompt/workflow guidance owns coordinator behavior and artifact authoring instructions.
4. Tests own regression coverage for missing artifact, missing sections, missing recommendation, missing decision, and compatibility.

This keeps the gate visible and enforceable without converting Proposal 137 into a broad rollout.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: `quality-profile.react-spa-public.v1`  
**Selected Preset**: `react-spa-public@v1.0.0`

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Lifecycle prompt generation | `scripts/specrew-start.ps1` | PowerShell prompt generator | Must describe the new design-analysis stop and stop order truthfully. |
| Boundary sync enforcement | `scripts/internal/sync-boundary-state.ps1`, wrapper command surfaces | PowerShell lifecycle state | Must block active `plan` sync when design-analysis evidence is missing. |
| Artifact helper | New or existing PowerShell helper under `scripts/internal/` | PowerShell governance helper | Keeps required-section checks reusable and testable. |
| Extension command/workflow metadata | `extensions/specrew-speckit/commands/`, `.specify/extensions/specrew-speckit/commands/`, extension/workflow metadata if needed | Markdown/YAML command metadata | May expose the stop and sync guidance without full broad multi-host deployment. |
| Tests and fixtures | `tests/unit/`, `tests/integration/fixtures/` | PowerShell tests | Proves enforcement and compatibility without relying on manual review. |
| Planning docs | `specs/140-design-analysis-gate/` | Markdown artifacts | Reviewers need the public contract, data model, quickstart, and diagrams before task approval. |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Governance integrity | required | The feature changes lifecycle stops and must not create another silent bypass. |
| Design quality and separation of concerns | required | Artifact validation should not be buried as ad hoc string checks inside unrelated prompt text. |
| Verification confidence | required | Tests must prove blocking behavior and not just artifact creation. |
| Maintainability | required | The first-slice helper must be simple enough to extend later for full Proposal 137. |
| Security | required | Human verdict evidence is authorization-adjacent and must not be fabricated. |
| Robustness | required | Missing or malformed artifacts must fail closed for active plan advancement, with actionable errors. |
| Concurrency correctness | required | Boundary sync touches shared state and must preserve atomic state behavior for active boundaries. |
| Retry/idempotency | not-applicable | The first slice is file-state validation and boundary gating, not a retry workflow. |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `react-spa-phase1` from before-plan readiness |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | Existing PowerShell test lane and governance validator |
| Manual Evidence | This plan, review artifacts, implementation review gap ledger |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | mechanical | `specs/140-design-analysis-gate/iterations/001/quality/mechanical-findings.json` after implementation |
| `anti-pattern` | mechanical | `specs/140-design-analysis-gate/iterations/001/quality/mechanical-findings.json` after implementation |
| `test-integrity` | mechanical | Focused tests must include negative cases for missing recommendation and missing human decision |
| `stack-tooling-evidence` | tooling | `specs/140-design-analysis-gate/iterations/001/quality/quality-evidence.md` after implementation |
| `quality-lens-review` | manual-evidence | Review gap ledger classifies implemented/enforced/observable/documented |
| `concurrency-correctness-review` | manual-evidence | Review confirms boundary sync state updates remain atomic and scoped |

### Explicit Deferrals

- Broad validator enforcement across existing or in-flight projects is deferred.
- Full multi-host `/speckit.design-analysis` slash-command deployment is deferred unless an existing low-risk command pattern is reusable without expanding scope.
- Full slice-type catalog integration is deferred; this slice uses only a simple substantive/trivial applicability rule.
- Unix install, shell wrapper, bootstrap, beta publish, and stable publish surfaces are out of scope.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: First-slice hardening for lifecycle state, artifact validation, and compatibility only.  
**Hardening Gate Artifact**: `specs/140-design-analysis-gate/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/140-design-analysis-gate/iterations/001/quality/trap-reapplication.md`

| Focus Area | Why It Matters | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | Human decision evidence authorizes plan advancement, so fabricated or missing approvals must be blocked. | Hardening gate plus tests for missing human decision. | required |
| Error handling and failure semantics | Missing or malformed design-analysis evidence must return actionable blocking output. | Negative tests and quickstart edge cases. | required |
| Retry/idempotency expectations | No retry workflow is introduced; explain non-applicability in hardening gate. | Hardening gate not-applicable rationale. | not-applicable |
| Test-integrity targets | The feature is governance-heavy, so negative fixtures are required. | Unit/integration tests for artifact and plan-blocking behavior. | required |

## Capacity Model

Iteration capacity is 20 story_points with no overcommit tolerance. The planned slice is 18 story_points and fits one iteration.

| Work Item | Requirement Refs | Owner Role | Effort |
| --- | --- | --- | --- |
| Design-analysis artifact helper and schema checks | FR-003, FR-004, FR-005, FR-006, FR-007, FR-013, FR-014, FR-015 | Implementer | 4 |
| Active plan-boundary enforcement and decision recording checks | FR-009, FR-010, FR-011, FR-012, FR-017 | Implementer | 4 |
| Lifecycle prompt/workflow guidance for the new stop | FR-001, FR-002, FR-008, FR-018 | Spec Steward, Implementer | 3 |
| Compatibility documentation and non-breaking default behavior | FR-018, FR-021, SC-012, SC-013 | Planner, Spec Steward | 2 |
| Focused tests and fixtures | FR-013, FR-014, FR-015, FR-016, FR-017 | Implementer, Reviewer | 4 |
| Review evidence and gap ledger updates | TG-006, SC-010, SC-011 | Reviewer | 1 |

**Total**: 18 story_points  
**Capacity Status**: ok  
**Suggested Deferrals if Scope Grows**: Full multi-host command deployment, broad validator rollout, and full slice-type catalog integration remain the first deferral candidates.

### Phase Baseline

| Phase | Planned Effort |
| --- | --- |
| Discovery/spike | 1 |
| Implementation | 9 |
| Tests | 5 |
| Review | 2 |
| Expected rework | 1 |

## Constitution Check

- **Spec Authority Gate**: PASS - the plan follows file:///C:/Dev/Specrew-design-analysis/specs/140-design-analysis-gate/spec.md and the human-approved planning defaults.
- **Lifecycle Boundary Gate**: PASS - planning is authorized only through `plan`; the next stop is `plan -> tasks`.
- **Scope Gate**: PASS - full Proposal 137 rollout, broad validator enforcement, full slice-type catalog, Unix wrapper surfaces, and release publishing remain out of scope.
- **Traceability Gate**: PASS - every FR maps to planned implementation and test/evidence surfaces below.
- **Compatibility Gate**: PASS - existing and in-flight projects must not hard-fail unexpectedly because they lack historical design-analysis artifacts.
- **Quality Gate**: PASS - before-plan quality output is embedded and negative tests are planned for enforcement behavior.

## Implementation Strategy

1. Add a minimal design-analysis artifact contract and helper that can scaffold or validate `specs/<feature>/iterations/<NNN>/design-analysis.md`.
2. Implement the simple applicability rule:
   - require the gate for new substantive feature iterations, architectural refactors, lifecycle/governance changes, and enabler work
   - skip or warn for trivial, doc-only, and clearly small bug-fix/chore work
   - never hard-fail historical/in-flight features solely because they predate the artifact
3. Add active plan-boundary enforcement so `plan` cannot sync for the active new substantive iteration unless:
   - `design-analysis.md` exists
   - required sections exist
   - at least Simplest and Reasonable options exist
   - the Crew recommendation is populated
   - Human Decision records chosen option, human reason or modifications, and commit hash
4. Update lifecycle prompt and command/workflow guidance so coordinators produce the design-analysis artifact between clarify/before-plan and plan.
5. Add focused tests and fixtures for valid artifact, missing artifact, missing sections, missing recommendation, missing human decision, conditional By-the-book behavior, and compatibility.
6. Document deferred broad validator and slash-command rollout so future iterations have a clear compatibility path.

## FR Traceability Matrix

| Requirement | Implementation Surface | Planned Tests / Evidence |
| --- | --- | --- |
| FR-001 | Generated lifecycle guidance and command/workflow metadata. | Prompt/workflow text assertion includes design-analysis before plan. |
| FR-002 | Applicability helper or boundary enforcement rule. | Fixtures for substantive required and trivial skipped/warned cases. |
| FR-003 | Artifact helper/scaffolder. | Valid artifact fixture created at `iterations/001/design-analysis.md`. |
| FR-004 | Artifact validation schema. | Missing-section fixture fails. |
| FR-005 | Alternative parser/checker. | One-option fixture fails; two-option fixture passes. |
| FR-006 | Conditional By-the-book rule in prompt/artifact validation. | Two-option artifact can pass when it states why By-the-book is not distinct. |
| FR-007 | Option-field validation. | Fixture missing approach/pattern/quality/effort/reversibility/trade-offs/diagram fails. |
| FR-008 | Recommendation section validation. | Missing or placeholder recommendation fixture fails. |
| FR-009 | Verdict guidance and artifact decision shape. | Human decision fixture requires `approved for plan with Option <X>` or equivalent. |
| FR-010 | Plan-boundary sync enforcement. | Plan sync fixture fails until artifact, recommendation, and decision are present. |
| FR-011 | Human Decision validation. | Fixture checks chosen option, reason/modifications, and commit hash. |
| FR-012 | Plan guidance and enforcement output. | Plan artifact references selected option as authoritative input. |
| FR-013 | Artifact tests. | Focused test creates/locates artifact for substantive feature. |
| FR-014 | Section tests. | Missing required sections fail. |
| FR-015 | Alternative tests. | Missing alternatives/fields fail. |
| FR-016 | Recommendation tests. | Placeholder recommendation fails. |
| FR-017 | Boundary blocking tests. | Plan-boundary advancement fails before decision and passes after decision. |
| FR-018 | Scope guards in plan/docs/tests. | Tests or review verify no broad validator/full command rollout unless explicitly included. |
| FR-019 | Implementation scope review. | Review confirms Unix install/wrapper paths untouched. |
| FR-020 | Release scope review. | Review confirms no beta/stable publish changes. |
| FR-021 | Compatibility docs and enforcement rule. | Compatibility fixture proves historical/in-flight feature does not hard-fail unexpectedly. |

## Test Plan

| Test Area | Positive Coverage | Negative Coverage |
| --- | --- | --- |
| Artifact creation | Substantive fixture creates `iterations/001/design-analysis.md`. | Missing artifact blocks active plan sync. |
| Required sections | Valid artifact contains problem framing, decision points, alternatives, Crew recommendation, Human Decision. | Missing section fails validation. |
| Alternatives | Simplest and Reasonable options pass with required fields and diagrams. | One option, missing option fields, or fake empty option fails. |
| By-the-book conditionality | Two-option artifact passes when it states By-the-book is not meaningfully distinct. | Required distinct By-the-book case without Option C fails if fixture marks it necessary. |
| Recommendation | Crew recommendation names one option with rationale. | Empty or placeholder recommendation fails. |
| Human decision | Chosen option, reason/modifications, and commit hash pass. | Missing chosen option or commit hash blocks plan. |
| Plan-boundary enforcement | Active new substantive iteration advances after valid decision. | Active new substantive iteration cannot advance to plan before valid decision. |
| Compatibility | Existing/in-flight or legacy feature without artifact warns/skips per compatibility rule. | New substantive iteration without artifact still blocks. |
| Scope guards | Unix wrapper/install and beta/stable publish paths remain untouched. | Review flags any accidental edit to excluded surfaces. |

Expected commands during implementation/review:

```powershell
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
pwsh -File tests/integration/boundary-sync-atomic.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

Exact file names may be adjusted to match existing test naming, but the coverage above must remain intact.

## Review Output Requirements

Review must classify the design-analysis gate behavior as:

- implemented
- enforced
- observable
- documented

Any missing dimension must be fixed or explicitly sent back before implementation closeout.

## Project Structure

### Documentation and Planning Artifacts

```text
specs/140-design-analysis-gate/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── review-diagrams.md
└── contracts/
    └── design-analysis-gate.md
```

### Expected Implementation Surfaces

```text
scripts/
├── specrew-start.ps1
└── internal/
    ├── design-analysis-gate.ps1
    └── sync-boundary-state.ps1

extensions/specrew-speckit/
└── commands/

.specify/extensions/specrew-speckit/
└── commands/

tests/
├── unit/
└── integration/
```

## Complexity Tracking

No constitutional violations are planned. Complexity is controlled by enforcing only the active new substantive iteration path and by documenting broad rollout deferrals instead of implementing them in this slice.

## Out of Scope

- Full Proposal 137 implementation
- Broad validator enforcement across all existing or in-flight projects
- Full multi-host slash-command deployment unless a low-risk existing command pattern is reused without expanding scope
- Full slice-type catalog
- Unix install, shell wrapper, and bootstrap files
- Beta or stable publishing
