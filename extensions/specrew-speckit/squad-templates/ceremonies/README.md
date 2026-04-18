# Specrew Ceremonies (Squad-Native Templates)

## Overview

This directory contains ceremony definition templates that will be appended to `.squad/ceremonies.md` in downstream projects by `specrew init`.

## Ceremonies

### Specrew: Planning

**Type**: Ceremony  
**When**: Before execution or any re-plan  
**Inputs**: Spec, role assignments, iteration config, prior retro, pre-planning spikes  
**Outputs**: `iterations/NNN/plan.md` with traceable tasks, capacity baseline, and gate outcomes  
**Gate**: Spec authority, traceability, capacity, and lifecycle readiness must all pass before execution starts.

### Specrew: Review/Demo

**Type**: Ceremony  
**When**: After execution reaches terminal task states  
**Inputs**: Plan, state, drift log, delivered artifacts, spec  
**Outputs**: `iterations/NNN/review.md` with per-task verdicts and iteration routing  
**Verdicts**: pass | needs-work | blocked (per task); accepted | needs-rework | blocked (iteration)  
**Gate**: Missing `state.md`, missing `drift-log.md`, or non-terminal tasks block review entry.

### Specrew: Retrospective

**Type**: Ceremony  
**When**: After `review.md` records an overall verdict  
**Inputs**: Plan, state, drift log, review  
**Outputs**: `iterations/NNN/retro.md` with estimation accuracy, drift summary, process notes, and improvement actions  
**Gate**: Retro cannot close until the artifact is complete enough to feed the next planning ceremony.

## Status

**Status**: Active governance templates for downstream Squad deployment

## References

- Contract: [squad-extension.md](../../../../specs/001-specrew-product/contracts/squad-extension.md)
