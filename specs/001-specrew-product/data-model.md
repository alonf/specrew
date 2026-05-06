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

**Validation**:
- YAML MUST contain the listed top-level scalar fields plus a `governance` mapping.
- `bootstrap_mode` MUST be either `greenfield` or `brownfield`.
- `bootstrap_date` MUST be an ISO date recorded at bootstrap time.
- `governance.*_path` values MUST be relative project paths that point to tracked downstream governance files under `.specrew/`.

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
| reviewer.test_path_globs | string[] | language heuristics | Glob patterns used to classify changed files as tests for reviewer artifacts |
| reviewer.sensitive_data_patterns | string[] | auth\*, secret\*, credential\*, token\*, key\*, crypto\* | Path/name patterns used by the security surface to flag sensitive modules |
| reviewer.test_commands | string[] | [] | Review-time test commands to execute when generating coverage evidence |
| reviewer.coverage.tool | string | "" | Coverage tool name when measured coverage is configured |
| reviewer.coverage.kind | enum: measured, qualitative | "qualitative" | Whether coverage evidence is measured or estimated |
| reviewer.skip_test_execution_at_close | boolean | false | Whether review-time test execution is skipped and recorded as not executed |
| reviewer.vulnerability_scanner.auto_detect | boolean | true | Whether Specrew should auto-detect recognized vulnerability scanners |
| reviewer.vulnerability_scanner.command | string | "" | Optional explicit scanner command override |
| reviewer.vulnerability_scanner.candidates | string[] | npm audit, dotnet list package --vulnerable, pip-audit, cargo audit, govulncheck | Commands eligible for auto-detection in v1 |
| reviewer.baseline_ref | string | "iteration-baseline" | Git reference recorded at iteration start for reviewer diff calculations |
| reviewer.diagram_format | enum: mermaid | "mermaid" | Reviewer diagram format used for generated structure/flow diagrams in v1 |
| reviewer.hotspot_thresholds.file_changed_lines | number | 250 | Per-file hotspot threshold |
| reviewer.hotspot_thresholds.function_changed_lines | number | 100 | Function-equivalent hotspot threshold |
| reviewer.diagram_thresholds.structure.min_modules_touched | number | 3 | Minimum modules touched before a structure diagram is required |
| reviewer.diagram_thresholds.structure.min_inter_module_edges | number | 2 | Minimum inter-module edges before a structure diagram is required |
| reviewer.diagram_thresholds.flow.min_entrypoints_changed | number | 1 | Minimum changed entrypoints before a flow diagram is required |
| reviewer.diagram_thresholds.flow.min_modules_in_flow | number | 2 | Minimum modules involved before a flow diagram is required |
  
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
| concurrency_rationale | markdown section | No | Auditable rationale for any same-specialty parallelism proposal or rejection |

Each task entry:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| task_id | string | Yes | e.g., "T-001" |
| title | string | Yes | Brief task description |
| requirement_ref | string | Yes | e.g., "FR-003" |
| user_story_ref | string | Yes | e.g., "US-2" |
| effort | number | Yes | Estimated effort in configured unit |
| owner | string | Yes | Assigned role name |
| owner_file_globs | string[] | No | Ownership-boundary globs for tasks allowed to run in parallel with same-specialty peers |
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
| baseline_ref | string | Yes | Git ref captured at iteration start and used as the reviewer-artifact diff baseline |
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
| gap_ledger | markdown section | Yes | Canonical `## Gap Ledger` section for unresolved or deferred alignment gaps |

**Relationships**: References Iteration Plan tasks and spec requirements (FR-009).

---

### Decisions Ledger

Canonical shared ledger for team-binding governance and lifecycle decisions.

**Location**: `.squad/decisions.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Ledger schema marker, currently `v1` |
| entries[] | array | Yes | Ordered append-only decision entries |
| entries[].decision_id | string | Yes | Unique decision identifier |
| entries[].type | enum: decision, defer, escalation, routing-evidence, clarify-skip, review-gap | Yes | Decision/event category |
| entries[].affected_requirement | string? | No | FR/TG/user-story reference when applicable |
| entries[].affected_iteration | string? | No | Iteration or feature reference when applicable |
| entries[].rationale | markdown section | Yes | Why the decision or event was recorded |
| entries[].approving_human | string? | No | Human approver when explicit approval is required |
| entries[].recorded_at | ISO datetime | Yes | When the entry was recorded |
| entries[].next_action | string? | No | Required follow-up action or explicit `none` |

**Append Policy**:
- `.squad/decisions.md` is the canonical shared ledger and MUST remain append-only in normal operation.
- Specrew-owned scripts MUST write runtime-routing evidence, escalation changes, and approved defers directly to this ledger when those events occur.
- Agent-authored team decisions MAY stage through `.squad/decisions/inbox/`, but only merged entries in `.squad/decisions.md` are canonical shared truth.

**Relationships**: Referenced by FR-027, FR-043, FR-044, FR-045, FR-055, and FR-056 as the shared governance ledger.

---

### Code Map

Reviewer-facing index of the code surface changed by an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/code-map.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| files_touched[] | array | Yes | Changed-file rows |
| files_touched[].path | path | Yes | Relative file path |
| files_touched[].added | number | Yes | Lines added |
| files_touched[].removed | number | Yes | Lines removed |
| files_touched[].owning_task | string | Yes | Task ID(s) responsible for the change |
| files_touched[].owning_role | string | Yes | Role responsible for the change |
| public_api_delta | markdown section | Yes | Added/removed top-level API declarations, best effort |
| module_hotspots | markdown section | Yes | Review-attention hotspots based on change thresholds |
| test_to_code_ratio | string | Yes | Summary of changed test files vs changed non-test files |

**Relationships**: Derived from the iteration diff and Iteration Plan task ownership (FR-046).

---

### Dependency Report

Reviewer-facing dependency and vulnerability evidence for an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/dependency-report.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| dependency_delta[] | array | Yes | Per-package dependency change rows |
| dependency_delta[].ecosystem | string | Yes | Ecosystem name (`npm`, `NuGet`, `PyPI`, `Cargo`, `Go`, etc.) |
| dependency_delta[].package | string | Yes | Package/module name |
| dependency_delta[].from_version | string | No | Prior version when known |
| dependency_delta[].to_version | string | No | New version when known |
| dependency_delta[].change_type | enum: added, upgraded, removed, downgraded | Yes | Type of dependency change |
| dependency_delta[].license | string | Yes | Declared license or `unknown` |
| dependency_delta[].owning_task | string | Yes | Task responsible for the dependency change |
| new_to_project | markdown section | Yes | Packages introduced for the first time |
| vulnerability_scan | markdown section | Yes | Verbatim scan output or explicit unscanned note |
| transitive_surface | string | Yes | Whether transitive dependencies were resolved and by what command |

**Relationships**: Derived from manifest/lockfile diffs and optional external scanner output (FR-047).

---

### Coverage Evidence

Reviewer-facing testing and coverage signal for an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/coverage-evidence.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| test_strategy | markdown section | Yes | Referenced test strategy aligned to the implementation briefing |
| tests_run[] | array | Yes | Executed test-command rows |
| tests_run[].command | string | Yes | Test command executed at review time |
| tests_run[].result | string | Yes | Pass/fail summary |
| tests_run[].duration | string | Yes | Duration captured for the run |
| tests_run[].exit_code | number | Yes | Actual command exit code |
| coverage_estimate.kind | enum: measured, qualitative | Yes | Whether coverage is measured or estimated |
| coverage_estimate.label | string | Yes | Percentage or qualitative label, depending on kind |
| coverage_estimate.tool | string | No | Coverage tool when measured coverage is available |
| coverage_to_requirements[] | array | Yes | Requirement-to-test traceability rows |
| coverage_to_requirements[].requirement_ref | string | Yes | FR/TG covered in the iteration |
| coverage_to_requirements[].test_files | string[] | Yes | Test files or commands providing coverage evidence |

**Relationships**: References Iteration Plan traceability, review-time test execution, and the implementation briefing (FR-049).

---

### Security Surface

Conditional reviewer-facing security evidence for an iteration.

**Location**: `specs/NNN-feature/iterations/NNN/security-surface.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| trust_boundaries_touched | markdown section | Yes | Entry points and trust boundaries affected by the iteration |
| sensitive_data_touchpoints | markdown section | Yes | Files/modules matching configured sensitive-data patterns |
| security_specialist_findings | markdown section | Yes | Specialist findings or explicit notice that no security specialist was present |
| vulnerability_highlights | markdown section | Yes | HIGH/CRITICAL findings reproduced from the dependency report |

**Relationships**: Generated only when security is materially in scope per plan/team context (FR-048).

---

### Reviewer Index

The primary entrypoint a human reviewer opens first for a closed iteration.

**Location**: `specs/NNN-feature/iterations/NNN/reviewer-index.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| summary | markdown section | Yes | Same headline content as the Reviewer Summary console block |
| read_order | string[] | Yes | Recommended artifact reading order |
| artifact_links | string[] | Yes | Links to related iteration artifacts, decisions evidence, and diff URLs when known |
| triage_hints | string[] | Yes | Hotspots and review-attention signals |

**Relationships**: References Review, Drift Events, Code Map, Dependency Report, Coverage Evidence, Security Surface, Review Diagrams, Current Architecture View, and implementation briefing surfaces (FR-052).

---

### Review Diagrams

Reviewer-facing structural and flow diagrams for a closed iteration.

**Location**: `specs/NNN-feature/iterations/NNN/review-diagrams.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| schema | string | Yes | Artifact schema marker, currently `v1` |
| diagram_format | enum: mermaid | Yes | Diagram format used in the artifact |
| structure_diagram | markdown section | No | Mermaid diagram summarizing module or component relationships when grounded evidence exists |
| flow_diagram | markdown section | No | Mermaid diagram summarizing important runtime/request flows when materially changed and sufficiently grounded |
| omissions[] | string[] | Yes | Explicit reasons when diagrams or sections are not generated |
| local_view_hints | string[] | Yes | Local file paths or open hints for browser/editor viewing |

**Relationships**: Referenced by Reviewer Index and rendered from iteration-close review evidence (FR-053).

---

### Current Architecture View

Mutable reviewer-orientation surface describing the latest known system view for a feature.

**Location**: `specs/NNN-feature/current-architecture.md`

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| source_iteration_ref | number | Yes | Most recent iteration that refreshed this current-view artifact |
| summary | markdown section | Yes | Latest structural/flow summary for reviewer orientation |
| linked_current_diagrams | string[] | No | Links to current-view diagrams if generated |
| last_updated | ISO datetime | Yes | Last refresh timestamp |

**Relationships**: Separate from immutable iteration reviewer artifacts; used only as the latest-view companion surface (FR-054).

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
