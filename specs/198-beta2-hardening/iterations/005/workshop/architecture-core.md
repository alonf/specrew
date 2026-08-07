# Architecture-core reassessment

**Status**: complete
**Iteration**: 005
**Human confirmation**: confirmed 2026-07-16

## Confirmed problem statement

The system delivers a controlled external review job:

1. Select and freeze an exact code state for review.
2. Create a disposable workspace outside the original repository.
3. Prevent the reviewer from running Specrew governance by controlling its environment and, where needed, stripping selected Specrew machinery from the review copy.
4. Launch different reviewer harnesses through a common contract.
5. Communicate through a command-line prompt, an authoritative machine-readable result, and a human-readable Markdown report.
6. Control the complete reviewer process tree with OS-native containment, timeout, cancellation, bounded capture, and termination mechanisms.
7. Validate that the result belongs to the requested run and exact reviewed snapshot.
8. Compare that immutable reviewed snapshot with the current code state and classify the result as current or stale.

The reviewer may write inside its disposable workspace for tests and result generation, but it must not modify the origin repository.

## Confirmed architectural center

`ReviewRun` is the central abstraction and lifecycle. The lease is subordinate concurrency infrastructure used to coordinate duplicate or overlapping active runs; it is not the conceptual or authority center of the entire review subsystem.

```text
 Original repository
        |
        | freeze exact tree identity
        v
 [Reviewed Snapshot] ---- digest/run identity ------------------+
        |                                                       |
        v                                                       |
 [Disposable external worktree]                                |
   - Specrew disabled                                           |
   - selected machinery stripped                               |
   - origin protected                                           |
        |                                                       |
        v                                                       |
 [Harness Adapter]                                              |
        |                                                       |
        v                                                       |
 [OS Runtime Controller]                                        |
        |                                                       |
        v                                                       |
 [Reviewer CLI] -- prompt --> review -- result files -----------+
                                                                |
                                                                v
                                                    [Result Validator]
                                                      run matches?
                                                      digest matches?
                                                      contract valid?
                                                                |
                                              +-----------------+----------------+
                                              |                                  |
                                           current                             stale
                                      usable for gating                 advisory / re-review
```

## Confirmed result contract

- The authoritative machine-readable result carries the run identity, reviewed-tree identity, status, and structured findings.
- A Markdown report provides the human-readable review.
- Markdown alone is not authoritative gate evidence.

## Confirmed lifecycle direction

```text
requested
  -> snapshot-bound
  -> workspace-ready
  -> running
  -> result-produced
  -> result-validated
  -> classified-current | classified-stale
  -> retired
```

## Confirmed execution authority separation

- The lease governs only active-run concurrency and the right to publish the terminal transition.
- A successful terminal transition durably records the completed run and its reviewed-tree identity.
- The lease may be released after that durable transition.
- Later result validation and current/stale classification rely on the terminal `ReviewRun` record, the machine result, and tree-identity comparison—not on a still-live lease.

## Confirmed decomposition method

The binding method is a state-machine core with ports and adapters.

```text
+-------------------------------------------------------+
| Core                                                  |
| ReviewRunStateMachine — legal states and transitions  |
| ResultAcceptancePolicy — result classification rules  |
| ReviewRunRecord — immutable run and terminal facts    |
+--------------------------^----------------------------+
                           |
+--------------------------|----------------------------+
| Application                                           |
| ReviewRunCoordinator — sequences the review workflow  |
+--------------------------^----------------------------+
                           |
                       stable ports
                           |
+-------------+-------------+------------+--------------+
| Snapshot    | Workspace   | Harness    | Runtime      |
| Result      | Concurrency | CurrentTree| Clock        |
+-------------+-------------+------------+--------------+
                           |
+--------------------------v----------------------------+
| Adapters                                               |
| Git | worktree | reviewer CLIs | JobObject/cgroup     |
| filesystem contracts | lease CAS | production/test time|
+-------------------------------------------------------+
```

The core owns correctness without performing filesystem, process, Git, host-harness, or wall-clock work. Volatile mechanisms live behind ports. The lease implementation is confined behind the concurrency port and cannot determine later result applicability.

## Confirmed mutation ownership

The repository boundary is the sole mutation authority. Runtime actors never mutate lifecycle state directly.

```text
Launcher --------+
Supervisor ------+--> revision-checked transition request
Navigator -------+                 |
Reviewer --------+                 v
                         Core state machine
                                  |
                                  v
                         Repository atomic commit
```

- The launcher may request pre-execution transitions through `running`.
- The runtime supervisor may request an execution outcome such as `result-produced`, `failed`, `timed-out`, or `cancelled`.
- The reconciler/navigator may request result validation, current/stale/invalid classification, and retirement.
- Every transition supplies the expected state and revision.
- Only the repository loads the current record, applies a legal core transition, and atomically commits the next revision.
- Direct caller writes, replacements, or deletion of live lifecycle state are forbidden.
- A stale actor loses the revision comparison rather than overwriting newer truth.

The physical compare-and-swap representation remains a data-storage-lens decision.

## Confirmed review-campaign boundary

`ReviewCampaign` sits above individual runs and owns re-review policy.

```text
ReviewCampaign
  target + lineage
  authorized / reserved / spent allowance
  append-only authorization history
  finding lineage
  accepted result
       |
       +--> ReviewRun 1 — snapshot A
       +--> ReviewRun 2 — snapshot B
       +--> ReviewRun 3 — snapshot C
```

- The human alone authorizes additional review allowance.
- `ReviewCampaignPolicy` deterministically decides whether a further run is permitted.
- `ReviewCampaignCoordinator` asks for human authorization and launches permitted runs.
- A reviewer may report findings or recommend re-review but cannot authorize or launch it.
- Each `ReviewRun` represents exactly one controlled provider invocation and does not decide whether another run follows.
- Preflight failures before provider invocation consume neither provider spend nor round allowance.
- A round slot is atomically reserved before launch; if the provider is never invoked, the reservation is released.
- Once provider invocation is observed, the slot is permanently spent even if the result is invalid, times out, or fails.
- Live reservations count against the allowance to prevent concurrent overspend.
- Human allowance changes append an auditable grant and never erase spent-round or finding history.
- Spending limits and no-progress loop guards are independent policies.
- Code, gate, and artifact reviews share campaign/run machinery through target adapters.

`ReviewCampaignRepository` is the sole mutation authority for campaign state and allowance; `ReviewRunRepository` is the sole mutation authority for run state. Both enforce core transitions with expected-state and expected-revision compare-and-swap semantics.

## Confirmed phased delivery

The current Beta2 architectural reassessment remains responsible for the shared `ReviewCampaign` / `ReviewRun` foundation and the production code-review target because the verified Iteration 005 defects are Beta2 blockers. Gate and artifact breadth is planned for Beta3 as additional, separately gated iterations.

The current foundation must expose a real `ReviewTargetAdapter` port and prove it with a thin non-code contract fixture so Beta3 does not discover that the architecture is secretly code-specific.

### Beta3 iteration A — production gate and generic artifact support

**Planning estimate**: 14 SP expected; 12–16 SP range. Capacity status: `ok` against the normal 20 SP iteration baseline.

| Task | Requirement slice | Owner role | SP |
|---|---|---:|---:|
| Generalize and stabilize the target-adapter contract | target neutrality | Implementer | 1.5 |
| Build canonical artifact bundles, manifests, and target identity | artifact review | Implementer | 2.0 |
| Implement a production lifecycle-gate adapter | gate review | Implementer + Spec Steward | 2.5 |
| Implement a generic selected-artifact adapter | artifact review | Implementer | 2.0 |
| Integrate non-code current/stale classification with campaigns | result applicability | Implementer | 2.0 |
| Add paired identity, containment, Windows, and Linux tests | evidence | Implementer + Reviewer | 2.5 |
| Independent review and expected correction allowance | quality | Reviewer + Implementer | 1.5 |

Phase baseline: planning/design 1.5 SP; implementation 7 SP; verification 3 SP; review/rework 2.5 SP.

### Beta3 iteration B — first-class lifecycle profiles

**Planning estimate**: 10 SP expected; 8–12 SP range. Capacity status: `ok` against the normal 20 SP iteration baseline.

Priority order:

1. Design-analysis and before-implement gate profiles.
2. Specification profile.
3. Plan profile.
4. Tasks and traceability profile.
5. Review, retro, and closeout profiles only when Iteration A demonstrates a concrete workflow benefit.

Phase baseline: planning/design 1 SP; implementation 5 SP; verification 2 SP; review/rework 2 SP.

### Binding deferral line

- Do not fold Beta3 Iterations A or B into the current code-review architecture slice.
- Do not postpone the target-neutral port or thin non-code contract proof.
- Do not require a bespoke adapter for every artifact type before Beta3 ships.
- Defer review/retro/closeout specialization when no demonstrated workflow benefit exists.
- Re-estimate Iteration B from measured Iteration A adapter cost before its plan boundary.

## Added iteration requirement: workshop-aware Stop

The generic five-section non-boundary context packet must not interrupt an active workshop after every material lens turn. When durable workshop state identifies the active feature, iteration, lens, and pending human question, the Stop provider must use a narrowly scoped workshop-intermediate classification and leave the rendered lens question as the final visible message.

This exception does not apply to lifecycle boundaries, fabricated workshop prose, workshop abandonment, or a handover that lacks sufficient durable re-entry context. The authoritative requirement is FR-056 with acceptance criterion SC-016 in the feature specification.

## Confirmed binding constraints and exclusions

- One run binds one frozen snapshot to at most one provider invocation.
- The original repository is never the reviewer's working directory or permitted write target.
- Reviewers run in a controlled environment with Specrew hooks and skills disabled; selected machinery may be stripped from the disposable workspace.
- Harness and operating-system mechanisms remain adapters; campaign, run, allowance, and result policy remain host-neutral.
- OS runtime control covers the full process tree, timeout, cancellation, termination, exit observation, and bounded output.
- The machine-readable result governs; Markdown explains.
- Gate eligibility requires a valid terminal run, matching result identity, and a reviewed snapshot equal to the current target state.
- Stale results remain visible but advisory.
- Human authorization alone can increase review allowance.
- Core behavior is testable without Git, filesystem access, process spawning, or a live clock.
- Uncertain execution, identity, or result validity never becomes clean or gateable.
- The current slice excludes hardened containers/VMs/network jails, remote/cloud execution, distributed locking, live changing-workspace review, reviewer edits to origin, automatic allowance increases, and unprovable exactly-once external execution.
- The runtime guarantee is at-most-one authoritative result.

**Human-agreed marker**: The maintainer explicitly confirmed these constraints and exclusions and moved architecture-core on 2026-07-16.
