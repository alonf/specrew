# Implementation Plan: Release Pipeline Hardening + Intake Roadmap Refresh

**Branch**: `049-pipeline-hardening-intake` | **Date**: 2026-05-27 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/049-pipeline-hardening-intake/spec.md`

## Summary

Feature 049 is now planned as an approved **four-iteration** roadmap. Iteration `001` remains closed and authoritative. The refreshed plan keeps Iteration `002` tightly focused on troubleshooting documentation and onboarding discoverability, keeps Iteration `003` as a deliberately small Proposal 063 `/speckit.specify` slice, and reserves Iteration `004` for the full Proposal 120 five-pillar bypass-detection scope, including Pillar 5 committed-tree versus working-tree-only-state enforcement. `tasks.md` is intentionally left unchanged by this refresh.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `scripts/specrew.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-start.ps1`, `Specrew.psd1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, mirrored `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/integration/publish-module-harness.tests.ps1`, `tests/integration/non-specrew-session-bypass.tests.ps1`, and the Spec Kit prompt/workflow surfaces for `/speckit.specify`  
**Storage**: Git-tracked Markdown/YAML/JSON/PowerShell assets under `docs/`, `scripts/`, `extensions/`, `.specify/`, `.github/`, and `specs/049-pipeline-hardening-intake/`  
**Testing**: PowerShell integration lanes plus governance validation, with documentation verification through manifest/link review and reviewer evidence for onboarding cross-references  
**Target Platform**: PowerShell-capable Specrew repositories on Windows and equivalent supported environments  
**Project Type**: Specrew governance/CLI monorepo with Spec Kit extension assets and mirrored deployment surfaces  
**Performance Goals**: Zero accepted closeouts may rely on production evidence absent from the cited committed tree; troubleshooting guidance must be discoverable from the primary onboarding path; the `/speckit.specify` slice should reduce downstream clarification churn without widening beyond the approved small slice  
**Constraints**: Preserve Iteration `001` as closed history, keep the roadmap aligned to TG-006 through TG-008, maintain mirror parity between `extensions/` and `.specify/extensions/`, do not modify `tasks.md`, and keep Iteration `004` fully faithful to Proposal 120's five pillars and SC-004  
**Scale/Scope**: Three remaining iterations after 17 SP already delivered in Iteration `001`; approved remaining capacity is 20-26 SP across Iterations `002`-`004`

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-roadmap-refresh-and-bounded-slice-planning`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Bounded custom composition based on the required `resolve-quality-profile.ps1` input, with no single preset claimed because repository-level signals are mixed  
**Bounded custom composition**: The resolver was consulted before finalizing this plan. It reported a bounded custom composition because repository-level signals span more than one preset family. For F-049, the authoritative planning posture stays anchored in Specrew's PowerShell governance, documentation, and review/validator surfaces rather than claiming a Node/React preset from incidental repo signals.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Troubleshooting + onboarding docs | `docs/troubleshooting.md`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `Specrew.psd1` | `docs-governance` | Iteration `002` must deliver the durable doc, manifest registration, onboarding cross-links, and the `specrew update` vs `Update-Module Specrew` clarification |
| Specify intake surfaces | `.github/agents/speckit.specify.agent.md`, `.github/prompts/speckit.specify.prompt.md`, `.specify/workflows/speckit/workflow.yml`, related Spec Kit prompt/runtime surfaces | `specify-governance` | Iteration `003` is a deliberately small `/speckit.specify` persona-driven intake slice and must remain bounded to approved Proposal 063 intent |
| Governance validation surfaces | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, mirrored `.specify/extensions/**`, iteration review/state artifacts | `powershell-governance` | Iteration `004` must implement all five bypass-detection pillars, especially Pillar 5 closeout enforcement |
| Regression lanes | `tests/integration/publish-module-harness.tests.ps1`, `tests/integration/non-specrew-session-bypass.tests.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | `powershell-test-fixtures` | The remaining roadmap must stay fail-closed with deterministic regression evidence instead of prose-only confidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `code-quality` | `required` | The remaining iterations touch docs, prompts, validator logic, and closeout enforcement; the plan must keep the quality bundle explicit and reviewable |
| `design-quality-and-separation-of-concerns` | `required` | F-049 spans docs, specify prompts, and validator logic; the roadmap must preserve layering instead of blending unrelated surfaces |
| `verification-confidence` | `required` | SC-004 is fail-closed and must be backed by deterministic validator coverage, not only manual confidence |
| `maintainability` | `required` | Iteration `004` changes governance logic in mirrored script trees and needs explicit parity expectations |
| `security` | `required` | Governance validation, boundary enforcement, and accepted-review provenance are integrity-sensitive surfaces |
| `robustness` | `required` | Troubleshooting and bypass-detection work both exist to make failure behavior explicit and recoverable |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` | Carry forward the resolver's bounded custom composition instead of claiming a single preset |
| Mechanical Checks | `dead-field`, `anti-pattern`, `test-integrity` | Evidence remains in `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/mechanical-findings.json` when execution begins |
| Ecosystem Tools | `pwsh -NoProfile -File .\tests\integration\publish-module-harness.tests.ps1`, `pwsh -NoProfile -File .\tests\integration\non-specrew-session-bypass.tests.ps1`, `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` | These commands are the concrete verification baseline for the approved remaining slices |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/mechanical-findings.json` | `planned` |
| `anti-pattern` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/mechanical-findings.json` | `planned` |
| `test-integrity` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/mechanical-findings.json` | `planned` |
| `stack-tooling-evidence` | `tooling` | `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/quality-evidence.md` | `planned` |
| `quality-lens-review` | `manual-evidence` | `specs/049-pipeline-hardening-intake/iterations/<NNN>/quality/quality-evidence.md` | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | No approved remaining slice introduces material shared-state, realtime, or concurrency-heavy behavior; the feature is about docs, intake flow, and governance validation | Revisit only if a later iteration widens into concurrent runtime orchestration |
| `resiliency-semantics-review` | The remaining slices do not add retry/reconnect infrastructure; robustness remains covered by baseline governance and troubleshooting analysis | None |
| `retry-idempotency-review` | Retry/idempotency is not a material primary behavior in Iterations `002`-`004`; where non-applicability matters, it will be stated explicitly in the hardening gate | None |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening-gate sign-off remains a later iteration-boundary requirement, not proof that has already happened.
- Dedicated bug-hunter execution and strongest-class routing evidence remain deferred until the approved execution slice invokes them.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless a later approved slice explicitly widens scope.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `iteration-004-governance-closeout-hardening`  
**Hardening Gate Artifact**: `specs/049-pipeline-hardening-intake/iterations/004/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/049-pipeline-hardening-intake/iterations/004/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | Iteration `004` changes boundary-validation trust signals and accepted-review provenance; expected controls must be explicit before implementation | `specs/049-pipeline-hardening-intake/iterations/004/quality/hardening-gate.md` | `required` |
| Error handling and failure semantics | Proposal 120 must distinguish warnings from blocking failures, especially for Pillar 5 production-file mismatches | `specs/049-pipeline-hardening-intake/iterations/004/quality/hardening-gate.md` + `review.md` evidence | `required` |
| Retry and idempotency expectations | The hardening gate should explicitly record why retry/idempotency is not a material risk dimension for this feature instead of leaving the omission implicit | `specs/049-pipeline-hardening-intake/iterations/004/quality/hardening-gate.md` | `not-applicable` |
| Test-integrity targets | SC-004 depends on deterministic fixture coverage proving that accepted review evidence cannot cite production files missing from the cited tree | Iteration `004` quality evidence + `tests/integration/non-specrew-session-bypass.tests.ps1` | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | `required` | Governance-closeout integrity is a materially reviewed baseline dimension for Proposal 120 | `specs/049-pipeline-hardening-intake/iterations/004/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | `required` | Warning-vs-fail semantics and boundary-fallback behavior must stay explicit | `specs/049-pipeline-hardening-intake/iterations/004/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | `required` | Iteration `004` only closes cleanly if validator/test evidence proves fail-closed behavior for all five pillars | `specs/049-pipeline-hardening-intake/iterations/004/quality/lenses/test-integrity.md` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` | Record when execution happens | Explicit approved lower-tier override required before any downgrade takes effect | Planning publishes the routing baseline only; execution-time evidence remains deferred until the review path runs |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence remains deferred until the approved implementation/review slice authorizes it.
- Known-traps corpus additions and trap reapplication remain deferred until the dedicated quality slice is active.
- Requested-versus-effective routing evidence remains deferred until routed lens execution exists.
- Quality-drift comparison and reference-implementation checks remain deferred unless separately approved.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Scope maps directly to the refreshed spec, especially TG-006 through TG-008, FR-016 through FR-022, and SC-004.
- **Layering Gate**: PASS — The plan keeps documentation, Spec Kit intake surfaces, and governance-validator logic in their correct Specrew layers.
- **Traceability Gate**: PASS — Each remaining iteration is explicitly tied to the approved FR/SC set: Iteration `002` to FR-006/007/015/016/017, Iteration `003` to FR-008/009/010/011, and Iteration `004` to FR-018/019/020/021/022 plus SC-004.
- **Ownership Gate**: PASS — Spec Steward owns scope truth, Planner owns the roadmap refresh and iteration framing, Implementer owns docs/prompt/script changes, and Reviewer owns cross-reference, validator, and closeout-evidence verification.
- **Capacity Gate**: PASS — The roadmap preserves Iteration `001` actuals and keeps the approved remaining 20-26 SP split visible instead of silently collapsing or expanding slices.
- **Drift/Reconciliation Gate**: PASS — The plan explicitly reconciles the stale three-iteration plan with the approved four-iteration roadmap and keeps Proposal 120's Pillar 5 requirement visible.
- **Verification Gate**: PASS — The validation path is explicit through docs/manifest review, specify-flow proof, integration tests, and fail-closed governance validation.

## Project Structure

### Documentation (this feature)

```text
specs/049-pipeline-hardening-intake/
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── pipeline-hardening-intake.md
├── iterations/
│   ├── 001/
│   │   └── retro.md                  # closed and authoritative
│   ├── 002/                          # planned remaining slice
│   ├── 003/                          # planned remaining slice
│   └── 004/                          # planned remaining slice
└── tasks.md                          # intentionally not modified by this refresh
```

### Source Code (repository root)

```text
docs/
├── getting-started.md
├── troubleshooting.md                # planned in Iteration 002
└── user-guide.md

scripts/
├── specrew.ps1
├── specrew-start.ps1
└── specrew-update.ps1

extensions/specrew-speckit/
└── scripts/
    ├── shared-governance.ps1
    └── validate-governance.ps1

.specify/
├── workflows/speckit/workflow.yml
└── extensions/specrew-speckit/
    └── scripts/
        └── validate-governance.ps1

.github/
├── agents/speckit.specify.agent.md
└── prompts/speckit.specify.prompt.md

tests/
├── Dockerfile.publish-test
└── integration/
    ├── publish-module-harness.tests.ps1
    └── non-specrew-session-bypass.tests.ps1
```

**Structure Decision**: Keep the feature anchored in one Specrew governance monorepo. Iteration `002` is docs + manifest wiring, Iteration `003` is a bounded `/speckit.specify` prompt/workflow slice, and Iteration `004` is validator/governance enforcement with mirrored extension parity.

## Phase 0: Research Decisions

The decisions that drive this roadmap refresh are:

1. Treat F-049 as an approved **four-iteration** feature and preserve Iteration `001` as closed history rather than reopening it.
2. Keep Iteration `002` intentionally narrow: `docs/troubleshooting.md`, onboarding cross-references, `specrew update` versus `Update-Module Specrew` clarification, and the Shape-5 durability lesson.
3. Keep Iteration `003` as a small, bounded Proposal 063 slice limited to persona-driven `/speckit.specify` intake rather than widening into the full proposal footprint.
4. Keep Iteration `004` anchored to Proposal 120 at main commit `4da969bc`, preserving all five pillars and especially Pillar 5 committed-tree enforcement.
5. Use the consulted quality-profile resolver output as a planning input only: bounded custom composition, explicit baseline lenses, and no implied hardening execution before the approved iteration boundary.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) remains the feature-level model reference for intake sessions and pipeline verification state.
- [contracts/pipeline-hardening-intake.md](contracts/pipeline-hardening-intake.md) remains the contract surface for publish-harness and specify interactions; implementation follow-through must stay consistent with the refreshed roadmap.
- [quickstart.md](quickstart.md) remains the execution guide, but the authoritative roadmap is this refreshed four-iteration plan.

### Approved Iteration Roadmap

| Iteration | Status | Scope | Requirement Alignment | Capacity | Notes |
| --- | --- | --- | --- | --- | --- |
| `001` | `closed` | Docker pre-publish harness + release hardening regressions already delivered | FR-001..FR-005, FR-012..FR-014, SC-001 | 17 SP actual | Preserve as closed history; do not reopen in this plan refresh |
| `002` | `planned` | Troubleshooting guide, onboarding cross-links, `specrew update` vs `Update-Module Specrew` clarification, and Shape-5 lesson | FR-006, FR-007, FR-015, FR-016, FR-017, SC-002 | 4-6 SP | Directly addresses the Iteration `001` retro's Shape-5 documentation/process lesson |
| `003` | `planned` | Proposal 063 persona-driven `/speckit.specify` intake **small slice** only | FR-008, FR-009, FR-010, FR-011, SC-003 | 10 SP | Bound the slice to persona selection, intake catalog shape, and Mode A/B/C behavior; do not silently pull in the full proposal |
| `004` | `planned` | Proposal 120 full five-pillar bypass detection, including Pillar 5 committed-tree enforcement | FR-018, FR-019, FR-020, FR-021, FR-022, SC-004 | 6-10 SP | Must preserve all five pillars exactly as approved; Pillar 5 is fail-closed for production-file mismatches |

### Planned Implementation Slices

| Slice | Scope | Affected Surfaces | Outcome |
| --- | --- | --- | --- |
| Slice A | Iteration `002` documentation hardening | `docs/troubleshooting.md`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `Specrew.psd1`, `scripts/specrew.ps1` wording alignment where needed | Recovery guidance becomes durable, discoverable, and explicit about project refresh vs installed-module upgrade |
| Slice B | Iteration `003` bounded persona-intake MVP | `.github/agents/speckit.specify.agent.md`, `.github/prompts/speckit.specify.prompt.md`, `.specify/workflows/speckit/workflow.yml`, related specify runtime surfaces | `/speckit.specify` gains the approved persona-driven small slice without widening into unrelated Proposal 063 triggers |
| Slice C | Iteration `004` governance bypass detection | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1`, mirrored `.specify/extensions/**`, `tests/integration/non-specrew-session-bypass.tests.ps1`, iteration review/state artifacts | All five approved bypass-detection pillars are enforced, including Pillar 5 blocking closeout on working-tree-only production evidence |

### Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\publish-module-harness.tests.ps1
pwsh -NoProfile -File .\tests\integration\non-specrew-session-bypass.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

### Traceability Notes for the Requested Refresh

- Iteration `002` now explicitly carries FR-016 and FR-017, not just the base troubleshooting doc creation.
- Iteration `003` is explicitly framed as a **small slice** of Proposal 063 so the roadmap stays inside the approved scope.
- Iteration `004` is explicitly framed as the **full five-pillar** Proposal 120 delivery, including the Pillar 5 requirement that directly supports SC-004.
- `tasks.md` remains untouched and may still reflect older decomposition until a later `/speckit.tasks` refresh is intentionally approved.

## Post-Design Constitution Re-check

- **Spec Authority Gate**: PASS — The design stays aligned with the refreshed spec and user-approved four-iteration roadmap.
- **Layering Gate**: PASS — Docs, prompt/workflow, and validator surfaces remain intentionally separated by iteration.
- **Traceability Gate**: PASS — The roadmap now makes FR-016..FR-022 and SC-004 visibly traceable to Iterations `002`-`004`.
- **Ownership Gate**: PASS — Human oversight remains explicit at planning approval, pre-implementation iteration approval, review, and any Pillar 5 failure remediation.
- **Capacity Gate**: PASS — The plan preserves 17 SP actuals in Iteration `001` and keeps the remaining 20-26 SP budget visible.
- **Drift/Reconciliation Gate**: PASS — The stale plan has been reconciled to the approved four-iteration scope without rewriting closed history.
- **Verification Gate**: PASS — Deterministic validation commands and artifact expectations are explicit for the remaining slices.

## Complexity Tracking

No constitution exceptions are required for this roadmap refresh.
