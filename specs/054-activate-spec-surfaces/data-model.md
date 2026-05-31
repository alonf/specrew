# Data Model: Discoverable Spec Kit Surfaces

## Entity: Lifecycle-Adjacent Command Surface

- **Purpose**: Represents a Spec Kit command that Specrew may surface as part of the governed lifecycle.
- **Fields**:
  - `command_id` (`checklist`, `analyze`, `taskstoissues`)
  - `canonical_command` (e.g. `/speckit.checklist`)
  - `status` (`first-class-active`, `deferred`)
  - `default_boundary` (`before-plan`, `before-implement`, `deferred`)
  - `prerequisite_artifacts` (empty for checklist; `spec.md`, `plan.md`, `tasks.md` for analyze)
  - `positioning_note` (plain-language purpose)
  - `proportionality_rule` (e.g. checklist recommended for substantive work, optional for lightweight slices)
  - `governance_relationship` (`additive`, `deferred`, never `replacement`)
- **Validation rules**:
  - `status=first-class-active` requires a concrete `default_boundary`.
  - `command_id=analyze` requires `tasks.md` in `prerequisite_artifacts`.
  - `command_id=taskstoissues` must remain `status=deferred` in this feature slice.

## Entity: Discovery Surface

- **Purpose**: A user-facing place where lifecycle-adjacent commands are surfaced.
- **Fields**:
  - `surface_id`
  - `path`
  - `surface_type` (`README`, `user-guide`, `agent`, `prompt`, `contract`)
  - `audience` (`new user`, `returning operator`, `Copilot host`, `maintainer`)
  - `boundary_context`
  - `required_commands`
  - `consistency_owner`
- **Validation rules**:
  - Every discovery surface updated by this feature must mention the same boundary for the same active command.
  - Any surface that mentions `/speckit.taskstoissues` must mark it deferred.

## Entity: Boundary Guidance Entry

- **Purpose**: The actual guidance text attached to a command in a specific surface.
- **Fields**:
  - `entry_id`
  - `surface_id`
  - `command_id`
  - `headline`
  - `timing_statement`
  - `plain_language_purpose`
  - `artifact_gate`
  - `optionality_or_deferral_note`
  - `must_not_imply`
- **Validation rules**:
  - `timing_statement` must match the command's `default_boundary`.
  - `must_not_imply` must include "replaces Specrew governance" for `/speckit.analyze`.
  - Checklist entries must preserve proportional guidance for lightweight slices.

## Entity: Deferred Command Decision

- **Purpose**: Captures commands that are known to exist but are intentionally not part of the active default lifecycle.
- **Fields**:
  - `command_id`
  - `decision_status` (`deferred`)
  - `decision_scope` (`this feature slice`)
  - `reason`
  - `revisit_trigger`
- **Validation rules**:
  - `taskstoissues` must retain `decision_status=deferred`.
  - `revisit_trigger` must require an explicit later re-scope, not silent activation.

## Entity: Quality Evidence Plan

- **Purpose**: Records how the plan will prove discovery/lifecycle truthfulness once implementation is authorized.
- **Fields**:
  - `quality_profile`
  - `custom_lenses`
  - `required_risk_dimensions`
  - `required_quality_gates`
  - `mechanical_evidence_path`
  - `tooling_commands`
  - `manual_evidence_path`
  - `not_applicable_dimensions`
- **Validation rules**:
  - `quality_profile` must equal `quality-profile.custom-composition.v1`.
  - `required_quality_gates` must include `dead-field`, `anti-pattern`, `test-integrity`, `stack-tooling-evidence`, and `quality-lens-review`.
  - `tooling_commands` must include markdownlint and the repository's slash-command/lifecycle integration lanes.

## Relationships

- A **Lifecycle-Adjacent Command Surface** appears in one or more **Discovery Surfaces**.
- Each **Discovery Surface** contains one or more **Boundary Guidance Entries**.
- A **Deferred Command Decision** constrains how a command may appear inside **Boundary Guidance Entries**.
- A **Quality Evidence Plan** validates the consistency of the updated **Discovery Surfaces** and **Boundary Guidance Entries**.

## State Transitions

### Command surfacing

`known-but-hidden` → `first-class-active`  
`known-but-hidden` → `deferred`

- `/speckit.checklist` and `/speckit.analyze` move to `first-class-active`.
- `/speckit.taskstoissues` remains `deferred`.

### Guidance readiness

`draft-contract` → `surface-aligned` → `validated`

- `surface-aligned` requires all discovery surfaces to share the same lifecycle timing.
- `validated` requires planned markdownlint plus discovery/routing/lifecycle/contract evidence lanes to pass.
