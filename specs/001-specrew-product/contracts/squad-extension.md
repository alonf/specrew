# Contract: Squad Extension Structure

**Date**: 2026-04-17
**Spec**: [spec.md](../spec.md)
**Requirements**: FR-001, FR-004, FR-005, FR-008, FR-013

## Extension Package Structure

```text
specrew-squad/
├── skills/
│   ├── drift-check.md
│   ├── capacity-planning.md
│   ├── traceability-check.md
│   └── iteration-resume.md
├── ceremonies/
│   ├── planning.md
│   └── review-demo.md
├── directives/
│   ├── spec-authority.md
│   ├── traceability.md
│   └── drift-reporting.md
└── README.md
```

## Skill Contracts

### drift-check.md

**When to use**: After each task is completed during an iteration.
**Invoked by**: Reviewer role (triggered by drift-reporting directive).
**Inputs**: Task output, source requirement text, spec path.
**Outputs**: PASS (no drift) or DRIFT (with requirement ref, deviation description).
**Side effects**: Appends to `drift-log.md` if drift detected.

### capacity-planning.md

**When to use**: During the Planning ceremony.
**Invoked by**: Planner role.
**Inputs**: Spec requirements, iteration config (effort unit, capacity limit).
**Outputs**: Task list with effort estimates. Warning if total exceeds capacity.
**Side effects**: None (produces plan content).

### traceability-check.md

**When to use**: Before review, or on demand.
**Invoked by**: Spec Steward role.
**Inputs**: Iteration plan tasks, spec requirements.
**Outputs**: Coverage report (which requirements have tasks, which don't).
**Side effects**: None.

### iteration-resume.md

**When to use**: When an iteration was interrupted and needs to continue.
**Invoked by**: Any agent, on user request.
**Inputs**: `state.md` from the interrupted iteration.
**Outputs**: List of remaining tasks, suggested next task.
**Side effects**: Updates `state.md` status.

## Ceremony Contracts

### planning.md (Specrew-defined)

**Decision gate**: User must approve the plan before status moves to "executing".
**Inputs**: Spec requirements, iteration config, role assignments.
**Outputs**: `iterations/NNN/plan.md` with task table.
**Verdicts**: N/A (planning produces a plan, not a verdict).
**Escalation**: If capacity exceeded, flag and suggest deferral.

### review-demo.md (Specrew-defined)

**Decision gate**: Each task gets a verdict. Iteration gets an overall verdict.
**Inputs**: Completed tasks, spec requirements, drift log.
**Outputs**: `iterations/NNN/review.md` with per-task verdicts.
**Verdicts**: pass | needs-work | blocked (per task). accepted | needs-rework | blocked (iteration).
**Escalation**: needs-work tasks re-enter backlog. blocked tasks escalate to human.

## Directive Contracts

### spec-authority.md

**Rule**: The spec is the authoritative source of truth. Do not make implementation decisions that contradict the spec without raising a drift event.
**Applies to**: All agents in the crew.
**Enforcement**: Drift-check skill validates compliance.

### traceability.md

**Rule**: Every task must record which requirement it traces to, who owns it, and the effort estimate. No orphan tasks.
**Applies to**: Planner, Implementer.
**Enforcement**: Traceability-check skill validates compliance.

### drift-reporting.md

**Rule**: After completing any task, invoke the drift-check skill. Report drift immediately. Do not normalize or suppress deviations.
**Applies to**: All agents executing tasks.
**Enforcement**: Built into task completion workflow.

## Installation

```
squad plugin install github/{org}/specrew-squad
```

Or for local development:
```
# Copy into .squad/ directly
cp -r specrew-squad/skills/* .squad/skills/
cp -r specrew-squad/ceremonies/* .squad/ceremonies/
cp -r specrew-squad/directives/* .squad/directives/
```
