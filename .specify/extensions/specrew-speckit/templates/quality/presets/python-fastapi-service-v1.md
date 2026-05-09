# Stack Preset: python-fastapi-service v1.0.0

| Field | Value |
| --- | --- |
| Preset ID | `python-fastapi-service` |
| Version | `v1.0.0` |
| Phase Scope | `phase-1-first-slice` |
| Intent | Reviewable Phase 1 quality baseline for a public FastAPI service. |

## Supported Stack Signals

| Signal | Match Examples | Why it qualifies |
| --- | --- | --- |
| Python project manifest | `pyproject.toml`, `requirements.txt` | Establishes Python service/tooling signals. |
| FastAPI dependency | FastAPI app or router modules | Indicates async API request handling. |
| Public service surface | internet-facing HTTP endpoints | Activates request-boundary, validation, and evidence expectations. |

## Required Quality Dimensions

| Dimension | Activation Rule | Phase 1 Expectation |
| --- | --- | --- |
| `security` | The service validates and processes public requests. | Keep request validation, auth boundaries, and secret handling explicit. |
| `robustness` | Async handlers, background tasks, or downstream calls are in scope. | Make cleanup, timeout, and failure semantics reviewable. |
| `verification-confidence` | Endpoint behavior depends on typed models and async flows. | Require assertions on inputs, outputs, and negative paths. |

## Required Mechanical Checks

| Check | Required Configuration | Blocking Expectation |
| --- | --- | --- |
| `dead-field` | Review request/response models, settings objects, and service DTOs for unused members. | Dead models or settings do not linger silently. |
| `anti-pattern` | Flag blocking work inside async handlers and hidden background-task failures. | Async request paths stay bounded and explicit. |
| `test-integrity` | Require endpoint tests with positive and negative assertions. | Tests prove request validation and observable responses. |

## Required Lens Checklist References

| Lens | Version | Activation Rationale |
| --- | --- | --- |
| `security-baseline` | `v1.0.0` | Public request handling and auth/config surfaces require security review. |
| `robustness-baseline` | `v1.0.0` | Async lifecycle and degraded operation must stay explicit. |
| `test-integrity` | `v1.0.0` | API tests need meaningful assertions across success and failure paths. |

## Toolchain / Evidence Expectations

| Area | Concrete Selection | Evidence Expectation |
| --- | --- | --- |
| Package + test workflow | `pytest` | Tests cover endpoint inputs, outputs, and error conditions. |
| Static feedback lane | Repo-standard Python lint/type-analysis commands | Findings remain reviewable and tied to the service scope. |
| API verification | FastAPI route/integration tests | Evidence proves validation, serialization, and failure semantics. |
| Governance artifacts | Preset reference plus iteration `quality/` artifacts | Reviewers can trace selected expectations to evidence. |

## Upgrade Guidance

1. Revisit the preset when async execution, validation, or dependency-injection conventions change materially.
2. Upgrade lens references independently when checklist coverage changes without changing the stack baseline.
3. Keep later-phase hardening or drift workflows out of this Phase 1 preset unless a future reviewed version approves them.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 preset for public FastAPI services. | Establishes typed async service expectations with independent preset versioning. |
