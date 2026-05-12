# Implementation Plan: Validator Hardening

**Branch**: `013-validator-hardening` | **Date**: 2026-05-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/013-validator-hardening/spec.md`

## Summary

This plan closes six governance-validator rigor gaps exposed during Specrew dogfooding. All six gaps are addressed mechanically inside the existing `validate-governance.ps1` / `shared-governance.ps1` PowerShell surface, without introducing model-based review. The work is split into two bounded iterations aligned to the capacity model in the spec:

- **Iteration 1**: canonical iteration `state.md` schema enforcement (FR-001), canonical hardening-gate concern enforcement (FR-002), graceful structured-error reporting (FR-005), canonical contract documents (FR-009), and Iteration-1 fixture/test coverage (FR-008 slice 1).
- **Iteration 2**: approval-evidence reuse detection (FR-003), over-claim / closeout-evidence enforcement (FR-004), bookkeeping classifier for `.github/copilot-instructions.md` (FR-006), known-traps corpus graduation (FR-007), Iteration-2 fixture/test coverage (FR-008 slice 2), and additive backward-compatibility assurance (FR-010).

The existing validator command surface, exit-code conventions, and PASS/FAIL format are preserved throughout.

**Implementation status (2026-05-12)**: Feature 013 is complete. Iteration 001, the canonical-schema and graceful-error slice, and Iteration 002, the approval-reuse / over-claim / bookkeeping-classifier slice, are both closed. The shipped feature now enforces canonical iteration state schema, canonical hardening-gate concern order, structured FAIL output, sibling-iteration approval-reuse detection, iteration closeout over-claim detection, and `.github/copilot-instructions.md` bookkeeping classification while preserving the existing validator CLI surface.

## Technical Context

**Language/Version**: PowerShell 7.x  
**Primary Dependencies**: `extensions/specrew-speckit/scripts/validate-governance.ps1`, `shared-governance.ps1`, `scripts/specrew-start.ps1`; Git working-tree inspection via `git status --porcelain`  
**Storage**: Git-tracked Markdown governance artifacts (`specs/*/iterations/*/state.md`, `quality/hardening-gate.md`, `plan.md`, `review.md`, `retro.md`, `.github/copilot-instructions.md`, `.specrew/quality/known-traps.md`)  
**Testing**: PowerShell integration tests under `tests/integration/`; scaffold-replay-style fixture assertions  
**Target Platform**: PowerShell-capable Specrew repositories on Windows (PowerShell 7+) and equivalent supported environments  
**Project Type**: Spec Kit extension + Specrew governance monorepo  
**Performance Goals**: Deterministic, fail-closed validation pass; no unhandled exceptions reaching users; structured FAIL output for every violation  
**Constraints**: Additive-only changes to existing validator surface; no new model-based review; grandfathering of pre-rollout iterations; dirty-tree check scoped to iteration-directory canonical artifacts only  
**Scale/Scope**: Six validator rules across two bounded iterations; test fixture coverage for each new rule

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `phase-1-iteration-1-slice` (canonical schema + graceful errors)  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom PowerShell governance composition; no recognized preset covers a Specrew-internal validator extension exactly  
**Bounded custom composition**: PowerShell governance scripts + Markdown fixture assertions + deterministic integration tests. No frontend, no API surface, no model inference. All unknowns are resolved.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Validator core | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `shared-governance.ps1` | `powershell-governance` | All new rules live here; this is the primary implementation surface |
| Bookkeeping classifier | `scripts/specrew-start.ps1`, new helper e.g. `Test-CopilotInstructionsChangeType.ps1` | `powershell-governance` | FR-006 classifier must be a reusable helper consumed by `specrew-start.ps1` |
| Contract artifacts | `specs/013-validator-hardening/contracts/iteration-state-schema.md`, `contracts/hardening-gate-concerns.md` | `governance-contract` | FR-009 canonical schema/concern contract; must exist before enforcement lands |
| Regression tests | `tests/integration/validator-hardening-*.ps1`, `tests/integration/fixtures/013-*/**` | `powershell-test-fixtures` | Fixture-based fail-closed proof for each new rule |
| Known-traps corpus | `.specrew/quality/known-traps.md` | `governance-corpus` | FR-007 graduation updates mark rows as validator-enforced |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Governance drift | `required` | New validator rules must not silently change existing PASS/FAIL behavior for compliant artifacts |
| Error handling and failure semantics | `required` | The feature's core goal is structured FAIL output; exception leakage is a first-class risk |
| Test integrity | `required` | Each rule must be provable with violating and compliant fixtures |
| Backward compatibility | `required` | FR-010: existing command surface and exit codes must be preserved |
| Security surface | `not-applicable` | Validator reads local Git-tracked files; no network surface, no user-supplied untrusted input paths beyond project root |
| Retry and idempotency | `not-applicable` | The validator is a stateless read-only pass; no state is written and re-runs are idempotent by design |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `quality-bundle.powershell-governance-validator-hardening.v1` | Scoped to PowerShell governance scripts, Markdown contract fixtures, and integration test lanes |
| Mechanical Checks | `canonical-field-check`, `concern-order-check`, `structured-fail-format`, `fixture-coverage-completeness` | Evidence lives in `contracts/`, iteration plans, and named test fixture directories |
| Ecosystem Tools | `pwsh` integration tests via `tests/integration/validator-hardening-*.ps1`; `validate-governance.ps1` self-validation | No new toolchain introduced |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `canonical-schema-contract-present` | manual-evidence | `specs/013-validator-hardening/contracts/iteration-state-schema.md` | `planned` |
| `canonical-concerns-contract-present` | manual-evidence | `specs/013-validator-hardening/contracts/hardening-gate-concerns.md` | `planned` |
| `iteration-1-fixture-coverage` | tooling | `tests/integration/validator-hardening-iteration1.ps1` | `planned` |
| `no-unhandled-exceptions-baseline` | tooling | fixture lane covering malformed/empty/missing inputs | `planned` |
| `backward-compatibility-pass` | tooling | `pwsh -NoProfile -File extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` on current corpus | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| Security surface analysis | Validator reads only local Git-tracked Markdown; no network, no untrusted external input | None; re-evaluate if future validator expansion adds external input |
| Retry and idempotency | Validator is a stateless read-only pass; re-runs are idempotent by definition | None |
| Specialist lens execution changes | This feature does not change lens catalogs or bug-hunter execution behavior | Keep deferred |
| Model-based review | Explicitly out of scope per TG-007 and Non-Goals | None |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics are deferred to the Iteration 1 pre-implementation gate run.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred beyond these two iterations.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `Iteration 1 pre-implementation hardening gate` (canonical schema + graceful error rules)  
**Hardening Gate Artifact**: `specs/013-validator-hardening/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/013-validator-hardening/quality/trap-reapplication.md` (created at Iteration 1 implementation start)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | Validator reads local Markdown via PowerShell; no network surface. Trust boundary is the project root path supplied by the caller. Expected control: `Resolve-ProjectPath` from `shared-governance.ps1` sanitizes the project root; no file outside the project root is read. Runtime proof: verify path resolution in fixture replay. | `iterations/001/quality/hardening-gate.md` — security-surface concern row | `required` |
| Error handling and failure semantics | The feature's core objective. Every parse failure, missing file, schema deviation, and unexpected condition must produce structured FAIL output (file path, line, category, remediation hint) and a non-zero exit code. No raw PowerShell exception should reach the user. Expected control: wrap all new check functions in `try/catch` returning structured error objects; unit fixture covers each error category. Runtime proof pending until Iteration 1 implementation exists. | `iterations/001/quality/hardening-gate.md` — error-handling-expectations concern row | `required` |
| Retry and idempotency expectations | Validator is a stateless read-only pass; there is no write path, no network call, and no retry logic needed. Repeated runs against the same artifact set are idempotent. Explicit not-applicable rationale: the feature adds no mutable state and no retry surface. | `iterations/001/quality/hardening-gate.md` — retry-idempotency-requirements concern row | `required` |
| Test-integrity targets | Each new rule must be exercised by at least one violating fixture and one compliant fixture via scaffold-replay-style assertions. Gaps in fixture coverage are a blocking concern. Runtime proof: named `tests/integration/validator-hardening-iteration1.ps1` must pass with zero FAIL lines. | `iterations/001/quality/hardening-gate.md` — test-integrity-targets concern row | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `governance-correctness-review-v1` | `required` | New validator rules change governance enforcement behavior | `iterations/001/quality/hardening-gate.md` |
| `error-handling-review-v1` | `required` | Structured FAIL output is the primary deliverable of FR-005 | `iterations/001/quality/hardening-gate.md` |
| `security-issues-v1` | `optional` | Low security surface; path sanitization check is the only relevant item | `iterations/001/quality/hardening-gate.md` |
| `performance-review-v1` | `not-applicable` | No throughput requirement; validator runs once per developer invocation | None |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening lenses | `strongest-available` | Record actual class when Iteration 1 gate is executed | `none` | Default routing; no lower-tier override requested |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof are deferred until Iteration 1 implementation exists and the pre-implementation gate is run.
- Iteration 2 hardening gate planning (covering FR-003, FR-004, FR-006, FR-007) is deferred to Iteration 2 planning.
- Known-traps corpus graduation entries (FR-007) are deferred to Iteration 2 implementation.
- Strongest-class routing enforcement evidence and requested-versus-effective execution records are deferred until gate execution.
- Quality-drift and reference-implementation checks remain explicitly deferred beyond this feature.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ Plan scope maps to approved `specs/013-validator-hardening/spec.md`. All planned deliverables trace to FRs, user stories, and SC measurable outcomes in the spec. No out-of-scope additions.
- **Layering Gate**: ✅ All changes are classified as Spec Kit extension layer: `validate-governance.ps1` and `shared-governance.ps1` live under `extensions/specrew-speckit/scripts/`. The bookkeeping classifier helper lives under `scripts/`. Contract and corpus updates are governance artifacts under `specs/` and `.specrew/`. No Squad layer behavior is introduced.
- **Traceability Gate**: ✅ Each planned deliverable links back to an FR and a user story via the TG requirements in the spec (TG-001 through TG-008). Iteration split maps directly to the delivery windows in FR-001 through FR-010.
- **Ownership Gate**: ✅ Spec Steward: Alon Fliess (per spec Governance Alignment). Validator maintainers own `validate-governance.ps1` / `shared-governance.ps1`. Governance-contract stewards own contract artifacts. Governance-corpus stewards own known-traps graduation. Restart-policy stewards own the bookkeeping classifier helper.
- **Capacity Gate**: ✅ Capacity unit: bounded iterations (as per spec capacity model). Iteration 1 carries FR-001, FR-002, FR-005, FR-008 slice 1, FR-009, FR-010 slice 1. Iteration 2 carries FR-003, FR-004, FR-006, FR-007, FR-008 slice 2, FR-010 slice 2. Each iteration is bounded and independently deliverable.
- **Drift/Reconciliation Gate**: ✅ Drift detection runs via `validate-governance.ps1` on each commit. Any divergence between contracts and validator behavior surfaces as FAIL output. Reconciliation path: update contracts and validator in the same PR.
- **Verification Gate**: ✅ Each rule is verified by at least one violating fixture and one compliant fixture via `tests/integration/validator-hardening-*.ps1`. Acceptance criteria from SC-001 through SC-007 are the explicit pass conditions.

*Post-design re-check*: Constitution check remains fully satisfied. The two-contract design (iteration-state-schema, hardening-gate-concerns) follows the feature-local contract pattern from spec 005. No layering violations or traceability gaps were introduced during Phase 1 design.

## Project Structure

### Documentation (this feature)

```text
specs/013-validator-hardening/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/
│   ├── iteration-state-schema.md        # FR-009 canonical state.md schema contract
│   └── hardening-gate-concerns.md       # FR-009 canonical hardening-gate concerns contract
└── tasks.md             # Phase 2 output (/speckit.tasks command — NOT created here)
```

### Source Code (repository root)

```text
extensions/specrew-speckit/scripts/
├── validate-governance.ps1      # New rules: FR-001, FR-002, FR-003, FR-004
├── shared-governance.ps1        # Supporting helper functions for new rules
└── (new helper) Test-CopilotInstructionsChangeType.ps1   # FR-006 bookkeeping classifier

scripts/
└── specrew-start.ps1            # Consumes FR-006 classifier (Iteration 2)

tests/integration/
├── validator-hardening-iteration1.ps1    # FR-001, FR-002, FR-005 fixture coverage
├── validator-hardening-iteration2.ps1    # FR-003, FR-004, FR-006 fixture coverage
└── fixtures/
    └── 013-validator-hardening/
        ├── state-canonical/              # Compliant state.md fixtures (FR-001)
        ├── state-noncanonical/           # Violating state.md fixtures (FR-001)
        ├── hardening-gate-canonical/     # Compliant hardening-gate.md fixtures (FR-002)
        ├── hardening-gate-noncanonical/  # Violating hardening-gate.md fixtures (FR-002)
        ├── approval-reuse/               # Sibling-iteration approval evidence fixtures (FR-003)
        ├── overclaim/                    # Closed-iteration over-claim fixtures (FR-004)
        └── copilot-instructions/         # Bookkeeping vs behavior diff fixtures (FR-006)

.specrew/quality/
└── known-traps.md               # FR-007 graduation updates (Iteration 2)
```

**Structure Decision**: Single project layout. All implementation targets existing Spec Kit extension scripts under `extensions/specrew-speckit/scripts/` and `scripts/`; tests extend the existing `tests/integration/` layout. No new top-level directory is needed.

## Complexity Tracking

No constitution violations. The plan is fully additive to existing surfaces. No new projects, no new architectural layers, no new repository patterns.
