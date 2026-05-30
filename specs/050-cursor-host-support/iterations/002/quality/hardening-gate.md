# Hardening Gate: Iteration 002

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/050-cursor-host-support/spec.md`  
**Iteration Ref**: `specs/050-cursor-host-support/iterations/002`  
**Requested Review Class**: `phase-1-custom-composition`  
**Effective Review Class**: phase-1-custom-composition  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Specrew Crew Coordinator  
**Reviewed At**: 2026-05-29  
**Post-Implementation Verification**: pending — to be completed after implement (new integration smoke runs/skips cleanly; detection-matrix assertion green; full host suite stays green).  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Iteration 002 adds tests only; no production code, no auth/secret surface. The auto-approve-flag + secret-handling controls were established and verified in iter-001. | `false` | Test-only iteration introduces no new privileged behavior. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The new integration smoke must skip-guard cleanly when `cursor-agent` is absent (no hard failure on CI runners), and assert the launch-invocation error/notice paths. | `false` | The main risk of a launch smoke is CI breakage on binaryless runners; skip-guarding is the control. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry/idempotency surface added; tests are deterministic. | `false` | N/A for a test-coverage iteration. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | New tests must be assertion-driven (not smoke-only): the launch smoke asserts the built argv (interactive `"<prompt>" --workspace`, `--force` only under allow-all), the version-probe fixture asserts real-binary detection, the detection assertion verifies cursor is in the probe matrix. | `false` | This is the test-hardening iteration; its own integrity bar is that the added tests prove behavior, not merely execute. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Added tests must not destabilize the existing green host suite; real-binary cases are skip-guarded; no shared fixtures mutated. | `false` | Resilience risk is a flaky/binary-dependent test breaking CI; skip-guards + deterministic asserts mitigate. | — |
| `maintainability` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | New tests follow the established `Write-Pass`/`Write-Fail` `tests/integration/host-*.tests.ps1` idiom for consistency. | `false` | Uniform test idiom keeps the suite reviewable. | — |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | No concurrency surface. | `false` | Deterministic tests; no shared mutable state. | — |

## Planning Evidence Notes

- Iteration 002 scope: T011–T013 (test coverage). FR-005 unit tests were delivered in iter-001; iter-002 adds the launch integration smoke (FR-006) + a real-binary version-probe fixture + an explicit detection-matrix assertion (FR-007).
- The five canonical hardening concerns appear first in the required order.
- No production code changes planned — this is a test-only iteration; the mirror-parity item from iter-001 remains the tracked feature-closeout action (no new framework-source edits here).

## Hardening-Gate Status

**Overall Verdict**: ready — a test-only iteration with all material risks (CI binary-dependence, test integrity) addressed via skip-guards + assertion-driven tests, or marked not-applicable.

**Scope**: Iteration 002 — Cursor host test coverage (launch integration smoke + real-binary fixture + detection-matrix assertion), ~2.5 story_points.
