# Current Architecture: 198-beta2-hardening

**Source Iteration Ref**: 006 foundation plus approved Iteration 007 production plan
**Last Updated**: 2026-07-16T16:30:00+03:00

## Current Truth

- Checked-in review authority mode is `legacy`; production cutover has not occurred.
- Iteration 006 delivered the independently reviewed authority foundation: pure campaign/run policy, immutable JSON facts, allowance/reservation/spend accounting, claim generations, exact external Git targets, strict candidate ingress, controller-owned terminal results, deterministic recovery, and a bounded Claude file-primary adapter.
- The foundation is executable through tests and the bounded Iteration 006 adapter, but the public `specrew review` path still uses legacy authority.
- Five-harness/three-OS production completeness is not yet proven. Iteration 007 owns public wiring, four remaining harnesses plus Claude integration hardening, three runtime ports, progress/retro projection, deterministic cross-OS proof, live smokes, and final cutover.
- Legacy lease/results are historical evidence only after cutover. They are never imported or promoted into campaign authority.

## Authority Components

| Layer | Current component | Responsibility |
| --- | --- | --- |
| Public command | `scripts/specrew-review.ps1` | Existing user surface; Iteration 007 delegates authority to the campaign application service |
| Cutover | `review-authority-cutover.ps1` + `review-authority-mode.json` | Closed `legacy`, `disabled`, `campaign` selection; invalid/missing enables neither path |
| Pure core | `review-authority-core.ps1` | Contracts, allowance, run transitions, currentness, result acceptance, finding lineage |
| Repositories | `review-authority-store.ps1` | Immutable create-new campaign/run/grant/reservation/spend/claim/result facts |
| Target | `review-target-port.ps1` | Frozen external Git worktree, exact digest, origin unchanged, moved-snapshot classification |
| Ingress | `review-result-ingestor.ps1` | Strict raw candidate validation and controller-owned JSON/Markdown terminal publication |
| Application | `review-campaign-orchestrator.ps1` | Synchronous composition of target, harness, runtime, clock, repository, and ingress ports |
| Harnesses | Claude bounded slice exists | Iteration 007 finishes Claude production integration plus Codex/Copilot/Cursor/Antigravity |
| Runtimes | Fixture runtime exists | Iteration 007 adds Windows Job Object, Linux cgroup, and macOS process-group ports |

## Planned One-Way Cutover

```text
legacy authority
    -> disabled (neither path promotes)
    -> campaign authority after public wiring + deterministic matrix + five live smokes
```

Code repositories remain the sole code-mutation authority. Review repositories remain the sole review-state mutation authority. A reviewer receives a frozen external target and a run-owned candidate path; it never edits the original repository or publishes authoritative results directly.

## Current Planning References

- Approved architecture: `iterations/005/design-analysis.md`
- Foundation map/evidence: `iterations/006/foundation-map.md`, `iterations/006/quality/foundation-evidence.md`
- Production plan: `iterations/007/plan.md`
- Iteration 003 reconciliation: `iterations/007/iteration-003-reconciliation.md`
- Review flows: `review-diagrams.md`
