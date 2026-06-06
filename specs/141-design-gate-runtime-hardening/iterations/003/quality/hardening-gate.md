# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-03T01:30:00Z
**Post-Implementation Verification**: recorded — the three runtime-evidence concerns are verified by the targeted suites: FR-012 warning scope by SC-008 (`feature-051-iteration2b` 21/0 — single-dev bootstrap → no signal/recommendation, 2-author repo → recommendation still fires, the over-suppression guard); FR-013 fail-safe + resolution by SC-009 (`design-gate-runtime-hardening-greenfield-baseline` 6/0 — zero-commit → no stamp / no auto-commit / guidance, post-commit → resolves to HEAD + consistent, non-corrupting); validator iteration-003 PASS. See review.md + coverage-evidence.md.
**Verified At**: 2026-06-03T12:34:05Z

**Pre-Implementation Readiness**: Iteration 003 is a bug-fix / hardening slice — greenfield/downstream hygiene: suppress spurious governance/runtime warnings (FR-012, US5) and fix fresh-greenfield baseline-commit handling (FR-013, US6); FR-015 keeps these in this feature. 10/20 SP, within cap. Design-analysis is not required (defect repair, no architectural fork). Reproduce-first + classify-before-fix is mandatory (maintainer instruction 2026-06-03): T001 captures fresh greenfield + downstream transcripts and classifies every warning actionable-vs-spurious before any suppression. No release/publish; no Unix/wrapper/bootstrap surfaces; no push/PR (feature in progress).

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | Warning suppression + baseline-commit handling introduce no auth, secrets, network, eval, or persistence surface. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Warning suppression must default safely — suppress ONLY classes T001 classified spurious, never hide a genuinely-actionable warning; baseline-commit resolution must fail safe when git history is minimal/absent (resolve a real hash or surface an explicit, non-corrupting state). | `true` | The defects are a missing applicability guard (warnings) and missing/placeholder baseline resolution; the fixes are fail-safe defaults, covered by positive + negative tests. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state, or shared resources; greenfield warning-gating + baseline-commit read/record only. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Tests must assert greenfield/downstream warning scope (SC-008: no spurious warnings outside the actionable set) and fresh-greenfield baseline-commit resolution + cross-file consistency (SC-009) as runtime behavior, not file-presence; reproduce-first + classify-before-fix (T001) so each test proves the fix. | `true` | Warning scope and baseline resolution are verifiable by running `specrew init`/`specrew start` in greenfield + downstream fixtures and asserting the transcript and start-context/boundary state. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Suppressing warnings must not lose genuinely-actionable signal (classify before suppress); baseline-commit handling must not corrupt boundary state or leave start-context.json inconsistent with the recorded baseline. | `true` | FR-012/FR-013 are operability hardening for greenfield/downstream runs; suppression must be precise and baseline recording consistent across start-context and boundary state. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 003; no push/PR while Feature 141 is in progress.
- Implementation review must confirm no Unix install, shell wrapper, bootstrap, or release surfaces were touched.
- FR-015: the smoke-bundle defects stay within Feature 141. Iteration 2 closed FR-011/FR-014; Iteration 3 closes FR-012/FR-013.

## Notes

- Runtime evidence (warning classification, baseline-resolution proof, test counts) was collected after implementation. The three `addressed` concerns are now promoted to Evidence Basis `runtime-evidence` / Runtime Evidence Status `recorded`, verified by the targeted suites + the prove-first discriminator (see Post-Implementation Verification + Verified At above).
- Overall Verdict is `ready` (planning-time gate); post-implementation closure is recorded via Post-Implementation Verification / Verified At for the review-signoff / iteration-complete state.
