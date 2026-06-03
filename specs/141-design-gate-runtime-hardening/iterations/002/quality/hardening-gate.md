# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-02T21:40:00Z
**Post-Implementation Verification**: recorded — the three runtime-evidence concerns are verified by the targeted feature-141 suites (FR-011 Test 9b; FR-014 Test 18b; FR-024 start-recovery-flow e2e + session-recovery unit; T004 gate clean-exit guard), 86 pass / 0 fail, mechanical lenses 0 findings, validator iteration 002 PASS. See coverage-evidence.md + review.md.
**Verified At**: 2026-06-03T01:11:16Z

**Pre-Implementation Readiness**: Iteration 002 is a bug-fix / hardening slice — start-packet correctness (FR-011 empty `specs//` paths, FR-014 host-wording leak), the stale cross-worktree session-recovery fix (FR-024, folded in 2026-06-02), and two non-blocking smoke-2 cleanup items. 16/20 SP, within cap, nothing dropped. Design-analysis is not required (defect repair with confirm-gated cleanup, no architectural fork). No release/publish; no Unix/wrapper/bootstrap surfaces.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The slice fixes generated-prompt path strings and host-conditional wording; it introduces no auth, secrets, network, eval, or persistence surface. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The empty-path guard must handle an unresolved/empty feature ref gracefully (omit or placeholder the path, never emit `specs//`); host-conditional wording must default safely for any selected host. | `true` | The defect is precisely a missing guard on an empty path segment; the fix is a fail-safe default, covered by positive + negative tests. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state, or shared resources; pure generated-string repair. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Tests must assert no `specs//` segment in generated paths, per-host wording correctness (no Copilot text on a Claude launch), and a clean gate-harness exit — runtime behavior, not file-presence. | `true` | Start-packet correctness is verifiable by generating a packet and asserting the output; reproduction-first (T001) ensures the test proves the fix. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Stale cross-worktree session recovery (FR-024) must fail safe: classify stale state, never re-anchor to a deleted external worktree, and clear only runtime session references (no feature-artifact touch, no lifecycle commits) behind explicit human confirmation. | `true` | FR-024 adds session-state recovery hardening; recovery must not corrupt or falsely resume state, and cleanup must be confirm-gated and artifact-safe. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 002.
- Implementation review must confirm no Unix install, shell wrapper, bootstrap, or release surfaces were touched.
- The four smoke-bundle defects must stay within Feature 141 (FR-015); Iteration 2 closes FR-011 and FR-014, leaving FR-012/FR-013 for Iteration 3.

## Notes

- Runtime evidence is now RECORDED post-implementation: the three blocking concerns (error-handling-expectations, test-integrity-targets, operational-resilience-concerns) are promoted to Evidence Basis `runtime-evidence` / Runtime Evidence Status `recorded`, verified by the targeted suites + the FR-024 end-to-end enforcement test (see Post-Implementation Verification above).
- Overall Verdict is `ready` (planning-time gate); post-implementation closure is recorded via Post-Implementation Verification / Verified At for the iteration-complete state.
