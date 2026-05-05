# Data Model: Specrew

**Date**: 2026-04-17
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Entities

### Specrew Configuration

Represents the bootstrap-generated state tying both extensions together.

**Location**: `.specrew/config.yml` in the downstream project root.

| Field | Type | Description |
| ----- | ---- | ----------- |
| specrew_version | string | Version of Specrew that created this config |
| speckit_version | string | Detected/installed Spec Kit version |
| squad_version | string | Detected/installed Squad version |
| bootstrap_date | ISO date | When `specrew init` was run |
| bootstrap_mode | enum: greenfield, brownfield | How config was created |
| governance.constitution_path | path | Relative path to downstream constitution |
| governance.iteration_config_path | path | Relative path to iteration config |
| governance.role_assignments_path | path | Relative path to role assignments |

**Relationships**: References Downstream Constitution, Iteration Config, Role Assignments.

---

### Downstream Constitution

A governance template for the user's project. Distinct from Specrew's own constitution.

**Location**: `.specrew/constitution.md` in the downstream project root.

| Field | Type | Description |
| ----- | ---- | ----------- |
| (Markdown document) | md | User-customizable governance principles |
| version | string (footer) | Document version |
| created_by | string (footer) | "specrew init" or user-customized |
| last_modified | ISO date (footer) | Last modification date |

**Relationships**: Referenced by Specrew Configuration. Independent of Specrew's own `.specify/memory/constitution.md`.

**Validation**: Must not be identical to Specrew's own constitution (FR-011).

---

### Iteration Config

Controls effort measurement and iteration behavior.

**Location**: `.specrew/iteration-config.yml` in the downstream project root.

| Field | Type | Default | Description |
| ----- | ---- | ------- | ----------- |
| effort_unit | string | "story_points" | Unit for effort measurement (Specrew v1 design decision) |
| capacity_per_iteration | number | 20 | Max effort units per iteration |
| iteration_bounding | enum: scope, time | "scope" | How iterations are bounded |
| time_limit_hours | number? | null | If time-bounded, max hours |
| overcommit_threshold | float | 1.0 | Ratio above which overcommit warning fires |
| calibration_enabled | boolean | true | Whether retro suggests calibration adjustments |
| defer_strategy | enum: manual, lowest_priority | "manual" | How planning chooses deferrals when the iteration is over capacity |
 
**Relationships**: Used by Planning ceremony and Capacity Planning skill.

---

### Role Assignments

Maps Specrew roles to agents or humans.

**Location**: `.specrew/role-assignments.yml` in the downstream project root.

| Field | Type | Description |
| ----- | ---- | ----------- |
| roles[] | array | List of role assignment entries |
| roles[].name | string | Role name (e.g., "Spec Steward") |
| roles[].type | enum: baseline, project | Whether this is a baseline or project-added role |
| roles[].assigned_to | string | Agent name, human name, or "unassigned" |
| roles[].preferred_agent | string? | Preferred Copilot-accessible agent family for this role (e.g., `copilot`, `claude`, `codex`) |
| roles[].responsibilities | string | Brief description of role's responsibilities |

**Baseline roles** (cannot be removed):
1. Spec Steward — Spec integrity, drift detection, reconciliation
2. Planner — Iteration planning, task decomposition, effort estimation
3. Implementer — Task execution, code generation
4. Reviewer — Review/demo verdicts, quality checks
5. Retro Facilitator — Retrospective ceremony, improvement actions

**Relationships**: Referenced by Specrew Configuration. Used by Squad team config and by FR-021 routing logic to derive Squad model overrides.

---

### Iteration

A delivery cycle with four phases.

**Location**: `specs/NNN-feature/iterations/NNN/`

| Field | Type | Description |
| ----- | ---- | ----------- |
| iteration_number | number | Sequential iteration number |
| spec_ref | path | Path to the spec this iteration delivers against |
| status | enum: planning, executing, reviewing, retro, complete, abandoned | Current phase |
| started | ISO datetime | When iteration started |
| completed | ISO datetime? | When iteration completed (null if in progress) |

**State transitions**:
```
planning → executing → reviewing → retro → complete
    ↓          ↓          ↓         ↓
 abandoned  abandoned  abandoned  abandoned
```

Any phase can transition to `abandoned` with a recorded reason. Abandoned tasks become available for the next iteration.

**Relationships**: Contains Iteration Plan, Drift Events, Review, Retrospective.

---

### Iteration Plan

Tasks for one iteration, mapped to spec requirements.

**Location**: `specs/NNN-feature/iterations/NNN/plan.md`

Plan-level snapshot fields:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| capacity | string | Yes | `{used}/{total} {effort_unit}` summary shown in plan metadata |
| effort_model.effort_unit | string | Yes | Snapshot of `.specrew/iteration-config.yml` |
| effort_model.capacity_per_iteration | number | Yes | Max effort for the iteration |
| effort_model.iteration_bounding | enum: scope, time | Yes | Scope vs. time-bounded planning mode |
| effort_model.time_limit_hours | number\|`n/a` | Yes | Displayed as `n/a` when not time-bounded |
| effort_model.overcommit_threshold | float | Yes | Threshold used by planning validation |
| effort_model.defer_strategy | enum: manual, lowest_priority | Yes | Deferral strategy snapshot |
| effort_model.calibration_enabled | boolean | Yes | Whether retro should suggest calibration |

Each task entry:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| task_id | string | Yes | e.g., "T-001" |
| title | string | Yes | Brief task description |
| requirement_ref | string | Yes | e.g., "FR-003" |
| user_story_ref | string | Yes | e.g., "US-2" |
| effort | number | Yes | Estimated effort in configured unit |
| owner | string | Yes | Assigned role name |
| status | enum: planned, in-progress, done, needs-rework, deferred | Yes | Task state |
| agent | string? | No | Which agent executed (recorded on completion) |
| actual_effort | number? | No | Actual effort (recorded on completion) |
| verdict | enum: pass, needs-work, blocked? | No | Review verdict (recorded at review) |

**Relationships**: Tasks trace to spec requirements (FR-018). Plan snapshots Iteration Config so generated artifacts and validators can confirm capacity/effort settings stayed aligned.

---

### Task State (for Resume)

Persistent execution state enabling resume after failure.

**Location**: `specs/NNN-feature/iterations/NNN/state.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| last_completed_task | string? | Yes | task_id of last successfully completed task |
| tasks_remaining | string[] | Yes | task_ids not yet started |
| tasks_in_progress | string? | Yes | task_id currently executing (null if between tasks) |
| updated | ISO datetime | Yes | Last state update |
| repair_escalation.status | enum: inactive, active | Yes | Whether a governance-repair escalation is currently in effect |
| repair_escalation.artifact | string? | No | Artifact currently under repair (for example `tasks.md`) |
| repair_escalation.gate | string? | No | Gate that is failing (for example `after-tasks`) |
| repair_escalation.failure_count | number | Yes | Count of consecutive failures for the active artifact/gate |
| repair_escalation.current_tier | enum: efficiency, balanced, deep | Yes | Current reasoning tier override for the repair cycle |
| repair_escalation.current_owner | string? | No | Agent currently assigned to the escalated repair |
| repair_escalation.locked_out_agents | string[] | Yes | Agents locked out of the next revision for this artifact |
| repair_escalation.last_escalated | ISO datetime? | No | Last time the escalation tier/owner changed |
| repair_escalation.resolved_at | ISO datetime? | No | When the active escalation was cleared after success |
| repair_escalation.notes | string? | No | Short explanation of the current escalation state |

**Relationships**: References Iteration Plan tasks and the current governance repair cycle. Updated after each task completes (FR-019) and after each escalation change (FR-027).

---

### Drift Event

A recorded divergence between implementation and spec.

**Location**: `specs/NNN-feature/iterations/NNN/drift-log.md`

Each event:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| drift_id | string | Yes | e.g., "DR-001" |
| detected_at | ISO datetime | Yes | When detected |
| task_ref | string | Yes | Which task triggered detection |
| requirement_ref | string | Yes | Which requirement was violated |
| description | string | Yes | What the deviation is |
| resolution | enum: spec-updated, implementation-reverted, deferred, human-decision | Yes | Chosen resolution |
| resolution_detail | string | No | Explanation of what was done |

**Relationships**: References task and requirement. Recorded during execution (FR-008).

---

### Review

Review/demo verdicts for an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/review.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| iteration_ref | number | Yes | Which iteration |
| reviewed_at | ISO datetime | Yes | When review ran |
| tasks[] | array | Yes | Per-task verdicts |
| tasks[].task_id | string | Yes | Task reference |
| tasks[].requirement_ref | string | Yes | Requirement reference |
| tasks[].verdict | enum: pass, needs-work, blocked | Yes | Per-task verdict |
| tasks[].notes | string | No | Reviewer notes |
| overall_verdict | enum: accepted, needs-rework, blocked | Yes | Iteration-level verdict |

**Relationships**: References Iteration Plan tasks and spec requirements (FR-009).

---

### Retrospective

Captures iteration learnings.

**Location**: `specs/NNN-feature/iterations/NNN/retro.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| iteration_ref | number | Yes | Which iteration |
| estimation_accuracy | object | Yes | Planned vs. actual effort summary |
| drift_summary | object | Yes | Count and severity of drift events |
| process_notes | string | Yes | What went well, what didn't |
| improvement_actions[] | string[] | Yes | Concrete actions for next iteration |
| calibration_suggestion | object? | No | Suggested capacity/effort adjustments |

**Relationships**: References Iteration Plan, Drift Events, Review (FR-010).

---

### Evaluation Report

Output of the evaluation harness.

**Location**: `evaluation/report.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| evaluated_at | ISO datetime | Yes | When harness ran |
| spec_ref | path | Yes | Reference spec used |
| iterations_completed | number | Yes | How many iterations ran |
| process_score | object | Yes | Ceremony adherence, drift detection rate, traceability coverage |
| outcome_score | object | No | Requirement coverage, acceptance pass rate, artifact consistency |
| overall | enum: PASS, FAIL | Yes | Summary verdict |
| details[] | array | Yes | Per-iteration breakdown |

**Relationships**: Aggregates data from all iterations (FR-015).

---

### Collision Record

A detected extension conflict.

**Location**: Logged to console/stderr during `specrew init` or iteration start. Not persisted unless collision blocks operation.

| Field | Type | Description |
| ----- | ---- | ----------- |
| detected_at | ISO datetime | When detected |
| conflicting_resource | string | Hook name, artifact path, or role name |
| extensions_involved | string[] | Names of conflicting extensions |
| severity | enum: hard-stop, warning | Whether operation is blocked |
| resolution_options | string[] | Suggested resolutions |
| user_choice | string? | What the user chose (if interactive) |

**Relationships**: May block `specrew init` or iteration start (FR-012).

---

### Delegated Agent

A Copilot-accessible agent option available to Specrew.

**Scope**: Detected, configured, and referenced during `specrew init` and throughout iteration execution.

| Field | Type | Description |
| ----- | ---- | ----------- |
| name | enum: Copilot, Claude, Codex | Agent identifier as exposed through Copilot / Agent HQ |
| access_path | enum: copilot_default, copilot_agent_hq, unavailable | How Specrew reaches this agent option |
| availability | enum: available, unavailable | Whether this agent is currently selectable in the user's Copilot environment |
| enabled | boolean | Whether user has opted in to use this agent |

**Cost/billing**: Not modeled. Consent is the only gate Specrew applies; any cost implications are between the user and GitHub.

**Relationships**: Configured in `iteration-config.yml` by `specrew init` (FR-022). Scope: per-project, per-iteration.
