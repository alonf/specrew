# Drift Log: Iteration 007

**Schema**: v1

## Summary

**Total local drift events**: 3
**Resolution rate**: 100% (3/3 resolved)
**Specification drift**: Both local dogfood gaps are resolved without changing approved product scope

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

- **Status**: resolved
- **Severity**: major
- **Requirements**: FR-012, FR-017, FR-059, FR-064, SC-018
- **Evidence**: local-machine run `run-t060-codex-macos-6708bf05-01` at commit `6708bf058b708df1c6b6f7492f46bb856154434a` and canonical digest `f668677ff652e84f7a05c81964d1a14721a39131` returned valid/current/contained/terminated partial evidence with `finding-d36b4c66cb3c1e56` and `finding-8d4f2649e461481c`.
- **Observed drift**: the returned-package validator checked only mutually agreeing package digests instead of recomputing the clean pinned checkout; separately, campaign auto-resolution ignored its explicit `FeatureId`, so a clean detached worktree with ignored session files and multiple feature specs degraded to `DESIGN_CONTEXT_EMPTY`.
- **Correction**: validation now takes a clean pinned repository input, verifies origin and exact `HEAD`, independently recomputes the canonical digest, and fails on mismatch. Campaign selection now resolves spec/latest design analysis/formal contracts from the command's validated feature identity before any mutable-session fallback.
- **Closure evidence**: the paired regressions and full 55-suite registry are green. Correction run `run-t060-codex-macos-b1ae8b47-02` at commit `b1ae8b47aece4e0f4a017dc1e8896708fc2c8700` and digest `7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c` invoked exactly once and returned complete/pass/current/valid evidence with verified containment/termination and zero findings. Independent package validation reported `package_valid=true`, `smoke_clean=true`, and no errors. Run 1 remains immutable partial evidence and was not retroactively promoted.

### DRIFT-198-I007-002 — ordinary conversational turns are over-classified as material Stop handoffs

- **Status**: resolved
- **Severity**: moderate UX/governance friction
- **Requirements**: FR-055, FR-056, NFR-002, NFR-007
- **Evidence**: during the T060 Mac setup and live-run discussion, short operational answers repeatedly rendered the full five-section non-boundary packet. The human clarified that context packets are for substantial completed work or real handoff stops, not ordinary back-and-forth every few seconds.
- **Root cause**: the stable material-surface hash retained the transient `; N new commit(s): ...` handover annotation. The first Stop after a commit contained the suffix; a later routine discussion over the exact same `HEAD` and file surface did not. That suffix-only transition looked like new material work even though the turn changed nothing.
- **Correction**: canonicalization removes only the transient new-commit observation before hashing. The concrete `HEAD`, commit title, dirty-file identity, and counts remain, so a genuinely different commit or file surface still creates a new obligation. Refocus guidance also states explicitly that clarify ambiguity and workshop questions are not packet stops.
- **Closure evidence**: the paired live-reproduction fixture proves same `HEAD`/files with the suffix disappearing stays conversational, while a different `HEAD` still demands the five-section packet. Existing substantial-work, long-read-only, rendered-packet, workshop, boundary-precedence, dispatcher, and deployed-binding cases remain green. Focused suites pass and all 55 F-198 suites pass in 630.5 seconds.

### DRIFT-198-I007-003 — first Windows live-smoke target exceeded the legacy path boundary before provider spend

- **Status**: resolved in code; clean exact-commit preflight and live rerun pending
- **Severity**: moderate infrastructure
- **Requirements**: FR-059, FR-061, FR-064, SC-018, SC-019, SC-021
- **Evidence**: `run-t060-cursor-windows-f1e69d0a-01` reserved one authorized slot, then failed after 17468 ms while checking out the canonical target because the default Windows temp prefix plus the repository's deepest tracked fixture exceeded the legacy 260-character boundary. The controller published and preserved a `preflight-failed` result/report, released the reservation, recorded no spend fact, and never invoked Cursor or consumed free credit.
- **Secondary packaging gap**: the pre-invocation controller result exposed `result_path` but omitted the already-published `report_path`, causing the outer T060 package to stop before copying its terminal projection even though the authority subtree retained it.
- **Correction**: the local Windows/Linux runner supplies the real production target port with short sibling `.t060-targets` and `.t060-staging` roots, preserving external isolation while removing 35 path characters in the reproduced fixture. Every pre-invocation terminal return now carries both immutable result and generated report paths.
- **Closure evidence**: a paired deterministic length fixture crosses the old boundary and remains below it with the short root; preflight, runtime-preflight, launch-failure, long-exception, and claim-contention paths expose readable reports. All 66 focused target/harness/orchestrator/Windows-runtime tests pass, followed by all 56 registered F-198 suites in 622.3 seconds and scoped Iteration 007 governance with historical warnings only. No provider invocation was used for the correction.

T059's fake-provider workflow remains green on hosted Windows, Ubuntu, and macOS but does not replace T060 live evidence. The inherited Iteration 006 event still requires T061 independent verification.
