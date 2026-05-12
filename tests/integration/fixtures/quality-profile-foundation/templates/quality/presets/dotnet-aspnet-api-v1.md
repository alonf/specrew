# Stack Preset: dotnet-aspnet-api v1.0.0

| Field | Value |
| --- | --- |
| Preset ID | `dotnet-aspnet-api` |
| Version | `v1.0.0` |
| Phase Scope | `phase-1-first-slice` |
| Intent | Reviewable Phase 1 quality baseline for a public ASP.NET API. |

## Supported Stack Signals

| Signal | Match Examples | Why it qualifies |
| --- | --- | --- |
| `*.csproj` or solution file | ASP.NET service project | Establishes .NET build/runtime signals. |
| ASP.NET API surface | Controllers, minimal APIs, middleware pipeline | Indicates public HTTP behavior and request pipeline review. |
| Hosted .NET service | Web API or service host | Activates middleware, configuration, and response-contract concerns. |

## Required Quality Dimensions

| Dimension | Activation Rule | Phase 1 Expectation |
| --- | --- | --- |
| `security` | Public API endpoints and configuration surfaces are in scope. | Validate auth boundaries, input handling, and configuration hygiene. |
| `robustness` | Middleware, async handlers, and hosting lifecycle are material. | Make failure behavior and resource ownership explicit. |
| `verification-confidence` | Observable correctness depends on API responses and pipeline behavior. | Require assertions on response contracts and failure paths. |

## Required Mechanical Checks

| Check | Required Configuration | Blocking Expectation |
| --- | --- | --- |
| `dead-field` | Review DTOs, options/config members, and response models for unused members. | Dead members are removed or justified before they drift. |
| `anti-pattern` | Flag synchronous blocking in async request flows and hidden middleware failure paths. | Request-pipeline behavior remains explicit and bounded. |
| `test-integrity` | Require assertions on response status, body, and failure semantics. | Tests prove meaningful API behavior rather than smoke-only startup. |

## Required Lens Checklist References

| Lens | Version | Activation Rationale |
| --- | --- | --- |
| `security-baseline` | `v1.0.0` | Public API boundaries and configuration handling require review. |
| `robustness-baseline` | `v1.0.0` | Middleware, cleanup, and degraded operation are material to service reliability. |
| `test-integrity` | `v1.0.0` | API tests must validate observable contracts and errors. |

## Toolchain / Evidence Expectations

| Area | Concrete Selection | Evidence Expectation |
| --- | --- | --- |
| Build + test workflow | `.NET` with `dotnet test` | Tests cover response contracts and failure paths. |
| Static feedback lane | Repo-standard .NET analyzer/lint lane | Findings stay reviewable and tied to the API scope. |
| API verification | Integration or host-level API tests | Evidence proves middleware and endpoint behavior. |
| Governance artifacts | Preset reference plus iteration `quality/` artifacts | Reviewers can trace selected expectations to evidence. |

## Upgrade Guidance

1. Revisit the preset when middleware, hosting, or API composition patterns change materially.
2. Upgrade lens references independently when checklist coverage changes without changing the stack baseline.
3. Keep later-phase hardening workflows explicit and deferred unless a future reviewed preset version intentionally expands scope.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 preset for public ASP.NET API services. | Establishes API pipeline expectations while keeping preset and lens versioning independent. |
