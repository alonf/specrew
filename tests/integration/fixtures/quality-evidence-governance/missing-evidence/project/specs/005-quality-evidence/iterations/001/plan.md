# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
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
