# Implementation Plan: Continuous Co-Review

**Branch**: `197-continuous-co-review` | **Date**: 2026-06-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/197-continuous-co-review/spec.md`

**Note**: Stops after planning; no tasks or implementation are started.

## Summary

Proposal 197 shifts design-conformance review from final Proposal 145 review-signoff to checkpoint boundaries. Iteration 001 delivers the host-neutral rung 2b spine: reviewer contract, forced findings schema, git-diff change-set, blackboard review-thread protocol, deterministic blocking gate, orchestrator checkpoint-loop trigger, explicit provider/model authorization, headless-floor spawn adapter seams, and a fresh-context read-only reviewer. The slice is local, contract-first, filesystem-backed, PowerShell/Pester-oriented, additive/new-file-only, and isolated from F-184 protected host-runtime, hook, provider, registry, refocus, shared-governance, and `validate-governance.ps1` surfaces.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance and contract artifacts.  
**Primary Dependencies**: Existing Specrew module/script surfaces, Git CLI, and installed headless AI host CLIs when explicitly configured/authorized; no new dependencies.  
**Storage**: Versioned filesystem artifacts only. Durable evidence under `.specrew/review/inline/<run-id>/...`; temporary immutable bundles in per-run workspaces.  
**Testing**: Deterministic Pester unit/contract/fixture tests, schema/fixture validation, controlled fake/fixture adapter path, markdown/governance validation; live AI-host smoke is optional and explicitly authorized only.  
**Target Platform**: Local developer checkout/session on supported Specrew hosts; no server, daemon, queue, cloud resource, background service, hosted worker, service identity, or new GitHub Actions workflow.  
**Project Type**: Local Specrew tooling/module-command spine with file/stdin/stdout/process-exit contracts.  
**Performance Goals**: Bounded synchronous reviewer invocation with configured timeout; no tuning goal beyond deterministic timeout handling and checkpoint-level review.  
**Constraints**: New-file-only first slice; no F-184 protected-surface edits; no `specrew update`; no proposal-governance branch edits; keep `.squad/agents/spec-steward/history.md` runtime churn out of commits; no new dependencies; do not name/scope a new CI/CD E2E companion proposal; preserve hooks/fixtures for Proposal 181 plus Proposal 194 canary composition.  
**Scale/Scope**: Iteration 001 host-neutral spine. Planning budget: 18 capacity points: contracts/schemas 3, diff/request/context 3, adapter/config/selection 4, execution/failure normalization 3, blackboard/gate/evidence 3, fixture/test/governance evidence 2.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Bounded custom composition for PowerShell + Markdown/YAML/JSON local tooling and contract artifacts.  
**Bounded custom composition**: No single recognized preset cleanly covers this reviewer spine. Required dimensions: code quality, design-quality-and-separation-of-concerns, verification-confidence, maintainability, security, and robustness. Mechanical checks: dead-field, anti-pattern, test-integrity. Iteration quality evidence and mechanical findings artifacts are required when an iteration scaffold exists. Manual unknowns left to tasking/implementation: exact command names, timeout default, fixture layout, and host/model config shape.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Feature planning artifacts | `specs/197-continuous-co-review/{plan.md,research.md,data-model.md,quickstart.md,contracts/**,implementation-rules.yml,workshop/**}` | custom | Authoritative planning, requirements, design decisions, and contracts. |
| Runtime spine | Proposed new namespace `scripts/internal/continuous-co-review/**` or equivalent explicit reviewer-domain module surfaces | PowerShell 7.x / custom | Houses orchestrator, diff, request, execution, blackboard, and gate logic without protected edits. |
| Reviewer host adapter seams | Explicit reviewer-domain names such as `reviewer-host-adapter-*`, `reviewer-model-capability`, `reviewer-host-catalog` | PowerShell 7.x / custom | Prevents collisions with F-184 provider files. |
| Contract and fixture tests | Proposed `tests/continuous-co-review/**` | Pester / JSON fixtures | Proves schemas, deterministic failures, gate behavior, and no-silent-downgrade. |
| Durable runtime evidence | `.specrew/review/inline/<run-id>/**` | filesystem JSON/Markdown | System of record for review threads, findings, verdicts, run metadata, and skipped runs. |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| code-quality | required | PowerShell orchestration must stay small, testable, dependency-free, and idiomatic. |
| design-quality-and-separation-of-concerns | required | Stable contracts stay inward; host CLI details stay behind reviewer-domain adapters. |
| verification-confidence | required | Fixtures/Pester must prove pass/block/unsafe outcomes without live provider dependency. |
| maintainability | required | Additive schema evolution, clear namespace ownership, and no broad utility packages are core. |
| security | required | Reviewer mutation boundary, secret exclusion, safe argv, and authorization are binding. |
| robustness | required | Timeouts, missing hosts, invalid JSON, malformed state, fallback exhaustion, cleanup failures, and no-diff runs need deterministic outcomes. |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `proposal-197.custom-powershell-contract-tooling.v1` | Bounded custom bundle. |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | Record evidence with iteration quality artifacts and mechanical findings artifacts once scaffolded. |
| Ecosystem Tools | Pester, existing PowerShell/static review practice, JSON fixture validation, markdownlint before commit | Existing tools only; no new package/dependency. |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `qg-contract-schema-fixtures` | mechanical/tooling | Fixtures for ReviewRequest, FindingsResult, InfrastructureFailure, ReviewThread, GateVerdict, SpawnInvocation, ReviewRun, ReviewRunSkipped | planned |
| `qg-deterministic-gate-semantics` | tooling | Tests for pass, blocked, unsafe malformed state, skipped no-diff, non-convergence escalation | planned |
| `qg-adapter-failure-floor` | tooling | Each adapter returns valid result or deterministic InfrastructureFailure in controlled/fake mode | planned |
| `qg-security-boundary` | tooling/manual | Safe argv, no source mutation, no secrets/raw transcripts, authorization before paid/non-default provider | planned |
| `qg-protected-surface-guard` | mechanical/manual | Git diff/file-list review proving no protected files changed | planned |
| `qg-implementation-rules-trace` | manual | Tasks/reviews reference `implementation-rules.yml` and dependency policy | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| UI/UX visual accessibility | No app UI or screens. | Cover artifact/CLI wording through review. |
| Server/API availability and load | No server, daemon, queue, cloud, or hosted worker. | Revisit if hosted review workers are scoped. |
| Database migration/integrity | Filesystem-only storage. | None. |
| CI/CD E2E implementation | Proposal 197 preserves contract hooks/fixtures only. | Downstream composition with Proposal 181 plus Proposal 194 canary. |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off/blocking semantics, dedicated bug-hunter lens execution, strongest-class routing enforcement, known-traps corpus workflows, quality-drift logic, mixed-stack override routing, and reference implementation comparison are deferred unless explicitly re-scoped.
- Provenance/audit of human-confirmed lens stamps is a non-blocking note for Proposal 196 and is not budgeted into Proposal 197 tasks, gates, or iteration scope.
- Phase 2 metadata below is planning-only and does not claim runtime proof.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `deferred-not-authorized-for-proposal-197-iteration-001`  
**Hardening Gate Artifact**: none for Iteration 001 planning; future approved slice may add `specs/197-continuous-co-review/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md` (not modified by this plan)  
**Trap Reapplication Artifact**: none yet

### Hardening Focus Areas

| Focus Area | Why It Matters | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | Trusted reviewer read path, no source mutation, secret exclusion, authorization. | Plan/contracts/future tests | required |
| Error handling and failure semantics | Deterministic infrastructure failures and unsafe states are core behavior. | Research, data model, contracts, future tests | required |
| Retry and idempotency expectations | At most one authorized availability fallback; replay creates new run id. | Data model/contracts/future tests | required |
| Test-integrity targets | Fixtures must exercise contract semantics without live paid hosts. | Future iteration quality evidence | required |
| Dedicated bug-hunter execution | Not authorized for this iteration. | None | deferred |
| Known-traps corpus workflow | Explicitly deferred. | None | deferred |
| Strongest-class routing enforcement proof | Recommendation planned; runtime proof depends on implementation. | Future routing evidence if scoped | deferred |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence |
| --- | --- | --- | --- |
| architecture-core | required | Fresh-process reviewer orchestration and future-rung boundary. | `workshop/architecture-core.md`, `research.md` |
| component-design | required | Layered component map, adapter seam, workspace ownership. | `workshop/component-design.md`, `data-model.md` |
| requirements-nfr | required | Deterministic failure, auditability, convergence, compatibility. | `workshop/requirements-nfr.md` |
| data-storage | required | Filesystem-only durable/temp artifact ownership. | `workshop/data-storage.md`, `data-model.md` |
| security-compliance | required | Trusted reviewer boundary, secret exclusion, safe argv, authorization. | `workshop/security-compliance.md`, contracts |
| integration-api | required | Local file/stdin/stdout/process contracts and error envelope. | `workshop/integration-api.md`, `contracts/**` |
| devops-operations | required | Local-only hosting and no new CI/service identity. | `workshop/devops-operations.md`, `quickstart.md` |
| observability-resilience | required | Correlation, skipped run, failure taxonomy, replay, cleanup evidence. | `workshop/observability-resilience.md`, `data-model.md` |
| code-implementation | required | Implementation rules, dependency policy, protected-surface constraint. | `implementation-rules.yml` |
| ui-ux | not-applicable | No app UI or user-facing screen. | `lens-applicability.json` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Implementation-time continuous co-review | Strong review-class recommended, with cross-host/model independence when available and authorized. | Future ReviewRun evidence. | Per-run human authorization; none at planning. | Same-host fresh-context remains valid when cross-host is unavailable/unauthorized/unaffordable or explicitly rejected. |
| Phase 2 hardening/bug-hunter lenses | Deferred. | None. | None. | Do not claim runtime proof in this plan. |

### Explicit Later Deferrals

- Runtime-only final proof, known-traps corpus workflows, strongest-class routing evidence, quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless explicitly approved.

## Constitution Check

*GATE: Passed before Phase 0 research. Re-checked after Phase 1 design below.*

- **Spec Authority Gate**: PASS — scope maps to approved `spec.md`, workshop artifacts, `lens-applicability.json`, `implementation-rules.yml`, clarify evidence commit `20f3ab1e80f17a444b3c8763f953bafbf932edbc`, and human clarify -> plan approval.
- **Layering Gate**: PASS — Specrew local tooling/module-command behavior plus feature-local Spec Kit contracts; no platform hacks or protected F-184 edits.
- **Traceability Gate**: PASS — deliverables map to Story 1 (contract/diff/gate/reviewer), Story 2 (blackboard/thread/disposition), Story 3 (host-neutral adapters/config/authorization), and FR/DS/SEC/INT/OPS/OBS/IMPL/TG requirements.
- **Ownership Gate**: PASS — Architect owns contracts; Implementer owns diff/request/adapters; Reviewer owns gate validation; Security Reviewer owns mutation/secret/authorization controls; Spec Steward owns scope/protected-surface guard; Iteration Facilitator owns checkpoint-loop planning/capacity.
- **Capacity Gate**: PASS — capacity points and 18-point Iteration 001 budget recorded.
- **Drift/Reconciliation Gate**: PASS — drift signals include protected-surface edits, PostToolUse/hook triggers, reviewer source mutation, new dependencies, ambiguous provider-file names, unnamed CI/CD expansion, Proposal 196 provenance absorption, and proposal-governance edits.
- **Verification Gate**: PASS — contract fixtures, deterministic Pester tests, adapter fake/failure floor, markdownlint, protected file diff review, no-dependency review, and SC-001..SC-011 mapping planned.

## Project Structure

### Documentation (this feature)

```text
specs/197-continuous-co-review/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── implementation-rules.yml
├── lens-applicability.json
├── contracts/
│   ├── review-request.schema.json
│   ├── findings-result.schema.json
│   ├── review-thread.schema.json
│   ├── gate-verdict.schema.json
│   ├── infrastructure-failure.schema.json
│   ├── spawn-invocation.schema.json
│   └── reviewer-spawn-contract.md
└── workshop/
```

### Source Code (repository root)

```text
scripts/
└── internal/
    └── continuous-co-review/           # proposed new namespace only
        ├── reviewer-contracts.ps1
        ├── checkpoint-diff-provider.ps1
        ├── review-request-builder.ps1
        ├── design-context-collector.ps1
        ├── review-run-workspace-manager.ps1
        ├── reviewer-host-catalog.ps1
        ├── reviewer-model-capability.ps1
        ├── reviewer-selection-policy.ps1
        ├── reviewer-authorization-gate.ps1
        ├── reviewer-execution-engine.ps1
        ├── reviewer-host-adapter-registry.ps1
        ├── reviewer-host-adapter-claude-prompt.ps1
        ├── reviewer-host-adapter-codex-exec.ps1
        ├── reviewer-host-adapter-copilot-prompt.ps1
        ├── reviewer-host-adapter-cursor-agent-prompt.ps1
        ├── reviewer-host-adapter-antigravity-prompt.ps1
        ├── review-result-normalizer.ps1
        ├── inline-review-gate-evaluator.ps1
        └── review-blackboard-writer.ps1

tests/
└── continuous-co-review/
    ├── contracts/
    ├── fixtures/
    ├── unit/
    └── integration/
```

**Structure Decision**: Use a new explicit `continuous-co-review` / reviewer-domain namespace. Do not create or edit `provider-adapter.ps1`, generic provider files, protected host-runtime/hook/registry/refocus/shared-governance files, `.specify/extensions/...` mirrored protected files, or `validate-governance.ps1`.

## Complexity Tracking

No constitutional violations are accepted or justified. Complexity is limited to contracts, strategy seams, and deterministic state machines required by the approved requirements.

## Phase 0 Research

See [research.md](./research.md). All Technical Context unknowns are resolved; no clarification placeholders remain.

## Phase 1 Design and Contracts

See [data-model.md](./data-model.md), [quickstart.md](./quickstart.md), and `contracts/`. The design preserves stable contract versioning, filesystem-only evidence, safe adapter seams, deterministic gate semantics, and explicit authorization/failure behavior.

## Post-Design Constitution Check

- **Spec Authority Gate**: PASS — artifacts preserve Iteration 001 and do not absorb Proposal 196 provenance work, CI/CD E2E implementation, Proposal 139 foundation, rung 1, or hook-triggered review.
- **Layering Gate**: PASS — contracts/runtime surfaces remain Specrew local tooling and feature-local artifacts.
- **Traceability Gate**: PASS — entities/contracts map to FR-001..FR-016, DS-001..DS-005, SEC-001..SEC-006, INT-001..INT-009, OPS-001..OPS-007, OBS-001..OBS-009, IMPL-001..IMPL-007, TG-001..TG-012, and SC-001..SC-011.
- **Ownership Gate**: PASS — ownership is explicit by workstream.
- **Capacity Gate**: PASS — 18-point Iteration 001 planning budget can be decomposed by `/speckit.tasks`.
- **Drift/Reconciliation Gate**: PASS — protected-surface, dependency, proposal-governance, runtime-history, CI/CD naming, and provider-file collision rules are blocking drift signals.
- **Verification Gate**: PASS — contract, schema, fixture, gate, adapter, security, and governance evidence sources are planned without claiming runtime proof.
