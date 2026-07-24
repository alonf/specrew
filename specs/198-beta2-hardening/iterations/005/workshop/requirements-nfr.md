# Requirements and NFR reassessment

**Status**: complete
**Iteration**: 005

## Confirmed priority profile

```text
P0  correctness, stability, authority, containment, recovery
 |
 +--> must hold before a result can approve the current target

P1  diagnostics, cost, performance, traceability, workshop UX
 |
 +--> optimized and measured without weakening P0

Not driving  distributed scale, service availability, telemetry infrastructure
```

| Priority | Quality driver | Measurable requirement |
|---|---|---|
| P0 | Authority integrity | No incomplete, invalid, containment-violating, or snapshot-moved result can approve the current target. |
| P0 | Origin safety | Pre/post HEAD and canonical target digest are compared; movement is reported while findings remain visible. Reviewer execution observed under the origin is a containment violation. |
| P0 | Allowance correctness | Concurrent acquisition creates at most one active claim per lineage; reservations and spend never exceed human-granted allowance. |
| P0 | Runtime control | At the configured deadline, the complete process tree is terminated and verified dead before timeout-result publication. The default maximum termination grace is 10 seconds and is configurable. |
| P0 | Harness completeness | Claude, Codex, Copilot, Cursor, and Antigravity each complete one bounded real review that produces valid JSON and Markdown. |
| P0 | Platform completeness | Windows, macOS, and Linux runtime adapters each pass real process-tree containment and timeout fixtures. |
| P0 | Recoverability | Interruption at every lifecycle publication boundary reconciles without fact overwrite, duplicate spend, or incomplete-result acceptance. |
| P0 | Secret minimization | Persisted records and safe diagnostics contain no credentials or raw environment. |
| P1 | Diagnostic usefulness | Every invoked run produces a terminal result; timeout/failure results state the reason and preserve validated partial findings. |
| P1 | Cost and performance | Cheap preflight precedes spend; snapshot, prompt, hashing, heartbeat, live-conformance, and re-review work are bounded and measured as defined below. |
| P1 | Retrospective traceability | Every retrospective problem derived from review retains campaign, run, finding, target, completeness, and relevance provenance. |
| P1 | Workshop UX | Intermediate workshop pauses use workshop-native context and do not emit the generic five-section material-work Stop packet. |
| Not driving | Scale and availability | No throughput SLO, daemon availability target, telemetry service, database, or distributed-processing requirement is introduced. |

## Confirmed performance and cost profile

Performance is below stability and integrity in priority, but is an explicit design driver. Requirements concentrate on controllable orchestration overhead and reviewer cost rather than promising model latency.

- All cheap Git, target, store, schema, contract, containment, and harness checks complete before provider invocation and allowance spend.
- Frozen code targets use Git worktrees and shared objects rather than full repository copies.
- Prompts do not embed the source tree. They carry bounded instructions, scope, changed-file summary, and unresolved prior-finding summaries; the reviewer reads the complete frozen worktree.
- Incremental re-review receives the target delta and finding lineage to focus attention, but its complete verdict still covers the full current frozen snapshot.
- A repeated target/harness/contract combination is surfaced before invocation to prevent accidental duplicate spend. An intentional repeat remains a new authorized run.
- Low-cost heartbeats read process state at an approximately 30-second default interval without repeatedly hashing the repository.
- Target identity is computed at required pre/post integrity points, not continuously.
- Deterministic executable fixtures cover failure paths. Baseline paid conformance normally uses one bounded live review per harness.
- Snapshot, launch, reviewer, termination, validation, and publication durations are recorded separately so controller overhead is distinguishable from provider time.
- Numeric token/usage/cost data is recorded when a harness exposes it safely; credentials and unrestricted raw output are never persisted.
- The reviewer process tree may not outlive its configured timeout plus termination grace. No additional fixed review-duration SLO is imposed because repository complexity and provider latency vary.

## Cross-platform proof strategy

Avoid a fifteen-cell paid harness/OS Cartesian product:

```text
five bounded real reviews
  -> one per supported harness
  -> distributed so Windows, macOS, and Linux each have live evidence

deterministic CI fixtures
  -> every adapter on the three-OS matrix
  -> every OS runtime proves full process-tree timeout/termination
```

A specific harness/OS combination is not described as live-proven without corresponding evidence. This strategy proves every harness and every supported runtime while containing paid review cost.

The component design therefore includes `MacProcessGroupRuntime` alongside `WindowsJobObjectRuntime` and `LinuxCgroupRuntime`. Observable complete-tree termination is binding; the precise macOS-native mechanism must be established by conformance evidence rather than assumed.

## Acceptance evidence

- Adversarial contract and state tests prove invalid authority cannot approve a target.
- Concurrent claim/allowance tests prove the at-most-one and never-over-grant invariants.
- Timeout fixtures prove complete-tree death before result publication and within configured termination grace.
- Five bounded live harness reviews plus the three-OS fixture matrix prove the stated coverage—never file existence alone.
- Fault injection at lifecycle publication boundaries proves deterministic reconciliation.
- Safe-output tests prove credentials and raw environments do not enter durable records.
- Timing, usage, duplicate-warning, and incremental re-review tests prove the P1 cost/performance behavior.
- Workshop behavior proves intermediate stops do not render the generic five-section context packet.

## Human agreement

The maintainer confirmed the priority order and measurable profile, specifically keeping performance below P0 stability/integrity while requiring timeouts and explicit optimization; the bounded prompt, delta-assisted full-snapshot re-review, preflight-before-spend, shared-object worktree, low-cost heartbeat, minimal hashing, fixture-first failure proof, phase timing, optional usage metrics, five-smoke/three-OS coverage strategy, macOS runtime addition, and 10-second default termination grace.
