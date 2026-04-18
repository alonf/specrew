# Specrew: Planning

**Type**: Ceremony  
**Schema**: v1  
**Status**: Active governance template

## Purpose

Turn approved scope into an executable iteration plan without breaking spec authority, traceability, or lifecycle rules.

## Trigger

- Start of an iteration
- Re-planning after an abandonment or review-driven re-entry to execution
- Any time scope changes require a new approved plan before execution continues

## Participants

| Role | Responsibility |
| ---- | -------------- |
| Planner | Leads decomposition, estimates effort, and drafts the task table |
| Spec Steward | Runs the spec-authority and traceability gates |
| Implementer | Flags execution risks, hidden dependencies, and sequencing issues |
| Chief Architect | Approves plan exceptions, overcommit, and architectural trade-offs |

## Required Inputs

| Input | Source | Description |
| ----- | ------ | ----------- |
| Spec requirements | `specs/NNN-feature/spec.md` | Authoritative FRs, user stories, and constraints in scope |
| Iteration config | `.specrew/iteration-config.yml` | Capacity, effort unit, and overcommit threshold |
| Role assignments | `.specrew/role-assignments.yml` | Available owners for execution and review |
| Prior retro/review | Previous iteration artifacts | Calibration, carryover work, and process corrections |
| Pre-planning spike results | Research notes / decisions | Required architecture-risk answers before task assignment |

## Ceremony Method

### 1. Pre-planning gate

Before drafting tasks, confirm:

1. required architecture-risk spikes are complete
2. the scope is named explicitly by requirement ID
3. any carryover or deferred work is still valid against the current spec

If one of these is false, do not produce a plan.

### 2. Requirement slicing

For each in-scope requirement:

1. identify deliverables
2. identify enabling work that is still traceable to that requirement
3. note dependencies and ordering constraints
4. flag any work that belongs in a different iteration instead of sneaking it in

### 3. Task decomposition and ownership

Build a single `## Tasks` table in `plan.md`.

Every task must include:

- task ID
- title
- requirement reference
- story reference
- effort
- owner
- initial status

Owners are role names, not agent nicknames.

### 4. Estimation and phase variance setup

Estimate effort twice:

1. **task level** for the task table
2. **phase level** for planning, discovery/spikes, implementation, review, and expected rework

This creates the baseline the retrospective will compare against.

### 5. Hard governance gates

The planning ceremony does not finish until all checks pass:

1. **Spec authority**: every task maps to an in-scope requirement
2. **Traceability**: no orphan tasks, no uncovered in-scope requirements
3. **Capacity**: total effort is within threshold or explicitly approved
4. **Lifecycle readiness**: the plan can transition to execution without missing required artifacts

Use `specrew-capacity-planning` to pressure-test estimates and `specrew-traceability-check` before approval.

### 6. Plan output

Write or update `iterations/NNN/plan.md` with:

- metadata (`Schema`, `Status`, `Capacity`, `Started`, `Completed`)
- the task table
- traceability summary
- known risks, deferred work, and gate outcomes

Set `Status: planning` until approval is recorded.

## Outputs

| Output | Destination | Description |
| ------ | ----------- | ----------- |
| Iteration plan | `iterations/NNN/plan.md` | Approved task table and governance metadata |
| Traceability evidence | Embedded in `plan.md` | Requirement-to-task coverage and exceptions |
| Capacity baseline | Embedded in `plan.md` | Task and phase-level estimates for retro comparison |
| Sequencing notes | Embedded in `plan.md` | Architecture risks, dependencies, and approved deferrals |

## Escalation

| Condition | Escalation Path |
| --------- | --------------- |
| Requirement ambiguity | Route to Picard for clarification or tracked change |
| Capacity breach | Route to Alon for deferral or overcommit approval |
| Hidden architecture risk | Pause planning and run a pre-planning spike |
| Missing traceability | Revise the plan before any task assignment |

## Exit Condition

Planning ends only when the plan is approved and safe to transition from `planning` to `executing`.
