# Drift Log: Iteration 006

**Schema**: v1

## Summary

**Total drift events**: 3
**Resolution state**: The maintainer supplied fresh Iteration 006 tasks and before-implement verdicts, reconciled the T050 ownership records, and explicitly authorized one Claude file-primary prompt-contract slice to move from Iteration 007 into T050. The canonical cross-iteration matcher defect remains unresolved and is not treated as authority.
**Specification drift**: Boundary authorization currently matches only the boundary-name pair and treated an old Iteration 003 `plan -> tasks` verdict as authorization for Iteration 006, contrary to the one-approval/one-crossing contract. Separately, approved T042/T046 owner globs named placeholder files rather than the delivered files. Finally, the v2/v5 malformed Claude outputs justified an explicitly authorized cross-iteration delivery change: the Claude file-primary candidate contract and its deterministic pair move into T050, while the remaining adapter matrix stays Iteration 007 scope.

## Events

### DRIFT-198-I006-001 — stale Iteration 003 verdicts matched Iteration 006 boundaries

- **Type**: violation
- **Severity**: critical
- **Detected at**: 2026-07-16
- **Task reference**: Iteration 006 plan sync at commit `4aedb0268f550c5c78e3b9bf19dfc16583c21cc8`
- **Requirement citation**: FR-001 requires the shared authorization check to compute the actual lifecycle-position delta; FR-002 requires an unpaid crossing to remain pending rather than silently reuse unrelated authority; the lifecycle invariant permits one human approval to advance at most one boundary.
- **Divergence**: After syncing the Iteration 006 plan, `Test-SpecrewBoundaryAuthorization` reported `plan -> tasks` authorized by verdict `138a74da` recorded on 2026-07-11 for Iteration 003. After syncing the Iteration 006 tasks, it likewise reported `tasks -> before-implement` authorized by old verdict `2d475962`. The matcher ignored the current iteration and authorization commit both times, so neither sync produced a fresh pending-verdict artifact.

#### Addendum — pending-verdict packet fabrication observed at the Iteration 007 plan gate

The same authority defect produced additional evidence during the Iteration 006 closeout to Iteration 007 plan crossing:

- The pending-verdict generator used stale `session_state` to fabricate a false “tasks committed / in-progress” narrative even though no Iteration 007 tasks artifact existed and task authoring was not authorized.
- Two sessions rendered boundary packets for the same crossing with divergent option numbering, so the numeric reply did not have one stable meaning.
- One packet declared `1 = approved`; that alias made a bare-number human reply unsafe because it could be rebound to a different packet/session meaning instead of the explicit boundary phrase.

This addendum is part of the open `DRIFT-198-I006-001` evidence, not a new drift ID. The Iteration 007 T033 task must provide an append-only invalidation/correction for the stale episode; bind pending-verdict facts to the current scoped crossing, boundary commit, and artifact state; make repeat renders preserve identical verdict semantics; and ensure a bare number is never authorization evidence. Until verified, fresh explicit `approved for <boundary>` text is the only authority used for Iteration 007 crossings.

- **Concrete evidence**: file:///C:/Dev/specrew-beta2-hardening/.specrew/start-context.json records Iteration 006 session commit `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`, while the matched authorization history entries predate this iteration and cite Iteration 003 commits `138a74da74cd8055b22a36200917a13e2e7b1bea` and `2d47596202086397be65a2a2c305dd56138b501e`.
- **Resolution**: human-decision
- **Resolution detail**: The maintainer supplied **approved for tasks** against plan commit `169599ef7b7accfe92ccf37e9cfe96182f1d52f4`, then separately supplied **approved for before-implement** against task-boundary commit `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`. Those fresh decisions authorize the current artifact and implementation stages respectively. The matcher defect remains visible and is not point-fixed inside the review-orchestration foundation without a scoped plan amendment.

### DRIFT-198-I006-002 — T042/T046 ownership records named placeholder files instead of delivered components

- **Type**: violation
- **Severity**: minor
- **Detected at**: 2026-07-16
- **Task reference**: T042 and T046 during authoritative Claude run `run-i006-t050-claude-v3`
- **Requirement citation**: FR-057 requires the pure campaign/run state-machine core behind ports; FR-059 requires a real `ReviewTargetPort` plus production-code and non-code proofs. The task contract requires owner file globs to identify the files carrying each deliverable.
- **Divergence**: T042 named `reviewer-contracts.ps1` and `review-identity-contracts.ps1`, although the closed contracts were consolidated in `review-authority-core.ps1`. T046 named `worktree-review-orchestrator.ps1`, although the target port was delivered in `review-target-port.ps1`. The implementation satisfies the requirements, but the approved ownership metadata did not identify its actual files.
- **Concrete evidence**: Closed contracts are implemented by file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-authority-core.ps1; the production and fixture target port is implemented by file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1. The prior owner-glob text is preserved in Git history and in the immutable reviewer result.
- **Resolution**: human-decision
- **Resolution detail**: T050's authorized correction scope reconciles file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/plan.md and file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md to those delivered components. No requirement, scope, effort, or implementation behavior changes.

### DRIFT-198-I006-003 — Claude file-primary prompt contract pulled forward from Iteration 007

- **Type**: violation
- **Severity**: minor
- **Detected at**: 2026-07-16
- **Task reference**: T050 after `run-i006-t050-claude-v5` repeated the v2 prose-wrapped-JSON failure
- **Requirement citation**: FR-060 requires one synchronous process/file contract in which reviewers write candidate output in staging and malformed output fails closed; FR-064 requires deterministic malformed-output fixtures for every adapter. The approved Iteration 006 plan originally deferred real harness adapters and the full malformed-output adapter matrix to Iteration 007.
- **Divergence**: The foundation contract and strict ingress behaved correctly, but Claude twice returned prose-wrapped JSON on stdout. Closing T050 with another run now requires a production Claude delivery seam that writes raw JSON directly to the controller candidate path plus the exact negative/positive regression pair. Delivering that slice in Iteration 006 changes the approved iteration boundary even though it remains within the authoritative FR-060/FR-064 feature scope.
- **Concrete evidence**: v5's immutable result is file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v5/result.json. The pulled-forward adapter is file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-claude-harness-port.ps1 and the deterministic pair is in file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1.
- **Resolution**: human-decision
- **Resolution detail**: The maintainer explicitly authorized this bounded pull-forward under T050: file-primary Claude candidate delivery, strict no-salvage ingress, and the two real-evidence-modeled regressions. Iteration 007 must subtract this exact slice. Its full malformed-output fixture matrix, remaining Claude adapter hardening, the other four harness adapters, production runtimes, live-smoke matrix, and cross-platform proof remain deferred and unauthorized here.

## Planning Tool Note

The iteration scaffold helper recognizes only undecorated `**FR-NNN**` headings, while the authoritative specification uses descriptive headings such as `**FR-057 (campaign/run authority model)**`. This is a tooling compatibility limitation, not product-spec drift. The plan was authored with the repository’s validated schema and manual exact traces; the specification was not altered to satisfy the helper.
