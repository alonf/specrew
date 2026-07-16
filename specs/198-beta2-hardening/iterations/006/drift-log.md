# Drift Log: Iteration 006

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution state**: The maintainer supplied fresh Iteration 006 tasks and before-implement verdicts against the current plan/task artifacts. Implementation may proceed from that durable human evidence, while the canonical cross-iteration matcher defect remains unresolved and is not treated as authority.
**Specification drift**: Boundary authorization currently matches only the boundary-name pair and treated an old Iteration 003 `plan -> tasks` verdict as authorization for Iteration 006, contrary to the one-approval/one-crossing contract.

## Events

### DRIFT-198-I006-001 — stale Iteration 003 verdicts matched Iteration 006 boundaries

- **Type**: violation
- **Severity**: critical
- **Detected at**: 2026-07-16
- **Task reference**: Iteration 006 plan sync at commit `4aedb0268f550c5c78e3b9bf19dfc16583c21cc8`
- **Requirement citation**: FR-001 requires the shared authorization check to compute the actual lifecycle-position delta; FR-002 requires an unpaid crossing to remain pending rather than silently reuse unrelated authority; the lifecycle invariant permits one human approval to advance at most one boundary.
- **Divergence**: After syncing the Iteration 006 plan, `Test-SpecrewBoundaryAuthorization` reported `plan -> tasks` authorized by verdict `138a74da` recorded on 2026-07-11 for Iteration 003. After syncing the Iteration 006 tasks, it likewise reported `tasks -> before-implement` authorized by old verdict `2d475962`. The matcher ignored the current iteration and authorization commit both times, so neither sync produced a fresh pending-verdict artifact.
- **Concrete evidence**: file:///C:/Dev/specrew-beta2-hardening/.specrew/start-context.json records Iteration 006 session commit `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`, while the matched authorization history entries predate this iteration and cite Iteration 003 commits `138a74da74cd8055b22a36200917a13e2e7b1bea` and `2d47596202086397be65a2a2c305dd56138b501e`.
- **Resolution**: human-decision
- **Resolution detail**: The maintainer supplied **approved for tasks** against plan commit `169599ef7b7accfe92ccf37e9cfe96182f1d52f4`, then separately supplied **approved for before-implement** against task-boundary commit `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`. Those fresh decisions authorize the current artifact and implementation stages respectively. The matcher defect remains visible and is not point-fixed inside the review-orchestration foundation without a scoped plan amendment.

## Planning Tool Note

The iteration scaffold helper recognizes only undecorated `**FR-NNN**` headings, while the authoritative specification uses descriptive headings such as `**FR-057 (campaign/run authority model)**`. This is a tooling compatibility limitation, not product-spec drift. The plan was authored with the repository’s validated schema and manual exact traces; the specification was not altered to satisfy the helper.
