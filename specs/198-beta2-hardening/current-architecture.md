# Current Architecture: 198-beta2-hardening

**Source Iteration Ref**: Iteration 007 closeout plus Iteration 008 production plan
**Last Updated**: 2026-07-18
**Planning Baseline**: `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`

## Current Truth

- Iteration 007 completed the campaign review architecture and cut over the public review path.
- Production support exists for Claude, Codex, Copilot, Cursor, and Antigravity through one file-primary harness
  contract and for Windows Job Objects, Linux cgroups, and macOS process groups through one runtime-port contract.
- Review targets are clean external Git snapshots. The origin repository is not modified; target digest/currentness
  and immutable controller-owned results govern approval.
- Strict candidate ingress, explicit human slot accounting, descendant termination, recovery, progress, retrospective
  projection, and exact-digest signoff are delivered and independently reviewed.
- The framework-neutral verification-plan schema, validator, ordered runner, and evidence recorder exist, but no
  production supplier currently feeds that seam and the campaign does not yet run/inject its evidence.
- The original Iteration 004 consumer distribution and release tail was never opened. It remains the other Beta2
  release dependency.

## Delivered Review Authority Components

| Layer | Component | Responsibility |
| --- | --- | --- |
| Public command | `scripts/specrew-review.ps1` | Campaign creation, authorized invocation, reconciliation, and result presentation |
| Authority mode | `review-authority-cutover.ps1` + `review-authority-mode.json` | One-way campaign authority; invalid or disabled state never promotes |
| Pure core | `review-authority-core.ps1` | Contracts, allowance, transitions, currentness, result acceptance, and finding lineage |
| Immutable store | `review-authority-store.ps1` | Create-new campaign/run/grant/reservation/spend/claim/result/recovery/finalization facts |
| Target port | `review-target-port.ps1` | Frozen external Git target, canonical digest, origin invariance, and moved-snapshot classification |
| Ingress | `review-result-ingestor.ps1` | Strict raw candidate validation and controller-owned terminal JSON/Markdown |
| Application | `review-campaign-orchestrator.ps1` | Target, harness, runtime, verification, repository, and ingress composition |
| Harness ports | Claude, Codex, Copilot, Cursor, Antigravity | One bounded invocation writing raw JSON to a run-owned candidate path |
| Runtime ports | Windows Job Object, Linux cgroup v2, macOS process group | Verified containment, complete descendant-tree termination, and recovery identity |
| Signoff | `review-signoff-evidence-gate.ps1` | Exact reviewed digest plus one-time finalization-envelope binding |

## Existing Verification Seam

| Component | Delivered responsibility | Iteration 008 residual |
| --- | --- | --- |
| `verification-plan.schema.json` | Framework-neutral ordered command contract | Reuse unchanged unless an evidence-backed compatibility correction is required |
| `verification-plan-contract.ps1` | Identity, path, timeout, provenance, and evidence-join validation | Feed it a selected production plan |
| `verification-plan-runner.ps1` | Load canonical plan, execute in order, record each attempt | Invoke it from the frozen-target campaign path |
| `test-evidence-recorder.ps1` | Bind evidence to reviewed digest and command identity | Inject only exact matching bounded evidence into review |
| `.specrew/verification-plan.json` | Canonical selected-plan seam | Add ordered supplier plus init/update/setup materialization |

## Planned Iteration 008 Additions

```text
explicit project config
  -> named reliable project-metadata detector
  -> explicit quality profile
  -> active provider-gated catalog row
  -> actionable verification-not-configured
  -> canonical selected plan
  -> existing T018 runner on frozen target
  -> exact digest + command-id evidence join
  -> bounded campaign injection
```

Explicit project configuration fails closed when invalid. Detection is restricted to named project-owned
metadata; file-extension inference and a Specrew/Pester default are prohibited. Init/update/setup may hash-guard
generated content, while review remains read-only over the frozen target.

The same iteration completes consumer workflow deployment, update healing, release-model teaching, the
technology-assumption firewall, `v0.40.0-beta2` publication after a separate human release grant, and published
beta dogfood. Stable promotion remains separate.

The tasks verdict also selected the narrow crossing rebind and multi-session Stop/capture repair as the first
3.0 SP of Iteration 008. T069 is hard-capped at 2.25 SP; exceeding it requires replan rather than expanding the
release slice. Proposal 209 remains separately scheduled.

## Mutation and Authority Boundaries

- The repository is the sole code mutation authority.
- Campaign repositories are the sole review-state mutation authority.
- Reviewers are trusted but fallible components: their findings are preserved, while controllers validate
  identity, currentness, containment, schema, and termination.
- A missing/invalid verification plan stops before provider spend. A configured command failure is retained as
  evidence and cannot become approval.
- A later lifecycle verdict, not this planning artifact, authorizes task authoring or implementation.

## Current Planning References

- Iteration 007 closeout: `iterations/007/retro.md` and `iterations/007/review.md`
- Iteration 008 plan: `iterations/008/plan.md`
- Supplier contract: `contracts/verification-plan-supplier.md`
- Verification schema: `contracts/verification-plan.schema.json`
- Review and finish-line flows: `review-diagrams.md`
