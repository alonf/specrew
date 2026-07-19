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
**Post-Implementation Verification**: correction verification in progress; independent exact-digest review pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Explicit configuration precedence; versioned allowlisted metadata detectors; safe repository-relative canonical paths; no secret values in plan/evidence; frozen external target; origin unchanged; repository-only code mutation. | `true` | Supplier inputs and executable commands cross project/reviewer trust boundaries and must not create path, secret, or mutation authority. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | T065 proves invalid explicit config, no source, and escaping paths stop before harness preflight, command execution, or spend; its pass/fail/pass plan records every attempt and remains non-approving. T064 plus the adjacent join suites refuse stale, duplicate, and unjoinable evidence. | `true` | Missing configuration, command failure, and stale authority cannot become silent success. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | T063 records the generated plan hash in a sidecar, performs no write when current, refreshes/removes only a hash-matching generated file, preserves any modified or explicit file byte-for-byte with an actionable warning, and exercises init/update production wiring. Review/release retry controls remain task-owned by T064/T066/T029. | `true` | Setup, review, and release have durable side effects whose replay must not overwrite user work or duplicate authority/spend. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | T068/T069 and T062–T065 carry paired false-allow/false-deny fixtures. T066 attempt 01 exposed ambient-only self-plan proof; plan v5 declares the required environment names. Attempt 02 exposed spend on an already-red plan; paired campaign fixtures now stop that failure before harness preflight/spend. Attempts 03/04 exposed a machinery-stripped verification snapshot; pinned tracked support is now staged only for verification and removed before reviewer preflight. Attempt 05 exposed plan-level clock reuse plus empty-support/rollback edges; observed serial-clock, conditional-teaching, and two-layer fail-loud rollback fixtures now cover them. | `true` | File presence, fake-provider success, ambient-only execution, a tag, an incomplete repository snapshot, fabricated time ordering, or a paid reviewer restating controller failure cannot prove the finish line. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Bounded command timeouts; pre-provider validation; controller-owned terminal evidence; visible setup/remediation; hash-guarded update; release workflow observation; non-convergence stop rule; T069 hard ceiling. | `true` | The slice changes downstream setup, CI, review preflight, and prerelease publication behavior. | `—` |
| `crossing-binding-and-capture-integrity` | `authorization-integrity` | `addressed` | `runtime-evidence` | `recorded` | T068 binds actual closeout commit/tree and rejects stale parent identity; T069 excludes injected context, preserves instruction-bearing approval through the real writer, scopes material state by session/owner, rejects machinery/teaching/bare-number input, and passes a barrier-synchronized two-session attribution fixture. | `true` | Both defect classes produced misleading or rejected boundary authority in real sessions. | `—` |
| `supplier-provenance-and-no-default` | `input-integrity` | `addressed` | `runtime-evidence` | `recorded` | The pure T062 selector enforces fixed precedence and explicit-invalid short circuit over normalized named identities. A closed mirrored catalog contains only one unambiguous package-script detector plus explicitly selected stack profiles; provider rows are supported but empty by default. Fourteen paired tests prove extension bait and inactive providers select nothing, no-source is actionable, output identity is stable, and provenance carries no supplied secret. | `true` | A convenient invented command would be unproven authority over downstream verification. | `—` |
| `exact-digest-evidence-injection` | `evidence-integrity` | `addressed` | `runtime-evidence` | `recorded` | T064 freezes the selected-plan bytes, runs T018 before provider launch, and requires one exact digest + command-ID join per declaration. T065 carries explicit, metadata, profile, provider, mixed-technology, safe-path, no-source, invalid, escape, and failed-command projects through the real materializer and campaign path; together with the adjacent join suites it proves ordered every-attempt evidence, exact injection, stale/duplicate/unjoinable refusal, zero preflight spend, and unchanged origin HEAD/status. | `true` | Useful evidence for another tree must remain visible but cannot approve the current tree. | `—` |
| `consumer-distribution-mutation` | `distribution-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Deny-by-default deploy set; provider gating; deployed-path fixtures; hash-guard retired-file healing; modified-file warning/preservation; applicability provenance; greenfield/brownfield separation. | `true` | Init/update changes consumer repositories and must not deploy self-host assumptions or overwrite user edits. | `—` |
| `release-and-promotion-separation` | `release-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Seven version surfaces agree; T066 clean signoff precedes release; T029 requires fresh release authorization; published tag/workflow evidence recorded; T067 installs published bits and records PASS/FAIL; no stable tag or promotion. | `true` | Implementation authorization, provider authorization, beta publication, and stable promotion are distinct authorities. | `—` |
| `performance-and-cost` | `performance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Stability remains P0; bounded command/provider timeouts; preflight before spend; one base signoff slot; visible correction slots; three-round non-convergence stop; record suite/provider wall time. | `false` | Review time and tokens matter, but optimization cannot weaken integrity or containment. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The human gave `approved for before-implement`, bound to task commit `364fbe88ef29cce5ac74d8086c1d78d8b8363197` and tree `1e5cf50256303efc81d6282315d1818ff2eebae4`; the hook-captured ledger entry records the exact crossing. | Implementation is authorized. Provider and release slots remain separate. |
| `condition-b-traceability` | `met` | 18/18 tasks map to valid selected requirements and 32/32 selected requirements have coverage in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md after the T066 reprice. | Any orphan or uncovered requirement reopens the gate. |
| `condition-c-fail-direction-review` | `met` | Stale crossing, injected context, invalid explicit config, unsafe path, missing plan, command failure, stale evidence, and release uncertainty all refuse authority or approval. | A fail-direction change requires recorded drift and replan. |
| `condition-d-capacity-discipline` | `met` | 25.0/26 SP includes T068/T069/T070, supplier/injection, distribution, all four observed T066 correction classes, deterministic proof, review, release, and dogfood. The +17% open-work stress forecast is 26.06/26. | Preserve the remaining 1.0 SP nominal headroom, add no scope, and keep the 0.06 SP calibration risk visible. |
| `condition-e-live-state-safety` | `met-with-scoped-control` | The tasks verdict names plan commit `08e86496`; the stale `744e77d8`/`542c54f0` record carries no authority. Canonical sync at exact task commit `29cf84084fd65da9f4199466a9aa4dccc5105958` then returned success with no pending verdict and null pending identity despite the open crossing. | Treat both results as DRIFT-198-I008-001 evidence, never authority. Until T068 passes, use only exact commit/tree plus explicit verdict text for crossings. |
| `condition-f-t069-ceiling` | `met` | T069 completed at 2.25 SP with its injected-context, instruction-retention, machinery, exact-boundary, bare-number, stale/current, dispatcher-delivery, and barrier-synchronized multi-session matrix green; all 60 registered suites passed in 788.5 seconds. | Further stop/capture expansion requires separate scope; T069 does not absorb it. |
| `condition-g-provider-authority` | `met` | Task/before-implement authorization granted zero provider invocations. T066 attempts 01, 02, and 05 each spent exactly one separately recorded Claude slot and retained their valid incomplete results. Attempts 03 and 04 stopped during controller verification with zero invocation/spend and released reservations. The maintainer later granted standing bounded correction/review authority while progress is demonstrable. | Every provider action still requires a new run ID, one immutable slot fact, changed evidence, no hidden retry, and the non-convergence stop rule. |
| `condition-h-release-authority` | `met` | T029 remains separately gated after clean T066 evidence. | Do not tag or publish under implementation approval. |
| `condition-i-promotion-boundary` | `met` | T067 is explicitly validate-not-promote. | Record published-beta evidence; never create a stable release. |
| `condition-j-proposal-209` | `met` | Proposal 209 remains separately scheduled in plan/tasks/state. | Do not fold its optimization or redesign into Iteration 008. |

Plan-boundary cross-platform CI run `29659141998` completed successfully at commit `08e86496`. That confirms the
committed planning baseline; it does not replace the post-implementation T066 three-OS run.

Initial T066 deterministic preparation passed all 72 registered Feature 198 suites locally in 998.6 seconds, explicit
Iteration 008 governance in 18.0 seconds with historical warnings only, and all jobs in hosted three-OS run
`29666927862` at commit `b97dd633`. T066 attempt 01 then proved that ambient-only evidence was insufficient: both
configured commands failed under the production runner's intentionally empty child environment because the
project plan declared no `env_refs`. Plan v5 now names only the required ambient variables, including Windows
application lookup, nested-process state, and common-data resolution outside the repository, and carries a paired
production-runner regression. The corrected candidate therefore required its own hosted run before another
provider request. Code candidate
`9dc0c10d1125a22645bd4d6545c70c145a7e4db0` then passed the production plan: all 73 suites in 814.881 seconds,
scoped governance in 13.436 seconds, and unchanged canonical digest
`ee374f3685cebfae153a63fd525d95f18e04dc01`. Hosted three-OS run `29693858260` also passed on that commit.
Attempt 02 nevertheless recorded both commands red at successor digest `7cdbaccd` and spent a provider slot because
the campaign treated red verification as reviewer context instead of a pre-spend stop. A bounded no-provider
diagnostic reproduction then passed the 73-suite registry and governance under the same constructed environment.
The corrected campaign now stops red verification before harness preflight or spend and directs the operator to the
existing human-authorized command-scoped diagnostic path. Exact-candidate full/CI proof and independent review must
be rerun before this field can become complete; no green claim is committed ahead of that digest's proof.

Attempts 03 and 04 targeted commit `9b37b05ec5b06a146cc6f5c2f93ee20091c1ba64`, digest
`2105a405bc03674ea49b203a23e97625574816af`, and both failed before provider invocation with released
reservations. The longer 2100-second fourth attempt disproved an outer-timeout diagnosis. Retained bounded
diagnostics showed the canonical reviewer tree had stripped tracked `.specify`, `.squad`, and `.specrew` support
required by the declared verification plan. The correction stages only tracked machinery from the pinned commit,
removes it before reviewer preflight, and proves the canonical digest unchanged; the final purge/baseline code
passes the expanded production matrix 86/86. Its immediate precursor passed all 73 registered suites in 845.1
seconds; the committed campaign pre-spend run owns the final full proof. T066 remains open pending the recut
candidate's exact-commit CI and independent result.

Attempt 05 targeted commit `fe17e3878875962d9bf5a63b6eafb851c3c7319f`, digest
`5602cb721abf943bbd39a4c9cf53b229422da18d`. Exact-commit three-OS CI run `29702808115` passed every job; the
campaign then passed all 73 registered suites in 900.3 seconds and governance in 10.9 seconds before invoking
Claude once. Its valid current incomplete result found one major per-command timestamp defect, one minor false
support-teaching defect, and one note-level rollback-observability defect. The correction removes caller clocks
from the production recorder, conditionally renders support teaching, and always attempts exact cleanup plus full
machinery purge with combined diagnostics. Focused tests record 32 passed with one platform skip; the expanded
ten-file set records 157 passed with one platform skip. A recut exact candidate still needs CI, full controller verification, and
fresh independent review.

### T066 Attempt and Slot Ledger

| Attempt | Run ID | Target | Provider invocations / slots | Outcome | Disposition |
| --- | --- | --- | --- | --- | --- |
| 01 | `run-t066-claude-windows-8daac538-e03a4139-01` | commit `8daac53888f29c47cab0c23531e9fbf53ec38729`, digest `e03a413985002981933eccdbcd7b25c5b6c6df96` | 1 / 1 | valid `incomplete`; containment reported violated after both configured commands failed; two blocking findings and one major finding | retained as non-approving evidence; correct self-plan environment contract and rerun only under a new exact grant |
| 02 | `run-t066-claude-windows-0625d8cb-7cdbaccd-02` | commit `0625d8cbeda13b54c98a8233728adc6acf543659`, digest `7cdbaccde22045e9335c6eb1e3435188c5d78539` | 1 / 1 | valid `incomplete`; both configured commands recorded red; two blocking and three major findings; later bounded diagnostic reproduction green | retained as non-approving intermittent evidence; make red verification a zero-spend preflight failure, reprove exact candidate, then use a new run ID |
| 03 | `run-t066-claude-windows-9b37b05e-2105a405-03` | commit `9b37b05ec5b06a146cc6f5c2f93ee20091c1ba64`, digest `2105a405bc03674ea49b203a23e97625574816af` | 0 / 0 | failed before provider at 896.6s; both commands red; reservation released | retained as zero-spend evidence; initial outer-timeout diagnosis required falsification before retry |
| 04 | `run-t066-claude-windows-9b37b05e-2105a405-04` | same commit/digest as attempt 03 | 0 / 0 | failed before provider at 907.0s under a 2100s bound; reservation released; retained snapshot diagnosed stripped tracked machinery | retained as zero-spend root-cause evidence; correct controller-only pinned support lifecycle before a new candidate/run |
| 05 | `run-t066-claude-windows-fe17e387-5602cb72-05` | commit `fe17e3878875962d9bf5a63b6eafb851c3c7319f`, digest `5602cb721abf943bbd39a4c9cf53b229422da18d` | 1 / 1 | exact CI and controller verification green; valid current `incomplete`; one major, one minor, one note finding | retained as non-approving evidence; correct per-command clocks, conditional support teaching, and fail-loud two-layer rollback before a new candidate/run |

## Required Evidence at Review

- T068 current/stale crossing pairs using the observed pre-closeout-parent class, stable repeat rendering, and
  bare-number refusal.
- T069 injected `<environment_context>`, full instruction-bearing approval, machinery/teaching, exact-boundary,
  shared-baseline, and barrier-synchronized multi-session fixtures.
- T062/T063 precedence, explicit-invalid, no-source, inactive-provider, extension-bait, stable-output,
  hash-matching refresh, and modified-plan preservation evidence.
- T064/T065 frozen-target origin invariance, ordered every-attempt execution, exact digest/command join,
  duplicate/unjoinable/stale refusal, and zero-spend invalid-plan/configured-command preflight evidence.
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
