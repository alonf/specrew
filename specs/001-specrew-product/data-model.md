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
| roles[].responsibilities | string | Brief description of role's responsibilities |

**Baseline roles** (cannot be removed):
1. Spec Steward — Spec integrity, drift detection, reconciliation
2. Planner — Iteration planning, task decomposition, effort estimation
3. Implementer — Task execution, code generation
4. Reviewer — Review/demo verdicts, quality checks
5. Retro Facilitator — Retrospective ceremony, improvement actions

**Relationships**: Referenced by Specrew Configuration. Used by Squad team config.

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

Each task entry:

| Field | Type | Description |
| ----- | ---- | ----------- |
| task_id | string | e.g., "T-001" |
| title | string | Brief task description |
| requirement_ref | string | e.g., "FR-003" |
| user_story_ref | string | e.g., "US-2" |
| effort | number | Estimated effort in configured unit |
| owner | string | Assigned role name |
| status | enum: planned, in-progress, done, needs-rework, deferred | Task state |
| agent | string? | Which agent executed (recorded on completion) |
| actual_effort | number? | Actual effort (recorded on completion) |
| verdict | enum: pass, needs-work, blocked? | Review verdict (recorded at review) |

**Relationships**: Tasks trace to spec requirements (FR-018). Plan references Iteration Config for capacity.

---

### Task State (for Resume)

Persistent execution state enabling resume after failure.

**Location**: `specs/NNN-feature/iterations/NNN/state.md`

| Field | Type | Description |
| ----- | ---- | ----------- |
| last_completed_task | string? | task_id of last successfully completed task |
| tasks_remaining | string[] | task_ids not yet started |
| tasks_in_progress | string? | task_id currently executing (null if between tasks) |
| updated | ISO datetime | Last state update |

**Relationships**: References Iteration Plan tasks. Updated after each task completes (FR-019).

---

### Drift Event

A recorded divergence between implementation and spec.

**Location**: `specs/NNN-feature/iterations/NNN/drift-log.md`

Each event:

| Field | Type | Description |
| ----- | ---- | ----------- |
| drift_id | string | e.g., "DR-001" |
| detected_at | ISO datetime | When detected |
| task_ref | string | Which task triggered detection |
| requirement_ref | string | Which requirement was violated |
| description | string | What the deviation is |
| resolution | enum: spec-updated, implementation-reverted, deferred, human-decision | Chosen resolution |
| resolution_detail | string | Explanation of what was done |

**Relationships**: References task and requirement. Recorded during execution (FR-008).

---

### Review

Review/demo verdicts for an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/review.md`

| Field | Type | Description |
| ----- | ---- | ----------- |
| iteration_ref | number | Which iteration |
| reviewed_at | ISO datetime | When review ran |
| tasks[] | array | Per-task verdicts |
| tasks[].task_id | string | Task reference |
| tasks[].requirement_ref | string | Requirement reference |
| tasks[].verdict | enum: pass, needs-work, blocked | Per-task verdict |
| tasks[].notes | string | Reviewer notes |
| overall_verdict | enum: accepted, needs-rework, blocked | Iteration-level verdict |

**Relationships**: References Iteration Plan tasks and spec requirements (FR-009).

---

### Retrospective

Captures iteration learnings.

**Location**: `specs/NNN-feature/iterations/NNN/retro.md`

| Field | Type | Description |
| ----- | ---- | ----------- |
| iteration_ref | number | Which iteration |
| estimation_accuracy | object | Planned vs. actual effort summary |
| drift_summary | object | Count and severity of drift events |
| process_notes | string | What went well, what didn't |
| improvement_actions[] | string[] | Concrete actions for next iteration |
| calibration_suggestion | object? | Suggested capacity/effort adjustments |

**Relationships**: References Iteration Plan, Drift Events, Review (FR-010).

---

### Evaluation Report

Output of the evaluation harness.

**Location**: `specs/NNN-feature/evaluation/report.md`

| Field | Type | Description |
| ----- | ---- | ----------- |
| evaluated_at | ISO datetime | When harness ran |
| spec_ref | path | Reference spec used |
| iterations_completed | number | How many iterations ran |
| process_score | object | Ceremony adherence, drift detection rate, traceability coverage |
| outcome_score | object | Requirement coverage, acceptance pass rate, artifact consistency |
| overall | enum: PASS, FAIL | Summary verdict |
| details[] | array | Per-iteration breakdown |

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
