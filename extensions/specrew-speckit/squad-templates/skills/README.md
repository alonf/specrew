# Specrew Skills (Squad-Native Templates)

## Overview

This directory contains Squad skill templates for Specrew runtime deployment. The bootstrap/runtime scripts copy the active slash-command skills content-identically to `.claude/skills/specrew-*/SKILL.md`, `.github/skills/specrew-*/SKILL.md`, and `.agents/skills/specrew-*/SKILL.md`.

## Skills

### specrew-drift-check

**When to use**: After each task is completed during an iteration.
**Invoked by**: Reviewer role (triggered by drift-reporting directive) or Review/Demo ceremony (batch fallback).
**Inputs**: Task ID, task output, requirement ref/text, spec path, and optional drift-log path / reviewer notes.
**Outputs**: PASS with evidence summary, or DRIFT with contract-aligned event data and a log-ready entry.
**Side effects**: Prepares updates for `drift-log.md`, including replacing the zero-drift placeholder summary when the first real event is logged.

### specrew-capacity-planning

**When to use**: During the Planning ceremony.
**Invoked by**: Planner role.
**Inputs**: Spec requirements, iteration config (effort unit, capacity limit).
**Outputs**: Task list with effort estimates, phase baseline, and overcommit guidance.
**Side effects**: None (produces plan content).

### specrew-traceability-check

**When to use**: Before plan approval, before review when needed, or on demand.
**Invoked by**: Spec Steward role.
**Inputs**: Iteration plan tasks, spec requirements.
**Outputs**: Coverage report plus required fixes for orphan tasks or uncovered requirements.
**Side effects**: None.

### specrew-iteration-resume

**Status**: Active recovery skill (FR-019 / Iteration 2).
**When to use**: When an iteration was interrupted and needs to continue.
**Invoked by**: Any agent, on user request.
**Inputs**: `state.md` plus `plan.md` from the interrupted iteration.  
**Outputs**: List of remaining tasks, suggested next task, blockers, and salvageable tasks when aborting.  
**Side effects**: Updates `state.md` with a resume report when the iteration is resumable or intentionally re-planned.

## Status

**Status**: Active governance and recovery skills for planning, drift detection, traceability, and iteration resume

## Slash-Command Runtime Skills

These subdirectory skills are deployed directly to the three active project skill roots and back the Feature 024 `/specrew-*` surface:

| Skill directory | Slash command | Purpose |
| --- | --- | --- |
| `specrew-where` | `/specrew-where` | Current Specrew project dashboard |
| `specrew-status` | `/specrew-status` | Alias for `/specrew-where` |
| `specrew-update` | `/specrew-update` | Refresh Specrew-managed assets |
| `specrew-team` | `/specrew-team` | Manage Squad team members |
| `specrew-review` | `/specrew-review` | Replay review state without approving a boundary |
| `specrew-help` | `/specrew-help` | Canonical catalog fallback |
| `specrew-version` | `/specrew-version` | Version and compatibility inspection |

## References

- Contract: [squad-extension.md](../../../../specs/001-specrew-product/contracts/squad-extension.md)
