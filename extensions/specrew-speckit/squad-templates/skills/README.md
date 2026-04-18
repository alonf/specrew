# Specrew Skills (Squad-Native Templates)

## Overview

This directory contains Squad skill templates that will be deployed to `.copilot/skills/specrew-*/SKILL.md` in downstream projects by `specrew init`.

## Skills

### specrew-drift-check

**When to use**: After each task is completed during an iteration.  
**Invoked by**: Reviewer role (triggered by drift-reporting directive) or Review/Demo ceremony (batch fallback).  
**Inputs**: Task output, source requirement text, spec path.  
**Outputs**: PASS (no drift) or DRIFT (with requirement ref, deviation description, and log-ready entry).  
**Side effects**: Appends to `drift-log.md` if drift detected.

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

**When to use**: When an iteration was interrupted and needs to continue.  
**Invoked by**: Any agent, on user request.  
**Inputs**: `state.md` from the interrupted iteration.  
**Outputs**: List of remaining tasks, suggested next task.  
**Side effects**: Updates `state.md` status.

## Status

**Status**: Active governance skills for planning, drift detection, and traceability

## References

- Contract: [squad-extension.md](../../../../specs/001-specrew-product/contracts/squad-extension.md)
