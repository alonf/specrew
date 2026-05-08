# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 2/20 story_points
**Started**: 2026-05-07

## Summary

Phase 1 quality evidence fixtures for fail-closed governance validation.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.node-public-ws-service.v1`
**Selected preset ref or explicit custom composition**: `node-public-ws-service@v1.0.0`
**Bounded custom composition**: Not required for this recognized stack.

### Stack Surfaces in Scope

| Stack Surface | Recognized Stack | Path Globs | Matched Signals |
| --- | --- | --- | --- |
| `service-runtime` | `node-public-ws-service` | `src/**`, `package.json` | package.json; websocket route |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `security` | `required` | Public ingress and payload handling are in scope. |
| `robustness` | `required` | Connection lifecycle behavior must remain explicit. |
| `verification-confidence` | `required` | Deterministic lifecycle assertions are required. |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `node-websocket-phase1` |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | npm test, repo-standard lint/static-analysis command |
| Manual Evidence | feature plan Phase 1 quality planning section, specs/<feature>/iterations/<NNN>/quality/quality-evidence.md |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | `mechanical` | `specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json` |
| `anti-pattern` | `mechanical` | `specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json` |
| `test-integrity` | `mechanical` | `specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | `tooling` | `specs/<feature>/iterations/<NNN>/quality/quality-evidence.md` |
| `quality-lens-review` | `manual-evidence` | `specs/<feature>/iterations/<NNN>/quality/quality-evidence.md` |

### Not-Applicable Dimensions and Rationale

| Dimension | Rationale | Omitted Gates |
| --- | --- | --- |
| `concurrency-correctness` | Not materially distinct in this fixture. | `(none)` |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off remains deferred.
- Dedicated bug-hunter lens execution remains deferred.
- Quality-drift logic remains deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `US-2 hardening-gate planning only; specialist lens execution, routing enforcement, and known-traps follow-through stay explicitly deferred.`  
**Hardening Gate Artifact**: `specs/005-quality-evidence/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/005-quality-evidence/iterations/001/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | The hardening gate must capture trust boundaries, auth assumptions, secret handling, and sensitive mutation paths before coding begins. | `specs/005-quality-evidence/iterations/001/quality/hardening-gate.md` | `required` |
| Error handling and failure semantics | Silent failure paths and fallback expectations must be made explicit in the hardening gate so implementation does not invent them later. | `specs/005-quality-evidence/iterations/001/quality/hardening-gate.md` | `required` |
| Retry and idempotency expectations | The hardening gate still records why retry and idempotency do not materially apply in this bounded websocket fixture so omissions stay reviewable. | `specs/005-quality-evidence/iterations/001/quality/hardening-gate.md` | `not-applicable` |
| Test-integrity targets | The hardening gate must name the evidence expected for this slice so readiness does not rely on smoke-only success. | `specs/005-quality-evidence/iterations/001/quality/quality-evidence.md` | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | `required` | Security remains materially relevant even though row-level specialist execution is deferred in this bounded fixture. | `specs/005-quality-evidence/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | `required` | Robustness and operational concerns feed the pre-implementation hardening review directly. | `specs/005-quality-evidence/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | `required` | Test-integrity targets are part of the hardening readiness contract for this fixture. | `specs/005-quality-evidence/iterations/001/quality/lenses/test-integrity.md` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` | Record when execution happens | Explicit approved lower-tier override required before any downgrade takes effect. | Planning publishes the requested routing baseline only; row-level specialist execution remains deferred. |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence remains deferred until the approved implementation/review slice authorizes it.
- Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T013 | Add lifecycle evidence coverage | FR-011, FR-012 | US-1 | 2 | Reviewer | planned |

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |
