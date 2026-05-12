# Stack Preset: react-spa-public v1.0.0

| Field | Value |
| --- | --- |
| Preset ID | `react-spa-public` |
| Version | `v1.0.0` |
| Phase Scope | `phase-1-first-slice` |
| Intent | Reviewable Phase 1 quality baseline for a public React single-page application. |

## Supported Stack Signals

| Signal | Match Examples | Why it qualifies |
| --- | --- | --- |
| `package.json` | Frontend app manifest | Establishes the Node-based frontend toolchain surface. |
| `react` dependency | React app or workspace package | Indicates component-driven browser UI behavior. |
| Public browser SPA | User-facing routed frontend | Activates client-side trust-boundary and rendering-quality review. |

## Required Quality Dimensions

| Dimension | Activation Rule | Phase 1 Expectation |
| --- | --- | --- |
| `security` | The application accepts or renders untrusted browser input. | Validate client-side input handling, token/config leakage, and safe rendering defaults. |
| `maintainability` | Components, state flows, and effects form the primary delivery surface. | Keep boundaries, state ownership, and side effects reviewable. |
| `verification-confidence` | UI correctness depends on rendered outcomes and interactions. | Require assertions on observable DOM or user-facing behavior. |

## Required Mechanical Checks

| Check | Required Configuration | Blocking Expectation |
| --- | --- | --- |
| `dead-field` | Review dead props, stale config entries, and unused UI state members. | Remove unused fields and props or justify them explicitly. |
| `anti-pattern` | Flag unsafe effect cleanup, hidden state mutation, and render-time side effects. | UI behavior remains predictable and easy to review. |
| `test-integrity` | Require assertion-driven tests for rendered outcomes and interaction flows. | Tests prove user-visible behavior instead of smoke-only rendering. |

## Required Lens Checklist References

| Lens | Version | Activation Rationale |
| --- | --- | --- |
| `security-baseline` | `v1.0.0` | Public browser inputs and client-exposed configuration require security review. |
| `robustness-baseline` | `v1.0.0` | Effects, retries, and degraded browser behavior still need explicit handling. |
| `test-integrity` | `v1.0.0` | UI tests must validate rendered behavior, not only setup success. |

## Toolchain / Evidence Expectations

| Area | Concrete Selection | Evidence Expectation |
| --- | --- | --- |
| Package + test workflow | `npm` with `npm test` | Tests assert rendered outputs, interactions, and error handling. |
| Static feedback lane | Repo-standard frontend lint/static-analysis command | Component/state issues surface in reviewable output. |
| UI verification | Browser-oriented component/integration tests | Evidence covers visible state changes and not just mount success. |
| Governance artifacts | Preset reference plus iteration `quality/` artifacts | Reviewers can trace selected UI expectations to evidence. |

## Upgrade Guidance

1. Revisit this preset when routing, state-management, or browser-exposed security expectations change materially.
2. Upgrade lens references separately from preset version changes.
3. Keep Phase 1 scope explicit; do not imply later-phase browser hardening workflows from this baseline alone.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 preset for public React SPA quality governance. | Establishes stack-specific UI expectations with independently versioned lens references. |
