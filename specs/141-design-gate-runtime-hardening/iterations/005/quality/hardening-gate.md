# Hardening Gate: Iteration 005

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/005`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-03T18:30:00Z
**Post-Implementation Verification**: recorded — the three runtime-evidence concerns are verified: error-handling = graceful `@()` / "none available" on a missing lens file/section or absent answers JSON (extractor + render + coverage tests); test-integrity = SC-016 determinism + grandfather skip + placeholder-fails + no-op (`tests/unit/lens-applicability-selector.tests.ps1` 31/0, `tests/unit/design-analysis-gate.tests.ps1` 22/0); operability = LLM/network-free pure functions + `index.yml` purity (test-asserted) + grandfather safety (Iteration 4 not retroactively failed) + honest anti-omission framing (the gate string + docs do not overclaim). The dogfood converged and the delete-the-`Addressed:`-lines discriminator PASSED. Validator iteration-005 PASS. See review.md + coverage-evidence.md.
**Verified At**: 2026-06-03T19:30:00Z

**Pre-Implementation Readiness**: Iteration 005 delivers the complete lens package (Amendment A2, Option B): FR-009 decision-point surfacing into the option comparison + FR-026 lens-coverage gate (block `plan.md` when a selected lens is unaddressed). The design-analysis gate passed (Option B, decision commit `0e758032`). Scope: a pure decision-point extractor, an enriched read-only render, and a deterministic, LLM/network-free, grandfather-safe coverage gate. 17/20 SP, within cap. No release/publish; no Unix/wrapper/bootstrap surfaces; no push/PR. The catalog `index.yml` stays pure; deferred Proposal 156 deep scope (schema-validation enforcement, standalone command, auto-rationale, overrides) stays out (FR-010). The honest limit is recorded up front: FR-026 enforces anti-omission only — genuine engagement is human-gated + verified by the blocking delete-the-`Addressed:`-lines discriminator at review-signoff.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The extractor reads local lens files, the renderer writes a read-only section, and the gate reads the answers JSON + the artifact; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | The extractor + render + coverage gate MUST fail safe: a missing lens file or absent `## Design Decision Points` section yields `@()` / "none available" (never throw); a missing/empty `lens-applicability.json` makes the gate no-op; a malformed artifact does not corrupt `design-analysis.md`. | `true` | The defect class is missing/partial lens inputs; the control is fail-safe defaults covered by positive + negative tests (T005). Promoted to runtime-evidence after implementation. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state, or shared mutable resources; the extractor/render/gate are pure read/compute. (Determinism is covered under test-integrity.) | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | Tests MUST assert SC-016 as pure-function behavior: an unaddressed selected lens FAILS the gate and the failure NAMES it; an all-addressed artifact PASSES; a placeholder `Addressed:` entry FAILS; no-json / no-lenses no-ops; a pre-FR-026 artifact (no `Addressed:` entries) is grandfather-skipped; and identical inputs are deterministic. Plus the blocking delete-`Addressed:` discriminator at review (T006). | `true` | The coverage check is a pure function, so SC-016 is deterministically unit-testable; reproduce-first ensures each test proves the behavior, not file-presence. Promoted to runtime-evidence after implementation. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | Enforcement MUST be LLM/network-free (only the recorded answers + the authored coverage entries are inputs); it MUST keep `index.yml` PURE; it MUST be grandfather-safe (only FR-026-shaped artifacts enforced — no retroactive failure of Iteration 4); and it MUST NOT overclaim — the gate is anti-omission, not a quality guarantee. | `true` | FR-026/FR-010 require deterministic, decoupled, bounded, backward-compatible enforcement; operational correctness = no network/LLM, pure `index.yml`, grandfather safety, and honest framing. Promoted to runtime-evidence after implementation. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 005; no push/PR while Feature 141 is in progress.
- Implementation review must confirm no Unix install, shell wrapper, bootstrap, or release surfaces were touched, and that the Proposal 156 catalog `index.yml` was NOT modified (decoupled sibling map only).
- Deferred Proposal 156 deep scope (schema-validation enforcement, standalone command, auto-rationale, overrides) must stay out (FR-010).
- FR-026 must be grandfather-safe: re-validating Iteration 4's design-analysis (no `Addressed:` entries) must NOT fail.

## Notes

- The three `addressed` concerns were `planning-time-analysis` at planning time; they are now promoted to Evidence Basis `runtime-evidence` / Runtime Evidence Status `recorded` at review-signoff (the tests + dogfood ran — see Post-Implementation Verification + Verified At above; mirrors the Iteration 4 closure pattern).
- Overall Verdict is `ready` (planning-time gate); post-implementation closure is recorded for the review-signoff / iteration-complete state.
