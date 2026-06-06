# Hardening Gate: Iteration 007

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/007`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-04T11:20:00Z
**Post-Implementation Verification**: recorded — the deterministic floor is verified (agenda generator, per-lens schema, the SC-021 presence-gate now firing at the specify boundary, the decisions render — selector/gate/feature suites green) and the MANDATORY runtime dogfood RAN (testLenses3) and validated the workshop conduct (SC-020). The dogfood also caught the SC-021 floor not firing on the feature-level artifact → fixed (`a0b78cbc`, re-homed to the specify boundary) + re-tested with a real-layout negative case. error-handling = graceful `@()`/"none" + gate-fails-not-crashes (tested); test-integrity = the deterministic floor + the specify-gate negative case + the dogfood as the conduct's acceptance; operability = LLM/network-free, marker-gated + grandfather-safe, `index.yml` pure. See review.md / retro.md.
**Verified At**: 2026-06-04T13:30:00Z

**Pre-Implementation Readiness**: Iteration 007 turns the lens intake into a per-lens facilitated design workshop (Amendment A4, Option B). The design-analysis gate passed (decision commit `57974536`, draft `ad7bea7e`). Scope: a deterministic discussable-prompt (agenda) generator built on `Get-SpecrewLensDecisionPoints`, a per-lens decision schema + the SC-021 coverage-gate extension (presence-only floor), the behavioral workshop conduct prompt rule, the FR-009 per-phase flow (carried from i006), the deterministic-floor tests, and the MANDATORY runtime dogfood (SC-020). 19/20 SP. The Iteration 4-6 engine is retained; deferred Proposal 156 deep scope stays out (FR-010); `index.yml` stays pure; no release/Unix/wrapper surfaces; no push/PR. **The honest constraint (carried into review): the workshop conduct is behavioral — unit tests cover the deterministic floor only; the runtime dogfood is the real acceptance evidence (maintainer instruction #4).**

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The generator reads local lens files, the gate reads the answers/decision JSON + the artifact, and the conduct is prompt-driven; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The agenda generator MUST fail safe (missing lens file or absent `## Design Decision Points` → `@()` / "none available", never throw); the SC-021 gate MUST FAIL (name the lens), never crash, on a missing/placeholder per-lens record; an interrupted workshop re-asks the current lens rather than writing a partial record. | `true` | The defect class is missing/partial lens inputs + partial intake; the control is fail-safe defaults + re-ask, covered by positive + negative tests (T005). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, or transactional state; the workshop asks → records per lens, and a deliberate re-run re-asks. The generator + gate are pure read/compute. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Tests MUST assert: the agenda is generated from the lens decision points; the per-lens schema fields (agenda, decision/agreement, depth, "move on" marker) round-trip; the SC-021 gate FAILS and NAMES the lens when any selected lens's record is missing or placeholder; back-compat (grandfathered artifacts). PLUS the **mandatory runtime dogfood (SC-020)** — the conduct quality is NOT unit-provable. | `true` | The generator + gate are pure → deterministically unit-testable; the workshop conduct must be exercised in a real downstream run (instruction #4), not asserted by unit tests. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | The generator + gate MUST be LLM/network-free; the conduct is coordinator-prompt-driven; the SC-021 gate enforces non-placeholder PRESENCE only and MUST NOT claim to assess quality; `index.yml` stays pure; FR-028 persisted-vs-console references honored; no deferred Proposal 156 scope. | `true` | A4/FR-010 require deterministic, decoupled, honestly-scoped behavior; operational correctness = no network/LLM in the generator/gate, presence-only enforcement, and honest framing that the gate is not a quality guarantee. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 007; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the generator/gate are LLM/network-free, `index.yml` was NOT modified, and the deferred Proposal 156 deep scope stayed out (FR-010).
- The review MUST include the **mandatory runtime dogfood (SC-020)** — a real downstream workshop run, lens by lens — not only the deterministic-floor unit tests (maintainer instruction #4).
- Persisted `.md` artifacts use markdown links; console packets use visible `file:///` URLs (maintainer instruction #5 / FR-028).

## Notes

- The three `addressed` concerns were `planning-time-analysis` at planning time; now promoted to `runtime-evidence` / `recorded` at review-signoff — the deterministic-floor tests ran (green) AND the runtime dogfood ran (SC-020 validated; it also caught + drove the SC-021 fix). See Post-Implementation Verification + Verified At above.
- Overall Verdict is `ready` (planning-time gate); post-implementation closure recorded at review-signoff. The conduct-quality bar is the dogfood, not the unit tests.
