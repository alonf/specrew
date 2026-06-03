# Hardening Gate: Iteration 004

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/004`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-03T15:38:13Z
**Post-Implementation Verification**: recorded — the three runtime-evidence concerns are verified: error-handling = graceful "none available" on absent map/answers (selector + render tests); test-integrity = SC-015 determinism + SC-006 scope + the never-hide-an-always-on-lens + MD049 guards (`tests/unit/lens-applicability-selector.tests.ps1`, 27/0); operability = LLM/network-free pure selector + `index.yml` purity (test-asserted) + no over-suppression. Dogfood render converged (render == JSON selected). Validator iteration-004 PASS. See review.md + coverage-evidence.md.
**Verified At**: 2026-06-03T16:13:59Z

**Pre-Implementation Readiness**: Iteration 004 delivers questionnaire-driven Applicable-Lenses selection (FR-009/FR-010/FR-025; SC-006/SC-015; TG-006) per Amendment A1. Substantive; the design-analysis gate passed (Option B decoupled, decision commit 51b31aaf). Scope: a sibling question->lens map file (catalog `index.yml` stays pure), a `lens-applicability.json` answers artifact, and a pure deterministic selector + read-only render. 14/20 SP, within cap. No release/publish; no Unix/wrapper/bootstrap surfaces; no push/PR. Deferred Proposal 156 deeper scope (overrides, schema-validation enforcement, broad automation, standalone command, rationale automation) stays out (FR-010).

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The selector reads local lens files + the answers JSON and renders a read-only section; no auth, secrets, network, eval, or persistence-of-credentials surface. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The selector + render MUST fail safe: missing/empty catalog or missing answers degrade gracefully to "none available" (never throw/crash); malformed answers resolve to a safe empty/foundational set rather than corrupting `design-analysis.md`. | `true` | The defect class is missing applicability inputs; the fix is fail-safe defaults covered by positive + negative tests. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state, or shared mutable resources; the selector is a pure read/compute/render. (Determinism is covered under test-integrity.) | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Tests MUST assert SC-015 determinism (identical answers -> identical selected set across runs) + the JSON audit, SC-006 selection scope + graceful degradation, the map-gating correctness, and that an always-on lens is NEVER hidden — as runtime behavior of a pure function, not file-presence. | `true` | The selector is a pure function, so determinism + gating are deterministically unit-testable; reproduce-first ensures each test proves the behavior. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Selection MUST be LLM/network-free (only the recorded answers are judgment input; the map is mechanical); it MUST keep the catalog `index.yml` PURE (decoupled sibling map); and it MUST NOT mis-hide a gated lens or pull deferred Proposal 156 automation. | `true` | FR-025/FR-010 require deterministic, decoupled, scoped selection; operational correctness = no network/LLM, pure index.yml, no over-suppression. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 004; no push/PR while Feature 141 is in progress.
- Implementation review must confirm no Unix install, shell wrapper, bootstrap, or release surfaces were touched, and that the Proposal 156 catalog `index.yml` was NOT modified (decoupled sibling map only).
- Deferred Proposal 156 deeper scope (overrides, schema-validation enforcement, broad automation, standalone command, per-lens rationale) must stay out (FR-010).

## Notes

- Runtime evidence (determinism, degradation, test counts, dogfood convergence) was collected after implementation. The three `addressed` concerns are now promoted to Evidence Basis `runtime-evidence` / Runtime Evidence Status `recorded` (see Post-Implementation Verification + Verified At above).
- Overall Verdict is `ready` (planning-time gate); post-implementation closure recorded for the review-signoff / iteration-complete state.
