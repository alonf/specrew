# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/012-descriptive-id-handoffs/spec.md`
**Iteration Ref**: `specs/012-descriptive-id-handoffs/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: strongest-available
**Overall Verdict**: ready
**Approval Ref**: —
**Reviewed By**: pending
**Reviewed At**: pending
**Post-Implementation Verification**: pending
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | This slice adds replay fixtures, replay assertions, corpus rows, and documentation updates only. No authentication boundaries, trust-domain crossings, secrets, or runtime services are introduced. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Replay tests and corpus/documentation updates must fail clearly when commands, fixtures, or evidence files drift. The iteration must preserve the existing soft-warning behavior and record any validation failure without silently skipping the replay lane. | — | The main risk is stale or partial evidence recording, not a new runtime exception path. Runtime confirmation is still pending because T012-T020 have not started. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | Iteration 002 does not introduce retries, queued work, or duplicate-write semantics. Re-running the replay lane and documentation updates should remain deterministic file-based work rather than a new idempotency contract. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The replay-path tests must use the real authored-message governance review path, include must-warn and must-pass fixtures, and preserve excluded-surface handling. The closeout lane must rerun the existing three handoff-governance tests alongside the new replay scripts and governance validation. | `false` | Test integrity is the core delivery risk for US3. Planning can define the controls now, but runtime evidence remains pending until T012-T019 execute. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Corpus and documentation updates must stay synchronized with replay outputs, and the feature-level quality follow-through artifacts must be updated without losing the pre-implementation planning gate. Any drift must be logged immediately in `drift-log.md`. | `false` | This slice is still repository-bound work, but it has a coordination risk across replay, corpus, documentation, and feature-level quality artifacts. The planned controls are sufficient for readiness; runtime proof remains pending. | — |
| `integration-test-replay-path-coverage` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T012-T014 must build fixtures and assertions that prove the authored-prose and excluded-surface rules through the real replay path. T017 must execute the replay lane and record evidence against those fixtures before closeout can continue. | `true` | Replay-path coverage is the highest-risk execution concern because the iteration exists primarily to prove durable runtime behavior rather than to add new guidance text. If the real review path is not exercised, the iteration fails its purpose. | — |
| `corpus-seeding-completeness` | `governance-compliance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T015 must seed descriptive-reference warn/pass examples in `.specrew/quality/known-traps.md` and keep `validation-lane.md` aligned to the same replay commands. T016 and T019 must then record the feature-level follow-through artifacts without dropping corpus evidence. | `true` | Corpus seeding is a named closure expectation for this slice and a direct guard against losing the low-noise rule in future work. Planning is complete, but the required runtime evidence is still pending. | — |
| `documentation-polish-fidelity` | `documentation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T018 must update `quickstart.md` and feature-level plan notes only after the final replay and closeout commands are known. Documentation must describe the actual validation lane and feature-level quality follow-through paths in readable terms. | `false` | Documentation is not the highest-risk delivery item, but it can still drift from the executed lane if updated too early or copied by hand. The iteration keeps this bounded to late-slice polish. | — |
| `regression-preservation` | `compatibility` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T017 and T019 must preserve the existing handoff-governance regression lane and confirm the readable-reference warning remains additive and non-blocking. T020 must audit the final diff to verify no Iteration 001 or feature 007 guidance is weakened. | `true` | This is a named high-risk concern because the new replay-path proof could accidentally narrow or over-tighten an existing low-noise governance path. Blocking status is appropriate until the existing regression lane reruns green. | — |
| `us1-integration-with-feature-007` | `integration` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Replay and closeout evidence must show that readable-reference governance continues to coexist with the feature 007 handoff-governance baseline. The existing three handoff-governance tests and the final diff audit are the required controls. | `false` | Feature 012 builds on feature 007's established review surfaces, so integration continuity must stay visible even though the new iteration scope is narrow. Runtime evidence will be recorded after the replay and closeout lanes finish. | — |

## Planning Notes

- This draft uses the richer pre-sign-off convention: `Overall Verdict: ready` with pending review metadata and pending post-implementation verification fields.
- The five canonical concerns appear first in the required order, followed by the five feature-specific concerns in the requested order.
- The three named high-risk concerns are explicitly marked `Blocking: true`: `integration-test-replay-path-coverage`, `corpus-seeding-completeness`, and `regression-preservation`.
- Runtime evidence remains pending because this file is a planning artifact, not execution proof.
