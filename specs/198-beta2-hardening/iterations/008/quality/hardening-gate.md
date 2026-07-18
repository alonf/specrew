# Hardening Gate: Iteration 008

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/198-beta2-hardening/spec.md`
**Iteration Ref**: `specs/198-beta2-hardening/iterations/008`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner
**Reviewed At**: 2026-07-18
**Post-Implementation Verification**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Explicit configuration precedence; versioned allowlisted metadata detectors; safe repository-relative canonical paths; no secret values in plan/evidence; frozen external target; origin unchanged; repository-only code mutation. | `true` | Supplier inputs and executable commands cross project/reviewer trust boundaries and must not create path, secret, or mutation authority. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Invalid explicit config fails without fallback; no source is actionable `verification-not-configured`; malformed plan stops before commands/spend; every attempted command is recorded; failure/timeout/invalid result remains non-approving; stale crossing/evidence fails closed. | `true` | Missing configuration, command failure, and stale authority cannot become silent success. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Hash-guard generated-plan refresh; preserve modified project content; stable selection identity; one evidence join per command; no hidden provider retry; new run ID and human grant per invocation; tag publication separately authorized. | `true` | Setup, review, and release have durable side effects whose replay must not overwrite user work or duplicate authority/spend. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Paired false-allow/false-deny fixtures for T068/T069 and every supplier source; mixed-command order/every-attempt evidence; exact/stale joins; consumer shape fixtures; full registry; three-OS CI; independent exact-digest review; published-beta dogfood. | `true` | File presence, fake-provider success, or a tag alone cannot prove the finish line. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Bounded command timeouts; pre-provider validation; controller-owned terminal evidence; visible setup/remediation; hash-guarded update; release workflow observation; non-convergence stop rule; T069 hard ceiling. | `true` | The slice changes downstream setup, CI, review preflight, and prerelease publication behavior. | `—` |
| `crossing-binding-and-capture-integrity` | `authorization-integrity` | `addressed` | `runtime-evidence` | `recorded` | T068 binds actual closeout commit/tree and rejects stale parent identity; T069 excludes injected context, preserves instruction-bearing approval through the real writer, scopes material state by session/owner, rejects machinery/teaching/bare-number input, and passes a barrier-synchronized two-session attribution fixture. | `true` | Both defect classes produced misleading or rejected boundary authority in real sessions. | `—` |
| `supplier-provenance-and-no-default` | `input-integrity` | `addressed` | `runtime-evidence` | `recorded` | The pure T062 selector enforces fixed precedence and explicit-invalid short circuit over normalized named identities. A closed mirrored catalog contains only one unambiguous package-script detector plus explicitly selected stack profiles; provider rows are supported but empty by default. Fourteen paired tests prove extension bait and inactive providers select nothing, no-source is actionable, output identity is stable, and provenance carries no supplied secret. | `true` | A convenient invented command would be unproven authority over downstream verification. | `—` |
| `exact-digest-evidence-injection` | `evidence-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Reuse T018; run from frozen target; join exact digest plus unique command ID; reject duplicate/missing/unjoinable/stale evidence; inject bounded matching evidence once; origin clean before/after. | `true` | Useful evidence for another tree must remain visible but cannot approve the current tree. | `—` |
| `consumer-distribution-mutation` | `distribution-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Deny-by-default deploy set; provider gating; deployed-path fixtures; hash-guard retired-file healing; modified-file warning/preservation; applicability provenance; greenfield/brownfield separation. | `true` | Init/update changes consumer repositories and must not deploy self-host assumptions or overwrite user edits. | `—` |
| `release-and-promotion-separation` | `release-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Seven version surfaces agree; T066 clean signoff precedes release; T029 requires fresh release authorization; published tag/workflow evidence recorded; T067 installs published bits and records PASS/FAIL; no stable tag or promotion. | `true` | Implementation authorization, provider authorization, beta publication, and stable promotion are distinct authorities. | `—` |
| `performance-and-cost` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Stability remains P0; bounded command/provider timeouts; preflight before spend; one base signoff slot; visible correction slots; three-round non-convergence stop; record suite/provider wall time. | `false` | Review time and tokens matter, but optimization cannot weaken integrity or containment. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The human gave `approved for before-implement`, bound to task commit `364fbe88ef29cce5ac74d8086c1d78d8b8363197` and tree `1e5cf50256303efc81d6282315d1818ff2eebae4`; the hook-captured ledger entry records the exact crossing. | Implementation is authorized. Provider and release slots remain separate. |
| `condition-b-traceability` | `met` | 17/17 tasks map to valid selected requirements and 32/32 selected requirements have coverage in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md. | Any orphan or uncovered requirement reopens the gate. |
| `condition-c-fail-direction-review` | `met` | Stale crossing, injected context, invalid explicit config, unsafe path, missing plan, command failure, stale evidence, and release uncertainty all refuse authority or approval. | A fail-direction change requires recorded drift and replan. |
| `condition-d-capacity-discipline` | `met` | 18/26 SP includes T068/T069, supplier/injection, distribution, deterministic proof, review, release, and dogfood. | Preserve the 8 SP headroom; do not hide extra scope. |
| `condition-e-live-state-safety` | `met-with-scoped-control` | The tasks verdict names plan commit `08e86496`; the stale `744e77d8`/`542c54f0` record carries no authority. Canonical sync at exact task commit `29cf84084fd65da9f4199466a9aa4dccc5105958` then returned success with no pending verdict and null pending identity despite the open crossing. | Treat both results as DRIFT-198-I008-001 evidence, never authority. Until T068 passes, use only exact commit/tree plus explicit verdict text for crossings. |
| `condition-f-t069-ceiling` | `met` | T069 completed at 2.25 SP with its injected-context, instruction-retention, machinery, exact-boundary, bare-number, stale/current, dispatcher-delivery, and barrier-synchronized multi-session matrix green; all 60 registered suites passed in 788.5 seconds. | Further stop/capture expansion requires separate scope; T069 does not absorb it. |
| `condition-g-provider-authority` | `met` | Task/before-implement authorization grants zero provider invocations. | T066 requires a separate slot, new run ID, and no hidden retry. |
| `condition-h-release-authority` | `met` | T029 remains separately gated after clean T066 evidence. | Do not tag or publish under implementation approval. |
| `condition-i-promotion-boundary` | `met` | T067 is explicitly validate-not-promote. | Record published-beta evidence; never create a stable release. |
| `condition-j-proposal-209` | `met` | Proposal 209 remains separately scheduled in plan/tasks/state. | Do not fold its optimization or redesign into Iteration 008. |

Plan-boundary cross-platform CI run `29659141998` completed successfully at commit `08e86496`. That confirms the
committed planning baseline; it does not replace the post-implementation T066 three-OS run.

## Required Evidence at Review

- T068 current/stale crossing pairs using the observed pre-closeout-parent class, stable repeat rendering, and
  bare-number refusal.
- T069 injected `<environment_context>`, full instruction-bearing approval, machinery/teaching, exact-boundary,
  shared-baseline, and barrier-synchronized multi-session fixtures.
- T062/T063 precedence, explicit-invalid, no-source, inactive-provider, extension-bait, stable-output,
  hash-matching refresh, and modified-plan preservation evidence.
- T064/T065 frozen-target origin invariance, ordered every-attempt execution, exact digest/command join,
  duplicate/unjoinable/stale refusal, failed-command non-approval, and zero-spend invalid-preflight evidence.
- T021–T028 GitHub/unset-provider init, Beta1-shaped update, local-only/publish-target, Python/non-Pester,
  non-GitHub, no-publish, deny-list, prompt-fixture, and applicability-provenance evidence.
- T066 focused and full suites, scoped governance, three-OS hosted CI, provider attempt/slot ledger, and one
  complete valid current exact-digest independent review or explicit blocked outcome.
- T029 seven-surface/version/credential/tag-workflow evidence plus the separate release authorization.
- T067 exact published-beta source and maintainer PASS/FAIL per SC-014 friction class, with no stable promotion.

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/198-beta2-hardening/iterations/008/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/198-beta2-hardening/iterations/008/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/198-beta2-hardening/iterations/008/quality/lenses/test-integrity.md` |

## Notes

- `Overall Verdict: ready` means planning-time hardening is complete and ready for the human before-implement
  decision. It authorizes neither implementation nor provider/release spend.
- Runtime evidence remains pending until its owning task executes.
- No selected concern is deferred. Generic non-code adapters, automatic campaign pruning, stable promotion, and
  Proposal 209 remain explicit exclusions.
