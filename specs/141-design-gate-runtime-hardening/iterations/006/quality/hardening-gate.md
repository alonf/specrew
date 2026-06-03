# Hardening Gate: Iteration 006

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/006`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-04T08:00:00Z

**Pre-Implementation Readiness**: Iteration 006 re-scopes the lens intake to interactive + expertise-adapted + inside specify (Amendment A3, Option B + the maintainer placement rule). The design-analysis gate passed (decision commit `3e610c4a`). Scope: a pure dial→depth mapping helper, lifecycle wiring so the intake completes before specify-sync (accepted spec is lens-informed), the lens-decision-point flow into specify/clarify/plan, the FR-028 file-reference render helper + handoff bare-path fix, and the FR-029 FileList-sort guard. 19/20 SP (tight; contingency splits FR-028/FR-029 if the wiring overruns). The Iteration 4-5 engine is retained; deferred Proposal 156 deep scope stays out (FR-010). No release/Unix/wrapper surfaces; no push/PR. The human-experience dogfood (the gap Iteration 5's retro named) is a required review step.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The intake reads the user-profile dials + lens files and writes `lens-applicability.json`; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The intake + helpers MUST fail safe: absent/unreadable user-profile dials fall back to a default interaction depth; an absent catalog or skipped intake degrades to "none available"; an interrupted intake re-asks rather than writing a partial selection; a malformed answer never corrupts `spec.md`. | `true` | The defect class is missing/partial intake inputs; the control is fail-safe defaults + re-ask, covered by positive + negative tests (T006). | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, or transactional state; the intake asks → records once, and a deliberate re-run re-asks. The dial→depth helper + file-ref renderer are pure. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Tests MUST assert: dial→depth mapping (deterministic, per dial level); intake JSON recording + the before-specify-sync placement; lens-decision-point availability to specify/clarify/plan; FR-028 render contexts (console `file:///` vs persisted markdown) + the handoff bare-path no-false-positive on `RRT/Bug1` / `FR/SC`; FR-029 no spurious downstream warning. Plus the human-experience dogfood (interactive run), per Iteration 5's retro. | `true` | The helpers are pure → deterministically unit-testable; the human-experience must be exercised, not only the mechanics. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The dial→depth + file-ref helpers MUST be LLM/network-free; the interactive asking is coordinator-prompt-driven (the Crew asks via the host primitive); the placement invariant (intake completes before specify-sync) MUST hold; FR-028 references MUST be context-correct; FR-029 MUST not warn downstream; `index.yml` stays pure; no deferred 156 scope. | `true` | A3/FR-010 require deterministic, decoupled, placement-correct, bounded behavior; operational correctness = no network/LLM in the helpers, the placement invariant, and honest scope. | `—` |

## Release-Blocking Items

- No beta or stable release publishing is in scope for Iteration 006; no push/PR while Feature 141 is in progress.
- Implementation review must confirm the placement invariant (the accepted `specify` output is lens-informed — intake before sync-specify) and that the Proposal 156 catalog `index.yml` was NOT modified.
- Deferred Proposal 156 deep scope (overrides, schema-validation enforcement, broad automation) must stay out (FR-010).
- The review MUST include the human-experience dogfood (interactive dial-adapted intake run), not only unit tests — the Iteration 5 retro lesson.

## Notes

- The three `addressed` concerns are `planning-time-analysis` at planning time; promoted to `runtime-evidence` / `recorded` at review-signoff once the tests + the human-experience dogfood run.
- Overall Verdict is `ready` (planning-time gate); post-implementation closure recorded at review-signoff.
