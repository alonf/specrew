# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 10/20 story_points
**Started**: 2026-06-09
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 004 replaces the SessionEnd-only handover (Claude-first, crash-fragile) with a **Stop-event
rolling handover** that is PORTABLE (all 4 hosts have an end-of-turn Stop) and CRASH-SAFE (the rolling
file always reflects the last completed turn). Design settled with the human:
`f174-i004-stop-event-rolling-handover` + `f174-i004-design-settled`. Single-agent only; sub-agent
per-worktree merge is deferred (maintainer memory `f174-subagent-handover-merge-consideration`).

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-009 | Handover trigger pivots to per-host Stop; one local always-latest rolling file | US-3 |
| FR-005 | Per-host Stop registration (Claude Stop, Codex Stop, Copilot agentStop, Cursor stop) | US-1 |
| FR-008 | Docs reconciled: handover refreshes per material turn, crash-safe, all hosts | US-2 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T023 | Rolling-handover write (overwrite-in-place always-latest session-handover.md) + gitignore the local path | FR-009 | US-3 | 2 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1 | planned | claude | — | — |
| T024 | Material-change engine: refresh only when boundary moved OR tracked-file change since last write | FR-009 | US-3 | 1 | Implementer | scripts/internal/bootstrap/ClassificationEngine.ps1 | planned | claude | — | — |
| T025 | Stop-event handover provider: fire on Stop, material-change gate, reuse SessionEnd write-logic | FR-009 | US-3 | 2 | Implementer | scripts/internal/specrew-handover-provider.ps1 | planned | claude | — | — |
| T026 | Per-host Stop registration + REMOVE Claude SessionEnd (deployer + provider-row events -> stop variants) | FR-005, FR-009 | US-1 | 2 | Implementer | scripts/internal/deploy-refocus-hooks.ps1 | planned | claude | — | — |
| T027 | Tests: rolling round-trip + material-change + crash-safety + per-host Stop deploy + on-disk DeployedHostConfig floor (Stop) + live cross-host Stop smoke | FR-009, SC-009 | US-3 | 2 | Implementer | tests/bootstrap | planned | claude | — | — |
| T028 | Spec FR-009 reconcile (trigger -> Stop + crash-safety SC-009) + docs update (getting-started) | FR-008, FR-009 | US-2 | 1 | Implementer | specs/174-hook-driven-session-bootstrap/spec.md | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Serial single-Implementer; the rolling-write (T023) -> material-change (T024) -> provider (T025) ->
  deploy (T026) chain is sequential; tests + docs (T027/T028) follow.
- Apply the iteration-003 retro live-wiring FLOOR from the start: T027 includes an on-disk
  deployed-config assertion (DeployedHostConfig pattern) for the per-host Stop hooks.
- Recommendation: serial; no Junior/Senior split.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Design pass settled with the human (this iteration's design decisions). |
| Discovery/Spikes | 0 | Per-host Stop events are research-confirmed (F-171 research-matrix). |
| Implementation | 10 | T023-T028. |
| Review | 2 | reviewer artifacts + Proposal-145 + the on-disk live-wiring floor. |
| Rework | 1 | needs-work buffer. |

## Traceability Summary

- Iteration 004 requirement scope: FR-009 (trigger pivot), FR-005 (per-host Stop), FR-008 (docs),
  - SC-009 (crash-safety: rolling handover reflects the last completed turn).
- User stories: US-3 (handover), US-1 (per-host/live), US-2 (docs).
- Supersedes: the iteration-003 SessionEnd-only handover (the Claude SessionEnd hook is removed).
- Per-task effort sums to 10 SP = Capacity 10/20 (no overcommit).

## Notes

- Capacity 10/20: per-task SP (2+1+2+2+2+1) = 10.
- SC-009 (crash-safety) is a NEW success criterion added with this trigger pivot; T028 reconciles the
  spec (FR-009 trigger + SC-009).
- Sub-agents OUT OF SCOPE: per-worktree handover + merge-on-finish + find-worktrees-cleanup-on-kill are
  deferred to the multi-agent work (memory `f174-subagent-handover-merge-consideration`).
