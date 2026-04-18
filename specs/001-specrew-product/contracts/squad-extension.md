# Contract: Squad Native Integration

**Date**: 2026-04-18 (Revised from 2026-04-17 following Iteration 0 architecture decision)
**Spec**: [spec.md](../spec.md)  
**Requirements**: FR-001, FR-004, FR-005, FR-008, FR-013  
**Decision**: `.squad\decisions\inbox\copilot-squad-native-surfaces-2026-04-18T00-24-57Z.md`

## Architecture Rationale

Iteration 0 spike results (T-017, T-020) confirmed Squad does NOT support a packaged `extensions/specrew-squad/` plugin structure. Squad's extension model is:

- **Skills**: Discovered from `.copilot/skills/{skill-name}/SKILL.md` (per-skill subdirectory)
- **Ceremonies**: Registered in `.squad/ceremonies.md` (central file)
- **Directives**: Referenced in `.squad/agents/{agent}/charter.md` (per-agent charter)
- **Plugins**: Marketplace-only (GitHub repos); no local bundled plugin path

Specrew v1 therefore uses **Squad-native surfaces directly** rather than creating a separate extension package.

## Deployment Structure

### Skills Location

```text
.copilot/
  └─ skills/
      ├─ specrew-drift-check/
      │   └─ SKILL.md
      ├─ specrew-capacity-planning/
      │   └─ SKILL.md
      ├─ specrew-traceability-check/
      │   └─ SKILL.md
      └─ specrew-iteration-resume/
          └─ SKILL.md
```

All Specrew skills use `specrew-*` prefix to avoid namespace collisions.

### Ceremonies Registration

Ceremonies are registered in `.squad/ceremonies.md` (appended by `specrew init`):

```markdown
## Specrew: Planning

**Type**: Decision Gate  
**When**: Start of iteration  
**Inputs**: Spec requirements, iteration config, role assignments  
**Outputs**: `iterations/NNN/plan.md` with task table  
**Approval**: User or Spec Steward must approve plan before execution begins

... (ceremony prompt content) ...

## Specrew: Review/Demo

**Type**: Delivery Gate  
**When**: End of iteration  
**Inputs**: Completed tasks, spec requirements, drift log  
**Outputs**: `iterations/NNN/review.md` with per-task verdicts  
**Verdicts**: pass | needs-work | blocked (per task); accepted | needs-rework | blocked (iteration)

... (ceremony prompt content) ...
```

### Directives

Directives are governance rules included in agent charters. When `specrew init` creates/updates agents in `.squad/agents/`, it adds Specrew directives to their charter files:

```markdown
## Directives

### Spec Authority

The spec is the authoritative source of truth. Do not make implementation decisions that contradict the spec without raising a drift event.

### Traceability

Every task must record which requirement it traces to, who owns it, and the effort estimate. No orphan tasks.

### Drift Reporting

After completing any task, invoke the `specrew-drift-check` skill. Report drift immediately. Do not normalize or suppress deviations.
```

## Skill Contracts

### specrew-drift-check

**When to use**: After each task is completed during an iteration.  
**Invoked by**: Reviewer role (triggered by drift-reporting directive) or Review/Demo ceremony (batch fallback).  
**Inputs**: Task output, source requirement text, spec path.  
**Outputs**: PASS (no drift) or DRIFT (with requirement ref, deviation description).  
**Side effects**: Appends to `drift-log.md` if drift detected.

### specrew-capacity-planning

**When to use**: During the Planning ceremony.  
**Invoked by**: Planner role.  
**Inputs**: Spec requirements, iteration config (effort unit, capacity limit).  
**Outputs**: Task list with effort estimates. Warning if total exceeds capacity.  
**Side effects**: None (produces plan content).

### specrew-traceability-check

**When to use**: Before review, or on demand.  
**Invoked by**: Spec Steward role.  
**Inputs**: Iteration plan tasks, spec requirements.  
**Outputs**: Coverage report (which requirements have tasks, which don't).  
**Side effects**: None.

### specrew-iteration-resume

**When to use**: When an iteration was interrupted and needs to continue.  
**Invoked by**: Any agent, on user request.  
**Inputs**: `state.md` from the interrupted iteration.  
**Outputs**: List of remaining tasks, suggested next task.  
**Side effects**: Updates `state.md` status.

## Ceremony Contracts

### Planning (Specrew-defined)

**Decision gate**: User must approve the plan before status moves to "executing".  
**Inputs**: Spec requirements, iteration config, role assignments.  
**Outputs**: `iterations/NNN/plan.md` with task table.  
**Verdicts**: N/A (planning produces a plan, not a verdict).  
**Escalation**: If capacity exceeded, flag and suggest deferral.

### Review/Demo (Specrew-defined)

**Decision gate**: Each task gets a verdict. Iteration gets an overall verdict.  
**Inputs**: Completed tasks, spec requirements, drift log.  
**Outputs**: `iterations/NNN/review.md` with per-task verdicts.  
**Verdicts**: pass | needs-work | blocked (per task). accepted | needs-rework | blocked (iteration).  
**Escalation**: needs-work tasks re-enter backlog. blocked tasks escalate to human.

## Installation

`specrew init` handles all Squad-native configuration:

1. Creates skill directories under `.copilot/skills/specrew-*/`
2. Copies `SKILL.md` files into each skill directory
3. Appends ceremony definitions to `.squad/ceremonies.md`
4. Merges directive text into agent charters in `.squad/agents/*/charter.md`
5. Adds 5 baseline roles to `.squad/team.md`

No `squad plugin install` command is used (marketplace-only, not applicable to bundled distribution).

## Version Control

Skills, ceremonies, and directives are versioned with the Specrew Spec Kit extension. The monorepo `extensions/specrew-speckit/extension.yml` contains the Specrew version number. Squad-native files deployed by `specrew init` are derived from this source.

## Upgrade Path

When Specrew releases a new version:

1. User updates Specrew Spec Kit extension (via `specify extension update specrew-speckit`)
2. User runs `specrew init --upgrade` (TBD: Iteration 2 FR-016 scope)
3. Script updates skills, ceremonies, directives in `.copilot/` and `.squad/` directories
4. User customizations (team roles, agent charter additions) are preserved

## Collision Avoidance

- **Skill namespace**: All Specrew skills prefixed with `specrew-*`
- **Ceremony names**: `Specrew: Planning`, `Specrew: Review/Demo` (explicit prefix)
- **Directive names**: Embedded in agent charters (no global namespace collision)
- **Role names**: Checked at bootstrap (FR-012: collision detector, Iteration 3)

## Extension Coexistence

Specrew's Squad integration is **additive-only**:

- Appends to `.squad/ceremonies.md` (never overwrites existing ceremonies)
- Merges roles into `.squad/team.md` (never replaces existing team)
- Adds directives to agent charters (preserves user-added directives)
- Deploys skills to dedicated `specrew-*` subdirectories (no file conflicts)

This ensures Specrew coexists with other Squad configurations and user customizations.
