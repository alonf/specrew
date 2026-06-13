# Iteration Plan: 011 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-06-13
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

STUB — opened at the **specify** boundary. This iteration fixes the DF-3/4/5/7 boundary-authoring +
verdict-integrity cluster (charter in
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/state.md`;
locked design in
`file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/011/fix-plan-draft.md`).

The task breakdown, capacity, effort, owners, and traceability are **finalized at the plan
boundary** (after specify + clarify), per one-boundary discipline — not drafted at open.

- **Requirements in scope**: FR-022 (iteration-011 amendment — capture ≠ author), FR-026
  (verdict-integrity), FR-027 (committed ≠ authorized resume). DF-1 / DF-2 trace to existing
  FR-002 / FR-022 (no new FR).
- **Locked fix sequence**: Fix A (authoring + clobber) → Fix C (verdict capture) → Fix B
  (committed ≠ authorized resume) → Fix D/E (DF-1 recap synthesis + DF-2 version/branch, small).
- **Acceptance**: a focused re-dogfood of the DF-3/4/5/7 scenario (real-host behavior is the gate).
- **Out of scope**: DF-6 (cursor continuity — within F-174, a later iteration); DF-8
  (agent-edits-governance — a separate proposal).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

Empty until the plan boundary.

## Effort Model

| Setting | Value |
| ------- | ----- |
| Effort Unit | story_points |
| Capacity per Iteration | 20 |
| Iteration Bounding | scope |
| Time Limit (hours) | n/a |
| Overcommit Threshold | 1.0 |
| Defer Strategy | manual |
| Calibration Enabled | true |

## Phase Baseline

Baseline: iteration-010 HEAD (`c5756473`) — F-174 iteration 010 closed (accepted, delivered scope).
