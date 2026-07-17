# Drift Log: Iteration 007

**Schema**: v1

## Summary

**Total local drift events**: 2
**Resolution rate**: 0% (0/2 resolved)
**Specification drift**: Two live-dogfood gaps are explicit below; neither changes approved product scope

## Inherited Open Drift

### DRIFT-198-I006-001 — boundary authorization matcher is not iteration-scoped

- **Status**: scoped correction delivered and locally verified; independent T061 verification pending
- **Severity**: critical
- **Authority constraint**: Iteration 007 must not rely on the stale global ledger entry. Every boundary uses a fresh scoped human verdict against the current boundary commit.
- **Disposition**: T033 implements the FR-044 append-only correction/invalidation door and makes every effective-state reader honor the correction. Prior events remain immutable.
- **Scope guard**: no quiet matcher point-fix is authorized inside adapter/runtime tasks. A matcher redesign beyond the correction door requires a scoped amendment or engine backlog decision.
- **Gate-episode addendum**: the pending-verdict generator fabricated “tasks committed / in-progress” from stale `session_state`; two sessions rendered divergent option numbering for the same crossing; and a `1 = approved` alias made a bare-number reply unsafe. The authoritative addendum is recorded in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/drift-log.md and is binding T033 acceptance evidence.
- **Scoped transition evidence**: on 2026-07-16 the maintainer explicitly wrote `approved for before-implement` against task-boundary commit `d9cdd16457e322628957ea74de959a5457358852`. That exact phrase/commit pair authorizes Iteration 007 execution; the global matcher and boundary synchronizer were not used.
- **Correction evidence**: T033 appended `correction-73ccb3f6407aabe32dadc7781e2acd3513ce4f466cad2f0def1a05c2b124eca9` for the old `plan -> tasks` entry at Iteration 006 commit/tree `4aedb0268f550c5c78e3b9bf19dfc16583c21cc8`/`0199418cc1ed12cd2ec1081fecc8b23b9d0ad714`, and `correction-6283109f289f3491db9baa23a5e9b8cb9619adfb9c490b753d70e98d9824fcde` for the old `tasks -> before-implement` entry at `32d70abf5e6cf1f5e9f3a4081ae561d2508e0979`/`2f8e6f7ef0f2601fdd62ff424ce9a3e5fa6333b6`. Raw verdict history remains intact, current authority remains `before-implement`, and T061 retains independent verification responsibility.

## Events

### DRIFT-198-I007-001 — local-Mac live proof exposed incomplete target/context binding

- **Status**: correction implemented; all 55 registered deterministic suites green; new committed Mac rerun pending
- **Severity**: major
- **Requirements**: FR-012, FR-017, FR-059, FR-064, SC-018
- **Evidence**: local-machine run `run-t060-codex-macos-6708bf05-01` at commit `6708bf058b708df1c6b6f7492f46bb856154434a` and canonical digest `f668677ff652e84f7a05c81964d1a14721a39131` returned valid/current/contained/terminated partial evidence with `finding-d36b4c66cb3c1e56` and `finding-8d4f2649e461481c`.
- **Observed drift**: the returned-package validator checked only mutually agreeing package digests instead of recomputing the clean pinned checkout; separately, campaign auto-resolution ignored its explicit `FeatureId`, so a clean detached worktree with ignored session files and multiple feature specs degraded to `DESIGN_CONTEXT_EMPTY`.
- **Correction**: validation now takes a clean pinned repository input, verifies origin and exact `HEAD`, independently recomputes the canonical digest, and fails on mismatch. Campaign selection now resolves spec/latest design analysis/formal contracts from the command's validated feature identity before any mutable-session fallback.
- **Closure rule**: the paired regressions and full 55-suite registry are green; a complete valid local-Mac rerun on the correction commit is still required. Run 1 remains immutable partial evidence and is never retroactively promoted.

### DRIFT-198-I007-002 — ordinary conversational turns are over-classified as material Stop handoffs

- **Status**: open; explicitly deferred until the Mac test sequence completes
- **Severity**: moderate UX/governance friction
- **Requirements**: FR-055, FR-056, NFR-002, NFR-007
- **Evidence**: during the T060 Mac setup and live-run discussion, short operational answers repeatedly rendered the full five-section non-boundary packet. The human clarified that context packets are for substantial completed work or real handoff stops, not ordinary back-and-forth every few seconds.
- **Scope**: T052's workshop-intermediate exception is insufficient because this failure is the ordinary Stop materiality classifier. The later correction must preserve lifecycle-boundary packets and genuine substantial-work handoffs while leaving direct discussion smooth.
- **Guard**: do not suppress Stop evidence globally and do not weaken boundary precedence. Add paired routine-discussion versus substantial-work fixtures before closing this event.

T059's fake-provider workflow remains green on hosted Windows, Ubuntu, and macOS but does not replace T060 live evidence. The inherited Iteration 006 event still requires T061 independent verification.
