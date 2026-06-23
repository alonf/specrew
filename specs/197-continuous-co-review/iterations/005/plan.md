# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18.00/20 story_points
**Started**: 2026-06-23
**Completed**:

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Phase B part 2: the async co-review navigator (FR-026/030/031), built on a NEW general
**isolated-task launcher** (the Proposal 139 foundation). We design both policy seams
(`access`, `disposition`) and artifact-agnostic review, but **implement only**
`access: read-only` + `disposition: discard` + `task: code-review`. `merge`/`preserve`/
`read-write`/non-code contracts are interface + comments only (the merge path delegates to the
future merge-agent, Proposals 010/134/149). No F-184 protected-surface edits.

| Requirement / Issue | Summary |
| ------------------- | ------- |
| FR-026/030/031 | Auto-fire co-review at every real implement checkpoint, host-neutral, non-blocking. |
| SC-019/020/021/022 | The auto-fire half (Iteration 004 delivered the gate-floor half). |
| 145 carries | Thread `TrunkName` through the gate wiring; F2 nested-key note. |

## Tasks

| Task | Title | Requirement | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ------ | ----- | ---------------- | ------ |
| T076 | SPIKE (de-risk first): prove the detached, self-limiting cross-platform spawn — `Start-Process -PassThru` launches a launcher that SURVIVES the parent exiting and SELF-times-out (kills its child + writes status), on Windows; document the mac/linux path. Throwaway; gates the build. | FR-031 | 2.00 | Implementer | `.scratch/**`; `specs/197-continuous-co-review/iterations/005/**` | done |
| T077 | The general **isolated-task launcher** (`Start-SpecrewIsolatedTask`) in `scripts/internal/agent-tasks/`: materialize a worktree from a target tree-id, supervised spawn (timeout/kill = the watchdog role), `disposition: discard` built, `access: read-only` built (+ host read-only mode), artifact+contract param (`code` built). `merge`/`preserve`/`read-write`/non-code = interface + DEFERRED comments. | FR-026, FR-031 | 5.00 | Implementer | `scripts/internal/agent-tasks/**` | planned |
| T078 | The co-review-navigator provider + `refocus-scopes.json` registration: a FAST reap-then-fire dispatcher (reuse the Phase A `Invoke-ContinuousCoReviewGateDispatch` real-checkpoint detection) with dedup-by-reviewed-tree-id; fires the launcher `{read-only, discard, code-review}`; returns immediately (respects the ~20s budget / #2885). | FR-026, FR-030 | 3.00 | Implementer | `scripts/internal/continuous-co-review/**`; `extensions/specrew-speckit/refocus-scopes.json` | planned |
| T079 | The pending-task registry (`.specrew/review/pending/`, gitignored + digest-stripped) + the reaper: next-stop reap (collect verdict, force-continue via 185 `STOP-BLOCK` if blocking) + a SessionStart sweep for cross-session orphans; kills zombie processes AND orphaned worktrees. | FR-030, FR-031 | 4.00 | Reviewer | `scripts/internal/continuous-co-review/**`; `scripts/internal/agent-tasks/**` | planned |
| T080 | Iteration-004 145 carries: thread `TrunkName` through `Invoke-ContinuousCoReviewSignoffGateIfEnabled` -> the gate (non-`main`-trunk repos stop failing closed); note the F2 nested-key fail-safe. | FR-025 | 1.00 | Reviewer | `scripts/internal/continuous-co-review/signoff-gate-wiring.ps1` | planned |
| T081 | Tests + closeout-validation + Proposal 145 review: fire/reap/orphan-kill/cross-session-sweep/dedup/disposition-discard/worktree-cleanup; the spawn seam per host; protected-surface guard. | FR-026, FR-030, FR-031, SC-006 | 3.00 | Reviewer | `tests/**`; `specs/197-continuous-co-review/iterations/005/**` | planned |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Traceability Summary

- In-scope: FR-026/030/031 (async navigator) + SC-019..022 auto-fire half + the 145 carries.
- Built: review path only (`read-only` / `discard` / `code` contract).
- Designed + DEFERRED (interface + comments): `merge` disposition (-> merge-agent 010/134/149),
  `preserve`, `read-write` access, non-code review contracts, multi-task orchestration (139).
- Capacity status: PASS, 18.00/20 story_points.

## Notes

- **Spike gates the build (T076 first).** If the cross-platform detached self-limiting spawn does
  not hold, the design changes before any production code lands.
- No F-184 protected-surface edits (a `refocus-scopes.json` row + non-protected scripts; the
  launcher lives in a general `scripts/internal/agent-tasks/` location as shared 139 infrastructure).
