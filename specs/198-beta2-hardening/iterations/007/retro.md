# Retrospective: Iteration 007

**Schema**: v1
**Date**: 2026-07-18
**Status**: accepted
**Human Authority**: approved for retro and separately approved for iteration-closeout on 2026-07-18
**Plan**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/plan.md
**State**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/state.md
**Drift Log**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/drift-log.md
**Review Evidence**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/007/review.md

## Summary

Iteration 007 delivered the production code-review path promised after the Iteration 005 architecture wall: five file-primary harness adapters, three native OS containment runtimes, strict result ingress, explicit spend authority, immutable partial/failure evidence, deterministic recovery, three-OS verification, live harness proof, and independent exact-digest signoff. All sixteen tasks are done. T061 run 13 cleanly reviewed commit `58869dfe343e1183c08e22ed1a1dd7419a75dc71` at digest `7c225e535f34597501ba1b3f0a80facfa7639e3e`; direct-child commit `b2d138dfd40cb2da418bff22ad0c06697f6fd80a` finalized exactly the six approved review artifacts through one immutable external binding fact. Finalization CI `29651549007` passed.

The implementation succeeded, but the cost model and interaction machinery need improvement. The five provider slots were a best-case floor; the iteration actually used 27 provider invocations across T060/T061. T061 alone required thirteen attempts, eleven invocations, twenty validated findings, and 3,887,031 ms of provider time. This was convergent—each correction was committed, tested, and narrowed the remaining risk—but it exposed the need for an explicit non-convergence stop rule before a future review loop becomes Iteration 005 again.

## What Went Well

- The architecture stayed simple at the authority boundary: reviewers wrote raw JSON to a unique candidate file, stdout never became authority, the repository remained the sole mutation authority, and controller-owned results retained currentness and containment evidence.
- All five harnesses and all three OS runtime mechanisms were exercised, not merely represented by interfaces. Codex/macOS, Antigravity/Windows, Copilot/Linux, and Claude/Windows produced clean exact-snapshot evidence; Cursor/Windows proved live execution and preserved the free-credit exhaustion honestly without a false clean claim.
- Strict ingress and immutable per-run artifacts made failures useful. Malformed output, partial results, timeouts, findings, quota failures, and clean results remained visible without salvage or hidden retries.
- The independent reviewer repeatedly found real integration edges that deterministic tests had missed. The finalization scope backfill, shared identity predicate, explicit-scope fail-closed guard, and concurrent `CreateNew` convergence are stronger because the paid review was allowed to challenge the trust machinery.
- The finalization envelope stayed within the maintainer's intended size and authority shape: one validator path, one immutable fact writer, gate wiring, and paired tests. It directly binds reviewed commit, reviewed digest, run, finalization commit, exact file allowlist, and displayed reviewed/finalized pair.
- The six-file allowlist worked as designed. It prevented the drift log from entering the finalization commit; this human-authorized retro commit now reconciles that lifecycle evidence without weakening the reviewed boundary.
- The final verification chain is concrete: 78/78 focused cases, all 57 registered F-198 suites in 707.8 seconds, scoped/gap governance, correction CI `29650851763`, exact no-spend preflight, clean T061 run 13, and finalization CI `29651549007`.

## What Was Hard

- Review cost exceeded the planning floor substantially. A five-slot base plan became 27 provider invocations across the iteration. T061 used eleven paid invocations over thirteen attempts and about 64m47s of provider runtime, excluding deterministic suites, CI, correction work, and human waiting.
- The review-evidence/currentness recursion was a real architecture trap: committing the required ledger moved the digest that the clean result approved. The bounded finalization envelope solved it, but only after multiple independent-review rounds exposed production-path, identity, and contention details.
- Live Mac proof imposed high operator friction. The local Mac was an older Intel machine with 8 GB RAM, operated through a web clipboard; installation, detached-worktree setup, command transfer, evidence return, and reruns were slow and error-prone even though the final package was valid.
- Cursor's free-account behavior and model selection were not predictable from the remaining-usage display. The controller correctly preserved unavailable/quota outcomes, but truthful support proof required several attempts without buying on-demand usage.
- The complete F-198 regression registry grew to 57 process-isolated suites and about 10–12 minutes per full run. Repeating it after every correction provided strong evidence but consumed a material part of the implementation window.
- Stop packets were sometimes emitted during ordinary discussion. The earlier same-HEAD material-key fix helped, but concurrent sessions exposed a separate attribution defect: sessions shared file:///C:/Dev/specrew-beta2-hardening/.specrew/runtime/conformance-material-baseline.json, so one session could be billed for another session's file changes.
- A timing-sensitive `HookRenderDedupe` fixture failed once on a shared two-core runner and passed on rerun and post-merge main CI. Evidence supports a race-fixture scheduling flake, not a product dedupe defect, but it still consumed investigation and reduced confidence in a single red result.

## Lessons Learned

1. Review convergence must be measured by finding lineage/class and count trend, not by total attempt count. Iteration 007's thirteen attempts continued to narrow risk; Iteration 005's repeated class/count pattern did not. The process needs a mandatory design reassessment when the same finding class recurs for three consecutive rounds or the validated finding count stops decreasing across three rounds.
2. A clean review result and committed review evidence are two different lifecycle facts. Generated review artifacts need a narrowly defined finalization mechanism that cannot modify code, tests, specifications, plans, tasks, or state and cannot form chains.
3. Session-local conversation accounting requires session-local attribution. A global material baseline is insufficient when an observer/reviewer session and an implementer session share a worktree.
4. Provider availability, account credit, model choice, and clean support are separate claims. Preflight and truthful incomplete evidence are more valuable than optimistic support labels.
5. Full-registry evidence is essential at committed boundaries, but repeating the entire serial registry in every inner loop is inefficient. Timing and bounded scheduling must improve without allowing a selected subset to become signoff evidence.
6. Timing-sensitive multi-process fixtures need explicit scheduling metadata. A serial tag and repeated-green proof are safer than interpreting a one-off race failure as either a product defect or harmless noise.
7. Old/remote machines are valid production targets, but operator handoffs need one copyable command, unique output paths, automatic packaging, and minimal round trips.

## Estimation Accuracy

The plan recorded 20.25 SP and the administrative actual column also totals 20.25 SP. Those values were not metered during execution, so they do not demonstrate zero variance. T060 and T061 materially exceeded their operational assumptions; no honest actual-SP value can be reconstructed after the fact.

| Task | Estimate | Recorded Actual | Retrospective Assessment |
| --- | ---: | ---: | --- |
| T030 | 0.75 | 0.75 | Delivered as planned. |
| T031 | 0.50 | 0.50 | Delivered as planned. |
| T032 | 0.50 | 0.50 | Delivered as planned. |
| T033 | 1.00 | 1.00 | Delivered plus two real stale-ledger corrections. |
| T034b | 0.50 | 0.50 | Delivered as the strict design-context residual. |
| T051 | 1.50 | 1.50 | Delivered public campaign cutover and gate. |
| T052 | 0.75 | 0.75 | Delivered, then absorbed one dogfood Stop-materiality correction. |
| T053 | 1.50 | 1.50 | Delivered shared contract and strict matrix. |
| T054 | 2.00 | 2.00 | Delivered Codex/Copilot adapters. |
| T055 | 2.00 | 2.00 | Delivered Cursor/Antigravity adapters. |
| T056 | 1.25 | 1.25 | Delivered Windows Job Object runtime. |
| T057 | 2.00 | 2.00 | Delivered Linux cgroup and macOS process-group runtimes. |
| T058 | 1.50 | 1.50 | Delivered progress, usage, and retro projection. |
| T059 | 1.50 | 1.50 | Delivered three-OS deterministic proof; registry growth increased recurring runtime. |
| T060 | 1.50 | 1.50 | Administrative value understates sixteen provider invocations, multi-OS provisioning, local-Mac handoffs, and correction cycles. |
| T061 | 1.50 | 1.50 | Administrative value materially understates thirteen attempts, eleven invocations, twenty findings, 3,887,031 ms provider time, corrections, CI, and finalization. |
| **Total** | **20.25** | **20.25** | Recorded total is a bookkeeping equality, not measured effort variance. |

## Operational Provider Calibration

- Planned successful-path floor: five provider invocations, expected about 52 minutes, with no preauthorized correction retry.
- T060 actual provider invocations: sixteen—Codex 2, Cursor 5, Antigravity 5, Copilot 4. Two earlier Cursor attempts stopped before invocation and correctly consumed no slot.
- T061 actual: thirteen attempts, eleven provider invocations/spend facts, twenty validated findings across the correction sequence, two clean passes, and no hidden retry.
- T061 provider duration: 3,887,031 ms, approximately 64m47s.
- Iteration total provider invocations: twenty-seven. A complete aggregate T060 provider-duration total was not centrally projected, so this retro does not invent one.
- Calibration change: future estimates must separate the base smoke floor from an observed correction reserve. The reserve is a planning range, never preauthorization to spend; each invocation remains visible and governed by the active human allowance.

## Drift Summary

- Total recorded events: 29, consisting of one inherited Iteration 006 event and 28 Iteration 007 events.
- Iteration 007: 27/28 resolved; DRIFT-198-I007-025 is explicitly deferred. Strict resolution rate is 96.4%; disposition coverage is 100%.
- DRIFT-198-I007-026 is resolved by the shipped controller-owned finalization envelope, clean run 13, its singular binding fact, reviewed/finalized display, and green finalization CI.
- DRIFT-198-I007-028 is resolved by correction commit `58869dfe343e1183c08e22ed1a1dd7419a75dc71`, correction CI `29650851763`, exact preflight, clean run 13, finalization commit `b2d138dfd40cb2da418bff22ad0c06697f6fd80a`, and finalization CI `29651549007`.
- DRIFT-198-I007-025 carries into the named stop/capture integrity repair. It is not silently resolved by the second-chance authority writer.
- Inherited DRIFT-198-I006-001 is resolved for Iteration 007 through T033's append-only correction door. The global matcher redesign remains backlog work and is not used as closeout authority.
- No Iteration 007 implementation drift remains blocking. The separate FR-048/FR-049/SC-015 Beta2 release dependency remains open outside this iteration.

## Reviewer-Instruction Triage

| Candidate | Decision | Rationale |
| --- | --- | --- |
| Finding-class/count non-convergence stop rule | PROMOTE | Prevents repeated point-fix loops while allowing a long but demonstrably narrowing review arc. |
| Per-session material baseline and attribution | PROMOTE | Concurrent sessions must not create false material-work packets for one another. |
| Injected environment-context exclusion and approval-plus-instructions normalization | PROMOTE | This is the exact DRIFT-198-I007-025 carry-forward and must retain strict boundary/bare-number controls. |
| `HookRenderDedupe` and similar timing-sensitive fixtures tagged `serial` | PROMOTE | The observed failure is consistent with a shared-runner race flake; explicit scheduling plus repeated-green proof preserves signal. |
| Small controller-owned review-evidence finalization envelope | PROMOTE | Reuse only for generated evidence with a direct parent, deny-by-default allowlist, one external fact, and no chains. |
| Proposal 209 implementation inside Iteration 007 closeout | DEFER | It is an engine optimization slice, not a Beta2 trust-foundation blocker. Schedule separately before the next correction-heavy hardening iteration or early Beta3. |
| DRIFT-198-I007-025 runtime point-fix during retro | DEFER | The defect needs a named repair with paired fixtures; retro is not authorization to mutate runtime code. |
| Fixed maximum number of review attempts | DROP | Attempt count alone would have stopped Iteration 007 despite continuing convergence. Use finding-class/count trend instead. |
| Change-scoped subset as boundary/signoff evidence | DROP | Subsets may speed the inner loop, but full registered verification remains mandatory for committed evidence and lifecycle boundaries. |

## Improvement Actions

| ID | Owner | Action | Completion Signal |
| --- | --- | --- | --- |
| IA-007-01 | Specrew review-methodology owner | Add a mandatory design-reassessment stop when the same validated finding class recurs for three consecutive review rounds or the validated finding count fails to decrease across three rounds. Persist round lineage so the rule is deterministic. | Paired convergent/non-convergent histories prove the stop fires only for the non-convergent case; further fix/rerun is blocked until human replan. |
| IA-007-02 | Stop/capture integrity repair owner | Resolve DRIFT-198-I007-025 and the multi-session material-attribution defect together: reject injected `<environment_context>` as verdict evidence, normalize leading explicit approval plus instructions while retaining the full instruction, key material baselines by session/owner, and prevent cross-session billing. | Paired injection, instruction-bearing approval, machinery, exact-boundary, bare-number, and concurrent-session fixtures pass. |
| IA-007-03 | Proposal 209 owner | Schedule W1 per-suite timing and W2 bounded parallel dispatch (initial worker pool approximately four), with `serial` tags for `HookRenderDedupe` and other timing-sensitive multi-process races. Require repeated-green proof before removing a serial tag. | Timing report identifies bottlenecks; serial-tagged races are stable; full-registry wall time improves without evidence loss. |
| IA-007-04 | Proposal 209 owner | After W1/W2 evidence, evaluate W3 change-scoped inner-loop selection and W4 measured hotspot repairs. Never use a selected subset as lifecycle-boundary evidence. | Inner-loop selector is conservative and explainable; full 57+ suite registry still runs for committed gates and signoff. |
| IA-007-05 | Planning/capacity owner | Separate provider base-floor, correction reserve, deterministic-suite runtime, CI time, and human/remote-machine handoff overhead in future capacity plans. | Next correction-heavy iteration contains an observed-cost range and stop conditions without preauthorizing slots. |

## Proposal 209 Scheduling Decision

Proposal 209, “Regression-Registry Performance — Per-Suite Timing, Throttled Parallel Dispatch, Change-Scoped Selection,” was merged to main through PR #3086 (proposal commit `dcf12937`, merge commit `b124b6f4`). It is not pulled into Iteration 007 and is not a Beta2 release blocker.

Schedule it as a separate Phase-2 engine optimization slice before the next correction-heavy hardening iteration, or early in Beta3. Start with W1 timing and W2 bounded parallel dispatch. Include `HookRenderDedupe` under explicit serial scheduling and repeat-stability proof. Consider W3 change-scoped selection only for the developer inner loop after timing data exists; full registry execution remains mandatory for committed evidence, CI release gates, and review signoff. W4 optimizes only measured hotspots.

## Signals for the Next Iteration

- Plan the open FR-048/FR-049/SC-015 command-plan supplier/injection dependency as its own Beta2 slice before T029 or feature closeout. Iteration 007 does not cover it.
- Name and schedule the stop/capture integrity repair carrying DRIFT-198-I007-025 and multi-session attribution; do not reopen it as an incidental point-fix.
- Schedule Proposal 209 W1/W2 before another correction-heavy review campaign if possible.
- Treat Cursor clean-current support as unproven until free credit resets or a separately authorized budget/model decision is made. Do not repeat an unchanged paid attempt.
- Preserve the finalization envelope's narrowness. Any attempt to add scripts, tests, specs/contracts, plan/tasks/state, a second fact, or an envelope chain is a new architecture decision and must fail closed.
- Keep trusted-reviewer stability above optimization. Progress heartbeats and faster registries are useful only when they do not weaken currentness, containment, termination, strict ingress, or immutable evidence.

## Process Notes

- The frequent five-section packet behavior is recorded as product/process friction, not dismissed as user error. Context packets belong after substantial work or a real handoff, not every few seconds during direct discussion.
- The multi-session attribution defect is separate from the already-resolved same-HEAD annotation issue. Both can produce awkward packets, but they require different fixes.
- The `HookRenderDedupe` incident is classified as a timing-sensitive fixture flake based on rerun and post-merge green evidence; this retro does not claim a product dedupe defect.
- This retro reconciles lifecycle artifacts after the deliberately narrow finalization commit. It does not mutate authority code, review code, tests, specifications, or contracts; iteration closeout was authorized separately against retro boundary commit `744e77d8086234bd8dfde3fbc6237abd226319ae`.
