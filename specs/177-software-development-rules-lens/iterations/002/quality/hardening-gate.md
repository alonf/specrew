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
**Post-Implementation Verification**: recorded -- runtime evidence produced at iteration-closeout (deployed dogfood T017 + multi-host parity T016); the behavioral SC-004 / SC-007 / SC-008 are deferred-with-gate (D-003) to the published-beta human dogfood
**Verified At**: 2026-06-10T17:50:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | The `specrew-code-rules` skill is a read-only reader (resolve active feature, read the manifest, surface rules). No auth, secrets, PII, or network. The catalog's secure-coding rules are content it surfaces, not a feature surface. | `true` | i2 adds a reader skill + workshop conduct; the security surface remains content-vs-feature-surface (light), confirmed at review. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open is the load-bearing robustness: no manifest -> baseline; unknown rule id -> warn + skip; malformed overlay -> warn + use shipped; never crash or silently skip. Unit-fixtured (T015); demonstrated in the dogfood (T017). | `true` | The skill's only failure modes are degradations; T015 fixtures them + T017 demonstrates them on the deployed module. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | The skill is a synchronous read-only reader; the workshop write is single-writer idempotent (i1). No network/queue/shared mutable runtime state. | `false` | No retry/idempotency surface (recorded so the omission stays reviewable). | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Behavior-proving: guidance-skill baseline+overlay + baseline-only + fail-open + dependency_policy surfacing (T015) + multi-host parity (T016) GREEN. The **deployed dogfood** (T017) VERIFIED deployment wiring + manifest-authoring on the 0.35.0 module; the BEHAVIORAL SC-004 / SC-007 / SC-008 are NOT proven by the dogfood -- they are DEFERRED-WITH-GATE (D-003) to the published-beta human dogfood. | `true` | Unit + parity green and the deployed-module wiring + manifest-authoring verified; the behavioral acceptance (agent actually guided / no rule wall / dependency stance honored) is the open D-003 beta-gate, not claimed here. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Multi-host: `specrew-code-rules` deploys to every host skill surface via the existing engine (added as data, T011), guarded by the parity test (T016); release adds the FileList + extension.yml bump + .specify mirror (T018). | `true` | The portability story is the deploy-parity test (T016) + the F-176-class release checklist (T018); the only failure mode is a missing host surface, which the parity test surfaces. | `—` |

## Notes

- Planning-time pre-implementation gate for **iteration 002 (i2 — delivery + guidance)**. Unlike i1, i2
  HAS a runtime surface (the guidance skill + the workshop conduct), so the load-bearing acceptance is the
  **deployed-module dogfood** (T017): installed-module layout, fresh `specrew init`, agent actually guided,
  no rule wall, dependency stance honored. Unit + parity tests are necessary, not sufficient.
- `retry-idempotency` is `not-applicable` (synchronous read-only reader), recorded so it stays reviewable.
- The runtime-bearing concerns (error-handling, test-integrity, operational) were
  `pending-post-implementation` at the planning gate and are now `recorded` at iteration-closeout: the
  runtime evidence (the deployed dogfood T017 + the parity test T016) has been produced. The dogfood
  verified deployment wiring + manifest-authoring on the 0.35.0 module; the **behavioral SC-004 / SC-007 /
  SC-008 are NOT proven by it -- DEFERRED-WITH-GATE (D-003)** to the published-beta human dogfood, which
  gates stable promotion. `security-surface` + `retry-idempotency` are `not-needed` (no runtime surface).
- Release (T018) ships `v0.35.0-beta.1` first (universal beta-before-stable); promotion only after the
  manual install-and-dogfood PASS.
