# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/177-software-development-rules-lens/spec.md`
**Iteration Ref**: `specs/177-software-development-rules-lens/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-10T12:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | The `specrew-code-rules` skill is a read-only reader (resolve active feature, read the manifest, surface rules). No auth, secrets, PII, or network. The catalog's secure-coding rules are content it surfaces, not a feature surface. | `true` | i2 adds a reader skill + workshop conduct; the security surface remains content-vs-feature-surface (light), confirmed at review. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fail-open is the load-bearing robustness: no manifest -> baseline; unknown rule id -> warn + skip; malformed overlay -> warn + use shipped; never crash or silently skip. Unit-fixtured (T015); demonstrated in the dogfood (T017). | `true` | The skill's only failure modes are degradations; T015 fixtures them + T017 demonstrates them on the deployed module. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | The skill is a synchronous read-only reader; the workshop write is single-writer idempotent (i1). No network/queue/shared mutable runtime state. | `false` | No retry/idempotency surface (recorded so the omission stays reviewable). | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Behavior-proving: guidance-skill baseline+overlay + baseline-only + fail-open + dependency_policy surfacing (T015); multi-host parity (T016); and the **deployed dogfood** proving SC-004 (agent guided), SC-007 (no rule wall), SC-008 (dependency stance honored) (T017). | `true` | i2's acceptance bar is the dogfood + parity; "passes" means the agent is actually guided on the deployed module, not file-presence. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Multi-host: `specrew-code-rules` deploys to every host skill surface via the existing engine (added as data, T011), guarded by the parity test (T016); release adds the FileList + extension.yml bump + .specify mirror (T018). | `true` | The portability story is the deploy-parity test (T016) + the F-176-class release checklist (T018); the only failure mode is a missing host surface, which the parity test surfaces. | `—` |

## Notes

- Planning-time pre-implementation gate for **iteration 002 (i2 — delivery + guidance)**. Unlike i1, i2
  HAS a runtime surface (the guidance skill + the workshop conduct), so the load-bearing acceptance is the
  **deployed-module dogfood** (T017): installed-module layout, fresh `specrew init`, agent actually guided,
  no rule wall, dependency stance honored. Unit + parity tests are necessary, not sufficient.
- `retry-idempotency` is `not-applicable` (synchronous read-only reader), recorded so it stays reviewable.
- The runtime-bearing concerns (error-handling, test-integrity, operational) are
  `pending-post-implementation` at this planning gate; the pending runtime evidence is the deployed dogfood
  (T017) + the parity test (T016), updated to `recorded` at i2 review/closeout. `security-surface` +
  `retry-idempotency` are `not-needed` (no runtime surface). The gate is ready for the start-implementation go-ahead.
- Release (T018) ships `v0.35.0-beta.1` first (universal beta-before-stable); promotion only after the
  manual install-and-dogfood PASS.
