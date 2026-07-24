# Iteration 003 Reconciliation for Iteration 007

**Schema**: v1
**Recorded**: 2026-07-16
**Authority**: Maintainer closeout instruction carried from Iteration 006
**Purpose**: prevent the unfinished Iteration 003 lease design from being quietly mixed with the approved campaign/run architecture.

## T019 Step-6 Disposition

| T019 piece | Original intent | Iteration 007 disposition | Rationale / vehicle |
| --- | --- | --- | --- |
| 1 | Repair legacy registry-key drift and unify reviewed-tree resolution | **Superseded; do not rewire** | Iteration 006 closed `ReviewRun.target_digest`, exact target currentness, and strict identity joins replace the legacy registry as authority. Legacy readers remain historical only. |
| 2 | Acquire/release a mutable per-lineage lease with PID recovery | **Superseded; do not rewire** | Immutable claim generations in the campaign repository provide single active ownership and deterministic abandon/recovery without process-owner handoff. |
| 3 | Make the legacy navigator consume the same lease | **Superseded; replace at cutover** | T051 makes the public command and verdict gate consume campaign/run facts. The legacy navigator cannot promote after campaign cutover. |
| 4 | Gate FR-045 verdict packets while review is required/in flight/stale/actionable | **Live obligation; carry by behavior, not mechanism** | T051 implements the gate against campaign/run terminal state, exact digest, and human disposition. Reuse the eight-state fixtures; do not depend on the old lease. |
| 5 | Inject `suites` plus `runs` evidence only when every embedded digest matches | **Legacy wiring deferred/superseded** | Iteration 007 T058 consumes validated campaign results for retro and diagnostics. FR-048/FR-049/SC-015 command-plan supply/injection remains a separate Beta2 release dependency; it must be replanned against the campaign contract, not wired into the old registry. |
| 6 | Add reviewed tree/baseline identity to every legacy finding surface | **Superseded; retain regression intent** | Controller-owned `ReviewResult` binds the envelope to `campaign_id`, `run_id`, and `target_digest`; findings gain controller lineage IDs. T053/T059 prove every adapter enters through that contract. |
| 7 | Add runtime retention/pruning for transient/durable artifacts | **Deferred outside Beta2 automatic behavior** | FR-058 requires immutable history and forbids a new automatic pruning subsystem in Beta2. Preserve residue; any future archival/pruning policy needs a separate design and authorization. |

No Iteration 007 task may import a legacy lease/result as campaign authority, mutate an old fact, select authority by timestamp, or add a shared result filename/lock.

## Carried Task Disposition

| Task | Prior state | Iteration 007 plan | Notes |
| --- | --- | --- | --- |
| T030 | planned/pending | Carry at 0.75 SP | Machinery/hook turns cannot become human verdict evidence. |
| T031 | planned/pending | Carry at 0.5 SP | Tokenizer, temporal ordering, and cursor invariants remain live capture-integrity work. |
| T032 | planned/pending | Carry at 0.5 SP | Exact 2026-07-11 fabrication sequence remains the deterministic acceptance fixture. |
| T033 | done; independently verified by clean T061 run 10 | Delivered at 1.0 SP | Append-only correction/invalidation is the explicit IA-006-04 vehicle for `DRIFT-198-I006-001`; two historical misuse episodes are corrected by exact entry/crossing identity, raw history is retained, and no quiet matcher point-fix was made. |
| T034b | strict-resolution code integrated; final live compatibility pending | Carry only the 0.5 SP residual | Do not cherry-pick again. Prove the landed physical-containment and strict design-context behavior through the production campaign adapters/live path. |

The source Iteration 003 plan/state/progress files remain historical execution records. Iteration 007 does not rewrite them during planning; the feature-level task artifact will record the ownership move after the plan-to-tasks verdict.

## Open Authority Constraint

`DRIFT-198-I006-001` has its T033 scoped correction disposition and local verification; T061 still must independently verify the final tree before iteration signoff. Iteration 007 boundary decisions use fresh scoped human verdicts and the boundary commit/tree being reviewed; stale ledger entries are not authority. The raw events remain immutable, and the underlying legacy matcher/backlog question remains visible rather than receiving a quiet point-fix.

## Release Boundary

This reconciliation closes no Iteration 003 task by itself. It defines which remaining behavior is delivered in Iteration 007, which old mechanism is superseded, and which separate release dependency still needs its own authorized scope. Completion claims follow task evidence, not this planning classification.
