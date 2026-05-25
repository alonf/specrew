# Implementation Plan: Specrew v0.27.1 Bug-Fix Bundle

**Branch**: `045-v0271-bugfix-bundle` | **Date**: 2026-05-25 | **Spec**: `specs/045-v0271-bugfix-bundle/spec.md`  
**Input**: Feature specification from `specs/045-v0271-bugfix-bundle/spec.md`

## Summary

Deliver a two-iteration v0.27.1 patch bundle that restores expected CLI behavior (`--version` / `-v`, `version` warning correctness, `start`/`init` skill-catalog recovery, brownfield ownership classification), preserves governance/mirror integrity, and updates operator guidance for safe update + re-deployment decisions.

### Two-Iteration Sequencing

- **Iteration 001 (20 SP)**: Foundational + User Story 1 (CLI defects, version/start/init behavior fixes, regression tests) — closes F1-F5
  - Exit gate: standard implement → review → retro → iteration-closeout
  - Human checkpoint: explicit iteration-001 closeout approval before iter-002 authorization
- **Iteration 002 (20 SP)**: User Story 2 + User Story 3 + Polish (brownfield ownership, operator docs, traceability finalization, governance checks) — closes F6-F7 + feature-closeout
  - Exit gate: standard implement → review → retro → iteration-closeout → feature-closeout

Rationale: The split enforces human verification that US1 (CLI surface fixes) lands cleanly before authorizing US2+US3+docs (deeper scope change + documentation). Both bundles maintain v0.27.1 release identity; split is delivery checkpoint, not scope fragmentation.

## Technical Context

**Language/Version**: PowerShell 7+ (primary runtime scripts), Markdown docs  
**Primary Dependencies**: Spec Kit CLI (`specify`), Squad CLI (`squad`), Git, module/runtime scripts under `scripts/` and `extensions/specrew-speckit/scripts/`  
**Storage**: File-based project artifacts (`.specrew/`, `.specify/`, `.squad/`, `.github/`)  
**Testing**: PowerShell integration harness in `tests/integration/*.ps1` plus governance validators  
**Target Platform**: Windows-first PowerShell environment with cross-platform path handling  
**Project Type**: CLI + governance tooling repository  
**Performance Goals**: No material runtime latency regressions in `specrew` command startup paths  
**Constraints**: Patch-only scope; no new lifecycle boundaries; no non-bug feature expansion  
**Scale/Scope**: Exactly the 7 post-release findings listed in this bundle

### In-Scope 7 Bug-Fix Bundle Items

1. Top-level `specrew --version` must resolve with parity to `specrew version`.
2. Top-level `specrew -v` must resolve with parity to `specrew version`.
3. `specrew version` must suppress false-positive “version could not be determined” warnings when version is actually available.
4. `specrew start` must auto-repair missing skill-catalog directories before continuing.
5. `specrew init` (non-force path) must treat missing skill-catalog directories as deployable gaps and proceed into deployment flow.
6. `specrew init -Force` must apply the same deployable-gap behavior (no false early success).
7. Brownfield conflict logic must treat `.squad/agents/` as canonical when `extensions/specrew-speckit/` self-hosting signal exists, and docs must capture update/redeploy guidance + stale finding disposition without widening runtime scope.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Explicit bounded custom composition from pre-plan resolver + before-plan hook output.  
**Bounded custom composition**: Focus on CLI/governance patch correctness and regression confidence for the 7-item bundle; defer advanced hardening execution artifacts to Phase 2.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| CLI entrypoint routing | `scripts/specrew.ps1`, `scripts/specrew-version.ps1`, `scripts/specrew-start.ps1`, `scripts/specrew-init.ps1` | custom | Core defects are command-routing and lifecycle-flow regressions |
| Brownfield merge logic | `extensions/specrew-speckit/scripts/brownfield-merge.ps1`, `tests/integration/brownfield-conflict-handling.ps1` | custom | Ownership classification bug is in brownfield conflict logic |
| Update/operator docs | `docs/getting-started.md`, `docs/user-guide.md`, new/updated update guidance doc in repo docs | custom | Story 3 requires explicit operator decision guidance |
| Regression harness | `tests/integration/validate-versions-cli-behavior.ps1`, `tests/integration/start-recovery-flow.tests.ps1`, `tests/integration/brownfield-conflict-handling.ps1` | custom | SC-001..SC-006 must be proven with deterministic checks |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| code-quality | required | Entry-point and flow regressions must be fixed without introducing parser drift |
| design-quality-and-separation-of-concerns | required | Routing changes must stay in command surfaces, not bleed into unrelated modules |
| verification-confidence | required | Patch release requires high-confidence targeted regression evidence |
| maintainability | required | Fixes must preserve existing script decomposition and update paths |
| security | required | Brownfield ownership + update behavior can impact trusted deployment boundaries |
| robustness | required | Missing-directory and stale-environment cases are failure-mode paths |
| concurrency-correctness | not-applicable | No concurrent processing design change in this patch slice |
| resiliency | not-applicable | No distributed runtime/retry subsystem is added here |
| retry-idempotency-and-recovery | not-applicable | No new retry loop semantics introduced in this 7-item scope |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `quality-profile.custom-composition.v1` | From before-plan gate output |
| Mechanical Checks | `dead-field`, `anti-pattern`, `test-integrity` | `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` |
| Ecosystem Tools | `pwsh -NoProfile -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath C:/Dev/Specrew -IterationPath specs/045-v0271-bugfix-bundle/iterations/001` | Populate mechanical findings + quality-evidence |
| Regression Lane | `pwsh -NoProfile -File tests/integration/validate-versions-cli-behavior.ps1`; `pwsh -NoProfile -File tests/integration/brownfield-conflict-handling.ps1`; `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1` | Directly exercises defect surfaces related to this bundle |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| dead-field | mechanical | `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` | planned |
| anti-pattern | mechanical | `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` | planned |
| test-integrity | mechanical | `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` | planned |
| stack-tooling-evidence | tooling | `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |
| quality-lens-review | manual-evidence | `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| concurrency-correctness | No concurrent executor/path mutation introduced | none |
| resiliency | No new resilient distributed behavior added | none |
| retry-idempotency-and-recovery | No retry/idempotency behavior introduced in this patch | none |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off remains a separate Phase 2 artifact.
- Dedicated bug-hunter lens execution remains deferred.
- Known-traps expansion and trap reapplication documentation remain deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `v0.27.1 patch hardening gate for 7-item bug-fix bundle`  
**Hardening Gate Artifact**: `specs/045-v0271-bugfix-bundle/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/045-v0271-bugfix-bundle/iterations/001/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | Brownfield ownership classification and update guidance can alter trusted behavior | hardening-gate security section + quality-evidence gate matrix | required |
| Error handling and failure semantics | False warning suppression and missing-directory handling are failure-mode fixes | hardening-gate failure contract section + regression outputs | required |
| Retry and idempotency expectations | Must explicitly remain unchanged in this patch | hardening-gate rationale section | required |
| Test-integrity targets | Patch release requires no failing P0/P1 regressions | regression command outputs + quality-evidence | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required | Ownership and update flows affect trust boundaries | `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` |
| `robustness-baseline@v1.0.0` | required | Missing-directory lifecycle resilience is core patch surface | `specs/045-v0271-bugfix-bundle/iterations/001/quality/quality-evidence.md` |
| `test-integrity@v1.0.0` | required | Regression confidence is release blocker | `specs/045-v0271-bugfix-bundle/iterations/001/quality/mechanical-findings.json` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest available | record at execution | none | No downgrade without explicit human approval |

### Explicit Later Deferrals

- Runtime-only closure evidence remains deferred until implementation + review execution.
- Known-traps corpus updates remain deferred until dedicated trap pass.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS (scope anchored to `spec.md` FR-001..FR-008, TG-001..TG-007, SC-001..SC-006).  
- **Layering Gate**: PASS (changes classified: CLI scripts + extension scripts + docs; no unsupported host hacks).  
- **Traceability Gate**: PASS (plan/research/data-model/contracts/quickstart map to stories and FRs).  
- **Ownership Gate**: PASS (Implementer/Reviewer/Doc Steward roles preserved per TG-005; Spec Steward explicit).  
- **Capacity Gate**: PASS (single patch iteration, bounded to 7 items).  
- **Drift/Reconciliation Gate**: PASS (Proposal 110/116 composition explicitly tracked; stale review findings closed with disposition notes).  
- **Verification Gate**: PASS (explicit regression command set + quality gates + artifact evidence paths).

## Project Structure

### Documentation (this feature)

```text
specs/045-v0271-bugfix-bundle/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── cli-behavior-contract.md
└── tasks.md  # created later by /speckit.tasks
```

### Source Code (repository root)

```text
scripts/
├── specrew.ps1
├── specrew-version.ps1
├── specrew-start.ps1
└── specrew-init.ps1

extensions/specrew-speckit/scripts/
└── brownfield-merge.ps1

docs/
├── getting-started.md
└── user-guide.md

tests/integration/
├── validate-versions-cli-behavior.ps1
├── brownfield-conflict-handling.ps1
└── start-recovery-flow.tests.ps1
```

**Structure Decision**: Single CLI/governance repository structure; patch is limited to existing script + docs + integration-test surfaces.

## Complexity Tracking

No constitution violations requiring exception.
