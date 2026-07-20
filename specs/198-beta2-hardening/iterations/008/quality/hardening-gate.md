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
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | T068/T069 and T062–T065 carry paired false-allow/false-deny fixtures. T066 attempt 01 exposed ambient-only self-plan proof; plan v5 declares the required environment names. Attempt 02 exposed spend on an already-red plan; paired campaign fixtures now stop that failure before harness preflight/spend. Attempts 03/04 exposed a machinery-stripped verification snapshot; pinned tracked support is now staged only for verification and removed before reviewer preflight. Attempt 05 exposed plan-level clock reuse plus empty-support/rollback edges; observed serial-clock, conditional-teaching, and two-layer fail-loud rollback fixtures now cover them. Attempt 06 exposed tracked-plan collision, live vocabulary rescan, failure-path rebaseline, and vestigial degradation plumbing; current-plan precedence, frozen-vocabulary currentness, success-only rebaseline, and contract-removal fixtures now cover them. Attempt 07 verified those corrections and found support lifecycle clean, then exposed recovery-binding/reason observability and a generic snapshot-integrity failure. Attempt 08 proved the changed-path diagnostic, then exposed scalar-array canonicalization and ambient user-setting leakage. Attempt 09 triggered the third integrity recurrence; zero-spend proof then isolated controller self-tamper and malformed strict-MCP startup. T071 now runs verification in a disposable exact-digest copy, projects evidence externally, OS-protects the untouched reviewer target before host preflight, and corrects the Claude vector. | `true` | File presence, fake-provider success, ambient-only execution, a tag, an incomplete repository snapshot, fabricated time ordering, self-consistent but unbound support scope, a lost recovery binding, malformed immutable arrays, controller writes misattributed to a reviewer, or a paid reviewer restating controller failure cannot prove the finish line. | `—` |
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
| `condition-b-traceability` | `met` | 19/19 tasks map to valid selected requirements and 32/32 selected requirements have coverage in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md after the T071 replan. | Any orphan or uncovered requirement reopens the gate. |
| `condition-c-fail-direction-review` | `met` | Stale crossing, injected context, invalid explicit config, unsafe path, missing plan, command failure, stale evidence, and release uncertainty all refuse authority or approval. | A fail-direction change requires recorded drift and replan. |
| `condition-d-capacity-discipline` | `met-with-explicit-overcommit` | 31.5/26 SP includes T068–T071, supplier/injection, distribution, all seven observed T066 correction classes, deterministic proof, review, release, and dogfood. The +17% stress forecast over the 12.75 SP open-work baseline was 33.67/26. | The authorized T071 replan makes the 5.5 SP overcommit and 7.67 SP stress overage explicit; add no optional scope silently. |
| `condition-e-live-state-safety` | `met-with-scoped-control` | The tasks verdict names plan commit `08e86496`; the stale `744e77d8`/`542c54f0` record carries no authority. Canonical sync at exact task commit `29cf84084fd65da9f4199466a9aa4dccc5105958` then returned success with no pending verdict and null pending identity despite the open crossing. | Treat both results as DRIFT-198-I008-001 evidence, never authority. Until T068 passes, use only exact commit/tree plus explicit verdict text for crossings. |
| `condition-f-t069-ceiling` | `met` | T069 completed at 2.25 SP with its injected-context, instruction-retention, machinery, exact-boundary, bare-number, stale/current, dispatcher-delivery, and barrier-synchronized multi-session matrix green; all 60 registered suites passed in 788.5 seconds. | Further stop/capture expansion requires separate scope; T069 does not absorb it. |
| `condition-g-provider-authority` | `met` | Task/before-implement authorization granted zero provider invocations. T066 attempts 01, 02, 05, 06, 07, 08, and 09 each spent exactly one separately recorded Claude slot. Attempts 03 and 04 stopped during controller verification with zero invocation/spend and released reservations. T071 used zero provider slots; its local proof and exact-commit hosted run `29775507402` passed, so the non-convergence guard is explicitly reset. | Every later provider action still requires a new run ID, one immutable slot fact, changed evidence, no hidden retry, and the non-convergence stop rule. |
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

Attempt 06 targeted commit `29dfd7cfabc89c0f7d0eb64f3738bdffc12a2a0e`, digest
`c0b8a57f49f69ac3eb8c422f44716a694cf592d7`. Exact-commit CI run `29704267055` passed all eight jobs and the
campaign completed its exact plan before one Claude invocation. Its valid current incomplete result found one major
tracked-plan collision, one minor live-vocabulary inconsistency, and two notes covering failure-path rebaseline and
unreachable degrade plumbing. The correction freezes/hash-binds the canonical machinery vocabulary, reuses it for
pinned support contents, keeps the current captured plan outside support restore/removal, re-baselines only after
success, and removes the unreachable field/consumer. Focused coverage, including frozen-vocabulary binding refusal,
passes 37/37; the preceding expanded eleven-file set records 175 passed with one platform skip and the committed
campaign owns final exact-candidate full proof. At that point, another support-lifecycle finding would have reached
the third consecutive support-class round; attempt 07 instead found that area clean.

Attempt 07 targeted commit `d8b4251898274eb17a596090802ae2ff1e978cb0`, reproducible digest
`c41f49fc4fab36107bb7a9cf1820b17aafe8829c`. Exact-commit CI run `29706211050` passed all eight jobs; controller
evidence passed the 73-suite registry in 951.3 seconds and governance in 14.8 seconds before one Claude invocation.
The valid current incomplete reviewer result verified all attempt-05/06 corrections, explicitly found the support
lifecycle convergence-watch area clean, and reported one minor recovery-binding gap plus one note-level reason-
masking gap. Provider finding counts for rounds 05/06/07 are 3/4/2, so no non-convergence rule fired. The run also
ended `containment-violated` after post-runtime snapshot integrity changed; the old controller did not retain the
changed-path cause. The correction round-trips every target binding through immutable recovery facts, keeps reasons
additive, runs Claude non-persistently with user-only settings, and records bounded relative changed paths on any
future integrity failure. Focused production-path coverage passes 98/98.

Attempt 08 targeted commit `24c3a9020d4d1b194aad1f6526320d8703a3a7ce`, reproducible digest
`f3faf55678b775f247afb8e8263a5374bcb885bd`. Exact-commit CI run `29707876205` passed all eight jobs and the
controller completed deterministic preflight before exactly one Claude invocation. The process exited 1 without a
candidate; integrity refused the modified snapshot and, as designed, retained `.review/implementer-evidence.json`
and `.scratch/distribution-module-update/**` paths. The persisted recovery fact also showed its string path array
had become `{Length}` objects during canonicalization. The correction preserves scalar arrays before object
canonicalization, proves the real fact through CreateNew/read/currentness, loads no user/project/local Claude
settings, disables skills and ambient MCPs, restricts built-in tools to Read/Glob/Grep plus candidate-only Write,
and hardens the prompt against commands or other writes. Changed suites pass 44/44; the six focused suites total
109/109. Snapshot-integrity failure has recurred in attempts 07/08; one further recurrence stops for replan.

Attempt 09 targeted commit `6667a3739ca487d41ef90df34d235783468d599a`, reproducible digest
`2c29cb53005f7cc314d0734539dd6dde6aedbcb2`, and exact-commit CI run `29709194209`. Controller verification was
green, then Claude exited 1 without a candidate after one immutable spend; integrity repeated the same `.review/**`
and `.scratch/**` class for the third consecutive round. T066 therefore paused under the non-convergence rule.
The authorized zero-provider T071 proof showed the full mutation list came from controller verification, not the
reviewer; isolated the invalid strict-MCP `{}` startup vector; and implemented disposable exact-digest verification,
external CreateNew evidence, OS read-only target protection/recovery, and the corrected MCP document. Focused
production coverage passes 86/86. After correcting six end-to-end fixtures that still expected target-local evidence,
the failed suite passed 11/11, the final full registry passed all 73 suites in 763.2 seconds, and scoped governance
passed in 11.6 seconds with historical warnings only. Hosted run `29771340851` then failed all three deterministic
jobs before spend at target protection: Linux CI runs as uid 0, macOS requires BSD-compatible chmod arguments, and
Windows needed recursive denies for explicit child allows. The corrected Windows sequence and privileged-Linux
production path pass locally under Pester 5.7.1; the corrected full registry passes 73/73 in 783.5 seconds and
scoped governance passes in 11.2 seconds. Exact-commit hosted retry `29775507402` passes all eight jobs, including
the Windows, privileged-Ubuntu, and macOS deterministic containment jobs. Push run `29773556546` was cancelled after
an unrelated macOS runner wedge and is not authority. The T066 guard is reset; fresh candidate preparation remains.

### T066 Attempt and Slot Ledger

| Attempt | Run ID | Target | Provider invocations / slots | Outcome | Disposition |
| --- | --- | --- | --- | --- | --- |
| 01 | `run-t066-claude-windows-8daac538-e03a4139-01` | commit `8daac53888f29c47cab0c23531e9fbf53ec38729`, digest `e03a413985002981933eccdbcd7b25c5b6c6df96` | 1 / 1 | valid `incomplete`; containment reported violated after both configured commands failed; two blocking findings and one major finding | retained as non-approving evidence; correct self-plan environment contract and rerun only under a new exact grant |
| 02 | `run-t066-claude-windows-0625d8cb-7cdbaccd-02` | commit `0625d8cbeda13b54c98a8233728adc6acf543659`, digest `7cdbaccde22045e9335c6eb1e3435188c5d78539` | 1 / 1 | valid `incomplete`; both configured commands recorded red; two blocking and three major findings; later bounded diagnostic reproduction green | retained as non-approving intermittent evidence; make red verification a zero-spend preflight failure, reprove exact candidate, then use a new run ID |
| 03 | `run-t066-claude-windows-9b37b05e-2105a405-03` | commit `9b37b05ec5b06a146cc6f5c2f93ee20091c1ba64`, digest `2105a405bc03674ea49b203a23e97625574816af` | 0 / 0 | failed before provider at 896.6s; both commands red; reservation released | retained as zero-spend evidence; initial outer-timeout diagnosis required falsification before retry |
| 04 | `run-t066-claude-windows-9b37b05e-2105a405-04` | same commit/digest as attempt 03 | 0 / 0 | failed before provider at 907.0s under a 2100s bound; reservation released; retained snapshot diagnosed stripped tracked machinery | retained as zero-spend root-cause evidence; correct controller-only pinned support lifecycle before a new candidate/run |
| 05 | `run-t066-claude-windows-fe17e387-5602cb72-05` | commit `fe17e3878875962d9bf5a63b6eafb851c3c7319f`, digest `5602cb721abf943bbd39a4c9cf53b229422da18d` | 1 / 1 | exact CI and controller verification green; valid current `incomplete`; one major, one minor, one note finding | retained as non-approving evidence; correct per-command clocks, conditional support teaching, and fail-loud two-layer rollback before a new candidate/run |
| 06 | `run-t066-claude-windows-29dfd7cf-c0b8a57f-06` | commit `29dfd7cfabc89c0f7d0eb64f3738bdffc12a2a0e`, digest `c0b8a57f49f69ac3eb8c422f44716a694cf592d7` | 1 / 1 | exact CI and controller verification green; valid current `incomplete`; one major, one minor, and two note findings | retained as non-approving evidence; freeze/currentness-bind support vocabulary, preserve current-plan precedence, retain failure baseline, and remove unreachable degradation plumbing before a new candidate/run |
| 07 | `run-t066-claude-windows-d8b42518-c41f49fc-07` | commit `d8b4251898274eb17a596090802ae2ff1e978cb0`, digest `c41f49fc4fab36107bb7a9cf1820b17aafe8829c` | 1 / 1 | exact CI/controller verification green; valid current `incomplete`; one minor and one note finding; snapshot integrity forced `containment-violated` without durable changed-path detail | retained as non-approving evidence; round-trip recovery bindings, preserve all currentness reasons, isolate Claude session settings, and retain bounded integrity diagnostics before a new candidate/run |
| 08 | `run-t066-claude-windows-24c3a902-f3faf556-08` | commit `24c3a9020d4d1b194aad1f6526320d8703a3a7ce`, digest `f3faf55678b775f247afb8e8263a5374bcb885bd` | 1 / 1 | exact CI/controller verification green; process exit 1; candidate not produced; integrity retained `.review/**` and `.scratch/**` changes; recovery path array persisted as `{Length}` objects | retained as non-approving evidence; preserve scalar arrays and remove ambient Claude settings/skills/MCP/command tools before a new candidate/run; one more integrity recurrence stops for replan |
| 09 | `run-t066-claude-windows-6667a373-2c29cb53-09` | commit `6667a3739ca487d41ef90df34d235783468d599a`, digest `2c29cb53005f7cc314d0734539dd6dde6aedbcb2` | 1 / 1 | exact CI/controller verification green; process exit 1 after provider launch; candidate not produced; integrity repeated the `.review/**` and `.scratch/**` class | retained as the third non-approving recurrence; T066 paused and guard locked while zero-spend T071 proves controller-self-tamper, corrected startup, disposable verification, external evidence, and OS read-only containment |

## Required Evidence at Review

- T068 current/stale crossing pairs using the observed pre-closeout-parent class, stable repeat rendering, and
  bare-number refusal.
- T069 injected `<environment_context>`, full instruction-bearing approval, machinery/teaching, exact-boundary,
  shared-baseline, and barrier-synchronized multi-session fixtures.
- T062/T063 precedence, explicit-invalid, no-source, inactive-provider, extension-bait, stable-output,
  hash-matching refresh, and modified-plan preservation evidence.
- T064/T065 frozen-target origin invariance, ordered every-attempt execution, exact digest/command join,
  duplicate/unjoinable/stale refusal, and zero-spend invalid-plan/configured-command preflight evidence.
- T071 untouched-control/disposable-verification byte proof, external CreateNew implementer evidence, strict empty-MCP
  provider-free startup, OS read-only false-allow/false-deny pairs, and normal/lost-lease cleanup on supported OSes.
- T066 persisted recovery-fact scalar-array/target-binding round-trip, additive multi-cause currentness, isolated
  non-persistent Claude settings/tools vector, and bounded relative changed-path evidence for any integrity failure.
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
